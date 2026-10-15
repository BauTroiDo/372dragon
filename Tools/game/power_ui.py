"""Power UI overlays: preserve CY ShenDing; arrange GL soul operations in CY skins."""
import re,xml.etree.ElementTree as E
SHENDING='''
-- The private server acknowledges every material/point mutation before refreshing.
local CysDingPreLoad=SelfShenDing_PreLoad
function SelfShenDing_PreLoad()
 CysDingPreLoad();this:RegisterEvent("CYS_SHENDING_UPDATE")
end
local CysDingEvent=SelfShenDing_OnEvent
function SelfShenDing_OnEvent(event)
 if event=="CYS_SHENDING_UPDATE" then
  if this:IsVisible() then
   if SelfShenDing_FenYe2:GetCheck()==1 then SelfShenDing_OnUpdateShow_Attack(1) else SelfShenDing_OnUpdateShow() end
  end
  return
 end
 CysDingEvent(event)
end
function SelfShenDing_NingLian() CysShenDingAction(1) end
function SelfShenDing2_NingLian() CysShenDingAction(2) end
function SelfShenDing_RongHe() CysShenDingAction(3) end
function SelfShenDing2_RongHe() CysShenDingAction(4) end
function SelfShenDing2_Accept_Click()
 CysShenDingAction(5,g_AttackValue[1].DBValue+g_AttackValue[1].SettingValue,g_AttackValue[2].DBValue+g_AttackValue[2].SettingValue,g_AttackValue[3].DBValue+g_AttackValue[3].SettingValue,g_AttackValue[4].DBValue+g_AttackValue[4].SettingValue)
end
function SelfShenDing2_Reset_Click() CysShenDingAction(6) end
function SelfShenDing_BangZhu()
 PushDebugMessage("Thần Đỉnh có 45 đan mỗi nhánh. Nạp Dược Trần từ vật phẩm trong túi, rồi bấm Ngưng. Dung hợp tiêu 1 Kim Đan đúng loại. Thiết lập lại điểm Côn Võ tốn 2000 Dược Trần.")
end
local function CysDingLabels()
 local costs={200,500,1000,2500,5000,10000,30000,80000,150000}
 for i=1,2 do
  local p=i==1 and "SelfShenDing" or "SelfShenDing2"
  local gold=Player:GetData(i==1 and "JinDanRongHeCount" or "Attack_JinDanCount")
  local max=Player:GetData(i==1 and "MaxJinDanRongHeCount" or "Attack_MaxJinDanCount")
  _G[p.."_Btn_RongHe_Text"]:SetText("Kim đan: "..gold.." / "..max)
  _G[p.."_Btn_RongHe_Text2"]:SetText((i==1 and "Thể lực +" or "Điểm +")..gold*(i==1 and 100 or 80))
  _G[p.."_Btn_RongHe_Text3"]:Hide()
  _G[p.."_ChengGongLv_Text"]:SetText("Thành công: 100%")
  local n=Player:GetData(i==1 and "LianDanCount" or "Attack_DanYaoCount")
  local grade=1;while grade<9 and n>=grade*(grade+1)/2 do grade=grade+1 end
  _G[p.."_XuYaoYaoChen_Text"]:SetText(n>=45 and "Đã đầy" or "Cần "..costs[grade].." bụi")
 end
end
local CysDingShow=SelfShenDing_OnUpdateShow
function SelfShenDing_OnUpdateShow() CysDingShow();CysDingLabels() end
local CysDingAttackShow=SelfShenDing_OnUpdateShow_Attack
function SelfShenDing_OnUpdateShow_Attack(x) CysDingAttackShow(x);CysDingLabels() end
local CysDingPointUpdate=SelfShenDing_UpdateAttackPoints
function SelfShenDing_UpdateAttackPoints()
 CysDingPointUpdate()
 local keys={"Bing","Huo","Xuan","Du"}
 for i=1,4 do _G["SelfShenDing2_ShuXingGong_"..keys[i].."_Text2"]:SetText(tostring(g_AttackValue[i].DBValue+g_AttackValue[i].SettingValue)) end
end
'''

