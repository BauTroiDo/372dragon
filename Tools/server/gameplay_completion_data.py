"""Authored crafting data recovery; reference packs and CanonicalCY stay read-only."""
from pathlib import Path
import copy,json,re,struct,sys,xml.etree.ElementTree as ET
from gameplay_completion import ROOT,SERVER,OUT,OWN,baseline,sha
sys.path.insert(0,str(ROOT/'Tools/game'))
from dbc_inventory import Table,decode
from hj_appearance_data import RawTable
HJ=ROOT.parent/'Tools/DATA NEW/CYHJ091026/Config'
REF=ROOT.parent/'Tools/DATA NEW/DataCY31-08-26/tlbb15/Public/Data/Script'
PLAY=ROOT/'Build/world-gui/stage-play-21'

def client(name):
    return client_asset('ConfigFolder/'+name+'.txt')

def client_asset(rel):
    for p in [PLAY/'Overlay/Post'/rel,PLAY/'Overlay/Pre'/rel,ROOT/'Assets/CanonicalCY/Data'/rel]:
        if p.exists():
            dest=OUT/'baseline/client'/rel
            if not dest.exists():dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(p.read_bytes())
            return dest
    raise FileNotFoundError(rel)

def binary(types,rows):
    pool=bytearray(b'\0');offsets={b'':0};cells=bytearray()
    for row in sorted(rows,key=lambda r:r[0]):
        assert len(row)==len(types)
        for t,v in zip(types,row):
            if t==2:
                if isinstance(v,str):v=v.encode('utf8')
                if v not in offsets:offsets[v]=len(pool);pool.extend(v+b'\0')
                v=offsets[v]
            cells.extend(struct.pack('<'+('f' if t==1 else 'i' if t==0 else 'I'),v))
    return b'\x00\xcc\xbb\xdd'+struct.pack('<3I',len(types),len(rows),len(pool))+struct.pack('<%dI'%len(types),*types)+cells+pool

def server_table(name):
    rel='configs/'+name+'.txt';baseline(rel)
    return Table(OUT/'baseline/server'/rel)

def table_bytes(t,rows):
    return ('\n'.join(['\t'.join(t.types),'\t'.join(t.names)]+['\t'.join(map(str,r))for r in sorted(rows,key=lambda r:r[0])])+'\n').encode('utf8')

def authored():
    global_text=decode((REF/'ScriptGlobal.lua').read_bytes()).replace('\r','')
    constants=dict(re.findall(r'^\s*([A-Z][A-Z0-9_]*)\s*=\s*(-?\d+)\s*(?:--[^\n]*)?$',global_text,re.M))
    result={};provenance=[]
    for sid,name in [(700900,'general_recipe'),(700901,'foodmat'),(700959,'substuff'),(700960,'g_fengren_yifu')]:
        p=REF/'event/peifang'/(name+'.lua');s=decode(p.read_bytes()).replace('\r','')
        declaration=s.split('\nfunction ',1)[0]
        declaration=re.sub(r'--[^\n]*','',declaration)
        declaration=re.sub(r'\b[A-Z][A-Z0-9_]+\b',lambda m:constants[m[0]] if m[0]in constants else m[0],declaration)
        declaration=re.sub(r'x'+str(sid)+r'_g_(\w+)',r'D.\1',declaration)
        declaration=re.sub(r'\n\s*\n','\n',declaration)
        data=('-- Generated from original CY '+name+'.lua; SHA256 '+sha(p.read_bytes())+'\nlocal D={}\n'+declaration+'\nreturn D\n').encode('utf8')
        result['GameServer/lualib/cys_recipe_data_'+str(sid)+'.lua']=data
        provenance.append(dict(script=sid,path=str(p),sha256=sha(p.read_bytes())))
    (OUT/'authored-recipe-sources.json').write_text(json.dumps(provenance,indent=2),encoding='utf8')
    return result

