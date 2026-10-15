"""Stage the four power systems over the verified Play profile."""
from pathlib import Path
import json,shutil,subprocess,struct,xml.etree.ElementTree as E
from publish_gameplay_fixes import ROOT,NAMES,sha
from deploy_npc_icons import idle,binaries
from round2_gm import append_dbc
from dbc_inventory import Table
import power_ui

def main():
    idle();play=ROOT/'Build/world-gui/stage-play-21';stage=ROOT/'Build/world-gui/stage-power-24'
    if not stage.exists():
        stage.mkdir()
        for folder in ['Bin64','Patch','Overlay']:shutil.copytree(play/folder,stage/folder)
        shutil.copy2(play/'Play.cmd',stage/'Play.cmd')
        subprocess.run(['powershell','-NoProfile','-Command',f"New-Item -ItemType Junction -Path '{stage/'Data'}' -Target '{ROOT/'Assets/CanonicalCY/Data'}' | Out-Null"],check=True)
    m=json.loads((play/'Bin64/game_data_stage.json').read_text(encoding='utf8'))
    for row in m['binaries']:
        if row['name'] in NAMES:
            dst=stage/'Bin64'/row['name'];shutil.copy2(ROOT/'Build/cmake/coord-x64/bin'/row['name'],dst)
            row.update(sha256=sha(dst),bytes=dst.stat().st_size)
    def source(side,rel):
        p=play/f'Overlay/{side}'/rel
        return p if p.exists() else ROOT/'Assets/CanonicalCY/Data'/rel
    def put(side,rel,data):
        rel=f'Overlay/{side}/{rel}';dst=stage/rel;dst.parent.mkdir(parents=True,exist_ok=True);dst.write_bytes(data)
        rows=[r for r in m['overlay'] if r['path'].replace('\\','/')==rel]
        if not rows:m['overlay'].append({'path':rel,'origin':'power_ui.py','reason':'CY power systems'});rows=[m['overlay'][-1]]
        rows[0].update(sha256=sha(dst),bytes=dst.stat().st_size)
    for side in ['Pre','Post']:
        rel='InterfaceFolder/Wuhun/Wuhun.layout.xml';put(side,rel,power_ui.wuhun_layout(source(side,rel).read_bytes()))
        for name,extra in [('Wuhun',power_ui.WUHUN),('WuhunMagicUp',power_ui.WUHUN_MAGIC),('Xiulian',power_ui.XIULIAN)]:
            rel=f'InterfaceFolder/{name}/{name}.lua'
            put(side,rel,source(side,rel).read_bytes()+extra.encode())
        rel='InterfaceFolder/Xiulian/Xiulian.layout.xml';put(side,rel,power_ui.xiulian_layout(source(side,rel).read_bytes()))
        gl=ROOT.parent/'client_GL/Data';server=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
        cy_kfs=Table(ROOT/'Assets/CanonicalCY/Data/ConfigFolder/KFSAttrEx.txt');gl_kfs=Table(gl/'ConfigFolder/KFSAttrEx.txt')
        assert len(cy_kfs.rows)==len(gl_kfs.rows)
        assert all(a[0]==b[0] and a[2:]==b[2:] for a,b in zip(cy_kfs.rows,gl_kfs.rows)),'GL translation must preserve every CY coefficient'
        put(side,'ConfigFolder/KFSAttrEx.txt',(gl/'ConfigFolder/KFSAttrEx.txt').read_bytes())
        put(side,'ConfigFolder/PetSoulExtension.txt',(gl/'ConfigFolder/PetSoulExtension.txt').read_bytes())
        soul_ids={r[0] for r in Table(server/'configs/PetSoulBase.txt').rows}
        rows=[[r[0],r[10],r[12],r[18],r[11],r[8],r[2],r[14]] for r in Table(gl/'ConfigFolder/PetEquipBase.txt').rows if r[0] in soul_ids]
        assert len(rows)==len(soul_ids)
        raw=struct.pack('<12I',0xDDBBCC00,8,0,1,0,2,2,2,0,0,0,0)+b'\0'
        put(side,'ConfigFolder/CysPetSoulCatalog.txt',append_dbc(raw,rows))
        scheme=E.fromstring(source(side,'InterfaceFolder/Schema/WoWLookSkin.scheme.xml').read_bytes())
        for name in ['PetSoulEquip1','PetSoulEquip2']:
            put(side,'InterfaceFolder/Icons/'+name+'.imageset.xml',(gl/f'InterfaceFolder/Icons/{name}.imageset.xml').read_bytes())
            put(side,'MaterialFolder/Icons/'+name+'.jpg',(gl/f'MaterialFolder/Icons/{name}.jpg').read_bytes())
            if not any(e.get('Name')==name for e in scheme.findall('Imageset')):E.SubElement(scheme,'Imageset',Name=name,Filename=f'Icons/{name}.imageset.xml')
        put(side,'InterfaceFolder/Schema/WoWLookSkin.scheme.xml',E.tostring(scheme,encoding='utf-8',xml_declaration=True))
        for ext,convert in [('lua',lambda b:power_ui.shending_lua(b.decode('utf8')).encode()),('layout.xml',power_ui.shending_layout)]:
            rel='InterfaceFolder/SelfShenDing/SelfShenDing.'+ext
            put(side,rel,convert(source(side,rel).read_bytes()))
        put(side,'InterfaceFolder/PetSoul_LevelUp/PetSoul_LevelUp.lua',power_ui.SOUL.encode())
        put(side,'InterfaceFolder/PetSoul_LevelUp/PetSoul_LevelUp.layout.xml',power_ui.soul_layout())
        p=source(side,'ConfigFolder/InterfaceEx.txt');t=Table(p)
        assert not any(r[1]=='PetSoul_LevelUp' for r in t.rows)
        key=max(int(r[0]) for r in t.rows)+1
        put(side,'ConfigFolder/InterfaceEx.txt',append_dbc(p.read_bytes(),[[key,'PetSoul_LevelUp','PetSoul_LevelUp/PetSoul_LevelUp.layout.xml','PetSoul_LevelUp/PetSoul_LevelUp.lua',2,'',19,20,-1,'Thú hồn']]))
    m['power_candidate']={'server':'cys-test-20260913','systems':['wuhun','petsoul','shending','xiulian']}
    (stage/'Bin64/game_data_stage.json').write_text(json.dumps(m,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
    binaries(stage,m);print('Staged',stage,'Game',sha(stage/'Bin64/Game.exe'))
if __name__=='__main__':main()
