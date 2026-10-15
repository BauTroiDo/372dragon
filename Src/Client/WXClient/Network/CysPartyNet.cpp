#include "StdAfx.h"
#include "CysPartyNet.h"
#include "CysModernGame.h"
#include "PgPackets_team.h"
#include "PgPackets_misc.h"
#include "CGTeamInvite.h"
#include "CGTeamApply.h"
#include "CGTeamRetInvite.h"
#include "CGTeamRetApply.h"
#include "CGTeamLeaderRetInvite.h"
#include "CGTeamLeave.h"
#include "CGTeamDismiss.h"
#include "CGTeamKick.h"
#include "CGTeamAppoint.h"
#include "CGAskTeamInfo.h"
#include "CGAskTeamMemberInfo.h"
#include "CGAskTeamFollow.h"
#include "CGReturnTeamFollow.h"
#include "CGStopTeamFollow.h"
#include "../DataPool/GMUIDataPool.h"
#include "../DataPool/TeamOrGroup.h"
#include "../DataPool/GMDP_CharacterData.h"
#include "../Object/ObjectManager.h"
#include "../Object/Character/Obj_PlayerMySelf.h"
#include "../Object/Character/Obj_PlayerOther.h"
#include "../Object/ObjectCommandDef.h"
#include "../Event/GMEventSystem.h"
#include "../Script/GMScriptSystem.h"
#include "../World/WorldManager.h"
#include "TDUtil.h"
#include "LuaPlus.h"
#include <algorithm>
#include <set>

