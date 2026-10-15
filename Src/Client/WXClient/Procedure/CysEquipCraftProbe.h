#pragma once
#include "CysQuickbarProbe.h"
#include "../Network/CysEquipCraft.h"
namespace CysEquipCraftProbe {
struct State {int step=0,moves=0;DWORD next=0;bool init=false;float from[2]={},to[2]={},x=0,z=0;const char* shot=nullptr;};
inline State& S(){static State s;return s;}
inline const char* ShotName(){auto p=S().shot;S().shot=nullptr;return p;}
inline void Check(bool ok,const char* msg){if(!ok)throw std::runtime_error(msg);TDU_Log("CYS-EQUIPCRAFT: PASS %s",msg);}
inline void Lua(const char* owner,const char* code){auto r=CScriptSystem::GetMe()->EvaluateScript(owner,code);Check(r.ok(),r.ok()?"Lua assertions":r.error);}
inline void Click(const char* name){float p[2]={};CysQuickbarProbe::Center(name,p);auto pointer=CysBagProbe::S().pointer;TDU_Log("CYS-EQUIPCRAFT: click %s %.1f %.1f",name,p[0],p[1]);Check(pointer(0,p[0],p[1])&&pointer(1,p[0],p[1])&&pointer(2,p[0],p[1]),"native click accepted");}
inline bool TickImpl(){auto& s=S();
 static bool reported=false;if(!reported){reported=true;char flag[64]={};DWORD n=GetEnvironmentVariableA("CYS_EQUIPCRAFT_LIVE",flag,sizeof(flag));TDU_Log("CYS-EQUIPCRAFT: gate length=%lu enabled=%d step=%d",n,flag[0]=='1'?1:0,s.step);}
 if(!CysTooltipContractProbe::Env("CYS_EQUIPCRAFT_LIVE")||s.step==99)return true;
 if(static_cast<LONG>(GetTickCount()-s.next)<0)return false;
 if(!s.init){Check(getenv("CYS_BOT_ACCOUNT")&&!strcmp(getenv("CYS_BOT_ACCOUNT"),"test15"),"owned test15 fixture");auto m=GetModuleHandleA("UI_CEGUI.dll");auto& b=CysBagProbe::S();b.pointer=(CysUiInputBridge::SmokePointer)GetProcAddress(m,"CysUiSmokePointer");b.rect=(CysUiInputBridge::GetWindowRectUtf8)GetProcAddress(m,"CysUiGetWindowRectUtf8");b.read=(CysUiInputBridge::ReadActionButtonUtf8)GetProcAddress(m,"CysUiReadActionButtonUtf8");s.init=true;}
 auto pointer=CysBagProbe::S().pointer;auto self=CObjectManager::GetMe()->GetMySelf();
 switch(s.step){
 case 0:CEventSystem::GetMe()->PushEvent(GE_TOGLE_CONTAINER);break;
 case 1:Lua("Packet_Env","Packet_ChangeTabIndex(0);assert(type(CysEquipCraftOpen)=='function')");Click("CysCraft_Open");break;
 case 2:Check(CysBagProbe::Shown("CysEquipCraft"),"workshop opened by inventory button");CysQuickbarProbe::Center("Packet_Space_Line1_Row1_button",s.from);CysQuickbarProbe::Center("CysCraft_Slot1",s.to);pointer(0,s.from[0],s.from[1]);break;
 case 3:pointer(1,s.from[0],s.from[1]);break;
 case 4:++s.moves;pointer(0,s.from[0]+(s.to[0]-s.from[0])*s.moves/4,s.from[1]+(s.to[1]-s.from[1])*s.moves/4);if(s.moves<4){s.next=GetTickCount()+150;return false;}break;
 case 5:pointer(2,s.to[0],s.to[1]);break;
 case 6:Lua("CysEquipCraft_Env",u8"local m,a,b,c,t,e=CysEquipCraftData();assert(m==1 and a==0 and e==1);assert(string.find(t,'5 Tử Vi',1,true))");s.shot="equipcraft-spirit-before";Click("CysCraft_OK");break;
 case 7:Check(CysBagProbe::Quantity(20800031)==245,"spirit consumes five real souls");Lua("CysEquipCraft_Env",u8"local m,a,b,c,t=CysEquipCraftData();assert(string.find(t,'Thành công',1,true));CysEquipCraftMode(2)");break;
 case 8:Check(CysEquipCraft::Drop(3,"CYS_CRAFT_MATERIAL"),"engraving item drop route");break;
 case 9:Click("CysCraft_OK");break;
 case 10:Check(CysBagProbe::Quantity(30110271)==1&&CysBagProbe::Quantity(30503149)==1,"etch consumes engraving and solvent once");Lua("CysEquipCraft_Env","CysEquipCraftMode(3)");break;
 case 11:s.shot="equipcraft-engraving-upgrade";Click("CysCraft_OK");break;
 case 12:Check(CysBagProbe::Quantity(20310166)==248,"upgrade actual table cost two silk");Lua("CysEquipCraft_Env","CysEquipCraftMode(6)");break;
 case 13:CysEquipCraft::Drop(1,"CYS_CRAFT_TARGET");break;
 case 14:Click("CysCraft_OK");break;
 case 15:Lua("CysEquipCraft_Env",u8"local m,a,b,c,t=CysEquipCraftData();assert(string.find(t,'Thành công',1,true));CysEquipCraftMode(4)");break;
 case 16:CysEquipCraft::Drop(1,"CYS_CRAFT_ITEM");break;
 case 17:Click("CysCraft_OK");break;
 case 18:Check(CysBagProbe::Quantity(30110272)==1&&CysBagProbe::Quantity(30503150)==1,"remove returns one level2 engraving");Lua("CysEquipCraft_Env","CysEquipCraftMode(5)");break;
 case 19:CysEquipCraft::Drop(7,"CYS_CRAFT_MATERIAL");break;
 case 20:Click("CysCraft_OK");break;
 case 21:Check(CysBagProbe::Quantity(30110271)==2&&CysBagProbe::Quantity(30120028)==0&&CysBagProbe::Quantity(20310169)==0&&CysBagProbe::Quantity(20502009)==0,"combine charges blueprint and two material stacks");CysInventoryIntegrityProbe::Unique();s.shot="equipcraft-combine-result";Lua("CysEquipCraft_Env","this:Hide()");break;
 case 22:CysQuickbarProbe::Center("Packet_Space_Line1_Row1_button",s.from);pointer(0,s.from[0],s.from[1]);break;
 case 23:Lua("SuperTooltip_Env",u8"local t=SuperTooltips:GetTitle();local p=SuperTooltips:GetPropertys();assert(string.find(t,'#cFF53FF',1,true));assert(string.find(t,'(+3)',1,true));assert(string.find(p,'Thăng Linh 1/9',1,true));assert(string.find(p,'Thăng Linh +1',1,true));assert(not string.find(SuperTooltips:GetAuthorInfo(),'&W',1,true))");s.shot="equipcraft-tooltip-colours";break;
 case 24:pointer(0,1,1);CysQuickbarProbe::Key(KC_ESCAPE);break;
 case 25:Check(!CysBagProbe::Shown("Packet"),"Escape closes inventory");s.x=self->GetPosition().x;s.z=self->GetPosition().z;CysAccel::SetChatting(false);Check(CysWorldReplay::LiveGroundClick(7),"movement input after crafting");break;
 case 26:Check(std::hypot(self->GetPosition().x-s.x,self->GetPosition().z-s.z)>0.5f,"character moves after crafting");TDU_Log("CYS-EQUIPCRAFT: RESULT errors=0");s.step=99;return true;
 }
 ++s.step;s.next=GetTickCount()+(s.step==26?3500:1300);return false;
}
inline bool Tick(){try{return TickImpl();}catch(const std::exception& e){TDU_Log("CYS-EQUIPCRAFT: FAIL step=%d %s",S().step,e.what());S().step=99;return true;}}
}
