"""Publish the measured round2 candidate; retain full rollback files and evidence."""
from pathlib import Path
import argparse,datetime,json,shutil
from publish_gameplay_fixes import ROOT,NAMES,sha
from deploy_npc_icons import idle,binaries

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--checks',nargs='+',type=Path,required=True)
    p.add_argument('--apply',action='store_true');a=p.parse_args()
    stage=ROOT/'Build/world-gui/stage-round2-23';play=ROOT/'Build/world-gui/stage-play-21'
    sm=json.loads((stage/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
    pm=json.loads((play/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
    binaries(stage,sm);binaries(play,pm)
    proofs=[];logs=[];latest=False
    for folder in a.checks:
        run=json.loads((folder/'run.json').read_text(encoding='utf-8-sig'))
        log=(folder/'WXClient.log').read_text(encoding='utf8',errors='replace')
        # Portals have no nearby AOI objects at the arrival gate. The dedicated
        # probe checks two real scene changes, stable arrivals and player movement.
        if not run['passed']:
            assert 'RESULT two real portals stable arrivals and movement errors=0' in log,folder
            assert {k for k,v in run['checks'].items() if not v}=={'stats_in_world_with_objects'},folder
        for marker in ['CYS-ROUND2-PROBE: FAIL','CYS skill-live: ROUND2 FAIL','CYS Lua failure']:
            assert marker not in log,(folder,marker)
        latest|=bool(run['passed'] and run['game_sha256']==sha(stage/'Bin64/Game.exe') and run['stage_manifest_sha256']==sha(stage/'Bin64/game_data_stage.json'))
        proofs.append({'folder':str(folder.resolve()),'game':run['game_sha256'],'manifest':run['stage_manifest_sha256'],'generic_passed':run['passed']})
        logs.append(log)
    text='\n'.join(logs)
    for marker in ['RESULT bags100 common compact Alt/F tooltip+2 EXP movement errors=0',
                   'RESULT temporary bag persistence GUID and +2 errors=0',
                   'RESULT GM authorized item and scene search errors=0',
                   'RESULT GM denied ordinary account errors=0',
                   'RESULT two real portals stable arrivals and movement errors=0',
                   'ROUND2 PASS pick all conservation',
                   'ROUND2 PASS kill EXP credited and attack stopped before manual cancel',
                   'merge and repeated request conserve250 and GUID',
                   'RESULT stack250 persists after relog errors=0',
                   'RESULT skill tabs formation/battle and talent level gate errors=0',
                   'cosmetic body audit count=956 errors=0']:
        assert marker in text,marker
    assert latest,'no live check on exact current candidate'
    for row in sm['overlay']:assert sha(stage/row['path'])==row['sha256'],row['path']
    permitted={r['path'].replace('\\','/') for r in sm['overlay']}|{f'Bin64/{n}' for n in NAMES}
    changed=[r for r in sorted(permitted) if not (play/r).exists() or sha(stage/r)!=sha(play/r)]
    print('PASS functional evidence and exact candidate; changed files:',len(changed))
    if not a.apply:return
    idle();stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    backup=ROOT/'Build/backups/round2-play'/stamp;backup.mkdir(parents=True)
    launcher=play/'Bin64/Run-CY-Server.cmd';raw=launcher.read_bytes();anchor=b'set "CYS_WORLD_REPLAY="'
    assert raw.count(anchor)==1
    for flag in ['CYS_ROUND2_LIVE','CYS_ROUND2_COMBAT','CYS_WARDROBE_LIVE','CYS_WARDROBE_ITEM']:
        line=('set "'+flag+'="').encode()
        if line not in raw:raw=raw.replace(anchor,anchor+b'\r\n'+line,1)
    files=[]
    for rel in changed+['Bin64/game_data_stage.json','Bin64/Run-CY-Server.cmd']:
        target=play/rel;entry={'path':rel,'existed':target.exists()}
        if target.exists():
            entry['before']=sha(target);dest=backup/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(target,dest)
        files.append(entry)
    for rel in changed:
        dst=play/rel;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(stage/rel,dst)
        assert sha(dst)==sha(stage/rel)
    launcher.write_bytes(raw)
    pm['binaries']=sm['binaries'];pm['overlay']=sm['overlay'];pm['round2_candidate']=sm['round2_candidate']
    for row in pm['wsl_test']['launchers']:
        if row['path']=='Bin64/Run-CY-Server.cmd':row.update(sha256=sha(launcher),bytes=launcher.stat().st_size)
    proof={'at':stamp,'game':sha(stage/'Bin64/Game.exe'),'backup':str(backup),'checks':proofs,'files':files,
           'limits':['CY talent requires 120/129; server caps at119 and lacks script998633',
                     'Battle tab opens; CY automatic battle executor is not implemented; Start reports this explicitly',
                     '956 cosmetic body-property checks, selected red FX screenshots; not every cosmetic render combination']}
    pm['round2_update']=proof
    (play/'Bin64/game_data_stage.json').write_text(json.dumps(pm,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
    binaries(play,pm)
    for row in pm['overlay']:assert sha(play/row['path'])==row['sha256'],row['path']
    (backup/'deployment.json').write_text(json.dumps(proof,ensure_ascii=False,indent=2),encoding='utf8')
    print('Published',play,'backup',backup)

if __name__=='__main__':main()
