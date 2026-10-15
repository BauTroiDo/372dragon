#pragma once
#include "CysRuntimePolishProbe.h"
#include "../Network/CysSkillNet.h"
#include "../Network/CysModernHandlers.h"
namespace CysGameplayAuditProbe {
struct State {int step=0,mode=0,after=0,item=-1;DWORD at=0;float xy[2]={},x=0,z=0;const char* shot=nullptr;};
inline State& S(){static State s;return s;}
inline void Check(bool ok,const char* why){TDU_Log("CYS-GAMEPLAY-AUDIT: %s %s",ok?"PASS":"FAIL",why);if(!ok)throw std::runtime_error(why);}
inline void Lua(const char* env,const char* code){auto r=CScriptSystem::GetMe()->EvaluateScript(env,code);Check(r.ok(),r.ok()?"Lua assertions":r.error);}
inline void Go(int n){S().step=n;S().at=GetTickCount();}
inline const char* ShotName(){auto p=S().shot;S().shot=nullptr;return p;}
inline void Click(const char* name,int next,bool right=false){CysQuickbarProbe::Center(name,S().xy);CysBagProbe::S().pointer(0,S().xy[0],S().xy[1]);S().after=next;Go(right?92:90);}
inline void Bag(int index,int next,bool right=false){char n[96];CysBagProbe::ButtonName(index,n);Click(n,next,right);}
inline bool Identified(int index){auto p=CDataPool::GetMe()->UserBag_GetItem(index);return p&&p->GetItemClass()==ICLASS_EQUIP&&static_cast<CObject_Item_Equip*>(p)->GetEquipAttrib()==CObject_Item_Equip::EQUIP_ATTRIB_IDENTIFY;}
inline bool WireIdentified(int index,bool expected){auto p=CDataPool::GetMe()->UserBag_GetItem(index);if(!p)return false;USHORT w=0,s=0;UINT id=0;p->GetGUID(w,s,id);CysEquipmentTooltip::Snapshot snapshot;return CysModernHandlers::EquipmentTooltip((BYTE)w,(BYTE)s,id,p->GetIdTable(),snapshot)&&((snapshot.status&2)!=0)==expected;}
inline void HoverBag(int index,int next){Check(index>=0,"bag equipment exists");char n[96];CysBagProbe::ButtonName(index,n);CysQuickbarProbe::Center(n,S().xy);CysBagProbe::S().pointer(0,S().xy[0],S().xy[1]);Go(next);}
inline bool TickImpl(){auto& s=S();if(!getenv("CYS_GAMEPLAY_AUDIT_LIVE")||s.step==99)return true;
 auto self=CObjectManager::GetMe()->GetMySelf();auto& b=CysBagProbe::S();
 if(!s.mode){s.mode=atoi(getenv("CYS_GAMEPLAY_AUDIT_LIVE"));Check(getenv("CYS_BOT_ACCOUNT")&&!strcmp(getenv("CYS_BOT_ACCOUNT"),"test15"),"owned test15 fixture");auto m=GetModuleHandleA("UI_CEGUI.dll");b.pointer=(CysUiInputBridge::SmokePointer)GetProcAddress(m,"CysUiSmokePointer");b.rect=(CysUiInputBridge::GetWindowRectUtf8)GetProcAddress(m,"CysUiGetWindowRectUtf8");b.read=(CysUiInputBridge::ReadActionButtonUtf8)GetProcAddress(m,"CysUiReadActionButtonUtf8");Go(s.mode==4?34:s.mode==3?30:s.mode==2?20:1);return false;}
 if(GetTickCount()-s.at<1000)return false;
 switch(s.step){
 case 90:b.pointer(1,s.xy[0],s.xy[1]);Go(91);break;
 case 91:b.pointer(2,s.xy[0],s.xy[1]);Go(s.after);break;
 case 92:b.pointer(3,s.xy[0],s.xy[1]);Go(93);break;
 case 93:b.pointer(4,s.xy[0],s.xy[1]);Go(s.after);break;
 case 30:Lua("MainMenuBar_Env","assert(Player:GetAbilityInfo(49,'level')==1);local a,g=DataPool:GetPrescrList_Item_LifeAbility(399);assert(a==49 and g==28);local n,t,l=LifeAbility:GetPrescr_Material_Tooltip(20103037);assert(n and string.len(n)>0 and t and string.len(t)>0);PushEvent('OPEN_COMPOSE_ITEM',49)");Go(31);break;
 case 31:Check(CysBagProbe::Shown("Synthesize"),"material conversion UI opens");Lua("Synthesize_Env","assert(Synthesize_Item_List:GetItemNumber()>0);Synthesize_Item_List:SetItemSelectByItemID(399);Synthesize_ListBox_Selected();Synthesize_MadeAmount:SetText('1');assert(Synthesize_Make:GetProperty('Disabled')=='False')");s.shot="craft-material-conversion";Click("Synthesize_Make",32);break;
 case 32:if(GetTickCount()-s.at<8500)break;Check(CDataPool::GetMe()->UserBag_CountItemByIDTable(20103037)==1&&CDataPool::GetMe()->UserBag_CountItemByIDTable(20103061)==1,"original CY conversion consumes one raw material and grants one result");Lua("Synthesize_Env","CloseWindow('Synthesize',true)");CysInventoryIntegrityProbe::Unique();Go(21);break;
 case 34:Check(CDataPool::GetMe()->UserBag_CountItemByIDTable(20103037)==1&&CDataPool::GetMe()->UserBag_CountItemByIDTable(20103061)==1,"converted material quantities persist across relogin");CysInventoryIntegrityProbe::Unique();Go(21);break;
 case 1:CGameProcedure::s_pGameInterface->Player_MoveTo(fVector2(218.0f,109.0f));Go(10);break;
 case 10:if(GetTickCount()-s.at<6000)break;if(std::hypot(self->GetPosition().x-216.0f,self->GetPosition().z-110.0f)>=4.5f&&GetTickCount()-s.at<45000)break;Check(std::hypot(self->GetPosition().x-216.0f,self->GetPosition().z-110.0f)<4.5f,"walked to active CY forge on valid navmesh");Lua("MainMenuBar_Env","assert(Player:GetAbilityInfo(4,'level')==1);local a,g=DataPool:GetPrescrList_Item_LifeAbility(1);assert(a==4 and g==1);assert(LifeAbility:GetPrescr_Item_Maximum(1)==2);PushEvent('OPEN_COMPOSE_ITEM',4)");Go(2);break;
 case 2:Check(CysBagProbe::Shown("Synthesize"),"authored synthesis window opens");Lua("Synthesize_Env","Synthesize_Item_List:SetItemSelectByItemID(1);Synthesize_ListBox_Selected();Synthesize_MadeAmount:SetText('1');CysAuditMakeCalls=0;local make=Synthesize_Do_Clicked;Synthesize_Do_Clicked=function() CysAuditMakeCalls=CysAuditMakeCalls+1;return make()end;assert(Synthesize_Make:GetProperty('Disabled')=='False')");s.shot="craft-recipe-materials";Click("Synthesize_Make",3);break;
 case 3:if(GetTickCount()-s.at<8500)break;Lua("Synthesize_Env","assert(CysAuditMakeCalls==1)");Check(CysBagProbe::Quantity(10200011)==1,"native Make button creates exactly one authored weapon");Lua("Synthesize_Env","assert(LifeAbility:GetPrescr_Item_Maximum(1)==1);CloseWindow('Synthesize',true)");CysInventoryIntegrityProbe::Unique();CEventSystem::GetMe()->PushEvent(GE_TOGLE_CONTAINER);Go(4);break;
 case 4:Lua("Packet_Env","Packet_ChangeTabIndex(0)");Check(!Identified(CysInventoryIntegrityProbe::Find(10200011)),"crafted weapon respects rule 22 requiring identification");s.item=CysInventoryIntegrityProbe::Find(10200001);HoverBag(s.item,11);break;
 case 11:if(GetTickCount()-s.at<2500)break;Check(WireIdentified(s.item,false)&&!Identified(s.item),"hover fetches authoritative unidentified equipment");Bag(CysInventoryIntegrityProbe::Find(30506001),5,true);break;
 case 5:Bag(s.item,6);break;
 case 6:Check(Identified(s.item)&&CysBagProbe::Quantity(30506001)==1,"native identify consumes one scroll and reveals equipment");s.shot="craft-identified-weapon";Bag(s.item,7);break;
 case 7:Check(CysBagProbe::Quantity(30506001)==1,"repeat identification does not consume another scroll");CysQuickbarProbe::Key(KC_ESCAPE);Lua("Packet_Env","CloseWindow('Packet',true)");Check(CysSkillNet::XinfaLevel(1)==1,"xinfa fixture level one");Lua("MainMenuBar_Env","SendAskStudyXinfa(1,1,0)");Go(8);break;
 case 8:Check(CysSkillNet::XinfaLevel(1)==2,"Lua study action upgrades authoritative xinfa");Lua("MainMenuBar_Env","SendAskStudyXinfa(1,1,0)");Go(9);break;
 case 9:Check(CysSkillNet::XinfaLevel(1)==2,"stale xinfa request cannot purchase another level");Go(21);break;
 case 20:CEventSystem::GetMe()->PushEvent(GE_TOGLE_CONTAINER);Go(23);break;
 case 23:Lua("Packet_Env","Packet_ChangeTabIndex(0)");s.item=CysInventoryIntegrityProbe::Find(10200001);HoverBag(s.item,24);break;
 case 24:if(GetTickCount()-s.at<2500)break;Check(CysBagProbe::Quantity(10200011)==1&&CysBagProbe::Quantity(10200001)==1&&s.item>=0&&WireIdentified(s.item,true)&&Identified(s.item),"crafted output and separately identified weapon survive relogin");Check(CysBagProbe::Quantity(30506001)==1&&CysSkillNet::XinfaLevel(1)==2,"scroll count and xinfa survive relogin");Lua("MainMenuBar_Env","assert(LifeAbility:GetPrescr_Item_Maximum(1)==1)");CysInventoryIntegrityProbe::Unique();Lua("Packet_Env","CloseWindow('Packet',true)");Go(21);break;
 case 21:s.x=self->GetPosition().x;s.z=self->GetPosition().z;CysAccel::SetChatting(false);Check(CysWorldReplay::LiveGroundClick(7),"world movement input accepted");Go(22);break;
 case 22:if(GetTickCount()-s.at<3500)break;Check(std::hypot(self->GetPosition().x-s.x,self->GetPosition().z-s.z)>0.5f,"character moves after crafting and study");TDU_Log("CYS-GAMEPLAY-AUDIT: RESULT mode=%d errors=0",s.mode);s.step=99;return true;
 }return false;
}
inline bool Tick(){try{return TickImpl();}catch(const std::exception& e){TDU_Log("CYS-GAMEPLAY-AUDIT: FAIL step=%d %s",S().step,e.what());S().step=99;return true;}}
}
