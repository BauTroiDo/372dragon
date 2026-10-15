"""Arrange existing CY manager controls for Vietnamese text; keep callbacks/skin."""
import xml.etree.ElementTree as E
def layout(raw):
    root=E.fromstring(raw);nodes={w.get('Name'):w for w in root.iter('Window')}
    nodes['PS_ShopMag_Shopkeeper_Name'].set('Type','TLBB_SimpleText')
    def prop(key,name,value):
        w=nodes['PS_ShopMag_'+key];p=w.find("Property[@Name='"+name+"']")
        if p is None:p=E.SubElement(w,'Property',Name=name)
        p.set('Value',value)
    def rect(key,x,y,w,h):
        n=nodes['PS_ShopMag_'+key]
        for p in list(n.findall('Property')):
            if p.get('Name') in ('UnifiedPosition','UnifiedSize','AbsolutePosition','AbsoluteSize','UnifiedAreaRect'):n.remove(p)
        prop(key,'AbsolutePosition',f'x:{x} y:{y}');prop(key,'AbsoluteSize',f'w:{w} h:{h}')
    prop('Frame','UnifiedSize','{{0,740},{0,460}}')
    prop('Frame','UnifiedPosition','{{0.5,-370},{0.5,-230}}')
    rect('Function_Frame',10,32,720,382)
    rect('Client_Line1',0,0,720,28);rect('Client_Line2',0,28,720,28)
    for key,y in [('Shopkeeper_Name',0),('Shopkeeper_ID',0)]:rect(key,4,y,208,26)
    for key in ['ShopCorpus_Text','ShopProfit_Text']:rect(key,215,1,84,24)
    for key in ['ShopCorpus','ShopProfit']:rect(key,305,3,118,23)
    rect('ImmitCorpus',427,2,86,24);rect('Immit',427,2,86,24);rect('DrawMoney',518,2,94,24)
    rect('CommerceExponential',520,1,195,25)
    rect('DPID',0,59,150,24);rect('Function_Frame2',155,59,205,24);rect('Stall_State',0,0,203,24)
    rect('PetList',0,87,360,156);rect('Item_Frame',0,87,360,156)
    for i in range(1,21):rect('Item'+str(i),(i-1)%7*49,(i-1)//7*49,44,44)
    rect('Last',294,100,50,21);rect('Next',294,123,50,21)
    for key in ['PageListNumber','PageListNumber2']:rect(key,0,246,360,24)
    for key in ['PageList','PageList2']:rect(key,52,2,183,22)
    for suffix in ('','_2'):
        for i in range(1,11):rect('Page'+str(i)+suffix,(i-1)*17,0,26 if i==10 else 17,22)
    rect('Petlan_Text',247,246,110,24);rect('TradeName',0,273,360,25)
    rect('PriceTag_Text',0,302,65,24);rect('PriceTag',69,303,196,24)
    rect('Buttons_Set',0,335,360,47)
    for i,key in enumerate(['AccountBook','Open','DownStall','TakeBack','Curtail','Continuation','DisposeOf']):
        rect(key,(i%4)*90,(i//4)*25,88,23)
    for key,y,h in [('Client_Right_Line1',59,26),('Client_Right_Line2',87,26),('Client_Right_Line3',115,128)]:rect(key,375,y,342,h)
    for key in ['MerchantName_Text','Sort_Text','Bewrite_Text']:rect(key,0,1,80,24)
    for key in ['MerchantName','SelectSort']:rect(key,82,2,168,24)
    for key in ['NameAmend','SortAmend','BewriteAmend']:rect(key,257,2,84,23)
    rect('Bewrite',0,30,342,98);rect('FriendList',375,274,164,108)
    rect('FriendID_Text',375,247,52,23);rect('FriendID',430,247,286,23)
    for key,y in [('Add',276),('ViewLog',304),('Del',332),('Relieve',332)]:rect(key,548,y,168,24)
    rect('Function_FrameSuo2',10,425,720,24);rect('Stall_StateSuo2',0,0,550,24);rect('OpenRecycleShop_BtnSuo2',556,0,160,24)
    for key,value in {'ShopCorpus_Text':'Vốn tiệm:','ShopProfit_Text':'Doanh thu:','ImmitCorpus':'Nạp vốn','Immit':'Nạp tiền',
        'DrawMoney':'Rút tiền','PriceTag_Text':'Giá bán:','MerchantName_Text':'Tên tiệm:','Sort_Text':'Loại tiệm:','Bewrite_Text':'Mô tả:',
        'NameAmend':'Đổi tên','SortAmend':'Đổi loại','BewriteAmend':'Sửa mô tả','AccountBook':'Sổ sách','TakeBack':'Lấy về',
        'Curtail':'Thu hẹp','Continuation':'Mở rộng','FriendID_Text':'ID bạn:'}.items():prop(key,'Text',value)
    return E.tostring(root,encoding='unicode',xml_declaration=True)
