#pragma once
#include "CysQuickbarProbe.h"
#include "../FakeObject/GMFakeObjSystem.h"
#include "CysHost_MeshWin.h"

// Opt-in, owned test15 only. The equip/unequip steps use the real server action.
// The model sweep afterwards exercises all ten existing CY presentation assets.
namespace CysWuhunPreviewProbe {
struct State { int step=0, model=2341; DWORD at=0; float x=0,z=0; const char* shot=nullptr; };
inline State& S(){static State s;return s;}
inline const char* ShotName(){auto p=S().shot;S().shot=nullptr;return p;}
inline void Check(bool ok,const char* why){TDU_Log("CYS-WUHUN-PREVIEW: %s %s",ok?"PASS":"FAIL",why);if(!ok)throw std::runtime_error(why);}
inline void Lua(const char* env,const char* code){auto r=CScriptSystem::GetMe()->EvaluateScript(env,code);Check(r.ok(),r.ok()?"Lua action":r.error);}
inline void Go(int n){S().step=n;S().at=GetTickCount();}
inline CObject_Character* Avatar(const char* name){return (CObject_Character*)CFakeObjSystem::GetMe()->FindFakeObject(name);}
inline void Model(const char* name,int expected){
 auto obj=Avatar(name);Check(obj!=nullptr,"dedicated soul object exists");
 Check(obj->GetCharacterData()->Get_RaceID()==INVALID_ID,"soul does not resolve a creature race");
 Check(obj->GetCharacterData()->Get_ModelID()==expected,"soul resolves exact CharModelEx ID");
 Check((obj->GetRenderInterface()!=nullptr)==(expected>0),"render entity agrees with equipped state");
 TDU_Log("CYS-WUHUN-PREVIEW: model object=%s id=%d entity=%d",name,expected,obj->GetRenderInterface()!=nullptr);
}
inline void Bind(int model){
 Lua("Wuhun_Env","Wuhun_FakeObject:SetFakeObject('')");
 CDataPool::GetMe()->Wuhun_SetModel(model);
 Lua("Wuhun_Env","Wuhun_FakeObject:SetFakeObject('My_Wuhun');if CysWuhunPreviewCamera then CysWuhunPreviewCamera() end");
}
inline bool TickImpl(){auto& s=S();const char* enabled=getenv("CYS_WUHUN_PREVIEW_LIVE");
 if(!enabled||strcmp(enabled,"1")||s.step==99)return true;
 if(GetTickCount()-s.at<1400)return false;
 auto self=CObjectManager::GetMe()->GetMySelf();auto pool=CDataPool::GetMe();
 switch(s.step){
 case 0:
  Check(getenv("CYS_BOT_ACCOUNT")&&!strcmp(getenv("CYS_BOT_ACCOUNT"),"test15"),"owned test15 fixture");
  Check(pool->UserEquip_GetItem((HUMAN_EQUIP)18)!=nullptr,"real equipped soul available");
  Lua("SelfEquip_Env","ToggleWuhunPage()");Go(1);break;
 case 1:
  Check(CGameProcedure::s_pUISystem->IsWindowShow("Wuhun")!=FALSE,"Wuhun page opens");
  Model("My_Wuhun",2341);s.shot="wuhun-flame-only";Go(2);break;
 case 2:
  Lua("Wuhun_Env","if CysWuhunPreviewCamera then local h,d,p=Wuhun_FakeObject:GetCameraEx();assert(math.abs(d-1.0)<0.001);Wuhun_Update();Wuhun_Update();h,d,p=Wuhun_FakeObject:GetCameraEx();assert(math.abs(d-1.0)<0.001) end;Wuhun_FakeObject:RotateBegin(0.6)");Go(20);break;
 case 20:s.shot="wuhun-flame-rotated";Lua("Wuhun_Env","Wuhun_FakeObject:RotateEnd()");Go(21);break;
 case 21:Lua("Wuhun_Env","Wuhun_Equip_Clicked(2)");Go(3);break;
 case 3:
  Check(!pool->UserEquip_GetItem((HUMAN_EQUIP)18),"server unequips soul");Model("My_Wuhun",-1);
  s.shot="wuhun-empty";Go(4);break;
 case 4:{int slot=-1;for(int i=0;i<100;++i){auto item=pool->UserBag_GetItem(i);if(item&&item->GetIdTable()==10156001){slot=i;break;}}
  Check(slot>=0,"unequipped soul returned to bag");
  CGameProcedure::s_pGameInterface->PacketItem_UserEquip(slot);Go(5);break;}
 case 5:Check(pool->UserEquip_GetItem((HUMAN_EQUIP)18)!=nullptr,"server reequips soul");Model("My_Wuhun",2341);
  Lua("Wuhun_Env","this:Hide();ToggleWuhunPage()");Go(6);break;
 case 6:Model("My_Wuhun",2341);Check(CGameProcedure::s_pUISystem->IsWindowShow("Wuhun")!=FALSE,"reopened soul window");
  Bind(s.model);Go(7);break;
 case 7:
  Model("My_Wuhun",s.model);
  pool->TargetWuhun_SetModel(s.model);Model("Other_Wuhun",s.model);
  {static const char* shots[]={"wuhun-flame-base","wuhun-flame-variant1","wuhun-flame-variant2","wuhun-flame-variant3","wuhun-flame-variant4","wuhun-disc-only","wuhun-disc-variant1","wuhun-disc-variant2","wuhun-disc-variant3","wuhun-disc-variant4"};s.shot=shots[s.model-2341];}
  Lua("Wuhun_Env","if CysWuhunPreviewCamera then local h,d,p=Wuhun_FakeObject:GetCameraEx();assert(math.abs(d-1.0)<0.001) end");
  if(s.model<2350){++s.model;Go(8);}else Go(9);break;
 case 8:Bind(s.model);Go(7);break;
 case 9:
  Bind(-1);Model("My_Wuhun",-1);pool->TargetWuhun_SetModel(-1);Model("Other_Wuhun",-1);
  Lua("Wuhun_Env","Wuhun_Update();this:Hide()");CEventSystem::GetMe()->PushEvent(GE_OPEN_EQUIP);Go(10);break;
 case 10:
  Check(CGameProcedure::s_pUISystem->IsWindowShow("SelfEquip")!=FALSE,"normal equipment page opens");
  Check(Avatar("Player") && Avatar("Player")!=Avatar("My_Wuhun") && Avatar("Player")->GetRenderInterface(),"normal player portrait still renders independently");
  s.shot="wuhun-selfequip-regression";Go(11);break;
 case 11:Lua("SelfEquip_Env","this:Hide()");s.x=self->GetPosition().x;s.z=self->GetPosition().z;
  Check(CysWorldReplay::LiveGroundClick(7),"movement input after soul window");Go(12);break;
 case 12:
  if(GetTickCount()-s.at<3500)break;
  Check(std::hypot(self->GetPosition().x-s.x,self->GetPosition().z-s.z)>0.5f,"character moves after UI closes");
  TDU_Log("CYS-WUHUN-PREVIEW: RESULT errors=0");s.step=99;return true;
 }
 return false;
}
inline bool Tick(){try{return TickImpl();}catch(const std::exception& e){TDU_Log("CYS-WUHUN-PREVIEW: FAIL step=%d %s",S().step,e.what());S().step=99;return true;}}
}
