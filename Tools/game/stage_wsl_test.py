#!/usr/bin/env python3
"""CY-Source Tools/game/stage_wsl_test.py - switch a Tools/game/stage_game.py stage between the offline smoke
endpoint (127.0.0.1:14400, never contacted) and a modern (skynet) server profile.

Profiles:
  cys-server (default)  the private CY-Source server /home/ubuntu/cys-test-20260913 on WSL TLBB. The login/game
                        ports and the reply host are READ from its confs/publish_yu (Tools/server/
                        cys_server_endpoints.lua evaluates cluster_db_conf.lua + server_conf.server_ip inside WSL,
                        read-only). Writes Patch/CysServerProfile.txt (endpoint, game port, host allow-list) and
                        Bin64/Run-CY-Server.cmd. No environment switch: Game.exe picks the modern protocol from
                        the profile file.
  wsl-test              legacy clone launchers (CYS_WSL_LOGIN_TEST=1, Run-CY-Test.cmd + Run-World-GUI.cmd, no
                        profile file; Game.exe uses its compatibility profile 15733/15734). Kept for old stages.

  apply  --stage DIR [--profile P] [--accounts a,b]   offline -> profile. WXSystem.cfg GameServer_Port 14400 -> login
                       port, Patch/LoginServer.txt (exact offline fixture) -> one server, Patch/WXLoginServer.txt
                       PORT -> login port, launchers (ASCII). Records every before/after sha256 under "wsl_test" in
                       Bin64/game_data_stage.json.
  revert --stage DIR   profile -> offline (the exact inverse; launchers and profile file removed; record kept under
                       "wsl_test_history").
  check  --stage DIR [--no-server]   verifies files/binaries against the recorded state; for cys-server also
                       re-reads the server configuration (read-only) and reports a drift of its endpoints.
  endpoints            prints the private server endpoints read from WSL (read-only).

The offline transform is the one Tools/data/prepare_gl_login_profile.py --wsl-test applies to a GL login stage
(Docs/specs/net/wsl-test_vi.md, Docs/specs/net/cys-server_vi.md). Offline smokes (Tools/game/run_game_smoke.ps1)
require the offline state, so smoke first, then apply. Never touches Data (junction), Overlay or any binary; refuses
while a Game.exe of the stage runs. Never connects to any server port.
"""
import argparse
import datetime
import hashlib
import ipaddress
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
TOOL_ROOT = Path(__file__).resolve().parents[2]
OFFLINE_PORT = 14400
LEGACY_LOGIN_PORT, LEGACY_GAME_PORT = 15733, 15734
SERVER_ROOT = '/home/ubuntu/cys-test-20260913'
WSL_DISTRO = 'TLBB'
FIXTURE = 'Tests/ui/fixtures/login-server-utf8.txt'
FILES = ('Bin64/WXSystem.cfg', 'Patch/LoginServer.txt', 'Patch/WXLoginServer.txt')
PROFILE_FILE = 'Patch/CysServerProfile.txt'

RUN_CY_TEST = '''@echo off
rem CY-Source world3 stage: GL login against the authorized WSL test clone (127.0.0.1:15733 login / 15734 game).
rem Data is the Canonical junction; Game.exe + every DLL come from one Release build of the world3 worktree.
rem The password is typed in the game window only; nothing is stored. ASCII only.
cd /d "%~dp0"
set "CYS_WSL_LOGIN_TEST=1"
set "CYS_GL_LOGIN_SMOKE="
set "CYS_CREATE_ROLE_SMOKE="
set "CYS_BOT_PWD="
set "TEMP=%~dp0tmp"
set "TMP=%~dp0tmp"
if not exist "%TEMP%" mkdir "%TEMP%"
start "" "%~dp0Game.exe" -fl
'''

