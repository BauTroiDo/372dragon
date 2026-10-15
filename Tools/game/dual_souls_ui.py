"""CY artwork, real equipment/skill actions, and a second character attachment."""
import copy,json,shutil,xml.etree.ElementTree as E
from pathlib import Path
from equipcraft_ui import window
from power_ui import prop

def baseline(relative):
 root=Path(__file__).resolve().parents[2];log=root/'Build/Logs/2026-09-25-dual-souls'
 saved=log/'ui-baseline'/relative
 if not saved.exists():
  report=log/'release-report.json'
  source=(Path(json.loads(report.read_text())['backup']) if report.exists() else root/'Build/world-gui/stage-play-21')/relative
  saved.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,saved)
 return saved.read_bytes()

def layout():
 r=E.Element('GUILayout');f=window(r,'TLBB_MainFrame2','CysDualSouls_Frame',35,80,590,450)
 window(f,'TLBB_DragTitle','CysDual_Title',25,3,535,26,'Võ hồn · Chiến hồn',DragTarget='CysDualSouls_Frame',HorzFormatting='HorzCentred')
 w=window(f,'TLBB_ButtonClose','CysDual_Close',558,8,14,14);E.SubElement(w,'Event',Name='Clicked',Function='this:Hide()')
 for role,x,title,label,point in [('Support',22,'Võ hồn · Huyền Giáp','Buff · Bị động · Phòng thủ',18),('Assault',304,'Chiến hồn · Xích Diệm','Chủ động · Sát thương',39)]:
  window(f,'TLBB_SimpleText','CysDual_Title'+role,x,42,265,25,title,TextColor='FFFFF263')
  w=window(f,'TLBB_ActionButton','CysDual_Item'+role,x,77,44,44,Empty='True',DragAcceptName='CYS_DUAL_'+role.upper(),DraggingEnabled='False')
  window(f,'TLBB_StaticText','CysDual_Name'+role,x+52,73,215,53,'Chưa trang bị',BackgroundEnabled='False',FrameEnabled='False',HorzFormatting='WordWrapLeftAligned',VertFormatting='TopAligned')
  window(f,'TLBB_SimpleText','CysDual_Label'+role,x,132,265,23,label,TextColor='FFBBE8FF')
  for n in range(2):
   k=n+(1 if point==18 else 3)
   w=window(f,'TLBB_ActionButton','CysDual_Skill'+str(k),x,166+n*57,40,40,Empty='True',DraggingEnabled='True')
   window(f,'TLBB_StaticText','CysDual_SkillName'+str(k),x+48,164+n*57,215,52,'',BackgroundEnabled='False',FrameEnabled='False',HorzFormatting='WordWrapLeftAligned',VertFormatting='TopAligned')
  b=window(f,'TLBB_ButtonCommon5','CysDual_Unwear'+role,x,289,130,25,'Tháo hồn');E.SubElement(b,'Event',Name='Clicked',Function=f'CysDualSoulsAction({point})')
 b=window(f,'TLBB_ButtonCommon5','CysDual_Visible',438,289,131,25,'Ẩn Chiến hồn');E.SubElement(b,'Event',Name='Clicked',Function='CysDualSoulsAction(1)')
 b=window(f,'TLBB_ButtonCommon5','CysDual_SupportVisible',156,289,131,25,'Ẩn/hiện Võ hồn');E.SubElement(b,'Event',Name='Clicked',Function='SystemSetup:SetShowWuhunObj(SystemSetup:GetShowWuhunObj()==1 and 0 or 1)')
 window(f,'TLBB_StaticText','CysDual_Help',22,332,548,92,'Kéo hồn từ túi vào ô tương ứng. Kéo chiêu chủ động xuống thanh F hoặc Alt+số để dùng.\nĐổi hồn sau khi rời giao tranh 10 giây. Hồi chiêu được giữ khi tháo hồn và đăng nhập lại.',BackgroundEnabled='False',FrameEnabled='True',HorzFormatting='WordWrapLeftAligned',VertFormatting='TopAligned')
 return E.tostring(r,encoding='utf-8',xml_declaration=True)

LUA='''
function CysDualSouls_PreLoad()
 this:RegisterEvent("CYS_DUAL_SOULS")
 this:RegisterEvent("REFRESH_EQUIP")
 this:RegisterEvent("PACKAGE_ITEM_CHANGED")
 this:RegisterEvent("SKILL_UPDATE")
 this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end
function CysDualSouls_OnLoad() end
function CysDualRefresh()
 local support,assault,shown=CysDualSoulsData()
 local roles={"Support","Assault"};local points={18,39};local items={support,assault}
 for i=1,2 do
  local slot=_G["CysDual_Item"..roles[i]];slot:SetActionItem(-1)
  if items[i]>0 then local a=EnumAction(points[i],"equip");if a then slot:SetActionItem(a:GetID()) end end
  _G["CysDual_Name"..roles[i]]:SetText(items[i]>0 and DataPool:Lua_GetItemNameByIndex(items[i]) or "Chưa trang bị")
 end
 CysDual_Visible:SetText(shown==1 and "Ẩn Chiến hồn" or "Hiện Chiến hồn")
 local names={"Huyền Giáp Hộ Thể\\nBị động: thủ giáp +5%","Cường Thể Hộ Hồn\\nBuff bản thân · 180 giây","Xích Diệm Trọng Kích\\nĐơn mục tiêu · 60 giây","Xích Diệm Bát Phương\\nDiện rộng · 90 giây"}
 for k=1,4 do _G["CysDual_Skill"..k]:SetActionItem(-1);_G["CysDual_SkillName"..k]:SetText(names[k]) end
 for i=0,GetActionNum("skill")-1 do
  local a=EnumAction(i,"skill");local id=a:GetDefineID()
  if id>=6100 and id<=6103 then _G["CysDual_Skill"..(id-6099)]:SetActionItem(a:GetID()) end
 end
 CysDual_Skill1:SetProperty("DraggingEnabled","False")
end
function CysDualSouls_OnEvent(event)
 if event=="HIDE_ON_SCENE_TRANSED" then this:Hide();return end
 if event=="CYS_DUAL_SOULS" and tonumber(arg0)==1 then this:Show();OpenWindow("Packet") end
 CysDualRefresh()
end
'''

