#include "StdAfx.h"
#include "CysGuildWarNet.h"
#include "CysModernGame.h"
#include "PgPackets_city.h"
#include "PgPackets_social.h"
#include "../DataPool/GMDP_CharacterData.h"
#include "../Object/ObjectManager.h"
#include "../Object/Character/Obj_PlayerMySelf.h"
#include "../Script/GMScriptSystem.h"
#include "../Event/GMEventSystem.h"
#include "LuaPlus.h"
#include "TDUtil.h"
namespace CysGuildWarNet {namespace {
std::vector<pg::WGCZhengTao::E_list> wars[4];
pg::GCGuild guilds;pg::WGCGuild guild;int selected=-1; bool pendingGuilds=false; unsigned guildPage=0;
int Num(LuaPlus::LuaState* s,int i,int d=0){LuaPlus::LuaStack a(s);return a[i].IsNumber()?int(a[i].GetNumber()):d;}
std::string Str(LuaPlus::LuaState* s,int i){LuaPlus::LuaStack a(s);return a[i].IsString()?a[i].GetString():"";}
void Event(const char* n,const std::vector<STRING>& a={}){CEventSystem::GetMe()->PushEventByName(n,a);}
void Send(std::unique_ptr<pg::Packet> p){CysModernGame::SendModern(std::move(p));}
template<class T>std::unique_ptr<T> New(){return std::unique_ptr<T>(new T);}
int MyGuild(){auto s=CObjectManager::GetMe()->GetMySelf();return s?s->GetCharacterData()->Get_Guild():-1;}
void Ask(int n){if(n<0||n>3)return;auto p=New<pg::CGCGWPacket>();p->type=2;p->data={0,0,(uint8_t)(6+n)};p->len=3;Send(std::move(p));}
int EnemyList(LuaPlus::LuaState* s){Ask(Num(s,2));return 0;}
int BattleList(LuaPlus::LuaState* s){Ask(Num(s,2)==0?3:2);return 0;}
int EnemyCount(LuaPlus::LuaState* s){int n=Num(s,2);s->PushInteger(n>=0&&n<2?(int)wars[n].size():0);return 1;}
int BattleCount(LuaPlus::LuaState* s){int n=Num(s,2);s->PushInteger(n>=0&&n<2?(int)wars[n==0?3:2].size():0);return 1;}
int Enum(LuaPlus::LuaState* s,bool battle){int n=Num(s,2),i=Num(s,3,-1);if(battle)n=n==0?3:n==1?2:-1;auto m=n>=0&&n<4&&i>=0&&i<(int)wars[n].size()?&wars[n][i]:nullptr;auto k=Str(s,4);if(k=="name")s->PushString(m?m->name_text().c_str():"");else if(k=="lefttime")s->PushString(m?(std::to_string(m->remain_time)+u8" phút").c_str():"");else s->PushInteger(m?m->id:-1);return 1;}
int EnumEnemy(LuaPlus::LuaState* s){return Enum(s,false);}int EnumBattle(LuaPlus::LuaState* s){return Enum(s,true);}
int DeclareEnemy(LuaPlus::LuaState* s){int id=Num(s,2,-1);if(MyGuild()>=0&&id>=0&&id!=MyGuild()){auto p=New<pg::CGCGWPacket>();p->type=3;p->len=34;p->guild_wild_war.tar_guild_id=id;Send(std::move(p));}return 0;}
int OpenEnemy(LuaPlus::LuaState* s){int id=Num(s,3,-1);if(Str(s,2)=="BenFu"&&id>=0){Event("CITY_CONFIRM",{"11",std::to_string(id)});}return 0;}
int DeclareBattle(LuaPlus::LuaState* s){int id=Num(s,2,-1);if(MyGuild()>=0&&id>=0&&id!=MyGuild()){auto p=New<pg::CGCGWPacket>();p->type=11;p->len=8;p->guild_war.initiate_or_accept=0;p->guild_war.my_guild_id=MyGuild();p->guild_war.tar_guild_id=id;Send(std::move(p));}return 0;}
int SelectBattle(LuaPlus::LuaState* s){selected=Num(s,2,-1);return 0;}
int AcceptBattle(LuaPlus::LuaState* s){if(Num(s,2)==1&&selected>=0&&selected<(int)wars[2].size()){auto p=New<pg::CGCGWPacket>();p->type=11;p->len=8;p->guild_war.initiate_or_accept=1;p->guild_war.my_guild_id=wars[2][selected].id;p->guild_war.tar_guild_id=MyGuild();Send(std::move(p));}return 0;}
int AskGuilds(LuaPlus::LuaState*){auto p=New<pg::CGGuild>();p->packet_type=0;guilds.guild_list.clear();pendingGuilds=true;guildPage=0;p->askid=guildPage;p->type=0;Send(std::move(p));return 0;}
int GuildCount(LuaPlus::LuaState* s){s->PushInteger((int)guilds.guild_list.size());return 1;}
int GuildInfo(LuaPlus::LuaState* s){int i=Num(s,3,-1);auto g=i>=0&&i<(int)guilds.guild_list.size()?&guilds.guild_list[i]:nullptr;auto key=Str(s,4);if(key=="GuildID")s->PushInteger(g?g->id:-1);else s->PushString(g?(key=="ChiefName"?g->chief_name_text():key=="CityName"?g->city_name_text():g->name_text()).c_str():"");return 1;}
int Open(LuaPlus::LuaState*){Event("NEW_BANGHUI_BHXZ_OPEN");return 0;}
LuaPlus::LuaObject Receiver(LuaPlus::LuaObject g,const char* n){auto o=g.GetByName(n);if(o.IsTable())return o;if(o.IsUserData()){auto m=o.GetMetaTable();if(m.IsTable()){auto i=m.GetByName("__index");return i.IsTable()?i:m;}}return LuaPlus::LuaObject();}
}
void Reset(){for(auto& v:wars)v.clear();guilds=pg::GCGuild();guild=pg::WGCGuild();selected=-1;pendingGuilds=false;}
bool IsWorldPacket(unsigned short id){return id==pg::GCWGCPacket::PACKET_ID;}
bool Dispatch(const pg::Packet& p){
    if(p.packetId()==pg::GCGuild::PACKET_ID){auto& g=static_cast<const pg::GCGuild&>(p);if(!pendingGuilds||g.packet_type!=57||g.askid!=guildPage+1)return false;
        guilds.guild_list.insert(guilds.guild_list.end(),g.guild_list.begin(),g.guild_list.end());
        if(!g.guild_list.empty()&&guilds.guild_list.size()<g.guild_count){guildPage=g.guild_list.back().id+1;auto q=New<pg::CGGuild>();q->packet_type=0;q->askid=guildPage;Send(std::move(q));}else {pendingGuilds=false;Event("GUILD_SHOW_ENEMYLIST");}return true;}
    if(!IsWorldPacket(p.packetId()))return false;auto& v=static_cast<const pg::GCWGCPacket&>(p);pg::Reader r(v.buffer.data(),v.buffer.size());
    if(v.type==4){pg::WGCGuild g;if(g.read(r))guild=g;}
    else if(v.type==10){pg::WGCZhengTao g;if(g.read(r)&&g.sub_type<4){auto& a=wars[g.sub_type];a.clear();for(auto& m:g.list)if(m.id>=0&&!m.name_text().empty())a.push_back(m);if(g.sub_type<2)Event("GUILD_SHOW_ENEMYLIST");else Event("GUILD_SHOW_GUILDBATTLE",{g.sub_type==3?"0":"1"});TDU_Log("CYS guild war: type=%u count=%u",g.sub_type,(unsigned)a.size());}}
    else if(v.type==11){pg::WGCNoitceBeWar n;if(n.read(r)){Ask(2);Event("NEW_DEBUGMESSAGE",{u8"Bang hội nhận được lời tuyên chiến. Mở mục Tuyên chiến để xem và ứng chiến."});}}
    return true;
}
void RegisterHost(){auto r=Receiver(CScriptSystem::GetMe()->GetLuaState()->GetGlobals(),"City");r.Register("AskEnemyList",EnemyList);r.Register("AskBattleList",BattleList);r.Register("GetEnemyNum",EnemyCount);r.Register("GetBattleNum",BattleCount);r.Register("EnumCityEnemy",EnumEnemy);r.Register("EnumBattleGuild",EnumBattle);r.Register("SendAddEnemyMsg",DeclareEnemy);r.Register("SendAddGuildBattleMsg",DeclareBattle);r.Register("OpenAddEnemyDlg",OpenEnemy);r.Register("SelectGuildBattle",SelectBattle);r.Register("ReponseGuildBattle",AcceptBattle);r.Register("GetGuildListWithCity",AskGuilds);r.Register("GetGuildNumByZoneWorldId",GuildCount);r.Register("GetGuildInfoBigWorld",GuildInfo);r.Register("OpenGuildWarDlg",Open);r.Register("OpenNewGuildWarDlg",Open);}
}
