"""Repair the effective CY guild layouts without replacing their skin or events."""
from pathlib import Path
import json, re, xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[2]
LOG=ROOT/'Build/Logs/2026-09-28-social-completion'
PLAY=ROOT/'Build/world-gui/stage-play-21'
def source(rel):
    p=LOG/'baseline/client'/rel
    if not p.exists():
        for root in [PLAY/'Overlay/Post',PLAY/'Overlay/Pre',ROOT/'Assets/CanonicalCY/Data']:
            f=root/rel
            if f.exists():p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(f.read_bytes());break
    return p.read_text(encoding='utf8')
def prop(w,key,value):
    p=w.find("Property[@Name='%s']"%key)
    if p is None:p=ET.SubElement(w,'Property',Name=key)
    p.set('Value',value)
def rect(w,x,y,width,height):
    for p in list(w.findall('Property')):
        if p.get('Name') in ['AbsolutePosition','AbsoluteSize']:w.remove(p)
    prop(w,'UnifiedPosition','{{0,%s},{0,%s}}'%(x,y))
    prop(w,'UnifiedSize','{{0,%s},{0,%s}}'%(width,height))
def generate():
    files={}
    rel='InterfaceFolder/NewBangHui_Bhxx/NewBangHui_Bhxx.layout.xml';tree=ET.fromstring(source(rel));ws={w.get('Name'):w for w in tree.iter('Window')}
    prefix='NewBangHui_Bhxx_'
    prop(ws[prefix+'Frame'],'UnifiedSize','{{0,750},{0,550}}');prop(ws[prefix+'Frame'],'UnifiedPosition','{{0.5,-375},{0.5,-275}}')
    prop(ws[prefix+'Frame2_Lace1_BHJBXX_Window'],'UnifiedSize','{{1,-6},{0,208}}')
    prop(ws[prefix+'Frame2_Lace1_Title2_lace'],'UnifiedPosition','{{0,3},{0,246}}')
    prop(ws[prefix+'Frame2_Lace1_BHCSXX_Window'],'UnifiedPosition','{{0,3},{0,278}}')
    rows=['BZ','BHID','SSTM','BHCSSJ','BHCSR','ZZDL','JYZL','BRSPSL']
    labels=['Bang chủ:','Mã bang:','Liên minh:','Ngày lập:','Người lập:','Chiến lực:','Chiến lực tinh anh:','Thương phiếu hôm nay:']
    for i,(key,label) in enumerate(zip(rows,labels)):
        w=ws[prefix+'Frame2_'+key+'_Window'];rect(w,3,2+i*25,333,25)
        labelwin=ws[prefix+'Frame2_'+key+'_Text'];rect(labelwin,4,0,153,24);prop(labelwin,'Text',label)
        for child in w.findall('Window'):
            if child is not labelwin:rect(child,158,0,171,24)
    # Town rows need the same independent label/value columns as guild rows.
    prop(ws[prefix+'Bhxz'],'Text','Bang chiến')
    prop(ws[prefix+'Frame2_Lace1_BHCSXX_Window'],'UnifiedSize','{{1,-6},{0,182}}')
    for key,y,label in [('BHCS',2,'Thành bang:'),('WHZT',27,'Bảo trì:'),('BHZJ',77,'Quỹ bang:'),('WHZJ',102,'Quỹ bảo trì:'),('BZWHZJ',127,'Quỹ dự phòng:'),('DQJS',152,'Đang xây:')]:
        name=prefix+'Frame2_'+key
        if name+'_Window' not in ws:continue
        rect(ws[name+'_Window'],3,y,333,25)
        rect(ws[name+'_Text'],4,0,130,24);prop(ws[name+'_Text'],'Text',label)
        for child in ws[name+'_Window'].findall('Window'):
            if child is not ws[name+'_Text']:rect(child,137,0,192,24)
        for money in ws[name+'_Window'].iter('Window'):
            if money.get('Type')=='TLBB_Money':rect(money,0,2,190,20)
    for key,x,width,label,labelwidth in [('CSGM',3,112,'Cấp:',42),('CSSZ',117,219,'Vị trí:',54)]:
        name=prefix+'Frame2_'+key;rect(ws[name+'_Window'],x,52,width,25)
        rect(ws[name+'_Text'],4,0,labelwidth,24);prop(ws[name+'_Text'],'Text',label)
        rect(ws[name+'_Lace'],labelwidth+7,0,width-labelwidth-11,24)
    prop(ws[prefix+'HuodongSet_Text'],'Text','Giờ mở phúc lợi')
    prop(ws[prefix+'HuodongSet_Text'],'HorzFormatting','HorzCentred')
    files[rel]='<?xml version="1.0" encoding="utf-8"?>\n'+ET.tostring(tree,encoding='unicode')
    rel='InterfaceFolder/Confraternity_OfficialPositionList/Confraternity_OfficialPositionList.layout.xml';tree=ET.fromstring(source(rel));ws={w.get('Name'):w for w in tree.iter('Window')};p='Confraternity_OfficialPositionList_'
    prop(ws[p+'Frame'],'AbsoluteSize','w:610 h:390');prop(ws[p+'Frame'],'UnifiedPosition','{{0.5,-305},{0.5,-195}}')
    rect(ws[p+'Function_Frame'],7,30,596,330)
    prop(ws[p+'MemberList'],'UnifiedSize','{{0,225},{1,0}}')
    rect(ws[p+'Bk'],230,0,366,191)
    # The title spans the pane; the remaining rows reserve independent label/value columns.
    rect(ws[p+'Info1_Text'],240,3,346,24)
    for row,i in enumerate([2,3,4,7,5,6]):
        rect(ws[p+'Info'+str(i)+'_Text'],240,30+row*26,142,25)
        rect(ws[p+'Info'+str(i)],384,30+row*26,204,25)
    for i,label in [(4,'Cống hiến:'),(7,'Cống hiến tuần:'),(5,'Vào bang:'),(6,'Trạng thái:')]:prop(ws[p+'Info'+str(i)+'_Text'],'Text',label)
    rect(ws[p+'Tenet_Text'],234,191,352,25)
    for key in ['Tenet','EditTenet']:rect(ws[p+key],234,218,352,110)
    files[rel]='<?xml version="1.0" encoding="utf-8"?>\n'+ET.tostring(tree,encoding='unicode')
    rel='InterfaceFolder/Confraternity_OfficialPositionList/Confraternity_OfficialPositionList.lua';s=source(rel)
    # Flush() supplies these labels at runtime and overrides the layout defaults.
    for before,after in [('Cống hiến độ:','Cống hiến:'),('Cống hiến độ tuần này:','Cống hiến tuần:'),('Thời gian vào bang:','Vào bang:'),('Thời gian ngoại tuyến:','Trạng thái:')]:s=s.replace(before,after)
    files[rel]=s
    rel='InterfaceFolder/NewBangHui_Tmxx/NewBangHui_Tmxx.layout.xml';tree=ET.fromstring(source(rel));ws={w.get('Name'):w for w in tree.iter('Window')};p='NewBangHui_Tmxx_'
    prop(ws[p+'Frame'],'UnifiedSize','{{0,750},{0,520}}');prop(ws[p+'Frame'],'UnifiedPosition','{{0.5,-375},{0.5,-260}}')
    prop(ws[p+'Bhxz'],'Text','Bang chiến')
    rect(ws[p+'Frame2_Lace1'],1,2,328,202)
    rect(ws[p+'Frame2_Lace1_TMJBXX_Window'],3,35,322,163)
    for i,(key,label) in enumerate(zip(['TMMC','XRBZ','TMID','TMRS','TMCSR','CJSJ'],['Liên minh:','Minh chủ:','Mã liên minh:','Thành viên:','Người lập:','Ngày lập:'])):
        rect(ws[p+'Frame2_'+key+'_Window'],3,2+i*26,316,26)
        rect(ws[p+'Frame2_'+key+'_Text'],5,0,108,25);prop(ws[p+'Frame2_'+key+'_Text'],'Text',label)
        rect(ws[p+'Frame2_'+key+'_Lace'],115,0,195,25)
    rect(ws[p+'Frame2_Lace2'],333,2,297,202)
    prop(ws[p+'Frame2_Lace2_Title_Text'],'Text','Tuyên ngôn')
    rect(ws[p+'ChangeDesc_Button'],224,8,66,24);prop(ws[p+'ChangeDesc_Button'],'Text','Sửa')
    rect(ws[p+'Frame2_Lace3'],1,208,630,230)
    rect(ws[p+'Member_List'],3,36,624,120)
    prop(ws[p+'Member_List'],'ForceHorzScrollbar','False')
    prop(ws[p+'Member_List'],'ColumnsAdjust','False')
    # This original skin has only a vertical scrollbar. The alliance has at most
    # three guilds; display dates underneath instead of creating clipped columns.
    widths=[.23,.08,.22,.06,.07,.33]
    titles=['Bang hội','Mã','Bang chủ','TV','Cấp','Thành bang']
    columns=ws[p+'Member_List'].findall("Property[@Name='ColumnHeader']")
    assert len(columns)==8
    for i,q in enumerate(columns):
        if i<6:q.set('Value','text:%s width:%s id:%s'%(titles[i],widths[i],i))
        else:ws[p+'Member_List'].remove(q)
    dates=ET.SubElement(ws[p+'Frame2_Lace3'],'Window',Type='TLBB_StaticText',Name=p+'Dates')
    rect(dates,5,159,618,64);prop(dates,'HorzFormatting','WordWrapLeftAligned');prop(dates,'VertFormatting','TopAligned');prop(dates,'VertScrollbar','True')
    files[rel]='<?xml version="1.0" encoding="utf-8"?>\n'+ET.tostring(tree,encoding='unicode')
    rel='InterfaceFolder/NewBangHui_Tmxx/NewBangHui_Tmxx.lua';s=source(rel)
    s=s.replace('if event == "UPDATE_GUILD_LEAGUE_INFO" then','if event == "UPDATE_GUILD_LEAGUE_INFO" then\n        if GuildLeague:GetID() < 0 then this:Hide();return end')
    s=s.replace('g_NewBH_Ctrl.list:RemoveAllItem()', 'g_NewBH_Ctrl.list:RemoveAllItem()\n    local dateLines = ""\n    NewBangHui_Tmxx_Dates:SetText("")')
    s=s.replace('g_NewBH_Ctrl.list:AddNewItem( GuildLeague:GetMemberCreateTime(i), 6, i )', 'dateLines = dateLines..GuildLeague:GetMemberName(i)..": Lập "..GuildLeague:GetMemberCreateTime(i)..", vào "..GuildLeague:GetMemberEnterTime(i).."\\n"')
    s=s.replace('g_NewBH_Ctrl.list:AddNewItem( GuildLeague:GetMemberEnterTime(i), 7, i )', 'NewBangHui_Tmxx_Dates:SetText(dateLines)')
    files[rel]=s
    rel='InterfaceFolder/NewBangHui_Xuanzhan/NewBangHui_Xuanzhan.layout.xml';tree=ET.fromstring(source(rel));ws={w.get('Name'):w for w in tree.iter('Window')};p='NewBangHui_Xuanzhan_'
    prop(ws[p+'Frame'],'UnifiedSize','{{0,750},{0,550}}');prop(ws[p+'Frame'],'UnifiedPosition','{{0.5,-375},{0.5,-275}}')
    for key,label in [('Bhxz','Bang chiến'),('Text','Mã bang mục tiêu:'),('Initiator','Tuyên chiến'),('Frame2_Lace1_Title1_Text','Tuyên chiến ngoài thành'),('Frame2_Lace2_Title_Text','Danh sách công thành'),('Frame2_Zhengtao_Title_Text','Bang cần ứng chiến'),('Tiaozhan_Button','Ứng chiến'),('Zhengtao_Button','Gửi'),('Zhengtao_Text','Nhập mã bang có thành để gửi lời tuyên chiến công thành.')]:prop(ws[p+key],'Text',label)
    rect(ws[p+'BenfuMember_List'],3,36,339,140)
    rect(ws[p+'Bk_New'],97,180,162,24)
    rect(ws[p+'Bk_New2'],4,208,337,28)
    rect(ws[p+'Text'],4,2,146,24);rect(ws[p+'Id'],153,3,66,23);rect(ws[p+'Initiator'],224,3,90,23);rect(ws[p+'Help2'],319,7,14,14)
    rect(ws[p+'Frame2_Lace1_Title1_lace'],3,244,339,30)
    rect(ws[p+'BenfuMember_List1'],4,276,338,211)
    rect(ws[p+'BenfuMember_List1_Tips'],4,274,338,20)
    rect(ws[p+'Zhengtao_List'],3,36,281,140)
    rect(ws[p+'Zhengtao_Text'],6,178,274,50)
    rect(ws[p+'Bk_Zhengtao'],72,230,143,27)
    rect(ws[p+'Frame2_Zhengtao_Title_lace'],3,270,185,30)
    rect(ws[p+'Tiaozhan_Button'],193,275,89,23)
    rect(ws[p+'ZhengtaoYingzhan_List'],3,304,281,183)
    rect(ws[p+'ZhengtaoYingzhan_List_Tips'],3,302,281,20)
    for key,titles,widths in [('BenfuMember_List',['Mã','Bang hội','Bang chủ'],[.15,.44,.4]),('BenfuMember_List1',['Mã','Bang hội','Quan hệ','Còn lại'],[.15,.4,.25,.24]),('Zhengtao_List',['Mã','Bang hội','Còn lại'],[.17,.47,.35]),('ZhengtaoYingzhan_List',['Mã','Bang hội','Còn lại'],[.17,.47,.35])]:
        columns=ws[p+key].findall("Property[@Name='ColumnHeader']");assert len(columns)==len(titles)
        for i,q in enumerate(columns):q.set('Value','text:%s width:%s id:%s'%(titles[i],widths[i],i))
    files[rel]='<?xml version="1.0" encoding="utf-8"?>\n'+ET.tostring(tree,encoding='unicode')
    rel='InterfaceFolder/NewBangHui_Xuanzhan/NewBangHui_Xuanzhan.lua';s=source(rel)
    s=s.replace('Guild:GetGuildNum()', 'City:GetGuildNumByZoneWorldId(0)')
    s=re.sub(r'Guild:GetGuildInfo\(i, "(\w+)"\)',lambda m:'City:GetGuildInfoBigWorld(0,i,"'+('GuildID' if m[1]=='ID' else m[1])+'")',s)
    s=s.replace('#{BHJM_140520_04}','Bang chiến').replace('#{BHJM_140520_110}','Tuyên chiến ngoài thành')
    files[rel]=s
    rel='InterfaceFolder/MessageBox_Self/MessageBox_Self.lua';s=source(rel)
    s=s.replace('function MessageBox_Self_City_UpdateFrame()', '''function MessageBox_Self_City_UpdateFrame()
    if g_CityData[1] == 11 then
        MessageBox_Self_DragTitle:SetText("Tuyên chiến bang hội")
        MessageBox_Self_Text:SetText("Tuyên chiến với bang "..tostring(g_CityData[2]).."? Tiêu hao 100 điểm mở rộng khi tuyên chiến thành công.")
        MessageBox_Self_UpdateRect();this:Show();return
    end''')
    s=s.replace('function MessageBox_Self_City_OK_Clicked()', '''function MessageBox_Self_City_OK_Clicked()
    if g_CityData[1] == 11 then City:SendAddEnemyMsg(g_CityData[2]);g_CityData={};return end''')
    s=s.replace('#{TM_20080331_09}#{_EXCHG1000000}#{TM_20080331_02}', 'Xác nhận thành lập liên minh bang hội?')
    files[rel]=s
    for rel,s in files.items():
        dst=LOG/'ui'/rel;dst.parent.mkdir(parents=True,exist_ok=True);dst.write_bytes(s.encode('utf8'))
        if rel.endswith('.xml'):ET.parse(dst)
    (LOG/'ui-manifest.json').write_text(json.dumps(list(files),indent=2))
    print('Generated',len(files),'guild layouts')
if __name__=='__main__':generate()
