#pragma once
#include "CysTooltipContractProbe.h"
#include "../Network/CysInspectNet.h"
#include "../Network/CysInventoryNet.h"
#include "../Action/GMActionSystem.h"
#include "../Object/Character/Obj_PlayerOther.h"
#include "../DataPool/GMDP_CharacterData.h"
namespace CysInspectProbe {
struct State {int step=0;DWORD next=0,start=0;const char* shot=nullptr;float x=0,z=0;};
inline State& S(){static State s;return s;}
inline const char* ShotName(){auto p=S().shot;S().shot=nullptr;return p;}
inline void Check(bool ok,const char* text){TDU_Log("CYS-INSPECT-PROBE: %s %s",ok?"PASS":"FAIL",text);if(!ok)throw std::runtime_error(text);}
inline void Lua(const char* owner,const char* code){auto r=CScriptSystem::GetMe()->EvaluateScript(owner,code);if(!r.ok())TDU_Log("CYS-INSPECT-PROBE: Lua %s",r.error);Check(r.ok(),"Lua contract");}
inline bool TickImpl(){
 auto& s=S();if(!CysTooltipContractProbe::Env("CYS_INSPECT_LIVE")||s.step==99)return true;
 if(!s.start)s.start=GetTickCount();if(GetTickCount()-s.start>=45000)Check(false,"within timeout");
 if(static_cast<LONG>(GetTickCount()-s.next)<0)return false;
 auto ui=CGameProcedure::s_pUISystem;auto objects=CObjectManager::GetMe();auto self=objects->GetMySelf();
 auto rect=(CysUiInputBridge::GetWindowRectUtf8)GetProcAddress(GetModuleHandleA("UI_CEGUI.dll"),"CysUiGetWindowRectUtf8");
 auto pointer=(CysUiInputBridge::SmokePointer)GetProcAddress(GetModuleHandleA("UI_CEGUI.dll"),"CysUiSmokePointer");
 auto text=(CysUiInputBridge::CopyCaptionUtf8)GetProcAddress(GetModuleHandleA("UI_CEGUI.dll"),"CysUiCopyCaptionUtf8");
 if(s.step==0){
  if(!objects->FindCharacterByName("CYTest13")){s.next=GetTickCount()+500;return false;}
  Lua("TargetFrame_Env","assert(Target:SendAskDetail('CYTest13')==true)");
 } else if(s.step==1){
  Check(ui->IsWindowShow("TargetEquip")!=FALSE,"other equipment window visible");
  Lua("TargetEquip_Env","assert(CachedTarget:IsPresent(1)==true);assert(CachedTarget:CanGetTargetEquip()==true);assert(CachedTarget:GetData('NAME',1)=='CYTest13');assert(CachedTarget:GetData('MEMPAI',1)==3);assert(CachedTarget:GetData('LEVEL',1)==15);assert(SystemSetup:GetPrivateInfo('other','guid')==200014)");
  Check(CDataPool::GetMe()->OtherPlayerEquip_GetItem((HUMAN_EQUIP)16)!=nullptr,"fashion slot 16 decoded");
  Check(CDataPool::GetMe()->OtherPlayerEquip_GetItem((HUMAN_EQUIP)-1)==nullptr&&CDataPool::GetMe()->OtherPlayerEquip_GetItem((HUMAN_EQUIP)999)==nullptr,"equipment bounds");
  auto peer=static_cast<CObject_Character*>(CysInspectNet::Target());
  Check(peer&&peer!=static_cast<CObject_Character*>(self),"cached target differs from self");
  Check(!CysInspectNet::AcceptEquipment(self->GetServerID()),"unrelated equipment response rejected");
  char caption[256]={};text("TargetEquip_PageHeader",caption,sizeof(caption));TDU_Log("CYS-INSPECT-PROBE: header=%s",caption);
  s.shot="inspect-equipment";
 } else if(s.step==2){
  float r[4]={};Check(rect("TargetEquip_Equip11",r)==1,"target weapon icon visible");pointer(0,r[0]+r[2]/2,r[1]+r[3]/2);
 } else if(s.step==3){
  float r[4]={};Check(rect("_SuperTooltip_",r)==1,"other equipment tooltip visible");
  s.shot="inspect-weapon-tooltip";CInputSystem::GetMe()->CysInjectKey(KC_LMENU,TRUE);
 } else if(s.step==4){
  Check(ui->IsWindowShow("SuperTooltip_Compare")!=FALSE,"Alt comparison visible");
  Lua("SuperTooltip_Compare_Env","assert(SuperTooltips_Cmp1:GetTitle()~='');assert(SuperTooltips:GetTitle()~='')");
  s.shot="inspect-alt-compare";CInputSystem::GetMe()->CysInjectKey(KC_LMENU,FALSE);
 } else if(s.step==5){
  Check(!ui->IsWindowShow("SuperTooltip_Compare"),"comparison hidden on Alt release");pointer(0,1,1);
  float r[4]={};Check(rect("TargetEquip_TargetData",r)==1,"normal tooltip owner visible");pointer(0,r[0]+r[2]/2,r[1]+r[3]/2);
 } else if(s.step==6){
  float r[4]={};Check(rect("CEGUI::System::default__auto_tooltip__",r)==1,"ordinary tooltip visible");
  char caption[256]={};text("CEGUI::System::default__auto_tooltip__",caption,sizeof(caption));TDU_Log("CYS-INSPECT-PROBE: normal-tooltip=%s",caption);
  Check(strstr(caption,u8"Thông tin cá nhân")!=nullptr,"ordinary tooltip UTF-8 caption");
  s.shot="inspect-normal-tooltip";
 } else if(s.step==7){
  pointer(0,1,1);Lua("TargetEquip_Env","SystemSetup:OpenPrivatePage('other')");
 } else if(s.step==8){
  Check(ui->IsWindowShow("TargetData")!=FALSE,"other profile visible");
  char caption[256]={};text("TargetData_PageHeader",caption,sizeof(caption));Check(strstr(caption,"CYTest13")!=nullptr,"profile shows peer name");
  Lua("TargetData_Env","assert(SystemSetup:GetPrivateInfo('other','name')=='CYTest13');assert(SystemSetup:GetPrivateInfo('other','job')=='')");
  s.shot="inspect-profile";CInputSystem::GetMe()->CysInjectKey(KC_ESCAPE,TRUE);
  text("TargetData_ID",caption,sizeof(caption));Check(strstr(caption,"0000000000030D4E")!=nullptr,"profile GUID display matches original format");
 } else if(s.step==9){
  CInputSystem::GetMe()->CysInjectKey(KC_ESCAPE,FALSE);
  Check(!ui->IsWindowShow("TargetData")&&!ui->IsWindowShow("TargetEquip"),"Escape closes inspection");
  Check(!CysInspectNet::AcceptEquipment(CysInspectNet::Target()->GetServerID()),"late equipment reply cannot reopen window");
  s.x=self->GetPosition().x;s.z=self->GetPosition().z;CysAccel::SetChatting(false);Check(CysWorldReplay::LiveGroundClick(7),"ground movement submitted");
 } else if(s.step==10){
  float dx=self->GetPosition().x-s.x,dz=self->GetPosition().z-s.z;Check(dx*dx+dz*dz>4,"character moves after closing inspection");
  TDU_Log("CYS-INSPECT-PROBE: RESULT errors=0");s.step=99;return true;
 }
 ++s.step;s.next=GetTickCount()+(s.step==10?3500:1500);return false;
}
inline bool Tick(){
 try {return TickImpl();}
 catch(const std::exception& e){TDU_Log("CYS-INSPECT-PROBE: RESULT errors=1 reason=%s",e.what());S().step=99;return true;}
}
}
