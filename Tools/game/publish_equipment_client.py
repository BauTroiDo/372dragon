"""Publish the verified equipment build to private Play21, retaining its profile.

Requires both a passing equipment GUI run and a passing residual-contract run
of the current binary. Never copies test-only account settings into Play21.
"""
from pathlib import Path
import argparse
import datetime
import hashlib
import json
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[2]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--live', type=Path, required=True)
    parser.add_argument('--contracts', type=Path, required=True)
    args = parser.parse_args()
    test = ROOT / 'Build/world-gui/stage-equipment-skills-23/Bin64'
    play = ROOT / 'Build/world-gui/stage-play-21/Bin64'
    build = ROOT / 'Build/cmake/coord-x64/bin'
    for folder, expected in ((args.live, 'UI and Dark PASS'), (args.contracts, 'residual contracts PASS')):
        report = json.loads((folder / 'run.json').read_text(encoding='utf-8-sig'))
        log = (folder / 'WXClient.log').read_text(encoding='utf8', errors='replace')
        assert report['passed'] and report['game_sha256'] == sha(test / 'Game.exe')
        assert report['stage_manifest_sha256'] == sha(test / 'game_data_stage.json')
        assert 'CYS equipment-live ' + expected in log
        assert 'CYS equipment-live FAIL' not in log and 'CYS Lua failure' not in log
        assert not any('CYS equipment-live step=' in line and 'lua=0' in line for line in log.splitlines())
    proc = subprocess.run(['powershell', '-NoProfile', '-Command',
                           '[bool](Get-Process Game -ErrorAction SilentlyContinue)'],
                          capture_output=True, text=True, check=True)
    assert proc.stdout.strip() == 'False', 'Game must be closed'
    manifest = play / 'game_data_stage.json'
    current = json.loads(manifest.read_text(encoding='utf8'))
    tested = json.loads((test / 'game_data_stage.json').read_text(encoding='utf8'))
    for base, data in ((play, current), (test, tested)):
        for row in data['binaries']:
            assert sha(base / row['name']) == row['sha256'], row['name']
    runtime = lambda data: {r['name']: r['sha256'] for r in data['binaries'] if r['name'].lower().endswith(('.dll', '.exe'))}
    before, after = runtime(current), runtime(tested)
    assert set(before) == set(after)
    assert all(before[k] == after[k] for k in before if k not in ('Game.exe', 'UI_CEGUI.dll'))
    for name in ('Game.exe', 'UI_CEGUI.dll'):
        assert sha(build / name) == after[name]
    stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    backup = ROOT / 'Build/backups/residual-play' / stamp
    backup.mkdir(parents=True, exist_ok=False)
    names = ('Game.exe', 'Game.pdb', 'UI_CEGUI.dll', 'UI_CEGUI.pdb')
    launcher = play / 'Run-CY-Server.cmd'
    raw = launcher.read_bytes()
    anchor = b'set "CYS_WORLD_REPLAY="'
    assert raw.count(anchor) == 1
    for flag in ('CYS_EQUIPMENT_SKILLS_LIVE', 'CYS_PET_LIST_LEGACY'):
        line = ('set "' + flag + '="').encode('ascii')
        if line not in raw:
            raw = raw.replace(anchor, anchor + b'\r\n' + line)
    for name in names + ('game_data_stage.json', 'Run-CY-Server.cmd'):
        shutil.copy2(play / name, backup / name)
    records = []
    for row in current['binaries']:
        if row['name'] not in names:
            continue
        path = play / row['name']
        old = sha(path)
        shutil.copy2(build / row['name'], path)
        row.update(sha256=sha(path), bytes=path.stat().st_size)
        records.append(dict(path=row['name'], before=old, after=row['sha256']))
    launcher.write_bytes(raw)
    for row in current['wsl_test']['launchers']:
        if row['path'] == 'Bin64/Run-CY-Server.cmd':
            row.update(sha256=sha(launcher), bytes=launcher.stat().st_size)
    evidence = dict(at=stamp, live=str(args.live), contracts=str(args.contracts), backup=str(backup), files=records)
    current['residual_audit_update'] = evidence
    manifest.write_text(json.dumps(current, ensure_ascii=False, indent=1) + '\n', encoding='utf8', newline='\n')
    for row in current['binaries']:
        assert sha(play / row['name']) == row['sha256']
    (backup / 'deployment.json').write_text(json.dumps(evidence, ensure_ascii=False, indent=2), encoding='utf8')
    print(json.dumps(evidence, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
