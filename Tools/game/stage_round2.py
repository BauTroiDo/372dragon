"""Stage round2 over the verified Play build without mutating the public launcher."""
from pathlib import Path
import json,shutil,subprocess
from publish_gameplay_fixes import ROOT,NAMES,sha
from deploy_npc_icons import idle,binaries
import round2_ui
import round2_gm
import round2_tembank
import struct
from dbc_inventory import Table
def main():
    idle();play=ROOT/'Build/world-gui/stage-play-21';stage=ROOT/'Build/world-gui/stage-round2-23'
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
    changed=[]
    def put(rel,data):
        dst=stage/rel;dst.parent.mkdir(parents=True,exist_ok=True);dst.write_bytes(data)
        rows=[r for r in m['overlay'] if r['path'].replace('\\','/')==rel]
        if not rows:m['overlay'].append({'path':rel,'origin':'CYS round2 generator','reason':'gameplay and UI repair'});rows=[m['overlay'][-1]]
        rows[0].update(sha256=sha(dst),bytes=dst.stat().st_size);changed.append(rel)
    for side in ['Pre','Post']:
        for name in ['CommonSkill','MainMenuBar','MainMenuBar_2','SelfEquip','ActionSkill','LifeSkill','ZhenfaSkill','AutoAttackSkill']:
            for suffix in (['lua','layout.xml'] if name in ['MainMenuBar_2','ZhenfaSkill','AutoAttackSkill'] else ['lua']):
                rel=f'InterfaceFolder/{name}/{name}.{suffix}'
                src=play/f'Overlay/{side}'/rel
                if not src.exists():src=ROOT/'Assets/CanonicalCY/Data'/rel
                data=(round2_ui.lua if suffix=='lua' else round2_ui.layout)(src.read_bytes(),name)
                put(f'Overlay/{side}/{rel}',data)
    for rel,data in round2_gm.generate(play,put).items():put(rel,data)
    # Server controls levelling/cap; the CY oracle has different EXP requirements.
    # Keep the client's STRING ABI and rebuild only this table from authoritative levels.
    exp=Table(round2_gm.SERVER/'configs/PlayerExpLevel.txt')
    raw=struct.pack('<6I',0xDDBBCC00,2,0,1,0,2)+b'\0'
    raw=round2_gm.append_dbc(raw,[[int(r[0]),str(int(r[1]))] for r in exp.rows])
    for side in ['Pre','Post']:put(f'Overlay/{side}/ConfigFolder/PlayerExpLevel.txt',raw)
    for side in ['Pre','Post']:
        put(f'Overlay/{side}/InterfaceFolder/Packet_Temporary/Packet_Temporary.lua',round2_tembank.LUA.encode())
        put(f'Overlay/{side}/InterfaceFolder/Packet_Temporary/Packet_Temporary.layout.xml',round2_tembank.layout())
    m['round2_candidate']={'files':changed,'bag':100,'stack':250,'exp_cap':3.5}
    (stage/'Bin64/game_data_stage.json').write_text(json.dumps(m,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
    binaries(stage,m);print('Staged',stage,'Game',sha(stage/'Bin64/Game.exe'))
if __name__=='__main__':main()
