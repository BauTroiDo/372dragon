#pragma once
#include "CysTooltipContractProbe.h"

namespace CysNpcIconProbe {
struct State {int step=0,page=1;DWORD next=0;const char* shot=nullptr;float r[12]={},x=0,z=0,zoom=0;};
inline State& S(){static State s;return s;}
inline const char* ShotName(){const char* p=S().shot;S().shot=nullptr;return p;}
inline void Check(bool ok,const char* why){
    TDU_Log("CYS-NPC-ICON: %s %s",ok?"PASS":"FAIL",why);
    if(!ok)throw std::runtime_error(why);
}
inline int Run(int mode){
    using Fn=int(__cdecl*)(int,float*);
    auto fn=(Fn)GetProcAddress(GetModuleHandleA("UI_CEGUI.dll"),"CysNpcIconFixtureRun");
    Check(fn!=nullptr,"fixture export");return fn(mode,S().r);
}
inline void Pointer(unsigned action,float x,float y){
    auto fn=(CysUiInputBridge::SmokePointer)GetProcAddress(GetModuleHandleA("UI_CEGUI.dll"),"CysUiSmokePointer");
    Check(fn && fn(action,x,y)==1,"native pointer");
}
inline bool Tick(){
    auto& s=S();if(!CysTooltipContractProbe::Env("CYS_NPC_ICON_LIVE")||s.step==99)return true;
    if(static_cast<LONG>(GetTickCount()-s.next)<0)return false;
    auto input=CInputSystem::GetMe();auto self=CObjectManager::GetMe()->GetMySelf();
    if(s.step==0){Check(Run(0)>0,"real server NPC menu icons");s.shot="npc-icons-server";}
    else if(s.step==1){Check(Run(s.page)==(s.page==6?2:6),"catalog page icons match native source cells");Pointer(0,s.r[0],s.r[1]);}
    else if(s.step==2){static const char* shots[]={"npc-icons-00-05","npc-icons-06-11","npc-icons-12-17","npc-icons-18-23","npc-icons-24-29","npc-icons-30-31"};s.shot=shots[s.page-1];Pointer(1,s.r[0],s.r[1]);}
    else if(s.step==3){Pointer(2,s.r[0],s.r[1]);Check(Run(7)==1 && s.r[4]==1,"click on icon reaches correct option");Pointer(1,s.r[2],s.r[3]);}
    else if(s.step==4){Pointer(2,s.r[2],s.r[3]);Check(Run(7)==1 && s.r[4]==2,"click on label reaches same option");if(++s.page<=6){s.step=1;s.next=GetTickCount()+500;return false;}}
    else if(s.step==5){Check(Run(9)==32,"all 32 icon states loaded");s.zoom=CGameProcedure::s_pGfxSystem->Camera_GetZoom();Check(input->CysDispatchWheel((int)s.r[0],(int)s.r[1],FALSE)==1,"wheel over icon consumed");}
    else if(s.step==6){Run(10);Check(s.r[4]>0,"wheel over icon scrolls long NPC menu");Check(fabs(CGameProcedure::s_pGfxSystem->Camera_GetZoom()-s.zoom)<0.001f,"UI wheel preserves camera");Check(Run(8)==1,"fixture removed");input->CysInjectKey(KC_ESCAPE,TRUE);}
    else if(s.step==7){input->CysInjectKey(KC_ESCAPE,FALSE);Check(!CGameProcedure::s_pUISystem->IsWindowShow("Quest"),"Escape closes NPC dialogue");s.x=self->GetPosition().x;s.z=self->GetPosition().z;CysAccel::SetChatting(false);Check(CysWorldReplay::LiveGroundClick(8),"ground click after dialogue");}
    else if(s.step==8){float dx=self->GetPosition().x-s.x,dz=self->GetPosition().z-s.z;Check(dx*dx+dz*dz>4,"movement after NPC dialogue");TDU_Log("CYS-NPC-ICON: RESULT states=32 pages=6 errors=0");s.step=99;return true;}
    ++s.step;s.next=GetTickCount()+(s.step==8?3500:650);return false;
}
}
