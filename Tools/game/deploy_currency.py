from pathlib import Path
import argparse,datetime,json,shutil,subprocess
from deploy_mount_flight import idle,binaries
from publish_gameplay_fixes import ROOT,sha,NAMES
from vothach_ui import outputs
PLAY=ROOT/'Build/world-gui/stage-play-21';STAGE=ROOT/'Build/world-gui/stage-vothach-26'
LOG=ROOT/'Build/Logs/2026-09-26-vothach'
def stage():
 idle();LOG.mkdir(parents=True,exist_ok=True)
 if not STAGE.exists():
  STAGE.mkdir()
  for name in ['Bin64','Overlay','Patch']:shutil.copytree(PLAY/name,STAGE/name)
  shutil.copy2(PLAY/'Play.cmd',STAGE/'Play.cmd')
  subprocess.run(['powershell','-NoProfile','-Command',f"New-Item -ItemType Junction -Path '{STAGE/'Data'}' -Target '{ROOT/'Assets/CanonicalCY/Data'}' | Out-Null"],check=True)
  (LOG/'play-manifest-baseline.json').write_bytes((PLAY/'Bin64/game_data_stage.json').read_bytes())
 m=json.loads((LOG/'play-manifest-baseline.json').read_text(encoding='utf8'));changed=[]
 for n in NAMES:
  p=STAGE/'Bin64'/n;shutil.copy2(ROOT/'Build/cmake/coord-x64/bin'/n,p);changed.append('Bin64/'+n)
  row=next(x for x in m['binaries'] if x['name']==n);row.update(sha256=sha(p),bytes=p.stat().st_size)
 content=outputs(PLAY)
 for side in ['Pre','Post']:
  for rel,raw in content.items():
   rel='Overlay/'+side+'/'+rel;p=STAGE/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(raw);changed.append(rel)
   row=next((r for r in m['overlay'] if r['path'].replace('\\','/').casefold()==rel.casefold()),None)
   if row is None:row={'path':rel};m['overlay'].append(row)
   row.update(sha256=sha(p),bytes=len(raw),origin='vothach_ui.py')
 m['vothach']={'wallets':['Vo Thach','Yuanbao'],'ratio':[100,100],'unit':'lower grade','source':'built-in image_gen'}
 assert len({r['path'].replace('\\','/').casefold() for r in m['overlay']})==len(m['overlay']),'Duplicate Windows overlay path'
 for row in m['overlay']:assert sha(STAGE/row['path'])==row['sha256'],row['path']
 (STAGE/'Bin64/game_data_stage.json').write_text(json.dumps(m,ensure_ascii=False,indent=1)+'\n',encoding='utf8');changed.append('Bin64/game_data_stage.json')
 baseline=LOG/'play-baseline.json'
 base=json.loads(baseline.read_text()) if baseline.exists() else {}
 assert sha(PLAY/'Bin64/game_data_stage.json')==sha(LOG/'play-manifest-baseline.json'),'Play changed during candidate work'
 for p in changed:
  if p not in base:base[p]=sha(PLAY/p) if (PLAY/p).exists() else None
 baseline.write_text(json.dumps(base,indent=2))
 (LOG/'changed-paths.json').write_text(json.dumps(changed,indent=2));binaries(STAGE,m)
 print('Staged',len(content),'overlay resources; Game',sha(STAGE/'Bin64/Game.exe'))
def publish(checks):
 idle();m=json.loads((STAGE/'Bin64/game_data_stage.json').read_text(encoding='utf8'));binaries(STAGE,m)
 modes=set()
 for folder in checks:
  r=json.loads((folder/'run.json').read_text(encoding='utf-8-sig'));s=(folder/'WXClient.log').read_text(encoding='utf8',errors='replace')
  assert r['passed'] and r['game_sha256']==sha(STAGE/'Bin64/Game.exe') and r['stage_manifest_sha256']==sha(STAGE/'Bin64/game_data_stage.json')
  assert 'CYS-CURRENCY: RESULT errors=0' in s and 'CYS-CURRENCY: FAIL' not in s
  for mode in [1,2]:
   if 'CYS-CURRENCY: RESULT errors=0 mode='+str(mode) in s:modes.add(mode)
 assert modes=={1,2},'Need purchase and relogin verification'
 assert json.loads((LOG/'fixture-restore.json').read_text())['full_bson_equal']
 assert json.loads((LOG/'fixture-persistent.json').read_text())['valid']
 for rel,h in json.loads((LOG/'play-baseline.json').read_text()).items():assert (sha(PLAY/rel) if (PLAY/rel).exists() else None)==h,rel
 for row in m['overlay']:assert sha(STAGE/row['path'])==row['sha256'],row['path']
 backup=ROOT/'Build/backups/vothach-play'/datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
 paths=json.loads((LOG/'changed-paths.json').read_text())
 for rel in paths:
  p=PLAY/rel
  if p.exists():b=backup/rel;b.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,b)
 for rel in paths:p=PLAY/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(STAGE/rel,p)
 report={'backup':str(backup),'game':sha(PLAY/'Bin64/Game.exe'),'manifest':sha(PLAY/'Bin64/game_data_stage.json'),'checks':[str(p) for p in checks],'files':len(paths)}
 (LOG/'release-report.json').write_text(json.dumps(report,indent=2));print('Published',report)
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('mode',choices=['stage','publish']);p.add_argument('--checks',nargs='+',type=Path);a=p.parse_args()
 stage() if a.mode=='stage' else publish(a.checks)
