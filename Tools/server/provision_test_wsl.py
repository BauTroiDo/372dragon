"""Provision a separate TLBB test runtime inside the existing WSL distribution.

Run with WSL Python. Creates only the named test directory; never changes the
live /home/ubuntu runtime or its database. Credentials are generated privately
or supplied through CYS_BOT_PWD, never printed or accepted on the command line.
"""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import secrets
import shutil
import signal
import select
import subprocess
import time

LIVE = Path('/home/ubuntu')
TEST = LIVE/'cys-test-20260913'
PORTS = [27018, 1884, 18888, 12531, 12532, 12528, 15733, 15734,
         16002, 16006, 16009, 18000, 23010, 23011, 23012, 23013]


def validate_root_identity(platform, test, live, resolved_test, resolved_live):
    fixed = PurePosixPath('/home/ubuntu/cys-test-20260913')
    if (platform != 'posix' or PurePosixPath(test) != fixed or
            PurePosixPath(live) != fixed.parent or
            PurePosixPath(resolved_test) != fixed or
            PurePosixPath(resolved_live) != fixed.parent):
        raise RuntimeError('Use WSL and the fixed private test root without symlinks')


def guard():
    validate_root_identity(os.name, TEST.as_posix(), LIVE.as_posix(),
                           TEST.resolve().as_posix(), LIVE.resolve().as_posix())


def private_path(path):
    """Reject escape and every symlink from the fixed root to the target."""
    path = Path(path)
    if '..' in path.parts or not path.is_absolute():
        raise RuntimeError('Private path must be absolute and may not contain traversal')
    try:
        path.relative_to(TEST)
        path.resolve().relative_to(TEST.resolve())
    except ValueError:
        raise RuntimeError('Path escapes the private test root') from None
    for candidate in (path, *path.parents):
        if candidate.is_symlink():
            raise RuntimeError('Private path may not cross a symlink')
        if candidate == TEST:
            break
    return path


def role_specs():
    game = TEST/'GameServer'
    roles = [
        {'name': 'Mongo', 'exe': Path('/usr/bin/mongod'), 'config': TEST/'mongod.conf',
         'pidfile': TEST/'mongod.pid', 'ports': [27018], 'option': '--config'},
        {'name': 'MQTT', 'exe': Path('/usr/sbin/mosquitto'), 'config': TEST/'mosquitto.conf',
         'pidfile': TEST/'mosquitto.pid', 'ports': [1884], 'option': '-c'},
    ]
    for name, number, ports in [('Manager',8,[18888]), ('DataCenter',9,[12531]),
                                 ('Tool',6,[12532]), ('Game',2,[15733,15734])]:
        roles.append({'name':name, 'process_id':number, 'exe':game/'framework'/f'{name}_tlbb_{number}',
                      'config':game/f'config_{number}', 'pidfile':game/f'skynet_{number}.pid',
                      'ports':ports, 'cwd':game})
    return roles


def read_process(pid):
    """Read only identity metadata; callers never publish argv or config contents."""
    if not isinstance(pid, int) or pid <= 1:
        return None
    proc = Path('/proc')/str(pid)
    try:
        raw = (proc/'cmdline').read_bytes()
        stat = (proc/'stat').read_text()
        fields = stat[stat.rfind(')') + 2:].split()
        if len(fields) < 20 or fields[0] == 'Z':
            return None
        return {'pid':pid, 'start_ticks':int(fields[19]),
                'exe':str((proc/'exe').resolve(strict=True)),
                'cwd':str((proc/'cwd').resolve(strict=True)),
                'args':[v.decode('utf-8', 'surrogateescape') for v in raw.split(b'\0') if v]}
    except (OSError, ValueError):
        return None


def process_matches(process, spec):
    if not process or process['exe'] != str(spec['exe'].resolve()):
        return False
    args = process['args']
    if 'option' in spec:
        expected = [spec['option'], str(spec['config'])]
        return args[1:] == expected or (spec['name']=='MQTT' and args[1:] == expected+['-d'])
    return (process['cwd'] == str(spec['cwd']) and len(args) == 2 and
            args[1] == str(spec['config']))


def owned_processes(spec, snapshot=None):
    if snapshot is None:
        snapshot = (read_process(int(p.name)) for p in Path('/proc').iterdir() if p.name.isdigit())
    return sorted((p for p in snapshot if process_matches(p, spec)), key=lambda p:p['pid'])


