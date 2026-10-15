"""Stage equipment tooltips over current Play; publish only the exact tested candidate."""
from pathlib import Path
import argparse,datetime,json,shutil,subprocess
from publish_gameplay_fixes import ROOT,NAMES,sha
from deploy_npc_icons import idle,binaries
from equipment_tooltip_layout import generate

def main():
 p=argparse.ArgumentParser();p.add_argument('mode',choices=['stage','publish']);p.add_argument('--check',type=Path);a=p.parse_args()
 idle();play=ROOT/'Build/world-gui/stage-play-21';stage=ROOT/'Build/world-gui/stage-equipment-tooltips-24'
 pm=json.loads((play/'Bin64/game_data_stage.json').read_text(encoding='utf8'));binaries(play,pm)
 if a.mode=='stage':
  if not stage.exists():
   stage.mkdir()
   for f in ['Bin64','Patch','Overlay']:shutil.copytree(play/f,stage/f)
   shutil.copy2(play/'Play.cmd',stage/'Play.cmd')
   subprocess.run(['powershell','-NoProfile','-Command',f"New-Item -ItemType Junction -Path '{stage/'Data'}' -Target '{ROOT/'Assets/CanonicalCY/Data'}' | Out-Null"],check=True)
  m=pm
  for side in ['Pre','Post']:
   for frame in ['SuperTooltip','SuperToolTip_Compare','SuperToolTip_Compare2']:
    rel=f'Overlay/{side}/InterfaceFolder/{frame}/{frame}.layout.xml'
    src=play/rel
    if not src.exists():src=ROOT/f'Assets/CanonicalCY/Data/InterfaceFolder/{frame}/{frame}.layout.xml'
    dst=stage/rel;dst.parent.mkdir(parents=True,exist_ok=True);dst.write_bytes(generate(src.read_bytes()))
    rows=[r for r in m['overlay'] if r['path'].replace('\\','/')==rel]
    if not rows:m['overlay'].append({'path':rel,'origin':'equipment_tooltip_layout.py','reason':'Readable equipment type'});rows=[m['overlay'][-1]]
    rows[0].update(sha256=sha(dst),bytes=dst.stat().st_size)
  for row in m['binaries']:
   if row['name'] in NAMES:
    dst=stage/'Bin64'/row['name'];shutil.copy2(ROOT/'Build/cmake/coord-x64/bin'/row['name'],dst)
    row.update(sha256=sha(dst),bytes=dst.stat().st_size)
  m['equipment_tooltips_candidate']={'baseline_manifest':sha(play/'Bin64/game_data_stage.json')}
  (stage/'Bin64/game_data_stage.json').write_text(json.dumps(m,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
  binaries(stage,m);print('Staged',stage,'Game',sha(stage/'Bin64/Game.exe'));return
 assert a.check
 sm=json.loads((stage/'Bin64/game_data_stage.json').read_text(encoding='utf8'));binaries(stage,sm)
 assert sha(play/'Bin64/game_data_stage.json')==sm['equipment_tooltips_candidate']['baseline_manifest'],'Play changed during test'
 run=json.loads((a.check/'run.json').read_text(encoding='utf-8-sig'));log=(a.check/'WXClient.log').read_text(encoding='utf8',errors='replace')
 assert run['passed'] and run['game_sha256']==sha(stage/'Bin64/Game.exe')
 assert run['stage_manifest_sha256']==sha(stage/'Bin64/game_data_stage.json')
 assert 'CYS-EQUIP-TIP: RESULT errors=0' in log
 for bad in ['CYS-EQUIP-TIP: FAIL','CYS Lua failure','Packet handler exception']:assert bad not in log,bad
 for row in sm['overlay']:assert sha(stage/row['path'])==row['sha256'],row['path']
 allowed={r['path'].replace('\\','/') for r in sm['overlay']}|{f'Bin64/{n}' for n in NAMES}
 changed=[rel for rel in sorted(allowed) if not (play/rel).exists() or sha(stage/rel)!=sha(play/rel)]
 stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S');backup=ROOT/'Build/backups/equipment-tooltips-play'/stamp;backup.mkdir(parents=True)
 for rel in changed+['Bin64/game_data_stage.json']:
  if (play/rel).exists():
   dst=backup/rel;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(play/rel,dst)
 for rel in changed:
  (play/rel).parent.mkdir(parents=True,exist_ok=True);shutil.copy2(stage/rel,play/rel);assert sha(stage/rel)==sha(play/rel)
 pm['binaries']=sm['binaries'];pm['overlay']=sm['overlay'];pm['equipment_tooltips_update']={'at':stamp,'check':str(a.check),'backup':str(backup),'files':changed}
 (play/'Bin64/game_data_stage.json').write_text(json.dumps(pm,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
 binaries(play,pm);print('Published',play,'backup',backup)
if __name__=='__main__':main()