namespace CysPartyNet {
namespace {
int teamId=-1,expMode=0;
CTeamOrGroup* Team(){return CUIDataPool::GetMe()->GetTeamOrGroup();}
CObject_PlayerMySelf* Self(){return CObjectManager::GetMe()->GetMySelf();}
int MyGuid(){return Self()?Self()->GetServerGUID():-1;}
bool Leader(){return Team()->HasTeam()&&Team()->GetLeaderGUID()==MyGuid();}
void Event(const char* n,const std::vector<STRING>& a={}){CEventSystem::GetMe()->PushEventByName(n,a);}
void Tip(const char* n){Event("NEW_DEBUGMESSAGE",{n});}
bool Send(std::unique_ptr<pg::Packet> p){return CysModernGame::SendModern(std::move(p));}
template<class T> std::unique_ptr<T> New(){return std::unique_ptr<T>(new T);}
LuaPlus::LuaObject Receiver(LuaPlus::LuaObject g,const char* name){auto o=g.GetByName(name);if(o.IsTable())return o;if(o.IsUserData()){auto m=o.GetMetaTable();if(m.IsTable()){auto i=m.GetByName("__index");return i.IsTable()?i:m;}}return LuaPlus::LuaObject();}
int Arg(LuaPlus::LuaState* s,int i,int d=0){LuaPlus::LuaStack a(s);return a[i].IsNumber()?int(a[i].GetNumber()):d;}
void Refresh(){
    const bool has=Team()->HasTeam();
    if(Self()){auto d=Self()->GetCharacterData();d->Set_HaveTeamFlag(has);d->Set_TeamLeaderFlag(Leader());d->Set_TeamFullFlag(has&&Team()->GetTeamMemberCount()>=6);}
    Event(has?"TEAM_REFRESH_DATA":"TEAM_HIDE_ALL_PLAYER");
    Event("TEAM_NOTIFY_APPLY",{has?(Leader()?"3":"0"):"4"});
    Event("TEAM_OPEN_TEAMINFO_DLG",{"4"});Event("TEAM_CHANGE_WORLD");
}
void Clear(bool pending=true){
    if(Self()&&Team()->HasTeam())Team()->DismissTeam();
    if(pending){Team()->ClearInviteTeam();Team()->ClearProposer();}
    SCRIPT_SANDBOX::Talk::s_Talk.TeamDestory();teamId=-1;expMode=0;
}
void AskInfo(){if(!Self())return;auto p=New<pg::CGAskTeamInfo>();p->m_objID=Self()->GetServerID();Send(std::move(p));}
void Add(int guid,int obj,int scene,int portrait,int race,int level,int sect,const std::string& name){
    if(Team()->HasTeam()&&Team()->GetMember(guid))return;
    if(Team()->HasTeam()&&Team()->GetTeamMemberCount()>=6)return;
    TeamMemberInfo m;m.m_GUID=guid;m.m_OjbID=obj;m.m_SceneID=scene;m.m_nPortrait=portrait;m.m_uDataID=race;m.m_uFamily=sect;m.m_uLevel=level;
    strncpy_s(m.m_szNick,name.c_str(),_TRUNCATE);Team()->AddMember(&m,teamId);
    if(auto dst=Team()->GetMember(guid))dst->m_uLevel=level;
}
void OnList(const pg::GCTeamList& p){
    // Reject a truncated/foreign roster before replacing the visible party.
    std::set<int> ids;bool self=false;
    if(p.member_list.size()>6)return;
    for(auto& m:p.member_list){if(!ids.insert(m.guid).second)return;self|=m.guid==MyGuid();}
    if(!p.member_list.empty()&&!self)return;
    const bool follow=Self()&&Team()->HasTeam()&&teamId==p.team_id&&!p.member_list.empty()&&Team()->GetLeaderGUID()==p.member_list[0].guid&&Self()->GetCharacterData()->Get_TeamFollowFlag();
    Clear(teamId!=p.team_id||p.member_list.empty());teamId=p.member_list.empty()?-1:p.team_id;expMode=int(p.exp_mode);
    for(auto& m:p.member_list)Add(m.guid,m.m_objID,m.sceneid,m.portrait_id,m.race_id,m.level,m.menpai,m.name);
    if(follow)Self()->GetCharacterData()->Set_TeamFollowFlag(TRUE);
    Refresh();TDU_Log("CYS party: roster id=%d count=%u leader=%u exp=%d",teamId,(unsigned)p.member_list.size(),Team()->GetLeaderGUID(),expMode);
}
void OnResult(const pg::GCTeamResult& p){
    auto t=Team();if(!t->HasTeam()){if(p.return_type==0||p.return_type==6)AskInfo();return;}
    if(p.team_id!=teamId)return;
    auto m=t->GetMember(p.guid);
    if(p.return_type==0||p.return_type==6)Add(p.guid,p.guid_ex,p.sceneid,p.portrait_id,p.sex,p.uinfo.level,p.uinfo.menpai,p.name);
    else if(p.return_type==3 || ((p.return_type==1||p.return_type==2||p.return_type==4)&&p.guid==MyGuid()))Clear();
    else if((p.return_type==1||p.return_type==2||p.return_type==4)&&m){if(p.return_type==2&&t->GetMember(p.guid_ex))t->Appoint(p.guid_ex);t->DelMember(p.guid);}
    else if(p.return_type==5&&t->GetMember(p.guid_ex))t->Appoint(p.guid_ex);
    else if(m&&(p.return_type==7||p.return_type==8||p.return_type==10)){m->m_SceneID=p.sceneid;m->m_bDeadLink=p.return_type==10;if(p.return_type==8){m->m_OjbID=p.guid_ex;auto q=New<pg::CGAskTeamMemberInfo>();q->guid=m->m_GUID;q->m_objID=m->m_OjbID;q->sceneid=m->m_SceneID;Send(std::move(q));}}
    Refresh();TDU_Log("CYS party: result=%u guid=%d count=%d",p.return_type,p.guid,t->HasTeam()?t->GetTeamMemberCount():0);
}
void OnMember(const pg::GCTeamMemberInfo& p){
    if(!Team()->HasTeam())return;auto m=Team()->GetMember(p.guid);if(!m)return;
    const unsigned f=p.flag;
    if(f&1)m->m_uFamily=p.menpai;if(f&2)m->m_uLevel=p.level;
    if(f&4){m->m_WorldPos.m_fX=p.world_pos_x;m->m_WorldPos.m_fZ=p.world_pos_y;}
    if(f&8){m->m_nHP=p.hp;m->m_bDead=p.hp==0;}if(f&16)m->m_dwMaxHP=p.hp_max;
    if(f&32)m->m_nMP=p.mp;if(f&64)m->m_dwMaxMP=p.mp_max;if(f&128)m->m_nAnger=p.rage;
    if(f&256){m->m_WeaponID=p.weapon_x;m->m_UIModel.SetUIModelInfo(HEQUIP_WEAPON,p.weapon_x);}
    if(f&512){m->m_CapID=p.cap_x;m->m_UIModel.SetUIModelInfo(HEQUIP_CAP,p.cap_x);}
    if(f&1024){m->m_ArmourID=p.armour_x;m->m_UIModel.SetUIModelInfo(HEQUIP_ARMOR,p.armour_x);}
    if(f&2048){m->m_CuffID=p.cuff_x;m->m_UIModel.SetUIModelInfo(HEQUIP_CUFF,p.cuff_x);}
    if(f&4096){m->m_FootID=p.foot_x;m->m_UIModel.SetUIModelInfo(HEQUIP_BOOT,p.foot_x);}
    // CY bits above equipment differ from the 0.85 DEADLINK/DEAD flags.
    if(m->m_UIModel.m_pAvatar){if(f&32768)m->m_UIModel.SetFaceMeshId(p.unknow_11);if(f&65536)m->m_UIModel.SetFaceHairId(p.unknow_12);if(f&131072)m->m_UIModel.SetHairColor(p.unknow_13);}
    Event("TEAM_UPDATE_MEMBER",{std::to_string(Team()->GetMemberUIIndex(p.guid)),"1"});
    for(int i=0;i<Team()->GetTeamMemberCount();++i)if(Team()->GetMemberByIndex(i)->m_GUID==p.guid)Event("TEAM_REFRESH_MEMBER",{std::to_string(i),"1"});
}
TeamCacheInfo* Cache(int guid,const std::string& name,int level,int sect,int scene,int race){auto m=new TeamCacheInfo;m->m_GUID=guid;strncpy_s(m->m_szNick,name.c_str(),_TRUNCATE);m->m_uLevel=level;m->m_uFamily=sect;m->m_Scene=scene;m->m_uDataID=race;return m;}
void OnInvite(const pg::GCTeamAskInvite& p){
    if(Team()->HasTeam()||p.member_list.size()>6)return;
    auto t=new InviteTeam;t->m_InviterGUID=p.guid;
    for(auto& v:p.member_list)t->m_InvitersInfo.push_back(Cache(p.guid,v.nickname,v.level,v.menpai,v.sceneid,v.model));
    if(Team()->AddInviteTeam(t))Event("TEAM_NOTIFY_APPLY",{"2"});
    else {for(auto m:t->m_InvitersInfo)delete m;delete t;}
}
int MemberInfo(LuaPlus::LuaState* s){
    const TeamMemberInfo* m=Team()->HasTeam()?Team()->GetMemberByIndex(Arg(s,2,-1)):nullptr;TeamMemberInfo empty;if(!m)m=&empty;
    s->PushString(m->m_szNick);s->PushInteger(m->m_uFamily);s->PushInteger(m->m_uLevel);s->PushInteger(m->m_bDead);s->PushInteger(m->m_bDeadLink);s->PushInteger(m->m_uDataID);s->PushInteger(-1);s->PushString("");s->PushString("");return 9;
}
int CacheInfo(LuaPlus::LuaState* s,bool invite){const TeamCacheInfo* m=nullptr;if(invite){auto t=Team()->GetInviteTeamByIndex(Arg(s,2,-1));int i=Arg(s,3,-1);if(t&&i>=0&&i<int(t->m_InvitersInfo.size()))m=t->m_InvitersInfo[i];}else m=Team()->GetProposerByIndex(Arg(s,2,-1));TeamCacheInfo empty;if(!m)m=&empty;s->PushString(m->m_szNick);s->PushInteger(m->m_uFamily);s->PushInteger(m->m_uLevel);for(int i=0;i<6;++i)s->PushInteger(0);s->PushInteger(m->m_uDataID);s->PushInteger(-1);s->PushString("");s->PushString("");return 13;}
int InviteInfo(LuaPlus::LuaState* s){return CacheInfo(s,true);}int ApplyInfo(LuaPlus::LuaState* s){return CacheInfo(s,false);}
int GetExp(LuaPlus::LuaState* s){s->PushInteger(expMode);return 1;}
int HudMember(LuaPlus::LuaState* s){SCRIPT_SANDBOX::DataPool::s_DataPool.GetTeamMemInfo(s);auto m=Team()->HasTeam()?Team()->GetMemberByUIIndex(Arg(s,2,-1)):nullptr;const char* name=m?CWorldManager::GetMe()->GetSceneName(m->m_SceneID):"";s->PushString(name?name:"");s->PushInteger(1);s->PushString("");s->PushInteger(0);s->PushInteger(m?m->m_SceneID:-1);return 17;}
int PlayerGuid(LuaPlus::LuaState* s){s->PushInteger(MyGuid());return 1;}
int IsLeader(LuaPlus::LuaState* s){s->PushInteger(Leader()?1:0);return 1;}
int IsInTeam(LuaPlus::LuaState* s){s->PushInteger(Team()->HasTeam()?1:0);return 1;}
int ConfirmDismiss(LuaPlus::LuaState*){if(Leader())Event("OPNE_DISMISS_TEAM_MSGBOX");return 0;}
int SetExp(LuaPlus::LuaState* s){int mode=Arg(s,2,-1);if(Leader()&&(mode==0||mode==1)){auto p=New<pg::CGTeamChangeOption>();p->exp_mode=mode;Send(std::move(p));AskInfo();}return 0;}
int InviteName(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);if(!Self()||!a[2].IsString())return 0;auto p=New<pg::CGTeamInvite>();p->m_objID=Self()->GetServerID();p->set_dest_name(a[2].GetString());Send(std::move(p));return 0;}
int RefreshHost(LuaPlus::LuaState*){AskInfo();return 0;}
int Leave(LuaPlus::LuaState*){auto p=New<pg::CGTeamLeave>();p->guid=MyGuid();Send(std::move(p));return 0;}
int Dismiss(LuaPlus::LuaState*){if(Leader()){auto p=New<pg::CGTeamDismiss>();p->guid=MyGuid();Send(std::move(p));}return 0;}
}
void Reset(){teamId=-1;expMode=0;}
int TeamId(){return teamId;}
bool IsWorldPacket(unsigned short id){switch(id){case pg::GCTeamOptionChanged::PACKET_ID:case pg::GCTeamList::PACKET_ID:case pg::GCTeamResult::PACKET_ID:case pg::GCTeamMemberInfo::PACKET_ID:case pg::GCTeamAskInvite::PACKET_ID:case pg::GCTeamAskApply::PACKET_ID:case pg::GCTeamLeaderAskInvite::PACKET_ID:case pg::GCTeamError::PACKET_ID:case pg::GCTeamFollowErr::PACKET_ID:case pg::GCAskTeamFollow::PACKET_ID:case pg::GCReturnTeamFollow::PACKET_ID:case pg::GCTeamFollowList::PACKET_ID:return true;default:return false;}}
bool Dispatch(const pg::Packet& packet){
    if(!IsWorldPacket(packet.packetId()))return false;if(!Self())return true;
    switch(packet.packetId()){
    case pg::GCTeamOptionChanged::PACKET_ID:expMode=int(static_cast<const pg::GCTeamOptionChanged&>(packet).exp_mode);Refresh();break;
    case pg::GCTeamList::PACKET_ID:OnList(static_cast<const pg::GCTeamList&>(packet));break;
    case pg::GCTeamResult::PACKET_ID:OnResult(static_cast<const pg::GCTeamResult&>(packet));break;
    case pg::GCTeamMemberInfo::PACKET_ID:OnMember(static_cast<const pg::GCTeamMemberInfo&>(packet));break;
    case pg::GCTeamAskInvite::PACKET_ID:OnInvite(static_cast<const pg::GCTeamAskInvite&>(packet));break;
    case pg::GCTeamAskApply::PACKET_ID:{auto& p=static_cast<const pg::GCTeamAskApply&>(packet);if(Leader()){auto m=Cache(p.source_guid,p.source_name,p.uinfo_level,p.uinfo_menpai,p.uinfo_sceneid,p.uinfo_model);if(Team()->AddProposer(m))Event("TEAM_NOTIFY_APPLY",{"1"});else delete m;}break;}
    case pg::GCTeamLeaderAskInvite::PACKET_ID:{auto& p=static_cast<const pg::GCTeamLeaderAskInvite&>(packet);if(Leader()){int i=CUIDataPool::GetMe()->SetMemberInviteGUID(p.source_guid,p.dest_guid);Event("TEAM_MEMBER_INVITE",{p.source_name,p.dest_name,std::to_string(i)});}break;}
    case pg::GCTeamError::PACKET_ID:{int e=static_cast<const pg::GCTeamError&>(packet).error_code;static const char* errors[]={u8"Người chơi đã có tổ đội.",u8"Lời mời đã bị từ chối.",u8"Tổ đội đã đủ 6 người.",u8"Đội trưởng từ chối lời mời.",u8"Chỉ đội trưởng được giải tán tổ đội.",u8"Chỉ đội trưởng được mời thành viên rời đội.",u8"Người xin gia nhập đã có tổ đội.",u8"Người chơi chưa có tổ đội.",u8"Đội trưởng từ chối đơn gia nhập.",u8"Tổ đội đã đầy.",u8"Đội trưởng đã thay đổi; hãy gửi lại yêu cầu.",u8"Bạn không còn trong tổ đội.",u8"Người được chọn không còn trong tổ đội.",u8"Hai người không cùng tổ đội.",u8"Bạn không phải đội trưởng.",u8"Đội trưởng chưa thể trả lời.",u8"Lời mời đã hết hiệu lực.",u8"Hãy rời tổ đội hiện tại trước.",u8"Tổ đội đã đủ 6 người.",u8"Người chơi đã bật từ chối lời mời tổ đội.",u8"Người chơi đã ngoại tuyến."};Tip(e>=0&&e<21?errors[e]:u8"Không thể thực hiện thao tác tổ đội.");break;}
    case pg::GCTeamFollowErr::PACKET_ID:Tip(u8"Không thể theo đội lúc này. Hãy đến gần đội trưởng và kiểm tra trạng thái nhân vật.");break;
    case pg::GCAskTeamFollow::PACKET_ID:if(Team()->HasTeam())if(auto m=Team()->GetMember(Team()->GetLeaderGUID()))Event("TEAM_FOLLOW_INVITE",{m->m_szNick});break;
    case pg::GCReturnTeamFollow::PACKET_ID:{auto& p=static_cast<const pg::GCReturnTeamFollow&>(packet);if(p.guid==MyGuid()&&p.return_type!=0){SCommand_Object c;c.m_wID=OC_UPDATE_TEAM_FOLLOW_FLAG;c.m_abParam[0]=p.return_type==1||p.return_type==3;Self()->PushCommand(&c);Event("TEAM_OPEN_TEAMINFO_DLG",{"4"});}break;}
    case pg::GCTeamFollowList::PACKET_ID:{auto& p=static_cast<const pg::GCTeamFollowList&>(packet);auto o=static_cast<CObject*>(CObjectManager::GetMe()->FindServerObject(p.m_objID));if(o&&p.guids.size()<=6){SCommand_Object c;c.m_wID=OC_TEAM_FOLLOW_MEMBER;c.m_adwParam[0]=(UINT)p.guids.size();for(size_t i=0;i<p.guids.size();++i)c.m_adwParam[i+1]=p.guids[i];o->PushCommand(&c);}break;}
    }return true;
}
std::unique_ptr<pg::Packet> Translate(Packet* old){
    if(!old)return nullptr;switch(old->GetPacketID()){
    case PACKET_CG_TEAMINVITE:{auto v=static_cast<Packets::CGTeamInvite*>(old);auto p=New<pg::CGTeamInvite>();p->m_objID=v->GetSourObjID();p->set_dest_name(v->GetDestName());return std::move(p);}
    case PACKET_CG_TEAMAPPLY:{auto v=static_cast<Packets::CGTeamApply*>(old);auto p=New<pg::CGTeamApply>();p->source_guid=MyGuid();p->set_dest_name(v->GetDestName());return std::move(p);}
    case PACKET_CG_TEAMRETINVITE:{auto v=static_cast<Packets::CGTeamRetInvite*>(old);auto p=New<pg::CGTeamRetInvite>();p->guid=v->GetGUID();p->return_type=v->GetReturn();return std::move(p);}
    case PACKET_CG_TEAMRETAPPLY:{auto v=static_cast<Packets::CGTeamRetApply*>(old);auto p=New<pg::CGTeamRetApply>();p->source_guid=v->GetSourGUID();p->dest_guid=MyGuid();p->return_type=v->GetReturn();return std::move(p);}
    case PACKET_CG_TEAMLEADERRETINVITE:{auto v=static_cast<Packets::CGTeamLeaderRetInvite*>(old);auto p=New<pg::CGTeamLeaderRetInvite>();p->source_guid=v->GetSourGUID();p->dest_guid=v->GetDestGUID();p->return_type=v->GetReturn();return std::move(p);}
    case PACKET_CG_TEAMLEAVE:{auto p=New<pg::CGTeamLeave>();p->guid=MyGuid();return std::move(p);}
    case PACKET_CG_TEAMDISMISS:{auto p=New<pg::CGTeamDismiss>();p->guid=MyGuid();return std::move(p);}
    case PACKET_CG_TEAMKICK:{auto p=New<pg::CGTeamKick>();p->source_guid=MyGuid();p->dest_guid=static_cast<Packets::CGTeamKick*>(old)->GetDestGUID();return std::move(p);}
    case PACKET_CG_TEAMAPPOINT:{auto p=New<pg::CGTeamAppoint>();p->source_guid=MyGuid();p->dest_guid=static_cast<Packets::CGTeamAppoint*>(old)->GetDestGUID();return std::move(p);}
    case PACKET_CG_ASKTEAMINFO:{auto p=New<pg::CGAskTeamInfo>();p->m_objID=static_cast<Packets::CGAskTeamInfo*>(old)->GetObjID();return std::move(p);}
    case PACKET_CG_ASKTEAMMEMBERINFO:{auto v=static_cast<Packets::CGAskTeamMemberInfo*>(old);auto p=New<pg::CGAskTeamMemberInfo>();p->guid=v->GetGUID();p->sceneid=v->GetSceneID();auto m=Team()->HasTeam()?Team()->GetMember(p->guid):nullptr;p->m_objID=m?m->m_OjbID:-1;return std::move(p);}
    case PACKET_CG_ASK_TEAMFOLLOW:return New<pg::CGAskTeamFollow>();
    case PACKET_CG_RETURN_TEAMFOLLOW:{auto p=New<pg::CGReturnTeamFollow>();p->return_type=static_cast<Packets::CGReturnTeamFollow*>(old)->GetReturn();return std::move(p);}
    case PACKET_CG_STOP_TEAMFOLLOW:return New<pg::CGStopTeamFollow>();
    default:return nullptr;}
}
void RegisterHost(){auto g=CScriptSystem::GetMe()->GetLuaState()->GetGlobals();auto d=Receiver(g,"DataPool");d.Register("GetTeamMemberInfo",HudMember);d.Register("GetTeamMemInfoByIndex",MemberInfo);d.Register("GetInviteTeamMemberInfo",InviteInfo);d.Register("GetApplyMemberInfo",ApplyInfo);d.Register("GetTeamExpMode",GetExp);d.Register("SetTeamExpMode",SetExp);auto p=Receiver(g,"Player");p.Register("GetGUID",PlayerGuid);p.Register("IsLeader",IsLeader);p.Register("IsInTeam",IsInTeam);p.Register("OpenDismissTeamMsgbox",ConfirmDismiss);p.Register("ConfirmDismissTeam",Dismiss);p.Register("CysInviteTeam",InviteName);p.Register("CysRefreshTeam",RefreshHost);p.Register("LeaveTeam",Leave);p.Register("DismissTeam",Dismiss);}
}
