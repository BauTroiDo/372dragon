"""Generate community overlays from the current Play, retaining CY skins."""
from pathlib import Path
import json,xml.etree.ElementTree as ET
from hj_appearance_data import RawTable
ROOT=Path(__file__).resolve().parents[2]
LOG=ROOT/'Build/Logs/2026-09-28-settings-friends-titles'
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
 # The original CY title script was excluded before its hosts existed. Restore
 # the original window ID with the replacement script, preserving every old row.
 rel='ConfigFolder/InterfaceEx.txt';base=LOG/'baseline/client'/rel
 if not base.exists():
  base.parent.mkdir(parents=True,exist_ok=True)
  base.write_bytes((PLAY/'Overlay/Post'/rel).read_bytes())
 table=RawTable(base)
 assert not any(r[1]==b'Agname' for r in table.rows)
 files[rel]=table.extend([[2,b'Agname',b'Agname/Agname.layout.xml',b'Agname/Agname.lua',1,b'jbsx',19,20,-1,'Danh hiệu'.encode()]])
 title='InterfaceFolder/Agname/Agname.lua'
 # Reference paths use InterfaceFolder; staged overlays use Interface.
 lua=Path(__file__).with_name('community_ui').joinpath('Agname.lua').read_text(encoding='utf8')
 files[title]=lua
 rel='InterfaceFolder/Agname/Agname.layout.xml';s=source(rel)
 tree=ET.fromstring(s);window=next(w for w in tree.iter('Window')if w.get('Name')=='Agname_ListContent')
 window.set('Type','TLBB_ListBoxCommon')
 for e in window.findall('Event'):window.remove(e)
 ET.SubElement(window,'Event',{'Name':'ListSelectionAccepted','Function':'AgnameFrame_ListContentItemClick()'})
 # Confirm the actual listbox event from the synthesis window.
 window.find('Event').set('Name','ItemSelectionChanged')
 windows={w.get('Name'):w for w in tree.iter('Window')}
 def setprop(name,key,value):
  w=windows[name];p=w.find(f"Property[@Name='{key}']")
  if p is None:p=ET.SubElement(w,'Property',Name=key)
  p.set('Value',value)
 setprop('Agname_Frame','UnifiedSize','{{0,616},{0,520}}')
 setprop('Agname_Frame','UnifiedPosition','{{0.5,-308},{0.5,-260}}')
 for name,x,y,width,height in [
  ('Agname_Frame_MainLace',1,20,599,435),('Agname_Frame_FenYeWindow1',0,0,599,430),
  ('Agname_ListContent_Lace',3,5,200,425),('Agname_Prize_Image',205,5,390,65),
  ('Agname_PlayerTitle',10,10,288,44),('Agname_Yulanxianshi',308,22,76,22),
  ('Agname_Chenhaoshuxing',205,75,390,132),('Agname_BK',205,215,390,214),
  ('Agname_Currently_Title1',6,8,96,22),('Agname_Info1_Youxiaoqi',104,8,278,22),
  ('Agname_Currently_Title2',6,36,96,22),('Agname_Info1_Yueli',104,36,278,22),
  ('Agname_Currently_Title3',6,66,96,22),('Agname_FinishCondition',104,66,278,66),
  ('Agname_Currently_Title5',6,140,96,22),('Agname_Dachengtiaojian',104,140,278,66)]:
  setprop(name,'UnifiedPosition','{{0,%s},{0,%s}}'%(x,y))
  setprop(name,'UnifiedSize','{{0,%s},{0,%s}}'%(width,height))
 windows['Agname_PlayerTitle'].set('Type','TLBB_SimpleText')
 setprop('Agname_PlayerTitle','HorzFormatting','WordWrapCentred')
 setprop('Agname_PlayerTitle','VertFormatting','VertCentred')
 files[rel]='<?xml version="1.0" encoding="utf-8"?>\n'+ET.tostring(tree,encoding='unicode')
 rel='InterfaceFolder/Friend/friend.lua';s=source(rel)
 s=s.replace('function Friend_PreLoad()','function Friend_PreLoad()\n    this:RegisterEvent("CYS_FRIEND_REFRESH",false);')
 # Ask for a fresh authoritative list on opening, not on every refresh event.
 s=s.replace('function Friend_OnEvent( event )','function Friend_OnEvent( event )\n    if event == "TOGLE_FRIEND" then DataPool:CysRefreshCommunity() end')
 files[rel]=s
 rel='InterfaceFolder/FriendInfo/FriendInfo.layout.xml'
 tree=ET.fromstring(source(rel));windows={w.get('Name'):w for w in tree.iter('Window')}
 def prop(name,key,value):
  w=windows[name];p=w.find(f"Property[@Name='{key}']")
  if p is None:p=ET.SubElement(w,'Property',Name=key)
  p.set('Value',value)
 def rect(name,x,y,width,height):
  for key in ['AbsolutePosition','AbsoluteSize']:
   p=windows[name].find(f"Property[@Name='{key}']")
   if p is not None:windows[name].remove(p)
  prop(name,'UnifiedPosition','{{0,%s},{0,%s}}'%(x,y))
  prop(name,'UnifiedSize','{{0,%s},{0,%s}}'%(width,height))
 prop('FriendInfo_Frame','AbsoluteSize','w:390 h:343')
 rect('FriendInfo_ID',5,0,238,20)
 rect('FriendInfo_Sheweisiliao',242,0,64,20)
 rect('FriendInfo_Name',0,22,306,23)
 rect('FriendInfo_Beizhu',0,45,306,23)
 rect('FriendInfo_Level',0,68,108,20)
 rect('FriendInfo_MenPai',112,68,264,20)
 rect('FriendInfo_FriendlyGrade',0,88,306,20)
 rect('FriendInfo_PlayerHead',322,15,48,48)
 rect('FriendInfo_PlayerHead_Frame',314,7,64,64)
 rect('FriendInfo_PlayerHead_Frame_Animate',314,7,64,64)
 prop('FriendInfo_Bk','UnifiedPosition','{{0,0},{0,110}}')
 prop('FriendInfo_Bk','UnifiedSize','{{1,-1},{1,-133}}')
 for name,x,width in [('Correspondence',1,50),('DEL',51,50),('Groupinge',101,64),('Join',165,112),('HistoryMessage',277,98)]:
  prop('FriendInfo_'+name,'UnifiedPosition','{{0,%s},{1,-20}}'%x)
  prop('FriendInfo_'+name,'AbsoluteSize','w:%s h:20'%width)
 prop('FriendInfo_HistoryMessage','Text','Lịch sử')
 files[rel]='<?xml version="1.0" encoding="utf-8"?>\n'+ET.tostring(tree,encoding='unicode')
 rel='InterfaceFolder/GameSetup/GameSetup.lua';s=source(rel)
 s += '''
-- Apply is the new Cancel baseline, as in SoundSetup / ViewSetup.
local CysGameApply = GameSetup_YingYong_Clicked
function GameSetup_YingYong_Clicked()
    CysGameApply()
    GameSetup_Save_Cur_Setup()
    local values={SystemSetup:GameGetData()}
    g_PreAlpha=tostring(values[10]);g_Track_PreAlpha=tostring(values[17])
end
'''
 files[rel]=s
 files['InterfaceFolder/GameSetup/GameSetup.lua'] += """
-- Do not offer switches whose underlying CY services are absent in this port.
-- Keep the original frame and captions; show the limitation on the control.
local CysGameUpdate=GameSetup_UpdateFrame
function GameSetup_UpdateFrame()
    CysGameUpdate()
    local pending={GameSetup_Item1,GameSetup_Item3,GameSetup_Item7,GameSetup_Item8,
      GameSetup_ChatItem,GameSetup_Item12,GameSetup_EquipCompareAttr,
      GameSetup_ClosePetPaoPao,GameSetup_FunctionBar_2,GameSetup_FunctionBar_3,
      GameSetup_HuoDongTiShi,GameSetup_cooltime,GameSetup_leverup,GameSetup_Aggregate,
      GameSetup_BugSubmit,GameSetup_FlyRide,GameSetup_AutoMount,GameSetup_Important}
    for _,ctrl in ipairs(pending) do
        ctrl:Disable()
        ctrl:SetToolTip("Tùy chọn này chưa được hỗ trợ trong bản CY hiện tại.")
    end
end
"""
 rel='InterfaceFolder/SoundSetup/SoundSetup.lua';s=source(rel)
 s+='''
local CysSoundApply = SoundSetup_YingYong_Clicked
function SoundSetup_YingYong_Clicked()
    CysSoundApply()
    SystemSetup:Lua_ViewSetupToFile()
    SoundSetup_Save_Cur_Setup()
end
'''
 files[rel]=s
 rel='InterfaceFolder/ViewSetup/ViewSetup.lua';s=source(rel)
 s=s.replace('Variable:SetVariable("View_Resoution", "", 0);','')
 s += "\nlocal CysViewApply=ViewSetup_YingYong_Clicked\nfunction ViewSetup_YingYong_Clicked() CysViewApply();ViewSetup_Save_Cur_Setup() end\n"
 s += """
local CysViewLoad=ViewSetup_OnLoad
function ViewSetup_OnLoad()
    CysViewLoad()
    local pending={ViewSetup_Item11_Control,ViewSetup_Item14_Control,ViewSetup_Item17_Control,
      ViewSetup_Item_Miwu,ViewSetup_Item_Bantou,ViewSetup_Item_Check16,
      ViewSetup_TiMo_Control,ViewSetup_Item_MARS,ViewSetup_Item_Checkfps}
    for _,ctrl in ipairs(pending) do
        ctrl:Disable()
        ctrl:SetToolTip("Tùy chọn này chưa được hỗ trợ trong bản CY hiện tại.")
    end
end
"""
 files[rel]=s
 for rel,s in files.items():
  p=LOG/'client'/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(s if isinstance(s,bytes) else s.encode('utf8'))
 (LOG/'client/manifest.json').write_text(json.dumps(list(files),indent=2))
 print('Generated',len(files),'community overlays')
if __name__=='__main__':generate()
