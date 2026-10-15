"""CY equipment workshop, using existing TLBB window/slot/button artwork."""
import xml.etree.ElementTree as E
from power_ui import prop

def window(parent,kind,name,x,y,width,height,text=None,**props):
    w=E.SubElement(parent,'Window',Type=kind,Name=name)
    props={'AbsolutePosition':f'x:{x} y:{y}','AbsoluteSize':f'w:{width} h:{height}',**props}
    if text is not None:props['Text']=text
    for k,v in props.items():prop(w,k,str(v))
    return w

def layout():
    root=E.Element('GUILayout');frame=window(root,'TLBB_MainFrame2','CysEquipCraft_Frame',25,100,620,490)
    window(frame,'TLBB_DragTitle','CysCraft_Title',30,3,550,25,'Thăng Linh · Điêu văn',DragTarget='CysEquipCraft_Frame',HorzFormatting='HorzCentred')
    w=window(frame,'TLBB_ButtonClose','CysCraft_Close',586,8,14,14);E.SubElement(w,'Event',Name='Clicked',Function='this:Hide()')
    labels=['Thăng Linh','Khắc','Nâng cấp','Tháo','Hợp thành','Chuyển']
    for i,name in enumerate(labels,1):
        w=window(frame,'TLBB_ButtonCommon5','CysCraft_Mode'+str(i),16+(i-1)*98,39,94,26,name)
        E.SubElement(w,'Event',Name='Clicked',Function=f'CysEquipCraftMode({i})')
    for n,key,x,label in [(1,'ITEM',24,'Trang bị'),(2,'MATERIAL',126,'Nguyên liệu'),(3,'TARGET',228,'Đích')]:
        w=window(frame,'TLBB_ActionButton','CysCraft_Slot'+str(n),x,90,42,42,Empty='True',DragAcceptName='CYS_CRAFT_'+key,DraggingEnabled='False')
        E.SubElement(w,'Event',Name='Clicked',Function=f'CysEquipCraftClear({n})')
        window(frame,'TLBB_SimpleText','CysCraft_Label'+str(n),x-6,136,100,22,label,MouseHollow='True')
    window(frame,'TLBB_StaticText','CysCraft_Help',330,82,266,90,'Kéo vật phẩm từ túi vào ô.\nBấm ô để bỏ chọn.\nPhí và kết quả hiển thị bên dưới.',FrameEnabled='False',BackgroundEnabled='False',HorzFormatting='WordWrapLeftAligned',VertFormatting='TopAligned',MouseHollow='True')
    window(frame,'TLBB_StaticText','CysCraft_Info',24,177,572,238,'',HorzFormatting='WordWrapLeftAligned',VertFormatting='TopAligned',BackgroundEnabled='False',FrameEnabled='True')
    b=window(frame,'TLBB_ButtonCommon5','CysCraft_Refresh',24,438,140,27,'Kiểm tra lại');E.SubElement(b,'Event',Name='Clicked',Function='CysEquipCraftRefresh()')
    b=window(frame,'TLBB_ButtonCommon5','CysCraft_OK',405,438,188,27,'Thực hiện');E.SubElement(b,'Event',Name='Clicked',Function='CysCraftExecute()')
    return E.tostring(root,encoding='utf-8',xml_declaration=True)

def packet_layout(raw):
    root=E.fromstring(raw)
    main=next(w for w in root.iter('Window') if w.get('Name')=='Packet_MainFrame')
    if not any(w.get('Name')=='CysCraft_Open' for w in root.iter('Window')):
        w=window(main,'TLBB_ButtonCommon5','CysCraft_Open',247,53,81,23,'Chế tác')
        prop(w,'UnifiedPosition','{{1,-135},{0,53}}')
        E.SubElement(w,'Event',Name='Clicked',Function='CysEquipCraftOpen(1)')
    return E.tostring(root,encoding='utf-8',xml_declaration=True)

LUA='''function CysEquipCraft_PreLoad()
 this:RegisterEvent("CYS_EQUIPCRAFT_UPDATE")
 this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end
function CysEquipCraft_OnLoad() end
function CysCraftExecute()
 CysCraft_OK:Disable();CysEquipCraftAction()
end
function CysEquipCraft_OnEvent(event)
 if event=="HIDE_ON_SCENE_TRANSED" then this:Hide();return end
 if event~="CYS_EQUIPCRAFT_UPDATE" then return end
 local mode,a,b,c,text,enabled=CysEquipCraftData()
 local slots={a,b,c}
 for i=1,3 do
  local w=_G["CysCraft_Slot"..i];w:SetActionItem(-1)
  if slots[i]>=0 then local action=EnumAction(slots[i],"packageitem");if action then w:SetActionItem(action:GetID()) end end
 end
 for i=1,6 do local w=_G["CysCraft_Mode"..i];if i==mode then w:Disable() else w:Enable() end end
 CysCraft_Info:SetText(text)
 local labels={"Thăng Linh","Khắc điêu văn","Nâng 1 cấp","Tháo điêu văn","Hợp thành","Chuyển điêu văn"}
 CysCraft_OK:SetText(mode==1 and string.find(text,"Tiến bậc:",1,true) and "Tiến bậc" or labels[mode])
 CysCraft_Label2:SetText(mode==5 and "Đồ phổ" or "Điêu văn")
 if mode==2 or mode==5 then CysCraft_Slot2:Show();CysCraft_Label2:Show() else CysCraft_Slot2:Hide();CysCraft_Label2:Hide() end
 if mode==6 then CysCraft_Slot3:Show();CysCraft_Label3:Show() else CysCraft_Slot3:Hide();CysCraft_Label3:Hide() end
 if mode==5 then CysCraft_Slot1:Hide();CysCraft_Label1:Hide() else CysCraft_Slot1:Show();CysCraft_Label1:Show() end
 if enabled==1 then CysCraft_OK:Enable() else CysCraft_OK:Disable() end
 if tonumber(arg0)==1 then this:Show();OpenWindow("Packet") end
end
'''
