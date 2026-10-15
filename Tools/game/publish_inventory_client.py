"""Publish the inventory build to private Play21 only after feature-specific live gates.

Keeps existing profile/settings; copies only the tested Game and its symbols.
Caller must hold the game slot. All live runs must use this exact staged binary.
"""
import argparse
import datetime
import hashlib
import json
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[2]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('negative', 'expanded', 'relogin', 'shop'):
        parser.add_argument('--' + name, type=Path, required=True)
    args = parser.parse_args()
    test = ROOT / 'Build/world-gui/stage-equipment-skills-23/Bin64'
    play = ROOT / 'Build/world-gui/stage-play-21/Bin64'
    build = ROOT / 'Build/cmake/coord-x64/bin'
    markers = {
        'negative': 'CYS-INVENTORY-LIVE NEGATIVE PASS missing pack transport detected',
        'expanded': 'CYS-INVENTORY-LIVE PASS expanded/shrink/sort/split/invalid packets',
        'relogin': 'CYS-INVENTORY-LIVE PASS relogin expanded inventory',
        'shop': 'CYS-BAG-PROBE: RESULT errors=0',
    }
    evidence = {}
    for name, marker in markers.items():
        folder = getattr(args, name)
        report = json.loads((folder / 'run.json').read_text(encoding='utf-8-sig'))
        log = (folder / 'WXClient.log').read_text(encoding='utf8', errors='replace')
        assert report['passed'] and report['account'] == 'test15', name
        assert report['game_sha256'] == sha(test / 'Game.exe'), name
        assert report['stage_manifest_sha256'] == sha(test / 'game_data_stage.json'), name
        assert marker in log and 'CYS Lua failure' not in log, name
        assert 'CYS-INVENTORY-LIVE FAIL' not in log and 'CYS-BAG-PROBE: INVALID' not in log, name
        if name == 'shop':
            # The stack snapshot is reached only after the probe asserts qty=2
            # and exactly one new server reply; the sale has its own marker.
            assert 'SNAP phase=bought-stack' in log and 'quantity=0 replies=1' in log
        evidence[name] = dict(path=str(folder), started=report['started'], finished=report['finished'])
    result = subprocess.run(['powershell', '-NoProfile', '-Command',
                             '[bool](Get-Process Game -ErrorAction SilentlyContinue)'],
                            capture_output=True, text=True, check=True)
    assert result.stdout.strip() == 'False', 'Game must be closed'
    manifest = play / 'game_data_stage.json'
    current = json.loads(manifest.read_text(encoding='utf8'))
    tested = json.loads((test / 'game_data_stage.json').read_text(encoding='utf8'))
    for base, data in ((play, current), (test, tested)):
        for row in data['binaries']:
            assert sha(base / row['name']) == row['sha256'], row['name']
    runtimes = lambda data: {r['name']: r['sha256'] for r in data['binaries']
                             if r['name'].lower().endswith(('.dll', '.exe'))}
    before, after = runtimes(current), runtimes(tested)
    assert set(before) == set(after)
    assert all(before[k] == after[k] for k in before if k != 'Game.exe'), 'unexpected DLL change'
    assert sha(build / 'Game.exe') == after['Game.exe']
    stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    backup = ROOT / 'Build/backups/inventory-play' / stamp
    backup.mkdir(parents=True, exist_ok=False)
    names = ('Game.exe', 'Game.pdb')
    launcher = play / 'Run-CY-Server.cmd'
    raw = launcher.read_bytes()
    anchor = b'set "CYS_WORLD_REPLAY="'
    assert raw.count(anchor) == 1
    for flag in ('CYS_INVENTORY_INTEGRITY_LIVE', 'CYS_BAG_PACK_OLD'):
        line = ('set "' + flag + '="').encode('ascii')
        if line not in raw:
            raw = raw.replace(anchor, anchor + b'\r\n' + line)
    for name in names + ('game_data_stage.json', 'Run-CY-Server.cmd'):
        shutil.copy2(play / name, backup / name)
    records = []
    for row in current['binaries']:
        if row['name'] in names:
            path = play / row['name']
            old = sha(path)
            shutil.copy2(build / row['name'], path)
            row.update(sha256=sha(path), bytes=path.stat().st_size)
            records.append(dict(path=row['name'], before=old, after=row['sha256']))
    launcher.write_bytes(raw)
    for row in current['wsl_test']['launchers']:
        if row['path'] == 'Bin64/Run-CY-Server.cmd':
            row.update(sha256=sha(launcher), bytes=launcher.stat().st_size)
    evidence.update(at=stamp, backup=str(backup), files=records)
    current['inventory_integrity_update'] = evidence
    manifest.write_text(json.dumps(current, ensure_ascii=False, indent=1) + '\n', encoding='utf8', newline='\n')
    for row in current['binaries']:
        assert sha(play / row['name']) == row['sha256']
    (backup / 'deployment.json').write_text(json.dumps(evidence, ensure_ascii=False, indent=2), encoding='utf8')
    print(json.dumps(evidence, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
