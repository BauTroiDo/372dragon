"""Publish the tested seven gameplay fixes to Play21, preserving the player's profile."""
from pathlib import Path
import argparse, datetime, hashlib, json, re, shutil, subprocess

ROOT = Path(__file__).resolve().parents[2]
NAMES = ('Game.exe', 'Game.pdb', 'UI_CEGUI.dll', 'UI_CEGUI.pdb', 'CEGUIFalagard.dll', 'CEGUIFalagard.pdb')
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--checks', nargs='+', type=Path, required=True)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    test = ROOT / 'Build/world-gui/stage-gameplay-fixes-23/Bin64'
    play = ROOT / 'Build/world-gui/stage-play-21/Bin64'
    build = ROOT / 'Build/cmake/coord-x64/bin'
    modes, wardrobe = set(), False
    for folder in args.checks:
        run = json.loads((folder / 'run.json').read_text(encoding='utf-8-sig'))
        log = (folder / 'WXClient.log').read_text(encoding='utf8', errors='replace')
        assert run['passed'] and run['game_sha256'] == sha(test / 'Game.exe'), folder
        assert run['stage_manifest_sha256'] == sha(test / 'game_data_stage.json'), folder
        results = re.findall(r'CYS-GAMEPLAY-CHECK: RESULT mode=(\d+) errors=0\b', log)
        assert results and 'pass=0' not in '\n'.join(x for x in log.splitlines() if 'CYS-GAMEPLAY-CHECK:' in x), folder
        run_modes = {int(mode) for mode in results};modes.update(run_modes)
        assert 'CYS Lua failure' not in log, folder
        if 1 in run_modes:
            assert len(re.findall(r'CYS-GAMEPLAY-CHECK: tab=\d+ expected=[1-5] visible=[1-5]',log)) == 8
            assert re.search(r'CYS-WARDROBE-PROBE: RESULT errors=0\b',log), folder
            wardrobe = True
        if 3 in run_modes:
            assert 'phase=2' in log and 'CYS-QINGGONG: landing-complete' in log
    assert modes == {1,2,3} and wardrobe
    manifest = play / 'game_data_stage.json'
    current = json.loads(manifest.read_text(encoding='utf8'))
    tested = json.loads((test / 'game_data_stage.json').read_text(encoding='utf8'))
    for base,data in ((play,current),(test,tested)):
        for row in data['binaries']:
            assert sha(base / row['name']) == row['sha256'], row['name']
    original = {r['name']:r['sha256'] for r in current['binaries']}
    candidate = {r['name']:r['sha256'] for r in tested['binaries']}
    assert original.keys() == candidate.keys()
    assert all(original[n] == candidate[n] for n in original if n not in NAMES)
    assert all(sha(build / n) == candidate[n] for n in NAMES)
    if not args.apply:
        print('PASS publication gates: three gameplay runs, eight skill tabs, wardrobe and landing animation')
        return
    proc = subprocess.run(['powershell','-NoProfile','-Command','[bool](Get-Process Game -ErrorAction SilentlyContinue)'], capture_output=True,text=True,check=True)
    assert proc.stdout.strip() == 'False', 'close Game before publication'
    stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    backup = ROOT / 'Build/backups/gameplay-fixes-play' / stamp
    backup.mkdir(parents=True, exist_ok=False)
    launcher = play / 'Run-CY-Server.cmd'
    raw = launcher.read_bytes();anchor = b'set "CYS_WORLD_REPLAY="'
    assert raw.count(anchor) == 1
    for flag in ('CYS_GAMEPLAY_FIX_LIVE','CYS_WARDROBE_LIVE','CYS_QINGGONG_LOG'):
        line = ('set "'+flag+'="').encode('ascii')
        if line not in raw: raw = raw.replace(anchor,anchor+b'\r\n'+line)
    for name in NAMES+('game_data_stage.json','Run-CY-Server.cmd'):
        shutil.copy2(play / name, backup / name)
    for row in current['binaries']:
        if row['name'] in NAMES:
            dst = play / row['name'];shutil.copy2(test / row['name'], dst)
            row.update(sha256=sha(dst),bytes=dst.stat().st_size)
    launcher.write_bytes(raw)
    for row in current['wsl_test']['launchers']:
        if row['path']=='Bin64/Run-CY-Server.cmd': row.update(sha256=sha(launcher),bytes=launcher.stat().st_size)
    evidence=dict(at=stamp,checks=[str(p.resolve()) for p in args.checks],backup=str(backup),before=original,after=candidate)
    current['gameplay_fixes_update']=evidence
    manifest.write_text(json.dumps(current,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
    for row in current['binaries']: assert sha(play / row['name'])==row['sha256']
    (backup / 'deployment.json').write_text(json.dumps(evidence,ensure_ascii=False,indent=2),encoding='utf8')
    print('Published to',play,'; backup:',backup)


if __name__=='__main__': main()