def prop(w,k,v):
    for p in list(w.findall('Property')):
        if p.get('Name')==k:w.remove(p)
    E.SubElement(w,'Property',Name=k,Value=v)

def wuhun_layout(raw):
    root=E.fromstring(raw)
    labels=['Cường lực','Nội lực','Thể lực','Trí lực','Thân pháp']
    originals=['Str','Nimbus','PhysicalStrength','Stability','Footwork']
    actual=['Str','Nimbus','PhysicalStrength','Stability','Dexterity']
    for w in root.iter('Window'):
        name=w.get('Name','')
        for p in w.findall('Property'):
            if p.get('Name') in ['UnifiedPosition','UnifiedSize']:
                p.set('Value',p.get('Value').replace('185.000000','310.000000').replace('184.000000','309.000000'))
        if name=='Wuhun_Frame':prop(w,'UnifiedSize','{{0,741},{0,395}}')
        if name=='Wuhun_FakeObject_Frame':
            prop(w,'UnifiedSize','{{0,410},{0,150}}');prop(w,'UnifiedPosition','{{0,0},{0,0}}')
        if name=='Wuhun_FakeObject':
            prop(w,'UnifiedSize','{{1,-50},{1,0}}');prop(w,'UnifiedPosition','{{0,25},{0,0}}')
        if name=='Wuhun_Head':prop(w,'UnifiedPosition','{{0,480},{0,0}}');prop(w,'UnifiedSize','{{0,185},{0,62}}')
        if name=='Wuhun_Bk3':prop(w,'UnifiedPosition','{{0,418},{0,62}}');prop(w,'UnifiedSize','{{0,310},{0,126}}')
        if name.startswith('Wuhun_Original'):
            for i,part in enumerate(originals):
                if name=='Wuhun_Original'+part+'_Text':
                    prop(w,'Text',labels[i]);prop(w,'UnifiedPosition','{{0,3},{0,%d}}'%(20+21*i));prop(w,'UnifiedSize','{{0,98},{0,20}}')
            if not name.endswith('_Text'):
                y=20+21*(originals.index(name[14:]) if name[14:] in originals else 4)
                prop(w,'UnifiedPosition','{{0,106},{0,%d}}'%y);prop(w,'UnifiedSize','{{0,70},{0,18}}');prop(w,'Tooltip','Giá trị thực tế sau trưởng thành')
        if name in ['Wuhun_'+x+'_Text' for x in originals]:prop(w,'Visible','False')
        if name in ['Wuhun_'+x for x in actual]:
            i=actual.index(name[6:]);prop(w,'UnifiedPosition','{{0,192},{0,%d}}'%(20+i*21));prop(w,'UnifiedSize','{{0,112},{0,20}}');prop(w,'Tooltip','Giá trị cơ bản')
        match=re.fullmatch(r'Wuhun_Property(\d+)(.*)',name)
        if match:
            i=int(match[1]);suffix=match[2];x,width=(1,408) if not suffix else ((1,310) if 'Text' in suffix else (311,98))
            prop(w,'UnifiedPosition','{{0,%d},{0,%d}}'%(x,160+18*(i-1)));prop(w,'UnifiedSize','{{0,%d},{0,18}}'%width)
        if name=='Wuhun_Growth1':prop(w,'Text','Trưởng thành');prop(w,'UnifiedPosition','{{1,-140},{0,10}}');prop(w,'UnifiedSize','{{0,132},{0,18}}')
        if name=='Wuhun_Growth':prop(w,'UnifiedPosition','{{1,-140},{0,29}}');prop(w,'UnifiedSize','{{0,132},{0,18}}')
        if name in ['Wuhun_NeedLevel','Wuhun_Level','Wuhun_ExtraLevel','Wuhun_Type']:
            prop(w,'UnifiedPosition',f'{{{{0,78}},{{0,{4+17*["Wuhun_NeedLevel","Wuhun_Level","Wuhun_ExtraLevel","Wuhun_Type"].index(name)}}}}}')
            prop(w,'UnifiedSize','{{0,162},{0,18}}')
            if name!='Wuhun_Type':prop(w,'Text',{'Wuhun_NeedLevel':'Cấp yêu cầu:','Wuhun_Level':'Cấp Võ hồn:','Wuhun_ExtraLevel':'Cấp hợp thành:'}[name])
        if name in ['Wuhun_NeedLevel_Text','Wuhun_Level_Text','Wuhun_ExtraLevel_Text']:
            prop(w,'UnifiedSize','{{0,48},{0,18}}');prop(w,'UnifiedPosition',f'{{{{1,-52}},{{0,{4+17*["Wuhun_NeedLevel_Text","Wuhun_Level_Text","Wuhun_ExtraLevel_Text"].index(name)}}}}}')
    return E.tostring(root,encoding='utf-8',xml_declaration=True)
