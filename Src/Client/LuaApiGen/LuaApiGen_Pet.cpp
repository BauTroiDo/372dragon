




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_Pet_CheckPetSkillStudyMoreMoneyMode(LuaPlus::LuaState* state) { return Stub(state, "Pet", "CheckPetSkillStudyMoreMoneyMode", "n"); }

        int LAG_Pet_CheckRClick(LuaPlus::LuaState* state) { return Stub(state, "Pet", "CheckRClick", ""); }

        int LAG_Pet_ClearSheliziPet(LuaPlus::LuaState* state) { return Stub(state, "Pet", "ClearSheliziPet", ""); }

        int LAG_Pet_ClosePetSkillStudyMsgBox(LuaPlus::LuaState* state) { return Stub(state, "Pet", "ClosePetSkillStudyMsgBox", ""); }

        int LAG_Pet_CloseSignalPetProCreate(LuaPlus::LuaState* state) { return Stub(state, "Pet", "CloseSignalPetProCreate", ""); }

        int LAG_Pet_CloseTeamPetProCreate(LuaPlus::LuaState* state) { return Stub(state, "Pet", "CloseTeamPetProCreate", ""); }


        int LAG_Pet_ConfirmPetProcreate(LuaPlus::LuaState* state) { return Stub(state, "Pet", "ConfirmPetProcreate", ""); }

        int LAG_Pet_ConfirmPetSkillStudy(LuaPlus::LuaState* state) { return Stub(state, "Pet", "ConfirmPetSkillStudy", ""); }

        int LAG_Pet_EnableHuanhua(LuaPlus::LuaState* state) { return Stub(state, "Pet", "EnableHuanhua", "n"); }

        int LAG_Pet_EnumPetSkillBarItem(LuaPlus::LuaState* state) { return Stub(state, "Pet", "EnumPetSkillBarItem", "o"); }

        int LAG_Pet_EnumTitleByIdx(LuaPlus::LuaState* state) { return Stub(state, "Pet", "EnumTitleByIdx", "s"); }

        int LAG_Pet_GetAIType_PetBank(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetAIType_PetBank", "n"); }

        int LAG_Pet_GetAttackTrait(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetAttackTrait", "ss"); }

        int LAG_Pet_GetCriticalAttack(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetCriticalAttack", "n"); }

        int LAG_Pet_GetCriticalDefence(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetCriticalDefence", "n"); }

        int LAG_Pet_GetCurrentSelectPet_PetBank(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetCurrentSelectPet_PetBank", "n"); }

        int LAG_Pet_GetCurrentTitle(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetCurrentTitle", "s"); }


        int LAG_Pet_GetData(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetData", "n"); }

        int LAG_Pet_GetDataId(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetDataId", "n"); }

        int LAG_Pet_GetDispatchTaskInfoByParamIndex(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetDispatchTaskInfoByParamIndex", "ssssssss"); }

        int LAG_Pet_GetFirstPetPosInBank_PetBank(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetFirstPetPosInBank_PetBank", "n"); }

        int LAG_Pet_GetFirstPetPosInPag(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetFirstPetPosInPag", "n"); }

        int LAG_Pet_GetFoodType(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetFoodType", "n"); }

        int LAG_Pet_GetGeneration(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetGeneration", "n"); }

        int LAG_Pet_GetGrowRate(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetGrowRate", "n"); }

        int LAG_Pet_GetGrowRate4(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetGrowRate4", "n"); }

        int LAG_Pet_GetHHChangeModel(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetHHChangeModel", "n"); }

        int LAG_Pet_GetHuanhuaMoney(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetHuanhuaMoney", "n"); }

        int LAG_Pet_GetIsDispatching(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetIsDispatching", "b"); }

        int LAG_Pet_GetIsPossession(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetIsPossession", "b"); }

        int LAG_Pet_GetLastProcreateLevel(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetLastProcreateLevel", "n"); }

        int LAG_Pet_GetLixing(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetLixing", "n"); }

        int LAG_Pet_GetMaxRage(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetMaxRage", "n"); }

        int LAG_Pet_GetPercent_Lx(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetPercent_Lx", "n"); }

        int LAG_Pet_GetPercent_LxUp(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetPercent_LxUp", "n"); }

        int LAG_Pet_GetPetDBCName(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetPetDBCName", "s"); }

        int LAG_Pet_GetPetDispatchInfo(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetPetDispatchInfo", "nn"); }

        int LAG_Pet_GetPetFightAction(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetPetFightAction", "o"); }

        int LAG_Pet_GetPetGrowLevel(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetPetGrowLevel", "n"); }

        int LAG_Pet_GetPetIndexByGUID(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetPetIndexByGUID", "n"); }

        int LAG_Pet_GetPetIndexByGUID_PetBank(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetPetIndexByGUID_PetBank", "n"); }

        int LAG_Pet_GetPetListCanJiHuoSkinPetNum(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetPetListCanJiHuoSkinPetNum", "n"); }

        int LAG_Pet_GetPetList_Appoint_PetBank(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetPetList_Appoint_PetBank", "snns"); }

        int LAG_Pet_GetPetLocation(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetPetLocation", "n"); }

        int LAG_Pet_GetPetPetMedicineHC(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetPetPetMedicineHC", "nn"); }

        int LAG_Pet_GetPetRelaxAction(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetPetRelaxAction", "o"); }

        int LAG_Pet_GetPetSkillBarItemCount(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetPetSkillBarItemCount", "n"); }

        int LAG_Pet_GetPetSkillLevelupInfo(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetPetSkillLevelupInfo", "nn"); }

        int LAG_Pet_GetPetSkinVarianceLevel(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetPetSkinVarianceLevel", "n"); }

        int LAG_Pet_GetPetType(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetPetType", "n"); }

        int LAG_Pet_GetPetTypeName(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetPetTypeName", ""); }

        int LAG_Pet_GetPetVarianceLevel(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetPetVarianceLevel", "n"); }

        int LAG_Pet_GetPet_Count_PetBank(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetPet_Count_PetBank", "n"); }

        int LAG_Pet_GetRage(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetRage", "n"); }

        int LAG_Pet_GetRate_LxUp(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetRate_LxUp", "n"); }

        int LAG_Pet_GetSavvy(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetSavvy", "n"); }

        int LAG_Pet_GetSkillIDbyIndex(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetSkillIDbyIndex", "n"); }

        int LAG_Pet_GetTakeLevel(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetTakeLevel", "n"); }

        int LAG_Pet_GetTitleNum(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetTitleNum", "n"); }

        int LAG_Pet_GetYuanbaoBuyState(LuaPlus::LuaState* state) { return Stub(state, "Pet", "GetYuanbaoBuyState", "n"); }


        int LAG_Pet_HandlePetMenuItemSelf(LuaPlus::LuaState* state) { return Stub(state, "Pet", "HandlePetMenuItemSelf", ""); }

        int LAG_Pet_HuanhuaOpenPetJian(LuaPlus::LuaState* state) { return Stub(state, "Pet", "HuanhuaOpenPetJian", ""); }

        int LAG_Pet_IsFreeing(LuaPlus::LuaState* state) { return Stub(state, "Pet", "IsFreeing", "n"); }

        int LAG_Pet_IsPetHaveEquip(LuaPlus::LuaState* state) { return Stub(state, "Pet", "IsPetHaveEquip", "n"); }


        int LAG_Pet_IsPresent_PetBank(LuaPlus::LuaState* state) { return Stub(state, "Pet", "IsPresent_PetBank", "n"); }

        int LAG_Pet_IsProtect(LuaPlus::LuaState* state) { return Stub(state, "Pet", "IsProtect", "n"); }


        int LAG_Pet_LockPetProcreate(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LockPetProcreate", ""); }


        int LAG_Pet_LuaFnClearPetSoulExValue(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnClearPetSoulExValue", ""); }

        int LAG_Pet_LuaFnClosePetSoulInfo(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnClosePetSoulInfo", ""); }

        int LAG_Pet_LuaFnElfShopBoughtCount(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnElfShopBoughtCount", "n"); }

        int LAG_Pet_LuaFnElfShopBuyConfirm(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnElfShopBuyConfirm", ""); }

        int LAG_Pet_LuaFnEnumOtherPetSoulSkillActionOnPet(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnEnumOtherPetSoulSkillActionOnPet", "o"); }

        int LAG_Pet_LuaFnEnumPetElfSkillId(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnEnumPetElfSkillId", "n"); }

        int LAG_Pet_LuaFnEnumPetSoulSkillActionByListID(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnEnumPetSoulSkillActionByListID", "o"); }

        int LAG_Pet_LuaFnEnumPetSoulSkillActionOnPet(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnEnumPetSoulSkillActionOnPet", "o"); }

        int LAG_Pet_LuaFnGetConAptitude_ps(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetConAptitude_ps", "n"); }

        int LAG_Pet_LuaFnGetDexAptitude_ps(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetDexAptitude_ps", "n"); }

        int LAG_Pet_LuaFnGetEquipPetSoulTableIndex(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetEquipPetSoulTableIndex", "n"); }

        int LAG_Pet_LuaFnGetIntAptitude_ps(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetIntAptitude_ps", "n"); }

        int LAG_Pet_LuaFnGetOtherPetDispatchStamina(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetOtherPetDispatchStamina", "n"); }

        int LAG_Pet_LuaFnGetOtherPetElfAttrSumInfo(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetOtherPetElfAttrSumInfo", "n"); }

        int LAG_Pet_LuaFnGetOtherPetElfLevel(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetOtherPetElfLevel", "n"); }

        int LAG_Pet_LuaFnGetOtherPetRage(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetOtherPetRage", "n"); }

        int LAG_Pet_LuaFnGetPetAttackType(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetAttackType", "n"); }

        int LAG_Pet_LuaFnGetPetDispatchStamina(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetDispatchStamina", "n"); }

        int LAG_Pet_LuaFnGetPetElfAttr(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetElfAttr", "nn"); }

        int LAG_Pet_LuaFnGetPetElfAttrSumInfo(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetElfAttrSumInfo", "n"); }

        int LAG_Pet_LuaFnGetPetElfExp(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetElfExp", "n"); }

        int LAG_Pet_LuaFnGetPetElfItem(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetElfItem", "n"); }

        int LAG_Pet_LuaFnGetPetElfLevel(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetElfLevel", "n"); }

        int LAG_Pet_LuaFnGetPetElfLevelKeepNeedItem(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetElfLevelKeepNeedItem", ""); }

        int LAG_Pet_LuaFnGetPetElfLevelNeedMoney(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetElfLevelNeedMoney", "n"); }

        int LAG_Pet_LuaFnGetPetElfLevelNeedQual(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetElfLevelNeedQual", "n"); }

        int LAG_Pet_LuaFnGetPetElfLevelTPNeedCount(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetElfLevelTPNeedCount", "n"); }

        int LAG_Pet_LuaFnGetPetElfLevelTPNeedPetLingXing(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetElfLevelTPNeedPetLingXing", "n"); }

        int LAG_Pet_LuaFnGetPetElfLevelTPOdds(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetElfLevelTPOdds", "n"); }

        int LAG_Pet_LuaFnGetPetElfLevelUpAttr(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetElfLevelUpAttr", "nn"); }

        int LAG_Pet_LuaFnGetPetElfNeedExpItemCount(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetElfNeedExpItemCount", "n"); }

        int LAG_Pet_LuaFnGetPetElfProtectNeedItem(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetElfProtectNeedItem", ""); }

        int LAG_Pet_LuaFnGetPetElfSkill(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetElfSkill", "n"); }

        int LAG_Pet_LuaFnGetPetElfType(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetElfType", "n"); }

        int LAG_Pet_LuaFnGetPetSoulData(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetSoulData", "snnn"); }

        int LAG_Pet_LuaFnGetPetSoulDataByListID(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetSoulDataByListID", "snnns"); }

        int LAG_Pet_LuaFnGetPetSoulDataOnOtherPet(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetSoulDataOnOtherPet", "nnsss"); }

        int LAG_Pet_LuaFnGetPetSoulDataOnPet(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetSoulDataOnPet", "nnsss"); }

        int LAG_Pet_LuaFnGetPetSoulExDesc(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetSoulExDesc", "s"); }

        int LAG_Pet_LuaFnGetPetSoulExtensionQual(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetSoulExtensionQual", "n"); }

        int LAG_Pet_LuaFnGetPetSoulHandbookMaxCount(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetSoulHandbookMaxCount", "n"); }

        int LAG_Pet_LuaFnGetPetSoulLeveldownCost(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetSoulLeveldownCost", "nnn"); }

        int LAG_Pet_LuaFnGetPetSoulLevelupCost(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetSoulLevelupCost", "nn"); }

        int LAG_Pet_LuaFnGetPetSoulLevelupData(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetSoulLevelupData", "nnnnn"); }

        int LAG_Pet_LuaFnGetPetSoulMaxLife(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetSoulMaxLife", "n"); }

        int LAG_Pet_LuaFnGetPetSoulPerfectExCount(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetSoulPerfectExCount", "n"); }

        int LAG_Pet_LuaFnGetPetSoulPieceInfo(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetSoulPieceInfo", ""); }

        int LAG_Pet_LuaFnGetPetSoulPossSkillInfo(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetSoulPossSkillInfo", "sssss"); }

        int LAG_Pet_LuaFnGetPetSoulPossSkillInfo_Handbook(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetSoulPossSkillInfo_Handbook", "ssss"); }

        int LAG_Pet_LuaFnGetPetSoulSkillNameOnPet(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetSoulSkillNameOnPet", "s"); }

        int LAG_Pet_LuaFnGetPetSoulSwallowData(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPetSoulSwallowData", ""); }

        int LAG_Pet_LuaFnGetPossessionPetIndex(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetPossessionPetIndex", "n"); }

        int LAG_Pet_LuaFnGetSprAptitude_ps(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetSprAptitude_ps", "n"); }

        int LAG_Pet_LuaFnGetStrAptitude_ps(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnGetStrAptitude_ps", "n"); }

        int LAG_Pet_LuaFnInitPetSoulHandbookList(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnInitPetSoulHandbookList", ""); }

        int LAG_Pet_LuaFnIsOtherPetElfActived(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnIsOtherPetElfActived", "n"); }

        int LAG_Pet_LuaFnIsOtherPetElfDefault(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnIsOtherPetElfDefault", "n"); }

        int LAG_Pet_LuaFnIsOtherPetEquipPetSoul(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnIsOtherPetEquipPetSoul", "n"); }

        int LAG_Pet_LuaFnIsPetElfActived(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnIsPetElfActived", "n"); }

        int LAG_Pet_LuaFnIsPetElfDefault(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnIsPetElfDefault", "n"); }

        int LAG_Pet_LuaFnIsPetEquipPetSoul(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnIsPetEquipPetSoul", "n"); }

        int LAG_Pet_LuaFnIsPetSoul(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnIsPetSoul", "n"); }

        int LAG_Pet_LuaFnIsPetSoulSkillPassiveOnPet(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnIsPetSoulSkillPassiveOnPet", "n"); }

        int LAG_Pet_LuaFnIsShowPetSoulModel(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnIsShowPetSoulModel", "n"); }

        int LAG_Pet_LuaFnOpenPetElfBook(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnOpenPetElfBook", ""); }

        int LAG_Pet_LuaFnOtherGetConAptitude_ps(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnOtherGetConAptitude_ps", "n"); }

        int LAG_Pet_LuaFnOtherGetDexAptitude_ps(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnOtherGetDexAptitude_ps", "n"); }

        int LAG_Pet_LuaFnOtherGetIntAptitude_ps(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnOtherGetIntAptitude_ps", "n"); }

        int LAG_Pet_LuaFnOtherGetSprAptitude_ps(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnOtherGetSprAptitude_ps", "n"); }

        int LAG_Pet_LuaFnOtherGetStrAptitude_ps(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnOtherGetStrAptitude_ps", "n"); }

        int LAG_Pet_LuaFnPetElfSkillDesc(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnPetElfSkillDesc", "s"); }

        int LAG_Pet_LuaFnPetElfSkillMaxNum(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnPetElfSkillMaxNum", "n"); }

        int LAG_Pet_LuaFnPetElfSkillName(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnPetElfSkillName", "s"); }

        int LAG_Pet_LuaFnPetElfSkillUseType(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnPetElfSkillUseType", "n"); }


        int LAG_Pet_LuaFnSavePetSoulExValue(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnSavePetSoulExValue", ""); }

        int LAG_Pet_LuaFnSelectPetJL(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnSelectPetJL", ""); }

        int LAG_Pet_LuaFnSelectPetKW(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnSelectPetKW", ""); }

        int LAG_Pet_LuaFnSelectPetKWTS(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnSelectPetKWTS", ""); }

        int LAG_Pet_LuaFnSendKWTSPetListState(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnSendKWTSPetListState", ""); }

        int LAG_Pet_LuaFnShowOtherPetSoulPossSkillInfo(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnShowOtherPetSoulPossSkillInfo", ""); }

        int LAG_Pet_LuaFnShowPetListJL(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnShowPetListJL", ""); }

        int LAG_Pet_LuaFnShowPetListKW(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnShowPetListKW", ""); }

        int LAG_Pet_LuaFnShowPetListKWTS(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnShowPetListKWTS", ""); }

        int LAG_Pet_LuaFnShowPetSoulInfo(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnShowPetSoulInfo", ""); }

        int LAG_Pet_LuaFnShowPetSoulPossSkillInfo(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnShowPetSoulPossSkillInfo", ""); }

        int LAG_Pet_LuaFnShowPetSoulPossSkillInfo_Handbook(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnShowPetSoulPossSkillInfo_Handbook", ""); }


        int LAG_Pet_LuaFnSwitchShowPetSoulModel(LuaPlus::LuaState* state) { return Stub(state, "Pet", "LuaFnSwitchShowPetSoulModel", ""); }

        int LAG_Pet_Lua_EnumPetDispatchList(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_EnumPetDispatchList", "n"); }

        int LAG_Pet_Lua_EnumPetDispatchMengHuiRewardItem(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_EnumPetDispatchMengHuiRewardItem", "n"); }

        int LAG_Pet_Lua_EnumPetDispatchQueue(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_EnumPetDispatchQueue", "nn"); }

        int LAG_Pet_Lua_EnumPetDispatchRewardInfo(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_EnumPetDispatchRewardInfo", "n"); }

        int LAG_Pet_Lua_EnumPetDispatchTableItem(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_EnumPetDispatchTableItem", "n"); }


        int LAG_Pet_Lua_FeedPetAddTili(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_FeedPetAddTili", ""); }

        int LAG_Pet_Lua_FilterPetDispatchList(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_FilterPetDispatchList", "n"); }

        int LAG_Pet_Lua_GetCooldownRemainTime(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_GetCooldownRemainTime", "n"); }

        int LAG_Pet_Lua_GetPetDispatchFuBenNum(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_GetPetDispatchFuBenNum", "nn"); }

        int LAG_Pet_Lua_GetPetDispatchIndexFromList(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_GetPetDispatchIndexFromList", "n"); }

        int LAG_Pet_Lua_GetPetDispatchListCount(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_GetPetDispatchListCount", "n"); }


        int LAG_Pet_Lua_GetPetDispatchReward(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_GetPetDispatchReward", ""); }

        int LAG_Pet_Lua_GetPetDispatchRewardItemRate(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_GetPetDispatchRewardItemRate", "n"); }

        int LAG_Pet_Lua_GetPetDispatchTypeCount(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_GetPetDispatchTypeCount", "n"); }

        int LAG_Pet_Lua_GetPetExteriorAttackTrait(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_GetPetExteriorAttackTrait", "n"); }

        int LAG_Pet_Lua_GetPetExteriorChangeData(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_GetPetExteriorChangeData", "nn"); }

        int LAG_Pet_Lua_GetPetExteriorChangeDataByGuid(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_GetPetExteriorChangeDataByGuid", "n"); }

        int LAG_Pet_Lua_GetPetExteriorChangeDataByPetIdx(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_GetPetExteriorChangeDataByPetIdx", "n"); }

        int LAG_Pet_Lua_GetPetExteriorChangeDataTips(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_GetPetExteriorChangeDataTips", "n"); }

        int LAG_Pet_Lua_GetPetExteriorGainFlagByPetIdx(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_GetPetExteriorGainFlagByPetIdx", "n"); }

        int LAG_Pet_Lua_GetPetExteriorIdByPetIdx(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_GetPetExteriorIdByPetIdx", "n"); }

        int LAG_Pet_Lua_GetPetExteriorInfo(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_GetPetExteriorInfo", "n"); }

        int LAG_Pet_Lua_GetPetExteriorInfoFromList(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_GetPetExteriorInfoFromList", "s"); }

        int LAG_Pet_Lua_GetPetExteriorInfoFromTBL(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_GetPetExteriorInfoFromTBL", "n"); }

        int LAG_Pet_Lua_GetPetExteriorListCount(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_GetPetExteriorListCount", "n"); }

        int LAG_Pet_Lua_GetPetExteriorNameByPetGuid(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_GetPetExteriorNameByPetGuid", "s"); }

        int LAG_Pet_Lua_GetPetExteriorNameByPetIdx(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_GetPetExteriorNameByPetIdx", "s"); }

        int LAG_Pet_Lua_InitPetExteriorList(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_InitPetExteriorList", ""); }

        int LAG_Pet_Lua_IsHavePetExteriorCollection(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_IsHavePetExteriorCollection", "n"); }


        int LAG_Pet_Lua_OneKeyUnEquip(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_OneKeyUnEquip", "n"); }


        int LAG_Pet_Lua_OpenPetExteriorUI(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_OpenPetExteriorUI", ""); }


        int LAG_Pet_Lua_RemovePetExteriorChangeDataTips(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_RemovePetExteriorChangeDataTips", "n"); }

        int LAG_Pet_Lua_SelectPetDispatchItem(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_SelectPetDispatchItem", "nnnn"); }

        int LAG_Pet_Lua_SortPetDispatchQueue(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_SortPetDispatchQueue", "n"); }

        int LAG_Pet_Lua_SortPetExteriorList(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_SortPetExteriorList", ""); }


        int LAG_Pet_Lua_StartPetDispatch(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_StartPetDispatch", ""); }


        int LAG_Pet_Lua_StopPetDispatch(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_StopPetDispatch", ""); }

        int LAG_Pet_Lua_UpdatePetExteriorGainModel(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_UpdatePetExteriorGainModel", ""); }

        int LAG_Pet_Lua_UpdatePetExteriorModel(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_UpdatePetExteriorModel", ""); }

        int LAG_Pet_Lua_UpdatePetExteriorModelByPetIdx(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Lua_UpdatePetExteriorModelByPetIdx", ""); }

        int LAG_Pet_NotifyPetDlgClosed(LuaPlus::LuaState* state) { return Stub(state, "Pet", "NotifyPetDlgClosed", ""); }

        int LAG_Pet_NotifySelChange(LuaPlus::LuaState* state) { return Stub(state, "Pet", "NotifySelChange", ""); }

        int LAG_Pet_OpenPetJianByZhenShouDanId(LuaPlus::LuaState* state) { return Stub(state, "Pet", "OpenPetJianByZhenShouDanId", ""); }

        int LAG_Pet_OpenPetJianByZhenShouDanIdFor77(LuaPlus::LuaState* state) { return Stub(state, "Pet", "OpenPetJianByZhenShouDanIdFor77", ""); }

        int LAG_Pet_OpenPetSkillStudyMsgBox(LuaPlus::LuaState* state) { return Stub(state, "Pet", "OpenPetSkillStudyMsgBox", ""); }

        int LAG_Pet_Other_GetAIType(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetAIType", "n"); }

        int LAG_Pet_Other_GetAttackCold(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetAttackCold", "n"); }

        int LAG_Pet_Other_GetAttackFire(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetAttackFire", "n"); }

        int LAG_Pet_Other_GetAttackLight(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetAttackLight", "n"); }

        int LAG_Pet_Other_GetAttackPoison(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetAttackPoison", "n"); }

        int LAG_Pet_Other_GetAttackTrait(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetAttackTrait", "ss"); }

        int LAG_Pet_Other_GetBasic(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetBasic", "n"); }

        int LAG_Pet_Other_GetConsort(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetConsort", "s"); }

        int LAG_Pet_Other_GetCriticalAttack(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetCriticalAttack", "n"); }

        int LAG_Pet_Other_GetCriticalDefence(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetCriticalDefence", "n"); }

        int LAG_Pet_Other_GetDefenceCold(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetDefenceCold", "n"); }

        int LAG_Pet_Other_GetDefenceFire(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetDefenceFire", "n"); }

        int LAG_Pet_Other_GetDefenceLight(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetDefenceLight", "n"); }

        int LAG_Pet_Other_GetDefencePoison(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetDefencePoison", "n"); }

        int LAG_Pet_Other_GetDex(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetDex", "n"); }

        int LAG_Pet_Other_GetDexAptitude(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetDexAptitude", "n"); }

        int LAG_Pet_Other_GetExp(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetExp", "nn"); }

        int LAG_Pet_Other_GetFoodType(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetFoodType", "n"); }

        int LAG_Pet_Other_GetGeneration(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetGeneration", "n"); }

        int LAG_Pet_Other_GetGoodsProtect_Pet(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetGoodsProtect_Pet", "n"); }

        int LAG_Pet_Other_GetGrowRate(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetGrowRate", "n"); }

        int LAG_Pet_Other_GetHP(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetHP", "n"); }

        int LAG_Pet_Other_GetHappy(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetHappy", "n"); }

        int LAG_Pet_Other_GetID(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetID", "ssn"); }

        int LAG_Pet_Other_GetInt(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetInt", "n"); }

        int LAG_Pet_Other_GetIntAptitude(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetIntAptitude", "n"); }

        int LAG_Pet_Other_GetLevel(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetLevel", "n"); }

        int LAG_Pet_Other_GetLixing(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetLixing", "n"); }

        int LAG_Pet_Other_GetLoyalgGade(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetLoyalgGade", "n"); }

        int LAG_Pet_Other_GetMP(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetMP", "n"); }

        int LAG_Pet_Other_GetMagicAttack(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetMagicAttack", "n"); }

        int LAG_Pet_Other_GetMagicRecovery(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetMagicRecovery", "n"); }

        int LAG_Pet_Other_GetMaxHP(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetMaxHP", "n"); }

        int LAG_Pet_Other_GetMaxLife(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetMaxLife", "n"); }

        int LAG_Pet_Other_GetMaxMP(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetMaxMP", "n"); }

        int LAG_Pet_Other_GetMiss(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetMiss", "n"); }

        int LAG_Pet_Other_GetName(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetName", "ss"); }

        int LAG_Pet_Other_GetNaturalLife(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetNaturalLife", "n"); }

        int LAG_Pet_Other_GetPF(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetPF", "n"); }

        int LAG_Pet_Other_GetPFAptitude(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetPFAptitude", "n"); }

        int LAG_Pet_Other_GetPercent_Lx(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetPercent_Lx", "n"); }

        int LAG_Pet_Other_GetPetExteriorChangeID(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetPetExteriorChangeID", "n"); }

        int LAG_Pet_Other_GetPetExteriorGainFlag(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetPetExteriorGainFlag", "n"); }

        int LAG_Pet_Other_GetPetExteriorId(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetPetExteriorId", "n"); }

        int LAG_Pet_Other_GetPetGrowLevel(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetPetGrowLevel", "n"); }

        int LAG_Pet_Other_GetPetIndexByGUID(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetPetIndexByGUID", "n"); }

        int LAG_Pet_Other_GetPetList_Appoint(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetPetList_Appoint", "ss"); }

        int LAG_Pet_Other_GetPetTypeName(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetPetTypeName", ""); }

        int LAG_Pet_Other_GetPet_Count(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetPet_Count", "n"); }

        int LAG_Pet_Other_GetPhysicsAttack(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetPhysicsAttack", "n"); }

        int LAG_Pet_Other_GetPhysicsRecovery(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetPhysicsRecovery", "n"); }

        int LAG_Pet_Other_GetPotential(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetPotential", "n"); }

        int LAG_Pet_Other_GetResistCold(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetResistCold", "n"); }

        int LAG_Pet_Other_GetResistFire(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetResistFire", "n"); }

        int LAG_Pet_Other_GetResistLight(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetResistLight", "n"); }

        int LAG_Pet_Other_GetResistPoison(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetResistPoison", "n"); }

        int LAG_Pet_Other_GetSavvy(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetSavvy", "n"); }

        int LAG_Pet_Other_GetSex(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetSex", "s"); }

        int LAG_Pet_Other_GetShootProbability(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetShootProbability", "n"); }

        int LAG_Pet_Other_GetSta(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetSta", "n"); }

        int LAG_Pet_Other_GetStaAptitude(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetStaAptitude", "n"); }

        int LAG_Pet_Other_GetStr(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetStr", "n"); }

        int LAG_Pet_Other_GetStrAptitude(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetStrAptitude", "n"); }

        int LAG_Pet_Other_GetTakeLevel(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetTakeLevel", "n"); }

        int LAG_Pet_Other_GetType(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_GetType", "n"); }

        int LAG_Pet_Other_IsPresent(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_IsPresent", "b"); }

        int LAG_Pet_Other_SetModel(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_SetModel", ""); }

        int LAG_Pet_Other_SetSelectedIdx(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Other_SetSelectedIdx", ""); }


        int LAG_Pet_PetAskChangeCurrentTitle(LuaPlus::LuaState* state) { return Stub(state, "Pet", "PetAskChangeCurrentTitle", ""); }

        int LAG_Pet_PetBank_PetListSelectChange(LuaPlus::LuaState* state) { return Stub(state, "Pet", "PetBank_PetListSelectChange", "o"); }

        int LAG_Pet_PetBank_WriteLog(LuaPlus::LuaState* state) { return Stub(state, "Pet", "PetBank_WriteLog", "o"); }

        int LAG_Pet_PetHHComfirm(LuaPlus::LuaState* state) { return Stub(state, "Pet", "PetHHComfirm", ""); }

        int LAG_Pet_PetOpenPetJian(LuaPlus::LuaState* state) { return Stub(state, "Pet", "PetOpenPetJian", ""); }

        int LAG_Pet_PetOpenTitleList(LuaPlus::LuaState* state) { return Stub(state, "Pet", "PetOpenTitleList", ""); }

        int LAG_Pet_PetProcreate_Clear(LuaPlus::LuaState* state) { return Stub(state, "Pet", "PetProcreate_Clear", ""); }

        int LAG_Pet_PetToShelizi(LuaPlus::LuaState* state) { return Stub(state, "Pet", "PetToShelizi", "n"); }


        int LAG_Pet_PossessionPet(LuaPlus::LuaState* state) { return Stub(state, "Pet", "PossessionPet", ""); }


        int LAG_Pet_RestorePet(LuaPlus::LuaState* state) { return Stub(state, "Pet", "RestorePet", ""); }


        int LAG_Pet_SavePetIntoBank_PetBank(LuaPlus::LuaState* state) { return Stub(state, "Pet", "SavePetIntoBank_PetBank", ""); }

        int LAG_Pet_SetCanFanzhiPet(LuaPlus::LuaState* state) { return Stub(state, "Pet", "SetCanFanzhiPet", ""); }

        int LAG_Pet_SetCurrentSelectPet_PetBank(LuaPlus::LuaState* state) { return Stub(state, "Pet", "SetCurrentSelectPet_PetBank", ""); }

        int LAG_Pet_SetDispatchModel(LuaPlus::LuaState* state) { return Stub(state, "Pet", "SetDispatchModel", ""); }

        int LAG_Pet_SetFightPetAsMainTarget(LuaPlus::LuaState* state) { return Stub(state, "Pet", "SetFightPetAsMainTarget", ""); }

        int LAG_Pet_SetModel_PetBank(LuaPlus::LuaState* state) { return Stub(state, "Pet", "SetModel_PetBank", ""); }


        int LAG_Pet_SetNullCurTitle(LuaPlus::LuaState* state) { return Stub(state, "Pet", "SetNullCurTitle", ""); }

        int LAG_Pet_SetPetLocation(LuaPlus::LuaState* state) { return Stub(state, "Pet", "SetPetLocation", ""); }

        int LAG_Pet_SetPetTujianJiHuoModel(LuaPlus::LuaState* state) { return Stub(state, "Pet", "SetPetTujianJiHuoModel", ""); }

        int LAG_Pet_SetProcreate_Other_Model(LuaPlus::LuaState* state) { return Stub(state, "Pet", "SetProcreate_Other_Model", ""); }

        int LAG_Pet_SetProcreate_Self_Model(LuaPlus::LuaState* state) { return Stub(state, "Pet", "SetProcreate_Self_Model", ""); }

        int LAG_Pet_SetPropagateModel(LuaPlus::LuaState* state) { return Stub(state, "Pet", "SetPropagateModel", ""); }

        int LAG_Pet_SetSelectPetIdx(LuaPlus::LuaState* state) { return Stub(state, "Pet", "SetSelectPetIdx", ""); }

        int LAG_Pet_SetSkillLevelupModel(LuaPlus::LuaState* state) { return Stub(state, "Pet", "SetSkillLevelupModel", ""); }

        int LAG_Pet_SetStudyNewSkillModel(LuaPlus::LuaState* state) { return Stub(state, "Pet", "SetStudyNewSkillModel", ""); }

        int LAG_Pet_SetSynModel(LuaPlus::LuaState* state) { return Stub(state, "Pet", "SetSynModel", ""); }

        int LAG_Pet_SetYuanbaoBuyState(LuaPlus::LuaState* state) { return Stub(state, "Pet", "SetYuanbaoBuyState", ""); }

        int LAG_Pet_SethuantongModel(LuaPlus::LuaState* state) { return Stub(state, "Pet", "SethuantongModel", ""); }


        int LAG_Pet_ShowBagSelectPet_PetBank(LuaPlus::LuaState* state) { return Stub(state, "Pet", "ShowBagSelectPet_PetBank", ""); }

        int LAG_Pet_ShowListTargetPet_PetBank(LuaPlus::LuaState* state) { return Stub(state, "Pet", "ShowListTargetPet_PetBank", ""); }


        int LAG_Pet_ShowTargetPet_PetBank(LuaPlus::LuaState* state) { return Stub(state, "Pet", "ShowTargetPet_PetBank", ""); }

        int LAG_Pet_Syn_Confirm(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Syn_Confirm", ""); }


        int LAG_Pet_Syn_Do(LuaPlus::LuaState* state) { return Stub(state, "Pet", "Syn_Do", ""); }

        int LAG_Pet_UpdatePetList(LuaPlus::LuaState* state) { return Stub(state, "Pet", "UpdatePetList", ""); }

        int LAG_Pet_ViewPetDetailData(LuaPlus::LuaState* state) { return Stub(state, "Pet", "ViewPetDetailData", ""); }
    }

    void Register_Pet(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "CheckPetSkillStudyMoreMoneyMode")) table.Register("CheckPetSkillStudyMoreMoneyMode", LAG_Pet_CheckPetSkillStudyMoreMoneyMode);
        if (IsMissing(table, "CheckRClick")) table.Register("CheckRClick", LAG_Pet_CheckRClick);
        if (IsMissing(table, "ClearSheliziPet")) table.Register("ClearSheliziPet", LAG_Pet_ClearSheliziPet);
        if (IsMissing(table, "ClosePetSkillStudyMsgBox")) table.Register("ClosePetSkillStudyMsgBox", LAG_Pet_ClosePetSkillStudyMsgBox);
        if (IsMissing(table, "CloseSignalPetProCreate")) table.Register("CloseSignalPetProCreate", LAG_Pet_CloseSignalPetProCreate);
        if (IsMissing(table, "CloseTeamPetProCreate")) table.Register("CloseTeamPetProCreate", LAG_Pet_CloseTeamPetProCreate);
        if (IsMissing(table, "ConfirmPetProcreate")) table.Register("ConfirmPetProcreate", LAG_Pet_ConfirmPetProcreate);
        if (IsMissing(table, "ConfirmPetSkillStudy")) table.Register("ConfirmPetSkillStudy", LAG_Pet_ConfirmPetSkillStudy);
        if (IsMissing(table, "EnableHuanhua")) table.Register("EnableHuanhua", LAG_Pet_EnableHuanhua);
        if (IsMissing(table, "EnumPetSkillBarItem")) table.Register("EnumPetSkillBarItem", LAG_Pet_EnumPetSkillBarItem);
        if (IsMissing(table, "EnumTitleByIdx")) table.Register("EnumTitleByIdx", LAG_Pet_EnumTitleByIdx);
        if (IsMissing(table, "GetAIType_PetBank")) table.Register("GetAIType_PetBank", LAG_Pet_GetAIType_PetBank);
        if (IsMissing(table, "GetAttackTrait")) table.Register("GetAttackTrait", LAG_Pet_GetAttackTrait);
        if (IsMissing(table, "GetCriticalAttack")) table.Register("GetCriticalAttack", LAG_Pet_GetCriticalAttack);
        if (IsMissing(table, "GetCriticalDefence")) table.Register("GetCriticalDefence", LAG_Pet_GetCriticalDefence);
        if (IsMissing(table, "GetCurrentSelectPet_PetBank")) table.Register("GetCurrentSelectPet_PetBank", LAG_Pet_GetCurrentSelectPet_PetBank);
        if (IsMissing(table, "GetCurrentTitle")) table.Register("GetCurrentTitle", LAG_Pet_GetCurrentTitle);
        if (IsMissing(table, "GetData")) table.Register("GetData", LAG_Pet_GetData);
        if (IsMissing(table, "GetDataId")) table.Register("GetDataId", LAG_Pet_GetDataId);
        if (IsMissing(table, "GetDispatchTaskInfoByParamIndex")) table.Register("GetDispatchTaskInfoByParamIndex", LAG_Pet_GetDispatchTaskInfoByParamIndex);
        if (IsMissing(table, "GetFirstPetPosInBank_PetBank")) table.Register("GetFirstPetPosInBank_PetBank", LAG_Pet_GetFirstPetPosInBank_PetBank);
        if (IsMissing(table, "GetFirstPetPosInPag")) table.Register("GetFirstPetPosInPag", LAG_Pet_GetFirstPetPosInPag);
        if (IsMissing(table, "GetFoodType")) table.Register("GetFoodType", LAG_Pet_GetFoodType);
        if (IsMissing(table, "GetGeneration")) table.Register("GetGeneration", LAG_Pet_GetGeneration);
        if (IsMissing(table, "GetGrowRate")) table.Register("GetGrowRate", LAG_Pet_GetGrowRate);
        if (IsMissing(table, "GetGrowRate4")) table.Register("GetGrowRate4", LAG_Pet_GetGrowRate4);
        if (IsMissing(table, "GetHHChangeModel")) table.Register("GetHHChangeModel", LAG_Pet_GetHHChangeModel);
        if (IsMissing(table, "GetHuanhuaMoney")) table.Register("GetHuanhuaMoney", LAG_Pet_GetHuanhuaMoney);
        if (IsMissing(table, "GetIsDispatching")) table.Register("GetIsDispatching", LAG_Pet_GetIsDispatching);
        if (IsMissing(table, "GetIsPossession")) table.Register("GetIsPossession", LAG_Pet_GetIsPossession);
        if (IsMissing(table, "GetLastProcreateLevel")) table.Register("GetLastProcreateLevel", LAG_Pet_GetLastProcreateLevel);
        if (IsMissing(table, "GetLixing")) table.Register("GetLixing", LAG_Pet_GetLixing);
        if (IsMissing(table, "GetMaxRage")) table.Register("GetMaxRage", LAG_Pet_GetMaxRage);
        if (IsMissing(table, "GetPercent_Lx")) table.Register("GetPercent_Lx", LAG_Pet_GetPercent_Lx);
        if (IsMissing(table, "GetPercent_LxUp")) table.Register("GetPercent_LxUp", LAG_Pet_GetPercent_LxUp);
        if (IsMissing(table, "GetPetDBCName")) table.Register("GetPetDBCName", LAG_Pet_GetPetDBCName);
        if (IsMissing(table, "GetPetDispatchInfo")) table.Register("GetPetDispatchInfo", LAG_Pet_GetPetDispatchInfo);
        if (IsMissing(table, "GetPetFightAction")) table.Register("GetPetFightAction", LAG_Pet_GetPetFightAction);
        if (IsMissing(table, "GetPetGrowLevel")) table.Register("GetPetGrowLevel", LAG_Pet_GetPetGrowLevel);
        if (IsMissing(table, "GetPetIndexByGUID")) table.Register("GetPetIndexByGUID", LAG_Pet_GetPetIndexByGUID);
        if (IsMissing(table, "GetPetIndexByGUID_PetBank")) table.Register("GetPetIndexByGUID_PetBank", LAG_Pet_GetPetIndexByGUID_PetBank);
        if (IsMissing(table, "GetPetListCanJiHuoSkinPetNum")) table.Register("GetPetListCanJiHuoSkinPetNum", LAG_Pet_GetPetListCanJiHuoSkinPetNum);
        if (IsMissing(table, "GetPetList_Appoint_PetBank")) table.Register("GetPetList_Appoint_PetBank", LAG_Pet_GetPetList_Appoint_PetBank);
        if (IsMissing(table, "GetPetLocation")) table.Register("GetPetLocation", LAG_Pet_GetPetLocation);
        if (IsMissing(table, "GetPetPetMedicineHC")) table.Register("GetPetPetMedicineHC", LAG_Pet_GetPetPetMedicineHC);
        if (IsMissing(table, "GetPetRelaxAction")) table.Register("GetPetRelaxAction", LAG_Pet_GetPetRelaxAction);
        if (IsMissing(table, "GetPetSkillBarItemCount")) table.Register("GetPetSkillBarItemCount", LAG_Pet_GetPetSkillBarItemCount);
        if (IsMissing(table, "GetPetSkillLevelupInfo")) table.Register("GetPetSkillLevelupInfo", LAG_Pet_GetPetSkillLevelupInfo);
        if (IsMissing(table, "GetPetSkinVarianceLevel")) table.Register("GetPetSkinVarianceLevel", LAG_Pet_GetPetSkinVarianceLevel);
        if (IsMissing(table, "GetPetType")) table.Register("GetPetType", LAG_Pet_GetPetType);
        if (IsMissing(table, "GetPetTypeName")) table.Register("GetPetTypeName", LAG_Pet_GetPetTypeName);
        if (IsMissing(table, "GetPetVarianceLevel")) table.Register("GetPetVarianceLevel", LAG_Pet_GetPetVarianceLevel);
        if (IsMissing(table, "GetPet_Count_PetBank")) table.Register("GetPet_Count_PetBank", LAG_Pet_GetPet_Count_PetBank);
        if (IsMissing(table, "GetRage")) table.Register("GetRage", LAG_Pet_GetRage);
        if (IsMissing(table, "GetRate_LxUp")) table.Register("GetRate_LxUp", LAG_Pet_GetRate_LxUp);
        if (IsMissing(table, "GetSavvy")) table.Register("GetSavvy", LAG_Pet_GetSavvy);
        if (IsMissing(table, "GetSkillIDbyIndex")) table.Register("GetSkillIDbyIndex", LAG_Pet_GetSkillIDbyIndex);
        if (IsMissing(table, "GetTakeLevel")) table.Register("GetTakeLevel", LAG_Pet_GetTakeLevel);
        if (IsMissing(table, "GetTitleNum")) table.Register("GetTitleNum", LAG_Pet_GetTitleNum);
        if (IsMissing(table, "GetYuanbaoBuyState")) table.Register("GetYuanbaoBuyState", LAG_Pet_GetYuanbaoBuyState);
        if (IsMissing(table, "HandlePetMenuItemSelf")) table.Register("HandlePetMenuItemSelf", LAG_Pet_HandlePetMenuItemSelf);
        if (IsMissing(table, "HuanhuaOpenPetJian")) table.Register("HuanhuaOpenPetJian", LAG_Pet_HuanhuaOpenPetJian);
        if (IsMissing(table, "IsFreeing")) table.Register("IsFreeing", LAG_Pet_IsFreeing);
        if (IsMissing(table, "IsPetHaveEquip")) table.Register("IsPetHaveEquip", LAG_Pet_IsPetHaveEquip);
        if (IsMissing(table, "IsPresent_PetBank")) table.Register("IsPresent_PetBank", LAG_Pet_IsPresent_PetBank);
        if (IsMissing(table, "IsProtect")) table.Register("IsProtect", LAG_Pet_IsProtect);
        if (IsMissing(table, "LockPetProcreate")) table.Register("LockPetProcreate", LAG_Pet_LockPetProcreate);
        if (IsMissing(table, "LuaFnClearPetSoulExValue")) table.Register("LuaFnClearPetSoulExValue", LAG_Pet_LuaFnClearPetSoulExValue);
        if (IsMissing(table, "LuaFnClosePetSoulInfo")) table.Register("LuaFnClosePetSoulInfo", LAG_Pet_LuaFnClosePetSoulInfo);
        if (IsMissing(table, "LuaFnElfShopBoughtCount")) table.Register("LuaFnElfShopBoughtCount", LAG_Pet_LuaFnElfShopBoughtCount);
        if (IsMissing(table, "LuaFnElfShopBuyConfirm")) table.Register("LuaFnElfShopBuyConfirm", LAG_Pet_LuaFnElfShopBuyConfirm);
        if (IsMissing(table, "LuaFnEnumOtherPetSoulSkillActionOnPet")) table.Register("LuaFnEnumOtherPetSoulSkillActionOnPet", LAG_Pet_LuaFnEnumOtherPetSoulSkillActionOnPet);
        if (IsMissing(table, "LuaFnEnumPetElfSkillId")) table.Register("LuaFnEnumPetElfSkillId", LAG_Pet_LuaFnEnumPetElfSkillId);
        if (IsMissing(table, "LuaFnEnumPetSoulSkillActionByListID")) table.Register("LuaFnEnumPetSoulSkillActionByListID", LAG_Pet_LuaFnEnumPetSoulSkillActionByListID);
        if (IsMissing(table, "LuaFnEnumPetSoulSkillActionOnPet")) table.Register("LuaFnEnumPetSoulSkillActionOnPet", LAG_Pet_LuaFnEnumPetSoulSkillActionOnPet);
        if (IsMissing(table, "LuaFnGetConAptitude_ps")) table.Register("LuaFnGetConAptitude_ps", LAG_Pet_LuaFnGetConAptitude_ps);
        if (IsMissing(table, "LuaFnGetDexAptitude_ps")) table.Register("LuaFnGetDexAptitude_ps", LAG_Pet_LuaFnGetDexAptitude_ps);
        if (IsMissing(table, "LuaFnGetEquipPetSoulTableIndex")) table.Register("LuaFnGetEquipPetSoulTableIndex", LAG_Pet_LuaFnGetEquipPetSoulTableIndex);
        if (IsMissing(table, "LuaFnGetIntAptitude_ps")) table.Register("LuaFnGetIntAptitude_ps", LAG_Pet_LuaFnGetIntAptitude_ps);
        if (IsMissing(table, "LuaFnGetOtherPetDispatchStamina")) table.Register("LuaFnGetOtherPetDispatchStamina", LAG_Pet_LuaFnGetOtherPetDispatchStamina);
        if (IsMissing(table, "LuaFnGetOtherPetElfAttrSumInfo")) table.Register("LuaFnGetOtherPetElfAttrSumInfo", LAG_Pet_LuaFnGetOtherPetElfAttrSumInfo);
        if (IsMissing(table, "LuaFnGetOtherPetElfLevel")) table.Register("LuaFnGetOtherPetElfLevel", LAG_Pet_LuaFnGetOtherPetElfLevel);
        if (IsMissing(table, "LuaFnGetOtherPetRage")) table.Register("LuaFnGetOtherPetRage", LAG_Pet_LuaFnGetOtherPetRage);
        if (IsMissing(table, "LuaFnGetPetAttackType")) table.Register("LuaFnGetPetAttackType", LAG_Pet_LuaFnGetPetAttackType);
        if (IsMissing(table, "LuaFnGetPetDispatchStamina")) table.Register("LuaFnGetPetDispatchStamina", LAG_Pet_LuaFnGetPetDispatchStamina);
        if (IsMissing(table, "LuaFnGetPetElfAttr")) table.Register("LuaFnGetPetElfAttr", LAG_Pet_LuaFnGetPetElfAttr);
        if (IsMissing(table, "LuaFnGetPetElfAttrSumInfo")) table.Register("LuaFnGetPetElfAttrSumInfo", LAG_Pet_LuaFnGetPetElfAttrSumInfo);
        if (IsMissing(table, "LuaFnGetPetElfExp")) table.Register("LuaFnGetPetElfExp", LAG_Pet_LuaFnGetPetElfExp);
        if (IsMissing(table, "LuaFnGetPetElfItem")) table.Register("LuaFnGetPetElfItem", LAG_Pet_LuaFnGetPetElfItem);
        if (IsMissing(table, "LuaFnGetPetElfLevel")) table.Register("LuaFnGetPetElfLevel", LAG_Pet_LuaFnGetPetElfLevel);
        if (IsMissing(table, "LuaFnGetPetElfLevelKeepNeedItem")) table.Register("LuaFnGetPetElfLevelKeepNeedItem", LAG_Pet_LuaFnGetPetElfLevelKeepNeedItem);
        if (IsMissing(table, "LuaFnGetPetElfLevelNeedMoney")) table.Register("LuaFnGetPetElfLevelNeedMoney", LAG_Pet_LuaFnGetPetElfLevelNeedMoney);
        if (IsMissing(table, "LuaFnGetPetElfLevelNeedQual")) table.Register("LuaFnGetPetElfLevelNeedQual", LAG_Pet_LuaFnGetPetElfLevelNeedQual);
        if (IsMissing(table, "LuaFnGetPetElfLevelTPNeedCount")) table.Register("LuaFnGetPetElfLevelTPNeedCount", LAG_Pet_LuaFnGetPetElfLevelTPNeedCount);
        if (IsMissing(table, "LuaFnGetPetElfLevelTPNeedPetLingXing")) table.Register("LuaFnGetPetElfLevelTPNeedPetLingXing", LAG_Pet_LuaFnGetPetElfLevelTPNeedPetLingXing);
        if (IsMissing(table, "LuaFnGetPetElfLevelTPOdds")) table.Register("LuaFnGetPetElfLevelTPOdds", LAG_Pet_LuaFnGetPetElfLevelTPOdds);
        if (IsMissing(table, "LuaFnGetPetElfLevelUpAttr")) table.Register("LuaFnGetPetElfLevelUpAttr", LAG_Pet_LuaFnGetPetElfLevelUpAttr);
        if (IsMissing(table, "LuaFnGetPetElfNeedExpItemCount")) table.Register("LuaFnGetPetElfNeedExpItemCount", LAG_Pet_LuaFnGetPetElfNeedExpItemCount);
        if (IsMissing(table, "LuaFnGetPetElfProtectNeedItem")) table.Register("LuaFnGetPetElfProtectNeedItem", LAG_Pet_LuaFnGetPetElfProtectNeedItem);
        if (IsMissing(table, "LuaFnGetPetElfSkill")) table.Register("LuaFnGetPetElfSkill", LAG_Pet_LuaFnGetPetElfSkill);
        if (IsMissing(table, "LuaFnGetPetElfType")) table.Register("LuaFnGetPetElfType", LAG_Pet_LuaFnGetPetElfType);
        if (IsMissing(table, "LuaFnGetPetSoulData")) table.Register("LuaFnGetPetSoulData", LAG_Pet_LuaFnGetPetSoulData);
        if (IsMissing(table, "LuaFnGetPetSoulDataByListID")) table.Register("LuaFnGetPetSoulDataByListID", LAG_Pet_LuaFnGetPetSoulDataByListID);
        if (IsMissing(table, "LuaFnGetPetSoulDataOnOtherPet")) table.Register("LuaFnGetPetSoulDataOnOtherPet", LAG_Pet_LuaFnGetPetSoulDataOnOtherPet);
        if (IsMissing(table, "LuaFnGetPetSoulDataOnPet")) table.Register("LuaFnGetPetSoulDataOnPet", LAG_Pet_LuaFnGetPetSoulDataOnPet);
        if (IsMissing(table, "LuaFnGetPetSoulExDesc")) table.Register("LuaFnGetPetSoulExDesc", LAG_Pet_LuaFnGetPetSoulExDesc);
        if (IsMissing(table, "LuaFnGetPetSoulExtensionQual")) table.Register("LuaFnGetPetSoulExtensionQual", LAG_Pet_LuaFnGetPetSoulExtensionQual);
        if (IsMissing(table, "LuaFnGetPetSoulHandbookMaxCount")) table.Register("LuaFnGetPetSoulHandbookMaxCount", LAG_Pet_LuaFnGetPetSoulHandbookMaxCount);
        if (IsMissing(table, "LuaFnGetPetSoulLeveldownCost")) table.Register("LuaFnGetPetSoulLeveldownCost", LAG_Pet_LuaFnGetPetSoulLeveldownCost);
        if (IsMissing(table, "LuaFnGetPetSoulLevelupCost")) table.Register("LuaFnGetPetSoulLevelupCost", LAG_Pet_LuaFnGetPetSoulLevelupCost);
        if (IsMissing(table, "LuaFnGetPetSoulLevelupData")) table.Register("LuaFnGetPetSoulLevelupData", LAG_Pet_LuaFnGetPetSoulLevelupData);
        if (IsMissing(table, "LuaFnGetPetSoulMaxLife")) table.Register("LuaFnGetPetSoulMaxLife", LAG_Pet_LuaFnGetPetSoulMaxLife);
        if (IsMissing(table, "LuaFnGetPetSoulPerfectExCount")) table.Register("LuaFnGetPetSoulPerfectExCount", LAG_Pet_LuaFnGetPetSoulPerfectExCount);
        if (IsMissing(table, "LuaFnGetPetSoulPieceInfo")) table.Register("LuaFnGetPetSoulPieceInfo", LAG_Pet_LuaFnGetPetSoulPieceInfo);
        if (IsMissing(table, "LuaFnGetPetSoulPossSkillInfo")) table.Register("LuaFnGetPetSoulPossSkillInfo", LAG_Pet_LuaFnGetPetSoulPossSkillInfo);
        if (IsMissing(table, "LuaFnGetPetSoulPossSkillInfo_Handbook")) table.Register("LuaFnGetPetSoulPossSkillInfo_Handbook", LAG_Pet_LuaFnGetPetSoulPossSkillInfo_Handbook);
        if (IsMissing(table, "LuaFnGetPetSoulSkillNameOnPet")) table.Register("LuaFnGetPetSoulSkillNameOnPet", LAG_Pet_LuaFnGetPetSoulSkillNameOnPet);
        if (IsMissing(table, "LuaFnGetPetSoulSwallowData")) table.Register("LuaFnGetPetSoulSwallowData", LAG_Pet_LuaFnGetPetSoulSwallowData);
        if (IsMissing(table, "LuaFnGetPossessionPetIndex")) table.Register("LuaFnGetPossessionPetIndex", LAG_Pet_LuaFnGetPossessionPetIndex);
        if (IsMissing(table, "LuaFnGetSprAptitude_ps")) table.Register("LuaFnGetSprAptitude_ps", LAG_Pet_LuaFnGetSprAptitude_ps);
        if (IsMissing(table, "LuaFnGetStrAptitude_ps")) table.Register("LuaFnGetStrAptitude_ps", LAG_Pet_LuaFnGetStrAptitude_ps);
        if (IsMissing(table, "LuaFnInitPetSoulHandbookList")) table.Register("LuaFnInitPetSoulHandbookList", LAG_Pet_LuaFnInitPetSoulHandbookList);
        if (IsMissing(table, "LuaFnIsOtherPetElfActived")) table.Register("LuaFnIsOtherPetElfActived", LAG_Pet_LuaFnIsOtherPetElfActived);
        if (IsMissing(table, "LuaFnIsOtherPetElfDefault")) table.Register("LuaFnIsOtherPetElfDefault", LAG_Pet_LuaFnIsOtherPetElfDefault);
        if (IsMissing(table, "LuaFnIsOtherPetEquipPetSoul")) table.Register("LuaFnIsOtherPetEquipPetSoul", LAG_Pet_LuaFnIsOtherPetEquipPetSoul);
        if (IsMissing(table, "LuaFnIsPetElfActived")) table.Register("LuaFnIsPetElfActived", LAG_Pet_LuaFnIsPetElfActived);
        if (IsMissing(table, "LuaFnIsPetElfDefault")) table.Register("LuaFnIsPetElfDefault", LAG_Pet_LuaFnIsPetElfDefault);
        if (IsMissing(table, "LuaFnIsPetEquipPetSoul")) table.Register("LuaFnIsPetEquipPetSoul", LAG_Pet_LuaFnIsPetEquipPetSoul);
        if (IsMissing(table, "LuaFnIsPetSoul")) table.Register("LuaFnIsPetSoul", LAG_Pet_LuaFnIsPetSoul);
        if (IsMissing(table, "LuaFnIsPetSoulSkillPassiveOnPet")) table.Register("LuaFnIsPetSoulSkillPassiveOnPet", LAG_Pet_LuaFnIsPetSoulSkillPassiveOnPet);
        if (IsMissing(table, "LuaFnIsShowPetSoulModel")) table.Register("LuaFnIsShowPetSoulModel", LAG_Pet_LuaFnIsShowPetSoulModel);
        if (IsMissing(table, "LuaFnOpenPetElfBook")) table.Register("LuaFnOpenPetElfBook", LAG_Pet_LuaFnOpenPetElfBook);
        if (IsMissing(table, "LuaFnOtherGetConAptitude_ps")) table.Register("LuaFnOtherGetConAptitude_ps", LAG_Pet_LuaFnOtherGetConAptitude_ps);
        if (IsMissing(table, "LuaFnOtherGetDexAptitude_ps")) table.Register("LuaFnOtherGetDexAptitude_ps", LAG_Pet_LuaFnOtherGetDexAptitude_ps);
        if (IsMissing(table, "LuaFnOtherGetIntAptitude_ps")) table.Register("LuaFnOtherGetIntAptitude_ps", LAG_Pet_LuaFnOtherGetIntAptitude_ps);
        if (IsMissing(table, "LuaFnOtherGetSprAptitude_ps")) table.Register("LuaFnOtherGetSprAptitude_ps", LAG_Pet_LuaFnOtherGetSprAptitude_ps);
        if (IsMissing(table, "LuaFnOtherGetStrAptitude_ps")) table.Register("LuaFnOtherGetStrAptitude_ps", LAG_Pet_LuaFnOtherGetStrAptitude_ps);
        if (IsMissing(table, "LuaFnPetElfSkillDesc")) table.Register("LuaFnPetElfSkillDesc", LAG_Pet_LuaFnPetElfSkillDesc);
        if (IsMissing(table, "LuaFnPetElfSkillMaxNum")) table.Register("LuaFnPetElfSkillMaxNum", LAG_Pet_LuaFnPetElfSkillMaxNum);
        if (IsMissing(table, "LuaFnPetElfSkillName")) table.Register("LuaFnPetElfSkillName", LAG_Pet_LuaFnPetElfSkillName);
        if (IsMissing(table, "LuaFnPetElfSkillUseType")) table.Register("LuaFnPetElfSkillUseType", LAG_Pet_LuaFnPetElfSkillUseType);
        if (IsMissing(table, "LuaFnSavePetSoulExValue")) table.Register("LuaFnSavePetSoulExValue", LAG_Pet_LuaFnSavePetSoulExValue);
        if (IsMissing(table, "LuaFnSelectPetJL")) table.Register("LuaFnSelectPetJL", LAG_Pet_LuaFnSelectPetJL);
        if (IsMissing(table, "LuaFnSelectPetKW")) table.Register("LuaFnSelectPetKW", LAG_Pet_LuaFnSelectPetKW);
        if (IsMissing(table, "LuaFnSelectPetKWTS")) table.Register("LuaFnSelectPetKWTS", LAG_Pet_LuaFnSelectPetKWTS);
        if (IsMissing(table, "LuaFnSendKWTSPetListState")) table.Register("LuaFnSendKWTSPetListState", LAG_Pet_LuaFnSendKWTSPetListState);
        if (IsMissing(table, "LuaFnShowOtherPetSoulPossSkillInfo")) table.Register("LuaFnShowOtherPetSoulPossSkillInfo", LAG_Pet_LuaFnShowOtherPetSoulPossSkillInfo);
        if (IsMissing(table, "LuaFnShowPetListJL")) table.Register("LuaFnShowPetListJL", LAG_Pet_LuaFnShowPetListJL);
        if (IsMissing(table, "LuaFnShowPetListKW")) table.Register("LuaFnShowPetListKW", LAG_Pet_LuaFnShowPetListKW);
        if (IsMissing(table, "LuaFnShowPetListKWTS")) table.Register("LuaFnShowPetListKWTS", LAG_Pet_LuaFnShowPetListKWTS);
        if (IsMissing(table, "LuaFnShowPetSoulInfo")) table.Register("LuaFnShowPetSoulInfo", LAG_Pet_LuaFnShowPetSoulInfo);
        if (IsMissing(table, "LuaFnShowPetSoulPossSkillInfo")) table.Register("LuaFnShowPetSoulPossSkillInfo", LAG_Pet_LuaFnShowPetSoulPossSkillInfo);
        if (IsMissing(table, "LuaFnShowPetSoulPossSkillInfo_Handbook")) table.Register("LuaFnShowPetSoulPossSkillInfo_Handbook", LAG_Pet_LuaFnShowPetSoulPossSkillInfo_Handbook);
        if (IsMissing(table, "LuaFnSwitchShowPetSoulModel")) table.Register("LuaFnSwitchShowPetSoulModel", LAG_Pet_LuaFnSwitchShowPetSoulModel);
        if (IsMissing(table, "Lua_EnumPetDispatchList")) table.Register("Lua_EnumPetDispatchList", LAG_Pet_Lua_EnumPetDispatchList);
        if (IsMissing(table, "Lua_EnumPetDispatchMengHuiRewardItem")) table.Register("Lua_EnumPetDispatchMengHuiRewardItem", LAG_Pet_Lua_EnumPetDispatchMengHuiRewardItem);
        if (IsMissing(table, "Lua_EnumPetDispatchQueue")) table.Register("Lua_EnumPetDispatchQueue", LAG_Pet_Lua_EnumPetDispatchQueue);
        if (IsMissing(table, "Lua_EnumPetDispatchRewardInfo")) table.Register("Lua_EnumPetDispatchRewardInfo", LAG_Pet_Lua_EnumPetDispatchRewardInfo);
        if (IsMissing(table, "Lua_EnumPetDispatchTableItem")) table.Register("Lua_EnumPetDispatchTableItem", LAG_Pet_Lua_EnumPetDispatchTableItem);
        if (IsMissing(table, "Lua_FeedPetAddTili")) table.Register("Lua_FeedPetAddTili", LAG_Pet_Lua_FeedPetAddTili);
        if (IsMissing(table, "Lua_FilterPetDispatchList")) table.Register("Lua_FilterPetDispatchList", LAG_Pet_Lua_FilterPetDispatchList);
        if (IsMissing(table, "Lua_GetCooldownRemainTime")) table.Register("Lua_GetCooldownRemainTime", LAG_Pet_Lua_GetCooldownRemainTime);
        if (IsMissing(table, "Lua_GetPetDispatchFuBenNum")) table.Register("Lua_GetPetDispatchFuBenNum", LAG_Pet_Lua_GetPetDispatchFuBenNum);
        if (IsMissing(table, "Lua_GetPetDispatchIndexFromList")) table.Register("Lua_GetPetDispatchIndexFromList", LAG_Pet_Lua_GetPetDispatchIndexFromList);
        if (IsMissing(table, "Lua_GetPetDispatchListCount")) table.Register("Lua_GetPetDispatchListCount", LAG_Pet_Lua_GetPetDispatchListCount);
        if (IsMissing(table, "Lua_GetPetDispatchReward")) table.Register("Lua_GetPetDispatchReward", LAG_Pet_Lua_GetPetDispatchReward);
        if (IsMissing(table, "Lua_GetPetDispatchRewardItemRate")) table.Register("Lua_GetPetDispatchRewardItemRate", LAG_Pet_Lua_GetPetDispatchRewardItemRate);
        if (IsMissing(table, "Lua_GetPetDispatchTypeCount")) table.Register("Lua_GetPetDispatchTypeCount", LAG_Pet_Lua_GetPetDispatchTypeCount);
        if (IsMissing(table, "Lua_GetPetExteriorAttackTrait")) table.Register("Lua_GetPetExteriorAttackTrait", LAG_Pet_Lua_GetPetExteriorAttackTrait);
        if (IsMissing(table, "Lua_GetPetExteriorChangeData")) table.Register("Lua_GetPetExteriorChangeData", LAG_Pet_Lua_GetPetExteriorChangeData);
        if (IsMissing(table, "Lua_GetPetExteriorChangeDataByGuid")) table.Register("Lua_GetPetExteriorChangeDataByGuid", LAG_Pet_Lua_GetPetExteriorChangeDataByGuid);
        if (IsMissing(table, "Lua_GetPetExteriorChangeDataByPetIdx")) table.Register("Lua_GetPetExteriorChangeDataByPetIdx", LAG_Pet_Lua_GetPetExteriorChangeDataByPetIdx);
        if (IsMissing(table, "Lua_GetPetExteriorChangeDataTips")) table.Register("Lua_GetPetExteriorChangeDataTips", LAG_Pet_Lua_GetPetExteriorChangeDataTips);
        if (IsMissing(table, "Lua_GetPetExteriorGainFlagByPetIdx")) table.Register("Lua_GetPetExteriorGainFlagByPetIdx", LAG_Pet_Lua_GetPetExteriorGainFlagByPetIdx);
        if (IsMissing(table, "Lua_GetPetExteriorIdByPetIdx")) table.Register("Lua_GetPetExteriorIdByPetIdx", LAG_Pet_Lua_GetPetExteriorIdByPetIdx);
        if (IsMissing(table, "Lua_GetPetExteriorInfo")) table.Register("Lua_GetPetExteriorInfo", LAG_Pet_Lua_GetPetExteriorInfo);
        if (IsMissing(table, "Lua_GetPetExteriorInfoFromList")) table.Register("Lua_GetPetExteriorInfoFromList", LAG_Pet_Lua_GetPetExteriorInfoFromList);
        if (IsMissing(table, "Lua_GetPetExteriorInfoFromTBL")) table.Register("Lua_GetPetExteriorInfoFromTBL", LAG_Pet_Lua_GetPetExteriorInfoFromTBL);
        if (IsMissing(table, "Lua_GetPetExteriorListCount")) table.Register("Lua_GetPetExteriorListCount", LAG_Pet_Lua_GetPetExteriorListCount);
        if (IsMissing(table, "Lua_GetPetExteriorNameByPetGuid")) table.Register("Lua_GetPetExteriorNameByPetGuid", LAG_Pet_Lua_GetPetExteriorNameByPetGuid);
        if (IsMissing(table, "Lua_GetPetExteriorNameByPetIdx")) table.Register("Lua_GetPetExteriorNameByPetIdx", LAG_Pet_Lua_GetPetExteriorNameByPetIdx);
        if (IsMissing(table, "Lua_InitPetExteriorList")) table.Register("Lua_InitPetExteriorList", LAG_Pet_Lua_InitPetExteriorList);
        if (IsMissing(table, "Lua_IsHavePetExteriorCollection")) table.Register("Lua_IsHavePetExteriorCollection", LAG_Pet_Lua_IsHavePetExteriorCollection);
        if (IsMissing(table, "Lua_OneKeyUnEquip")) table.Register("Lua_OneKeyUnEquip", LAG_Pet_Lua_OneKeyUnEquip);
        if (IsMissing(table, "Lua_OpenPetExteriorUI")) table.Register("Lua_OpenPetExteriorUI", LAG_Pet_Lua_OpenPetExteriorUI);
        if (IsMissing(table, "Lua_RemovePetExteriorChangeDataTips")) table.Register("Lua_RemovePetExteriorChangeDataTips", LAG_Pet_Lua_RemovePetExteriorChangeDataTips);
        if (IsMissing(table, "Lua_SelectPetDispatchItem")) table.Register("Lua_SelectPetDispatchItem", LAG_Pet_Lua_SelectPetDispatchItem);
        if (IsMissing(table, "Lua_SortPetDispatchQueue")) table.Register("Lua_SortPetDispatchQueue", LAG_Pet_Lua_SortPetDispatchQueue);
        if (IsMissing(table, "Lua_SortPetExteriorList")) table.Register("Lua_SortPetExteriorList", LAG_Pet_Lua_SortPetExteriorList);
        if (IsMissing(table, "Lua_StartPetDispatch")) table.Register("Lua_StartPetDispatch", LAG_Pet_Lua_StartPetDispatch);
        if (IsMissing(table, "Lua_StopPetDispatch")) table.Register("Lua_StopPetDispatch", LAG_Pet_Lua_StopPetDispatch);
        if (IsMissing(table, "Lua_UpdatePetExteriorGainModel")) table.Register("Lua_UpdatePetExteriorGainModel", LAG_Pet_Lua_UpdatePetExteriorGainModel);
        if (IsMissing(table, "Lua_UpdatePetExteriorModel")) table.Register("Lua_UpdatePetExteriorModel", LAG_Pet_Lua_UpdatePetExteriorModel);
        if (IsMissing(table, "Lua_UpdatePetExteriorModelByPetIdx")) table.Register("Lua_UpdatePetExteriorModelByPetIdx", LAG_Pet_Lua_UpdatePetExteriorModelByPetIdx);
        if (IsMissing(table, "NotifyPetDlgClosed")) table.Register("NotifyPetDlgClosed", LAG_Pet_NotifyPetDlgClosed);
        if (IsMissing(table, "NotifySelChange")) table.Register("NotifySelChange", LAG_Pet_NotifySelChange);
        if (IsMissing(table, "OpenPetJianByZhenShouDanId")) table.Register("OpenPetJianByZhenShouDanId", LAG_Pet_OpenPetJianByZhenShouDanId);
        if (IsMissing(table, "OpenPetJianByZhenShouDanIdFor77")) table.Register("OpenPetJianByZhenShouDanIdFor77", LAG_Pet_OpenPetJianByZhenShouDanIdFor77);
        if (IsMissing(table, "OpenPetSkillStudyMsgBox")) table.Register("OpenPetSkillStudyMsgBox", LAG_Pet_OpenPetSkillStudyMsgBox);
        if (IsMissing(table, "Other_GetAIType")) table.Register("Other_GetAIType", LAG_Pet_Other_GetAIType);
        if (IsMissing(table, "Other_GetAttackCold")) table.Register("Other_GetAttackCold", LAG_Pet_Other_GetAttackCold);
        if (IsMissing(table, "Other_GetAttackFire")) table.Register("Other_GetAttackFire", LAG_Pet_Other_GetAttackFire);
        if (IsMissing(table, "Other_GetAttackLight")) table.Register("Other_GetAttackLight", LAG_Pet_Other_GetAttackLight);
        if (IsMissing(table, "Other_GetAttackPoison")) table.Register("Other_GetAttackPoison", LAG_Pet_Other_GetAttackPoison);
        if (IsMissing(table, "Other_GetAttackTrait")) table.Register("Other_GetAttackTrait", LAG_Pet_Other_GetAttackTrait);
        if (IsMissing(table, "Other_GetBasic")) table.Register("Other_GetBasic", LAG_Pet_Other_GetBasic);
        if (IsMissing(table, "Other_GetConsort")) table.Register("Other_GetConsort", LAG_Pet_Other_GetConsort);
        if (IsMissing(table, "Other_GetCriticalAttack")) table.Register("Other_GetCriticalAttack", LAG_Pet_Other_GetCriticalAttack);
        if (IsMissing(table, "Other_GetCriticalDefence")) table.Register("Other_GetCriticalDefence", LAG_Pet_Other_GetCriticalDefence);
        if (IsMissing(table, "Other_GetDefenceCold")) table.Register("Other_GetDefenceCold", LAG_Pet_Other_GetDefenceCold);
        if (IsMissing(table, "Other_GetDefenceFire")) table.Register("Other_GetDefenceFire", LAG_Pet_Other_GetDefenceFire);
        if (IsMissing(table, "Other_GetDefenceLight")) table.Register("Other_GetDefenceLight", LAG_Pet_Other_GetDefenceLight);
        if (IsMissing(table, "Other_GetDefencePoison")) table.Register("Other_GetDefencePoison", LAG_Pet_Other_GetDefencePoison);
        if (IsMissing(table, "Other_GetDex")) table.Register("Other_GetDex", LAG_Pet_Other_GetDex);
        if (IsMissing(table, "Other_GetDexAptitude")) table.Register("Other_GetDexAptitude", LAG_Pet_Other_GetDexAptitude);
        if (IsMissing(table, "Other_GetExp")) table.Register("Other_GetExp", LAG_Pet_Other_GetExp);
        if (IsMissing(table, "Other_GetFoodType")) table.Register("Other_GetFoodType", LAG_Pet_Other_GetFoodType);
        if (IsMissing(table, "Other_GetGeneration")) table.Register("Other_GetGeneration", LAG_Pet_Other_GetGeneration);
        if (IsMissing(table, "Other_GetGoodsProtect_Pet")) table.Register("Other_GetGoodsProtect_Pet", LAG_Pet_Other_GetGoodsProtect_Pet);
        if (IsMissing(table, "Other_GetGrowRate")) table.Register("Other_GetGrowRate", LAG_Pet_Other_GetGrowRate);
        if (IsMissing(table, "Other_GetHP")) table.Register("Other_GetHP", LAG_Pet_Other_GetHP);
        if (IsMissing(table, "Other_GetHappy")) table.Register("Other_GetHappy", LAG_Pet_Other_GetHappy);
        if (IsMissing(table, "Other_GetID")) table.Register("Other_GetID", LAG_Pet_Other_GetID);
        if (IsMissing(table, "Other_GetInt")) table.Register("Other_GetInt", LAG_Pet_Other_GetInt);
        if (IsMissing(table, "Other_GetIntAptitude")) table.Register("Other_GetIntAptitude", LAG_Pet_Other_GetIntAptitude);
        if (IsMissing(table, "Other_GetLevel")) table.Register("Other_GetLevel", LAG_Pet_Other_GetLevel);
        if (IsMissing(table, "Other_GetLixing")) table.Register("Other_GetLixing", LAG_Pet_Other_GetLixing);
        if (IsMissing(table, "Other_GetLoyalgGade")) table.Register("Other_GetLoyalgGade", LAG_Pet_Other_GetLoyalgGade);
        if (IsMissing(table, "Other_GetMP")) table.Register("Other_GetMP", LAG_Pet_Other_GetMP);
        if (IsMissing(table, "Other_GetMagicAttack")) table.Register("Other_GetMagicAttack", LAG_Pet_Other_GetMagicAttack);
        if (IsMissing(table, "Other_GetMagicRecovery")) table.Register("Other_GetMagicRecovery", LAG_Pet_Other_GetMagicRecovery);
        if (IsMissing(table, "Other_GetMaxHP")) table.Register("Other_GetMaxHP", LAG_Pet_Other_GetMaxHP);
        if (IsMissing(table, "Other_GetMaxLife")) table.Register("Other_GetMaxLife", LAG_Pet_Other_GetMaxLife);
        if (IsMissing(table, "Other_GetMaxMP")) table.Register("Other_GetMaxMP", LAG_Pet_Other_GetMaxMP);
        if (IsMissing(table, "Other_GetMiss")) table.Register("Other_GetMiss", LAG_Pet_Other_GetMiss);
        if (IsMissing(table, "Other_GetName")) table.Register("Other_GetName", LAG_Pet_Other_GetName);
        if (IsMissing(table, "Other_GetNaturalLife")) table.Register("Other_GetNaturalLife", LAG_Pet_Other_GetNaturalLife);
        if (IsMissing(table, "Other_GetPF")) table.Register("Other_GetPF", LAG_Pet_Other_GetPF);
        if (IsMissing(table, "Other_GetPFAptitude")) table.Register("Other_GetPFAptitude", LAG_Pet_Other_GetPFAptitude);
        if (IsMissing(table, "Other_GetPercent_Lx")) table.Register("Other_GetPercent_Lx", LAG_Pet_Other_GetPercent_Lx);
        if (IsMissing(table, "Other_GetPetExteriorChangeID")) table.Register("Other_GetPetExteriorChangeID", LAG_Pet_Other_GetPetExteriorChangeID);
        if (IsMissing(table, "Other_GetPetExteriorGainFlag")) table.Register("Other_GetPetExteriorGainFlag", LAG_Pet_Other_GetPetExteriorGainFlag);
        if (IsMissing(table, "Other_GetPetExteriorId")) table.Register("Other_GetPetExteriorId", LAG_Pet_Other_GetPetExteriorId);
        if (IsMissing(table, "Other_GetPetGrowLevel")) table.Register("Other_GetPetGrowLevel", LAG_Pet_Other_GetPetGrowLevel);
        if (IsMissing(table, "Other_GetPetIndexByGUID")) table.Register("Other_GetPetIndexByGUID", LAG_Pet_Other_GetPetIndexByGUID);
        if (IsMissing(table, "Other_GetPetList_Appoint")) table.Register("Other_GetPetList_Appoint", LAG_Pet_Other_GetPetList_Appoint);
        if (IsMissing(table, "Other_GetPetTypeName")) table.Register("Other_GetPetTypeName", LAG_Pet_Other_GetPetTypeName);
        if (IsMissing(table, "Other_GetPet_Count")) table.Register("Other_GetPet_Count", LAG_Pet_Other_GetPet_Count);
        if (IsMissing(table, "Other_GetPhysicsAttack")) table.Register("Other_GetPhysicsAttack", LAG_Pet_Other_GetPhysicsAttack);
        if (IsMissing(table, "Other_GetPhysicsRecovery")) table.Register("Other_GetPhysicsRecovery", LAG_Pet_Other_GetPhysicsRecovery);
        if (IsMissing(table, "Other_GetPotential")) table.Register("Other_GetPotential", LAG_Pet_Other_GetPotential);
        if (IsMissing(table, "Other_GetResistCold")) table.Register("Other_GetResistCold", LAG_Pet_Other_GetResistCold);
        if (IsMissing(table, "Other_GetResistFire")) table.Register("Other_GetResistFire", LAG_Pet_Other_GetResistFire);
        if (IsMissing(table, "Other_GetResistLight")) table.Register("Other_GetResistLight", LAG_Pet_Other_GetResistLight);
        if (IsMissing(table, "Other_GetResistPoison")) table.Register("Other_GetResistPoison", LAG_Pet_Other_GetResistPoison);
        if (IsMissing(table, "Other_GetSavvy")) table.Register("Other_GetSavvy", LAG_Pet_Other_GetSavvy);
        if (IsMissing(table, "Other_GetSex")) table.Register("Other_GetSex", LAG_Pet_Other_GetSex);
        if (IsMissing(table, "Other_GetShootProbability")) table.Register("Other_GetShootProbability", LAG_Pet_Other_GetShootProbability);
        if (IsMissing(table, "Other_GetSta")) table.Register("Other_GetSta", LAG_Pet_Other_GetSta);
        if (IsMissing(table, "Other_GetStaAptitude")) table.Register("Other_GetStaAptitude", LAG_Pet_Other_GetStaAptitude);
        if (IsMissing(table, "Other_GetStr")) table.Register("Other_GetStr", LAG_Pet_Other_GetStr);
        if (IsMissing(table, "Other_GetStrAptitude")) table.Register("Other_GetStrAptitude", LAG_Pet_Other_GetStrAptitude);
        if (IsMissing(table, "Other_GetTakeLevel")) table.Register("Other_GetTakeLevel", LAG_Pet_Other_GetTakeLevel);
        if (IsMissing(table, "Other_GetType")) table.Register("Other_GetType", LAG_Pet_Other_GetType);
        if (IsMissing(table, "Other_IsPresent")) table.Register("Other_IsPresent", LAG_Pet_Other_IsPresent);
        if (IsMissing(table, "Other_SetModel")) table.Register("Other_SetModel", LAG_Pet_Other_SetModel);
        if (IsMissing(table, "Other_SetSelectedIdx")) table.Register("Other_SetSelectedIdx", LAG_Pet_Other_SetSelectedIdx);
        if (IsMissing(table, "PetAskChangeCurrentTitle")) table.Register("PetAskChangeCurrentTitle", LAG_Pet_PetAskChangeCurrentTitle);
        if (IsMissing(table, "PetBank_PetListSelectChange")) table.Register("PetBank_PetListSelectChange", LAG_Pet_PetBank_PetListSelectChange);
        if (IsMissing(table, "PetBank_WriteLog")) table.Register("PetBank_WriteLog", LAG_Pet_PetBank_WriteLog);
        if (IsMissing(table, "PetHHComfirm")) table.Register("PetHHComfirm", LAG_Pet_PetHHComfirm);
        if (IsMissing(table, "PetOpenPetJian")) table.Register("PetOpenPetJian", LAG_Pet_PetOpenPetJian);
        if (IsMissing(table, "PetOpenTitleList")) table.Register("PetOpenTitleList", LAG_Pet_PetOpenTitleList);
        if (IsMissing(table, "PetProcreate_Clear")) table.Register("PetProcreate_Clear", LAG_Pet_PetProcreate_Clear);
        if (IsMissing(table, "PetToShelizi")) table.Register("PetToShelizi", LAG_Pet_PetToShelizi);
        if (IsMissing(table, "PossessionPet")) table.Register("PossessionPet", LAG_Pet_PossessionPet);
        if (IsMissing(table, "RestorePet")) table.Register("RestorePet", LAG_Pet_RestorePet);
        if (IsMissing(table, "SavePetIntoBank_PetBank")) table.Register("SavePetIntoBank_PetBank", LAG_Pet_SavePetIntoBank_PetBank);
        if (IsMissing(table, "SetCanFanzhiPet")) table.Register("SetCanFanzhiPet", LAG_Pet_SetCanFanzhiPet);
        if (IsMissing(table, "SetCurrentSelectPet_PetBank")) table.Register("SetCurrentSelectPet_PetBank", LAG_Pet_SetCurrentSelectPet_PetBank);
        if (IsMissing(table, "SetDispatchModel")) table.Register("SetDispatchModel", LAG_Pet_SetDispatchModel);
        if (IsMissing(table, "SetFightPetAsMainTarget")) table.Register("SetFightPetAsMainTarget", LAG_Pet_SetFightPetAsMainTarget);
        if (IsMissing(table, "SetModel_PetBank")) table.Register("SetModel_PetBank", LAG_Pet_SetModel_PetBank);
        if (IsMissing(table, "SetNullCurTitle")) table.Register("SetNullCurTitle", LAG_Pet_SetNullCurTitle);
        if (IsMissing(table, "SetPetLocation")) table.Register("SetPetLocation", LAG_Pet_SetPetLocation);
        if (IsMissing(table, "SetPetTujianJiHuoModel")) table.Register("SetPetTujianJiHuoModel", LAG_Pet_SetPetTujianJiHuoModel);
        if (IsMissing(table, "SetProcreate_Other_Model")) table.Register("SetProcreate_Other_Model", LAG_Pet_SetProcreate_Other_Model);
        if (IsMissing(table, "SetProcreate_Self_Model")) table.Register("SetProcreate_Self_Model", LAG_Pet_SetProcreate_Self_Model);
        if (IsMissing(table, "SetPropagateModel")) table.Register("SetPropagateModel", LAG_Pet_SetPropagateModel);
        if (IsMissing(table, "SetSelectPetIdx")) table.Register("SetSelectPetIdx", LAG_Pet_SetSelectPetIdx);
        if (IsMissing(table, "SetSkillLevelupModel")) table.Register("SetSkillLevelupModel", LAG_Pet_SetSkillLevelupModel);
        if (IsMissing(table, "SetStudyNewSkillModel")) table.Register("SetStudyNewSkillModel", LAG_Pet_SetStudyNewSkillModel);
        if (IsMissing(table, "SetSynModel")) table.Register("SetSynModel", LAG_Pet_SetSynModel);
        if (IsMissing(table, "SetYuanbaoBuyState")) table.Register("SetYuanbaoBuyState", LAG_Pet_SetYuanbaoBuyState);
        if (IsMissing(table, "SethuantongModel")) table.Register("SethuantongModel", LAG_Pet_SethuantongModel);
        if (IsMissing(table, "ShowBagSelectPet_PetBank")) table.Register("ShowBagSelectPet_PetBank", LAG_Pet_ShowBagSelectPet_PetBank);
        if (IsMissing(table, "ShowListTargetPet_PetBank")) table.Register("ShowListTargetPet_PetBank", LAG_Pet_ShowListTargetPet_PetBank);
        if (IsMissing(table, "ShowTargetPet_PetBank")) table.Register("ShowTargetPet_PetBank", LAG_Pet_ShowTargetPet_PetBank);
        if (IsMissing(table, "Syn_Confirm")) table.Register("Syn_Confirm", LAG_Pet_Syn_Confirm);
        if (IsMissing(table, "Syn_Do")) table.Register("Syn_Do", LAG_Pet_Syn_Do);
        if (IsMissing(table, "UpdatePetList")) table.Register("UpdatePetList", LAG_Pet_UpdatePetList);
        if (IsMissing(table, "ViewPetDetailData")) table.Register("ViewPetDetailData", LAG_Pet_ViewPetDetailData);
    }
}
