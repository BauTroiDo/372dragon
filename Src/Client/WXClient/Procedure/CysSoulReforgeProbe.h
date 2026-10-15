#pragma once
#include "CysPowerSystemsProbe.h"
namespace CysSoulReforgeProbe {
struct State {int mode=-1,step=0,after=0,moves=0;DWORD at=0;float from[2]={},to[2]={},x=0,z=0;const char* shot=nullptr;};
inline State& S(){static State s;return s;}
inline void Check(bool ok,const char* why){if(!ok)throw std::runtime_error(why);TDU_Log("CYS-SOUL-REFORGE: PASS %s",why);}
inline void Go(int n){S().step=n;S().at=GetTickCount();}
inline void Lua(const char* env,const char* code){auto r=CScriptSystem::GetMe()->EvaluateScript(env,code);Check(r.ok(),r.error);}
inline const char* ShotName(){auto p=S().shot;S().shot=nullptr;return p;}
inline void Drag(int id,const char* target,int after){auto& s=S();int slot=CysPowerSystemsProbe::Slot(id);Check(slot>=0,"fixture item in bag");char name[96];CysBagProbe::ButtonName(slot,name);CysQuickbarProbe::Center(name,s.from);CysQuickbarProbe::Center(target,s.to);s.after=after;s.moves=0;CysBagProbe::S().pointer(0,s.from[0],s.from[1]);Go(100);}
inline void Click(const char* target,int after){auto& s=S();CysQuickbarProbe::Center(target,s.to);s.after=after;CysBagProbe::S().pointer(0,s.to[0],s.to[1]);CysBagProbe::S().pointer(1,s.to[0],s.to[1]);Go(110);}
inline void Verify(bool applied){
 auto item=CDataPool::GetMe()->UserBag_GetItem(CysPowerSystemsProbe::Slot(70600005));auto p=CysPetSoul::Details(item);Check(p!=nullptr,"full soul details available");
 Check(p->pet_soul_attr[4].type==22&&p->pet_soul_attr[5].type==-1,"last visible locked attribute retained and hidden row empty");
 Check(!applied||p->pet_soul_attr[4].value>1,"applied value rerolled");
 Check(applied||p->pet_soul_attr[4].value==1,"preview leaves original attributes unchanged");
 Check(CysBagProbe::Quantity(38002533)==3&&CysBagProbe::Quantity(38002636)==1,"two washers and one color material consumed once");
 Check(CObjectManager::GetMe()->GetMySelf()->GetCharacterData()->Get_Money()==50000,"fee debited once");CysInventoryIntegrityProbe::Unique();
}
inline bool TickImpl(){auto& s=S();if(s.mode<0){const char* e=getenv("CYS_SOUL_REFORGE_PROBE");s.mode=e?atoi(e):0;if(!s.mode)return true;
 Check(getenv("CYS_BOT_ACCOUNT")&&!strcmp(getenv("CYS_BOT_ACCOUNT"),"test15"),"owned soul fixture account");
 auto mod=GetModuleHandleA("UI_CEGUI.dll");auto& b=CysBagProbe::S();b.pointer=(CysUiInputBridge::SmokePointer)GetProcAddress(mod,"CysUiSmokePointer");b.rect=(CysUiInputBridge::GetWindowRectUtf8)GetProcAddress(mod,"CysUiGetWindowRectUtf8");b.read=(CysUiInputBridge::ReadActionButtonUtf8)GetProcAddress(mod,"CysUiReadActionButtonUtf8");Go(0);}
 if(!s.mode||s.step==99)return true;if(GetTickCount()-s.at<900)return false;auto self=CObjectManager::GetMe()->GetMySelf();
 switch(s.step){
 case 0:CysPowerSystemsProbe::Ui(80012701,{1,self->GetServerID()});Go(1);break;
 case 1:Check(CysBagProbe::Shown("PetSoul_LevelUp"),"soul UI opens");Lua("Packet_Env","Packet_ChangeTabIndex(0)");Drag(70600005,"CysSoul_Item",2);break;
 case 2:Lua("PetSoul_LevelUp_Env","local p,m,t=CysPetSoulData();assert(p>=0);local v,l=CysPetSoulLockInfo(5);assert(v==1 and l==0);v=CysPetSoulLockInfo(6);assert(v==0)");
  if(s.mode==2){Verify(true);s.shot="soul-lock-relogin";Go(90);break;}Click("CysSoul_Lock5",3);break;
 case 3:Lua("PetSoul_LevelUp_Env","local a,b,c,d,e,l=CysPetSoulData();assert(l==10)");Drag(38002636,"CysSoul_Color",4);break;
 case 4:Lua("PetSoul_LevelUp_Env","local a,b,c,d,e,l,color=CysPetSoulData();assert(l==10 and color>=0)");s.shot="soul-lock-before";Go(5);break;
 case 5:Click("CysSoul_Op3",6);break;
 case 6:Lua("PetSoul_LevelUp_Env","local a,b,c,p,busy=CysPetSoulData();assert(p==1 and busy==0)");Verify(false);s.shot="soul-lock-preview";Go(7);break;
 case 7:Click("CysSoul_Op4",8);break;
 case 8:Lua("PetSoul_LevelUp_Env","local a,b,c,p,busy,l=CysPetSoulData();assert(p==0 and busy==0 and l==0)");Verify(true);s.shot="soul-lock-applied";Go(90);break;
 case 90:Lua("PetSoul_LevelUp_Env","this:Hide()");Lua("Packet_Env","this:Hide()");s.x=self->GetPosition().x;s.z=self->GetPosition().z;Check(CysWorldReplay::LiveGroundClick(7),"move after soul UI");Go(91);break;
 case 91:if(GetTickCount()-s.at<3000)break;Check(std::hypot(self->GetPosition().x-s.x,self->GetPosition().z-s.z)>0.5f,"character moves after soul UI closes");TDU_Log("CYS-SOUL-REFORGE: RESULT mode=%d errors=0",s.mode);s.step=99;return true;
 case 100:CysBagProbe::S().pointer(1,s.from[0],s.from[1]);Go(101);break;
 case 101:++s.moves;CysBagProbe::S().pointer(0,s.from[0]+(s.to[0]-s.from[0])*s.moves/4,s.from[1]+(s.to[1]-s.from[1])*s.moves/4);if(s.moves==4)Go(102);break;
 case 102:CysBagProbe::S().pointer(2,s.to[0],s.to[1]);Go(s.after);break;
 case 110:CysBagProbe::S().pointer(2,s.to[0],s.to[1]);Go(s.after);break;
 }return false;
}
inline bool Tick(){try{return TickImpl();}catch(const std::exception& e){TDU_Log("CYS-SOUL-REFORGE: FAIL step=%d %s",S().step,e.what());S().step=99;return true;}}
}