def needs_start(spec, owned, occupied):
    if len(owned) > 1:
        raise RuntimeError('Multiple owned processes; inspect the private test runtime')
    if owned:
        return False
    if any(occupied.get(port, False) for port in spec['ports']):
        raise RuntimeError('Test port occupied without a verified owned process')
    return True


def archive_existing(path, reason):
    """Move only a verified private regular file; never delete stale evidence."""
    path = private_path(path)
    if not path.exists():
        return None
    if not path.is_file():
        raise RuntimeError('Only private regular files can be archived')
    archive = private_path(TEST/'lifecycle-backups')
    archive.mkdir(mode=0o700, exist_ok=True)
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S')
    destination = private_path(archive/(stamp+'-'+str(time.time_ns())+'-'+reason+'-'+path.name))
    if destination.exists():
        raise RuntimeError('Preserve existing lifecycle archive')
    path.rename(destination)
    return destination


def parse_tcp_listeners(text, family):
    """Kernel LISTEN metadata only; an empty connect would create server errors."""
    result=set()
    for line in text.splitlines()[1:]:
        fields=line.split()
        if not fields:
            continue
        if len(fields)<4:
            raise RuntimeError('Malformed kernel TCP table')
        if fields[3]!='0A':
            continue
        address,port=fields[1].split(':')
        if len(address)!=(8 if family==4 else 32):
            raise RuntimeError('Malformed kernel TCP address')
        int(address,16)
        number=int(port,16)
        if not 0<number<=65535:
            raise RuntimeError('Malformed kernel TCP port')
        result.add((family,address.upper(),number))
    return result


def tcp_listeners():
    listeners=parse_tcp_listeners(Path('/proc/net/tcp').read_text(),4)
    try:
        listeners.update(parse_tcp_listeners(Path('/proc/net/tcp6').read_text(),6))
    except FileNotFoundError:
        pass # IPv6 may be disabled; IPv4 table is required.
    return listeners


def port_open(port, listeners=None):
    # Test clients explicitly connect IPv4 127.0.0.1. Another LAN/loopback IP or
    # an IPv6-only listener does not prove that endpoint is available.
    listeners=tcp_listeners() if listeners is None else listeners
    return (4,'0100007F',port) in listeners or (4,'00000000',port) in listeners


def port_occupied(port):
    # Before launch, any LISTEN binding/family on this port is a conflict.
    return any(entry[2]==port for entry in tcp_listeners())


def write_new(path, text, mode=0o600):
    path = private_path(path)
    with path.open('x', encoding='utf-8', newline='\n') as stream:
        stream.write(text)
    path.chmod(mode)


def report(name, value):
    private_path(TEST/name).write_text(json.dumps(value, indent=2), encoding='utf-8')