RUN_WORLD_GUI = '''@echo off
rem CY world GUI test (world3): WSL-test login (like Run-CY-Test.cmd) -> CLAskCharLogin -> game socket (CGConnect
rem first) -> scene 2. Game.exe and all DLLs are one build of the world3 worktree (DBC structs follow client_GL,
rem so SceneDefineEx.txt is read and scene 2 resolves). Private clone only: 127.0.0.1:15733 login / 15734 game.
rem The password is typed in the game window only; nothing is stored.
rem Guide (Vietnamese): C:\\TLBB\\085\\CY-Source\\Docs\\specs\\net\\world-gui-howto_vi.md
cd /d "%~dp0"
set "CYS_WSL_LOGIN_TEST=1"
set "CYS_GL_LOGIN_SMOKE="
set "CYS_CREATE_ROLE_SMOKE="
set "CYS_BOT_PWD="
set "TEMP=%~dp0tmp"
set "TMP=%~dp0tmp"
if not exist "%TEMP%" mkdir "%TEMP%"
echo CY world GUI test (world3): log in as test00, choose CYTest00, enter the game, walk a few steps, quit from the menu.
echo Guide: C:\\TLBB\\085\\CY-Source\\Docs\\specs\\net\\world-gui-howto_vi.md
start "" "%~dp0Game.exe" -fl
'''

RUN_CY_SERVER = '''@echo off
rem CY-Source stage -> private CY-Source server (WSL {root}).
rem Endpoints come from Patch\\CysServerProfile.txt (login {login_host}:{login_port}, game port {game_port}), written by
rem Tools\\game\\stage_wsl_test.py from the server confs/publish_yu. No CYS_WSL_LOGIN_TEST switch is needed.
rem The password is typed in the game window only; nothing is stored. ASCII only.
rem Guide (Vietnamese): C:\\TLBB\\085\\CY-Source\\Docs\\specs\\net\\cys-server_vi.md
cd /d "%~dp0"
tasklist /FI "IMAGENAME eq Game.exe" 2>nul | find /I "Game.exe" >nul
if not errorlevel 1 (
  echo Another Game.exe is running. Close it first: only one Game.exe can run at a time.
  pause
  exit /b 1
)
set "CYS_WSL_LOGIN_TEST="
set "CYS_GL_LOGIN_SMOKE="
set "CYS_CREATE_ROLE_SMOKE="
set "CYS_WORLD_REPLAY="
set "CYS_BOT_PWD="
set "TEMP=%~dp0tmp"
set "TMP=%~dp0tmp"
if not exist "%TEMP%" mkdir "%TEMP%"
echo CY-Source private server: log in with a test account (e.g. test00), choose a character, enter the game, quit from the menu.
start "" "%~dp0Game.exe" -fl
'''


def sha(data):
    return hashlib.sha256(data).hexdigest()


def rel(path):
    try:
        return Path(path).resolve().relative_to(ROOT.resolve()).as_posix()
    except ValueError:
        return str(path).replace('\\', '/')


def exact_setting(data, name, expected):
    values = re.findall(rb'(?m)^[ \t]*' + re.escape(name) + rb'[ \t]*=[ \t]*([^\r\n]*)', data)
    if [v.strip() for v in values] != [expected]:
        raise SystemExit('unexpected or duplicate setting %s in the stage' % name.decode('ascii'))


def swap_port(data, name, old, new):
    exact_setting(data, name, old)
    pattern = rb'(?m)^([ \t]*' + re.escape(name) + rb'[ \t]*=[ \t]*)' + old + rb'([ \t]*\r?$)'
    after, count = re.subn(pattern, rb'\g<1>' + new + rb'\g<2>', data)
    if count != 1:
        raise SystemExit('could not replace %s' % name.decode('ascii'))
    return after


def login_list(fixture, host, port, name, description):
    modern = fixture.replace(b'127.0.0.1:14400', ('%s:%d' % (host, port)).encode('ascii'))
    return modern.replace(b'CYS offline', name.encode('ascii')).replace(b'offline (no server)', description.encode('ascii'))


def wsl_login_list(fixture):
    return login_list(fixture, '127.0.0.1', LEGACY_LOGIN_PORT, 'CYS WSL Test', 'Independent WSL test')


def allow_literal(host):
    try:
        address = ipaddress.IPv4Address(host)
    except ValueError:
        return False
    return str(address) == host and (address.is_loopback or address in ipaddress.ip_network('10.0.0.0/8') or
                                     address in ipaddress.ip_network('172.16.0.0/12') or
                                     address in ipaddress.ip_network('192.168.0.0/16'))


