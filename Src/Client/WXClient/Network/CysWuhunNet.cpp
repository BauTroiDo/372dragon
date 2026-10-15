#include "StdAfx.h"
#include "CysWuhunNet.h"
#include "CysModernGame.h"
#include "PgPackets_misc.h"
#include "PgPackets_core.h"
#include "PgPackets_combat.h"
#include "PgPackets_mission.h"
#include "../DataPool/CysWuhunData.h"
#include "../DataPool/GMDataPool.h"
#include "../DataPool/GMDP_CharacterData.h"
#include "../Object/ObjectManager.h"
#include "../Object/Character/Obj_PlayerMySelf.h"
#include "../Script/GMScriptSystem.h"
#include "../Event/GMEventSystem.h"
#include "LuaPlus.h"
#include "TDUtil.h"
#include <cstring>
namespace CysWuhunNet { namespace {
int levels[7]={},grades[7]={},slots[2]={},yy=0,shown=1;
bool ready=false,busy=false;DWORD sent=0;
void Event(){if(auto e=CEventSystem::GetMe())e->PushEventByName("CYS_WUHUN_APPEARANCE",{});}
bool Script(const char* name,std::vector<int> args) {
 if(!CysModernGame::IsInWorld())return false;
 std::unique_ptr<pg::CGExecuteScript> p(new pg::CGExecuteScript);
 p->m_ScriptID=888800;p->m_szFunName=name;p->m_aParam=args;p->m_uParamCount=(uint32_t)args.size();
 return CysModernGame::SendModern(std::move(p));
}
int Refresh(LuaPlus::LuaState*){Script("CysState",{});return 0;}
int Action(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);
 int op=a[1].IsNumber()?a[1].GetInteger():-1,id=a[2].IsNumber()?a[2].GetInteger():0,arg=a[3].IsNumber()?a[3].GetInteger():0;
 if(!ready||(busy&&GetTickCount()-sent<5000))return 0;
 const char* fn=nullptr;std::vector<int> args;
 switch(op){case 1:fn="ActiveWg";args={id};break;case 2:fn="LevelUpWg";args={id};break;
 case 3:{if(id<1||id>6||arg<0||arg>1)return 0;std::unique_ptr<pg::CGWuhunWG> p(new pg::CGWuhunWG);p->type=2;p->huanhun_id=(int16_t)id;p->qiankun=arg;
 busy=CysModernGame::SendModern(std::move(p));sent=GetTickCount();return 0;}
 case 4:fn="TakeOut";args={arg};break;case 5:fn="SwitchYY";args={arg};break;default:return 0;}
 busy=Script(fn,args);sent=GetTickCount();return 0;
}
int Data(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);int id=a[1].IsNumber()?a[1].GetInteger():0;
 if(id<1||id>6)return 0;const auto& r=CysWuhunData::souls[id-1];
 s->PushString(r.name);s->PushInteger(levels[id]);s->PushInteger(grades[id]);s->PushInteger(slots[0]);s->PushInteger(slots[1]);s->PushInteger(yy);s->PushInteger(shown);s->PushInteger(ready&&(!busy||GetTickCount()-sent>=5000));
 const auto cost=CysWuhunData::Cost(id,levels[id],grades[id]);
 s->PushInteger(cost?cost->gold:(levels[id]>0?-1:r.gold));s->PushInteger(cost?cost->material[0]:r.material[0]);s->PushInteger(cost?cost->material[1]:r.material[1]);s->PushInteger(cost?cost->count:r.count);
 return 12;
}
int GetShow(LuaPlus::LuaState* s){s->PushInteger(shown);return 1;}
int SetShow(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);if(a[2].IsNumber()){int v=a[2].GetInteger();if(v==0||v==1)Script("SetShowWuhun",{v});}return 0;}
LuaPlus::LuaObject Receiver(LuaPlus::LuaObject& g,const char* name){auto t=g.GetByName(name);if(t.IsUserData()){auto m=t.GetMetaTable();auto i=m.GetByName("__index");return i.IsTable()?i:m;}return t;}
}
void RegisterHost(){memset(levels,0,sizeof(levels));memset(grades,0,sizeof(grades));slots[0]=slots[1]=yy=0;shown=1;ready=busy=false;
 auto s=CScriptSystem::GetMe()->GetLuaState();if(!s)return;auto g=s->GetGlobals();
 g.Register("CysWuhunRefresh",Refresh);g.Register("CysWuhunAction",Action);g.Register("CysWuhunData",Data);
 auto setup=Receiver(g,"SystemSetup");if(setup.IsTable()){setup.Register("GetShowWuhunObj",GetShow);setup.Register("SetShowWuhunObj",SetShow);}
}
bool Dispatch(const pg::Packet& p){
 if(p.packetId()==pg::GCWuhunWG::PACKET_ID){const auto& x=static_cast<const pg::GCWuhunWG&>(p);if(x.type==1)return true;
  memset(levels,0,sizeof(levels));memset(grades,0,sizeof(grades));for(const auto& r:x.unlockd)if(r.id>=1&&r.id<=6){levels[r.id]=r.level;grades[r.id]=r.grade;}Event();return true;}
 if(p.packetId()!=pg::GCUICommand::PACKET_ID)return false;const auto& x=static_cast<const pg::GCUICommand&>(p);
 if(x.m_nUIIndex!=888800)return false;const auto& a=x.m_Param_m_aIntValue;if(a.size()<4)return true;
 yy=a[0];slots[0]=a[1];slots[1]=a[2];shown=a[3];ready=true;busy=false;Event();
 TDU_Log("CYS-WUHUN: state yy=%d qian=%d kun=%d shown=%d",yy,slots[0],slots[1],shown);return true;
}
void Detail(const pg::GCDetailAttrib& p){auto self=CObjectManager::GetMe()?CObjectManager::GetMe()->GetMySelf():nullptr;if(!self||p.m_objID!=(unsigned)self->GetServerID())return;
 int f=pg::at1(p.flags,15);if(f&1)yy=p.wuhun_yy_flag;if(f&2)slots[0]=p.huanhun_qian_index;if(f&4)slots[1]=p.huanhun_kun_index;if(f&7)Event();
}
int PreviewModel(){int side=yy==1?1:0,id=slots[side];if(!id){side=1-side;id=slots[side];}if(id<1||id>6||levels[id]<1)return -1;
 int tier=levels[id]>=8?2:levels[id]>=5?1:0;int visual=CysWuhunData::HuanVisual(id,side,tier);auto row=CysWuhunData::Find(visual);return row?row->model:-1;
}
}
