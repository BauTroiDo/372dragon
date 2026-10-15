"""Stage/publish the exact tested equipment workshop over current Play."""
from pathlib import Path
import argparse,datetime,json,re,shutil,subprocess
from publish_gameplay_fixes import ROOT,NAMES,sha
from deploy_npc_icons import idle,binaries
from dbc_inventory import Table
from round2_gm import append_dbc
import equipcraft_ui as ui

def main():
    p=argparse.ArgumentParser();p.add_argument('mode',choices=['stage','publish']);p.add_argument('--check',type=Path);a=p.parse_args()
    idle();play=ROOT/'Build/world-gui/stage-play-21';stage=ROOT/'Build/world-gui/stage-equipcraft-24'
    pm=json.loads((play/'Bin64/game_data_stage.json').read_text(encoding='utf8'));binaries(play,pm)
    if a.mode=='stage':
        if not stage.exists():
            stage.mkdir()
            for folder in ['Bin64','Patch','Overlay']:shutil.copytree(play/folder,stage/folder)
            shutil.copy2(play/'Play.cmd',stage/'Play.cmd')
            subprocess.run(['powershell','-NoProfile','-Command',f"New-Item -ItemType Junction -Path '{stage/'Data'}' -Target '{ROOT/'Assets/CanonicalCY/Data'}' | Out-Null"],check=True)
        m=pm
        def source(side,rel):
            p=play/f'Overlay/{side}'/rel
            return p if p.exists() else ROOT/'Assets/CanonicalCY/Data'/rel
        def put(side,rel,data):
            rel=f'Overlay/{side}/{rel}';dst=stage/rel;dst.parent.mkdir(parents=True,exist_ok=True);dst.write_bytes(data)
            rows=[r for r in m['overlay'] if r['path'].replace('\\','/')==rel]
            if not rows:m['overlay'].append({'path':rel,'origin':'equipcraft_ui.py','reason':'Equipment workshop'});rows=[m['overlay'][-1]]
            rows[0].update(sha256=sha(dst),bytes=dst.stat().st_size)
        for side in ['Pre','Post']:
            put(side,'InterfaceFolder/CysEquipCraft/CysEquipCraft.lua',ui.LUA.encode())
            put(side,'InterfaceFolder/CysEquipCraft/CysEquipCraft.layout.xml',ui.layout())
            rel='InterfaceFolder/Packet/Packet.layout.xml';put(side,rel,ui.packet_layout(source(side,rel).read_bytes()))
            rel='ConfigFolder/InterfaceEx.txt';src=source(side,rel);rows=Table(src).rows
            assert not any(r[1]=='CysEquipCraft' for r in rows)
            put(side,rel,append_dbc(src.read_bytes(),[[max(r[0] for r in rows)+1,'CysEquipCraft','CysEquipCraft/CysEquipCraft.layout.xml','CysEquipCraft/CysEquipCraft.lua',2,'',19,20,-1,'Thăng Linh · Điêu văn']]))
            for frame,mode in [('DWShike',2),('DWQianghua',3),('DWChaichu',4),('DWHecheng',5),('EquipEducation_ShengLing',1)]:
                rel=f'InterfaceFolder/{frame}/{frame}.lua';s=source(side,rel).read_text(encoding='utf8')
                if mode==1:condition='event=="ZHIZUN_EQUIP_LEVELUP"'
                else:
                    match=re.search(r'event\s*==\s*"UI_COMMAND"\s*and\s*tonumber\(arg0\)\s*==\s*(\d+)',s);assert match,frame
                    condition=f'event=="UI_COMMAND" and tonumber(arg0)=={match[1]}'
                s+=f'\nlocal CysOldCraftEvent={frame}_OnEvent\nfunction {frame}_OnEvent(event)\n if {condition} then CysEquipCraftOpen({mode});return end\n CysOldCraftEvent(event)\nend\n'
                put(side,rel,s.encode())
        for row in m['binaries']:
            if row['name'] in NAMES:
                dst=stage/'Bin64'/row['name'];shutil.copy2(ROOT/'Build/cmake/coord-x64/bin'/row['name'],dst);row.update(sha256=sha(dst),bytes=dst.stat().st_size)
        m['equipcraft_candidate']={'baseline_manifest':sha(play/'Bin64/game_data_stage.json')}
        (stage/'Bin64/game_data_stage.json').write_text(json.dumps(m,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
        binaries(stage,m);print('Staged',stage,'Game',sha(stage/'Bin64/Game.exe'));return
    assert a.check
    sm=json.loads((stage/'Bin64/game_data_stage.json').read_text(encoding='utf8'));binaries(stage,sm)
    assert sha(play/'Bin64/game_data_stage.json')==sm['equipcraft_candidate']['baseline_manifest']
    run=json.loads((a.check/'run.json').read_text(encoding='utf-8-sig'));log=(a.check/'WXClient.log').read_text(encoding='utf8',errors='replace')
    assert run['passed'] and run['game_sha256']==sha(stage/'Bin64/Game.exe') and run['stage_manifest_sha256']==sha(stage/'Bin64/game_data_stage.json')
    assert 'CYS-EQUIPCRAFT: RESULT errors=0' in log
    for bad in ['CYS-EQUIPCRAFT: FAIL','CYS Lua failure','Packet handler exception']:assert bad not in log,bad
    for row in sm['overlay']:assert sha(stage/row['path'])==row['sha256'],row['path']
    allowed={r['path'].replace('\\','/') for r in sm['overlay']}|{f'Bin64/{n}' for n in NAMES}
    changed=[rel for rel in sorted(allowed) if not (play/rel).exists() or sha(stage/rel)!=sha(play/rel)]
    stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S');backup=ROOT/'Build/backups/equipcraft-play'/stamp;backup.mkdir(parents=True)
    for rel in changed+['Bin64/game_data_stage.json']:
        if (play/rel).exists():dst=backup/rel;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(play/rel,dst)
    for rel in changed:
        (play/rel).parent.mkdir(parents=True,exist_ok=True);shutil.copy2(stage/rel,play/rel);assert sha(stage/rel)==sha(play/rel)
    pm['binaries']=sm['binaries'];pm['overlay']=sm['overlay'];pm['equipcraft_update']={'at':stamp,'check':str(a.check),'backup':str(backup),'files':changed}
    (play/'Bin64/game_data_stage.json').write_text(json.dumps(pm,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
    binaries(play,pm);print('Published',play,'backup',backup)
if __name__=='__main__':main()
