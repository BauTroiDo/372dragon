#include "StdAfx.h"
#include "CysInventoryDriver.h"

#if defined(CYS_HAVE_NETCORE)
#include "CysInventoryNet.h"
#include "CysModernGame.h"
#include "CysWorldReplay.h"
#include "TDEventDefine.h"
#include "TDUtil.h"
#include "TDUISystem.h"
#include "..\Procedure\GameProcedure.h"
#include "..\Input\GMInputSystem.h"
#include "..\Object\ObjectManager.h"
#include "..\Object\Character\Obj_PlayerMySelf.h"
#include "..\Object\Item\Obj_Item.h"
#include "..\DataPool\GMDataPool.h"
#include "..\DataPool\GMUIDataPool.h"
#include "..\DataPool\GMDP_CharacterData.h"
#include "..\Action\GMActionSystem.h"
#include "..\Event\GMEventSystem.h"
#include "..\Interface\GMGameInterface.h"
#include "NetManager.h"
#include "CGCharDefaultEvent.h"
#include <cstdarg>
#include <cstdlib>

namespace
{
    enum Step { Off, Begin, BagOpen, Tooltip, EquipOpen, Equip, EquipWait, Unequip, UnequipWait, Reequip, ReequipWait,
                Talk, MenuWait, ShopWait, Buy, BuyWait, Close, Done };
    struct State
    {
        bool evaluated = false;
        Step step = Off;
        DWORD at = 0;
        int equipBag = -1, equipPoint = -1, weaponBefore = -1;
        bool unequipFirst = false, equippedOnce = false;
        unsigned base = 0;
        // odali_yunpiaopiao (script 2051, ShopTable 27, currency 8 = jiaozi then gold) in dali_new_320_monster.ini; the
        // gold-only shop 1 (odali_puliang 219,123) cannot sell to CYTest00 (gold 0, jiaozi 28.8 M on 15/09).
        float npcX = 271.0f, npcZ = 133.0f;
        unsigned buyItem = 30602001;          // first goods of shop 27 (price 100)
    };
    State& S() { static State s; return s; }

    void Log(const char* fmt, ...)
    {
        char text[512] = {};
        va_list args; va_start(args, fmt);
        _vsnprintf(text, sizeof(text) - 1, fmt, args);
        va_end(args);
        TDU_Log("CYS inv-live: %s", text);
    }

    void Go(Step next, const char* why)
    {
        S().step = next; S().at = GetTickCount();
        Log("step %d: %s", (int)next, why);
    }

    DWORD Age() { return GetTickCount() - S().at; }

    bool Shown(const char* window)
    {
        return CGameProcedure::s_pUISystem && CGameProcedure::s_pUISystem->IsWindowShow(window);
    }

    void Shot(const char* label) { CysWorldReplay::LiveShot(label); }

    // First bag slot (0..219) holding equipment: the action item and its point.
    tActionItem* FindBagEquipment(int& slot)
    {
        for (int i = 0; i < CYS_CLIENT_BAG_SLOTS; ++i)
        {
            tObject_Item* item = CDataPool::GetMe()->UserBag_GetItem(i);
            if (!item || item->GetItemClass() != ICLASS_EQUIP) continue;
            tActionItem* action = CActionSystem::GetMe()->EnumAction(i, NAMETYPE_PACKAGEITEM);
            if (!action) continue;
            slot = i;
            return action;
        }
        return nullptr;
    }

    int Weapon()
    {
        CObject_PlayerMySelf* self = CObjectManager::GetMe()->GetMySelf();
        return self ? self->GetCharacterData()->Get_Equip(HEQUIP_WEAPON) : -1;
    }
}