WUHUN='''
-- CYS power: concise labels in the existing CY window.
-- Model_Parameter rows 125..134 all center at 0.08. Use the full 150px-high
-- preview and a closer camera than the native 2.0/2.2 distance. Absolute
-- values also work while the model is loading and never compound on refresh.
function CysWuhunPreviewCamera()
 Wuhun_FakeObject:SetCameraEx(0.08,1.0,0.21)
end
local CysWuhunUpdate=Wuhun_Update
function Wuhun_Update()
 CysWuhunUpdate()
 CysWuhunPreviewCamera()
 Wuhun_Growth1:SetText("Trưởng thành")
 local grade=DataPool:GetKfsData("Grade")
 local value=DataPool:GetKfsData("GROWRATE")
 local names={"Thường","Ưu tú","Kiệt xuất","Trác việt","Hoàn mỹ"}
 if grade~=nil and value~=nil then Wuhun_Growth:SetText("#G"..names[grade+1].." · "..value) end
end
'''
def wuhun_lua(raw):
    """Replace only our terminal power block; preserve all original CY handlers."""
    marker=b'-- CYS power: concise labels in the existing CY window.'
    assert raw.count(marker)==1
    return raw[:raw.index(marker)].rstrip()+b'\n'+WUHUN.encode('utf8')
WUHUN_MAGIC='''
-- CYS power: original GL two-soul compound, as implemented by server790075.
function WuhunMagicUp_OnCompound(confirmed)
 if m_Equip_Idx<0 or m_Equip_Item<0 or m_Equip_Idx==m_Equip_Item then return end
 if PlayerPackage:IsBagItemKFS(m_Equip_Idx)~=1 or PlayerPackage:IsBagItemKFS(m_Equip_Item)~=1 then return end
 local a=PlayerPackage:GetBagKfsData(m_Equip_Idx,"EXTRALEVEL")
 local b=PlayerPackage:GetBagKfsData(m_Equip_Item,"EXTRALEVEL")
 if a~=b or a>=7 then PushDebugMessage("Cần hai Võ hồn cùng cấp hợp thành, dưới cấp 7.");return end
 if confirmed~=1 then
  MessageBoxSelf3("WuhunMagicUp_OnCompoundComfirmedBack",{Content="Tiêu Võ hồn nguyên liệu và 10000 vàng/giao tử để tăng 1 cấp hợp thành?",Type="YesNo"});return
 end
 PlayerPackage:Kfs_Op_Do(3,m_Equip_Idx,m_Equip_Item)
end
local CysWuhunCompoundDrop=WuhunMagicUp_Update_Sub_ForCompound
function WuhunMagicUp_Update_Sub_ForCompound(slot)
 if slot>=0 and PlayerPackage:IsBagItemKFS(slot)~=1 then PushDebugMessage("Đặt Võ hồn cùng cấp hợp thành vào ô nguyên liệu.");return end
 CysWuhunCompoundDrop(slot)
end
local CysWuhunCheck=WuhunMagicUp_UICheck
function WuhunMagicUp_UICheck()
 CysWuhunCheck()
 g_YBCheck=0;WuhunMagicUp_Blank_Queren:SetCheck(0);WuhunMagicUp_Blank_Queren:Hide()
 if m_UIType==UI_TYPE_COMPOUND then
  needMoney=10000;WuhunMagicUp_DemandMoney:SetProperty("MoneyNumber",needMoney)
  local a=PlayerPackage:GetBagKfsData(m_Equip_Idx,"EXTRALEVEL")
  local b=PlayerPackage:GetBagKfsData(m_Equip_Item,"EXTRALEVEL")
  if a==nil or b==nil or a~=b or a>=7 then WuhunMagicUp_OK:Disable() end
 end
end
'''
def shending_lua(s):
    return s.split('-- The private server acknowledges')[0]+SHENDING
