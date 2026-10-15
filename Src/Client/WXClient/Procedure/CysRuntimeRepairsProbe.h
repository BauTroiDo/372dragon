#pragma once
#include "CysQuickbarProbe.h"
#include "CGAskItemInfo.h"
#include "CGCharDefaultEvent.h"
#include "PgPackets_social.h"
namespace CysRuntimeRepairsProbe {
struct State {int mode=0,step=0,quantity=0;unsigned replies=0;DWORD at=0;float x=0,z=0;const char* shot=nullptr;};
inline State& S(){static State s;return s;}
inline void Check(bool ok,const char* why){TDU_Log("CYS-RUNTIME-FIX: %s %s",ok?"PASS":"FAIL",why);if(!ok)throw std::runtime_error(why);}
inline void Lua(const char* owner,const char* code){auto r=CScriptSystem::GetMe()->EvaluateScript(owner,code);Check(r.ok(),r.ok()?"Lua assertions":r.error);}
inline void Go(int n){S().step=n;S().at=GetTickCount();}
inline const char* ShotName(){auto p=S().shot;S().shot=nullptr;return p;}
inline void Gm(const char* text){std::unique_ptr<pg::CGChat> p(new pg::CGChat);p->ChatType=CHAT_TYPE_TELL;p->set_TargetName("GM");p->set_Contex(text);Check(CysModernGame::SendModern(std::move(p)),"GM command submitted");}
inline bool TickImpl(){auto& s=S();const char* mode=getenv("CYS_RUNTIME_FIX_LIVE");if(!mode||s.step==99)return true;
 auto self=CObjectManager::GetMe()->GetMySelf();auto& b=CysBagProbe::S();const DWORD age=GetTickCount()-s.at;
 if(!s.mode){s.mode=atoi(mode);Check(getenv("CYS_BOT_ACCOUNT")&&!strcmp(getenv("CYS_BOT_ACCOUNT"),"test15"),"owned test15 fixture");
  auto m=GetModuleHandleA("UI_CEGUI.dll");b.pointer=(CysUiInputBridge::SmokePointer)GetProcAddress(m,"CysUiSmokePointer");b.rect=(CysUiInputBridge::GetWindowRectUtf8)GetProcAddress(m,"CysUiGetWindowRectUtf8");
  Check(b.pointer&&b.rect,"UI bridge");if(!CysBagProbe::Shown("Packet"))CEventSystem::GetMe()->PushEvent(GE_TOGLE_CONTAINER);
  for(int slot:{0,20,21}){CGAskItemInfo p;p.setID(slot);CNetManager::GetMe()->SendPacket(&p);}Go(1);return false;}
 if(age<1300)return false;
 switch(s.step){
 case 1:{
  Lua("Packet_Env","Packet_ChangeTabIndex(0);assert(EnumAction(0,'packageitem'):GetRemainRepairCount()==2);assert(EnumAction(20,'packageitem'):GetRemainRepairCount()==3);assert(EnumAction(21,'packageitem'):GetRemainRepairCount()==0)");
  Check(CDataPool::GetMe()->UserBag_GetItem(0)->GetItemRepairCount()==1,"wire repair failure count is preserved");
  char name[96];float p[2];CysBagProbe::ButtonName(0,name);CysQuickbarProbe::Center(name,p);b.pointer(0,p[0],p[1]);Go(2);break;}
 case 2:
  Lua("SuperTooltip_Env",u8"assert(string.find(SuperTooltips:GetPropertys(),'Sửa cao cấp thất bại: 1/3',1,true))");s.shot="repair-count-tooltip";Go(3);break;
 case 3:
  b.pointer(0,1,1);CEventSystem::GetMe()->PushEvent(GE_SUPERTOOLTIP,"0");
  if(s.mode==2){Check(self->GetCharacterData()->Get_Money()==9907&&CysBagProbe::Quantity(30602001)==4,"GM money and purchase persist on relogin");Go(10);break;}
  Check(self->GetCharacterData()->Get_Money()==10000&&CysBagProbe::Quantity(30602001)==3,"known purchase baseline");
  Gm("help");Go(4);break;
 case 4:Gm("vothach@invalid");Go(5);break;
 case 5:Check(self->GetCharacterData()->Get_Money()==10000,"invalid GM input leaves money unchanged");Gm("vothach@7");Go(6);break;
 case 6:Check(self->GetCharacterData()->Get_Money()==10007,"authorized GM works in publish profile");CGameProcedure::s_pGameInterface->Player_MoveTo(fVector2(271,135));Go(7);break;
 case 7:{
  if(std::hypot(self->GetPosition().x-271,self->GetPosition().z-135)>2){if(age<30000)break;Check(false,"walk to merchant");}
  const auto id=CysModernGame::NearestObjectAt(271,133,6,nullptr);Check(id!=0,"merchant exists");s.replies=CysInventoryNet::Get().eventLists;
  CGCharDefaultEvent p;p.setObjID(id);CNetManager::GetMe()->SendPacket(&p);Go(8);break;}
 case 8:{
  Check(CysInventoryNet::Get().eventLists>s.replies,"merchant dialogue received");int script=0,index=0;Check(CysInventoryNet::LastShopOption(script,index),"shop option exists");s.replies=CysInventoryNet::Get().shopLists;
  CUIDataPool::GetMe()->SendSelectEvent(0,script,index);Go(9);break;}
 case 9:{
  Check(CysInventoryNet::Get().shopLists>s.replies,"shop merchandise received");
  Lua("Packet_Env","Packet_ChangeTabIndex(0);CysFixFull=0;CysFixDelta=0;local f=Packet_OnUpdateShow;Packet_OnUpdateShow=function() CysFixFull=CysFixFull+1;return f() end;local d=Packet_UpdateChangedSlot;Packet_UpdateChangedSlot=function(s) CysFixDelta=CysFixDelta+1;return d(s) end");
  auto pool=CDataPool::GetMe();tActionItem* buy=nullptr;for(int i=0;i<pool->Booth_GetNumber();++i){auto item=pool->Booth_GetItem(i);if(item&&item->GetIdTable()==30602001)buy=CActionSystem::GetMe()->EnumAction(i,NAMETYPE_BOOTITEM);}
  Check(buy!=nullptr,"test merchandise");s.quantity=CysBagProbe::Quantity(30602001);s.replies=CysInventoryNet::Get().shopBuys;buy->DoAction();Go(12);break;}
 case 12:
  Check(CysInventoryNet::Get().shopBuys>s.replies&&self->GetCharacterData()->Get_Money()==9907&&CysBagProbe::Quantity(30602001)==s.quantity+1,"one purchase debits exactly 100 and adds one item");
  Lua("Packet_Env","assert(CysFixDelta>0);assert(CysFixFull==0)");Check(true,"purchase refreshes changed slot without full bag rebuild");s.shot="purchase-incremental-bag";Go(10);break;
 case 10:
  CEventSystem::GetMe()->PushEvent(GE_CLOSE_BOOTH);Lua("Packet_Env","CloseWindow('Packet',true)");CysQuickbarProbe::Key(KC_ESCAPE);
  s.x=self->GetPosition().x;s.z=self->GetPosition().z;CysAccel::SetChatting(false);Check(CysWorldReplay::LiveGroundClick(7),"movement submitted after windows close");Go(11);break;
 case 11:
  if(age<3500)break;Check(std::hypot(self->GetPosition().x-s.x,self->GetPosition().z-s.z)>0.5f,"movement works after UI");
  TDU_Log("CYS-RUNTIME-FIX: RESULT mode=%d errors=0",s.mode);s.step=99;return true;
 }
 return false;
}
inline bool Tick(){try{return TickImpl();}catch(const std::exception& e){TDU_Log("CYS-RUNTIME-FIX: FAIL step=%d %s",S().step,e.what());S().step=99;return true;}}
}
