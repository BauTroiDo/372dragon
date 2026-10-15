"""Stage/publish the tested name/title fit change and its two scoped overlays."""
from pathlib import Path
import argparse,datetime,json,re,shutil,subprocess
from publish_gameplay_fixes import ROOT,NAMES,sha
from deploy_npc_icons import idle,binaries
from patch_creatureboard_readability import generate,NAME

STAGE=ROOT/'Build/world-gui/stage-nameboards-23'
PLAY=ROOT/'Build/world-gui/stage-play-21'
BUILD=ROOT/'Build/cmake/coord-x64/bin'
OVERLAYS=[f'Overlay/{side}/InterfaceFolder/{NAME}' for side in ['Pre','Post']]

def write_manifest(stage,m):
    (stage/'Bin64/game_data_stage.json').write_text(json.dumps(m,ensure_ascii=False,indent=1)+'\n',encoding='utf8')

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('mode',choices=['stage','check','publish']);p.add_argument('--check',type=Path);a=p.parse_args()
    data,details=generate((ROOT/'Assets/CanonicalCY/Data/InterfaceFolder'/NAME).read_bytes())
    if a.mode=='stage':
        idle()
        if not STAGE.exists():
            STAGE.mkdir()
            for folder in ['Bin64','Overlay','Patch']:shutil.copytree(PLAY/folder,STAGE/folder)
            shutil.copy2(PLAY/'Play.cmd',STAGE/'Play.cmd')
            subprocess.run(['powershell','-NoProfile','-Command',f"New-Item -ItemType Junction -Path '{STAGE/'Data'}' -Target '{ROOT/'Assets/CanonicalCY/Data'}' | Out-Null"],check=True)
        m=json.loads((STAGE/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
        for row in m['binaries']:
            if row['name'] in NAMES:
                dst=STAGE/'Bin64'/row['name'];shutil.copy2(BUILD/row['name'],dst);row.update(sha256=sha(dst),bytes=dst.stat().st_size)
        m['overlay'][:]=[r for r in m['overlay'] if r['path'] not in OVERLAYS]
        for rel in OVERLAYS:
            dst=STAGE/rel;dst.parent.mkdir(parents=True,exist_ok=True);dst.write_bytes(data)
            m['overlay'].append(dict(path=rel,sha256=sha(dst),bytes=len(data),origin='../Data/InterfaceFolder/'+NAME,reason='Name/title text fitting and wider centred wrapping'))
        m['nameboard_candidate']=details;write_manifest(STAGE,m);binaries(STAGE,m)
        print('Staged:',STAGE,'Game:',sha(STAGE/'Bin64/Game.exe'));return
    assert a.check
    run=json.loads((a.check/'run.json').read_text(encoding='utf-8-sig'))
    log=(a.check/'WXClient.log').read_text(encoding='utf8',errors='replace')
    ui=(a.check/'UISystem.log').read_text(encoding='utf8',errors='replace')
    assert run['passed'] and run['game_sha256']==sha(STAGE/'Bin64/Game.exe')
    assert run['stage_manifest_sha256']==sha(STAGE/'Bin64/game_data_stage.json')
    assert 'CYS-NAMEBOARD: RESULT cases=3 errors=0' in log and 'KET QUA lop 1..4 XANH' in log
    assert not any(s in log+ui for s in ['CYS-NAMEBOARD: FAIL','CYS-NAMEBOARD: exception','CYS Lua failure'])
    for mode in [2,3]:
        for label in ['name','title']:assert re.search(rf'CYS-NAMEBOARD: mode={mode} label={label} .*cut=0 fit=1 max=600 hollow=1',ui)
    tested=json.loads((STAGE/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
    current=json.loads((PLAY/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
    binaries(PLAY,current);binaries(STAGE,tested)
    before={r['name']:r['sha256'] for r in current['binaries']};after={r['name']:r['sha256'] for r in tested['binaries']}
    assert before.keys()==after.keys() and all(before[n]==after[n] for n in before if n not in NAMES)
    assert all(sha(BUILD/n)==after[n] for n in NAMES)
    for rel in OVERLAYS:assert (STAGE/rel).read_bytes()==data
    for folder in ['Patch','Overlay']:
        for f in (STAGE/folder).rglob('*'):
            rel=f.relative_to(STAGE).as_posix()
            if f.is_file() and rel not in OVERLAYS:assert sha(f)==sha(PLAY/rel),rel
    if a.mode=='check':print('PASS: negative control, long/wrapped labels, NPC interaction, movement, exact binary and overlay hashes');return
    idle();stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    backup=ROOT/'Build/backups/nameboards-play'/stamp;backup.mkdir(parents=True)
    paths=['Bin64/'+n for n in NAMES]+['Bin64/game_data_stage.json','Bin64/Run-CY-Server.cmd']+OVERLAYS
    missing=[]
    for rel in paths:
        if (PLAY/rel).exists():dst=backup/rel;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(PLAY/rel,dst)
        else:missing.append(rel)
    for row in current['binaries']:
        if row['name'] in NAMES:
            dst=PLAY/'Bin64'/row['name'];shutil.copy2(STAGE/'Bin64'/row['name'],dst);row.update(sha256=sha(dst),bytes=dst.stat().st_size)
    for rel in OVERLAYS:
        dst=PLAY/rel;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(STAGE/rel,dst)
    current['overlay'][:]=[r for r in current['overlay'] if r['path'] not in OVERLAYS]
    current['overlay'].extend(r for r in tested['overlay'] if r['path'] in OVERLAYS)
    launcher=PLAY/'Bin64/Run-CY-Server.cmd';raw=launcher.read_bytes();anchor=b'set "CYS_WORLD_REPLAY="';line=b'set "CYS_NAMEBOARD_LIVE="';assert raw.count(anchor)==1
    if line not in raw:raw=raw.replace(anchor,anchor+b'\r\n'+line)
    launcher.write_bytes(raw)
    for row in current['wsl_test']['launchers']:
        if row['path']=='Bin64/Run-CY-Server.cmd':row.update(sha256=sha(launcher),bytes=launcher.stat().st_size)
    evidence=dict(at=stamp,check=str(a.check.resolve()),backup=str(backup),new_paths=missing,before=before,after=after,layout=details)
    current['nameboard_update']=evidence;write_manifest(PLAY,current)
    (backup/'deployment.json').write_text(json.dumps(evidence,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    binaries(PLAY,current)
    for rel in OVERLAYS:assert (PLAY/rel).read_bytes()==data
    print('Published:',PLAY,'backup:',backup)

if __name__=='__main__':main()
