#pragma once
#include "CysTooltipContractProbe.h"
#include <cmath>

namespace CysUiWheelProbe {
struct Menu {const char* env; const char* name; const char* shot;};
static const Menu menus[]={
 {"Quest_Env","QuestGreeting_Desc","wheel-npc-menu"},
 {"QuestLog_Env","QuestLog_Listbox","wheel-quest-list"},
 {"SelectFacestyle_Env","SelectFacestyle_StyleList","wheel-style-list"},
 {"AutoSearch_Env","AutoSearch_List","wheel-table"},
 {"ActionSkill_Env","ActionSkill_Explain","wheel-skill-description"},
 {"ChatFrame_Env","Chat_Frame_History","wheel-chat-history"}
};
struct State {int step=0,menu=0,errors=0;DWORD next=0;const char* shot=nullptr;float x=0,z=0,last=0,zoom=0;};
inline State& S(){static State s;return s;}
inline const char* ShotName(){auto p=S().shot;S().shot=nullptr;return p;}
inline void Check(bool ok,const char* name){TDU_Log("CYS-UI-WHEEL: %s menu=%d %s",ok?"PASS":"FAIL",S().menu,name);if(!ok)throw std::runtime_error(name);}
inline void Lua(const char* env,const char* text){auto r=CScriptSystem::GetMe()->EvaluateScript(env,text);if(!r.ok())TDU_Log("CYS-UI-WHEEL: Lua %s",r.error);Check(r.ok(),"Lua");}
inline void Sample(float out[6],bool prepare=false){
 using Fn=int(__cdecl*)(const char*,int,float*);
 auto fn=(Fn)GetProcAddress(GetModuleHandleA("UI_CEGUI.dll"),"CysUiWheelFixture");
 Check(fn && fn(menus[S().menu].name,prepare?1:0,out)==1,"actual menu/scrollbar ready");
 Check(out[5]>0,"content longer than page");
}
inline void Wheel(float r[6],bool up){
 auto input=CInputSystem::GetMe();
 if(input->CysDispatchWheel((int)(r[0]+r[2]*0.45f),(int)(r[1]+r[3]*0.40f),up)!=1)Check(false,"production UI queue consumes wheel over content");
}
inline void Boundary(float r[6],bool up){
 using Fn=int(__cdecl*)(const char*,int,float*);
 auto fn=(Fn)GetProcAddress(GetModuleHandleA("UI_CEGUI.dll"),"CysUiWheelFixture");
 for(int i=0;i<1024;++i){
  const float before=r[4];Wheel(r,up);
  if(!fn || fn(menus[S().menu].name,0,r)!=1)Check(false,"read scroll boundary");
  if(fabs(r[4]-before)<0.001f)return;
 }
 Check(false,"scroll reaches a boundary within fixture limit");
}
inline bool TickImpl(){
 auto& s=S();if(!CysTooltipContractProbe::Env("CYS_UI_WHEEL_LIVE")||s.step==99)return true;
 if(static_cast<LONG>(GetTickCount()-s.next)<0)return false;
 float r[6]={};auto self=CObjectManager::GetMe()->GetMySelf();auto input=CInputSystem::GetMe();
 if(s.step==0){
  using Fn=int(__cdecl*)(const char*,int,float*);
  auto fn=(Fn)GetProcAddress(GetModuleHandleA("UI_CEGUI.dll"),"CysUiWheelFixture");
  std::string frame=menus[s.menu].env;frame.resize(frame.size()-4);
  Check(fn && fn(frame.c_str(),-1,r)==1,"managed menu load and open");
 }
 else if(s.step==1){Sample(r,true);Check(r[4]==0,"starts at top");s.zoom=CGameProcedure::s_pGfxSystem->Camera_GetZoom();}
 else if(s.step==2){Sample(r);for(int i=0;i<3;++i)Wheel(r,false);}
 else if(s.step==3){Sample(r);Check(r[4]>0,"wheel down scrolls");Check(fabs(CGameProcedure::s_pGfxSystem->Camera_GetZoom()-s.zoom)<0.001f,"menu wheel does not zoom camera");s.last=r[4];s.shot=menus[s.menu].shot;Wheel(r,true);}
 else if(s.step==4){Sample(r);Check(r[4]<s.last,"wheel up scrolls");Boundary(r,true);Check(r[4]==0,"clamps at top");Boundary(r,false);TDU_Log("CYS-UI-WHEEL: boundary menu=%s position=%.1f max=%.1f",menus[s.menu].name,r[4],r[5]);Check(fabs(r[4]-r[5])<0.01f,"clamps at bottom");TDU_Log("CYS-UI-WHEEL: menu=%s max=%.1f verified",menus[s.menu].name,r[5]);}
 else if(s.step==5){
  if(s.menu!=5)Lua(menus[s.menu].env,"this:Hide()");
  if(++s.menu<6){s.step=0;s.next=GetTickCount()+500;return false;}
  CEventSystem::GetMe()->PushEvent(GE_ACCELERATE_KEYSEND,"acc_pet");
 }
 else if(s.step==6){Check(CGameProcedure::s_pUISystem->IsWindowShow("Pet")!=FALSE,"Pet frame visible for shared cell skin");s.shot="cells-pet";}
 else if(s.step==7){input->CysInjectKey(KC_ESCAPE,TRUE);}
 else if(s.step==8){input->CysInjectKey(KC_ESCAPE,FALSE);Check(!CGameProcedure::s_pUISystem->IsWindowShow("Pet"),"Escape closes Pet");CEventSystem::GetMe()->PushEvent(GE_TOGLE_SKILL_BOOK);}
 else if(s.step==9){Check(CGameProcedure::s_pUISystem->IsWindowShow("ActionSkill")!=FALSE,"skill frame visible for shared cell skin");s.shot="cells-skill";}
 else if(s.step==10){input->CysInjectKey(KC_ESCAPE,TRUE);}
 else if(s.step==11){input->CysInjectKey(KC_ESCAPE,FALSE);Check(!CGameProcedure::s_pUISystem->IsWindowShow("ActionSkill"),"Escape closes skill");s.zoom=CGameProcedure::s_pGfxSystem->Camera_GetZoom();Check(input->CysDispatchWheel(920,500,TRUE)==0,"world wheel remains available to camera");}
 else if(s.step==12){Check(fabs(CGameProcedure::s_pGfxSystem->Camera_GetZoom()-s.zoom)>0.01f,"world wheel zooms camera");s.x=self->GetPosition().x;s.z=self->GetPosition().z;CysAccel::SetChatting(false);Check(CysWorldReplay::LiveGroundClick(8),"ground click after menus");}
 else if(s.step==13){float dx=self->GetPosition().x-s.x,dz=self->GetPosition().z-s.z;Check(dx*dx+dz*dz>4,"movement after UI");TDU_Log("CYS-UI-WHEEL: RESULT menus=6 errors=%d",s.errors);s.step=99;return true;}
 ++s.step;s.next=GetTickCount()+(s.step==13?3500:650);return false;
}
inline bool Tick(){try{return TickImpl();}catch(const std::exception& e){
 auto& s=S();++s.errors;TDU_Log("CYS-UI-WHEEL: case failure menu=%d reason=%s",s.menu,e.what());
 if(s.step<=5 && s.menu<5){
  using Fn=int(__cdecl*)(const char*,int,float*);
  auto fn=(Fn)GetProcAddress(GetModuleHandleA("UI_CEGUI.dll"),"CysUiWheelFixture");
  std::string frame=menus[s.menu].env;frame.resize(frame.size()-4);float r[6]={};if(fn)fn(frame.c_str(),-2,r);
  ++s.menu;s.step=0;s.next=GetTickCount()+500;return false;
 }
 TDU_Log("CYS-UI-WHEEL: RESULT errors=%d",s.errors);s.step=99;return true;
}}
}
