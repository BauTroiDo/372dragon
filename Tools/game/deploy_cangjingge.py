"""Stage the Cangjingge DBC as paired CY overlays; preserve all other Play files."""
from pathlib import Path
import argparse,datetime,json,shutil,subprocess
from deploy_mount_flight import idle,binaries
from publish_gameplay_fixes import ROOT,sha
PLAY=ROOT/'Build/world-gui/stage-play-21';STAGE=ROOT/'Build/world-gui/stage-cangjingge-29'
LOG=ROOT/'Build/Logs/2026-09-29-cangjingge'
NAMES=('Game.exe','Game.pdb','UI_CEGUI.dll','UI_CEGUI.pdb')
OVERLAYS=tuple(f'Overlay/{p}/ConfigFolder/MonsterAttrExTable.txt' for p in ('Pre','Post'))
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def refresh():
 m=read(STAGE/'Bin64/game_data_stage.json')
 prior=LOG/('candidate-'+sha(STAGE/'Bin64/game_data_stage.json')+'.json')
 if not prior.exists():shutil.copy2(STAGE/'Bin64/game_data_stage.json',prior)
 for r in m['binaries']:
  if r['name'] in NAMES:
   dst=STAGE/'Bin64'/r['name'];shutil.copy2(ROOT/'Build/cmake/coord-x64/bin'/r['name'],dst)
   r.update(sha256=sha(dst),bytes=dst.stat().st_size)
 m['cangjingge_candidate']['manifest']=sha(LOG/'manifest.json')
 (STAGE/'Bin64/game_data_stage.json').write_text(json.dumps(m,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
 binaries(STAGE,m);print('Refreshed UI shutdown fix and server manifest')
def publish(gui,icons,apply):
 assert gui and icons
 base=read(LOG/'play-baseline.json');before=read(PLAY/'Bin64/game_data_stage.json');after=read(STAGE/'Bin64/game_data_stage.json')
 assert sha(PLAY/'Bin64/game_data_stage.json')==base['manifest'] and sha(PLAY/'Bin64/Game.exe')==base['game']
 binaries(PLAY,before);binaries(STAGE,after)
 old={r['name']:r['sha256'] for r in before['binaries']};new={r['name']:r['sha256'] for r in after['binaries']}
 assert old.keys()==new.keys() and all(old[n]==new[n] for n in old if n not in NAMES)
 for n in NAMES:assert new[n]==sha(ROOT/'Build/cmake/coord-x64/bin'/n)
 for folder in ('Overlay','Patch'):
  actual={f.relative_to(STAGE).as_posix():sha(f) for f in (STAGE/folder).rglob('*') if f.is_file()}
  prior={f.relative_to(PLAY).as_posix():sha(f) for f in (PLAY/folder).rglob('*') if f.is_file()}
  added={rel:sha(LOG/'client/MonsterAttrExTable.txt') for rel in OVERLAYS} if folder=='Overlay' else {}
  assert actual==prior|added
 run=read(gui/'run.json');log=(gui/'WXClient.log').read_text(encoding='utf8',errors='replace')
 assert run['passed'] and all(run['checks'].values()) and run['game_sha256']==new['Game.exe']
 assert run['stage_manifest_sha256']==sha(STAGE/'Bin64/game_data_stage.json')
 assert 'CYS Lua failure' not in log and 'server tra menu NPC' in log
 assert 'CYS UI: script dispatch stopped before node teardown' in log
 for race in (113565,113574,113583,113592):assert 'race='+str(race) in log
 assert read(gui/'server-check.json')['passed'] and read(LOG/'live-result.json')['passed']
 other=read(icons/'run.json');otherlog=(icons/'WXClient.log').read_text(encoding='utf8',errors='replace')
 assert other['passed'] and all(other['checks'].values()) and other['game_sha256']==new['Game.exe']
 assert other['stage_manifest_sha256']==run['stage_manifest_sha256'] and read(icons/'server-check.json')['passed']
 assert 'CYS Lua failure' not in otherlog and 'CYS-NPC-ICON: FAIL' not in otherlog
 for marker in ('RESULT states=32 pages=6 errors=0','PASS Escape closes NPC dialogue','PASS movement after NPC dialogue'):
  assert 'CYS-NPC-ICON: '+marker in otherlog,marker
 from audit_npc_icons import verify_runtime
 verify_runtime(icons)
 assert read(LOG/'live-server-check-v2.json')['passed']
 assert read(LOG/'tests.json')['passed'] and read(LOG/'tests.json')['manifest']==sha(LOG/'manifest.json')
 assert read(LOG/'health.json')['healthy'] and not read(LOG/'boot-log-summary.json')['tracebacks']
 assert after['cangjingge_candidate']['manifest']==read(LOG/'applied.json')['manifest']==sha(LOG/'manifest.json')
 live=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
 for row in read(LOG/'manifest.json')['server']:assert sha(live/row['path'])==row['after']
 review=read(LOG/'visual-review.json');assert review['models_visible'] and sha(gui/review['image'])==review['sha256']
 subprocess.run(['wsl','-d','TLBB','-u','root','--','python3','/mnt/c/TLBB/085/CY-Source/Tools/server/cangjingge_fixture.py','verify'],check=True)
 if not apply:print('PASS exact candidate, callbacks, live scene, GUI, logs and restored BSON');return
 stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S');backup=ROOT/'Build/backups/cangjingge-play'/stamp;backup.mkdir(parents=True)
 for n in NAMES+('game_data_stage.json',):shutil.copy2(PLAY/'Bin64'/n,backup/n)
 for n in NAMES:shutil.copy2(STAGE/'Bin64'/n,PLAY/'Bin64'/n)
 for rel in OVERLAYS:
  dst=PLAY/rel;assert not dst.exists();dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(STAGE/rel,dst)
 evidence=dict(at=stamp,backup=str(backup),gui=str(gui.resolve()),icons_gui=str(icons.resolve()),tested_manifest=run['stage_manifest_sha256'],server_manifest=sha(LOG/'manifest.json'),binaries={n:new[n] for n in NAMES})
 after['cangjingge_update']=evidence
 (PLAY/'Bin64/game_data_stage.json').write_text(json.dumps(after,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
 binaries(PLAY,after);(LOG/'release-report.json').write_text(json.dumps(evidence,indent=2))
 print('Published tested Cangjingge data and UI DLL; backup',backup)
def main():
 p=argparse.ArgumentParser();p.add_argument('mode',choices=['stage','refresh','check','publish']);p.add_argument('--gui',type=Path);p.add_argument('--icons',type=Path);a=p.parse_args();idle()
 if a.mode=='refresh':refresh();return
 if a.mode in ('check','publish'):publish(a.gui,a.icons,a.mode=='publish');return
 assert not STAGE.exists(),'Preserve existing evidence/candidate'
 STAGE.mkdir()
 for name in ('Bin64','Patch','Overlay'):shutil.copytree(PLAY/name,STAGE/name)
 shutil.copy2(PLAY/'Play.cmd',STAGE/'Play.cmd')
 subprocess.run(['powershell','-NoProfile','-Command',f"New-Item -ItemType Junction -Path '{STAGE/'Data'}' -Target '{(PLAY/'Data').resolve()}' | Out-Null"],check=True)
 (LOG/'play-baseline.json').write_text(json.dumps(dict(manifest=sha(PLAY/'Bin64/game_data_stage.json'),game=sha(PLAY/'Bin64/Game.exe'))))
 m=json.loads((PLAY/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
 for place in ('Pre','Post'):
  rel=f'Overlay/{place}/ConfigFolder/MonsterAttrExTable.txt';dst=STAGE/rel
  assert not dst.exists(),'Unexpected earlier monster overlay'
  dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(LOG/'client/MonsterAttrExTable.txt',dst)
  m['overlay'].append(dict(path=rel,sha256=sha(dst),bytes=dst.stat().st_size,origin='GL/CY verified Cangjingge family',reason='36 isolated monster IDs'))
 m['cangjingge_candidate']=dict(manifest=sha(LOG/'manifest.json'),ids=[113565,113600])
 (STAGE/'Bin64/game_data_stage.json').write_text(json.dumps(m,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
 binaries(STAGE,m)
 for r in m['overlay']:assert sha(STAGE/r['path'])==r['sha256'],r['path']
 print('Staged',STAGE,'existing Game/DLLs unchanged')
if __name__=='__main__':main()
