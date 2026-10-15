#include "StdAfx.h"
#include "CysRaidNet.h"
#include "CysPartyNet.h"
#include "CysModernGame.h"
#include "PgPackets_team.h"
#include "PgPackets_misc.h"
#include "../DataPool/GMUIDataPool.h"
#include "../DataPool/TeamOrGroup.h"
#include "../DataPool/GMDP_CharacterData.h"
#include "../Object/ObjectManager.h"
#include "../Object/Character/Obj_PlayerMySelf.h"
#include "../Object/Character/Obj_PlayerOther.h"
#include "../Script/GMScriptSystem.h"
#include "../Event/GMEventSystem.h"
#include "../World/WorldManager.h"
#include "../DBC/GMDataBase.h"
#include "../Interface/GMGameInterface.h"
#include "../Input/GMInputSystem.h"
#include "tddbc_struct.h"
#include "LuaPlus.h"
#include "TDUtil.h"
#include <map>
#include <memory>
#include <algorithm>
#include <cstdlib>
#include <climits>

namespace CysRaidNet { namespace {
struct Member {
    pg::GCRaidList::E_member_list::E_elem base;
    int level=0,sect=0,hp=0,maxhp=0,mp=0,maxmp=0,rage=0,dead=0,offline=0;
    pg::GCRaidMemberInfo details;
    CModelShowInUI model;
};
int raidId=-1; int cells[5][6];
std::map<int,std::unique_ptr<Member>> members;
std::vector<pg::GCRaidAskInvite> invites;
std::vector<pg::GCRaidAskApply> applications;
auto Self()->CObject_PlayerMySelf* {return CObjectManager::GetMe()->GetMySelf();}
int Guid(){return Self()?Self()->GetServerGUID():-1;}
template<class T> std::unique_ptr<T> New(){return std::unique_ptr<T>(new T);}
void Send(std::unique_ptr<pg::Packet> p){CysModernGame::SendModern(std::move(p));}
void Event(const char* n,const std::vector<STRING>& a={}){CEventSystem::GetMe()->PushEventByName(n,a);}
int Arg(LuaPlus::LuaState* s,int i,int d=-1){LuaPlus::LuaStack a(s);if(a[i].IsNumber())return int(a[i].GetNumber());if(a[i].IsString()){char* end=nullptr;const char* text=a[i].GetString();auto v=std::strtoll(text,&end,10);if(end!=text&&!*end&&v>=INT_MIN&&v<=INT_MAX)return int(v);}return d;}
Member* Find(int guid){auto it=members.find(guid);return it==members.end()?nullptr:it->second.get();}
Member* At(int a,int b){return a>=0&&a<5&&b>=0&&b<6?Find(cells[a][b]):nullptr;}
Member* At(LuaPlus::LuaState* s){return At(Arg(s,2),Arg(s,3));}
int Role(){auto m=Find(Guid());return m?m->base.m_Position:-1;}
void Refresh(){Event(raidId>=0?"RAID_UPDATE_RAID_FRAME":"RAID_CLOSE_RAID_FRAME",{"-1","-1","1"});Event(raidId>=0?"RAID_UPDATE_SQUAD_FRAME":"RAID_CLOSE_SQUAD_FRAME",{"-1","-1","1"});}
void AskRoster(){if(Self()){auto p=New<pg::CGAskTeamInfo>();p->m_objID=Self()->GetServerID();Send(std::move(p));}}
void AskMember(Member& m){auto p=New<pg::CGAskRaidMemberInfo>();p->guid=m.base.guid;p->m_objID=m.base.m_objID;p->sceneid=m.base.sceneid;Send(std::move(p));}
const char* Scene(Member* m){const char* n=m?CWorldManager::GetMe()->GetSceneName(m->base.sceneid):nullptr;return n?n:"";}
const char* Portrait(Member* m){if(!m)return "";DBC_DEFINEHANDLE(faces,DBC_CHARACTER_FACE);auto f=(const _DBC_CHAR_FACE*)faces->Search_Index_EQU(m->base.portrait_id);return f?f->pImageSetName:"";}
int SelectTarget(LuaPlus::LuaState* s){auto m=At(s);auto me=Find(Guid());if(m&&me&&m->base.sceneid==me->base.sceneid&&!m->offline){auto o=(CObject*)CObjectManager::GetMe()->FindServerObject(m->base.m_objID);if(o&&g_theKernel.IsKindOf(o->GetClass(),GETCLASS(CObject_PlayerNPC))&&((CObject_PlayerNPC*)o)->GetServerGUID()==(GUID_t)m->base.guid)CGameInterface::GetMe()->Object_SelectAsMainTarget(m->base.m_objID);}return 0;}
int InRaid(LuaPlus::LuaState* s){s->PushInteger(raidId>=0);return 1;}
int Leader(LuaPlus::LuaState* s){s->PushInteger(Role()==0);return 1;}
int Assistant(LuaPlus::LuaState* s){s->PushInteger(Role()==1);return 1;}
int Index(LuaPlus::LuaState* s){auto m=Find(Arg(s,2));s->PushInteger(m?m->base.anon1:-1);s->PushInteger(m?m->base.anon2:-1);return 2;}
int MyIndex(LuaPlus::LuaState* s){auto m=Find(Guid());s->PushInteger(m?m->base.anon1:-1);s->PushInteger(m?m->base.anon2:-1);return 2;}
int Count(LuaPlus::LuaState* s){s->PushInteger((int)members.size());return 1;}
int SquadCount(LuaPlus::LuaState* s){auto me=Find(Guid());int n=0;if(me)for(int i=0;i<6;++i)if(At(me->base.anon1,i))++n;s->PushInteger(n);return 1;}
int SquadIndex(LuaPlus::LuaState* s){auto me=Find(Guid());Member* m=nullptr;int n=Arg(s,2);if(me)for(int i=0;i<6;++i){auto v=At(me->base.anon1,i);if(v&&v!=me&&n--==0){m=v;break;}}s->PushInteger(m?m->base.anon1:-1);s->PushInteger(m?m->base.anon2:-1);return 2;}
int MemberGuid(LuaPlus::LuaState* s){auto m=At(s);s->PushInteger(m?m->base.guid:-1);return 1;}
int MemberName(LuaPlus::LuaState* s){auto m=Find(Arg(s,2));s->PushString(m?m->base.text.c_str():"");s->PushInteger(m?m->base.m_ZoneWorldID:0);return 2;}
int MemberRole(LuaPlus::LuaState* s){auto m=At(s);s->PushInteger(m&&m->base.m_Position<2?m->base.m_Position+1:0);return 1;}
int SameScene(LuaPlus::LuaState* s){auto m=At(s);auto me=Find(Guid());s->PushInteger(m&&me&&m->base.sceneid==me->base.sceneid&&!m->offline);return 1;}
int Info(LuaPlus::LuaState* s){auto m=At(s);s->PushString(m?m->base.text.c_str():"");s->PushInteger(m?m->sect:0);s->PushInteger(m?m->level:0);s->PushInteger(m?m->dead:0);s->PushInteger(m?m->offline:0);s->PushString(Scene(m));s->PushInteger(m?m->base.m_ZoneWorldID:0);s->PushString("");s->PushInteger(0);s->PushInteger(m?m->base.m_iFightScore:0);s->PushString(m?m->base.text_2.c_str():"");return 11;}
int Detail(LuaPlus::LuaState* s){auto m=At(s);s->PushString(m?m->base.text.c_str():"");s->PushString(Portrait(m));s->PushInteger(m?m->hp:0);s->PushInteger(m&&m->maxhp>0?m->maxhp:1);s->PushInteger(m?m->mp:0);s->PushInteger(m&&m->maxmp>0?m->maxmp:1);s->PushInteger(m?m->sect:0);s->PushInteger(m?m->level:0);s->PushInteger(m?m->rage:0);s->PushInteger(m?m->offline:0);s->PushInteger(m?m->dead:0);s->PushInteger(m?m->base.model:0);s->PushString(Scene(m));s->PushString("");return 14;}
int Model(LuaPlus::LuaState* s){auto m=At(s);if(!m){s->PushString("");return 1;}auto& v=m->model;if(!v.m_pAvatar){v.CreateNewUIModel();v.m_pAvatar->GetCharacterData()->Set_RaceID(m->base.model);}auto& d=m->details;v.SetUIModelInfo(HEQUIP_WEAPON,d.weapon_x);v.SetUIModelInfo(HEQUIP_CAP,d.cap_x);v.SetUIModelInfo(HEQUIP_ARMOR,d.armour_x);v.SetUIModelInfo(HEQUIP_CUFF,d.cuff_x);v.SetUIModelInfo(HEQUIP_BOOT,d.foot_x);v.SetFaceHairId(d.hair_id);v.SetHairColor(d.hair_color);s->PushString(v.GetUIModelName());return 1;}
int Confirm(LuaPlus::LuaState*){if(raidId<0)Event("OPNE_CREATE_RAID_CONFIRM");return 0;}
int Create(LuaPlus::LuaState*){auto t=CUIDataPool::GetMe()->GetTeamOrGroup();if(raidId>=0||!t->HasTeam()||t->GetLeaderGUID()!=Guid())return 0;auto p=New<pg::CGRaidCreate>();p->m_CreateGUID=Guid();p->m_CreateTeamId=CysPartyNet::TeamId();for(int i=0;i<t->GetTeamMemberCount();++i)p->m_aPlayerInRaid.push_back(t->GetMemberByIndex(i)->m_GUID);p->nCountInRaid=(int)p->m_aPlayerInRaid.size();Send(std::move(p));return 0;}
int Leave(LuaPlus::LuaState*){if(raidId>=0){auto p=New<pg::CGRaidLeave>();p->guid=Guid();Send(std::move(p));}return 0;}
int Kick(LuaPlus::LuaState* s){auto m=At(s);if(m&&Role()>=0&&Role()<2){auto p=New<pg::CGRaidKick>();p->m_OperateGUID=Guid();p->m_TargetGUID=m->base.guid;Send(std::move(p));}return 0;}
int Appoint(LuaPlus::LuaState* s){int role=Arg(s,2);auto m=At(Arg(s,3),Arg(s,4));if(m&&Role()==0&&role>=0&&role<3){auto p=New<pg::CGRaidAppoint>();p->m_OperateGUID=Guid();p->m_TargetGUID=m->base.guid;p->m_Position=role;Send(std::move(p));}return 0;}
int ShowMemberMenu(LuaPlus::LuaState* s){auto m=At(Arg(s,3),Arg(s,4));auto input=CInputSystem::GetMe();if(!m||!input||Role()<0)return 0;int type=m->base.guid==Guid()?6:Role()==0?(m->base.m_Position==1?2:1):Role()==1?(m->base.m_Position==2?4:3):5;POINT pt=input->MouseGetPos();Event("SHOW_CONTEXMENU",{"RaidFrame_Menu",std::to_string(type),std::to_string(m->base.guid),std::to_string(pt.x),std::to_string(pt.y)});return 0;}
std::string TargetName(LuaPlus::LuaState* s){LuaPlus::LuaStack a(s);if(a[2].IsString())return a[2].GetString();auto o=(CObject*)CObjectManager::GetMe()->GetMainTarget();if(!o||o==(CObject*)Self()||!g_theKernel.IsKindOf(o->GetClass(),GETCLASS(CObject_PlayerOther)))return "";return ((CObject_PlayerOther*)o)->GetCharacterData()->Get_Name();}
int InviteTarget(LuaPlus::LuaState* s){auto name=TargetName(s);if(Role()<0||Role()>1||name.empty()||name.size()>29)return 0;auto p=New<pg::CGRaidInvite>();p->m_SourObjID=Guid();p->set_m_DestName(name);Send(std::move(p));return 0;}
int ApplyTarget(LuaPlus::LuaState* s){auto name=TargetName(s);if(raidId>=0||name.empty()||name.size()>29)return 0;auto p=New<pg::CGRaidApply>();p->m_SourGUID=Guid();p->set_m_DestName(name);Send(std::move(p));return 0;}
int Exchange(LuaPlus::LuaState* s){if(Role()<0||Role()>1)return 0;auto p=New<pg::CGRaidModifyMemberPosition>();p->m_OperateGUID=Guid();p->m_sSquadIndex=Arg(s,2);p->m_sMemIndex=Arg(s,3);p->m_dSquadIndex=Arg(s,4);p->m_dMemIndex=Arg(s,5);Send(std::move(p));return 0;}
int InviteCount(LuaPlus::LuaState* s){s->PushInteger((int)invites.size());return 1;}
int InviteInfo(LuaPlus::LuaState* s){int i=Arg(s,2);auto p=i>=0&&i<(int)invites.size()?&invites[i]:nullptr;s->PushString(p?p->nickname_text().c_str():"");s->PushInteger(p?p->m_uLeaderLevel:0);return 2;}
int AnswerInvite(LuaPlus::LuaState* s,bool yes){int i=Arg(s,2);if(i<0||i>=(int)invites.size())return 0;auto p=New<pg::CGRaidRetInvite>();p->m_GUID=invites[i].guid;p->m_Return=yes?1:0;invites.erase(invites.begin()+i);Send(std::move(p));Event("RAID_UPDATE_INVITATION");return 0;}
int Accept(LuaPlus::LuaState* s){return AnswerInvite(s,true);}int Reject(LuaPlus::LuaState* s){return AnswerInvite(s,false);}
int ApplyCount(LuaPlus::LuaState* s){s->PushInteger((int)applications.size());return 1;}
int ApplyInfo(LuaPlus::LuaState* s){int i=Arg(s,2);auto p=i>=0&&i<(int)applications.size()?&applications[i]:nullptr;s->PushString(p?p->SourceName.c_str():"");s->PushInteger(p?p->m_uFamily:0);s->PushInteger(p?p->m_Level:0);for(int j=0;j<6;++j)s->PushInteger(0);s->PushInteger(p?p->m_uDataID:0);s->PushInteger(p?p->m_ZoneWorldID:0);s->PushInteger(p?p->m_iFightScore:0);s->PushString(p?p->GuildName.c_str():"");return 13;}
int AnswerApply(LuaPlus::LuaState* s,bool yes){int i=Arg(s,2);if(Role()!=0||i<0||i>=(int)applications.size())return 0;auto p=New<pg::CGRaidRetApply>();p->source_guid=applications[i].m_SourGUID;p->return_type=yes?1:0;applications.erase(applications.begin()+i);Send(std::move(p));Event("TEAM_NOTIFY_APPLY",{"1"});Refresh();return 0;}
int Agree(LuaPlus::LuaState* s){return AnswerApply(s,true);}int Oppose(LuaPlus::LuaState* s){return AnswerApply(s,false);}
int ClearApply(LuaPlus::LuaState*){applications.clear();Refresh();return 0;}
int ShowApply(LuaPlus::LuaState*){Event("TEAM_OPEN_TEAMINFO_DLG",{"3"});return 0;}
LuaPlus::LuaObject Receiver(LuaPlus::LuaObject g,const char* n){auto o=g.GetByName(n);if(o.IsTable())return o;if(o.IsUserData()){auto m=o.GetMetaTable();if(m.IsTable()){auto i=m.GetByName("__index");return i.IsTable()?i:m;}}return LuaPlus::LuaObject();}
}
void Reset(){raidId=-1;members.clear();invites.clear();applications.clear();for(auto& row:cells)for(auto& v:row)v=-1;}
bool IsWorldPacket(unsigned short id){switch(id){case 124:case 226:case 418:case 1691:case 1711:case pg::GCRaidError::PACKET_ID:return true;default:return false;}}
bool Dispatch(const pg::Packet& packet){if(!IsWorldPacket(packet.packetId()))return false;if(!Self())return true;
    switch(packet.packetId()){
    case pg::GCRaidList::PACKET_ID:{auto& p=static_cast<const pg::GCRaidList&>(packet);bool contains=false;for(auto& t:p.member_list)for(auto& m:t.anon1)contains|=m.guid==Guid();if(p.m_nMemberCount&&!contains)return true;
        auto old=std::move(members);members.clear();for(auto& row:cells)for(auto& v:row)v=-1;raidId=p.m_bLeaveRaid||!p.m_nMemberCount?-1:p.m_RaidID;
        for(auto& t:p.member_list)for(auto& b:t.anon1){if(b.anon1>=5||b.anon2>=6)continue;auto& m=members[b.guid];auto i=old.find(b.guid);if(i!=old.end())m=std::move(i->second);else m.reset(new Member);m->base=b;cells[b.anon1][b.anon2]=b.guid;AskMember(*m);}
        if(raidId>=0){invites.clear();if(Role()!=0)applications.clear();}else applications.clear();Refresh();if(p.m_nEventID==0)Event("OPEN_WINDOW",{"UnionFrame"});TDU_Log("CYS raid: roster=%d members=%u",raidId,(unsigned)members.size());break;}
    case pg::GCRaidResult::PACKET_ID:AskRoster();break;
    case pg::GCRaidMemberInfo::PACKET_ID:{auto& p=static_cast<const pg::GCRaidMemberInfo&>(packet);auto m=Find(p.guid);if(!m||p.m_RaidID!=raidId)break;unsigned f=p.flag;if(f&1)m->sect=p.menpai;if(f&2)m->level=p.level;if(f&8)m->hp=p.hp;if(f&16)m->maxhp=p.hp_max;if(f&32)m->mp=p.mp;if(f&64)m->maxmp=p.mp_max;if(f&128)m->rage=p.rage;if(f&32768)m->offline=p.offline;if(f&65536)m->dead=p.is_die;
        if(f&1024)m->details.weapon_x=p.weapon_x;if(f&2048)m->details.cap_x=p.cap_x;if(f&4096)m->details.armour_x=p.armour_x;if(f&8192)m->details.cuff_x=p.cuff_x;if(f&16384)m->details.foot_x=p.foot_x;if(f&262144)m->details.hair_id=p.hair_id;if(f&524288)m->details.hair_color=p.hair_color;Refresh();break;}
    case pg::GCRaidAskInvite::PACKET_ID:{auto& p=static_cast<const pg::GCRaidAskInvite&>(packet);invites.erase(std::remove_if(invites.begin(),invites.end(),[&](const pg::GCRaidAskInvite& q){return q.guid==p.guid;}),invites.end());if(invites.size()<30)invites.push_back(p);Event("RAID_UPDATE_INVITATION");Event("OPEN_WINDOW",{"UnionChoose"});break;}
    case pg::GCRaidAskApply::PACKET_ID:{auto& p=static_cast<const pg::GCRaidAskApply&>(packet);if(Role()!=0)break;applications.erase(std::remove_if(applications.begin(),applications.end(),[&](const pg::GCRaidAskApply& q){return q.m_SourGUID==p.m_SourGUID;}),applications.end());if(applications.size()<60)applications.push_back(p);Event("TEAM_NOTIFY_APPLY",{"1"});Refresh();break;}
    case pg::GCRaidError::PACKET_ID:Event("NEW_DEBUGMESSAGE",{u8"Thao tác chiến đoàn không hợp lệ hoặc lời mời đã hết hiệu lực."});break;
    }return true;
}
void RegisterHost(){auto g=CScriptSystem::GetMe()->GetLuaState()->GetGlobals();auto p=Receiver(g,"Player");auto r=Receiver(g,"Raid");
    r.Register("ShowMemberContMenu",ShowMemberMenu);auto target=Receiver(g,"Target");target.Register("SendRaidInvitation",InviteTarget);target.Register("SendRaidApplication",ApplyTarget);
    p.Register("IsInRaid",InRaid);p.Register("IsRaidLeader",Leader);p.Register("IsRaidAssitant",Assistant);p.Register("GetMyRaidIndex",MyIndex);p.Register("OpenCreateRaidConfirmWindow",Confirm);p.Register("CreateRaidSelf",Create);p.Register("LeaveRiad",Leave);p.Register("KickRaidMemberByIdx",Kick);p.Register("RaidAppointByIdx",Appoint);p.Register("SendAcceptRaidInvitation",Accept);p.Register("SendRejectRaidInvitation",Reject);p.Register("SendAgreeRaidApplication",Agree);p.Register("SendOpposeRaidApplication",Oppose);p.Register("ShowRaidApplicationList",ShowApply);
    r.Register("SelectAsTargetByIdx",SelectTarget);r.Register("GetMemCount",Count);r.Register("GetMemberIndexByGUID",Index);r.Register("GetMySquadMemCount",SquadCount);r.Register("GetMySquadMemIdxByUIIdx",SquadIndex);r.Register("GetMemberGUIDByIdx",MemberGuid);r.Register("GetMemberNameByGUID",MemberName);r.Register("IsLeaderByIdx",MemberRole);r.Register("IsMemberInSceneByIdx",SameScene);r.Register("GetMemberInfoByIdx",Info);r.Register("GetMemberDetailByIdx",Detail);r.Register("SetModelLookByIdx",Model);r.Register("ExchangeMemberPosition",Exchange);r.Register("GetInvitationCount",InviteCount);r.Register("GetInvitationByIdx",InviteInfo);r.Register("GetApplicantCount",ApplyCount);r.Register("GetApplyMemberInfoByIdx",ApplyInfo);r.Register("ClearApplicant",ClearApply);
}
}
