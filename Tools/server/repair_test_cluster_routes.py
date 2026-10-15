"""Root-reviewed private-clone startup repair. Default plan is read-only.

Run using WSL Python. --apply writes only one pinned private clone source, with
an exclusive backup and provenance under CY-Source/Build. --activate only sends
the reviewed Lua replay to the verified private Tool debug console. No login,
credential, character, service-start, restart, or database operation is present.
"""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import socket
import stat
import sys
import time

import provision_test_wsl as server

CY = Path('/mnt/c/TLBB/085/CY-Source')
REL = Path('GameServer/cluster/service/cluster_mgr.lua')
BEFORE_SHA = '9ac3caffa796a6bba4f51570277af9968cac720afb7d886fe32a83bac6109f29'
DEPENDENCIES = {
    'GameServer/framework/service/debug_console.lua':
        'b6818436bfc0b8213472bf9c464ba83d6035d9bc77a2e417f896e31be585d521',
    'GameServer/cluster/service/cluster_agent.lua':
        'e66bdf20d787afc2fbe5f2672790162a3335fcc7aecaffa3e22db3c76ef2f867',
    'GameServer/framework/service/clusterd.lua':
        '092e1881bf61492c97ee29c6c4ff21dd69f59cc9054f13cc55d0d18f541ee66e',
    'GameServer/framework/lualib/skynet/cluster.lua':
        '0b8c00a36f4751030697169d7a35ba6a6453bd402391268dad2bd727fd850e05',
}
OLD = b'    skynet.fork(function()\n        broad_event(event)\n    end)'
NEW = b'''    skynet.fork(function()
        -- CYS: a peer can become online while this node initializes scenes.
        -- Replay current peers now that the new node can receive events.
        for _, peer in pairs(node_list) do
            if peer.processid ~= process_id and group_intersect(peer.group, node.group) then
                broad_event({name = "online", node = peer}, node)
            end
        end
        broad_event(event)
    end)'''


def sha(data):
    return hashlib.sha256(data).hexdigest()


def patched(data):
    if sha(data) != BEFORE_SHA or data.count(OLD) != 1:
        raise RuntimeError('Pinned cluster manager source mismatch')
    return data.replace(OLD, NEW, 1)


def private_source():
    server.guard()
    p = server.private_path(server.TEST / REL)
    original = server.LIVE / REL
    s = p.lstat()
    if not stat.S_ISREG(s.st_mode) or s.st_nlink != 1:
        raise RuntimeError('Source must be a private regular file without hardlinks')
    if original.exists() and os.path.samefile(p, original):
        raise RuntimeError('Source aliases original runtime')
    return p


def output_path(relative):
    if os.name != 'posix' or CY.resolve() != CY:
        raise RuntimeError('Use the fixed CY-Source checkout in WSL')
    p = Path(relative)
    if p.is_absolute() or '..' in p.parts or not p.parts or p.parts[0] != 'Build':
        raise RuntimeError('Output must be a relative private Build directory')
    out = CY / p
    for item in (out, *out.parents):
        if item.is_symlink():
            raise RuntimeError('Output may not cross a symlink')
        if item == CY:
            break
    out.resolve().relative_to(CY / 'Build')
    if out.exists():
        raise RuntimeError('Preserve previous output directory')
    return out


def verified_tool():
    spec = next(v for v in server.role_specs() if v['name'] == 'Tool')
    owned = server.owned_processes(spec)
    if len(owned) != 1:
        raise RuntimeError('Exactly one owned private Tool process is required')
    process = owned[0]
    # Pin the listening inode to this process, not merely a port number.
    inodes = set()
    for fd in (Path('/proc') / str(process['pid']) / 'fd').iterdir():
        try:
            target = os.readlink(fd)
        except FileNotFoundError:
            continue
        m = re.fullmatch(r'socket:\[(\d+)\]', target)
        if m:
            inodes.add(m[1])
    matched = False
    for line in Path('/proc/net/tcp').read_text().splitlines()[1:]:
        f = line.split()
        if (len(f) > 9 and f[3] == '0A' and f[1] in
                ('0100007F:3E86', '00000000:3E86') and f[9] in inodes):
            matched = True  # 16006, the fixed private Tool debug console.
    if not matched:
        raise RuntimeError('Private Tool does not own the expected debug listener')
    return {'pid': process['pid'], 'start_ticks': process['start_ticks']}


