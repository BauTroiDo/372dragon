"""Keep CY skins and the original 120-slot temporary-bag contract."""
import xml.etree.ElementTree as E
def layout():
    root=E.Element('GUILayout')
    def w(parent,kind,name,x,y,width,height,text=None,**props):
        node=E.SubElement(parent,'Window',Type=kind,Name=name)
        values={'AbsolutePosition':f'x:{x} y:{y}','AbsoluteSize':f'w:{width} h:{height}',**props}
        if text is not None:values['Text']=text
        for k,v in values.items():E.SubElement(node,'Property',Name=k,Value=str(v))
        return node
    def event(n,k,v):E.SubElement(n,'Event',Name=k,Function=v)
    frame=w(root,'TLBB_MainFrame2','Packet_Temporary_Frame',12,120,370,500)
    title=w(frame,'TLBB_DragTitle','Packet_Temporary_Title',30,3,305,25,'Thiên cơ cẩm nang',DragTarget='Packet_Temporary_Frame',Font='YouYuan11.25',HorzFormatting='HorzCentred')
    close=w(frame,'TLBB_ButtonClose','Packet_Temporary_Close',336,8,14,14);event(close,'Clicked','this:Hide();')
    for i in range(120):
        button=w(frame,'TLBB_ActionButton',f'TemBank_Item{i}',15+(i%10)*34,36+(i//10)*34,34,34,DragAcceptName=f'CYSTEMP{i}',DraggingEnabled='False',Empty='True')
        event(button,'MouseRClick',f'CysTemBank_Take({i});')
    w(frame,'TLBB_SimpleText','TemBank_Help',15,446,340,22,'Kéo đồ vào để cất; chuột phải để rút.',HorzFormatting='HorzCentred',MouseHollow='True')
    count=w(frame,'TLBB_SimpleText','TemBank_Count',15,470,95,20,'0 / 120',MouseHollow='True')
    for name,x,width,text,call in [('TakeAll',128,120,'Rút tất cả','Bank:MoveAllTemBankItemToPacket()'),('Sort',260,95,'Sắp xếp','Bank:TemBankPackUp()')]:
        button=w(frame,'TLBB_ButtonCommon5','TemBank_'+name,x,470,width,20,text);event(button,'Clicked',call)
    return E.tostring(root,encoding='utf-8',xml_declaration=True)
LUA='''function Packet_Temporary_PreLoad()
 this:RegisterEvent("UI_COMMAND",true)
 this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end
function Packet_Temporary_OnLoad() end
function Packet_Temporary_OnEvent(event)
 if event=="HIDE_ON_SCENE_TRANSED" then this:Hide();return end
 if event~="UI_COMMAND" or tonumber(arg0)~=990025 then return end
 local kind=Get_XParam_INT(0)
 CysTemBank_Sync(kind,Get_XParam_INT(1))
 for i=0,119 do
  local a,locked=Bank:EnumTemItem(i)
  local b=_G["TemBank_Item"..i]
  b:SetActionItem(a:GetID()>0 and a:GetID() or -1)
  if locked or kind==0 then b:Disable() else b:Enable() end
 end
 if kind==1 then
  TemBank_Count:SetText(Bank:GetTemBankItemNum().." / 120")
  this:Show()
 end
end
'''
