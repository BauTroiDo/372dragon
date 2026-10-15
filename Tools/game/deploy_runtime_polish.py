from pathlib import Path
import argparse,datetime,json,shutil,subprocess
from deploy_mount_flight import idle,binaries
from publish_gameplay_fixes import ROOT,sha,NAMES
from runtime_polish_ui import outputs,gm_index,shop_mask
from round2_gm_rules import generate_rules
PLAY=ROOT/'Build/world-gui/stage-play-21';STAGE=ROOT/'Build/world-gui/stage-runtime-polish-26'
LOG=ROOT/'Build/Logs/2026-09-26-runtime-polish'
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
   row.update(sha256=sha(p),bytes=len(raw),origin='runtime_polish_ui.py')
 rel='Patch/Plugin_GameSearch.dll';raw=gm_index(PLAY);p=STAGE/rel;p.write_bytes(raw);changed.append(rel)
 for row in m.get('patch_files',[]):
  if row.get('path','').replace('\\','/').casefold()==rel.casefold():row.update(sha256=sha(p),bytes=len(raw))
 m['runtime_polish']={'flight_plane':'max authored .fly height','gm_index_sha256':sha(p),'shops':shop_mask()}
 rel='Patch/Plugin_GmEquipRules.dll';p=STAGE/rel;p.write_bytes(generate_rules(LOG/'gm-rules'));changed.append(rel)
 assert b'10156901\tequip\t' in p.read_bytes() and b'10156902\tequip\t' in p.read_bytes()
 for rel in ['Patch/Plugin_GameSearch.dll','Patch/Plugin_GmEquipRules.dll']:
  p=STAGE/rel;row=next(r for r in m['overlay'] if r['path'].replace('\\','/').casefold()==rel.casefold());row.update(sha256=sha(p),bytes=p.stat().st_size,origin='runtime_polish_ui.py')
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
 found=set()
 for folder in checks:
  r=json.loads((folder/'run.json').read_text(encoding='utf-8-sig'));s=(folder/'WXClient.log').read_text(encoding='utf8',errors='replace')
  assert r['passed'] and r['game_sha256']==sha(STAGE/'Bin64/Game.exe') and r['stage_manifest_sha256']==sha(STAGE/'Bin64/game_data_stage.json'),folder
  for mode in [1,3,4]:
   if 'CYS-RUNTIME-POLISH: RESULT mode='+str(mode)+' errors=0' in s:found.add(mode)
  if 'CYS-MOUNT-FLIGHT-PROBE: RESULT errors=0' in s and 'fixed plane original=' in s:found.add('flight')
  if 'CYS-MOUNT-FLIGHT-PROBE: PASS server rejects ground mount independently' in s:found.add('ground')
  if 'CYS-ROUND2-PROBE: RESULT automatic battle kill EXP stop manual movement errors=0' in s:found.add('battle')
  if 'CYS-HJ-PROBE: census count=91 errors=0' in s and 'CYS-WARDROBE-PROBE: RESULT errors=0' in s:
   assert 'pass=0' not in '\n'.join(line for line in s.splitlines() if 'CYS-WARDROBE-PROBE:' in line)
   found.add('hj')
  if 'CYS-WARDROBE-PROBE: cosmetic body audit count=4 errors=0' in s and 'CYS-WARDROBE-PROBE: RESULT errors=0' in s:
   assert 'pass=0' not in '\n'.join(line for line in s.splitlines() if 'CYS-WARDROBE-PROBE:' in line)
   found.add('cosmetic')
  assert not any(tag in s for tag in ['CYS-RUNTIME-POLISH: FAIL','CYS-MOUNT-FLIGHT-PROBE: FAIL','CYS-ROUND2-PROBE: FAIL'])
 assert found=={1,3,4,'flight','ground','battle','hj','cosmetic'},found
 assert json.loads((LOG/'fixture-restore.json').read_text())['full_bson_equal']
 for rel,h in json.loads((LOG/'play-baseline.json').read_text()).items():assert (sha(PLAY/rel) if (PLAY/rel).exists() else None)==h,rel
 for row in m['overlay']:assert sha(STAGE/row['path'])==row['sha256'],row['path']
 backup=ROOT/'Build/backups/runtime-polish-play'/datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
 paths=json.loads((LOG/'changed-paths.json').read_text())
 for rel in paths:
  p=PLAY/rel
  if p.exists():b=backup/rel;b.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,b)
 for rel in paths:p=PLAY/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(STAGE/rel,p)
 binaries(PLAY,m)
 for row in m['overlay']:assert sha(PLAY/row['path'])==row['sha256'],row['path']
 report={'backup':str(backup),'game':sha(PLAY/'Bin64/Game.exe'),'manifest':sha(PLAY/'Bin64/game_data_stage.json'),'checks':[str(p) for p in checks],'files':len(paths)}
 (LOG/'release-report.json').write_text(json.dumps(report,indent=2));print('Published',report)

if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('mode',choices=['stage','publish'],default='stage',nargs='?');p.add_argument('--checks',nargs='+',type=Path);a=p.parse_args()
 stage() if a.mode=='stage' else publish(a.checks or [])