def wsl_path(path):
    resolved = Path(path).resolve()
    drive = resolved.drive.rstrip(':').lower()
    if not drive:
        raise SystemExit('tool path must be on a Windows drive: ' + str(resolved))
    return '/mnt/%s/%s' % (drive, resolved.as_posix().split(':/', 1)[1])


def read_server_endpoints():
    """Effective endpoints of the private server, evaluated by Lua inside WSL (read-only, no socket)."""
    script = TOOL_ROOT / 'Tools/server/cys_server_endpoints.lua'
    result = subprocess.run(['wsl.exe', '-d', WSL_DISTRO, '-u', 'root', '--', 'lua', wsl_path(script), SERVER_ROOT, '2'],
                            capture_output=True, timeout=60)
    if result.returncode != 0:
        raise SystemExit('could not read the private server configuration (rc=%d)' % result.returncode)
    values = {}
    for line in result.stdout.decode('utf-8', 'replace').splitlines():
        parts = line.strip().split('\t')
        if parts and parts[0] in ('logind', 'gamed') and len(parts) == 3:
            values[parts[0]] = (int(parts[1]), parts[2])
        elif parts and parts[0] == 'server_ip' and len(parts) == 2:
            values['server_ip'] = parts[1]
        elif parts and parts[0] == 'process' and len(parts) == 3:
            values['process'] = parts[2]
    if set(values) != {'logind', 'gamed', 'server_ip', 'process'} or values['process'] != 'Game_tlbb_2':
        raise SystemExit('private server configuration is incomplete (need process 2 logind/gamed/server_ip)')
    login_port, login_address = values['logind']
    game_port, _ = values['gamed']
    server_ip = values['server_ip']
    if not (0 < login_port < 65536 and 0 < game_port < 65536 and login_port != game_port):
        raise SystemExit('private server ports are invalid')
    login_host = '127.0.0.1' if login_address in ('127.0.0.1', '0.0.0.0') else login_address
    if not allow_literal(login_host) or not allow_literal(server_ip):
        raise SystemExit('private server hosts must be loopback or private LAN literals')
    hosts = [login_host] + ([server_ip] if server_ip != login_host else [])
    return {'server_root': SERVER_ROOT, 'source': SERVER_ROOT + '/confs/publish_yu (cluster_db_conf.lua process 2, '
            'server_conf.server_ip)', 'login_host': login_host, 'login_port': login_port, 'game_port': game_port,
            'server_ip': server_ip, 'allowed_hosts': hosts}


def profile_text(endpoints, accounts):
    lines = ['VERSION 1',
             '# CY-Source server profile written by Tools/game/stage_wsl_test.py (profile cys-server).',
             '# Source: ' + endpoints['source'],
             '# Read by Game.exe (GamePro_Login.cpp, NetCore/ServerProfile.h). ASCII only.',
             '[profile]',
             'name=cys-server',
             'login=%s:%d' % (endpoints['login_host'], endpoints['login_port']),
             'game_port=%d' % endpoints['game_port'],
             'allowed_hosts=' + ','.join(endpoints['allowed_hosts'])]
    if accounts:
        lines.append('accounts=' + ','.join(accounts))
    return ('\r\n'.join(lines) + '\r\n').encode('ascii')


def load_stage(stage_arg):
    stage = Path(stage_arg).resolve()
    manifest_path = stage / 'Bin64/game_data_stage.json'
    if not manifest_path.is_file():
        raise SystemExit('not a stage_game.py stage (no Bin64/game_data_stage.json): ' + str(stage))
    data = stage / 'Data'
    if not (data.exists() and data.is_junction()):
        raise SystemExit('stage Data must be the Canonical junction; refusing')
    for name in FILES:
        p = stage / name
        if p.is_symlink() or p.is_junction() or not p.is_file():
            raise SystemExit('missing or reparsed stage file: ' + name)
    return stage, manifest_path, json.loads(manifest_path.read_text(encoding='utf-8'))


