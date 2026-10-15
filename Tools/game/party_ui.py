"""Party/guild overlays from the effective Play version, retaining CY windows and skins."""
from pathlib import Path
import json,re,xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[2]
LOG=ROOT/'Build/Logs/2026-09-28-party-guild'
PLAY=ROOT/'Build/world-gui/stage-play-21'
def source(rel):
 p=LOG/'baseline/client'/rel
 if not p.exists():
  for root in [PLAY/'Overlay/Post',PLAY/'Overlay/Pre',ROOT/'Assets/CanonicalCY/Data']:
   f=root/rel
   if f.exists():p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(f.read_bytes());break
 return p.read_text(encoding='utf8')
def generate():
 files={}
 rel='InterfaceFolder/ConfraternityList/ConfraternityList.layout.xml';tree=ET.fromstring(source(rel));parent=next(w for w in tree.iter('Window')if w.get('Name')=='ConfraternityList_Function_Frame')
 w=ET.SubElement(parent,'Window',Type='TLBB_ButtonCommon',Name='ConfraternityList_Create')
 for k,v in [('UnifiedPosition','{{0,4},{1,-20}}'),('UnifiedSize','{{0,82},{0,20}}'),('Text','Lập bang'),('Tooltip','Cấp 40; phí 50 Võ Thạch thượng phẩm.')]:ET.SubElement(w,'Property',Name=k,Value=v)
 ET.SubElement(w,'Event',Name='Clicked',Function='this:Hide();Guild:CysCreateGuildWindow();')
 files[rel]='<?xml version="1.0" encoding="utf-8"?>\n'+ET.tostring(tree,encoding='unicode')
 rel='InterfaceFolder/CreateConfraternity/CreateConfraternity.lua';s=source(rel)
 s=s.replace('this:CareObject(objCared, 1, "GuildCreate");','if objCared and objCared >= 0 then this:CareObject(objCared, 1, "GuildCreate"); end')
 s=s.replace('this:CareObject(objCared, 0, "GuildCreate");','if objCared and objCared >= 0 then this:CareObject(objCared, 0, "GuildCreate"); end')
 s=s.replace('local szGuildDesc = CreateConfraternity_InputTenet:GetText();','local szGuildDesc = string.gsub(CreateConfraternity_InputTenet:GetText(), "%s+$", "");')
 s=s.replace('function Guild_Create_Click()', '''function Guild_Create_Click()
 local n=CreateConfraternity_InputConfraternityName:GetText();local d=string.gsub(CreateConfraternity_InputTenet:GetText(), "%s+$", "");
 if string.len(n)>23 or string.len(d)>60 then PushDebugMessage("Tên bang hoặc tôn chỉ quá dài. Hãy viết ngắn hơn.");return end
''')
 files[rel]=s
 rel='InterfaceFolder/Confraternity_OfficialPositionList/Confraternity_OfficialPositionList.lua';s=source(rel)
 s=s.replace('g_ListIdx2IDTbl = nil','g_ListIdx2IDTbl = {}')
 files[rel]=s
 rel='InterfaceFolder/CreateConfraternity/CreateConfraternity.layout.xml';tree=ET.fromstring(source(rel))
 for w in tree.iter('Window'):
  if w.get('Name')=='CreateConfraternity_Frame':w.find("Property[@Name='AbsoluteSize']").set('Value','w:360 h:300')
  if w.get('Name')=='CreateConfraternity_Text1':
   p=w.find("Property[@Name='Text']");p.set('Value','Cấp 40; phí 50 Võ Thạch thượng phẩm.')
 files[rel]='<?xml version="1.0" encoding="utf-8"?>\n'+ET.tostring(tree,encoding='unicode')
 rel='InterfaceFolder/ConfraternityList/ConfraternityList.lua';s=source(rel)
 s=s.replace('local MaxNum = 128;', 'local MaxNum = 20;')
 s=s.replace('this:CareObject(g_clientNpcId, 1, "GuildList");','if g_clientNpcId >= 0 then this:CareObject(g_clientNpcId, 1, "GuildList"); end')
 s=s.replace('this:CareObject(g_clientNpcId, 0, "GuildList");','if g_clientNpcId >= 0 then this:CareObject(g_clientNpcId, 0, "GuildList"); end')
 files[rel]=s
 rel='InterfaceFolder/MessageBox_Self/MessageBox_Self.lua';s=source(rel)
 s=s.replace('"Ngươi xác nhận muốn tạo?" .. argCREATE_CONFIRM0 .. "bang hội không?"','"Lập bang " .. argCREATE_CONFIRM0 .. "? Phí: 50 Võ Thạch thượng phẩm. Phí chỉ trừ khi lập bang thành công."')
 files[rel]=s
 rel='InterfaceFolder/TeamFrame/TeamFrame.lua';s=source(rel)
 for a,b in {'Rời khỏi đội':'Rời đội','Tự kiến đội ngũ':'Tạo đội','Giải tán đội':'Giải tán','Đá khỏi đội':'Mời ra','Bổ nhiệm đội trưởng':'Đội trưởng','Thông tin đội':'Tổ đội','Xóa danh sách':'Xóa hết','Đồng ý yêu cầu':'Đồng ý','Từ chối yêu cầu':'Từ chối','Đồng ý lời mời':'Đồng ý','Từ chối lời mời':'Từ chối'}.items():s=s.replace(a,b)
 s=s.replace('g_Team_PlayerInfo_GuildName[index]:SetText("#{BHXX_160531_1}".."#{GMGameInterface_Script_DataPool_Info_None}")','g_Team_PlayerInfo_GuildName[index]:SetText("")')
 s=s.replace('g_Team_PlayerInfo_FightScore[index]:SetText("#{BHXX_160531_3}"..tostring(iFightScore));','g_Team_PlayerInfo_FightScore[index]:SetText(iFightScore == "" and "" or ("#{BHXX_160531_3}"..tostring(iFightScore)));')
 files[rel]=s
 rel='InterfaceFolder/NewBangHui_Bhxx/NewBangHui_Bhxx.lua';s=source(rel)
 s=s.replace('Guild:GetMyGuildName("Name")','Guild:GetMyGuildDetailInfo("Name")')
 files[rel]=s
 # Keep the original controls/events; fit Vietnamese labels in their actual cells.
 rel='InterfaceFolder/TeamFrame/TeamFrame.lua'
 for a,b in {'Danh sách đăng ký':'Đơn xin','Giải tán ngũ':'Giải tán','Xin rời đội':'Mời ra','Đội trưởng':'Giao đội','#{DRCQ_100804_57}':'Cùng cưỡi','Trang trước':'Trước','Trang sau':'Sau','Ẩn người chơi':'Ẩn','Chế độ thuần thú':'Thuần thú'}.items():files[rel]=files[rel].replace(a,b)
 rel='InterfaceFolder/TeamFrame/TeamFrame.layout.xml';tree=ET.fromstring(source(rel))
 for w in tree.iter('Window'):
  n=w.get('Name','')
  if re.fullmatch('Team_PlayerInfo[1-6]_(School|Level)',n):
   w.find("Property[@Name='UnifiedSize']").set('Value','{{1,-4},{0,20}}')
   w.find("Property[@Name='UnifiedPosition']").set('Value','{{0,2},{0,'+('24'if n.endswith('School')else'44')+'}}')
  if n=='Team_Follow_Button':w.find("Property[@Name='Text']").set('Value','Theo đội')
  if n=='Team_AbortTeamFollow_Button':w.find("Property[@Name='Text']").set('Value','Dừng')
  if n=='Team_Button_Frame8':w.find("Property[@Name='Text']").set('Value','Đổi đoàn')
  if re.fullmatch('Team_PlayerInfo[1-6]_Banghui',n):w.find("Property[@Name='UnifiedPosition']").set('Value','{{0,2},{0,64}}')
 files[rel]='<?xml version="1.0" encoding="utf-8"?>\n'+ET.tostring(tree,encoding='unicode')
 rel='InterfaceFolder/NewBangHui_Hygl/NewBangHui_Hygl.lua';s=source(rel)
 s=s.replace('function NewBangHui_Hygl_Update()','function NewBangHui_Hygl_Update()\n NewBangHui_Hygl_ClearInfo();')
 s=s.replace('Guild:GetMembersNum(3).."/"..Guild:GetMembersNum(1)', 'Guild:GetMembersNum(3).."/"..Guild:GetMembersNum(4)')
 s=s.replace('color..szMsg.."("..szId..")"','color..szMsg')
 for a,b in {'#{BHJM_140520_06}':'Sửa tôn chỉ','Sửa đổi hoàn thành':'Lưu','#{INTERFACE_XML_577}':'Vào bang:','#{BHJM_140520_30}':'Online:','#{LDSD_200805_85}':'Đúc tệ:'}.items():s=s.replace(a,b)
 files[rel]=s
 rel='InterfaceFolder/NewBangHui_Hygl/NewBangHui_Hygl.layout.xml';tree=ET.fromstring(source(rel))
 labels={'NewBangHui_Hygl_Paixu':'Xếp:','NewBangHui_Hygl_Online':'Thành viên:', 'NewBangHui_Hygl_Chengyuanmingcheng_Text1':'Tên:', 'NewBangHui_Hygl_GUID_Text1':'ID:', 'NewBangHui_Hygl_Gongxian_Text1':'Cống hiến:', 'NewBangHui_Hygl_RenMing_Button':'Bổ nhiệm', 'NewBangHui_Hygl_ZhuChu_Button':'Mời ra', 'NewBangHui_Hygl_ShanRang_Button':'Nhường', 'NewBangHui_Hygl_XiugaiZhongzhi_Button':'Sửa tôn chỉ'}
 for w in tree.iter('Window'):
  n=w.get('Name','')
  if n=='NewBangHui_Hygl_Frame':
   w.find("Property[@Name='UnifiedSize']").set('Value','{{0,900},{0,420}}')
   w.find("Property[@Name='UnifiedPosition']").set('Value','{{0.5,-450},{0.5,-210}}')
  if n in labels and w.find("Property[@Name='Text']")is not None:w.find("Property[@Name='Text']").set('Value',labels[n])
  if n=='NewBangHui_Hygl_Paixu_Frame':
   w.find("Property[@Name='UnifiedPosition']").set('Value','{{0,190},{0,8}}')
   w.find("Property[@Name='UnifiedSize']").set('Value','{{0,300},{0,20}}')
  if n=='NewBangHui_Hygl_SearchMode':
   w.find("Property[@Name='UnifiedPosition']").set('Value','{{0,40},{0,0}}')
   w.find("Property[@Name='UnifiedSize']").set('Value','{{0,260},{0,20}}')
  if n=='NewBangHui_Hygl_DingWei':w.find("Property[@Name='UnifiedPosition']").set('Value','{{0,496},{0,8}}')
  if n=='NewBangHui_Hygl_Online':w.find("Property[@Name='UnifiedPosition']").set('Value','{{1,-250},{0,8}}')
  if n=='NewBangHui_Hygl_Online_Text':
   w.find("Property[@Name='UnifiedPosition']").set('Value','{{1,-145},{0,8}}')
   w.find("Property[@Name='UnifiedSize']").set('Value','{{0,135},{0,20}}')
  if n in ['NewBangHui_Hygl_BHCYList','NewBangHui_Hygl_SQJRList']:w.find("Property[@Name='UnifiedSize']").set('Value','{{0,500},{0,315}}')
  if n.endswith('_Text2'):
   p=w.find("Property[@Name='Text']")
   if p is not None:p.set('Value','')
   pos=w.find("Property[@Name='UnifiedPosition']")
   if pos is not None:pos.set('Value',re.sub(r'^\{\{[^}]+\}', '{{0,84}',pos.get('Value')))
   size=w.find("Property[@Name='UnifiedSize']")
   if size is not None:size.set('Value','{{1,-88},{0,20}}')
  if n=='NewBangHui_Hygl_BHCYList':
   for p,caption,width in zip(w.findall("Property[@Name='ColumnHeader']"),['Chức vụ','Tên','Cấp','Môn phái','Tuần','Điểm'],[.2,.27,.08,.23,.11,.11]):
    ident=p.get('Value').split('id:')[-1];p.set('Value',f'text:{caption} width:{width} id:{ident}')
  if n=='NewBangHui_Hygl_SQJRList':
   for p,caption,width in zip(w.findall("Property[@Name='ColumnHeader']"),['Tên','Cấp','Môn phái','Điểm'],[.48,.10,.27,.15]):
    ident=p.get('Value').split('id:')[-1];p.set('Value',f'text:{caption} width:{width} id:{ident}')
 files[rel]='<?xml version="1.0" encoding="utf-8"?>\n'+ET.tostring(tree,encoding='unicode')
 # ColumnHeader is parsed by CEGUI as a property, outside runtime text expansion.
 dictionary={}
 for line in source('ConfigFolder/StrDictionary.txt').splitlines():
  parts=line.split('\t',1)
  if len(parts)==2:dictionary[parts[0]]=parts[1]
 for rel in ['InterfaceFolder/ConfraternityList/ConfraternityList.layout.xml','InterfaceFolder/Confraternity_OfficialPositionList/Confraternity_OfficialPositionList.layout.xml']:
  tree=ET.fromstring(files.get(rel)or source(rel))
  for p in tree.iter('Property'):
   if p.get('Name')=='ColumnHeader':p.set('Value',re.sub(r'#\{([^}]+)\}',lambda m:dictionary.get(m[1],m[0]),p.get('Value')))
  files[rel]='<?xml version="1.0" encoding="utf-8"?>\n'+ET.tostring(tree,encoding='unicode')
 rel='InterfaceFolder/ConfraternityList/ConfraternityList.lua';s=files[rel]
 a=s.index('function Guild_Valid_City_Info_Update()');b=s.index('\nfunction Guild_List_Update()',a)
 s=s[:a]+'''function Guild_Valid_City_Info_Update()
 g_GuildListCtl.info:SetText("Bang hội: "..tostring(Guild:GetGuildNum()).."  - Trang "..tostring(CurPage+1));
end
'''+s[b:]
 s=s.replace('Guild:GetGuildInfo(i,"FineEquipPoint")','Guild:GetGuildInfo(i,"Count")').replace('Guild:GetGuildInfo(i,"AllEquipPoint")','Guild:GetGuildInfo(i,"ChiefName")')
 s=s.replace('Thời gian thành lập:','Lập:').replace('Không có thành thị','Chưa có')
 files[rel]=s
 rel='InterfaceFolder/ConfraternityList/ConfraternityList.layout.xml';tree=ET.fromstring(files[rel])
 for w in tree.iter('Window'):
  n=w.get('Name','')
  if n=='ConfraternityList_Frame':
   w.find("Property[@Name='AbsoluteSize']").set('Value','w:820 h:366')
   w.find("Property[@Name='UnifiedPosition']").set('Value','{{0.5,-410},{0.12,0}}')
  for p in w.findall('Property'):
   if p.get('Name')=='UnifiedSize':p.set('Value',p.get('Value').replace('201.000000','321.000000'))
   if p.get('Name')=='UnifiedPosition':p.set('Value',p.get('Value').replace('-203.000000','-323.000000'))
   if p.get('Name')=='AbsoluteSize'and p.get('Value')=='w:201 h:100':p.set('Value','w:321 h:100')
  if n=='ConfraternityList_List':
   for p,caption,width in zip(w.findall("Property[@Name='ColumnHeader']"),['ID','Tên bang','Cấp','Số TV','Bang chủ'],[.08,.36,.1,.14,.32]):
    ident=p.get('Value').split('id:')[-1];p.set('Value',f'text:{caption} width:{width} id:{ident}')
 files[rel]='<?xml version="1.0" encoding="utf-8"?>\n'+ET.tostring(tree,encoding='unicode')
 for rel,s in files.items():
  p=LOG/'client'/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(s.encode('utf8'))
 (LOG/'client/manifest.json').write_text(json.dumps(list(files),indent=2));print('Generated',len(files),'party/guild overlays')
if __name__=='__main__':generate()
