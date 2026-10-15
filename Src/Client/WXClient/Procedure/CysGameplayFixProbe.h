#pragma once
#include "CysUiInputBridge.h"
#include "../Action/GMActionSystem.h"
#include "../Script/GMScriptSystem.h"
#include "../Input/GMInputSystem.h"
#include "../Object/Character/AI/GMAI_MySelf.h"
#include "../Interface/GMGameInterface.h"
#include "../World/WorldManager.h"
#include "../World/Scene.h"
#include "../Network/CysLeapNet.h"
#include "../Object/Character/Obj_PlayerNPC.h"
#include <cmath>

// Opt-in integration checks through the actual CY windows and player AI.
namespace CysGameplayFixProbe {
struct State { int mode=-1,step=0,errors=0,tab=1; DWORD at=0; float x=0,z=0; bool airborne=false,all=false; const char* shot=nullptr; char shotBuffer[64]={}; };
inline State& S(){static State s;return s;}
inline void Check(bool ok,const char* label){if(!ok)++S().errors;TDU_Log("CYS-GAMEPLAY-CHECK: %s pass=%d",label,ok?1:0);}
inline void Go(int n){S().step=n;S().at=GetTickCount();}
inline void Lua(const char* env,const char* text){Check(CScriptSystem::GetMe()->EvaluateScript(env,text).ok(),"Lua");}
inline const char* ShotName(){auto p=S().shot;S().shot=nullptr;return p;}
inline void NameColours(CObject_PlayerMySelf* self){
 unsigned ids[128]={};auto count=CysModernGame::ObjectsNear(self->GetPosition().x,self->GetPosition().z,200,ids,128);
 CObject_PlayerNPC* npc=nullptr;
 for(unsigned i=0;i<count;++i){auto obj=CObjectManager::GetMe()->FindServerObject(ids[i]);
  if(obj&&g_theKernel.IsKindOf(obj->GetClass(),GETCLASS(CObject_PlayerNPC))&&((CObject*)obj)->GetOwnerID()==INVALID_ID){npc=(CObject_PlayerNPC*)obj;break;}}
 Check(npc!=nullptr,"name-colour-fixture-present");if(!npc)return;
 auto data=npc->GetCharacterData();const _CAMP_DATA oldCamp=*data->Get_CampData();const int oldAI=data->Get_AIType();
 _CAMP_DATA camp=oldCamp;camp.m_nCampID=9;data->Set_CampData(&camp);data->Set_AIType(0);
 Check(_strnicmp(npc->GetNameWithColor().c_str(),"#cff0000#e880000",16)==0,"active-monster-red");
 data->Set_AIType(1);Check(_strnicmp(npc->GetNameWithColor().c_str(),"#cffff00#e888800",16)==0,"passive-monster-yellow");
 camp.m_nCampID=8;data->Set_CampData(&camp);data->Set_AIType(2);
 Check(_strnicmp(npc->GetNameWithColor().c_str(),"#cffffff#e2727ff",16)==0,"peaceful-NPC-native-colour");
 data->Set_CampData(&oldCamp);data->Set_AIType(oldAI);
}
inline bool Tick(){
 auto& s=S(); if(s.mode<0){const char* e=getenv("CYS_GAMEPLAY_FIX_LIVE");s.mode=e?atoi(e):0;s.all=s.mode==4;if(s.all)s.mode=1;}
 if(!s.mode||s.step==99)return true;
 auto self=CObjectManager::GetMe()->GetMySelf();if(!self)return false;
 auto ai=static_cast<CAI_MySelf*>(self->CharacterLogic_GetAI());
 auto ui=CGameProcedure::s_pUISystem;DWORD age=GetTickCount()-s.at;
 if(s.step==0){s.x=self->GetPosition().x;s.z=self->GetPosition().z;TDU_Log("CYS-GAMEPLAY-CHECK: BEGIN mode=%d menpai=%d",s.mode,self->GetCharacterData()->Get_MenPai());NameColours(self);Go(s.mode==1?10:s.mode==2?20:30);}
 switch(s.step){
 case 10:
  CEventSystem::GetMe()->PushEvent(GE_TOGLE_SKILL_BOOK);Go(11);break;
 case 11:
  if(age<800)break;
  Check(ui->IsWindowShow("ActionSkill")!=FALSE,"skill-window-open");
  Check(CActionSystem::GetMe()->GetActionNum("xinfa")==8,"eight-sect-xinfa");
  {int learned=0,locked=0;for(const auto& row:self->GetCharacterData()->Get_Skill()) {if(row.second.m_bLeaned)++learned;else ++locked;}
   Check(learned>0&&locked>0,"learned-and-locked-skills");TDU_Log("CYS-GAMEPLAY-CHECK: learned=%d locked=%d",learned,locked);}
  Go(12);break;
 case 12:{
  char code[128];_snprintf(code,sizeof(code),"ActionSkill_Update_Cliecked(%d,1)",s.tab);
  Lua("ActionSkill_Env",code);Go(13);break;}
 case 13:{
  if(age<300)break;
  auto read=(CysUiInputBridge::ReadActionButtonUtf8)GetProcAddress(GetModuleHandleA("UI_CEGUI.dll"),"CysUiReadActionButtonUtf8");
  int filled=0;
  for(int i=1;i<=5;++i){char name[64];_snprintf(name,64,"ActionSkill_Zhaoshi%d",i);int v[4]={};if(read&&read(name,v)==1&&v[1]==0)++filled;}
  int expected=0;auto actions=CActionSystem::GetMe();auto owner=actions->EnumAction(s.tab-1,"xinfa");
  for(const auto& row:self->GetCharacterData()->Get_Skill()) {
   const auto def=row.second.m_pDefine;if(!def||!owner||def->m_nSkillClass!=owner->GetDefineID())continue;
   const int id=def->m_nID;
   if((id>=788&&id<=800)||(id>=821&&id<=834)||(id>=4465&&id<=4466)||(id>=4533&&id<=4536)||(id>=4528&&id<=4529)||(id>=4742&&id<=4746)||(id>=5189&&id<=5193))continue;
   ++expected;
  }
  TDU_Log("CYS-GAMEPLAY-CHECK: tab=%d expected=%d visible=%d",s.tab,expected,filled);
  Check(expected>0&&filled==expected,"sect-skills-visible");
  _snprintf(s.shotBuffer,sizeof(s.shotBuffer),"gameplay-skills-%d",s.tab);s.shot=s.shotBuffer;
  if(++s.tab<=8)Go(12);else Go(14);break;}
 case 14:
  CInputSystem::GetMe()->CysInjectKey(KC_ESCAPE,TRUE);CInputSystem::GetMe()->CysInjectKey(KC_ESCAPE,FALSE);Go(15);break;
 case 15:
  if(age<500)break;Check(!ui->IsWindowShow("ActionSkill"),"Escape-closes-skill");Go(90);break;
 case 20:{
  auto scene=CWorldManager::GetMe()->GetActiveScene();
  std::vector<STRING> args{scene->GetSceneDefine()->szSceneMap,"2"};CEventSystem::GetMe()->PushEvent(GE_TOGLE_SCENEMAP,args);Go(21);break;}
 case 21:{
  if(age<800)break;Check(ui->IsWindowShow("SceneMap")!=FALSE,"map-open");
  // Click away from the center of the actual map widget. The registered Lua callback
  // must dispatch AutoRunToTarget and the normal navmesh path.
  float r[4]={};auto mod=GetModuleHandleA("UI_CEGUI.dll");
  auto rect=(CysUiInputBridge::GetWindowRectUtf8)GetProcAddress(mod,"CysUiGetWindowRectUtf8");
  auto ptr=(CysUiInputBridge::SmokePointer)GetProcAddress(mod,"CysUiSmokePointer");
  Check(rect&&ptr&&rect("SceneMap_Board",r)==1,"map-widget");
  if(rect&&ptr&&r[2]>0){float x=r[0]+r[2]*0.5f+40,y=r[1]+r[3]*0.5f;ptr(0,x,y);ptr(1,x,y);ptr(2,x,y);}
  Go(22);break;}
 case 22:
  if(age<2500)break;
  Check(std::hypot(self->GetPosition().x-s.x,self->GetPosition().z-s.z)>0.5f,"map-click-moves-player");s.shot="gameplay-map";
  CInputSystem::GetMe()->CysInjectKey(KC_ESCAPE,TRUE);CInputSystem::GetMe()->CysInjectKey(KC_ESCAPE,FALSE);Go(90);break;
 case 30:
  Check(ai&&ai->PushCommand_Fly(34,s.x+10,s.z),"basic-leap-request");Go(31);break;
 case 31:
  if(self->CysIsLeaping()){
   s.airborne=true;Check(!ai->PushCommand_MoveTo(s.x-5,s.z+5),"move-blocked-in-flight");
   Check(!ai->PushCommand_Jump(),"jump-blocked-in-flight");s.shot="gameplay-takeoff";Go(32);
  }else if(age>4000){Check(false,"leap-started");Go(90);}break;
 case 32:
  if(self->CysIsLeaping()){
   if(age>700){Check(!ai->PushCommand_MoveTo(s.x-5,s.z+5),"move-blocked-after-send-gate");s.shot="gameplay-air";Go(33);}
  }else {Check(s.airborne,"leap-landed");Go(90);}break;
 case 33:
  if(!self->CysIsLeaping()){Check(std::hypot(self->GetPosition().x-(s.x+10),self->GetPosition().z-s.z)<0.3f,"leap-keeps-original-target");s.shot="gameplay-landed";Go(90);}
  else if(age>10000){Check(false,"leap-unlocks");Go(90);}break;
 case 90:
  CGameProcedure::s_pGameInterface->Player_MoveTo(fVector2(s.x,s.z));Go(91);break;
 case 91:
  if(age<4000)break;
  Check(!self->CysIsLeaping(),"controls-unlocked");
  Check(std::hypot(self->GetPosition().x-s.x,self->GetPosition().z-s.z)<0.5f,"movement-restores-start");
  TDU_Log("CYS-GAMEPLAY-CHECK: RESULT mode=%d errors=%d position=(%.3f,%.3f)",s.mode,s.errors,self->GetPosition().x,self->GetPosition().z);
  if(s.all&&s.mode<3){++s.mode;s.errors=0;Go(s.mode==2?20:30);break;}
  s.step=99;return true;
 }
 return false;
}
}
