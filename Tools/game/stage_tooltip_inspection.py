"""Refresh the isolated tooltip/inspection stage from built binaries and overlay sources."""
from pathlib import Path
import hashlib,json,shutil
from patch_inspection_ui import generate,layout
root=Path(__file__).resolve().parents[2]
stage=root/'Build/world-gui/stage-tooltip-inspect-23'
manifest=stage/'Bin64/game_data_stage.json';m=json.loads(manifest.read_text(encoding='utf8'))
sha=lambda b:hashlib.sha256(b).hexdigest()
for row in m['binaries']:
    if row['name'] in ['Game.exe','Game.pdb','UI_CEGUI.dll','UI_CEGUI.pdb','CEGUIFalagard.dll','CEGUIFalagard.pdb']:
        p=stage/'Bin64'/row['name'];shutil.copy2(root/'Build/cmake/coord-x64/bin'/row['name'],p)
        row.update(bytes=p.stat().st_size,sha256=sha(p.read_bytes()))
for frame in ['TargetData','TargetEquip']:
    name=f'{frame}/{frame}.lua';source=root/'Assets/CanonicalCY/Data/InterfaceFolder'/name
    files={name:generate(source.read_bytes(),frame)}
    files[f'{frame}/{frame}.layout.xml']=layout((source.parent/f'{frame}.layout.xml').read_bytes(),frame)
    for name,data in files.items():
        for side in ['Pre','Post']:
            rel=f'Overlay/{side}/InterfaceFolder/{name}';p=stage/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
            rows=next(v for v in m.values() if isinstance(v,list) and any(isinstance(r,dict) and str(r.get('path','')).startswith('Overlay/Pre/') for r in v))
            rows[:]=[r for r in rows if r.get('path')!=rel]
            rows.append(dict(path=rel,sha256=sha(data),bytes=len(data),origin='../Data/InterfaceFolder/'+name,reason='CY inspection: readable tabs and labels, care lifecycle and unavailable enhancement data'))
manifest.write_text(json.dumps(m,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
print('Candidate refreshed:',stage,'Game:',sha((stage/'Bin64/Game.exe').read_bytes()))