def wuhun(raw):
 r=E.fromstring(raw);f=next(w for w in r.iter('Window') if w.get('Name')=='Wuhun_FakeObject_Frame')
 b=window(f,'TLBB_ButtonCommon5','CysDual_Open',272,130,115,25,'Song hồn');E.SubElement(b,'Event',Name='Clicked',Function='CysDualSoulsOpen()')
 return E.tostring(r,encoding='utf-8',xml_declaration=True)

def selfequip(raw):
 r=E.fromstring(raw)
 # Use the same parent as the established Wuhun slot; preserve all old positions.
 template=next(w for w in r.iter('Window') if w.get('Name')=='SelfEquip_1')
 parent=next(p for p in r.iter('Window') if template in list(p))
 w=copy.deepcopy(template);w.set('Name','CysDual_SelfEquip')
 for child in list(w):
  if child.tag in ('Event','Window'):w.remove(child)
 prop(w,'UnifiedPosition','{{0,285},{0,347}}');prop(w,'UnifiedSize','{{0,34},{0,34}}')
 prop(w,'DragAcceptName','CYS_DUAL_ASSAULT');prop(w,'DraggingEnabled','False')
 prop(w,'Tooltip','Chiến hồn: kéo từ túi vào ô. Mở Song hồn để xem kỹ năng.')
 E.SubElement(w,'Event',Name='Clicked',Function='CysDualSoulsOpen()')
 parent.append(w)
 w=copy.deepcopy(w);w.set('Name','CysDual_SelfSupport');prop(w,'UnifiedPosition','{{0,45},{0,347}}');prop(w,'DragAcceptName','CYS_DUAL_SUPPORT');prop(w,'Tooltip','Võ hồn: buff, bị động và phòng thủ.');parent.append(w)
 return E.tostring(r,encoding='utf-8',xml_declaration=True)

SELF_LUA='''
local CysDualSelfPre=SelfEquip_PreLoad
function SelfEquip_PreLoad() CysDualSelfPre();this:RegisterEvent("CYS_DUAL_SOULS") end
local CysDualSelfEvent=SelfEquip_OnEvent
function SelfEquip_OnEvent(event)
 CysDualSelfEvent(event)
 CysDual_SelfEquip:SetActionItem(-1)
 local s,a=CysDualSoulsData()
 if a>0 then local action=EnumAction(39,"equip");if action then CysDual_SelfEquip:SetActionItem(action:GetID()) end end
 CysDual_SelfSupport:SetActionItem(-1)
 if s>0 then local action=EnumAction(18,"equip");if action then CysDual_SelfSupport:SetActionItem(action:GetID()) end end
end
'''

def inspect(raw):
 r=E.fromstring(raw);original=next(w for w in r.iter('Window') if w.get('Name')=='TargetEquip_Equip1')
 parent=next(p for p in r.iter('Window') if original in list(p))
 for name,x in [('Support',45),('Assault',285)]:
  w=copy.deepcopy(original);w.set('Name','CysDual_Inspect'+name)
  for child in list(w):
   if child.tag in ('Event','Window'):w.remove(child)
  prop(w,'UnifiedPosition',f'{{{{0,{x}}},{{0,347}}}}');prop(w,'UnifiedSize','{{0,34},{0,34}}')
  prop(w,'DraggingEnabled','False');prop(w,'DragAcceptName','');parent.append(w)
 return E.tostring(r,encoding='utf-8',xml_declaration=True)

INSPECT_LUA='''
local CysDualInspectEvent=TargetEquip_OnEvent
function TargetEquip_OnEvent(event)
 CysDualInspectEvent(event)
 CysDual_InspectSupport:SetActionItem(-1);CysDual_InspectAssault:SetActionItem(-1)
 local a=EnumAction(18,"targetequip");if a then CysDual_InspectSupport:SetActionItem(a:GetID()) end
 a=EnumAction(39,"targetequip");if a then CysDual_InspectAssault:SetActionItem(a:GetID()) end
end
'''

def actors(raw):
 r=E.fromstring(raw.decode('gbk'))
 count=0
 for obj in r:
  attr=next(e for e in obj.iter('Attribute') if e.get('name')=='KFSObj')
  parent=next(p for p in obj.iter() if attr in list(p))
  a=copy.deepcopy(attr);a.set('name','BattleSoulObj');parent.append(a)
  loc=next(e for e in obj.iter('Locator') if any(s.get('name')=='KFSObj' for s in e.findall('Slot')))
  # Bip01 bind rotation maps local (x,y,z) to actor (y,z,x).
  # Its local Y is the lateral axis; mirroring X only changes depth.
  b=copy.deepcopy(loc);b.set('name','CysBattleSoulLocator');b.set('y','40');b.set('z','35')
  b.find('Slot').set('name','BattleSoulObj')
  parent=next(p for p in obj.iter() if loc in list(p));parent.append(b);count+=1
 assert count==4
 return E.tostring(r,encoding='unicode').encode('gbk')
