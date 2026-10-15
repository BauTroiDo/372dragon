#pragma once
#include "CysTooltipContractProbe.h"
namespace CysEquipmentTooltipProbe {
struct State {int step=0;DWORD next=0;unsigned infos=0;float item[4]={},beforeY=0,x=0,z=0;const char* shot=nullptr;};
inline State& S(){static State s;return s;}
inline const char* ShotName(){auto n=S().shot;S().shot=nullptr;return n;}
inline void Check(bool ok,const char* msg){TDU_Log("CYS-EQUIP-TIP: %s %s",ok?"PASS":"FAIL",msg);if(!ok)throw std::runtime_error(msg);}
inline void Lua(const char* owner,const char* code){auto r=CScriptSystem::GetMe()->EvaluateScript(owner,code);Check(r.ok(),r.ok()?"Lua tooltip assertions":r.error);}
inline bool TickImpl(){auto& s=S();if(!CysTooltipContractProbe::Env("CYS_EQUIP_TOOLTIP_LIVE")||s.step==99)return true;
 if(static_cast<LONG>(GetTickCount()-s.next)<0)return false;
 auto ui=CGameProcedure::s_pUISystem;auto self=CObjectManager::GetMe()->GetMySelf();
 auto m=GetModuleHandleA("UI_CEGUI.dll");
 auto rect=(CysUiInputBridge::GetWindowRectUtf8)GetProcAddress(m,"CysUiGetWindowRectUtf8");
 auto pointer=(CysUiInputBridge::SmokePointer)GetProcAddress(m,"CysUiSmokePointer");
 auto caption=(CysUiInputBridge::CopyCaptionUtf8)GetProcAddress(m,"CysUiCopyCaptionUtf8");
 if(s.step==0){Check(getenv("CYS_BOT_ACCOUNT")&&!strcmp(getenv("CYS_BOT_ACCOUNT"),"test15"),"owned test15 fixture");CEventSystem::GetMe()->PushEvent(GE_TOGLE_CONTAINER);}
 else if(s.step==1){Lua("Packet_Env","Packet_ChangeTabIndex(0)");Check(rect("Packet_Space_Line1_Row1_button",s.item)==1,"advanced bag item visible");pointer(0,s.item[0]+s.item[2]/2,s.item[1]+s.item[3]/2);}
 else if(s.step==2){
  Lua("SuperTooltip_Env",u8"local p=SuperTooltips:GetPropertys();assert(string.find(SuperTooltips:GetTitle(),'(+9)',1,true));assert(string.find(p,'Cường hóa +9',1,true));assert(string.find(p,'Công vật lý +499',1,true));assert(string.find(p,'Công pháp thuật +537',1,true));assert(string.find(p,'khắc minh',1,true));assert(string.find(p,'tư chất',1,true));assert(string.find(p,'Khế hợp 19',1,true));assert(string.find(p,'Tăng phúc +3',1,true));assert(string.find(p,'Ngọc 3:',1,true));assert(not string.find(p,'Ngọc 2:',1,true));assert(string.find(p,'Tinh khắc: 5',1,true));assert(not string.find(SuperTooltips:GetAuthorInfo(),'&SQ',1,true));assert(string.find(SuperTooltips:GetAuthorInfo(),'ThoRen',1,true));assert(SuperTooltips:GetEquipQual()==8);assert(SuperTooltips:GetDiaowenIcon()~='')");
  Lua("SuperTooltip_Env","assert(tonumber(SuperTooltip_Property:GetProperty('AbsoluteHeight'))>720)");
  char text[16000]={};caption("SuperTooltip_Property",text,sizeof(text));TDU_Log("CYS-EQUIP-TIP: property=[%s]",text);
  float r[4]={},display[2]={};auto size=(CysUiInputBridge::GetDisplaySize)GetProcAddress(m,"CysUiGetDisplaySize");size(display);
  Check(rect("_SuperTooltip_",r)==1&&r[3]<=display[1],"long tooltip bounded by viewport");rect("SuperTooltip_Property",r);s.beforeY=r[1];s.shot="equipment-tooltip-top";

 }
 else if(s.step==3){Check(CInputSystem::GetMe()->CysDispatchWheel(int(s.item[0]+s.item[2]/2),int(s.item[1]+s.item[3]/2),FALSE)==1,"wheel consumed while hovering item");float r[4]={};rect("SuperTooltip_Property",r);Check(r[1]<s.beforeY,"long tooltip content scrolls");for(int i=0;i<45;++i)CInputSystem::GetMe()->CysDispatchWheel(int(s.item[0]+s.item[2]/2),int(s.item[1]+s.item[3]/2),FALSE);}
 else if(s.step==4){s.shot="equipment-tooltip-bottom";
  Lua("SuperTooltip_Env",u8"assert(string.find(SuperTooltips:GetPropertys(),'Tẩy luyện: 7 lần',1,true))");
  float prop[4]={},author[4]={},frame[4]={},desc[4]={};rect("SuperTooltip_Property",prop);Check(rect("SuperTooltip_Manufacturer",author)==1,"creator row visible at bottom");
  rect("SuperTooltip_Manufacturer_Frame",frame);rect("SuperTooltip_Explain",desc);
  Check(prop[1]+prop[3]<=frame[1]+1 && frame[1]+frame[3]<=desc[1]+1,"property creator and description do not overlap after repeated wheel at bottom");
  char maker[256]={};caption("SuperTooltip_Manufacturer",maker,sizeof(maker));Check(strstr(maker,"ThoRen")!=nullptr,"actual creator widget contains manufacturer name");
  TDU_Log("CYS-EQUIP-TIP: bottom property=%.1f,%.1f,%.1f,%.1f author=%.1f,%.1f,%.1f,%.1f",prop[0],prop[1],prop[2],prop[3],author[0],author[1],author[2],author[3]);
  char captured[16000]={};caption("SuperTooltip_Property",captured,sizeof(captured));Check(strstr(captured,u8"Tinh khắc: 5")!=nullptr,"last property line retained in actual widget");
  s.infos=CysModernHandlers::Core().itemInfos;CGAskItemInfo p;p.setID(0);CNetManager::GetMe()->SendPacket(&p);}
 else if(s.step==5){Check(CysModernHandlers::Core().itemInfos>s.infos,"server GCItemInfo refresh received");Lua("SuperTooltip_Env",u8"assert(string.find(SuperTooltips:GetPropertys(),'Khế hợp 19',1,true))");CInputSystem::GetMe()->CysInjectKey(KC_LMENU,TRUE);}
 else if(s.step==6){Check(ui->IsWindowShow("SuperTooltip_Compare")!=FALSE,"Alt comparison visible");Lua("SuperTooltip_Compare_Env",u8"assert(string.find(SuperTooltips_Cmp1:GetTitle(),'(+3)',1,true));assert(not string.find(SuperTooltips_Cmp1:GetPropertys(),'Khế hợp',1,true));assert(string.find(SuperTooltips:GetTitle(),'(+9)',1,true))");Lua("SuperTooltip_Env","local _,_,y=string.find(_SuperTooltip_:GetProperty('AbsolutePosition'),'y:([%d%.%-]+)');assert(tonumber(y)+tonumber(_SuperTooltip_:GetProperty('AbsoluteHeight'))<=720)");s.shot="equipment-tooltip-compare";CInputSystem::GetMe()->CysInjectKey(KC_LMENU,FALSE);}
 else if(s.step==7){Check(rect("Packet_Space_Line1_Row2_button",s.item)==1,"plain same-ID item visible");pointer(0,s.item[0]+s.item[2]/2,s.item[1]+s.item[3]/2);}
 else if(s.step==8){Lua("SuperTooltip_Env",u8"local p=SuperTooltips:GetPropertys();assert(not string.find(p,'Cường hóa',1,true));assert(not string.find(p,'tư chất',1,true));assert(not string.find(p,'Khế hợp',1,true));assert(SuperTooltips:GetAuthorInfo()==nil);assert(SuperTooltips:GetGemHoleCounts()==0);assert(SuperTooltips:GetDiaowenIcon()=='')");Check(true,"same-ID item has no stale metadata");s.shot="equipment-tooltip-plain";pointer(0,1,1);CEventSystem::GetMe()->PushEvent(GE_TOGLE_CONTAINER);CInputSystem::GetMe()->CysInjectKey(KC_C,TRUE);}
 else if(s.step==9){CInputSystem::GetMe()->CysInjectKey(KC_C,FALSE);Check(rect("SelfEquip_11",s.item)==1,"SelfEquip weapon visible");pointer(0,s.item[0]+s.item[2]/2,s.item[1]+s.item[3]/2);}
 else if(s.step==10){Lua("SuperTooltip_Env",u8"assert(string.find(SuperTooltips:GetTitle(),'(+3)',1,true));assert(string.find(SuperTooltips:GetPropertys(),'Cường hóa +3',1,true))");s.shot="equipment-tooltip-selfequip";pointer(0,1,1);CInputSystem::GetMe()->CysInjectKey(KC_ESCAPE,TRUE);}
 else if(s.step==11){CInputSystem::GetMe()->CysInjectKey(KC_ESCAPE,FALSE);Check(!ui->IsWindowShow("SelfEquip"),"Escape closes SelfEquip");s.x=self->GetPosition().x;s.z=self->GetPosition().z;CysAccel::SetChatting(false);Check(CysWorldReplay::LiveGroundClick(7),"ground move submitted");}
 else if(s.step==12){float dx=self->GetPosition().x-s.x,dz=self->GetPosition().z-s.z;Check(dx*dx+dz*dz>4,"character moves after tooltip closes");TDU_Log("CYS-EQUIP-TIP: RESULT errors=0");s.step=99;return true;}
 ++s.step;s.next=GetTickCount()+(s.step==12?3500:1800);return false;
}
inline bool Tick(){try{return TickImpl();}catch(const std::exception& e){TDU_Log("CYS-EQUIP-TIP: RESULT errors=1 reason=%s",e.what());S().step=99;return true;}}
}
