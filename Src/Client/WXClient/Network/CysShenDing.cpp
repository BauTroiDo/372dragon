#include "StdAfx.h"
#include "CysShenDing.h"
#include "CysModernGame.h"
#include "PgPackets_mission.h"
#include "PgPackets_misc.h"
#include "PgPackets_core.h"
#include "../Script/GMScriptSystem.h"
#include "../Event/GMEventSystem.h"
#include "TDUtil.h"
#include <cstring>
#include <vector>
namespace CysShenDing {
namespace {
int values[15]={};bool ready=false,busy=false;DWORD sentAt=0;
bool Send(int op,const std::vector<int32_t>& extra={}) {
    if(!CysModernGame::IsInWorld())return false;
    if(busy && GetTickCount()-sentAt<5000)return false;
    if(op!=0&&!ready)return false;
    std::unique_ptr<pg::CGExecuteScript> p(new pg::CGExecuteScript);
    p->m_ScriptID=990027;p->m_szFunName="Action";p->m_aParam={op,values[0]};
    p->m_aParam.insert(p->m_aParam.end(),extra.begin(),extra.end());p->m_uParamCount=(uint8_t)p->m_aParam.size();
    busy=CysModernGame::SendModern(std::move(p));sentAt=GetTickCount();return busy;
}
int Open(LuaPlus::LuaState* s){s->PushInteger(Send(0)?1:0);return 1;}
int Action(LuaPlus::LuaState* s){
    LuaPlus::LuaStack a(s);if(!a[1].IsNumber())return 0;int op=a[1].GetInteger();std::vector<int32_t> extra;
    if(op==5)for(int i=2;i<=5;++i){if(!a[i].IsNumber())return 0;extra.push_back(a[i].GetInteger());}
    if(op<1||op>7)return 0;s->PushInteger(Send(op,extra)?1:0);return 1;
}
}
void RegisterHost(){
    memset(values,0,sizeof(values));ready=false;busy=false;
    auto script=CScriptSystem::GetMe();auto state=script?script->GetLuaState():nullptr;if(!state)return;
    auto globals=state->GetGlobals();globals.Register("OpenShenDingPage",Open);globals.Register("CysShenDingAction",Action);
}
bool Dispatch(const pg::Packet& packet){
    if(packet.packetId()!=pg::GCUICommand::PACKET_ID)return false;
    const auto& p=static_cast<const pg::GCUICommand&>(packet);if(p.m_nUIIndex!=990027)return false;
    if(p.m_Param_m_aIntValue.size()!=15 || p.m_Param_m_aIntValue[0]<1)return true;
    for(int i=0;i<15;++i)values[i]=p.m_Param_m_aIntValue[i];ready=true;busy=false;
    TDU_Log("CYS shending revision=%d dust=%d conPills=%d attackPills=%d con=%d points=%d ice=%d fire=%d light=%d poison=%d",values[0],values[2],values[3],values[4],values[7],values[8],values[9],values[10],values[11],values[12]);
    if(auto events=CEventSystem::GetMe())events->PushEventByName(values[1]?"OPEN_SHENDING_PAGE":"CYS_SHENDING_UPDATE",{});
    return true;
}
int GetData(LuaPlus::LuaState* s,const char* key){
    const struct {const char* name;int index;} keys[]={
        {"LIANDANLUCONVALUE",7},{"LianDanCount",3},{"YaoChenValue",2},{"JinDanRongHeCount",5},
        {"MaxJinDanRongHeCount",13},{"Attack_MaxJinDanCount",14},{"Attack_JinDanCount",6},
        {"Attack_DanYaoCount",4},{"Attack_QianNengPoint",8}};
    for(auto& k:keys)if(!strcmp(key,k.name)){s->PushInteger(values[k.index]);return 1;}
    if(!strcmp(key,"RongHeConValue")){s->PushInteger(values[5]*100);return 1;}
    if(!strcmp(key,"Attack_IFTPValue")){for(int i=9;i<=12;++i)s->PushInteger(values[i]);return 4;}
    return 0;
}
}
