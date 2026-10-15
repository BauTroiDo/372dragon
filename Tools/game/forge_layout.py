"""Generate one CY EquipStrengthen window using the existing game widget looks."""
from xml.etree import ElementTree as E

def generate():
    root=E.Element('GUILayout')
    def win(parent,kind,name,x,y,w,h,text=None,**props):
        a=E.SubElement(parent,'Window',Type=kind,Name=name)
        p={'AbsolutePosition':f'x:{x} y:{y}','AbsoluteSize':f'w:{w} h:{h}',**props}
        if text is not None:p['Text']=text
        for k,v in p.items():E.SubElement(a,'Property',Name=k,Value=str(v))
        return a
    def event(w,name,call):E.SubElement(w,'Event',Name=name,Function=call)
    def label(name,x,y,w,h,text,color='FFFFE6A8',align='LeftAligned'):
        return win(frame,'TLBB_SimpleText',name,x,y,w,h,text,TextColor=color,
                   HorzFormatting=align,VertFormatting='VertCentred',MouseHollow='True',RiseOnClick='False')
    def solid(name,x,y,w,h,color):
        return win(frame,'TLBB_StaticImageNULL',name,x,y,w,h,Image='set:UIIcons image:Space',
                   ImageColours=' '.join(f'{k}:{color}' for k in ['tl','tr','bl','br']),
                   MouseHollow='True',RiseOnClick='False',ZOrderChangeEnabled='False')
    frame=win(root,'TLBB_MainFrame1','EquipStrengthen_Frame',12,70,720,590)
    event(frame,'Hidden','EquipStrengthen_OnHiden();')
    title=win(frame,'TLBB_DragTitle','EquipStrengthen_DragTitle',40,4,640,25,
              'Cường hoá • Nhịp rèn',DragTarget='EquipStrengthen_Frame',Font='YouYuan11.25',HorzFormatting='HorzCentred')
    close=win(frame,'TLBB_ButtonClose','EquipStrengthen_Close',681,7,14,14)
    event(close,'Clicked','this:Hide();')
    label('Forge_Intro',28,38,664,26,'Đặt trang bị • Chuẩn bị nguyên liệu • Căn nhịp búa',align='HorzCentred')
    win(frame,'TLBB_StaticImageNULL','Forge_Art',28,80,288,216,Image='set:CysForgeArt image:AnvilHammer',MouseHollow='True',RiseOnClick='False')
    label('Forge_EquipLabel',344,72,144,25,'Trang bị',align='HorzCentred')
    label('Forge_MatLabel',518,72,162,25,'Nguyên liệu',align='HorzCentred')
    equip=win(frame,'TLBB_ActionButton','Forge_Equip',396,102,40,40,DragAcceptName='CYSFORGE0',DraggingEnabled='False',Empty='True')
    material=win(frame,'TLBB_ActionButton','Forge_Material',576,102,40,40,DragAcceptName='CYSFORGE1',DraggingEnabled='False',Empty='True')
    event(equip,'MouseRClick','CysForge_Clear(0);');event(material,'MouseRClick','CysForge_Clear(1);')
    label('Forge_Current',340,146,344,27,'Cường hoá hiện tại: +0 / 9',align='HorzCentred')
    stats=label('Forge_Stats',340,174,344,132,'Chỉ số tăng theo bảng cường hoá.',align='WordWrapLeftAligned')
    E.SubElement(stats,'Property',Name='VertFormatting',Value='TopAligned')
    label('Forge_Required',30,309,660,25,'Đặt trang bị để xem nguyên liệu cần dùng.',align='HorzCentred')
    for i in range(1,10):
        x=71+(i-1)*65
        win(frame,'TLBB_SimpleMulitiTextFrame',f'Forge_LevelFrame{i}',x-6,346,53,31)
        label(f'Forge_Level{i}',x-4,347,49,28,f'+{i}',align='HorzCentred')
    solid('Forge_TrackBorder',34,404,652,36,'FF9C7940')
    solid('Forge_Track',38,408,644,28,'FF241D13')
    solid('Forge_White',280,410,140,24,'FFF8F6ED')
    solid('Forge_Cursor',39,400,3,44,'FFFFC34D')
    label('Forge_Status',28,447,664,29,'Đặt trang bị và nguyên liệu để bắt đầu.',color='FFF2E7CE',align='HorzCentred')
    label('Forge_Cost',28,480,664,25,'Chi phí mỗi lượt: —',align='HorzCentred')
    label('Forge_Wallet',28,504,53,25,'Vàng:')
    win(frame,'TLBB_Money','Forge_Money',80,507,124,20,MoneyNumber='0',HorzFormatting='RightAligned')
    label('Forge_JiaoziLabel',219,504,69,25,'Giao tử:')
    win(frame,'TLBB_Money','Forge_Jiaozi',291,507,142,20,MoneyNumber='0',HorzFormatting='RightAligned',
        GoldIcon='set:Button6 image:Lace_JiaoziJin',SilverIcon='set:Button6 image:Lace_JiaoziYin',CopperIcon='set:Button6 image:Lace_JiaoziTong')
    start=win(frame,'TLBB_ButtonCommon','Forge_Start',448,506,148,29,'Bắt đầu')
    event(start,'Clicked','CysForge_Button();')
    stop=win(frame,'TLBB_ButtonCommon','Forge_Stop',600,506,86,29,'Dừng')
    event(stop,'Clicked','CysForge_Stop();')
    label('Forge_Rules',28,539,664,37,'Trừ giao tử trước, rồi vàng. Tự tiếp tục sau mỗi lần thành công.\nTrượt hoặc bỏ lượt: giảm 1 cấp, mất chi phí. Cấp thấp nhất là 0.',color='FFB9A787',align='WordWrapCentred')
    E.indent(root,space='  ')
    return E.tostring(root,encoding='utf-8',xml_declaration=True)

if __name__=='__main__':
    from pathlib import Path
    Path(__file__).with_name('forge').joinpath('EquipStrengthen.layout.xml').write_bytes(generate())