def initialize():
    guard()
    if TEST.exists():
        raise RuntimeError('Preserve existing test root; use status/start')
    if any(port_occupied(p) for p in PORTS):
        raise RuntimeError('A test port is occupied')
    TEST.mkdir(mode=0o700)
    os.umask(0o077)
    records=[]
    def ignore(directory, names):
        skip=[]
        for name in names:
            if '.bak' in name or name.startswith(('nohup_', 'skynet_')) or re.fullmatch(r'config_\d+',name) or name.endswith(('.pid','.out','.log')):
                skip.append(name)
            elif Path(directory)==LIVE/'GameServer' and name in ('config','game_config','tool_config','DataCenter_config'):
                skip.append(name)
        return skip
    for name in ('GameServer','Game_2','configs'):
        shutil.copytree(LIVE/name, TEST/name, ignore=ignore, symlinks=False)
        print('Copied '+name, flush=True)
    # Rewrite only absolute references inside the private copy, at byte level.
    for top in ('GameServer','Game_2','configs'):
        for path in (TEST/top).rglob('*'):
            if not path.is_file():
                continue
            data=path.read_bytes()
            digest=hashlib.sha256(data).hexdigest()
            changed=data
            if path.suffix in ('.lua','.sh','.path'):
                changed=changed.replace(b'/home/ubuntu/',str(TEST).encode()+b'/')
            if path.suffix=='.lua':
                changed=changed.replace(b'socket.listen("0.0.0.0",',b'socket.listen("127.0.0.1",')
            if changed!=data:
                path.write_bytes(changed)
            records.append({'path':str(path.relative_to(TEST)), 'source_sha256':digest,
                            'test_sha256':hashlib.sha256(changed).hexdigest()})
    conf=TEST/'confs/publish_yu'
    conf.mkdir(parents=True)
    for name in ('db_conf.lua','default_char.lua','ranking_conf.lua'):
        shutil.copy2(LIVE/'confs/publish_yu'/name,conf/name)
    shutil.copy2(LIVE/'confs/publish_yu/cluster_db_conf.lua',conf/'cluster_db_source.lua')
    write_new(conf/'cluster_db_conf.lua', '''-- CYS: same services, separate ports and only zone 1.
local c = require "cluster_db_source"
local enabled = {[2]=true,[6]=true,[8]=true,[9]=true}
local function remap(t)
    for k,v in pairs(t) do
        if k == "port" and type(v) == "number" and v > 0 then t[k] = v + 10000
        elseif k == "address" then t[k] = "127.0.0.1"
        elseif type(v) == "table" then remap(v) end
    end
end
for _,h in ipairs(c.host_conf) do h.localip="127.0.0.1"; h.ip="127.0.0.1"; h.domain="127.0.0.1" end
local p,s={},{}
for _,v in ipairs(c.process_conf) do if enabled[v.id] then p[#p+1]=v end end
for _,v in ipairs(c.server_conf) do if enabled[v.processid] then remap(v); s[#s+1]=v end end
c.process_conf=p; c.server_conf=s
return c
''')
    cluster=(LIVE/'confs/publish_yu/cluster_conf.lua').read_bytes()
    assert b'127.0.0.1:8888' in cluster
    (conf/'cluster_conf.lua').write_bytes(cluster.replace(b'127.0.0.1:8888',b'127.0.0.1:18888'))
    db_secret=secrets.token_hex(32)
    config='''local c = {}
c.server_ip = "127.0.0.1"
c.gamedb = {host="127.0.0.1",port=27018,db_name="admin",username="cys_test",password="%s"}
c.logdb = c.gamedb
c.mysqldb = {host="127.0.0.1",port=13306,database="dl",user="cys_test",password=""}
c.mqtt = {uri="127.0.0.1:1884",clean=true}
c.MAX_COPY_SCENE=20
c.MAX_SPAN_COPY_SCENE=5
c.PREWARM_COPY_SCENE=3
c.client_wire_encoding="utf8"
return c
''' % db_secret
    write_new(conf/'server_conf.lua',config)
    (TEST/'db').mkdir()
    (TEST/'log').mkdir()
    write_new(TEST/'mongod.conf', f'''storage:
  dbPath: {TEST}/db
  wiredTiger:
    engineConfig:
      cacheSizeGB: 0.5
systemLog:
  destination: file
  path: {TEST}/log/mongod.log
  logAppend: true
net:
  bindIp: 127.0.0.1
  port: 27018
security:
  authorization: enabled
processManagement:
  fork: true
  pidFilePath: {TEST}/mongod.pid
''')
    write_new(TEST/'mosquitto.conf',f'''listener 1884 127.0.0.1
allow_anonymous true
persistence false
log_dest file {TEST}/log/mosquitto.log
pid_file {TEST}/mosquitto.pid
user root
''')
    # No production credentials are copied. Fresh Mongo uses the localhost
    # exception once to create the generated private test administrator.
    proc=subprocess.run(['/usr/bin/mongod','--config',str(TEST/'mongod.conf')],capture_output=True)
    if proc.returncode:
        raise RuntimeError('Test mongod startup failed; inspect private log')
    from pymongo import MongoClient
    client=MongoClient('127.0.0.1',27018,serverSelectionTimeoutMS=5000)
    client.admin.command('createUser','cys_test',pwd=db_secret,roles=[{'role':'root','db':'admin'}])
    client.close()
    report('source-manifest.json',records)
    report('provision.json',{'root':str(TEST),'source':str(LIVE),'at':datetime.datetime.now().isoformat(),
                           'fresh_database':True,'live_database_copied':False,'ports':PORTS,'files':len(records)})
    print('Test runtime provisioned; fresh private Mongo, source unchanged',flush=True)


def database():
    from pymongo import MongoClient
    guard()
    config=private_path(TEST/'confs/publish_yu/server_conf.lua').read_text()
    match=re.search(r'username="cys_test",password="([0-9a-f]{64})"',config)
    if not match:
        raise RuntimeError('Invalid private test database configuration')
    return MongoClient('127.0.0.1',27018,username='cys_test',password=match[1],authSource='admin',serverSelectionTimeoutMS=5000)


