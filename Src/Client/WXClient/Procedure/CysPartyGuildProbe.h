#pragma once
#include "CysCommunityProbe.h"
#include "../DataPool/GMDataPool.h"
#include "../DataPool/GMDP_Struct_Guild.h"
#include "../DataPool/GMUIDataPool.h"
#include "../DataPool/TeamOrGroup.h"
namespace CysPartyGuildProbe {
struct State {int step=0,mode=0,after=0;DWORD at=0;float xy[2]={},x=0,z=0;const char* shot=nullptr;};
inline State& S(){static State s;return s;}
inline void Check(bool ok,const char* why){TDU_Log("CYS-PARTY-GUILD: %s %s",ok?"PASS":"FAIL",why);if(!ok)throw std::runtime_error(why);}
inline void Lua(const char* env,const char* code){auto r=CScriptSystem::GetMe()->EvaluateScript(env,code);Check(r.ok(),r.ok()?"Lua assertions":r.error);}
inline void Go(int n){S().step=n;S().at=GetTickCount();}
inline const char* ShotName(){auto p=S().shot;S().shot=nullptr;return p;}
inline void Click(const char* name,int next){CysQuickbarProbe::Center(name,S().xy);CysBagProbe::S().pointer(0,S().xy[0],S().xy[1]);S().after=next;Go(90);}
inline bool TickImpl(){auto& s=S();if(!getenv("CYS_PARTY_GUILD_LIVE")||s.step==99)return true;
 auto self=CObjectManager::GetMe()->GetMySelf();auto& b=CysBagProbe::S();auto t=CUIDataPool::GetMe()->GetTeamOrGroup();auto d=CDataPool::GetMe();
 if(!s.mode){s.mode=atoi(getenv("CYS_PARTY_GUILD_LIVE"));const char* account=getenv("CYS_BOT_ACCOUNT");Check(account&&!strcmp(account,(s.mode==2||s.mode==4)?"test14":"test15"),"owned test fixture");auto m=GetModuleHandleA("UI_CEGUI.dll");b.pointer=(CysUiInputBridge::SmokePointer)GetProcAddress(m,"CysUiSmokePointer");b.rect=(CysUiInputBridge::GetWindowRectUtf8)GetProcAddress(m,"CysUiGetWindowRectUtf8");b.read=(CysUiInputBridge::ReadActionButtonUtf8)GetProcAddress(m,"CysUiReadActionButtonUtf8");Go(s.mode==6?80:s.mode==7?100:s.mode==1?1:s.mode==2?20:s.mode==3?30:s.mode==4?40:50);return false;}
 if(GetTickCount()-s.at<1200)return false;
 switch(s.step){
 case 90:b.pointer(1,s.xy[0],s.xy[1]);Go(91);break;
 case 91:b.pointer(2,s.xy[0],s.xy[1]);Go(s.after);break;
 case 1:Lua("MainMenuBar_Env","Player:CreateTeamSelf();PushEvent('TEAM_OPEN_TEAMINFO_DLG','0')");Go(2);break;
 case 2:Check(t->HasTeam()&&t->GetTeamMemberCount()==1,"create solo party acknowledged");Check(CysBagProbe::Shown("Team_Frame"),"CY party window opens");Lua("Team_Frame_Env","Player:CysInviteTeam('CYTest14')");Go(3);break;
 case 3:if(GetTickCount()-s.at<8000)break;Check(t->HasTeam()&&t->GetTeamMemberCount()==2,"peer accepted invitation; party roster has two");Check(t->GetMember(200015)&&t->GetMember(200015)->m_dwMaxHP>0,"peer HP and appearance snapshot arrived");s.shot="party-two-members";Lua("Team_Frame_Env","DataPool:SetTeamExpMode(1)");Go(4);break;
 case 4:Lua("Team_Frame_Env","assert(DataPool:GetTeamExpMode()==1);Player:CysRefreshTeam()");Go(5);break;
 case 5:Check(t->GetTeamMemberCount()==2,"refresh does not duplicate members");Lua("Team_Frame_Env","SelectPos(1)");Click("Team_Button_Frame3",60);break;
 case 60:Check(t->GetTeamMemberCount()==1,"kick selected member through original CY button");Lua("MainMenuBar_Env","PushEvent('TEAM_OPEN_TEAMINFO_DLG','0')");Go(62);break;
 case 62:Click("Team_Button_Frame1",61);break;
 case 61:Check(CysBagProbe::Shown("MessageBox_Self"),"dismiss team confirmation opens");Click("MessageBox_Self_OK_Button",6);break;
 case 6:Check(!t->HasTeam(),"dismiss clears authoritative party");CysQuickbarProbe::Key(KC_ESCAPE);Lua("MainMenuBar_Env","Guild:AskGuildList4Page(0)");Go(7);break;
 case 7:Check(CysBagProbe::Shown("ConfraternityList"),"guild browser opens");s.shot="guild-list";Click("ConfraternityList_Create",8);break;
 case 8:Check(CysBagProbe::Shown("CreateConfraternity"),"create guild window opens");Lua("CreateConfraternity_Env","CreateConfraternity_InputConfraternityName:SetText('CYSQA0928');CreateConfraternity_InputTenet:SetText('Owned test guild')");Click("CreateConfraternity_Accept",9);break;
 case 9:Check(CysBagProbe::Shown("MessageBox_Self"),"guild creation confirmation opens");s.shot="guild-create-confirm";Click("MessageBox_Self_OK_Button",10);break;
 case 10:Check(self->GetCharacterData()->Get_Guild()>=0,"server created guild");Check(self->GetCharacterData()->Get_Money()==1000000,"creation charged exactly 500000 base units");Check(CysBagProbe::Shown("NewBangHui_Hygl"),"guild membership UI opens");Lua("NewBangHui_Hygl_Env","assert(Guild:GetMyPosition()==9);assert(Guild:GetMembersNum(1)==1)");s.shot="guild-chief";CysQuickbarProbe::Key(KC_ESCAPE);Go(70);break;
 case 20:Check(self->GetCharacterData()->Get_Guild()<0,"applicant initially has no guild");Lua("MainMenuBar_Env","Guild:AskGuildList4Page(0)");Go(21);break;
 case 21:Check(CysBagProbe::Shown("ConfraternityList"),"applicant guild browser opens");Lua("ConfraternityList_Env","local idx=-1;for i=0,Guild:GetGuildNumCurPage()-1 do if Guild:GetGuildInfo(i,'Name')=='CYSQA0928' then idx=i end end;assert(idx>=0);ConfraternityList_List:SetSelectItem(idx);Guild_List_Selected()");s.shot="guild-apply-selected";Click("ConfraternityList_Join",22);break;
 case 22:Check(self->GetCharacterData()->Get_Guild()<0,"application does not grant membership before approval");CysQuickbarProbe::Key(KC_ESCAPE);Go(70);break;
 case 30:Check(self->GetCharacterData()->Get_Guild()>=0,"chief membership persisted across relogin");Check(self->GetCharacterData()->Get_Money()==1000000,"guild fee persisted once");Lua("MainMenuBar_Env","Guild:AskGuildMembersInfo()");Go(31);break;
 case 31:Lua("NewBangHui_Hygl_Env","assert(Guild:GetMembersNum(5)==1);NewBangHui_Hygl_SQRB_Button_Clicked();NewBangHui_Hygl_SQJRList:SetSelectItem(0);NewBangHui_Hygl_SQJRSelectChanged()");s.shot="guild-pending-offline";Click("NewBangHui_Hygl_JieShou_Button",32);break;
 case 32:Lua("NewBangHui_Hygl_Env","assert(Guild:GetMembersNum(5)==0 and Guild:GetMembersNum(4)==2);Guild:FixGuildInfo('Desc','Approved offline member');local idx=-1;for i=0,Guild:GetMembersNum(1)-1 do if Guild:GetMembersInfo(i,'GUID')==200015 then idx=i end end;assert(idx>=0);Guild:AskGuildAppointPosInfo(idx)");Go(33);break;
 case 33:{int index=-1;for(int i=0;i<10;++i){auto v=d->Guild_GetAppointInfoByIndex(i);if(v&&v->m_PosID==8)index=i;}Check(index>=0,"vice chief appointment available");std::string code="Guild:AdjustMemberAuth("+std::to_string(index)+")";Lua("NewBangHui_Hygl_Env",code.c_str());Go(34);break;}
 case 34:Lua("NewBangHui_Hygl_Env","assert(Guild:GetMyGuildInfo('Desc')=='Approved offline member');local found=0;for i=0,Guild:GetMembersNum(1)-1 do if Guild:GetMembersInfo(i,'GUID')==200015 then assert(Guild:GetMembersInfo(i,'Position')==8);found=1 end end;assert(found==1);NewBangHui_Hygl_BHCY_Button_Clicked();NewBangHui_Hygl_BHCYList:SetSelectItem(1);assert(NewBangHui_Hygl_BHCYList:GetSelectItem()==1);NewBangHui_Hygl_BHCYSelectChanged();assert(NewBangHui_Hygl_Chengyuanmingcheng_Text2:GetText()=='CYTest14')");s.shot="guild-promoted-offline";CysQuickbarProbe::Key(KC_ESCAPE);CysQuickbarProbe::Key(KC_ESCAPE);Go(70);break;
 case 40:Check(self->GetCharacterData()->Get_Guild()>=0,"offline approval persists on applicant relogin");Lua("MainMenuBar_Env","Guild:AskGuildMembersInfo()");Go(41);break;
 case 41:Lua("NewBangHui_Hygl_Env","assert(Guild:GetMyPosition()==8);assert(Guild:GetMyGuildInfo('Desc')=='Approved offline member');Guild:FixGuildInfo('Desc','Denied non-chief edit')");s.shot="guild-vice-relogin";Go(42);break;
 case 42:Lua("NewBangHui_Hygl_Env","Guild:AskGuildMembersInfo()");Go(43);break;
 case 43:Lua("NewBangHui_Hygl_Env","assert(Guild:GetMyGuildInfo('Desc')=='Approved offline member')");Click("NewBangHui_Hygl_Tuichu_Button",44);break;
 case 44:Check(CysBagProbe::Shown("MessageBox_Self"),"leave guild asks confirmation");Click("MessageBox_Self_OK_Button",45);break;
 case 45:Check(self->GetCharacterData()->Get_Guild()<0,"leave guild acknowledged");s.shot="guild-left";CysQuickbarProbe::Key(KC_ESCAPE);Go(70);break;
 case 50:Lua("MainMenuBar_Env","Guild:AskGuildMembersInfo()");Go(51);break;
 case 51:Lua("NewBangHui_Hygl_Env","assert(Guild:GetMyPosition()==9);assert(Guild:GetMembersNum(1)==1);local desc=Guild:GetMyGuildInfo('Desc');assert(desc=='Approved offline member' or desc=='Owned test guild');Guild:AskGuildDetailInfo()");Go(52);break;
 case 52:Check(CysBagProbe::Shown("NewBangHui_Bhxx"),"guild details opens");Lua("NewBangHui_Bhxx_Env","assert(Guild:GetMyGuildDetailInfo('Name')=='CYSQA0928');Guild:AskAnyGuildMembersInfo(Guild:GetMyGuildDetailInfo('ID'),0)");s.shot="guild-details";Go(53);break;
 case 53:Check(CysBagProbe::Shown("Confraternity_OfficialPositionList"),"public guild officers window opens");Lua("Confraternity_OfficialPositionList_Env","assert(Guild:GetAnyGuildMembersInfo(0,'OfficialsNum')==1);assert(Guild:GetAnyGuildMembersInfo(0,'Name')=='CYTest15');assert(Guild:GetMyPosition()==9 and Guild:GetMembersNum(1)==1)");s.shot="guild-officers";CysQuickbarProbe::Key(KC_ESCAPE);CysQuickbarProbe::Key(KC_ESCAPE);CysQuickbarProbe::Key(KC_ESCAPE);Go(70);break;

 case 80:Lua("MainMenuBar_Env","Player:CreateTeamSelf();PushEvent('TEAM_OPEN_TEAMINFO_DLG','0')");Go(81);break;
 case 81:Check(t->HasTeam(),"raid fixture party created");Lua("MainMenuBar_Env","Player:CysInviteTeam('CYTest14')");Go(82);break;
 case 82:if(GetTickCount()-s.at<8000)break;Check(t->GetTeamMemberCount()==2,"raid fixture peer joined");Lua("MainMenuBar_Env","Player:OpenCreateRaidConfirmWindow()");Go(83);break;
 case 83:Check(CysBagProbe::Shown("Union_Ensure"),"original raid creation confirmation");Click("Union_Ensure_Button1",84);break;
 case 84:Lua("MainMenuBar_Env","assert(Player:IsInRaid()==1 and Player:IsRaidLeader()==1);assert(Raid:GetMemCount()==2);local a,b=Raid:GetMemberIndexByGUID(200015);assert(a==0 and b==1);local n,icon,hp,maxhp=Raid:GetMemberDetailByIdx(a,b);assert(n=='CYTest14' and maxhp>1)");Check(CysBagProbe::Shown("UnionFrame"),"raid window opened by server roster");s.shot="raid-two-members";Lua("UnionFrame_Env","Raid:ExchangeMemberPosition(0,1,1,0)");Go(85);break;
 case 85:Lua("UnionFrame_Env","local a,b=Raid:GetMemberIndexByGUID(200015);assert(a==1 and b==0);assert(Raid:GetMySquadMemCount()==1);UnionFrame_ToggleMemberMenu(2,1)");Go(92);break;
 case 92:Check(CysBagProbe::Shown("ContexMenu"),"raid member context menu opens");s.shot="raid-member-menu";Click("Union1_8",86);break;
 case 86:Lua("UnionFrame_Env","assert(Raid:IsLeaderByIdx(1,0)==2);UnionFrame_ToggleMemberMenu(2,1)");Go(93);break;
 case 93:Click("Union2_9",87);break;
 case 87:Lua("UnionFrame_Env","assert(Raid:GetMemCount()==1);local a,b=Raid:GetMemberIndexByGUID(200015);assert(a==-1 and b==-1)");Click("Union_Button_Frame2",88);break;
 case 88:Lua("MainMenuBar_Env","assert(Player:IsInRaid()==0 and Raid:GetMemCount()==0)");CysQuickbarProbe::Key(KC_ESCAPE);Go(70);break;
 case 100:Lua("MainMenuBar_Env","Guild:AskGuildMembersInfo()");Go(101);break;
 case 101:Lua("MainMenuBar_Env","GuildLeague:ShowCreateWindow()");Go(108);break;
 case 108:Check(CysBagProbe::Shown("GuildLeagueCreate"),"alliance creation window");Lua("GuildLeagueCreate_Env","GuildLeagueCreate_InputName:SetText('CYSAL0928');GuildLeagueCreate_InputDesc:SetText('Owned alliance fixture');assert(GuildLeagueCreate_InputName:GetText()=='CYSAL0928')");Click("GuildLeagueCreate_Accept",102);break;
 case 102:Check(CysBagProbe::Shown("MessageBox_Self"),"alliance creation confirmation");Click("MessageBox_Self_OK_Button",103);break;
 case 103:Lua("MainMenuBar_Env","GuildLeague:RequestInfo();GuildLeague:ShowInfoWindow()");Go(104);break;
 case 104:Lua("NewBangHui_Tmxx_Env","assert(GuildLeague:GetName()=='CYSAL0928');assert(GuildLeague:GetMemberCount()==1);assert(Player:GetData('GUILDLEAGUE')==GuildLeague:GetID());assert(GuildLeague:GetChieftainGUID()==200016);assert(GuildLeague:GetMemberName(0)=='CYSQA0928')");s.shot="alliance-info";Click("NewBangHui_Tmxx_Bhxz",105);break;
 case 105:Check(CysBagProbe::Shown("NewBangHui_Xuanzhan"),"guild war lists open");Lua("NewBangHui_Xuanzhan_Env","assert(City:GetEnemyNum(0)==0 and City:GetEnemyNum(1)==0);assert(City:GetGuildNumByZoneWorldId(0)>0);assert(NewBangHui_Xuanzhan_BenfuMember_List:GetItemCount()>0)");s.shot="guild-war-lists";Lua("MainMenuBar_Env","GuildLeague:ShowQuitConfirmWindow()");Go(106);break;
 case 106:Click("MessageBox_Self_OK_Button",107);break;
 case 107:Lua("MainMenuBar_Env","assert(GuildLeague:GetID()==-1 and GuildLeague:GetMemberCount()==0);assert(Player:GetData('GUILDLEAGUE')==-1)");CysQuickbarProbe::Key(KC_ESCAPE);CysQuickbarProbe::Key(KC_ESCAPE);Go(70);break;
 case 70:s.x=self->GetPosition().x;s.z=self->GetPosition().z;CysAccel::SetChatting(false);Check(CysWorldReplay::LiveGroundClick(7),"movement input after party/guild UI");Go(71);break;
 case 71:if(GetTickCount()-s.at<3500)break;Check(std::hypot(self->GetPosition().x-s.x,self->GetPosition().z-s.z)>0.5f,"movement remains usable");TDU_Log("CYS-PARTY-GUILD: RESULT mode=%d errors=0",s.mode);s.step=99;return true;
 }return false;
}
inline bool Tick(){try{return TickImpl();}catch(const std::exception& e){TDU_Log("CYS-PARTY-GUILD: FAIL step=%d %s",S().step,e.what());S().step=99;return true;}}
}
