"""Candidate/publish with exact executable evidence and untouched Play guards."""
from pathlib import Path
import argparse,datetime,json,shutil,subprocess
from deploy_mount_flight import idle,binaries
from publish_gameplay_fixes import ROOT,sha
from smart_equip_ui import patch
PLAY=ROOT/'Build/world-gui/stage-play-21';STAGE=ROOT/'Build/world-gui/stage-smart-equip-25'
LOG=ROOT/'Build/Logs/2026-09-25-smart-equip'
OVERLAYS=[f'Overlay/{s}/InterfaceFolder/SelfEquip/SelfEquip.lua' for s in ['Pre','Post']]
PATHS=['Bin64/Game.exe','Bin64/Game.pdb','Bin64/game_data_stage.json']+OVERLAYS
def stage():
 idle();LOG.mkdir(parents=True,exist_ok=True)
 if not STAGE.exists():
  STAGE.mkdir()
  for name in ['Bin64','Overlay','Patch']:shutil.copytree(PLAY/name,STAGE/name)
  shutil.copy2(PLAY/'Play.cmd',STAGE/'Play.cmd')
  subprocess.run(['powershell','-NoProfile','-Command',f"New-Item -ItemType Junction -Path '{STAGE/'Data'}' -Target '{ROOT/'Assets/CanonicalCY/Data'}' | Out-Null"],check=True)
  (LOG/'baseline.json').write_text(json.dumps({p:sha(PLAY/p) for p in PATHS}))
 for rel in OVERLAYS:
  p=LOG/'baseline'/rel
  if not p.exists():p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(PLAY/rel,p)
  (STAGE/rel).write_bytes(patch(p.read_bytes()))
 for n in ['Game.exe','Game.pdb']:shutil.copy2(ROOT/'Build/cmake/coord-x64/bin'/n,STAGE/'Bin64'/n)
 m=json.loads((STAGE/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
 for row in m['binaries']:
  if row['name'] in ['Game.exe','Game.pdb']:
   p=STAGE/'Bin64'/row['name'];row.update(sha256=sha(p),bytes=p.stat().st_size)
 for row in m['overlay']:
  if row['path'] in OVERLAYS:
   p=STAGE/row['path'];row.update(sha256=sha(p),bytes=p.stat().st_size,origin='smart_equip_ui.py')
 m['smart_equip']={'mission_fields':[602,603],'paired_slot_server_reply':True}
 (STAGE/'Bin64/game_data_stage.json').write_text(json.dumps(m,ensure_ascii=False,indent=1)+'\n',encoding='utf8');binaries(STAGE,m)
 print('Staged',STAGE,'Game',sha(STAGE/'Bin64/Game.exe'))
def publish(check,relogin):
 idle();m=json.loads((STAGE/'Bin64/game_data_stage.json').read_text(encoding='utf8'));binaries(STAGE,m)
 for folder,marker in [(check,'RESULT'),(relogin,'RELOGIN')]:
  r=json.loads((folder/'run.json').read_text(encoding='utf-8-sig'));assert r['passed'] and r['game_sha256']==sha(STAGE/'Bin64/Game.exe') and r['stage_manifest_sha256']==sha(STAGE/'Bin64/game_data_stage.json')
  s=(folder/'WXClient.log').read_text(encoding='utf8',errors='replace');assert f'CYS-SMART-EQUIP: {marker} errors=0' in s and 'CYS-SMART-EQUIP: FAIL' not in s
 assert json.loads((LOG/'restore-result.json').read_text())['full_bson_equal']
 assert json.loads((LOG/'persistent-result.json').read_text())['metadata_preserved']
 for p,h in json.loads((LOG/'baseline.json').read_text()).items():assert sha(PLAY/p)==h,p
 for row in m['overlay']:
  assert sha(STAGE/row['path'])==row['sha256'],row['path']
  if row['path'] not in OVERLAYS:assert sha(STAGE/row['path'])==sha(PLAY/row['path'])
 backup=ROOT/'Build/backups/smart-equip-play'/datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
 for rel in PATHS:
  p=backup/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(PLAY/rel,p)
 for rel in PATHS:shutil.copy2(STAGE/rel,PLAY/rel)
 report={'backup':str(backup),'game':sha(PLAY/'Bin64/Game.exe'),'manifest':sha(PLAY/'Bin64/game_data_stage.json'),'gui':str(check),'relogin':str(relogin)}
 (LOG/'release-report.json').write_text(json.dumps(report,indent=2));print('Published',report)
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('mode',choices=['stage','publish']);p.add_argument('--check',type=Path);p.add_argument('--relogin',type=Path);a=p.parse_args()
 if a.mode=='stage':stage()
 else:assert a.check and a.relogin;publish(a.check,a.relogin)
