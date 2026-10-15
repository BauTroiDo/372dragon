"""Stage and publish soul appearance only after exact-binary functional and relogin checks."""
from pathlib import Path
import argparse,datetime,json,shutil,subprocess
from publish_gameplay_fixes import ROOT,NAMES,sha
from deploy_mount_flight import idle,binaries
from wuhun_appearance_ui import layout,lua
PLAY=ROOT/'Build/world-gui/stage-play-21';STAGE=ROOT/'Build/world-gui/stage-wuhun-appearance-25'
ASSETS=ROOT/'Build/Logs/2026-09-25-wuhun-appearance/assets';BUILD=ROOT/'Build/cmake/coord-x64/bin'
def overlays():
 out={}
 for side in ['Pre','Post']:
  for ext,fn in [('lua',lua),('layout.xml',layout)]:
   rel=f'Overlay/{side}/InterfaceFolder/Wuhun/Wuhun.{ext}';out[rel]=fn((PLAY/rel).read_bytes())
  out[f'Overlay/{side}/ConfigFolder/CharModelEx.txt']=(ASSETS/'CharModelEx.txt').read_bytes()
 for folder in ['ModelFolder','MaterialFolder','EffectFolder']:
  for f in (ASSETS/folder).iterdir():out[f'Overlay/Post/{folder}/{f.name}']=f.read_bytes()
 return out
def main():
 p=argparse.ArgumentParser();p.add_argument('mode',choices=['stage','check','publish']);p.add_argument('--check',type=Path);p.add_argument('--relogin',type=Path);a=p.parse_args()
 baseline=STAGE/'appearance_baseline.json'
 if a.mode=='stage':
  idle()
  if not STAGE.exists():
   STAGE.mkdir()
   for folder in ['Bin64','Overlay','Patch']:shutil.copytree(PLAY/folder,STAGE/folder)
   shutil.copy2(PLAY/'Play.cmd',STAGE/'Play.cmd')
   subprocess.run(['powershell','-NoProfile','-Command',f"New-Item -ItemType Junction -Path '{STAGE/'Data'}' -Target '{ROOT/'Assets/CanonicalCY/Data'}' | Out-Null"],check=True)
   baseline.write_text(json.dumps({'manifest':sha(PLAY/'Bin64/game_data_stage.json'),'game':sha(PLAY/'Bin64/Game.exe')}),encoding='utf8')
  m=json.loads((STAGE/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
  for row in m['binaries']:
   if row['name'] in NAMES:
    dst=STAGE/'Bin64'/row['name'];shutil.copy2(BUILD/row['name'],dst);row.update(sha256=sha(dst),bytes=dst.stat().st_size)
  for rel,data in overlays().items():
   dst=STAGE/rel;dst.parent.mkdir(parents=True,exist_ok=True);dst.write_bytes(data)
   row=next((r for r in m['overlay'] if r['path']==rel),None)
   if row is None:row={'path':rel,'origin':'GL soul catalog, isolated dependency closure','reason':'wuhun appearance'};m['overlay'].append(row)
   row.update(sha256=sha(dst),bytes=dst.stat().st_size)
  cfg=STAGE/'Bin64/WXResources.cfg';data=cfg.read_bytes();line=b'FileSystem=*../Overlay/Post/ModelFolder'
  if line not in data:data=data.replace(b'[General]',b'[General]\r\n'+line)
  cfg.write_bytes(data);m['configs']['WXResources.cfg']=sha(cfg)
  m['wuhun_appearance_candidate']={'date':'2026-09-25','catalog':6,'appearances':36}
  (STAGE/'Bin64/game_data_stage.json').write_text(json.dumps(m,ensure_ascii=False,indent=1)+'\n',encoding='utf8');binaries(STAGE,m)
  print('Staged',STAGE,'Game',sha(STAGE/'Bin64/Game.exe'));return
 assert a.check and a.relogin
 tested=json.loads((STAGE/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
 for folder in [a.check,a.relogin]:
  run=json.loads((folder/'run.json').read_text(encoding='utf-8-sig'))
  assert run['passed'] and run['game_sha256']==sha(STAGE/'Bin64/Game.exe') and run['stage_manifest_sha256']==sha(STAGE/'Bin64/game_data_stage.json')
 log=(a.check/'WXClient.log').read_text(encoding='utf8',errors='replace')
 assert 'CYS-WUHUN-APPEARANCE: RESULT errors=0' in log and 'CYS-WUHUN-APPEARANCE: FAIL' not in log
 assert 'CYS Lua failure env=Wuhun_Env' not in log
 relog=(a.relogin/'WXClient.log').read_text(encoding='utf8',errors='replace')
 assert 'CYS-WUHUN-APPEARANCE: RELOGIN errors=0' in relog and 'CYS-WUHUN-APPEARANCE: FAIL' not in relog
 assert 'CYS-WUHUN: selection item=10156001 visual=750 object=cys_wh_' in relog
 assert (ROOT/'Build/Logs/2026-09-25-wuhun-appearance/persistent-result.json').exists()
 assert json.loads((ROOT/'Build/Logs/2026-09-25-wuhun-appearance/restore-result.json').read_text())['full_bson_equal']
 old=json.loads(baseline.read_text());assert sha(PLAY/'Bin64/game_data_stage.json')==old['manifest'] and sha(PLAY/'Bin64/Game.exe')==old['game']
 current=json.loads((PLAY/'Bin64/game_data_stage.json').read_text(encoding='utf8'));binaries(PLAY,current);binaries(STAGE,tested)
 for r in tested['overlay']:assert sha(STAGE/r['path'])==r['sha256'],r['path']
 changed=set(overlays())
 for r in current['overlay']:
  if r['path'] not in changed:assert sha(PLAY/r['path'])==sha(STAGE/r['path']),r['path']
 if a.mode=='check':print('PASS exact candidate and persistent costs');return
 idle();stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S');backup=ROOT/'Build/backups/wuhun-appearance-play'/stamp;backup.mkdir(parents=True)
 paths=[f'Bin64/{n}' for n in NAMES]+['Bin64/game_data_stage.json','Bin64/WXResources.cfg']+sorted(changed)
 for rel in paths:
  if (PLAY/rel).exists():dst=backup/rel;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(PLAY/rel,dst)
 for rel in paths:
  if rel=='Bin64/game_data_stage.json':continue
  dst=PLAY/rel;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(STAGE/rel,dst)
 tested['wuhun_appearance_update']={'at':stamp,'backup':str(backup),'check':str(a.check.resolve()),'relogin':str(a.relogin.resolve())}
 (PLAY/'Bin64/game_data_stage.json').write_text(json.dumps(tested,ensure_ascii=False,indent=1)+'\n',encoding='utf8');binaries(PLAY,tested)
 print('Published',PLAY,'backup',backup)
if __name__=='__main__':main()
