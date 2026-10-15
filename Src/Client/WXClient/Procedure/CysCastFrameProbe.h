#pragma once
// Owned UI integration only: production events, Lua callbacks and rendered atlas
// geometry. No inventory/DB mutations, desktop input or forced resource eviction.
#include "CysUiInputBridge.h"
#include "../Event/GMEventSystem.h"
#include "../Script/GMScriptSystem.h"
#include "../Network/CysWorldReplay.h"
#include "../Object/ObjectManager.h"
#include "../Object/Character/Obj_PlayerMySelf.h"
#include "TDEventDefine.h"
#include "TDUtil.h"
#include <cmath>
#include <stdexcept>

namespace CysCastFrameProbe {
struct State {
    bool checked=false, enabled=false;
    int step=0, cycle=0, errors=0, checks=0;
    DWORD at=0;
    float fromX=0,fromZ=0;
    const char* shot=nullptr;
    char shotBuffer[64]={};
    CysUiInputBridge::GetWindowRectUtf8 rect=nullptr;
    using Metrics=int (__cdecl*)(const char*,const char*,float*);
    Metrics metrics=nullptr;
};
inline State& S(){static State s;return s;}
inline void Go(int step){S().step=step;S().at=GetTickCount();}
inline void Check(bool yes,const char* what){++S().checks;if(!yes)++S().errors;TDU_Log("CYS-CAST-FRAME: check=%s pass=%d cycle=%d",what,yes?1:0,S().cycle);}
inline bool Visible(const char* name){float r[4]={};return S().rect(name,r)==1;}
inline void Lua(const char* env,const char* code){Check(CScriptSystem::GetMe()->EvaluateScript(env,code).ok(),code);}
inline void Shot(const char* name){_snprintf(S().shotBuffer,64,"cast-frame-%s-%d",name,S().cycle);S().shot=S().shotBuffer;}
inline void Cast(){CEventSystem::GetMe()->PushEvent(GE_PROGRESSBAR_SHOW,"Niem");CEventSystem::GetMe()->PushEvent(GE_PROGRESSBAR_WIDTH,.65f);}
inline void Frame(){
    Check(Visible("SelfEquip_MainFrame"),"selfequip-visible");
    const char* parts[]={"TL","TR","BL","BR","L","R","T","B"};
    const float sizes[][2]={{104,60},{57,60},{104,9},{57,9},{22,3},{8,3},{10,54},{10,9}};
    for(int i=0;i<8;++i){char name[64];_snprintf(name,64,"MainMenuFrame_%s",parts[i]);float v[3]={};
        const bool ok=S().metrics("CommonFrame3",name,v)==1 && v[0]==sizes[i][0] && v[1]==sizes[i][1] && v[2]==0;
        Check(ok,name);TDU_Log("CYS-CAST-FRAME: atlas=%s width=%.1f height=%.1f autoscaled=%.0f",name,v[0],v[1],v[2]);}
    // CY prepends a colour control to the name (SelfEquip.lua GetCurTitle).
    Lua("SelfEquip_Env","assert(SelfEquip_MainFrame:GetProperty('FrameEnabled')=='True'); assert(string.find(SelfEquip_PageHeader:GetProperty('Text'),'CYTest13',1,true))");
}
inline bool Tick(){
    auto& s=S();
    if(!s.checked){s.checked=true;char v[4]={};s.enabled=GetEnvironmentVariableA("CYS_CAST_FRAME_LIVE",v,4)==1&&v[0]=='1';if(!s.enabled)return true;
        if(GetEnvironmentVariableA("CYS_GL_LOGIN_SMOKE",v,4)!=1||v[0]!='1')throw std::runtime_error("cast/frame probe requires owned smoke");
        HMODULE ui=GetModuleHandleA("UI_CEGUI.dll");s.rect=(CysUiInputBridge::GetWindowRectUtf8)GetProcAddress(ui,"CysUiGetWindowRectUtf8");
        s.metrics=(State::Metrics)GetProcAddress(ui,"CysUiReadImageMetricsUtf8");
        if(!s.rect||!s.metrics)throw std::runtime_error("cast/frame probe bridge missing");
        TDU_Log("CYS-CAST-FRAME: BEGIN");CEventSystem::GetMe()->PushEvent(GE_OPEN_EQUIP,"1");Go(1);
    }
    if(!s.enabled||s.step==99)return true;
    const DWORD age=GetTickCount()-s.at;
    switch(s.step){
    case 1:if(age<1200)break;Frame();Shot("open");Go(2);break;
    case 2:if(age<600)break;Lua("SelfEquip_Env","SelfEquip_MainFrame:SetProperty('FrameEnabled','False'); SelfEquip_MainFrame:SetProperty('FrameEnabled','True')");Go(3);break;
    case 3:if(age<800)break;Frame();Shot("redraw");Go(30);break;
    case 30:if(age<250)break;Lua("SelfEquip_Env","SelfEquip_CloseFunction()");Cast();Go(4);break;
    case 4:if(age<400)break;Check(Visible("ProgressBar_Progress"),"cast-shown");Shot("casting");CEventSystem::GetMe()->PushEvent(GE_PROGRESSBAR_WIDTH,1.f);CEventSystem::GetMe()->PushEvent(GE_PROGRESSBAR_HIDE);Go(5);break;
    case 5:if(age<800)break;Check(!Visible("ProgressBar_Progress"),"cast-complete-hidden");Lua("ProgressBar_Env","assert(not this:IsVisible())");Shot("completed");Cast();Go(6);break;
    case 6:if(age<400)break;Check(Visible("ProgressBar_Progress"),"second-cast-shown");Lua("ProgressBar_Env","ProgressBar_OnEvent('PROGRESSBAR_BREAK')");Go(7);break;
    case 7:if(age<800)break;Check(!Visible("ProgressBar_Progress"),"cast-interrupt-hidden");Lua("ProgressBar_Env","assert(not this:IsVisible())");Cast();Go(8);break;
    case 8:if(age<400)break;CEventSystem::GetMe()->PushEvent(GE_PROGRESSBAR_HIDE);Go(9);break;
    case 9:if(age<100)break;Cast();Go(10);break;
    case 10:if(age<800)break;Check(Visible("ProgressBar_Progress"),"recast-cancels-old-fade");Lua("ProgressBar_Env","assert(this:IsVisible()); assert(tonumber(ProgressBar_Progress:GetProperty('Alpha'))==1)");CEventSystem::GetMe()->PushEvent(GE_PROGRESSBAR_HIDE);Go(11);break;
    case 11:if(age<800)break;Check(!Visible("ProgressBar_Progress"),"recast-complete-hidden");Cast();Go(12);break;
    case 12:if(age<400)break;Lua("ProgressBar_Env","ProgressBar_OnEvent('HIDE_ON_SCENE_TRANSED')");Check(!Visible("ProgressBar_Progress"),"scene-hide");Go(13);break;
    case 13: // More than two natural 6-second atlas collection passes while closed.
        if(age<15000)break;Check(!Visible("SelfEquip_MainFrame"),"selfequip-closed-during-eviction");
        ++s.cycle;CEventSystem::GetMe()->PushEvent(GE_OPEN_EQUIP,"1");Go(14);break;
    case 14:if(age<1000)break;Frame();Shot("reopen");Go(15);break;
    case 15:if(age<15000)break;Frame();Shot("held-open");Go(31);break;
    case 31:if(age<250)break;Lua("SelfEquip_Env","SelfEquip_CloseFunction()");
        if(s.cycle<3){Go(13);break;}
        {auto p=CObjectManager::GetMe()->GetMySelf()->GetPosition();s.fromX=p.x;s.fromZ=p.z;Check(CysWorldReplay::LiveGroundClick(4),"post-close-move-request");Go(16);}break;
    case 16:if(age<3500)break;
        {auto p=CObjectManager::GetMe()->GetMySelf()->GetPosition();float distance=std::hypot(p.x-s.fromX,p.z-s.fromZ);
         Check(!Visible("SelfEquip_MainFrame")&&!Visible("ProgressBar_Progress"),"both-closed-after-movement");Check(distance>=.5f,"movement-after-close");
         TDU_Log("CYS-CAST-FRAME: RESULT checks=%d errors=%d distance=%.3f",s.checks,s.errors,distance);Go(99);}break;
    }
    return s.step==99;
}
inline const char* ShotName(){auto p=S().shot;S().shot=nullptr;return p;}
}
