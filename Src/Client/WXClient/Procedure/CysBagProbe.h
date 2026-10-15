#pragma once
// Explicit owned live smoke. Reads the rendered widgets, never forces a bag refresh.
#include "CysUiInputBridge.h"
#include "../Event/CysBagEvents.h"
#include "../Event/GMEventSystem.h"
#include "../Action/GMActionSystem.h"
#include "../Network/CysInventoryNet.h"
#include "../Network/CysModernHandlers.h"
#include "../Network/CysWorldReplay.h"
#include "../DataPool/GMDataPool.h"
#include "../DataPool/GMUIDataPool.h"
#include "../Interface/GMGameInterface.h"
#include "../Network/CysModernGame.h"
#include "TDWorldSystem.h"
#include "../DataPool/GMDP_CharacterData.h"
#include "../Object/ObjectManager.h"
#include "../Object/Character/Obj_PlayerMySelf.h"
#include "../Object/Item/Obj_Item.h"
#include "../Script/GMScriptSystem.h"
#include "../Script/CysCheckedScriptLua.h"
#include "TDEventDefine.h"
#include "TDUtil.h"
#include <cmath>
#include <stdexcept>

namespace CysBagProbe
{
    struct State
    {
        bool checked = false, enabled = false, right = false;
        int step = 0, after = 0, errors = 0, slot = -1, goods = -1, item = 0;
        DWORD at = 0, down = 0;
        unsigned replies = 0;
        unsigned __int64 guid = 0;
        float x = 0, y = 0, fromX = 0, fromZ = 0;
        const char* shot = nullptr;
        CysUiInputBridge::SmokePointer pointer = nullptr;
        CysUiInputBridge::GetWindowRectUtf8 rect = nullptr;
        CysUiInputBridge::ReadActionButtonUtf8 read = nullptr;
    };
    inline State& S() { static State s; return s; }
    inline bool Env(const char* name) { char v[4] = {}; return GetEnvironmentVariableA(name, v, sizeof(v)) == 1 && v[0] == '1'; }
    inline void Require(bool ok, const char* why)
    {
        if (!ok) { TDU_Log("CYS-BAG-PROBE: INVALID %s step=%d", why, S().step); throw std::runtime_error(why); }
    }
    inline void Go(int step) { S().step = step; S().at = GetTickCount(); }
    inline bool Shown(const char* name) { return CGameProcedure::s_pUISystem->IsWindowShow(name) != FALSE; }
    inline void ButtonName(int index, char out[96]) { _snprintf(out, 96, "Packet_Space_Line%d_Row%d_button", index / 10 + 1, index % 10 + 1); }
    inline int Quantity(int id)
    {
        int count = 0;
        for (int i = 0; i < 100; ++i) { tObject_Item* item = CDataPool::GetMe()->UserBag_GetItem(i); if (item && item->GetIdTable() == id) count += item->GetNumber(); }
        return count;
    }
    inline void Click(const char* name, bool right, int after)
    {
        State& s = S(); float r[4] = {};
        Require(s.rect(name, r) == 1, "click target not visible");
        s.x = r[0] + r[2] / 2; s.y = r[1] + r[3] / 2;
        Require(s.pointer(0, s.x, s.y) == 1, "hover rejected");
        s.right = right; s.after = after;
        TDU_Log("CYS-BAG-PROBE: click target=%s right=%d xy=%.1f,%.1f", name, right, s.x, s.y);
        Go(90);
    }
    inline void Snapshot(const char* phase, int tab)
    {
        State& s = S(); Require(Shown("Packet"), "bag closed during snapshot");
        const int capacity = CysInventoryNet::BagSize(tab), offset = tab * 100;
        int mismatch = 0, occupied = 0, empty = 0, backgrounds = 0, visible = 0;
        for (int i = 0; i < capacity; ++i)
        {
            char name[96]; ButtonName(i, name); int ui[4] = {};
            const int shown = s.read(name, ui);
            tObject_Item* item = CDataPool::GetMe()->UserBag_GetItem(offset + i);
            tActionItem* action = item ? CActionSystem::GetMe()->EnumAction(offset + i, NAMETYPE_PACKAGEITEM) : nullptr;
            const int expected = action ? action->GetID() : -1;
            const int count = item ? item->GetNumber() : 0;
            const bool match = shown == 1 && ui[1] == (item ? 0 : 1) && (!item || (ui[0] == expected && ui[3] == (count > 1 ? count : 0)));
            if (!match) ++mismatch;
            if (item) ++occupied; else ++empty;
            if (shown) { ++visible; backgrounds += ui[2]; }
            if (item || !match) TDU_Log("CYS-BAG-PROBE: slot phase=%s tab=%d local=%d item=%u guid=%I64u count=%d action=%d ui=%d,%d,%d,%d visible=%d match=%d",
                phase, tab, i, item ? item->GetIdTable() : 0, item ? item->GetGUID() : 0, count, expected, ui[0], ui[1], ui[2], ui[3], shown, match);
        }
        s.errors += mismatch;
        TDU_Log("CYS-BAG-PROBE: SNAP phase=%s tab=%d capacity=%d visible=%d occupied=%d empty=%d backgrounds=%d mismatch=%d",
            phase, tab, capacity, visible, occupied, empty, backgrounds, mismatch);
        if (visible != capacity || backgrounds != capacity) ++s.errors;
        char code[320];
        const CCharacterData* data = CObjectManager::GetMe()->GetMySelf()->GetCharacterData();
        _snprintf(code, sizeof(code), "assert(tonumber(Packet_Money:GetProperty('MoneyNumber'))==%d); assert(tonumber(Packet_Jiaozi:GetProperty('MoneyNumber'))==%d)", data->Get_Money(), data->Get_MoneyJZ());
        const CysCheckedScriptLua::Result money = CScriptSystem::GetMe()->EvaluateScript("Packet_Env", code);
        TDU_Log("CYS-BAG-PROBE: money phase=%s match=%d gold=%d jiaozi=%d", phase, money.ok(), data->Get_Money(), data->Get_MoneyJZ());
        if (!money.ok()) ++s.errors;
        s.pointer(0, 1, 1);
    }
    inline bool Tick()
    {
        State& s = S();
        if (!s.checked)
        {
            s.checked = true; s.enabled = Env("CYS_BAG_LIVE");
            if (!s.enabled) return true;
            Require(Env("CYS_GL_LOGIN_SMOKE"), "owned smoke is required");
            HMODULE ui = GetModuleHandleA("UI_CEGUI.dll");
            s.pointer = reinterpret_cast<CysUiInputBridge::SmokePointer>(GetProcAddress(ui, "CysUiSmokePointer"));
            s.rect = reinterpret_cast<CysUiInputBridge::GetWindowRectUtf8>(GetProcAddress(ui, "CysUiGetWindowRectUtf8"));
            s.read = reinterpret_cast<CysUiInputBridge::ReadActionButtonUtf8>(GetProcAddress(ui, "CysUiReadActionButtonUtf8"));
            Require(s.pointer && s.rect && s.read, "UI bridge unavailable");
            TDU_Log("CYS-BAG-PROBE: BEGIN old_refresh=%d old_enum=%d", CysBagEvents::OldRefresh(), CysBagEvents::OldEnumeration());
            Go(Env("CYS_BAG_SHOP_LIVE") ? 30 : 1);
        }
        if (!s.enabled || s.step == 99) return true;
        const DWORD age = GetTickCount() - s.at;
        const CysInventoryNet::Counters c = CysInventoryNet::Get();
        switch (s.step)
        {
        case 1:
            if (!Shown("Packet")) CEventSystem::GetMe()->PushEvent(GE_TOGLE_CONTAINER);
            Go(2); break;
        case 2:
            if (age < 1500) break;
            Snapshot("open", 0); s.shot = "bag-open"; Click("Packet_Stall", false, 3); break;
        case 3:
            if (age < 1000) break;
            Snapshot("material", 1); s.shot = "bag-material"; Click("Packet_Mission", false, 4); break;
        case 4:
            if (age < 1000) break;
            Snapshot("quest", 2); s.shot = "bag-quest"; Click("Packet_Material", false, 5); break;
        case 5:
            if (age < 1000) break;
            Snapshot("base", 0);
            {
                tObject_Item* worn = CDataPool::GetMe()->UserEquip_GetItem(HEQUIP_WEAPON);
                Require(worn != nullptr, "test account needs a worn weapon"); s.guid = worn->GetGUID();
                TDU_Log("CYS-BAG-PROBE: original weapon guid=%I64u item=%u", s.guid, worn->GetIdTable());
            }
            CEventSystem::GetMe()->PushEvent(GE_ACCELERATE_KEYSEND, "acc_selfequip"); Go(6); break;
        case 6:
            if (age < 2000) break;
            s.replies = c.unEquip; Click("SelfEquip_11", true, 7); break;
        case 7:
            if (age < 1800) break;
            Require(c.unEquip == s.replies + 1, "unequip server reply absent");
            Require(!CDataPool::GetMe()->UserEquip_GetItem(HEQUIP_WEAPON), "weapon remains worn");
            for (int i = 0; i < 100; ++i) { tObject_Item* item = CDataPool::GetMe()->UserBag_GetItem(i); if (item && item->GetGUID() == s.guid) s.slot = i; }
            Require(s.slot >= 0, "unequipped GUID missing in bag");
            Snapshot("unequipped", 0); s.shot = "bag-unequipped";
            CEventSystem::GetMe()->PushEvent(GE_ACCELERATE_KEYSEND, "acc_selfequip"); Go(8); break;
        case 8:
            if (age < 1000) break;
            s.replies = c.useEquip;
            if (CysBagEvents::OldRefresh())
            {
                // Negative arm already measured the stale widget. Restore the original
                // test weapon via its action, explicitly NOT a successful UI click.
                tActionItem* action = CActionSystem::GetMe()->EnumAction(s.slot, NAMETYPE_PACKAGEITEM);
                Require(action != nullptr, "cleanup action absent"); action->DoAction();
                TDU_Log("CYS-BAG-PROBE: negative-arm cleanup via action (not UI evidence)"); Go(9);
            }
            else { char name[96]; ButtonName(s.slot, name); Click(name, true, 9); }
            break;
        case 9:
            if (age < 1800) break;
            Require(c.useEquip == s.replies + 1, "equip server reply absent");
            {
                tObject_Item* worn = CDataPool::GetMe()->UserEquip_GetItem(HEQUIP_WEAPON);
                Require(worn && worn->GetGUID() == s.guid, "original weapon not restored");
            }
            Snapshot("equipped", 0); s.shot = "bag-equipped";
            CEventSystem::GetMe()->PushEvent(GE_TOGLE_CONTAINER); Go(10); break;
        case 10:
            if (age < 1000) break;
            Require(!Shown("Packet"), "bag did not close");
            CEventSystem::GetMe()->PushEvent(GE_TOGLE_CONTAINER); Go(11); break;
        case 11:
            if (age < 1200) break;
            Snapshot("reopened", 0); s.shot = "bag-reopened";
            CEventSystem::GetMe()->PushEvent(GE_TOGLE_CONTAINER); Go(12); break;
        case 12:
            if (age < 1000) break;
            Require(!Shown("Packet") && !Shown("SelfEquip"), "frames remained open");
            s.fromX = CObjectManager::GetMe()->GetMySelf()->GetPosition().x;
            s.fromZ = CObjectManager::GetMe()->GetMySelf()->GetPosition().z;
            Require(CysWorldReplay::LiveGroundClick(4), "post-close move rejected"); Go(13); break;
        case 13:
            if (age < 3000) break;
            {
                const float dx = CObjectManager::GetMe()->GetMySelf()->GetPosition().x - s.fromX;
                const float dz = CObjectManager::GetMe()->GetMySelf()->GetPosition().z - s.fromZ;
                const float moved = std::sqrt(dx * dx + dz * dz);
                Require(moved >= 0.5f, "no post-close movement");
                TDU_Log("CYS-BAG-PROBE: RESULT errors=%d restored_guid=%I64u post_move_m=%.3f", s.errors, s.guid, moved);
                s.shot = "bag-postclose-move"; Go(98);
            }
            break;
        case 90:
            if (age < 300) break;
            Require(s.pointer(s.right ? 3 : 1, s.x, s.y) == 1, "mouse down rejected"); s.down = GetTickCount(); Go(91); break;
        case 91:
            Require(s.pointer(s.right ? 4 : 2, s.x, s.y) == 1, "mouse up rejected");
            Require(GetTickCount() - s.down <= 190, "held click exceeds CEGUI timeout"); Go(s.after); break;
        case 30:
            // Walk through the real Wuliang -> Dali transfer area (wuliang_area.ini area2).
            // No database teleport and no server mutation by the harness.
            if (CGameProcedure::s_pWorldManager->GetActiveSceneID() == 2) { Go(32); break; }
            Require(CGameProcedure::s_pWorldManager->GetActiveSceneID() == 6, "shop route requires Wuliang or Dali");
            CGameProcedure::s_pGameInterface->Player_MoveTo(fVector2(32, 176)); Go(31); break;
        case 31:
            if (CGameProcedure::s_pWorldManager->GetActiveSceneID() == 2 && CysModernGame::IsInWorld()) { Go(32); break; }
            Require(age < 60000, "Wuliang portal walk timed out"); break;
        case 32:
            if (age < 3000) break;
            CGameProcedure::s_pGameInterface->Player_MoveTo(fVector2(271, 135)); Go(33); break;
        case 33:
        {
            const fVector3 p = CObjectManager::GetMe()->GetMySelf()->GetPosition();
            if ((p.x - 271) * (p.x - 271) + (p.z - 133) * (p.z - 133) > 36)
            { Require(age < 45000, "shop NPC walk timed out"); break; }
            float distance = 0;
            const unsigned id = CysModernGame::NearestObjectAt(271, 133, 3, &distance);
            Require(id != 0, "Yunpiaopiao NPC not loaded");
            tObject* npc = CObjectManager::GetMe()->FindServerObject(id);
            Require(npc != nullptr, "NPC object missing");
            s.replies = c.eventLists;
            // MCT_SPEAK carries the server object ID (CursorMng.cpp), not GetID().
            TDU_Log("CYS-BAG-PROBE: shop NPC server=%u client=%u distance=%.2f", id, npc->GetID(), distance);
            CGameProcedure::s_pGameInterface->Player_Speak(id); Go(34); break;
        }
        case 34:
            if (c.eventLists <= s.replies) { Require(age < 10000, "NPC menu absent"); break; }
            {
                int script = 0, index = 0;
                Require(CysInventoryNet::LastShopOption(script, index) && script == 2051, "wrong NPC menu");
                s.replies = c.shopLists; CUIDataPool::GetMe()->SendSelectEvent(0, script, index); Go(35);
            }
            break;
        case 35:
            if (c.shopLists <= s.replies || age < 2000) { Require(age < 10000, "NPC shop absent"); break; }
            Require(Shown("Shop") && Shown("Packet"), "shop/bag must both be visible");
            for (int i = 0; i < CDataPool::GetMe()->Booth_GetNumber() && i < 12; ++i)
            {
                tObject_Item* item = CDataPool::GetMe()->Booth_GetItem(i);
                if (item && !Quantity(item->GetIdTable()) && CDataPool::GetMe()->Booth_GetItemPrice(i) > 0 && CDataPool::GetMe()->Booth_GetItemPrice(i) <= 1000)
                { s.goods = i; s.item = item->GetIdTable(); break; }
            }
            Require(s.goods >= 0, "no new cheap shop item in first page");
            Snapshot("shop-before", 0); s.shot = "bag-shop-before";
            s.replies = c.shopBuys;
            { char name[64]; _snprintf(name, sizeof(name), "Shop_Item%d", s.goods + 1); Click(name, false, 36); }
            break;
        case 36:
            if (age < 2000) break;
            Require(c.shopBuys == s.replies + 1 && Quantity(s.item) == 1, "new-slot buy did not succeed");
            Snapshot("bought-new", 0); s.shot = "bag-bought-new";
            TDU_Log("CYS-BAG-PROBE: bought item=%d quantity=1 replies=1", s.item);
            s.replies = c.shopBuys;
            { char name[64]; _snprintf(name, sizeof(name), "Shop_Item%d", s.goods + 1); Click(name, false, 37); }
            break;
        case 37:
            if (age < 2000) break;
            Require(c.shopBuys == s.replies + 1 && Quantity(s.item) == 2, "stack buy did not succeed");
            Snapshot("bought-stack", 0); s.shot = "bag-bought-stack";
            s.slot = -1;
            for (int i = 0; i < 100; ++i) { tObject_Item* item = CDataPool::GetMe()->UserBag_GetItem(i); if (item && item->GetIdTable() == s.item && item->GetNumber() == 2) s.slot = i; }
            Require(s.slot >= 0, "purchase did not form one two-item stack");
            s.replies = c.shopSells;
            if (CysBagEvents::OldRefresh())
            {
                // Cleanup only the two items this run bought; the negative UI observation
                // has already happened. Never sell any pre-existing test account item.
                CGameProcedure::s_pGameInterface->Booth_SellItem(CDataPool::GetMe()->UserBag_GetItem(s.slot));
                TDU_Log("CYS-BAG-PROBE: negative-arm sell cleanup via host (not UI evidence)"); Go(38);
            }
            else { char name[96]; ButtonName(s.slot, name); Click(name, true, 38); }
            break;
        case 38:
            if (age < 2000) break;
            Require(c.shopSells == s.replies + 1 && Quantity(s.item) == 0, "sale did not remove purchased stack");
            Snapshot("sold", 0); s.shot = "bag-sold";
            TDU_Log("CYS-BAG-PROBE: sold item=%d quantity=0 replies=1", s.item);
            CEventSystem::GetMe()->PushEvent(GE_CLOSE_BOOTH); Go(39); break;
        case 39:
            if (age < 1000) break;
            Require(!Shown("Shop"), "shop did not close");
            if (Shown("Packet")) CEventSystem::GetMe()->PushEvent(GE_TOGLE_CONTAINER);
            Go(12); break;
        case 98: Go(99); break;
        }
        return s.step == 99;
    }
    inline const char* ShotName() { const char* name = S().shot; S().shot = nullptr; return name; }
}
