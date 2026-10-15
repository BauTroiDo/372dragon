#pragma once
#include "CysTooltipContractProbe.h"
#include "../Object/Item/Obj_Item_Equip.h"
#include "../Action/GMActionSystem.h"
// Opt-in visual/interaction check. Durability variants are client-only and restored.
namespace CysCellSkinProbe {
struct State {int step=0,cur=-1,max=0,item=-1;DWORD next=0;const char* shot=nullptr;float x=0,z=0;};
inline State& S(){static State s;return s;}
inline const char* ShotName(){auto r=S().shot;S().shot=nullptr;return r;}
inline void Check(bool ok,const char* name){TDU_Log("CYS-CELL-SKIN: %s %s",ok?"PASS":"FAIL",name);if(!ok)throw std::runtime_error(name);}
inline void Lua(const char* code){auto r=CScriptSystem::GetMe()->EvaluateScript("SelfEquip_Env",code);if(!r.ok())TDU_Log("CYS-CELL-SKIN: Lua %s",r.error);Check(r.ok(),"Lua contract");}
inline CObject_Item_Equip* Item(){auto p=CDataPool::GetMe()->UserEquip_GetItem((HUMAN_EQUIP)0);return p && p->GetItemClass()==ICLASS_EQUIP ? static_cast<CObject_Item_Equip*>(p):nullptr;}
inline void Dur(int value){auto p=Item();Check(p && p->GetID()==S().item,"same weapon instance");p->SetDur(value);CActionSystem::GetMe()->UserEquip_Update();CEventSystem::GetMe()->PushEvent(GE_UPDATE_EQUIP);}
inline bool TickImpl(){
 auto& s=S();if(!CysTooltipContractProbe::Env("CYS_CELL_SKIN_LIVE")||s.step==99)return true;
 if(static_cast<LONG>(GetTickCount()-s.next)<0)return false;
 auto ui=CGameProcedure::s_pUISystem;auto self=CObjectManager::GetMe()->GetMySelf();
 auto rect=(CysUiInputBridge::GetWindowRectUtf8)GetProcAddress(GetModuleHandleA("UI_CEGUI.dll"),"CysUiGetWindowRectUtf8");
 auto pointer=(CysUiInputBridge::SmokePointer)GetProcAddress(GetModuleHandleA("UI_CEGUI.dll"),"CysUiSmokePointer");
 if(s.step==0){auto p=Item();Check(p && p->GetMaxDur()>0,"worn weapon has durability");s.cur=p->GetDur();s.max=p->GetMaxDur();s.item=p->GetID();CEventSystem::GetMe()->PushEvent(GE_ACCELERATE_KEYSEND,"acc_selfequip");}
 else if(s.step==1){
  Check(ui->IsWindowShow("SelfEquip")!=FALSE,"SelfEquip visible");
  Lua("local a=EnumAction(0,'equip');local c,m=a:GetEquipDurValue();assert(m>0);assert(math.abs(a:GetEquipDur()-c/m)<0.0001);assert(math.abs(tonumber(SelfEquip_11:GetProperty('EquipmentDurability'))-c/m)<0.001);assert(SelfEquip_11:GetProperty('ShowDurability')=='True')");
  TDU_Log("CYS-CELL-SKIN: server durability %d/%d",s.cur,s.max);s.shot="cells-selfequip";
 } else if(s.step==2){float r[4]={};Check(rect("SelfEquip_11",r)==1,"weapon icon visible");pointer(0,r[0]+r[2]/2,r[1]+r[3]/2);}
 else if(s.step==3){float r[4]={};Check(rect("_SuperTooltip_",r)==1,"weapon SuperTooltip visible");s.shot="cells-weapon-tooltip";}
 else if(s.step==4){pointer(0,1,1);Dur(s.max/2);}
 else if(s.step==5){Lua("local a=EnumAction(0,'equip');local c,m=a:GetEquipDurValue();assert(c==math.floor(m/2));assert(math.abs(tonumber(SelfEquip_11:GetProperty('EquipmentDurability'))-c/m)<0.001)");s.shot="cells-half-durability";}
 else if(s.step==6){Dur(s.max/20);}
 else if(s.step==7){Lua("local a=EnumAction(0,'equip');assert(a:GetEquipDur()<0.1);local p=tonumber(SelfEquip_11:GetProperty('EquipmentDurability'));assert(p>=0 and p<0.1)");s.shot="cells-low-durability";}
 else if(s.step==8){Dur(s.cur);}
 else if(s.step==9){Lua("SelfEquip_11:SetActionItem(-1);assert(tonumber(SelfEquip_11:GetProperty('EquipmentDurability'))==-1)");s.shot="cells-empty-slot";}
 else if(s.step==10){Lua("SelfEquip_11:SetActionItem(EnumAction(0,'equip'):GetID())");Check(Item()->GetDur()==s.cur,"original durability restored");CInputSystem::GetMe()->CysInjectKey(KC_ESCAPE,TRUE);}
 else if(s.step==11){CInputSystem::GetMe()->CysInjectKey(KC_ESCAPE,FALSE);Check(!ui->IsWindowShow("SelfEquip"),"Escape closes SelfEquip");s.x=self->GetPosition().x;s.z=self->GetPosition().z;CysAccel::SetChatting(false);Check(CysWorldReplay::LiveGroundClick(7),"ground click submitted");}
 else if(s.step==12){float dx=self->GetPosition().x-s.x,dz=self->GetPosition().z-s.z;Check(dx*dx+dz*dz>4,"movement after equipment UI");TDU_Log("CYS-CELL-SKIN: RESULT errors=0");s.step=99;return true;}
 ++s.step;s.next=GetTickCount()+(s.step==12?3500:1500);return false;
}
inline bool Tick(){try{return TickImpl();}catch(const std::exception& e){auto p=Item();if(p&&p->GetID()==S().item&&S().cur>=0)p->SetDur(S().cur);TDU_Log("CYS-CELL-SKIN: RESULT errors=1 reason=%s",e.what());S().step=99;return true;}}
}
