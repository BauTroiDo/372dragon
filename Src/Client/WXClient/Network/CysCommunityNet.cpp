#include "StdAfx.h"
#include "CysCommunityNet.h"
#include "CysModernGame.h"
#include "PgPackets_misc.h"
#include "PgPackets_social.h"
#include "PgPackets_combat.h"
#include "CGRelation.h"
#include "CGCharAllTitles.h"
#include "CGCharUpdateCurTitle.h"
#include "../Script/GMScriptSystem.h"
#include "../Event/GMEventSystem.h"
#include "../Object/ObjectManager.h"
#include "../Object/Character/Obj_PlayerMySelf.h"
#include "../DataPool/GMDP_CharacterData.h"
#include "../DataPool/GMDataPool.h"
#include "../DataPool/GMDP_Struct_Relation.h"
#include "../DBC/GMDataBase.h"
#include "TDDBC_Struct.h"
#include "../DBC/CysTitleMetadata.h"
#include "../Procedure/CysAccelTable.h"
#include "TDUtil.h"
#include "LuaPlus.h"
#include <algorithm>
#include <map>
#include <vector>
namespace CysCommunityNet {
namespace {
struct Member {int guid=0,group=0,type=0,point=0,level=0,menpai=0,portrait=0,scene=0,team=0;bool online=false;std::string name,mood,title,guild;};
struct Title {int id=0,type=0,remaining=0;bool numeric=false;std::string text;};
std::vector<Member> members;
std::vector<Title> titles;
Member inspected;
std::string mood,currentTitle;
int currentType=0;
LuaPlus::LuaObject Receiver(LuaPlus::LuaObject g,const char* name) {
    auto o=g.GetByName(name);if(o.IsTable())return o;
    if(o.IsUserData()){auto m=o.GetMetaTable();if(m.IsTable()){auto i=m.GetByName("__index");return i.IsTable()?i:m;}}
    return LuaPlus::LuaObject();
}
void Event(const char* name,const std::vector<STRING>& args={}) {CEventSystem::GetMe()->PushEventByName(name,args);}
void Tip(const char* message){Event("NEW_DEBUGMESSAGE",{message});}
int Num(LuaPlus::LuaStack& a,int i,int def=0){if(a[i].IsNumber())return int(a[i].GetNumber());if(a[i].IsString()){char* end=nullptr;const char* value=a[i].GetString();long n=strtol(value,&end,10);if(end!=value&&!*end)return int(n);}return def;}
std::string Str(LuaPlus::LuaStack& a,int i){return !a[i].IsNumber()&&a[i].IsString()?a[i].GetString():"";}
bool Send(std::unique_ptr<pg::Packet> p){return CysModernGame::SendModern(std::move(p));}
std::unique_ptr<pg::CGRelation> Request(int type){std::unique_ptr<pg::CGRelation> p(new pg::CGRelation);p->type=type;p->request_relation_info_guid=-1;return p;}
Member* ByGuid(int id){for(auto& m:members)if(m.guid==id)return &m;return nullptr;}
Member* At(int group,int index){if(index<0)return nullptr;for(auto& m:members)if(m.group==group || (group==0&&m.group>=1&&m.group<=4)){if(index--==0)return &m;}return nullptr;}
void Remove(int id){members.erase(std::remove_if(members.begin(),members.end(),[id](const Member& m){return m.guid==id;}),members.end());}
void Upsert(const Member& m){if(!m.guid)return;auto old=ByGuid(m.guid);if(old)*old=m;else members.push_back(m);}
void Refresh(){Event("UPDATE_FRIEND");}
int Count(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);int n=0;for(int i=0;At(Num(a,2),i);++i)++n;s->PushInteger(n);return 1;}
int OnlineCount(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);int n=0;for(int i=0;auto m=At(Num(a,2),i);++i)if(m->online)++n;s->PushInteger(n);return 1;}
int GetFriend(LuaPlus::LuaState* s){
    LuaPlus::LuaStack a(s);bool chat=Str(a,2)=="chat";auto m=chat?&inspected:At(Num(a,2),Num(a,3));const std::string key=Str(a,chat?3:4);
    Member empty;if(!m)m=&empty;
    if(key=="ONLINE")s->PushBoolean(m->online);
    else if(key=="IS_SPOUSE")s->PushInteger(m->type==3?1:0);
    else if(key=="NAME")s->PushString(m->name.c_str());
    else if(key=="MOOD")s->PushString(m->mood.c_str());
    else if(key=="TITLE")s->PushString(TransTitleStr(m->title.c_str()));
    else if(key=="GUILD_NAME"||key=="GUID_NAME")s->PushString(m->guild.c_str());
    else if(key=="PORTRAIT"){DBC_DEFINEHANDLE(db,DBC_CHARACTER_FACE);auto face=db?reinterpret_cast<const _DBC_CHAR_FACE*>(db->Search_Index_EQU(m->portrait)):nullptr;if(!face&&db)face=reinterpret_cast<const _DBC_CHAR_FACE*>(db->Search_Index_EQU(1));s->PushString(face&&face->pImageSetName?face->pImageSetName:"");}
    else if(key=="REMARK"||key=="GUILD_LEAGUE_NAME"||key=="HEADFRAME"||key=="HEADFRAMEANIMATE")s->PushString("");
    else if(key=="ZONEWORLDID")s->PushInteger(-1);
    else if(key=="RELATION_TEXT")s->PushString(m->group==5?u8"Danh sách chặn":m->group==6?u8"Kẻ thù":u8"Bạn bè");
    else if(key=="SCENE"){DBC_DEFINEHANDLE(db,DBC_SCENE_DEFINE);auto scene=db?reinterpret_cast<const _DBC_SCENE_DEFINE*>(db->Search_Index_EQU(m->scene)):nullptr;s->PushString(!m->online?u8"Ngoại tuyến":scene&&scene->szName?scene->szName:u8"Không rõ");}
    else if(key=="TEAM_NUMBER")s->PushString(std::to_string(m->team).c_str());
    else if(key=="ID_TEXT")s->PushInteger(m->guid);
    else if(key=="MENPAI_TEXT"){
        // Server's contiguous sect IDs, also used by the GL GM import.
        static const char* names[]={u8"Thiếu Lâm",u8"Minh Giáo",u8"Cái Bang",u8"Võ Đang",u8"Nga Mi",u8"Tinh Túc",u8"Thiên Long",u8"Thiên Sơn",u8"Tiêu Dao",u8"Không có phái",u8"Mộ Dung",u8"Đường Môn",u8"Quỷ Cốc",u8"Đào Hoa Đảo",u8"Tuyệt Tình Cốc",u8"Ác Nhân Cốc"};
        s->PushString(m->menpai>=0&&m->menpai<16?names[m->menpai]:u8"Không rõ");
    }
    else {int n=0;if(key=="ID")n=m->guid;else if(key=="RELATION_TYPE")n=m->type;else if(key=="FRIENDSHIP")n=m->point;else if(key=="LEVEL")n=m->level;else if(key=="MENPAI_TYPE")n=m->menpai;else if(key=="PORTRAIT")n=m->portrait;s->PushInteger(n);}
    return 1;
}
int FindFriend(LuaPlus::LuaState* s,bool byName){LuaPlus::LuaStack a(s);int group=-1,index=-1;for(auto& m:members)if(byName?m.name==Str(a,2):m.guid==Num(a,2)){group=m.group;for(int i=0;auto x=At(group,i);++i)if(x->guid==m.guid){index=i;break;}break;}s->PushInteger(group);s->PushInteger(index);return 2;}
int FindName(LuaPlus::LuaState* s){return FindFriend(s,true);}int FindGuid(LuaPlus::LuaState* s){return FindFriend(s,false);}
int AddFriend(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);int group=Num(a,2,1);if(group==0)group=1;if(group<1||group>7)return 0;auto p=Request(group==5?5:4);p->request_relation_info_relation_type=group==5?4:1;p->request_relation_info_group=group;
    if(a[3].IsNumber())p->request_relation_info_guid=Num(a,3);else if(a[3].IsString())p->set_request_relation_info_name(Str(a,3));else {auto target=dynamic_cast<CObject_Character*>(CObjectManager::GetMe()->GetMainTarget());if(!target)return 0;auto data=target->GetCharacterData();if(!data)return 0;p->set_request_relation_info_name(data->Get_Name());}
    if(group!=5 && group>4)return 0;Send(std::move(p));return 0;}
