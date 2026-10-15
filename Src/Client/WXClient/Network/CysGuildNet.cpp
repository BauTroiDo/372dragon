#include "StdAfx.h"
#include "CysGuildNet.h"
#include "CysModernGame.h"
#include "PgPackets_social.h"
#include "CGGuild.h"
#include "CGGuildApply.h"
#include "CGGuildJoin.h"
#include "../DataPool/GMDataPool.h"
#include "../DataPool/GMDP_Struct_Guild.h"
#include "../DataPool/GMDP_CharacterData.h"
#include "../Object/ObjectManager.h"
#include "../Object/Character/Obj_PlayerMySelf.h"
#include "../Script/GMScriptSystem.h"
#include "../Event/GMEventSystem.h"
#include "LuaPlus.h"
#include "TDUtil.h"
#include <algorithm>
#include <map>

namespace CysGuildNet {
namespace {
pg::GCGuild roster,detail,list,selfInfo,officials;
unsigned serial=1;
int selectedGuid=-1;
int detailId=-1;
std::map<unsigned,int> detailRequests;
bool openMembers=false;
int GuildId(){auto s=CObjectManager::GetMe()->GetMySelf();return s?s->GetCharacterData()->Get_Guild():-1;}
int MyGuid(){auto s=CObjectManager::GetMe()->GetMySelf();return s?s->GetServerGUID():-1;}
void Event(const char* n,const std::vector<STRING>& a={}){CEventSystem::GetMe()->PushEventByName(n,a);}
void Tip(const char* n){Event("NEW_DEBUGMESSAGE",{n});}
template<class T>std::unique_ptr<T> New(){return std::unique_ptr<T>(new T);}
void Send(std::unique_ptr<pg::Packet> p){CysModernGame::SendModern(std::move(p));}
std::unique_ptr<pg::CGGuild> Request(int op){auto p=New<pg::CGGuild>();p->packet_type=op;p->askid=++serial;p->guild_id=GuildId();return p;}
void Ask(int type,int guild=-2){auto p=Request(3);p->type=type;if(guild!=-2)p->guild_id=guild;if(type==1||type==5){if(detailRequests.size()>32)detailRequests.clear();detailRequests[p->askid+1]=p->guild_id;}Send(std::move(p));}
void Refresh(){if(GuildId()>=0){Ask(3);Ask(0);}}
void SetGuild(int id){auto s=CObjectManager::GetMe()->GetMySelf();if(s)s->GetCharacterData()->Set_Guild(id);if(id<0){roster=pg::GCGuild();detail=pg::GCGuild();selfInfo=pg::GCGuild();auto d=CDataPool::GetMe();d->Guild_ClearMemInfo();d->Guild_SetMemInfoNum(0);d->Guild_SetName("");d->Guild_SetDesc("");d->Guild_SetCurPosition(0);d->Guild_SetCurAccess(0);Event("GUILD_FORCE_CLOSE");}}
LuaPlus::LuaObject Receiver(LuaPlus::LuaObject g,const char* name){auto o=g.GetByName(name);if(o.IsTable())return o;if(o.IsUserData()){auto m=o.GetMetaTable();if(m.IsTable()){auto i=m.GetByName("__index");return i.IsTable()?i:m;}}return LuaPlus::LuaObject();}
int Num(LuaPlus::LuaState* s,int i,int def=0){LuaPlus::LuaStack a(s);return a[i].IsNumber()?int(a[i].GetNumber()):def;}
std::string Str(LuaPlus::LuaState* s,int i){LuaPlus::LuaStack a(s);return a[i].IsString()?a[i].GetString():"";}
std::string Date(uint32_t n){if(!n)return "";std::string t=std::to_string(n);if(t.size()!=10)return t;return t.substr(4,2)+"/"+t.substr(2,2)+"/20"+t.substr(0,2)+" "+t.substr(6,2)+":"+t.substr(8,2);}
const char* Position(int p){static const char* names[]={"",u8"Dự bị",u8"Bang chúng",u8"Tinh anh",u8"Thương nhân",u8"Hoằng hóa sứ",u8"Công vụ sứ",u8"Nội vụ sứ",u8"Phó bang chủ",u8"Bang chủ"};return p>=0&&p<10?names[p]:"";}
void OnGuild(const pg::GCGuild& p){auto d=CDataPool::GetMe();
    if(p.packet_type==48||p.packet_type==57){list=p;d->Guild_ClearAllInfo();for(size_t i=0;i<p.guild_list.size();++i){auto& v=p.guild_list[i];GuildInfo_t m;m.m_GuildID=v.id;m.m_GuildName=v.name_text();m.m_GuildDesc=v.desc_text();m.m_ChiefName=v.chief_name_text();m.m_CityName=v.city_name_text();m.m_PortSceneID=v.port_scene_id;m.m_uGuildStatus=v.status;m.m_uGuildUserCount=(UCHAR)(std::min)(v.user_count,255);m.m_bGuildLevel=v.level;m.m_nFoundedTime=v.founded_time;d->Guild_SetInfoByIndex((int)i,&m);}d->Guild_SetInfoNum((int)p.guild_list.size());Event("GUILD_SHOW_LIST");}
    else if(p.packet_type==49||p.packet_type==58){
        // Public officer inspection must not replace this character's guild or powers.
        if(p.unknow_8==5){officials=p;std::stable_sort(officials.memberlist.begin(),officials.memberlist.end(),[](const pg::GCGuild::E_memberlist& a,const pg::GCGuild::E_memberlist& b){return a.position>b.position;});Event("GUILD_SHOW_OFFICIALLIST");return;}
        roster=p;d->Guild_ClearMemInfo();for(size_t i=0;i<p.memberlist.size();++i){auto& v=p.memberlist[i];GuildMemberInfo_t m;m.m_Guid=v.guid;m.m_szName=v.name_text();m.m_bLevel=v.level;m.m_bMenPaiID=v.menpai;m.m_bIsOnline=v.is_online;m.m_bPosition=v.position;m.m_iCurContribute=v.cur_contribute;m.m_iMaxContribute=v.max_contribute;m.m_iJoinTime=v.join_time;m.m_iLogOutTime=v.logout_time;d->Guild_SetMemInfoByIndex((int)i,&m);}
        d->Guild_SetMemInfoNum((int)p.memberlist.size());d->Guild_SetMaxMemNum(p.member_max);d->Guild_SetCurPosition(p.position);d->Guild_SetCurAccess(p.access);d->Guild_SetDesc(p.desc_text().c_str());d->Guild_SetName(p.name_text().c_str());
        Event(openMembers?"GUILD_SHOW_MEMBERINFO":"GUILD_UPDATE_MEMBERINFO");openMembers=false;
    }else if(p.packet_type==50||p.packet_type==59){detail=p;auto i=detailRequests.find(p.askid);detailId=i==detailRequests.end()?GuildId():i->second;if(i!=detailRequests.end())detailRequests.erase(i);Event("GUILD_SHOW_DETAILINFO");}
    else if(p.packet_type==51||p.packet_type==60){d->Guild_ClearAppointInfo();for(size_t i=0;i<p.appoint_infos.size();++i){auto& v=p.appoint_infos[i];GuildAppointPos_t m;m.m_PosID=v.pos;m.m_szPosName=Position(v.pos);d->Guild_SetAppointInfoByIndex((int)i,&m);}Event("GUILD_SHOW_APPOINTPOS");}
    else if(p.packet_type==52||p.packet_type==61){selfInfo=p;SetGuild(p.guild_id);d->Guild_SetName(p.name_2.c_str());d->Guild_SetDesc(p.desc_2.c_str());d->Guild_SetCurPosition(p.position_2);if(GuildId()>=0)Ask(0);}
    TDU_Log("CYS guild: type=%u id=%d members=%u position=%d",p.packet_type,GuildId(),(unsigned)roster.memberlist.size(),roster.position);
}
int AskList(LuaPlus::LuaState* s){auto p=Request(0);p->askid=(std::max)(0,Num(s,2));Send(std::move(p));return 0;}
int AskMembers(LuaPlus::LuaState* s){if(GuildId()<0)return AskList(s);openMembers=true;Refresh();return 0;}
int AskDetail(LuaPlus::LuaState*){if(GuildId()>=0)Ask(1);return 0;}
int AskOtherDetail(LuaPlus::LuaState* s){int id=Num(s,2,-1);if(id>=0)Ask(5,id);return 0;}
int AskOfficials(LuaPlus::LuaState* s){int id=Num(s,2,-1);if(id>=0)Ask(6,id);return 0;}
int RefreshMembers(LuaPlus::LuaState*){Refresh();return 0;}
int Count(LuaPlus::LuaState* s){s->PushInteger(list.guild_count);return 1;}
int CountPage(LuaPlus::LuaState* s){s->PushInteger((int)list.guild_list.size());return 1;}
int Info(LuaPlus::LuaState* s){int i=Num(s,2,-1);auto key=Str(s,3);pg::GCGuild::E_guild_list empty;auto& v=i>=0&&i<int(list.guild_list.size())?list.guild_list[i]:empty;
    if(key=="Name")s->PushString(v.name_text().c_str());else if(key=="Desc")s->PushString(v.desc_text().c_str());else if(key=="ChiefName")s->PushString(v.chief_name_text().c_str());else if(key=="CityName")s->PushString(v.city_name_text().c_str());else if(key=="LeagueName")s->PushString(v.confederate_name_text().c_str());else if(key=="FoundTime")s->PushString(Date(v.founded_time).c_str());else {int n=0;if(key=="ID")n=v.id;else if(key=="Count")n=v.user_count;else if(key=="Level")n=v.level;else if(key=="Status")n=v.status;s->PushInteger(n);}return 1;}
int ReadMember(LuaPlus::LuaState* s,const pg::GCGuild& data){int i=Num(s,2,-1);auto key=Str(s,3);pg::GCGuild::E_memberlist empty;auto& v=i>=0&&i<int(data.memberlist.size())?data.memberlist[i]:empty;
    if(key=="OfficialsNum"){s->PushInteger(int(data.memberlist.size()));return 1;}if(key=="Desc"){s->PushString(data.desc_text().c_str());return 1;}
    if(key=="Name")s->PushString(v.name_text().c_str());else if(key=="JoinTime")s->PushString(Date(v.join_time).c_str());else if(key=="LogOutTime"||key=="LastLoginTime")s->PushString(v.is_online?u8"Đang trực tuyến":Date(v.logout_time).c_str());
    else if(key=="ShowColor"){s->PushString(v.is_online?"#W":"#c909090");s->PushString(v.is_online?u8"Đang trực tuyến":u8"Ngoại tuyến");return 2;}
    else {int n=0;if(key=="GUID")n=v.guid;else if(key=="Level")n=v.level;else if(key=="MenPai")n=v.menpai;else if(key=="Position")n=v.position;else if(key=="Online")n=v.is_online;else if(key=="CurCon")n=v.cur_contribute;else if(key=="MaxCon")n=v.max_contribute;else if(key=="ContriPerWeek")n=v.week_contribute;else if(key=="FirstManGuid")n=-1;s->PushInteger(n);}return 1;}
int MembersInfo(LuaPlus::LuaState* s){return ReadMember(s,roster);}
int OfficialsInfo(LuaPlus::LuaState* s){return ReadMember(s,officials);}
int OfficialValid(LuaPlus::LuaState* s){int i=Num(s,2,-1);s->PushBoolean(i>=0&&i<int(officials.memberlist.size()));return 1;}
int OfficialIndex(LuaPlus::LuaState* s){s->PushInteger(Num(s,2,-1));return 1;}
int MyInfo(LuaPlus::LuaState* s){auto key=Str(s,2);if(key=="Appoint"){auto a=CDataPool::GetMe()->Guild_GetAppointInfoByIndex(Num(s,3,-1));if(a&&a->m_PosID>=0)s->PushString(a->m_szPosName.c_str());else s->PushNil();}
    else if(key=="Desc")s->PushString(CDataPool::GetMe()->Guild_GetDesc());else if(key=="Name")s->PushString(CDataPool::GetMe()->Guild_GetName());else if(key=="FirstManName"){std::string n;for(auto& m:roster.memberlist)if(m.position==8){n=m.name_text();break;}s->PushString(n.c_str());}else s->PushString("");return 1;}
int DetailInfo(LuaPlus::LuaState* s){auto k=Str(s,2);
    if(k=="Name")s->PushString(detail.name_text().c_str());else if(k=="ChiefName")s->PushString(detail.chief_name_text().c_str());else if(k=="Creator")s->PushString(detail.creator_text().c_str());else if(k=="CityName")s->PushString(detail.city_name_text().c_str());else if(k=="LeagueName")s->PushString(detail.confederate_name_text().c_str());else if(k=="FoundedTime")s->PushString(Date(detail.founded_time).c_str());
    else if(k=="FuliOpenStatus"){for(int i=0;i<10;++i)s->PushInteger(0);return 10;}
    else if(k=="zhizunday"){s->PushInteger(0);s->PushString("");return 2;}
    else{int n=0;if(k=="ID")n=detailId;else if(k=="Level"||k=="guildlevel")n=detail.level;else if(k=="MemNum")n=detail.mem_num;else if(k=="FMoney")n=detail.founded_money;else if(k=="Ind")n=detail.ind_level;else if(k=="Agr")n=detail.agr_level;else if(k=="Com")n=detail.com_level;else if(k=="Def")n=detail.def_level;else if(k=="Tech")n=detail.tech_level;else if(k=="Ambi")n=detail.ambi_level;else if(k=="BldMaxProg")n=1;else if(k=="Scene"||k=="LocalScene")n=detail.port_scene_id;s->PushInteger(n);}return 1;}
int Power(LuaPlus::LuaState* s){int p=CDataPool::GetMe()->Guild_GetCurAccess();std::string v;for(int i=0;i<8;++i)v+=p&(1<<i)?'1':'0';v+='0';v+=CDataPool::GetMe()->Guild_GetCurPosition()==9?'1':'0';s->PushString(v.c_str());return 1;}
int FixInfo(LuaPlus::LuaState* s){if(Str(s,2)!="Desc")return 0;auto text=Str(s,3);while(!text.empty()&&(text.back()==10||text.back()==13||text.back()==32))text.pop_back();if(text.empty()||text.size()>60){Tip(u8"Tôn chỉ phải có từ 1 đến 60 byte UTF-8.");return 0;}auto p=Request(13);p->set_new_desc(text);Send(std::move(p));return 0;}
int AppointInfo(LuaPlus::LuaState* s){int i=Num(s,2,-1);if(i<0||i>=int(roster.memberlist.size()))return 0;selectedGuid=roster.memberlist[i].guid;Ask(2);return 0;}
int MemberBak(LuaPlus::LuaState* s){int n=-1;for(size_t i=0;i<roster.memberlist.size();++i)if(roster.memberlist[i].guid==selectedGuid)n=int(i);s->PushInteger(n);return 1;}
int Appoint(LuaPlus::LuaState* s){auto v=CDataPool::GetMe()->Guild_GetAppointInfoByIndex(Num(s,2,-1));if(v&&selectedGuid>=0){auto p=Request(4);p->guid=selectedGuid;p->new_position=v->m_PosID;Send(std::move(p));}return 0;}
int MyPosition(LuaPlus::LuaState* s){s->PushInteger(CDataPool::GetMe()->Guild_GetCurPosition());return 1;}
int CreateGuildWindow(LuaPlus::LuaState*){Event("GUILD_CREATE",{"-1"});return 0;}
int Zero(LuaPlus::LuaState* s){s->PushInteger(0);return 1;}
}
void Reset(){roster=pg::GCGuild();detail=pg::GCGuild();list=pg::GCGuild();selfInfo=pg::GCGuild();officials=pg::GCGuild();serial=1;selectedGuid=-1;detailId=-1;detailRequests.clear();openMembers=false;}
bool IsWorldPacket(unsigned short id){return id==pg::GCGuild::PACKET_ID||id==pg::GCGuildReturn::PACKET_ID||id==pg::GCGuildError::PACKET_ID||id==pg::GCGuildApply::PACKET_ID;}
bool Dispatch(const pg::Packet& packet){
    if(!IsWorldPacket(packet.packetId()))return false;
    if(packet.packetId()==pg::GCGuild::PACKET_ID)OnGuild(static_cast<const pg::GCGuild&>(packet));
    else if(packet.packetId()==pg::GCGuildApply::PACKET_ID)Event("GUILD_CREATE",{std::to_string(static_cast<const pg::GCGuildApply&>(packet).m_NpcId)});
    else if(packet.packetId()==pg::GCGuildError::PACKET_ID){int e=static_cast<const pg::GCGuildError&>(packet).error_code;const char* msg=e==-2?u8"Tên bang không hợp lệ.":e==-3?u8"Tên bang đã được sử dụng.":e==-7?u8"Bạn đã gia nhập một bang hội.":e==-8?u8"Bang hội không còn tồn tại.":e==-9?u8"Bạn không có quyền thực hiện thao tác này.":e==-18?u8"Bạn đã gửi đơn gia nhập bang này.":e==-15?u8"Cần bổ nhiệm phó bang chủ trước khi nhường chức.":e==-5?u8"Bang hội đã đầy.":e==-14?u8"Thành viên không còn trong bang hội.":e==-17?u8"Chức vụ này đã đủ người.":u8"Không thể thực hiện thao tác bang hội. Hãy kiểm tra điều kiện và thử lại.";Tip(msg);TDU_Log("CYS guild: error=%d",e);}
    else {auto& p=static_cast<const pg::GCGuildReturn&>(packet);TDU_Log("CYS guild: return=%u guid=%d id=%d",p.return_type,p.guid,p.id);
        if(p.return_type==0){SetGuild(p.id);Tip(u8"Đã thành lập bang hội.");openMembers=true;Refresh();}
        else if(p.return_type==2)Tip(u8"Đã gửi đơn gia nhập. Hãy chờ bang hội xét duyệt.");
        else if((p.return_type==8||p.return_type==12)&&p.guid==MyGuid()){SetGuild(-1);Tip(u8"Bạn đã rời bang hội.");}
        else if(p.return_type==7&&p.guid==MyGuid()){SetGuild(p.guild_id);Tip(u8"Bạn đã được nhận vào bang hội.");openMembers=true;Refresh();}
        else if(p.return_type==15){SetGuild(-1);Tip(u8"Bang hội đã giải tán.");}
        else if(p.return_type!=13)Refresh();
    }return true;
}
std::unique_ptr<pg::Packet> Translate(Packet* old){
    if(old->GetPacketID()==PACKET_CG_GUILDAPPLY){auto v=static_cast<Packets::CGGuildApply*>(old);auto p=New<pg::CGGuildApply>();p->set_name(v->GetGuildName());p->set_desc(v->GetGuildDesc());TDU_Log("CYS guild create: name_bytes=%u desc_bytes=%u",(unsigned)p->name.size(),(unsigned)p->desc.size());return std::move(p);}
    if(old->GetPacketID()==PACKET_CG_GUILDJOIN){auto p=New<pg::CGGuildJoin>();p->guild_id=static_cast<Packets::CGGuildJoin*>(old)->GetGuildID();return std::move(p);}
    if(old->GetPacketID()!=PACKET_CG_GUILD)return nullptr;
    auto v=static_cast<Packets::CGGuild*>(old)->GetGuildPacket();int type=v->m_uPacketType;auto p=Request(type);
    if(type==3){auto x=static_cast<GUILD_CGW_ASKINFO*>(v->GetPacket(type));if(!x)return nullptr;p->guild_id=x->m_GuildGUID;p->type=x->m_Type;}
    else if(type==4){auto x=static_cast<GUILD_CGW_APPOINT*>(v->GetPacket(type));if(!x)return nullptr;p->guid=x->m_CandidateGUID;p->new_position=x->m_NewPosition;}
    else if(type==6){auto x=static_cast<GUILD_CGW_RECRUIT*>(v->GetPacket(type));if(!x)return nullptr;p->m_ProposerGUID=x->m_ProposerGUID;}
    else if(type==7){auto x=static_cast<GUILD_CGW_EXPEL*>(v->GetPacket(type));if(!x)return nullptr;p->m_GuildUserGUID=x->m_GuildUserGUID;}
    else if(type!=0&&type!=10&&type!=11&&type!=12)return nullptr;
    return std::move(p);
}
void RegisterHost(){auto g=Receiver(CScriptSystem::GetMe()->GetLuaState()->GetGlobals(),"Guild");g.Register("AskGuildList4Page",AskList);g.Register("AskGuildMembersInfo",AskMembers);g.Register("ToggleGuildDetailInfo",AskMembers);g.Register("AskGuildDetailInfo",AskDetail);g.Register("AskAnyGuildDetailInfo",AskOtherDetail);g.Register("AskAnyGuildMembersInfo",AskOfficials);g.Register("GetAnyGuildMembersInfo",OfficialsInfo);g.Register("IsAnyGuildMemberIdxValid",OfficialValid);g.Register("Sort2UnSortIndex",OfficialIndex);g.Register("SortAnyGuildMembersByPosition",Zero);g.Register("ReflashEquipPoint",RefreshMembers);g.Register("GetGuildNum",Count);g.Register("GetGuildNumCurPage",CountPage);g.Register("GetGuildInfo",Info);g.Register("GetMembersInfo",MembersInfo);g.Register("GetMyGuildInfo",MyInfo);g.Register("GetMyGuildName",MyInfo);g.Register("GetMyGuildDetailInfo",DetailInfo);g.Register("GetMyGuildPower",Power);g.Register("FixGuildInfo",FixInfo);g.Register("AskGuildAppointPosInfo",AppointInfo);g.Register("AdjustMemberAuth",Appoint);g.Register("GetMemberBak",MemberBak);g.Register("GetMyPosition",MyPosition);g.Register("CysCreateGuildWindow",CreateGuildWindow);g.Register("GetYXstate",Zero);g.Register("IsGuildKeptOneWeed",Zero);}
}
