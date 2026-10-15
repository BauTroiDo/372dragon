"""Stage and publish the exact GUI-tested runtime repairs over unchanged Play."""
from pathlib import Path
import argparse,datetime,json,shutil,subprocess
from deploy_mount_flight import idle,binaries
from publish_gameplay_fixes import ROOT,sha
from runtime_repairs_ui import generate
LOG=ROOT/'Build/Logs/2026-10-01-runtime-fixes'
PLAY=ROOT/'Build/world-gui/stage-play-21';STAGE=ROOT/'Build/world-gui/stage-runtime-fixes-01'
NAMES=('Game.exe','Game.pdb')
RELS=tuple(f'Overlay/{p}/InterfaceFolder/Packet/Packet.lua' for p in ('Pre','Post'))
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def stage(refresh=False):
 if not refresh:
  assert not STAGE.exists();STAGE.mkdir()
  for name in ('Bin64','Patch','Overlay'):shutil.copytree(PLAY/name,STAGE/name)
  shutil.copy2(PLAY/'Play.cmd',STAGE/'Play.cmd')
  subprocess.run(['powershell','-NoProfile','-Command',f"New-Item -ItemType Junction -Path '{STAGE/'Data'}' -Target '{(PLAY/'Data').resolve()}' | Out-Null"],check=True)
 m=read(PLAY/'Bin64/game_data_stage.json')
 for n in NAMES:shutil.copy2(ROOT/'Build/cmake/coord-x64/bin'/n,STAGE/'Bin64'/n)
 for r in m['binaries']:
  if r['name'] in NAMES:r.update(sha256=sha(STAGE/'Bin64'/r['name']),bytes=(STAGE/'Bin64'/r['name']).stat().st_size)
 for rel in RELS:
  src=PLAY/rel;dst=STAGE/rel;dst.write_text(generate(src.read_text(encoding='utf-8-sig')),encoding='utf8',newline='\n')
  found=False
  for row in m['overlay']:
   if row['path']==rel:row.update(sha256=sha(dst),bytes=dst.stat().st_size,reason='Single-slot bag delta');found=True
  if not found:m['overlay'].append(dict(path=rel,sha256=sha(dst),bytes=dst.stat().st_size,origin='runtime repairs',reason='Single-slot bag delta'))
 m['runtime_repairs_candidate']=dict(server_manifest=sha(LOG/'server-manifest.json'))
 (STAGE/'Bin64/game_data_stage.json').write_text(json.dumps(m,ensure_ascii=False,indent=1),encoding='utf8')
 binaries(STAGE,m);print('Candidate ready',STAGE)
def publish(gui,relogin,apply):
 base=read(LOG/'play-baseline.json');assert sha(PLAY/'Bin64/game_data_stage.json')==base['manifest'] and sha(PLAY/'Bin64/Game.exe')==base['game']
 before=read(PLAY/'Bin64/game_data_stage.json');after=read(STAGE/'Bin64/game_data_stage.json');binaries(PLAY,before);binaries(STAGE,after)
 old={r['name']:r['sha256'] for r in before['binaries']};new={r['name']:r['sha256'] for r in after['binaries']}
 assert old.keys()==new.keys() and all(old[n]==new[n] for n in old if n not in NAMES)
 for n in NAMES:assert new[n]==sha(ROOT/'Build/cmake/coord-x64/bin'/n)
 for folder in ('Overlay','Patch'):
  a={f.relative_to(STAGE).as_posix():sha(f) for f in (STAGE/folder).rglob('*') if f.is_file()}
  b={f.relative_to(PLAY).as_posix():sha(f) for f in (PLAY/folder).rglob('*') if f.is_file()}
  assert a.keys()==b.keys() and all(a[n]==b[n] for n in a if n not in RELS)
 for mode,path in ((1,gui),(2,relogin)):
  run=read(path/'run.json');text=(path/'WXClient.log').read_text(encoding='utf8',errors='replace')
  assert run['passed'] and all(run['checks'].values()) and run['game_sha256']==new['Game.exe']
  assert run['stage_manifest_sha256']==sha(STAGE/'Bin64/game_data_stage.json')
  assert f'CYS-RUNTIME-FIX: RESULT mode={mode} errors=0' in text and 'CYS-RUNTIME-FIX: FAIL' not in text
  assert read(path/'server-check.json')['passed']
 assert read(LOG/'purchase-persisted.json')['passed']
 assert read(LOG/'verify.json')['full_bson_equal'] and read(LOG/'health.json')['healthy']
 review=read(LOG/'visual-review.json');assert review['repair_counter_visible'] and review['bag_visible']
 for row in review['images']:assert sha(ROOT/row['path'])==row['sha256']
 server_tests=read(LOG/'server-tests.json');ui_tests=read(LOG/'ui-tests.json')
 assert server_tests['passed'] and server_tests['manifest']==sha(LOG/'server-manifest.json')
 assert ui_tests['passed'] and ui_tests['sources']==[sha(STAGE/r) for r in RELS]
 navigation=read(LOG/'live-result.json')
 assert navigation['passed'] and navigation['script_sha256']==sha(ROOT/'Tools/server/runtime_repairs_live.lua')
 for r in read(LOG/'server-manifest.json'):
  assert sha(Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')/r['path'])==r['after']
 if not apply:print('PASS publish checks');return
 stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S');backup=ROOT/'Build/backups/runtime-repairs-play'/stamp
 for rel in [f'Bin64/{n}' for n in (*NAMES,'game_data_stage.json')]+list(RELS):
  p=backup/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(PLAY/rel,p)
 for rel in [f'Bin64/{n}' for n in NAMES]+list(RELS):shutil.copy2(STAGE/rel,PLAY/rel)
 report=dict(at=stamp,backup=str(backup),game=new['Game.exe'],gui=str(gui),relogin=str(relogin),tested_manifest=sha(STAGE/'Bin64/game_data_stage.json'),server_manifest=sha(LOG/'server-manifest.json'))
 after['runtime_repairs_release']=report
 (PLAY/'Bin64/game_data_stage.json').write_text(json.dumps(after,ensure_ascii=False,indent=1),encoding='utf8')
 binaries(PLAY,after);(LOG/'release-report.json').write_text(json.dumps(report,indent=2));print('Published runtime repairs',report['game'])
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('mode',choices=['stage','refresh','check','publish']);p.add_argument('--gui',type=Path);p.add_argument('--relogin',type=Path);a=p.parse_args();idle()
 if a.mode in ('stage','refresh'):stage(a.mode=='refresh')
 else:publish(a.gui,a.relogin,a.mode=='publish')