def generate():
    recipes=server_table('ItemCompound');files=authored();report={}
    old={name:server_table(name)for name in ['EquipBase','CommonItem','GemInfo','PetEquipBase']}
    known={r[0]for t in old.values()for r in t.rows}
    wanted={r[2]for r in recipes.rows if r[2]>0 and r[2]not in known}
    # Dependencies of the recovered original recipe tables are also required.
    for rel,data in files.items():wanted|={int(v)for v in re.findall(rb'\b[123][0-9]{7}\b',data)if int(v)not in known}
    imported={};missing=set(wanted);icons=set()
    for name in ['EquipBase','CommonItem']:
        donor=Table(HJ/(name+'.txt'));dest=old[name]
        rows=[r for r in donor.rows if r[0]in wanted];missing-={r[0]for r in rows}
        # txtreader always converts GBK to UTF-8. Keep original bytes and append
        # donor bytes; rewriting decoded headers as UTF-8 corrupts every key.
        original=RawTable(OUT/'baseline/server/configs'/(name+'.txt'))
        source_raw=RawTable(HJ/(name+'.txt'))
        files['configs/'+name+'.txt']=original.extend([source_raw.byid[r[0]]for r in rows])
        raw=RawTable(client(name));mapped=[]
        for r in rows:
            if r[0]in raw.byid:continue
            if name=='EquipBase':out=r[:18]+r[21:25]+[0,-1]+r[25:101]+r[18:21]
            else:out=r[:15]+r[16:26]+[0,0]+[r[15]]
            col=18 if name=='EquipBase'else 5
            icons.add(out[col]);out[col]='CysCraft'+out[col]
            mapped.append([v.encode('utf8')if isinstance(v,str)else v for v in out])
        files['CLIENT/ConfigFolder/'+name+'.txt']=raw.extend(mapped)
        imported[name]=[r[0]for r in rows]
    # Preserve native columns without a server equivalent; synchronize meaningful fields.
    cy=RawTable(client('ItemCompound'));mapped=[]
    for r in recipes.rows:
        prior=cy.byid.get(r[0]);out=r[:20]+r[25:30]+r[20:23]+([-1]*7)+r[23:25]+[r[30]]
        # Unused CY fields are intentionally not copied from a different recipe at this ID.
        mapped.append(out)
    files['CLIENT/ConfigFolder/ItemCompound.txt']=binary(cy.types,mapped)
    # Runtime includes remapped CY faction professions (70+). Preserve native translations
    # only where the profession identity (level table and icon) matches.
    abilities=server_table('Ability');cy=RawTable(client('Ability'));mapped=[]
    for r in abilities.rows:
        q=list(r);c=cy.byid.get(r[0])
        if c and decode(c[4]).lower()==str(r[4]).lower() and decode(c[11])==r[11]:
            for col in [1,13,15]:q[col]=c[col]
        mapped.append(q)
    files['CLIENT/ConfigFolder/Ability.txt']=binary(cy.types,mapped)
    index={}
    for p in (HJ.parent/'Interface').rglob('*.imageset.xml'):
        tree=ET.fromstring(p.read_bytes())
        for e in tree.findall('Image'):index.setdefault(e.get('Name'),(p,tree))
    groups={}
    for icon in sorted(icons):
        p,tree=index[icon];groups.setdefault(p,(tree,set()))[1].add(icon)
    scheme_rel='InterfaceFolder/Schema/WoWLookSkin.scheme.xml'
    scheme=client_asset(scheme_rel).read_bytes();additions=[]
    for p,(tree,names)in groups.items():
        filename=tree.get('Imagefile').replace('\\','/');name='CysCraft'+tree.get('Name')
        candidates=[HJ.parent/'Interface'/filename,p.parent/Path(filename).name]+[f/filename for f in sorted(HJ.parent.glob('Material*'))]
        source=next(f for f in candidates if f.exists())
        bitmap='Icons/CysCraft'+Path(filename).name
        files['CLIENT/InterfaceFolder/'+bitmap]=source.read_bytes()
        doc=ET.Element('Imageset',dict(tree.attrib,Name=name,Imagefile=bitmap))
        for e in tree.findall('Image'):
            if e.get('Name')in names:ET.SubElement(doc,'Image',dict(e.attrib,Name='CysCraft'+e.get('Name')))
        rel='Icons/'+name+'.imageset.xml'
        files['CLIENT/InterfaceFolder/'+rel]=ET.tostring(doc,encoding='utf-8',xml_declaration=True)
        additions.append(f'  <Imageset Name="{name}" Filename="{rel}" />'.encode())
    files['CLIENT/'+scheme_rel]=scheme.replace(b'</GUIScheme>',b'\n'.join(additions)+b'\n</GUIScheme>')
    rel='InterfaceFolder/Synthesize/Synthesize.layout.xml'
    tree=ET.fromstring(client_asset(rel).read_bytes())
    windows={w.get('Name'):w for w in tree.iter('Window')}
    fourth=windows['Synthesize_MaterialIcon4_Frame'];fifth=copy.deepcopy(fourth)
    for e in fifth.iter():
        for k,v in list(e.attrib.items()):e.set(k,v.replace('Icon4','Icon5').replace('Material4','Material5').replace('Tip(4)','Tip(5)'))
    next(w for w in tree.iter('Window')if fourth in list(w)).append(fifth)
    def setprop(w,name,value):
        p=next((p for p in w.findall('Property')if p.get('Name')==name),None)
        if p is None:p=ET.SubElement(w,'Property',{'Name':name})
        p.set('Value',value)
    setprop(fifth,'UnifiedPosition','{{0.05,0},{0,323}}')
    for w in tree.iter('Window'):
        name=w.get('Name')
        if re.fullmatch(r'Synthesize_MaterialIcon[1-5]_Amount',name):
            w.set('Type','TLBB_SimpleMulitiTextFrame')
            setprop(w,'UnifiedPosition','{{0,36},{0,18}}');setprop(w,'UnifiedSize','{{1,-36},{0,18}}')
            setprop(w,'HorzFormatting','LeftAligned')
        if re.fullmatch(r'Synthesize_Material[1-5]_Name_Text',name):
            setprop(w,'UnifiedSize','{{1,-36},{0,18}}')
        if name in ['Synthesize_SpecialMaterial_Text','Synthesize_SpecialMaterialIcon_Frame']:
            setprop(w,'UnifiedPosition','{{0.05,0},{0,'+('359'if name.endswith('_Text')else'379')+'}}')
        offsets={'Synthesize_Make':-143,'Synthesize_Refuse':-63,'Synthesize_Decrease':-225,'Synthesize_MadeAmount_Bk':-207,'Synthesize_More':-176}
        if name in offsets:setprop(w,'UnifiedPosition','{{1,'+str(offsets[name])+'},{1,'+('-18'if name in ['Synthesize_Decrease','Synthesize_More']else'-20')+'}}')
        if name=='Synthesize_Make':setprop(w,'AbsoluteSize','w:80 h:20')
        if name=='Synthesize_Refuse':setprop(w,'AbsoluteSize','w:60 h:20')
        for prop in w.findall('Property'):
            if w.get('Name')=='Synthesize_Frame'and prop.get('Name')=='AbsoluteSize':prop.set('Value','w:440 h:502')
            if w.get('Name')=='Synthesize_Item_Frame'and prop.get('Name')=='UnifiedSize':prop.set('Value','{{0.9,0},{0,36}}')
    files['CLIENT/'+rel]=ET.tostring(tree,encoding='utf-8',xml_declaration=True)
    rel='InterfaceFolder/Synthesize/Synthesize.lua'
    lua=client_asset(rel).read_text(encoding='utf-8-sig')
    lua=re.sub(r'for\s+i=1,\s*4\s+do','for i=1, 5 do',lua)
    lua=re.sub(r'Material_Icon\[i\]\s*:\s*Hide\(\);',
        'Material_Icon[i]:Hide(); Material_Frame[i]:Hide();',lua)
    lua=re.sub(r'if holdnum > 99 then.*?\n\s*end',
        'Material_Num[i]:SetText("#e010101" .. holdnum .. "/" .. stuffnum);',lua,flags=re.S)
    anchor='\telseif who == 4 then'
    assert anchor in lua
    lua=lua.replace(anchor,'\telseif who == 5 then\n\t\titemID,stuffnum = DataPool:GetPrescrList_Item_Requirement(nSelIndex,5);\n\t\tleft, right, top, bottom = Synthesize_MaterialIcon5_Mask:GetPixelRect();\n'+anchor)
    files['CLIENT/'+rel]=lua.encode('utf8')
    report.update(imported=imported,missing=sorted(missing),recipes=len(recipes.rows),abilities=len(abilities.rows),icons=len(icons))
    # Item dependencies are reported separately; item definitions alone are not proof
    # that scripts, skills, appearance resources, or random attribute rules exist.
    eq={r[0]:r for r in Table(HJ/'EquipBase.txt').rows}
    co={r[0]:r for r in Table(HJ/'CommonItem.txt').rows}
    report['equip_dependencies']=[dict(id=i,visual=eq[i][6],point=eq[i][5],icon=eq[i][21],rule=eq[i][89],skill=eq[i][19],script=eq[i][20])for i in imported['EquipBase']]
    report['common_dependencies']=[dict(id=i,icon=co[i][5],script=co[i][13],skill=co[i][14],recipe=co[i][22])for i in imported['CommonItem']]
    (OUT/'data-recovery.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
    return files

if __name__=='__main__':
    fs=generate()
    for rel,data in fs.items():
        p=OUT/'data-stage'/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
    print('Prepared',len(fs),'files; see',OUT/'data-recovery.json')
