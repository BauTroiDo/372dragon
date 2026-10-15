"""Scoped 16-slot wardrobe overlay: CY art / RTT, fixed visible widget budget."""
from pathlib import Path
import re
import xml.etree.ElementTree as ET
from wardrobe_catalog import build, lua

def generate(canon):
    catalog=build(canon.parents[2])
    doc=ET.Element('GUILayout')
    def prop(w,k,v): ET.SubElement(w,'Property',Name=k,Value=str(v))
    def event(w,k,v): ET.SubElement(w,'Event',Name=k,Function=v)
    def win(parent,type,name,x,y,w,h,text=None,click=None):
        e=ET.SubElement(parent,'Window',Type=type,Name=name)
        prop(e,'UnifiedPosition','{{0,%s},{0,%s}}'%(x,y)); prop(e,'UnifiedSize','{{0,%s},{0,%s}}'%(w,h))
        if text is not None: prop(e,'Text',text)
        if click: event(e,'Clicked',click)
        return e
    root=win(doc,'TLBB_MainFrameNULL','NewExterior_DressBox_Frame',0,0,1024,680)
    prop(root,'UnifiedPosition','{{0.5,-512},{0.5,-340}}')
    event(root,'Hidden','NewExterior_DressBox_OnHidden();')
    bg=win(root,'TLBB_StaticImageNULL','CysWard_Background',0,0,1024,680)
    prop(bg,'Image','set:NewExterior5 image:RenWu_BK'); prop(bg,'MouseHollow','True')
    title=win(root,'TLBB_DragTitle','NewExterior_DressBox_DragTitle',0,0,975,40)
    prop(title,'DragTarget','NewExterior_DressBox_Frame')
    win(root,'TLBB_ButtonClose','NewExterior_DressBox_Close',984,10,24,24,click='NewExterior_DressBox_CloseClick();')
    def label(name,x,y,w,h,text=''):
        e=win(root,'TLBB_SimpleText','CysWard_'+name,x,y,w,h,text)
        prop(e,'MouseHollow','True'); return e
    def button(name,x,y,w,h,text,click):
        return win(root,'TLBB_ButtonCommon2','CysWard_'+name,x,y,w,h,text,click)
    label('Title',24,9,440,28,'#cF9D687PHÒNG THAY ĐỒ')
    label('Subtitle',156,51,315,25,'Xem trước ngoại hình của bạn')
    for position,i in enumerate([1,2,3,4,5,6,7,9,8]):
        button('Tab'+str(i),18,71+position*55,122,42,catalog['labels'][i-1],'CysWard_Category(%d);'%i)
    mesh=win(root,'TLBB_MeshWindowXWG','NewExterior_DressBox_FakeObject',146,80,355,505)
    prop(mesh,'BackgroundName','Common/NewOrnamensObj.dds'); prop(mesh,'MouseHollow','True')
    portrait=win(root,'TLBB_StaticImageNULL','CysWard_Portrait',218,190,220,220)
    prop(portrait,'MouseHollow','True'); prop(portrait,'Visible','False')
    for name,x,direction in [('Left',232,-1),('Right',362,1)]:
        b=button(name,x,565,45,30,'<' if direction<0 else '> ',None)
        event(b,'MouseButtonDown','CysWard_Rotate(%d);'%direction)
        event(b,'MouseButtonUp','CysWard_Rotate(0);'); event(b,'CaptureLost','CysWard_Rotate(0);')
    button('Reset',202,611,240,30,'Khôi phục xem trước','CysWard_DoReset();')
    for i in range(1,4):
        a=button('Action'+str(i),151+(i-1)*114,597,109,28,'Động tác '+str(i),'CysWard_PlayAction(%d);'%i)
        prop(a,'Visible','False')
    ride=button('Ride',202,650,240,26,'Lên / xuống thú','CysWard_DoRide();')
    prop(ride,'Visible','False')
    panel=win(root,'DefaultWindow','CysWard_Position',151,447,344,146)
    prop(panel,'Visible','False')
    for index,(axis,title) in enumerate([('X','Trái / phải'),('Y','Lên / xuống'),('Z','Xa / gần')]):
        y=index*33
        labelwin=win(panel,'TLBB_SimpleText','CysWard_PosLabel'+axis,0,y,150,27,title)
        prop(labelwin,'MouseHollow','True')
        win(panel,'TLBB_ButtonCommon2','CysWard_Pos'+axis+'Minus',151,y,34,27,'−','CysWard_Adjust(%d,-1);'%(index+1))
        value=win(panel,'TLBB_SimpleText','CysWard_Pos'+axis,191,y,62,27,'128')
        prop(value,'MouseHollow','True')
        win(panel,'TLBB_ButtonCommon2','CysWard_Pos'+axis+'Plus',260,y,34,27,'+','CysWard_Adjust(%d,1);'%(index+1))
    win(panel,'TLBB_ButtonCommon2','CysWard_PosDefault',0,106,140,29,'Về mặc định','CysWard_DefaultPosition();')
    win(panel,'TLBB_ButtonCommon2','CysWard_PosSave',151,106,143,29,'Lưu vị trí','CysWard_SavePosition();')
    variants=win(root,'DefaultWindow','CysWard_Variants',151,447,344,145)
    prop(variants,'Visible','False')
    for row,(kind,title) in enumerate([('Level','Cấp độ'),('Color','Màu sắc')]):
        y=row*65
        titlewin=win(variants,'TLBB_SimpleText','CysWard_'+kind+'Title',0,y,330,24,title)
        prop(titlewin,'MouseHollow','True')
        win(variants,'TLBB_ButtonCommon2','CysWard_'+kind+'Prev',0,y+26,32,28,'<',"CysWard_Variant('%s',-1);"%kind)
        value=win(variants,'TLBB_SimpleText','CysWard_'+kind+'Value',40,y+26,250,35)
        prop(value,'MouseHollow','True')
        win(variants,'TLBB_ButtonCommon2','CysWard_'+kind+'Next',302,y+26,32,28,'>',"CysWard_Variant('%s',1);"%kind)
    label('Count',510,51,482,27)
    search=win(root,'TLBB_EditBoxNormal','CysWard_Search',512,85,260,28)
    prop(search,'MaxTextLength',80)
    button('Find',780,85,65,28,'Tìm','CysWard_DoSearch();')
    button('Filter',853,85,140,28,'Tất cả','CysWard_DoFilter();')
    for i in range(1,17):
        x=510+((i-1)%4)*123; y=125+((i-1)//4)*97
        b=win(root,'TLBB_ButtonCommon2','CysWard_Item'+str(i),x,y,118,92,click='CysWard_Select(%d);'%i)
        # Each cell has an explicit skin background and its own selection frame.
        frame=win(b,'TLBB_StaticImageNULL','CysWard_Select'+str(i),0,0,118,92)
        prop(frame,'Image','set:NewExterior3 image:NewExterior_yeqian_xuanzhong'); prop(frame,'MouseHollow','True'); prop(frame,'Visible','False')
        icon=win(b,'TLBB_StaticImageNULL','CysWard_Icon'+str(i),5,4,32,32)
        prop(icon,'MouseHollow','True')
        n=win(b,'TLBB_SimpleText','CysWard_Name'+str(i),5,37,108,36)
        prop(n,'MouseHollow','True')
        st=win(b,'TLBB_SimpleText','CysWard_State'+str(i),5,72,108,19)
        prop(st,'MouseHollow','True')
    label('Empty',537,272,400,50,'Không có vật phẩm phù hợp. Hãy đổi bộ lọc hoặc từ khóa.')
    button('Prev',515,520,72,28,'Trước','CysWard_DoPage(-1);')
    label('Page',650,520,205,28)
    button('Next',917,520,72,28,'Sau','CysWard_DoPage(1);')
    label('Selected',510,558,482,35)
    label('Status',510,593,482,37)
    button('Sync',510,641,115,28,'Đồng bộ','CysWard_DoSync();')
    remove=button('Remove',631,637,92,32,'Tháo','CysWard_DoRemove();')
    prop(remove,'Visible','False')
    button('Own',729,637,126,32,'Sở hữu','CysWard_Operation(1);')
    button('Wear',865,637,126,32,'Mặc','CysWard_Operation(2);')
    ET.indent(doc,space='  ')
    layout=ET.tostring(doc,encoding='utf-8',xml_declaration=True)
    controller='local WARD_CATALOG = '+lua(catalog['families'])+'\n'+Path(__file__).with_suffix('.lua').read_text(encoding='utf-8')
    # The engine injects widgets into the same frame environment as functions.
    # A matching callback name overwrites the widget and fails only at runtime.
    widgets={w.attrib['Name'] for w in doc.iter('Window')}
    functions=set(re.findall(r'^function\s+(\w+)\s*\(',controller,re.M))
    if widgets & functions:
        raise ValueError('Lua callback shadows UI widget: '+', '.join(sorted(widgets & functions)))
    return layout,controller.encode('utf-8'),{str(k):len(v) for k,v in catalog['categories'].items()}
