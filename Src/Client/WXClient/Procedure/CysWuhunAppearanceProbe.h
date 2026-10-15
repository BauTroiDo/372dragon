#pragma once
#include "CysWuhunPreviewProbe.h"
#include "CysEquipCraftProbe.h"
#include "../DataPool/CysWuhunData.h"
namespace CysWuhunAppearanceProbe {
struct State {int step=0,sweep=0;DWORD at=0;bool init=false;float x=0,z=0;std::string shot;};
inline State& S(){static State s;return s;}
inline const char* ShotName(){static std::string name;name=S().shot;S().shot.clear();return name.empty()?nullptr:name.c_str();}
inline void Check(bool ok,const char* msg){TDU_Log("CYS-WUHUN-APPEARANCE: %s %s",ok?"PASS":"FAIL",msg);if(!ok)throw std::runtime_error(msg);}
inline void Lua(const char* code){auto r=CScriptSystem::GetMe()->EvaluateScript("Wuhun_Env",code);Check(r.ok(),r.ok()?"Lua action":r.error);}
inline void Click(const char* name){CysEquipCraftProbe::Click(name);}
inline int Material(int id){int count=0;for(int i=100;i<200;++i){auto t=CDataPool::GetMe()->UserBag_GetItem(i);if(t&&t->GetIdTable()==id)count+=t->GetNumber();}return count;}
inline void Attached(CObject_Character* who,int visual){Check(who&&who->GetRenderInterface(),"actor exists");STRING got;who->GetRenderInterface()->Actor_GetObjectProperty("KFSObj",got);
 auto row=CysWuhunData::Find(visual);Check(got==(row?row->object:""),"KFSObj matches server appearance");
 TDU_Log("CYS-WUHUN-APPEARANCE: attached fake=%d visual=%d file=%s",who->GetFakeObjectFlag(),visual,got.c_str());}
inline bool TickImpl(){auto& s=S();if(!getenv("CYS_WUHUN_APPEARANCE_LIVE")||s.step==99)return true;
 if(GetTickCount()-s.at<1700)return false;
 if(!s.init){Check(getenv("CYS_BOT_ACCOUNT")&&!strcmp(getenv("CYS_BOT_ACCOUNT"),"test15"),"private test15 only");auto m=GetModuleHandleA("UI_CEGUI.dll");auto& b=CysBagProbe::S();b.pointer=(CysUiInputBridge::SmokePointer)GetProcAddress(m,"CysUiSmokePointer");b.rect=(CysUiInputBridge::GetWindowRectUtf8)GetProcAddress(m,"CysUiGetWindowRectUtf8");s.init=true;if(atoi(getenv("CYS_WUHUN_APPEARANCE_LIVE"))==2)s.step=30;}
 auto self=CObjectManager::GetMe()->GetMySelf();auto pool=CDataPool::GetMe();
 switch(s.step){
 case 0:Attached(self,699);s.shot="wuhun-world-base";CEventSystem::GetMe()->PushEvent(GE_OPEN_EQUIP);break;
 case 1:Attached(CysWuhunPreviewProbe::Avatar("Player"),699);s.shot="wuhun-selfequip-base";s.step=49;s.at=GetTickCount();return false;
 case 49:CysWuhunPreviewProbe::Lua("SelfEquip_Env","this:Hide();ToggleWuhunPage()");s.step=2;s.at=GetTickCount();return false;
 case 2:Click("CysHuan_Open");break;
 case 3:Lua("local n,l,g,q,k,y,v,r=CysWuhunData(1);assert(l==0 and r==1)");s.shot="wuhun-huan-catalog";Click("CysHuan_Activate");break;
 case 4:Click("CysHuan_Yes");break;
 case 5:Lua("local n,l=CysWuhunData(1);assert(l==1)");Check(Material(20800001)==50,"activation consumes exactly 50 materials");Click("CysHuan_Qian");break;
 case 6:Attached(self,744);Attached(CysWuhunPreviewProbe::Avatar("Player"),744);s.shot="wuhun-huan-qian";Click("CysHuan_Upgrade");break;
 case 7:Click("CysHuan_Yes");break;
 case 8:Lua("local n,l,g=CysWuhunData(1);assert(l==1 and g==1)");Check(Material(20800013)==98,"upgrade consumes exactly two materials");Click("CysHuan_Item3");break;
 case 9:Click("CysHuan_Activate");break;
 case 10:Click("CysHuan_Yes");break;
 case 11:Check(Material(20800005)==50,"second soul activation cost");Click("CysHuan_Kun");break;
 case 12:Lua("local n,l,g,q,k=CysWuhunData(3);assert(q==1 and k==3)");Click("CysHuan_Switch");break;
 case 13:Attached(self,750);s.shot="wuhun-huan-kun";Click("Wuhun_Show");break;
 case 14:Attached(self,0);Attached(CysWuhunPreviewProbe::Avatar("Player"),0);Lua("assert(SystemSetup:GetShowWuhunObj()==0)");Click("Wuhun_Show");break;
 case 15:Attached(self,750);Lua("Wuhun_Equip_Clicked(2)");break;
 case 16:Check(!pool->UserEquip_GetItem((HUMAN_EQUIP)18),"server unequips soul");Attached(self,0);Attached(CysWuhunPreviewProbe::Avatar("Player"),0);
  {int slot=-1;for(int i=0;i<100;++i){auto t=pool->UserBag_GetItem(i);if(t&&t->GetIdTable()==10156001)slot=i;}Check(slot>=0,"soul remains in bag exactly once");CGameProcedure::s_pGameInterface->PacketItem_UserEquip(slot);}break;
 case 17:Attached(self,750);Check(pool->UserEquip_GetItem((HUMAN_EQUIP)18)!=nullptr,"server reequips soul");
  Lua("CysHuanClose();this:Hide()");CEventSystem::GetMe()->PushEvent(GE_OPEN_EQUIP);break;
 case 18:Attached(CysWuhunPreviewProbe::Avatar("Player"),750);s.shot="wuhun-selfequip-huan";break;
 case 19:CysWuhunPreviewProbe::Lua("SelfEquip_Env","this:Hide();ToggleWuhunPage()");break;
 case 20:{auto& v=CysWuhunData::visuals[10+s.sweep];CysWuhunPreviewProbe::Bind(v.model);s.at=GetTickCount();s.step=21;return false;}
 case 21:{auto& v=CysWuhunData::visuals[10+s.sweep];CysWuhunPreviewProbe::Model("My_Wuhun",v.model);s.shot="wuhun-huan-asset-"+std::to_string(v.id);
  if(++s.sweep<36){s.step=20;s.at=GetTickCount();return false;}break;}
 case 22:Lua("Wuhun_Update();this:Hide()");s.x=self->GetPosition().x;s.z=self->GetPosition().z;Check(CysWorldReplay::LiveGroundClick(7),"movement input after UI");break;
 case 23:if(GetTickCount()-s.at<3500)return false;Check(std::hypot(self->GetPosition().x-s.x,self->GetPosition().z-s.z)>0.5f,"character moves after soul UI");s.shot="wuhun-world-huan";break;
 case 24:TDU_Log("CYS-WUHUN-APPEARANCE: RESULT errors=0");s.step=99;return true;
 case 30:Attached(self,750);s.shot="wuhun-relogin-world";CEventSystem::GetMe()->PushEvent(GE_OPEN_EQUIP);break;
 case 31:Attached(CysWuhunPreviewProbe::Avatar("Player"),750);s.shot="wuhun-relogin-selfequip";break;
 case 32:CysWuhunPreviewProbe::Lua("SelfEquip_Env","this:Hide();ToggleWuhunPage()");break;
 case 33:Lua("local n,l,g,q,k,y,v,r=CysWuhunData(1);assert(l==1 and g==1 and q==1 and k==3 and y==1 and v==1 and r==1)");Click("CysHuan_Open");break;
 case 34:s.shot="wuhun-relogin-catalog";break;
 case 35:Lua("CysHuanClose();this:Hide()");s.x=self->GetPosition().x;s.z=self->GetPosition().z;Check(CysWorldReplay::LiveGroundClick(7),"movement after relogin soul UI");break;
 case 36:if(GetTickCount()-s.at<3500)return false;Check(std::hypot(self->GetPosition().x-s.x,self->GetPosition().z-s.z)>0.5f,"movement survives relogin");
  Lua("Clear_XSCRIPT();Set_XSCRIPT_ScriptID(900066);Set_XSCRIPT_Function_Name('ConsoleSceneUse');Set_XSCRIPT_Parameter(0,1);Set_XSCRIPT_Parameter(1,2);Set_XSCRIPT_Parameter(2,77);Set_XSCRIPT_Parameter(3,89);Set_XSCRIPT_Parameter(4,0);Set_XSCRIPT_ParamCount(5);Send_XSCRIPT()");break;
 case 37:if(!CysModernGame::IsInWorld()||CWorldManager::GetMe()->GetActiveSceneID()!=2){if(GetTickCount()-s.at>65000)Check(false,"map transfer timeout");return false;}s.at=GetTickCount();s.step=38;return false;
 case 38:if(GetTickCount()-s.at<5000)return false;Attached(self,750);s.shot="wuhun-transfer-world";CEventSystem::GetMe()->PushEvent(GE_OPEN_EQUIP);break;
 case 39:Attached(CysWuhunPreviewProbe::Avatar("Player"),750);s.shot="wuhun-transfer-selfequip";break;
 case 40:CysWuhunPreviewProbe::Lua("SelfEquip_Env","this:Hide()");TDU_Log("CYS-WUHUN-APPEARANCE: RELOGIN errors=0");s.step=99;return true;
 }
 ++s.step;s.at=GetTickCount();return false;
}
inline bool Tick(){try{return TickImpl();}catch(const std::exception& e){TDU_Log("CYS-WUHUN-APPEARANCE: FAIL step=%d %s",S().step,e.what());S().step=99;return true;}}
}
