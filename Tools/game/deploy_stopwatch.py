"""Stage/publish the shared stopwatch formatting fix, with a real bank GUI check."""
from pathlib import Path
import argparse,datetime,json,shutil,subprocess
from deploy_mount_flight import idle,binaries
from publish_gameplay_fixes import ROOT,sha
PLAY=ROOT/'Build/world-gui/stage-play-21';STAGE=ROOT/'Build/world-gui/stage-stopwatch-28'
LOG=ROOT/'Build/Logs/2026-09-28-hj05-remaining';OUT=LOG/'stopwatch'
NAMES=('CEGUIFalagard.dll','CEGUIFalagard.pdb')
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def main():
 p=argparse.ArgumentParser();p.add_argument('mode',choices=['stage','check','publish']);p.add_argument('--gui',type=Path);a=p.parse_args()
 idle();OUT.mkdir(exist_ok=True)
 if a.mode=='stage':
  assert not STAGE.exists(),'Preserve the prior candidate; do not replace a tested stage'
  baseline=dict(game=sha(PLAY/'Bin64/Game.exe'),manifest=sha(PLAY/'Bin64/game_data_stage.json'))
  (OUT/'baseline.json').write_text(json.dumps(baseline))
  STAGE.mkdir()
  for folder in ('Bin64','Patch','Overlay'):shutil.copytree(PLAY/folder,STAGE/folder)
  shutil.copy2(PLAY/'Play.cmd',STAGE/'Play.cmd')
  subprocess.run(['powershell','-NoProfile','-Command',f"New-Item -ItemType Junction -Path '{STAGE/'Data'}' -Target '{(PLAY/'Data').resolve()}' | Out-Null"],check=True)
  m=read(PLAY/'Bin64/game_data_stage.json')
  for row in m['binaries']:
   if row['name'] in NAMES:
    dst=STAGE/'Bin64'/row['name'];shutil.copy2(ROOT/'Build/cmake/coord-x64/bin'/row['name'],dst)
    row.update(sha256=sha(dst),bytes=dst.stat().st_size)
  (STAGE/'Bin64/game_data_stage.json').write_text(json.dumps(m,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
  binaries(STAGE,m);print('Staged stopwatch DLL',sha(STAGE/'Bin64/CEGUIFalagard.dll'));return
 assert a.gui
 baseline=read(OUT/'baseline.json');before=read(PLAY/'Bin64/game_data_stage.json');after=read(STAGE/'Bin64/game_data_stage.json')
 assert sha(PLAY/'Bin64/Game.exe')==baseline['game'] and sha(PLAY/'Bin64/game_data_stage.json')==baseline['manifest']
 binaries(PLAY,before);binaries(STAGE,after)
 old={r['name']:r['sha256'] for r in before['binaries']};new={r['name']:r['sha256'] for r in after['binaries']}
 assert old.keys()==new.keys() and all(old[n]==new[n] for n in old if n not in NAMES)
 for n in NAMES:assert new[n]==sha(ROOT/'Build/cmake/coord-x64/bin'/n)
 assert {k:v for k,v in before.items() if k!='binaries'}=={k:v for k,v in after.items() if k!='binaries'}
 for folder in ('Overlay','Patch'):
  for f in (STAGE/folder).rglob('*'):
   if f.is_file():assert sha(f)==sha(PLAY/f.relative_to(STAGE)),f
 r=read(a.gui/'run.json');log=(a.gui/'WXClient.log').read_text(encoding='utf8',errors='replace')
 assert r['passed'] and all(r['checks'].values()) and r['game_sha256']==new['Game.exe']
 assert r['stage_manifest_sha256']==sha(STAGE/'Bin64/game_data_stage.json')
 assert 'CYS-POWER-SYSTEMS: RESULT mode=5 errors=0' in log and 'CYS-POWER-SYSTEMS: FAIL' not in log and 'CYS Lua failure' not in log
 assert read(a.gui/'server-check.json')['passed']
 review=read(OUT/'visual-review.json');assert review['seconds_in_range'] and review['text']=='4:59'
 assert sha(a.gui/review['image'])==review['sha256']
 for fixture in ('remaining_shop_fixture.py','remaining_soul_fixture.py'):
  subprocess.run(['wsl','-d','TLBB','-u','root','--','python3','/mnt/c/TLBB/085/CY-Source/Tools/server/'+fixture,'verify'],check=True)
 if a.mode=='check':print('PASS stopwatch DLL, bank GUI, 4:59 visual check, exact fixture restoration');return
 stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S');backup=ROOT/'Build/backups/stopwatch-play'/stamp;backup.mkdir(parents=True)
 for n in NAMES+('game_data_stage.json',):shutil.copy2(PLAY/'Bin64'/n,backup/n)
 for n in NAMES:shutil.copy2(STAGE/'Bin64'/n,PLAY/'Bin64'/n)
 evidence=dict(at=stamp,backup=str(backup),gui=str(a.gui.resolve()),game_sha256=new['Game.exe'],
               dll_sha256=new['CEGUIFalagard.dll'],tested_manifest_sha256=r['stage_manifest_sha256'])
 after['stopwatch_update']=evidence
 (PLAY/'Bin64/game_data_stage.json').write_text(json.dumps(after,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
 binaries(PLAY,after);(OUT/'release-report.json').write_text(json.dumps(evidence,indent=2))
 print('Published stopwatch DLL, backup',backup)
if __name__=='__main__':main()
