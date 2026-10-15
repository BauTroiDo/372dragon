"""Publish the shop/soul continuation with exact-build GUI and restored fixtures."""
from pathlib import Path
import argparse,datetime,json,shutil,subprocess
from deploy_mount_flight import idle,binaries
from publish_gameplay_fixes import ROOT,sha

PLAY=ROOT/'Build/world-gui/stage-play-21'
STAGE=ROOT/'Build/world-gui/stage-hj05-remaining'
LOG=ROOT/'Build/Logs/2026-09-28-hj05-remaining'
LIVE=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
CASES={'shop_owner':('CYS-SHOP-PROBE',1),'shop_buyer':('CYS-SHOP-PROBE',2),
       'shop_relogin':('CYS-SHOP-PROBE',3),'soul':('CYS-SOUL-REFORGE',1),
       'soul_relogin':('CYS-SOUL-REFORGE',2),'bank':('CYS-POWER-SYSTEMS',5),
       'bank_relogin':('CYS-POWER-SYSTEMS',6)}

def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('mode',choices=['check','publish'])
    for name in CASES:p.add_argument('--'+name.replace('_','-'),required=True,type=Path)
    a=p.parse_args();idle()
    before=read(PLAY/'Bin64/game_data_stage.json');after=read(STAGE/'Bin64/game_data_stage.json')
    baseline=read(LOG/'play-baseline.json')
    assert sha(PLAY/'Bin64/Game.exe')==baseline['game']
    assert sha(PLAY/'Bin64/game_data_stage.json')==baseline['manifest'],'Play changed since baseline'
    binaries(PLAY,before);binaries(STAGE,after)
    for name in ('Game.exe','Game.pdb'):
        assert sha(STAGE/'Bin64'/name)==sha(ROOT/'Build/cmake/coord-x64/bin'/name),name
    proof=[]
    for key,(marker,mode) in CASES.items():
        folder=getattr(a,key).resolve();assert folder.is_relative_to(LOG)
        r=read(folder/'run.json');log=(folder/'WXClient.log').read_text(encoding='utf8',errors='replace')
        assert r['passed'] and all(r['checks'].values()),folder
        assert r['game_sha256']==sha(STAGE/'Bin64/Game.exe'),folder
        tested_manifest=r['stage_manifest_sha256']
        if tested_manifest!=sha(STAGE/'Bin64/game_data_stage.json'):
            # Soul-only layout changes do not invalidate completed shop tests.
            # Require an immutable manifest and equality of every other file.
            assert key.startswith('shop_'),folder
            saved=LOG/'manifests'/(tested_manifest+'.json');assert sha(saved)==tested_manifest
            tested=read(saved)
            assert {k:v for k,v in tested.items() if k!='overlay'}=={k:v for k,v in after.items() if k!='overlay'}
            arows={x['path']:x for x in after['overlay']};trows={x['path']:x for x in tested['overlay']}
            assert arows.keys()==trows.keys()
            different={k for k in arows if arows[k]!=trows[k]}
            allowed={f'Overlay/{layer}/InterfaceFolder/PetSoul_LevelUp/PetSoul_LevelUp{ext}'
                     for layer in ('Pre','Post') for ext in ('.lua','.layout.xml')}
            assert different and different<=allowed,(folder,different)
        assert f'{marker}: RESULT mode={mode} errors=0' in log,folder
        assert f'{marker}: FAIL' not in log and 'CYS Lua failure' not in log,folder
        assert read(folder/'server-check.json')['passed'],folder
        for shot in r['shots']:assert sha(folder/shot['name'])==shot['sha256'],shot['name']
        proof.append(dict(case=key,mode=mode,folder=str(folder),run_sha256=sha(folder/'run.json'),
                          stage_manifest_sha256=tested_manifest))
    # All cumulative server changes, including the preceding HJ05 release.
    for row in read(LOG/'runtime-manifest.json'):assert sha(LIVE/row['path'])==row['after'],row['path']
    assert read(LOG/'server/manifest.json')==read(LOG/'deployed-manifest.json')
    reports=[p for p in LOG.glob('verify-*/report.json')
             if read(p).get('server_manifest_sha256')==sha(LOG/'server/manifest.json')
             and read(p).get('runtime_manifest_sha256')==sha(LOG/'runtime-manifest.json')]
    assert reports and read(max(reports))['passed'],'No passing current runtime verification'
    for f in ('shop-purchase-proof.json','soul-persist-proof.json'):assert read(LOG/f)['passed'],f
    bank=read(LOG/'bank-after.json');assert len(bank)==4 and len({tuple(x['guid']) for x in bank})==4
    for fixture in ('remaining_shop_fixture.py','remaining_soul_fixture.py'):
        subprocess.run(['wsl','-d','TLBB','-u','root','--','python3',
                        '/mnt/c/TLBB/085/CY-Source/Tools/server/'+fixture,'verify'],check=True)
    old={r['name']:r['sha256'] for r in before['binaries']};new={r['name']:r['sha256'] for r in after['binaries']}
    assert old.keys()==new.keys()
    assert all(old[n]==new[n] for n in old if n not in ('Game.exe','Game.pdb'))
    changed=['Bin64/Game.exe','Bin64/Game.pdb']
    for row in after['overlay']:
        rel=Path(row['path']).as_posix()
        assert (STAGE/rel).resolve().is_relative_to(STAGE.resolve()) and rel.startswith(('Overlay/','Patch/')),rel
        assert sha(STAGE/rel)==row['sha256'],rel
        if rel.startswith('Patch/'):assert sha(STAGE/rel)==sha(PLAY/rel),rel
        elif not (PLAY/rel).exists() or sha(PLAY/rel)!=row['sha256']:changed.append(rel)
    for f in (STAGE/'Patch').rglob('*'):
        if f.is_file():assert sha(f)==sha(PLAY/f.relative_to(STAGE)),f
    assert (PLAY/'Data').resolve()==(STAGE/'Data').resolve()
    if a.mode=='check':print('PASS seven exact-build GUI runs, current server, persistence and complete BSON restore');return
    stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    backup=ROOT/'Build/backups/hj05-remaining-play'/stamp;backup.mkdir(parents=True)
    for rel in changed+['Bin64/game_data_stage.json','Bin64/Run-CY-Server.cmd']:
        path=PLAY/rel;assert path.resolve().is_relative_to(PLAY.resolve()),path
        if path.exists():
            dest=backup/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,dest)
    for rel in changed:
        dest=PLAY/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(STAGE/rel,dest)
    launcher=PLAY/'Bin64/Run-CY-Server.cmd';raw=launcher.read_bytes()
    anchor=b'set "CYS_WORLD_REPLAY="';assert raw.count(anchor)==1
    for env in ('CYS_PLAYER_SHOP_PROBE','CYS_SOUL_REFORGE_PROBE','CYS_POWER_SYSTEMS_LIVE','CYS_POWER_DRAG_LOG'):
        line=('set "'+env+'="').encode('ascii')
        if line not in raw:raw=raw.replace(anchor,anchor+b'\r\n'+line)
    launcher.write_bytes(raw)
    for row in after['wsl_test']['launchers']:
        if row['path']=='Bin64/Run-CY-Server.cmd':row.update(sha256=sha(launcher),bytes=launcher.stat().st_size)
    release=dict(at=stamp,backup=str(backup),game_sha256=sha(PLAY/'Bin64/Game.exe'),
        tested_manifest_sha256=sha(STAGE/'Bin64/game_data_stage.json'),baseline=baseline,
        changed=changed,proof=proof,server_manifest_sha256=sha(LOG/'server/manifest.json'),
        runtime_manifest_sha256=sha(LOG/'runtime-manifest.json'),verification=str(max(reports)))
    after['hj05_remaining']=release
    (PLAY/'Bin64/game_data_stage.json').write_text(json.dumps(after,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
    binaries(PLAY,after)
    for row in after['overlay']:assert sha(PLAY/row['path'])==row['sha256'],row['path']
    (LOG/'release-report.json').write_text(json.dumps(release,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    print('Published',PLAY,'backup',backup)

if __name__=='__main__':main()
