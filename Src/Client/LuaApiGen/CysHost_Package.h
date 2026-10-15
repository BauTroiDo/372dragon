#pragma once
// CYS-INV: Lua host functions of the CY bag / equipment / shop windows (Packet.lua, SelfEquip.lua, Shop.lua) that
// the 0.85 source lacks or that the generated catalog stubs answer with 0. Game-layer state comes through Services
// (implemented in WXClient/Network/CysInventoryNet.cpp); this file only does the Lua glue.
#include "LuaPlus.h"

namespace CysHostPackage
{
    enum Bag { BagBase = 0, BagMaterial = 1, BagTask = 2 };
    enum Count { CountNum = 0, CountBase = 1, CountRealMax = 2, CountMax = 3 };
    // SuperTooltip.lua (CY) text parts of the item under the tooltip; an empty Propertys/Author means "absent" (nil).
    enum TipText { TipIcon = 0, TipDesc1, TipDesc2, TipDesc3, TipDesc4, TipDesc6, TipPropertys, TipExplain, TipAuthor, TipMoney1Label, TipMoney2Label, TipGem1, TipGem2, TipGem3, TipGem4, TipTitle, TipStatus, TipDiaowenIcon };
    enum TipNumber { TipGemHoles = 0, TipEquipQual, TipPresent, TipMoney1, TipMoney2, TipMoneyType };

    struct Services
    {
        void* context = nullptr;
        // Slot counts of one bag page (Packet.lua Packet_OnUpdateShow / Packet_UpdateDragAcceptName).
        int (*bagCount)(void* context, int bag, int what) = nullptr;
        // DataPool:AskMyBagList (Packet_CloseFunction): CGAskMyBagList + CGAskMyBagSize.
        void (*askBagList)(void* context) = nullptr;
        void (*pickAll)(void* context) = nullptr;
        double (*experience)(void* context, bool maximum) = nullptr;
        // Tooltip parts (nullptr / 0 = neutral).
        const char* (*tooltipText)(void* context, int part) = nullptr;
        int (*tooltipNumber)(void* context, int part) = nullptr;
        void (*tooltipShowWithAlt)(void* context, int left, int top, int right, int bottom) = nullptr;
    };

    // Registers every function; the bag counters and AskMyBagList replace catalog stubs, the neutral helpers are
    // added only when the receiver lacks them. Returns the number of functions registered.
    int Register(LuaPlus::LuaState* state, const Services& services);
}