def console_result(data):
    """Classify control vs console formatting; never return raw server text."""
    success = re.search(rb'CYS_ROUTE_OK had_tool=([01]) has_tool=1 public_count=(\d+) filter_equal=1', data)
    failure = re.search(rb'CYS_ROUTE_FAIL phase=(load|activation) code=([a-z_]+) line=(\d+)', data)
    allowed_codes = {'script_load', 'process', 'tool_identity', 'tool_name', 'tool_metadata',
                     'duplicate_endpoint', 'endpoint', 'filter_identity', 'filter_public',
                     'filter_local', 'game_identity', 'replay_refused', 'replay_visibility',
                     'filter_remote', 'unclassified', 'unexpected_result',
                     'call_to_invalid_address', 'call_failed', 'attempt_call_nil',
                     'attempt_index_nil', 'lua_type_error', 'module_not_found', 'file_open'}
    if failure and failure[2].decode('ascii') not in allowed_codes:
        failure = None
    console = 'error' if b'<CMD Error>' in data else ('ok' if b'<CMD OK>' in data else 'missing')
    formatter = b"field 'tostr'" in data or b'field "tostr"' in data
    location = re.search(rb'debug_console\.lua:(\d+):', data)
    detail = re.search(rb' step=([a-z_]+) source=([a-z_.]+) trace=([0-9,]+|none)', data)
    steps = {'load', 'unknown', 'module_skynet', 'module_cluster', 'identity_env',
             'tool_process', 'tool_name', 'tool_metadata', 'tool_public', 'filter_local',
             'game_process', 'game_nodes_before', 'replay', 'game_nodes_after', 'filter_remote', 'complete'}
    sources = {'none', 'activate_test_cluster_routes.lua', 'skynet.lua', 'cluster.lua',
               'console_test_cluster_routes.lua', 'debug_console.lua'}
    if detail and (detail[1].decode('ascii') not in steps or detail[2].decode('ascii') not in sources):
        detail = None
    trace = [int(v) for v in detail[3].split(b',')] if detail and detail[3] != b'none' else []
    if len(trace) > 6 or any(v >= 10000 for v in trace):
        trace = []
    return {
        'ok': success is not None and failure is None and console == 'ok',
        'console_status': console,
        'activation_status': 'success' if success else ('failure' if failure else 'unknown'),
        'format_status': 'error' if formatter else ('ok' if success or failure else 'unknown'),
        'failure_phase': failure[1].decode('ascii') if failure else None,
        'failure_code': failure[2].decode('ascii') if failure else None,
        'failure_line': int(failure[3]) if failure else None,
        'failure_step': detail[1].decode('ascii') if detail else None,
        'failure_source': detail[2].decode('ascii') if detail else None,
        'activation_trace_lines': trace,
        'console_source': 'debug_console.lua' if location else None,
        'console_line': int(location[1]) if location else None,
        'had_tool': bool(int(success[1])) if success else None,
        'has_tool': bool(success), 'public_count': int(success[2]) if success else None,
        'filter_equal': bool(success),
    }


