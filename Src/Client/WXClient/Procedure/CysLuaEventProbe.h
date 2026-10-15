#pragma once
// Owned integration: codec -> production handler -> queue -> actual CY Lua;
// server requests below only OPEN existing windows, never confirm operations.
#include "CysUiInputBridge.h"
#include "../Network/CysInventoryNet.h"
#include "../Network/CysModernGame.h"
#include "../Network/CysModernHandlers.h"
#include "../Network/CysWorldReplay.h"
#include "../DataPool/GMDataPool.h"
#include "../Event/GMEventSystem.h"
#include "../Script/GMScriptSystem.h"
#include "../Object/ObjectManager.h"
#include "../Object/Character/Obj_PlayerMySelf.h"
#include "PgPackets_core.h"
#include "PgPackets_mission.h"
#include "TDUtil.h"
#include <cmath>
#include <stdexcept>
namespace CysLuaEventProbe {
struct State { bool checked=false,on=false; int step=0,checks=0,errors=0,commands=0,named=0,live=0;DWORD at=0;float x=0,z=0;const char* shot=nullptr;CysUiInputBridge::GetWindowRectUtf8 rect=nullptr; };
inline State& S(){static State s;return s;}
inline void Check(bool ok,const char* name){++S().checks;if(!ok)++S().errors;TDU_Log("CYS-LUA-AUDIT: check=%s pass=%d",name,ok?1:0);}
inline void Lua(const char* env,const char* script){Check(CScriptSystem::GetMe()->EvaluateScript(env,script).ok(),script);}
inline bool Visible(const char* name){float r[4]={};return S().rect(name,r)==1;}
inline void Go(int step){S().step=step;S().at=GetTickCount();}
inline void __stdcall Event(const EVENT* e,UINT_PTR){
    if(!S().on)return;
    if(std::string(e->pEventDef->szEvent)=="CYS_AUDIT_LUA_EVENT"){
        ++S().named;Check(e->vArg.size()==2&&e->vArg[0]=="alpha"&&e->vArg[1]=="42","Lua PushEvent preserves arguments");return;
    }
    if(e->vArg.empty())return;
    const int id=atoi(e->vArg[0].c_str());auto p=CDataPool::GetMe()->X_PARAM_Get();
    if(id==20100716){
        ++S().commands;Check(p->GetIntCount()==1&&p->GetIntValue(0)==4&&p->GetStrCount()==1,"queued command counts");
        const char* expected=S().commands==1?"Lua audit first":S().commands==2?"Lua audit second":"Lua audit third";
        Check(p->GetStrValue(0)&&std::string(p->GetStrValue(0))==expected,"queued command retains its own string");
        Lua("AcceptBox_Env","assert(Get_XParam_INT_Count()==1 and Get_XParam_GetIntCount()==1 and Get_XParam_STR_Count()==1)");
    }else if(id==19810313||id==1004){
        ++S().live;Check(p->GetIntValue(0)==-1,"real server command argument");
        TDU_Log("CYS-LUA-AUDIT: server-ui index=%d ints=%d strings=%d",id,p->GetIntCount(),p->GetStrCount());
    }
}
inline void Inject(const char* text){
    pg::GCUICommand packet;packet.m_nUIIndex=20100716;packet.m_Param_m_IntCount=1;packet.m_Param_m_aIntValue={4};
    packet.m_Param_m_StrCount=1;packet.m_Param_m_aStrValue=std::string(text)+'\0';packet.m_Param_m_aStrOffset={(uint16_t)strlen(text)};
    pg::Writer writer;packet.write(writer);pg::GCUICommand decoded;pg::Reader reader(writer.buffer().data(),writer.size());
    Check(decoded.read(reader)&&reader.remaining()==0,"GCUICommand actual codec");bool changed=false;
    Check(CysModernHandlers::Dispatch(decoded,1,changed)&&!changed,"GCUICommand actual dispatcher");
}
inline void Server(const char* function){
    std::unique_ptr<pg::CGExecuteScript> request(new pg::CGExecuteScript);
    request->m_ScriptID=892666;request->set_m_szFunName(function);
    Check(CysModernGame::SendModern(std::unique_ptr<pg::Packet>(request.release())),function);
}
inline bool Tick(){
    auto& s=S();if(!s.checked){s.checked=true;char v[4]={};s.on=GetEnvironmentVariableA("CYS_LUA_AUDIT_LIVE",v,4)==1&&v[0]=='1';if(!s.on)return true;
        if(GetEnvironmentVariableA("CYS_GL_LOGIN_SMOKE",v,4)!=1||v[0]!='1')throw std::runtime_error("Lua event probe needs owned smoke");
        s.rect=(CysUiInputBridge::GetWindowRectUtf8)GetProcAddress(GetModuleHandleA("UI_CEGUI.dll"),"CysUiGetWindowRectUtf8");if(!s.rect)throw std::runtime_error("Lua probe UI bridge missing");
        TDU_Log("CYS-LUA-AUDIT: BEGIN");CEventSystem::GetMe()->RegisterEventHandle("UI_COMMAND",Event,0);
        CEventSystem::GetMe()->RegisterEventHandle("CYS_AUDIT_LUA_EVENT",Event,0);
        Lua("AcceptBox_Env","PushEvent('CYS_AUDIT_LUA_EVENT','alpha','42')");
        Inject("Lua audit first");Inject("Lua audit second");Go(1);
    }
    if(!s.on||s.step==99)return true;DWORD age=GetTickCount()-s.at;
    switch(s.step){
    case 1:if(age<1500)break;
        Check(s.commands==2,"both same-index commands delivered");Check(s.named==1,"named Lua event delivered");
        Check(Visible("AcceptBox_Frame"),"AcceptBox opened by decoded packet");
        // AcceptBox.lua intentionally ignores replacement while already shown.
        if(Visible("AcceptBox_Frame"))Lua("AcceptBox_Env","assert(AcceptBox_Text:GetProperty('Text')=='Lua audit first')");
        s.shot="lua-command-acceptbox";Go(2);break;
    case 2:if(age<300)break;Lua("AcceptBox_Env","CloseWindow('AcceptBox',true)");Inject("Lua audit third");Go(8);break;
    case 8:if(age<1000)break;Check(s.commands==3,"command delivered after close");Check(Visible("AcceptBox_Frame"),"AcceptBox reopened");
        if(Visible("AcceptBox_Frame"))Lua("AcceptBox_Env","assert(AcceptBox_Text:GetProperty('Text')=='Lua audit third')");
        s.shot="lua-command-reopen";Go(9);break;
    case 9:if(age<300)break;Lua("AcceptBox_Env","CloseWindow('AcceptBox',true)");Server("open_fix_equip");Go(3);break;
    case 3:if(age<5000)break;Check(s.live==1,"first real server reply delivered");Check(Visible("EquipRepair_Frame"),"repair window from real server Lua");s.shot="lua-command-repair";Go(4);break;
    case 4:if(age<300)break;Lua("EquipRepair_Env","CloseWindow('EquipRepair',true)");Server("open_add_fix_equip_count");Go(5);break;
    case 5:if(age<5000)break;Check(s.live==2,"second real server reply delivered");Check(Visible("EquipEnchange_Frame"),"repair count window from real server Lua");s.shot="lua-command-repair-count";Go(6);break;
    case 6:if(age<300)break;Lua("EquipEnchange_Env","CloseWindow('EquipEnchange',true); CloseWindow('Packet',true)");
        {auto p=CObjectManager::GetMe()->GetMySelf()->GetPosition();s.x=p.x;s.z=p.z;Check(CysWorldReplay::LiveGroundClick(4),"movement request after Lua windows");}Go(7);break;
    case 7:if(age<3500)break;
        {auto p=CObjectManager::GetMe()->GetMySelf()->GetPosition();float distance=std::hypot(p.x-s.x,p.z-s.z);Check(distance>=.5f,"movement after Lua windows");
        TDU_Log("CYS-LUA-AUDIT: RESULT checks=%d errors=%d commands=%d named=%d live=%d distance=%.3f",s.checks,s.errors,s.commands,s.named,s.live,distance);}Go(99);break;
    }return s.step==99;
}
inline const char* ShotName(){auto p=S().shot;S().shot=nullptr;return p;}
}
