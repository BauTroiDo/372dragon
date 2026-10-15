"""Publish the verified forge candidate; preserve unrelated Play overlays and profile."""
from pathlib import Path
import argparse,datetime,json,shutil,struct
from publish_gameplay_fixes import ROOT,NAMES,sha
from deploy_npc_icons import idle,binaries

def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--checks',nargs='+',type=Path,required=True);p.add_argument('--apply',action='store_true');a=p.parse_args()
 stage=ROOT/'Build/world-gui/stage-forge-23';play=ROOT/'Build/world-gui/stage-play-21'
 sm=json.loads((stage/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
 pm=json.loads((play/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
 binaries(stage,sm);binaries(play,pm);logs=[]
 for folder in a.checks:
  run=json.loads((folder/'run.json').read_text(encoding='utf-8-sig'))
  assert run['passed'] and run['game_sha256']==sha(stage/'Bin64/Game.exe'),folder
  assert run['stage_manifest_sha256']==sha(stage/'Bin64/game_data_stage.json'),folder
  log=(folder/'WXClient.log').read_text(encoding='utf8',errors='replace')
  for bad in ['CYS-FORGE-PROBE: FAIL','CYS-FORGE: Lua error','CYS Lua failure']:
   assert bad not in log,(folder,bad)
  logs.append(log)
 joined='\n'.join(logs)
 for marker in ['RESULT real drag + cost + miss + eight hits + cap9 + Escape errors=0',
                'RESULT cancel delevel + leave charged pending errors=0',
                'RESULT relogin abandoned level0 unlocked + movement errors=0',
                'PASS position actually changed after forge closed']:
  assert marker in joined,marker
 allowed={f'Bin64/{n}' for n in NAMES}
 for side in ['Pre','Post']:
  allowed.add(f'Overlay/{side}/ConfigFolder/UICommandIndex.txt')
  allowed|={f'Overlay/{side}/InterfaceFolder/{rel}' for rel in [
   'EquipStrengthen/EquipStrengthen.lua','EquipStrengthen/EquipStrengthen.layout.xml',
   'Common/CysForgeArt.imageset.xml','Common/forge-anvil-hammer.png','Schema/WoWLookSkin.scheme.xml']}
 changed=[]
 for rel in sorted(allowed):
  assert (stage/rel).is_file(),rel
  if not (play/rel).exists() or sha(stage/rel)!=sha(play/rel):changed.append(rel)
 for row in sm['overlay']:
  rel=row['path'].replace('\\','/');assert sha(stage/rel)==row['sha256'],rel
  if rel not in allowed:assert sha(play/rel)==row['sha256'],rel
 assert sm['configs']==pm['configs']
 # Every original command route must remain byte-identical; only the appended
 # private response route is allowed, even if another task changed Play meanwhile.
 for side in ['Pre','Post']:
  rel=f'Overlay/{side}/ConfigFolder/UICommandIndex.txt'
  data=(stage/rel).read_bytes();count=struct.unpack_from('<I',data,8)[0]
  row=struct.unpack_from('<3I',data,28+(count-1)*12);assert row[1]==990023
  base=bytearray(data[:28+(count-1)*12]+data[28+count*12:]);struct.pack_into('<I',base,8,count-1)
  original=play/rel
  if not original.exists():original=ROOT/'Assets/CanonicalCY/Data/ConfigFolder/UICommandIndex.txt'
  assert bytes(base)==original.read_bytes() or data==original.read_bytes(),'existing UI routes changed; rebuild candidate'
 for n in NAMES:assert sha(ROOT/'Build/cmake/coord-x64/bin'/n)==sha(stage/'Bin64'/n),n
 print('PASS exact candidate rules, pointer drag, Space, cancellation, persistence, movement; files',len(changed))
 if not a.apply:return
 idle();stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
 backup=ROOT/'Build/backups/forge-play'/stamp;backup.mkdir(parents=True)
 launcher=play/'Bin64/Run-CY-Server.cmd';raw=launcher.read_bytes();anchor=b'set "CYS_WORLD_REPLAY="'
 assert raw.count(anchor)==1
 line=b'set "CYS_FORGE_LIVE="'
 if line not in raw:raw=raw.replace(anchor,anchor+b'\r\n'+line,1)
 rows=[]
 for rel in changed+['Bin64/game_data_stage.json','Bin64/Run-CY-Server.cmd']:
  dst=play/rel;row={'path':rel,'existed':dst.exists()}
  if dst.exists():
   row['before']=sha(dst);saved=backup/rel;saved.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dst,saved)
  rows.append(row)
 for rel in changed:
  dst=play/rel;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(stage/rel,dst);assert sha(dst)==sha(stage/rel)
 launcher.write_bytes(raw);pm['binaries']=sm['binaries']
 overlays={r['path'].replace('\\','/'):r for r in pm['overlay']}
 for row in sm['overlay']:
  if row['path'].replace('\\','/') in allowed:overlays[row['path'].replace('\\','/')]=row
 pm['overlay']=list(overlays.values())
 for row in pm['wsl_test']['launchers']:
  if row['path']=='Bin64/Run-CY-Server.cmd':row.update(sha256=sha(launcher),bytes=launcher.stat().st_size)
 proof={'at':stamp,'backup':str(backup),'checks':[str(f.resolve()) for f in a.checks],
        'game':sha(stage/'Bin64/Game.exe'),'files':rows,'rules':sm['forge_candidate']}
 pm['forge_update']=proof
 (play/'Bin64/game_data_stage.json').write_text(json.dumps(pm,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
 binaries(play,pm)
 for row in pm['overlay']:assert sha(play/row['path'])==row['sha256'],row['path']
 (backup/'deployment.json').write_text(json.dumps(proof,ensure_ascii=False,indent=2),encoding='utf8')
 print('Published',play,'backup',backup)
if __name__=='__main__':main()
