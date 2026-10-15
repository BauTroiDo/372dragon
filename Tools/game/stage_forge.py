"""Isolated forging candidate based on the current verified Play profile."""
from pathlib import Path
import json,shutil,subprocess,struct
from PIL import Image
from publish_gameplay_fixes import ROOT,NAMES,sha
from deploy_npc_icons import idle,binaries
from forge_layout import generate

def main():
    idle();play=ROOT/'Build/world-gui/stage-play-21';stage=ROOT/'Build/world-gui/stage-forge-23'
    if not stage.exists():
        stage.mkdir()
        for folder in ['Bin64','Patch','Overlay']:shutil.copytree(play/folder,stage/folder)
        shutil.copy2(play/'Play.cmd',stage/'Play.cmd')
        subprocess.run(['powershell','-NoProfile','-Command',f"New-Item -ItemType Junction -Path '{stage/'Data'}' -Target '{ROOT/'Assets/CanonicalCY/Data'}' | Out-Null"],check=True)
    m=json.loads((stage/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
    for row in m['binaries']:
        if row['name'] in NAMES:
            dst=stage/'Bin64'/row['name'];shutil.copy2(ROOT/'Build/cmake/coord-x64/bin'/row['name'],dst)
            row.update(sha256=sha(dst),bytes=dst.stat().st_size)
    def overlay(rel,data):
        dst=stage/rel;dst.parent.mkdir(parents=True,exist_ok=True);dst.write_bytes(data)
        rows=[r for r in m['overlay'] if r['path'].replace('\\','/')==rel]
        if not rows:m['overlay'].append({'path':rel,'origin':'CYS forge','reason':'timing enhancement UI'});rows=[m['overlay'][-1]]
        rows[0].update(sha256=sha(dst),bytes=dst.stat().st_size)
    art=ROOT/'Tools/game/forge/forge-anvil-hammer.png'
    route_source=play/'Overlay/Pre/ConfigFolder/UICommandIndex.txt'
    if not route_source.exists():route_source=ROOT/'Assets/CanonicalCY/Data/ConfigFolder/UICommandIndex.txt'
    routes=route_source.read_bytes()
    magic,cols,count,pool=struct.unpack_from('<4I',routes)
    assert magic==0xDDBBCC00 and cols==3 and len(routes)==28+count*12+pool
    entries=[struct.unpack_from('<3I',routes,28+i*12) for i in range(count)]
    receivers={win for _,cmd,win in entries if cmd==1002};assert len(receivers)==1
    existing=[win for _,cmd,win in entries if cmd==990023]
    if existing:assert len(existing)==1 and set(existing)==receivers
    else:
        header=bytearray(routes[:28]);struct.pack_into('<I',header,8,count+1)
        routes=bytes(header)+routes[28:28+count*12]+struct.pack('<3I',max(i for i,_,_ in entries)+1,990023,receivers.pop())+routes[28+count*12:]
    with Image.open(art) as im:w,h=im.size
    atlas=f'<Imageset Name="CysForgeArt" Imagefile="forge-anvil-hammer.png" NativeHorzRes="1280" NativeVertRes="720" AutoScaled="false"><Image Name="AnvilHammer" XPos="0" YPos="0" Width="{w}" Height="{h}" /></Imageset>'.encode()
    for side in ['Pre','Post']:
        overlay(f'Overlay/{side}/ConfigFolder/UICommandIndex.txt',routes)
        base=f'Overlay/{side}/InterfaceFolder'
        overlay(base+'/EquipStrengthen/EquipStrengthen.layout.xml',generate())
        overlay(base+'/EquipStrengthen/EquipStrengthen.lua',(ROOT/'Tools/game/forge/EquipStrengthen.lua').read_bytes())
        overlay(base+'/Common/CysForgeArt.imageset.xml',atlas)
        overlay(base+'/Common/forge-anvil-hammer.png',art.read_bytes())
        skin=(play/base/'Schema/WoWLookSkin.scheme.xml').read_bytes()
        registration=b'<Imageset Name="CysForgeArt" Filename="Common/CysForgeArt.imageset.xml" />'
        if b'CysForgeArt' in skin:assert skin.count(registration)==1
        else:skin=skin.replace(b'</GUIScheme>',b'  '+registration+b'\n</GUIScheme>')
        overlay(base+'/Schema/WoWLookSkin.scheme.xml',skin)
    m['forge_candidate']={'max_level':9,'input':'Space','cost':'existing table + material','failure':'minus one','image_source':'built-in imagegen'}
    (stage/'Bin64/game_data_stage.json').write_text(json.dumps(m,ensure_ascii=False,indent=1)+'\n',encoding='utf8',newline='\n')
    binaries(stage,m);print('Staged',stage,'Game',sha(stage/'Bin64/Game.exe'))
if __name__=='__main__':main()
