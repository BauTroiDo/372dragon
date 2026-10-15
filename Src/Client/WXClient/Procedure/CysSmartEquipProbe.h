#pragma once
#include "CysDualSoulsProbe.h"
#include "../Network/CysQuestNet.h"
#include "../Network/CysPiercingData.h"
namespace CysSmartEquipProbe {
struct State {int step=0,mode=0,after=0;DWORD at=0;bool init=false;float xy[2]={},x=0,z=0;const char* shot=nullptr;};
inline State& S(){static State s;return s;}
inline void Check(bool ok,const char* text){TDU_Log("CYS-SMART-EQUIP: %s %s",ok?"PASS":"FAIL",text);if(!ok)throw std::runtime_error(text);}
inline void Lua(const char* env,const char* text){auto r=CScriptSystem::GetMe()->EvaluateScript(env,text);Check(r.ok(),r.ok()?"Lua":r.error);}
inline void Go(int n){S().step=n;S().at=GetTickCount();}
inline const char* ShotName(){auto p=S().shot;S().shot=nullptr;return p;}
inline void Right(int bag,int next){char name[96];CysBagProbe::ButtonName(bag,name);CysQuickbarProbe::Center(name,S().xy);S().after=next;CysBagProbe::S().pointer(0,S().xy[0],S().xy[1]);Go(90);}
inline void Stats(int att,int def){uint32_t a=0,d=0;Check(CysQuestNet::Piercing(false,a)&&CysQuestNet::Piercing(true,d),"server piercing totals received");TDU_Log("CYS-SMART-EQUIP: stats attack=%u defence=%u expected=%d,%d",a,d,att,def);Check(a==att&&d==def,"totals follow equipped items");CysInventoryIntegrityProbe::Unique();}
inline void Equip(int point,int id){Check(CysDualSoulsProbe::Item(point)==id,"correct equipment point");}
inline bool TickImpl(){auto& s=S();if(!getenv("CYS_SMART_EQUIP_LIVE")||s.step==99)return true;
 if(!s.init){Check(getenv("CYS_BOT_ACCOUNT")&&!strcmp(getenv("CYS_BOT_ACCOUNT"),"test15"),"private test15 only");s.mode=atoi(getenv("CYS_SMART_EQUIP_LIVE"));auto m=GetModuleHandleA("UI_CEGUI.dll");auto& b=CysBagProbe::S();b.pointer=(CysUiInputBridge::SmokePointer)GetProcAddress(m,"CysUiSmokePointer");b.rect=(CysUiInputBridge::GetWindowRectUtf8)GetProcAddress(m,"CysUiGetWindowRectUtf8");b.read=(CysUiInputBridge::ReadActionButtonUtf8)GetProcAddress(m,"CysUiReadActionButtonUtf8");s.init=true;Go(s.mode==2?40:0);}
 if(GetTickCount()-s.at<900)return false;
 auto pool=CDataPool::GetMe();auto self=CObjectManager::GetMe()->GetMySelf();auto pointer=CysBagProbe::S().pointer;
 switch(s.step){
 case 0:Stats(0,0);CEventSystem::GetMe()->PushEvent(GE_TOGLE_CONTAINER);Go(1);break;
 case 1:Lua("Packet_Env","Packet_ChangeTabIndex(0)");Right(0,2);break;
 case 2:Equip(0,10102001);Stats(42,0);Right(1,3);break;
 case 3:Equip(0,10102001);Stats(0,0);Right(1,4);break;
 case 4:Stats(42,0);Right(2,5);break;
 case 5:Equip(6,10122001);Stats(84,0);Right(3,6);break;
 case 6:Equip(6,10122001);Equip(11,10122001);Check(!pool->UserBag_GetItem(3),"second ring consumes bag slot, no phantom copy");Stats(84,0);Right(4,7);break;
 case 7:Equip(6,10122001);Equip(11,10122001);Check(pool->UserBag_GetItem(4)!=nullptr,"old ring returns to source bag cell");Stats(84,0);Right(5,8);break;
 case 8:Equip(12,10123001);Stats(126,0);Right(6,9);break;
 case 9:Equip(13,10123001);Check(!pool->UserBag_GetItem(6),"second amulet has no phantom copy");Stats(126,0);Right(7,10);break;
 case 10:Equip(1,10110000);Stats(126,42);Right(8,11);break;
 case 11:Stats(126,0);Right(8,12);break;
 case 12:Stats(126,42);CysDualSoulsProbe::Grant(10156901);Go(13);break;
 case 13:CysDualSoulsProbe::Grant(10156902);Go(14);break;
 case 14:{int slot=-1;for(int i=0;i<100;++i){auto p=pool->UserBag_GetItem(i);if(p&&p->GetIdTable()==10156901)slot=i;}Check(slot>=0,"support in bag");Right(slot,15);break;}
 case 15:Equip(18,10156901);{int slot=-1;for(int i=0;i<100;++i){auto p=pool->UserBag_GetItem(i);if(p&&p->GetIdTable()==10156902)slot=i;}Check(slot>=0,"assault in bag");Right(slot,16);break;}
 case 16:Equip(39,10156902);Stats(126,42);Lua("CysEquipCraft_Env","CysEquipCraftOpen(1)");Go(17);break;
 case 17:Check(CysBagProbe::Shown("CysEquipCraft"),"workshop open");Right(9,18);break;
 case 18:Lua("CysEquipCraft_Env","local m,a=CysEquipCraftData();assert(a==9);this:Hide()");Check(pool->UserBag_GetItem(9)!=nullptr,"workshop selection preserves bag item");CEventSystem::GetMe()->PushEvent(GE_UI_COMMAND,1002);Go(19);break;
 case 19:Check(CysBagProbe::Shown("EquipStrengthen"),"forge opened through existing UI command");Right(9,20);break;
 case 20:Lua("EquipStrengthen_Env","assert(CysForge_State.equip==9);assert(CysForge_State.phase~='run');this:Hide()");Check(pool->UserBag_GetItem(9)!=nullptr,"forge selection does not consume or equip");Lua("Packet_Env","this:Hide()");CEventSystem::GetMe()->PushEvent(GE_OPEN_EQUIP);Go(30);break;
 case 30:Lua("SelfEquip_Env","SelfEquip_SetStateTooltip();assert(Player:GetData('ENCHANCEATT')==126);assert(Player:GetData('ENCHANCEDEF')==42)");CysQuickbarProbe::Center("SelfEquip_HurtFastness",s.xy);pointer(0,s.xy[0],s.xy[1]);Go(31);break;
 case 31:s.shot="smart-equip-piercing";Go(32);break;
 case 32:CysQuickbarProbe::Center("SelfEquip_DefenceFastness",s.xy);pointer(0,s.xy[0],s.xy[1]);Go(33);break;
 case 33:s.shot="smart-equip-resistance";Go(34);break;
 case 34:CysQuickbarProbe::Center("SelfEquip_ShenDing_Icon",s.xy);pointer(0,s.xy[0],s.xy[1]);Go(35);break;
 case 35:s.shot="smart-equip-shending";Lua("SelfEquip_Env","local i,f,l,p=Player:GetData('Attack_IFTPValue');assert(i==6 and f==4 and l==0 and p==0)");Go(36);break;
 case 36:CysAccel::SetChatting(false);CysQuickbarProbe::Key(KC_ESCAPE);Go(37);break;
 case 37:Check(!CysBagProbe::Shown("SelfEquip"),"Esc closes equipment UI");s.x=self->GetPosition().x;s.z=self->GetPosition().z;Check(CysWorldReplay::LiveGroundClick(7),"movement request after UI");Go(38);break;
 case 38:if(GetTickCount()-s.at<3500)return false;Check(std::hypot(self->GetPosition().x-s.x,self->GetPosition().z-s.z)>0.5f,"movement after UI");if(s.mode==1){CysDualSoulsProbe::GM(2,507,3);Go(45);break;}TDU_Log("CYS-SMART-EQUIP: RELOGIN errors=0");Go(99);return true;
 case 40:Equip(0,10102001);Equip(1,10110000);Equip(6,10122001);Equip(11,10122001);Equip(12,10123001);Equip(13,10123001);Equip(18,10156901);Equip(39,10156902);Stats(126,42);CEventSystem::GetMe()->PushEvent(GE_OPEN_EQUIP);Go(30);break;
 case 45:{unsigned ids[64]={};int target=-1;auto pos=self->GetPosition();auto n=CysModernGame::ObjectsNear(pos.x,pos.z,18,ids,64);
  for(unsigned i=0;i<n;++i){auto obj=(CObject*)CObjectManager::GetMe()->FindServerObject(ids[i]);if(obj&&obj!=(CObject*)self&&CGameProcedure::s_pGameInterface->GetCampType(self,obj)==RELATION_ENEMY){target=ids[i];break;}}
  if(target<0){if(GetTickCount()-s.at>=20000)Check(false,"enemy spawn timed out");return false;}Check(true,"enemy for real piercing combat");CObjectManager::GetMe()->SetMainTarget(target);
  int level=CysSkillNet::SkillLevel(371);auto a=CActionSystem::GetMe()->GetAction_SkillID(37100+level);Check(a!=nullptr,"Wudang normal attack learned");Lua("MainMenuBar_Env","MainmenuBar_PageOne()");CActionSystem::GetMe()->MainMenuBar_Set(0,a->GetID());CysAccel::SetChatting(false);CysQuickbarProbe::Key(KC_F1);Go(46);break;}
 case 46:if(GetTickCount()-s.at<6500)return false;Check(CysPiercingData::DamageBoards()>0,"actual piercing floating number rendered");s.shot="smart-equip-combat";CysDualSoulsProbe::GM(3);Go(47);break;
 case 47:TDU_Log("CYS-SMART-EQUIP: RESULT errors=0");Go(99);return true;
 case 90:pointer(3,s.xy[0],s.xy[1]);Go(91);break;
 case 91:pointer(4,s.xy[0],s.xy[1]);Go(s.after);break;
 }
 return false;
}
inline bool Tick(){try{return TickImpl();}catch(const std::exception& e){TDU_Log("CYS-SMART-EQUIP: FAIL step=%d %s",S().step,e.what());S().step=99;return true;}}
}
