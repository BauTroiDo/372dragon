"""Exact-binary, exact-overlay staging and release for the continuing gameplay audit."""
from pathlib import Path
import argparse,json,shutil,subprocess,datetime
from publish_gameplay_fixes import ROOT,sha
from deploy_mount_flight import idle,binaries
PLAY=ROOT/'Build/world-gui/stage-play-21'
STAGE=ROOT/'Build/world-gui/stage-community-28'
LOG=ROOT/'Build/Logs/2026-09-28-settings-friends-titles'
NAMES=('Game.exe','Game.pdb','UI_CEGUI.dll','UI_CEGUI.pdb')
def entries():
    return {f'Overlay/{side}/'+rel:LOG/'client'/rel for rel in json.loads((LOG/'client/manifest.json').read_text()) for side in ['Pre','Post']}

def check_files(base,m):
    binaries(base,m)
    for row in m['overlay']:assert sha(base/row['path'])==row['sha256'],row['path']
def main():
    p=argparse.ArgumentParser();p.add_argument('mode',choices=['stage','publish']);p.add_argument('--checks',nargs='+',type=Path);a=p.parse_args()
    idle();files=entries();baseline=LOG/'play-baseline.json'
    if a.mode=='stage':
        if not STAGE.exists():
            STAGE.mkdir()
            for n in ['Bin64','Patch','Overlay']:shutil.copytree(PLAY/n,STAGE/n)
            shutil.copy2(PLAY/'Play.cmd',STAGE/'Play.cmd')
            subprocess.run(['powershell','-NoProfile','-Command',f"New-Item -ItemType Junction -Path '{STAGE/'Data'}' -Target '{ROOT/'Assets/CanonicalCY/Data'}' | Out-Null"],check=True)
        if not baseline.exists():baseline.write_text(json.dumps({'manifest':sha(PLAY/'Bin64/game_data_stage.json'),'files':{r:sha(PLAY/r)if(PLAY/r).exists()else None for r in files}}))
        b=json.loads(baseline.read_text());assert b['manifest']==sha(PLAY/'Bin64/game_data_stage.json')
        for rel in files:
            if rel not in b['files']:b['files'][rel]=sha(PLAY/rel)if(PLAY/rel).exists()else None
        baseline.write_text(json.dumps(b))
        m=json.loads((PLAY/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
        for row in m['binaries']:
            if row['name']in NAMES:
                dst=STAGE/'Bin64'/row['name'];shutil.copy2(ROOT/'Build/cmake/coord-x64/bin'/row['name'],dst);row.update(sha256=sha(dst),bytes=dst.stat().st_size)
        for rel,src in files.items():
            dst=STAGE/rel;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
            row=next((r for r in m['overlay']if r['path']==rel),None)
            if row is None:row={'path':rel,'origin':'community_data.py','reason':'settings, friends and titles'};m['overlay'].append(row)
            row.update(sha256=sha(dst),bytes=dst.stat().st_size)
        m['community_candidate']={'plan':sha(LOG/'client/manifest.json')}
        m['ui_compat']['excluded_windows']=[r for r in m['ui_compat']['excluded_windows'] if r.get('window')!='Agname']
        (STAGE/'Bin64/game_data_stage.json').write_text(json.dumps(m,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
        check_files(STAGE,m);print('Staged',len(files),'overlays; Game',sha(STAGE/'Bin64/Game.exe'));return
    b=json.loads(baseline.read_text());assert sha(PLAY/'Bin64/game_data_stage.json')==b['manifest']
    for rel,before in b['files'].items():assert (sha(PLAY/rel)if(PLAY/rel).exists()else None)==before,rel
    m=json.loads((STAGE/'Bin64/game_data_stage.json').read_text(encoding='utf8'));check_files(STAGE,m)
    assert m['community_candidate']['plan']==sha(LOG/'client/manifest.json')
    modes=set();assert a.checks
    for f in a.checks:
        r=json.loads((f/'run.json').read_text(encoding='utf-8-sig'));log=(f/'WXClient.log').read_text(encoding='utf8',errors='replace')
        assert r['passed']and r['game_sha256']==sha(STAGE/'Bin64/Game.exe')and r['stage_manifest_sha256']==sha(STAGE/'Bin64/game_data_stage.json'),str(f)
        assert 'CYS-COMMUNITY: FAIL'not in log and 'CYS Lua failure'not in log,str(f)
        for mode in [1,2,3]:
            if f'CYS-COMMUNITY: RESULT mode={mode} errors=0'in log:modes.add(mode)
    assert modes=={1,2,3},modes
    assert json.loads((LOG/'fixture-restore.json').read_text())['full_bson_equal']
    stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S');backup=ROOT/'Build/backups/community-play'/stamp
    for rel in list(files)+['Bin64/'+n for n in NAMES]+['Bin64/game_data_stage.json']:
        p=PLAY/rel
        if p.exists():dest=backup/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
    for rel in list(files)+['Bin64/'+n for n in NAMES]:
        dst=PLAY/rel;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(STAGE/rel,dst)
    evidence={'at':stamp,'checks':[str(f.resolve())for f in a.checks],'backup':str(backup),'game':sha(PLAY/'Bin64/Game.exe')}
    m['community_release']=evidence
    (PLAY/'Bin64/game_data_stage.json').write_text(json.dumps(m,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
    check_files(PLAY,m);(LOG/'release-report.json').write_text(json.dumps(evidence,indent=2));print('Published',evidence)
if __name__=='__main__':main()
