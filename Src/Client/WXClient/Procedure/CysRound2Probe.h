#pragma once
#include "CysQuickbarProbe.h"
#include "CysInventoryIntegrityProbe.h"
namespace CysRound2Probe {
struct State {int mode=-1,step=0;DWORD at=0;float pos[2]={};unsigned __int64 guid=0;std::string bag;const char* shot=nullptr;};
inline State& S(){static State s;return s;}
inline void Check(bool ok,const char* label){if(!ok){TDU_Log("CYS-ROUND2-PROBE: FAIL %s",label);throw std::runtime_error(label);}TDU_Log("CYS-ROUND2-PROBE: PASS %s",label);}
inline void Go(int n){S().step=n;S().at=GetTickCount();}
inline void Lua(const char* env,const char* code){auto r=CScriptSystem::GetMe()->EvaluateScript(env,code);Check(r.ok(),r.error);}
inline const char* ShotName(){auto p=S().shot;S().shot=nullptr;return p;}
inline bool TickImpl(){auto& s=S();
 if(s.mode<0){const char* e=getenv("CYS_ROUND2_LIVE");s.mode=e?atoi(e):0;if(!s.mode)return true;
  Check(getenv("CYS_BOT_ACCOUNT")&&!strcmp(getenv("CYS_BOT_ACCOUNT"),s.mode==4?"test00":"test15"),"owned fixture account");
  auto m=GetModuleHandleA("UI_CEGUI.dll");auto& b=CysBagProbe::S();
  b.pointer=(CysUiInputBridge::SmokePointer)GetProcAddress(m,"CysUiSmokePointer");
  b.rect=(CysUiInputBridge::GetWindowRectUtf8)GetProcAddress(m,"CysUiGetWindowRectUtf8");
  b.read=(CysUiInputBridge::ReadActionButtonUtf8)GetProcAddress(m,"CysUiReadActionButtonUtf8");
  Check(b.pointer&&b.rect&&b.read,"UI bridge");Go(s.mode==13?130:s.mode==10?100:s.mode==11?110:s.mode==12?120:s.mode==9?80:s.mode==3?30:s.mode>=7?70:s.mode==6?60:s.mode>=4?40:0);
 }
 if(!s.mode||s.step==99)return true;
 auto self=CObjectManager::GetMe()->GetMySelf();auto actions=CActionSystem::GetMe();auto& b=CysBagProbe::S();
 if(GetTickCount()-s.at<700)return false;
 switch(s.step){
 case 100:
  Check(self->GetCharacterData()->Get_Level()==199,"level199 fixture");
  Lua("SelfEquip_Env","assert(Player:GetDefineHumanMaxLevel()==200);assert(Lua_GetMyMaxLevelLimit()==200)");
  CGameInterface::GetMe()->Player_AskLevelUp();Go(101);break;
 case 101:
  if(self->GetCharacterData()->Get_Level()!=200){if(GetTickCount()-s.at>=10000)Check(false,"199 to200 timeout");break;}
  CGameInterface::GetMe()->Player_AskLevelUp();Go(102);break;
 case 102:
  Check(self->GetCharacterData()->Get_Level()==200,"200 cap rejects201");
  CEventSystem::GetMe()->PushEvent(GE_ACCELERATE_KEYSEND,"acc_selfequip");Go(103);break;
 case 103:
  s.shot="progression-level200-alt-transparent";
  Lua("Operation_Env","Operation_GmTool_Clicked()");Go(104);break;
 case 104:
  Check(CysBagProbe::Shown("GmTool"),"test15 GM allowed");
  CysQuickbarProbe::Key(KC_ESCAPE);Go(105);break;
 case 105:
  s.pos[0]=self->GetPosition().x;s.pos[1]=self->GetPosition().z;
  Check(CysWorldReplay::LiveGroundClick(7),"movement input at200");Go(106);break;
 case 106:
  if(GetTickCount()-s.at<3000)break;
  Check(std::hypot(self->GetPosition().x-s.pos[0],self->GetPosition().z-s.pos[1])>0.5f,"level200 movement");
  TDU_Log("CYS-ROUND2-PROBE: RESULT level200 cap GM test15 movement errors=0");s.step=99;return true;
 case 110:
  Lua("CommonSkill_Env","PushEvent('TRIGGER_ZIDONGZHANDOU','config')");Go(111);break;
 case 111:
  Check(CysBagProbe::Shown("AutoAttackSkill"),"auto config opens");s.guid=self->GetCharacterData()->Get_Exp();
  Check(CysBagProbe::Quantity(30001001)==3,"auto potion starts with three owned items");
  Lua("AutoAttackSkill_Env","assert(BattleAssist:IsWorking()=='false');assert(PlayerPackage:CountAvailableItemByIDTable(30001001)==3);assert(PlayerPackage:GetItemName(30001001)~='');BattleAssist:Farm_SetCfgData_MaxNum(0,0,200);AutoAttackSkill_CallCb(1,'onSetPotionOk',1)");Go(112);break;
 case 112:
  Lua("AutoAttackSkill_Env","local a,b,c=BattleAssist:Farm_GetCfgData_MaxNum();assert(c==200);assert(BattleAssist:AskIsNeiGuaOpen('FB')==false);AutoAttackSkill_OnStartClick()");Go(113);break;
 case 113:
  if(GetTickCount()-s.at<2500)break;
  Lua("AutoAttackSkill_Env","assert(BattleAssist:IsWorking()=='true')");s.shot="progression-auto-active";Go(114);break;
 case 114:
  if(self->GetCharacterData()->Get_Exp()<=s.guid){if(GetTickCount()-s.at>=55000)Check(false,"automatic combat EXP timeout");break;}
  TDU_Log("CYS-ROUND2-PROBE: PASS automatic kill exp before=%llu after=%lld",s.guid,self->GetCharacterData()->Get_Exp());
  Check(CysBagProbe::Quantity(30001001)<3&&CysBagProbe::Quantity(30001001)>=0,"automatic potion consumes existing inventory");CysInventoryIntegrityProbe::Unique();
  Lua("AutoAttackSkill_Env","AutoAttackSkill_OnStartClick()");Go(115);break;
 case 115:
  Lua("AutoAttackSkill_Env","assert(BattleAssist:IsWorking()=='false')");
  Lua("AutoAttackSkill_Env","AutoAttackSkill_OnStartClick()");Go(116);break;
 case 116:
  if(GetTickCount()-s.at<2000)break;
  Lua("AutoAttackSkill_Env","assert(BattleAssist:IsWorking()=='true')");
  CysQuickbarProbe::Key(KC_ESCAPE);CysAccel::SetChatting(false);
  Check(CysWorldReplay::LiveGroundClick(7),"manual movement cancels auto input");Go(117);break;
 case 117:
  if(GetTickCount()-s.at<2500)break;
  Lua("AutoAttackSkill_Env","assert(BattleAssist:IsWorking()=='false')");
  TDU_Log("CYS-ROUND2-PROBE: RESULT automatic battle kill EXP stop manual movement errors=0");s.step=99;return true;
 case 120:
  Check(self->GetCharacterData()->Get_Level()==200,"level200 survives relog");
  TDU_Log("CYS-ROUND2-PROBE: RESULT level200 relog errors=0");s.step=99;return true;
 case 130:
  Check(self->GetCharacterData()->Get_Exp()==3000000000LL,"EXP exceeds signed32 without wrap");
  Lua("MainMenuBar_Env","assert(Player:GetData('EXP')==3000000000);local e,n=Player:GetExp();assert(e==3000000000 and n>0)");
  Lua("AutoAttackSkill_Env","local a,b,c=BattleAssist:Farm_GetCfgData_MaxNum();assert(c==200);assert(BattleAssist:IsWorking()=='false')");
  s.shot="progression-transparent-alt-populated";
  TDU_Log("CYS-ROUND2-PROBE: RESULT EXP3b positive auto settings persist stopped on relog errors=0");s.step=99;return true;
 case 80:
  CEventSystem::GetMe()->PushEvent(GE_TOGLE_COMMONSKILL_PAGE);Go(81);break;
 case 81:
  Lua("CommonSkill_Env","CommonSkill_Zhenfa_Page_Switch()");Go(82);break;
 case 82:
  Check(CysBagProbe::Shown("ZhenfaSkill"),"formation tab opens");
  Lua("ZhenfaSkill_Env",u8"ZhenfaSkill_SetSelectSkillInfo(1);assert(ZhenfaSkill_Info_Name:GetText()~='');assert(ZhenfaSkill_Explain:GetText()~='');assert(ZhenfaSkill_Info_Level:GetText()=='Chưa học')");
  s.shot="round2-formation";Go(83);break;
 case 83:
  CEventSystem::GetMe()->PushEvent(GE_TOGLE_COMMONSKILL_PAGE);Go(84);break;
 case 84:
  Lua("CommonSkill_Env","CommonSkill_AutoAttack_Page_Switch(5)");Go(85);break;
 case 85:
  Check(CysBagProbe::Shown("AutoAttackSkill"),"battle tab opens at level81");
  s.shot="round2-battle";Go(86);break;
 case 86:
  CEventSystem::GetMe()->PushEvent(GE_TOGLE_COMMONSKILL_PAGE);Go(87);break;
 case 87:
  Lua("CommonSkill_Env","CommonSkill_ZongMen_Page_Switch(6)");Go(88);break;
 case 88:
  Check(CysBagProbe::Shown("CommonSkill")&&!CysBagProbe::Shown("ZongMenSkill"),"talent below120 preserves current page");
  CEventSystem::GetMe()->PushEvent(GE_CLOSE_SKILL_BOOK);
  TDU_Log("CYS-ROUND2-PROBE: RESULT skill tabs formation/battle and talent level gate errors=0");s.step=99;return true;
 case 0:
  Check(CysInventoryNet::BagSize(0)==100&&CysInventoryNet::BagSize(1)==100,"both bags 100 server slots");
  Lua("MainMenuBar_Env","local e,n=Player:GetExp(); assert(type(e)=='number' and type(n)=='number' and n>0); assert(e==Player:GetData('EXP') and n==Player:GetData('NEEDEXP'))");
  {float f[4]={},alt[4]={};Check(b.rect("Button_Action1",f)==1&&b.rect("MainMenuBar_2_Button_Action1",alt)==1,"both quickbars visible by default");
   Check(fabs(f[0]-alt[0])<3&&alt[1]+alt[3]<=f[1],"Alt row aligned above F row without overlap");}
  CEventSystem::GetMe()->PushEvent(GE_TOGLE_COMMONSKILL_PAGE);Go(1);break;
 case 1:{
  bool empty=false;int count=0;
  for(int i=1;i<=20;++i){char name[64];_snprintf(name,64,"CommonSkill_Skill%d",i);int v[4]={};Check(b.read(name,v)==1,"common cell readable");
   auto a=actions->GetAction(v[0]);if(v[1]||!a){empty=true;}else{Check(!empty,"common skills contain no initial/interior holes");++count;}}
  Check(count>0,"common skills populated");s.shot="round2-common-and-bars";Go(2);break;}
 case 2:
  CEventSystem::GetMe()->PushEvent(GE_CLOSE_SKILL_BOOK);
  if(!CysBagProbe::Shown("Packet"))CEventSystem::GetMe()->PushEvent(GE_TOGLE_CONTAINER);Go(3);break;
 case 3:{
  char name[96];float r[4];CysBagProbe::ButtonName(99,name);Check(b.rect(name,r)==1,"100th bag cell visible");
  auto item=CDataPool::GetMe()->UserBag_GetItem(18);Check(item!=nullptr,"enhanced item fixture exists");
  auto action=actions->GetAction_ItemID(item->GetID());Check(action!=nullptr,"enhanced item action exists");
  action->NotifyTooltipsShow(200,160,234,194);Go(4);break;}
 case 4:
  Lua("SuperTooltip_Env",u8"assert(string.find(SuperTooltips:GetTitle(), '(+2)',1,true)); assert(string.find(SuperTooltips:GetPropertys(),'Cường hoá +2',1,true))");
  s.shot="round2-enhancement-tooltip-bag100";Go(5);break;
 case 5:
  {auto item=CDataPool::GetMe()->UserBag_GetItem(18);auto action=actions->GetAction_ItemID(item->GetID());action->NotifyTooltipsHide();}
  CysQuickbarProbe::Key(KC_ESCAPE);
  s.pos[0]=self->GetPosition().x;s.pos[1]=self->GetPosition().z;
  CysAccel::SetChatting(false);Check(CysWorldReplay::LiveGroundClick(7),"ground click");Go(6);break;
 case 6:
  if(GetTickCount()-s.at<3000)break;
  Check(fabs(self->GetPosition().x-s.pos[0])+fabs(self->GetPosition().z-s.pos[1])>0.5f,"player still moves after shared UI");
  TDU_Log("CYS-ROUND2-PROBE: RESULT bags100 common compact Alt/F tooltip+2 EXP movement errors=0");
  if(s.mode==2){Go(7);break;}s.step=99;return true;
 case 7:
  Lua("MainMenuBar_Env","Bank:AskTemBankList()");Go(8);break;
 case 8:{
  float r[4];Check(b.rect("TemBank_Item119",r)==1,"temporary bag 120th cell visible");
  Lua("Packet_Temporary_Env","assert(Bank:GetTemBankItemNum()==0)");
  auto item=CDataPool::GetMe()->UserBag_GetItem(18);Check(item!=nullptr,"deposit source");
  auto a=actions->GetAction_ItemID(item->GetID());a->NotifyDragDropDragged(FALSE,"CYSTEMP0","");Go(9);break;}
 case 9:
  Check(CDataPool::GetMe()->UserBag_GetItem(18)==nullptr,"deposit acknowledged removed source");
  Lua("Packet_Temporary_Env","assert(Bank:GetTemBankItemNum()==1);local a=Bank:EnumTemItem(0);assert(a:GetID()>0)");
  s.shot="round2-tembank-equipment-stored";Go(10);break;
 case 10:
  Lua("Packet_Temporary_Env","CysTemBank_Take(0)");Go(11);break;
 case 11:{
  auto item=CDataPool::GetMe()->UserBag_GetItem(0);Check(item&&item->GetIdTable()==10106000,"withdraw acknowledged real bag item");
  USHORT world=0,server=0;UINT serial=0;item->GetGUID(world,server,serial);
  Check(world==254&&server==254&&serial==2309202601U,"roundtrip exact equipment GUID");
  auto a=actions->GetAction_ItemID(item->GetID());a->NotifyTooltipsShow(150,100,184,134);Go(12);break;}
 case 12:
  Lua("SuperTooltip_Env",u8"assert(string.find(SuperTooltips:GetTitle(), '(+2)',1,true))");
  {auto item=CDataPool::GetMe()->UserBag_GetItem(0);auto a=actions->GetAction_ItemID(item->GetID());a->NotifyTooltipsHide();a->NotifyDragDropDragged(FALSE,"CYSTEMP0","");}Go(13);break;
 case 13:
  Check(CDataPool::GetMe()->UserBag_GetItem(0)==nullptr,"persistent deposit source removed");
  Lua("Packet_Temporary_Env","assert(Bank:GetTemBankItemNum()==1)");
  TDU_Log("CYS-ROUND2-PROBE: RESULT temporary bag roundtrip exact GUID +2 and deposited for relog errors=0");s.step=99;return true;
 case 30:
  Lua("MainMenuBar_Env","Bank:AskTemBankList()");Go(31);break;
 case 31:
  Lua("Packet_Temporary_Env","assert(Bank:GetTemBankItemNum()==1);local a=Bank:EnumTemItem(0);assert(a:GetDefineID()==10106000);CysTemBank_Take(0)");Go(32);break;
 case 32:{
  auto item=CDataPool::GetMe()->UserBag_GetItem(0);Check(item&&item->GetIdTable()==10106000,"stored item survives relog");
  USHORT w=0,v=0;UINT serial=0;item->GetGUID(w,v,serial);Check(serial==2309202601U,"relogged GUID preserved");
  auto a=actions->GetAction_ItemID(item->GetID());a->NotifyTooltipsShow(150,100,184,134);Go(33);break;}
 case 33:
  Lua("SuperTooltip_Env",u8"assert(string.find(SuperTooltips:GetTitle(), '(+2)',1,true))");
  TDU_Log("CYS-ROUND2-PROBE: RESULT temporary bag persistence GUID and +2 errors=0");s.step=99;return true;
 case 40:
  CysQuickbarProbe::Key(KC_ESCAPE);Go(41);break;
 case 41:
  {float r[4]={};Check(b.rect("Operation_GmTool",r)==1,"GM button visible");s.pos[0]=r[0]+r[2]/2;s.pos[1]=r[1]+r[3]/2;b.pointer(0,s.pos[0],s.pos[1]);}Go(46);break;
 case 46:
  Check(b.pointer(1,s.pos[0],s.pos[1])==1,"GM button mouse down");Go(47);break;
 case 47:
  Check(b.pointer(2,s.pos[0],s.pos[1])==1,"GM button mouse up");Go(42);break;
 case 42:
  if(GetTickCount()-s.at<1500)break;
  if(s.mode==5){Check(!CysBagProbe::Shown("GmTool"),"ordinary account denied GM");TDU_Log("CYS-ROUND2-PROBE: RESULT GM denied ordinary account errors=0");s.step=99;return true;}
  Check(CysBagProbe::Shown("GmTool"),"authorized GM window opened by server");
  Lua("GmTool_Env",u8"GmTool_SelectModule('item');GmTool_SelectItemMode('equip');GmTool_ItemSearch:SetText('Lượng Ngân');GmTool_SearchItems();assert(string.find(GmTool_ItemName1:GetText(),'Lượng Ngân',1,true))");Go(43);break;
 case 43:{
  int values[4]={};Check(b.read("GmTool_ItemIcon1",values)==1&&values[0]>0,"GM search result has native item icon");
  s.shot="round2-gm-equipment-search";Go(44);break;}
 case 44:
  Lua("GmTool_Env",u8"GmTool_SelectModule('scene');GmTool_SceneSearch:SetText('Vô Lượng');GmTool_SearchScenes();assert(string.find(GmTool_SceneResult1:GetText(),'Vô Lượng',1,true));assert(string.find(GmTool_SceneResult1:GetText(),'[6]',1,true))");
  s.shot="round2-gm-scenes";Go(45);break;
 case 45:
  CysQuickbarProbe::Key(KC_ESCAPE);Go(48);break;
 case 48:
  Check(!CysBagProbe::Shown("GmTool"),"GM closes with Esc");
  TDU_Log("CYS-ROUND2-PROBE: RESULT GM authorized item and scene search errors=0");s.step=99;return true;
 case 60:
  Check(CysModernGame::CurrentSceneId()==0,"portal starts in Luoyang");
  CGameInterface::GetMe()->Player_MoveTo(fVector2(85,257));Go(61);break;
 case 61:
  if(!CysModernGame::IsInWorld()||CysModernGame::CurrentSceneId()!=8){Check(GetTickCount()-s.at<45000,"Luoyang to Dunhuang timeout");break;}
  TDU_Log("CYS-ROUND2-PROBE: PASS real walking portal Luoyang to Dunhuang");s.shot="round2-portal-dunhuang";Go(62);break;
 case 62:
  if(GetTickCount()-s.at<4000)break;
  Check(CysModernGame::CurrentSceneId()==8,"portal arrival does not bounce back");
  CGameInterface::GetMe()->Player_MoveTo(fVector2(284,146));Go(63);break;
 case 63:
  if(!CysModernGame::IsInWorld()||CysModernGame::CurrentSceneId()!=0){Check(GetTickCount()-s.at<45000,"Dunhuang to Luoyang timeout");break;}
  TDU_Log("CYS-ROUND2-PROBE: PASS real walking return portal Dunhuang to Luoyang");Go(64);break;
 case 64:
  if(GetTickCount()-s.at<4000)break;
  Check(CysModernGame::CurrentSceneId()==0,"return arrival stable");
  s.pos[0]=self->GetPosition().x;s.pos[1]=self->GetPosition().z;Check(CysWorldReplay::LiveGroundClick(7),"ground click after both portals");Go(65);break;
 case 65:
  if(GetTickCount()-s.at<3000)break;
  Check(std::hypot(self->GetPosition().x-s.pos[0],self->GetPosition().z-s.pos[1])>0.5f,"movement after both portals");
  TDU_Log("CYS-ROUND2-PROBE: RESULT two real portals stable arrivals and movement errors=0");s.step=99;return true;
 case 70:
  Check(CysInventoryNet::BagSize(0)==100&&CysInventoryNet::BagSize(1)==100,"live bag sizes 100/100");
  if(!CysBagProbe::Shown("Packet"))CEventSystem::GetMe()->PushEvent(GE_TOGLE_CONTAINER);Go(s.mode==8?78:71);break;
 case 71:{
  auto p=CDataPool::GetMe()->UserBag_GetItem(18);auto q=CDataPool::GetMe()->UserBag_GetItem(19);
  Check(p&&q&&p->GetNumber()==249&&q->GetNumber()==1,"stack249 plus1 fixture");s.guid=p->GetGUID();
  CysInventoryIntegrityProbe::Swap(19,18);CysInventoryIntegrityProbe::Swap(19,18);Go(72);break;}
 case 72:{
  auto p=CDataPool::GetMe()->UserBag_GetItem(18);
  Check(p&&p->GetNumber()==250&&p->GetGUID()==s.guid&&!CDataPool::GetMe()->UserBag_GetItem(19),"merge and repeated request conserve250 and GUID");
  CysInventoryIntegrityProbe::Unique();CysInventoryIntegrityProbe::Swap(18,99);Go(73);break;}
 case 73:{
  auto p=CDataPool::GetMe()->UserBag_GetItem(99);Check(p&&p->GetGUID()==s.guid&&p->GetNumber()==250,"slot100 holds250 with exact GUID");
  s.bag=CysInventoryIntegrityProbe::Fingerprint();CysInventoryIntegrityProbe::Swap(99,100);Go(74);break;}
 case 74:
  Check(s.bag==CysInventoryIntegrityProbe::Fingerprint(),"cross-region swap rejected without loss or duplication");
  CDataPool::GetMe()->Split_SetItemConta(tObject_Item::IO_MYSELF_PACKET);CDataPool::GetMe()->Split_SetItemPos(99);
  Lua("Packet_Env","PlayerPackage:SplitItem(100)");Go(75);break;
 case 75:{
  auto p=CDataPool::GetMe()->UserBag_GetItem(99);auto q=CDataPool::GetMe()->UserBag_GetItem(0);
  Check(p&&q&&p->GetNumber()==150&&q->GetNumber()==100&&p->GetGUID()!=q->GetGUID(),"split100 leaves150 with distinct GUIDs");
  CysInventoryIntegrityProbe::Unique();Check(CysBagProbe::Quantity(30001001)==250,"split conserves250");
  CysInventoryIntegrityProbe::Swap(0,99);CysInventoryIntegrityProbe::Swap(0,99);Go(76);break;}
 case 76:{
  auto p=CDataPool::GetMe()->UserBag_GetItem(99);Check(p&&p->GetNumber()==250&&p->GetGUID()==s.guid&&!CDataPool::GetMe()->UserBag_GetItem(0),"remerge and replay conserve250 original GUID");
  CysInventoryIntegrityProbe::Unique();s.shot="round2-stack250-slot100";
  TDU_Log("CYS-ROUND2-PROBE: RESULT stack250 split merge replay cross-region slot100 errors=0");s.step=99;return true;}
 case 78:{
  auto p=CDataPool::GetMe()->UserBag_GetItem(99);Check(p&&p->GetNumber()==250&&p->GetIdTable()==30001001,"relogged stack250 in slot100");
  Check(CysBagProbe::Quantity(30001001)==250,"relogged total250");CysInventoryIntegrityProbe::Unique();
  char name[96];float r[4];CysBagProbe::ButtonName(99,name);Check(b.rect(name,r)==1,"relogged100th cell visible");
  s.shot="round2-stack250-relogged";TDU_Log("CYS-ROUND2-PROBE: RESULT stack250 persists after relog errors=0");s.step=99;return true;}
 }
 return false;
}
inline bool Tick(){try{return TickImpl();}catch(const std::exception& e){TDU_Log("CYS-ROUND2-PROBE: FAIL step=%d %s",S().step,e.what());if(S().mode==4)CScriptSystem::GetMe()->EvaluateScript("GmTool_Env","this:Hide()");S().step=99;return true;}}
}