def game_running(stage):
    query = ("@(Get-Process -Name Game -ErrorAction SilentlyContinue | ForEach-Object { try { $_.Path } catch { '' } })"
             " -join ';'")
    result = subprocess.run(['powershell.exe', '-NoProfile', '-NonInteractive', '-Command', query],
                            capture_output=True, text=True, check=True)
    game = str((stage / 'Bin64/Game.exe').resolve()).lower()
    return any(p.strip().lower() == game for p in result.stdout.split(';') if p.strip())


def parse_accounts(text):
    if not text:
        return []
    accounts = [a.strip() for a in text.split(',')]
    if not all(re.fullmatch(r'[A-Za-z0-9-]{1,49}', a) for a in accounts) or len(accounts) > 32:
        raise SystemExit('--accounts: comma list of ASCII letters/digits/hyphen')
    return accounts


def cmd_endpoints(_args):
    print(json.dumps(read_server_endpoints(), ensure_ascii=False, indent=1))
    return 0


def cmd_apply(args):
    stage, manifest_path, manifest = load_stage(args.stage)
    if manifest.get('wsl_test'):
        raise SystemExit('stage is already in a server-profile state (revert first)')
    if game_running(stage):
        raise SystemExit('a Game.exe of this stage is running; no writes performed')
    profile = args.profile
    accounts = parse_accounts(args.accounts)
    if profile == 'wsl-test':
        if accounts:
            raise SystemExit('--accounts applies to the cys-server profile only')
        endpoints = {'login_host': '127.0.0.1', 'login_port': LEGACY_LOGIN_PORT, 'game_port': LEGACY_GAME_PORT,
                     'allowed_hosts': ['127.0.0.1'], 'source': 'legacy compatibility profile (Game.exe, CYS_WSL_LOGIN_TEST=1)'}
    else:
        endpoints = read_server_endpoints()
    if (stage / PROFILE_FILE).exists():
        raise SystemExit('stage already has ' + PROFILE_FILE)
    fixture = (ROOT / FIXTURE).read_bytes()
    before = {n: (stage / n).read_bytes() for n in FILES}
    after = {}
    port = str(endpoints['login_port']).encode('ascii')
    cfg = before['Bin64/WXSystem.cfg']
    exact_setting(cfg, b'GameServer_Address', b'127.0.0.1')
    exact_setting(cfg, b'GameServer_ConnectDirect', b'0')
    exact_setting(cfg, b'System_CodePage', b'65001')
    after['Bin64/WXSystem.cfg'] = swap_port(cfg, b'GameServer_Port', b'14400', port)
    if before['Patch/LoginServer.txt'] != fixture:
        raise SystemExit('Patch/LoginServer.txt is not the exact offline fixture')
    if profile == 'wsl-test':
        after['Patch/LoginServer.txt'] = wsl_login_list(fixture)
    else:
        after['Patch/LoginServer.txt'] = login_list(fixture, endpoints['login_host'], endpoints['login_port'],
                                                    'CYS Server', 'Private CY-Source server')
    legacy = before['Patch/WXLoginServer.txt']
    if len(re.findall(rb'(?m)^[ \t]*\[LOGIN[^\]\r\n]*\]', legacy)) != 1:
        raise SystemExit('expected exactly one legacy dummy server')
    exact_setting(legacy, b'IP', b'127.0.0.1')
    after['Patch/WXLoginServer.txt'] = swap_port(legacy, b'PORT', b'14400', port)
    if profile == 'wsl-test':
        launchers = {'Bin64/Run-CY-Test.cmd': RUN_CY_TEST, 'Bin64/Run-World-GUI.cmd': RUN_WORLD_GUI}
        extra = {}
    else:
        launchers = {'Bin64/Run-CY-Server.cmd': RUN_CY_SERVER.format(root=SERVER_ROOT, **endpoints)}
        extra = {PROFILE_FILE: profile_text(endpoints, accounts)}
    for name, text in launchers.items():
        text.encode('ascii')
        if (stage / name).exists():
            raise SystemExit('launcher already exists: ' + name)
    record = {'profile': profile,
              'endpoint': '%s:%d (login) / game port %d, allowed hosts %s' % (
                  endpoints['login_host'], endpoints['login_port'], endpoints['game_port'],
                  ','.join(endpoints['allowed_hosts'])),
              'server': endpoints, 'accounts': accounts,
              'tool': 'Tools/game/stage_wsl_test.py', 'tool_sha256': sha(Path(__file__).read_bytes()),
              'applied': datetime.datetime.now().astimezone().isoformat(timespec='seconds'),
              'files': [{'path': n, 'sha256_before': sha(before[n]), 'sha256_after': sha(after[n]),
                         'bytes': len(after[n])} for n in FILES],
              'created': [], 'launchers': [], 'never_written': ['Data (junction)', 'Overlay', 'Bin64/*.exe', 'Bin64/*.dll']}
    for n in FILES:
        (stage / n).write_bytes(after[n])
        if sha((stage / n).read_bytes()) != sha(after[n]):
            raise SystemExit('write verification failed: ' + n)
    for name, raw in extra.items():
        (stage / name).write_bytes(raw)
        record['created'].append({'path': name, 'sha256': sha(raw), 'bytes': len(raw)})
    for name, text in launchers.items():
        raw = text.replace('\n', '\r\n').encode('ascii')
        (stage / name).write_bytes(raw)
        record['launchers'].append({'path': name, 'sha256': sha(raw), 'bytes': len(raw)})
    manifest['wsl_test'] = record
    manifest['endpoint_current'] = record['endpoint']
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    print(json.dumps({'stage': rel(stage), 'state': profile, 'server': endpoints, 'files': record['files'],
                      'created': record['created'], 'launchers': record['launchers']}, ensure_ascii=False, indent=1))
    return 0


