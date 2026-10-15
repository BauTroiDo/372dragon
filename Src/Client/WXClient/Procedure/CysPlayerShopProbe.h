#pragma once
#include "CysQuickbarProbe.h"
#include "PgPackets_shop.h"
#include "../Network/CysPlayerShopNet.h"
namespace CysPlayerShopProbe {
struct State{int mode=-1,step=0,index=-1;DWORD at=0;float x=0,z=0;const char* shot=nullptr;};
inline State& S(){static State s;return s;}
inline void Check(bool ok,const char* why){if(!ok)throw std::runtime_error(why);TDU_Log("CYS-SHOP-PROBE: PASS %s",why);}
inline void Go(int n){S().step=n;S().at=GetTickCount();}
inline void Lua(const char* env,const char* code){auto r=CScriptSystem::GetMe()->EvaluateScript(env,code);Check(r.ok(),r.error);}
inline const char* ShotName(){auto p=S().shot;S().shot=nullptr;return p;}
inline int PetSlot(){for(int i=0;i<HUMAN_PET_MAX_COUNT;++i){auto p=CDataPool::GetMe()->Pet_GetPet(i);if(p&&p->m_GUID.m_uHighSection==200016&&p->m_GUID.m_uLowSection==22092851)return i;}return -1;}
inline void Deposit(){auto slot=PetSlot();Check(slot>=0,"owned fixture pet in bag");Check(CysBagProbe::Shown("PetList"),"compact pet selector available");Lua("PetList_Env",("PetList_List:SetItemSelectByItemID("+std::to_string(slot)+");PetList_Choose_Click()").c_str());}
inline bool TickImpl(){auto& s=S();if(s.mode<0){const char* e=getenv("CYS_PLAYER_SHOP_PROBE");s.mode=e?atoi(e):0;if(!s.mode)return true;
    Check(getenv("CYS_BOT_ACCOUNT")&&!strcmp(getenv("CYS_BOT_ACCOUNT"),s.mode==1?"test15":"test14"),"owned shop fixture account");
    auto mod=GetModuleHandleA("UI_CEGUI.dll");auto& b=CysBagProbe::S();b.pointer=(CysUiInputBridge::SmokePointer)GetProcAddress(mod,"CysUiSmokePointer");b.rect=(CysUiInputBridge::GetWindowRectUtf8)GetProcAddress(mod,"CysUiGetWindowRectUtf8");b.read=(CysUiInputBridge::ReadActionButtonUtf8)GetProcAddress(mod,"CysUiReadActionButtonUtf8");Go(0);}
    if(!s.mode||s.step==99)return true;if(GetTickCount()-s.at<1600)return false;
    auto pool=CDataPool::GetMe();auto self=CObjectManager::GetMe()->GetMySelf();
    switch(s.step){
    case 0:Lua("Pet_Env","this:Hide()");Lua("Packet_Env","this:Hide()");
        if(s.mode==3){Check(PetSlot()>=0,"purchased pet survives relogin");Go(90);break;}
        {std::unique_ptr<pg::CGPlayerShopAcquireShopList> p(new pg::CGPlayerShopAcquireShopList);Check(CysModernGame::SendModern(std::move(p)),"request real shop list");Go(1);}break;
    case 1:for(int i=0;i<pool->PlayerShop_GetShopNum();++i)if(!strcmp(pool->PlayerShop_GetShopNameByIndex(i),"CYSShop"))s.index=i;
        Check(s.index>=0,"fixture shop returned by server");Check(CysBagProbe::Shown("PS_ShopList"),"native shop list visible");
        Lua("PS_ShopList_Env","PS_ShopList_ChangeTabIndex(1)");Go(100);break;
    case 100:Lua("PS_ShopList_Env","assert(PS_ShopList_ShopList:GetItemCount()==1);PS_ShopList_ShopList:SetSelectItem(0);assert(PS_ShopList_ShopList:GetSelectItem()==0);PS_ShopList_SelectChanged()");Go(101);break;
    case 101:if(s.mode==1)Lua("PS_ShopList_Env","PS_ShopListAccept_Clicked('manage')");Go(2);break;
    case 2:
        if(s.mode==1){Check(CysBagProbe::Shown("PS_ShopMag"),"native shop manager visible");
            Check(!CysBagProbe::Shown("Pet")&&!CysBagProbe::Shown("Packet"),"pet manager is not covered by full pet and bag windows");
            if(PetSlot()<0){auto p=pool->PlayerShop_GetPet(true,0,0);Check(p&&p->m_GUID.m_uLowSection==22092851,"saved shop pet survives server restart");
                Lua("PS_ShopMag_Env","PlayerShop:SetCurSelectPetIndex('self',0,0)");
                if(pool->PlayerShop_GetItemOnSale(true,0,0)){Lua("PS_ShopMag_Env","PlayerShop:DownSale('pet')");Go(20);}
                else{Lua("PS_ShopMag_Env","PlayerShop:RetackItem('pet')");Go(21);}}
            else{Deposit();Go(3);}}
        else{Check(CysBagProbe::Shown("PS_ShopList"),"native shop buyer visible");auto p=pool->PlayerShop_GetPet(false,0,0);Check(p&&p->m_GUID.m_uLowSection==22092851,"buyer sees exact shop pet");
            Check(pool->PlayerShop_GetPetPrice(false,0,0)==500,"server price visible");Lua("PS_ShopList_Env","assert(PS_ShopList_Shop_PetList:IsVisible());PS_ShopList_Shop_PetList:SetItemSelectByItemID(0);PS_ShopList_Shop_PetList_Selected();PS_ShopList_Shop_PetList_RClick()");Go(8);}break;
    case 3:Check(PetSlot()<0,"deposit removes pet from bag");Check(pool->PlayerShop_GetPet(true,0,0)!=nullptr,"deposit appears in shop slot zero");
        Lua("PS_ShopMag_Env","PlayerShop:SetCurSelectPetIndex('self',0,0);PlayerShop:RetackItem('pet')");Go(4);break;
    case 4:Check(PetSlot()>=0,"withdraw returns same GUID");Check(pool->PlayerShop_GetPet(true,0,0)==nullptr,"withdraw empties shop slot");Deposit();Go(5);break;
    case 5:Check(PetSlot()<0,"second deposit acknowledged");Lua("PS_ShopMag_Env","PlayerShop:SetCurSelectPetIndex('self',0,0);PlayerShop:UpStall('pet',500)");Go(6);break;
    case 6:Check(pool->PlayerShop_GetItemOnSale(true,0,0)==1,"pet listed on server");Check(pool->PlayerShop_GetPetPrice(true,0,0)==500,"listing price acknowledged");
        Check(!CysBagProbe::Shown("Pet")&&!CysBagProbe::Shown("Packet"),"pet and bag windows remain closed after all shop operations");
        Lua("PS_ShopMag_Env","assert(PlayerShop:GetSelfPlace()=='boss');assert(PlayerShop:GetCurShopType('self')==6);PS_ShopMag_PetList:SetItemSelectByItemID(0);PS_ShopMag_PetList_Selected()");Go(61);break;
    case 61:Lua("PS_ShopMag_Env","assert(tonumber(PS_ShopMag_PriceTag:GetProperty('MoneyNumber'))==500)");s.shot="shop-pet-listed";Go(90);break;
    case 8:Check(CysBagProbe::Shown("TargetPet"),"shop pet detail window visible");s.shot="shop-pet-buyer";Go(7);break;
    case 7:Lua("TargetPet_Env","this:Hide()");
        Lua("PS_ShopList_Env","PS_ShopList_Buy_Clicked();PS_ShopList_Buy_Clicked()");Go(9);break;
    case 9:Check(PetSlot()>=0,"purchase returns exact GUID");Check(pool->PlayerShop_GetPet(false,0,0)==nullptr,"sold pet disappears from shop");s.shot="shop-pet-purchased";Go(90);break;
    case 20:Check(pool->PlayerShop_GetItemOnSale(true,0,0)==0,"persisted listing removed before withdrawal");Lua("PS_ShopMag_Env","PlayerShop:SetCurSelectPetIndex('self',0,0);PlayerShop:RetackItem('pet')");Go(21);break;
    case 21:Check(PetSlot()>=0,"saved shop pet withdrawn with original GUID");Deposit();Go(3);break;
    case 90:Lua("PS_ShopMag_Env","this:Hide()");Lua("PS_ShopList_Env","this:Hide()");Lua("PetList_Env","this:Hide()");
        s.x=self->GetPosition().x;s.z=self->GetPosition().z;Check(CysWorldReplay::LiveGroundClick(7),"move after shop UI");Go(91);break;
    case 91:if(GetTickCount()-s.at<3000)break;Check(std::hypot(self->GetPosition().x-s.x,self->GetPosition().z-s.z)>0.5f,"character moves after shop UI closes");TDU_Log("CYS-SHOP-PROBE: RESULT mode=%d errors=0",s.mode);s.step=99;return true;
    }
    return false;
}
inline bool Tick(){try{return TickImpl();}catch(const std::exception& e){TDU_Log("CYS-SHOP-PROBE: FAIL step=%d %s",S().step,e.what());S().step=99;return true;}}
}
