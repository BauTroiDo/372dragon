#!/usr/bin/env python3
"""Private offline stage for the Game.exe login-screen A/B smoke of the world-session work.

`prepare` works on a PRIVATE copy of a WSL-test GL stage (copied beforehand; the source stage is never touched):
it inverts exactly the --wsl-test endpoint transform of Tools/data/prepare_gl_login_profile.py (WXSystem.cfg port,
Patch/LoginServer.txt back to the offline fixture, Patch/WXLoginServer.txt port), re-records those three hashes in
gl_login_profile.json and copies the stage's own 'ours' binaries into a private CiBin under Build/cmake (variant A).
`use-game` puts another Game.exe into the same private stage, updates the manifest entry and builds CiBin B.
Metadata only in the records (paths, sizes, hashes); no credentials exist in any touched file.
"""
import argparse
import hashlib
import json
import re
import shutil
from pathlib import Path

CY = Path(__file__).resolve().parents[2]


def sha(data):
    return hashlib.sha256(data).hexdigest()


def inside(path, base):
    full = (CY / path).resolve()
    if not full.is_relative_to(CY / base):
        raise SystemExit('path must stay below CY-Source/' + base)
    for part in [full, *full.parents]:
        if part.exists() and (part.is_symlink() or part.is_junction()):
            raise SystemExit('path must not traverse a junction')
    return full


def one_setting(data, name, old, new):
    pattern = rb'(?m)^([ \t]*' + re.escape(name) + rb'[ \t]*=[ \t]*)' + old + rb'([ \t]*\r?$)'
    after, count = re.subn(pattern, rb'\g<1>' + new + rb'\g<2>', data)
    if count != 1:
        raise SystemExit('expected exactly one %s = %s' % (name.decode(), old.decode()))
    return after


def write_record(path, record):
    if path.exists():
        raise SystemExit('record exists; choose a new name')
    path.write_text(json.dumps(record, indent=2) + '\n', encoding='utf-8')