def cmd_revert(args):
    stage, manifest_path, manifest = load_stage(args.stage)
    record = manifest.get('wsl_test')
    if not record:
        raise SystemExit('stage is not in a server-profile state')
    if game_running(stage):
        raise SystemExit('a Game.exe of this stage is running; no writes performed')
    fixture = (ROOT / FIXTURE).read_bytes()
    port = str(record.get('server', {}).get('login_port', LEGACY_LOGIN_PORT)).encode('ascii')
    current = {n: (stage / n).read_bytes() for n in FILES}
    expected = {f['path']: f['sha256_after'] for f in record['files']}
    for n in FILES:
        if sha(current[n]) != expected[n]:
            raise SystemExit('stage file drifted since apply; not reverting: ' + n)
    for created in record.get('created', []):
        p = stage / created['path']
        if not p.is_file() or sha(p.read_bytes()) != created['sha256']:
            raise SystemExit('created file drifted since apply; not reverting: ' + created['path'])
    after = {'Bin64/WXSystem.cfg': swap_port(current['Bin64/WXSystem.cfg'], b'GameServer_Port', port, b'14400'),
             'Patch/LoginServer.txt': fixture,
             'Patch/WXLoginServer.txt': swap_port(current['Patch/WXLoginServer.txt'], b'PORT', port, b'14400')}
    before_hash = {f['path']: f['sha256_before'] for f in record['files']}
    for n in FILES:
        if sha(after[n]) != before_hash[n]:
            raise SystemExit('inverse transform does not reproduce the offline bytes: ' + n)
    for n in FILES:
        (stage / n).write_bytes(after[n])
    for created in record.get('created', []):
        (stage / created['path']).unlink()
    for launcher in record['launchers']:
        p = stage / launcher['path']
        if p.is_file() and sha(p.read_bytes()) == launcher['sha256']:
            p.unlink()
    record['reverted'] = datetime.datetime.now().astimezone().isoformat(timespec='seconds')
    manifest.setdefault('wsl_test_history', []).append(record)
    del manifest['wsl_test']
    manifest['endpoint_current'] = manifest.get('endpoint')
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    print(json.dumps({'stage': rel(stage), 'state': 'offline'}, ensure_ascii=False))
    return 0


