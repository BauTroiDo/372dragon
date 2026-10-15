"""Repairs on top of the current CY overlay; original callbacks remain in use."""
from pathlib import Path
import hashlib,shutil,xml.etree.ElementTree as E
import remaining_shop_ui
ROOT=Path(__file__).resolve().parents[2]
LOG=ROOT/'Build/Logs/2026-09-28-hj05-remaining'

def source(rel):
    original=LOG/'ui-baseline'/rel
    if not original.exists():
        live=ROOT/'Build/world-gui/stage-play-21/Overlay/Pre'/rel
        if not live.exists():live=ROOT/'Assets/CanonicalCY/Data'/rel
        original.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(live,original)
    return original.read_text(encoding='utf-8-sig')

def once(s,a,b):
    assert s.count(a)==1,(a,s.count(a))
    return s.replace(a,b)

def files(stage):
    outputs={}
    rel='InterfaceFolder/PetBankMain/PetBankMain.lua';s=source(rel)
    assert s.count('"TOGLE_PET_PAGE"')==2
    s=s.replace('"TOGLE_PET_PAGE"','"CYS_PETBANK_BAG_SELECT"')
    s=once(s,'this:RegisterEvent("UPDATE_PET_PAGE");','this:RegisterEvent("UPDATE_PET_PAGE",false);')
    s=once(s,'this:RegisterEvent("CYS_PETBANK_BAG_SELECT");','this:RegisterEvent("CYS_PETBANK_BAG_SELECT",false);')
    outputs[rel]=s
    rel='InterfaceFolder/PS_ShopList/PS_ShopList.lua';s=source(rel)
    s=once(s,'if szType == "珍兽店" then','if szType == "珍兽店" or szType == "Trân thú" then')
    # A list can include item and pet shops. Select the detail layout from the
    # server snapshot, never from the active search filter or translated label.
    s=once(s,'function PS_ShopList_UpdateDetailShopInfo()',
        '''function PS_ShopList_UpdateDetailShopInfo()
    PS_ShopList_TableSet(PlayerShop:GetCurShopType(g_Owner)==6 and "Trân thú" or "Vật phẩm")''')
    outputs[rel]=s
    rel='InterfaceFolder/Packet/Packet.lua';s=source(rel)
    s=once(s,'elseif ( event == "PS_OPEN_MY_SHOP" )  then\n\t\tPacket_Open();',
        '''elseif ( event == "PS_OPEN_MY_SHOP" )  then
        if tonumber(arg1)==2 then this:Hide() else Packet_Open() end''')
    outputs[rel]=s
    rel='InterfaceFolder/PS_ShopMag/PS_ShopMag.lua';s=source(rel)
    s=once(s,'\t\t\tg_CurStallObj = STALL_PET;',
        '\t\t\tg_CurStallObj = STALL_PET;\n            CloseWindow("Pet")')
    s=s.replace('"珍兽店"','"Trân thú"')
    s=once(s,'PS_ShopMag_Shopkeeper_Name:SetChatString("#YĐiếm chủ:#{_INFOUSR".. szName .. "}");',
        'PS_ShopMag_Shopkeeper_Name:SetText("Chủ: "..szName);')
    s=s.replace('"Điếm chủ ID: "','"ID chủ: "').replace('"Điếm Phố ID:"','"ID tiệm: "')
    s=once(s,'local szIDText = ConvertGuidToShow(szID)','local szIDText = tostring(szID)')
    s=s.replace('"Trạng thái quầy hiện tại:#GKhởi trương"','"Quầy: #GĐang mở"').replace('"Trạng thái quầy hiện tại:#RĐóng cửa"','"Quầy: #RĐóng cửa"')
    outputs[rel]=s
    rel='InterfaceFolder/PS_ShopMag/PS_ShopMag.layout.xml';outputs[rel]=remaining_shop_ui.layout(source(rel))
    rel='InterfaceFolder/PetSoul_LevelUp/PetSoul_LevelUp.lua';s=source(rel)
    s=once(s,'local slot,material,text,pending,busy=CysPetSoulData()',
        'local slot,material,text,pending,busy,locks,color=CysPetSoulData()')
    s=once(s,' CysSoul_Item:SetActionItem(-1);CysSoul_Material:SetActionItem(-1)',
        ' CysSoul_Item:SetActionItem(-1);CysSoul_Material:SetActionItem(-1);CysSoul_Color:SetActionItem(-1)')
    s=once(s,' local first=string.find(text,', ''' if color>=0 then local a=EnumAction(color,"packageitem");CysSoul_Color:SetActionItem(a:GetID()) end
 local count=0
 for i=1,6 do
  local valid,selected=CysPetSoulLockInfo(i)
  local b=_G["CysSoul_Lock"..i]
  b:SetText(selected==1 and "Đã khóa" or "Khóa loại")
  if valid==1 then b:Show() else b:Hide() end
  if valid==1 and busy==0 then b:Enable() else b:Disable() end
  count=count+selected
 end
 local costs={[0]=1,2,2,3,3,4,5}
 CysSoul_Help:SetText("Tẩy: "..costs[count].." nguyên liệu + 50000 Võ Thạch hạ phẩm.\\nKhóa loại: giữ loại thuộc tính, tẩy lại trị số.\\nKhóa màu: kéo vào ô, chuột phải để bỏ.")
 local first=string.find(text,''')
    s='''function CysSoulRows(text,prefix)
 local rows={}
 for line in string.gfind(text,"[^\\n]+") do table.insert(rows,line) end
 for i=1,6 do _G[prefix..i]:SetText(rows[i] or "") end
end
'''+s
    # GetText returns CEGUI's encoded formatting characters. Split the original
    # server string so the second SetText does not turn color codes into glyphs.
    s=once(s,' for i=1,5 do', ''' CysSoulRows(first and string.sub(text,first+2,last and last-1 or -1) or "","CysSoul_CurrentRow")
 CysSoulRows(last and string.sub(text,last+string.len(marker)) or "Chưa có kết quả tẩy.","CysSoul_PendingRow")
 for i=1,5 do''')
    outputs[rel]=s
    rel='InterfaceFolder/PetSoul_LevelUp/PetSoul_LevelUp.layout.xml';tree=E.fromstring(source(rel))
    nodes={w.get('Name'):w for w in tree.iter('Window')};frame=nodes['PetSoul_LevelUp_Frame']
    def prop(name,key,value):
        w=nodes[name];p=w.find("Property[@Name='"+key+"']")
        if p is None:p=E.SubElement(w,'Property',Name=key)
        p.set('Value',value)
    def add(kind,name,x,y,w,h,text='',**extra):
        n=E.SubElement(frame,'Window',Type=kind,Name=name);nodes[name]=n
        for key,value in dict(AbsolutePosition=f'x:{x} y:{y}',AbsoluteSize=f'w:{w} h:{h}',Text=text,**extra).items():prop(name,key,value)
        return n
    add('TLBB_ActionButton','CysSoul_Color',210,46,42,42,Empty='True',DragAcceptName='CYS_SOUL_COLOR',DraggingEnabled='False')
    E.SubElement(nodes['CysSoul_Color'],'Event',Name='MouseRButtonDown',Function='CysPetSoulClearColor()')
    add('TLBB_SimpleText','CysSoul_ColorLabel',210,91,94,22,'Khóa màu',MouseHollow='True')
    prop('PetSoul_LevelUp_Frame','AbsolutePosition','x:30 y:40')
    prop('PetSoul_LevelUp_Frame','AbsoluteSize','w:740 h:630')
    prop('CysSoul_Help','AbsolutePosition','x:310 y:40');prop('CysSoul_Help','AbsoluteSize','w:410 h:75')
    prop('CysSoul_Help','Font','YouYuan9.75')
    for name in ('CysSoul_Current','CysSoul_Pending'):prop(name,'Visible','False')
    for i in range(1,6):prop('CysSoul_Op'+str(i),'AbsolutePosition',f'x:{20+(i-1)*141} y:515')
    for name,x in [('PetName',20),('Next',450),('Wear',545),('Remove',640)]:
        prop('CysSoul_'+name,'AbsolutePosition',f'x:{x} y:550')
    prop('CysSoul_Note','AbsolutePosition','x:20 y:585');prop('CysSoul_Note','AbsoluteSize','w:700 h:40')
    prop('CysSoul_Note','Font','GLFit11')
    for i in range(1,7):
        y=265+(i-1)*40
        for prefix,x,width in [('Current',20,270),('Pending',375,344)]:
            add('TLBB_StaticText','CysSoul_'+prefix+'Row'+str(i),x,y,width,40,
                Font='GLFit11',VertFormatting='TopAligned',HorzFormatting='WordWrapLeftAligned',
                FrameEnabled='False',BackgroundEnabled='False',MouseHollow='True')
        n=add('TLBB_ButtonCommon5','CysSoul_Lock'+str(i),292,y+4,72,22,'Khóa loại')
        E.SubElement(n,'Event',Name='Clicked',Function=f'CysPetSoulLock({i})')
    outputs[rel]=E.tostring(tree,encoding='unicode',xml_declaration=True)
    rows=[]
    for rel,s in outputs.items():
        for layer in ('Pre','Post'):
            p=Path(stage)/'Overlay'/layer/rel;p.parent.mkdir(parents=True,exist_ok=True)
            p.write_text(s,encoding='utf8',newline='\n')
            rows.append(dict(path=p.relative_to(stage).as_posix(),sha256=hashlib.sha256(p.read_bytes()).hexdigest(),bytes=p.stat().st_size))
    return rows