def shending_layout(raw):
    root=E.fromstring(raw)
    for w in root.iter('Window'):
        name=w.get('Name','')
        match=re.fullmatch(r'SelfShenDing(2)?_Chengdan_(\d+)(_B)?',name)
        if match:
            i=int(match[2]);value=([10,14,18,22,26,31,36,41,46] if match[1] else [15,17,19,24,29,34,39,45,51])[i-1]
            prop(w,'Text',(f'+{value} điểm/đan' if match[1] else f'+{value} thể lực/đan') if match[3] else f'Phẩm {i}')
            prop(w,'HorzFormatting','HorzCentred');prop(w,'VertFormatting','VertCentred')
        match=re.fullmatch(r'SelfShenDing2_ShuXingGong_(Bing|Huo|Xuan|Du)_Text([12])',name)
        if match:
            if match[2]=='1':
                prop(w,'Text',{'Bing':'Băng','Huo':'Hỏa','Xuan':'Huyền','Du':'Độc'}[match[1]])
                # CY nests Text2 inside Text1; include the value column in its
                # parent's width, otherwise CEGUI clips every allocated value.
                prop(w,'UnifiedSize','{{0,118},{0,20}}');prop(w,'HorzFormatting','LeftAligned')
            else:
                prop(w,'UnifiedPosition','{{0,57},{0,0}}');prop(w,'UnifiedSize','{{0,61},{0,20}}');prop(w,'HorzFormatting','RightAligned')
        if name=='SelfShenDing2_ShuXingGong_Title_Text':
            prop(w,'Text','Phân phối điểm');prop(w,'UnifiedPosition','{{0,0},{0,0}}');prop(w,'UnifiedSize','{{1,0},{0,20}}');prop(w,'VertFormatting','VertCentred')
        if name=='SelfShenDing2_ShuXingGong_QianNeng_Text1':prop(w,'Text','Điểm còn:');prop(w,'UnifiedSize','{{0,94},{0,20}}')
        if w.get('Name') in ['SelfShenDing_querengoumai','SelfShenDing_querengoumai_Text']:
            for p in w.findall('Property'):
                if p.get('Name')=='Visible':p.set('Value','False')
            E.SubElement(w,'Property',Name='Visible',Value='False')
        # Keep the existing bottom utility row and replace the purchase label with a button.
        if w.get('Name')=='SelfShenDing_YaoChen':
            for p in w.findall('Property'):
                if p.get('Name')=='UnifiedSize':p.set('Value','{{0,220},{0,20}}')
                if p.get('Name')=='UnifiedPosition':p.set('Value','{{1,-226},{0,2}}')
    parent=next(w for w in root.iter('Window') if any(c.get('Name')=='SelfShenDing_Btn_BangZhu' for c in w.findall('Window')))
    b=E.SubElement(parent,'Window',Type='TLBB_ButtonCommon',Name='CysShenDing_Dust')
    for k,v in {'UnifiedSize':'{{0,130},{0,20}}','UnifiedPosition':'{{0,90},{0,2}}','Text':'Nạp Dược Trần','Tooltip':'Tiêu 1 vật phẩm Dược Trần từ hành trang.'}.items():E.SubElement(b,'Property',Name=k,Value=v)
    E.SubElement(b,'Event',Name='Clicked',Function='CysShenDingAction(7)')
    return E.tostring(root,encoding='utf-8',xml_declaration=True)