def prepare(args):
    stage, record_path = inside(args.stage, 'Build/world-smoke'), inside(args.record, 'Build/Logs')
    cibin = inside(args.cibin, 'Build/cmake')
    bin64 = stage / 'Bin64'
    profile_path = bin64 / 'gl_login_profile.json'
    profile = json.loads(profile_path.read_text(encoding='utf-8'))
    if profile.get('applied') is not True or profile.get('endpoint') != '127.0.0.1:15733':
        raise SystemExit('expected an applied WSL-test GL profile')
    records = {entry['path']: entry for entry in profile['files']}
    restored = None
    if args.pristine_cfg:
        # A client run from the source stage rewrites WXSystem.cfg (remembered login area/server/mail index).
        # Restore the profile-applied bytes from another stage built by the same tool, proven by the recorded hash.
        pristine = inside(args.pristine_cfg, 'Build').read_bytes()
        current = (bin64 / 'WXSystem.cfg').read_bytes()
        if sha(pristine) != records['Bin64/WXSystem.cfg']['sha256'].lower():
            raise SystemExit('pristine WXSystem.cfg does not match the recorded profile hash')
        (bin64 / 'WXSystem.cfg').write_bytes(pristine)
        restored = {'from': args.pristine_cfg, 'replaced_sha256': sha(current), 'restored_sha256': sha(pristine)}
    fixture = (CY / 'Tests/ui/fixtures/login-server-utf8.txt').read_bytes()
    forward = fixture.replace(b'127.0.0.1:14400', b'127.0.0.1:15733').replace(b'CYS offline', b'CYS WSL Test')
    forward = forward.replace(b'offline (no server)', b'Independent WSL test')
    plan = []
    for relative, transform in (
            ('Bin64/WXSystem.cfg', lambda b: one_setting(b, b'GameServer_Port', b'15733', b'14400')),
            ('Patch/LoginServer.txt', lambda b: fixture if b == forward else None),
            ('Patch/WXLoginServer.txt', lambda b: one_setting(b, b'PORT', b'15733', b'14400'))):
        before = (stage / relative).read_bytes()
        after = transform(before)
        if after is None:
            raise SystemExit(relative + ' is not the WSL transform of the offline fixture')
        entry = records.get(relative)
        if entry is None or entry['sha256'].lower() != sha(before):
            raise SystemExit('profile record differs before inversion: ' + relative)
        plan.append((relative, before, after))
    changes = []
    for relative, before, after in plan:
        (stage / relative).write_bytes(after)
        entry = records[relative]
        entry['bytes'], entry['sha256'] = len(after), sha(after)
        entry['origin'] = 'cys-world: inverse of the WSL-test transform (offline 127.0.0.1:14400)'
        changes.append({'path': relative, 'before_sha256': sha(before), 'after_sha256': sha(after)})
    profile['endpoint'] = '127.0.0.1:14400'
    profile_path.write_text(json.dumps(profile, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    manifest = json.loads((bin64 / 'offline_stage.json').read_text(encoding='utf-8'))
    cibin.mkdir(parents=True, exist_ok=False)
    ours = []
    for entry in manifest['files']:
        if entry['kind'] != 'ours' or entry['name'] in ours:
            continue
        source = bin64 / entry['name']
        if sha(source.read_bytes()) != entry['sha256'].lower():
            raise SystemExit('stage binary differs from its manifest: ' + entry['name'])
        shutil.copy2(source, cibin / entry['name'])
        ours.append(entry['name'])
    write_record(record_path, {'stage': str(stage.relative_to(CY)), 'stage_sha': manifest.get('sha'),
                               'restored_cfg': restored, 'inverted': changes, 'profile_endpoint': profile['endpoint'],
                               'cibin': str(cibin.relative_to(CY)), 'ours': ours})
    print('PREPARED offline stage', stage.relative_to(CY), 'cibin', cibin.relative_to(CY), 'ours', len(ours))


def use_game(args):
    stage, record_path = inside(args.stage, 'Build/world-smoke'), inside(args.record, 'Build/Logs')
    exe, base = inside(args.exe, 'Build'), inside(args.base_cibin, 'Build/cmake')
    cibin = inside(args.cibin, 'Build/cmake')
    bin64 = stage / 'Bin64'
    manifest_path = bin64 / 'offline_stage.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    game = [entry for entry in manifest['files'] if entry['name'] == 'Game.exe' and entry['kind'] == 'ours']
    if len(game) != 1:
        raise SystemExit('manifest needs exactly one Game.exe')
    data = exe.read_bytes()
    if data[:2] != b'MZ':
        raise SystemExit('not a PE executable')
    cibin.mkdir(parents=True, exist_ok=False)
    for source in base.iterdir():
        if source.is_file() and source.name != 'Game.exe':
            shutil.copy2(source, cibin / source.name)
    shutil.copy2(exe, cibin / 'Game.exe')
    previous = dict(game[0])
    shutil.copy2(exe, bin64 / 'Game.exe')
    game[0].update({'source': str(exe), 'bytes': len(data), 'sha256': sha(data),
                    'ci_target': 'cys-world pin build (HEAD + world-agent files)'})
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    write_record(record_path, {'stage': str(stage.relative_to(CY)), 'game_before': previous,
                               'game_after': game[0], 'cibin': str(cibin.relative_to(CY))})
    print('GAME', sha(data)[:16], 'in', stage.relative_to(CY), 'cibin', cibin.relative_to(CY))


def private_stage(relative):
    stage = inside(relative, 'Build')
    for source in ('Build/gpt-p1-1-20260913', 'Build/cmake'):
        root = (CY / source).resolve()
        if stage == root or root in stage.parents:
            raise SystemExit('refusing to modify a source stage or build tree: ' + source)
    if not (stage / 'Bin64' / 'offline_stage.json').is_file():
        raise SystemExit('not a staged client (Bin64/offline_stage.json missing)')
    return stage


def use_set(args):
    """Replace EVERY 'ours' binary of a private stage with one consistent build set (e.g. the pin snapshot)."""
    stage, record_path = private_stage(args.stage), inside(args.record, 'Build/Logs')
    source, cibin = inside(args.bin_dir, 'Build'), inside(args.cibin, 'Build/cmake')
    bin64 = stage / 'Bin64'
    restored = None
    if args.pristine_cfg:
        profile = json.loads((bin64 / 'gl_login_profile.json').read_text(encoding='utf-8'))
        wanted = {entry['path']: entry['sha256'].lower() for entry in profile['files']}.get('Bin64/WXSystem.cfg')
        pristine = inside(args.pristine_cfg, 'Build').read_bytes()
        if wanted is None or sha(pristine) != wanted:
            raise SystemExit('pristine WXSystem.cfg does not match the recorded profile hash')
        current = (bin64 / 'WXSystem.cfg').read_bytes()
        (bin64 / 'WXSystem.cfg').write_bytes(pristine)
        restored = {'from': args.pristine_cfg, 'replaced_sha256': sha(current), 'restored_sha256': sha(pristine)}
    manifest_path = bin64 / 'offline_stage.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    plan, seen = [], set()
    for entry in manifest['files']:
        if entry['kind'] != 'ours' or entry['name'] in seen:
            continue
        seen.add(entry['name'])
        candidate = source / entry['name']
        if not candidate.is_file():
            raise SystemExit('binary set lacks ' + entry['name'])
        plan.append((entry, candidate.read_bytes()))
    cibin.mkdir(parents=True, exist_ok=False)
    changes = []
    for entry, data in plan:
        before = entry['sha256'].lower()
        (bin64 / entry['name']).write_bytes(data)
        (cibin / entry['name']).write_bytes(data)
        entry.update({'source': str(source / entry['name']), 'bytes': len(data), 'sha256': sha(data),
                      'ci_target': 'cys-world pin snapshot set'})
        changes.append({'name': entry['name'], 'before_sha256': before, 'after_sha256': sha(data)})
    manifest['cys_world_binary_set'] = str(source.relative_to(CY))
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    write_record(record_path, {'stage': str(stage.relative_to(CY)), 'binary_set': str(source.relative_to(CY)),
                               'cibin': str(cibin.relative_to(CY)), 'restored_cfg': restored, 'binaries': changes})
    print('SET', len(changes), 'binaries into', stage.relative_to(CY), 'cibin', cibin.relative_to(CY))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    first = commands.add_parser('prepare')
    first.add_argument('--stage', required=True)
    first.add_argument('--cibin', required=True)
    first.add_argument('--record', required=True)
    first.add_argument('--pristine-cfg', default='', help='Profile-applied WXSystem.cfg proven by the recorded hash')
    second = commands.add_parser('use-game')
    second.add_argument('--stage', required=True)
    second.add_argument('--exe', required=True)
    second.add_argument('--base-cibin', required=True)
    second.add_argument('--cibin', required=True)
    second.add_argument('--record', required=True)
    third = commands.add_parser('use-set')
    third.add_argument('--stage', required=True, help='Private stage below Build (never a source stage)')
    third.add_argument('--bin-dir', required=True, help='Folder with Game.exe and every ours DLL of one build')
    third.add_argument('--cibin', required=True)
    third.add_argument('--record', required=True)
    third.add_argument('--pristine-cfg', default='', help='Profile-applied WXSystem.cfg proven by the recorded hash')
    args = parser.parse_args()
    {'prepare': prepare, 'use-game': use_game, 'use-set': use_set}[args.command](args)


if __name__ == '__main__':
    main()
