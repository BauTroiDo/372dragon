#pragma once
#include "CysSmartEquipProbe.h"
namespace CysCurrencyProbe {
struct State {int step=0,mode=0,goods=-1,item=0,price=0,money=0;DWORD at=0;unsigned replies=0;float xy[2]={},x=0,z=0;const char* shot=nullptr;};
inline State& S(){static State s;return s;}
inline void Check(bool ok,const char* why){TDU_Log("CYS-CURRENCY: %s %s",ok?"PASS":"FAIL",why);if(!ok)throw std::runtime_error(why);}
inline void Lua(const char* env,const char* code){auto r=CScriptSystem::GetMe()->EvaluateScript(env,code);Check(r.ok(),r.ok()?"Lua":r.error);}
inline void Go(int n){S().step=n;S().at=GetTickCount();}
inline const char* ShotName(){auto p=S().shot;S().shot=nullptr;return p;}
inline bool TickImpl(){auto& s=S();if(!getenv("CYS_CURRENCY_LIVE")||s.step==99)return true;
 auto self=CObjectManager::GetMe()->GetMySelf();auto data=self->GetCharacterData();auto pool=CDataPool::GetMe();auto& b=CysBagProbe::S();auto c=CysInventoryNet::Get();
 if(!s.mode){s.mode=atoi(getenv("CYS_CURRENCY_LIVE"));Check(getenv("CYS_BOT_ACCOUNT")&&!strcmp(getenv("CYS_BOT_ACCOUNT"),"test15"),"owned test15");auto mod=GetModuleHandleA("UI_CEGUI.dll");b.pointer=(CysUiInputBridge::SmokePointer)GetProcAddress(mod,"CysUiSmokePointer");b.rect=(CysUiInputBridge::GetWindowRectUtf8)GetProcAddress(mod,"CysUiGetWindowRectUtf8");b.read=(CysUiInputBridge::ReadActionButtonUtf8)GetProcAddress(mod,"CysUiReadActionButtonUtf8");CEventSystem::GetMe()->PushEvent(GE_TOGLE_CONTAINER);Go(1);return false;}
 if(GetTickCount()-s.at<1200)return false;
 switch(s.step){
 case 1:Check(data->Get_MoneyJZ()==0&&data->Get_BindRMB()==0,"legacy wallet fields zero");Check(data->Get_RMB()==345,"yuanbao conserved");
  Check(s.mode==1?data->Get_Money()==230745:(data->Get_Money()<230745&&data->Get_Money()>=229745),"Vo Thach persistence");
  Lua("Packet_Env","assert(Packet_Jiaozi_Back:IsVisible()==false);assert(Packet_BangdingYuanbao_Back:IsVisible()==false);assert(Packet_Fanquan_Back:IsVisible()==false);assert(Packet_Money:GetProperty('GoldIcon')=='set:CysVoThach image:Upper');assert(tonumber(Packet_Money:GetProperty('MoneyNumber'))==Player:GetData('MONEY'));assert(Player:GetData('MONEY_JZ')==0)");
  CysQuickbarProbe::Center("Packet_Money",s.xy);b.pointer(0,s.xy[0],s.xy[1]);Go(2);break;
 case 2:s.shot="vothach-bag";Go(3);break;
 case 3:Lua("Packet_Env","this:Hide()");CEventSystem::GetMe()->PushEvent(GE_UI_COMMAND,1002);Go(4);break;
 case 4:Check(CysBagProbe::Shown("EquipStrengthen"),"forge open");Lua("EquipStrengthen_Env","assert(Forge_Jiaozi:IsVisible()==false);assert(tonumber(Forge_Money:GetProperty('MoneyNumber'))==Player:GetData('MONEY'))");s.shot="vothach-forge";Go(5);break;
 case 5:Lua("EquipStrengthen_Env","this:Hide()");if(s.mode==2){Go(20);break;}CGameProcedure::s_pGameInterface->Player_MoveTo(fVector2(271,135));Go(6);break;
 case 6:{auto p=self->GetPosition();if(std::hypot(p.x-271,p.z-133)>6){if(GetTickCount()-s.at>45000)Check(false,"NPC walk timeout");break;}unsigned id=CysModernGame::NearestObjectAt(271,133,3,nullptr);Check(id!=0,"shop NPC");s.replies=c.eventLists;CGameProcedure::s_pGameInterface->Player_Speak(id);Go(7);break;}
 case 7:if(c.eventLists<=s.replies){if(GetTickCount()-s.at>10000)Check(false,"dialogue timeout");break;}{int script=0,index=0;Check(CysInventoryNet::LastShopOption(script,index)&&script==2051,"shop option");s.replies=c.shopLists;CUIDataPool::GetMe()->SendSelectEvent(0,script,index);Go(8);break;}
 case 8:if(c.shopLists<=s.replies){if(GetTickCount()-s.at>10000)Check(false,"shop timeout");break;}Check(CysBagProbe::Shown("Shop")&&CysBagProbe::Shown("Packet"),"shop and bag open");
  for(int i=0;i<pool->Booth_GetNumber()&&i<12;++i){auto item=pool->Booth_GetItem(i);int cost=pool->Booth_GetItemPrice(i);if(item&&cost>0&&cost<=1000&&CysBagProbe::Quantity(item->GetIdTable())==0){s.goods=i;s.item=item->GetIdTable();s.price=cost;break;}}
  Check(s.goods>=0,"cheap new item");s.money=data->Get_Money();s.replies=c.shopBuys;{char name[64];_snprintf(name,64,"Shop_Item%d",s.goods+1);CysQuickbarProbe::Center(name,s.xy);b.pointer(0,s.xy[0],s.xy[1]);b.pointer(1,s.xy[0],s.xy[1]);b.pointer(2,s.xy[0],s.xy[1]);Go(9);break;}
 case 9:Check(c.shopBuys==s.replies+1&&CysBagProbe::Quantity(s.item)==1,"one purchase one item");Check(data->Get_Money()==s.money-s.price&&data->Get_MoneyJZ()==0&&data->Get_RMB()==345,"exact Vo Thach deduction only");CysInventoryIntegrityProbe::Unique();TDU_Log("CYS-CURRENCY: PURCHASE item=%d price=%d before=%d after=%d",s.item,s.price,s.money,data->Get_Money());s.shot="vothach-shop-purchase";Go(10);break;
 case 10:Lua("Shop_Env","this:Hide()");Lua("Packet_Env","this:Hide()");Go(20);break;
 case 20:if(CysBagProbe::Shown("Packet"))Lua("Packet_Env","this:Hide()");s.x=self->GetPosition().x;s.z=self->GetPosition().z;CysAccel::SetChatting(false);Check(CysWorldReplay::LiveGroundClick(7),"movement after currency UI");Go(21);break;
 case 21:if(GetTickCount()-s.at<3500)break;Check(std::hypot(self->GetPosition().x-s.x,self->GetPosition().z-s.z)>0.5f,"character moves");TDU_Log("CYS-CURRENCY: RESULT errors=0 mode=%d money=%d yuanbao=%d",s.mode,data->Get_Money(),data->Get_RMB());Go(99);return true;
 }
 return false;
}
inline bool Tick(){try{return TickImpl();}catch(const std::exception& e){TDU_Log("CYS-CURRENCY: FAIL step=%d %s",S().step,e.what());S().step=99;return true;}}
}
