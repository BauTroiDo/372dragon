"""CY shop geometry and readable empty shelves; retain every control/event."""
import re,xml.etree.ElementTree as ET

def geometry(text):
 before=ET.fromstring(text); changes={}
 def put(name,**props):changes.setdefault(name,{}).update(props)
 def pos(x,y):return '{{0,%s},{0,%s}}'%(x,y)
 def size(w,h):return '{{0,%s},{0,%s}}'%(w,h)
 put('YuanbaoShop_Frame',UnifiedSize=size(932,600),UnifiedPosition='{{0,12},{0.5,-300}}')
 put('YuanbaoShop_ShopFrame',UnifiedSize='{{0,766},{1,0}}')
 for suffix in ['', '_Bind']:
  put('YuanbaoShop_Bk2'+suffix,UnifiedSize=size(120,288))
  for i in range(1,9):
   put('YuanbaoShop_Button%02d'%i+suffix,UnifiedPosition='{{0.5,-56},{%s,0}}'%(0.04+(i-1)*0.12),UnifiedSize=size(112,24))
 put('YuanbaoShop_Action_Set',UnifiedPosition=pos(124,107),UnifiedSize=size(636,288))
 for i in range(1,19):
  x=((i-1)//6)*212;y=((i-1)%6)*48
  put('YuanbaoShop_Item%d'%i,AbsolutePosition='x:%d y:%d'%(x,y+6))
  put('YuanbaoShop_ItemInfo%d'%i,AbsolutePosition='x:%d y:%d'%(x+35,y),AbsoluteSize='w:174 h:46')
  put('YuanbaoShop_ItemInfo%d_Text'%i,AbsolutePosition='x:4 y:0',AbsoluteSize='w:169 h:23')
  put('YuanbaoShop_ItemInfo%d_GB'%i,AbsolutePosition='x:4 y:23',AbsoluteSize='w:169 h:23')
 # The original bottom group assumes a 25px footer; the two-row footer is 53px.
 # Move the entire history/page group up by that extra 28px, preserving its controls.
 for name in ['YuanbaoShop_Bk','YuanbaoShop_Bk_New']:
  put(name,UnifiedPosition='{{%s},{1,-151}}'%('0,0' if name.endswith('_Bk') else '1,-165'))
 put('YuanbaoShop_LastBuy_Text',AbsoluteSize='w:320 h:22')
 for i in range(1,6):
  x=12+(i-1)*148
  put('YuanbaoShop_LastItem%d'%i,UnifiedPosition=pos(x,56))
  put('YuanbaoShop_LastItemInfo%d'%i,UnifiedPosition=pos(x+34,55),UnifiedSize=size(111,36))
  for suffix in ['Text','GB']:put('YuanbaoShop_LastItemInfo%d_%s'%(i,suffix),AbsoluteSize='w:103 h:18')
 for name,props in changes.items():
  pattern=r'(<Window\b[^>]*\bName="'+re.escape(name)+r'"[^>]*>)(.*?)(?=<Window\b|</Window>)'
  matches=list(re.finditer(pattern,text,re.S));assert len(matches)==1,name
  m=matches[0];block=m[2]
  for prop,value in props.items():
   pat=r'(<Property\b[^>]*\bName="'+prop+r'"[^>]*\bValue=")[^"]*(")'
   block,n=re.subn(pat,lambda m:m[1]+value+m[2],block);assert n==1,(name,prop)
  text=text[:m.start(2)]+block+text[m.end(2):]
 after=ET.fromstring(text)
 assert [(w.get('Name'),w.get('Type')) for w in before.iter('Window')]==[(w.get('Name'),w.get('Type')) for w in after.iter('Window')]
 assert [e.attrib for e in before.iter('Event')]==[e.attrib for e in after.iter('Event')]
 return text
def generate(layout,lua):
 text=geometry(layout.decode('utf8'));script=lua.decode('utf8')
 assert 'CysNbShop_Empty' not in text and 'CysNbShop_UpdatePage' not in script
 anchor='<Window Type="TLBB_DragTitle" Name="YuanbaoShop_DragTitle">'
 assert text.count(anchor)==1
 notice='''<Window Type="DefaultWindow" Name="CysNbShop_Empty">
        <Property Name="AbsolutePosition" Value="x:24 y:205"/>
        <Property Name="AbsoluteSize" Value="w:586 h:70"/>
        <Property Name="MouseHollow" Value="True"/>
        <Property Name="AlwaysOnTop" Value="True"/>
        <Property Name="Visible" Value="False"/>
        <Window Type="TLBB_SimpleText" Name="CysNbShop_EmptyTitle">
          <Property Name="AbsoluteSize" Value="w:586 h:26"/>
          <Property Name="HorzFormatting" Value="HorzCentred"/>
          <Property Name="MouseHollow" Value="True"/>
          <Property Name="Text" Value="Danh mục hiện không có vật phẩm."/>
        </Window>
        <Window Type="TLBB_SimpleText" Name="CysNbShop_EmptyHint">
          <Property Name="AbsolutePosition" Value="x:0 y:30"/>
          <Property Name="AbsoluteSize" Value="w:586 h:26"/>
          <Property Name="HorzFormatting" Value="HorzCentred"/>
          <Property Name="MouseHollow" Value="True"/>
          <Property Name="Text" Value="Các ngoại hình đã có được chọn tại Phòng thay đồ."/>
        </Window>
      </Window>
      '''
 text=text.replace(anchor,notice+anchor)
 script+='''

local CysNbShop_UpdatePage = YuanbaoShop_UpdatePage
function YuanbaoShop_UpdatePage(page)
    CysNbShop_UpdatePage(page)
    if GetActionNum("boothitem") == 0 then
        YuanbaoShop_Action_Set:Hide()
        CysNbShop_Empty:Show()
        YuanbaoShop_CurrentlyPage:SetText("0/0")
    else
        YuanbaoShop_Action_Set:Show()
        CysNbShop_Empty:Hide()
    end
end
'''
 return text.encode('utf8'),script.encode('utf8')
