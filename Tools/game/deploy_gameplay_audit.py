"""Stage/publish quest/craft/xinfa repairs after exact-binary live checks."""
from pathlib import Path
import argparse,json,shutil,subprocess,datetime
from publish_gameplay_fixes import ROOT,sha
from deploy_mount_flight import idle,binaries
PLAY=ROOT/'Build/world-gui/stage-play-21'
STAGE=ROOT/'Build/world-gui/stage-gameplay-audit-27'
LOG=ROOT/'Build/Logs/2026-09-26-quest-craft-combat'
NAMES=('Game.exe','Game.pdb')
p=argparse.ArgumentParser();p.add_argument('mode',choices=['stage','publish']);p.add_argument('--checks',nargs='+',type=Path);a=p.parse_args()
idle()
if a.mode=='stage':
 if not STAGE.exists():
  STAGE.mkdir()
  for n in ['Bin64','Patch','Overlay']:shutil.copytree(PLAY/n,STAGE/n)
  shutil.copy2(PLAY/'Play.cmd',STAGE/'Play.cmd')
  subprocess.run(['powershell','-NoProfile','-Command',f"New-Item -ItemType Junction -Path '{STAGE/'Data'}' -Target '{ROOT/'Assets/CanonicalCY/Data'}' | Out-Null"],check=True)
 base=STAGE/'audit-baseline.json'
 if not base.exists():base.write_text(json.dumps({'manifest':sha(PLAY/'Bin64/game_data_stage.json'),'game':sha(PLAY/'Bin64/Game.exe')}))
 m=json.loads((STAGE/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
 for row in m['binaries']:
  if row['name']in NAMES:
   dest=STAGE/'Bin64'/row['name'];shutil.copy2(ROOT/'Build/cmake/coord-x64/bin'/row['name'],dest);row.update(sha256=sha(dest),bytes=dest.stat().st_size)
 (STAGE/'Bin64/game_data_stage.json').write_text(json.dumps(m,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
 binaries(STAGE,m);print('Staged',STAGE,'Game',sha(STAGE/'Bin64/Game.exe'));raise SystemExit
assert a.checks
candidate=json.loads((STAGE/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
base=json.loads((STAGE/'audit-baseline.json').read_text());assert sha(PLAY/'Bin64/game_data_stage.json')==base['manifest'] and sha(PLAY/'Bin64/Game.exe')==base['game']
current=json.loads((PLAY/'Bin64/game_data_stage.json').read_text(encoding='utf8'));binaries(STAGE,candidate);binaries(PLAY,current)
modes=set()
for f in a.checks:
 r=json.loads((f/'run.json').read_text(encoding='utf-8-sig'));log=(f/'WXClient.log').read_text(encoding='utf8',errors='replace')
 assert r['passed']and r['game_sha256']==sha(STAGE/'Bin64/Game.exe')and r['stage_manifest_sha256']==sha(STAGE/'Bin64/game_data_stage.json'),str(f)
 assert 'CYS-GAMEPLAY-AUDIT: FAIL'not in log and'CYS Lua failure'not in log,str(f)
 for mode in [1,2]:
  if f'CYS-GAMEPLAY-AUDIT: RESULT mode={mode} errors=0'in log:modes.add(mode)
assert modes=={1,2}
assert json.loads((LOG/'fixture-restore.json').read_text())['full_bson_equal']
for folder in ['Overlay','Patch']:
 for f in (STAGE/folder).rglob('*'):
  if f.is_file():assert sha(f)==sha(PLAY/f.relative_to(STAGE)),str(f)
stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S');backup=ROOT/'Build/backups/gameplay-audit-play'/stamp;backup.mkdir(parents=True)
for n in NAMES+('game_data_stage.json','Run-CY-Server.cmd'):shutil.copy2(PLAY/'Bin64'/n,backup/n)
for row in current['binaries']:
 if row['name']in NAMES:
  dest=PLAY/'Bin64'/row['name'];shutil.copy2(STAGE/'Bin64'/row['name'],dest);row.update(sha256=sha(dest),bytes=dest.stat().st_size)
launcher=PLAY/'Bin64/Run-CY-Server.cmd';raw=launcher.read_bytes();anchor=b'set "CYS_WORLD_REPLAY="';flag=b'set "CYS_GAMEPLAY_AUDIT_LIVE="';assert raw.count(anchor)==1
if flag not in raw:raw=raw.replace(anchor,anchor+b'\r\n'+flag)
launcher.write_bytes(raw)
for row in current['wsl_test']['launchers']:
 if row['path']=='Bin64/Run-CY-Server.cmd':row.update(sha256=sha(launcher),bytes=launcher.stat().st_size)
evidence={'at':stamp,'checks':[str(f.resolve())for f in a.checks],'backup':str(backup),'game':sha(PLAY/'Bin64/Game.exe')}
current['gameplay_audit_update']=evidence
(PLAY/'Bin64/game_data_stage.json').write_text(json.dumps(current,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
binaries(PLAY,current);(LOG/'release-report.json').write_text(json.dumps(evidence,indent=2));print('Published',evidence)
