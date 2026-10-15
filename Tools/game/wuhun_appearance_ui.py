"""A compact GL soul catalog inside the existing CY Wuhun window and artwork."""
import xml.etree.ElementTree as E
from equipcraft_ui import window
from power_ui import prop

def layout(raw):
 r=E.fromstring(raw);frame=next(w for w in r.iter('Window') if w.get('Name')=='Wuhun_Frame_Client')
 model=next(w for w in r.iter('Window') if w.get('Name')=='Wuhun_FakeObject_Frame')
 b=window(model,'TLBB_ButtonCommon5','CysHuan_Open',150,130,115,25,'Huyễn hóa')
 E.SubElement(b,'Event',Name='Clicked',Function='CysHuanOpen()')
 right=window(frame,'DefaultWindow','CysHuan_Original',418,0,310,340)
 for w in list(frame):
  if w.get('Name') in ['Wuhun_Head','Wuhun_Bk3','Wuhun_Bk1','Wuhun_Name','Wuhun_Exp','Wuhun_Life']+[f'Wuhun_Skill{i}' for i in range(1,5)]:
   frame.remove(w);right.append(w)
   if w.get('Name')=='Wuhun_Head':prop(w,'UnifiedPosition','{{0,62},{0,0}}')
   if w.get('Name')=='Wuhun_Bk3':prop(w,'UnifiedPosition','{{0,0},{0,62}}')
 panel=window(frame,'TLBB_StaticText','CysHuan_Panel',418,0,310,340,'',BackgroundEnabled='True',FrameEnabled='True',Visible='False',MouseHollow='False')
 content=window(panel,'DefaultWindow','CysHuan_Content',0,0,310,340)
 confirm=window(panel,'DefaultWindow','CysHuan_Confirm',0,0,310,340,Visible='False')
 window(confirm,'TLBB_StaticText','CysHuan_ConfirmText',8,35,294,190,'',BackgroundEnabled='False',FrameEnabled='False',HorzFormatting='WordWrapLeftAligned',VertFormatting='TopAligned')
 for n,label,x,ret in [('Yes','Xác nhận',8,'Yes'),('No','Hủy',158,'No')]:
  b=window(confirm,'TLBB_ButtonCommon5','CysHuan_'+n,x,249,144,25,label);E.SubElement(b,'Event',Name='Clicked',Function=f'CysHuanConfirm("{ret}")')
 panel=content
 window(panel,'TLBB_SimpleText','CysHuan_State',8,7,294,25,'',TextColor='FFFFF263')
 for i in range(1,7):
  b=window(panel,'TLBB_ButtonCommon5','CysHuan_Item'+str(i),8,28+(i-1)*23,294,22,'')
  E.SubElement(b,'Event',Name='Clicked',Function=f'CysHuanSelect({i})')
 window(panel,'TLBB_StaticText','CysHuan_Info',8,168,294,72,'',BackgroundEnabled='False',FrameEnabled='False',HorzFormatting='WordWrapLeftAligned',VertFormatting='TopAligned')
 for n,label,x,y,w,call in [('Activate','Kích hoạt',8,240,144,'CysHuanPay(1)'),('Upgrade','Nâng cấp',158,240,144,'CysHuanPay(2)'),('Qian','Gắn Càn',8,265,144,'CysHuanSlot(0)'),('Kun','Gắn Khôn',158,265,144,'CysHuanSlot(1)'),('Switch','Đổi Càn / Khôn',8,290,294,'CysHuanSwitch()'),('Close','Về thuộc tính Võ hồn',8,315,294,'CysHuanClose()')]:
  b=window(panel,'TLBB_ButtonCommon5','CysHuan_'+n,x,y,w,23,label);E.SubElement(b,'Event',Name='Clicked',Function=call)
 return E.tostring(r,encoding='utf-8',xml_declaration=True)

