"""Build a progression candidate over the published round2 baseline."""
from pathlib import Path
import json,re,shutil,subprocess,struct,xml.etree.ElementTree as ET
from publish_gameplay_fixes import ROOT,NAMES,sha
from deploy_npc_icons import idle,binaries

def auto_lua(s):
    # The next candidate may be based on a previously published candidate.
    # Replace our generated prefix instead of shadowing it with another copy.
    s=s[s.index('local g_unifiedposistion'):]
    if 'g_uiskilloptions[i].combo:SetProperty("Tooltip", "")' not in s:
        s=s.replace('g_uiskilloptions[i].combo:ResetList()', 'g_uiskilloptions[i].combo:ResetList()\n            g_uiskilloptions[i].combo:SetProperty("Tooltip", "")')
    if 'if j == select then g_uiskilloptions[i].combo:SetProperty("Tooltip", desc) end' not in s:
        s=s.replace('g_uiskilloptions[i].combo:AddTextItem(desc,j)', 'g_uiskilloptions[i].combo:AddTextItem(desc,j)\n                if j == select then g_uiskilloptions[i].combo:SetProperty("Tooltip", desc) end')
    keys=set(re.findall(r'#\{([^}]+)\}',s));formats={}
    for line in (ROOT/'Assets/CanonicalCY/Data/ConfigFolder/StrDictionary.txt').read_text(encoding='utf8').splitlines():
        parts=line.split('\t',1)
        if len(parts)==2 and parts[0] in keys and re.search(r'%s\d+',parts[1]):formats['#{'+parts[0]+'}']=parts[1]
    for key in ['ZDZD_200724_13','ZDZD_200724_14','ZDZD_200724_21','ZDZD_200724_22','ZDZD_20220815_21']:
        assert '#{'+key+'}' in formats,key
    lua_formats='local CysAutoFormats={\n'+''.join('    ['+json.dumps(k,ensure_ascii=False)+']='+json.dumps(v,ensure_ascii=False)+',\n' for k,v in sorted(formats.items()))+'}\n'
    return lua_formats+'''-- Resolve CY dictionary placeholders before they reach legacy combo text items.
local function CysAutoFormat(key, ...)
    local text=CysAutoFormats[key] or key
    local compact={ ["#{ZDZD_200724_13}"]="Máu dưới %s0%",["#{ZDZD_200724_21}"]="Khí dưới %s0%",["#{ZDZD_200724_22}"]="Máu thú dưới %s0%",["#{ZDZD_200724_14}"]="%s0 (còn lại %s1)" }
    text=compact[key] or text
    local values=arg
    return (string.gsub(text,"%%s(%d+)",function(index)
        return tostring(values[tonumber(index)+1] or "")
    end))
end
'''+s.replace('ScriptGlobal_Format(', 'CysAutoFormat(')

def main():
    idle();play=ROOT/'Build/world-gui/stage-play-21';stage=ROOT/'Build/world-gui/stage-progression-24'
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
    def put(rel,data):
        dst=stage/rel;dst.parent.mkdir(parents=True,exist_ok=True);dst.write_bytes(data)
        rows=[r for r in m['overlay'] if r['path'].replace('\\','/')==rel]
        if not rows:m['overlay'].append({'path':rel,'origin':'progression generator','reason':'level200 / transparent Alt / automatic combat'});rows=[m['overlay'][-1]]
        rows[0].update(sha256=sha(dst),bytes=dst.stat().st_size)
    for side in ['Pre','Post']:
        from round2_gm import append_dbc,SERVER
        from dbc_inventory import Table
        exp=Table(SERVER/'configs/PlayerExpLevel.txt')
        raw=struct.pack('<6I',0xDDBBCC00,2,0,1,0,2)+b'\0'
        put(f'Overlay/{side}/ConfigFolder/PlayerExpLevel.txt',append_dbc(raw,[[int(r[0]),str(int(r[1]))] for r in exp.rows]))
        rel=f'Overlay/{side}/InterfaceFolder/MainMenuBar_2/MainMenuBar_2.layout.xml'
        root=ET.fromstring((play/rel).read_bytes())
        for w in root.iter('Window'):
            if re.fullmatch(r'MainMenuBar_2_Button_Action\d+',w.get('Name','')):
                w.set('Type','TLBB_ActionButtonNULL')
                for p in list(w.findall('Property')):
                    if p.get('Name')=='BackImage':w.remove(p)
        assert sum(w.get('Type')=='TLBB_ActionButtonNULL' for w in root.iter('Window'))==10
        assert sum(w.get('Type')=='TLBB_Animate' for w in root.iter('Window'))==10
        put(rel,ET.tostring(root,encoding='utf-8',xml_declaration=True))
        # The state is authoritative; update the button only after a server acknowledgement.
        rel=f'Overlay/{side}/InterfaceFolder/AutoAttackSkill/AutoAttackSkill.lua'
        s=(play/rel).read_text(encoding='utf8')
        put(rel,auto_lua(s).encode())
        rel=f'Overlay/{side}/InterfaceFolder/AutoAttackSkill/AutoAttackSkill.layout.xml'
        root=ET.fromstring((play/rel).read_bytes())
        # The private server has no Wuyi progression counter. Do not present an
        # editable termination condition which the server cannot evaluate.
        for w in root.iter('Window'):
            if w.get('Name')=='AutoAttackSkill_Others_Wuyi':
                for prop in list(w.findall('Property')):
                    if prop.get('Name') in ['Disabled','Tooltip']:w.remove(prop)
                ET.SubElement(w,'Property',Name='Disabled',Value='True')
                ET.SubElement(w,'Property',Name='Tooltip',Value='Máy chủ chưa có bộ đếm Võ ý; điều kiện này chưa sử dụng.')
        put(rel,ET.tostring(root,encoding='utf-8',xml_declaration=True))
    m['progression_candidate']={'cap':200,'alt_background':'transparent','server':'cys-test-20260913'}
    (stage/'Bin64/game_data_stage.json').write_text(json.dumps(m,ensure_ascii=False,indent=1)+'\n',encoding='utf8')
    binaries(stage,m);print('Staged',stage,'Game',sha(stage/'Bin64/Game.exe'))
if __name__=='__main__':main()
