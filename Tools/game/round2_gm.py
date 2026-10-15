"""Port the existing GL GM Console with CY catalog IDs and existing server authority."""
from pathlib import Path
import re,struct,sys,copy,configparser,xml.etree.ElementTree as ET
from dbc_inventory import Table
ROOT=Path(__file__).resolve().parents[2]
GL=ROOT.parent/'client_GL'
SERVER=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')

def append_dbc(raw,rows):
    magic,cols,count,poolsize=struct.unpack_from('<4I',raw);assert magic==0xDDBBCC00
    types=struct.unpack_from('<%dI'%cols,raw,16);start=16+cols*4;end=start+cols*count*4
    pool=bytearray(raw[end:]);assert len(pool)==poolsize
    records=bytearray(raw[start:end])
    for row in rows:
        assert len(row)==cols
        for typ,value in zip(types,row):
            if typ==2:
                offset=len(pool);pool.extend(str(value).encode('utf8')+b'\0');records.extend(struct.pack('<I',offset))
            elif typ==1:records.extend(struct.pack('<f',float(value)))
            else:records.extend(struct.pack('<I',int(value)&0xffffffff))
    header=bytearray(raw[:start]);struct.pack_into('<II',header,8,count+len(rows),len(pool))
    return bytes(header+records+pool)

