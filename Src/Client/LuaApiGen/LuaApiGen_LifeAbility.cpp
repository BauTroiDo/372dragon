




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_LifeAbility_Baoshiyi_Gem(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Baoshiyi_Gem", "n"); }

        int LAG_LifeAbility_Baoshiyi_GetGemType(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Baoshiyi_GetGemType", "n"); }

        int LAG_LifeAbility_Baoshiyi_SetGemByIndex(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Baoshiyi_SetGemByIndex", "b"); }

        int LAG_LifeAbility_Baoshiyi_Update(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Baoshiyi_Update", "b"); }

        int LAG_LifeAbility_CanEquipDiaowen_Enchase(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "CanEquipDiaowen_Enchase", "n"); }

        int LAG_LifeAbility_CanEquipDiaowen_JinJie(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "CanEquipDiaowen_JinJie", "n"); }

        int LAG_LifeAbility_CanEquipDiaowen_JinJieShengJi(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "CanEquipDiaowen_JinJieShengJi", "n"); }

        int LAG_LifeAbility_Can_Diaowen(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Can_Diaowen", "n"); }

        int LAG_LifeAbility_CheckDwAndEquipPoint(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "CheckDwAndEquipPoint", "n"); }

        int LAG_LifeAbility_ClearComposeItems(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "ClearComposeItems", ""); }

        int LAG_LifeAbility_ClearSlotFour(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "ClearSlotFour", ""); }

        int LAG_LifeAbility_ClosePetEquipEnhanceMsgBox(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "ClosePetEquipEnhanceMsgBox", ""); }

        int LAG_LifeAbility_ClosePetEquipReIdentifyMsgBox(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "ClosePetEquipReIdentifyMsgBox", ""); }

        int LAG_LifeAbility_CloseReIdentifyMsgBox(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "CloseReIdentifyMsgBox", ""); }

        int LAG_LifeAbility_CloseStrengthMsgBox(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "CloseStrengthMsgBox", ""); }

        int LAG_LifeAbility_ConfirmDiaowenHecheng(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "ConfirmDiaowenHecheng", "n"); }

        int LAG_LifeAbility_ConfirmDiaowenQianghua(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "ConfirmDiaowenQianghua", "n"); }

        int LAG_LifeAbility_ConfirmDiaowenShike(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "ConfirmDiaowenShike", "n"); }


        int LAG_LifeAbility_Do_Displace(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Do_Displace", ""); }


        int LAG_LifeAbility_Do_Enchase_Four(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Do_Enchase_Four", ""); }


        int LAG_LifeAbility_Do_SeparateGem(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Do_SeparateGem", ""); }

        int LAG_LifeAbility_Enchase_CloseMsgBox(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Enchase_CloseMsgBox", ""); }

        int LAG_LifeAbility_Enchase_Confirm(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Enchase_Confirm", ""); }

        int LAG_LifeAbility_Enchase_Four_Confirm(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Enchase_Four_Confirm", ""); }

        int LAG_LifeAbility_GetDWAttrbyDWID(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetDWAttrbyDWID", "n"); }

        int LAG_LifeAbility_GetDiaowenId(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetDiaowenId", "nnn"); }

        int LAG_LifeAbility_GetDiaowenJinJieAttrAdd(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetDiaowenJinJieAttrAdd", "n"); }

        int LAG_LifeAbility_GetDiaowenJinJieHuiTuiGotInfo(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetDiaowenJinJieHuiTuiGotInfo", "nn"); }

        int LAG_LifeAbility_GetDiaowenJinJieItemTexingIndex(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetDiaowenJinJieItemTexingIndex", "n"); }

        int LAG_LifeAbility_GetDiaowenJinJieLevel(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetDiaowenJinJieLevel", "n"); }

        int LAG_LifeAbility_GetDiaowenJinJieShengJiMaxLevel(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetDiaowenJinJieShengJiMaxLevel", "n"); }

        int LAG_LifeAbility_GetDiaowenJinJieShengJiNeedJCSNum(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetDiaowenJinJieShengJiNeedJCSNum", "nn"); }

        int LAG_LifeAbility_GetDiaowenJinJieTeXingByID(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetDiaowenJinJieTeXingByID", "nnn"); }

        int LAG_LifeAbility_GetDiaowenJinJieTeXingByIdx(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetDiaowenJinJieTeXingByIdx", "nnn"); }

        int LAG_LifeAbility_GetDiaowenJinJieTeXingHaveNum(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetDiaowenJinJieTeXingHaveNum", "n"); }

        int LAG_LifeAbility_GetDiaowenJinJieTeXingMaxLevel(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetDiaowenJinJieTeXingMaxLevel", "n"); }

        int LAG_LifeAbility_GetDiaowenJinJieTeXingShengJiRequiredCount(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetDiaowenJinJieTeXingShengJiRequiredCount", "nnn"); }

        int LAG_LifeAbility_GetDiaowenJinJieTeXingTotalNum(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetDiaowenJinJieTeXingTotalNum", "n"); }

        int LAG_LifeAbility_GetDiaowenJinJieTeXingValid(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetDiaowenJinJieTeXingValid", "n"); }

        int LAG_LifeAbility_GetDiaowenTeXingAddInfo(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetDiaowenTeXingAddInfo", "nn"); }

        int LAG_LifeAbility_GetDiaowenTeXingAddMax(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetDiaowenTeXingAddMax", "nn"); }

        int LAG_LifeAbility_GetDiaowenTeXingDescInfo(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetDiaowenTeXingDescInfo", "ssssn"); }

        int LAG_LifeAbility_GetEquipDWCurExp(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetEquipDWCurExp", "nn"); }

        int LAG_LifeAbility_GetEquipDiaowen_AttrName(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetEquipDiaowen_AttrName", "ss"); }

        int LAG_LifeAbility_GetEquipDiaowen_Name(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetEquipDiaowen_Name", "ss"); }

        int LAG_LifeAbility_GetEquip_GemID(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetEquip_GemID", "n"); }

        int LAG_LifeAbility_GetEquip_GemLevel(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetEquip_GemLevel", "s"); }

        int LAG_LifeAbility_GetEquip_GemTypeSubindex(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetEquip_GemTypeSubindex", "nn"); }

        int LAG_LifeAbility_GetEquip_HoleCount(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetEquip_HoleCount", "n"); }

        int LAG_LifeAbility_GetEquitDiaowenID(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetEquitDiaowenID", "nn"); }

        int LAG_LifeAbility_GetGemNamebyID(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetGemNamebyID", "s"); }

        int LAG_LifeAbility_GetItem_Class(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetItem_Class", "n"); }

        int LAG_LifeAbility_GetLifeAbility_LimitExp(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetLifeAbility_LimitExp", "n"); }

        int LAG_LifeAbility_GetPrescr_Consume_ContriAttr(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetPrescr_Consume_ContriAttr", "n"); }

        int LAG_LifeAbility_GetPrescr_Consume_ShengongAttr(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetPrescr_Consume_ShengongAttr", "n"); }

        int LAG_LifeAbility_GetPrescr_Consume_Vigor_Energy(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetPrescr_Consume_Vigor_Energy", "nn"); }

        int LAG_LifeAbility_GetPrescr_HelpMaterialIds(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetPrescr_HelpMaterialIds", "t"); }

        int LAG_LifeAbility_GetPrescr_HelpPrescrCount(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetPrescr_HelpPrescrCount", "nnn"); }

        int LAG_LifeAbility_GetPrescr_HelpResultId(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetPrescr_HelpResultId", "n"); }

        int LAG_LifeAbility_GetPrescr_IsStudy(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetPrescr_IsStudy", "n"); }

        int LAG_LifeAbility_GetPrescr_Item_IsNeedSpecial(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetPrescr_Item_IsNeedSpecial", "n"); }

        int LAG_LifeAbility_GetPrescr_Material_Consume(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetPrescr_Material_Consume", "n"); }

        int LAG_LifeAbility_GetPrescr_Material_Tooltip(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetPrescr_Material_Tooltip", "sss"); }

        int LAG_LifeAbility_GetPrescription_Kind(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetPrescription_Kind", "s"); }

        int LAG_LifeAbility_GetQuestUI_Demand(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetQuestUI_Demand", "n"); }

        int LAG_LifeAbility_GetQuestUI_Reward(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetQuestUI_Reward", "n"); }

        int LAG_LifeAbility_GetReqMatforEquipDWLevelUp(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetReqMatforEquipDWLevelUp", "nn"); }

        int LAG_LifeAbility_GetSplitGem_Gem(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetSplitGem_Gem", "n"); }

        int LAG_LifeAbility_GetSplitGem_GemEx(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetSplitGem_GemEx", "n"); }

        int LAG_LifeAbility_GetWearedDiaoWenName(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "GetWearedDiaoWenName", "s"); }

        int LAG_LifeAbility_Get_Enhance_Cost(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Get_Enhance_Cost", "n"); }

        int LAG_LifeAbility_Get_Equip_CurStrengthLevel(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Get_Equip_CurStrengthLevel", "n"); }

        int LAG_LifeAbility_Get_Equip_Exterior(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Get_Equip_Exterior", "n"); }

        int LAG_LifeAbility_Get_Equip_Level(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Get_Equip_Level", "n"); }

        int LAG_LifeAbility_Get_Equip_Point(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Get_Equip_Point", "n"); }

        int LAG_LifeAbility_Get_Equip_Point_NoMsg(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Get_Equip_Point_NoMsg", "n"); }

        int LAG_LifeAbility_Get_Equip_StrengthLevel(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Get_Equip_StrengthLevel", "nn"); }

        int LAG_LifeAbility_Get_Equip_Validity(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Get_Equip_Validity", "n"); }

        int LAG_LifeAbility_Get_Equip_VisualID(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Get_Equip_VisualID", "n"); }

        int LAG_LifeAbility_Get_Gem_Level(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Get_Gem_Level", "n"); }

        int LAG_LifeAbility_Get_Item_Icon_Name(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Get_Item_Icon_Name", "s"); }

        int LAG_LifeAbility_Get_Item_Icon_NameByDataIndex(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Get_Item_Icon_NameByDataIndex", "s"); }

        int LAG_LifeAbility_Get_OtherPlayerEquip_VisualID(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Get_OtherPlayerEquip_VisualID", "n"); }

        int LAG_LifeAbility_Get_PetEquip_CurStrengthLevel(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Get_PetEquip_CurStrengthLevel", "n"); }

        int LAG_LifeAbility_Get_PetEquip_EnhanceLevel(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Get_PetEquip_EnhanceLevel", "nn"); }

        int LAG_LifeAbility_Get_PetEquip_Level(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Get_PetEquip_Level", "n"); }

        int LAG_LifeAbility_Get_PetEquip_Point(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Get_PetEquip_Point", "n"); }

        int LAG_LifeAbility_Get_Test_Prescr_Item(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Get_Test_Prescr_Item", "nn"); }

        int LAG_LifeAbility_Get_UserEquip_Current_Durability(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Get_UserEquip_Current_Durability", "n"); }

        int LAG_LifeAbility_Get_UserEquip_Maximum_Durability(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Get_UserEquip_Maximum_Durability", "n"); }

        int LAG_LifeAbility_Get_UserEquip_VisualID(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Get_UserEquip_VisualID", "n"); }

        int LAG_LifeAbility_IsDiaowenPic(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "IsDiaowenPic", "n"); }

        int LAG_LifeAbility_IsEquipHaveDiaowen(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "IsEquipHaveDiaowen", "n"); }

        int LAG_LifeAbility_IsIndentify(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "IsIndentify", "n"); }

        int LAG_LifeAbility_Is_PetEquip(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Is_PetEquip", "n"); }

        int LAG_LifeAbility_Is_SlotFour(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Is_SlotFour", "n"); }

        int LAG_LifeAbility_Lock_Packet_ItemByID(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Lock_Packet_ItemByID", ""); }

        int LAG_LifeAbility_LuaFnGetAbilityPrescrID(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "LuaFnGetAbilityPrescrID", "t"); }

        int LAG_LifeAbility_LuaFnGetEquipGemId(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "LuaFnGetEquipGemId", "n"); }

        int LAG_LifeAbility_LuaFnGetEquipGemType(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "LuaFnGetEquipGemType", "n"); }

        int LAG_LifeAbility_LuaFnGetPrescrDetailInfo(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "LuaFnGetPrescrDetailInfo", "s"); }

        int LAG_LifeAbility_Lua_GetGemComposeNotify(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Lua_GetGemComposeNotify", "n"); }

        int LAG_LifeAbility_Lua_SetGemComposeNotify(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Lua_SetGemComposeNotify", ""); }

        int LAG_LifeAbility_ShowSuperToolTip(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "ShowSuperToolTip", "n"); }

        int LAG_LifeAbility_SplitGem_Update(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "SplitGem_Update", "b"); }

        int LAG_LifeAbility_Stiletto_Preparation(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Stiletto_Preparation", "nnnn"); }

        int LAG_LifeAbility_Update_Equip_VisualID(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Update_Equip_VisualID", ""); }

        int LAG_LifeAbility_Wear_Equip_VisualID(LuaPlus::LuaState* state) { return Stub(state, "LifeAbility", "Wear_Equip_VisualID", ""); }
    }

    void Register_LifeAbility(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "Baoshiyi_Gem")) table.Register("Baoshiyi_Gem", LAG_LifeAbility_Baoshiyi_Gem);
        if (IsMissing(table, "Baoshiyi_GetGemType")) table.Register("Baoshiyi_GetGemType", LAG_LifeAbility_Baoshiyi_GetGemType);
        if (IsMissing(table, "Baoshiyi_SetGemByIndex")) table.Register("Baoshiyi_SetGemByIndex", LAG_LifeAbility_Baoshiyi_SetGemByIndex);
        if (IsMissing(table, "Baoshiyi_Update")) table.Register("Baoshiyi_Update", LAG_LifeAbility_Baoshiyi_Update);
        if (IsMissing(table, "CanEquipDiaowen_Enchase")) table.Register("CanEquipDiaowen_Enchase", LAG_LifeAbility_CanEquipDiaowen_Enchase);
        if (IsMissing(table, "CanEquipDiaowen_JinJie")) table.Register("CanEquipDiaowen_JinJie", LAG_LifeAbility_CanEquipDiaowen_JinJie);
        if (IsMissing(table, "CanEquipDiaowen_JinJieShengJi")) table.Register("CanEquipDiaowen_JinJieShengJi", LAG_LifeAbility_CanEquipDiaowen_JinJieShengJi);
        if (IsMissing(table, "Can_Diaowen")) table.Register("Can_Diaowen", LAG_LifeAbility_Can_Diaowen);
        if (IsMissing(table, "CheckDwAndEquipPoint")) table.Register("CheckDwAndEquipPoint", LAG_LifeAbility_CheckDwAndEquipPoint);
        if (IsMissing(table, "ClearComposeItems")) table.Register("ClearComposeItems", LAG_LifeAbility_ClearComposeItems);
        if (IsMissing(table, "ClearSlotFour")) table.Register("ClearSlotFour", LAG_LifeAbility_ClearSlotFour);
        if (IsMissing(table, "ClosePetEquipEnhanceMsgBox")) table.Register("ClosePetEquipEnhanceMsgBox", LAG_LifeAbility_ClosePetEquipEnhanceMsgBox);
        if (IsMissing(table, "ClosePetEquipReIdentifyMsgBox")) table.Register("ClosePetEquipReIdentifyMsgBox", LAG_LifeAbility_ClosePetEquipReIdentifyMsgBox);
        if (IsMissing(table, "CloseReIdentifyMsgBox")) table.Register("CloseReIdentifyMsgBox", LAG_LifeAbility_CloseReIdentifyMsgBox);
        if (IsMissing(table, "CloseStrengthMsgBox")) table.Register("CloseStrengthMsgBox", LAG_LifeAbility_CloseStrengthMsgBox);
        if (IsMissing(table, "ConfirmDiaowenHecheng")) table.Register("ConfirmDiaowenHecheng", LAG_LifeAbility_ConfirmDiaowenHecheng);
        if (IsMissing(table, "ConfirmDiaowenQianghua")) table.Register("ConfirmDiaowenQianghua", LAG_LifeAbility_ConfirmDiaowenQianghua);
        if (IsMissing(table, "ConfirmDiaowenShike")) table.Register("ConfirmDiaowenShike", LAG_LifeAbility_ConfirmDiaowenShike);
        if (IsMissing(table, "Do_Displace")) table.Register("Do_Displace", LAG_LifeAbility_Do_Displace);
        if (IsMissing(table, "Do_Enchase_Four")) table.Register("Do_Enchase_Four", LAG_LifeAbility_Do_Enchase_Four);
        if (IsMissing(table, "Do_SeparateGem")) table.Register("Do_SeparateGem", LAG_LifeAbility_Do_SeparateGem);
        if (IsMissing(table, "Enchase_CloseMsgBox")) table.Register("Enchase_CloseMsgBox", LAG_LifeAbility_Enchase_CloseMsgBox);
        if (IsMissing(table, "Enchase_Confirm")) table.Register("Enchase_Confirm", LAG_LifeAbility_Enchase_Confirm);
        if (IsMissing(table, "Enchase_Four_Confirm")) table.Register("Enchase_Four_Confirm", LAG_LifeAbility_Enchase_Four_Confirm);
        if (IsMissing(table, "GetDWAttrbyDWID")) table.Register("GetDWAttrbyDWID", LAG_LifeAbility_GetDWAttrbyDWID);
        if (IsMissing(table, "GetDiaowenId")) table.Register("GetDiaowenId", LAG_LifeAbility_GetDiaowenId);
        if (IsMissing(table, "GetDiaowenJinJieAttrAdd")) table.Register("GetDiaowenJinJieAttrAdd", LAG_LifeAbility_GetDiaowenJinJieAttrAdd);
        if (IsMissing(table, "GetDiaowenJinJieHuiTuiGotInfo")) table.Register("GetDiaowenJinJieHuiTuiGotInfo", LAG_LifeAbility_GetDiaowenJinJieHuiTuiGotInfo);
        if (IsMissing(table, "GetDiaowenJinJieItemTexingIndex")) table.Register("GetDiaowenJinJieItemTexingIndex", LAG_LifeAbility_GetDiaowenJinJieItemTexingIndex);
        if (IsMissing(table, "GetDiaowenJinJieLevel")) table.Register("GetDiaowenJinJieLevel", LAG_LifeAbility_GetDiaowenJinJieLevel);
        if (IsMissing(table, "GetDiaowenJinJieShengJiMaxLevel")) table.Register("GetDiaowenJinJieShengJiMaxLevel", LAG_LifeAbility_GetDiaowenJinJieShengJiMaxLevel);
        if (IsMissing(table, "GetDiaowenJinJieShengJiNeedJCSNum")) table.Register("GetDiaowenJinJieShengJiNeedJCSNum", LAG_LifeAbility_GetDiaowenJinJieShengJiNeedJCSNum);
        if (IsMissing(table, "GetDiaowenJinJieTeXingByID")) table.Register("GetDiaowenJinJieTeXingByID", LAG_LifeAbility_GetDiaowenJinJieTeXingByID);
        if (IsMissing(table, "GetDiaowenJinJieTeXingByIdx")) table.Register("GetDiaowenJinJieTeXingByIdx", LAG_LifeAbility_GetDiaowenJinJieTeXingByIdx);
        if (IsMissing(table, "GetDiaowenJinJieTeXingHaveNum")) table.Register("GetDiaowenJinJieTeXingHaveNum", LAG_LifeAbility_GetDiaowenJinJieTeXingHaveNum);
        if (IsMissing(table, "GetDiaowenJinJieTeXingMaxLevel")) table.Register("GetDiaowenJinJieTeXingMaxLevel", LAG_LifeAbility_GetDiaowenJinJieTeXingMaxLevel);
        if (IsMissing(table, "GetDiaowenJinJieTeXingShengJiRequiredCount")) table.Register("GetDiaowenJinJieTeXingShengJiRequiredCount", LAG_LifeAbility_GetDiaowenJinJieTeXingShengJiRequiredCount);
        if (IsMissing(table, "GetDiaowenJinJieTeXingTotalNum")) table.Register("GetDiaowenJinJieTeXingTotalNum", LAG_LifeAbility_GetDiaowenJinJieTeXingTotalNum);
        if (IsMissing(table, "GetDiaowenJinJieTeXingValid")) table.Register("GetDiaowenJinJieTeXingValid", LAG_LifeAbility_GetDiaowenJinJieTeXingValid);
        if (IsMissing(table, "GetDiaowenTeXingAddInfo")) table.Register("GetDiaowenTeXingAddInfo", LAG_LifeAbility_GetDiaowenTeXingAddInfo);
        if (IsMissing(table, "GetDiaowenTeXingAddMax")) table.Register("GetDiaowenTeXingAddMax", LAG_LifeAbility_GetDiaowenTeXingAddMax);
        if (IsMissing(table, "GetDiaowenTeXingDescInfo")) table.Register("GetDiaowenTeXingDescInfo", LAG_LifeAbility_GetDiaowenTeXingDescInfo);
        if (IsMissing(table, "GetEquipDWCurExp")) table.Register("GetEquipDWCurExp", LAG_LifeAbility_GetEquipDWCurExp);
        if (IsMissing(table, "GetEquipDiaowen_AttrName")) table.Register("GetEquipDiaowen_AttrName", LAG_LifeAbility_GetEquipDiaowen_AttrName);
        if (IsMissing(table, "GetEquipDiaowen_Name")) table.Register("GetEquipDiaowen_Name", LAG_LifeAbility_GetEquipDiaowen_Name);
        if (IsMissing(table, "GetEquip_GemID")) table.Register("GetEquip_GemID", LAG_LifeAbility_GetEquip_GemID);
        if (IsMissing(table, "GetEquip_GemLevel")) table.Register("GetEquip_GemLevel", LAG_LifeAbility_GetEquip_GemLevel);
        if (IsMissing(table, "GetEquip_GemTypeSubindex")) table.Register("GetEquip_GemTypeSubindex", LAG_LifeAbility_GetEquip_GemTypeSubindex);
        if (IsMissing(table, "GetEquip_HoleCount")) table.Register("GetEquip_HoleCount", LAG_LifeAbility_GetEquip_HoleCount);
        if (IsMissing(table, "GetEquitDiaowenID")) table.Register("GetEquitDiaowenID", LAG_LifeAbility_GetEquitDiaowenID);
        if (IsMissing(table, "GetGemNamebyID")) table.Register("GetGemNamebyID", LAG_LifeAbility_GetGemNamebyID);
        if (IsMissing(table, "GetItem_Class")) table.Register("GetItem_Class", LAG_LifeAbility_GetItem_Class);
        if (IsMissing(table, "GetLifeAbility_LimitExp")) table.Register("GetLifeAbility_LimitExp", LAG_LifeAbility_GetLifeAbility_LimitExp);
        if (IsMissing(table, "GetPrescr_Consume_ContriAttr")) table.Register("GetPrescr_Consume_ContriAttr", LAG_LifeAbility_GetPrescr_Consume_ContriAttr);
        if (IsMissing(table, "GetPrescr_Consume_ShengongAttr")) table.Register("GetPrescr_Consume_ShengongAttr", LAG_LifeAbility_GetPrescr_Consume_ShengongAttr);
        if (IsMissing(table, "GetPrescr_Consume_Vigor_Energy")) table.Register("GetPrescr_Consume_Vigor_Energy", LAG_LifeAbility_GetPrescr_Consume_Vigor_Energy);
        if (IsMissing(table, "GetPrescr_HelpMaterialIds")) table.Register("GetPrescr_HelpMaterialIds", LAG_LifeAbility_GetPrescr_HelpMaterialIds);
        if (IsMissing(table, "GetPrescr_HelpPrescrCount")) table.Register("GetPrescr_HelpPrescrCount", LAG_LifeAbility_GetPrescr_HelpPrescrCount);
        if (IsMissing(table, "GetPrescr_HelpResultId")) table.Register("GetPrescr_HelpResultId", LAG_LifeAbility_GetPrescr_HelpResultId);
        if (IsMissing(table, "GetPrescr_IsStudy")) table.Register("GetPrescr_IsStudy", LAG_LifeAbility_GetPrescr_IsStudy);
        if (IsMissing(table, "GetPrescr_Item_IsNeedSpecial")) table.Register("GetPrescr_Item_IsNeedSpecial", LAG_LifeAbility_GetPrescr_Item_IsNeedSpecial);
        if (IsMissing(table, "GetPrescr_Material_Consume")) table.Register("GetPrescr_Material_Consume", LAG_LifeAbility_GetPrescr_Material_Consume);
        if (IsMissing(table, "GetPrescr_Material_Tooltip")) table.Register("GetPrescr_Material_Tooltip", LAG_LifeAbility_GetPrescr_Material_Tooltip);
        if (IsMissing(table, "GetPrescription_Kind")) table.Register("GetPrescription_Kind", LAG_LifeAbility_GetPrescription_Kind);
        if (IsMissing(table, "GetQuestUI_Demand")) table.Register("GetQuestUI_Demand", LAG_LifeAbility_GetQuestUI_Demand);
        if (IsMissing(table, "GetQuestUI_Reward")) table.Register("GetQuestUI_Reward", LAG_LifeAbility_GetQuestUI_Reward);
        if (IsMissing(table, "GetReqMatforEquipDWLevelUp")) table.Register("GetReqMatforEquipDWLevelUp", LAG_LifeAbility_GetReqMatforEquipDWLevelUp);
        if (IsMissing(table, "GetSplitGem_Gem")) table.Register("GetSplitGem_Gem", LAG_LifeAbility_GetSplitGem_Gem);
        if (IsMissing(table, "GetSplitGem_GemEx")) table.Register("GetSplitGem_GemEx", LAG_LifeAbility_GetSplitGem_GemEx);
        if (IsMissing(table, "GetWearedDiaoWenName")) table.Register("GetWearedDiaoWenName", LAG_LifeAbility_GetWearedDiaoWenName);
        if (IsMissing(table, "Get_Enhance_Cost")) table.Register("Get_Enhance_Cost", LAG_LifeAbility_Get_Enhance_Cost);
        if (IsMissing(table, "Get_Equip_CurStrengthLevel")) table.Register("Get_Equip_CurStrengthLevel", LAG_LifeAbility_Get_Equip_CurStrengthLevel);
        if (IsMissing(table, "Get_Equip_Exterior")) table.Register("Get_Equip_Exterior", LAG_LifeAbility_Get_Equip_Exterior);
        if (IsMissing(table, "Get_Equip_Level")) table.Register("Get_Equip_Level", LAG_LifeAbility_Get_Equip_Level);
        if (IsMissing(table, "Get_Equip_Point")) table.Register("Get_Equip_Point", LAG_LifeAbility_Get_Equip_Point);
        if (IsMissing(table, "Get_Equip_Point_NoMsg")) table.Register("Get_Equip_Point_NoMsg", LAG_LifeAbility_Get_Equip_Point_NoMsg);
        if (IsMissing(table, "Get_Equip_StrengthLevel")) table.Register("Get_Equip_StrengthLevel", LAG_LifeAbility_Get_Equip_StrengthLevel);
        if (IsMissing(table, "Get_Equip_Validity")) table.Register("Get_Equip_Validity", LAG_LifeAbility_Get_Equip_Validity);
        if (IsMissing(table, "Get_Equip_VisualID")) table.Register("Get_Equip_VisualID", LAG_LifeAbility_Get_Equip_VisualID);
        if (IsMissing(table, "Get_Gem_Level")) table.Register("Get_Gem_Level", LAG_LifeAbility_Get_Gem_Level);
        if (IsMissing(table, "Get_Item_Icon_Name")) table.Register("Get_Item_Icon_Name", LAG_LifeAbility_Get_Item_Icon_Name);
        if (IsMissing(table, "Get_Item_Icon_NameByDataIndex")) table.Register("Get_Item_Icon_NameByDataIndex", LAG_LifeAbility_Get_Item_Icon_NameByDataIndex);
        if (IsMissing(table, "Get_OtherPlayerEquip_VisualID")) table.Register("Get_OtherPlayerEquip_VisualID", LAG_LifeAbility_Get_OtherPlayerEquip_VisualID);
        if (IsMissing(table, "Get_PetEquip_CurStrengthLevel")) table.Register("Get_PetEquip_CurStrengthLevel", LAG_LifeAbility_Get_PetEquip_CurStrengthLevel);
        if (IsMissing(table, "Get_PetEquip_EnhanceLevel")) table.Register("Get_PetEquip_EnhanceLevel", LAG_LifeAbility_Get_PetEquip_EnhanceLevel);
        if (IsMissing(table, "Get_PetEquip_Level")) table.Register("Get_PetEquip_Level", LAG_LifeAbility_Get_PetEquip_Level);
        if (IsMissing(table, "Get_PetEquip_Point")) table.Register("Get_PetEquip_Point", LAG_LifeAbility_Get_PetEquip_Point);
        if (IsMissing(table, "Get_Test_Prescr_Item")) table.Register("Get_Test_Prescr_Item", LAG_LifeAbility_Get_Test_Prescr_Item);
        if (IsMissing(table, "Get_UserEquip_Current_Durability")) table.Register("Get_UserEquip_Current_Durability", LAG_LifeAbility_Get_UserEquip_Current_Durability);
        if (IsMissing(table, "Get_UserEquip_Maximum_Durability")) table.Register("Get_UserEquip_Maximum_Durability", LAG_LifeAbility_Get_UserEquip_Maximum_Durability);
        if (IsMissing(table, "Get_UserEquip_VisualID")) table.Register("Get_UserEquip_VisualID", LAG_LifeAbility_Get_UserEquip_VisualID);
        if (IsMissing(table, "IsDiaowenPic")) table.Register("IsDiaowenPic", LAG_LifeAbility_IsDiaowenPic);
        if (IsMissing(table, "IsEquipHaveDiaowen")) table.Register("IsEquipHaveDiaowen", LAG_LifeAbility_IsEquipHaveDiaowen);
        if (IsMissing(table, "IsIndentify")) table.Register("IsIndentify", LAG_LifeAbility_IsIndentify);
        if (IsMissing(table, "Is_PetEquip")) table.Register("Is_PetEquip", LAG_LifeAbility_Is_PetEquip);
        if (IsMissing(table, "Is_SlotFour")) table.Register("Is_SlotFour", LAG_LifeAbility_Is_SlotFour);
        if (IsMissing(table, "Lock_Packet_ItemByID")) table.Register("Lock_Packet_ItemByID", LAG_LifeAbility_Lock_Packet_ItemByID);
        if (IsMissing(table, "LuaFnGetAbilityPrescrID")) table.Register("LuaFnGetAbilityPrescrID", LAG_LifeAbility_LuaFnGetAbilityPrescrID);
        if (IsMissing(table, "LuaFnGetEquipGemId")) table.Register("LuaFnGetEquipGemId", LAG_LifeAbility_LuaFnGetEquipGemId);
        if (IsMissing(table, "LuaFnGetEquipGemType")) table.Register("LuaFnGetEquipGemType", LAG_LifeAbility_LuaFnGetEquipGemType);
        if (IsMissing(table, "LuaFnGetPrescrDetailInfo")) table.Register("LuaFnGetPrescrDetailInfo", LAG_LifeAbility_LuaFnGetPrescrDetailInfo);
        if (IsMissing(table, "Lua_GetGemComposeNotify")) table.Register("Lua_GetGemComposeNotify", LAG_LifeAbility_Lua_GetGemComposeNotify);
        if (IsMissing(table, "Lua_SetGemComposeNotify")) table.Register("Lua_SetGemComposeNotify", LAG_LifeAbility_Lua_SetGemComposeNotify);
        if (IsMissing(table, "ShowSuperToolTip")) table.Register("ShowSuperToolTip", LAG_LifeAbility_ShowSuperToolTip);
        if (IsMissing(table, "SplitGem_Update")) table.Register("SplitGem_Update", LAG_LifeAbility_SplitGem_Update);
        if (IsMissing(table, "Stiletto_Preparation")) table.Register("Stiletto_Preparation", LAG_LifeAbility_Stiletto_Preparation);
        if (IsMissing(table, "Update_Equip_VisualID")) table.Register("Update_Equip_VisualID", LAG_LifeAbility_Update_Equip_VisualID);
        if (IsMissing(table, "Wear_Equip_VisualID")) table.Register("Wear_Equip_VisualID", LAG_LifeAbility_Wear_Equip_VisualID);
    }
}