int DeleteFriend(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);auto m=At(Num(a,2),Num(a,3));if(!m)return 0;auto p=Request(9);p->request_relation_info_guid=m->guid;Send(std::move(p));return 0;}
int MoveFriend(LuaPlus::LuaState* s,bool black){LuaPlus::LuaStack a(s);auto m=At(Num(a,2),Num(a,3));int to=black?5:Num(a,4);if(!m||to<1||to>5||to==m->group)return 0;auto p=Request(8);p->request_relation_info_guid=m->guid;p->request_relation_info_from=m->group==13?7:m->group;p->request_relation_info_to=to;Send(std::move(p));return 0;}
int Move(LuaPlus::LuaState* s){return MoveFriend(s,false);}int Black(LuaPlus::LuaState* s){return MoveFriend(s,true);}
int Info(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);auto p=Request(2);int group=Num(a,2,-1),index=Num(a,3,-1);auto m=At(group,index);if(m)p->request_relation_info_guid=m->guid;else if(a[2].IsString())p->set_request_relation_info_name(Str(a,2));else return 0;Send(std::move(p));if(group>0)Event("TOGLE_FRIEND_INFO",{std::to_string(group),std::to_string(index)});return 0;}
int OpenChat(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);auto m=At(Num(a,2),Num(a,3));if(m&&m->group!=5){inspected=*m;Event("CHAT_CHANGE_PRIVATENAME",{m->name});CysAccel::SetChatting(true);}return 0;}
int RefreshLists(LuaPlus::LuaState*){RequestLists();return 0;}
int IMIcons(LuaPlus::LuaState* s){for(int i=0;i<4;++i)s->PushInteger(0);return 4;}
int GetMood(LuaPlus::LuaState* s){s->PushString(mood.c_str());return 1;}
const CysTitleMetadata::Entry* TitleDef(int id){return CysTitleMetadata::Find(id);}
std::string TitleName(const Title& t){auto d=t.numeric?TitleDef(t.id):nullptr;return t.numeric?(d&&d->name?d->name:std::string(u8"Danh hiệu #")+std::to_string(t.id)):t.text;}
bool Current(const Title& t){return t.numeric?currentTitle=="#"+std::to_string(t.id):currentType==t.id && currentTitle==t.text;}
int TitleCount(LuaPlus::LuaState* s){s->PushInteger((int)titles.size());return 1;}
int TitleAt(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);int i=Num(a,2,-1);Title empty;auto& t=i>=0&&i<(int)titles.size()?titles[i]:empty;auto d=t.numeric?TitleDef(t.id):nullptr;s->PushString(TitleName(t).c_str());s->PushInteger(t.id);s->PushInteger(t.numeric?1:0);s->PushInteger(t.remaining);s->PushInteger(Current(t)?1:0);s->PushString(d&&d->description?d->description:"");s->PushString(d&&d->source?d->source:"");s->PushString(d?d->attributes:"");return 8;}
int SelectTitle(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);int i=Num(a,2,-1);if(i<0||i>=(int)titles.size())return 0;auto& t=titles[i];std::unique_ptr<pg::CGCharUpdateCurTitle> p(new pg::CGCharUpdateCurTitle);p->id=t.numeric?0:t.id;p->id_title_id=t.numeric?t.id:0;Send(std::move(p));return 0;}
int ClearTitle(LuaPlus::LuaState*){std::unique_ptr<pg::CGCharUpdateCurTitle> p(new pg::CGCharUpdateCurTitle);p->id=0;p->id_title_id=0;Send(std::move(p));return 0;}
void OnRelation(const pg::GCRelation& p){
    if(p.type==1){members.clear();mood=p.relation_list_mood;
        for(auto& v:p.relation_list_friends){Member m;m.guid=v.guid;m.name=v.name;m.mood=v.mood;m.group=v.group;m.type=v.relation_type;m.point=v.friend_point;m.portrait=v.portrait;Upsert(m);}
        for(auto& v:p.relation_list_black){Member m;m.guid=v.guid;m.name=v.name;m.mood=v.mood;m.group=5;m.type=4;Upsert(m);}
        for(auto& v:p.relation_list_enemies){Member m;m.guid=v.guid;m.name=v.name;m.mood=v.mood;m.group=6;m.type=9;Upsert(m);}
        for(auto& v:p.relation_list_temp){Member m;m.guid=v.guid;m.name=v.name;m.group=13;m.type=5;Upsert(m);}
    }else if(p.type==2){auto old=ByGuid(p.relation_info_relation_guid);Member m=old?*old:Member();m.guid=p.relation_info_relation_guid;m.name=p.relation_info_relation_name;m.group=old?old->group:p.relation_info_group;m.type=p.relation_info_relation_type;m.point=p.relation_info_friend_point;m.level=p.relation_info_relation_level;m.menpai=p.relation_info_relation_menpai;m.portrait=p.relation_info_relation_portrait;m.online=p.relation_info_relation_online_flag!=0;m.mood=p.relation_info_relation_mood;m.title=p.relation_info_relation_title;m.guild=p.relation_info_relation_guild_name;m.scene=p.relation_info_relation_sceneid;m.team=p.relation_info_relation_team_size;inspected=m;if(old)Upsert(m);if(old){for(int i=0;auto x=At(m.group,i);++i)if(x->guid==m.guid){Event("UPDATE_FRIEND_INFO",{std::to_string(m.group),std::to_string(i),"0"});break;}}
    }else if(p.type>=5&&p.type<=8){Member m;m.guid=p.relation_info_guid;m.name=p.relation_info_name;m.group=p.relation_info_group;m.type=p.relation_info_relation_type;m.point=p.relation_info_friend_point;m.level=p.relation_info_level;m.menpai=p.relation_info_menpai;m.portrait=p.relation_info_portrait;m.online=p.relation_info_online_flag!=0;m.mood=p.relation_info_mood;m.title=p.relation_info_title;m.guild=p.relation_info_guild_name;m.scene=p.relation_info_sceneid;m.team=p.relation_info_team_size;Upsert(m);
    }else if(p.type==9){auto m=ByGuid(p.relation_guid_uchar_uchar_guid);if(m){m->group=p.relation_guid_uchar_uchar_group;m->type=p.relation_guid_uchar_uchar_relation_type;}}
    else if(p.type==10||p.type==11)Remove(p.del_relation_guid);
    else if(p.type==13){for(auto& m:members)m.online=false;for(auto& v:p.online_friends_list){auto m=ByGuid(v.guid);if(m){m->online=true;m->mood=v.mood;}}}
    else if(p.type==14){auto m=ByGuid(p.relation_online_guid);if(m){m->online=true;m->mood=p.relation_online_mood;}}
    else if(p.type==15){auto m=ByGuid(p.del_relation_guid);if(m)m->online=false;}
    else if(p.type==16)mood=p.new_mood_mood;
    else if(p.type>=26){const char* text=p.type==26?u8"Không tìm thấy nhân vật.":p.type==27?u8"Nhóm bạn bè đã đầy.":p.type==28?u8"Nhân vật đã có trong Bạn bè.":p.type==29?u8"Nhân vật đang ở danh sách chặn.":p.type==42?u8"Nhân vật từ chối kết bạn.":u8"Không thể thực hiện thao tác quan hệ này.";Tip(text);}
    TDU_Log("CYS community: relation type=%u members=%u",p.type,(unsigned)members.size());Refresh();
}
}
bool IsBlocked(const char* name){if(!name||!*name)return false;for(auto& m:members)if(m.group==5&&m.name==name)return true;return false;}
void Reset(){members.clear();titles.clear();mood.clear();currentTitle.clear();currentType=0;inspected=Member();}
void RequestLists(){Send(Request(1));Send(std::unique_ptr<pg::Packet>(new pg::CGCharAllTitles));}
void Base(const pg::GCCharBaseAttrib& p){auto self=CObjectManager::GetMe()->GetMySelf();if(!self||p.m_objID!=self->GetServerID())return;int64_t f[11]={},extra=0,extra2=0;pg::deriveCharBaseAttribFlags(p.new_flags.data(),f,&extra,&extra2);if(f[0]&4){currentTitle=p.m_szTitle;currentType=p.m_TitleType;Event("CYS_TITLES_CHANGED");}}
bool IsWorldPacket(unsigned short id){return id==pg::GCRelation::PACKET_ID||id==pg::GCCharAllTitles::PACKET_ID;}
bool Dispatch(const pg::Packet& packet){if(packet.packetId()==pg::GCRelation::PACKET_ID){OnRelation(static_cast<const pg::GCRelation&>(packet));return true;}if(packet.packetId()==pg::GCCharAllTitles::PACKET_ID){const auto& p=static_cast<const pg::GCCharAllTitles&>(packet);auto self=CObjectManager::GetMe()->GetMySelf();if(!self||p.m_objID!=self->GetServerID())return true;titles.clear();for(auto& v:p.m_TitleIdList){Title t;t.numeric=true;t.id=v.id;t.remaining=v.remain_time;titles.push_back(t);}for(auto& v:p.m_TitleStrList){Title t;t.id=v.id;t.text=v.str;titles.push_back(t);}TDU_Log("CYS community: titles=%u",(unsigned)titles.size());Event("CYS_TITLES_CHANGED");return true;}return false;}
std::unique_ptr<pg::Packet> Translate(Packet* legacy){
    if(legacy->GetPacketID()==PACKET_CG_CHARALLTITLES)return std::unique_ptr<pg::Packet>(new pg::CGCharAllTitles);
    if(legacy->GetPacketID()!=PACKET_CG_RELATION)return nullptr;
    auto& r=*static_cast<Packets::CGRelation*>(legacy)->GetRelation();auto p=Request(r.m_Type);
    if(r.m_Type==REQ_RELATIONINFO){p->request_relation_info_guid=r.m_RequestInfo.GetTargetGUID();p->set_request_relation_info_name(r.m_RequestInfo.GetTargetName());}
    else if(r.m_Type==REQ_ADDFRIEND){auto& v=r.m_AddRelationWithGroup;p->request_relation_info_guid=v.GetTargetGUID();p->set_request_relation_info_name(v.GetTargetName());p->request_relation_info_relation_type=v.GetRelationType();p->request_relation_info_group=v.GetGroup();}
    else if(r.m_Type==REQ_MODIFYMOOD)p->set_request_relation_info_mood(r.m_ModifyMood.GetMood());
    else if(r.m_Type!=REQ_RELATIONLIST)return nullptr;
    return std::move(p);
}
void RegisterHost(){auto s=CScriptSystem::GetMe()->GetLuaState();auto g=s->GetGlobals();auto d=Receiver(g,"DataPool");d.Register("GetFriendNumber",Count);d.Register("GetFriendNumberCommon",Count);d.Register("GetFriendOnlineNumberCommon",OnlineCount);d.Register("GetFriend",GetFriend);d.Register("GetFriendByName",FindName);d.Register("GetFriendByGUID",FindGuid);d.Register("AddFriend",AddFriend);d.Register("DelFriend",DeleteFriend);d.Register("ThrowToBlackList",Black);d.Register("ThrowToList",Move);d.Register("ShowFriendInfo",Info);d.Register("ShowChatInfo",Info);d.Register("Open1On1Chat",OpenChat);d.Register("CysRefreshCommunity",RefreshLists);d.Register("GetMood",GetMood);d.Register("GetIMIconNum",IMIcons);auto p=Receiver(g,"Player");p.Register("CysTitleCount",TitleCount);p.Register("CysTitleAt",TitleAt);p.Register("AskChangeCurrentAgname",SelectTitle);p.Register("SetNullAgname",ClearTitle);p.Register("CysRefreshTitles",RefreshLists);}
}
