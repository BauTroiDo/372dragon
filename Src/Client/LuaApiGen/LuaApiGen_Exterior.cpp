




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_Exterior_GetIndexIDByProperty(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "GetIndexIDByProperty", "n"); }

        int LAG_Exterior_GetItemNameByProperty(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "GetItemNameByProperty", "ss"); }

        int LAG_Exterior_IsGemOnDressByItemIndex(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "IsGemOnDressByItemIndex", "nnnn"); }


        int LAG_Exterior_LuaFnAskOpenExterior(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnAskOpenExterior", ""); }


        int LAG_Exterior_LuaFnAskOpenExteriorWeapon(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnAskOpenExteriorWeapon", ""); }


        int LAG_Exterior_LuaFnDianZan(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnDianZan", ""); }

        int LAG_Exterior_LuaFnDressCanPaint(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnDressCanPaint", "n"); }


        int LAG_Exterior_LuaFnDressPreviewPlayAction(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnDressPreviewPlayAction", ""); }

        int LAG_Exterior_LuaFnEnumExteriorHairColor(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnEnumExteriorHairColor", "nnnnn"); }

        int LAG_Exterior_LuaFnEnumExteriorHairColorTip(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnEnumExteriorHairColorTip", "n"); }

        int LAG_Exterior_LuaFnEnumPossessionPetEquipAction(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnEnumPossessionPetEquipAction", "o"); }


        int LAG_Exterior_LuaFnExteriorAddCoupleFashion(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnExteriorAddCoupleFashion", ""); }


        int LAG_Exterior_LuaFnExteriorAvatarPlayAction(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnExteriorAvatarPlayAction", ""); }

        int LAG_Exterior_LuaFnExteriorFashionDepotItemClick(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnExteriorFashionDepotItemClick", "n"); }


        int LAG_Exterior_LuaFnExteriorFashionOperation(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnExteriorFashionOperation", "n"); }


        int LAG_Exterior_LuaFnExteriorFashionTakeOut(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnExteriorFashionTakeOut", "n"); }

        int LAG_Exterior_LuaFnExteriorGetPlayerDepotIsCanShare(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnExteriorGetPlayerDepotIsCanShare", "n"); }


        int LAG_Exterior_LuaFnExteriorMoveCoupleFashion(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnExteriorMoveCoupleFashion", ""); }


        int LAG_Exterior_LuaFnExteriorOtherShareLinkAvatar(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnExteriorOtherShareLinkAvatar", "n"); }

        int LAG_Exterior_LuaFnExteriorOtherShareLinkAvatarMount(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnExteriorOtherShareLinkAvatarMount", ""); }

        int LAG_Exterior_LuaFnExteriorPlayerClearTagSel(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnExteriorPlayerClearTagSel", "n"); }

        int LAG_Exterior_LuaFnExteriorPlayerGetProfileData(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnExteriorPlayerGetProfileData", "nnn"); }

        int LAG_Exterior_LuaFnExteriorPlayerGetSharePlan(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnExteriorPlayerGetSharePlan", "nnnnnnnn"); }

        int LAG_Exterior_LuaFnExteriorPlayerGetTagChoose(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnExteriorPlayerGetTagChoose", "n"); }

        int LAG_Exterior_LuaFnExteriorPlayerGetTagChooseCount(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnExteriorPlayerGetTagChooseCount", "n"); }

        int LAG_Exterior_LuaFnExteriorPlayerGetTagChooseInfo(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnExteriorPlayerGetTagChooseInfo", "nnns"); }


        int LAG_Exterior_LuaFnExteriorPlayerOpenProfileUI(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnExteriorPlayerOpenProfileUI", "n"); }


        int LAG_Exterior_LuaFnExteriorPlayerOpenSharePlan(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnExteriorPlayerOpenSharePlan", "n"); }


        int LAG_Exterior_LuaFnExteriorPlayerSaveSharePlan(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnExteriorPlayerSaveSharePlan", "n"); }

        int LAG_Exterior_LuaFnExteriorPlayerShareClick(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnExteriorPlayerShareClick", "n"); }


        int LAG_Exterior_LuaFnExteriorProfileAskData(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnExteriorProfileAskData", "n"); }

        int LAG_Exterior_LuaFnExteriorProfileGetTagSel(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnExteriorProfileGetTagSel", "n"); }


        int LAG_Exterior_LuaFnExteriorProfileSaveData(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnExteriorProfileSaveData", "n"); }

        int LAG_Exterior_LuaFnExteriorProfileSelData(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnExteriorProfileSelData", "n"); }

        int LAG_Exterior_LuaFnExteriorRideItemClick(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnExteriorRideItemClick", "n"); }

        int LAG_Exterior_LuaFnExteriorRidePreviewUpdateAvatar(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnExteriorRidePreviewUpdateAvatar", ""); }

        int LAG_Exterior_LuaFnFittingExteriorRide(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnFittingExteriorRide", "n"); }

        int LAG_Exterior_LuaFnGetCoupleFashionDepotItem(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetCoupleFashionDepotItem", "nn"); }

        int LAG_Exterior_LuaFnGetCoupleFashionInUse(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetCoupleFashionInUse", "nn"); }

        int LAG_Exterior_LuaFnGetCoupleFashionValidity(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetCoupleFashionValidity", "n"); }

        int LAG_Exterior_LuaFnGetCurFashionItemIndex(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetCurFashionItemIndex", "nn"); }

        int LAG_Exterior_LuaFnGetCurrentExteriorSetInfo(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetCurrentExteriorSetInfo", "nnnn"); }

        int LAG_Exterior_LuaFnGetCurrentRanSeSetInfo(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetCurrentRanSeSetInfo", "nn"); }

        int LAG_Exterior_LuaFnGetExteriorFaceInfo(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorFaceInfo", "s"); }

        int LAG_Exterior_LuaFnGetExteriorFaceStyleInfo(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorFaceStyleInfo", "nnnnnsns"); }

        int LAG_Exterior_LuaFnGetExteriorFashionInUse(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorFashionInUse", "nn"); }

        int LAG_Exterior_LuaFnGetExteriorHairColorCount(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorHairColorCount", "n"); }

        int LAG_Exterior_LuaFnGetExteriorHairColorIndex(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorHairColorIndex", "n"); }

        int LAG_Exterior_LuaFnGetExteriorHairInfo(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorHairInfo", "s"); }

        int LAG_Exterior_LuaFnGetExteriorHairStyleInfo(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorHairStyleInfo", "nnnnnsns"); }

        int LAG_Exterior_LuaFnGetExteriorHeadStyleInfo(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorHeadStyleInfo", "nnnnnsns"); }

        int LAG_Exterior_LuaFnGetExteriorIDFromList(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorIDFromList", "n"); }

        int LAG_Exterior_LuaFnGetExteriorIDFromListForRanSe(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorIDFromListForRanSe", "n"); }

        int LAG_Exterior_LuaFnGetExteriorIdByItem(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorIdByItem", "n"); }

        int LAG_Exterior_LuaFnGetExteriorIdByItemIndex(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorIdByItemIndex", "n"); }

        int LAG_Exterior_LuaFnGetExteriorInUse(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorInUse", "n"); }

        int LAG_Exterior_LuaFnGetExteriorLeftTime(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorLeftTime", "n"); }

        int LAG_Exterior_LuaFnGetExteriorListCount(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorListCount", "n"); }

        int LAG_Exterior_LuaFnGetExteriorMaxCount(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorMaxCount", "n"); }

        int LAG_Exterior_LuaFnGetExteriorOtherShareLinkInfo(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorOtherShareLinkInfo", "nnnn"); }

        int LAG_Exterior_LuaFnGetExteriorPlayerFittingCount(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorPlayerFittingCount", "n"); }

        int LAG_Exterior_LuaFnGetExteriorPortraitInfo(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorPortraitInfo", "s"); }

        int LAG_Exterior_LuaFnGetExteriorPossInfo(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorPossInfo", "s"); }

        int LAG_Exterior_LuaFnGetExteriorPossVisualIndex(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorPossVisualIndex", "n"); }

        int LAG_Exterior_LuaFnGetExteriorRideCameraParam(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorRideCameraParam", ""); }

        int LAG_Exterior_LuaFnGetExteriorRideInfo(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorRideInfo", "s"); }

        int LAG_Exterior_LuaFnGetExteriorRideMaxSpeed(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorRideMaxSpeed", "n"); }

        int LAG_Exterior_LuaFnGetExteriorTip(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorTip", "n"); }

        int LAG_Exterior_LuaFnGetExteriorWeaponActionNum(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorWeaponActionNum", "n"); }

        int LAG_Exterior_LuaFnGetExteriorWeaponIDFromList(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorWeaponIDFromList", "n"); }

        int LAG_Exterior_LuaFnGetExteriorWeaponInUse(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorWeaponInUse", "n"); }

        int LAG_Exterior_LuaFnGetExteriorWeaponInfo(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorWeaponInfo", "s"); }

        int LAG_Exterior_LuaFnGetExteriorWeaponLeftTime(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorWeaponLeftTime", "n"); }

        int LAG_Exterior_LuaFnGetExteriorWeaponLevel(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorWeaponLevel", "n"); }

        int LAG_Exterior_LuaFnGetExteriorWeaponLevelData(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorWeaponLevelData", "nnnnn"); }

        int LAG_Exterior_LuaFnGetExteriorWeaponListCount(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorWeaponListCount", "n"); }

        int LAG_Exterior_LuaFnGetExteriorWeaponMaxCount(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorWeaponMaxCount", "n"); }

        int LAG_Exterior_LuaFnGetExteriorWeaponTip(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorWeaponTip", "n"); }

        int LAG_Exterior_LuaFnGetExteriorWeaponToolTip(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetExteriorWeaponToolTip", "n"); }

        int LAG_Exterior_LuaFnGetFaceStylePreviewInfo(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetFaceStylePreviewInfo", "nnnnnsn"); }

        int LAG_Exterior_LuaFnGetFashionActionActionNum(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetFashionActionActionNum", "n"); }

        int LAG_Exterior_LuaFnGetFashionEquipVisual(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetFashionEquipVisual", "n"); }

        int LAG_Exterior_LuaFnGetHairStylePreviewInfo(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetHairStylePreviewInfo", "nnnnnsn"); }

        int LAG_Exterior_LuaFnGetMyCoupleFashionInfoByPlayerDepotIdx(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetMyCoupleFashionInfoByPlayerDepotIdx", "nnn"); }

        int LAG_Exterior_LuaFnGetNumberingFashionInfo(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetNumberingFashionInfo", "n"); }

        int LAG_Exterior_LuaFnGetOtherExteriorInUse(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetOtherExteriorInUse", "n"); }

        int LAG_Exterior_LuaFnGetOtherExteriorWeaponToolTip(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetOtherExteriorWeaponToolTip", "s"); }

        int LAG_Exterior_LuaFnGetOtherFashionInUse(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetOtherFashionInUse", "n"); }

        int LAG_Exterior_LuaFnGetOtherPlayerTag(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetOtherPlayerTag", "n"); }

        int LAG_Exterior_LuaFnGetOtherProfileData(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetOtherProfileData", "nnnn"); }

        int LAG_Exterior_LuaFnGetPossDefaultData(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetPossDefaultData", "nnn"); }

        int LAG_Exterior_LuaFnGetPreviewDressDesc(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetPreviewDressDesc", "nsn"); }

        int LAG_Exterior_LuaFnGetPreviewDressStdVisualID(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetPreviewDressStdVisualID", "n"); }

        int LAG_Exterior_LuaFnGetQualityForRanSe(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetQualityForRanSe", "n"); }

        int LAG_Exterior_LuaFnGetRanSeColorItem(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetRanSeColorItem", "n"); }

        int LAG_Exterior_LuaFnGetRanSeListCount(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetRanSeListCount", "n"); }

        int LAG_Exterior_LuaFnGetRanSePlanByEquip(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetRanSePlanByEquip", ""); }

        int LAG_Exterior_LuaFnGetRanSePlanCount(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetRanSePlanCount", "n"); }

        int LAG_Exterior_LuaFnGetRanSePlanImage(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetRanSePlanImage", ""); }

        int LAG_Exterior_LuaFnGetRanSePlanIndex(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetRanSePlanIndex", "n"); }

        int LAG_Exterior_LuaFnGetRanSePlanName(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetRanSePlanName", ""); }

        int LAG_Exterior_LuaFnGetRanSePlanNameTips(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetRanSePlanNameTips", ""); }

        int LAG_Exterior_LuaFnGetRideCardRideToolTip(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetRideCardRideToolTip", "n"); }

        int LAG_Exterior_LuaFnGetRideToolTip(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetRideToolTip", "n"); }

        int LAG_Exterior_LuaFnGetSpouseCoupleFashionInfo(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnGetSpouseCoupleFashionInfo", "nnnn"); }

        int LAG_Exterior_LuaFnInitCurrentExteriorSet(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnInitCurrentExteriorSet", ""); }

        int LAG_Exterior_LuaFnInitCurrentExteriorSetExceptFashion(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnInitCurrentExteriorSetExceptFashion", ""); }

        int LAG_Exterior_LuaFnInitCurrentRanSeJianSet(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnInitCurrentRanSeJianSet", ""); }

        int LAG_Exterior_LuaFnInitCurrentRanSeSet(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnInitCurrentRanSeSet", ""); }


        int LAG_Exterior_LuaFnInitExteriorFashionList(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnInitExteriorFashionList", "n"); }

        int LAG_Exterior_LuaFnInitExteriorList(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnInitExteriorList", ""); }

        int LAG_Exterior_LuaFnInitExteriorListForRanSe(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnInitExteriorListForRanSe", ""); }

        int LAG_Exterior_LuaFnInitExteriorWeaponList(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnInitExteriorWeaponList", ""); }

        int LAG_Exterior_LuaFnInitPreviewDressData(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnInitPreviewDressData", "n"); }

        int LAG_Exterior_LuaFnIsCanRanSe(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnIsCanRanSe", "n"); }

        int LAG_Exterior_LuaFnIsEquipExteriorInUse(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnIsEquipExteriorInUse", "n"); }

        int LAG_Exterior_LuaFnIsHaveCoupleFashionShowTip(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnIsHaveCoupleFashionShowTip", "n"); }

        int LAG_Exterior_LuaFnIsHaveExterior(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnIsHaveExterior", "n"); }

        int LAG_Exterior_LuaFnIsHaveExteriorChange(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnIsHaveExteriorChange", "n"); }

        int LAG_Exterior_LuaFnIsHaveExteriorShowTip(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnIsHaveExteriorShowTip", "n"); }

        int LAG_Exterior_LuaFnIsHaveExteriorWeapon(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnIsHaveExteriorWeapon", "n"); }

        int LAG_Exterior_LuaFnIsHaveExteriorWeaponShowTip(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnIsHaveExteriorWeaponShowTip", "n"); }

        int LAG_Exterior_LuaFnIsHaveHairColorShowTip(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnIsHaveHairColorShowTip", "n"); }

        int LAG_Exterior_LuaFnIsPlanInUsing(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnIsPlanInUsing", "n"); }

        int LAG_Exterior_LuaFnIsPlanInUsingByEquip(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnIsPlanInUsingByEquip", "n"); }


        int LAG_Exterior_LuaFnRemoveCoupleFashionShowTip(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnRemoveCoupleFashionShowTip", ""); }


        int LAG_Exterior_LuaFnRemoveExteriorTip(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnRemoveExteriorTip", ""); }


        int LAG_Exterior_LuaFnRemoveExteriorWeaponTip(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnRemoveExteriorWeaponTip", ""); }


        int LAG_Exterior_LuaFnRemoveHairColorTip(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnRemoveHairColorTip", ""); }

        int LAG_Exterior_LuaFnRemovePlayerExteriorFitting(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnRemovePlayerExteriorFitting", ""); }

        int LAG_Exterior_LuaFnRestoreExteriorPlayerFittingData(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnRestoreExteriorPlayerFittingData", ""); }


        int LAG_Exterior_LuaFnSaveExteriorAllChange(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnSaveExteriorAllChange", "n"); }

        int LAG_Exterior_LuaFnSetCurrentExteriorSetInfo(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnSetCurrentExteriorSetInfo", ""); }

        int LAG_Exterior_LuaFnSetCurrentRanSeJianSetInfo(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnSetCurrentRanSeJianSetInfo", ""); }

        int LAG_Exterior_LuaFnSetCurrentRanSeSetInfo(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnSetCurrentRanSeSetInfo", ""); }


        int LAG_Exterior_LuaFnSetExteriorInUse(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnSetExteriorInUse", ""); }


        int LAG_Exterior_LuaFnSetExteriorWeaponInUse(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnSetExteriorWeaponInUse", ""); }

        int LAG_Exterior_LuaFnSetMountId(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnSetMountId", ""); }

        int LAG_Exterior_LuaFnSetShowShowWeaponChatMoodTips(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnSetShowShowWeaponChatMoodTips", ""); }

        int LAG_Exterior_LuaFnShowExteriorPlayerPetSoulEffect(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnShowExteriorPlayerPetSoulEffect", ""); }


        int LAG_Exterior_LuaFnUnUseExteriorFashion(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnUnUseExteriorFashion", "n"); }

        int LAG_Exterior_LuaFnUpdateDressGemEffect(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnUpdateDressGemEffect", ""); }

        int LAG_Exterior_LuaFnUpdateDressPreviewPlayerData(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnUpdateDressPreviewPlayerData", ""); }

        int LAG_Exterior_LuaFnUpdateExteriorAvatarFashion(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnUpdateExteriorAvatarFashion", ""); }


        int LAG_Exterior_LuaFnUpdateExteriorPlayerData(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnUpdateExteriorPlayerData", ""); }

        int LAG_Exterior_LuaFnUpdateExteriorProfileAvatar(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnUpdateExteriorProfileAvatar", "n"); }

        int LAG_Exterior_LuaFnUpdateExteriorProfileAvatarMount(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnUpdateExteriorProfileAvatarMount", ""); }

        int LAG_Exterior_LuaFnUpdateExteriorRideAvatarMount(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnUpdateExteriorRideAvatarMount", ""); }

        int LAG_Exterior_LuaFnUpdateExteriorShareOtherAvatar(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnUpdateExteriorShareOtherAvatar", ""); }

        int LAG_Exterior_LuaFnUpdateExteriorShareOtherData(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnUpdateExteriorShareOtherData", ""); }

        int LAG_Exterior_LuaFnUpdateExteriorSharePlayerData(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnUpdateExteriorSharePlayerData", "n"); }

        int LAG_Exterior_LuaFnUpdateExteriorWeaponPlayerData(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnUpdateExteriorWeaponPlayerData", ""); }

        int LAG_Exterior_LuaFnUpdateOhterProfileAvatarMount(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnUpdateOhterProfileAvatarMount", ""); }

        int LAG_Exterior_LuaFnUpdateOrnamentsBackDir(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnUpdateOrnamentsBackDir", ""); }

        int LAG_Exterior_LuaFnUpdateOrnamentsFashion(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnUpdateOrnamentsFashion", ""); }

        int LAG_Exterior_LuaFnUpdateOtherExteriorAvatar(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnUpdateOtherExteriorAvatar", ""); }

        int LAG_Exterior_LuaFnUpdateOtherProfileAvatar(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnUpdateOtherProfileAvatar", "n"); }

        int LAG_Exterior_LuaFnUpdateOtherProfileAvatarObj(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnUpdateOtherProfileAvatarObj", "n"); }

        int LAG_Exterior_LuaFnUpdatePetSoulRanSeJianData(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnUpdatePetSoulRanSeJianData", ""); }

        int LAG_Exterior_LuaFnUpdatePetSoulRanSePlayerData(LuaPlus::LuaState* state) { return Stub(state, "Exterior", "LuaFnUpdatePetSoulRanSePlayerData", ""); }
    }

    void Register_Exterior(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "GetIndexIDByProperty")) table.Register("GetIndexIDByProperty", LAG_Exterior_GetIndexIDByProperty);
        if (IsMissing(table, "GetItemNameByProperty")) table.Register("GetItemNameByProperty", LAG_Exterior_GetItemNameByProperty);
        if (IsMissing(table, "IsGemOnDressByItemIndex")) table.Register("IsGemOnDressByItemIndex", LAG_Exterior_IsGemOnDressByItemIndex);
        if (IsMissing(table, "LuaFnAskOpenExterior")) table.Register("LuaFnAskOpenExterior", LAG_Exterior_LuaFnAskOpenExterior);
        if (IsMissing(table, "LuaFnAskOpenExteriorWeapon")) table.Register("LuaFnAskOpenExteriorWeapon", LAG_Exterior_LuaFnAskOpenExteriorWeapon);
        if (IsMissing(table, "LuaFnDianZan")) table.Register("LuaFnDianZan", LAG_Exterior_LuaFnDianZan);
        if (IsMissing(table, "LuaFnDressCanPaint")) table.Register("LuaFnDressCanPaint", LAG_Exterior_LuaFnDressCanPaint);
        if (IsMissing(table, "LuaFnDressPreviewPlayAction")) table.Register("LuaFnDressPreviewPlayAction", LAG_Exterior_LuaFnDressPreviewPlayAction);
        if (IsMissing(table, "LuaFnEnumExteriorHairColor")) table.Register("LuaFnEnumExteriorHairColor", LAG_Exterior_LuaFnEnumExteriorHairColor);
        if (IsMissing(table, "LuaFnEnumExteriorHairColorTip")) table.Register("LuaFnEnumExteriorHairColorTip", LAG_Exterior_LuaFnEnumExteriorHairColorTip);
        if (IsMissing(table, "LuaFnEnumPossessionPetEquipAction")) table.Register("LuaFnEnumPossessionPetEquipAction", LAG_Exterior_LuaFnEnumPossessionPetEquipAction);
        if (IsMissing(table, "LuaFnExteriorAddCoupleFashion")) table.Register("LuaFnExteriorAddCoupleFashion", LAG_Exterior_LuaFnExteriorAddCoupleFashion);
        if (IsMissing(table, "LuaFnExteriorAvatarPlayAction")) table.Register("LuaFnExteriorAvatarPlayAction", LAG_Exterior_LuaFnExteriorAvatarPlayAction);
        if (IsMissing(table, "LuaFnExteriorFashionDepotItemClick")) table.Register("LuaFnExteriorFashionDepotItemClick", LAG_Exterior_LuaFnExteriorFashionDepotItemClick);
        if (IsMissing(table, "LuaFnExteriorFashionOperation")) table.Register("LuaFnExteriorFashionOperation", LAG_Exterior_LuaFnExteriorFashionOperation);
        if (IsMissing(table, "LuaFnExteriorFashionTakeOut")) table.Register("LuaFnExteriorFashionTakeOut", LAG_Exterior_LuaFnExteriorFashionTakeOut);
        if (IsMissing(table, "LuaFnExteriorGetPlayerDepotIsCanShare")) table.Register("LuaFnExteriorGetPlayerDepotIsCanShare", LAG_Exterior_LuaFnExteriorGetPlayerDepotIsCanShare);
        if (IsMissing(table, "LuaFnExteriorMoveCoupleFashion")) table.Register("LuaFnExteriorMoveCoupleFashion", LAG_Exterior_LuaFnExteriorMoveCoupleFashion);
        if (IsMissing(table, "LuaFnExteriorOtherShareLinkAvatar")) table.Register("LuaFnExteriorOtherShareLinkAvatar", LAG_Exterior_LuaFnExteriorOtherShareLinkAvatar);
        if (IsMissing(table, "LuaFnExteriorOtherShareLinkAvatarMount")) table.Register("LuaFnExteriorOtherShareLinkAvatarMount", LAG_Exterior_LuaFnExteriorOtherShareLinkAvatarMount);
        if (IsMissing(table, "LuaFnExteriorPlayerClearTagSel")) table.Register("LuaFnExteriorPlayerClearTagSel", LAG_Exterior_LuaFnExteriorPlayerClearTagSel);
        if (IsMissing(table, "LuaFnExteriorPlayerGetProfileData")) table.Register("LuaFnExteriorPlayerGetProfileData", LAG_Exterior_LuaFnExteriorPlayerGetProfileData);
        if (IsMissing(table, "LuaFnExteriorPlayerGetSharePlan")) table.Register("LuaFnExteriorPlayerGetSharePlan", LAG_Exterior_LuaFnExteriorPlayerGetSharePlan);
        if (IsMissing(table, "LuaFnExteriorPlayerGetTagChoose")) table.Register("LuaFnExteriorPlayerGetTagChoose", LAG_Exterior_LuaFnExteriorPlayerGetTagChoose);
        if (IsMissing(table, "LuaFnExteriorPlayerGetTagChooseCount")) table.Register("LuaFnExteriorPlayerGetTagChooseCount", LAG_Exterior_LuaFnExteriorPlayerGetTagChooseCount);
        if (IsMissing(table, "LuaFnExteriorPlayerGetTagChooseInfo")) table.Register("LuaFnExteriorPlayerGetTagChooseInfo", LAG_Exterior_LuaFnExteriorPlayerGetTagChooseInfo);
        if (IsMissing(table, "LuaFnExteriorPlayerOpenProfileUI")) table.Register("LuaFnExteriorPlayerOpenProfileUI", LAG_Exterior_LuaFnExteriorPlayerOpenProfileUI);
        if (IsMissing(table, "LuaFnExteriorPlayerOpenSharePlan")) table.Register("LuaFnExteriorPlayerOpenSharePlan", LAG_Exterior_LuaFnExteriorPlayerOpenSharePlan);
        if (IsMissing(table, "LuaFnExteriorPlayerSaveSharePlan")) table.Register("LuaFnExteriorPlayerSaveSharePlan", LAG_Exterior_LuaFnExteriorPlayerSaveSharePlan);
        if (IsMissing(table, "LuaFnExteriorPlayerShareClick")) table.Register("LuaFnExteriorPlayerShareClick", LAG_Exterior_LuaFnExteriorPlayerShareClick);
        if (IsMissing(table, "LuaFnExteriorProfileAskData")) table.Register("LuaFnExteriorProfileAskData", LAG_Exterior_LuaFnExteriorProfileAskData);
        if (IsMissing(table, "LuaFnExteriorProfileGetTagSel")) table.Register("LuaFnExteriorProfileGetTagSel", LAG_Exterior_LuaFnExteriorProfileGetTagSel);
        if (IsMissing(table, "LuaFnExteriorProfileSaveData")) table.Register("LuaFnExteriorProfileSaveData", LAG_Exterior_LuaFnExteriorProfileSaveData);
        if (IsMissing(table, "LuaFnExteriorProfileSelData")) table.Register("LuaFnExteriorProfileSelData", LAG_Exterior_LuaFnExteriorProfileSelData);
        if (IsMissing(table, "LuaFnExteriorRideItemClick")) table.Register("LuaFnExteriorRideItemClick", LAG_Exterior_LuaFnExteriorRideItemClick);
        if (IsMissing(table, "LuaFnExteriorRidePreviewUpdateAvatar")) table.Register("LuaFnExteriorRidePreviewUpdateAvatar", LAG_Exterior_LuaFnExteriorRidePreviewUpdateAvatar);
        if (IsMissing(table, "LuaFnFittingExteriorRide")) table.Register("LuaFnFittingExteriorRide", LAG_Exterior_LuaFnFittingExteriorRide);
        if (IsMissing(table, "LuaFnGetCoupleFashionDepotItem")) table.Register("LuaFnGetCoupleFashionDepotItem", LAG_Exterior_LuaFnGetCoupleFashionDepotItem);
        if (IsMissing(table, "LuaFnGetCoupleFashionInUse")) table.Register("LuaFnGetCoupleFashionInUse", LAG_Exterior_LuaFnGetCoupleFashionInUse);
        if (IsMissing(table, "LuaFnGetCoupleFashionValidity")) table.Register("LuaFnGetCoupleFashionValidity", LAG_Exterior_LuaFnGetCoupleFashionValidity);
        if (IsMissing(table, "LuaFnGetCurFashionItemIndex")) table.Register("LuaFnGetCurFashionItemIndex", LAG_Exterior_LuaFnGetCurFashionItemIndex);
        if (IsMissing(table, "LuaFnGetCurrentExteriorSetInfo")) table.Register("LuaFnGetCurrentExteriorSetInfo", LAG_Exterior_LuaFnGetCurrentExteriorSetInfo);
        if (IsMissing(table, "LuaFnGetCurrentRanSeSetInfo")) table.Register("LuaFnGetCurrentRanSeSetInfo", LAG_Exterior_LuaFnGetCurrentRanSeSetInfo);
        if (IsMissing(table, "LuaFnGetExteriorFaceInfo")) table.Register("LuaFnGetExteriorFaceInfo", LAG_Exterior_LuaFnGetExteriorFaceInfo);
        if (IsMissing(table, "LuaFnGetExteriorFaceStyleInfo")) table.Register("LuaFnGetExteriorFaceStyleInfo", LAG_Exterior_LuaFnGetExteriorFaceStyleInfo);
        if (IsMissing(table, "LuaFnGetExteriorFashionInUse")) table.Register("LuaFnGetExteriorFashionInUse", LAG_Exterior_LuaFnGetExteriorFashionInUse);
        if (IsMissing(table, "LuaFnGetExteriorHairColorCount")) table.Register("LuaFnGetExteriorHairColorCount", LAG_Exterior_LuaFnGetExteriorHairColorCount);
        if (IsMissing(table, "LuaFnGetExteriorHairColorIndex")) table.Register("LuaFnGetExteriorHairColorIndex", LAG_Exterior_LuaFnGetExteriorHairColorIndex);
        if (IsMissing(table, "LuaFnGetExteriorHairInfo")) table.Register("LuaFnGetExteriorHairInfo", LAG_Exterior_LuaFnGetExteriorHairInfo);
        if (IsMissing(table, "LuaFnGetExteriorHairStyleInfo")) table.Register("LuaFnGetExteriorHairStyleInfo", LAG_Exterior_LuaFnGetExteriorHairStyleInfo);
        if (IsMissing(table, "LuaFnGetExteriorHeadStyleInfo")) table.Register("LuaFnGetExteriorHeadStyleInfo", LAG_Exterior_LuaFnGetExteriorHeadStyleInfo);
        if (IsMissing(table, "LuaFnGetExteriorIDFromList")) table.Register("LuaFnGetExteriorIDFromList", LAG_Exterior_LuaFnGetExteriorIDFromList);
        if (IsMissing(table, "LuaFnGetExteriorIDFromListForRanSe")) table.Register("LuaFnGetExteriorIDFromListForRanSe", LAG_Exterior_LuaFnGetExteriorIDFromListForRanSe);
        if (IsMissing(table, "LuaFnGetExteriorIdByItem")) table.Register("LuaFnGetExteriorIdByItem", LAG_Exterior_LuaFnGetExteriorIdByItem);
        if (IsMissing(table, "LuaFnGetExteriorIdByItemIndex")) table.Register("LuaFnGetExteriorIdByItemIndex", LAG_Exterior_LuaFnGetExteriorIdByItemIndex);
        if (IsMissing(table, "LuaFnGetExteriorInUse")) table.Register("LuaFnGetExteriorInUse", LAG_Exterior_LuaFnGetExteriorInUse);
        if (IsMissing(table, "LuaFnGetExteriorLeftTime")) table.Register("LuaFnGetExteriorLeftTime", LAG_Exterior_LuaFnGetExteriorLeftTime);
        if (IsMissing(table, "LuaFnGetExteriorListCount")) table.Register("LuaFnGetExteriorListCount", LAG_Exterior_LuaFnGetExteriorListCount);
        if (IsMissing(table, "LuaFnGetExteriorMaxCount")) table.Register("LuaFnGetExteriorMaxCount", LAG_Exterior_LuaFnGetExteriorMaxCount);
        if (IsMissing(table, "LuaFnGetExteriorOtherShareLinkInfo")) table.Register("LuaFnGetExteriorOtherShareLinkInfo", LAG_Exterior_LuaFnGetExteriorOtherShareLinkInfo);
        if (IsMissing(table, "LuaFnGetExteriorPlayerFittingCount")) table.Register("LuaFnGetExteriorPlayerFittingCount", LAG_Exterior_LuaFnGetExteriorPlayerFittingCount);
        if (IsMissing(table, "LuaFnGetExteriorPortraitInfo")) table.Register("LuaFnGetExteriorPortraitInfo", LAG_Exterior_LuaFnGetExteriorPortraitInfo);
        if (IsMissing(table, "LuaFnGetExteriorPossInfo")) table.Register("LuaFnGetExteriorPossInfo", LAG_Exterior_LuaFnGetExteriorPossInfo);
        if (IsMissing(table, "LuaFnGetExteriorPossVisualIndex")) table.Register("LuaFnGetExteriorPossVisualIndex", LAG_Exterior_LuaFnGetExteriorPossVisualIndex);
        if (IsMissing(table, "LuaFnGetExteriorRideCameraParam")) table.Register("LuaFnGetExteriorRideCameraParam", LAG_Exterior_LuaFnGetExteriorRideCameraParam);
        if (IsMissing(table, "LuaFnGetExteriorRideInfo")) table.Register("LuaFnGetExteriorRideInfo", LAG_Exterior_LuaFnGetExteriorRideInfo);
        if (IsMissing(table, "LuaFnGetExteriorRideMaxSpeed")) table.Register("LuaFnGetExteriorRideMaxSpeed", LAG_Exterior_LuaFnGetExteriorRideMaxSpeed);
        if (IsMissing(table, "LuaFnGetExteriorTip")) table.Register("LuaFnGetExteriorTip", LAG_Exterior_LuaFnGetExteriorTip);
        if (IsMissing(table, "LuaFnGetExteriorWeaponActionNum")) table.Register("LuaFnGetExteriorWeaponActionNum", LAG_Exterior_LuaFnGetExteriorWeaponActionNum);
        if (IsMissing(table, "LuaFnGetExteriorWeaponIDFromList")) table.Register("LuaFnGetExteriorWeaponIDFromList", LAG_Exterior_LuaFnGetExteriorWeaponIDFromList);
        if (IsMissing(table, "LuaFnGetExteriorWeaponInUse")) table.Register("LuaFnGetExteriorWeaponInUse", LAG_Exterior_LuaFnGetExteriorWeaponInUse);
        if (IsMissing(table, "LuaFnGetExteriorWeaponInfo")) table.Register("LuaFnGetExteriorWeaponInfo", LAG_Exterior_LuaFnGetExteriorWeaponInfo);
        if (IsMissing(table, "LuaFnGetExteriorWeaponLeftTime")) table.Register("LuaFnGetExteriorWeaponLeftTime", LAG_Exterior_LuaFnGetExteriorWeaponLeftTime);
        if (IsMissing(table, "LuaFnGetExteriorWeaponLevel")) table.Register("LuaFnGetExteriorWeaponLevel", LAG_Exterior_LuaFnGetExteriorWeaponLevel);
        if (IsMissing(table, "LuaFnGetExteriorWeaponLevelData")) table.Register("LuaFnGetExteriorWeaponLevelData", LAG_Exterior_LuaFnGetExteriorWeaponLevelData);
        if (IsMissing(table, "LuaFnGetExteriorWeaponListCount")) table.Register("LuaFnGetExteriorWeaponListCount", LAG_Exterior_LuaFnGetExteriorWeaponListCount);
        if (IsMissing(table, "LuaFnGetExteriorWeaponMaxCount")) table.Register("LuaFnGetExteriorWeaponMaxCount", LAG_Exterior_LuaFnGetExteriorWeaponMaxCount);
        if (IsMissing(table, "LuaFnGetExteriorWeaponTip")) table.Register("LuaFnGetExteriorWeaponTip", LAG_Exterior_LuaFnGetExteriorWeaponTip);
        if (IsMissing(table, "LuaFnGetExteriorWeaponToolTip")) table.Register("LuaFnGetExteriorWeaponToolTip", LAG_Exterior_LuaFnGetExteriorWeaponToolTip);
        if (IsMissing(table, "LuaFnGetFaceStylePreviewInfo")) table.Register("LuaFnGetFaceStylePreviewInfo", LAG_Exterior_LuaFnGetFaceStylePreviewInfo);
        if (IsMissing(table, "LuaFnGetFashionActionActionNum")) table.Register("LuaFnGetFashionActionActionNum", LAG_Exterior_LuaFnGetFashionActionActionNum);
        if (IsMissing(table, "LuaFnGetFashionEquipVisual")) table.Register("LuaFnGetFashionEquipVisual", LAG_Exterior_LuaFnGetFashionEquipVisual);
        if (IsMissing(table, "LuaFnGetHairStylePreviewInfo")) table.Register("LuaFnGetHairStylePreviewInfo", LAG_Exterior_LuaFnGetHairStylePreviewInfo);
        if (IsMissing(table, "LuaFnGetMyCoupleFashionInfoByPlayerDepotIdx")) table.Register("LuaFnGetMyCoupleFashionInfoByPlayerDepotIdx", LAG_Exterior_LuaFnGetMyCoupleFashionInfoByPlayerDepotIdx);
        if (IsMissing(table, "LuaFnGetNumberingFashionInfo")) table.Register("LuaFnGetNumberingFashionInfo", LAG_Exterior_LuaFnGetNumberingFashionInfo);
        if (IsMissing(table, "LuaFnGetOtherExteriorInUse")) table.Register("LuaFnGetOtherExteriorInUse", LAG_Exterior_LuaFnGetOtherExteriorInUse);
        if (IsMissing(table, "LuaFnGetOtherExteriorWeaponToolTip")) table.Register("LuaFnGetOtherExteriorWeaponToolTip", LAG_Exterior_LuaFnGetOtherExteriorWeaponToolTip);
        if (IsMissing(table, "LuaFnGetOtherFashionInUse")) table.Register("LuaFnGetOtherFashionInUse", LAG_Exterior_LuaFnGetOtherFashionInUse);
        if (IsMissing(table, "LuaFnGetOtherPlayerTag")) table.Register("LuaFnGetOtherPlayerTag", LAG_Exterior_LuaFnGetOtherPlayerTag);
        if (IsMissing(table, "LuaFnGetOtherProfileData")) table.Register("LuaFnGetOtherProfileData", LAG_Exterior_LuaFnGetOtherProfileData);
        if (IsMissing(table, "LuaFnGetPossDefaultData")) table.Register("LuaFnGetPossDefaultData", LAG_Exterior_LuaFnGetPossDefaultData);
        if (IsMissing(table, "LuaFnGetPreviewDressDesc")) table.Register("LuaFnGetPreviewDressDesc", LAG_Exterior_LuaFnGetPreviewDressDesc);
        if (IsMissing(table, "LuaFnGetPreviewDressStdVisualID")) table.Register("LuaFnGetPreviewDressStdVisualID", LAG_Exterior_LuaFnGetPreviewDressStdVisualID);
        if (IsMissing(table, "LuaFnGetQualityForRanSe")) table.Register("LuaFnGetQualityForRanSe", LAG_Exterior_LuaFnGetQualityForRanSe);
        if (IsMissing(table, "LuaFnGetRanSeColorItem")) table.Register("LuaFnGetRanSeColorItem", LAG_Exterior_LuaFnGetRanSeColorItem);
        if (IsMissing(table, "LuaFnGetRanSeListCount")) table.Register("LuaFnGetRanSeListCount", LAG_Exterior_LuaFnGetRanSeListCount);
        if (IsMissing(table, "LuaFnGetRanSePlanByEquip")) table.Register("LuaFnGetRanSePlanByEquip", LAG_Exterior_LuaFnGetRanSePlanByEquip);
        if (IsMissing(table, "LuaFnGetRanSePlanCount")) table.Register("LuaFnGetRanSePlanCount", LAG_Exterior_LuaFnGetRanSePlanCount);
        if (IsMissing(table, "LuaFnGetRanSePlanImage")) table.Register("LuaFnGetRanSePlanImage", LAG_Exterior_LuaFnGetRanSePlanImage);
        if (IsMissing(table, "LuaFnGetRanSePlanIndex")) table.Register("LuaFnGetRanSePlanIndex", LAG_Exterior_LuaFnGetRanSePlanIndex);
        if (IsMissing(table, "LuaFnGetRanSePlanName")) table.Register("LuaFnGetRanSePlanName", LAG_Exterior_LuaFnGetRanSePlanName);
        if (IsMissing(table, "LuaFnGetRanSePlanNameTips")) table.Register("LuaFnGetRanSePlanNameTips", LAG_Exterior_LuaFnGetRanSePlanNameTips);
        if (IsMissing(table, "LuaFnGetRideCardRideToolTip")) table.Register("LuaFnGetRideCardRideToolTip", LAG_Exterior_LuaFnGetRideCardRideToolTip);
        if (IsMissing(table, "LuaFnGetRideToolTip")) table.Register("LuaFnGetRideToolTip", LAG_Exterior_LuaFnGetRideToolTip);
        if (IsMissing(table, "LuaFnGetSpouseCoupleFashionInfo")) table.Register("LuaFnGetSpouseCoupleFashionInfo", LAG_Exterior_LuaFnGetSpouseCoupleFashionInfo);
        if (IsMissing(table, "LuaFnInitCurrentExteriorSet")) table.Register("LuaFnInitCurrentExteriorSet", LAG_Exterior_LuaFnInitCurrentExteriorSet);
        if (IsMissing(table, "LuaFnInitCurrentExteriorSetExceptFashion")) table.Register("LuaFnInitCurrentExteriorSetExceptFashion", LAG_Exterior_LuaFnInitCurrentExteriorSetExceptFashion);
        if (IsMissing(table, "LuaFnInitCurrentRanSeJianSet")) table.Register("LuaFnInitCurrentRanSeJianSet", LAG_Exterior_LuaFnInitCurrentRanSeJianSet);
        if (IsMissing(table, "LuaFnInitCurrentRanSeSet")) table.Register("LuaFnInitCurrentRanSeSet", LAG_Exterior_LuaFnInitCurrentRanSeSet);
        if (IsMissing(table, "LuaFnInitExteriorFashionList")) table.Register("LuaFnInitExteriorFashionList", LAG_Exterior_LuaFnInitExteriorFashionList);
        if (IsMissing(table, "LuaFnInitExteriorList")) table.Register("LuaFnInitExteriorList", LAG_Exterior_LuaFnInitExteriorList);
        if (IsMissing(table, "LuaFnInitExteriorListForRanSe")) table.Register("LuaFnInitExteriorListForRanSe", LAG_Exterior_LuaFnInitExteriorListForRanSe);
        if (IsMissing(table, "LuaFnInitExteriorWeaponList")) table.Register("LuaFnInitExteriorWeaponList", LAG_Exterior_LuaFnInitExteriorWeaponList);
        if (IsMissing(table, "LuaFnInitPreviewDressData")) table.Register("LuaFnInitPreviewDressData", LAG_Exterior_LuaFnInitPreviewDressData);
        if (IsMissing(table, "LuaFnIsCanRanSe")) table.Register("LuaFnIsCanRanSe", LAG_Exterior_LuaFnIsCanRanSe);
        if (IsMissing(table, "LuaFnIsEquipExteriorInUse")) table.Register("LuaFnIsEquipExteriorInUse", LAG_Exterior_LuaFnIsEquipExteriorInUse);
        if (IsMissing(table, "LuaFnIsHaveCoupleFashionShowTip")) table.Register("LuaFnIsHaveCoupleFashionShowTip", LAG_Exterior_LuaFnIsHaveCoupleFashionShowTip);
        if (IsMissing(table, "LuaFnIsHaveExterior")) table.Register("LuaFnIsHaveExterior", LAG_Exterior_LuaFnIsHaveExterior);
        if (IsMissing(table, "LuaFnIsHaveExteriorChange")) table.Register("LuaFnIsHaveExteriorChange", LAG_Exterior_LuaFnIsHaveExteriorChange);
        if (IsMissing(table, "LuaFnIsHaveExteriorShowTip")) table.Register("LuaFnIsHaveExteriorShowTip", LAG_Exterior_LuaFnIsHaveExteriorShowTip);
        if (IsMissing(table, "LuaFnIsHaveExteriorWeapon")) table.Register("LuaFnIsHaveExteriorWeapon", LAG_Exterior_LuaFnIsHaveExteriorWeapon);
        if (IsMissing(table, "LuaFnIsHaveExteriorWeaponShowTip")) table.Register("LuaFnIsHaveExteriorWeaponShowTip", LAG_Exterior_LuaFnIsHaveExteriorWeaponShowTip);
        if (IsMissing(table, "LuaFnIsHaveHairColorShowTip")) table.Register("LuaFnIsHaveHairColorShowTip", LAG_Exterior_LuaFnIsHaveHairColorShowTip);
        if (IsMissing(table, "LuaFnIsPlanInUsing")) table.Register("LuaFnIsPlanInUsing", LAG_Exterior_LuaFnIsPlanInUsing);
        if (IsMissing(table, "LuaFnIsPlanInUsingByEquip")) table.Register("LuaFnIsPlanInUsingByEquip", LAG_Exterior_LuaFnIsPlanInUsingByEquip);
        if (IsMissing(table, "LuaFnRemoveCoupleFashionShowTip")) table.Register("LuaFnRemoveCoupleFashionShowTip", LAG_Exterior_LuaFnRemoveCoupleFashionShowTip);
        if (IsMissing(table, "LuaFnRemoveExteriorTip")) table.Register("LuaFnRemoveExteriorTip", LAG_Exterior_LuaFnRemoveExteriorTip);
        if (IsMissing(table, "LuaFnRemoveExteriorWeaponTip")) table.Register("LuaFnRemoveExteriorWeaponTip", LAG_Exterior_LuaFnRemoveExteriorWeaponTip);
        if (IsMissing(table, "LuaFnRemoveHairColorTip")) table.Register("LuaFnRemoveHairColorTip", LAG_Exterior_LuaFnRemoveHairColorTip);
        if (IsMissing(table, "LuaFnRemovePlayerExteriorFitting")) table.Register("LuaFnRemovePlayerExteriorFitting", LAG_Exterior_LuaFnRemovePlayerExteriorFitting);
        if (IsMissing(table, "LuaFnRestoreExteriorPlayerFittingData")) table.Register("LuaFnRestoreExteriorPlayerFittingData", LAG_Exterior_LuaFnRestoreExteriorPlayerFittingData);
        if (IsMissing(table, "LuaFnSaveExteriorAllChange")) table.Register("LuaFnSaveExteriorAllChange", LAG_Exterior_LuaFnSaveExteriorAllChange);
        if (IsMissing(table, "LuaFnSetCurrentExteriorSetInfo")) table.Register("LuaFnSetCurrentExteriorSetInfo", LAG_Exterior_LuaFnSetCurrentExteriorSetInfo);
        if (IsMissing(table, "LuaFnSetCurrentRanSeJianSetInfo")) table.Register("LuaFnSetCurrentRanSeJianSetInfo", LAG_Exterior_LuaFnSetCurrentRanSeJianSetInfo);
        if (IsMissing(table, "LuaFnSetCurrentRanSeSetInfo")) table.Register("LuaFnSetCurrentRanSeSetInfo", LAG_Exterior_LuaFnSetCurrentRanSeSetInfo);
        if (IsMissing(table, "LuaFnSetExteriorInUse")) table.Register("LuaFnSetExteriorInUse", LAG_Exterior_LuaFnSetExteriorInUse);
        if (IsMissing(table, "LuaFnSetExteriorWeaponInUse")) table.Register("LuaFnSetExteriorWeaponInUse", LAG_Exterior_LuaFnSetExteriorWeaponInUse);
        if (IsMissing(table, "LuaFnSetMountId")) table.Register("LuaFnSetMountId", LAG_Exterior_LuaFnSetMountId);
        if (IsMissing(table, "LuaFnSetShowShowWeaponChatMoodTips")) table.Register("LuaFnSetShowShowWeaponChatMoodTips", LAG_Exterior_LuaFnSetShowShowWeaponChatMoodTips);
        if (IsMissing(table, "LuaFnShowExteriorPlayerPetSoulEffect")) table.Register("LuaFnShowExteriorPlayerPetSoulEffect", LAG_Exterior_LuaFnShowExteriorPlayerPetSoulEffect);
        if (IsMissing(table, "LuaFnUnUseExteriorFashion")) table.Register("LuaFnUnUseExteriorFashion", LAG_Exterior_LuaFnUnUseExteriorFashion);
        if (IsMissing(table, "LuaFnUpdateDressGemEffect")) table.Register("LuaFnUpdateDressGemEffect", LAG_Exterior_LuaFnUpdateDressGemEffect);
        if (IsMissing(table, "LuaFnUpdateDressPreviewPlayerData")) table.Register("LuaFnUpdateDressPreviewPlayerData", LAG_Exterior_LuaFnUpdateDressPreviewPlayerData);
        if (IsMissing(table, "LuaFnUpdateExteriorAvatarFashion")) table.Register("LuaFnUpdateExteriorAvatarFashion", LAG_Exterior_LuaFnUpdateExteriorAvatarFashion);
        if (IsMissing(table, "LuaFnUpdateExteriorPlayerData")) table.Register("LuaFnUpdateExteriorPlayerData", LAG_Exterior_LuaFnUpdateExteriorPlayerData);
        if (IsMissing(table, "LuaFnUpdateExteriorProfileAvatar")) table.Register("LuaFnUpdateExteriorProfileAvatar", LAG_Exterior_LuaFnUpdateExteriorProfileAvatar);
        if (IsMissing(table, "LuaFnUpdateExteriorProfileAvatarMount")) table.Register("LuaFnUpdateExteriorProfileAvatarMount", LAG_Exterior_LuaFnUpdateExteriorProfileAvatarMount);
        if (IsMissing(table, "LuaFnUpdateExteriorRideAvatarMount")) table.Register("LuaFnUpdateExteriorRideAvatarMount", LAG_Exterior_LuaFnUpdateExteriorRideAvatarMount);
        if (IsMissing(table, "LuaFnUpdateExteriorShareOtherAvatar")) table.Register("LuaFnUpdateExteriorShareOtherAvatar", LAG_Exterior_LuaFnUpdateExteriorShareOtherAvatar);
        if (IsMissing(table, "LuaFnUpdateExteriorShareOtherData")) table.Register("LuaFnUpdateExteriorShareOtherData", LAG_Exterior_LuaFnUpdateExteriorShareOtherData);
        if (IsMissing(table, "LuaFnUpdateExteriorSharePlayerData")) table.Register("LuaFnUpdateExteriorSharePlayerData", LAG_Exterior_LuaFnUpdateExteriorSharePlayerData);
        if (IsMissing(table, "LuaFnUpdateExteriorWeaponPlayerData")) table.Register("LuaFnUpdateExteriorWeaponPlayerData", LAG_Exterior_LuaFnUpdateExteriorWeaponPlayerData);
        if (IsMissing(table, "LuaFnUpdateOhterProfileAvatarMount")) table.Register("LuaFnUpdateOhterProfileAvatarMount", LAG_Exterior_LuaFnUpdateOhterProfileAvatarMount);
        if (IsMissing(table, "LuaFnUpdateOrnamentsBackDir")) table.Register("LuaFnUpdateOrnamentsBackDir", LAG_Exterior_LuaFnUpdateOrnamentsBackDir);
        if (IsMissing(table, "LuaFnUpdateOrnamentsFashion")) table.Register("LuaFnUpdateOrnamentsFashion", LAG_Exterior_LuaFnUpdateOrnamentsFashion);
        if (IsMissing(table, "LuaFnUpdateOtherExteriorAvatar")) table.Register("LuaFnUpdateOtherExteriorAvatar", LAG_Exterior_LuaFnUpdateOtherExteriorAvatar);
        if (IsMissing(table, "LuaFnUpdateOtherProfileAvatar")) table.Register("LuaFnUpdateOtherProfileAvatar", LAG_Exterior_LuaFnUpdateOtherProfileAvatar);
        if (IsMissing(table, "LuaFnUpdateOtherProfileAvatarObj")) table.Register("LuaFnUpdateOtherProfileAvatarObj", LAG_Exterior_LuaFnUpdateOtherProfileAvatarObj);
        if (IsMissing(table, "LuaFnUpdatePetSoulRanSeJianData")) table.Register("LuaFnUpdatePetSoulRanSeJianData", LAG_Exterior_LuaFnUpdatePetSoulRanSeJianData);
        if (IsMissing(table, "LuaFnUpdatePetSoulRanSePlayerData")) table.Register("LuaFnUpdatePetSoulRanSePlayerData", LAG_Exterior_LuaFnUpdatePetSoulRanSePlayerData);
    }
}
