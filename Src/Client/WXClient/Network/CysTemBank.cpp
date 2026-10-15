#include "StdAfx.h"
#include "CysTemBank.h"
#include "CysModernGame.h"
#include "CysModernHandlers.h"
#include "PgPackets_misc.h"
#include "PgPackets_mission.h"
#include "../Script/GMScriptSystem.h"
#include "../DataPool/GMDataPool.h"
#include "../Object/Item/Obj_Item.h"
#include "../Action/GMActionSystem.h"
#include "../Event/GMEventSystem.h"
#include "TDEventDefine.h"
#include "CysItemWireCount.h"
#include <cstring>
namespace CysTemBank {
namespace {
CObject_Item* slots[120]={};int revision=0;bool busy=false;
void Clear() {for(auto& item:slots){if(item)CObject_Item::DestroyItem(item);item=nullptr;}if(CActionSystem::GetMe())CActionSystem::GetMe()->CleanInvalidAction();}
bool Send(const char* fn,std::initializer_list<int32_t> args) {
    if(!CysModernGame::IsInWorld())return false;
    std::unique_ptr<pg::CGExecuteScript> p(new pg::CGExecuteScript);
    p->m_ScriptID=990025;p->m_szFunName=fn;p->m_aParam=args;p->m_uParamCount=(uint8_t)p->m_aParam.size();
    return CysModernGame::SendModern(std::move(p));
}
bool Move(int dir,int pos,tObject_Item* item) {
    if(!item||item->IsLocked()||busy||revision<1)return false;
    USHORT world=0,server=0;UINT serial=0;item->GetGUID(world,server,serial);
    busy=Send("Move",{dir,pos,revision,world,server,(int32_t)serial});return busy;
}
int Open(LuaPlus::LuaState*) {busy=Send("Open",{});return 0;}
int Sync(LuaPlus::LuaState* s) {
    // UI events are queued. Snapshot boundaries are handled on the ordered
    // network stream, before the contained GCItemInfo packets, never here.
    return 0;
}
int Enum(LuaPlus::LuaState* s) {
    LuaPlus::LuaStack a(s);int i=a[2].IsNumber()?a[2].GetInteger():-1;
    auto item=i>=0&&i<120?slots[i]:nullptr;
    auto action=item?CActionSystem::GetMe()->GetAction_ItemID(item->GetID()):nullptr;
    LuaPlus::LuaObject boxed=s->BoxPointer(action?(void*)action:(void*)&CActionItem::s_InvalidAction);
    boxed.SetMetaTable(*CActionItem::s_pMetaTable);boxed.PushStack();s->PushBoolean(busy||(item&&item->IsLocked()));return 2;
}
int Count(LuaPlus::LuaState* s){int n=0;for(auto i:slots)if(i)++n;s->PushInteger(n);return 1;}
int TakeAll(LuaPlus::LuaState*){if(!busy&&revision>0)busy=Send("TakeAll",{revision});return 0;}
int Sort(LuaPlus::LuaState*){if(!busy&&revision>0)busy=Send("Sort",{revision});return 0;}
int GetOne(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);if(a[1].IsNumber()){int i=a[1].GetInteger();if(i>=0&&i<120)Withdraw(slots[i]);}return 0;}
LuaPlus::LuaObject Table(LuaPlus::LuaObject globals,const char* name){auto t=globals.GetByName(name);if(t.IsUserData()){auto m=t.GetMetaTable();auto i=m.GetByName("__index");return i.IsTable()?i:m;}return t.IsTable()?t:globals.CreateTable(name);}
}
void RegisterHost(){Clear();revision=0;busy=false;auto scripts=CScriptSystem::GetMe();auto s=scripts?scripts->GetLuaState():nullptr;if(!s)return;
 auto g=s->GetGlobals();auto bank=Table(g,"Bank");bank.Register("AskTemBankList",Open);bank.Register("EnumTemItem",Enum);
 bank.Register("GetTemBankItemNum",Count);bank.Register("MoveAllTemBankItemToPacket",TakeAll);bank.Register("TemBankPackUp",Sort);
 g.Register("CysTemBank_Sync",Sync);g.Register("CysTemBank_Take",GetOne);
}
void Snapshot(int kind,int rev){if(rev<1)return;if(kind==0){Clear();busy=true;revision=rev;}else if(kind==1&&rev==revision)busy=false;}
bool ItemInfo(const pg::GCItemInfo& p){
 if(p.bagIndex<600||p.bagIndex>=720)return false;
 const int i=p.bagIndex-600;if(slots[i])CObject_Item::DestroyItem(slots[i]);slots[i]=nullptr;
 CActionSystem::GetMe()->CleanInvalidAction();
 if(p.item.item_index>0&&p.unknow_1==0){
  _ITEM legacy;CysModernHandlers::ItemInfoToLegacy(p.item,legacy);auto item=CObject_Item::NewItem(legacy.m_ItemIndex);
  if(item){item->SetGUID(legacy.m_ItemGUID.m_World,legacy.m_ItemGUID.m_Server,(GUID_t)legacy.m_ItemGUID.m_Serial);
   item->SetExtraInfo(&legacy);item->SetNumber((INT)CysItemWireCount::Get(p.item));item->SetPosIndex(i);
   item->SetTypeOwner(tObject_Item::IO_QUESTVIRTUALITEM);slots[i]=item;CActionSystem::GetMe()->UpdateExternalItem(item);
  }
 }
 return true;
}
bool Owns(tObject_Item* item){if(!item)return false;for(auto p:slots)if(p==item)return true;return false;}
bool Withdraw(tObject_Item* item){if(!Owns(item))return false;Move(1,item->GetPosIndex(),item);return true;}
bool Drop(int pos,const char* target){if(!target||strncmp(target,"CYSTEMP",7))return false;Move(0,pos,CDataPool::GetMe()->UserBag_GetItem(pos));return true;}
}
