




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_PlayerPackage_CheckDiaowenHechengMat(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "CheckDiaowenHechengMat", "n"); }

        int LAG_PlayerPackage_CountAvailableItemByIDTable(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "CountAvailableItemByIDTable", "n"); }

        int LAG_PlayerPackage_FindFirstBindedItemIdxByIDTable(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "FindFirstBindedItemIdxByIDTable", "nn"); }

        int LAG_PlayerPackage_GetBagItemName(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "GetBagItemName", "s"); }

        int LAG_PlayerPackage_GetBagItemNum(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "GetBagItemNum", "n"); }

        int LAG_PlayerPackage_GetBagKfsAttrExNum(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "GetBagKfsAttrExNum", "n"); }

        int LAG_PlayerPackage_GetBagKfsAttrExUpItem(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "GetBagKfsAttrExUpItem", "n"); }

        int LAG_PlayerPackage_GetBagKfsAttrExUpMoney(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "GetBagKfsAttrExUpMoney", "n"); }

        int LAG_PlayerPackage_GetBagKfsData(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "GetBagKfsData", "n"); }

        int LAG_PlayerPackage_GetBagKfsSkill(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "GetBagKfsSkill", "n"); }

        int LAG_PlayerPackage_GetBagKfsSkillNum(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "GetBagKfsSkillNum", "n"); }

        int LAG_PlayerPackage_GetBagKfsSkillUpItem(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "GetBagKfsSkillUpItem", "n"); }

        int LAG_PlayerPackage_GetBagKfsSkillUpMoney(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "GetBagKfsSkillUpMoney", "n"); }

        int LAG_PlayerPackage_GetBagKfsSkillUpSkill(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "GetBagKfsSkillUpSkill", "n"); }

        int LAG_PlayerPackage_GetBagKfsSlotMoney(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "GetBagKfsSlotMoney", "n"); }

        int LAG_PlayerPackage_GetBagPosByItemIndex(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "GetBagPosByItemIndex", "n"); }

        int LAG_PlayerPackage_GetGoldTickValueByIndex(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "GetGoldTickValueByIndex", "nn"); }

        int LAG_PlayerPackage_GetItemBindStatusByIndex(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "GetItemBindStatusByIndex", "n"); }

        int LAG_PlayerPackage_GetItemGrade(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "GetItemGrade", "n"); }

        int LAG_PlayerPackage_GetItemName(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "GetItemName", "s"); }

        int LAG_PlayerPackage_GetItemNeedLvByIndex(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "GetItemNeedLvByIndex", "n"); }

        int LAG_PlayerPackage_GetItemSubTableIndex(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "GetItemSubTableIndex", "n"); }

        int LAG_PlayerPackage_GetItemTableIndex(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "GetItemTableIndex", "n"); }

        int LAG_PlayerPackage_GetKfsAttrEx(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "GetKfsAttrEx", "sn"); }

        int LAG_PlayerPackage_GetPUnlockElapsedTime_Pet(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "GetPUnlockElapsedTime_Pet", "n"); }

        int LAG_PlayerPackage_IsBagItemDark(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "IsBagItemDark", "n"); }

        int LAG_PlayerPackage_IsBagItemKFS(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "IsBagItemKFS", "n"); }

        int LAG_PlayerPackage_IsGem(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "IsGem", "n"); }

        int LAG_PlayerPackage_IsGoodsProtect_Pet(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "IsGoodsProtect_Pet", "n"); }

        int LAG_PlayerPackage_IsIdentityStilettoEquip(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "IsIdentityStilettoEquip", "n"); }

        int LAG_PlayerPackage_IsMaterial(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "IsMaterial", "n"); }

        int LAG_PlayerPackage_IsPetLock(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "IsPetLock", "n"); }

        int LAG_PlayerPackage_IsPetShopTradeItem(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "IsPetShopTradeItem", "n"); }

        int LAG_PlayerPackage_IsProtectGoods(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "IsProtectGoods", "n"); }

        int LAG_PlayerPackage_IsYubaoTradeItem(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "IsYubaoTradeItem", "n"); }


        int LAG_PlayerPackage_Kfs_Op_Do(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "Kfs_Op_Do", ""); }

        int LAG_PlayerPackage_LuaFnEnumEquipExtAttr(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnEnumEquipExtAttr", "s"); }

        int LAG_PlayerPackage_LuaFnGetBagItemEquipPoint(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnGetBagItemEquipPoint", "n"); }

        int LAG_PlayerPackage_LuaFnGetBagItemLingYuExAttrDesc(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnGetBagItemLingYuExAttrDesc", "s"); }

        int LAG_PlayerPackage_LuaFnGetBagItemLingYuMainAttrDesc(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnGetBagItemLingYuMainAttrDesc", "s"); }

        int LAG_PlayerPackage_LuaFnGetBagLingYuData(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnGetBagLingYuData", "n"); }

        int LAG_PlayerPackage_LuaFnGetBagShenBingData(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnGetBagShenBingData", "nn"); }

        int LAG_PlayerPackage_LuaFnGetCheDiFuLuPosInfo(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnGetCheDiFuLuPosInfo", "nsnnnn"); }

        int LAG_PlayerPackage_LuaFnGetEquipAttrCount(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnGetEquipAttrCount", "n"); }

        int LAG_PlayerPackage_LuaFnGetEquipAttrRefreshTimes(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnGetEquipAttrRefreshTimes", "n"); }

        int LAG_PlayerPackage_LuaFnGetEquipQual(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnGetEquipQual", "n"); }

        int LAG_PlayerPackage_LuaFnGetItemPetElfAttr(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnGetItemPetElfAttr", "nn"); }

        int LAG_PlayerPackage_LuaFnGetPetElfItemQual(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnGetPetElfItemQual", "n"); }

        int LAG_PlayerPackage_LuaFnGetPetElfItemSkill(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnGetPetElfItemSkill", "n"); }

        int LAG_PlayerPackage_LuaFnGetPetElfItemType(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnGetPetElfItemType", "n"); }

        int LAG_PlayerPackage_LuaFnGetPetSoulDataInBag(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnGetPetSoulDataInBag", "s"); }

        int LAG_PlayerPackage_LuaFnGetShenBingCommonSkillFromPool(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnGetShenBingCommonSkillFromPool", "n"); }

        int LAG_PlayerPackage_LuaFnGetShenBingCoreSkillTime(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnGetShenBingCoreSkillTime", "n"); }

        int LAG_PlayerPackage_LuaFnGetShenBingCustomSkillFromPool(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnGetShenBingCustomSkillFromPool", "n"); }

        int LAG_PlayerPackage_LuaFnGetShenBingExtensionAttr(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnGetShenBingExtensionAttr", ""); }

        int LAG_PlayerPackage_LuaFnGetShenBingLevelUpInfo(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnGetShenBingLevelUpInfo", "nnn"); }

        int LAG_PlayerPackage_LuaFnGetShenBingLimitSkillActiveNeed(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnGetShenBingLimitSkillActiveNeed", "n"); }

        int LAG_PlayerPackage_LuaFnGetShenBingSkillUpInfo(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnGetShenBingSkillUpInfo", "nnnnn"); }

        int LAG_PlayerPackage_LuaFnGetShenBingStarInfo(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnGetShenBingStarInfo", ""); }

        int LAG_PlayerPackage_LuaFnIsBagItemLingYu(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnIsBagItemLingYu", "n"); }

        int LAG_PlayerPackage_LuaFnIsBagItemShenBing(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnIsBagItemShenBing", "n"); }

        int LAG_PlayerPackage_LuaFnIsEquip(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnIsEquip", "n"); }

        int LAG_PlayerPackage_LuaFnIsHandMakeEquip(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnIsHandMakeEquip", "n"); }

        int LAG_PlayerPackage_LuaFnIsPetElf(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnIsPetElf", "n"); }

        int LAG_PlayerPackage_LuaFnIsPetElfIdentified(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnIsPetElfIdentified", "n"); }

        int LAG_PlayerPackage_LuaFnPetSoulSmashPiecesCount(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnPetSoulSmashPiecesCount", "n"); }

        int LAG_PlayerPackage_LuaFnUseCheDiFuLuBuChong(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnUseCheDiFuLuBuChong", ""); }

        int LAG_PlayerPackage_LuaFnUseCheDiFuLuChuanSong(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnUseCheDiFuLuChuanSong", ""); }

        int LAG_PlayerPackage_LuaFnUseCheDiFuLuSetpos(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "LuaFnUseCheDiFuLuSetpos", ""); }

        int LAG_PlayerPackage_Lua_GetBagItemEquipPoint(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "Lua_GetBagItemEquipPoint", "n"); }

        int LAG_PlayerPackage_Lua_GetUnLockBindItemCount(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "Lua_GetUnLockBindItemCount", "n"); }

        int LAG_PlayerPackage_Lua_GetUnLockItemCount(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "Lua_GetUnLockItemCount", "n"); }

        int LAG_PlayerPackage_OpenPetEquipEnhanceMsgBox(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "OpenPetEquipEnhanceMsgBox", ""); }

        int LAG_PlayerPackage_OpenPetEquipReIdentifyMsgBox(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "OpenPetEquipReIdentifyMsgBox", ""); }

        int LAG_PlayerPackage_OpenReIdentifyMsgBox(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "OpenReIdentifyMsgBox", ""); }

        int LAG_PlayerPackage_OpenStengMsgBox(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "OpenStengMsgBox", ""); }

        int LAG_PlayerPackage_PickAllItem(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "PickAllItem", ""); }

        int LAG_PlayerPackage_SellCurrItem(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "SellCurrItem", "n"); }


        int LAG_PlayerPackage_UseItem(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "UseItem", ""); }

        int LAG_PlayerPackage_UseTulingzhuSetpos(LuaPlus::LuaState* state) { return Stub(state, "PlayerPackage", "UseTulingzhuSetpos", ""); }
    }

    void Register_PlayerPackage(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "CheckDiaowenHechengMat")) table.Register("CheckDiaowenHechengMat", LAG_PlayerPackage_CheckDiaowenHechengMat);
        if (IsMissing(table, "CountAvailableItemByIDTable")) table.Register("CountAvailableItemByIDTable", LAG_PlayerPackage_CountAvailableItemByIDTable);
        if (IsMissing(table, "FindFirstBindedItemIdxByIDTable")) table.Register("FindFirstBindedItemIdxByIDTable", LAG_PlayerPackage_FindFirstBindedItemIdxByIDTable);
        if (IsMissing(table, "GetBagItemName")) table.Register("GetBagItemName", LAG_PlayerPackage_GetBagItemName);
        if (IsMissing(table, "GetBagItemNum")) table.Register("GetBagItemNum", LAG_PlayerPackage_GetBagItemNum);
        if (IsMissing(table, "GetBagKfsAttrExNum")) table.Register("GetBagKfsAttrExNum", LAG_PlayerPackage_GetBagKfsAttrExNum);
        if (IsMissing(table, "GetBagKfsAttrExUpItem")) table.Register("GetBagKfsAttrExUpItem", LAG_PlayerPackage_GetBagKfsAttrExUpItem);
        if (IsMissing(table, "GetBagKfsAttrExUpMoney")) table.Register("GetBagKfsAttrExUpMoney", LAG_PlayerPackage_GetBagKfsAttrExUpMoney);
        if (IsMissing(table, "GetBagKfsData")) table.Register("GetBagKfsData", LAG_PlayerPackage_GetBagKfsData);
        if (IsMissing(table, "GetBagKfsSkill")) table.Register("GetBagKfsSkill", LAG_PlayerPackage_GetBagKfsSkill);
        if (IsMissing(table, "GetBagKfsSkillNum")) table.Register("GetBagKfsSkillNum", LAG_PlayerPackage_GetBagKfsSkillNum);
        if (IsMissing(table, "GetBagKfsSkillUpItem")) table.Register("GetBagKfsSkillUpItem", LAG_PlayerPackage_GetBagKfsSkillUpItem);
        if (IsMissing(table, "GetBagKfsSkillUpMoney")) table.Register("GetBagKfsSkillUpMoney", LAG_PlayerPackage_GetBagKfsSkillUpMoney);
        if (IsMissing(table, "GetBagKfsSkillUpSkill")) table.Register("GetBagKfsSkillUpSkill", LAG_PlayerPackage_GetBagKfsSkillUpSkill);
        if (IsMissing(table, "GetBagKfsSlotMoney")) table.Register("GetBagKfsSlotMoney", LAG_PlayerPackage_GetBagKfsSlotMoney);
        if (IsMissing(table, "GetBagPosByItemIndex")) table.Register("GetBagPosByItemIndex", LAG_PlayerPackage_GetBagPosByItemIndex);
        if (IsMissing(table, "GetGoldTickValueByIndex")) table.Register("GetGoldTickValueByIndex", LAG_PlayerPackage_GetGoldTickValueByIndex);
        if (IsMissing(table, "GetItemBindStatusByIndex")) table.Register("GetItemBindStatusByIndex", LAG_PlayerPackage_GetItemBindStatusByIndex);
        if (IsMissing(table, "GetItemGrade")) table.Register("GetItemGrade", LAG_PlayerPackage_GetItemGrade);
        if (IsMissing(table, "GetItemName")) table.Register("GetItemName", LAG_PlayerPackage_GetItemName);
        if (IsMissing(table, "GetItemNeedLvByIndex")) table.Register("GetItemNeedLvByIndex", LAG_PlayerPackage_GetItemNeedLvByIndex);
        if (IsMissing(table, "GetItemSubTableIndex")) table.Register("GetItemSubTableIndex", LAG_PlayerPackage_GetItemSubTableIndex);
        if (IsMissing(table, "GetItemTableIndex")) table.Register("GetItemTableIndex", LAG_PlayerPackage_GetItemTableIndex);
        if (IsMissing(table, "GetKfsAttrEx")) table.Register("GetKfsAttrEx", LAG_PlayerPackage_GetKfsAttrEx);
        if (IsMissing(table, "GetPUnlockElapsedTime_Pet")) table.Register("GetPUnlockElapsedTime_Pet", LAG_PlayerPackage_GetPUnlockElapsedTime_Pet);
        if (IsMissing(table, "IsBagItemDark")) table.Register("IsBagItemDark", LAG_PlayerPackage_IsBagItemDark);
        if (IsMissing(table, "IsBagItemKFS")) table.Register("IsBagItemKFS", LAG_PlayerPackage_IsBagItemKFS);
        if (IsMissing(table, "IsGem")) table.Register("IsGem", LAG_PlayerPackage_IsGem);
        if (IsMissing(table, "IsGoodsProtect_Pet")) table.Register("IsGoodsProtect_Pet", LAG_PlayerPackage_IsGoodsProtect_Pet);
        if (IsMissing(table, "IsIdentityStilettoEquip")) table.Register("IsIdentityStilettoEquip", LAG_PlayerPackage_IsIdentityStilettoEquip);
        if (IsMissing(table, "IsMaterial")) table.Register("IsMaterial", LAG_PlayerPackage_IsMaterial);
        if (IsMissing(table, "IsPetLock")) table.Register("IsPetLock", LAG_PlayerPackage_IsPetLock);
        if (IsMissing(table, "IsPetShopTradeItem")) table.Register("IsPetShopTradeItem", LAG_PlayerPackage_IsPetShopTradeItem);
        if (IsMissing(table, "IsProtectGoods")) table.Register("IsProtectGoods", LAG_PlayerPackage_IsProtectGoods);
        if (IsMissing(table, "IsYubaoTradeItem")) table.Register("IsYubaoTradeItem", LAG_PlayerPackage_IsYubaoTradeItem);
        if (IsMissing(table, "Kfs_Op_Do")) table.Register("Kfs_Op_Do", LAG_PlayerPackage_Kfs_Op_Do);
        if (IsMissing(table, "LuaFnEnumEquipExtAttr")) table.Register("LuaFnEnumEquipExtAttr", LAG_PlayerPackage_LuaFnEnumEquipExtAttr);
        if (IsMissing(table, "LuaFnGetBagItemEquipPoint")) table.Register("LuaFnGetBagItemEquipPoint", LAG_PlayerPackage_LuaFnGetBagItemEquipPoint);
        if (IsMissing(table, "LuaFnGetBagItemLingYuExAttrDesc")) table.Register("LuaFnGetBagItemLingYuExAttrDesc", LAG_PlayerPackage_LuaFnGetBagItemLingYuExAttrDesc);
        if (IsMissing(table, "LuaFnGetBagItemLingYuMainAttrDesc")) table.Register("LuaFnGetBagItemLingYuMainAttrDesc", LAG_PlayerPackage_LuaFnGetBagItemLingYuMainAttrDesc);
        if (IsMissing(table, "LuaFnGetBagLingYuData")) table.Register("LuaFnGetBagLingYuData", LAG_PlayerPackage_LuaFnGetBagLingYuData);
        if (IsMissing(table, "LuaFnGetBagShenBingData")) table.Register("LuaFnGetBagShenBingData", LAG_PlayerPackage_LuaFnGetBagShenBingData);
        if (IsMissing(table, "LuaFnGetCheDiFuLuPosInfo")) table.Register("LuaFnGetCheDiFuLuPosInfo", LAG_PlayerPackage_LuaFnGetCheDiFuLuPosInfo);
        if (IsMissing(table, "LuaFnGetEquipAttrCount")) table.Register("LuaFnGetEquipAttrCount", LAG_PlayerPackage_LuaFnGetEquipAttrCount);
        if (IsMissing(table, "LuaFnGetEquipAttrRefreshTimes")) table.Register("LuaFnGetEquipAttrRefreshTimes", LAG_PlayerPackage_LuaFnGetEquipAttrRefreshTimes);
        if (IsMissing(table, "LuaFnGetEquipQual")) table.Register("LuaFnGetEquipQual", LAG_PlayerPackage_LuaFnGetEquipQual);
        if (IsMissing(table, "LuaFnGetItemPetElfAttr")) table.Register("LuaFnGetItemPetElfAttr", LAG_PlayerPackage_LuaFnGetItemPetElfAttr);
        if (IsMissing(table, "LuaFnGetPetElfItemQual")) table.Register("LuaFnGetPetElfItemQual", LAG_PlayerPackage_LuaFnGetPetElfItemQual);
        if (IsMissing(table, "LuaFnGetPetElfItemSkill")) table.Register("LuaFnGetPetElfItemSkill", LAG_PlayerPackage_LuaFnGetPetElfItemSkill);
        if (IsMissing(table, "LuaFnGetPetElfItemType")) table.Register("LuaFnGetPetElfItemType", LAG_PlayerPackage_LuaFnGetPetElfItemType);
        if (IsMissing(table, "LuaFnGetPetSoulDataInBag")) table.Register("LuaFnGetPetSoulDataInBag", LAG_PlayerPackage_LuaFnGetPetSoulDataInBag);
        if (IsMissing(table, "LuaFnGetShenBingCommonSkillFromPool")) table.Register("LuaFnGetShenBingCommonSkillFromPool", LAG_PlayerPackage_LuaFnGetShenBingCommonSkillFromPool);
        if (IsMissing(table, "LuaFnGetShenBingCoreSkillTime")) table.Register("LuaFnGetShenBingCoreSkillTime", LAG_PlayerPackage_LuaFnGetShenBingCoreSkillTime);
        if (IsMissing(table, "LuaFnGetShenBingCustomSkillFromPool")) table.Register("LuaFnGetShenBingCustomSkillFromPool", LAG_PlayerPackage_LuaFnGetShenBingCustomSkillFromPool);
        if (IsMissing(table, "LuaFnGetShenBingExtensionAttr")) table.Register("LuaFnGetShenBingExtensionAttr", LAG_PlayerPackage_LuaFnGetShenBingExtensionAttr);
        if (IsMissing(table, "LuaFnGetShenBingLevelUpInfo")) table.Register("LuaFnGetShenBingLevelUpInfo", LAG_PlayerPackage_LuaFnGetShenBingLevelUpInfo);
        if (IsMissing(table, "LuaFnGetShenBingLimitSkillActiveNeed")) table.Register("LuaFnGetShenBingLimitSkillActiveNeed", LAG_PlayerPackage_LuaFnGetShenBingLimitSkillActiveNeed);
        if (IsMissing(table, "LuaFnGetShenBingSkillUpInfo")) table.Register("LuaFnGetShenBingSkillUpInfo", LAG_PlayerPackage_LuaFnGetShenBingSkillUpInfo);
        if (IsMissing(table, "LuaFnGetShenBingStarInfo")) table.Register("LuaFnGetShenBingStarInfo", LAG_PlayerPackage_LuaFnGetShenBingStarInfo);
        if (IsMissing(table, "LuaFnIsBagItemLingYu")) table.Register("LuaFnIsBagItemLingYu", LAG_PlayerPackage_LuaFnIsBagItemLingYu);
        if (IsMissing(table, "LuaFnIsBagItemShenBing")) table.Register("LuaFnIsBagItemShenBing", LAG_PlayerPackage_LuaFnIsBagItemShenBing);
        if (IsMissing(table, "LuaFnIsEquip")) table.Register("LuaFnIsEquip", LAG_PlayerPackage_LuaFnIsEquip);
        if (IsMissing(table, "LuaFnIsHandMakeEquip")) table.Register("LuaFnIsHandMakeEquip", LAG_PlayerPackage_LuaFnIsHandMakeEquip);
        if (IsMissing(table, "LuaFnIsPetElf")) table.Register("LuaFnIsPetElf", LAG_PlayerPackage_LuaFnIsPetElf);
        if (IsMissing(table, "LuaFnIsPetElfIdentified")) table.Register("LuaFnIsPetElfIdentified", LAG_PlayerPackage_LuaFnIsPetElfIdentified);
        if (IsMissing(table, "LuaFnPetSoulSmashPiecesCount")) table.Register("LuaFnPetSoulSmashPiecesCount", LAG_PlayerPackage_LuaFnPetSoulSmashPiecesCount);
        if (IsMissing(table, "LuaFnUseCheDiFuLuBuChong")) table.Register("LuaFnUseCheDiFuLuBuChong", LAG_PlayerPackage_LuaFnUseCheDiFuLuBuChong);
        if (IsMissing(table, "LuaFnUseCheDiFuLuChuanSong")) table.Register("LuaFnUseCheDiFuLuChuanSong", LAG_PlayerPackage_LuaFnUseCheDiFuLuChuanSong);
        if (IsMissing(table, "LuaFnUseCheDiFuLuSetpos")) table.Register("LuaFnUseCheDiFuLuSetpos", LAG_PlayerPackage_LuaFnUseCheDiFuLuSetpos);
        if (IsMissing(table, "Lua_GetBagItemEquipPoint")) table.Register("Lua_GetBagItemEquipPoint", LAG_PlayerPackage_Lua_GetBagItemEquipPoint);
        if (IsMissing(table, "Lua_GetUnLockBindItemCount")) table.Register("Lua_GetUnLockBindItemCount", LAG_PlayerPackage_Lua_GetUnLockBindItemCount);
        if (IsMissing(table, "Lua_GetUnLockItemCount")) table.Register("Lua_GetUnLockItemCount", LAG_PlayerPackage_Lua_GetUnLockItemCount);
        if (IsMissing(table, "OpenPetEquipEnhanceMsgBox")) table.Register("OpenPetEquipEnhanceMsgBox", LAG_PlayerPackage_OpenPetEquipEnhanceMsgBox);
        if (IsMissing(table, "OpenPetEquipReIdentifyMsgBox")) table.Register("OpenPetEquipReIdentifyMsgBox", LAG_PlayerPackage_OpenPetEquipReIdentifyMsgBox);
        if (IsMissing(table, "OpenReIdentifyMsgBox")) table.Register("OpenReIdentifyMsgBox", LAG_PlayerPackage_OpenReIdentifyMsgBox);
        if (IsMissing(table, "OpenStengMsgBox")) table.Register("OpenStengMsgBox", LAG_PlayerPackage_OpenStengMsgBox);
        if (IsMissing(table, "PickAllItem")) table.Register("PickAllItem", LAG_PlayerPackage_PickAllItem);
        if (IsMissing(table, "SellCurrItem")) table.Register("SellCurrItem", LAG_PlayerPackage_SellCurrItem);
        if (IsMissing(table, "UseItem")) table.Register("UseItem", LAG_PlayerPackage_UseItem);
        if (IsMissing(table, "UseTulingzhuSetpos")) table.Register("UseTulingzhuSetpos", LAG_PlayerPackage_UseTulingzhuSetpos);
    }
}
