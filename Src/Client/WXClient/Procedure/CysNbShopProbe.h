#pragma once
// Opt-in real-door evidence: minimap/button mouse input -> Lua -> packets -> shop/confirm/bag/balance.
// CYS_NBSHOP_LIVE=1. A/B differs only by CYS_NBSHOP_OFF=1; no direct action or packet is used here.
#include "CysUiInputBridge.h"
#include "CysHost_NbShop.h"
#include "GameProcedure.h"
#include "../Network/CysInventoryNet.h"
#include "../Network/CysModernGame.h"
#include "../Network/CysWorldReplay.h"
#include "../Object/ObjectManager.h"
#include "../Object/Character/Obj_PlayerMySelf.h"
#include "../Object/Item/Obj_Item.h"
#include "../DataPool/GMDataPool.h"
#include "../DataPool/GMDP_CharacterData.h"
#include "TDUISystem.h"
#include "TDUtil.h"
#include <cstring>
#include <cstdio>

namespace CysNbShopProbe
{
    struct State
    {
        bool checked = false, enabled = false, cleanupCancel = false, cleanupClose = false;
        int step = 0, next = 0, item = 0, qty = 0, price = 0, balance = 0, slot = 0;
        unsigned buys = 0, lists = 0;
        DWORD at = 0, downAt = 0;
        float x = 0, y = 0;
        char target[96] = {};
        CysUiInputBridge::SmokePointer pointer = nullptr;
        CysUiInputBridge::GetWindowRectUtf8 rect = nullptr;
        CysUiInputBridge::GetDisplaySize display = nullptr;
        CysUiInputBridge::CopyWindowTextUtf8 text = nullptr;
    };
    inline State& S() { static State s; return s; }
    inline bool Shown(const char* name) { return CGameProcedure::s_pUISystem->IsWindowShow(name); }
    inline void Go(int step) { S().step = step; S().at = GetTickCount(); }
    inline bool Fail(const char* why) { TDU_Log("CYS-NBSHOP-LIVE: PRECONDITION %s step=%d", why, S().step); Go(97); return false; }
    inline int Balance() { return CObjectManager::GetMe()->GetMySelf()->GetCharacterData()->Get_RMB(); }
    inline int Quantity(int id)
    {
        int n = 0;
        for (int i = 0; i < CYS_CLIENT_BAG_SLOTS; ++i)
        {
            tObject_Item* item = CDataPool::GetMe()->UserBag_GetItem(i);
            if (item && (int)item->GetIdTable() == id) n += item->GetNumber();
        }
        return n;
    }
    inline bool Click(const char* name, int after)
    {
        State& s = S(); float r[4] = {}, d[2] = {};
        if (s.rect(name,r) != 1 || s.display(d) != 1 || r[2] <= 0 || r[3] <= 0) { Fail("target rect missing"); return false; }
        s.x = r[0]+r[2]*0.5f; s.y = r[1]+r[3]*0.5f;
        if (s.x < 0 || s.y < 0 || s.x >= d[0] || s.y >= d[1]) { Fail("target off-screen"); return false; }
        s.pointer(0,s.x,s.y);
        std::snprintf(s.target,sizeof(s.target),"%s",name);
        TDU_Log("CYS-NBSHOP-LIVE: HOVER window=%s settle_ms=250",name);
        s.next = after; Go(89); return true;
    }
    inline void Text(const char* name, const char* phase)
    {
        char text[2048] = {};
        const int bytes = S().text(name,text,sizeof(text));
        TDU_Log("CYS-NBSHOP-LIVE: text phase=%s window=%s bytes=%d text=%s",phase,name,bytes,text);
    }
    inline bool Tick()
    {
        State& s=S();
        if (!s.checked)
        {
            s.checked=true; char value[8]={};
            s.enabled=GetEnvironmentVariableA("CYS_NBSHOP_LIVE",value,sizeof(value))==1 && value[0]=='1';
            if (!s.enabled) return true;
            const DWORD slotLength=GetEnvironmentVariableA("CYS_NBSHOP_SLOT",value,sizeof(value));
            if(slotLength && (slotLength!=1 || (value[0]!='0' && value[0]!='1'))) return Fail("unsupported target slot");
            s.slot=slotLength && value[0]=='1' ? 1 : 0; // Slot1 is a separate new-slot regression, never the core A/B.
            HMODULE ui=GetModuleHandleA("UI_CEGUI.dll");
            s.pointer=(CysUiInputBridge::SmokePointer)GetProcAddress(ui,"CysUiSmokePointer");
            s.rect=(CysUiInputBridge::GetWindowRectUtf8)GetProcAddress(ui,"CysUiGetWindowRectUtf8");
            s.display=(CysUiInputBridge::GetDisplaySize)GetProcAddress(ui,"CysUiGetDisplaySize");
            // Both Text2 and CurrentlyPage map to Falagard/SimpleText in WoWLookSkin.scheme.xml.
            s.text=(CysUiInputBridge::CopyWindowTextUtf8)GetProcAddress(ui,"CysUiCopySimpleTextUtf8");
            TDU_Log("CYS-NBSHOP-LIVE: enabled off=[%s] exports=%d%d%d%d slot=%d",CysHostNbShop::OffText(),!!s.pointer,!!s.rect,!!s.display,!!s.text,s.slot);
            if (!s.pointer || !s.rect || !s.display || !s.text) return Fail("UI exports missing");
            Go(1);
        }
        if (!s.enabled || s.step==99) return true;
        if (!CysModernGame::IsInWorld()) { Fail("left world"); Go(99); return true; }
        const DWORD age=GetTickCount()-s.at;
        const CysInventoryNet::Counters counters=CysInventoryNet::Get();
        CDataPool* pool=CDataPool::GetMe();
        switch(s.step)
        {
        case 1:
            if(age<3000) break;
            if(Shown("YuanbaoShop")) return Fail("shop was already open");
            s.lists=counters.shopLists; s.buys=counters.shopBuys;
            Click("MiniMap_Yuanbao",2); break;
        case 2:
            if(age<6000) break;
            TDU_Log("CYS-NBSHOP-LIVE: OPEN shown=%d list_delta=%u goods=%d",Shown("YuanbaoShop"),counters.shopLists-s.lists,pool->Booth_GetNumber());
            CysWorldReplay::LiveShot("nbshop-1-open");
            if(CysHostNbShop::Off('d') || CysHostNbShop::Off('x') || CysHostNbShop::Off('o')) { Go(99); break; }
            if(!Shown("YuanbaoShop") || counters.shopLists<=s.lists || pool->Booth_GetNumber()<=0) return Fail("shop did not open with goods");
            if(pool->Booth_GetCurrencyUnit()!=5 || !pool->Booth_GetItem(s.slot)) return Fail("unexpected default shop");
            s.item=(int)pool->Booth_GetItem(s.slot)->GetIdTable(); s.price=(int)pool->Booth_GetItemPrice(s.slot);
            s.balance=Balance(); s.qty=Quantity(s.item);
            TDU_Log("CYS-NBSHOP-LIVE: BEFORE item=%d price=%d balance=%d quantity=%d",s.item,s.price,s.balance,s.qty);
            TDU_Log("CYS-NBSHOP-LIVE: TARGET slot=%d item=%d price=%d quantity=%d",s.slot,s.item,s.price,s.qty);
            if(s.slot==1 && s.qty!=0) return Fail("new-slot target already exists in bag");
            if(s.price<=0 || s.balance<s.price) return Fail("test account lacks price balance");
            Text("YuanbaoShop_Text2","before");
            Click(s.slot==1 ? "YuanbaoShop_Item2" : "YuanbaoShop_Item1",3); break;
        case 3:
            if(age<1500) break;
            TDU_Log("CYS-NBSHOP-LIVE: CONFIRM shown=%d buy_delta=%u",Shown("MessageBox_Self"),counters.shopBuys-s.buys);
            if(!Shown("MessageBox_Self") || counters.shopBuys!=s.buys) return Fail("confirmation absent or purchase happened before OK");
            CysWorldReplay::LiveShot("nbshop-2-confirm");
            Click("MessageBox_Self_Cancel_Button",4); break;
        case 4:
            if(age<1500) break;
            TDU_Log("CYS-NBSHOP-LIVE: CANCEL shown=%d buy_delta=%u balance=%d quantity=%d",Shown("MessageBox_Self"),counters.shopBuys-s.buys,Balance(),Quantity(s.item));
            if(Shown("MessageBox_Self") || counters.shopBuys!=s.buys || Balance()!=s.balance || Quantity(s.item)!=s.qty) return Fail("cancel changed account");
            Click(s.slot==1 ? "YuanbaoShop_Item2" : "YuanbaoShop_Item1",5); break;
        case 5:
            if(age<1200) break;
            if(!Shown("MessageBox_Self")) return Fail("second confirmation absent");
            Click("MessageBox_Self_OK_Button",6); break;
        case 6:
            if(age<6000) break;
            TDU_Log("CYS-NBSHOP-LIVE: BUY replies=%u item=%d price=%d balance_before=%d balance_after=%d quantity_before=%d quantity_after=%d",
                counters.shopBuys-s.buys,s.item,s.price,s.balance,Balance(),s.qty,Quantity(s.item));
            Text("YuanbaoShop_Text2","after"); CysWorldReplay::LiveShot("nbshop-3-bought");
            if(counters.shopBuys!=s.buys+1 || Balance()!=s.balance-s.price || Quantity(s.item)!=s.qty+1) return Fail("purchase/bag/balance mismatch");
            Click("YuanbaoShop_DownPage",7); break;
        case 7:
            if(age<1200) break;
            Text("YuanbaoShop_CurrentlyPage","page2"); CysWorldReplay::LiveShot("nbshop-4-page2");
            Click("YuanbaoShop_Button5",8); break;
        case 8:
            if(age<2000) break;
            TDU_Log("CYS-NBSHOP-LIVE: TAB5 goods=%d first=%d",pool->Booth_GetNumber(),pool->Booth_GetItem(0)?pool->Booth_GetItem(0)->GetIdTable():0);
            s.item=pool->Booth_GetItem(0)?(int)pool->Booth_GetItem(0)->GetIdTable():0;
            Click("MiniMap_Yuanbao",9); break;
        case 9:
            if(age<1500) break;
            if(Shown("YuanbaoShop")) return Fail("toggle did not close shop");
            Click("MiniMap_Yuanbao",10); break;
        case 10:
            if(age<2500) break;
            TDU_Log("CYS-NBSHOP-LIVE: REOPEN shown=%d remembered=%d first=%d",Shown("YuanbaoShop"),s.item,
                pool->Booth_GetItem(0)?pool->Booth_GetItem(0)->GetIdTable():0);
            if(!Shown("YuanbaoShop") || !pool->Booth_GetItem(0) || (int)pool->Booth_GetItem(0)->GetIdTable()!=s.item) return Fail("reopen did not remember tab");
            CysWorldReplay::LiveShot("nbshop-5-reopen");
            if(getenv("CYS_NBSHOP_EMPTY_LIVE")) Click("YuanbaoShop_Button06",11); else Go(97);
            break;
        case 11:
            if(age<2500)break;
            if(pool->Booth_GetNumber()!=0) return Fail("wardrobe mount shelf retained goods");
            {float r[4]={};if(s.rect("CysNbShop_Empty",r)!=1)return Fail("empty shelf notice hidden");}
            Text("YuanbaoShop_CurrentlyPage","empty");CysWorldReplay::LiveShot("nbshop-empty-wardrobe");
            TDU_Log("CYS-NBSHOP-LIVE: PASS wardrobe mount shelf empty with visible notice");Go(97);break;
        case 89:
        {
            if(age<250) break;
            // The queued tooltip Show/activate must finish before the measured mouse-down begins.
            const int accepted=s.pointer(1,s.x,s.y);
            TDU_Log("CYS-NBSHOP-LIVE: DOWN window=%s accepted=%d xy=%.1f,%.1f",s.target,accepted,s.x,s.y);
            if(accepted!=1) return Fail("mouse down refused");
            s.downAt=GetTickCount(); Go(90); break;
        }
        case 90:
        {
            const int accepted=s.pointer(2,s.x,s.y); const DWORD held=GetTickCount()-s.downAt;
            TDU_Log("CYS-NBSHOP-LIVE: UP accepted=%d held_ms=%lu",accepted,(unsigned long)held);
            if(accepted!=1 || held>190) return Fail("mouse click invalid (>190ms or refused)");
            Go(s.next); break;
        }
        case 97:
            // Close via the same UI door before the outer smoke opens the system menu. Keep the failure log.
            if(age<1500) break;
            if(!s.pointer || !s.rect || !s.display) { Go(99); break; }
            if(Shown("MessageBox_Self") && !s.cleanupCancel)
            { s.cleanupCancel=true; Click("MessageBox_Self_Cancel_Button",97); break; }
            if(Shown("YuanbaoShop") && !s.cleanupClose)
            { s.cleanupClose=true; Click("MiniMap_Yuanbao",98); break; }
            Go(98); break;
        case 98:
            if(age<1500) break;
            TDU_Log("CYS-NBSHOP-LIVE: CLEANUP shop=%d confirm=%d",Shown("YuanbaoShop"),Shown("MessageBox_Self"));
            if(Shown("YuanbaoShop") || Shown("MessageBox_Self"))
                TDU_Log("CYS-NBSHOP-LIVE: PRECONDITION cleanup did not close shop/confirm");
            Go(99); break;
        }
        return s.step==99;
    }
}
