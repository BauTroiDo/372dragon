#pragma once
#include "CysQuickbarProbe.h"
// Opt-in owned test15. Read UI state, use actual pointer drag + actual Space input.
namespace CysForgeProbe {
struct State {int mode=-1,step=0,moves=0,hits=0,lastNonce=0;DWORD at=0;float from[2]={},to[2]={};const char* shot=nullptr;};
inline State& S(){static State s;return s;}
inline void Go(int n){S().step=n;S().at=GetTickCount();}
inline void Check(bool ok,const char* text){if(!ok)throw std::runtime_error(text);TDU_Log("CYS-FORGE-PROBE: PASS %s",text);}
inline LuaPlus::LuaObject UI(){auto o=CScriptSystem::GetMe()->GetLuaState()->GetGlobals().GetByName("CysForge_State");if(!o.IsTable())throw std::runtime_error("forge state table missing");return o;}
inline double Num(const char* key){auto o=UI().GetByName(key);return o.IsNumber()?o.GetNumber():0;}
inline std::string Phase(){auto o=UI().GetByName("phase");return o.IsString()?o.GetString():"";}
inline void Center(const char* name,float* p){float r[4]={};Check(CysBagProbe::S().rect(name,r)==1,name);p[0]=r[0]+r[2]/2;p[1]=r[1]+r[3]/2;}
inline void Lua(const char* code){auto r=CScriptSystem::GetMe()->EvaluateScript("EquipStrengthen_Env",code);Check(r.ok(),r.error);}
inline void Click(const char* name){float p[2];Center(name,p);auto f=CysBagProbe::S().pointer;f(0,p[0],p[1]);f(1,p[0],p[1]);f(2,p[0],p[1]);}
inline bool TickImpl(){auto& s=S();
 if(s.mode<0){const char* v=getenv("CYS_FORGE_LIVE");s.mode=v?atoi(v):0;if(!s.mode)return true;
  Check(getenv("CYS_BOT_ACCOUNT")&&!strcmp(getenv("CYS_BOT_ACCOUNT"),"test15"),"private test15 only");
  auto m=GetModuleHandleA("UI_CEGUI.dll");auto& b=CysBagProbe::S();
  b.pointer=(CysUiInputBridge::SmokePointer)GetProcAddress(m,"CysUiSmokePointer");
  b.rect=(CysUiInputBridge::GetWindowRectUtf8)GetProcAddress(m,"CysUiGetWindowRectUtf8");
  Check(b.pointer&&b.rect,"UI input bridge");Go(0);
 }
 if(!s.mode||s.step==99)return true;
 DWORD age=GetTickCount()-s.at;auto pointer=CysBagProbe::S().pointer;
 if(age>90000)throw std::runtime_error("forge step timed out");
 if(s.step!=8&&s.step!=11&&age<450)return false;
 switch(s.step){
 case 0:
  CEventSystem::GetMe()->PushEvent(GE_UI_COMMAND,1002);
  if(!CysBagProbe::Shown("Packet"))CEventSystem::GetMe()->PushEvent(GE_TOGLE_CONTAINER);
  Go(1);break;
 case 1:
  Check(CysBagProbe::Shown("EquipStrengthen"),"existing NPC frame opened");s.shot="forge-empty";
  {char name[80];CysBagProbe::ButtonName(18,name);Center(name,s.from);Center("Forge_Equip",s.to);}
  pointer(0,s.from[0],s.from[1]);Go(2);break;
 case 2:pointer(1,s.from[0],s.from[1]);s.moves=0;Go(3);break;
 case 3:
  ++s.moves;pointer(0,s.from[0]+(s.to[0]-s.from[0])*s.moves/6,s.from[1]+(s.to[1]-s.from[1])*s.moves/6);
  if(s.moves==6)Go(4);else s.at=GetTickCount()-400;break;
 case 4:pointer(2,s.to[0],s.to[1]);Go(s.hits==-1?6:5);break;
 case 5:
  if(Phase()=="quote"&&age<10000)break;
  TDU_Log("CYS-FORGE-PROBE: quote equip=%.0f level=%.0f phase=%s",Num("equip"),Num("level"),Phase().c_str());
  Check(Num("equip")==18&&Phase()=="ready"&&Num("level")== (s.mode==3?0:2),"real equipment drag + server quote");
  if(s.mode==3){Check(CysBagProbe::Quantity(30900005)==28,"relogin retains two consumed materials");Go(12);break;}
  {char name[80];CysBagProbe::ButtonName(19,name);Center(name,s.from);Center("Forge_Material",s.to);}
  s.hits=-1;pointer(0,s.from[0],s.from[1]);Go(2);break;
 case 6:
  if(Phase()=="quote"&&age<10000)break;
  Check(Num("material")==19&&Phase()=="ready","real material drag + server quote");s.shot="forge-ready";Go(7);break;
 case 7:Click("Forge_Start");Go(8);break;
 case 8:
  if(Phase()=="run"){
   if(s.mode==2){CysInventoryIntegrityProbe::Swap(18,0);Go(21);break;}
   double t=double(GetTickCount())-Num("at")+Num("offset")-Num("delay");
   if(t>100&&t<350){s.shot="forge-first-attempt";CysQuickbarProbe::Key(KC_SPACE);Go(9);}
  }break;
 case 9:
  Check(Phase()=="failed"&&Num("level")==1,"miss or cancel lowers +2 to +1 and stops");s.shot="forge-miss";s.hits=0;Go(10);break;
 case 10:Click("Forge_Start");Go(s.mode==2?20:11);break;
 case 11:
  if(Phase()=="failed"||Phase()=="error")throw std::runtime_error("forge timed hit failed");
  if(Num("level")==9){Check(s.hits==8,"eight real Space hits to cap9");s.shot="forge-cap9";Go(12);break;}
  if(Phase()=="run"&&int(Num("nonce"))!=s.lastNonce){
   double t=double(GetTickCount())-Num("at")+Num("offset")-Num("delay");double period=Num("period");
   if(t<0||period<=0)break;double x=fmod(t,period*2);if(x>period)break;
   double p=x*10000/period,center=Num("center"),width=Num("width");
   if(p>=center-width/4&&p<=center){s.lastNonce=int(Num("nonce"));++s.hits;CysQuickbarProbe::Key(KC_SPACE);}
  }break;
 case 12:
  CysQuickbarProbe::Key(KC_ESCAPE);Go(13);break;
 case 13:
  if(CysBagProbe::Shown("EquipStrengthen")){CysQuickbarProbe::Key(KC_ESCAPE);Go(14);}else Go(14);break;
 case 14:
  Check(!CysBagProbe::Shown("EquipStrengthen"),"Escape closes forge and releases Space capture");
  if(s.mode==3){CysInventoryIntegrityProbe::Swap(18,0);Go(16);break;}
  Go(18);break;
 case 18:
  {const auto& p=CObjectManager::GetMe()->GetMySelf()->GetPosition();s.from[0]=p.x;s.from[1]=p.z;}
  CysAccel::SetChatting(false);Check(CysWorldReplay::LiveGroundClick(7),"ground click after forge closed");Go(15);break;
 case 15:
  if(age<2000)break;
  {const auto& p=CObjectManager::GetMe()->GetMySelf()->GetPosition();
   Check(fabs(p.x-s.from[0])+fabs(p.z-s.from[1])>0.5f,"position actually changed after forge closed");
   TDU_Log("CYS-FORGE-PROBE: movement before=%.3f,%.3f after=%.3f,%.3f",s.from[0],s.from[1],p.x,p.z);}
  if(s.mode==3){TDU_Log("CYS-FORGE-PROBE: RESULT relogin abandoned level0 unlocked + movement errors=0");Go(99);return true;}
  TDU_Log("CYS-FORGE-PROBE: RESULT real drag + cost + miss + eight hits + cap9 + Escape errors=0");Go(99);return true;
 case 20:
  if(Phase()=="run"){
   Check(Num("level")==1,"second charged attempt active before logout");
   TDU_Log("CYS-FORGE-PROBE: RESULT cancel delevel + leave charged pending errors=0");Go(99);return true;
  }break;
 case 21:
  if(age<1200)break;
  Check(CDataPool::GetMe()->UserBag_GetItem(18)&&!CDataPool::GetMe()->UserBag_GetItem(0),"server refuses moving charged equipment");
  Click("Forge_Stop");Go(9);break;
 case 16:
  if(age<1200)break;
  Check(CDataPool::GetMe()->UserBag_GetItem(0)&&!CDataPool::GetMe()->UserBag_GetItem(18),"server allows moving equipment after abandoned attempt");
  CysInventoryIntegrityProbe::Swap(0,18);Go(17);break;
 case 17:
  if(age<1200)break;
  Check(CDataPool::GetMe()->UserBag_GetItem(18)&&!CDataPool::GetMe()->UserBag_GetItem(0),"restored equipment slot after relogin movement test");
  Go(18);break;
 }
 return false;
}
inline bool Tick(){try{return TickImpl();}catch(const std::exception& e){TDU_Log("CYS-FORGE-PROBE: FAIL %s step=%d",e.what(),S().step);S().step=99;return true;}}
inline const char* ShotName(){auto n=S().shot;S().shot=nullptr;return n;}
}