LUA='''
-- CYS-WUHUN-APPEARANCE: original GL costs and Càn/Khôn operations in CY skins.
local CysHuanSelected=1
local CysHuanPending=nil
function CysHuanUpdate()
 local name,lv,grade,q,k,yy,show,ready,gold,a,b,count=CysWuhunData(CysHuanSelected)
 if name==nil then return end
 for i=1,6 do local n,l=CysWuhunData(i);_G["CysHuan_Item"..i]:SetText((i==CysHuanSelected and "> " or "")..n) end
 local active=yy==1 and "Khôn" or "Càn"
 CysHuan_State:SetText("Ngoại hình đang dùng: "..active)
 local desc=(lv==0 and "Chưa kích hoạt" or "Cấp "..lv.." · Tiến độ "..grade.."/10")
 if gold<0 then desc=desc.."\\nĐã đạt cấp tối đa."
 else
  local mat=DataPool:Lua_GetItemNameByIndex(a) or tostring(a)
  desc=desc.."\\nPhí: "..gold.." vàng/giao tử\\nCần "..count.." "..mat
 end
 CysHuan_Info:SetText(desc)
 CysHuan_Activate:Disable();CysHuan_Upgrade:Disable();CysHuan_Qian:Disable();CysHuan_Kun:Disable();CysHuan_Switch:Disable()
 if ready==1 then
  if lv==0 then CysHuan_Activate:Enable() else
   if gold>=0 then CysHuan_Upgrade:Enable() end
   CysHuan_Qian:Enable();CysHuan_Kun:Enable()
  end
  if q>0 or k>0 then CysHuan_Switch:Enable() end
 end
 CysHuan_Upgrade:SetText(grade==10 and "Đột phá" or "Nâng cấp")
 CysHuan_Qian:SetText(q==CysHuanSelected and "Tháo khỏi Càn" or "Gắn Càn")
 CysHuan_Kun:SetText(k==CysHuanSelected and "Tháo khỏi Khôn" or "Gắn Khôn")
end
function CysHuanOpen() CysHuan_Original:Hide();CysHuan_Content:Show();CysHuan_Confirm:Hide();CysHuan_Panel:Show();CysWuhunRefresh();CysHuanUpdate() end
function CysHuanClose() CysHuan_Panel:Hide();CysHuan_Original:Show();CysHuanPending=nil end
function CysHuanSelect(id) CysHuanSelected=id;CysHuanUpdate() end
function CysHuanSlot(side)
 local n,l,g,q,k=CysWuhunData(CysHuanSelected)
 local current=side==0 and q or k
 CysWuhunAction(current==CysHuanSelected and 4 or 3,CysHuanSelected,side);CysHuanUpdate()
end
function CysHuanSwitch()
 local n,l,g,q,k,yy=CysWuhunData(CysHuanSelected)
 CysWuhunAction(5,CysHuanSelected,yy==1 and 0 or 1);CysHuanUpdate()
end
function CysHuanPay(op)
 local n,l,g,q,k,yy,show,ready,gold,a,b,count=CysWuhunData(CysHuanSelected)
 if ready~=1 or gold<0 then return end
 CysHuanPending={op=op,id=CysHuanSelected}
 CysHuan_ConfirmText:SetText((op==1 and "Kích hoạt " or "Nâng ")..n.."?\\n\\nTiêu "..gold.." vàng/giao tử\\nvà "..count.." "..(DataPool:Lua_GetItemNameByIndex(a) or tostring(a)).." (hoặc bản khóa).")
 CysHuan_Content:Hide();CysHuan_Confirm:Show()
end
function CysHuanConfirm(ret)
 local p=CysHuanPending;CysHuanPending=nil
 CysHuan_Confirm:Hide();CysHuan_Content:Show()
 if ret=="Yes" and p then CysWuhunAction(p.op,p.id,0);CysHuanUpdate() end
end
local CysHuanPreLoad=Wuhun_PreLoad
function Wuhun_PreLoad() CysHuanPreLoad();this:RegisterEvent("CYS_WUHUN_APPEARANCE") end
local CysHuanEvent=Wuhun_OnEvent
function Wuhun_OnEvent(event)
 if event=="CYS_WUHUN_APPEARANCE" then
  if this:IsVisible() then Wuhun_Update();CysHuanUpdate() end
  return
 end
 CysHuanEvent(event)
 if event=="TOGGLE_WUHUN_PAGE" and this:IsVisible() then CysWuhunRefresh() end
end
'''
def lua(raw):
 marker=b'-- CYS-WUHUN-APPEARANCE:'
 if marker in raw:raw=raw[:raw.index(marker)]
 return raw.rstrip()+b'\n'+LUA.encode('utf8')
