#pragma once
#include "CysCurrencyProbe.h"
#include "../FakeObject/GMFakeObjSystem.h"
namespace CysRuntimePolishProbe {
struct State {int mode=0,step=0,after=0,index=0,level=0;DWORD at=0;long long exp=0;float xy[2]={},x=0,z=0;const char* shot=nullptr;};
inline State& S(){static State s;return s;}
inline void Check(bool ok,const char* why){TDU_Log("CYS-RUNTIME-POLISH: %s %s",ok?"PASS":"FAIL",why);if(!ok)throw std::runtime_error(why);}
inline void Lua(const char* env,const char* code){auto r=CScriptSystem::GetMe()->EvaluateScript(env,code);Check(r.ok(),r.ok()?"Lua":r.error);}
inline void Go(int n){S().step=n;S().at=GetTickCount();}
inline const char* ShotName(){auto p=S().shot;S().shot=nullptr;return p;}
inline void Click(const char* name,int next){CysQuickbarProbe::Center(name,S().xy);CysBagProbe::S().pointer(0,S().xy[0],S().xy[1]);S().after=next;Go(90);}
inline void Right(int slot,int next){char name[96];CysBagProbe::ButtonName(slot,name);Click(name,next);Go(92);}
inline bool TickImpl(){auto& s=S();if(!getenv("CYS_RUNTIME_POLISH_LIVE")||s.step==99)return true;
 auto self=CObjectManager::GetMe()->GetMySelf();auto data=self->GetCharacterData();auto& b=CysBagProbe::S();
 if(!s.mode){s.mode=atoi(getenv("CYS_RUNTIME_POLISH_LIVE"));Check(getenv("CYS_BOT_ACCOUNT")&&!strcmp(getenv("CYS_BOT_ACCOUNT"),"test15"),"owned test15");auto mod=GetModuleHandleA("UI_CEGUI.dll");b.pointer=(CysUiInputBridge::SmokePointer)GetProcAddress(mod,"CysUiSmokePointer");b.rect=(CysUiInputBridge::GetWindowRectUtf8)GetProcAddress(mod,"CysUiGetWindowRectUtf8");b.read=(CysUiInputBridge::ReadActionButtonUtf8)GetProcAddress(mod,"CysUiReadActionButtonUtf8");CEventSystem::GetMe()->PushEvent(GE_OPEN_EQUIP,"1");Go(1);return false;}
 if(GetTickCount()-s.at<800)return false;
 if(s.step==1&&s.mode>=3){Lua("SelfEquip_Env","CloseWindow('SelfEquip',true)");CEventSystem::GetMe()->PushEvent(GE_TOGLE_CONTAINER);Go(s.mode==4?35:30);return false;}
 switch(s.step){
 case 90:b.pointer(1,s.xy[0],s.xy[1]);Go(91);break;
 case 91:b.pointer(2,s.xy[0],s.xy[1]);Go(s.after);break;
 case 92:b.pointer(3,s.xy[0],s.xy[1]);Go(93);break;
 case 93:b.pointer(4,s.xy[0],s.xy[1]);Go(s.after);break;
 case 30:Check(CysBagProbe::Quantity(38007057)==2&&CysBagProbe::Quantity(38007035)==0,"gift fixture two boxes no reward");Lua("Packet_Env","Packet_ChangeTabIndex(0)");Right(0,31);break;
 case 31:Check(CysBagProbe::Shown("OptionalGiftBox_Four"),"right click opens native CY gift window");Lua("OptionalGiftBox_Four_Env","local b,n,c=LuaFnGetOptionalGiftBoxInfo(38007057);assert(b==1 and n==4 and c==1);local id,num=LuaFnGetOptionalGiftBoxGiftInfo(38007057);assert(id==38007035 and num==1)");s.shot="gift-four-options";Click("OptionalGiftBox_Four_Item1",32);break;
 case 32:Click("OptionalGiftBox_Four_GetButton",33);break;
 case 33:if(GetTickCount()-s.at<2200)break;Check(CysBagProbe::Quantity(38007057)==1&&CysBagProbe::Quantity(38007035)==1,"gift consumes exactly one box and grants selected reward");CysInventoryIntegrityProbe::Unique();Lua("Packet_Env","Clear_XSCRIPT();Set_XSCRIPT_Function_Name('OnClientGetGift');Set_XSCRIPT_ScriptID(990031);Set_XSCRIPT_Parameter(0,0);Set_XSCRIPT_Parameter(1,1);Set_XSCRIPT_Parameter(2,0);Set_XSCRIPT_Parameter(3,0);Set_XSCRIPT_Parameter(4,0);Set_XSCRIPT_Parameter(5,-1);Set_XSCRIPT_ParamCount(6);Send_XSCRIPT()");Go(34);break;
 case 34:Check(CysBagProbe::Quantity(38007057)==1&&CysBagProbe::Quantity(38007035)==1,"duplicate gift request cannot consume or duplicate items");s.shot="gift-exact-result";Lua("Packet_Env","CloseWindow('Packet',true)");Go(23);break;
 case 35:Check(CysBagProbe::Quantity(38007057)==1&&CysBagProbe::Quantity(38007035)==1,"gift inventory survives relogin exactly");CysInventoryIntegrityProbe::Unique();s.shot="gift-relogin";Lua("Packet_Env","CloseWindow('Packet',true)");Go(23);break;
 case 1:Check(CysBagProbe::Shown("SelfEquip"),"SelfEquip opens");s.level=data->Get_Level();s.exp=data->Get_Exp();
  if(s.mode==1){Lua("SelfEquip_Env","assert(Player:IsCanLevelup()==1);assert(SelfEquip_UpLevel:GetProperty('Disabled')=='False')");s.shot="levelup-enabled";Click("SelfEquip_UpLevel",2);}else Go(3);break;
 case 2:Check(data->Get_Level()==s.level+1&&data->Get_Exp()<s.exp,"actual level button sends request and spends EXP");TDU_Log("CYS-RUNTIME-POLISH: LEVEL before=%d after=%d exp_before=%lld exp_after=%lld",s.level,data->Get_Level(),s.exp,data->Get_Exp());s.shot="levelup-success";Go(3);break;
 case 3:Lua("SelfEquip_Env","CloseWindow('SelfEquip',true)");Lua("Operation_Env","Operation_GmTool_Clicked()");Go(4);break;
 case 4:Check(CysBagProbe::Shown("GmTool"),"GM console server-authorized");Click("GmTool_TabPet",5);break;
 case 5:if(GetTickCount()-s.at<2500)break;{auto p=(CObject_Character*)CFakeObjSystem::GetMe()->FindFakeObject("Rabbit");Check(p&&p->GetRenderInterface(),"GM pet model from server");}s.shot="gm-pet-first";Click("GmTool_PetChoice2",6);break;
 case 6:if(GetTickCount()-s.at<2000)break;{auto p=(CObject_Character*)CFakeObjSystem::GetMe()->FindFakeObject("Rabbit");Check(p&&p->GetRenderInterface(),"GM second pet model");}s.shot="gm-pet-second";Lua("GmTool_Env","CysTestPetBefore=Pet:GetPet_Count()");Click("GmTool_PetConfirm",60);break;
 case 60:if(GetTickCount()-s.at<2000)break;Lua("GmTool_Env","assert(Pet:GetPet_Count()==CysTestPetBefore+1)");Click("GmTool_TabItem",7);break;
 case 7:Click("GmTool_ItemModeEquip",8);break;
 case 8:Lua("GmTool_Env","GmTool_ItemSearch:SetText('10156901')");Click("GmTool_ItemSearchButton",9);break;
 case 9:Lua("GmTool_Env","assert(string.find(GmTool_ItemMeta1:GetText(),'10156901',1,true));GmTool_SelectItem(1);assert(not string.find(GmTool_SelectedMeta:GetText(),'#R',1,true))");s.shot="gm-wuhun-search";s.index=CysBagProbe::Quantity(10156901);Click("GmTool_ItemGrant",10);break;
 case 10:Check(CysBagProbe::Quantity(10156901)==s.index+1,"GM grants one support soul");Lua("GmTool_Env","GmTool_ItemSearch:SetText('10156902')");Click("GmTool_ItemSearchButton",11);break;
 case 11:Lua("GmTool_Env","assert(string.find(GmTool_ItemMeta1:GetText(),'10156902',1,true));GmTool_SelectItem(1);assert(not string.find(GmTool_SelectedMeta:GetText(),'#R',1,true))");s.shot="gm-chienhon-search";s.index=CysBagProbe::Quantity(10156902);Click("GmTool_ItemGrant",110);break;
 case 110:Check(CysBagProbe::Quantity(10156902)==s.index+1,"GM grants one assault soul");CysInventoryIntegrityProbe::Unique();Click("GmTool_Close",12);break;
 case 12:CEventSystem::GetMe()->PushEvent(GE_TOGLE_PET_PAGE,-1);Go(61);break;
 case 61:if(GetTickCount()-s.at<2000)break;Check(CysBagProbe::Shown("Pet"),"normal pet window opens");{auto p=(CObject_Character*)CFakeObjSystem::GetMe()->FindFakeObject("My_Pet");Check(p&&p->GetRenderInterface(),"normal pet window model");}s.shot="normal-pet-model";Go(62);break;
 case 62:Lua("Pet_Env","CloseWindow('Pet',true)");CEventSystem::GetMe()->PushEvent(GE_TOGGLE_YUANBAOSHOP);Go(13);break;
 case 13:Check(CysBagProbe::Shown("YuanbaoShop"),"Yuanbao shop open");s.shot="shop-populated-menus";Go(130);break;
 case 130:Lua("YuanbaoShop_Env","YuanbaoShop_UpdateList(5);assert(YuanbaoShop_Button01:GetProperty('Visible')=='True');assert(YuanbaoShop_Button02:GetProperty('Visible')=='False');assert(YuanbaoShop_Button03:GetProperty('Visible')=='True');assert(YuanbaoShop_Button06:GetProperty('Visible')=='False');assert(YuanbaoShop_Button07:GetProperty('Visible')=='False')");Go(131);break;
 case 131:s.shot="shop-empty-shelves-hidden";Lua("YuanbaoShop_Env","CloseWindow('YuanbaoShop',true)");CEventSystem::GetMe()->PushEvent(GE_OPEN_EQUIP,"1");Go(14);break;
 case 14:Click("SelfEquip_Yirong_Icon",15);break;
 case 15:Check(CysBagProbe::Shown("NewExterior_DressBox"),"wardrobe open");Click("CysWard_Tab9",16);break;
 case 16:if(GetTickCount()-s.at<1500)break;Click("CysWard_Item1",17);break;
 case 17:if(GetTickCount()-s.at<2000)break;s.shot="wardrobe-mount-first";Click("CysWard_Item2",18);break;
 case 18:if(GetTickCount()-s.at<2000)break;s.shot="wardrobe-mount-second";Click("CysWard_Tab7",19);break;
 case 19:if(GetTickCount()-s.at<1200)break;Click("CysWard_Item1",20);break;
 case 20:if(GetTickCount()-s.at<3000)break;s.shot="wardrobe-weapon-after-mount";Click("CysWard_Tab1",21);break;
 case 21:Click("CysWard_Item2",22);break;
 case 22:if(GetTickCount()-s.at<2500)break;s.shot="wardrobe-costume-after-mount";Lua("NewExterior_DressBox_Env","assert(CysWard_HJPreview(9,2094,2087))");Go(70);break;
 case 70:if(GetTickCount()-s.at<4500)break;s.shot="wardrobe-hj-large-mount";Lua("NewExterior_DressBox_Env","assert(CysWard_HJPreview(9,2094,2087));assert(CysWard_HJPreview(9,2185,2227))");Go(71);break;
 case 71:if(GetTickCount()-s.at<4500)break;s.shot="wardrobe-hj-second-mount";Lua("NewExterior_DressBox_Env","assert(CysWard_HJPreview(7,1193,10101994))");Go(72);break;
 case 72:if(GetTickCount()-s.at<4500)break;s.shot="wardrobe-hj-weapon";Lua("NewExterior_DressBox_Env","assert(CysWard_HJPreview(1,10129226,20725))");Go(73);break;
 case 73:if(GetTickCount()-s.at<4500)break;s.shot="wardrobe-hj-costume";Click("NewExterior_DressBox_Close",23);break;
 case 23:s.x=self->GetPosition().x;s.z=self->GetPosition().z;CysAccel::SetChatting(false);Check(CysWorldReplay::LiveGroundClick(7),"movement input after repaired UI");Go(24);break;
 case 24:if(GetTickCount()-s.at<3500)break;Check(std::hypot(self->GetPosition().x-s.x,self->GetPosition().z-s.z)>.5f,"character moves after all UI");TDU_Log("CYS-RUNTIME-POLISH: RESULT mode=%d errors=0",s.mode);Go(99);return true;
 }
 return false;
}
inline bool Tick(){try{return TickImpl();}catch(const std::exception& e){TDU_Log("CYS-RUNTIME-POLISH: FAIL step=%d %s",S().step,e.what());CScriptSystem::GetMe()->EvaluateScript("MainMenuBar_Env","for _,n in ipairs({'GmTool','SelfEquip','Pet','YuanbaoShop','NewExterior_DressBox','OptionalGiftBox_Four','Packet'}) do CloseWindow(n,true) end");S().step=99;return true;}}
}