def xiulian_layout(raw):
    root=E.fromstring(raw)
    for w in root.iter('Window'):
        name=w.get('Name')
        if name=='Xiulian_XinfaSkill_4':prop(w,'Visible','False')
        if name=='Xiulian_Gongli_Text':prop(w,'Text','');prop(w,'UnifiedSize','{{0,360},{0,22}}');prop(w,'UnifiedPosition','{{0.5,-180},{1,-24}}')
        if name=='Xiulian_Vigor':prop(w,'UnifiedPosition','{{0,6},{0,0}}');prop(w,'UnifiedSize','{{0,348},{0,22}}')
        if name=='Xiulian_Gongli_Tooltip':prop(w,'Visible','False')
    return E.tostring(root,encoding='utf-8',xml_declaration=True)
XIULIAN='''
local CysXiulianUpdate=Xiulian_JingJie_Selected_Update
function Xiulian_JingJie_Selected_Update()
 CysXiulianUpdate()
 local count=XIULIAN_BOOK_SELECT==1 and 5 or XIULIAN_BOOK_SELECT==2 and 6 or 4
 for i=1,6 do if i<=count then XIULIAN_MIJI[i]:Show() else XIULIAN_MIJI[i]:Hide() end end
 if XIULIAN_BOOK_SELECT>=1 and XIULIAN_BOOK_SELECT<=3 then
  Xiulian_SkillJingjie:SetText("Cảnh giới cao nhất: "..Player:GetXiuLianBookInfo(XIULIAN_BOOK_SELECT-1,"Level"))
 end
end
local CysXiulianEvent=Xiulian_OnEvent
function Xiulian_OnEvent(event)
 CysXiulianEvent(event)
 Xiulian_Gongli_Text:SetProperty("UnifiedSize","{{0,280},{0,22}}")
 Xiulian_Gongli_Text:SetProperty("UnifiedPosition","{{0.5,-140},{1,-24}}")
 Xiulian_Vigor:SetProperty("UnifiedSize","{{1,-12},{1,0}}")
 Xiulian_Gongli_Text:SetText("");Xiulian_Vigor:SetText("Công lực: "..Player:GetData("POWER"))
end
'''
def soul_layout():
    root=E.Element('GUILayout')
    def w(parent,kind,name,x,y,width,height,text=None,**props):
        node=E.SubElement(parent,'Window',Type=kind,Name=name)
        values={'AbsolutePosition':f'x:{x} y:{y}','AbsoluteSize':f'w:{width} h:{height}',**props}
        if text is not None:values['Text']=text
        for k,v in values.items():E.SubElement(node,'Property',Name=k,Value=str(v))
        return node
    frame=w(root,'TLBB_MainFrame2','PetSoul_LevelUp_Frame',30,70,740,600)
    w(frame,'TLBB_DragTitle','CysSoul_Title',30,3,660,25,'Thú hồn',DragTarget='PetSoul_LevelUp_Frame',HorzFormatting='HorzCentred')
    close=w(frame,'TLBB_ButtonClose','CysSoul_Close',707,8,14,14);E.SubElement(close,'Event',Name='Clicked',Function='this:Hide()')
    for key,x,text,target in [('Item',20,'Thú hồn','CYS_SOUL_ITEM'),('Material',115,'Hồn ngọc','CYS_SOUL_MATERIAL')]:
        w(frame,'TLBB_ActionButton','CysSoul_'+key,x,46,42,42,Empty='True',DragAcceptName=target,DraggingEnabled='False')
        w(frame,'TLBB_SimpleText','CysSoul_'+key+'Label',x,91,90,22,text,MouseHollow='True')
    w(frame,'TLBB_SimpleText','CysSoul_Help',215,40,500,75,'Kéo Thú hồn và Hồn ngọc từ túi vào ô.\nHuyết mạch / hồi thọ: dùng 1 Hồn ngọc/lượt.\nTẩy thuộc tính: 50000 vàng/giao tử và nguyên liệu.',VertFormatting='TopAligned',MouseHollow='True')
    w(frame,'TLBB_SimpleText','CysSoul_Info',20,120,700,118,'',VertFormatting='TopAligned',MouseHollow='True')
    for name,x,title in [('Current',20,'Thuộc tính hiện tại'),('Pending',375,'Kết quả tẩy chưa nhận')]:
        w(frame,'TLBB_SimpleText','CysSoul_'+name+'Title',x,242,344,22,title,MouseHollow='True')
        w(frame,'TLBB_StaticText','CysSoul_'+name,x,265,344,175,'',VertFormatting='TopAligned',HorzFormatting='WordWrapLeftAligned',FrameEnabled='False',BackgroundEnabled='False')
    for index,label in enumerate(['Nâng cấp','Huyết mạch','Tẩy thuộc tính','Nhận kết quả','Hồi thọ']):
        b=w(frame,'TLBB_ButtonCommon5','CysSoul_Op'+str(index+1),20+index*141,455,134,25,label)
        E.SubElement(b,'Event',Name='Clicked',Function=f'CysPetSoulAction({index+1})')
    w(frame,'TLBB_SimpleText','CysSoul_PetName',20,492,430,22,'',MouseHollow='True')
    for name,x,label,callback in [('Next',450,'Đổi thú','CysSoulNextPet()'),('Wear',545,'Trang bị','CysPetSoulWear(CysSoulPetIndex,0)'),('Remove',640,'Tháo','CysPetSoulWear(CysSoulPetIndex,1)')]:
        b=w(frame,'TLBB_ButtonCommon5','CysSoul_'+name,x,490,86,25,label);E.SubElement(b,'Event',Name='Clicked',Function=callback)
    w(frame,'TLBB_SimpleText','CysSoul_Note',20,535,700,48,'Thu hồi trân thú trước khi trang bị / tháo Thú hồn.\nTẩy xong phải Nhận kết quả; kết quả chưa nhận sẽ mất khi thoát game.',MouseHollow='True')
    return E.tostring(root,encoding='utf-8',xml_declaration=True)
