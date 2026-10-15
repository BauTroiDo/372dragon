#pragma once
#include "CysQuickbarProbe.h"
#include "../Network/CysRideNet.h"
#include "../Network/CysMountFlightPacket.h"
#include "../Cursor/CursorMng.h"
#include "../Object/Character/AI/GMAI_MySelf.h"
#include "../World/Path.h"
#include "../World/Scene.h"
#include "../World/WorldManager.h"
#include "../World/CysNavMesh.h"
namespace CysMountFlightProbe {
struct State {int step=0;DWORD next=0;unsigned replies=0;float ground=0,x=0,z=0,bx=0,bz=0,plane=0;const char* shot=nullptr;};
inline State& S(){static State s;return s;}
inline const char* ShotName(){auto p=S().shot;S().shot=nullptr;return p;}
inline void Check(bool ok,const char* why){if(!ok)throw std::runtime_error(why);TDU_Log("CYS-MOUNT-FLIGHT-PROBE: PASS %s",why);}
inline void CtrlClick(){
 auto self=CObjectManager::GetMe()->GetMySelf();auto cursor=CCursorMng::GetMe();
 CysAccel::SetChatting(false);CInputSystem::GetMe()->CysInjectKey(KC_LCONTROL,TRUE);
 cursor->MouseCommand_Set(FALSE,NULL,self->GetPosition(),NULL);
 auto cmd=cursor->MouseCommand_GetLeft();CInputSystem::GetMe()->CysInjectKey(KC_LCONTROL,FALSE);
 Check(cmd.m_typeMouse==SCommand_Mouse::MCT_LEAP,"Ctrl plus ground click selects native command");
 cursor->MouseCommand_Active(cmd);
}
inline void FlyOverObstacle(){
 auto& s=S();auto self=CObjectManager::GetMe()->GetMySelf();
 auto scene=static_cast<CScene*>(CWorldManager::GetMe()->GetActiveScene());auto nav=scene->GetNavMesh();
 Check(nav!=nullptr,"flight probe has ground navmesh");float y=0;bool found=false;
 s.x=self->GetPosition().x;s.z=self->GetPosition().z;
 for(int r=3;r<=12&&!found;++r)for(int a=0;a<16&&!found;++a){
    float x=s.x+r*cosf(a*6.2831853f/16),z=s.z+r*sinf(a*6.2831853f/16);
    if(scene->FlightHeight(fVector2(x,z),y)&&nav->IsBlocked(x,z)){s.bx=x;s.bz=z;found=true;}
 }
 Check(found,"found ground obstacle below flight surface");
 CPath path;Check(path.GetPathDirect(fVector2(s.x,s.z),fVector2(s.bx,s.bz))&&path.GetUnitNum()==1&&
    TDU_GetDistSq(path.GetConstPathUnit(0).fvTarget,fVector2(s.bx,s.bz))<.001f,"direct flight path crosses ground obstacle");
 Check(!path.GetPathDirect(fVector2(s.x,s.z),fVector2(-10,-10))&&path.GetUnitNum()==0,"direct flight path rejects outside scene");
 Check(self->CharacterLogic_GetAI()->PushCommand_MoveTo(s.bx,s.bz)!=FALSE,"move over blocked ground accepted");
}
inline bool TickImpl(){auto& s=S();
 if(!CysTooltipContractProbe::Env("CYS_MOUNT_FLIGHT_LIVE")||s.step==99)return true;
 if(static_cast<LONG>(GetTickCount()-s.next)<0)return false;
 auto self=CObjectManager::GetMe()->GetMySelf();auto ai=self->CharacterLogic_GetAI();int wait=1000;
 switch(s.step){
 case 0:Check(getenv("CYS_BOT_ACCOUNT")&&!strcmp(getenv("CYS_BOT_ACCOUNT"),"test15"),"private test15 fixture");Check(CysRideNet::RequestAutoRide(),"normal mount request accepted");wait=6500;break;
 case 1:
    if(self->GetCharacterData()->Get_MountID()==21) {
        Check(!self->CysCanMountFly(),"ground mount21 has no flight flag");CtrlClick();
        Check(!CysRideNet::FlightRequestPending()&&!self->CysMountFlightState(),"Ctrl click refuses ground mount locally");
        s.replies=CysRideNet::FlightReplies();std::unique_ptr<pg::CGFlyOperation> p(new pg::CGFlyOperation);p->object=self->GetServerID();
        Check(CysModernGame::SendModern(std::move(p)),"send native request to verify server eligibility gate");s.step=19;wait=1800;break;
    }
    Check(self->GetCharacterData()->Get_MountID()==94||self->GetCharacterData()->Get_MountID()==271,"owned flying mount applied");Check(self->CysCanMountFly()&&self->CysMountFlightState()==0,"capable mount starts on ground");s.ground=self->GetPosition().y;s.x=self->GetPosition().x;s.z=self->GetPosition().z;s.shot="mount-flight-ground";CtrlClick();wait=600;break;
 case 2:Check(self->CysMountFlightState()==2,"server accepted takeoff");Check(self->GetPosition().y>s.ground+.2f,"takeoff visibly raises rider");Check(!ai->PushCommand_MoveTo(s.x+3,s.z),"movement locked during takeoff");Check(!CysRideNet::ToggleFlight(),"repeated takeoff refused");s.shot="mount-flight-taking-off";wait=2300;break;
 case 3:Check(self->CysMountFlightState()==1,"takeoff reaches stable airborne state");Check(self->GetPosition().y>s.ground+3,"rider reaches native flight surface");Check(!CysRideNet::RequestAutoRide(),"dismount refused in air");Check(!ai->PushCommand_UseSkill(35,0,0,0,0,0),"skill action refused in air");s.shot="mount-flight-airborne";FlyOverObstacle();s.step=29;wait=4000;break;
 case 4:Check(std::hypot(self->GetPosition().x-s.x,self->GetPosition().z-s.z)>.5f,"airborne movement works");s.x=self->GetPosition().x;s.z=self->GetPosition().z;CtrlClick();wait=600;break;
 case 5:Check(self->CysMountFlightState()==3,"same shortcut starts landing");Check(!ai->PushCommand_MoveTo(s.x+3,s.z),"movement locked during landing");s.shot="mount-flight-landing";wait=2300;break;
 case 6:Check(self->CysMountFlightState()==0,"server finished landing");Check(CysRideNet::RequestAutoRide(),"dismount permitted after landing");wait=2500;break;
 case 7:Check(self->GetCharacterData()->Get_MountID()==INVALID_ID,"mount removed normally");Check(!CysRideNet::ToggleFlight(),"unmounted flight refused");s.shot="mount-flight-landed";s.x=self->GetPosition().x;s.z=self->GetPosition().z;CysWorldReplay::LiveGroundClick(8);wait=3000;break;
 case 8:Check(std::hypot(self->GetPosition().x-s.x,self->GetPosition().z-s.z)>.5f,"normal movement restored after flight");TDU_Log("CYS-MOUNT-FLIGHT-PROBE: RESULT errors=0");s.step=99;return true;
 case 20:Check(CysRideNet::FlightReplies()>s.replies&&!self->CysMountFlightState(),"server rejects ground mount independently of client");s.shot="mount-flight-ground-refused";Check(CysRideNet::RequestAutoRide(),"ground mount dismount unaffected");s.step=6;wait=2000;break;
 case 30:
    {auto scene=static_cast<CScene*>(CWorldManager::GetMe()->GetActiveScene());float a=0,b=0;
    Check(scene->FlightHeight(fVector2(s.x,s.z),a)&&scene->FlightHeight(fVector2(s.bx,s.bz),b)&&fabsf(a-b)<.001f,"flight uses one absolute plane across terrain");
    Check(fabsf(self->GetPosition().y-b)<.05f,"airborne rider stays on fixed plane over obstacle");
    TDU_Log("CYS-MOUNT-FLIGHT-PROBE: fixed plane original=%.4f destination=%.4f rider=%.4f",a,b,self->GetPosition().y);}
    Check(std::hypot(self->GetPosition().x-s.bx,self->GetPosition().z-s.bz)<.6f,"airborne movement reaches blocked ground");
    Check(!CysRideNet::ToggleFlight()&&self->CysMountFlightState()==1,"landing over obstacle refused locally");
    s.replies=CysRideNet::FlightReplies();{std::unique_ptr<pg::CGFlyOperation> p(new pg::CGFlyOperation);p->object=self->GetServerID();p->operation=1;
    Check(CysModernGame::SendModern(std::move(p)),"send native landing request over blocked ground");}wait=1800;break;
 case 31:
    Check(CysRideNet::FlightReplies()>s.replies&&self->CysMountFlightState()==1,"server rejects landing over obstacle");
    Check(ai->PushCommand_MoveTo(s.x,s.z)!=FALSE,"return from above obstacle accepted");wait=4000;break;
 case 32:
    Check(std::hypot(self->GetPosition().x-s.x,self->GetPosition().z-s.z)<.6f,"returned to safe landing position");
    CysWorldReplay::LiveGroundClick(7);s.step=3;wait=3000;break;
 }
 TDU_Log("CYS-MOUNT-FLIGHT-PROBE: step=%d state=%d pos=(%.2f,%.2f,%.2f)",s.step,self->CysMountFlightState(),self->GetPosition().x,self->GetPosition().y,self->GetPosition().z);
 ++s.step;s.next=GetTickCount()+wait;return false;
}
inline bool Tick(){try{return TickImpl();}catch(const std::exception& e){TDU_Log("CYS-MOUNT-FLIGHT-PROBE: FAIL step=%d %s",S().step,e.what());S().step=99;return true;}}
}
