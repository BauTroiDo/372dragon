"""Publish only a progression candidate proven by live gameplay checks."""
from pathlib import Path
import argparse,datetime,json,shutil
from publish_gameplay_fixes import ROOT,NAMES,sha
from deploy_npc_icons import idle,binaries

def main():
    p=argparse.ArgumentParser();p.add_argument('--checks',nargs='+',type=Path,required=True);p.add_argument('--apply',action='store_true');a=p.parse_args()
    stage=ROOT/'Build/world-gui/stage-progression-24';play=ROOT/'Build/world-gui/stage-play-21'
    sm=json.loads((stage/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
    pm=json.loads((play/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
    binaries(stage,sm);binaries(play,pm);proofs=[];logs=[];exact=False
    for folder in a.checks:
        run=json.loads((folder/'run.json').read_text(encoding='utf-8-sig'))
        log=(folder/'WXClient.log').read_text(encoding='utf8',errors='replace')
        ui=(folder/'UISystem.log').read_text(encoding='utf8',errors='replace')
        assert run['passed'],folder
        for bad in ['CYS-ROUND2-PROBE: FAIL','CYS-QUICKBAR: FAIL','CYS Lua failure']:
            assert bad not in log,(folder,bad)
        for name in ['MainMenuBar_2','AutoAttackSkill']:
            assert "window '"+name+"' not loaded" not in ui,(folder,name)
        exact|=run['game_sha256']==sha(stage/'Bin64/Game.exe') and run['stage_manifest_sha256']==sha(stage/'Bin64/game_data_stage.json')
        proofs.append({'folder':str(folder.resolve()),'game':run['game_sha256'],'manifest':run['stage_manifest_sha256']});logs.append(log)
    combined='\n'.join(logs)
    for required in ['RESULT level200 cap GM test15 movement errors=0','RESULT level200 relog errors=0',
                     'RESULT automatic battle kill EXP stop manual movement errors=0',
                     'automatic potion consumes existing inventory',
                     'RESULT EXP3b positive auto settings persist stopped on relog errors=0',
                     'RESULT fifty slots + pointer drag + F pages + Alt keys errors=0']:
        assert required in combined,required
    assert exact,'no proof on exact current binary and overlays'
    for row in sm['overlay']:assert sha(stage/row['path'])==row['sha256'],row['path']
    allowed={r['path'].replace('\\','/') for r in sm['overlay']}|{f'Bin64/{n}' for n in NAMES}
    changed=[r for r in sorted(allowed) if not(play/r).exists() or sha(stage/r)!=sha(play/r)]
    print('PASS functional and layout checks; exact candidate; changed files',len(changed))
    if not a.apply:return
    idle();stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S');backup=ROOT/'Build/backups/progression-play'/stamp;backup.mkdir(parents=True)
    files=[]
    for rel in changed+['Bin64/game_data_stage.json']:
        path=play/rel;entry={'path':rel,'existed':path.exists()}
        if path.exists():
            entry['before']=sha(path);out=backup/rel;out.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,out)
        files.append(entry)
    for rel in changed:
        path=play/rel;path.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(stage/rel,path);assert sha(path)==sha(stage/rel)
    pm['binaries']=sm['binaries'];pm['overlay']=sm['overlay'];pm['progression_candidate']=sm['progression_candidate']
    proof={'at':stamp,'game':sha(stage/'Bin64/Game.exe'),'backup':str(backup),'checks':proofs,'files':files,
        'scope':['character200','GM existing test00..test15','transparent Alt cells','Farm automatic battle'],
        'limits':['Talent CY versus GL choice pending; talent not complete','Wuyi counter absent; disabled in UI','automatic dungeon route FB not implemented','not every school/pet/team combination played live']}
    pm['progression_update']=proof
    (play/'Bin64/game_data_stage.json').write_text(json.dumps(pm,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
    binaries(play,pm)
    for row in pm['overlay']:assert sha(play/row['path'])==row['sha256'],row['path']
    (backup/'deployment.json').write_text(json.dumps(proof,ensure_ascii=False,indent=2),encoding='utf8')
    print('Published',play,'backup',backup)

if __name__=='__main__':main()
