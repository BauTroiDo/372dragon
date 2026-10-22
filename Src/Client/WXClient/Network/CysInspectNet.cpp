#include "StdAfx.h"
#include "CysInspectNet.h"
#include "CysModernGame.h"
#include "PgPackets_core.h"
#include "PgPackets_combat.h"
#include "PgPackets_item.h"
#include "PgPackets_misc.h"
#include "PgPackets_social.h"
#include "../Object/ObjectManager.h"
#include "../Object/Character/Obj_PlayerOther.h"
#include "../DataPool/GMDataPool.h"
#include "../DataPool/GMDP_CharacterData.h"
#include "../Action/GMActionSystem.h"
#include "../Script/GMScriptSystem.h"
#include "../Event/GMEventSystem.h"
#include "../Procedure/GameProcedure.h"
#include "TDUISystem.h"
#include "TDEventDefine.h"
#include "TDUtil.h"
#include <map>
#include <string>

namespace CysInspectNet {
namespace {
std::map<int,int> guids;
int serverId=-1, clientId=-1, guid=0;
bool pending=false, ready=false;
pg::GCPrivateInfo profile;
bool profileReady=false;
LuaPlus::LuaObject Table(LuaPlus::LuaObject globals, const char* name) {
    auto o=globals.GetByName(name);
    if(o.IsUserData()) { auto meta=o.GetMetaTable(); auto index=meta.GetByName("__index"); return index.IsTable()?index:meta; }
    return o.IsTable()?o:globals.CreateTable(name);
}
int Present(LuaPlus::LuaState* s) { s->PushBoolean(Target()!=nullptr); return 1; }
int CanEquip(LuaPlus::LuaState* s) { s->PushBoolean(ready && Target()!=nullptr); return 1; }
int Data(LuaPlus::LuaState* s) {
    LuaPlus::LuaStack a(s); const std::string key=a[2].IsString()?a[2].GetString():"";
    auto obj=static_cast<CObject_Character*>(Target()); auto d=obj?obj->GetCharacterData():nullptr;
    if(key=="NPCID") { if(obj)s->PushInteger(obj->GetID());else s->PushNil(); }
    else if(key=="NAME") { if(d)s->PushString(d->Get_Name());else s->PushNil(); }
    else if(key=="TITLE") s->PushString(d?d->Get_CurTitle():"");
    else if(key=="GUILD") s->PushString(""); // server supplies a guild ID, not its display name
    else if(key=="LEVEL" || key=="LEVEL_CompatPKLV") s->PushInteger(d?d->Get_Level():0);
    else if(key=="MEMPAI") s->PushInteger(d?d->Get_MenPai():-1);
    else if(key=="ISPLAYER") s->PushInteger(obj?1:0);
    else if(key=="BATTLESCORE" || key=="EQUIPSCOREHH") s->PushString("--"); // absent from foreign detail whitelist
    else s->PushInteger(0);
    return 1;
}
int Name(LuaPlus::LuaState* s) { auto o=static_cast<CObject_Character*>(Target());s->PushString(o?o->GetCharacterData()->Get_Name():"");return 1; }
int Model(LuaPlus::LuaState*) { if(ready&&Target()) CObjectManager::GetMe()->SetTargetAvatarAsTarget();return 0; }
int CloseModel(LuaPlus::LuaState*) { pending=false;return 0; }
int Zero(LuaPlus::LuaState* s) {s->PushInteger(0);return 1;}
int PrivateInfo(LuaPlus::LuaState* s) {
    LuaPlus::LuaStack a(s);const std::string whose=a[2].IsString()?a[2].GetString():"",key=a[3].IsString()?a[3].GetString():"";
    auto obj=whose=="other"?static_cast<CObject_Character*>(Target()):nullptr;
    if(key=="name") s->PushString(obj?obj->GetCharacterData()->Get_Name():"");
    else if(key=="guid") s->PushInteger(obj?guid:0);
    else if(key=="age") s->PushString("--");
    else if(key=="sex"||key=="blood"||key=="animal"||key=="Consella"||key=="Province") s->PushInteger(0);
    else s->PushString("");
    // The current scenecore.char_ask_private_info sends GUID and default/empty fields only.
    // Never substitute the viewer's private data or guess layouts for unknown CY fields.
    return 1;
}
int OpenPrivate(LuaPlus::LuaState* s) {
    LuaPlus::LuaStack a(s);
    if(a[2].IsString() && std::string(a[2].GetString())=="other" && Target()) {
        CEventSystem::GetMe()->PushEvent(GE_OPEN_PRIVATE_INFO,"other");
    }
    return 0;
}
int GuidToShow(LuaPlus::LuaState* s) {
    LuaPlus::LuaStack a(s);if(!a[1].IsNumber())return 0;

    char text[24]={};_snprintf(text,sizeof(text),"00000000%08X",static_cast<unsigned>(a[1].GetNumber()));
    s->PushString(text);return 1;
}
}
CObject* Target() {
    auto objects=CObjectManager::GetMe(); if(!objects || serverId<0)return nullptr;
    auto o=static_cast<CObject*>(objects->FindServerObject(serverId));
    const auto found=guids.find(serverId);
    return o && o->GetID()==clientId && found!=guids.end() && found->second==guid ? o : nullptr;
}
void Reset() {
    serverId=clientId=-1;guid=0;pending=ready=profileReady=false;profile=pg::GCPrivateInfo();guids.clear();
    if(CDataPool::GetMe()) CDataPool::GetMe()->Copy_To_TargetEquip(nullptr);
}
void Remove(int id) {
    guids.erase(id);
    if(id==serverId) { serverId=clientId=-1;pending=ready=profileReady=false; CDataPool::GetMe()->Copy_To_TargetEquip(nullptr); }
}
void Base(const pg::GCCharBaseAttrib& p) {
    int64_t flags[11]={},a=0,b=0;pg::deriveCharBaseAttribFlags(p.new_flags.data(),flags,&a,&b);
    if(flags[4]&4)guids[p.m_objID]=p.guid;
}
bool Request(CObject* o) {
    if(!CysModernGame::IsActive()||!o||!g_theKernel.IsKindOf(o->GetClass(),GETCLASS(CObject_PlayerOther)))return false;
    const auto found=guids.find(o->GetServerID()); if(found==guids.end()||found->second<=0)return false;
    serverId=o->GetServerID();clientId=o->GetID();guid=found->second;pending=true;ready=profileReady=false;profile=pg::GCPrivateInfo();
    CDataPool::GetMe()->Copy_To_TargetEquip(o);
    CDataPool::GetMe()->OtherPlayerEquip_Clear();CActionSystem::GetMe()->OtherPlayerEquip_Update();
    std::unique_ptr<pg::CGAskDetailAttrib> attr(new pg::CGAskDetailAttrib);attr->m_objID=serverId;
    std::unique_ptr<pg::CGAskDetailEquipList> equip(new pg::CGAskDetailEquipList);equip->m_objID=serverId;
    std::unique_ptr<pg::CGAskPrivateInfo> info(new pg::CGAskPrivateInfo);info->m_objID=serverId;
    const bool ok=CysModernGame::SendModern(std::move(attr))&&CysModernGame::SendModern(std::move(equip))&&CysModernGame::SendModern(std::move(info));
    if(!ok)pending=false;
    TDU_Log("CYS inspect: request object=%d client=%d guid=%d sent=%d",serverId,clientId,guid,ok);
    return ok;
}
bool AcceptEquipment(int id) {return pending&&id==serverId&&Target()!=nullptr;}
void EquipmentReady() {if(!Target())return;pending=false;ready=true;CEventSystem::GetMe()->PushEvent(GE_OTHERPLAYER_UPDATE_EQUIP);}
bool IsWorldPacket(uint16_t id) {return id==pg::GCPrivateInfo::PACKET_ID;}
bool Dispatch(const pg::Packet& packet) {
    if(!IsWorldPacket(packet.packetId()))return false;
    auto& p=static_cast<const pg::GCPrivateInfo&>(packet);
    if(Target() && p.unknow_1==0 && p.guid==guid) {profile=p;profileReady=true;TDU_Log("CYS inspect: private guid=%d received",guid);}
    return true;
}
void RegisterHost() {
    auto s=CScriptSystem::GetMe()->GetLuaState();if(!s)return;
    auto g=s->GetGlobals();auto target=Table(g,"CachedTarget");
    g.Register("ConvertGuidToShow",GuidToShow);
    target.Register("IsPresent",Present);target.Register("CanGetTargetEquip",CanEquip);target.Register("GetData",Data);target.Register("GetName",Name);
    target.Register("TargetEquip_ChangeModel",Model);target.Register("TargetEquip_DestroyUIModel",CloseModel);
    target.Register("GetEquipMasterFlag",Zero);target.Register("Lua_GetTargetEnchanceMinLevel",Zero);
    auto setup=Table(g,"SystemSetup");setup.Register("GetPrivateInfo",PrivateInfo);setup.Register("OpenPrivatePage",OpenPrivate);
}
}