def account():
    guard()
    password=os.environ.get('CYS_BOT_PWD')
    if not password or len(password)>32:
        raise RuntimeError('Set CYS_BOT_PWD in memory')
    client=database()
    collection=client.tlbb.account
    existing=collection.find_one({'uid':'test00'},{'_id':1})
    if existing:
        raise RuntimeError('test00 already exists; do not overwrite its credentials')
    collection.create_index('uid',unique=True)
    collection.insert_one({'uid':'test00','pwd':password,'super_pwd':password,'uuid':'100001',
                           'char_list':[],'top_up_point':0,'status':0,'right':0,'ip':'127.0.0.1',
                           'date':datetime.datetime.now().strftime('%Y-%m-%d'),'qq':''})
    found=collection.find_one({'uid':'test00'},{'_id':0,'uid':1,'uuid':1,'status':1,'char_list':1})
    assert found and found['char_list']==[] and found['status']==0
    report('account-created.json',{'account':'test00','database_port':27018,'created':True,'characters':0})
    client.close()
    print('Created test00 in private test database; credentials omitted',flush=True)


def start():
    guard()
    os.umask(0o077)
    if not private_path(TEST/'provision.json').is_file():
        raise RuntimeError('Provision is incomplete')
    specs=role_specs()
    # Validate every destination first, before starting or moving anything.
    for spec in specs:
        private_path(spec['config'])
        private_path(spec['pidfile'])
        if 'cwd' in spec:
            private_path(spec['exe'])
            private_path(spec['cwd'])
    for spec in specs:
        owned=owned_processes(spec)
        occupied={p:port_occupied(p) for p in spec['ports']}
        if not needs_start(spec,owned,occupied):
            print(spec['name']+' already running (verified identity)',flush=True)
            continue
        name=spec['name']
        # A stale/reused pid never authorizes a signal. Preserve it before launch.
        archive_existing(spec['pidfile'],'stale-pid')
        if name in ('Mongo','MQTT'):
            command=([str(spec['exe']),'--config',str(spec['config'])] if name=='Mongo' else
                     [str(spec['exe']),'-c',str(spec['config']),'-d'])
            subprocess.run(command,check=True,capture_output=True)
            for _ in range(50):
                if owned_processes(spec) and all(port_open(p) for p in spec['ports']):
                    break
                time.sleep(.1)
            else:
                raise RuntimeError('Private infrastructure service did not become ready')
            print('Started '+name+' in test root',flush=True)
            continue
        game=spec['cwd']
        pid=spec['process_id']
        target=spec['exe']
        if not target.exists():
            shutil.copy2(private_path(game/'framework/skynet'),target)
        command=['lua','config_maker.lua','publish_yu',str(TEST/'Game_2/Script'),str(pid),name,str(TEST/'Game_2/Scene'),str(TEST/'configs/%s')]
        private_path(game/'config_maker.lua')
        generated=subprocess.run(command,cwd=game,check=True,capture_output=True).stdout.replace(b'thread = 64',b'thread = 16')
        config=spec['config']
        archive_existing(config,'previous-config')
        with config.open('xb') as stream:
            stream.write(generated)
        logpath=private_path(game/f'nohup_{pid}.out')
        archive_existing(logpath,'previous-output')
        with logpath.open('xb') as log:
            subprocess.Popen([str(target),str(config)],cwd=game,stdout=log,stderr=log,start_new_session=True)
        print('Started '+name+' in test root',flush=True)
        # Short startup waits only; Game scene readiness is polled separately.
        for _ in range(20):
            if all(port_open(p) for p in spec['ports']):
                break
            time.sleep(1)
        if not owned_processes(spec):
            raise RuntimeError('Private game service exited during startup; logs preserved')
        if name=='Tool':
            for _ in range(40):
                logs=sorted((TEST/'log').glob('*/Tool6_*.log'))
                if logs and b'LAUNCH snlua ranking' in logs[-1].read_bytes():
                    break
                time.sleep(1)
    print(json.dumps(status()),flush=True)


