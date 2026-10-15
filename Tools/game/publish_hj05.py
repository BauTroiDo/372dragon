"""Publish only the reviewed HJ05 candidate after exact-build GUI and data checks."""
from pathlib import Path
import argparse,datetime,json,shutil,subprocess
from deploy_mount_flight import idle,binaries
from publish_gameplay_fixes import ROOT,sha

PLAY=ROOT/'Build/world-gui/stage-play-21'
STAGE=ROOT/'Build/world-gui/stage-hj05-28'
LOG=ROOT/'Build/Logs/2026-09-28-hj05-fixes'
LIVE=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('mode',choices=['check','publish'])
    for mode in [3,4,5,6]:p.add_argument('--mode'+str(mode),required=True,type=Path)
    a=p.parse_args();idle()
    before=json.loads((PLAY/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
    after=json.loads((STAGE/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
    baseline=json.loads((LOG/'play-baseline.json').read_text())
    assert sha(PLAY/'Bin64/Game.exe')==baseline['game']
    assert sha(PLAY/'Bin64/game_data_stage.json')==baseline['manifest'],'Play changed during tests'
    binaries(PLAY,before);binaries(STAGE,after)
    for name in ['Game.exe','Game.pdb']:
        assert sha(STAGE/'Bin64'/name)==sha(ROOT/'Build/cmake/coord-x64/bin'/name),'Candidate is not the latest build: '+name
    proof=[]
    for mode in [3,4,5,6]:
        folder=getattr(a,'mode'+str(mode)).resolve()
        r=json.loads((folder/'run.json').read_text(encoding='utf-8-sig'))
        log=(folder/'WXClient.log').read_text(encoding='utf8',errors='replace')
        assert r['passed'] and r['game_sha256']==sha(STAGE/'Bin64/Game.exe'),folder
        assert r['stage_manifest_sha256']==sha(STAGE/'Bin64/game_data_stage.json'),folder
        assert 'CYS-POWER-SYSTEMS: RESULT mode='+str(mode)+' errors=0' in log,folder
        assert 'CYS-POWER-SYSTEMS: FAIL' not in log and 'CYS Lua failure' not in log,folder
        assert json.loads((folder/'server-check.json').read_text(encoding='utf8'))['passed'],folder
        proof.append(dict(mode=mode,folder=str(folder),run_sha256=sha(folder/'run.json')))
    for row in json.loads((LOG/'server/manifest.json').read_text()):
        assert sha(LIVE/row['path'])==row['after'],row['path']
    subprocess.run(['wsl','-d','TLBB','-u','root','--','python3',
        '/mnt/c/TLBB/085/CY-Source/Tools/server/hj05_fixture.py','verify'],check=True)
    oldbins={r['name']:r['sha256'] for r in before['binaries']}
    newbins={r['name']:r['sha256'] for r in after['binaries']}
    assert oldbins.keys()==newbins.keys()
    assert all(oldbins[n]==newbins[n] for n in oldbins if n not in ['Game.exe','Game.pdb'])
    changed=['Bin64/Game.exe','Bin64/Game.pdb']
    for row in after['overlay']:
        rel=Path(row['path']).as_posix()
        assert (STAGE/rel).resolve().is_relative_to(STAGE.resolve()),rel
        assert rel.startswith(('Overlay/','Patch/')),rel
        assert sha(STAGE/rel)==row['sha256'],rel
        # Older stage manifests also inventory the existing GM plugins here.
        # They are unchanged dependencies, not files this release may replace.
        if rel.startswith('Patch/'):
            assert sha(STAGE/rel)==sha(PLAY/rel),rel
            continue
        if not (PLAY/rel).exists() or sha(PLAY/rel)!=row['sha256']:changed.append(rel)
    for f in (STAGE/'Patch').rglob('*'):
        if f.is_file():assert sha(f)==sha(PLAY/f.relative_to(STAGE)),f
    if a.mode=='check':print('PASS candidate, four feature runs, runtime hashes, exact BSON restore');return
    stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    backup=ROOT/'Build/backups/hj05-play'/stamp;backup.mkdir(parents=True)
    for rel in changed+['Bin64/game_data_stage.json','Bin64/Run-CY-Server.cmd']:
        path=PLAY/rel
        assert path.resolve().is_relative_to(PLAY.resolve()),path
        if path.exists():
            dest=backup/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,dest)
    for rel in changed:
        dest=PLAY/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(STAGE/rel,dest)
    launcher=PLAY/'Bin64/Run-CY-Server.cmd';raw=launcher.read_bytes()
    anchor=b'set "CYS_WORLD_REPLAY="';assert raw.count(anchor)==1
    for env in ['CYS_POWER_SYSTEMS_LIVE','CYS_POWER_DRAG_LOG']:
        line=('set "'+env+'="').encode('ascii')
        if line not in raw:raw=raw.replace(anchor,anchor+b'\r\n'+line)
    launcher.write_bytes(raw)
    for row in after['wsl_test']['launchers']:
        if row['path']=='Bin64/Run-CY-Server.cmd':row.update(sha256=sha(launcher),bytes=launcher.stat().st_size)
    after.pop('hj05_probe_candidate',None)
    release=dict(at=stamp,backup=str(backup),game_sha256=sha(PLAY/'Bin64/Game.exe'),
        baseline=baseline,changed=changed,proof=proof,server_manifest_sha256=sha(LOG/'server/manifest.json'))
    after['hj05_update']=release
    (PLAY/'Bin64/game_data_stage.json').write_text(json.dumps(after,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
    binaries(PLAY,after)
    for row in after['overlay']:assert sha(PLAY/row['path'])==row['sha256'],row['path']
    (LOG/'release-report.json').write_text(json.dumps(release,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    print('Published',PLAY,'backup',backup)

if __name__=='__main__':main()
