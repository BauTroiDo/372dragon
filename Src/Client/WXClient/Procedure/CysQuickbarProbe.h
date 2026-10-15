#pragma once
#include "CysInventoryIntegrityProbe.h"
#include "../Network/CysSkillNet.h"
#include "CysAccelTable.h"

// Explicit private test15 only. Real pointer drag and real keyboard dispatch;
// database fixture snapshots/restores the entire character outside the client.
namespace CysQuickbarProbe {
struct State { int mode=-1,step=0,moves=0;DWORD at=0;float from[2]={},to[2]={};int skill=-1;const char* shot=nullptr; };
inline State& S(){static State s;return s;}
inline void Check(bool ok,const char* why){if(!ok)throw std::runtime_error(why);TDU_Log("CYS-QUICKBAR: PASS %s",why);}
inline void Go(int n){S().step=n;S().at=GetTickCount();}
inline void Lua(const char* env,const char* code){auto r=CScriptSystem::GetMe()->EvaluateScript(env,code);Check(r.ok(),r.error);}
inline void Key(int key){CInputSystem::GetMe()->CysInjectKey(key,TRUE);CInputSystem::GetMe()->CysInjectKey(key,FALSE);}
inline tActionItem* Bar(int slot){return CActionSystem::GetMe()->GetAction(CActionSystem::GetMe()->MainMenuBar_Get(slot));}
inline bool Skill35(tActionItem* item){return item&&item->GetType()==AOT_SKILL&&item->GetDefineID()/100==35;}
inline void Center(const char* name,float* p){float r[4]={};Check(CysBagProbe::S().rect(name,r)==1,name);p[0]=r[0]+r[2]/2;p[1]=r[1]+r[3]/2;}
inline bool TickImpl(){auto& s=S();
 if(s.mode<0){const char* e=getenv("CYS_QUICKBAR_LIVE");s.mode=e?atoi(e):0;if(!s.mode)return true;
  Check(getenv("CYS_BOT_ACCOUNT")&&!strcmp(getenv("CYS_BOT_ACCOUNT"),"test15"),"private test15 only");
  auto mod=GetModuleHandleA("UI_CEGUI.dll");auto& b=CysBagProbe::S();
  b.pointer=(CysUiInputBridge::SmokePointer)GetProcAddress(mod,"CysUiSmokePointer");
  b.rect=(CysUiInputBridge::GetWindowRectUtf8)GetProcAddress(mod,"CysUiGetWindowRectUtf8");
  b.read=(CysUiInputBridge::ReadActionButtonUtf8)GetProcAddress(mod,"CysUiReadActionButtonUtf8");
  Check(b.pointer&&b.rect&&b.read,"UI bridge");Go(0);
 }
 if(!s.mode||s.step==99)return true;
 auto a=CActionSystem::GetMe();auto self=CObjectManager::GetMe()->GetMySelf();auto pointer=CysBagProbe::S().pointer;
 DWORD age=GetTickCount()-s.at;if(age<700)return false;
 switch(s.step){
 case 0:{
  if(s.mode==3){Check(CysBagProbe::Quantity(30001001)==3,"three potion fixture");Lua("MainMenuBar_Env","MainmenuBar_PageOne()");if(!CysBagProbe::Shown("Packet"))CEventSystem::GetMe()->PushEvent(GE_TOGLE_CONTAINER);Go(30);break;}
  const int level=CysSkillNet::SkillLevel(374);auto tip=a->GetAction_SkillID(37400+level);
  Check(tip&&tip->GetDesc()&&strlen(tip->GetDesc())>120,"Tam Khuyen Sao Nguyet full tooltip description");
  TDU_Log("CYS-QUICKBAR: skill374 text=%s",tip->GetDesc());
  tip->NotifyTooltipsShow(200,160,234,194);Go(1);break;}
 case 1:s.shot="skill-description-restored";Go(2);break;
 case 2:
  {auto tip=a->GetAction_SkillID(37400+CysSkillNet::SkillLevel(374));if(tip)tip->NotifyTooltipsHide();}
  if(s.mode==2){for(int i=0;i<50;++i)Check(Skill35(Bar(i)),"persisted slot35");TDU_Log("CYS-QUICKBAR: relogin fifty slots restored");Go(98);break;}
  CEventSystem::GetMe()->PushEvent(GE_TOGLE_SKILL_BOOK);Go(20);break;
 case 20:
  CEventSystem::GetMe()->PushEvent(GE_TOGLE_COMMONSKILL_PAGE);Lua("MainMenuBar_Env","MainmenuBar_PageThree()");a->MainMenuBar_Set(20,INVALID_ID);Go(3);break;
 case 3:{
  char name[64]={};bool found=false;
  for(int i=1;i<=20;++i){_snprintf(name,64,"CommonSkill_Skill%d",i);int v[4]={};
   if(CysBagProbe::S().read(name,v)==1){auto item=a->GetAction(v[0]);TDU_Log("CYS-QUICKBAR: %s id=%d empty=%d define=%d",name,v[0],v[1],item?item->GetDefineID():-1);if(Skill35(item)){s.skill=v[0];Center(name,s.from);found=true;break;}}}
  Check(found,"common skill35 visible");Check(!Bar(20),"drag destination starts empty");Center("Button_Action21",s.to);
  Check(a->GetAction(s.skill)->IsEnabled()!=FALSE,"source skill enabled");
  TDU_Log("CYS-QUICKBAR: drag from=%.1f,%.1f to=%.1f,%.1f",s.from[0],s.from[1],s.to[0],s.to[1]);
  s.shot="quickbar-before-drag";pointer(0,s.from[0],s.from[1]);Go(301);break;}
 case 4:
  ++s.moves;pointer(0,s.from[0]+(s.to[0]-s.from[0])*s.moves/6,s.from[1]+(s.to[1]-s.from[1])*s.moves/6);
  if(s.moves==6)Go(5);else s.at=GetTickCount()-600;break;
 case 5:pointer(2,s.to[0],s.to[1]);Go(6);break;
 case 6:
  if(s.mode==3){Check(Bar(0)&&Bar(0)->GetDefineID()==30001001,"real item drop on F1");CEventSystem::GetMe()->PushEvent(GE_TOGLE_CONTAINER);CysAccel::SetChatting(false);CysInventoryIntegrityProbe::Swap(18,0);Go(31);break;}
  Check(Skill35(Bar(20)),"real pointer drop on third F page");s.shot="quickbar-page-three-drag";
  CEventSystem::GetMe()->PushEvent(GE_CLOSE_SKILL_BOOK);
  for(int i=0;i<50;++i)a->MainMenuBar_Set(i,s.skill);
  for(int i=0;i<50;++i)Check(Skill35(Bar(i)),"all fifty slots bound");
  CysAccel::SetChatting(false);Go(7);break;
 case 7:Lua("MainMenuBar_Env","MainmenuBar_PageOne()");Go(8);break;
 case 8:Check(CysAccel::MenuBarPage()==0,"F page1");Key(KC_F1);Key(KC_F10);Go(9);break;
 case 9:Lua("MainMenuBar_Env","MainmenuBar_PageTwo()");Go(10);break;
 case 10:Check(CysAccel::MenuBarPage()==1,"F page2");Key(KC_F1);Key(KC_F10);Go(11);break;
 case 11:Lua("MainMenuBar_Env","MainmenuBar_PageThree()");Go(12);break;
 case 12:Check(CysAccel::MenuBarPage()==2,"F page3");Key(KC_F1);Key(KC_F10);Go(13);break;
 case 13:
  CInputSystem::GetMe()->CysInjectKey(KC_LMENU,TRUE);Key(KC_1);Key(KC_0);CInputSystem::GetMe()->CysInjectKey(KC_LMENU,FALSE);Go(14);break;
 case 14:
  Check(CysModernHandlers::Core().skillSends>0,"key dispatched skill onto live server");
  TDU_Log("CYS-QUICKBAR: RESULT fifty slots + pointer drag + F pages + Alt keys errors=0");Go(98);break;
 case 30:{
  char name[96]={};CysBagProbe::ButtonName(19,name);Center(name,s.from);Center("Button_Action1",s.to);
  pointer(0,s.from[0],s.from[1]);Go(301);break;}
 case 301:pointer(1,s.from[0],s.from[1]);Go(4);break;
 case 31:
  Check(CysBagProbe::Quantity(30001001)==3,"bag move preserves count");CysInventoryIntegrityProbe::Unique();Key(KC_F1);Go(32);break;
 case 32:
  if(age<1500)break;
  Check(CysBagProbe::Quantity(30001001)==2,"first use after moved bag removes exactly one");CysInventoryIntegrityProbe::Unique();Go(33);break;
 case 33:if(age<16000)break;Key(KC_F1);Go(34);break;
 case 34:
  if(age<1500)break;
  Check(CysBagProbe::Quantity(30001001)==1,"second use exhausts first stack");CysInventoryIntegrityProbe::Unique();Go(35);break;
 case 35:if(age<16000)break;Key(KC_F1);Go(36);break;
 case 36:
  if(age<1500)break;
  Check(CysBagProbe::Quantity(30001001)==0,"third use resolves remaining stack");CysInventoryIntegrityProbe::Unique();Key(KC_F1);Go(37);break;
 case 37:
  Check(CysBagProbe::Quantity(30001001)==0,"empty shortcut creates no phantom item");
  TDU_Log("CYS-QUICKBAR: RESULT item drag/move/consume/rebind/empty errors=0");Go(98);break;
 case 98:
  CysAccel::SetChatting(false);Check(CysWorldReplay::LiveGroundClick(7),"movement after quickbar");Go(99);break;
 }
 return s.step==99;
}
inline bool Tick(){try{return TickImpl();}catch(const std::exception& e){TDU_Log("CYS-QUICKBAR: FAIL step=%d %s",S().step,e.what());S().step=99;return true;}}
inline const char* ShotName(){auto p=S().shot;S().shot=nullptr;return p;}
}
