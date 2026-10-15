// CYS-NBSHOP 20/09: see CysHost_NbShop.h.
#include <winsock2.h> // NetManager must see winsock2 before Windows headers reached through LuaPlus.
#include "CysHost_NbShop.h"
#include "LuaApiGen.h"
#include "Event/GMEventSystem.h"
#include "Script/GMScriptSystem.h"
#include "TDEventDefine.h"
#include "TDUtil.h"
#include "DataPool/GMDataPool.h"
#include "Interface/GMGameInterface_Script.h"
#include "Network/NetManager.h"
#include "CGShopBuy.h"
#include <cstring>
#include <cstdio>
#include <vector>

namespace CysHostNbShop
{
    namespace
    {
        bool g_buyDirectly = false;
        int GetBuyDirectly(LuaPlus::LuaState* state) { state->PushInteger(g_buyDirectly ? 1 : 0); return 1; }
        int SetBuyDirectly(LuaPlus::LuaState* state)
        {
            LuaPlus::LuaStack args(state);
            g_buyDirectly = args[2].IsNumber() && args[2].GetNumber() != 0;
            return 0;
        }
        int CloseConfirm(LuaPlus::LuaState*)
        {
            CEventSystem::GetMe()->PushEvent(GE_YUANBAO_BUY_ITEM_CONFIRM, "close");
            return 0;
        }
        bool SendBuy(int index, int count)
        {
            CDataPool* pool = CDataPool::GetMe();
            if (!pool || pool->Booth_IsClose() || index < 0 || index >= pool->Booth_GetNumber() ||
                index > 254 || count < 1) return false;
            tObject_Item* item = pool->Booth_GetItem(index);
            if (!item || count > (item->GetMaxOverLay() > 0 ? item->GetMaxOverLay() : 1)) return false;
            Packets::CGShopBuy msg;
            msg.SetIndex((BYTE)index);
            msg.SetUniqueID(pool->Booth_GetShopUniqueId());
            msg.SetSerialNum(pool->Booth_GetSerialNum());
            msg.SetBuyNum((UINT)count);
            CNetManager::GetMe()->SendPacket(&msg);
            TDU_Log("CYS-NBSHOP: buy index=%d count=%d item=%u currency=%d price=%d", index, count,
                    item->GetIdTable(), pool->Booth_GetCurrencyUnit(), pool->Booth_GetItemPrice(index));
            return true;
        }
        int BulkBuyItem(LuaPlus::LuaState* state)
        {
            LuaPlus::LuaStack args(state);
            if (!args[2].IsNumber() || !args[3].IsNumber()) return 0;
            // The GL server has no CY recent-purchase list; do not reinterpret that index as a shelf index.
            if (args[4].IsNumber() && args[4].GetInteger() != 0) return 0;
            SendBuy(args[2].GetInteger(), args[3].GetInteger());
            return 0;
        }
        struct Switch
        {
            bool read;
            char text[16];
        };
        Switch& Sw()
        {
            static Switch s = { false, {0} };
            if (!s.read)
            {
                s.read = true;
                const DWORD n = ::GetEnvironmentVariableA("CYS_NBSHOP_OFF", s.text, sizeof(s.text));
                if (n == 0 || n >= sizeof(s.text)) s.text[0] = '\0';
            }
            return s;
        }

        int GlobalToggleYuanbaoShop(LuaPlus::LuaState*)
        {
            ToggleYuanbaoShop();
            return 0;   // both live binaries return 0 values
        }
    }

    const char* OffText() { return Sw().text; }

    bool Off(char link)
    {
        const char* t = Sw().text;
        if (!t[0]) return false;
        if (t[0] == '1' && !t[1]) return true;
        return std::strchr(t, link) != NULL;
    }

    bool ToggleYuanbaoShop()
    {
        CEventSystem* events = CEventSystem::GetMe();
        if (!events) return false;
        // CY pushes ONE string argument, "normal" (.rdata 0x140b217b4); client_GL pushes none. The frame of this
        // tree is the CY frame and YuanbaoShop.lua:819 reads arg0 == "normal" to reopen the LAST tab. Pushing
        // nothing would still open (the else branch), which is why only the CY form is correct here.
        events->PushEvent(GE_TOGGLE_YUANBAOSHOP, "normal");
        TDU_Log("CYS-NBSHOP: ToggleYuanbaoShop -> TOGGLE_YUANBAOSHOP(normal)");   // one line per click: rare event
        return true;
    }

    bool BuyItemOrConfirm(tObject_Item* item)
    {
        CDataPool* pool = CDataPool::GetMe();
        if (!pool || !item || Off('c')) return false;
        const int currency = pool->Booth_GetCurrencyUnit();
        if (currency != 5 && currency != 9) return false;
        if (g_buyDirectly) { SendBuy(item->GetPosIndex(), 1); return true; }
        // CY MessageBox_Self.lua consumes seven arguments, then BulkBuyItem(slot,1,recent).
        char index[24] = {}, price[24] = {};
        std::sprintf(index, "%d", item->GetPosIndex());
        std::sprintf(price, "%u", (unsigned)pool->Booth_GetItemPrice(item->GetPosIndex()));
        std::vector<STRING> args;
        args.push_back("open"); args.push_back(item->GetName()); args.push_back(index); args.push_back(price);
        args.push_back("0"); args.push_back(currency == 9 ? "bind" : ""); args.push_back("1");
        CEventSystem::GetMe()->PushEvent(GE_YUANBAO_BUY_ITEM_CONFIRM, args);
        TDU_Log("CYS-NBSHOP: confirm index=%s item=%u price=%s currency=%d", index, item->GetIdTable(), price, currency);
        return true;
    }

    void RegisterHost()
    {
        CScriptSystem* scripts = CScriptSystem::GetMe();
        if (!scripts || !scripts->GetLuaState()) return;
        int registered = 0;
        if (!Off('d'))
        {
            LuaPlus::LuaObject globals = scripts->GetLuaState()->GetGlobals();
            globals.Register("ToggleYuanbaoShop", GlobalToggleYuanbaoShop);   // forced: the generated stub owns the slot
            registered = 1;
        }
        if (!Off('c') && SCRIPT_SANDBOX::NpcShop::s_pMetaTable && SCRIPT_SANDBOX::NpcShop::s_pMetaTable->IsTable())
        {
            LuaPlus::LuaObject& shop = *SCRIPT_SANDBOX::NpcShop::s_pMetaTable;
            shop.Register("BulkBuyItem", BulkBuyItem);
            shop.Register("GetBuyDirectly", GetBuyDirectly);
            shop.Register("SetBuyDirectly", SetBuyDirectly);
            shop.Register("CloseConfirm", CloseConfirm);
        }
        TDU_Log("CYS-NBSHOP: host registered=%d off=[%s] door=%d xscript=%d open_event=%d", registered, OffText(),
                Off('d') ? 0 : 1, Off('x') ? 0 : 1, Off('o') ? 0 : 1);
    }
}