SOUL='''CysSoulPetIndex=-1
function CysSoulNextPet()
 for j=1,30 do
  local i=math.mod(CysSoulPetIndex+j,30)
  local name,id=CysPetSoulPetInfo(i)
  if string.len(name)>0 then CysSoulPetIndex=i;CysSoulRefreshPet();return end
 end
end
function CysSoulRefreshPet()
 local name,id=CysPetSoulPetInfo(CysSoulPetIndex)
 CysSoul_PetName:SetText(string.len(name)>0 and (name..(id>0 and " · Có Thú hồn" or " · Chưa có Thú hồn")) or "Chưa chọn trân thú")
end
function PetSoul_LevelUp_PreLoad()
 this:RegisterEvent("CYS_PETSOUL_UPDATE")
 this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end
function PetSoul_LevelUp_OnLoad() end
function PetSoul_LevelUp_OnEvent(event)
 if event=="HIDE_ON_SCENE_TRANSED" then this:Hide();return end
 if event~="CYS_PETSOUL_UPDATE" then return end
 local slot,material,text,pending,busy=CysPetSoulData()
 if CysSoulPetIndex<0 then CysSoulNextPet() else CysSoulRefreshPet() end
 CysSoul_Item:SetActionItem(-1);CysSoul_Material:SetActionItem(-1)
 if slot>=0 then local a=EnumAction(slot,"packageitem");CysSoul_Item:SetActionItem(a:GetID()) end
 if material>=0 then local a=EnumAction(material,"packageitem");CysSoul_Material:SetActionItem(a:GetID()) end
 local first=string.find(text,"\\n\\n",1,true)
 local marker="\\n\\nKẾT QUẢ TẨY CHƯA NHẬN:\\n"
 local last=string.find(text,marker,1,true)
 CysSoul_Info:SetText(first and string.sub(text,1,first-1) or text)
 CysSoul_Current:SetText(first and string.sub(text,first+2,last and last-1 or -1) or "")
 CysSoul_Pending:SetText(last and string.sub(text,last+string.len(marker)) or "Chưa có kết quả tẩy.")
 for i=1,5 do
  local b=_G["CysSoul_Op"..i]
  if slot>=0 and busy==0 and (i~=4 or pending==1) then b:Enable() else b:Disable() end
 end
 if tonumber(arg0)==1 then this:Show();OpenWindow("Packet") end
end
'''
