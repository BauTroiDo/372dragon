"""Isolate a complete candidate from the current Play build and preserve its HJ pack."""
from pathlib import Path
import argparse,datetime,json,shutil,subprocess
from publish_gameplay_fixes import ROOT,NAMES as UI_NAMES,sha
from deploy_mount_flight import idle,binaries
from dual_souls_data import tables,PLAY,live
from hj_appearance_data import RawTable
import dual_souls_ui as ui
from verify_dual_souls_evidence import combat, relogin as check_relogin
STAGE=ROOT/'Build/world-gui/stage-dual-souls-25'
LOG=ROOT/'Build/Logs/2026-09-25-dual-souls'
NAMES=UI_NAMES+('Render.dll','Render.pdb')
def overlays():
 out={};data=tables()
 for side in ['Pre','Post']:
  for rel,content in data.items():
   if rel.startswith('client/'):out[f'Overlay/{side}/ConfigFolder/'+rel.split('/',1)[1]]=content
  out[f'Overlay/{side}/InterfaceFolder/CysDualSouls/CysDualSouls.lua']=ui.LUA.encode()
  out[f'Overlay/{side}/InterfaceFolder/CysDualSouls/CysDualSouls.layout.xml']=ui.layout()
  for name,fn in [('Wuhun',ui.wuhun),('SelfEquip',ui.selfequip),('TargetEquip',ui.inspect)]:
   rel=f'Overlay/{side}/InterfaceFolder/{name}/{name}.layout.xml';out[rel]=fn(ui.baseline(rel))
  rel=f'Overlay/{side}/InterfaceFolder/SelfEquip/SelfEquip.lua';out[rel]=ui.baseline(rel)+ui.SELF_LUA.encode()
  rel=f'Overlay/{side}/InterfaceFolder/TargetEquip/TargetEquip.lua';out[rel]=ui.baseline(rel)+ui.INSPECT_LUA.encode()
  rel=f'Overlay/{side}/ConfigFolder/InterfaceEx.txt';ui.baseline(rel)
  table=RawTable(LOG/'ui-baseline'/rel);row=table.byid[next(r[0] for r in table.rows if r[1]==b'CysEquipCraft')].copy()
  row[0]=max(table.byid)+1;row[1]=b'CysDualSouls';row[2]=b'CysDualSouls/CysDualSouls.layout.xml';row[3]=b'CysDualSouls/CysDualSouls.lua';row[9]='Võ hồn · Chiến hồn'.encode()
  out[f'Overlay/{side}/ConfigFolder/InterfaceEx.txt']=table.extend([row])
 rel='Overlay/Post/ModelFolder/cys_hj_riders.obj';out[rel]=ui.actors(ui.baseline(rel))
 return out
def stage():
 idle();LOG.mkdir(parents=True,exist_ok=True)
 baseline=STAGE/'dual_souls_baseline.json'
 if not STAGE.exists():
  STAGE.mkdir()
  for name in ['Bin64','Overlay','Patch']:shutil.copytree(PLAY/name,STAGE/name)
  shutil.copy2(PLAY/'Play.cmd',STAGE/'Play.cmd')
  subprocess.run(['powershell','-NoProfile','-Command',f"New-Item -ItemType Junction -Path '{STAGE/'Data'}' -Target '{ROOT/'Assets/CanonicalCY/Data'}' | Out-Null"],check=True)
  baseline.write_text(json.dumps({'game':sha(PLAY/'Bin64/Game.exe'),'manifest':sha(PLAY/'Bin64/game_data_stage.json')}))
 m=json.loads((STAGE/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
 for row in m['binaries']:
  if row['name'] in NAMES:
   p=STAGE/'Bin64'/row['name'];shutil.copy2(ROOT/'Build/cmake/coord-x64/bin'/row['name'],p);row.update(sha256=sha(p),bytes=p.stat().st_size)
 # Symbols are copied even when the runtime manifest lists executable images only.
 for name in NAMES:
  if name.endswith('.pdb'):shutil.copy2(ROOT/'Build/cmake/coord-x64/bin'/name,STAGE/'Bin64'/name)
 for rel,content in overlays().items():
  p=STAGE/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(content)
  row=next((r for r in m['overlay'] if r['path']==rel),None)
  if row is None:row={'path':rel,'origin':'dual_souls_data.py / dual_souls_ui.py','reason':'Independent support/assault prototype'};m['overlay'].append(row)
  row.update(sha256=sha(p),bytes=p.stat().st_size)
 m['dual_souls']={'schema':1,'support_slot':18,'assault_slot':39}
 (STAGE/'Bin64/game_data_stage.json').write_text(json.dumps(m,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
 binaries(STAGE,m);print('Staged',STAGE,'Game',sha(STAGE/'Bin64/Game.exe'))
def publish(check,relogin):
 idle();m=json.loads((STAGE/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
 evidence={'combat':combat(check),'relogin':check_relogin(relogin)}
 for folder,marker in [(check,'RESULT'),(relogin,'RELOGIN')]:
  r=json.loads((folder/'run.json').read_text(encoding='utf-8-sig'));assert r['passed'] and r['game_sha256']==sha(STAGE/'Bin64/Game.exe') and r['stage_manifest_sha256']==sha(STAGE/'Bin64/game_data_stage.json')
  s=(folder/'WXClient.log').read_text(encoding='utf8',errors='replace');assert f'CYS-DUAL-SOULS: {marker} errors=0' in s and 'CYS-DUAL-SOULS: FAIL' not in s
 assert json.loads((LOG/'restore-result.json').read_text())['full_bson_equal']
 assert (LOG/'persistent-result.json').exists()
 b=json.loads((STAGE/'dual_souls_baseline.json').read_text());assert sha(PLAY/'Bin64/Game.exe')==b['game'] and sha(PLAY/'Bin64/game_data_stage.json')==b['manifest']
 for row in m['overlay']:assert sha(STAGE/row['path'])==row['sha256'],row['path']
 binaries(STAGE,m)
 current=json.loads((PLAY/'Bin64/game_data_stage.json').read_text(encoding='utf8'));changed=set(overlays())
 for row in current['overlay']:
  if row['path'] not in changed:assert sha(PLAY/row['path'])==sha(STAGE/row['path'])
 stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S');backup=ROOT/'Build/backups/dual-souls-play'/stamp;backup.mkdir(parents=True)
 paths=[f'Bin64/{n}' for n in NAMES]+sorted(changed)+['Bin64/game_data_stage.json']
 for rel in paths:
  if (PLAY/rel).exists():p=backup/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(PLAY/rel,p)
 for rel in paths:
  p=PLAY/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(STAGE/rel,p)
 report={'backup':str(backup),'game':sha(PLAY/'Bin64/Game.exe'),'render':sha(PLAY/'Bin64/Render.dll'),'manifest':sha(PLAY/'Bin64/game_data_stage.json'),'check':str(check),'relogin':str(relogin),'evidence':evidence}
 (LOG/'release-report.json').write_text(json.dumps(report,indent=2));print('Published',report)
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('mode',choices=['stage','publish']);p.add_argument('--check',type=Path);p.add_argument('--relogin',type=Path);a=p.parse_args()
 if a.mode=='stage':stage()
 else:assert a.check and a.relogin;publish(a.check,a.relogin)
