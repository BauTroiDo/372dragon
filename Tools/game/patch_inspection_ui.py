"""TargetData fixes against canonical Lua, staged through Overlay only."""
def generate(data, name='TargetData'):
    text=data.decode('utf8')
    if name=='TargetEquip':
        old='    local arg1,arg2 = actionItem:GetEnhanceAttAndDef();'
        assert old in text
        text=text.replace(old,'    if type(actionItem.GetEnhanceAttAndDef) ~= "function" then return nil,nil end\n'+old+'\n    if arg1 == nil or arg2 == nil then return nil,nil end')
        old='TargetEquip_FakeObject:SetFakeObject("Target");'
        assert text.count(old)==1
        text=text.replace(old,old+'\n        TargetEquip_FakeObject:RestPositonEx()\n        local h,d,p = TargetEquip_FakeObject:GetCameraEx()\n        if d ~= nil and d > 0 then TargetEquip_FakeObject:SetCameraEx(h * 1.10, d * 0.65, p) end')
        return text.encode('utf8')
    replacements={
        'TargetData_YearAnimal:ComboBoxAddItem("Nạp thêm tại: https://platform.beeknoee.com/billing",5);':'TargetData_YearAnimal:ComboBoxAddItem("Rồng",5);',
        'TargetData_YearAnimal:ComboBoxAddItem("Nạp thêm tại: https://platform.beeknoee.com/billing",7);':'TargetData_YearAnimal:ComboBoxAddItem("Ngựa",7);',
        'this:CareObject(obj_id , 1)':'objCared = obj_id\n\t\tthis:CareObject(objCared, 1, "TargetData")',
        'this:CareObject(objCared, 0, "SelfData");':'this:CareObject(objCared, 0, "TargetData");',
    }
    for old,new in replacements.items():
        assert old in text,old
        text=text.replace(old,new)
    return text.encode('utf8')

def layout(data, frame='TargetEquip'):
    import xml.etree.ElementTree as ET
    root=ET.fromstring(data);nodes={w.get('Name'):w for w in root.iter('Window')}
    before=[(w.get('Name'),w.get('Type'),[(e.get('Name'),e.get('Function')) for e in w.findall('Event')]) for w in root.iter('Window')]
    def prop(name,key,value):
        w=nodes[name];p=next((p for p in w.findall('Property') if p.get('Name')==key),None)
        if p is None:p=ET.SubElement(w,'Property',Name=key)
        p.set('Value',value)
    def box(name,x,y,w,h):
        node=nodes[name]
        for p in list(node.findall('Property')):
            if p.get('Name') in ('Position','Size','AbsolutePosition','AbsoluteSize','UnifiedPosition','UnifiedSize'):node.remove(p)
        prop(name,'UnifiedPosition','{{0,%s},{0,%s}}'%(x,y));prop(name,'UnifiedSize','{{0,%s},{0,%s}}'%(w,h))
    prop(frame+'_TargetData','Tooltip','Thông tin cá nhân')
    prop(frame+'_SelfEquip','Tooltip','Trang bị nhân vật')
    if frame=='TargetEquip':
        for name,node in nodes.items():
            if node.get('Type')=='TLBB_ActionButton' and name.startswith('TargetEquip_Equip'):
                prop(name,'ShowDurability','True')
    if frame=='TargetData':
        prop('TargetData_Frame','AbsoluteSize','w:640 h:480')
        prop('TargetData_Client','UnifiedSize','{{1,0},{1,-52}}')
        prop('TargetData_Checkbox_Frame','UnifiedPosition','{{0,0},{1,-52}}')
        prop('TargetData_Checkbox_Frame','UnifiedSize','{{1,0},{0,52}}')
        tabs=['SelfEquip','TargetData','Pet','TargetInfant','TargetWuhun','Miji','ZhenYuan','JingMai','ShenDing','JueWei','BaoJian','WuYi','ShenQi','Armor','CangPin']
        for i,name in enumerate(tabs):box('TargetData_'+name,(i%8)*80,(i//8)*26,79,25)
        box('TargetData_ID',5,0,610,24)
        fields=[('Age','Tuổi',5,28,130,140,165),('Sex','Giới tính',325,28,105,435,180),
                ('BloodType','Nhóm máu',5,58,130,140,165),
                ('YearAnimal','Con giáp',325,58,105,435,180),
                ('Constellation','Cung hoàng đạo',5,88,130,140,165),
                ('Province','Tỉnh / vùng',325,88,105,435,180)]
        for name,caption,x,y,w,vx,vw in fields:
            box('TargetData_'+name+'_Text',x,y,w,24);prop('TargetData_'+name+'_Text','Text',caption)
            box('TargetData_'+name,vx,y,vw,24)
        for name,caption,y in [('City','Thành phố',122),('Job','Nghề nghiệp',152),('School','Trường học',182),('EMail','Email',212)]:
            box('TargetData_'+name+'_Text',5,y,130,24);prop('TargetData_'+name+'_Text','Text',caption)
            box('TargetData_'+name,140,y,475,24)
        box('TargetData_MessageBoard_Text',5,242,610,24);prop('TargetData_MessageBoard_Text','Text','Giới thiệu cá nhân')
        box('TargetData_MessageBoard',5,268,610,90)
        box('TargetData_Cancel',535,367,80,24)
        after=[(w.get('Name'),w.get('Type'),[(e.get('Name'),e.get('Function')) for e in w.findall('Event')]) for w in root.iter('Window')]
        assert before==after,'widgets or event bindings changed'
        return ET.tostring(root,encoding='utf-8',xml_declaration=True)
    prop('TargetEquip_Frame','UnifiedSize','{{0,640},{0,480}}')
    prop('TargetEquip_Client','UnifiedSize','{{1,0},{1,-52}}')
    prop('TargetEquip_Checkbox_Frame','UnifiedPosition','{{0,0},{1,-52}}')
    prop('TargetEquip_Checkbox_Frame','UnifiedSize','{{1,0},{0,52}}')
    tabs=['SelfEquip','TargetData','Pet','TargetInfant','TargetWuhun','Miji','ZhenYuan','JingMai','ShenDing','JueWei','BaoJian','WuYi','ShenQi','Armor','CangPin']
    for i,name in enumerate(tabs):box('TargetEquip_'+name,(i%8)*80,(i//8)*26,79,25)
    box('TargetEquip_FightScore',20,0,270,24)
    box('TargetEquip_Level',20,25,110,24)
    box('TargetEquip_MenPai',136,25,154,24)
    prop('TargetEquip_MenPai','HorzFormatting','LeftAligned')
    box('TargetEquip_Fuwuqi',20,75,270,24)
    for name,y,caption in [('Confraternity',0,'Bang hội'),('Agname',50,'Danh hiệu'),('Spouse',122,'Phối ngẫu'),('Date',172,'Ngày kết hôn'),('Message',222,'Lời giới thiệu')]:
        box('TargetEquip_'+name+'_Text',338,y,285,22);prop('TargetEquip_'+name+'_Text','Text',caption)
        box('TargetEquip_'+name,338,y+22,285,50 if name=='Agname' else 110 if name=='Message' else 26)
    after=[(w.get('Name'),w.get('Type'),[(e.get('Name'),e.get('Function')) for e in w.findall('Event')]) for w in root.iter('Window')]
    assert before==after,'widgets or event bindings changed'
    return ET.tostring(root,encoding='utf-8',xml_declaration=True)
