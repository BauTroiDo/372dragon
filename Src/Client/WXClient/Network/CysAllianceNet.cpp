#include "StdAfx.h"
#include "CysAllianceNet.h"
#include "PgPackets_social.h"
#include <map>
#include "CysModernGame.h"
#include "PgPackets_city.h"
#include "PgPackets_misc.h"
#include "../DataPool/GMDP_CharacterData.h"
#include "../Object/ObjectManager.h"
#include "../Object/Character/Obj_PlayerMySelf.h"
#include "../Script/GMScriptSystem.h"
#include "../Event/GMEventSystem.h"
#include "LuaPlus.h"
#include "TDUtil.h"
namespace CysAllianceNet { namespace {
pg::WGCGuildLeagueInfo info;
pg::WGCGuildLeagueList list;
pg::WGCGuildLeagueMemberApplyList apps;
std::map<int,pg::GCGuild> guildDetails;
std::map<unsigned,int> pendingDetails;
unsigned detailSerial=0x50000000;
int membershipId=-1;
void Event(const char* n,const std::vector<STRING>& a={}){CEventSystem::GetMe()->PushEventByName(n,a);}
void Send(std::unique_ptr<pg::Packet> p){CysModernGame::SendModern(std::move(p));}
template<class T> std::unique_ptr<T> New(){return std::unique_ptr<T>(new T);}
int Num(LuaPlus::LuaState* s,int i,int d=-1){LuaPlus::LuaStack a(s);return a[i].IsNumber()?int(a[i].GetNumber()):d;}
std::string Str(LuaPlus::LuaState* s,int i){LuaPlus::LuaStack a(s);return a[i].IsString()?a[i].GetString():"";}
std::string Date(uint32_t n){auto t=std::to_string(n);return t.size()==10?t.substr(4,2)+"/"+t.substr(2,2)+"/20"+t.substr(0,2):"";}
template<class T> const T* Row(const std::vector<T>& v,int i){return i>=0&&i<(int)v.size()?&v[i]:nullptr;}
int RequestList(LuaPlus::LuaState*){Send(New<pg::CGWGuildLeagueList>());return 0;}
int RequestInfo(LuaPlus::LuaState*){auto p=New<pg::CGWGuildLeagueInfo>();p->league_id=info.league_id;Send(std::move(p));return 0;}
int RequestApps(LuaPlus::LuaState*){Send(New<pg::CGWGuildLeagueMemberApplyList>());return 0;}
int ShowList(LuaPlus::LuaState*){Event("GUILD_LEAGUE_LIST");return 0;}
int ShowInfo(LuaPlus::LuaState*){Event("GUILD_LEAGUE_INFO");return 0;}
int ShowApps(LuaPlus::LuaState*){Event("GUILD_LEAGUE_APPLY_LIST");return 0;}
int ShowCreate(LuaPlus::LuaState*){Event("GUILD_LEAGUE_CREATE");return 0;}
int ShowQuit(LuaPlus::LuaState*){Event("GUILD_LEAGUE_QUIT_CONFIRM",{info.name_text()});return 0;}
int ConfirmCreate(LuaPlus::LuaState* s){auto n=Str(s,2),d=Str(s,3);int rc=n.empty()||n.size()>31?-1:d.size()>63?-2:1;if(rc==1)Event("GUILD_LEAGUE_CREATE_CONFIRM",{n,d});s->PushInteger(rc);return 1;}
int Create(LuaPlus::LuaState* s){auto n=Str(s,2),d=Str(s,3);int rc=n.empty()||n.size()>31?-1:d.size()>63?-2:1;if(rc==1){auto p=New<pg::CGCreateGuildLeague>();p->set_name(n);p->set_desc(d);Send(std::move(p));}s->PushInteger(rc);return 1;}
int Quit(LuaPlus::LuaState*){Send(New<pg::CGWGuildLeagueQuit>());return 0;}
int Ask(LuaPlus::LuaState* s){int id=Num(s,2);if(id>=0){auto p=New<pg::CGWGuildLeagueAskEnter>();p->league_id=id;Send(std::move(p));}return 0;}
int Answer(LuaPlus::LuaState* s){auto p=New<pg::CGWGuildLeagueAnswerEnter>();p->guild_id=Num(s,2);p->answer=Num(s,3);if(p->guild_id>=0&&(p->answer==0||p->answer==1))Send(std::move(p));return 0;}
int Fire(LuaPlus::LuaState* s){int id=Num(s,3);if(id>=0&&id<32768){auto p=New<pg::CGCGWPacket>();p->type=7;p->data={0,0,(uint8_t)id,(uint8_t)(id>>8)};p->len=4;Send(std::move(p));}return 0;}
int ListCount(LuaPlus::LuaState* s){s->PushInteger((int)list.leagues.size());return 1;}
int MemberCount(LuaPlus::LuaState* s){s->PushInteger((int)info.guilds.size());return 1;}
int ApplyCount(LuaPlus::LuaState* s){s->PushInteger((int)apps.guilds.size());return 1;}
#define TOP_S(name,field) int name(LuaPlus::LuaState* s){s->PushString(info.field().c_str());return 1;}
#define TOP_N(name,field) int name(LuaPlus::LuaState* s){s->PushInteger(info.field);return 1;}
#define ROW_S(name,container,field) int name(LuaPlus::LuaState* s){auto p=Row(container,Num(s,2));s->PushString(p?p->field().c_str():"");return 1;}
#define ROW_N(name,container,field) int name(LuaPlus::LuaState* s){auto p=Row(container,Num(s,2));s->PushInteger(p?p->field:0);return 1;}
#define ROW_D(name,container,field) int name(LuaPlus::LuaState* s){auto p=Row(container,Num(s,2));s->PushString(p?Date(p->field).c_str():"");return 1;}
TOP_S(GetName,name_text) TOP_S(GetDescription,desc_text) TOP_S(GetChieftain,chief_name_text) TOP_S(GetCreator,creator_text)
TOP_N(GetID,league_id) TOP_N(GetChieftainGUID,chief_guid) TOP_N(GetUserCount,member_count)
int GetMemberCityLevel(LuaPlus::LuaState* s){auto p=Row(info.guilds,Num(s,2));auto i=p?guildDetails.find(p->id):guildDetails.end();s->PushString(i!=guildDetails.end()?std::to_string(i->second.level).c_str():"");return 1;}
int GetMemberCityScene(LuaPlus::LuaState* s){auto p=Row(info.guilds,Num(s,2));auto i=p?guildDetails.find(p->id):guildDetails.end();s->PushString(i!=guildDetails.end()?i->second.city_name_text().c_str():"");return 1;}
int GetMemberCreateTime(LuaPlus::LuaState* s){auto p=Row(info.guilds,Num(s,2));auto i=p?guildDetails.find(p->id):guildDetails.end();s->PushString(i!=guildDetails.end()?Date(i->second.founded_time).c_str():"");return 1;}
int GetCreateTime(LuaPlus::LuaState* s){s->PushString(Date(info.founded_time).c_str());return 1;}
ROW_S(GetMemberName,info.guilds,name_text) ROW_S(GetMemberChieftain,info.guilds,chief_name_text)
ROW_N(GetMemberID,info.guilds,id) ROW_N(GetMemberChieftainGUID,info.guilds,chief_guid) ROW_N(GetMemberUserCount,info.guilds,member_count) ROW_D(GetMemberEnterTime,info.guilds,join_date)
ROW_S(GetLeagueName,list.leagues,name_text) ROW_S(GetLeagueDescription,list.leagues,desc_text) ROW_S(GetLeagueChieftain,list.leagues,chief_name_text)
ROW_N(GetLeagueID,list.leagues,id) ROW_N(GetLeagueMemberCount,list.leagues,guild_count) ROW_D(GetLeagueCreateTime,list.leagues,founded_time)
ROW_S(GetApplyGuildName,apps.guilds,name_text) ROW_S(GetApplyGuildDescription,apps.guilds,desc_text) ROW_S(GetApplyGuildChieftain,apps.guilds,chief_name_text) ROW_S(GetApplyGuildCity,apps.guilds,city_name_text)
ROW_N(GetApplyGuildID,apps.guilds,id) ROW_N(GetApplyGuildLevel,apps.guilds,level) ROW_N(GetApplyGuildUserCount,apps.guilds,member_count) ROW_D(GetApplyGuildCreateTime,apps.guilds,founded_time)
#undef TOP_S
#undef TOP_N
#undef ROW_S
#undef ROW_N
#undef ROW_D
LuaPlus::LuaObject Receiver(LuaPlus::LuaObject g,const char* n){auto o=g.GetByName(n);if(o.IsTable())return o;if(o.IsUserData()){auto m=o.GetMetaTable();if(m.IsTable()){auto i=m.GetByName("__index");return i.IsTable()?i:m;}}return LuaPlus::LuaObject();}
}
int MyLeagueId(){return membershipId;}
void OnMembership(int id){membershipId=id;if(id<0){info=pg::WGCGuildLeagueInfo();info.league_id=-1;guildDetails.clear();pendingDetails.clear();}}
void Reset(){membershipId=-1;guildDetails.clear();pendingDetails.clear();detailSerial=0x50000000;info=pg::WGCGuildLeagueInfo();info.league_id=-1;list=pg::WGCGuildLeagueList();apps=pg::WGCGuildLeagueMemberApplyList();}
bool IsWorldPacket(unsigned short id){return id==332||id==728||id==518;}
bool Dispatch(const pg::Packet& p){
if(p.packetId()==pg::GCGuild::PACKET_ID){auto& q=static_cast<const pg::GCGuild&>(p);auto i=pendingDetails.find(q.askid);if(i==pendingDetails.end()||(q.packet_type!=50&&q.packet_type!=59))return false;guildDetails[i->second]=q;pendingDetails.erase(i);Event("UPDATE_GUILD_LEAGUE_INFO");return true;}
switch(p.packetId()){
case 332:info=static_cast<const pg::WGCGuildLeagueInfo&>(p);membershipId=info.league_id;pendingDetails.clear();guildDetails.clear();for(auto& g:info.guilds){auto r=New<pg::CGGuild>();r->packet_type=3;r->type=5;r->guild_id=g.id;r->askid=++detailSerial;pendingDetails[r->askid+1]=g.id;Send(std::move(r));}Event("UPDATE_GUILD_LEAGUE_INFO");TDU_Log("CYS alliance: id=%d guilds=%u",info.league_id,(unsigned)info.guilds.size());return true;
case 728:list=static_cast<const pg::WGCGuildLeagueList&>(p);Event("UPDATE_GUILD_LEAGUE_LIST");return true;
case 518:apps=static_cast<const pg::WGCGuildLeagueMemberApplyList&>(p);Event("UPDATE_GUILD_LEAGUE_APPLY_LIST");return true;
default:return false;}}
void RegisterHost(){auto r=Receiver(CScriptSystem::GetMe()->GetLuaState()->GetGlobals(),"GuildLeague");
    r.Register("RequestList",RequestList);r.Register("RequestInfo",RequestInfo);r.Register("RequestApplyList",RequestApps);r.Register("ShowListWindow",ShowList);r.Register("ShowInfoWindow",ShowInfo);r.Register("ShowApplyListWindow",ShowApps);r.Register("ShowCreateWindow",ShowCreate);r.Register("ShowQuitConfirmWindow",ShowQuit);r.Register("ShowCreateConfirmWindow",ConfirmCreate);r.Register("Create",Create);r.Register("Quit",Quit);r.Register("AskEnter",Ask);r.Register("AnswerEnter",Answer);r.Register("FireGuild",Fire);r.Register("GetLeagueCount",ListCount);r.Register("GetMemberCount",MemberCount);r.Register("GetApplyGuildCount",ApplyCount);
#define BIND(name) r.Register(#name,name)
    BIND(GetMemberCityLevel);BIND(GetMemberCityScene);BIND(GetMemberCreateTime);BIND(GetName);BIND(GetDescription);BIND(GetChieftain);BIND(GetCreator);BIND(GetID);BIND(GetChieftainGUID);BIND(GetUserCount);BIND(GetCreateTime);BIND(GetMemberName);BIND(GetMemberChieftain);BIND(GetMemberID);BIND(GetMemberChieftainGUID);BIND(GetMemberUserCount);BIND(GetMemberEnterTime);BIND(GetLeagueName);BIND(GetLeagueDescription);BIND(GetLeagueChieftain);BIND(GetLeagueID);BIND(GetLeagueMemberCount);BIND(GetLeagueCreateTime);BIND(GetApplyGuildName);BIND(GetApplyGuildDescription);BIND(GetApplyGuildChieftain);BIND(GetApplyGuildCity);BIND(GetApplyGuildID);BIND(GetApplyGuildLevel);BIND(GetApplyGuildUserCount);BIND(GetApplyGuildCreateTime);
#undef BIND
}
}
