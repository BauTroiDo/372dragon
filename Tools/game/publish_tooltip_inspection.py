"""Publish verified inspection/tooltip binaries and scoped overlays, with a full rollback set."""
from pathlib import Path
import argparse,datetime,json,shutil,subprocess
from publish_gameplay_fixes import ROOT,NAMES,sha
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--checks',nargs='+',type=Path,required=True);p.add_argument('--apply',action='store_true');a=p.parse_args()
stage=ROOT/'Build/world-gui/stage-tooltip-inspect-23';play=ROOT/'Build/world-gui/stage-play-21'
tested=json.loads((stage/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
current=json.loads((play/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
inspection=tooltip=False
for folder in a.checks:
    run=json.loads((folder/'run.json').read_text(encoding='utf-8-sig'));log=(folder/'WXClient.log').read_text(encoding='utf8',errors='replace')
    assert run['passed'] and run['game_sha256']==sha(stage/'Bin64/Game.exe'),folder
    assert run['stage_manifest_sha256']==sha(stage/'Bin64/game_data_stage.json'),folder
    assert 'CYS Lua failure' not in log and 'CYS-INSPECT-PROBE: FAIL' not in log and 'CYS-FT-TOOLTIP-PROBE: FAIL' not in log,folder
    inspection|='CYS-INSPECT-PROBE: RESULT errors=0' in log
    tooltip|='CYS-FT-TOOLTIP-PROBE: END old=0' in log
assert inspection and tooltip
for base,m in [(play,current),(stage,tested)]:
    for row in m['binaries']:assert sha(base/'Bin64'/row['name'])==row['sha256'],row['name']
assert all(sha(ROOT/'Build/cmake/coord-x64/bin'/name)==sha(stage/'Bin64'/name) for name in NAMES)
if not a.apply:print('PASS: current binary/manifest, inspection, comparison, ordinary tooltip and item refresh gates');raise SystemExit(0)
proc=subprocess.run(['powershell','-NoProfile','-Command','[bool](Get-Process Game -ErrorAction SilentlyContinue)'],capture_output=True,text=True,check=True)
assert proc.stdout.strip()=='False','Game must be closed before copying binaries'
stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S');backup=ROOT/'Build/backups/tooltip-inspection-play'/stamp;backup.mkdir(parents=True)
overlays=[r for v in tested.values() if isinstance(v,list) for r in v if isinstance(r,dict) and any(str(r.get('path','')).startswith(f'Overlay/{side}/InterfaceFolder/{frame}/') for side in ['Pre','Post'] for frame in ['TargetData','TargetEquip'])]
paths=['Bin64/'+n for n in NAMES]+['Bin64/game_data_stage.json','Bin64/Run-CY-Server.cmd']+[r['path'] for r in overlays]
missing=[]
for rel in paths:
    source=play/rel
    if source.exists():dest=backup/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,dest)
    else:missing.append(rel)
for row in current['binaries']:
    if row['name'] in NAMES:
        dest=play/'Bin64'/row['name'];shutil.copy2(stage/'Bin64'/row['name'],dest);row.update(sha256=sha(dest),bytes=dest.stat().st_size)
for row in overlays:
    assert sha(stage/row['path'])==row['sha256'];dest=play/row['path'];dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(stage/row['path'],dest)
rows=next(v for v in current.values() if isinstance(v,list) and any(isinstance(r,dict) and str(r.get('path','')).startswith('Overlay/Pre/') for r in v))
rows[:]=[r for r in rows if r.get('path') not in {x['path'] for x in overlays}];rows.extend(overlays)
launcher=play/'Bin64/Run-CY-Server.cmd';raw=launcher.read_bytes();anchor=b'set "CYS_WORLD_REPLAY="';assert raw.count(anchor)==1
for flag in ['CYS_INSPECT_LIVE','CYS_FT_TOOLTIP_LIVE','CYS_FT_TOOLTIP_PROBE']:
    line=('set "'+flag+'="').encode('ascii')
    if line not in raw:raw=raw.replace(anchor,anchor+b'\r\n'+line)
launcher.write_bytes(raw)
for row in current['wsl_test']['launchers']:
    if row['path']=='Bin64/Run-CY-Server.cmd':row.update(sha256=sha(launcher),bytes=launcher.stat().st_size)
evidence=dict(at=stamp,checks=[str(p.resolve()) for p in a.checks],backup=str(backup),new_paths=missing)
current['tooltip_inspection_update']=evidence
(play/'Bin64/game_data_stage.json').write_text(json.dumps(current,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
(backup/'deployment.json').write_text(json.dumps(evidence,ensure_ascii=False,indent=2),encoding='utf8')
for row in current['binaries']:assert sha(play/'Bin64'/row['name'])==row['sha256']
for row in overlays:assert sha(play/row['path'])==row['sha256']
print('Published to',play,'backup',backup)
