"""Vo Thach overlay generator; original CY/GL resources remain read-only."""
from pathlib import Path
import re,io,xml.etree.ElementTree as E
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
ART=Path(__file__).parent/'vothach'
ICONS={
 'set:Button2 image:Icon_GoldCoin':'set:CysVoThach image:Upper',
 'set:Button2 image:Icon_SilverCoin':'set:CysVoThach image:Middle',
 'set:Button2 image:Icon_CopperCoin':'set:CysVoThach image:Lower',
 'set:Button6 image:Lace_JiaoziJin':'set:CysVoThach image:Upper',
 'set:Button6 image:Lace_JiaoziYin':'set:CysVoThach image:Middle',
 'set:Button6 image:Lace_JiaoziTong':'set:CysVoThach image:Lower',
 'set:CommonFrame38 image:Icon_GoldCoin2':'set:CysVoThach image:Upper',
 'set:CommonFrame38 image:Icon_SilverCoin2':'set:CysVoThach image:Middle',
 'set:CommonFrame38 image:Icon_CopperCoin2':'set:CysVoThach image:Lower',
 'set:CommonFrame38 image:Lace_JiaoziJin2':'set:CysVoThach image:Upper',
 'set:CommonFrame38 image:Lace_JiaoziYin2':'set:CysVoThach image:Middle',
 'set:CommonFrame38 image:Lace_JiaoziTong2':'set:CysVoThach image:Lower',
 'set:QiFuSign image:JiaoZiIcon':'set:CysVoThach image:Lower'}
TEXT=[('vàng/giao tử','Võ Thạch hạ phẩm'),('vàng và giao tử','Võ Thạch'),('tiền và giao tử','Võ Thạch'),
 ('Nguyên Bảo khóa','Nguyên Bảo'),('Nguyên bảo khóa','Nguyên Bảo'),('nguyên bảo khóa','Nguyên Bảo'),
 ('Nguyên bảo khóa','Nguyên Bảo'),('nguyên bảo cố định','Nguyên Bảo'),
 ('Giao tử','Võ Thạch'),('Giao Tử','Võ Thạch'),('giao tử','Võ Thạch'),
 ('Kim tiền','Võ Thạch'),('kim tiền','Võ Thạch'),('Tiền vàng','Võ Thạch'),('tiền vàng','Võ Thạch'),
 ('Tiền bạc','Võ Thạch'),('tiền bạc','Võ Thạch'),('Vàng:','Võ Thạch:')]
def words(s):
 for a,b in TEXT:s=s.replace(a,b)
 return s
def props(w,**kw):
 for k,v in kw.items():
  p=w.find("Property[@Name='%s']"%k)
  if p is None:p=E.SubElement(w,'Property',Name=k)
  p.set('Value',str(v))
def xml(root):return E.tostring(root,encoding='utf-8',xml_declaration=True)
def bag(raw):
 root=E.fromstring(raw);by={w.get('Name'):w for w in root.iter('Window')}
 for name in ['Packet_Jiaozi_Back','Packet_BangdingYuanbao_Back','Packet_Tongbao_Back','Packet_Fanquan_Back','Packet_YuanBao_Back']:
  props(by[name],Visible='False')
 props(by['Packet_Money_Back'],UnifiedPosition='{{0,0},{1,-116}}',UnifiedSize='{{1,0},{0,32}}')
 props(by['Packet_Money'],UnifiedPosition='{{0,85},{0,6}}',UnifiedSize='{{1,-94},{0,20}}',Tooltip='Võ Thạch: 100 hạ = 1 trung; 100 trung = 1 thượng.')
 lab=E.SubElement(by['Packet_Money_Back'],'Window',Type='TLBB_SimpleText',Name='CysVoThach_Label')
 props(lab,AbsolutePosition='x:6 y:6',AbsoluteSize='w:80 h:20',Text='Võ Thạch:',MouseHollow='True')
 props(by['Packet_YuanBao_Back2'],UnifiedPosition='{{0,0},{1,-84}}',UnifiedSize='{{1,0},{0,28}}')
 parent=next(w for w in root.iter('Window') if by['Packet_Money_Back'] in list(w))
 lab=E.SubElement(parent,'Window',Type='TLBB_SimpleText',Name='CysVoThach_Rates')
 props(lab,UnifiedPosition='{{0,5},{1,-54}}',UnifiedSize='{{1,-10},{0,30}}',Text='100 hạ = 1 trung; 100 trung = 1 thượng',HorzFormatting='HorzCentred',MouseHollow='True')
 return xml(root)
def forge(raw):
 root=E.fromstring(raw);by={w.get('Name'):w for w in root.iter('Window')}
 props(by['Forge_Wallet'],Text='Võ Thạch:',AbsoluteSize='w:90 h:25')
 props(by['Forge_Money'],AbsolutePosition='x:120 y:507',AbsoluteSize='w:300 h:20')
 props(by['Forge_Jiaozi'],Visible='False');props(by['Forge_JiaoziLabel'],Visible='False')
 props(by['Forge_Rules'],Text='Tiêu Võ Thạch và nguyên liệu khi bắt đầu. Tự tiếp tục sau mỗi lần thành công.\nTrượt hoặc bỏ lượt: giảm 1 cấp, mất chi phí. Cấp thấp nhất là 0.')
 return xml(root)
