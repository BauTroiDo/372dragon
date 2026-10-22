




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_NpcShop_BindYuanBaoNotEnough(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "BindYuanBaoNotEnough", ""); }


        int LAG_NpcShop_BulkBuyItem(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "BulkBuyItem", ""); }

        int LAG_NpcShop_CloseConfirm(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "CloseConfirm", ""); }

        int LAG_NpcShop_EnumCallBackItem(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "EnumCallBackItem", "o"); }

        int LAG_NpcShop_GetAbilityIdByIBIdentityId(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "GetAbilityIdByIBIdentityId", "nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn"); }

        int LAG_NpcShop_GetAnniversaryFanChangShopCountBySellType(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "GetAnniversaryFanChangShopCountBySellType", "n"); }

        int LAG_NpcShop_GetAnniversaryFanChangShopItemData(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "GetAnniversaryFanChangShopItemData", "t"); }

        int LAG_NpcShop_GetBuyDirectly(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "GetBuyDirectly", "n"); }

        int LAG_NpcShop_GetHKCJDirectly(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "GetHKCJDirectly", "n"); }

        int LAG_NpcShop_GetIsShopReorder(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "GetIsShopReorder", "n"); }

        int LAG_NpcShop_GetJiYuanDirectly(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "GetJiYuanDirectly", "n"); }

        int LAG_NpcShop_GetQianWuShopItem(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "GetQianWuShopItem", ""); }

        int LAG_NpcShop_GetQianWuShopItemByIdx(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "GetQianWuShopItemByIdx", "nnnn"); }

        int LAG_NpcShop_GetQingQiuDirectly(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "GetQingQiuDirectly", "n"); }


        int LAG_NpcShop_GetRepairAllPrice(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "GetRepairAllPrice", ""); }

        int LAG_NpcShop_GetReputationShopBuyCountByIdx(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "GetReputationShopBuyCountByIdx", "n"); }

        int LAG_NpcShop_GetReputationShopItemByIdx(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "GetReputationShopItemByIdx", "nnnnnn"); }

        int LAG_NpcShop_GetShengWangYBDirectly(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "GetShengWangYBDirectly", "n"); }


        int LAG_NpcShop_GetShopType(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "GetShopType", "n"); }

        int LAG_NpcShop_GetUseYBForBind(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "GetUseYBForBind", "n"); }

        int LAG_NpcShop_GetXinYeDirectly(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "GetXinYeDirectly", "n"); }

        int LAG_NpcShop_GetZSCShopBuyDirectly(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "GetZSCShopBuyDirectly", "n"); }

        int LAG_NpcShop_Lua_UpdateMSShopLimitItem(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "Lua_UpdateMSShopLimitItem", ""); }


        int LAG_NpcShop_SetBuyDirectly(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "SetBuyDirectly", ""); }


        int LAG_NpcShop_SetHKCJDirectly(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "SetHKCJDirectly", ""); }


        int LAG_NpcShop_SetJiYuanDirectly(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "SetJiYuanDirectly", ""); }


        int LAG_NpcShop_SetQingQiuDirectly(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "SetQingQiuDirectly", ""); }


        int LAG_NpcShop_SetShengWangYBDirectly(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "SetShengWangYBDirectly", ""); }

        int LAG_NpcShop_SetUseYBForBind(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "SetUseYBForBind", ""); }


        int LAG_NpcShop_SetXinYeDirectly(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "SetXinYeDirectly", ""); }


        int LAG_NpcShop_SetZSCShopBuyDirectly(LuaPlus::LuaState* state) { return Stub(state, "NpcShop", "SetZSCShopBuyDirectly", ""); }
    }

    void Register_NpcShop(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "BindYuanBaoNotEnough")) table.Register("BindYuanBaoNotEnough", LAG_NpcShop_BindYuanBaoNotEnough);
        if (IsMissing(table, "BulkBuyItem")) table.Register("BulkBuyItem", LAG_NpcShop_BulkBuyItem);
        if (IsMissing(table, "CloseConfirm")) table.Register("CloseConfirm", LAG_NpcShop_CloseConfirm);
        if (IsMissing(table, "EnumCallBackItem")) table.Register("EnumCallBackItem", LAG_NpcShop_EnumCallBackItem);
        if (IsMissing(table, "GetAbilityIdByIBIdentityId")) table.Register("GetAbilityIdByIBIdentityId", LAG_NpcShop_GetAbilityIdByIBIdentityId);
        if (IsMissing(table, "GetAnniversaryFanChangShopCountBySellType")) table.Register("GetAnniversaryFanChangShopCountBySellType", LAG_NpcShop_GetAnniversaryFanChangShopCountBySellType);
        if (IsMissing(table, "GetAnniversaryFanChangShopItemData")) table.Register("GetAnniversaryFanChangShopItemData", LAG_NpcShop_GetAnniversaryFanChangShopItemData);
        if (IsMissing(table, "GetBuyDirectly")) table.Register("GetBuyDirectly", LAG_NpcShop_GetBuyDirectly);
        if (IsMissing(table, "GetHKCJDirectly")) table.Register("GetHKCJDirectly", LAG_NpcShop_GetHKCJDirectly);
        if (IsMissing(table, "GetIsShopReorder")) table.Register("GetIsShopReorder", LAG_NpcShop_GetIsShopReorder);
        if (IsMissing(table, "GetJiYuanDirectly")) table.Register("GetJiYuanDirectly", LAG_NpcShop_GetJiYuanDirectly);
        if (IsMissing(table, "GetQianWuShopItem")) table.Register("GetQianWuShopItem", LAG_NpcShop_GetQianWuShopItem);
        if (IsMissing(table, "GetQianWuShopItemByIdx")) table.Register("GetQianWuShopItemByIdx", LAG_NpcShop_GetQianWuShopItemByIdx);
        if (IsMissing(table, "GetQingQiuDirectly")) table.Register("GetQingQiuDirectly", LAG_NpcShop_GetQingQiuDirectly);
        if (IsMissing(table, "GetRepairAllPrice")) table.Register("GetRepairAllPrice", LAG_NpcShop_GetRepairAllPrice);
        if (IsMissing(table, "GetReputationShopBuyCountByIdx")) table.Register("GetReputationShopBuyCountByIdx", LAG_NpcShop_GetReputationShopBuyCountByIdx);
        if (IsMissing(table, "GetReputationShopItemByIdx")) table.Register("GetReputationShopItemByIdx", LAG_NpcShop_GetReputationShopItemByIdx);
        if (IsMissing(table, "GetShengWangYBDirectly")) table.Register("GetShengWangYBDirectly", LAG_NpcShop_GetShengWangYBDirectly);
        if (IsMissing(table, "GetShopType")) table.Register("GetShopType", LAG_NpcShop_GetShopType);
        if (IsMissing(table, "GetUseYBForBind")) table.Register("GetUseYBForBind", LAG_NpcShop_GetUseYBForBind);
        if (IsMissing(table, "GetXinYeDirectly")) table.Register("GetXinYeDirectly", LAG_NpcShop_GetXinYeDirectly);
        if (IsMissing(table, "GetZSCShopBuyDirectly")) table.Register("GetZSCShopBuyDirectly", LAG_NpcShop_GetZSCShopBuyDirectly);
        if (IsMissing(table, "Lua_UpdateMSShopLimitItem")) table.Register("Lua_UpdateMSShopLimitItem", LAG_NpcShop_Lua_UpdateMSShopLimitItem);
        if (IsMissing(table, "SetBuyDirectly")) table.Register("SetBuyDirectly", LAG_NpcShop_SetBuyDirectly);
        if (IsMissing(table, "SetHKCJDirectly")) table.Register("SetHKCJDirectly", LAG_NpcShop_SetHKCJDirectly);
        if (IsMissing(table, "SetJiYuanDirectly")) table.Register("SetJiYuanDirectly", LAG_NpcShop_SetJiYuanDirectly);
        if (IsMissing(table, "SetQingQiuDirectly")) table.Register("SetQingQiuDirectly", LAG_NpcShop_SetQingQiuDirectly);
        if (IsMissing(table, "SetShengWangYBDirectly")) table.Register("SetShengWangYBDirectly", LAG_NpcShop_SetShengWangYBDirectly);
        if (IsMissing(table, "SetUseYBForBind")) table.Register("SetUseYBForBind", LAG_NpcShop_SetUseYBForBind);
        if (IsMissing(table, "SetXinYeDirectly")) table.Register("SetXinYeDirectly", LAG_NpcShop_SetXinYeDirectly);
        if (IsMissing(table, "SetZSCShopBuyDirectly")) table.Register("SetZSCShopBuyDirectly", LAG_NpcShop_SetZSCShopBuyDirectly);
    }
}