bool CysInventoryDriver::Tick()
{
    State& s = S();
    if (!s.evaluated)
    {
        s.evaluated = true;
        char text[64] = {};
        const DWORD n = GetEnvironmentVariableA("CYS_INV_LIVE", text, sizeof(text));
        if (n == 1 && text[0] == '1') { s.step = Begin; s.at = GetTickCount(); }
        if (GetEnvironmentVariableA("CYS_INV_BUY_ITEM", text, sizeof(text)) > 0) s.buyItem = static_cast<unsigned>(strtoul(text, nullptr, 10));
        if (GetEnvironmentVariableA("CYS_INV_NPC", text, sizeof(text)) > 0) { char* comma = nullptr; s.npcX = (float)strtod(text, &comma); if (comma && *comma == ',') s.npcZ = (float)strtod(comma + 1, nullptr); }
        Log("driver %s buy_item=%u npc=%.0f,%.0f", s.step == Begin ? "enabled" : "disabled", s.buyItem, s.npcX, s.npcZ);
    }
    if (s.step == Off || s.step == Done) return true;
    if (!CysModernGame::IsInWorld()) { Log("left the world at step %d", (int)s.step); s.step = Done; return true; }
    CysInventoryNet::Counters c = CysInventoryNet::Get();
    switch (s.step)
    {
    case Begin:
        if (Age() < 1500) break;
        Log("money=%d bag_page=%d material_page=%d weapon=%d", CObjectManager::GetMe()->GetMySelf()->GetCharacterData()->Get_Money(),
            CysInventoryNet::BagSize(0), CysInventoryNet::BagSize(1), Weapon());
        CEventSystem::GetMe()->PushEvent(GE_TOGLE_CONTAINER); // the bag button of the CY main menu (ToggleContainer)
        Go(BagOpen, "TOGLE_CONTAINER");
        break;
    case BagOpen:
        if (Age() < 2000) break;
        Log("bag window Packet shown=%d", Shown("Packet") ? 1 : 0);
        Shot("inv-bag-open");
        {
            int slot = -1;
            tActionItem* action = FindBagEquipment(slot);
            if (!action)
                for (int i = 0; i < CYS_CLIENT_BAG_SLOTS && !action; ++i)
                    if (CDataPool::GetMe()->UserBag_GetItem(i)) { action = CActionSystem::GetMe()->EnumAction(i, NAMETYPE_PACKAGEITEM); slot = i; }
            if (action)
            {
                tObject_Item* item = CDataPool::GetMe()->UserBag_GetItem(slot);
                Log("tooltip for bag slot %d item=%u name=%s", slot, item ? item->GetIdTable() : 0, item ? item->GetName() : "");
                // This older smoke has no target button; retain its mouse-point
                // anchor explicitly. Native hover supplies the real button rect.
                const POINT point = CGameProcedure::s_pInputSystem->MouseGetPos();
                action->NotifyTooltipsShow(point.x, point.y, point.x, point.y);
            }
            else Log("bag is empty on the client: no tooltip");
        }
        Go(Tooltip, "NotifyTooltipsShow");
        break;
    case Tooltip:
        if (Age() < 1500) break;
        Log("tooltip window SuperTooltip shown=%d", Shown("SuperTooltip") ? 1 : 0);
        Shot("inv-tooltip");
        CEventSystem::GetMe()->PushEvent(GE_SUPERTOOLTIP, "0");
        CEventSystem::GetMe()->PushEvent(GE_OPEN_EQUIP, 1); // OpenEquip(1) of the CY main menu
        Go(EquipOpen, "OPEN_EQUIP");
        break;
    case EquipOpen:
        if (Age() < 2000) break;
        Log("equipment window SelfEquip shown=%d", Shown("SelfEquip") ? 1 : 0);
        Shot("inv-equip-open");
        Go(Equip, "equip");
        break;
    case Equip:
    {
        int slot = -1;
        tActionItem* action = FindBagEquipment(slot);
        if (!action)
        {
            if (!s.unequipFirst && CDataPool::GetMe()->UserEquip_GetItem(HEQUIP_WEAPON))
            {
                s.unequipFirst = true;
                Log("no equipment in the bag: unequip the worn weapon first, then equip it back");
                Go(Unequip, "unequip first");
                break;
            }
            Log("no equipment in the bag: equip skipped"); Go(Talk, "skip equip"); break;
        }
        tObject_Item* item = CDataPool::GetMe()->UserBag_GetItem(slot);
        s.equipBag = slot;
        s.weaponBefore = Weapon();
        s.base = c.useEquip;
        Log("DoAction on bag slot %d item=%u (%s) weapon_before=%d", slot, item->GetIdTable(), item->GetName(), s.weaponBefore);
        action->DoAction(); // CActionItem_Item: equipment in the own bag -> CGUseEquip
        Go(EquipWait, "CGUseEquip");
        break;
    }
    case EquipWait:
        if (c.useEquip > s.base && Age() >= 1500)
        {
            Log("equipped: weapon %d -> %d", s.weaponBefore, Weapon());
            Shot("inv-equipped");
            s.equippedOnce = true;
            if (s.unequipFirst) Go(Talk, "shop"); else Go(Unequip, "unequip");
        }
        else if (Age() > 6000) { Log("no GCUseEquipResult within 6 s"); Go(Talk, "equip timeout"); }
        break;
    case Unequip:
    {
        // the point just filled: the first own equipment action whose item came from the bag slot
        tActionItem* action = nullptr;
        for (int i = 0; i < CYS_CLIENT_EQUIP_SLOTS && !action; ++i)
            if (CDataPool::GetMe()->UserEquip_GetItem((HUMAN_EQUIP)i) && i == HEQUIP_WEAPON) { action = CActionSystem::GetMe()->EnumAction(i, NAMETYPE_EQUIP); s.equipPoint = i; }
        for (int i = 0; i < CYS_CLIENT_EQUIP_SLOTS && !action; ++i)
            if (CDataPool::GetMe()->UserEquip_GetItem((HUMAN_EQUIP)i)) { action = CActionSystem::GetMe()->EnumAction(i, NAMETYPE_EQUIP); s.equipPoint = i; }
        if (!action) { Log("no equipped item on the client"); Go(Talk, "skip unequip"); break; }
        s.base = c.unEquip;
        // CYS-UNEQUIP 20/09/2026: a worn item comes off through DoSubAction (the right click) as in client_GL and CY;
        // DoAction (the left click) no longer sends CGUnEquip - see GMActionSystem_Item.cpp. This script still calls
        // the C++ behind the door; the door itself (MouseRClick -> Lua -> host) is measured by CysUnequipProbe.
        Log("DoSubAction on equip point %d", s.equipPoint);
        action->DoSubAction(); // equipped item -> CGUnEquip
        Go(UnequipWait, "CGUnEquip");
        break;
    }
    case UnequipWait:
        if (c.unEquip > s.base && Age() >= 1500) { Log("unequipped: weapon now %d", Weapon()); Shot("inv-unequipped"); Go(s.unequipFirst && !s.equippedOnce ? Equip : Reequip, "equip from the bag"); }
        else if (Age() > 6000) { Log("no GCUnEquipResult within 6 s"); Go(Talk, "unequip timeout"); }
        break;
    case Reequip:
    {
        int slot = -1;
        tActionItem* action = FindBagEquipment(slot);
        if (!action) { Go(Talk, "nothing to re-equip"); break; }
        s.base = c.useEquip;
        action->DoAction();
        Go(ReequipWait, "CGUseEquip (restore)");
        break;
    }
    case ReequipWait:
        if (c.useEquip > s.base && Age() >= 1500) { Log("re-equipped: weapon %d", Weapon()); Shot("inv-reequipped"); Go(Talk, "shop"); }
        else if (Age() > 6000) Go(Talk, "re-equip timeout");
        break;
    case Talk:
    {
        float distance = 0;
        const unsigned serverId = CysModernGame::NearestObjectAt(s.npcX, s.npcZ, 6.0f, &distance);
        tObject* npc = serverId ? CObjectManager::GetMe()->FindServerObject((INT)serverId) : nullptr;
        if (!npc) { Log("no NPC near %.0f,%.0f in this scene", s.npcX, s.npcZ); Go(Close, "no merchant"); break; }
        s.base = c.eventLists;
        // The modern GCNewMonster carries no NPC flag, so the object stays NPC_TYPE_MONSTER and a left click would attack
        // (CAI default event); the NPC dialogue module (npc-quest) owns that. Send the talk request the click sends.
        Log("CGCharDefaultEvent npc server=%u client=%d dist_to_point=%.1f", serverId, npc->GetID(), distance);
        CGCharDefaultEvent talk;
        talk.setObjID((ObjID_t)serverId);
        CNetManager::GetMe()->SendPacket(&talk);
        Go(MenuWait, "CGCharDefaultEvent");
        break;
    }
    case MenuWait:
        if (c.eventLists > s.base && Age() >= 1500)
        {
            int script = 0, index = 0;
            Log("NPC dialogue Quest shown=%d", Shown("Quest") ? 1 : 0);
            Shot("inv-npc-menu");
            if (!CysInventoryNet::LastShopOption(script, index)) { Log("the NPC menu has no shop option"); Go(Close, "no shop option"); break; }
            s.base = c.shopLists;
            Log("SendSelectEvent script=%d index=%d (shop option)", script, index);
            CUIDataPool::GetMe()->SendSelectEvent(0, script, index);
            Go(ShopWait, "CGEventRequest");
        }
        else if (Age() > 15000) { Log("no NPC menu within 15 s"); Go(Close, "menu timeout"); }
        break;
    case ShopWait:
        if (c.shopLists > s.base && Age() >= 2000)
        {
            Log("shop window Shop shown=%d bag Packet shown=%d goods=%d", Shown("Shop") ? 1 : 0, Shown("Packet") ? 1 : 0, CDataPool::GetMe()->Booth_GetNumber());
            Shot("inv-shop-open");
            Go(Buy, "buy");
        }
        else if (Age() > 6000) { Log("no GCShopMerchandiseList within 6 s"); Go(Close, "shop timeout"); }
        break;
    case Buy:
    {
        tActionItem* action = nullptr;
        for (int i = 0; i < CDataPool::GetMe()->Booth_GetNumber() && !action; ++i)
        {
            tObject_Item* goods = CDataPool::GetMe()->Booth_GetItem(i);
            if (goods && goods->GetIdTable() == s.buyItem) action = CActionSystem::GetMe()->EnumAction(i, NAMETYPE_BOOTITEM);
        }
        if (!action) { Log("item %u not on the booth", s.buyItem); Go(Close, "no goods"); break; }
        s.base = c.shopBuys;
        Log("DoAction on booth item %u money=%d", s.buyItem, CObjectManager::GetMe()->GetMySelf()->GetCharacterData()->Get_Money());
        action->DoAction(); // booth item -> Booth_BuyItem -> CGShopBuy
        Go(BuyWait, "CGShopBuy");
        break;
    }
    case BuyWait:
        if (c.shopBuys > s.base && Age() >= 2000) { Log("GCShopBuy received; money=%d", CObjectManager::GetMe()->GetMySelf()->GetCharacterData()->Get_Money()); Shot("inv-shop-bought"); Go(Close, "close"); }
        else if (Age() > 6000) { Log("no GCShopBuy within 6 s (client money check or server refusal)"); Shot("inv-shop-nobuy"); Go(Close, "buy timeout"); }
        break;
    case Close:
        if (Age() < 500) break;
        CEventSystem::GetMe()->PushEvent(GE_CLOSE_BOOTH);
        Log("PASS inventory live script (counters use_equip=%u un_equip=%u equip_lists=%u shop_lists=%u shop_buys=%u)", c.useEquip, c.unEquip, c.equipLists, c.shopLists, c.shopBuys);
        s.step = Done;
        return true;
    default:
        break;
    }
    return false;
}

#else
bool CysInventoryDriver::Tick() { return true; }
#endif