def outputs(play):
 # Mechanical export/resampling only: artwork and alpha come from image_gen.
 atlas=Image.new('RGBA',(64,32));images=E.Element('Imageset',Name='CysVoThach',Imagefile='CysVoThach.tga',NativeHorzRes='1280',NativeVertRes='720',AutoScaled='false')
 for i,(file,name) in enumerate([('thuong-pham','Upper'),('trung-pham','Middle'),('ha-pham','Lower')]):
  im=Image.open(ART/(file+'.png')).convert('RGBA');assert im.getchannel('A').getextrema()==(0,255),'Need genuine alpha'
  box=im.getchannel('A').getbbox();im=im.crop(box);im.thumbnail((16,16),Image.Resampling.LANCZOS)
  atlas.alpha_composite(im,(i*20+(16-im.width)//2,(16-im.height)//2))
  E.SubElement(images,'Image',Name=name,XPos=str(i*20),YPos='0',Width='16',Height='16')
 b=io.BytesIO();atlas.save(b,format='TGA');result={'InterfaceFolder/Common/CysVoThach.tga':b.getvalue(),'InterfaceFolder/Common/CysVoThach.imageset.xml':xml(images)}
 # Resolve current overlays before canonical resources, preserving prior fixes.
 sources={}
 for p in (ROOT/'Assets/CanonicalCY/Data/InterfaceFolder').rglob('*'):
  if p.suffix in ['.xml','.lua']:
   rel=p.relative_to(ROOT/'Assets/CanonicalCY/Data').as_posix();sources[rel.casefold()]=(rel,p)
 for p in (play/'Overlay/Pre/InterfaceFolder').rglob('*'):
  if p.suffix in ['.xml','.lua']:
   rel=p.relative_to(play/'Overlay/Pre').as_posix();sources[rel.casefold()]=(rel,p)
 files=dict(sources.values())
 for rel,p in files.items():
  raw=p.read_bytes()
  try:s=raw.decode('utf-8-sig')
  except UnicodeDecodeError:continue
  t=s
  for a,b in ICONS.items():t=t.replace(a,b)
  if any(k in rel for k in ['EquipStrengthen/','CysEquipCraft/','Wuhun/','WuhunMagicUp/','CysPetSoul/','CysDualSouls/','ShenMuWangDing/','Xiulian/']):t=words(t)
  if rel=='InterfaceFolder/Schema/WoWLookSkin.scheme.xml':t=t.replace('</GUIScheme>','<Imageset Name="CysVoThach" Filename="Common/CysVoThach.imageset.xml" />\n</GUIScheme>')
  if rel=='InterfaceFolder/Packet/Packet.lua':
   t=t.replace('"N.Bảo:"','"Nguyên Bảo: "')
   t+= '''
local CysCurrencyBagUpdate=Packet_OnUpdateShow
function Packet_OnUpdateShow()
 CysCurrencyBagUpdate()
 Packet_Money:SetToolTip("#YVõ Thạch#W#rHạ phẩm: xanh ngọc#rTrung phẩm: xanh lam#rThượng phẩm: tím#r100 hạ = 1 trung#r100 trung = 1 thượng")
end
local CysCurrencyBagLine=Packet_UpdateBagLine
local CysCurrencyBagLines=-1
function Packet_UpdateBagLine(n)
 CysCurrencyBagLine(n)
 if n~=CysCurrencyBagLines then
  local height=n*40+304
  if SystemSetup:IsClassic()==1 then height=n*35+278 end
  Packet_Frame:SetProperty("UnifiedYPosition","{1,"..tostring(-height-8).."}")
  CysCurrencyBagLines=n
 end
end
'''
  if rel=='InterfaceFolder/YuanBaoShop/YuanbaoShop.lua':
   t=t.replace('tostring( Player:GetData("BIND_YUANBAO")).."/"..tostring(Player:GetData("YUANBAO"))','tostring(Player:GetData("YUANBAO"))')
  if t!=s:result[rel]=t.encode()
 for rel,fn in [('InterfaceFolder/Packet/Packet.layout.xml',bag),('InterfaceFolder/EquipStrengthen/EquipStrengthen.layout.xml',forge)]:result[rel]=fn(result.get(rel,files[rel].read_bytes()))
 rel='ConfigFolder/StrDictionary.txt';p=play/'Overlay/Pre'/rel
 if not p.exists():p=ROOT/'Assets/CanonicalCY/Data'/rel
 s=p.read_text(encoding='utf8');lines=s.splitlines();fixed=[]
 overrides={'money_tips':'Giới hạn Võ Thạch:','no_money':'Không đủ Võ Thạch.','JZT_081211_1':'Võ Thạch: 100 hạ = 1 trung; 100 trung = 1 thượng.','BDYB_XML_6':'Nguyên Bảo: '}
 for line in lines:
  parts=line.split('\t',1)
  if len(parts)==2:parts[1]=overrides.get(parts[0],words(parts[1]));line='\t'.join(parts)
  fixed.append(line)
 result[rel]=('\r\n'.join(fixed)+'\r\n').encode()
 assert len({p.casefold() for p in result})==len(result),'Duplicate Windows overlay path'
 return result
