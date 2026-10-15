"""Generate the 26 September runtime repairs from the current cumulative Play."""
from pathlib import Path
import re, xml.etree.ElementTree as ET
from dbc_inventory import Table
ROOT=Path(__file__).resolve().parents[2]
SERVER=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
GL=ROOT.parent/'client_GL/Data'

def gm_index(play):
 lines=[]
 lingyu={int(r[0]) for r in Table(SERVER/'configs/LingYuBase.txt').rows}
 for name in ['EquipBase','CommonItem','GemInfo']:
  p=play/f'Overlay/Pre/ConfigFolder/{name}.txt'
  if not p.exists():p=ROOT/f'Assets/CanonicalCY/Data/ConfigFolder/{name}.txt'
  valid={r[0] for r in Table(SERVER/f'configs/{name}.txt').rows}
  for r in Table(p).rows:
   if r[0] not in valid:continue
   label=re.sub(r'[\t\r\n]+',' ',str(r[10 if name=='EquipBase' else 7 if name=='GemInfo' else 6]))
   kind=('lingwu' if r[0] in lingyu else 'equip') if name=='EquipBase' else 'item'
   count=1 if name=='EquipBase' else 250 if name=='GemInfo' or int(r[12])>1 else 1
   lines.append(f'{label}\t{r[0]}\t{count}\t{kind}')
 assert any('\t10156901\t' in x for x in lines) and any('\t10156902\t' in x for x in lines)
 return ('\n'.join(lines)+'\n').encode('utf8')

def shop_mask():
 script=(SERVER/'Game_2/Script/scripts/event/prize/yuanbaoshop.lua').read_text(encoding='utf8')
 rows={r[0]:r for r in Table(SERVER/'configs/ShopTable.txt').rows}
 groups={}
 for a,ids in re.findall(r'shoplist\[(\d+)\]\s*=\s*\{([\d, ]+)\}',script):
  groups[int(a)]={b+1:shop for b,shop in enumerate(map(int,ids.split(','))) if shop in rows and int(rows[shop][11])>0 and any(int(rows[shop][i])>0 for i in range(27,min(len(rows[shop]),27+6*int(rows[shop][11])),6))}
 return groups