def activate():
    identity = verified_tool()
    game_spec = next(v for v in server.role_specs() if v['name'] == 'Game')
    games = server.owned_processes(game_spec)
    if len(games) != 1:
        raise RuntimeError('Exactly one owned private Game process is required')
    game_identity = {'pid': games[0]['pid'], 'start_ticks': games[0]['start_ticks']}
    for rel, expected in DEPENDENCIES.items():
        p = server.private_path(server.TEST / rel)
        if not p.is_file() or p.stat().st_nlink != 1 or sha(p.read_bytes()) != expected:
            raise RuntimeError('Reviewed debug/bootstrap dependency mismatch')
    script = CY / 'Tools/server/activate_test_cluster_routes.lua'
    if script.is_symlink() or script.resolve() != script or not script.is_file():
        raise RuntimeError('Replay script identity mismatch')
    wrapper = CY / 'Tools/server/console_test_cluster_routes.lua'
    if wrapper.is_symlink() or wrapper.resolve() != wrapper or not wrapper.is_file():
        raise RuntimeError('Console wrapper identity mismatch')
    # The Skynet loadfile cache can retain a previous helper at the same path.
    # Load only this reviewed bounded text; never clear the shared code cache.
    command = ('run local f=assert(io.open("' + str(wrapper) + '","rb")); '
               'local s=f:read(131073); f:close(); assert(#s<=131072); '
               'return assert(load(s,"@' + str(wrapper) + '","t"))()\n').encode('ascii')
    with socket.create_connection(('127.0.0.1', 16006), timeout=3) as sock:
        sock.settimeout(0.5)
        data = b''
        deadline = time.monotonic() + 3
        while b'Welcome' not in data and time.monotonic() < deadline:
            try:
                chunk = sock.recv(4096)
            except socket.timeout:
                continue
            if not chunk:
                break
            data += chunk
            if len(data) > 8192:
                raise RuntimeError('Unexpected debug console greeting')
        if b'Welcome' not in data or verified_tool() != identity:
            raise RuntimeError('Debug console ownership or greeting changed')
        sock.sendall(command)
        data = b''
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            try:
                chunk = sock.recv(4096)
            except socket.timeout:
                continue
            if not chunk:
                break
            data += chunk
            if len(data) > 16384:
                raise RuntimeError('Unexpected debug reply size')
            if b'<CMD OK>' in data or b'<CMD Error>' in data:
                break
    # Deliberately never save/print raw console reply or exception text.
    result = console_result(data)
    games_after = server.owned_processes(game_spec)
    ok = result['ok'] and len(games_after) == 1 and games_after[0]['pid'] == game_identity['pid']
    ok = ok and games_after[0]['start_ticks'] == game_identity['start_ticks']
    return {**result, 'ok': ok, 'tool_identity': identity, 'game_identity': game_identity,
            'response_sha256': sha(data),
            'response_bytes': len(data), 'script_sha256': sha(script.read_bytes()),
            'wrapper_sha256': sha(wrapper.read_bytes()),
            'reviewed_source_hashes': DEPENDENCIES}


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--out', required=True)
    actions = ap.add_mutually_exclusive_group()
    actions.add_argument('--apply', action='store_true')
    actions.add_argument('--activate', action='store_true')
    args = ap.parse_args()
    source = private_source()
    out = output_path(args.out)
    before = source.read_bytes()
    if args.activate:
        if sha(before) != BEFORE_SHA and not (before.count(NEW) == 1 and
                sha(before.replace(NEW, OLD, 1)) == BEFORE_SHA):
            raise RuntimeError('Current cluster manager is neither reviewed original nor patch')
        # Activation can run after applying the startup repair; module identity
        # and route guards are enforced independently of the loaded old manager.
        out.mkdir(parents=True)
        (out / 'pending.json').write_text('{"mode":"activate","started":true}\n')
        result = activate()
        result['manager_source_sha256'] = sha(before)
    else:
        after = patched(before)
        result = {'ok': True, 'mode': 'apply' if args.apply else 'plan',
                  'target': str(REL), 'before_sha256': sha(before),
                  'after_sha256': sha(after), 'source_original_untouched': True}
        out.mkdir(parents=True)
        (out / 'cluster_mgr.before.lua').write_bytes(before)
        (out / 'cluster_mgr.after.lua').write_bytes(after)
        if args.apply:
            if source.read_bytes() != before or private_source() != source:
                raise RuntimeError('Source changed after planning')
            temp = server.private_path(source.with_name(source.name + '.cys-route-new'))
            with temp.open('xb') as f:
                f.write(after)
            temp.chmod(stat.S_IMODE(source.stat().st_mode))
            os.replace(temp, source)
            if source.read_bytes() != after:
                raise RuntimeError('Applied source verification failed')
    out.mkdir(parents=True, exist_ok=True)
    result['utc'] = datetime.datetime.now(datetime.timezone.utc).isoformat()
    (out / 'report.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result))
    return 0 if result['ok'] else 1


if __name__ == '__main__':
    try:
        sys.exit(main())
    except Exception as exc:
        print(json.dumps({'ok': False, 'error_type': type(exc).__name__}))
        sys.exit(1)
