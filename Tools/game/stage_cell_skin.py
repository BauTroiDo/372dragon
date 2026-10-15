"""Prepare the isolated cell-skin/durability candidate without touching canonical data."""
from pathlib import Path
import json,shutil,subprocess
from publish_gameplay_fixes import ROOT,NAMES,sha
from patch_selfequip_readability import generate as selfequip
from patch_inspection_ui import layout as inspect_layout
stage=ROOT/'Build/world-gui/stage-cell-skin-23'
assert subprocess.run(['powershell','-NoProfile','-Command','[bool](Get-Process Game -ErrorAction SilentlyContinue)'],capture_output=True,text=True,check=True).stdout.strip()=='False'
if not stage.exists():
    stage.mkdir()
    for folder in ['Bin64','Patch','Overlay']:shutil.copytree(ROOT/'Build/world-gui/stage-play-21'/folder,stage/folder)
    shutil.copy2(ROOT/'Build/world-gui/stage-play-21/Play.cmd',stage/'Play.cmd')
    subprocess.run(['powershell','-NoProfile','-Command',f"New-Item -ItemType Junction -Path '{stage / 'Data'}' -Target '{ROOT / 'Assets/CanonicalCY/Data'}' | Out-Null"],check=True)
manifest=stage/'Bin64/game_data_stage.json';m=json.loads(manifest.read_text(encoding='utf8'))
for row in m['binaries']:
    if row['name'] in NAMES:
        dest=stage/'Bin64'/row['name'];shutil.copy2(ROOT/'Build/cmake/coord-x64/bin'/row['name'],dest)
        row.update(sha256=sha(dest),bytes=dest.stat().st_size)
source=ROOT/'Assets/CanonicalCY/Data/InterfaceFolder'
layout,lua,details=selfequip((source/'SelfEquip/SelfEquip.layout.xml').read_bytes(),(source/'SelfEquip/SelfEquip.lua').read_bytes())
files={'SelfEquip/SelfEquip.layout.xml':layout,'SelfEquip/SelfEquip.lua':lua,
       'TargetEquip/TargetEquip.layout.xml':inspect_layout((source/'TargetEquip/TargetEquip.layout.xml').read_bytes(),'TargetEquip')}
rows=next(v for v in m.values() if isinstance(v,list) and any(isinstance(r,dict) and str(r.get('path','')).startswith('Overlay/Pre/') for r in v))
for name,data in files.items():
    for side in ['Pre','Post']:
        rel='Overlay/'+side+'/InterfaceFolder/'+name;dest=stage/rel;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(data)
        rows[:]=[r for r in rows if r.get('path')!=rel]
        rows.append(dict(path=rel,sha256=sha(dest),bytes=len(data),origin='../Data/InterfaceFolder/'+name,reason='Equipment durability strip; preserve existing controls and events'))
m['cell_skin_candidate']={'files':list(files),'selfequip':details}
manifest.write_text(json.dumps(m,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
print('Candidate:',stage,'Game:',sha(stage/'Bin64/Game.exe'))