def play_account_filter_problem(profile_text):
    """A delivered play stage must not retain one measurement account's filter."""
    rows = re.findall(r'(?m)^[ \t]*accounts[ \t]*=([^\r\n]*)', profile_text)
    if not rows:
        return ''  # The native parser allows all accounts when this optional key is absent.
    if len(rows) != 1:
        return 'play-stage profile has duplicate account filters'
    allowed = set(parse_accounts(rows[0]))
    missing = ['test%02d' % i for i in range(16) if 'test%02d' % i not in allowed]
    return 'play-stage account filter excludes ' + ','.join(missing) if missing else ''


def cmd_check(args):
    stage, _, manifest = load_stage(args.stage)
    record = manifest.get('wsl_test')
    state = record.get('profile', 'wsl-test') if record else 'offline'
    problems = []
    server_now = None
    if record:
        expected = {f['path']: f['sha256_after'] for f in record['files']}
        port = str(record.get('server', {}).get('login_port', LEGACY_LOGIN_PORT)).encode('ascii')
        cfg = (stage / 'Bin64/WXSystem.cfg').read_bytes()
        try:
            exact_setting(cfg, b'GameServer_Port', port)
        except SystemExit as e:
            problems.append(str(e))
        for item in record['launchers'] + record.get('created', []):
            p = stage / item['path']
            if not p.is_file() or sha(p.read_bytes()) != item['sha256']:
                problems.append('launcher/profile drifted or missing: ' + item['path'])
        if state == 'cys-server' and stage.name.startswith('stage-play-') and (stage / PROFILE_FILE).is_file():
            problem = play_account_filter_problem((stage / PROFILE_FILE).read_text(encoding='ascii'))
            if problem:
                problems.append(problem)
        if state == 'cys-server' and not args.no_server:
            try:
                server_now = read_server_endpoints()
            except SystemExit as e:
                problems.append('server configuration unreadable: ' + str(e))
            else:
                for key in ('login_host', 'login_port', 'game_port', 'allowed_hosts'):
                    if server_now[key] != record['server'][key]:
                        problems.append('server configuration changed since apply: ' + key)
        if state != 'cys-server' and (stage / PROFILE_FILE).exists():
            problems.append('unexpected ' + PROFILE_FILE + ' for profile ' + state)
    else:
        expected = {'Bin64/WXSystem.cfg': manifest['configs']['WXSystem.cfg'],
                    'Patch/LoginServer.txt': manifest['patch']['LoginServer.txt'],
                    'Patch/WXLoginServer.txt': manifest['patch']['WXLoginServer.txt']}
        if (stage / PROFILE_FILE).exists():
            problems.append('offline stage must not carry ' + PROFILE_FILE)
    for n in FILES:
        if sha((stage / n).read_bytes()) != expected[n]:
            problems.append('drifted: ' + n)
    binaries = [b for b in manifest['binaries'] if sha((stage / 'Bin64' / b['name']).read_bytes()) != b['sha256']]
    for b in binaries:
        problems.append('binary drifted: ' + b['name'])
    print(json.dumps({'stage': rel(stage), 'state': state, 'game_exe_sha256': next(
        b['sha256'] for b in manifest['binaries'] if b['name'].lower() == 'game.exe'),
        'binaries_checked': len(manifest['binaries']), 'server_now': server_now, 'problems': problems},
        ensure_ascii=False, indent=1))
    return 1 if problems else 0


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest='cmd', required=True)
    for name in ('apply', 'revert', 'check'):
        s = sub.add_parser(name)
        s.add_argument('--stage', required=True)
        s.add_argument('--root', help='CY-Source tree holding the offline login fixture (default: this tree)')
        if name == 'apply':
            s.add_argument('--profile', choices=('cys-server', 'wsl-test'), default='cys-server')
            s.add_argument('--accounts', default='', help='optional account filter written to the profile')
        if name == 'check':
            s.add_argument('--no-server', action='store_true', help='skip re-reading the server configuration')
    sub.add_parser('endpoints')
    args = parser.parse_args()
    if getattr(args, 'root', None):
        global ROOT
        ROOT = Path(args.root).resolve()
    return {'apply': cmd_apply, 'revert': cmd_revert, 'check': cmd_check, 'endpoints': cmd_endpoints}[args.cmd](args)


if __name__ == '__main__':
    sys.exit(main())
