"""Stage or publish the verified CY mount high flight, preserving all Play overlays."""
from pathlib import Path
import argparse, datetime, json, shutil, subprocess
from publish_gameplay_fixes import ROOT, NAMES, sha

STAGE=ROOT/'Build/world-gui/stage-mount-flight-24'
PLAY=ROOT/'Build/world-gui/stage-play-21'
BUILD=ROOT/'Build/cmake/coord-x64/bin'

def idle():
    assert subprocess.run(['powershell','-NoProfile','-Command','[bool](Get-Process Game -ErrorAction SilentlyContinue)'],capture_output=True,text=True,check=True).stdout.strip()=='False', 'Game is running'

def binaries(base, manifest):
    for row in manifest['binaries']:
        assert sha(base/'Bin64'/row['name'])==row['sha256'], row['name']

def main():
    global STAGE
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('mode',choices=['stage','check','publish']);p.add_argument('--check',type=Path);p.add_argument('--ground-check',type=Path)
    p.add_argument('--stage',type=Path,default=ROOT/'Build/world-gui/stage-mount-flight-actions-24')
    p.add_argument('--second-flight-check',type=Path)
    a=p.parse_args()
    STAGE=a.stage.resolve();assert STAGE.is_relative_to(ROOT/'Build/world-gui') and STAGE!=PLAY
    baseline=STAGE/'mount_flight_baseline.json'
    if a.mode=='stage':
        idle()
        if not STAGE.exists():
            STAGE.mkdir()
            for name in ['Bin64','Patch','Overlay']:shutil.copytree(PLAY/name,STAGE/name)
            shutil.copy2(PLAY/'Play.cmd',STAGE/'Play.cmd')
            subprocess.run(['powershell','-NoProfile','-Command',f"New-Item -ItemType Junction -Path '{STAGE/'Data'}' -Target '{ROOT/'Assets/CanonicalCY/Data'}' | Out-Null"],check=True)
        if not baseline.exists():
            baseline.write_text(json.dumps({'play_manifest':sha(PLAY/'Bin64/game_data_stage.json'),'game':sha(PLAY/'Bin64/Game.exe')})+'\n',encoding='utf8')
        m=json.loads((STAGE/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
        for row in m['binaries']:
            if row['name'] in NAMES:
                dest=STAGE/'Bin64'/row['name'];shutil.copy2(BUILD/row['name'],dest)
                row.update(sha256=sha(dest),bytes=dest.stat().st_size)
        m['mount_flight_candidate']={'native_CGFlyOperation':2242,'shortcut':'Ctrl+left click'}
        (STAGE/'Bin64/game_data_stage.json').write_text(json.dumps(m,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
        binaries(STAGE,m)
        print('Staged:',STAGE,'Game:',sha(STAGE/'Bin64/Game.exe'))
        return
    assert a.check
    run=json.loads((a.check/'run.json').read_text(encoding='utf-8-sig'))
    log=(a.check/'WXClient.log').read_text(encoding='utf8',errors='replace')
    assert run['passed'] and run['game_sha256']==sha(STAGE/'Bin64/Game.exe')
    assert run['stage_manifest_sha256']==sha(STAGE/'Bin64/game_data_stage.json')
    assert 'CYS-MOUNT-FLIGHT-PROBE: RESULT errors=0' in log
    assert 'PASS rider reaches native flight surface' in log
    assert 'PASS airborne movement works' in log
    assert a.second_flight_check, 'Second mount with zero ground hover required'
    second=json.loads((a.second_flight_check/'run.json').read_text(encoding='utf-8-sig'))
    secondlog=(a.second_flight_check/'WXClient.log').read_text(encoding='utf8',errors='replace')
    assert second['passed'] and second['game_sha256']==run['game_sha256'] and second['stage_manifest_sha256']==run['stage_manifest_sha256']
    for flightlog in [log,secondlog]:
        for marker in ['RESULT errors=0','PASS direct flight path crosses ground obstacle','PASS direct flight path rejects outside scene',
                       'PASS airborne movement reaches blocked ground','PASS server rejects landing over obstacle',
                       'PASS returned to safe landing position','PASS normal movement restored after flight']:
            assert 'CYS-MOUNT-FLIGHT-PROBE: '+marker in flightlog,marker
        assert 'CYS-MOUNT-FLIGHT-PROBE: FAIL' not in flightlog and 'CYS Lua failure' not in flightlog
        for action in [922,923,924,927]:assert 'action='+str(action)+' rider=' in flightlog,action
    assert 'mount=271' in secondlog
    assert a.ground_check, 'Ground-mount rejection run required'
    ground=json.loads((a.ground_check/'run.json').read_text(encoding='utf-8-sig'))
    groundlog=(a.ground_check/'WXClient.log').read_text(encoding='utf8',errors='replace')
    assert ground['passed'] and ground['game_sha256']==run['game_sha256'] and ground['stage_manifest_sha256']==run['stage_manifest_sha256']
    assert 'PASS server rejects ground mount independently of client' in groundlog
    assert 'CYS-MOUNT-FLIGHT-PROBE: RESULT errors=0' in groundlog and 'CYS-MOUNT-FLIGHT-PROBE: FAIL' not in groundlog
    for bad in ['CYS-MOUNT-FLIGHT-PROBE: FAIL','CYS Lua failure']:assert bad not in log,bad
    current=json.loads((PLAY/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
    tested=json.loads((STAGE/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
    binaries(PLAY,current);binaries(STAGE,tested)
    original=json.loads(baseline.read_text(encoding='utf8'))
    assert sha(PLAY/'Bin64/Game.exe')==original['game'] and sha(PLAY/'Bin64/game_data_stage.json')==original['play_manifest'], 'Play changed since the flight baseline was captured'
    before={r['name']:r['sha256'] for r in current['binaries']}
    after={r['name']:r['sha256'] for r in tested['binaries']}
    assert before.keys()==after.keys()
    assert all(before[n]==after[n] for n in before if n not in NAMES)
    assert all(sha(BUILD/n)==after[n] for n in NAMES)
    # This fix ships code only. Any overlay difference is unexpected.
    for folder in ['Overlay','Patch']:
        for f in (STAGE/folder).rglob('*'):
            if f.is_file():assert sha(f)==sha(PLAY/f.relative_to(STAGE)),f
    if a.mode=='check':print('PASS: native shortcut, takeoff/landing, locks, movement and exact binaries');return
    idle()
    stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    backup=ROOT/'Build/backups/mount-flight-play'/stamp;backup.mkdir(parents=True)
    for name in NAMES+('game_data_stage.json','Run-CY-Server.cmd'):shutil.copy2(PLAY/'Bin64'/name,backup/name)
    for row in current['binaries']:
        if row['name'] in NAMES:
            dest=PLAY/'Bin64'/row['name'];shutil.copy2(STAGE/'Bin64'/row['name'],dest)
            row.update(sha256=sha(dest),bytes=dest.stat().st_size)
    launcher=PLAY/'Bin64/Run-CY-Server.cmd';raw=launcher.read_bytes()
    anchor=b'set "CYS_WORLD_REPLAY="';line=b'set "CYS_MOUNT_FLIGHT_LIVE="'
    assert raw.count(anchor)==1
    if line not in raw:raw=raw.replace(anchor,anchor+b'\r\n'+line)
    launcher.write_bytes(raw)
    for row in current['wsl_test']['launchers']:
        if row['path']=='Bin64/Run-CY-Server.cmd':row.update(sha256=sha(launcher),bytes=launcher.stat().st_size)
    evidence=dict(at=stamp,check=str(a.check.resolve()),ground_check=str(a.ground_check.resolve()),second_flight_check=str(a.second_flight_check.resolve()),backup=str(backup),before=before,after=after)
    current['mount_flight_update']=evidence
    (PLAY/'Bin64/game_data_stage.json').write_text(json.dumps(current,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
    (backup/'deployment.json').write_text(json.dumps(evidence,indent=2)+'\n',encoding='utf8')
    binaries(PLAY,current)
    print('Published:',PLAY,'backup:',backup)

if __name__=='__main__':main()
