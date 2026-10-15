#include "StdAfx.h"
#include "CysDualSouls.h"
#include "CysModernGame.h"
#include "CysInspectNet.h"
#include "PgPackets_core.h"
#include "PgPackets_item.h"
#include "PgPackets_mission.h"
#include "../DataPool/GMDataPool.h"
#include "../DataPool/GMDP_CharacterData.h"
#include "../Object/ObjectManager.h"
#include "../Object/Character/Obj_PlayerOther.h"
#include "../Object/Character/Obj_PlayerMySelf.h"
#include "../Script/GMScriptSystem.h"
#include "../Event/GMEventSystem.h"
#include "LuaPlus.h"
#include "TDUtil.h"
#include <cstring>
namespace CysDualSouls { namespace {
int shown=1;
void Event(int open=0){if(auto e=CEventSystem::GetMe())e->PushEventByName("CYS_DUAL_SOULS",{std::to_string(open)});}
bool Ask(int op=0,int value=0){
 if(!CysModernGame::IsInWorld())return false;
 std::unique_ptr<pg::CGExecuteScript> p(new pg::CGExecuteScript);
 p->m_ScriptID=888800;p->m_szFunName="CysDualSoul";p->m_aParam={op,value};p->m_uParamCount=2;
 return CysModernGame::SendModern(std::move(p));
}
int Open(LuaPlus::LuaState*){Ask();Event(1);return 0;}
int Data(LuaPlus::LuaState* s){
 auto pool=CDataPool::GetMe();auto support=pool?pool->UserEquip_GetItem((HUMAN_EQUIP)18):nullptr;auto assault=pool?pool->UserEquip_GetItem((HUMAN_EQUIP)39):nullptr;
 s->PushInteger(support?support->GetIdTable():-1);s->PushInteger(assault?assault->GetIdTable():-1);s->PushInteger(shown);return 3;
}
int Action(LuaPlus::LuaState* s){
 LuaPlus::LuaStack a(s);if(!a[1].IsNumber()||!CysModernGame::IsInWorld())return 0;
 const int op=a[1].GetInteger();
 if(op==1){Ask(1,1-shown);return 0;}
 if(op==18||op==39){
  std::unique_ptr<pg::CGUnEquip> p(new pg::CGUnEquip);p->equipPoint=(uint8_t)op;
  CysModernGame::SendModern(std::move(p));
 }
 return 0;
}
}
void RegisterHost(){shown=1;auto scripts=CScriptSystem::GetMe();auto s=scripts?scripts->GetLuaState():nullptr;if(!s)return;
 auto g=s->GetGlobals();g.Register("CysDualSoulsOpen",Open);g.Register("CysDualSoulsData",Data);g.Register("CysDualSoulsAction",Action);
}
bool Drop(int bag,const char* target){
 if(!target||strncmp(target,"CYS_DUAL_",9))return false;
 const int point=!strcmp(target,"CYS_DUAL_SUPPORT")?18:!strcmp(target,"CYS_DUAL_ASSAULT")?39:-1;
 auto pool=CDataPool::GetMe();auto item=pool&&bag>=0&&bag<100?pool->UserBag_GetItem(bag):nullptr;
 if(point<0||!item||!CysModernGame::IsInWorld())return true;
 const int id=item->GetIdTable();
 if((point==39&&id!=10156902)||(point==18&&id!=10156901&&id!=10156001&&id!=10156002&&id!=10156003&&id!=10156004))return true;
 std::unique_ptr<pg::CGUseEquip> p(new pg::CGUseEquip);p->bagIndex=(uint8_t)bag;p->equipPoint=(uint8_t)point;p->type=0;
 CysModernGame::SendModern(std::move(p));return true;
}
bool Dispatch(const pg::Packet& p){
 if(p.packetId()!=pg::GCUICommand::PACKET_ID)return false;
 auto& packet=static_cast<const pg::GCUICommand&>(p);if(packet.m_nUIIndex!=990031)return false;
 const auto& a=packet.m_Param_m_aIntValue;if(a.size()!=6||a[0]!=1)return true;
 auto manager=CObjectManager::GetMe();auto object=manager?(CObject*)manager->FindServerObject(a[1]):nullptr;
 // Legacy kernel RTTI registers MySelf directly under Character, skipping its C++ Other base.
 if(object&&g_theKernel.IsKindOf(object->GetClass(),GETCLASS(CObject_Character))){
  auto character=static_cast<CObject_Character*>(object);
  const auto type=character->GetCharacterType();
  if(type==CObject_Character::CT_PLAYERMYSELF||type==CObject_Character::CT_PLAYEROTHER)
   character->GetCharacterData()->Set_AssaultAppearance(a[2],a[3]);
 }
 if(object&&CysInspectNet::Target()==object)manager->SetTargetAvatarAsTarget();
 auto self=manager?manager->GetMySelf():nullptr;
 if(self&&self->GetServerID()==a[1]){shown=a[4]==0?0:1;Event();}
 TDU_Log("CYS-DUAL-SOULS: state obj=%d item=%d visual=%d shown=%d support=%d",a[1],a[2],a[3],a[4],a[5]);
 return true;
}
}
