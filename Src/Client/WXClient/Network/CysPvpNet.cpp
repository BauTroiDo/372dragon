#include "StdAfx.h"
#include "CysPvpNet.h"
#include "CysPvpRules.h"
#include "CysModernGame.h"
#include "PgPackets_combat.h"
#include "PgPackets_misc.h"
#include "../Script/GMScriptSystem.h"
#include "../Script/CysCheckedScriptLua.h"
#include "../Object/ObjectManager.h"
#include "../Object/Character/Obj_PlayerMySelf.h"
#include "../Object/Character/Obj_PlayerOther.h"
#include "../DataPool/GMDP_CharacterData.h"
#include "../FakeObject/GMFakeObjSystem.h"
#include "../Event/GMEventSystem.h"
#include "../Input/GMInputSystem.h"
#include "../World/WorldManager.h"
#include "../Procedure/GameProcedure.h"
#include "../Interface/GMGameInterface.h"
#include "../WxRender/RenderSystem.h"
#include "LuaPlus.h"
#include "TDUtil.h"
#include <map>
#include <string>
#include <memory>
#include <algorithm>
namespace CysPvpNet {
namespace {
std::map<int,CysPvp::Human> humans;
pg::GCChallenge invitation;
int challenger=-1,rule=0,minimum=10000,delay=0;
DWORD receivedAt=0,delayAt=0;
unsigned damageEvents=0,challengeEvents=0;
bool Enabled(){static bool on=[](){char v[4]={};return GetEnvironmentVariableA("CYS_PVP_OLD",v,4)!=1||v[0]!='1';}();return on;}
int SelfId(){auto s=CObjectManager::GetMe()?CObjectManager::GetMe()->GetMySelf():nullptr;return s?s->GetServerID():-1;}
void RefreshNames(int changed){
    auto objects=CObjectManager::GetMe();if(!objects)return;
    for(const auto& h:humans){
        auto object=(CObject*)objects->FindServerObject(h.first);
        if(!object||!g_theKernel.IsKindOf(object->GetClass(),GETCLASS(CObject_Character)))continue;
        if(changed!=SelfId()&&h.first!=changed&&object->GetOwnerID()!=changed)continue;
        auto data=((CObject_Character*)object)->GetCharacterData();
        if(data){const STRING name=data->Get_Name();data->Set_Name(name.c_str());}
    }
}
void Event(const char* name,const std::vector<std::string>& args={}){if(CEventSystem::GetMe())CEventSystem::GetMe()->PushEventByName(name,args);}
int Arg(LuaPlus::LuaStack& a,int n,int fallback=-1){return a[n].IsNumber()?a[n].GetInteger():fallback;}
int Push(LuaPlus::LuaState* s,int n){s->PushInteger(n);return 1;}
LuaPlus::LuaObject Receiver(LuaPlus::LuaObject& globals,const char* name){
    auto object=globals.GetByName(name);if(object.IsTable())return object;
    if(object.IsUserData()){
        auto meta=object.GetMetaTable();if(!meta.IsTable())return LuaPlus::LuaObject();
        auto index=meta.GetByName("__index");return index.IsTable()?index:meta;
    }
    return LuaPlus::LuaObject();
}
bool Change(int mode,const char* password=nullptr){
    if(mode<0||mode>5||!CysModernGame::IsInWorld())return false;
    std::unique_ptr<pg::CGChangePkModeReq> p(new pg::CGChangePkModeReq);p->pk_mode=(uint8_t)mode;
    if(password)p->set_unknow_2(password);
    return CysModernGame::SendModern(std::move(p));
}
int ChangeMode(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);Change(Arg(a,2));return 0;}
int ChangePassword(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);if(a[3].IsString())Change(Arg(a,2),a[3].GetString());return 0;}
int Mode(LuaPlus::LuaState* s){return Push(s,humans[SelfId()].mode);}
int PeaceTime(LuaPlus::LuaState* s){return Push(s,delay>0?(std::max)(0,delay-(int)(GetTickCount()-delayAt)):-1);}
int ShowMenu(LuaPlus::LuaState*){
    auto input=CInputSystem::GetMe();if(!input)return 0;
    POINT pos=input->MouseGetPos();
    Event("SHOW_CONTEXMENU",{"PKmode",humans[SelfId()].level>=20?"1":"0",std::to_string(pos.x),std::to_string(pos.y)});
    return 0;
}
int ConfirmMode(LuaPlus::LuaState* s){
    // CY menu uses 6 for raid confirmation; 5 is the PK help entry.
    LuaPlus::LuaStack a(s);int mode=Arg(a,1);int ui=mode==1?1:mode==3?2:mode==4?3:mode==6?6:0;
    if(ui)Event("MENU_SHOWACCEPTCHANGEPVP",{std::to_string(ui)});return 0;
}
bool SendChallenge(int type,int target){
    if(target<0||target==SelfId()||!CysModernGame::IsInWorld())return false;
    std::unique_ptr<pg::CGChallenge> p(new pg::CGChallenge);p->type=(uint8_t)type;p->m_objID=target;
    return CysModernGame::SendModern(std::move(p));
}
int Challenge(LuaPlus::LuaState* s){
    LuaPlus::LuaStack a(s);int target=Arg(a,2);
    if(target<0){auto obj=CObjectManager::GetMe()->GetMainTarget();if(obj)target=((CObject*)obj)->GetServerID();}
    SendChallenge(0,target);return 0;
}
int Respond(LuaPlus::LuaState* s){
    LuaPlus::LuaStack a(s);int accept=Arg(a,2);
    if(challenger>=0&&(accept==0||accept==1)){
        if(GetTickCount()-receivedAt<30000)SendChallenge(accept?1:2,challenger);
        challenger=-1;invitation.member_list.clear();
    }
    return 0;
}
int Count(LuaPlus::LuaState* s){return Push(s,(int)invitation.member_list.size());}
std::string Preview(int i){
    std::string name="CYS_Challenge_"+std::to_string(i);
    auto fake=CFakeObjSystem::GetMe();if(!fake)return "";
    auto obj=(CObject_PlayerOther*)fake->FindFakeObject(name.c_str());
    if(!obj)obj=(CObject_PlayerOther*)fake->NewFakeObject("CObject_PlayerOther",name.c_str(),"Camera_Main");
    if(!obj)return "";
    const auto& p=invitation.member_list[(size_t)i];auto d=obj->GetCharacterData();
    d->Set_RaceID(p.model);d->Set_FaceMesh(p.face_style);d->Set_HairMesh(p.hair_style);d->Set_HairColor((UINT)p.hair_color);
    d->Set_Equip(HEQUIP_WEAPON,p.weapon);d->Set_Equip(HEQUIP_CAP,p.cap);d->Set_Equip(HEQUIP_ARMOR,p.armor);
    d->Set_Equip(HEQUIP_CUFF,p.glove);d->Set_Equip(HEQUIP_BOOT,p.shoe);d->Set_DressVisual(p.fashion>0?p.fashion_visual:-1);
    d->Set_Ornament(0,p.headid,p.headpos);d->Set_Ornament(1,p.backid,p.backpos);obj->SetFaceDir(0);
    return name;
}
int Member(LuaPlus::LuaState* s){
    LuaPlus::LuaStack a(s);int i=Arg(a,2);
    if(i<0||i>=(int)invitation.member_list.size()){s->PushString("");s->PushString("");s->PushInteger(0);s->PushInteger(9);s->PushInteger(0);return 5;}
    const auto& p=invitation.member_list[(size_t)i];s->PushString(Preview(i).c_str());s->PushString(p.name.c_str());
    s->PushInteger(p.level);s->PushInteger(p.menpai);s->PushInteger(p.server_id);return 5;
}
}
void Reset(){humans.clear();invitation.member_list.clear();challenger=-1;rule=0;minimum=10000;delay=0;delayAt=GetTickCount();}
void Remove(int id){humans.erase(id);if(challenger==id){challenger=-1;invitation.member_list.clear();Event("CLOSE_CHALLENGE_DLG");}}
void RegisterHost(){
    Reset();if(!Enabled())return;
    auto scripts=CScriptSystem::GetMe();auto s=scripts?scripts->GetLuaState():nullptr;if(!s)return;
    auto g=s->GetGlobals();auto player=Receiver(g,"Player"),pool=Receiver(g,"DataPool");
    if(!player.IsTable()||!pool.IsTable()){TDU_Log("CYS PVP host registration failed: receiver unavailable");return;}
    player.Register("ChangePVPMode",ChangeMode);player.Register("ChangePVPModeWithPassword",ChangePassword);
    player.Register("GetPKMode",Mode);player.Register("GetTimeToPeace",PeaceTime);
    player.Register("PVP_ShowMenu",ShowMenu);g.Register("ShowChangePVPMode",ShowMenu);
    pool.Register("Challenge",Challenge);pool.Register("RespondChallenge",Respond);
    pool.Register("GetChallengeTeamMemberCount",Count);pool.Register("GetChallengeTeamMemberInfo",Member);
    g.Register("ShowAcceptChangePVPMode",ConfirmMode);
}
void Base(const pg::GCCharBaseAttrib& p){
    if(!Enabled())return;
    int64_t f[11]={},a=0,b=0;pg::deriveCharBaseAttribFlags(p.new_flags.data(),f,&a,&b);
    auto& h=humans[(int)p.m_objID];
    if(f[0]&8)h.level=p.level;
    if(f[4]&4)h.guid=p.guid;
    if(f[3]&64)h.team=p.team_id;
    if(f[3]&128)h.guild=p.guild_id;
    if(f[4]&8)h.mode=p.pk_mode;
    if(f[4]&16)h.pk=p.pk_value;
    if(f[4]&32)h.camp=p.camp_id;
    if(f[6]&1)h.alliance=p.confederate_id;
    if(f[6]&8)h.raid=p.raid_id;
    if(f[7]&32)h.server=p.server_id;
    if((f[4]&128)&&!(f[6]&128)){h.attackers.clear();for(auto& v:p.attackers)if(v.guid>0)h.attackers.insert(v.guid);}
    if((f[5]&8)&&!(f[7]&8)){h.declarations.clear();for(auto& v:p.pk_declaration_list)if(v.guid>0)h.declarations.insert(v.guid);}
    if((f[5]&2)&&!(f[7]&2)){h.wars.clear();for(auto& v:p.wild_war_guilds)if(v.id>=0)h.wars.insert(v.id);}
    if((int)p.m_objID==SelfId()&&(f[4]&8))Event("PKMODE_CHANGE");
    // Living CCharacterData::Set_CampData refreshes the name; PK/list deltas need the same notification.
    if((f[0]&8)||(f[3]&192)||(f[4]&188)||(f[5]&10)||(f[6]&9)||(f[7]&32))RefreshNames((int)p.m_objID);
}
void Detail(const pg::GCDetailAttrib& p){
    if(!Enabled()||(int)p.m_objID!=SelfId())return;
    auto has=[&](int n,int mask){return (p.flags[(size_t)n-1]&mask)!=0;};auto& h=humans[SelfId()];
    if(has(11,2))h.mode=p.pk_mode;
    if(has(11,4))minimum=(int)p.pk_min_level;
    if(has(11,8))rule=p.pvp_rule;
    if(has(11,16))h.camp=p.camp_id;
    if(has(10,128))h.team=p.team_id;
    if(has(13,1)){delay=(std::max)(0,p.change_pk_mode_delay);delayAt=GetTickCount();}
    if(has(11,2)||has(13,1))Event("PKMODE_CHANGE");
    if(has(11,2)||has(11,4)||has(11,8)||has(11,16)||has(10,128))RefreshNames(SelfId());
}
bool HasAttackers(int objectId){
    const auto i=humans.find(objectId);
    return i!=humans.end()&&!i->second.attackers.empty();
}
bool Relation(CObject* a,CObject* b,bool& enemy){
    if(!Enabled()||!CysModernGame::IsActive()||!a||!b)return false;
    auto objects=CObjectManager::GetMe();
    if(a->GetOwnerID()!=INVALID_ID)a=(CObject*)objects->FindServerObject(a->GetOwnerID());
    if(b->GetOwnerID()!=INVALID_ID)b=(CObject*)objects->FindServerObject(b->GetOwnerID());
    if(!a||!b){enemy=false;return true;}
    // Engine RTTI registers MySelf directly under Character, unlike C++ inheritance.
    auto human=[](CObject* o){return g_theKernel.IsKindOf(o->GetClass(),GETCLASS(CObject_PlayerMySelf)) || g_theKernel.IsKindOf(o->GetClass(),GETCLASS(CObject_PlayerOther));};
    if(!human(a)||!human(b))return false;
    auto x=humans.find(a->GetServerID()),y=humans.find(b->GetServerID());
    if(x==humans.end()||y==humans.end()){enemy=false;return true;}
    enemy=CysPvp::Enemy(x->second,y->second,rule,minimum);return true;
}
bool IsWorldPacket(uint16_t id){return id==pg::GCChallenge::PACKET_ID;}
bool Dispatch(const pg::Packet& packet){
    if(!Enabled()||packet.packetId()!=pg::GCChallenge::PACKET_ID)return false;
    auto& p=static_cast<const pg::GCChallenge&>(packet);
    if(p.type==1&&p.m_objID!=SelfId()&&!p.member_list.empty()&&p.member_list.size()<=6){
        ++challengeEvents;
        invitation=p;challenger=p.m_objID;receivedAt=GetTickCount();Event("OPEN_CHALLENGE_DLG");
    }
    return true;
}
void Observe(const pg::Packet& packet){
    static bool probe=[](){char v[8]={};return GetEnvironmentVariableA("CYS_PVP_LIVE",v,8)>0&&atoi(v)>0;}();
    if(!probe)return;
    if(packet.packetId()==pg::GCDetailHealsAndDamages::PACKET_ID){
        auto& p=static_cast<const pg::GCDetailHealsAndDamages&>(packet);
        auto peer=humans.find((int)p.reciver);
        if(p.sender==(unsigned)SelfId()&&peer!=humans.end()&&peer->second.guid==200015&&(p.dirty_flags&1)&&p.hp_modification<0)++damageEvents;
    }
}
bool Probe(){
    static int mode=[](){char v[8]={};GetEnvironmentVariableA("CYS_PVP_LIVE",v,8);return atoi(v);}();
    if(!mode)return true;
    static int step=0;static DWORD due=0;static bool done=false;static int initialScene=-1;static DWORD start=GetTickCount();
    if(done)return true;if(GetTickCount()<due)return false;due=GetTickCount()+2500;
    if(GetTickCount()-start>100000){TDU_Log("CYS PVP-LIVE FAIL timeout mode=%d step=%d",mode,step);done=true;return true;}
    auto eval=[](const char* code){auto r=CScriptSystem::GetMe()->EvaluateScript("SelfEquip_Env",code);if(!r.ok())TDU_Log("CYS PVP-LIVE Lua FAIL %s",r.error);return r.ok();};bool ok=true;
    if(mode>=2){
        int target=-1;for(auto& h:humans)if(h.second.guid==200015)target=h.first;
        if(initialScene<0)initialScene=CWorldManager::GetMe()->GetActiveSceneID();
        auto finish=[&](bool good,const char* reason){TDU_Log("CYS PVP-LIVE %s mode=%d %s damage=%u invitations=%u rule=%d min=%d",good?"PASS":"FAIL",mode,reason,damageEvents,challengeEvents,rule,minimum);done=true;return true;};
        auto invite=[&](){return eval(("DataPool:Challenge("+std::to_string(target)+")").c_str());};
        auto nearPeer=[&](){
            auto self=CObjectManager::GetMe()->GetMySelf();auto other=(CObject*)CObjectManager::GetMe()->FindServerObject(target);
            if(!self||!other)return false;
            const auto a=self->GetPosition(),b=other->GetPosition();
            // CObject::GetPosition is already in world/plan metres (see SendUseSkillMessage).
            if((a.x-b.x)*(a.x-b.x)+(a.z-b.z)*(a.z-b.z)<=2.25f)return true;
            CGameProcedure::s_pGameInterface->Player_MoveTo(fVector2(b.x,b.z));return false;
        };
        auto cast=[&](){
            std::unique_ptr<pg::CGCharUseSkill> p(new pg::CGCharUseSkill);p->m_objID=SelfId();p->skillID=0;p->target=target;p->targetObjID=target;
            auto o=(CObject*)CObjectManager::GetMe()->FindServerObject(target);if(!o)return false;
            const auto pos=o->GetPosition();
            p->posTarget_x=pos.x;p->posTarget_y=pos.z;return CysModernGame::SendModern(std::move(p));
        };
        if(mode==2){
            if(step==0){if(target<0)return false;invite();++step;return false;}
            if(step==1){if(CWorldManager::GetMe()->GetActiveSceneID()!=initialScene)return finish(false,"reject transferred");invite();++step;return false;}
            if(step==2){if(CWorldManager::GetMe()->GetActiveSceneID()==initialScene)return false;step=3;due=GetTickCount()+18000;return false;}
            if(target<0)return false;
            if(!nearPeer())return false;
            if(step<7){cast();++step;return false;}
            return finish(damageEvents>0,"arena reject accept transfer combat");
        }
        if(mode==3){
            if(step==0){if(!challengeEvents)return false;ok=eval("assert(DataPool:GetChallengeTeamMemberCount()==1); local m,n,l,p,z=DataPool:GetChallengeTeamMemberInfo(0);assert(m~='' and n~='' and l>0)");if(!ok)return finish(false,"invitation UI data");
                ok=CScriptSystem::GetMe()->EvaluateScript("Challenge_Env","Challenge_Yes_Click()").ok();if(!ok)return finish(false,"accept UI");++step;return false;}
            return CWorldManager::GetMe()->GetActiveSceneID()!=initialScene?finish(true,"received invitation accepted through CY UI"):false;
        }
        if(step==0){if(target<0)return false;Change(1);++step;return false;}
        if(!nearPeer())return false;
        if(step==1){
            bool enemy=false;auto a=(CObject*)CObjectManager::GetMe()->GetMySelf();auto b=(CObject*)CObjectManager::GetMe()->FindServerObject(target);
            bool known=Relation(a,b,enemy);TDU_Log("CYS PVP-LIVE relation known=%d enemy=%d selfGuid=%d peer=%d rule=%d min=%d",known,enemy,humans[SelfId()].guid,target,rule,minimum);
            if(!known||enemy!=(mode==4))return finish(false,"target relation");
        }
        if(step<5){cast();++step;return false;}
        return finish(mode==4?damageEvents>0:damageEvents==0,mode==4?"free PK combat":"safe zone rejected attacks");
    }
    if(step==0){ok=CScriptSystem::GetMe()->EvaluateScript("MiniMap_Env","Player:PVP_ShowMenu()").ok();ok=ok&&eval("Player:ChangePVPMode(1)");}
    else if(step==1){ok=eval("assert(Player:GetPKMode()==1, 'PK mode not acknowledged')");CScriptSystem::GetMe()->EvaluateScript("ContexMenu_Env","ContexMenuFrame_Close()");}
    else if(step==2)ok=CScriptSystem::GetMe()->EvaluateScript("ContexMenu_Env","ContexMenu_PVP_FreeforRaid_Clicked()").ok();
    else if(step==3)ok=CScriptSystem::GetMe()->EvaluateScript("MessageBox_Self_Env","MessageBox_Self_OK_Clicked()").ok();
    else if(step==4)ok=eval("assert(Player:GetPKMode()==5); Player:ChangePVPMode(0)");
    else if(step==5){ok=eval("assert(Player:GetPKMode()==5); assert(Player:GetTimeToPeace()>0)");TDU_Log("CYS PVP-LIVE mode %s",ok?"PASS":"FAIL");done=true;return true;}
    if(!ok){TDU_Log("CYS PVP-LIVE step=%d FAIL",step);done=true;return true;}++step;return false;
}
}
