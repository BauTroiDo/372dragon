"""Stage/publish the soul-only preview after a matching live GUI run."""
from pathlib import Path
import argparse,datetime,json,shutil,subprocess
from publish_gameplay_fixes import ROOT,NAMES,sha
from deploy_mount_flight import idle,binaries
PLAY=ROOT/'Build/world-gui/stage-play-21'
STAGE=ROOT/'Build/world-gui/stage-wuhun-preview-25'
BUILD=ROOT/'Build/cmake/coord-x64/bin'
LOG=ROOT/'Build/Logs/2026-09-25-wuhun-preview'
p=argparse.ArgumentParser();p.add_argument('mode',choices=['stage','check','publish']);p.add_argument('--check',type=Path);p.add_argument('--scale',action='store_true');a=p.parse_args()
if a.scale:STAGE=ROOT/'Build/world-gui/stage-wuhun-scale-25'
changed_overlays={Path(f'Overlay/{side}/InterfaceFolder/Wuhun/Wuhun.{ext}') for side in ['Pre','Post'] for ext in ['lua','layout.xml']} if a.scale else set()
baseline=STAGE/'wuhun_preview_baseline.json'
if a.mode=='stage':
 idle()
 if not STAGE.exists():
  STAGE.mkdir()
  for folder in ['Bin64','Overlay','Patch']:shutil.copytree(PLAY/folder,STAGE/folder)
  shutil.copy2(PLAY/'Play.cmd',STAGE/'Play.cmd')
  subprocess.run(['powershell','-NoProfile','-Command',f"New-Item -ItemType Junction -Path '{STAGE/'Data'}' -Target '{ROOT/'Assets/CanonicalCY/Data'}' | Out-Null"],check=True)
  baseline.write_text(json.dumps({'manifest':sha(PLAY/'Bin64/game_data_stage.json'),'game':sha(PLAY/'Bin64/Game.exe')})+'\n',encoding='utf8')
 m=json.loads((STAGE/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
 for row in m['binaries']:
  if row['name'] in NAMES:
   dst=STAGE/'Bin64'/row['name'];shutil.copy2(BUILD/row['name'],dst);row.update(sha256=sha(dst),bytes=dst.stat().st_size)
 m['wuhun_preview_candidate']={'model_source':'CharModelEx, not MonsterAttrExTable','date':'2026-09-25'}
 if a.scale:
  from power_ui import wuhun_lua,wuhun_layout
  for rel in changed_overlays:
   generate=wuhun_lua if rel.suffix=='.lua' else wuhun_layout
   dst=STAGE/rel;dst.write_bytes(generate((PLAY/rel).read_bytes()))
   row=next(r for r in m['overlay'] if Path(r['path'])==rel);row.update(sha256=sha(dst),bytes=dst.stat().st_size)
  m['wuhun_preview_candidate']['camera']=[0.08,1.0,0.21]
 (STAGE/'Bin64/game_data_stage.json').write_text(json.dumps(m,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
 binaries(STAGE,m);print('Staged',STAGE,'Game',sha(STAGE/'Bin64/Game.exe'));raise SystemExit
assert a.check
run=json.loads((a.check/'run.json').read_text(encoding='utf-8-sig'));log=(a.check/'WXClient.log').read_text(encoding='utf8',errors='replace')
assert run['passed'] and run['game_sha256']==sha(STAGE/'Bin64/Game.exe')
assert run['stage_manifest_sha256']==sha(STAGE/'Bin64/game_data_stage.json')
for marker in ['RESULT errors=0','PASS server unequips soul','PASS server reequips soul','PASS character moves after UI closes']:
 assert 'CYS-WUHUN-PREVIEW: '+marker in log,marker
for name in ['My_Wuhun','Other_Wuhun']:
 for model in [-1,*range(2341,2351)]:assert f'model object={name} id={model} entity={int(model>0)}' in log
assert 'CYS-WUHUN-PREVIEW: FAIL' not in log and 'CYS Lua failure' not in log
for shot in ['wuhun-flame-only','wuhun-disc-only','wuhun-empty','wuhun-selfequip-regression']:
 assert list(a.check.glob('*'+shot+'.png')),shot
if a.scale:
 assert list(a.check.glob('*wuhun-flame-rotated.png'))
 ui_log=(a.check/'UISystem.log').read_text(encoding='utf8',errors='replace')
 assert 'SetCameraEx Wuhun_FakeObject rc=1 h=0.0800 d=1.0000 p=0.2100' in ui_log
old=json.loads(baseline.read_text(encoding='utf8'))
assert sha(PLAY/'Bin64/game_data_stage.json')==old['manifest'] and sha(PLAY/'Bin64/Game.exe')==old['game'],'Play changed since staging'
current=json.loads((PLAY/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
tested=json.loads((STAGE/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
binaries(PLAY,current);binaries(STAGE,tested)
before={r['name']:r['sha256'] for r in current['binaries']};after={r['name']:r['sha256'] for r in tested['binaries']}
assert before.keys()==after.keys() and all(before[n]==after[n] for n in before if n not in NAMES)
assert all(sha(BUILD/n)==after[n] for n in NAMES)
for folder in ['Overlay','Patch']:
 paths=lambda base:{f.relative_to(base) for f in (base/folder).rglob('*') if f.is_file()}
 assert paths(PLAY)==paths(STAGE)
 for rel in paths(STAGE):
  if rel not in changed_overlays:assert sha(STAGE/rel)==sha(PLAY/rel),rel
for r in tested['overlay']:assert sha(STAGE/r['path'])==r['sha256'],r['path']
if a.mode=='check':print('PASS exact tested binaries, all ten models, unequip/reequip, movement, scoped overlay changes');raise SystemExit
idle();stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S');backup=ROOT/'Build/backups'/('wuhun-preview-scale-play' if a.scale else 'wuhun-preview-play')/stamp;backup.mkdir(parents=True)
for name in NAMES+('game_data_stage.json','Run-CY-Server.cmd'):shutil.copy2(PLAY/'Bin64'/name,backup/name)
for rel in changed_overlays:
 dest=backup/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(PLAY/rel,dest)
for rel in changed_overlays:
 dst=PLAY/rel;shutil.copy2(STAGE/rel,dst)
 row=next(r for r in current['overlay'] if Path(r['path'])==rel);row.update(sha256=sha(dst),bytes=dst.stat().st_size)
for row in current['binaries']:
 if row['name'] in NAMES:
  dst=PLAY/'Bin64'/row['name'];shutil.copy2(STAGE/'Bin64'/row['name'],dst);row.update(sha256=sha(dst),bytes=dst.stat().st_size)
launcher=PLAY/'Bin64/Run-CY-Server.cmd';raw=launcher.read_bytes();anchor=b'set "CYS_WORLD_REPLAY="';line=b'set "CYS_WUHUN_PREVIEW_LIVE="'
assert raw.count(anchor)==1
if line not in raw:raw=raw.replace(anchor,anchor+b'\r\n'+line)
launcher.write_bytes(raw)
for row in current['wsl_test']['launchers']:
 if row['path']=='Bin64/Run-CY-Server.cmd':row.update(sha256=sha(launcher),bytes=launcher.stat().st_size)
evidence=dict(at=stamp,check=str(a.check.resolve()),backup=str(backup),before=before,after=after)
current['wuhun_preview_scale_update' if a.scale else 'wuhun_preview_update']=evidence
(PLAY/'Bin64/game_data_stage.json').write_text(json.dumps(current,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
(backup/'deployment.json').write_text(json.dumps(evidence,indent=2)+'\n',encoding='utf8')
binaries(PLAY,current);print('Published',PLAY,'backup',backup)
