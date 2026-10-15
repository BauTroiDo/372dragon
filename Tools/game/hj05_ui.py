"""Small CY PetBank compatibility repairs; preserve original widgets/callbacks."""
from pathlib import Path
import hashlib
import re,xml.etree.ElementTree as ET
import shutil
ROOT=Path(__file__).resolve().parents[2]
def files(stage):
    def source(rel):
        original=ROOT/'Build/Logs/2026-09-28-hj05-fixes/ui-baseline'/rel
        if original.exists():return original
        p=ROOT/'Build/world-gui/stage-play-21/Overlay/Pre'/rel
        p=p if p.exists() else ROOT/'Assets/CanonicalCY/Data'/rel
        original.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,original)
        return original
    rel='InterfaceFolder/PetBankMain/PetBankMain.lua'
    # Start from the current Play overlay so previous repairs remain intact.
    s=source(rel).read_text(encoding='utf8')
    s=s.replace('szCharName ==" " or szCharName ==nil','szCharName ==" " or szCharName =="" or szCharName ==nil')
    s=s.replace('nSelectArg0 < nPetCount','nSelectArg0 < PETBANK_MAX_COUNT and Pet:IsPresent_PetBank(nSelectArg0)==1')
    s=s.replace('Pet : SetModel_PetBank(0);','Pet : SetModel_PetBank(PETBANK_CURRENT_SELECT);')
    # Optional estate-training data is absent in this server's bank protocol.
    # Missing optional time fields must not abort a normal storage list.
    s=s.replace('nRemainHour > 0 or nRemainMin > 0 or nRemainSec > 0',
        '(nRemainHour or 0) > 0 or (nRemainMin or 0) > 0 or (nRemainSec or 0) > 0')
    s=s.replace('if JYSLOperType > 0 then','if (JYSLOperType or 0) > 0 then')
    s=s.replace('#{ZSYH_120503_18}','Kho trân thú: ')
    s=s.replace('#{JYSL_160518_170}','Rút')
    s=s.replace('#{ZSYH_120503_47}',' cấp mang').replace('#gFF8E92','#cFF8E92')
    s=s.replace('#{VIPTQ3_120517_29}','Thời gian:')
    outputs={rel:s.encode('utf8')}
    for frame in ['PetBankList','BieYePetBar_List']:
        rel='InterfaceFolder/'+frame+'/'+frame+'.lua'
        s=source(rel).read_text(encoding='utf-8-sig')
        # GetFirstPetPosInPag now returns the real sparse index, or -1.
        s,n=re.subn(r'('+frame+r'_List\s*:\s*SetItemSelectByItemID\(nfirstpagpet\);)',
            r'if nfirstpagpet >= 0 then \1 end',s)
        assert n==2,(frame,n)
        s=s.replace('#{ZSYH_120503_19}','Đang mang: ')
        outputs[rel]=s.encode('utf8')
    rel='InterfaceFolder/TargetPet/TargetPet.lua'
    s=source(rel).read_text(encoding='utf-8-sig')
    s=s.replace('#gFF0FA0','#cFFF263').replace('#gFF8E92','#cFF8E92')
    # Same UTF-8 instance-name and detach-before-replace repair as Pet.lua.
    s=s.replace('TargetPet_PetName:SetText(strName2)','TargetPet_PetName:SetText(strName)')
    s=s.replace('TargetPet_PageHeader:SetText("#cFFF263"..strName2)',
        'TargetPet_PageHeader:SetText("#cFFF263Trân thú - "..strName)')
    s=s.replace('TargetPet:SetModelAboutHuanLing()','TargetPet:SetModel()')
    s=s.replace('TargetPet:SetModel()',
        'TargetPet_FakeObject:DetachWindowEx(); TargetPet:SetModel(); TargetPet_FakeObject:AttachWindowEx("My_TargetPet"); TargetPet_FakeObject:RestPositonEx()')
    outputs[rel]=s.encode('utf8')
    rel='InterfaceFolder/TargetPet/TargetPet.layout.xml'
    tree=ET.fromstring(source(rel).read_bytes())
    original=[(w.get('Name'),w.get('Type'),[(e.get('Name'),e.get('Function')) for e in w.findall('Event')]) for w in tree.iter('Window')]
    for p in tree.iter('Property'):
        name,value=p.get('Name'),p.get('Value','')
        if name in ['UnifiedSize','UnifiedPosition']:
            pairs=re.findall(r'\{\s*([-\d.]+)\s*,\s*([-\d.]+)\s*\}',value)
            if len(pairs)==2:p.set('Value','{'+','.join('{'+a+','+format(float(b)*scale,'.5f')+'}' for (a,b),scale in zip(pairs,[1.5,1.2]))+'}')
        elif name in ['AbsoluteSize','AbsolutePosition']:
            p.set('Value',re.sub(r'([whxy]):([-\d.]+)',lambda m:m[1]+':'+format(float(m[2])*(1.5 if m[1] in 'wx' else 1.2),'.5f'),value))
    nodes={w.get('Name'):w for w in tree.iter('Window')}
    def prop(name,key,value):
        w=nodes[name];p=w.find("Property[@Name='"+key+"']")
        if p is None:p=ET.SubElement(w,'Property',Name=key)
        p.set('Value',value)
    def horizontal(name,x,width):
        w=nodes[name]
        for key,axis,prefix in [('UnifiedPosition',x,'{{0,'),('UnifiedSize',width[1], '{{'+str(width[0])+',')]:
            p=w.find("Property[@Name='"+key+"']")
            if p is not None:p.set('Value',re.sub(r'^\{\{[^}]+\}',prefix+str(axis)+'}',p.get('Value')))
    prop('TargetPet_Frame','UnifiedPosition','{{0,16},{0.06,0}}')
    prop('TargetPet_Frame','UnifiedSize','{{0,700},{0,549.6}}')
    for short,label in [('Str','Cường lực'),('Nimbus','Nội lực'),('PhysicalStrength','Thể lực'),('Stability','Trí lực'),('Footwork','Thân pháp')]:
        prop('TargetPet_'+short+'_Text','Text',label)
        horizontal('TargetPet_'+short+'_Text',5,(0,88))
        name='TargetPet_'+('Dexterity' if short=='Footwork' else short)
        horizontal(name,94,(1,-150))
    for short,label in [('Str','TC Cường lực'),('Nimbus','TC Nội lực'),('PhysicalStrength','TC Thể lực'),('Stability','TC Trí lực'),('Footwork','TC Thân pháp')]:
        name='TargetPet_'+short+'Aptitude_Text';prop(name,'Text',label);prop(name,'Font','YouYuan9.75');horizontal(name,5,(0,140))
        horizontal('TargetPet_'+('Dexterity' if short=='Footwork' else short)+'Aptitude',146,(1,-149))
    # Give each translated caption its own column.
    for i,name in enumerate(['WuXing','GenGu','Lingxing']):
        prop('TargetPet_'+name,'AbsolutePosition','x:'+str(4+i*110)+' y:4')
        prop('TargetPet_'+name,'AbsoluteSize','w:109 h:20')
        prop('TargetPet_'+name,'Font','YouYuan9.75')
    for name in ['TargetPet_TargetPetID','TargetPet_ConsortID']:horizontal(name,12,(0,315))
    prop('TargetPet_FakeObject','UnifiedSize','{{0.8,0},{0.9,0}}')
    prop('TargetPet_FakeObject','UnifiedPosition','{{0.1,0},{0.08,0}}')
    prop('TargetPet_NeedLevel','AbsoluteSize','w:182 h:20')
    prop('TargetPet_Growth1','UnifiedPosition','{{1,-135},{0,19}}')
    prop('TargetPet_Growth1','UnifiedSize','{{0,130},{0,20}}')
    prop('TargetPet_Growth1','Text','Tăng trưởng')
    assert original==[(w.get('Name'),w.get('Type'),[(e.get('Name'),e.get('Function')) for e in w.findall('Event')]) for w in tree.iter('Window')]
    outputs[rel]=ET.tostring(tree,encoding='utf-8',xml_declaration=True)
    rel='InterfaceFolder/PetBankList/PetBankList.layout.xml'
    tree=ET.fromstring(source(rel).read_bytes());nodes={w.get('Name'):w for w in tree.iter('Window')}
    prop('PetBankList_Frame','AbsoluteSize','w:270 h:300')
    prop('PetBankList_Frame','UnifiedPosition','{{0,720},{0.3,0}}')
    prop('PetBankList_DragTitle','Text','Trân thú đang mang')
    prop('PetBankList_Choose_Button','UnifiedPosition','{{1,-174},{1,-25}}')
    prop('PetBankList_Choose_Button','AbsoluteSize','w:85 h:24')
    prop('PetBankList_Choose_Button','Text','Đổi chỗ')
    prop('PetBankList_Refuse_Button','UnifiedPosition','{{1,-88},{1,-25}}')
    prop('PetBankList_Refuse_Button','AbsoluteSize','w:85 h:24')
    prop('PetBankList_Refuse_Button','Text','Gửi')
    prop('PetBankList_Choose_Blank','UnifiedSize','{{1,-174},{0,24}}')
    prop('PetBankList_List','UnifiedSize','{{1,-4},{1,-57}}')
    outputs[rel]=ET.tostring(tree,encoding='utf-8',xml_declaration=True)
    # Bank main and bag list must not cover each other's first characters.
    rel='InterfaceFolder/PetBankMain/PetBankMain.layout.xml'
    tree=ET.fromstring(source(rel).read_bytes());nodes={w.get('Name'):w for w in tree.iter('Window')}
    prop('PetBankMain_Frame','UnifiedPosition','{{0,320},{0.3,0}}')
    prop('PetBankMain_DragTitle','Text','Kho trân thú')
    prop('PetBankMain_Choose_Button','Text','Chi tiết')
    prop('PetBankMain_Refuse_xiedaizhenshouliebiao','Text','Đang mang')
    prop('PetBankMain_Type','UnifiedSize','{{0,140},{0,20}}')
    prop('PetBankMain_Type','UnifiedPosition','{{0.5,-70},{1,-36}}')
    prop('PetBankMain_NeedLevel','UnifiedSize','{{0,124},{0,20}}')
    prop('PetBankMain_Level','UnifiedPosition','{{0,132},{0,3}}')
    prop('PetBankMain_Level','UnifiedSize','{{0,70},{0,20}}')
    prop('PetBankMain_StopWatch','UnifiedSize','{{0,48},{0,18}}')
    outputs[rel]=ET.tostring(tree,encoding='utf-8',xml_declaration=True)
    rows=[]
    for rel,data in outputs.items():
      for layer in ['Pre','Post']:
        p=Path(stage)/'Overlay'/layer/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
        rows.append(dict(path=p.relative_to(stage).as_posix(),sha256=hashlib.sha256(p.read_bytes()).hexdigest(),bytes=p.stat().st_size))
    return rows