def outputs(play):
 result={}
 def source(rel):
  p=play/'Overlay/Pre'/rel
  return p if p.exists() else ROOT/'Assets/CanonicalCY/Data'/rel
 rel='InterfaceFolder/NewExterior_DressBox/NewExterior_DressBox.lua'
 s=source(rel).read_text(encoding='utf-8-sig')
 marker='-- Scoped CY wardrobe controller.'
 assert marker in s
 result[rel]=(s[:s.index(marker)]+(ROOT/'Tools/game/wardrobe_ui.lua').read_text(encoding='utf8')).encode('utf8')
 # Hit-testing recursively visits children before their parent. Making only
 # the tooltip root hollow leaves its labels/frames intercepting clicks.
 # UISystem explicitly routes wheel input to long SuperTooltip cards.
 for rel in ['InterfaceFolder/SuperTooltip/SuperTooltip.layout.xml',
             'InterfaceFolder/SuperTooltip_Compare/SuperTooltip_Compare.layout.xml',
             'InterfaceFolder/SuperTooltip_Compare2/SuperTooltip_Compare2.layout.xml']:
  if not source(rel).exists():continue
  tree=ET.fromstring(source(rel).read_bytes())
  for w in tree.iter('Window'):
   for name in ['MouseHollow','MouseMoveHollow']:
    prop=w.find("Property[@Name='"+name+"']")
    if prop is None:prop=ET.SubElement(w,'Property',Name=name)
    prop.set('Value','True')
  result[rel]=ET.tostring(tree,encoding='utf-8',xml_declaration=True)
 rel='InterfaceFolder/SelfEquip/SelfEquip.lua'
 s=source(rel).read_text(encoding='utf-8-sig')
 s+='''
-- The private CY server uses manual progression to 200, without CY regional
-- 119/129/compat-PK locks. School/xinfa prerequisites remain server authority.
function SelfEquip_LevelupButtonShow()
 local level=tonumber(Player:GetData("LEVEL")) or 0
 local cap=tonumber(Lua_GetMyMaxLevelLimit()) or 200
 local exp=tonumber(Player:GetData("EXP")) or 0
 local need=tonumber(Player:GetData("NEEDEXP")) or 0
 SelfEquip_UpLevel_Tip:Hide()
 if level>=10 and level<cap and Player:IsCanLevelup()==1 then
  SelfEquip_UpLevel:Enable()
 else SelfEquip_UpLevel:Disable() end
 local tip="Kinh nghiệm: "..tostring(exp).." / "..tostring(need)
 if level>=cap then tip="Đã đạt cấp tối đa "..tostring(cap)
 elseif need>0 and exp>=math.floor(need*3.5) then
  tip=tip.."#rĐã đầy EXP tích lũy (3,5 lần). Hãy lên cấp hoặc dùng EXP trước khi nhận thêm."
 elseif exp<need then tip=tip.."#rChưa đủ kinh nghiệm để lên cấp."
 else tip=tip.."#rBấm để lên cấp. Mốc 90/100/110 cần tâm pháp 80/90/100." end
 SelfEquip_UpLevel:SetToolTip(tip)
 SelfEquip_Exp2:SetToolTip(tip)
end
'''
 result[rel]=s.encode('utf8')
 # GL detaches the pet RTT before SetModel replaces the entity. Keep CY's
 # widget names/callbacks, with enough room for the Vietnamese font.
 rel='InterfaceFolder/Pet/Pet.lua';s=source(rel).read_text(encoding='utf-8-sig')
 s,n=re.subn(r'Pet\s*:\s*SetModel\(([^)]+)\);',
  r'Pet_FakeObject:DetachWindowEx(); Pet:SetModel(\1); Pet_FakeObject:AttachWindowEx("My_Pet"); CysPetCamera();',s)
 assert n==3
 # Retain the authored camera: uniformly reducing distance clips flying pets
 # whose idle animation rises above the model origin.
 s+='''
function CysPetCamera()
 Pet_FakeObject:RestPositonEx()
end
'''
 s=s.replace('#gFF0FA0','#cFFF263')
 # The instance name is decoded by the network path. The legacy second return
 # of GetName still contains the table's GBK species name, so do not send it
 # directly to a UTF-8 title widget.
 s=s.replace('Pet_PageHeader : SetText("#cFFF263"..strName2);',
             'Pet_PageHeader : SetText("#cFFF263Trân thú - "..strName);')
 result[rel]=s.encode('utf8')
 rel='InterfaceFolder/Pet/Pet.layout.xml';tree=ET.fromstring(source(rel).read_bytes())
 for prop in tree.iter('Property'):
  name,value=prop.get('Name'),prop.get('Value')
  if name in ['UnifiedSize','UnifiedPosition']:
   pairs=re.findall(r'\{\s*([-\d.]+)\s*,\s*([-\d.]+)\s*\}',value)
   if len(pairs)==2:
    prop.set('Value','{'+','.join('{'+a+','+format(float(b)*scale,'.5f')+'}' for (a,b),scale in zip(pairs,[1.3,1.25]))+'}')
  elif name in ['AbsoluteSize','AbsolutePosition']:
   prop.set('Value',re.sub(r'([whxy]):([-\d.]+)',lambda m:m[1]+':'+format(float(m[2])*(1.3 if m[1] in 'wx' else 1.25),'.5f'),value))
 for w in tree.iter('Window'):
  name=w.get('Name')
  if name=='Pet_PageHeader':w.find("Property[@Name='Font']").set('Value','YouYuan13')
  labels={'Pet_StrAptitude_Text':'TC Lực','Pet_NimbusAptitude_Text':'TC Nội lực',
          'Pet_PhysicalStrengthAptitude_Text':'TC Thể lực','Pet_StabilityAptitude_Text':'TC Trí lực',
          'Pet_FootworkAptitude_Text':'TC Thân pháp'}
  if name in labels:
   w.find("Property[@Name='Text']").set('Value',labels[name])
   for prop in list(w.findall("Property[@Name='Font']")):w.remove(prop)
   ET.SubElement(w,'Property',Name='Font',Value='YouYuan9.75')
  if name in ['Pet_Str_Text','Pet_Nimbus_Text','Pet_PhysicalStrength_Text','Pet_Stability_Text','Pet_Footwork_Text']:
   p=w.find("Property[@Name='UnifiedSize']");p.set('Value',re.sub(r'^\{\{[^}]+\}', '{{0,78}',p.get('Value')))
  if name in ['Pet_Str','Pet_Nimbus','Pet_PhysicalStrength','Pet_Stability','Pet_Dexterity']:
   p=w.find("Property[@Name='UnifiedPosition']");p.set('Value',re.sub(r'^\{\{[^}]+\}', '{{0,85}',p.get('Value')))
   p=w.find("Property[@Name='UnifiedSize']");p.set('Value',re.sub(r'^\{\{[^}]+\}', '{{1,-129}',p.get('Value')))
  if name.endswith('Aptitude_Text'):
   p=w.find("Property[@Name='UnifiedSize']");p.set('Value',re.sub(r'^\{\{[^}]+\}', '{{0,105}',p.get('Value')))
  elif name.endswith('Aptitude'):
   p=w.find("Property[@Name='UnifiedPosition']");p.set('Value',re.sub(r'^\{\{[^}]+\}', '{{0,112}',p.get('Value')))
   p=w.find("Property[@Name='UnifiedSize']");p.set('Value',re.sub(r'^\{\{[^}]+\}', '{{1,-114}',p.get('Value')))
 mesh=tree.find(".//Window[@Name='Pet_FakeObject']")
 mesh.find("Property[@Name='UnifiedSize']").set('Value','{{0.8,0},{0.9,0}}')
 mesh.find("Property[@Name='UnifiedPosition']").set('Value','{{0.1,0},{0.08,0}}')
 result[rel]=ET.tostring(tree,encoding='utf-8',xml_declaration=True)
 rel='InterfaceFolder/GmTool/GmTool.lua';s=source(rel).read_text(encoding='utf-8-sig')
 equip=Table(SERVER/'configs/EquipBase.txt');point=equip.names.index('EquipPoint(装备点)')
 souls={r[0] for r in equip.rows if r[point] in [18,39]}
 s='local CYS_SOUL_ITEMS={'+','.join('['+str(i)+']=true' for i in sorted(souls))+'}\n'+s
 # CY pet ids/variants come from the live server. GL handbook/name matching is
 # not an identity mapping, and some new species are absent from that book.
 start=s.index('    local wantedPage =',s.index('local function gmPetLoadPreview'))
 end=s.index('\nlocal function gmPetClearModel',start)
 s=s[:start]+'end\n'+s[end:]
 s=s.replace('    DataPool:SortPetTujianList();','')
 start=s.index('    local isBaize = modelId >=',s.index('local function gmPetShowGenericModel'))
 end=s.index('    gmPetGenericModel = true;',start)
 s=s[:start]+'    GmTool_PetFakeObject:RestPositonEx();\n'+s[end:]
 s=s.replace('string.find(string.lower(name), folded, 1, true)', '(string.find(string.lower(name), folded, 1, true) or tostring(id)==folded)')
 # Souls are initialized by their own server subsystem (equip type 2), not
 # by the ordinary 1..9-star random-equipment generator (type 0).
 s=s.replace('function GmTool_GrantItem()', '''function GmTool_GrantItem()
    if gmSelectedItem and CYS_SOUL_ITEMS[gmSelectedItem.id] then
        gmSendItem("item",gmSelectedItem.id,1,GmTool_ItemBind:GetCheck()==1,0)
        gmSetStatus("Đã gửi tạo "..gmSelectedItem.name.." theo dữ liệu Võ hồn / Chiến hồn.","#cfff263")
        return
    end''',1)
 s+='''
local CysSoulSelectOriginal=GmTool_SelectItem
function GmTool_SelectItem(slot)
 CysSoulSelectOriginal(slot)
 if gmSelectedItem and CYS_SOUL_ITEMS[gmSelectedItem.id] then
  GmTool_EquipAttrs:Hide()
  GmTool_SelectedMeta:SetText("#WVõ hồn / Chiến hồn: tạo theo dữ liệu hệ thống")
 elseif gmItemMode~="item" then GmTool_EquipAttrs:Show() end
end
'''
 result[rel]=s.encode('utf8')
 # The GL console explicitly references this atlas for the level/mutation
 # controls. It was never copied by the earlier GM port.
 rel='InterfaceFolder/Common/PetTujian.imageset.xml';result[rel]=(GL/rel).read_bytes()
 # Overlay InterfaceFolder is mounted in General; Material5Folder overlays
 # are not mounted by WXResources.cfg.
 result['InterfaceFolder/Common/png_PetTujian.dds']=(GL/'Material5Folder/Common/png_PetTujian.dds').read_bytes()
 rel='InterfaceFolder/Schema/WoWLookSkin.scheme.xml';tree=ET.fromstring(source(rel).read_bytes())
 if tree.find("Imageset[@Name='PetTujian']") is None:
  ET.SubElement(tree,'Imageset',Name='PetTujian',Filename='Common/PetTujian.imageset.xml')
 result[rel]=ET.tostring(tree,encoding='utf-8',xml_declaration=True)
 rel='InterfaceFolder/YuanbaoShop/YuanbaoShop.lua';s=source(rel).read_text(encoding='utf-8-sig')
 groups=shop_mask()
 mask='local CYS_SHOPS = {'+','.join('['+str(a)+']={'+','.join('['+str(b)+']=true' for b in bs)+'}' for a,bs in groups.items())+'}\n'
 mask+='local function CysShopHas(a,b) return CYS_SHOPS[a] and CYS_SHOPS[a][b] end\n'
 s=mask+s
 # Every open path, including search, chooses only an existing populated shelf.
 s=s.replace('function UpdateShopItem( shopA , shopB)','''function UpdateShopItem( shopA , shopB)
 if not CysShopHas(shopA,shopB) then
  local found=nil
  for i=1,8 do if CysShopHas(shopA,i) then found=i;break end end
  if not found then return end
  shopB=found
  if shopA<100 then lastB=shopB;SHOP_LIST_B[shopB]:SetCheck(1)
  else lastB_Bind=shopB;SHOP_LIST_B_BIND[shopB]:SetCheck(1) end
 end''',1)
 # Keep original button indices: callbacks and server coordinates must not shift.
 s+='''
local CysShopOrigins={}
local function CysShopCompact(a,buttons)
 if not CysShopOrigins[buttons] then
  CysShopOrigins[buttons]=tonumber(buttons[1]:GetProperty('AbsoluteYPosition')) or 0
 end
 local y=CysShopOrigins[buttons]
 for i=1,8 do
  local button=buttons[i]
  if button then
   if CysShopHas(a,i) then button:Show();button:SetProperty('AbsoluteYPosition',tostring(y));y=y+g_nDistanceBBtnY
   else button:Hide() end
  end
 end
end
local CysShopShowOriginal=YuanbaoShop_Show
function YuanbaoShop_Show()
 CysShopShowOriginal()
 for i=1,8 do
  local entry=SHOP_LIST_A[i]
  if entry then
   if CYS_SHOPS[i] and next(CYS_SHOPS[i]) then entry.btn:Show()
   else entry.btn:Hide() end
  end
 end
 CysShopCompact(lastA,SHOP_LIST_B)
 CysShopCompact(lastA_Bind+100,SHOP_LIST_B_BIND)
end
local CysShopListOriginal=YuanbaoShop_UpdateList
function YuanbaoShop_UpdateList(index)
 CysShopListOriginal(index)
 CysShopCompact(index,SHOP_LIST_B)
end
local CysShopBindOriginal=YuanbaoShop_UpdateList_Bind
function YuanbaoShop_UpdateList_Bind(index)
 CysShopBindOriginal(index)
 CysShopCompact(index+100,SHOP_LIST_B_BIND)
end
local CysShopSearchOriginal=YuanbaoShop_BeginSearch
function YuanbaoShop_BeginSearch()
 CysShopSearchOriginal()
 if lastSelect>0 then CysShopCompact(lastSelect+8,SHOP_LIST_B) end
end
local CysShopBindSearchOriginal=YuanbaoShop_BeginSearch_Bind
function YuanbaoShop_BeginSearch_Bind()
 CysShopBindSearchOriginal()
 if lastSelect_Bind>0 then CysShopCompact(lastSelect_Bind+108,SHOP_LIST_B_BIND) end
end
'''
 result[rel]=s.encode('utf8')
 for number in ['Two','Three','Four','Five']:
  rel=f'InterfaceFolder/OptionalGiftBox_{number}/OptionalGiftBox_{number}.lua'
  s=source(rel).read_text(encoding='utf-8-sig')
  s,n=re.subn(r'(local g_OptionalGiftBox_\w+_MainScript = )998256',r'\g<1>990031',s)
  assert n==1
  result[rel]=s.encode('utf8')
 return result
