#pragma once
#include "CysGameplayAuditProbe.h"
#include "../Interface/CysSettings.h"
#include "../Sound/GMSoundSystem.h"
#include "../Network/CysCommunityNet.h"
namespace CysCommunityProbe {
struct State {int step=0,mode=0,after=0;DWORD at=0;float xy[2]={},x=0,z=0;const char* shot=nullptr;};
inline State& S(){static State s;return s;}
inline void Check(bool ok,const char* why){TDU_Log("CYS-COMMUNITY: %s %s",ok?"PASS":"FAIL",why);if(!ok)throw std::runtime_error(why);}
inline void Lua(const char* env,const char* code){auto r=CScriptSystem::GetMe()->EvaluateScript(env,code);Check(r.ok(),r.ok()?"Lua assertions":r.error);}
inline void Go(int n){S().step=n;S().at=GetTickCount();}
inline const char* ShotName(){auto p=S().shot;S().shot=nullptr;return p;}
inline void Click(const char* name,int next){CysQuickbarProbe::Center(name,S().xy);CysBagProbe::S().pointer(0,S().xy[0],S().xy[1]);S().after=next;Go(90);}
inline bool TickImpl(){auto& s=S();if(!getenv("CYS_COMMUNITY_LIVE")||s.step==99)return true;
 auto self=CObjectManager::GetMe()->GetMySelf();auto& b=CysBagProbe::S();
 if(!s.mode){s.mode=atoi(getenv("CYS_COMMUNITY_LIVE"));Check(getenv("CYS_BOT_ACCOUNT")&&!strcmp(getenv("CYS_BOT_ACCOUNT"),"test15"),"owned test15 fixture");auto m=GetModuleHandleA("UI_CEGUI.dll");b.pointer=(CysUiInputBridge::SmokePointer)GetProcAddress(m,"CysUiSmokePointer");b.rect=(CysUiInputBridge::GetWindowRectUtf8)GetProcAddress(m,"CysUiGetWindowRectUtf8");b.read=(CysUiInputBridge::ReadActionButtonUtf8)GetProcAddress(m,"CysUiReadActionButtonUtf8");Lua("MainMenuBar_Env","DataPool:CysRefreshCommunity()");Go(s.mode==1?1:s.mode==2?20:30);return false;}
 if(GetTickCount()-s.at<1200)return false;
 switch(s.step){
 case 90:b.pointer(1,s.xy[0],s.xy[1]);Go(91);break;
 case 91:b.pointer(2,s.xy[0],s.xy[1]);Go(s.after);break;
 case 1:Lua("MainMenuBar_Env","SystemSetup:GameSetup()");Go(2);break;
 case 2:Check(CysBagProbe::Shown("GameSetup"),"game settings opens");Lua("GameSetup_Env","GameSetup_Item2:SetCheck(1);GameSetup_Lock:SetCheck(1);GameSetup_ChatBkg_Slider:SetPosition(0.4);GameSetup_Set_Setup_Changed();assert(SystemSetup:GetIsConfigChanged()==1)");Click("GameSetup_YingYong",3);break;
 case 3:Lua("GameSetup_Env","local a={SystemSetup:GameGetData()};assert(a[2]==1 and a[12]==1 and math.abs(a[10]-0.4)<0.01);assert(SystemSetup:GetIsConfigChanged()==0);GameSetup_Item2:SetCheck(0);GameSetup_ChatBkg_Slider:SetPosition(0.7);GameSetup_Retrieve_Setup();a={SystemSetup:GameGetData()};assert(a[2]==1 and math.abs(a[10]-0.4)<0.01);GameSetup_UpdateFrame();GameSetup_Set_Setup_UnChanged()");Check(CVariableSystem::GetMe()->GetAs_Int("CysQuickbarLocked")==1,"quickbar lock reaches UI bridge");s.shot="settings-game";CysQuickbarProbe::Key(KC_ESCAPE);Go(4);break;
 case 4:Check(!CysBagProbe::Shown("GameSetup"),"Esc closes settings");Lua("MainMenuBar_Env","SystemSetup:SoundSetup()");Go(5);break;
 case 5:Lua("SoundSetup_Env","SoundSetup_Item1:SetCheck(1);SoundSetup_Item2_Control:SetPosition(0.35);SoundSetup_Set_Setup_Changed()");Click("SoundSetup_YingYong",6);break;
 case 6:Lua("SoundSetup_Env","assert(tonumber(Variable:GetVariable('DisableAllSound'))==1);assert(math.abs(tonumber(Variable:GetVariable('VOLUME_BG'))-0.35)<0.01);Variable:SetVariable('VOLUME_BG',0.9,0);SoundSetup_Retrieve_Setup();assert(math.abs(tonumber(Variable:GetVariable('VOLUME_BG'))-0.35)<0.01);SoundSetup_UpdateFrame();SoundSetup_Config_UnChanged()");Check(CSoundSystemFMod::GetMe()->GetTypeVolume(tSoundSource::type_background)==0.0f&&CSoundSystemFMod::GetMe()->GetTypeVolume(tSoundSource::type_UI)==0.0f,"mute reaches live mixer gains");s.shot="settings-sound";CysQuickbarProbe::Key(KC_ESCAPE);Lua("MainMenuBar_Env","SystemSetup:ViewSetup()");Go(7);break;
 case 7:Lua("ViewSetup_Env","assert(type(SystemSetup:View_GetData('ksfw'))=='number');ViewSetup_Item2_Control:SetPosition(1);ViewSetup_Set_Setup_Changed()");Click("ViewSetup_YingYong",8);break;
 case 8:Lua("ViewSetup_Env","assert(SystemSetup:View_GetData('fhj')==1);SystemSetup:View_SetData('fhj',0);ViewSetup_Retrieve_Setup();assert(SystemSetup:View_GetData('fhj')==1)");s.shot="settings-video";CysQuickbarProbe::Key(KC_ESCAPE);Lua("MainMenuBar_Env","SystemSetup:InputSetup()");Go(60);break;
 case 60:Check(CysBagProbe::Shown("AcceSetup"),"key bindings UI opens");Lua("AcceSetup_Env","CysKeyBefore=SystemSetup:GetInputSetup(11);NoChat_Button_Clicked(1)");Check(CysAccel::IsCapturing(),"Lua arms native key capture");CysQuickbarProbe::Key(KC_P);Go(61);break;
 case 61:Check(!CysAccel::IsCapturing()&&CysAccel::IsChanged(),"new key captured");Lua("AcceSetup_Env","local k=SystemSetup:GetInputSetup(11);assert(k=='P');SystemSetup:RevertAcceCustom();k=SystemSetup:GetInputSetup(11);assert(k==CysKeyBefore);SystemSetup:UseAcceCustomKey();AcceSetup_UpdateFrame();AcceSetup_Set_Setup_UnChanged()");s.shot="settings-key-bindings";CysQuickbarProbe::Key(KC_ESCAPE);Lua("MainMenuBar_Env","PushEvent('TOGLE_FRIEND','2')");Go(9);break;
 case 9:Check(CysBagProbe::Shown("Friend"),"friends UI opens");Lua("Friend_Env","assert(DataPool:GetFriendNumber(0)==0);DataPool:AddFriend(1,'CYTest14')");Go(10);break;
 case 10:Lua("Friend_Env","assert(DataPool:GetFriendNumber(1)==1);assert(DataPool:GetFriend(1,0,'NAME')=='CYTest14');DataPool:ThrowToList(1,0,2)");Go(11);break;
 case 11:Lua("Friend_Env","assert(DataPool:GetFriendNumber(1)==0 and DataPool:GetFriendNumber(2)==1);DataPool:ThrowToBlackList(2,0)");Go(12);break;
 case 12:Check(CysCommunityNet::IsBlocked("CYTest14"),"blacklist reaches incoming chat filter");Lua("Friend_Env","assert(DataPool:GetFriendNumber(5)==1 and DataPool:GetFriendNumber(0)==0);assert(DataPool:GetFriend(5,0,'RELATION_TYPE')==4);DataPool:ThrowToList(5,0,2)");Go(13);break;
 case 13:Check(!CysCommunityNet::IsBlocked("CYTest14"),"unblock releases incoming chat filter");Lua("Friend_Env","assert(DataPool:GetFriendNumber(2)==1 and DataPool:GetFriendNumber(5)==0);DataPool:DelFriend(2,0)");Go(14);break;
 case 14:Lua("Friend_Env","assert(DataPool:GetFriendNumber(0)==0);DataPool:AddFriend(2,'CYTest14')");Go(15);break;
 case 15:Lua("Friend_Env","assert(DataPool:GetFriendNumber(2)==1);DataPool:AddFriend(2,'CYTest14')");s.shot="friends-authoritative";Go(16);break;
 case 16:Lua("Friend_Env","assert(DataPool:GetFriendNumber(2)==1);DataPool:ShowFriendInfo(2,0)");Go(50);break;
 case 50:Check(CysBagProbe::Shown("FriendInfo"),"friend information opens");Lua("FriendInfo_Env","assert(string.find(FriendInfo_Name:GetText(),'CYTest14'));assert(DataPool:GetFriend(2,0,'LEVEL')>0)");s.shot="friends-info";CysQuickbarProbe::Key(KC_ESCAPE);Go(51);break;
 case 51:CysQuickbarProbe::Key(KC_ESCAPE);Lua("MainMenuBar_Env","PushEvent('OPEN_AGNAME')");Go(17);break;
 case 17:Check(CysBagProbe::Shown("Agname"),"title UI opens");Lua("Agname_Env","assert(Player:CysTitleCount()>=2);local n,id=Player:CysTitleAt(0);assert(id==1043 and string.len(n)>0);Agname_ListContent:SetItemSelectByItemID(0);AgnameFrame_ListContentItemClick()");Click("Agname_Yulanxianshi",18);break;
 case 18:Check(std::string(self->GetCharacterData()->Get_CurTitle())==TransTitleStr("#1043"),"title reaches world character data");Lua("Agname_Env","local n,id,k,t,current=Player:CysTitleAt(0);assert(current==1)");s.shot="titles-selected";CysQuickbarProbe::Key(KC_ESCAPE);Go(40);break;
 case 20:Lua("MainMenuBar_Env","local a={SystemSetup:GameGetData()};assert(a[2]==1 and a[12]==1 and math.abs(a[10]-0.4)<0.01);assert(tonumber(Variable:GetVariable('DisableAllSound'))==1);assert(math.abs(tonumber(Variable:GetVariable('VOLUME_BG'))-0.35)<0.01);assert(SystemSetup:View_GetData('fhj')==1);assert(DataPool:GetFriendNumber(2)==1);local n,id,k,t,current=Player:CysTitleAt(0);assert(id==1043 and current==1);PushEvent('OPEN_AGNAME')");Go(21);break;
 case 21:s.shot="titles-relogin";Click("Agname_Yulanxianshi",22);break;
 case 22:Lua("Agname_Env","local n,id,k,t,current=Player:CysTitleAt(0);assert(current==0);DataPool:DelFriend(2,0)");CysQuickbarProbe::Key(KC_ESCAPE);Go(23);break;
 case 23:Check(!*self->GetCharacterData()->Get_CurTitle(),"hidden title reaches world character data");Lua("MainMenuBar_Env","assert(DataPool:GetFriendNumber(0)==0)");Go(40);break;
 case 30:Lua("MainMenuBar_Env","assert(DataPool:GetFriendNumber(0)==0);local n,id,k,t,current=Player:CysTitleAt(0);assert(current==0)");Go(40);break;
 case 40:Check(!CysBagProbe::Shown("Agname")&&!CysBagProbe::Shown("Friend"),"Esc closes community frames");s.shot=s.mode==1?"title-world-selected":"title-world-hidden";s.x=self->GetPosition().x;s.z=self->GetPosition().z;CysAccel::SetChatting(false);Check(CysWorldReplay::LiveGroundClick(7),"world movement input accepted");Go(41);break;
 case 41:if(GetTickCount()-s.at<3500)break;Check(std::hypot(self->GetPosition().x-s.x,self->GetPosition().z-s.z)>0.5f,"movement works after settings and community UI");TDU_Log("CYS-COMMUNITY: RESULT mode=%d errors=0",s.mode);s.step=99;return true;
 }return false;
}
inline bool Tick(){try{return TickImpl();}catch(const std::exception& e){TDU_Log("CYS-COMMUNITY: FAIL step=%d %s",S().step,e.what());S().step=99;return true;}}
}