def status():
    guard()
    snapshot=[read_process(int(p.name)) for p in Path('/proc').iterdir() if p.name.isdigit()]
    services=[]
    for spec in role_specs():
        path=private_path(spec['pidfile'])
        number=path.read_text().strip() if path.is_file() else ''
        # Publish only a numeric pid; malformed contents may contain unrelated text.
        file_pid=int(number) if number.isdecimal() and len(number)<=10 else None
        owned=owned_processes(spec,snapshot)
        services.append({'name':spec['name'],'process_id':spec.get('process_id'),
                         'owned_pids':[p['pid'] for p in owned], 'running':bool(owned),
                         'duplicate':len(owned)>1, 'pid_file_pid':file_pid,
                         'pid_file_matches':len(owned)==1 and file_pid==owned[0]['pid']})
    listeners=tcp_listeners()
    return {'root':str(TEST),'services':services,'port_check':'kernel-listen-no-connect',
            'ports':{str(p):port_open(p,listeners) for p in PORTS}}


def stop_owned(spec, expected, timeout=30):
    """SIGTERM one verified identity through pidfd, never a reusable numeric PID."""
    if not hasattr(os,'pidfd_open') or not hasattr(signal,'pidfd_send_signal'):
        raise RuntimeError('Safe stop requires Linux pidfd support')
    try:
        handle=os.pidfd_open(expected['pid'],0)
    except ProcessLookupError:
        return False
    try:
        current=read_process(expected['pid'])
        if (not process_matches(current,spec) or
                current['start_ticks']!=expected['start_ticks']):
            raise RuntimeError('Process identity changed; no signal sent')
        try:
            signal.pidfd_send_signal(handle,signal.SIGTERM,None,0)
        except ProcessLookupError:
            return False
        ready,_,_=select.select([handle],[],[],timeout)
        if not ready:
            raise RuntimeError('Private service did not stop; no forced kill performed')
        return True
    finally:
        os.close(handle)


def stop(confirm_root):
    guard()
    if confirm_root!=str(TEST):
        raise RuntimeError('Stop requires the exact private root confirmation')
    # Reverse dependency order: Game, Tool, DataCenter, Manager, MQTT, Mongo.
    specs=list(reversed(role_specs()))
    planned=[]
    for spec in specs:
        private_path(spec['config'])
        private_path(spec['pidfile'])
        owned=owned_processes(spec)
        if len(owned)>1:
            raise RuntimeError('Multiple owned processes; stop plan refused')
        planned.append((spec,owned))
    for spec,owned in planned:
        if owned:
            stop_owned(spec,owned[0])
            print('Stopped verified private '+spec['name'],flush=True)
        else:
            print(spec['name']+' already stopped (no verified process)',flush=True)
    print(json.dumps(status()),flush=True)


def record_supplement():
    """Add provenance for config_maker restored after the original init manifest."""
    guard()
    relative=Path('GameServer/config_maker.lua')
    source=LIVE/relative
    target=private_path(TEST/relative)
    original=private_path(TEST/'source-manifest.json')
    if not original.is_file() or not target.is_file():
        raise RuntimeError('Original manifest and restored file are required')
    source_hash=hashlib.sha256(source.read_bytes()).hexdigest()
    target_hash=hashlib.sha256(target.read_bytes()).hexdigest()
    directory=private_path(TEST/'manifest-supplements')
    directory.mkdir(mode=0o700,exist_ok=True)
    for previous in directory.glob('*.json'):
        data=json.loads(private_path(previous).read_text())
        if (data.get('path')==relative.as_posix() and data.get('source_sha256')==source_hash and
                data.get('test_sha256')==target_hash):
            print('Supplement already recorded; original manifest unchanged',flush=True)
            return
    value={'path':relative.as_posix(),'source_sha256':source_hash,'test_sha256':target_hash,
           'reason':'config_maker restored after the original init ignore rule was corrected',
           'original_manifest_sha256':hashlib.sha256(original.read_bytes()).hexdigest(),
           'at':datetime.datetime.now(datetime.timezone.utc).isoformat()}
    write_new(directory/(str(time.time_ns())+'-config-maker.json'),json.dumps(value,indent=2)+'\n')
    print('Supplement recorded; original manifest unchanged',flush=True)


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('action',choices=['init','account','start','status','stop','record-supplement'])
    parser.add_argument('--confirm-root',default=None)
    args=parser.parse_args()
    try:
        if args.action=='status':
            print(json.dumps(status(),indent=2))
        elif args.action=='stop':
            stop(args.confirm_root)
        elif args.action=='record-supplement':
            record_supplement()
        else:
            globals()[{'init':'initialize'}.get(args.action,args.action)]()
    except Exception as error:
        # Database exceptions may echo command documents. Keep details private.
        print('Test operation failed: '+type(error).__name__+'; inspect test state without printing credentials',flush=True)
        raise SystemExit(1)
