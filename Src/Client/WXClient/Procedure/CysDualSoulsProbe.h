#pragma once
#include "CysWuhunAppearanceProbe.h"
#include "../Network/CysDualSouls.h"
namespace CysDualSoulsProbe {
struct State {int step=0,mode=0,after=0,moves=0;DWORD at=0;bool init=false;float from[2]={},to[2]={},x=0,z=0;unsigned damage=0;const char* shot=nullptr;};
inline State& S(){static State s;return s;}
inline void Check(bool ok,const char* text){TDU_Log("CYS-DUAL-SOULS: %s %s",ok?"PASS":"FAIL",text);if(!ok)throw std::runtime_error(text);}
inline void Lua(const char* text){auto r=CScriptSystem::GetMe()->EvaluateScript("CysDualSouls_Env",text);Check(r.ok(),r.ok()?"Lua":r.error);}
inline const char* ShotName(){auto p=S().shot;S().shot=nullptr;return p;}
inline void Go(int step){S().step=step;S().at=GetTickCount();}
inline void Drag(const char* from,const char* to,int after){auto& s=S();CysQuickbarProbe::Center(from,s.from);CysQuickbarProbe::Center(to,s.to);s.after=after;s.moves=0;CysBagProbe::S().pointer(0,s.from[0],s.from[1]);Go(80);}
inline int Item(int point){auto p=CDataPool::GetMe()->UserEquip_GetItem((HUMAN_EQUIP)point);return p?p->GetIdTable():-1;}
inline void Attached(CObject_Character* who,bool present){Check(who&&who->GetRenderInterface(),"actor created");STRING model;who->GetRenderInterface()->Actor_GetObjectProperty("BattleSoulObj",model);auto row=CysWuhunData::Find(699);TDU_Log("CYS-DUAL-SOULS: attachment item=%d visual=%d model_bytes=%u expected=%d",who->GetCharacterData()->Get_AssaultItem(),who->GetCharacterData()->Get_AssaultVisual(),(unsigned)model.size(),present);Check(model==(present?row->object:""),"independent BattleSoulObj");}
inline int SkillAction(int id){auto a=CActionSystem::GetMe()->GetAction_SkillID(id*100+1);Check(a!=nullptr,"learned soul action exists");return a->GetID();}
inline void Grant(int id){char b[512];_snprintf(b,sizeof(b),"Clear_XSCRIPT();Set_XSCRIPT_ScriptID(900066);Set_XSCRIPT_Function_Name('ConsoleItemUse');Set_XSCRIPT_Parameter(0,1);Set_XSCRIPT_Parameter(1,%d);Set_XSCRIPT_Parameter(2,1);Set_XSCRIPT_Parameter(3,1);Set_XSCRIPT_Parameter(4,1);Set_XSCRIPT_Parameter(5,0);Set_XSCRIPT_ParamCount(6);Send_XSCRIPT()",id);Lua(b);}
inline void GM(int op,int id=0,int count=0){char b[512];_snprintf(b,sizeof(b),"Clear_XSCRIPT();Set_XSCRIPT_ScriptID(900066);Set_XSCRIPT_Function_Name('ConsoleSceneUse');Set_XSCRIPT_Parameter(0,%d);Set_XSCRIPT_Parameter(1,%d);Set_XSCRIPT_Parameter(2,%d);Set_XSCRIPT_Parameter(3,3);Set_XSCRIPT_Parameter(4,0);Set_XSCRIPT_ParamCount(5);Send_XSCRIPT()",op,id,count);Lua(b);}
inline bool TickImpl(){auto& s=S();if(!getenv("CYS_DUAL_SOULS_LIVE")||s.step==99)return true;
 if(!s.init){s.mode=atoi(getenv("CYS_DUAL_SOULS_LIVE"));Check(getenv("CYS_BOT_ACCOUNT")&&!strcmp(getenv("CYS_BOT_ACCOUNT"),"test15"),"private test15 only");auto m=GetModuleHandleA("UI_CEGUI.dll");auto& b=CysBagProbe::S();b.pointer=(CysUiInputBridge::SmokePointer)GetProcAddress(m,"CysUiSmokePointer");b.rect=(CysUiInputBridge::GetWindowRectUtf8)GetProcAddress(m,"CysUiGetWindowRectUtf8");b.read=(CysUiInputBridge::ReadActionButtonUtf8)GetProcAddress(m,"CysUiReadActionButtonUtf8");s.init=true;Go(s.mode==2?40:0);}
 if(GetTickCount()-s.at<1000)return false;
 auto self=CObjectManager::GetMe()->GetMySelf();auto pool=CDataPool::GetMe();auto pointer=CysBagProbe::S().pointer;
 switch(s.step){
 case 0:Check(pool->CoolDownGroup_Get(702)&&!pool->CoolDownGroup_Get(-1)&&!pool->PetSkillCoolDownGroup_Get(702,HUMAN_PET_MAX_COUNT-1),"human soul cooldowns preserve pet bounds");CysQuickbarProbe::Lua("MainMenuBar_Env","MainmenuBar_PageOne()");Lua("CysDualSoulsOpen()");Grant(10156901);Go(70);break;
 case 70:Check(CysBagProbe::Quantity(10156901)==1,"support created through real GM item grant");Grant(10156902);Go(71);break;
 case 71:Check(CysBagProbe::Quantity(10156902)==1,"assault created through real GM item grant");Go(1);break;
 case 1:Check(CysBagProbe::Shown("CysDualSouls"),"Song hon window visible");CysQuickbarProbe::Lua("Packet_Env","Packet_ChangeTabIndex(0)");Drag("Packet_Space_Line1_Row1_button","CysDual_ItemSupport",2);break;
 case 2:Check(Item(18)==10156901,"support equipped by drag");Drag("Packet_Space_Line1_Row2_button","CysDual_ItemAssault",3);break;
 case 3:Check(Item(39)==10156902,"assault equipped by drag");CysInventoryIntegrityProbe::Unique();Attached(self,true);CysWuhunAppearanceProbe::Attached(self,704);
  for(int id=6100;id<=6103;++id)Check(CysSkillNet::SkillLevel(id)==1,"four owned soul skills");s.shot="dual-souls-panel";Lua("CysDualRefresh()");Go(4);break;
 case 4:Drag("CysDual_Skill2","Button_Action1",5);break;
 case 5:Check(CysQuickbarProbe::Bar(0)&&CysQuickbarProbe::Bar(0)->GetDefineID()/100==6101,"real skill drag onto F1");Lua("this:Hide()");CysQuickbarProbe::Lua("Packet_Env","this:Hide()");CysAccel::SetChatting(false);CysQuickbarProbe::Key(KC_F1);Go(6);break;
 case 6:{auto cd=pool->CoolDownGroup_Get(700);Check(cd&&cd->nTime>0,"F1 accepted; authoritative support cooldown");Lua("CysDualSoulsOpen()");Go(7);break;}
 case 7:CysEquipCraftProbe::Click("CysDual_Visible");Go(8);break;
 case 8:Attached(self,false);Check(CysSkillNet::SkillLevel(6102)==1,"hiding preserves skill ownership");CysEquipCraftProbe::Click("CysDual_Visible");Go(9);break;
 case 9:Attached(self,true);Lua("this:Hide()");CysQuickbarProbe::Lua("Packet_Env","this:Hide()");CEventSystem::GetMe()->PushEvent(GE_OPEN_EQUIP);Go(10);break;
 case 10:Attached(CysWuhunPreviewProbe::Avatar("Player"),true);CysWuhunAppearanceProbe::Attached(CysWuhunPreviewProbe::Avatar("Player"),704);s.shot="dual-souls-selfequip";Go(11);break;
 case 11:CysQuickbarProbe::Lua("SelfEquip_Env","this:Hide()");GM(2,507,3);Go(12);break;
 case 12:{unsigned ids[64]={};int target=-1;auto pos=self->GetPosition();auto n=CysModernGame::ObjectsNear(pos.x,pos.z,18,ids,64);
  for(unsigned i=0;i<n;++i){auto obj=(CObject*)CObjectManager::GetMe()->FindServerObject(ids[i]);if(obj&&obj!=(CObject*)self&&CGameProcedure::s_pGameInterface->GetCampType(self,obj)==RELATION_ENEMY){target=ids[i];break;}}
  Check(target>=0,"real enemy target for soul attack");CObjectManager::GetMe()->SetMainTarget(target);CActionSystem::GetMe()->MainMenuBar_Set(30,SkillAction(6102));s.damage=CysModernHandlers::Core().damages;
  CysAccel::SetChatting(false);CInputSystem::GetMe()->CysInjectKey(KC_LMENU,TRUE);CysQuickbarProbe::Key(KC_1);CInputSystem::GetMe()->CysInjectKey(KC_LMENU,FALSE);Go(13);break;}
 case 13:if(GetTickCount()-s.at<4500)return false;{auto cd=pool->CoolDownGroup_Get(701);Check(cd&&cd->nTime>0,"Alt+1 accepted; assault cooldown");Check(CysModernHandlers::Core().damages>s.damage,"single target combat damage received");}s.shot="dual-souls-combat";Lua("CysDualSoulsAction(39)");GM(3);Go(20);break;
 case 20:Check(Item(39)==10156902,"server rejects unequip during combat");GM(2,507,3);Go(21);break;
 case 21:{unsigned ids[64]={};int target=-1;auto pos=self->GetPosition();auto n=CysModernGame::ObjectsNear(pos.x,pos.z,18,ids,64);
  for(unsigned i=0;i<n;++i){auto obj=(CObject*)CObjectManager::GetMe()->FindServerObject(ids[i]);if(obj&&obj!=(CObject*)self&&CGameProcedure::s_pGameInterface->GetCampType(self,obj)==RELATION_ENEMY){target=ids[i];break;}}
  Check(target>=0,"real enemy target for soul AoE");CObjectManager::GetMe()->SetMainTarget(target);CActionSystem::GetMe()->MainMenuBar_Set(1,SkillAction(6103));s.damage=CysModernHandlers::Core().damages;
  TDU_Log("CYS-DUAL-SOULS: AOE begin owner=%d",self->GetServerID());CysAccel::SetChatting(false);CysQuickbarProbe::Key(KC_F2);Go(22);break;}
 case 22:if(GetTickCount()-s.at<5500)return false;{auto cd=pool->CoolDownGroup_Get(702);Check(cd&&cd->nTime>0,"F2 accepted; AoE cooldown");Check(CysModernHandlers::Core().damages>s.damage,"AoE combat damage received");}TDU_Log("CYS-DUAL-SOULS: AOE end");s.shot="dual-souls-aoe";GM(3);Go(14);break;
 case 14:if(GetTickCount()-s.at<11500)return false;Lua("CysDualSoulsOpen()");Go(15);break;
 case 15:CysEquipCraftProbe::Click("CysDual_UnwearAssault");Go(16);break;
 case 16:Check(Item(39)<0&&CysSkillNet::SkillLevel(6102)<0&&CysSkillNet::SkillLevel(6103)<0,"unequip revokes assault skills");Check(CysSkillNet::SkillLevel(6101)==1,"support remains independent");Attached(self,false);CysInventoryIntegrityProbe::Unique();Go(17);break;
 case 17:{int slot=-1;for(int i=0;i<100;++i){auto item=pool->UserBag_GetItem(i);if(item&&item->GetIdTable()==10156902)slot=i;}Check(slot>=0,"assault returned to bag once");char name[96];CysBagProbe::ButtonName(slot,name);Drag(name,"CysDual_ItemAssault",18);break;}
 case 18:Check(Item(39)==10156902&&CysSkillNet::SkillLevel(6102)==1,"re-equip restores skills");{auto cd=pool->CoolDownGroup_Get(701);Check(cd&&cd->nTime>0,"re-equip preserves cooldown");}Lua("this:Hide()");CysQuickbarProbe::Lua("Packet_Env","this:Hide()");s.x=self->GetPosition().x;s.z=self->GetPosition().z;Check(CysWorldReplay::LiveGroundClick(7),"movement after UI");Go(19);break;
 case 19:if(GetTickCount()-s.at<3500)return false;Check(std::hypot(self->GetPosition().x-s.x,self->GetPosition().z-s.z)>0.5f,"character still moves");TDU_Log("CYS-DUAL-SOULS: RESULT errors=0");Go(99);return true;
 case 40:Check(Item(18)==10156901&&Item(39)==10156902,"both independent items survived relogin");Attached(self,true);for(int id=6100;id<=6103;++id)Check(CysSkillNet::SkillLevel(id)==1,"skills survived relogin");s.shot="dual-souls-relogin-world";CEventSystem::GetMe()->PushEvent(GE_OPEN_EQUIP);Go(41);break;
 case 41:Attached(CysWuhunPreviewProbe::Avatar("Player"),true);s.shot="dual-souls-relogin-selfequip";Go(43);break;
 case 43:CysQuickbarProbe::Lua("SelfEquip_Env","this:Hide()");Lua("CysDualSoulsOpen()");Go(42);break;
 case 42:s.shot="dual-souls-relogin-panel";Go(44);break;
 case 44:Lua("this:Hide()");CysQuickbarProbe::Lua("Packet_Env","this:Hide()");Lua("Clear_XSCRIPT();Set_XSCRIPT_ScriptID(900066);Set_XSCRIPT_Function_Name('ConsoleSceneUse');Set_XSCRIPT_Parameter(0,1);Set_XSCRIPT_Parameter(1,2);Set_XSCRIPT_Parameter(2,160);Set_XSCRIPT_Parameter(3,150);Set_XSCRIPT_Parameter(4,0);Set_XSCRIPT_ParamCount(5);Send_XSCRIPT()");Go(45);break;
 case 45:if(!CysModernGame::IsInWorld()||CysModernGame::CurrentSceneId()!=2||!self||!self->GetRenderInterface()){Check(GetTickCount()-s.at<45000,"scene transfer within deadline");return false;}
  if(GetTickCount()-s.at<5000)return false;
  Check(Item(18)==10156901&&Item(39)==10156902,"two soul items survive scene transfer");Attached(self,true);CysWuhunAppearanceProbe::Attached(self,704);
  for(int id=6100;id<=6103;++id)Check(CysSkillNet::SkillLevel(id)==1,"soul skill entitlement survives scene transfer");s.shot="dual-souls-transferred";Go(46);break;
 case 46:TDU_Log("CYS-DUAL-SOULS: RELOGIN errors=0");Go(99);return true;
 case 80:pointer(1,s.from[0],s.from[1]);Go(81);break;
 case 81:++s.moves;pointer(0,s.from[0]+(s.to[0]-s.from[0])*s.moves/4,s.from[1]+(s.to[1]-s.from[1])*s.moves/4);if(s.moves<4){s.at=GetTickCount()-800;return false;}Go(82);break;
 case 82:pointer(2,s.to[0],s.to[1]);Go(s.after);break;
 }
 return false;
}
inline bool Tick(){try{return TickImpl();}catch(const std::exception& e){TDU_Log("CYS-DUAL-SOULS: FAIL step=%d %s",S().step,e.what());if(S().step>=11&&S().step<40){try{GM(3);}catch(...){}}S().step=99;return true;}}
}
