"""Publish the verified cell backgrounds and equipment durability strip with rollback files."""
from pathlib import Path
import argparse,datetime,json,shutil,subprocess
from publish_gameplay_fixes import ROOT,NAMES,sha
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--check',type=Path,required=True);p.add_argument('--apply',action='store_true');a=p.parse_args()
stage=ROOT/'Build/world-gui/stage-cell-skin-23';play=ROOT/'Build/world-gui/stage-play-21'
run=json.loads((a.check/'run.json').read_text(encoding='utf-8-sig'));log=(a.check/'WXClient.log').read_text(encoding='utf8',errors='replace')
assert run['passed'] and run['game_sha256']==sha(stage/'Bin64/Game.exe')
assert run['stage_manifest_sha256']==sha(stage/'Bin64/game_data_stage.json')
for marker in ['CYS-CELL-SKIN: RESULT errors=0','CYS-INSPECT-PROBE: RESULT errors=0','CYS-FT-TOOLTIP-PROBE: END old=0']:assert marker in log,marker
for marker in ['CYS Lua failure','CYS-CELL-SKIN: FAIL','CYS-INSPECT-PROBE: FAIL','CYS-FT-TOOLTIP-PROBE: FAIL']:assert marker not in log,marker
tested=json.loads((stage/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
current=json.loads((play/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
for base,m in [(play,current),(stage,tested)]:
    for row in m['binaries']:assert sha(base/'Bin64'/row['name'])==row['sha256'],row['name']
assert all(sha(ROOT/'Build/cmake/coord-x64/bin'/n)==sha(stage/'Bin64'/n) for n in NAMES)
paths={f'Overlay/{side}/InterfaceFolder/{name}' for side in ['Pre','Post'] for name in tested['cell_skin_candidate']['files']}
overlays=[r for v in tested.values() if isinstance(v,list) for r in v if isinstance(r,dict) and r.get('path') in paths]
assert len(overlays)==len(paths)
for row in overlays:assert sha(stage/row['path'])==row['sha256']
if not a.apply:print('PASS cell skin, durability, tooltips, comparison, inspection and binary gates');raise SystemExit(0)
assert subprocess.run(['powershell','-NoProfile','-Command','[bool](Get-Process Game -ErrorAction SilentlyContinue)'],capture_output=True,text=True,check=True).stdout.strip()=='False'
stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S');backup=ROOT/'Build/backups/cell-skin-play'/stamp;backup.mkdir(parents=True)
missing=[]
for rel in ['Bin64/'+n for n in NAMES]+['Bin64/game_data_stage.json','Bin64/Run-CY-Server.cmd']+sorted(paths):
    src=play/rel
    if src.exists():dest=backup/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dest)
    else:missing.append(rel)
for row in current['binaries']:
    if row['name'] in NAMES:
        dest=play/'Bin64'/row['name'];shutil.copy2(stage/'Bin64'/row['name'],dest);row.update(sha256=sha(dest),bytes=dest.stat().st_size)
for row in overlays:dest=play/row['path'];dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(stage/row['path'],dest)
rows=next(v for v in current.values() if isinstance(v,list) and any(isinstance(r,dict) and str(r.get('path','')).startswith('Overlay/Pre/') for r in v))
rows[:]=[r for r in rows if r.get('path') not in paths];rows.extend(overlays)
launcher=play/'Bin64/Run-CY-Server.cmd';raw=launcher.read_bytes();anchor=b'set "CYS_WORLD_REPLAY="';line=b'set "CYS_CELL_SKIN_LIVE="';assert raw.count(anchor)==1
if line not in raw:raw=raw.replace(anchor,anchor+b'\r\n'+line)
launcher.write_bytes(raw)
for row in current['wsl_test']['launchers']:
    if row['path']=='Bin64/Run-CY-Server.cmd':row.update(sha256=sha(launcher),bytes=launcher.stat().st_size)
evidence=dict(at=stamp,check=str(a.check.resolve()),backup=str(backup),new_paths=missing)
current['cell_skin_update']=evidence
(play/'Bin64/game_data_stage.json').write_text(json.dumps(current,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
(backup/'deployment.json').write_text(json.dumps(evidence,ensure_ascii=False,indent=2),encoding='utf8')
for row in current['binaries']:assert sha(play/'Bin64'/row['name'])==row['sha256']
for row in overlays:assert sha(play/row['path'])==row['sha256']
print('Published:',play,'backup:',backup)