def generate(play,put):
    def source(side,rel):
        p=play/f'Overlay/{side}'/rel
        return p if p.exists() else ROOT/'Assets/CanonicalCY/Data'/rel
    lua=(GL/'Data/InterfaceFolder/GmTool/GmTool.lua').read_text(encoding='utf8')
    # CY server uses contiguous sect IDs 0..14; GL's historic 10/11 branches differ.
    names=['Thiếu Lâm','Minh Giáo','Cái Bang','Võ Đang','Nga Mi','Tinh Túc','Thiên Long','Thiên Sơn','Tiêu Dao','Không có phái','Mộ Dung','Đường Môn','Quỷ Cốc','Đào Hoa Đảo','Tuyệt Tình Cốc']
    lua=re.sub(r'local gmSectNames = \{[^\n]+',lambda _: 'local gmSectNames = {'+','.join('"'+x+'"' for x in names)+'};',lua,count=1)
    # GL's local data indices are plain tab-separated text, despite the .dll suffix.
    patch={}
    from round2_gm_rules import generate_rules
    patch['Patch/Plugin_GmEquipRules.dll']=generate_rules()
    lingyu={int(r[0]) for r in Table(SERVER/'configs/LingYuBase.txt').rows}
    for name in ['EquipBase','CommonItem','GemInfo']:
        t=Table(ROOT/f'Assets/CanonicalCY/Data/ConfigFolder/{name}.txt')
        valid={int(r[0]) for r in Table(SERVER/f'configs/{name}.txt').rows}
        lines=[]
        for r in t.rows:
            if int(r[0]) not in valid:continue
            label=re.sub(r'[\t\r\n]+',' ',str(r[10 if name=='EquipBase' else 7 if name=='GemInfo' else 6]))
            count=1 if name=='EquipBase' else 250 if name=='GemInfo' or int(r[12])>1 else 1
            kind=('lingwu' if int(r[0]) in lingyu else 'equip') if name=='EquipBase' else 'item'
            lines.append(f'{label}\t{r[0]}\t{count}\t{kind}')
        patch.setdefault('Patch/Plugin_GameSearch.dll',b'')
        patch['Patch/Plugin_GameSearch.dll']+=('\n'.join(lines)+'\n').encode()
    scenes={int(r[0]):r for r in Table(ROOT/'Assets/CanonicalCY/Data/ConfigFolder/SceneDefineEx.txt').rows}
    info=configparser.ConfigParser(interpolation=None,strict=False,inline_comment_prefixes=(';',))
    info.read_string((SERVER/'configs/SceneInfo.ini').read_bytes().decode('gbk'))
    lines=[]
    for section in info.sections():
        if not re.fullmatch(r'scene\d+',section):continue
        s=info[section]
        if s.getint('active',0)!=1 or s.getint('type',-1)!=0 or not (SERVER/'Game_2/Scene'/s['file']).exists():continue
        label=scenes.get(s.getint('clientres',-1),[0,s.get('name','')])[1]
        lines.append(f'{int(section[5:])}\t{label}\t0\n')
    patch['Patch/Plugin_GmSceneSearch.dll']=''.join(lines).encode()
    rows=Table(SERVER/'configs/MonsterAttrExTable.txt').rows
    patch['Patch/Plugin_GmMonsterSearch.dll']=(''.join(f'{r[0]}\t{r[1]}\t{r[7]}\t'+('npc' if r[13]==1 else 'monster')+'\n' for r in rows)).encode()
    layout=(GL/'Data/InterfaceFolder/GmTool/GmTool.layout.xml').read_bytes()
    types={w.get('Type') for w in ET.fromstring(layout).iter('Window') if '_GLFit' in w.get('Type','')}
    doc=ET.fromstring(layout)
    def prop(w,name,value):
        p=w.find(f"Property[@Name='{name}']")
        if p is None:p=ET.SubElement(w,'Property',Name=name)
        p.set('Value',value)
    labels={'GmTool_TargetSelf':'Bản thân','GmTool_TargetLock':'Khoá mục tiêu','GmTool_TargetSearchButton':'Tìm','GmTool_ItemModeNormal':'Vật phẩm','GmTool_ItemModeEquip':'Trang bị','GmTool_ItemModeLingwu':'Linh Võ','GmTool_EquipRandom':'Ngẫu nhiên','GmTool_EquipCustom':'Tuỳ chọn'}
    labels.update({'GmTool_ItemSearchButton':'Tìm','GmTool_ItemPrev':'Trước','GmTool_ItemNext':'Sau','GmTool_EquipStarLabel':'#WSao'})
    for w in doc.iter('Window'):
        name=w.get('Name','')
        if name in labels:prop(w,'Text',labels[name])
        if re.fullmatch('GmTool_ItemName[1-6]',name):
            prop(w,'HorzLabelFormatting','WordWrapLeftAligned');prop(w,'Font','GLFit10')
            prop(w,'AbsoluteSize','w:132 h:43')
        if re.fullmatch('GmTool_ItemMeta[1-6]',name):
            prop(w,'Font','GLFit10');prop(w,'AbsolutePosition','x:62 y:54');prop(w,'AbsoluteSize','w:130 h:18')
        if name=='GmTool_TargetMark':prop(w,'Font','GLFit11')
        if name=='GmTool_TargetMarkFrame':prop(w,'Visible','False')
        for p in w.findall("Property[@Name='Text']"):
            if p.get('Value')=='#WMô-đun chức năng':p.set('Value','#WChức năng')
    layout=ET.tostring(doc,encoding='utf-8',xml_declaration=True)
    lua=lua.replace('"#WID "..tostring(result.id).."  #GCộng dồn "..tostring(result.count)','"#WID "..tostring(result.id).."  #G×"..tostring(result.count)')
    lua=lua.replace('Đồ thường: ngẫu nhiên theo bảng hoặc tùy chỉnh trường giới hạn','Ngẫu nhiên hoặc tuỳ chỉnh thuộc tính')
    lua=lua.replace('Linh Võ: ngẫu nhiên theo bộ vị hoặc tùy chỉnh ba dòng','Linh Võ: ngẫu nhiên hoặc tuỳ chỉnh')
    for side in ['Pre','Post']:
        scheme=ET.fromstring(source(side,'InterfaceFolder/Schema/WoWLookSkin.scheme.xml').read_bytes())
        native={m.get('WindowType'):m for m in scheme.findall('FalagardMapping')}
        definitions={}
        needed={native[t.split('_GLFit')[0]].get('LookNFeel') for t in types}
        for l in scheme.findall('LookNFeel'):
            if needed.issubset(definitions):break
            tree=ET.fromstring(source(side,'InterfaceFolder/'+l.get('Filename')).read_bytes())
            definitions.update({v.get('name'):v for v in tree.findall('WidgetLook')})
        looks=ET.Element('Falagard');mappings=[]
        for kind in sorted(types):
            base,size=kind.split('_GLFit');mapping=copy.deepcopy(native[base]);look=copy.deepcopy(definitions[mapping.get('LookNFeel')])
            look.set('name',kind+'_Look');mapping.set('WindowType',kind);mapping.set('LookNFeel',look.get('name'))
            for p in look.findall("Property[@name='Font']"):look.remove(p)
            ET.SubElement(look,'Property',name='Font',value='GLFit'+size)
            for component in look.iter('TextComponent'):
                for p in component.iter():
                    if p.tag=='Font':p.set('name','GLFit'+size)
            looks.append(look);mappings.append(mapping)
        # Only GM-specific look/font definitions; no responsive adapter or shared look changes.
        for size in [10,11]:
            font=(GL/f'Data/InterfaceFolder/Schema/GLFit{size}.font').read_bytes()
            put(f'Overlay/{side}/InterfaceFolder/Schema/GLFit{size}.font',font)
            ET.SubElement(scheme,'Font',Name=f'GLFit{size}',Filename=f'Schema/GLFit{size}.font',Type='FreeType')
        ET.SubElement(scheme,'LookNFeel',Filename='Schema/CysGm.looknfeel.xml')
        for m in mappings:scheme.append(m)
        put(f'Overlay/{side}/InterfaceFolder/Schema/CysGm.looknfeel.xml',ET.tostring(looks,encoding='utf-8',xml_declaration=True))
        put(f'Overlay/{side}/InterfaceFolder/Schema/WoWLookSkin.scheme.xml',ET.tostring(scheme,encoding='utf-8',xml_declaration=True))
        table=source(side,'ConfigFolder/InterfaceEx.txt');t=Table(table)
        assert not any(r[1]=='GmTool' for r in t.rows)
        window=max(int(r[0]) for r in t.rows)+1
        temwindow=next(r[0] for r in t.rows if r[1]=='Packet_Temporary')
        put(f'Overlay/{side}/ConfigFolder/InterfaceEx.txt',append_dbc(table.read_bytes(),[[window,'GmTool','GmTool/GmTool.layout.xml','GmTool/GmTool.lua',2,'',19,20,-1,'GM Console GL']]))
        table=source(side,'ConfigFolder/UICommandIndex.txt');t=Table(table);cmds=[316022021,426042021,426042023,999261012,999261013,999261014]
        assert not any(r[1] in cmds for r in t.rows),'existing GM routes must be inspected'
        key=max(int(r[0]) for r in t.rows)
        put(f'Overlay/{side}/ConfigFolder/UICommandIndex.txt',append_dbc(table.read_bytes(),[[key+i+1,cmd,window] for i,cmd in enumerate(cmds)]+[[key+len(cmds)+1,990025,temwindow]]))
        put(f'Overlay/{side}/InterfaceFolder/GmTool/GmTool.lua',lua.encode())
        put(f'Overlay/{side}/InterfaceFolder/GmTool/GmTool.layout.xml',layout)
        operation=ET.fromstring(source(side,'InterfaceFolder/Operation/Operation.layout.xml').read_bytes())
        parent=next(w for w in operation.iter('Window') if w.get('Name')=='Operation_Frame_Client')
        button=ET.SubElement(parent,'Window',Type='TLBB_ButtonCommon5',Name='Operation_GmTool')
        for key,value in {'UnifiedPosition':'{{0.15,0},{0,197}}','UnifiedSize':'{{0.7,0},{0,20}}','Text':'GM Tool','Tooltip':'Mở công cụ GM; máy chủ kiểm tra quyền tài khoản.'}.items():ET.SubElement(button,'Property',Name=key,Value=value)
        ET.SubElement(button,'Event',Name='Clicked',Function='Operation_GmTool_Clicked()')
        put(f'Overlay/{side}/InterfaceFolder/Operation/Operation.layout.xml',ET.tostring(operation,encoding='utf-8',xml_declaration=True))
        op=source(side,'InterfaceFolder/Operation/Operation.lua').read_bytes()+b'''\nfunction Operation_GmTool_Clicked()
    Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID(900066)
    Set_XSCRIPT_Function_Name("OpenGmTool")
    Set_XSCRIPT_ParamCount(0)
    Send_XSCRIPT()
    this:Hide()
end
'''
        put(f'Overlay/{side}/InterfaceFolder/Operation/Operation.lua',op)
    return patch
