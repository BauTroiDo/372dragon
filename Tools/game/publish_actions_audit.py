"""Publish only the measured action/equipment candidate, with a complete file backup."""
from pathlib import Path
import argparse,datetime,json,re,shutil
from publish_gameplay_fixes import ROOT,NAMES,sha
from deploy_npc_icons import idle,binaries

def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--checks',nargs='+',type=Path,required=True);p.add_argument('--apply',action='store_true');a=p.parse_args()
 stage=ROOT/'Build/world-gui/stage-actions-23';play=ROOT/'Build/world-gui/stage-play-21'
 sm=json.loads((stage/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
 pm=json.loads((play/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
 binaries(stage,sm);binaries(play,pm)
 combined=[]
 for folder in a.checks:
  run=json.loads((folder/'run.json').read_text(encoding='utf-8-sig'))
  assert run['passed'] and run['game_sha256']==sha(stage/'Bin64/Game.exe'),folder
  log=(folder/'WXClient.log').read_text(encoding='utf8',errors='replace')
  if run['stage_manifest_sha256']!=sha(stage/'Bin64/game_data_stage.json'):
   # The combat run predates a shop-only visibility correction. Its exact
   # manifest was saved before that edit; require identical code, FX and configs.
   saved=folder/'candidate_manifest.json';assert sha(saved)==run['stage_manifest_sha256']
   old=json.loads(saved.read_text(encoding='utf8'))
   assert {k:v for k,v in old.items() if k!='overlay'}=={k:v for k,v in sm.items() if k!='overlay'}
   arows={r['path'].replace('\\','/'):r for r in old['overlay']}
   brows={r['path'].replace('\\','/'):r for r in sm['overlay']}
   assert arows.keys()==brows.keys()
   assert all('/InterfaceFolder/YuanbaoShop/' in k for k in arows if arows[k]!=brows[k])
   assert 'RESULT skill=4515' in log and 'CYS-NBSHOP-LIVE: enabled' not in log
  for bad in ['CYS-QUICKBAR: FAIL','CYS-NBSHOP-LIVE: PRECONDITION','CYS-CELL-SKIN: FAIL','CYS Lua failure']:
   assert bad not in log,(folder,bad)
  combined.append(log)
 logs='\n'.join(combined)
 for marker in ['RESULT fifty slots + pointer drag + F pages + Alt keys errors=0',
                'relogin fifty slots restored','RESULT item drag/move/consume/rebind/empty errors=0',
                'PASS wardrobe mount shelf empty with visible notice','CYS-CELL-SKIN: RESULT errors=0']:
  assert marker in logs,marker
 assert 'RESULT skill=4515' in logs
 assert re.search(r'CYS-BULLETLIVE: repeat-release .*age=7\d\d\b',logs),'repeated attack release not measured'
 # Require a measured projectile impact before EXP, not only a successful login.
 combat=next(s for s in combined if 'RESULT skill=4515' in s)
 hit=re.search(r'CYS-BULLETLIVE: hit t=(\d+)',combat)
 exp=re.search(r'GCDetailExp t=(\d+) exp=[1-9]',combat)
 assert hit and exp and int(hit[1])<int(exp[1]),'EXP must follow projectile hit'
 permitted={f'Bin64/{n}' for n in NAMES}|{'Bin64/WXResources.cfg'}
 for side in ['Pre','Post']:
  permitted|={f'Overlay/{side}/InterfaceFolder/{folder}/{name}' for folder,names in [
   ('SelfEquip',['SelfEquip.layout.xml','SelfEquip.lua']),('YuanbaoShop',['YuanbaoShop.layout.xml','YuanbaoShop.lua'])] for name in names}
 permitted|={f'Overlay/Post/EffectFolder/{n}' for n in ['all.skill','all.effect','all.particle']}
 changed=[]
 for rel in sorted(permitted):
  src=stage/rel;assert src.is_file(),rel
  if not (play/rel).exists() or sha(src)!=sha(play/rel):changed.append(rel)
 for row in sm['overlay']:
  rel=row['path'].replace('\\','/');assert sha(stage/rel)==row['sha256'],rel
  if rel not in permitted:assert (play/rel).is_file() and sha(play/rel)==row['sha256'],rel
 assert sm['configs']['WXResources.cfg']==sha(stage/'Bin64/WXResources.cfg')
 for name in NAMES:assert sha(ROOT/'Build/cmake/coord-x64/bin'/name)==sha(stage/'Bin64'/name),name
 print('PASS exact candidate: skill/items/relogin/skin/shop/Jue impact before EXP; files',len(changed))
 if not a.apply:return
 idle();stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
 backup=ROOT/'Build/backups/actions-equipment-play'/stamp;backup.mkdir(parents=True)
 launcher=play/'Bin64/Run-CY-Server.cmd';raw=launcher.read_bytes();anchor=b'set "CYS_WORLD_REPLAY="'
 assert raw.count(anchor)==1
 for flag in ['CYS_QUICKBAR_LIVE','CYS_NBSHOP_LIVE','CYS_NBSHOP_EMPTY_LIVE','CYS_SKILL_LIVE','CYS_SKILL_ID',
              'CYS_SKILL_RANGE','CYS_SKILL_COOL_KEY','CYS_BULLET_LOG','CYS_SFX_LOG']:
  line=('set "'+flag+'="').encode();
  if line not in raw:raw=raw.replace(anchor,anchor+b'\r\n'+line,1)
 metadata=[]
 for rel in changed+['Bin64/game_data_stage.json','Bin64/Run-CY-Server.cmd']:
  dst=play/rel;row={'path':rel,'existed':dst.exists()}
  if dst.exists():
   row['before']=sha(dst);saved=backup/rel;saved.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dst,saved)
  metadata.append(row)
 for rel in changed:
  dst=play/rel;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(stage/rel,dst);assert sha(dst)==sha(stage/rel)
 launcher.write_bytes(raw)
 pm['binaries']=sm['binaries'];pm['configs']['WXResources.cfg']=sm['configs']['WXResources.cfg']
 rows={r['path'].replace('\\','/'):r for r in pm['overlay']}
 for row in sm['overlay']:
  if row['path'].replace('\\','/') in permitted:rows[row['path'].replace('\\','/')]=row
 pm['overlay']=list(rows.values());pm['cy_selfequip_readability']=sm['cy_selfequip_readability']
 for row in pm['wsl_test']['launchers']:
  if row['path']=='Bin64/Run-CY-Server.cmd':row.update(sha256=sha(launcher),bytes=launcher.stat().st_size)
 proof={'at':stamp,'backup':str(backup),'checks':[str(f.resolve()) for f in a.checks],
        'game':sha(stage/'Bin64/Game.exe'),'files':metadata,'jue_hit':int(hit[1]),'jue_exp':int(exp[1])}
 pm['actions_equipment_update']=proof
 (play/'Bin64/game_data_stage.json').write_text(json.dumps(pm,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
 binaries(play,pm)
 for row in pm['overlay']:assert sha(play/row['path'])==row['sha256'],row['path']
 (backup/'deployment.json').write_text(json.dumps(proof,ensure_ascii=False,indent=2),encoding='utf8')
 print('Published',play,'backup',backup)

if __name__=='__main__':main()
