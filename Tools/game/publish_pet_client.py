"""Publish tested Pet client to private Play21; caller must hold the game slot.

Four feature runs must match the exact Game/manifest. Preserve all other DLLs,
settings and previous release metadata; back up every modified file first.
"""
import argparse
import datetime
import json
from pathlib import Path
import shutil
import subprocess
from publish_inventory_client import ROOT, sha


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    markers = {
        'negative': 'CYS-PET-MECHANICS NEGATIVE PASS missing target GUID detected',
        'normal': 'CYS-PET-MECHANICS PASS book duplicate upgrade points possession separation savvy lingxing summon recall',
        'relogin': 'CYS-PET-MECHANICS PASS relogin',
        'awakening': 'CYS-PET-MECHANICS PASS awakening replay normal_lingxing quick_skill UI_tables',
    }
    for name in markers:
        parser.add_argument('--' + name, type=Path, required=True)
    args = parser.parse_args()
    test = ROOT / 'Build/world-gui/stage-equipment-skills-23/Bin64'
    play = ROOT / 'Build/world-gui/stage-play-21/Bin64'
    build = ROOT / 'Build/cmake/coord-x64/bin'
    evidence = {}
    for name, marker in markers.items():
        folder = getattr(args, name)
        report = json.loads((folder / 'run.json').read_text(encoding='utf-8-sig'))
        log = (folder / 'WXClient.log').read_text(encoding='utf8', errors='replace')
        assert report['passed'] and report['account'] == 'test15', name
        assert report['game_sha256'] == sha(test / 'Game.exe'), name
        assert report['stage_manifest_sha256'] == sha(test / 'game_data_stage.json'), name
        assert marker in log and 'CYS Lua failure' not in log, name
        assert 'CYS-PET-MECHANICS FAIL' not in log and 'CYS-CRASHRPT' not in log, name
        if name == 'negative':
            assert 'BEGIN mode=1 slot=0 legacy=1' in log
        elif name == 'normal':
            assert 'BEGIN mode=1 slot=0 legacy=0' in log
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
    backup = ROOT / 'Build/backups/pet-play' / stamp
    backup.mkdir(parents=True, exist_ok=False)
    names = ('Game.exe', 'Game.pdb')
    launcher = play / 'Run-CY-Server.cmd'
    raw = launcher.read_bytes()
    anchor = b'set "CYS_WORLD_REPLAY="'
    assert raw.count(anchor) == 1
    for flag in ('CYS_PET_MECHANICS_LIVE', 'CYS_PET_ITEM_LEGACY'):
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
    current['pet_integrity_update'] = evidence
    manifest.write_text(json.dumps(current, ensure_ascii=False, indent=1) + '\n', encoding='utf8', newline='\n')
    for row in current['binaries']:
        assert sha(play / row['name']) == row['sha256']
    (backup / 'deployment.json').write_text(json.dumps(evidence, ensure_ascii=False, indent=2), encoding='utf8')
    print(json.dumps(evidence, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
