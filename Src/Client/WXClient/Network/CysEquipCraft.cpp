#include "StdAfx.h"
#include "CysEquipCraft.h"
#include "CysModernGame.h"
#include "PgPackets_core.h"
#include "PgPackets_mission.h"
#include "../Script/GMScriptSystem.h"
#include "../Event/GMEventSystem.h"
#include "TDUtil.h"
#include <cstring>
namespace CysEquipCraft {
namespace {
int revision=0,mode=1,slot=-1,material=-1,target=-1,enabled=0;
bool busy=false;DWORD sent=0;std::string text;
bool Ask(int op) {
 TDU_Log("CYS-EQUIPCRAFT: ask op=%d mode=%d slot=%d world=%d busy=%d",op,mode,slot,CysModernGame::IsInWorld()?1:0,busy?1:0);
 if(!CysModernGame::IsInWorld()||(busy&&GetTickCount()-sent<5000)||(op==1&&(!enabled||!revision)))return false;
 std::unique_ptr<pg::CGExecuteScript> p(new pg::CGExecuteScript);
 p->m_ScriptID=990029;p->m_szFunName="Action";p->m_aParam={op,mode,slot,material,target,revision};p->m_uParamCount=6;
 busy=CysModernGame::SendModern(std::move(p));sent=GetTickCount();TDU_Log("CYS-EQUIPCRAFT: sent=%d",busy?1:0);return busy;
}
int Open(LuaPlus::LuaState* s){TDU_Log("CYS-EQUIPCRAFT: Open called");LuaPlus::LuaStack a(s);mode=a[1].IsNumber()?a[1].GetInteger():1;slot=material=target=-1;Ask(0);return 0;}
int Mode(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);if(a[1].IsNumber()&&(!busy||GetTickCount()-sent>=5000)){mode=a[1].GetInteger();Ask(0);}return 0;}
int Refresh(LuaPlus::LuaState*){Ask(0);return 0;}
int Action(LuaPlus::LuaState*){Ask(1);return 0;}
int Clear(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);if(!busy&&a[1].IsNumber()){int n=a[1].GetInteger();if(n==1)slot=-1;if(n==2)material=-1;if(n==3)target=-1;Ask(0);}return 0;}
int Data(LuaPlus::LuaState* s){s->PushInteger(mode);s->PushInteger(slot);s->PushInteger(material);s->PushInteger(target);s->PushString(text.c_str());s->PushInteger(enabled&&!busy?1:0);return 6;}
}
void RegisterHost(){TDU_Log("CYS-EQUIPCRAFT: register host");revision=0;mode=1;slot=material=target=-1;busy=false;text.clear();
 auto script=CScriptSystem::GetMe();auto state=script?script->GetLuaState():nullptr;if(!state)return;
 auto g=state->GetGlobals();g.Register("CysEquipCraftOpen",Open);g.Register("CysEquipCraftMode",Mode);g.Register("CysEquipCraftData",Data);
 g.Register("CysEquipCraftAction",Action);g.Register("CysEquipCraftRefresh",Refresh);g.Register("CysEquipCraftClear",Clear);
}
bool Drop(int bag,const char* name){
 if(!name||strncmp(name,"CYS_CRAFT_",10))return false;
 if(busy&&GetTickCount()-sent<5000)return true;
 if(!strcmp(name,"CYS_CRAFT_ITEM"))slot=bag;
 else if(!strcmp(name,"CYS_CRAFT_MATERIAL"))material=bag;
 else if(!strcmp(name,"CYS_CRAFT_TARGET"))target=bag;
 Ask(0);return true;
}
bool Dispatch(const pg::Packet& packet){
 if(packet.packetId()!=pg::GCUICommand::PACKET_ID)return false;
 const auto& p=static_cast<const pg::GCUICommand&>(packet);if(p.m_nUIIndex!=990029)return false;
 if(p.m_Param_m_aIntValue.size()<7)return true;
 const auto& a=p.m_Param_m_aIntValue;revision=a[0];mode=a[1];slot=a[2];material=a[3];target=a[4];enabled=a[6];busy=false;
 text=p.m_Param_m_aStrValue;
 TDU_Log("CYS craft revision=%d mode=%d slots=%d,%d,%d enabled=%d text=%s",revision,mode,slot,material,target,enabled,text.c_str());
 if(auto e=CEventSystem::GetMe())e->PushEventByName("CYS_EQUIPCRAFT_UPDATE",{a[5]?"1":"0"});return true;
}
}
