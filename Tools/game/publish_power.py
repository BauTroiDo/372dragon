"""Publish the exact four-system candidate after gameplay AND relog checks."""
from pathlib import Path
import argparse,datetime,json,shutil
from publish_gameplay_fixes import ROOT,NAMES,sha
from deploy_npc_icons import idle,binaries

def main():
    p=argparse.ArgumentParser();p.add_argument('--checks',type=Path,nargs='+',required=True);p.add_argument('--apply',action='store_true');a=p.parse_args()
    stage=ROOT/'Build/world-gui/stage-power-24';play=ROOT/'Build/world-gui/stage-play-21'
    sm=json.loads((stage/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
    pm=json.loads((play/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
    binaries(stage,sm);binaries(play,pm);proofs=[];modes=set();combined=''
    for folder in a.checks:
        run=json.loads((folder/'run.json').read_text(encoding='utf-8-sig'))
        log=(folder/'WXClient.log').read_text(encoding='utf8',errors='replace')
        assert run['passed'],folder
        assert run['game_sha256']==sha(stage/'Bin64/Game.exe'),('different binary',folder)
        assert run['stage_manifest_sha256']==sha(stage/'Bin64/game_data_stage.json'),('different overlays',folder)
        for bad in ['CYS-POWER-SYSTEMS: FAIL','CYS Lua failure','Packet handler exception']:assert bad not in log,(folder,bad)
        for mode in (1,2):
            if f'CYS-POWER-SYSTEMS: RESULT mode={mode} errors=0' in log:modes.add(mode)
        combined+=log
        proofs.append({'folder':str(folder.resolve()),'game':run['game_sha256'],'manifest':run['stage_manifest_sha256']})
    assert modes=={1,2},'Both actual operations and a fresh relog must pass'
    for marker in ['ShenDing changes real character constitution','ShenDing changes real element attacks',
                   'native Wuhun compound window','compound consumes one material soul',
                   'native cultivation study window','blood feed consumes one','wash uses one material',
                   'equipping removes soul from bag','unequipping returns exactly one soul','character moves after UI closes']:
        assert marker in combined,marker
    tests=(ROOT/'Build/Logs/2026-09-24-power/server-tests.txt').read_text(encoding='utf-8-sig')
    assert 'RESULT power server PASS 47' in tests
    for row in sm['overlay']:assert sha(stage/row['path'])==row['sha256'],row['path']
    allowed={r['path'].replace('\\','/') for r in sm['overlay']}|{f'Bin64/{n}' for n in NAMES}
    changed=[r for r in sorted(allowed) if not(play/r).exists() or sha(stage/r)!=sha(play/r)]
    print('PASS exact gameplay, relog, server transactions; changed files',len(changed))
    if not a.apply:return
    idle();stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S');backup=ROOT/'Build/backups/power-play'/stamp;backup.mkdir(parents=True)
    files=[]
    for rel in changed+['Bin64/game_data_stage.json']:
        path=play/rel;entry={'path':rel,'existed':path.exists()}
        if path.exists():
            entry['before']=sha(path);out=backup/rel;out.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,out)
        files.append(entry)
    for rel in changed:
        dst=play/rel;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(stage/rel,dst);assert sha(dst)==sha(stage/rel)
    proof={'at':stamp,'game':sha(stage/'Bin64/Game.exe'),'backup':str(backup),'checks':proofs,'files':files,
           'limits':['CY school advancement meridians inactive: no costs charged',
                     'Pet soul attribute/color locks are not exposed by the integrated window; reward counters retained in native NPC menu',
                     'Soul grade/max-level boundaries checked in native Lua tests, not every combination played live']}
    pm['binaries']=sm['binaries'];pm['overlay']=sm['overlay'];pm['power_candidate']=sm['power_candidate'];pm['power_update']=proof
    (play/'Bin64/game_data_stage.json').write_text(json.dumps(pm,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
    binaries(play,pm)
    for row in pm['overlay']:assert sha(play/row['path'])==row['sha256'],row['path']
    (backup/'deployment.json').write_text(json.dumps(proof,ensure_ascii=False,indent=2),encoding='utf8')
    print('Published',play,'backup',backup)

if __name__=='__main__':main()
