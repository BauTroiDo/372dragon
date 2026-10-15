"""Stage or publish the verified shared UI wheel fix, preserving all Play overlays."""
from pathlib import Path
import argparse, datetime, json, shutil, subprocess
from publish_gameplay_fixes import ROOT, NAMES, sha

STAGE=ROOT/'Build/world-gui/stage-ui-wheel-23'
PLAY=ROOT/'Build/world-gui/stage-play-21'
BUILD=ROOT/'Build/cmake/coord-x64/bin'

def idle():
    assert subprocess.run(['powershell','-NoProfile','-Command','[bool](Get-Process Game -ErrorAction SilentlyContinue)'],capture_output=True,text=True,check=True).stdout.strip()=='False', 'Game is running'

def binaries(base, manifest):
    for row in manifest['binaries']:
        assert sha(base/'Bin64'/row['name'])==row['sha256'], row['name']

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('mode',choices=['stage','check','publish']);p.add_argument('--check',type=Path)
    a=p.parse_args()
    if a.mode=='stage':
        idle()
        if not STAGE.exists():
            STAGE.mkdir()
            for name in ['Bin64','Patch','Overlay']:shutil.copytree(PLAY/name,STAGE/name)
            shutil.copy2(PLAY/'Play.cmd',STAGE/'Play.cmd')
            subprocess.run(['powershell','-NoProfile','-Command',f"New-Item -ItemType Junction -Path '{STAGE/'Data'}' -Target '{ROOT/'Assets/CanonicalCY/Data'}' | Out-Null"],check=True)
        m=json.loads((STAGE/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
        for row in m['binaries']:
            if row['name'] in NAMES:
                dest=STAGE/'Bin64'/row['name'];shutil.copy2(BUILD/row['name'],dest)
                row.update(sha256=sha(dest),bytes=dest.stat().st_size)
        m['ui_wheel_candidate']={'shared_input':True,'complex_window':True,'chat_history':True}
        (STAGE/'Bin64/game_data_stage.json').write_text(json.dumps(m,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
        binaries(STAGE,m)
        print('Staged:',STAGE,'Game:',sha(STAGE/'Bin64/Game.exe'))
        return
    assert a.check
    run=json.loads((a.check/'run.json').read_text(encoding='utf-8-sig'))
    log=(a.check/'WXClient.log').read_text(encoding='utf8',errors='replace')
    assert run['passed'] and run['game_sha256']==sha(STAGE/'Bin64/Game.exe')
    assert run['stage_manifest_sha256']==sha(STAGE/'Bin64/game_data_stage.json')
    assert 'CYS-UI-WHEEL: RESULT menus=6 errors=0' in log
    for bad in ['CYS-UI-WHEEL: FAIL','CYS-UI-WHEEL: RESULT errors=1','CYS Lua failure']:assert bad not in log,bad
    current=json.loads((PLAY/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
    tested=json.loads((STAGE/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
    binaries(PLAY,current);binaries(STAGE,tested)
    before={r['name']:r['sha256'] for r in current['binaries']}
    after={r['name']:r['sha256'] for r in tested['binaries']}
    assert before.keys()==after.keys()
    assert all(before[n]==after[n] for n in before if n not in NAMES)
    assert all(sha(BUILD/n)==after[n] for n in NAMES)
    # This fix ships code only. Any overlay difference is unexpected.
    for folder in ['Overlay','Patch']:
        for f in (STAGE/folder).rglob('*'):
            if f.is_file():assert sha(f)==sha(PLAY/f.relative_to(STAGE)),f
    if a.mode=='check':print('PASS: six menu families, shared input, camera, Escape, movement and exact binaries');return
    idle()
    stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    backup=ROOT/'Build/backups/ui-wheel-play'/stamp;backup.mkdir(parents=True)
    for name in NAMES+('game_data_stage.json','Run-CY-Server.cmd'):shutil.copy2(PLAY/'Bin64'/name,backup/name)
    for row in current['binaries']:
        if row['name'] in NAMES:
            dest=PLAY/'Bin64'/row['name'];shutil.copy2(STAGE/'Bin64'/row['name'],dest)
            row.update(sha256=sha(dest),bytes=dest.stat().st_size)
    launcher=PLAY/'Bin64/Run-CY-Server.cmd';raw=launcher.read_bytes()
    anchor=b'set "CYS_WORLD_REPLAY="';line=b'set "CYS_UI_WHEEL_LIVE="'
    assert raw.count(anchor)==1
    if line not in raw:raw=raw.replace(anchor,anchor+b'\r\n'+line)
    launcher.write_bytes(raw)
    for row in current['wsl_test']['launchers']:
        if row['path']=='Bin64/Run-CY-Server.cmd':row.update(sha256=sha(launcher),bytes=launcher.stat().st_size)
    evidence=dict(at=stamp,check=str(a.check.resolve()),backup=str(backup),before=before,after=after)
    current['ui_wheel_update']=evidence
    (PLAY/'Bin64/game_data_stage.json').write_text(json.dumps(current,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
    (backup/'deployment.json').write_text(json.dumps(evidence,indent=2)+'\n',encoding='utf8')
    binaries(PLAY,current)
    print('Published:',PLAY,'backup:',backup)

if __name__=='__main__':main()
