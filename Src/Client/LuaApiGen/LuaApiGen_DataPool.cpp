




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_DataPool_ActiveMissionCue(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "ActiveMissionCue", ""); }

        int LAG_DataPool_AddFriendAndGrouping(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "AddFriendAndGrouping", ""); }


        int LAG_DataPool_AddTrustFriend(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "AddTrustFriend", ""); }


        int LAG_DataPool_AskChallengeList(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "AskChallengeList", ""); }


        int LAG_DataPool_AskCreateChar(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "AskCreateChar", ""); }

        int LAG_DataPool_AskDelFriend(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "AskDelFriend", ""); }


        int LAG_DataPool_AskMyBagList(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "AskMyBagList", "n"); }

        int LAG_DataPool_CampaignTrackGotoCampaignList(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "CampaignTrackGotoCampaignList", ""); }


        int LAG_DataPool_Challenge(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Challenge", ""); }

        int LAG_DataPool_ChangeLongHaiZiAction(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "ChangeLongHaiZiAction", ""); }

        int LAG_DataPool_Change_MyFaceStyle(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Change_MyFaceStyle", ""); }

        int LAG_DataPool_Change_MyFaceStyle_Item(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Change_MyFaceStyle_Item", "nnnsns"); }

        int LAG_DataPool_Change_MyHeadStyle(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Change_MyHeadStyle", ""); }

        int LAG_DataPool_Change_MyHeadStyle_Item(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Change_MyHeadStyle_Item", "nnnnsnss"); }

        int LAG_DataPool_CheckBugFBtime(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "CheckBugFBtime", "b"); }

        int LAG_DataPool_CheckCanSubmitBug(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "CheckCanSubmitBug", "b"); }

        int LAG_DataPool_CleanQinChiDaoData(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "CleanQinChiDaoData", "n"); }

        int LAG_DataPool_ClearActionItemForShow(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "ClearActionItemForShow", ""); }

        int LAG_DataPool_Clear_ChatAction_Bar(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Clear_ChatAction_Bar", ""); }

        int LAG_DataPool_CreateActionItemForShow(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "CreateActionItemForShow", "ob"); }

        int LAG_DataPool_CreateActionItemForShowDisable(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "CreateActionItemForShowDisable", "ob"); }

        int LAG_DataPool_CreateActionItemForShowWithMaxNum(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "CreateActionItemForShowWithMaxNum", "ob"); }

        int LAG_DataPool_CreateBindActionItemForShow(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "CreateBindActionItemForShow", "ob"); }

        int LAG_DataPool_CreateBindActionItemForShowWithMaxNum(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "CreateBindActionItemForShowWithMaxNum", "ob"); }


        int LAG_DataPool_DarkAdjustAttr(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "DarkAdjustAttr", ""); }


        int LAG_DataPool_DarkAdjustSkill(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "DarkAdjustSkill", ""); }


        int LAG_DataPool_DarkReset(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "DarkReset", ""); }


        int LAG_DataPool_DarkResetQuality(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "DarkResetQuality", ""); }


        int LAG_DataPool_DelTrustFriend(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "DelTrustFriend", ""); }

        int LAG_DataPool_DiffDayCount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "DiffDayCount", "n"); }


        int LAG_DataPool_DoMobileApprove(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "DoMobileApprove", "n"); }


        int LAG_DataPool_DoSMSCodeMobileApprove(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "DoSMSCodeMobileApprove", "n"); }


        int LAG_DataPool_EnterChallengeView(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "EnterChallengeView", "n"); }

        int LAG_DataPool_EnumProvinces(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "EnumProvinces", "ns"); }

        int LAG_DataPool_EnumTeamBoardGoal(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "EnumTeamBoardGoal", "nn"); }


        int LAG_DataPool_FriendSetClicked(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "FriendSetClicked", "n"); }


        int LAG_DataPool_FunChallenge(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "FunChallenge", ""); }

        int LAG_DataPool_GetAccVipLevel(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetAccVipLevel", "n"); }

        int LAG_DataPool_GetAutoSearch(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetAutoSearch", "nnnsss"); }

        int LAG_DataPool_GetAutoSearchOriginalHide(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetAutoSearchOriginalHide", "nn"); }

        int LAG_DataPool_GetAutoSearchPriority(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetAutoSearchPriority", "n"); }

        int LAG_DataPool_GetAutoSearchSceneStartEnd(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetAutoSearchSceneStartEnd", "nn"); }

        int LAG_DataPool_GetBaseBag_BaseNum(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetBaseBag_BaseNum", "n"); }

        int LAG_DataPool_GetBaseBag_MaxNum(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetBaseBag_MaxNum", "n"); }

        int LAG_DataPool_GetBaseBag_Num(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetBaseBag_Num", "n"); }

        int LAG_DataPool_GetBaseBag_RealMaxNum(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetBaseBag_RealMaxNum", "n"); }

        int LAG_DataPool_GetBugFBcount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetBugFBcount", "n"); }

        int LAG_DataPool_GetChallengeCount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetChallengeCount", "n"); }

        int LAG_DataPool_GetChallengeInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetChallengeInfo", "nnsnnnnsnnn"); }

        int LAG_DataPool_GetChallengeTeamMemberCount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetChallengeTeamMemberCount", "n"); }

        int LAG_DataPool_GetChallengeTeamMemberInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetChallengeTeamMemberInfo", "sssnn"); }

        int LAG_DataPool_GetCityNumFromOneProvinceId(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetCityNumFromOneProvinceId", "n"); }

        int LAG_DataPool_GetCurDialogNpcId(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetCurDialogNpcId", "n"); }

        int LAG_DataPool_GetCurrentChatChannel(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetCurrentChatChannel", "n"); }

        int LAG_DataPool_GetCurrentChatIndex(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetCurrentChatIndex", "n"); }

        int LAG_DataPool_GetDarkSkillDesc(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetDarkSkillDesc", "sss"); }

        int LAG_DataPool_GetDarkSkillNewDesc(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetDarkSkillNewDesc", "sss"); }

        int LAG_DataPool_GetDeliveryMissionTrackInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetDeliveryMissionTrackInfo", "ssnnn"); }

        int LAG_DataPool_GetDestroyErciQueRen(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetDestroyErciQueRen", "n"); }

        int LAG_DataPool_GetDifDayWithServerTime(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetDifDayWithServerTime", "n"); }

        int LAG_DataPool_GetDiffDay(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetDiffDay", "n"); }

        int LAG_DataPool_GetFixKfsBase(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetFixKfsBase", "n"); }

        int LAG_DataPool_GetFriendByGUID(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetFriendByGUID", "nn"); }

        int LAG_DataPool_GetFriendNumberCommon(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetFriendNumberCommon", "n"); }

        int LAG_DataPool_GetFriendOnlineNumber(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetFriendOnlineNumber", "n"); }

        int LAG_DataPool_GetFriendOnlineNumberCommon(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetFriendOnlineNumberCommon", "n"); }

        int LAG_DataPool_GetGroupingName(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetGroupingName", "s"); }

        int LAG_DataPool_GetHusongMissionTrackInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetHusongMissionTrackInfo", "sssnnn"); }

        int LAG_DataPool_GetIMChatData(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetIMChatData", "s"); }

        int LAG_DataPool_GetIMChatNumber(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetIMChatNumber", "n"); }

        int LAG_DataPool_GetIMRecentByGUID(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetIMRecentByGUID", "n"); }

        int LAG_DataPool_GetIMRecentByIndex(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetIMRecentByIndex", "ns"); }

        int LAG_DataPool_GetKFSNewSkillDesc(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetKFSNewSkillDesc", "s"); }

        int LAG_DataPool_GetKFSSkillDesc(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetKFSSkillDesc", "s"); }

        int LAG_DataPool_GetKfsBase(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetKfsBase", "n"); }

        int LAG_DataPool_GetKfsData(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetKfsData", "s"); }

        int LAG_DataPool_GetKfsFixAttrEx(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetKfsFixAttrEx", "sn"); }

        int LAG_DataPool_GetKfsSkill(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetKfsSkill", "n"); }

        int LAG_DataPool_GetKillMonsterMissionTrackInfo_MonsterInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetKillMonsterMissionTrackInfo_MonsterInfo", "sssnnn"); }

        int LAG_DataPool_GetKillMonsterMissionTrackInfo_num(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetKillMonsterMissionTrackInfo_num", "n"); }

        int LAG_DataPool_GetLeftProtectTime(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetLeftProtectTime", "n"); }

        int LAG_DataPool_GetLookUpPartInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetLookUpPartInfo", "s"); }

        int LAG_DataPool_GetLootItemMissionTrackInfo_ItemInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetLootItemMissionTrackInfo_ItemInfo", "ssssnnn"); }

        int LAG_DataPool_GetLootItemMissionTrackInfo_num(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetLootItemMissionTrackInfo_num", "n"); }

        int LAG_DataPool_GetLuaMissionTrackInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetLuaMissionTrackInfo", "s"); }

        int LAG_DataPool_GetMailTimeInt(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetMailTimeInt", "n"); }

        int LAG_DataPool_GetMatBag_BaseNum(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetMatBag_BaseNum", "n"); }

        int LAG_DataPool_GetMatBag_MaxNum(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetMatBag_MaxNum", "n"); }

        int LAG_DataPool_GetMatBag_Num(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetMatBag_Num", "n"); }

        int LAG_DataPool_GetMatBag_RealMaxNum(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetMatBag_RealMaxNum", "n"); }

        int LAG_DataPool_GetMenPaiName(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetMenPaiName", "s"); }

        int LAG_DataPool_GetMissionFinishInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetMissionFinishInfo", "ssnnn"); }

        int LAG_DataPool_GetMissionShortName(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetMissionShortName", "ns"); }

        int LAG_DataPool_GetMission_WhetherComplete(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetMission_WhetherComplete", "n"); }


        int LAG_DataPool_GetMobileApprovePrize(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetMobileApprovePrize", "n"); }


        int LAG_DataPool_GetMobileApproveSecurityCode(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetMobileApproveSecurityCode", "n"); }

        int LAG_DataPool_GetMobileApproveStatus(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetMobileApproveStatus", "n"); }

        int LAG_DataPool_GetMobilePhoneNumber(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetMobilePhoneNumber", "s"); }


        int LAG_DataPool_GetMonsterNameAndIcon(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetMonsterNameAndIcon", ""); }

        int LAG_DataPool_GetMsgDetail(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetMsgDetail", "s"); }

        int LAG_DataPool_GetMsgNum(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetMsgNum", "n"); }

        int LAG_DataPool_GetMsgPlayerGuild(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetMsgPlayerGuild", "sn"); }

        int LAG_DataPool_GetMsgTimeTitle(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetMsgTimeTitle", "ss"); }

        int LAG_DataPool_GetMsgType(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetMsgType", "n"); }

        int LAG_DataPool_GetNameWithServerInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetNameWithServerInfo", "s"); }

        int LAG_DataPool_GetPaoShangData(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetPaoShangData", "nnnnnn"); }

        int LAG_DataPool_GetPaoShangItemBuyPirceLvl(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetPaoShangItemBuyPirceLvl", "n"); }

        int LAG_DataPool_GetPetFightList_Show1(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetPetFightList_Show1", "n"); }

        int LAG_DataPool_GetPetFightList_Show2(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetPetFightList_Show2", "n"); }

        int LAG_DataPool_GetPetSkinJiHuoDataId(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetPetSkinJiHuoDataId", "n"); }

        int LAG_DataPool_GetPetSkinJiHuoDatasIndex(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetPetSkinJiHuoDatasIndex", "n"); }

        int LAG_DataPool_GetPetTujianJiHuoType(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetPetTujianJiHuoType", "n"); }

        int LAG_DataPool_GetPetTujianName(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetPetTujianName", "s"); }

        int LAG_DataPool_GetPetTujianNum(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetPetTujianNum", "n"); }

        int LAG_DataPool_GetPetTujianPetInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetPetTujianPetInfo", "sns"); }

        int LAG_DataPool_GetPetsOneTypeNum(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetPetsOneTypeNum", "n"); }

        int LAG_DataPool_GetPlayerMissionIndexByID(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetPlayerMissionIndexByID", "n"); }

        int LAG_DataPool_GetPlayerMissionRandomCustom(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetPlayerMissionRandomCustom", "snn"); }

        int LAG_DataPool_GetPlayerMissionRandomCustom_Num(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetPlayerMissionRandomCustom_Num", "n"); }

        int LAG_DataPool_GetPlayerMissionTrackType(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetPlayerMissionTrackType", "nn"); }

        int LAG_DataPool_GetPlayerMission_ActivePos(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetPlayerMission_ActivePos", ""); }

        int LAG_DataPool_GetPlayerMission_DelActivePos(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetPlayerMission_DelActivePos", ""); }

        int LAG_DataPool_GetPlayerMission_ForePart(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetPlayerMission_ForePart", "n"); }

        int LAG_DataPool_GetPlayerMission_StrList(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetPlayerMission_StrList", "ss"); }

        int LAG_DataPool_GetPlayerMission_VariableByByte(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetPlayerMission_VariableByByte", "n"); }

        int LAG_DataPool_GetPortraitByID(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetPortraitByID", "s"); }

        int LAG_DataPool_GetPrescrList_Item_LifeAbilityLevel(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetPrescrList_Item_LifeAbilityLevel", "n"); }

        int LAG_DataPool_GetProposerCount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetProposerCount", "n"); }

        int LAG_DataPool_GetProvincesNum(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetProvincesNum", "n"); }

        int LAG_DataPool_GetQinChiDaoTopListCount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetQinChiDaoTopListCount", "n"); }

        int LAG_DataPool_GetQinChiDaoTopListInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetQinChiDaoTopListInfo", "sn"); }


        int LAG_DataPool_GetRomanInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetRomanInfo", ""); }


        int LAG_DataPool_GetSMSCodeSecurityCode(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetSMSCodeSecurityCode", "n"); }

        int LAG_DataPool_GetSearchResultByGUID(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetSearchResultByGUID", "n"); }

        int LAG_DataPool_GetSearchResultByIndex(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetSearchResultByIndex", "ns"); }

        int LAG_DataPool_GetSearchResultNum(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetSearchResultNum", "n"); }

        int LAG_DataPool_GetSectType(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetSectType", "n"); }

        int LAG_DataPool_GetSelfZoneWorldID(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetSelfZoneWorldID", "n"); }

        int LAG_DataPool_GetSellErciQueRen(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetSellErciQueRen", "n"); }

        int LAG_DataPool_GetServerDayTime(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetServerDayTime", "n"); }

        int LAG_DataPool_GetServerMinuteTime(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetServerMinuteTime", "n"); }

        int LAG_DataPool_GetServerName(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetServerName", "s"); }

        int LAG_DataPool_GetServerWeekDayTime(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetServerWeekDayTime", "n"); }

        int LAG_DataPool_GetSystemHistroy(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetSystemHistroy", "s"); }

        int LAG_DataPool_GetSystemHistroyNumber(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetSystemHistroyNumber", "n"); }

        int LAG_DataPool_GetTaskBag_BaseNum(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetTaskBag_BaseNum", "n"); }

        int LAG_DataPool_GetTaskBag_MaxNum(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetTaskBag_MaxNum", "n"); }

        int LAG_DataPool_GetTaskBag_Num(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetTaskBag_Num", "n"); }

        int LAG_DataPool_GetTeamBoardGoalNum(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetTeamBoardGoalNum", "n"); }

        int LAG_DataPool_GetTeamExpMode(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetTeamExpMode", "n"); }

        int LAG_DataPool_GetTeamMemBufInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetTeamMemBufInfo", ""); }

        int LAG_DataPool_GetTeamMemBufIsShowIcon(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetTeamMemBufIsShowIcon", "n"); }

        int LAG_DataPool_GetTeamMemBufNum(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetTeamMemBufNum", "n"); }

        int LAG_DataPool_GetTeamMemBufPriority(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetTeamMemBufPriority", "n"); }

        int LAG_DataPool_GetTeamMemInfoExByIndex(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetTeamMemInfoExByIndex", "snsnn"); }

        int LAG_DataPool_GetTeamMemNameByUIIndex(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetTeamMemNameByUIIndex", "s"); }

        int LAG_DataPool_GetTeamMemSandBoxHPInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetTeamMemSandBoxHPInfo", "nn"); }

        int LAG_DataPool_GetTopGUID(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetTopGUID", "n"); }

        int LAG_DataPool_GetTransBWaitTime(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetTransBWaitTime", "n"); }

        int LAG_DataPool_GetTrustFriend(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetTrustFriend", "n"); }

        int LAG_DataPool_GetTrustFriendNumber(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetTrustFriendNumber", "n"); }

        int LAG_DataPool_GetXiuChangRoomCount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetXiuChangRoomCount", "n"); }

        int LAG_DataPool_GetXiuChangRoomInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetXiuChangRoomInfo", "snsn"); }

        int LAG_DataPool_GetXiuChangSelectRoomInd(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "GetXiuChangSelectRoomInd", "n"); }

        int LAG_DataPool_Get_DIYFrame_Item(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Get_DIYFrame_Item", "nsnnsnn"); }

        int LAG_DataPool_Get_MyFaceStyle(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Get_MyFaceStyle", "n"); }

        int LAG_DataPool_Get_MyHeadStyle(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Get_MyHeadStyle", "n"); }

        int LAG_DataPool_Get_RMB_ChatActionInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Get_RMB_ChatActionInfo", "nssss"); }

        int LAG_DataPool_Get_RMB_ChatActionName(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Get_RMB_ChatActionName", "s"); }

        int LAG_DataPool_Get_RMB_ChatActionRealID(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Get_RMB_ChatActionRealID", "n"); }

        int LAG_DataPool_Get_RMB_ChatActionValidHour(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Get_RMB_ChatActionValidHour", "n"); }

        int LAG_DataPool_HandleGameSetupAction(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "HandleGameSetupAction", ""); }

        int LAG_DataPool_HaveMisstionTrackThisType(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "HaveMisstionTrackThisType", "n"); }

        int LAG_DataPool_HaveNewIMMsg(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "HaveNewIMMsg", "n"); }

        int LAG_DataPool_IfHaveBuffByID(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "IfHaveBuffByID", "n"); }

        int LAG_DataPool_InitPetSkinJiHuoDatas(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "InitPetSkinJiHuoDatas", ""); }


        int LAG_DataPool_InviteAddFriend(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "InviteAddFriend", ""); }


        int LAG_DataPool_InviteAddFriendByFriendList(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "InviteAddFriendByFriendList", ""); }


        int LAG_DataPool_InviteAddFriendByteam(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "InviteAddFriendByteam", ""); }


        int LAG_DataPool_InviteApplyAddPingbi(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "InviteApplyAddPingbi", "o"); }

        int LAG_DataPool_IsCampaignCanTrack(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "IsCampaignCanTrack", "n"); }

        int LAG_DataPool_IsCampaignTrackOpen(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "IsCampaignTrackOpen", "n"); }

        int LAG_DataPool_IsMissionTrackOpen(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "IsMissionTrackOpen", "n"); }

        int LAG_DataPool_IsMsgRead(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "IsMsgRead", "n"); }

        int LAG_DataPool_IsPetsOneType_HH(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "IsPetsOneType_HH", "n"); }

        int LAG_DataPool_IsTrackFuncShow(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "IsTrackFuncShow", "n"); }

        int LAG_DataPool_IsTrustFriend(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "IsTrustFriend", "n"); }

        int LAG_DataPool_KFS_UpdateKFSModel(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "KFS_UpdateKFSModel", ""); }


        int LAG_DataPool_LookupOtherParticularInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LookupOtherParticularInfo", ""); }

        int LAG_DataPool_LuaFnCalcEquipDWAttr(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnCalcEquipDWAttr", ""); }


        int LAG_DataPool_LuaFnCastChangeWGSkill(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnCastChangeWGSkill", ""); }

        int LAG_DataPool_LuaFnCheckEmo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnCheckEmo", "s"); }

        int LAG_DataPool_LuaFnCreateActionElfForSelect(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnCreateActionElfForSelect", "ob"); }

        int LAG_DataPool_LuaFnEnumBagShenBingSkillAction(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnEnumBagShenBingSkillAction", "o"); }

        int LAG_DataPool_LuaFnEnumDressCollectionFromList(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnEnumDressCollectionFromList", "nnnnnssn"); }

        int LAG_DataPool_LuaFnEnumDressSeriesExteriorIdx(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnEnumDressSeriesExteriorIdx", "n"); }

        int LAG_DataPool_LuaFnEnumEmoInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnEnumEmoInfo", "nss"); }

        int LAG_DataPool_LuaFnEnumEquipRefreshAttr(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnEnumEquipRefreshAttr", "s"); }

        int LAG_DataPool_LuaFnEnumEquipShenBingSkillAction(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnEnumEquipShenBingSkillAction", "o"); }

        int LAG_DataPool_LuaFnEnumFeaturesID(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnEnumFeaturesID", "n"); }

        int LAG_DataPool_LuaFnEnumFeaturesIdFromTable(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnEnumFeaturesIdFromTable", "n"); }

        int LAG_DataPool_LuaFnEnumRideCollectionEffect(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnEnumRideCollectionEffect", "n"); }

        int LAG_DataPool_LuaFnEnumRideCollectionFromList(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnEnumRideCollectionFromList", "nn"); }

        int LAG_DataPool_LuaFnEnumRideSeriesExteriorRideId(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnEnumRideSeriesExteriorRideId", "n"); }

        int LAG_DataPool_LuaFnEnumShenBingJianSkillAction(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnEnumShenBingJianSkillAction", "o"); }

        int LAG_DataPool_LuaFnEquipRefreshBindConfirmed(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnEquipRefreshBindConfirmed", ""); }

        int LAG_DataPool_LuaFnEquipRefreshCloseConfirmed(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnEquipRefreshCloseConfirmed", ""); }

        int LAG_DataPool_LuaFnEquipRefreshEquipChangeConfirmed(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnEquipRefreshEquipChangeConfirmed", ""); }

        int LAG_DataPool_LuaFnFittingFashion(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnFittingFashion", ""); }

        int LAG_DataPool_LuaFnGet2025Q1ZSBBYDMD_ConditionIsFinish(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGet2025Q1ZSBBYDMD_ConditionIsFinish", "n"); }

        int LAG_DataPool_LuaFnGetAttributeDesc(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetAttributeDesc", ""); }

        int LAG_DataPool_LuaFnGetCurFashionLotteryIndex(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetCurFashionLotteryIndex", "n"); }

        int LAG_DataPool_LuaFnGetDFengEssenceKongWeiActiveData(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetDFengEssenceKongWeiActiveData", "n"); }

        int LAG_DataPool_LuaFnGetDFengEssenceKongWeiDataByIndex(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetDFengEssenceKongWeiDataByIndex", "nnnnn"); }

        int LAG_DataPool_LuaFnGetDFengEssenceKongWeiTableData(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetDFengEssenceKongWeiTableData", "nnnn"); }

        int LAG_DataPool_LuaFnGetDFengEssenceSectionAndSelectedIndex(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetDFengEssenceSectionAndSelectedIndex", "nn"); }

        int LAG_DataPool_LuaFnGetDiaoWenName(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetDiaoWenName", "s"); }

        int LAG_DataPool_LuaFnGetDiaoWenRankMaxExp(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetDiaoWenRankMaxExp", "n"); }

        int LAG_DataPool_LuaFnGetDressCollectEffectMaxCount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetDressCollectEffectMaxCount", "n"); }

        int LAG_DataPool_LuaFnGetDressCollectionEffectInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetDressCollectionEffectInfo", "nnn"); }

        int LAG_DataPool_LuaFnGetDressCollectionMaxCount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetDressCollectionMaxCount", "nn"); }

        int LAG_DataPool_LuaFnGetDressCollectionToolTip(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetDressCollectionToolTip", "nnnns"); }

        int LAG_DataPool_LuaFnGetDressInfoByExteriorId(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetDressInfoByExteriorId", "n"); }

        int LAG_DataPool_LuaFnGetEmoSetId(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetEmoSetId", "n"); }

        int LAG_DataPool_LuaFnGetEmoSetName(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetEmoSetName", "s"); }

        int LAG_DataPool_LuaFnGetEmoValidHour(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetEmoValidHour", "n"); }

        int LAG_DataPool_LuaFnGetEquipDWAttr(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetEquipDWAttr", "nss"); }

        int LAG_DataPool_LuaFnGetEquipDiaoWenEffect(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetEquipDiaoWenEffect", "s"); }

        int LAG_DataPool_LuaFnGetEquipDiaoWenFeaturesId(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetEquipDiaoWenFeaturesId", "n"); }

        int LAG_DataPool_LuaFnGetEquipDiaoWenJinJieEffect(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetEquipDiaoWenJinJieEffect", "s"); }

        int LAG_DataPool_LuaFnGetEquipDiaoWenRank(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetEquipDiaoWenRank", "n"); }

        int LAG_DataPool_LuaFnGetEquipDiaoWenRankExp(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetEquipDiaoWenRankExp", "n"); }

        int LAG_DataPool_LuaFnGetEquipDiaowenExp(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetEquipDiaowenExp", "n"); }

        int LAG_DataPool_LuaFnGetEquipDiaowenInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetEquipDiaowenInfo", "n"); }

        int LAG_DataPool_LuaFnGetEquipPointByTableIndex(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetEquipPointByTableIndex", "n"); }

        int LAG_DataPool_LuaFnGetEquipRefreshAttrCount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetEquipRefreshAttrCount", "n"); }

        int LAG_DataPool_LuaFnGetEquipTotalFeaturesValue(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetEquipTotalFeaturesValue", "nn"); }

        int LAG_DataPool_LuaFnGetEquipTotalValidFeaturesDesc(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetEquipTotalValidFeaturesDesc", "s"); }

        int LAG_DataPool_LuaFnGetEquipedShenBingData(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetEquipedShenBingData", "nn"); }

        int LAG_DataPool_LuaFnGetEquipedShenBingStarInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetEquipedShenBingStarInfo", "nn"); }

        int LAG_DataPool_LuaFnGetExteriorRideIdFromRideCard(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetExteriorRideIdFromRideCard", "n"); }

        int LAG_DataPool_LuaFnGetFashionAuctionBiddingInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetFashionAuctionBiddingInfo", "n"); }

        int LAG_DataPool_LuaFnGetFashionAuctionGroupIndexFromList(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetFashionAuctionGroupIndexFromList", "n"); }

        int LAG_DataPool_LuaFnGetFashionAuctionTopBidSortType(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetFashionAuctionTopBidSortType", "n"); }

        int LAG_DataPool_LuaFnGetFashionAuctionType(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetFashionAuctionType", "n"); }

        int LAG_DataPool_LuaFnGetFashionLotteryStage(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetFashionLotteryStage", "n"); }

        int LAG_DataPool_LuaFnGetFeaturesDesc(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetFeaturesDesc", "s"); }

        int LAG_DataPool_LuaFnGetFeaturesEffectLimitDesc(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetFeaturesEffectLimitDesc", "s"); }

        int LAG_DataPool_LuaFnGetFeaturesEffectValueMax(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetFeaturesEffectValueMax", "nn"); }

        int LAG_DataPool_LuaFnGetFeaturesInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetFeaturesInfo", "n"); }

        int LAG_DataPool_LuaFnGetFeaturesListCount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetFeaturesListCount", "n"); }

        int LAG_DataPool_LuaFnGetFeaturesMaxCount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetFeaturesMaxCount", "n"); }

        int LAG_DataPool_LuaFnGetIcePrizeDrawCount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetIcePrizeDrawCount", "n"); }

        int LAG_DataPool_LuaFnGetIcePrizeDrawCountById(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetIcePrizeDrawCountById", "n"); }

        int LAG_DataPool_LuaFnGetIcePrizeDrawDataByInDex(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetIcePrizeDrawDataByInDex", "nn"); }

        int LAG_DataPool_LuaFnGetIcePrizeDrawInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetIcePrizeDrawInfo", "nnnn"); }

        int LAG_DataPool_LuaFnGetIcePrizeDrawListCount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetIcePrizeDrawListCount", "n"); }

        int LAG_DataPool_LuaFnGetIcePrizeDrawNowId(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetIcePrizeDrawNowId", "n"); }

        int LAG_DataPool_LuaFnGetIcePrizeDrawNowState(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetIcePrizeDrawNowState", "n"); }

        int LAG_DataPool_LuaFnGetItemIconByTableIndex(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetItemIconByTableIndex", "s"); }

        int LAG_DataPool_LuaFnGetItemNameByTableIndex(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetItemNameByTableIndex", "s"); }

        int LAG_DataPool_LuaFnGetItemPetElfAttrDesc(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetItemPetElfAttrDesc", ""); }

        int LAG_DataPool_LuaFnGetItemPetElfModel(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetItemPetElfModel", "n"); }

        int LAG_DataPool_LuaFnGetItemPetElfMutualId(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetItemPetElfMutualId", "n"); }

        int LAG_DataPool_LuaFnGetLingYuAttrCount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetLingYuAttrCount", "n"); }

        int LAG_DataPool_LuaFnGetLingYuAttrName(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetLingYuAttrName", "s"); }

        int LAG_DataPool_LuaFnGetLingYuAttrValueString(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetLingYuAttrValueString", "s"); }

        int LAG_DataPool_LuaFnGetLingYuSetAttrDesc(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetLingYuSetAttrDesc", "s"); }

        int LAG_DataPool_LuaFnGetLingYuSetEffectCount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetLingYuSetEffectCount", "n"); }

        int LAG_DataPool_LuaFnGetLingYuSetSkillForUI(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetLingYuSetSkillForUI", "n"); }

        int LAG_DataPool_LuaFnGetLotteryNumber(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetLotteryNumber", "n"); }

        int LAG_DataPool_LuaFnGetLotterySignUpFlag(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetLotterySignUpFlag", "n"); }

        int LAG_DataPool_LuaFnGetLotteryTakeBackFlag(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetLotteryTakeBackFlag", "n"); }

        int LAG_DataPool_LuaFnGetMD(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetMD", "n"); }

        int LAG_DataPool_LuaFnGetMF(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetMF", "n"); }

        int LAG_DataPool_LuaFnGetMyLotteryNumber(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetMyLotteryNumber", "n"); }

        int LAG_DataPool_LuaFnGetNecklaceDW(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetNecklaceDW", "nss"); }

        int LAG_DataPool_LuaFnGetOtherEquipDiaoWenEffect(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetOtherEquipDiaoWenEffect", "s"); }

        int LAG_DataPool_LuaFnGetOtherEquipDiaoWenFeaturesId(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetOtherEquipDiaoWenFeaturesId", "n"); }

        int LAG_DataPool_LuaFnGetOtherEquipDiaoWenJinJieEffect(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetOtherEquipDiaoWenJinJieEffect", "s"); }

        int LAG_DataPool_LuaFnGetOtherEquipDiaoWenRank(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetOtherEquipDiaoWenRank", "n"); }

        int LAG_DataPool_LuaFnGetOtherEquipDiaoWenRankExp(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetOtherEquipDiaoWenRankExp", "n"); }

        int LAG_DataPool_LuaFnGetOtherEquipDiaowenExp(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetOtherEquipDiaowenExp", "n"); }

        int LAG_DataPool_LuaFnGetOtherEquipDiaowenInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetOtherEquipDiaowenInfo", "n"); }

        int LAG_DataPool_LuaFnGetOtherEquipTotalFeaturesValue(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetOtherEquipTotalFeaturesValue", "nn"); }

        int LAG_DataPool_LuaFnGetOtherEquipTotalValidFeaturesDesc(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetOtherEquipTotalValidFeaturesDesc", "s"); }

        int LAG_DataPool_LuaFnGetOtherEquipedShenBingStarInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetOtherEquipedShenBingStarInfo", "nn"); }

        int LAG_DataPool_LuaFnGetOtherFeaturesEffectLimitDesc(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetOtherFeaturesEffectLimitDesc", "s"); }

        int LAG_DataPool_LuaFnGetOtherFeaturesInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetOtherFeaturesInfo", "n"); }

        int LAG_DataPool_LuaFnGetOtherLingYuAttrCount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetOtherLingYuAttrCount", "n"); }

        int LAG_DataPool_LuaFnGetOtherLingYuAttrName(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetOtherLingYuAttrName", "s"); }

        int LAG_DataPool_LuaFnGetOtherLingYuAttrValueString(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetOtherLingYuAttrValueString", "s"); }

        int LAG_DataPool_LuaFnGetOtherLingYuSetAttrDesc(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetOtherLingYuSetAttrDesc", "s"); }

        int LAG_DataPool_LuaFnGetOtherLingYuSetEffectCount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetOtherLingYuSetEffectCount", "n"); }

        int LAG_DataPool_LuaFnGetOtherShenBingExtensionAttr(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetOtherShenBingExtensionAttr", ""); }

        int LAG_DataPool_LuaFnGetOtherWHWGAllAttrCount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetOtherWHWGAllAttrCount", "n"); }

        int LAG_DataPool_LuaFnGetOtherWHWGAllAttrDesc(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetOtherWHWGAllAttrDesc", ""); }

        int LAG_DataPool_LuaFnGetRanSePlanAddNum(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetRanSePlanAddNum", "n"); }

        int LAG_DataPool_LuaFnGetRideCardActivedFlag(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetRideCardActivedFlag", "n"); }

        int LAG_DataPool_LuaFnGetRideCardHaveRideCount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetRideCardHaveRideCount", "n"); }

        int LAG_DataPool_LuaFnGetRideCardLeftTime(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetRideCardLeftTime", "n"); }

        int LAG_DataPool_LuaFnGetRideCollectionEffectSummary(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetRideCollectionEffectSummary", "n"); }

        int LAG_DataPool_LuaFnGetRideCollectionListCount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetRideCollectionListCount", "n"); }

        int LAG_DataPool_LuaFnGetRideCollectionMaxCount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetRideCollectionMaxCount", "n"); }

        int LAG_DataPool_LuaFnGetRideSeriesInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetRideSeriesInfo", "n"); }

        int LAG_DataPool_LuaFnGetShenBingCount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetShenBingCount", "n"); }

        int LAG_DataPool_LuaFnGetShenBingExtensionAttr(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetShenBingExtensionAttr", ""); }

        int LAG_DataPool_LuaFnGetShenBingFromJian(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetShenBingFromJian", "n"); }

        int LAG_DataPool_LuaFnGetShenBingSkillDesc(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetShenBingSkillDesc", "s"); }

        int LAG_DataPool_LuaFnGetSnowShopCJItemInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetSnowShopCJItemInfo", "n"); }

        int LAG_DataPool_LuaFnGetWHWGAllAttrCount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetWHWGAllAttrCount", "n"); }

        int LAG_DataPool_LuaFnGetWHWGAllAttrDesc(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetWHWGAllAttrDesc", ""); }

        int LAG_DataPool_LuaFnGetWHWGIDFromList(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetWHWGIDFromList", "n"); }

        int LAG_DataPool_LuaFnGetWHWGInSlot(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetWHWGInSlot", "n"); }

        int LAG_DataPool_LuaFnGetWHWGInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetWHWGInfo", "n"); }

        int LAG_DataPool_LuaFnGetWHWGLevelInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetWHWGLevelInfo", "nnnn"); }

        int LAG_DataPool_LuaFnGetWHWGListCount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetWHWGListCount", "n"); }

        int LAG_DataPool_LuaFnGetWHWGMaxCount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetWHWGMaxCount", "n"); }

        int LAG_DataPool_LuaFnGetWorldAuctionBiddingInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetWorldAuctionBiddingInfo", "n"); }

        int LAG_DataPool_LuaFnGetWorldAuctionGetTime(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetWorldAuctionGetTime", "n"); }

        int LAG_DataPool_LuaFnGetWorldAuctionIdByIndex(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetWorldAuctionIdByIndex", "n"); }

        int LAG_DataPool_LuaFnGetWorldAuctionIsUpItemTime(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetWorldAuctionIsUpItemTime", "n"); }

        int LAG_DataPool_LuaFnGetWorldAuctionItemNameById(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetWorldAuctionItemNameById", "s"); }

        int LAG_DataPool_LuaFnGetWorldAuctionListCount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetWorldAuctionListCount", "n"); }

        int LAG_DataPool_LuaFnGetWorldAuctionTopBidSortType(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetWorldAuctionTopBidSortType", "n"); }

        int LAG_DataPool_LuaFnGetYYFlag(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnGetYYFlag", "n"); }

        int LAG_DataPool_LuaFnInitDressCollectionList(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnInitDressCollectionList", ""); }

        int LAG_DataPool_LuaFnInitFeaturesList(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnInitFeaturesList", ""); }

        int LAG_DataPool_LuaFnInitRideCollectionList(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnInitRideCollectionList", ""); }

        int LAG_DataPool_LuaFnInitWHWGList(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnInitWHWGList", ""); }

        int LAG_DataPool_LuaFnIsActiveDressCollectByExteriorIdx(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnIsActiveDressCollectByExteriorIdx", "n"); }

        int LAG_DataPool_LuaFnIsCanReliveInDLSY(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnIsCanReliveInDLSY", "n"); }

        int LAG_DataPool_LuaFnIsCanReliveInTJCPVP(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnIsCanReliveInTJCPVP", "n"); }

        int LAG_DataPool_LuaFnIsCurLotteryGetNumberOver(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnIsCurLotteryGetNumberOver", "n"); }

        int LAG_DataPool_LuaFnIsEquipHaveValidFeaturesEffect(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnIsEquipHaveValidFeaturesEffect", "n"); }

        int LAG_DataPool_LuaFnIsEquipShenBing(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnIsEquipShenBing", "n"); }

        int LAG_DataPool_LuaFnIsExteriorRideActiveByRideCard(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnIsExteriorRideActiveByRideCard", "n"); }

        int LAG_DataPool_LuaFnIsLotteryDraw(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnIsLotteryDraw", "n"); }

        int LAG_DataPool_LuaFnIsLotteryWin(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnIsLotteryWin", "n"); }

        int LAG_DataPool_LuaFnIsWorldAuctionItemByIndex(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnIsWorldAuctionItemByIndex", "n"); }

        int LAG_DataPool_LuaFnOpenFashionLotteryDressPreview(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnOpenFashionLotteryDressPreview", ""); }

        int LAG_DataPool_LuaFnOpenSocialServer(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnOpenSocialServer", "n"); }

        int LAG_DataPool_LuaFnOpenSocialServerFlag(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnOpenSocialServerFlag", "n"); }

        int LAG_DataPool_LuaFnOpenWHWG(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnOpenWHWG", ""); }

        int LAG_DataPool_LuaFnOpenWHWGChange(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnOpenWHWGChange", ""); }

        int LAG_DataPool_LuaFnOtherEnumEquipShenBingSkillAction(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnOtherEnumEquipShenBingSkillAction", "o"); }

        int LAG_DataPool_LuaFnOtherGetEquipedShenBingData(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnOtherGetEquipedShenBingData", "nn"); }

        int LAG_DataPool_LuaFnOtherIsEquipShenBing(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnOtherIsEquipShenBing", "n"); }


        int LAG_DataPool_LuaFnReqRideCardLeftTime(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnReqRideCardLeftTime", ""); }

        int LAG_DataPool_LuaFnSetFashionAuctionTopBidSortType(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnSetFashionAuctionTopBidSortType", ""); }

        int LAG_DataPool_LuaFnSetItemPetElfAvatar1Model(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnSetItemPetElfAvatar1Model", ""); }

        int LAG_DataPool_LuaFnSetItemPetElfAvatar2Model(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnSetItemPetElfAvatar2Model", ""); }

        int LAG_DataPool_LuaFnSetPetKaiWuPetModel(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnSetPetKaiWuPetModel", ""); }

        int LAG_DataPool_LuaFnSetPetKaiWuTargetPetModel(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnSetPetKaiWuTargetPetModel", ""); }

        int LAG_DataPool_LuaFnSetPetSoulAvatarModel(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnSetPetSoulAvatarModel", ""); }

        int LAG_DataPool_LuaFnSetWorldAuctionTopBidSortType(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnSetWorldAuctionTopBidSortType", ""); }

        int LAG_DataPool_LuaFnShowEquipRefreshCloseConfirm(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnShowEquipRefreshCloseConfirm", ""); }

        int LAG_DataPool_LuaFnShowEquipRefreshEquipChangeConfirm(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnShowEquipRefreshEquipChangeConfirm", ""); }

        int LAG_DataPool_LuaFnSortFashionAuctionList(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnSortFashionAuctionList", ""); }

        int LAG_DataPool_LuaFnSortWorldAuctionList(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnSortWorldAuctionList", ""); }


        int LAG_DataPool_LuaFnUnInstallEmo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnUnInstallEmo", ""); }

        int LAG_DataPool_LuaFnUpdateLingYuAttrList(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnUpdateLingYuAttrList", ""); }

        int LAG_DataPool_LuaFnUpdateOtherShenBingModel(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnUpdateOtherShenBingModel", ""); }

        int LAG_DataPool_LuaFnUpdatePetSoulAvatarFromPet(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnUpdatePetSoulAvatarFromPet", ""); }

        int LAG_DataPool_LuaFnUpdateShenBingCamera(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnUpdateShenBingCamera", ""); }

        int LAG_DataPool_LuaFnUpdateShenBingJianModel(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnUpdateShenBingJianModel", ""); }

        int LAG_DataPool_LuaFnUpdateShenBingModel(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnUpdateShenBingModel", ""); }

        int LAG_DataPool_LuaFnUpdateWHWGModel(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnUpdateWHWGModel", ""); }

        int LAG_DataPool_LuaFnWHWGAttrSTR(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnWHWGAttrSTR", ""); }

        int LAG_DataPool_LuaFnWHWGEffect(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaFnWHWGEffect", ""); }

        int LAG_DataPool_LuaGetCurrentServerTime(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "LuaGetCurrentServerTime", "n"); }

        int LAG_DataPool_Lua_ArriveServerTime_Add(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_ArriveServerTime_Add", ""); }

        int LAG_DataPool_Lua_ArriveServerTime_Clear(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_ArriveServerTime_Clear", ""); }

        int LAG_DataPool_Lua_CheckHJTSMissionForbiddenItem(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_CheckHJTSMissionForbiddenItem", "n"); }

        int LAG_DataPool_Lua_CheckIsShowTalent(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_CheckIsShowTalent", "n"); }

        int LAG_DataPool_Lua_CheckOpenTalent(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_CheckOpenTalent", "n"); }

        int LAG_DataPool_Lua_ClearFanChangItemInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_ClearFanChangItemInfo", ""); }

        int LAG_DataPool_Lua_ClearZNFCShopItemInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_ClearZNFCShopItemInfo", ""); }

        int LAG_DataPool_Lua_CreateSectInfoAction(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_CreateSectInfoAction", "o"); }

        int LAG_DataPool_Lua_DressGemListA_Update(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_DressGemListA_Update", "n"); }

        int LAG_DataPool_Lua_DressGemListB_Update(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_DressGemListB_Update", "n"); }

        int LAG_DataPool_Lua_GemComposeLayedItem_Update(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GemComposeLayedItem_Update", "n"); }

        int LAG_DataPool_Lua_GemMeltingLayedItem_Update(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GemMeltingLayedItem_Update", "n"); }

        int LAG_DataPool_Lua_GetAnnINTParamByIndex(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetAnnINTParamByIndex", "n"); }

        int LAG_DataPool_Lua_GetAnnWGDataByIndex(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetAnnWGDataByIndex", "nnnnnns"); }

        int LAG_DataPool_Lua_GetDDZBaoMingInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetDDZBaoMingInfo", ""); }

        int LAG_DataPool_Lua_GetDDZMatchCnt(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetDDZMatchCnt", "n"); }

        int LAG_DataPool_Lua_GetDDZMatchInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetDDZMatchInfo", ""); }

        int LAG_DataPool_Lua_GetDDZYaZhuInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetDDZYaZhuInfo", ""); }

        int LAG_DataPool_Lua_GetFestivalShopData(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetFestivalShopData", "t"); }

        int LAG_DataPool_Lua_GetFuQiShopDBConfirmSkip(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetFuQiShopDBConfirmSkip", "n"); }

        int LAG_DataPool_Lua_GetFuQiShopData(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetFuQiShopData", "t"); }

        int LAG_DataPool_Lua_GetFuQiShopTotalCount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetFuQiShopTotalCount", "n"); }

        int LAG_DataPool_Lua_GetIsBigWorld(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetIsBigWorld", "n"); }

        int LAG_DataPool_Lua_GetIsThreeDaLi(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetIsThreeDaLi", "n"); }

        int LAG_DataPool_Lua_GetItemNameByIndex(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetItemNameByIndex", "s"); }

        int LAG_DataPool_Lua_GetQingRenJieReceiveTopListInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetQingRenJieReceiveTopListInfo", "nnsn"); }

        int LAG_DataPool_Lua_GetQingRenJieSendTopListInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetQingRenJieSendTopListInfo", "nnsn"); }

        int LAG_DataPool_Lua_GetQixiReceiveTopListInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetQixiReceiveTopListInfo", "nnsn"); }

        int LAG_DataPool_Lua_GetQixiSendTopListInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetQixiSendTopListInfo", "nnsn"); }

        int LAG_DataPool_Lua_GetRoseReceiveTopListInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetRoseReceiveTopListInfo", "nsn"); }

        int LAG_DataPool_Lua_GetRoseSendTopListInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetRoseSendTopListInfo", "nsn"); }

        int LAG_DataPool_Lua_GetRoseTopListInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetRoseTopListInfo", "nssn"); }

        int LAG_DataPool_Lua_GetSectDesc(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetSectDesc", "s"); }

        int LAG_DataPool_Lua_GetSectName(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetSectName", "s"); }

        int LAG_DataPool_Lua_GetSectPoint(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetSectPoint", "n"); }

        int LAG_DataPool_Lua_GetSectSchema(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetSectSchema", "t"); }

        int LAG_DataPool_Lua_GetSectTotalLevel(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetSectTotalLevel", "n"); }

        int LAG_DataPool_Lua_GetSectinvest(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetSectinvest", "n"); }

        int LAG_DataPool_Lua_GetSongLiaoGuidFromlist(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetSongLiaoGuidFromlist", "nnnnn"); }

        int LAG_DataPool_Lua_GetSuperRecoinEnumAttr(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetSuperRecoinEnumAttr", "s"); }

        int LAG_DataPool_Lua_GetSuperRecoinNum(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetSuperRecoinNum", "n"); }


        int LAG_DataPool_Lua_GetTSPhoenixCamp(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetTSPhoenixCamp", "o"); }


        int LAG_DataPool_Lua_GetTSPhoenixData(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetTSPhoenixData", "o"); }


        int LAG_DataPool_Lua_GetTSPhoenixScore(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetTSPhoenixScore", "o"); }

        int LAG_DataPool_Lua_GetTargetSectMT(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetTargetSectMT", "nn"); }

        int LAG_DataPool_Lua_GetXiuChangUserRuleDes(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_GetXiuChangUserRuleDes", "s"); }

        int LAG_DataPool_Lua_HasSect(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_HasSect", "nn"); }

        int LAG_DataPool_Lua_IsHaveMission(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_IsHaveMission", "n"); }

        int LAG_DataPool_Lua_IsInTServer(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_IsInTServer", "n"); }

        int LAG_DataPool_Lua_IsMissionComplete(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_IsMissionComplete", "n"); }

        int LAG_DataPool_Lua_IsMissionHaveDone(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_IsMissionHaveDone", "n"); }


        int LAG_DataPool_Lua_OpenFuQiShop(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_OpenFuQiShop", ""); }

        int LAG_DataPool_Lua_SetFanChangItemInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_SetFanChangItemInfo", ""); }


        int LAG_DataPool_Lua_SetFuQiShopDBConfirmSkip(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_SetFuQiShopDBConfirmSkip", ""); }

        int LAG_DataPool_Lua_SetZNFCShopItemInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_SetZNFCShopItemInfo", "n"); }

        int LAG_DataPool_Lua_SortDDZRankInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Lua_SortDDZRankInfo", ""); }

        int LAG_DataPool_MissionTrackGotoQuestLog(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "MissionTrackGotoQuestLog", ""); }


        int LAG_DataPool_ModifyGroupingName(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "ModifyGroupingName", "n"); }

        int LAG_DataPool_NumCityFromOneProvince(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "NumCityFromOneProvince", "nn"); }

        int LAG_DataPool_OpenDelCheckBox(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "OpenDelCheckBox", ""); }

        int LAG_DataPool_OpenDelTrustFriendCheckBox(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "OpenDelTrustFriendCheckBox", ""); }

        int LAG_DataPool_OpenFenxianDlg(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "OpenFenxianDlg", ""); }


        int LAG_DataPool_OpenFirstFriendChatInMsgPool(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "OpenFirstFriendChatInMsgPool", "o"); }


        int LAG_DataPool_OpenIMChat(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "OpenIMChat", ""); }

        int LAG_DataPool_OpenMailRead(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "OpenMailRead", ""); }

        int LAG_DataPool_OpenSystemHistroy(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "OpenSystemHistroy", ""); }

        int LAG_DataPool_PetSkinJiHuoType(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "PetSkinJiHuoType", "n"); }

        int LAG_DataPool_PetSoulHandbook_SetCurSelLevel(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "PetSoulHandbook_SetCurSelLevel", ""); }

        int LAG_DataPool_PetSoulHandbook_SetPetModel(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "PetSoulHandbook_SetPetModel", "n"); }

        int LAG_DataPool_PetsOneTypeJiHuo_Index(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "PetsOneTypeJiHuo_Index", "n"); }

        int LAG_DataPool_PetsOneTypeJiHuo_JiHuoType(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "PetsOneTypeJiHuo_JiHuoType", "n"); }

        int LAG_DataPool_PetsOneType_GetAttr(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "PetsOneType_GetAttr", "nn"); }

        int LAG_DataPool_PetsOneType_SetModel(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "PetsOneType_SetModel", ""); }

        int LAG_DataPool_PetsOneType_SetModel77(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "PetsOneType_SetModel77", ""); }


        int LAG_DataPool_ReConnect(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "ReConnect", ""); }

        int LAG_DataPool_ResetBugFBtime(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "ResetBugFBtime", ""); }


        int LAG_DataPool_RespondChallenge(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "RespondChallenge", ""); }

        int LAG_DataPool_ScriptPlus(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "ScriptPlus", "n"); }

        int LAG_DataPool_SearchFriends(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "SearchFriends", ""); }

        int LAG_DataPool_SelectTeamMemPetAsTargetByUIIndex(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "SelectTeamMemPetAsTargetByUIIndex", "n"); }


        int LAG_DataPool_SendBugFB(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "SendBugFB", ""); }

        int LAG_DataPool_SetBugFBcount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "SetBugFBcount", ""); }

        int LAG_DataPool_SetCampaignTrackOpen(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "SetCampaignTrackOpen", ""); }

        int LAG_DataPool_SetCanUseHotKey(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "SetCanUseHotKey", ""); }

        int LAG_DataPool_SetCurrentChatChannel(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "SetCurrentChatChannel", ""); }

        int LAG_DataPool_SetCurrentChatIndex(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "SetCurrentChatIndex", ""); }

        int LAG_DataPool_SetDestroyErciQueRen(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "SetDestroyErciQueRen", ""); }

        int LAG_DataPool_SetLongHaiZiModel(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "SetLongHaiZiModel", ""); }

        int LAG_DataPool_SetMissionTrackOpen(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "SetMissionTrackOpen", ""); }

        int LAG_DataPool_SetMsgRead(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "SetMsgRead", ""); }

        int LAG_DataPool_SetPetFightList_Show1(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "SetPetFightList_Show1", ""); }

        int LAG_DataPool_SetPetFightList_Show2(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "SetPetFightList_Show2", ""); }

        int LAG_DataPool_SetPetSkinModel(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "SetPetSkinModel", ""); }

        int LAG_DataPool_SetPetTujianModel(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "SetPetTujianModel", ""); }

        int LAG_DataPool_SetRabbitModel(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "SetRabbitModel", ""); }


        int LAG_DataPool_SetRemark(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "SetRemark", ""); }

        int LAG_DataPool_SetSellErciQueRen(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "SetSellErciQueRen", ""); }


        int LAG_DataPool_SetTeamExpMode(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "SetTeamExpMode", "o"); }

        int LAG_DataPool_SetTrackFuncShow(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "SetTrackFuncShow", ""); }

        int LAG_DataPool_SetXiuChangSelectRoomInd(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "SetXiuChangSelectRoomInd", ""); }

        int LAG_DataPool_Set_RMB_ChatAction(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "Set_RMB_ChatAction", ""); }

        int LAG_DataPool_ShowChatHistory(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "ShowChatHistory", ""); }

        int LAG_DataPool_ShowFriendIMChatHistory(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "ShowFriendIMChatHistory", ""); }

        int LAG_DataPool_ShowMiniWatch(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "ShowMiniWatch", ""); }

        int LAG_DataPool_ShowNormalWatch(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "ShowNormalWatch", ""); }

        int LAG_DataPool_SortPetTujianList(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "SortPetTujianList", ""); }

        int LAG_DataPool_StorPetsOneType(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "StorPetsOneType", ""); }

        int LAG_DataPool_TBSearch_Index_EQU(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "TBSearch_Index_EQU", "o"); }

        int LAG_DataPool_TeamMemIsSnowMan(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "TeamMemIsSnowMan", "n"); }

        int LAG_DataPool_ToggleTrustFriendWindow(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "ToggleTrustFriendWindow", ""); }


        int LAG_DataPool_UnInstall_RMB_ChatAction(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "UnInstall_RMB_ChatAction", ""); }

        int LAG_DataPool_UnInstall_RMB_ChatAction_BarItem(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "UnInstall_RMB_ChatAction_BarItem", ""); }

        int LAG_DataPool_UpdateCampaignListByTrack(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "UpdateCampaignListByTrack", ""); }

        int LAG_DataPool_UpdateCampaignTrack(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "UpdateCampaignTrack", ""); }


        int LAG_DataPool_UpdateFriendInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "UpdateFriendInfo", ""); }


        int LAG_DataPool_UpdateFriendInfoByName(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "UpdateFriendInfoByName", ""); }

        int LAG_DataPool_UpdateMissionTrack(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "UpdateMissionTrack", ""); }

        int LAG_DataPool_UpdateQuestLogByTrack(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "UpdateQuestLogByTrack", ""); }

        int LAG_DataPool_UpdateTrackStateButton(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "UpdateTrackStateButton", ""); }

        int LAG_DataPool_ZhengYouOpenMail(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "ZhengYouOpenMail", ""); }

        int LAG_DataPool_getPetsOneTypeJiHuo_Num(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "getPetsOneTypeJiHuo_Num", "n"); }

        int LAG_DataPool_getUINumbersFromIpRegion(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "getUINumbersFromIpRegion", "nn"); }

        int LAG_DataPool_lua_GetDoubleRankingListMyvalue(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "lua_GetDoubleRankingListMyvalue", "nns"); }

        int LAG_DataPool_lua_GetExamRankingListInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "lua_GetExamRankingListInfo", "nnsnnn"); }

        int LAG_DataPool_lua_GetJSRankingListDataCount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "lua_GetJSRankingListDataCount", "n"); }


        int LAG_DataPool_lua_GetJSRankingListGetReward(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "lua_GetJSRankingListGetReward", "o"); }


        int LAG_DataPool_lua_GetJSRankingListGetRewardEx(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "lua_GetJSRankingListGetRewardEx", "o"); }

        int LAG_DataPool_lua_GetJSRankingListInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "lua_GetJSRankingListInfo", "nsnn"); }

        int LAG_DataPool_lua_GetJSRankingListMemberInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "lua_GetJSRankingListMemberInfo", "nnnsn"); }

        int LAG_DataPool_lua_GetJSRankingListMyInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "lua_GetJSRankingListMyInfo", "n"); }

        int LAG_DataPool_lua_GetJSRankingListParam(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "lua_GetJSRankingListParam", "n"); }

        int LAG_DataPool_lua_GetJSRankingListRewardInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "lua_GetJSRankingListRewardInfo", "n"); }

        int LAG_DataPool_lua_GetMenPaiWarRankingListMyvalue(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "lua_GetMenPaiWarRankingListMyvalue", "n"); }

        int LAG_DataPool_lua_GetNormalRankGetRankTime(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "lua_GetNormalRankGetRankTime", "nnn"); }

        int LAG_DataPool_lua_GetNormalRankListCount(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "lua_GetNormalRankListCount", "n"); }

        int LAG_DataPool_lua_GetNormalRankListInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "lua_GetNormalRankListInfo", "nsnnn"); }

        int LAG_DataPool_lua_GetNormalRankPlayerRewardInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "lua_GetNormalRankPlayerRewardInfo", "nnnn"); }

        int LAG_DataPool_lua_GetNormalRankingBaseRewardInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "lua_GetNormalRankingBaseRewardInfo", "n"); }

        int LAG_DataPool_lua_GetNormalRankingMaxRankNum(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "lua_GetNormalRankingMaxRankNum", "n"); }

        int LAG_DataPool_lua_GetNormalRankingMaxRewardNum(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "lua_GetNormalRankingMaxRewardNum", "n"); }

        int LAG_DataPool_lua_GetNormalRankingPlayerRankInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "lua_GetNormalRankingPlayerRankInfo", "nnn"); }

        int LAG_DataPool_lua_GetNormalRankingRewardShowIndex(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "lua_GetNormalRankingRewardShowIndex", "n"); }


        int LAG_DataPool_lua_GetNormalRankingRewardShowInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "lua_GetNormalRankingRewardShowInfo", ""); }

        int LAG_DataPool_lua_GetNormalRankingStopTime(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "lua_GetNormalRankingStopTime", "nn"); }

        int LAG_DataPool_lua_GetRankServerType(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "lua_GetRankServerType", "n"); }

        int LAG_DataPool_lua_GetShaxingRankingListInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "lua_GetShaxingRankingListInfo", "nsnnn"); }

        int LAG_DataPool_lua_IsNormalRankGetBoutsTime(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "lua_IsNormalRankGetBoutsTime", "n"); }

        int LAG_DataPool_lua_IsNormalRankingClientShow(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "lua_IsNormalRankingClientShow", "n"); }


        int LAG_DataPool_lua_OpenLevelRankInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "lua_OpenLevelRankInfo", "o"); }


        int LAG_DataPool_lua_UpdateNormalRankInfo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "lua_UpdateNormalRankInfo", "o"); }

        int LAG_DataPool_storPetsOneTypeJiHuo(LuaPlus::LuaState* state) { return Stub(state, "DataPool", "storPetsOneTypeJiHuo", ""); }
    }

    void Register_DataPool(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "ActiveMissionCue")) table.Register("ActiveMissionCue", LAG_DataPool_ActiveMissionCue);
        if (IsMissing(table, "AddFriendAndGrouping")) table.Register("AddFriendAndGrouping", LAG_DataPool_AddFriendAndGrouping);
        if (IsMissing(table, "AddTrustFriend")) table.Register("AddTrustFriend", LAG_DataPool_AddTrustFriend);
        if (IsMissing(table, "AskChallengeList")) table.Register("AskChallengeList", LAG_DataPool_AskChallengeList);
        if (IsMissing(table, "AskCreateChar")) table.Register("AskCreateChar", LAG_DataPool_AskCreateChar);
        if (IsMissing(table, "AskDelFriend")) table.Register("AskDelFriend", LAG_DataPool_AskDelFriend);
        if (IsMissing(table, "AskMyBagList")) table.Register("AskMyBagList", LAG_DataPool_AskMyBagList);
        if (IsMissing(table, "CampaignTrackGotoCampaignList")) table.Register("CampaignTrackGotoCampaignList", LAG_DataPool_CampaignTrackGotoCampaignList);
        if (IsMissing(table, "Challenge")) table.Register("Challenge", LAG_DataPool_Challenge);
        if (IsMissing(table, "ChangeLongHaiZiAction")) table.Register("ChangeLongHaiZiAction", LAG_DataPool_ChangeLongHaiZiAction);
        if (IsMissing(table, "Change_MyFaceStyle")) table.Register("Change_MyFaceStyle", LAG_DataPool_Change_MyFaceStyle);
        if (IsMissing(table, "Change_MyFaceStyle_Item")) table.Register("Change_MyFaceStyle_Item", LAG_DataPool_Change_MyFaceStyle_Item);
        if (IsMissing(table, "Change_MyHeadStyle")) table.Register("Change_MyHeadStyle", LAG_DataPool_Change_MyHeadStyle);
        if (IsMissing(table, "Change_MyHeadStyle_Item")) table.Register("Change_MyHeadStyle_Item", LAG_DataPool_Change_MyHeadStyle_Item);
        if (IsMissing(table, "CheckBugFBtime")) table.Register("CheckBugFBtime", LAG_DataPool_CheckBugFBtime);
        if (IsMissing(table, "CheckCanSubmitBug")) table.Register("CheckCanSubmitBug", LAG_DataPool_CheckCanSubmitBug);
        if (IsMissing(table, "CleanQinChiDaoData")) table.Register("CleanQinChiDaoData", LAG_DataPool_CleanQinChiDaoData);
        if (IsMissing(table, "ClearActionItemForShow")) table.Register("ClearActionItemForShow", LAG_DataPool_ClearActionItemForShow);
        if (IsMissing(table, "Clear_ChatAction_Bar")) table.Register("Clear_ChatAction_Bar", LAG_DataPool_Clear_ChatAction_Bar);
        if (IsMissing(table, "CreateActionItemForShow")) table.Register("CreateActionItemForShow", LAG_DataPool_CreateActionItemForShow);
        if (IsMissing(table, "CreateActionItemForShowDisable")) table.Register("CreateActionItemForShowDisable", LAG_DataPool_CreateActionItemForShowDisable);
        if (IsMissing(table, "CreateActionItemForShowWithMaxNum")) table.Register("CreateActionItemForShowWithMaxNum", LAG_DataPool_CreateActionItemForShowWithMaxNum);
        if (IsMissing(table, "CreateBindActionItemForShow")) table.Register("CreateBindActionItemForShow", LAG_DataPool_CreateBindActionItemForShow);
        if (IsMissing(table, "CreateBindActionItemForShowWithMaxNum")) table.Register("CreateBindActionItemForShowWithMaxNum", LAG_DataPool_CreateBindActionItemForShowWithMaxNum);
        if (IsMissing(table, "DarkAdjustAttr")) table.Register("DarkAdjustAttr", LAG_DataPool_DarkAdjustAttr);
        if (IsMissing(table, "DarkAdjustSkill")) table.Register("DarkAdjustSkill", LAG_DataPool_DarkAdjustSkill);
        if (IsMissing(table, "DarkReset")) table.Register("DarkReset", LAG_DataPool_DarkReset);
        if (IsMissing(table, "DarkResetQuality")) table.Register("DarkResetQuality", LAG_DataPool_DarkResetQuality);
        if (IsMissing(table, "DelTrustFriend")) table.Register("DelTrustFriend", LAG_DataPool_DelTrustFriend);
        if (IsMissing(table, "DiffDayCount")) table.Register("DiffDayCount", LAG_DataPool_DiffDayCount);
        if (IsMissing(table, "DoMobileApprove")) table.Register("DoMobileApprove", LAG_DataPool_DoMobileApprove);
        if (IsMissing(table, "DoSMSCodeMobileApprove")) table.Register("DoSMSCodeMobileApprove", LAG_DataPool_DoSMSCodeMobileApprove);
        if (IsMissing(table, "EnterChallengeView")) table.Register("EnterChallengeView", LAG_DataPool_EnterChallengeView);
        if (IsMissing(table, "EnumProvinces")) table.Register("EnumProvinces", LAG_DataPool_EnumProvinces);
        if (IsMissing(table, "EnumTeamBoardGoal")) table.Register("EnumTeamBoardGoal", LAG_DataPool_EnumTeamBoardGoal);
        if (IsMissing(table, "FriendSetClicked")) table.Register("FriendSetClicked", LAG_DataPool_FriendSetClicked);
        if (IsMissing(table, "FunChallenge")) table.Register("FunChallenge", LAG_DataPool_FunChallenge);
        if (IsMissing(table, "GetAccVipLevel")) table.Register("GetAccVipLevel", LAG_DataPool_GetAccVipLevel);
        if (IsMissing(table, "GetAutoSearch")) table.Register("GetAutoSearch", LAG_DataPool_GetAutoSearch);
        if (IsMissing(table, "GetAutoSearchOriginalHide")) table.Register("GetAutoSearchOriginalHide", LAG_DataPool_GetAutoSearchOriginalHide);
        if (IsMissing(table, "GetAutoSearchPriority")) table.Register("GetAutoSearchPriority", LAG_DataPool_GetAutoSearchPriority);
        if (IsMissing(table, "GetAutoSearchSceneStartEnd")) table.Register("GetAutoSearchSceneStartEnd", LAG_DataPool_GetAutoSearchSceneStartEnd);
        if (IsMissing(table, "GetBaseBag_BaseNum")) table.Register("GetBaseBag_BaseNum", LAG_DataPool_GetBaseBag_BaseNum);
        if (IsMissing(table, "GetBaseBag_MaxNum")) table.Register("GetBaseBag_MaxNum", LAG_DataPool_GetBaseBag_MaxNum);
        if (IsMissing(table, "GetBaseBag_Num")) table.Register("GetBaseBag_Num", LAG_DataPool_GetBaseBag_Num);
        if (IsMissing(table, "GetBaseBag_RealMaxNum")) table.Register("GetBaseBag_RealMaxNum", LAG_DataPool_GetBaseBag_RealMaxNum);
        if (IsMissing(table, "GetBugFBcount")) table.Register("GetBugFBcount", LAG_DataPool_GetBugFBcount);
        if (IsMissing(table, "GetChallengeCount")) table.Register("GetChallengeCount", LAG_DataPool_GetChallengeCount);
        if (IsMissing(table, "GetChallengeInfo")) table.Register("GetChallengeInfo", LAG_DataPool_GetChallengeInfo);
        if (IsMissing(table, "GetChallengeTeamMemberCount")) table.Register("GetChallengeTeamMemberCount", LAG_DataPool_GetChallengeTeamMemberCount);
        if (IsMissing(table, "GetChallengeTeamMemberInfo")) table.Register("GetChallengeTeamMemberInfo", LAG_DataPool_GetChallengeTeamMemberInfo);
        if (IsMissing(table, "GetCityNumFromOneProvinceId")) table.Register("GetCityNumFromOneProvinceId", LAG_DataPool_GetCityNumFromOneProvinceId);
        if (IsMissing(table, "GetCurDialogNpcId")) table.Register("GetCurDialogNpcId", LAG_DataPool_GetCurDialogNpcId);
        if (IsMissing(table, "GetCurrentChatChannel")) table.Register("GetCurrentChatChannel", LAG_DataPool_GetCurrentChatChannel);
        if (IsMissing(table, "GetCurrentChatIndex")) table.Register("GetCurrentChatIndex", LAG_DataPool_GetCurrentChatIndex);
        if (IsMissing(table, "GetDarkSkillDesc")) table.Register("GetDarkSkillDesc", LAG_DataPool_GetDarkSkillDesc);
        if (IsMissing(table, "GetDarkSkillNewDesc")) table.Register("GetDarkSkillNewDesc", LAG_DataPool_GetDarkSkillNewDesc);
        if (IsMissing(table, "GetDeliveryMissionTrackInfo")) table.Register("GetDeliveryMissionTrackInfo", LAG_DataPool_GetDeliveryMissionTrackInfo);
        if (IsMissing(table, "GetDestroyErciQueRen")) table.Register("GetDestroyErciQueRen", LAG_DataPool_GetDestroyErciQueRen);
        if (IsMissing(table, "GetDifDayWithServerTime")) table.Register("GetDifDayWithServerTime", LAG_DataPool_GetDifDayWithServerTime);
        if (IsMissing(table, "GetDiffDay")) table.Register("GetDiffDay", LAG_DataPool_GetDiffDay);
        if (IsMissing(table, "GetFixKfsBase")) table.Register("GetFixKfsBase", LAG_DataPool_GetFixKfsBase);
        if (IsMissing(table, "GetFriendByGUID")) table.Register("GetFriendByGUID", LAG_DataPool_GetFriendByGUID);
        if (IsMissing(table, "GetFriendNumberCommon")) table.Register("GetFriendNumberCommon", LAG_DataPool_GetFriendNumberCommon);
        if (IsMissing(table, "GetFriendOnlineNumber")) table.Register("GetFriendOnlineNumber", LAG_DataPool_GetFriendOnlineNumber);
        if (IsMissing(table, "GetFriendOnlineNumberCommon")) table.Register("GetFriendOnlineNumberCommon", LAG_DataPool_GetFriendOnlineNumberCommon);
        if (IsMissing(table, "GetGroupingName")) table.Register("GetGroupingName", LAG_DataPool_GetGroupingName);
        if (IsMissing(table, "GetHusongMissionTrackInfo")) table.Register("GetHusongMissionTrackInfo", LAG_DataPool_GetHusongMissionTrackInfo);
        if (IsMissing(table, "GetIMChatData")) table.Register("GetIMChatData", LAG_DataPool_GetIMChatData);
        if (IsMissing(table, "GetIMChatNumber")) table.Register("GetIMChatNumber", LAG_DataPool_GetIMChatNumber);
        if (IsMissing(table, "GetIMRecentByGUID")) table.Register("GetIMRecentByGUID", LAG_DataPool_GetIMRecentByGUID);
        if (IsMissing(table, "GetIMRecentByIndex")) table.Register("GetIMRecentByIndex", LAG_DataPool_GetIMRecentByIndex);
        if (IsMissing(table, "GetKFSNewSkillDesc")) table.Register("GetKFSNewSkillDesc", LAG_DataPool_GetKFSNewSkillDesc);
        if (IsMissing(table, "GetKFSSkillDesc")) table.Register("GetKFSSkillDesc", LAG_DataPool_GetKFSSkillDesc);
        if (IsMissing(table, "GetKfsBase")) table.Register("GetKfsBase", LAG_DataPool_GetKfsBase);
        if (IsMissing(table, "GetKfsData")) table.Register("GetKfsData", LAG_DataPool_GetKfsData);
        if (IsMissing(table, "GetKfsFixAttrEx")) table.Register("GetKfsFixAttrEx", LAG_DataPool_GetKfsFixAttrEx);
        if (IsMissing(table, "GetKfsSkill")) table.Register("GetKfsSkill", LAG_DataPool_GetKfsSkill);
        if (IsMissing(table, "GetKillMonsterMissionTrackInfo_MonsterInfo")) table.Register("GetKillMonsterMissionTrackInfo_MonsterInfo", LAG_DataPool_GetKillMonsterMissionTrackInfo_MonsterInfo);
        if (IsMissing(table, "GetKillMonsterMissionTrackInfo_num")) table.Register("GetKillMonsterMissionTrackInfo_num", LAG_DataPool_GetKillMonsterMissionTrackInfo_num);
        if (IsMissing(table, "GetLeftProtectTime")) table.Register("GetLeftProtectTime", LAG_DataPool_GetLeftProtectTime);
        if (IsMissing(table, "GetLookUpPartInfo")) table.Register("GetLookUpPartInfo", LAG_DataPool_GetLookUpPartInfo);
        if (IsMissing(table, "GetLootItemMissionTrackInfo_ItemInfo")) table.Register("GetLootItemMissionTrackInfo_ItemInfo", LAG_DataPool_GetLootItemMissionTrackInfo_ItemInfo);
        if (IsMissing(table, "GetLootItemMissionTrackInfo_num")) table.Register("GetLootItemMissionTrackInfo_num", LAG_DataPool_GetLootItemMissionTrackInfo_num);
        if (IsMissing(table, "GetLuaMissionTrackInfo")) table.Register("GetLuaMissionTrackInfo", LAG_DataPool_GetLuaMissionTrackInfo);
        if (IsMissing(table, "GetMailTimeInt")) table.Register("GetMailTimeInt", LAG_DataPool_GetMailTimeInt);
        if (IsMissing(table, "GetMatBag_BaseNum")) table.Register("GetMatBag_BaseNum", LAG_DataPool_GetMatBag_BaseNum);
        if (IsMissing(table, "GetMatBag_MaxNum")) table.Register("GetMatBag_MaxNum", LAG_DataPool_GetMatBag_MaxNum);
        if (IsMissing(table, "GetMatBag_Num")) table.Register("GetMatBag_Num", LAG_DataPool_GetMatBag_Num);
        if (IsMissing(table, "GetMatBag_RealMaxNum")) table.Register("GetMatBag_RealMaxNum", LAG_DataPool_GetMatBag_RealMaxNum);
        if (IsMissing(table, "GetMenPaiName")) table.Register("GetMenPaiName", LAG_DataPool_GetMenPaiName);
        if (IsMissing(table, "GetMissionFinishInfo")) table.Register("GetMissionFinishInfo", LAG_DataPool_GetMissionFinishInfo);
        if (IsMissing(table, "GetMissionShortName")) table.Register("GetMissionShortName", LAG_DataPool_GetMissionShortName);
        if (IsMissing(table, "GetMission_WhetherComplete")) table.Register("GetMission_WhetherComplete", LAG_DataPool_GetMission_WhetherComplete);
        if (IsMissing(table, "GetMobileApprovePrize")) table.Register("GetMobileApprovePrize", LAG_DataPool_GetMobileApprovePrize);
        if (IsMissing(table, "GetMobileApproveSecurityCode")) table.Register("GetMobileApproveSecurityCode", LAG_DataPool_GetMobileApproveSecurityCode);
        if (IsMissing(table, "GetMobileApproveStatus")) table.Register("GetMobileApproveStatus", LAG_DataPool_GetMobileApproveStatus);
        if (IsMissing(table, "GetMobilePhoneNumber")) table.Register("GetMobilePhoneNumber", LAG_DataPool_GetMobilePhoneNumber);
        if (IsMissing(table, "GetMonsterNameAndIcon")) table.Register("GetMonsterNameAndIcon", LAG_DataPool_GetMonsterNameAndIcon);
        if (IsMissing(table, "GetMsgDetail")) table.Register("GetMsgDetail", LAG_DataPool_GetMsgDetail);
        if (IsMissing(table, "GetMsgNum")) table.Register("GetMsgNum", LAG_DataPool_GetMsgNum);
        if (IsMissing(table, "GetMsgPlayerGuild")) table.Register("GetMsgPlayerGuild", LAG_DataPool_GetMsgPlayerGuild);
        if (IsMissing(table, "GetMsgTimeTitle")) table.Register("GetMsgTimeTitle", LAG_DataPool_GetMsgTimeTitle);
        if (IsMissing(table, "GetMsgType")) table.Register("GetMsgType", LAG_DataPool_GetMsgType);
        if (IsMissing(table, "GetNameWithServerInfo")) table.Register("GetNameWithServerInfo", LAG_DataPool_GetNameWithServerInfo);
        if (IsMissing(table, "GetPaoShangData")) table.Register("GetPaoShangData", LAG_DataPool_GetPaoShangData);
        if (IsMissing(table, "GetPaoShangItemBuyPirceLvl")) table.Register("GetPaoShangItemBuyPirceLvl", LAG_DataPool_GetPaoShangItemBuyPirceLvl);
        if (IsMissing(table, "GetPetFightList_Show1")) table.Register("GetPetFightList_Show1", LAG_DataPool_GetPetFightList_Show1);
        if (IsMissing(table, "GetPetFightList_Show2")) table.Register("GetPetFightList_Show2", LAG_DataPool_GetPetFightList_Show2);
        if (IsMissing(table, "GetPetSkinJiHuoDataId")) table.Register("GetPetSkinJiHuoDataId", LAG_DataPool_GetPetSkinJiHuoDataId);
        if (IsMissing(table, "GetPetSkinJiHuoDatasIndex")) table.Register("GetPetSkinJiHuoDatasIndex", LAG_DataPool_GetPetSkinJiHuoDatasIndex);
        if (IsMissing(table, "GetPetTujianJiHuoType")) table.Register("GetPetTujianJiHuoType", LAG_DataPool_GetPetTujianJiHuoType);
        if (IsMissing(table, "GetPetTujianName")) table.Register("GetPetTujianName", LAG_DataPool_GetPetTujianName);
        if (IsMissing(table, "GetPetTujianNum")) table.Register("GetPetTujianNum", LAG_DataPool_GetPetTujianNum);
        if (IsMissing(table, "GetPetTujianPetInfo")) table.Register("GetPetTujianPetInfo", LAG_DataPool_GetPetTujianPetInfo);
        if (IsMissing(table, "GetPetsOneTypeNum")) table.Register("GetPetsOneTypeNum", LAG_DataPool_GetPetsOneTypeNum);
        if (IsMissing(table, "GetPlayerMissionIndexByID")) table.Register("GetPlayerMissionIndexByID", LAG_DataPool_GetPlayerMissionIndexByID);
        if (IsMissing(table, "GetPlayerMissionRandomCustom")) table.Register("GetPlayerMissionRandomCustom", LAG_DataPool_GetPlayerMissionRandomCustom);
        if (IsMissing(table, "GetPlayerMissionRandomCustom_Num")) table.Register("GetPlayerMissionRandomCustom_Num", LAG_DataPool_GetPlayerMissionRandomCustom_Num);
        if (IsMissing(table, "GetPlayerMissionTrackType")) table.Register("GetPlayerMissionTrackType", LAG_DataPool_GetPlayerMissionTrackType);
        if (IsMissing(table, "GetPlayerMission_ActivePos")) table.Register("GetPlayerMission_ActivePos", LAG_DataPool_GetPlayerMission_ActivePos);
        if (IsMissing(table, "GetPlayerMission_DelActivePos")) table.Register("GetPlayerMission_DelActivePos", LAG_DataPool_GetPlayerMission_DelActivePos);
        if (IsMissing(table, "GetPlayerMission_ForePart")) table.Register("GetPlayerMission_ForePart", LAG_DataPool_GetPlayerMission_ForePart);
        if (IsMissing(table, "GetPlayerMission_StrList")) table.Register("GetPlayerMission_StrList", LAG_DataPool_GetPlayerMission_StrList);
        if (IsMissing(table, "GetPlayerMission_VariableByByte")) table.Register("GetPlayerMission_VariableByByte", LAG_DataPool_GetPlayerMission_VariableByByte);
        if (IsMissing(table, "GetPortraitByID")) table.Register("GetPortraitByID", LAG_DataPool_GetPortraitByID);
        if (IsMissing(table, "GetPrescrList_Item_LifeAbilityLevel")) table.Register("GetPrescrList_Item_LifeAbilityLevel", LAG_DataPool_GetPrescrList_Item_LifeAbilityLevel);
        if (IsMissing(table, "GetProposerCount")) table.Register("GetProposerCount", LAG_DataPool_GetProposerCount);
        if (IsMissing(table, "GetProvincesNum")) table.Register("GetProvincesNum", LAG_DataPool_GetProvincesNum);
        if (IsMissing(table, "GetQinChiDaoTopListCount")) table.Register("GetQinChiDaoTopListCount", LAG_DataPool_GetQinChiDaoTopListCount);
        if (IsMissing(table, "GetQinChiDaoTopListInfo")) table.Register("GetQinChiDaoTopListInfo", LAG_DataPool_GetQinChiDaoTopListInfo);
        if (IsMissing(table, "GetRomanInfo")) table.Register("GetRomanInfo", LAG_DataPool_GetRomanInfo);
        if (IsMissing(table, "GetSMSCodeSecurityCode")) table.Register("GetSMSCodeSecurityCode", LAG_DataPool_GetSMSCodeSecurityCode);
        if (IsMissing(table, "GetSearchResultByGUID")) table.Register("GetSearchResultByGUID", LAG_DataPool_GetSearchResultByGUID);
        if (IsMissing(table, "GetSearchResultByIndex")) table.Register("GetSearchResultByIndex", LAG_DataPool_GetSearchResultByIndex);
        if (IsMissing(table, "GetSearchResultNum")) table.Register("GetSearchResultNum", LAG_DataPool_GetSearchResultNum);
        if (IsMissing(table, "GetSectType")) table.Register("GetSectType", LAG_DataPool_GetSectType);
        if (IsMissing(table, "GetSelfZoneWorldID")) table.Register("GetSelfZoneWorldID", LAG_DataPool_GetSelfZoneWorldID);
        if (IsMissing(table, "GetSellErciQueRen")) table.Register("GetSellErciQueRen", LAG_DataPool_GetSellErciQueRen);
        if (IsMissing(table, "GetServerDayTime")) table.Register("GetServerDayTime", LAG_DataPool_GetServerDayTime);
        if (IsMissing(table, "GetServerMinuteTime")) table.Register("GetServerMinuteTime", LAG_DataPool_GetServerMinuteTime);
        if (IsMissing(table, "GetServerName")) table.Register("GetServerName", LAG_DataPool_GetServerName);
        if (IsMissing(table, "GetServerWeekDayTime")) table.Register("GetServerWeekDayTime", LAG_DataPool_GetServerWeekDayTime);
        if (IsMissing(table, "GetSystemHistroy")) table.Register("GetSystemHistroy", LAG_DataPool_GetSystemHistroy);
        if (IsMissing(table, "GetSystemHistroyNumber")) table.Register("GetSystemHistroyNumber", LAG_DataPool_GetSystemHistroyNumber);
        if (IsMissing(table, "GetTaskBag_BaseNum")) table.Register("GetTaskBag_BaseNum", LAG_DataPool_GetTaskBag_BaseNum);
        if (IsMissing(table, "GetTaskBag_MaxNum")) table.Register("GetTaskBag_MaxNum", LAG_DataPool_GetTaskBag_MaxNum);
        if (IsMissing(table, "GetTaskBag_Num")) table.Register("GetTaskBag_Num", LAG_DataPool_GetTaskBag_Num);
        if (IsMissing(table, "GetTeamBoardGoalNum")) table.Register("GetTeamBoardGoalNum", LAG_DataPool_GetTeamBoardGoalNum);
        if (IsMissing(table, "GetTeamExpMode")) table.Register("GetTeamExpMode", LAG_DataPool_GetTeamExpMode);
        if (IsMissing(table, "GetTeamMemBufInfo")) table.Register("GetTeamMemBufInfo", LAG_DataPool_GetTeamMemBufInfo);
        if (IsMissing(table, "GetTeamMemBufIsShowIcon")) table.Register("GetTeamMemBufIsShowIcon", LAG_DataPool_GetTeamMemBufIsShowIcon);
        if (IsMissing(table, "GetTeamMemBufNum")) table.Register("GetTeamMemBufNum", LAG_DataPool_GetTeamMemBufNum);
        if (IsMissing(table, "GetTeamMemBufPriority")) table.Register("GetTeamMemBufPriority", LAG_DataPool_GetTeamMemBufPriority);
        if (IsMissing(table, "GetTeamMemInfoExByIndex")) table.Register("GetTeamMemInfoExByIndex", LAG_DataPool_GetTeamMemInfoExByIndex);
        if (IsMissing(table, "GetTeamMemNameByUIIndex")) table.Register("GetTeamMemNameByUIIndex", LAG_DataPool_GetTeamMemNameByUIIndex);
        if (IsMissing(table, "GetTeamMemSandBoxHPInfo")) table.Register("GetTeamMemSandBoxHPInfo", LAG_DataPool_GetTeamMemSandBoxHPInfo);
        if (IsMissing(table, "GetTopGUID")) table.Register("GetTopGUID", LAG_DataPool_GetTopGUID);
        if (IsMissing(table, "GetTransBWaitTime")) table.Register("GetTransBWaitTime", LAG_DataPool_GetTransBWaitTime);
        if (IsMissing(table, "GetTrustFriend")) table.Register("GetTrustFriend", LAG_DataPool_GetTrustFriend);
        if (IsMissing(table, "GetTrustFriendNumber")) table.Register("GetTrustFriendNumber", LAG_DataPool_GetTrustFriendNumber);
        if (IsMissing(table, "GetXiuChangRoomCount")) table.Register("GetXiuChangRoomCount", LAG_DataPool_GetXiuChangRoomCount);
        if (IsMissing(table, "GetXiuChangRoomInfo")) table.Register("GetXiuChangRoomInfo", LAG_DataPool_GetXiuChangRoomInfo);
        if (IsMissing(table, "GetXiuChangSelectRoomInd")) table.Register("GetXiuChangSelectRoomInd", LAG_DataPool_GetXiuChangSelectRoomInd);
        if (IsMissing(table, "Get_DIYFrame_Item")) table.Register("Get_DIYFrame_Item", LAG_DataPool_Get_DIYFrame_Item);
        if (IsMissing(table, "Get_MyFaceStyle")) table.Register("Get_MyFaceStyle", LAG_DataPool_Get_MyFaceStyle);
        if (IsMissing(table, "Get_MyHeadStyle")) table.Register("Get_MyHeadStyle", LAG_DataPool_Get_MyHeadStyle);
        if (IsMissing(table, "Get_RMB_ChatActionInfo")) table.Register("Get_RMB_ChatActionInfo", LAG_DataPool_Get_RMB_ChatActionInfo);
        if (IsMissing(table, "Get_RMB_ChatActionName")) table.Register("Get_RMB_ChatActionName", LAG_DataPool_Get_RMB_ChatActionName);
        if (IsMissing(table, "Get_RMB_ChatActionRealID")) table.Register("Get_RMB_ChatActionRealID", LAG_DataPool_Get_RMB_ChatActionRealID);
        if (IsMissing(table, "Get_RMB_ChatActionValidHour")) table.Register("Get_RMB_ChatActionValidHour", LAG_DataPool_Get_RMB_ChatActionValidHour);
        if (IsMissing(table, "HandleGameSetupAction")) table.Register("HandleGameSetupAction", LAG_DataPool_HandleGameSetupAction);
        if (IsMissing(table, "HaveMisstionTrackThisType")) table.Register("HaveMisstionTrackThisType", LAG_DataPool_HaveMisstionTrackThisType);
        if (IsMissing(table, "HaveNewIMMsg")) table.Register("HaveNewIMMsg", LAG_DataPool_HaveNewIMMsg);
        if (IsMissing(table, "IfHaveBuffByID")) table.Register("IfHaveBuffByID", LAG_DataPool_IfHaveBuffByID);
        if (IsMissing(table, "InitPetSkinJiHuoDatas")) table.Register("InitPetSkinJiHuoDatas", LAG_DataPool_InitPetSkinJiHuoDatas);
        if (IsMissing(table, "InviteAddFriend")) table.Register("InviteAddFriend", LAG_DataPool_InviteAddFriend);
        if (IsMissing(table, "InviteAddFriendByFriendList")) table.Register("InviteAddFriendByFriendList", LAG_DataPool_InviteAddFriendByFriendList);
        if (IsMissing(table, "InviteAddFriendByteam")) table.Register("InviteAddFriendByteam", LAG_DataPool_InviteAddFriendByteam);
        if (IsMissing(table, "InviteApplyAddPingbi")) table.Register("InviteApplyAddPingbi", LAG_DataPool_InviteApplyAddPingbi);
        if (IsMissing(table, "IsCampaignCanTrack")) table.Register("IsCampaignCanTrack", LAG_DataPool_IsCampaignCanTrack);
        if (IsMissing(table, "IsCampaignTrackOpen")) table.Register("IsCampaignTrackOpen", LAG_DataPool_IsCampaignTrackOpen);
        if (IsMissing(table, "IsMissionTrackOpen")) table.Register("IsMissionTrackOpen", LAG_DataPool_IsMissionTrackOpen);
        if (IsMissing(table, "IsMsgRead")) table.Register("IsMsgRead", LAG_DataPool_IsMsgRead);
        if (IsMissing(table, "IsPetsOneType_HH")) table.Register("IsPetsOneType_HH", LAG_DataPool_IsPetsOneType_HH);
        if (IsMissing(table, "IsTrackFuncShow")) table.Register("IsTrackFuncShow", LAG_DataPool_IsTrackFuncShow);
        if (IsMissing(table, "IsTrustFriend")) table.Register("IsTrustFriend", LAG_DataPool_IsTrustFriend);
        if (IsMissing(table, "KFS_UpdateKFSModel")) table.Register("KFS_UpdateKFSModel", LAG_DataPool_KFS_UpdateKFSModel);
        if (IsMissing(table, "LookupOtherParticularInfo")) table.Register("LookupOtherParticularInfo", LAG_DataPool_LookupOtherParticularInfo);
        if (IsMissing(table, "LuaFnCalcEquipDWAttr")) table.Register("LuaFnCalcEquipDWAttr", LAG_DataPool_LuaFnCalcEquipDWAttr);
        if (IsMissing(table, "LuaFnCastChangeWGSkill")) table.Register("LuaFnCastChangeWGSkill", LAG_DataPool_LuaFnCastChangeWGSkill);
        if (IsMissing(table, "LuaFnCheckEmo")) table.Register("LuaFnCheckEmo", LAG_DataPool_LuaFnCheckEmo);
        if (IsMissing(table, "LuaFnCreateActionElfForSelect")) table.Register("LuaFnCreateActionElfForSelect", LAG_DataPool_LuaFnCreateActionElfForSelect);
        if (IsMissing(table, "LuaFnEnumBagShenBingSkillAction")) table.Register("LuaFnEnumBagShenBingSkillAction", LAG_DataPool_LuaFnEnumBagShenBingSkillAction);
        if (IsMissing(table, "LuaFnEnumDressCollectionFromList")) table.Register("LuaFnEnumDressCollectionFromList", LAG_DataPool_LuaFnEnumDressCollectionFromList);
        if (IsMissing(table, "LuaFnEnumDressSeriesExteriorIdx")) table.Register("LuaFnEnumDressSeriesExteriorIdx", LAG_DataPool_LuaFnEnumDressSeriesExteriorIdx);
        if (IsMissing(table, "LuaFnEnumEmoInfo")) table.Register("LuaFnEnumEmoInfo", LAG_DataPool_LuaFnEnumEmoInfo);
        if (IsMissing(table, "LuaFnEnumEquipRefreshAttr")) table.Register("LuaFnEnumEquipRefreshAttr", LAG_DataPool_LuaFnEnumEquipRefreshAttr);
        if (IsMissing(table, "LuaFnEnumEquipShenBingSkillAction")) table.Register("LuaFnEnumEquipShenBingSkillAction", LAG_DataPool_LuaFnEnumEquipShenBingSkillAction);
        if (IsMissing(table, "LuaFnEnumFeaturesID")) table.Register("LuaFnEnumFeaturesID", LAG_DataPool_LuaFnEnumFeaturesID);
        if (IsMissing(table, "LuaFnEnumFeaturesIdFromTable")) table.Register("LuaFnEnumFeaturesIdFromTable", LAG_DataPool_LuaFnEnumFeaturesIdFromTable);
        if (IsMissing(table, "LuaFnEnumRideCollectionEffect")) table.Register("LuaFnEnumRideCollectionEffect", LAG_DataPool_LuaFnEnumRideCollectionEffect);
        if (IsMissing(table, "LuaFnEnumRideCollectionFromList")) table.Register("LuaFnEnumRideCollectionFromList", LAG_DataPool_LuaFnEnumRideCollectionFromList);
        if (IsMissing(table, "LuaFnEnumRideSeriesExteriorRideId")) table.Register("LuaFnEnumRideSeriesExteriorRideId", LAG_DataPool_LuaFnEnumRideSeriesExteriorRideId);
        if (IsMissing(table, "LuaFnEnumShenBingJianSkillAction")) table.Register("LuaFnEnumShenBingJianSkillAction", LAG_DataPool_LuaFnEnumShenBingJianSkillAction);
        if (IsMissing(table, "LuaFnEquipRefreshBindConfirmed")) table.Register("LuaFnEquipRefreshBindConfirmed", LAG_DataPool_LuaFnEquipRefreshBindConfirmed);
        if (IsMissing(table, "LuaFnEquipRefreshCloseConfirmed")) table.Register("LuaFnEquipRefreshCloseConfirmed", LAG_DataPool_LuaFnEquipRefreshCloseConfirmed);
        if (IsMissing(table, "LuaFnEquipRefreshEquipChangeConfirmed")) table.Register("LuaFnEquipRefreshEquipChangeConfirmed", LAG_DataPool_LuaFnEquipRefreshEquipChangeConfirmed);
        if (IsMissing(table, "LuaFnFittingFashion")) table.Register("LuaFnFittingFashion", LAG_DataPool_LuaFnFittingFashion);
        if (IsMissing(table, "LuaFnGet2025Q1ZSBBYDMD_ConditionIsFinish")) table.Register("LuaFnGet2025Q1ZSBBYDMD_ConditionIsFinish", LAG_DataPool_LuaFnGet2025Q1ZSBBYDMD_ConditionIsFinish);
        if (IsMissing(table, "LuaFnGetAttributeDesc")) table.Register("LuaFnGetAttributeDesc", LAG_DataPool_LuaFnGetAttributeDesc);
        if (IsMissing(table, "LuaFnGetCurFashionLotteryIndex")) table.Register("LuaFnGetCurFashionLotteryIndex", LAG_DataPool_LuaFnGetCurFashionLotteryIndex);
        if (IsMissing(table, "LuaFnGetDFengEssenceKongWeiActiveData")) table.Register("LuaFnGetDFengEssenceKongWeiActiveData", LAG_DataPool_LuaFnGetDFengEssenceKongWeiActiveData);
        if (IsMissing(table, "LuaFnGetDFengEssenceKongWeiDataByIndex")) table.Register("LuaFnGetDFengEssenceKongWeiDataByIndex", LAG_DataPool_LuaFnGetDFengEssenceKongWeiDataByIndex);
        if (IsMissing(table, "LuaFnGetDFengEssenceKongWeiTableData")) table.Register("LuaFnGetDFengEssenceKongWeiTableData", LAG_DataPool_LuaFnGetDFengEssenceKongWeiTableData);
        if (IsMissing(table, "LuaFnGetDFengEssenceSectionAndSelectedIndex")) table.Register("LuaFnGetDFengEssenceSectionAndSelectedIndex", LAG_DataPool_LuaFnGetDFengEssenceSectionAndSelectedIndex);
        if (IsMissing(table, "LuaFnGetDiaoWenName")) table.Register("LuaFnGetDiaoWenName", LAG_DataPool_LuaFnGetDiaoWenName);
        if (IsMissing(table, "LuaFnGetDiaoWenRankMaxExp")) table.Register("LuaFnGetDiaoWenRankMaxExp", LAG_DataPool_LuaFnGetDiaoWenRankMaxExp);
        if (IsMissing(table, "LuaFnGetDressCollectEffectMaxCount")) table.Register("LuaFnGetDressCollectEffectMaxCount", LAG_DataPool_LuaFnGetDressCollectEffectMaxCount);
        if (IsMissing(table, "LuaFnGetDressCollectionEffectInfo")) table.Register("LuaFnGetDressCollectionEffectInfo", LAG_DataPool_LuaFnGetDressCollectionEffectInfo);
        if (IsMissing(table, "LuaFnGetDressCollectionMaxCount")) table.Register("LuaFnGetDressCollectionMaxCount", LAG_DataPool_LuaFnGetDressCollectionMaxCount);
        if (IsMissing(table, "LuaFnGetDressCollectionToolTip")) table.Register("LuaFnGetDressCollectionToolTip", LAG_DataPool_LuaFnGetDressCollectionToolTip);
        if (IsMissing(table, "LuaFnGetDressInfoByExteriorId")) table.Register("LuaFnGetDressInfoByExteriorId", LAG_DataPool_LuaFnGetDressInfoByExteriorId);
        if (IsMissing(table, "LuaFnGetEmoSetId")) table.Register("LuaFnGetEmoSetId", LAG_DataPool_LuaFnGetEmoSetId);
        if (IsMissing(table, "LuaFnGetEmoSetName")) table.Register("LuaFnGetEmoSetName", LAG_DataPool_LuaFnGetEmoSetName);
        if (IsMissing(table, "LuaFnGetEmoValidHour")) table.Register("LuaFnGetEmoValidHour", LAG_DataPool_LuaFnGetEmoValidHour);
        if (IsMissing(table, "LuaFnGetEquipDWAttr")) table.Register("LuaFnGetEquipDWAttr", LAG_DataPool_LuaFnGetEquipDWAttr);
        if (IsMissing(table, "LuaFnGetEquipDiaoWenEffect")) table.Register("LuaFnGetEquipDiaoWenEffect", LAG_DataPool_LuaFnGetEquipDiaoWenEffect);
        if (IsMissing(table, "LuaFnGetEquipDiaoWenFeaturesId")) table.Register("LuaFnGetEquipDiaoWenFeaturesId", LAG_DataPool_LuaFnGetEquipDiaoWenFeaturesId);
        if (IsMissing(table, "LuaFnGetEquipDiaoWenJinJieEffect")) table.Register("LuaFnGetEquipDiaoWenJinJieEffect", LAG_DataPool_LuaFnGetEquipDiaoWenJinJieEffect);
        if (IsMissing(table, "LuaFnGetEquipDiaoWenRank")) table.Register("LuaFnGetEquipDiaoWenRank", LAG_DataPool_LuaFnGetEquipDiaoWenRank);
        if (IsMissing(table, "LuaFnGetEquipDiaoWenRankExp")) table.Register("LuaFnGetEquipDiaoWenRankExp", LAG_DataPool_LuaFnGetEquipDiaoWenRankExp);
        if (IsMissing(table, "LuaFnGetEquipDiaowenExp")) table.Register("LuaFnGetEquipDiaowenExp", LAG_DataPool_LuaFnGetEquipDiaowenExp);
        if (IsMissing(table, "LuaFnGetEquipDiaowenInfo")) table.Register("LuaFnGetEquipDiaowenInfo", LAG_DataPool_LuaFnGetEquipDiaowenInfo);
        if (IsMissing(table, "LuaFnGetEquipPointByTableIndex")) table.Register("LuaFnGetEquipPointByTableIndex", LAG_DataPool_LuaFnGetEquipPointByTableIndex);
        if (IsMissing(table, "LuaFnGetEquipRefreshAttrCount")) table.Register("LuaFnGetEquipRefreshAttrCount", LAG_DataPool_LuaFnGetEquipRefreshAttrCount);
        if (IsMissing(table, "LuaFnGetEquipTotalFeaturesValue")) table.Register("LuaFnGetEquipTotalFeaturesValue", LAG_DataPool_LuaFnGetEquipTotalFeaturesValue);
        if (IsMissing(table, "LuaFnGetEquipTotalValidFeaturesDesc")) table.Register("LuaFnGetEquipTotalValidFeaturesDesc", LAG_DataPool_LuaFnGetEquipTotalValidFeaturesDesc);
        if (IsMissing(table, "LuaFnGetEquipedShenBingData")) table.Register("LuaFnGetEquipedShenBingData", LAG_DataPool_LuaFnGetEquipedShenBingData);
        if (IsMissing(table, "LuaFnGetEquipedShenBingStarInfo")) table.Register("LuaFnGetEquipedShenBingStarInfo", LAG_DataPool_LuaFnGetEquipedShenBingStarInfo);
        if (IsMissing(table, "LuaFnGetExteriorRideIdFromRideCard")) table.Register("LuaFnGetExteriorRideIdFromRideCard", LAG_DataPool_LuaFnGetExteriorRideIdFromRideCard);
        if (IsMissing(table, "LuaFnGetFashionAuctionBiddingInfo")) table.Register("LuaFnGetFashionAuctionBiddingInfo", LAG_DataPool_LuaFnGetFashionAuctionBiddingInfo);
        if (IsMissing(table, "LuaFnGetFashionAuctionGroupIndexFromList")) table.Register("LuaFnGetFashionAuctionGroupIndexFromList", LAG_DataPool_LuaFnGetFashionAuctionGroupIndexFromList);
        if (IsMissing(table, "LuaFnGetFashionAuctionTopBidSortType")) table.Register("LuaFnGetFashionAuctionTopBidSortType", LAG_DataPool_LuaFnGetFashionAuctionTopBidSortType);
        if (IsMissing(table, "LuaFnGetFashionAuctionType")) table.Register("LuaFnGetFashionAuctionType", LAG_DataPool_LuaFnGetFashionAuctionType);
        if (IsMissing(table, "LuaFnGetFashionLotteryStage")) table.Register("LuaFnGetFashionLotteryStage", LAG_DataPool_LuaFnGetFashionLotteryStage);
        if (IsMissing(table, "LuaFnGetFeaturesDesc")) table.Register("LuaFnGetFeaturesDesc", LAG_DataPool_LuaFnGetFeaturesDesc);
        if (IsMissing(table, "LuaFnGetFeaturesEffectLimitDesc")) table.Register("LuaFnGetFeaturesEffectLimitDesc", LAG_DataPool_LuaFnGetFeaturesEffectLimitDesc);
        if (IsMissing(table, "LuaFnGetFeaturesEffectValueMax")) table.Register("LuaFnGetFeaturesEffectValueMax", LAG_DataPool_LuaFnGetFeaturesEffectValueMax);
        if (IsMissing(table, "LuaFnGetFeaturesInfo")) table.Register("LuaFnGetFeaturesInfo", LAG_DataPool_LuaFnGetFeaturesInfo);
        if (IsMissing(table, "LuaFnGetFeaturesListCount")) table.Register("LuaFnGetFeaturesListCount", LAG_DataPool_LuaFnGetFeaturesListCount);
        if (IsMissing(table, "LuaFnGetFeaturesMaxCount")) table.Register("LuaFnGetFeaturesMaxCount", LAG_DataPool_LuaFnGetFeaturesMaxCount);
        if (IsMissing(table, "LuaFnGetIcePrizeDrawCount")) table.Register("LuaFnGetIcePrizeDrawCount", LAG_DataPool_LuaFnGetIcePrizeDrawCount);
        if (IsMissing(table, "LuaFnGetIcePrizeDrawCountById")) table.Register("LuaFnGetIcePrizeDrawCountById", LAG_DataPool_LuaFnGetIcePrizeDrawCountById);
        if (IsMissing(table, "LuaFnGetIcePrizeDrawDataByInDex")) table.Register("LuaFnGetIcePrizeDrawDataByInDex", LAG_DataPool_LuaFnGetIcePrizeDrawDataByInDex);
        if (IsMissing(table, "LuaFnGetIcePrizeDrawInfo")) table.Register("LuaFnGetIcePrizeDrawInfo", LAG_DataPool_LuaFnGetIcePrizeDrawInfo);
        if (IsMissing(table, "LuaFnGetIcePrizeDrawListCount")) table.Register("LuaFnGetIcePrizeDrawListCount", LAG_DataPool_LuaFnGetIcePrizeDrawListCount);
        if (IsMissing(table, "LuaFnGetIcePrizeDrawNowId")) table.Register("LuaFnGetIcePrizeDrawNowId", LAG_DataPool_LuaFnGetIcePrizeDrawNowId);
        if (IsMissing(table, "LuaFnGetIcePrizeDrawNowState")) table.Register("LuaFnGetIcePrizeDrawNowState", LAG_DataPool_LuaFnGetIcePrizeDrawNowState);
        if (IsMissing(table, "LuaFnGetItemIconByTableIndex")) table.Register("LuaFnGetItemIconByTableIndex", LAG_DataPool_LuaFnGetItemIconByTableIndex);
        if (IsMissing(table, "LuaFnGetItemNameByTableIndex")) table.Register("LuaFnGetItemNameByTableIndex", LAG_DataPool_LuaFnGetItemNameByTableIndex);
        if (IsMissing(table, "LuaFnGetItemPetElfAttrDesc")) table.Register("LuaFnGetItemPetElfAttrDesc", LAG_DataPool_LuaFnGetItemPetElfAttrDesc);
        if (IsMissing(table, "LuaFnGetItemPetElfModel")) table.Register("LuaFnGetItemPetElfModel", LAG_DataPool_LuaFnGetItemPetElfModel);
        if (IsMissing(table, "LuaFnGetItemPetElfMutualId")) table.Register("LuaFnGetItemPetElfMutualId", LAG_DataPool_LuaFnGetItemPetElfMutualId);
        if (IsMissing(table, "LuaFnGetLingYuAttrCount")) table.Register("LuaFnGetLingYuAttrCount", LAG_DataPool_LuaFnGetLingYuAttrCount);
        if (IsMissing(table, "LuaFnGetLingYuAttrName")) table.Register("LuaFnGetLingYuAttrName", LAG_DataPool_LuaFnGetLingYuAttrName);
        if (IsMissing(table, "LuaFnGetLingYuAttrValueString")) table.Register("LuaFnGetLingYuAttrValueString", LAG_DataPool_LuaFnGetLingYuAttrValueString);
        if (IsMissing(table, "LuaFnGetLingYuSetAttrDesc")) table.Register("LuaFnGetLingYuSetAttrDesc", LAG_DataPool_LuaFnGetLingYuSetAttrDesc);
        if (IsMissing(table, "LuaFnGetLingYuSetEffectCount")) table.Register("LuaFnGetLingYuSetEffectCount", LAG_DataPool_LuaFnGetLingYuSetEffectCount);
        if (IsMissing(table, "LuaFnGetLingYuSetSkillForUI")) table.Register("LuaFnGetLingYuSetSkillForUI", LAG_DataPool_LuaFnGetLingYuSetSkillForUI);
        if (IsMissing(table, "LuaFnGetLotteryNumber")) table.Register("LuaFnGetLotteryNumber", LAG_DataPool_LuaFnGetLotteryNumber);
        if (IsMissing(table, "LuaFnGetLotterySignUpFlag")) table.Register("LuaFnGetLotterySignUpFlag", LAG_DataPool_LuaFnGetLotterySignUpFlag);
        if (IsMissing(table, "LuaFnGetLotteryTakeBackFlag")) table.Register("LuaFnGetLotteryTakeBackFlag", LAG_DataPool_LuaFnGetLotteryTakeBackFlag);
        if (IsMissing(table, "LuaFnGetMD")) table.Register("LuaFnGetMD", LAG_DataPool_LuaFnGetMD);
        if (IsMissing(table, "LuaFnGetMF")) table.Register("LuaFnGetMF", LAG_DataPool_LuaFnGetMF);
        if (IsMissing(table, "LuaFnGetMyLotteryNumber")) table.Register("LuaFnGetMyLotteryNumber", LAG_DataPool_LuaFnGetMyLotteryNumber);
        if (IsMissing(table, "LuaFnGetNecklaceDW")) table.Register("LuaFnGetNecklaceDW", LAG_DataPool_LuaFnGetNecklaceDW);
        if (IsMissing(table, "LuaFnGetOtherEquipDiaoWenEffect")) table.Register("LuaFnGetOtherEquipDiaoWenEffect", LAG_DataPool_LuaFnGetOtherEquipDiaoWenEffect);
        if (IsMissing(table, "LuaFnGetOtherEquipDiaoWenFeaturesId")) table.Register("LuaFnGetOtherEquipDiaoWenFeaturesId", LAG_DataPool_LuaFnGetOtherEquipDiaoWenFeaturesId);
        if (IsMissing(table, "LuaFnGetOtherEquipDiaoWenJinJieEffect")) table.Register("LuaFnGetOtherEquipDiaoWenJinJieEffect", LAG_DataPool_LuaFnGetOtherEquipDiaoWenJinJieEffect);
        if (IsMissing(table, "LuaFnGetOtherEquipDiaoWenRank")) table.Register("LuaFnGetOtherEquipDiaoWenRank", LAG_DataPool_LuaFnGetOtherEquipDiaoWenRank);
        if (IsMissing(table, "LuaFnGetOtherEquipDiaoWenRankExp")) table.Register("LuaFnGetOtherEquipDiaoWenRankExp", LAG_DataPool_LuaFnGetOtherEquipDiaoWenRankExp);
        if (IsMissing(table, "LuaFnGetOtherEquipDiaowenExp")) table.Register("LuaFnGetOtherEquipDiaowenExp", LAG_DataPool_LuaFnGetOtherEquipDiaowenExp);
        if (IsMissing(table, "LuaFnGetOtherEquipDiaowenInfo")) table.Register("LuaFnGetOtherEquipDiaowenInfo", LAG_DataPool_LuaFnGetOtherEquipDiaowenInfo);
        if (IsMissing(table, "LuaFnGetOtherEquipTotalFeaturesValue")) table.Register("LuaFnGetOtherEquipTotalFeaturesValue", LAG_DataPool_LuaFnGetOtherEquipTotalFeaturesValue);
        if (IsMissing(table, "LuaFnGetOtherEquipTotalValidFeaturesDesc")) table.Register("LuaFnGetOtherEquipTotalValidFeaturesDesc", LAG_DataPool_LuaFnGetOtherEquipTotalValidFeaturesDesc);
        if (IsMissing(table, "LuaFnGetOtherEquipedShenBingStarInfo")) table.Register("LuaFnGetOtherEquipedShenBingStarInfo", LAG_DataPool_LuaFnGetOtherEquipedShenBingStarInfo);
        if (IsMissing(table, "LuaFnGetOtherFeaturesEffectLimitDesc")) table.Register("LuaFnGetOtherFeaturesEffectLimitDesc", LAG_DataPool_LuaFnGetOtherFeaturesEffectLimitDesc);
        if (IsMissing(table, "LuaFnGetOtherFeaturesInfo")) table.Register("LuaFnGetOtherFeaturesInfo", LAG_DataPool_LuaFnGetOtherFeaturesInfo);
        if (IsMissing(table, "LuaFnGetOtherLingYuAttrCount")) table.Register("LuaFnGetOtherLingYuAttrCount", LAG_DataPool_LuaFnGetOtherLingYuAttrCount);
        if (IsMissing(table, "LuaFnGetOtherLingYuAttrName")) table.Register("LuaFnGetOtherLingYuAttrName", LAG_DataPool_LuaFnGetOtherLingYuAttrName);
        if (IsMissing(table, "LuaFnGetOtherLingYuAttrValueString")) table.Register("LuaFnGetOtherLingYuAttrValueString", LAG_DataPool_LuaFnGetOtherLingYuAttrValueString);
        if (IsMissing(table, "LuaFnGetOtherLingYuSetAttrDesc")) table.Register("LuaFnGetOtherLingYuSetAttrDesc", LAG_DataPool_LuaFnGetOtherLingYuSetAttrDesc);
        if (IsMissing(table, "LuaFnGetOtherLingYuSetEffectCount")) table.Register("LuaFnGetOtherLingYuSetEffectCount", LAG_DataPool_LuaFnGetOtherLingYuSetEffectCount);
        if (IsMissing(table, "LuaFnGetOtherShenBingExtensionAttr")) table.Register("LuaFnGetOtherShenBingExtensionAttr", LAG_DataPool_LuaFnGetOtherShenBingExtensionAttr);
        if (IsMissing(table, "LuaFnGetOtherWHWGAllAttrCount")) table.Register("LuaFnGetOtherWHWGAllAttrCount", LAG_DataPool_LuaFnGetOtherWHWGAllAttrCount);
        if (IsMissing(table, "LuaFnGetOtherWHWGAllAttrDesc")) table.Register("LuaFnGetOtherWHWGAllAttrDesc", LAG_DataPool_LuaFnGetOtherWHWGAllAttrDesc);
        if (IsMissing(table, "LuaFnGetRanSePlanAddNum")) table.Register("LuaFnGetRanSePlanAddNum", LAG_DataPool_LuaFnGetRanSePlanAddNum);
        if (IsMissing(table, "LuaFnGetRideCardActivedFlag")) table.Register("LuaFnGetRideCardActivedFlag", LAG_DataPool_LuaFnGetRideCardActivedFlag);
        if (IsMissing(table, "LuaFnGetRideCardHaveRideCount")) table.Register("LuaFnGetRideCardHaveRideCount", LAG_DataPool_LuaFnGetRideCardHaveRideCount);
        if (IsMissing(table, "LuaFnGetRideCardLeftTime")) table.Register("LuaFnGetRideCardLeftTime", LAG_DataPool_LuaFnGetRideCardLeftTime);
        if (IsMissing(table, "LuaFnGetRideCollectionEffectSummary")) table.Register("LuaFnGetRideCollectionEffectSummary", LAG_DataPool_LuaFnGetRideCollectionEffectSummary);
        if (IsMissing(table, "LuaFnGetRideCollectionListCount")) table.Register("LuaFnGetRideCollectionListCount", LAG_DataPool_LuaFnGetRideCollectionListCount);
        if (IsMissing(table, "LuaFnGetRideCollectionMaxCount")) table.Register("LuaFnGetRideCollectionMaxCount", LAG_DataPool_LuaFnGetRideCollectionMaxCount);
        if (IsMissing(table, "LuaFnGetRideSeriesInfo")) table.Register("LuaFnGetRideSeriesInfo", LAG_DataPool_LuaFnGetRideSeriesInfo);
        if (IsMissing(table, "LuaFnGetShenBingCount")) table.Register("LuaFnGetShenBingCount", LAG_DataPool_LuaFnGetShenBingCount);
        if (IsMissing(table, "LuaFnGetShenBingExtensionAttr")) table.Register("LuaFnGetShenBingExtensionAttr", LAG_DataPool_LuaFnGetShenBingExtensionAttr);
        if (IsMissing(table, "LuaFnGetShenBingFromJian")) table.Register("LuaFnGetShenBingFromJian", LAG_DataPool_LuaFnGetShenBingFromJian);
        if (IsMissing(table, "LuaFnGetShenBingSkillDesc")) table.Register("LuaFnGetShenBingSkillDesc", LAG_DataPool_LuaFnGetShenBingSkillDesc);
        if (IsMissing(table, "LuaFnGetSnowShopCJItemInfo")) table.Register("LuaFnGetSnowShopCJItemInfo", LAG_DataPool_LuaFnGetSnowShopCJItemInfo);
        if (IsMissing(table, "LuaFnGetWHWGAllAttrCount")) table.Register("LuaFnGetWHWGAllAttrCount", LAG_DataPool_LuaFnGetWHWGAllAttrCount);
        if (IsMissing(table, "LuaFnGetWHWGAllAttrDesc")) table.Register("LuaFnGetWHWGAllAttrDesc", LAG_DataPool_LuaFnGetWHWGAllAttrDesc);
        if (IsMissing(table, "LuaFnGetWHWGIDFromList")) table.Register("LuaFnGetWHWGIDFromList", LAG_DataPool_LuaFnGetWHWGIDFromList);
        if (IsMissing(table, "LuaFnGetWHWGInSlot")) table.Register("LuaFnGetWHWGInSlot", LAG_DataPool_LuaFnGetWHWGInSlot);
        if (IsMissing(table, "LuaFnGetWHWGInfo")) table.Register("LuaFnGetWHWGInfo", LAG_DataPool_LuaFnGetWHWGInfo);
        if (IsMissing(table, "LuaFnGetWHWGLevelInfo")) table.Register("LuaFnGetWHWGLevelInfo", LAG_DataPool_LuaFnGetWHWGLevelInfo);
        if (IsMissing(table, "LuaFnGetWHWGListCount")) table.Register("LuaFnGetWHWGListCount", LAG_DataPool_LuaFnGetWHWGListCount);
        if (IsMissing(table, "LuaFnGetWHWGMaxCount")) table.Register("LuaFnGetWHWGMaxCount", LAG_DataPool_LuaFnGetWHWGMaxCount);
        if (IsMissing(table, "LuaFnGetWorldAuctionBiddingInfo")) table.Register("LuaFnGetWorldAuctionBiddingInfo", LAG_DataPool_LuaFnGetWorldAuctionBiddingInfo);
        if (IsMissing(table, "LuaFnGetWorldAuctionGetTime")) table.Register("LuaFnGetWorldAuctionGetTime", LAG_DataPool_LuaFnGetWorldAuctionGetTime);
        if (IsMissing(table, "LuaFnGetWorldAuctionIdByIndex")) table.Register("LuaFnGetWorldAuctionIdByIndex", LAG_DataPool_LuaFnGetWorldAuctionIdByIndex);
        if (IsMissing(table, "LuaFnGetWorldAuctionIsUpItemTime")) table.Register("LuaFnGetWorldAuctionIsUpItemTime", LAG_DataPool_LuaFnGetWorldAuctionIsUpItemTime);
        if (IsMissing(table, "LuaFnGetWorldAuctionItemNameById")) table.Register("LuaFnGetWorldAuctionItemNameById", LAG_DataPool_LuaFnGetWorldAuctionItemNameById);
        if (IsMissing(table, "LuaFnGetWorldAuctionListCount")) table.Register("LuaFnGetWorldAuctionListCount", LAG_DataPool_LuaFnGetWorldAuctionListCount);
        if (IsMissing(table, "LuaFnGetWorldAuctionTopBidSortType")) table.Register("LuaFnGetWorldAuctionTopBidSortType", LAG_DataPool_LuaFnGetWorldAuctionTopBidSortType);
        if (IsMissing(table, "LuaFnGetYYFlag")) table.Register("LuaFnGetYYFlag", LAG_DataPool_LuaFnGetYYFlag);
        if (IsMissing(table, "LuaFnInitDressCollectionList")) table.Register("LuaFnInitDressCollectionList", LAG_DataPool_LuaFnInitDressCollectionList);
        if (IsMissing(table, "LuaFnInitFeaturesList")) table.Register("LuaFnInitFeaturesList", LAG_DataPool_LuaFnInitFeaturesList);
        if (IsMissing(table, "LuaFnInitRideCollectionList")) table.Register("LuaFnInitRideCollectionList", LAG_DataPool_LuaFnInitRideCollectionList);
        if (IsMissing(table, "LuaFnInitWHWGList")) table.Register("LuaFnInitWHWGList", LAG_DataPool_LuaFnInitWHWGList);
        if (IsMissing(table, "LuaFnIsActiveDressCollectByExteriorIdx")) table.Register("LuaFnIsActiveDressCollectByExteriorIdx", LAG_DataPool_LuaFnIsActiveDressCollectByExteriorIdx);
        if (IsMissing(table, "LuaFnIsCanReliveInDLSY")) table.Register("LuaFnIsCanReliveInDLSY", LAG_DataPool_LuaFnIsCanReliveInDLSY);
        if (IsMissing(table, "LuaFnIsCanReliveInTJCPVP")) table.Register("LuaFnIsCanReliveInTJCPVP", LAG_DataPool_LuaFnIsCanReliveInTJCPVP);
        if (IsMissing(table, "LuaFnIsCurLotteryGetNumberOver")) table.Register("LuaFnIsCurLotteryGetNumberOver", LAG_DataPool_LuaFnIsCurLotteryGetNumberOver);
        if (IsMissing(table, "LuaFnIsEquipHaveValidFeaturesEffect")) table.Register("LuaFnIsEquipHaveValidFeaturesEffect", LAG_DataPool_LuaFnIsEquipHaveValidFeaturesEffect);
        if (IsMissing(table, "LuaFnIsEquipShenBing")) table.Register("LuaFnIsEquipShenBing", LAG_DataPool_LuaFnIsEquipShenBing);
        if (IsMissing(table, "LuaFnIsExteriorRideActiveByRideCard")) table.Register("LuaFnIsExteriorRideActiveByRideCard", LAG_DataPool_LuaFnIsExteriorRideActiveByRideCard);
        if (IsMissing(table, "LuaFnIsLotteryDraw")) table.Register("LuaFnIsLotteryDraw", LAG_DataPool_LuaFnIsLotteryDraw);
        if (IsMissing(table, "LuaFnIsLotteryWin")) table.Register("LuaFnIsLotteryWin", LAG_DataPool_LuaFnIsLotteryWin);
        if (IsMissing(table, "LuaFnIsWorldAuctionItemByIndex")) table.Register("LuaFnIsWorldAuctionItemByIndex", LAG_DataPool_LuaFnIsWorldAuctionItemByIndex);
        if (IsMissing(table, "LuaFnOpenFashionLotteryDressPreview")) table.Register("LuaFnOpenFashionLotteryDressPreview", LAG_DataPool_LuaFnOpenFashionLotteryDressPreview);
        if (IsMissing(table, "LuaFnOpenSocialServer")) table.Register("LuaFnOpenSocialServer", LAG_DataPool_LuaFnOpenSocialServer);
        if (IsMissing(table, "LuaFnOpenSocialServerFlag")) table.Register("LuaFnOpenSocialServerFlag", LAG_DataPool_LuaFnOpenSocialServerFlag);
        if (IsMissing(table, "LuaFnOpenWHWG")) table.Register("LuaFnOpenWHWG", LAG_DataPool_LuaFnOpenWHWG);
        if (IsMissing(table, "LuaFnOpenWHWGChange")) table.Register("LuaFnOpenWHWGChange", LAG_DataPool_LuaFnOpenWHWGChange);
        if (IsMissing(table, "LuaFnOtherEnumEquipShenBingSkillAction")) table.Register("LuaFnOtherEnumEquipShenBingSkillAction", LAG_DataPool_LuaFnOtherEnumEquipShenBingSkillAction);
        if (IsMissing(table, "LuaFnOtherGetEquipedShenBingData")) table.Register("LuaFnOtherGetEquipedShenBingData", LAG_DataPool_LuaFnOtherGetEquipedShenBingData);
        if (IsMissing(table, "LuaFnOtherIsEquipShenBing")) table.Register("LuaFnOtherIsEquipShenBing", LAG_DataPool_LuaFnOtherIsEquipShenBing);
        if (IsMissing(table, "LuaFnReqRideCardLeftTime")) table.Register("LuaFnReqRideCardLeftTime", LAG_DataPool_LuaFnReqRideCardLeftTime);
        if (IsMissing(table, "LuaFnSetFashionAuctionTopBidSortType")) table.Register("LuaFnSetFashionAuctionTopBidSortType", LAG_DataPool_LuaFnSetFashionAuctionTopBidSortType);
        if (IsMissing(table, "LuaFnSetItemPetElfAvatar1Model")) table.Register("LuaFnSetItemPetElfAvatar1Model", LAG_DataPool_LuaFnSetItemPetElfAvatar1Model);
        if (IsMissing(table, "LuaFnSetItemPetElfAvatar2Model")) table.Register("LuaFnSetItemPetElfAvatar2Model", LAG_DataPool_LuaFnSetItemPetElfAvatar2Model);
        if (IsMissing(table, "LuaFnSetPetKaiWuPetModel")) table.Register("LuaFnSetPetKaiWuPetModel", LAG_DataPool_LuaFnSetPetKaiWuPetModel);
        if (IsMissing(table, "LuaFnSetPetKaiWuTargetPetModel")) table.Register("LuaFnSetPetKaiWuTargetPetModel", LAG_DataPool_LuaFnSetPetKaiWuTargetPetModel);
        if (IsMissing(table, "LuaFnSetPetSoulAvatarModel")) table.Register("LuaFnSetPetSoulAvatarModel", LAG_DataPool_LuaFnSetPetSoulAvatarModel);
        if (IsMissing(table, "LuaFnSetWorldAuctionTopBidSortType")) table.Register("LuaFnSetWorldAuctionTopBidSortType", LAG_DataPool_LuaFnSetWorldAuctionTopBidSortType);
        if (IsMissing(table, "LuaFnShowEquipRefreshCloseConfirm")) table.Register("LuaFnShowEquipRefreshCloseConfirm", LAG_DataPool_LuaFnShowEquipRefreshCloseConfirm);
        if (IsMissing(table, "LuaFnShowEquipRefreshEquipChangeConfirm")) table.Register("LuaFnShowEquipRefreshEquipChangeConfirm", LAG_DataPool_LuaFnShowEquipRefreshEquipChangeConfirm);
        if (IsMissing(table, "LuaFnSortFashionAuctionList")) table.Register("LuaFnSortFashionAuctionList", LAG_DataPool_LuaFnSortFashionAuctionList);
        if (IsMissing(table, "LuaFnSortWorldAuctionList")) table.Register("LuaFnSortWorldAuctionList", LAG_DataPool_LuaFnSortWorldAuctionList);
        if (IsMissing(table, "LuaFnUnInstallEmo")) table.Register("LuaFnUnInstallEmo", LAG_DataPool_LuaFnUnInstallEmo);
        if (IsMissing(table, "LuaFnUpdateLingYuAttrList")) table.Register("LuaFnUpdateLingYuAttrList", LAG_DataPool_LuaFnUpdateLingYuAttrList);
        if (IsMissing(table, "LuaFnUpdateOtherShenBingModel")) table.Register("LuaFnUpdateOtherShenBingModel", LAG_DataPool_LuaFnUpdateOtherShenBingModel);
        if (IsMissing(table, "LuaFnUpdatePetSoulAvatarFromPet")) table.Register("LuaFnUpdatePetSoulAvatarFromPet", LAG_DataPool_LuaFnUpdatePetSoulAvatarFromPet);
        if (IsMissing(table, "LuaFnUpdateShenBingCamera")) table.Register("LuaFnUpdateShenBingCamera", LAG_DataPool_LuaFnUpdateShenBingCamera);
        if (IsMissing(table, "LuaFnUpdateShenBingJianModel")) table.Register("LuaFnUpdateShenBingJianModel", LAG_DataPool_LuaFnUpdateShenBingJianModel);
        if (IsMissing(table, "LuaFnUpdateShenBingModel")) table.Register("LuaFnUpdateShenBingModel", LAG_DataPool_LuaFnUpdateShenBingModel);
        if (IsMissing(table, "LuaFnUpdateWHWGModel")) table.Register("LuaFnUpdateWHWGModel", LAG_DataPool_LuaFnUpdateWHWGModel);
        if (IsMissing(table, "LuaFnWHWGAttrSTR")) table.Register("LuaFnWHWGAttrSTR", LAG_DataPool_LuaFnWHWGAttrSTR);
        if (IsMissing(table, "LuaFnWHWGEffect")) table.Register("LuaFnWHWGEffect", LAG_DataPool_LuaFnWHWGEffect);
        if (IsMissing(table, "LuaGetCurrentServerTime")) table.Register("LuaGetCurrentServerTime", LAG_DataPool_LuaGetCurrentServerTime);
        if (IsMissing(table, "Lua_ArriveServerTime_Add")) table.Register("Lua_ArriveServerTime_Add", LAG_DataPool_Lua_ArriveServerTime_Add);
        if (IsMissing(table, "Lua_ArriveServerTime_Clear")) table.Register("Lua_ArriveServerTime_Clear", LAG_DataPool_Lua_ArriveServerTime_Clear);
        if (IsMissing(table, "Lua_CheckHJTSMissionForbiddenItem")) table.Register("Lua_CheckHJTSMissionForbiddenItem", LAG_DataPool_Lua_CheckHJTSMissionForbiddenItem);
        if (IsMissing(table, "Lua_CheckIsShowTalent")) table.Register("Lua_CheckIsShowTalent", LAG_DataPool_Lua_CheckIsShowTalent);
        if (IsMissing(table, "Lua_CheckOpenTalent")) table.Register("Lua_CheckOpenTalent", LAG_DataPool_Lua_CheckOpenTalent);
        if (IsMissing(table, "Lua_ClearFanChangItemInfo")) table.Register("Lua_ClearFanChangItemInfo", LAG_DataPool_Lua_ClearFanChangItemInfo);
        if (IsMissing(table, "Lua_ClearZNFCShopItemInfo")) table.Register("Lua_ClearZNFCShopItemInfo", LAG_DataPool_Lua_ClearZNFCShopItemInfo);
        if (IsMissing(table, "Lua_CreateSectInfoAction")) table.Register("Lua_CreateSectInfoAction", LAG_DataPool_Lua_CreateSectInfoAction);
        if (IsMissing(table, "Lua_DressGemListA_Update")) table.Register("Lua_DressGemListA_Update", LAG_DataPool_Lua_DressGemListA_Update);
        if (IsMissing(table, "Lua_DressGemListB_Update")) table.Register("Lua_DressGemListB_Update", LAG_DataPool_Lua_DressGemListB_Update);
        if (IsMissing(table, "Lua_GemComposeLayedItem_Update")) table.Register("Lua_GemComposeLayedItem_Update", LAG_DataPool_Lua_GemComposeLayedItem_Update);
        if (IsMissing(table, "Lua_GemMeltingLayedItem_Update")) table.Register("Lua_GemMeltingLayedItem_Update", LAG_DataPool_Lua_GemMeltingLayedItem_Update);
        if (IsMissing(table, "Lua_GetAnnINTParamByIndex")) table.Register("Lua_GetAnnINTParamByIndex", LAG_DataPool_Lua_GetAnnINTParamByIndex);
        if (IsMissing(table, "Lua_GetAnnWGDataByIndex")) table.Register("Lua_GetAnnWGDataByIndex", LAG_DataPool_Lua_GetAnnWGDataByIndex);
        if (IsMissing(table, "Lua_GetDDZBaoMingInfo")) table.Register("Lua_GetDDZBaoMingInfo", LAG_DataPool_Lua_GetDDZBaoMingInfo);
        if (IsMissing(table, "Lua_GetDDZMatchCnt")) table.Register("Lua_GetDDZMatchCnt", LAG_DataPool_Lua_GetDDZMatchCnt);
        if (IsMissing(table, "Lua_GetDDZMatchInfo")) table.Register("Lua_GetDDZMatchInfo", LAG_DataPool_Lua_GetDDZMatchInfo);
        if (IsMissing(table, "Lua_GetDDZYaZhuInfo")) table.Register("Lua_GetDDZYaZhuInfo", LAG_DataPool_Lua_GetDDZYaZhuInfo);
        if (IsMissing(table, "Lua_GetFestivalShopData")) table.Register("Lua_GetFestivalShopData", LAG_DataPool_Lua_GetFestivalShopData);
        if (IsMissing(table, "Lua_GetFuQiShopDBConfirmSkip")) table.Register("Lua_GetFuQiShopDBConfirmSkip", LAG_DataPool_Lua_GetFuQiShopDBConfirmSkip);
        if (IsMissing(table, "Lua_GetFuQiShopData")) table.Register("Lua_GetFuQiShopData", LAG_DataPool_Lua_GetFuQiShopData);
        if (IsMissing(table, "Lua_GetFuQiShopTotalCount")) table.Register("Lua_GetFuQiShopTotalCount", LAG_DataPool_Lua_GetFuQiShopTotalCount);
        if (IsMissing(table, "Lua_GetIsBigWorld")) table.Register("Lua_GetIsBigWorld", LAG_DataPool_Lua_GetIsBigWorld);
        if (IsMissing(table, "Lua_GetIsThreeDaLi")) table.Register("Lua_GetIsThreeDaLi", LAG_DataPool_Lua_GetIsThreeDaLi);
        if (IsMissing(table, "Lua_GetItemNameByIndex")) table.Register("Lua_GetItemNameByIndex", LAG_DataPool_Lua_GetItemNameByIndex);
        if (IsMissing(table, "Lua_GetQingRenJieReceiveTopListInfo")) table.Register("Lua_GetQingRenJieReceiveTopListInfo", LAG_DataPool_Lua_GetQingRenJieReceiveTopListInfo);
        if (IsMissing(table, "Lua_GetQingRenJieSendTopListInfo")) table.Register("Lua_GetQingRenJieSendTopListInfo", LAG_DataPool_Lua_GetQingRenJieSendTopListInfo);
        if (IsMissing(table, "Lua_GetQixiReceiveTopListInfo")) table.Register("Lua_GetQixiReceiveTopListInfo", LAG_DataPool_Lua_GetQixiReceiveTopListInfo);
        if (IsMissing(table, "Lua_GetQixiSendTopListInfo")) table.Register("Lua_GetQixiSendTopListInfo", LAG_DataPool_Lua_GetQixiSendTopListInfo);
        if (IsMissing(table, "Lua_GetRoseReceiveTopListInfo")) table.Register("Lua_GetRoseReceiveTopListInfo", LAG_DataPool_Lua_GetRoseReceiveTopListInfo);
        if (IsMissing(table, "Lua_GetRoseSendTopListInfo")) table.Register("Lua_GetRoseSendTopListInfo", LAG_DataPool_Lua_GetRoseSendTopListInfo);
        if (IsMissing(table, "Lua_GetRoseTopListInfo")) table.Register("Lua_GetRoseTopListInfo", LAG_DataPool_Lua_GetRoseTopListInfo);
        if (IsMissing(table, "Lua_GetSectDesc")) table.Register("Lua_GetSectDesc", LAG_DataPool_Lua_GetSectDesc);
        if (IsMissing(table, "Lua_GetSectName")) table.Register("Lua_GetSectName", LAG_DataPool_Lua_GetSectName);
        if (IsMissing(table, "Lua_GetSectPoint")) table.Register("Lua_GetSectPoint", LAG_DataPool_Lua_GetSectPoint);
        if (IsMissing(table, "Lua_GetSectSchema")) table.Register("Lua_GetSectSchema", LAG_DataPool_Lua_GetSectSchema);
        if (IsMissing(table, "Lua_GetSectTotalLevel")) table.Register("Lua_GetSectTotalLevel", LAG_DataPool_Lua_GetSectTotalLevel);
        if (IsMissing(table, "Lua_GetSectinvest")) table.Register("Lua_GetSectinvest", LAG_DataPool_Lua_GetSectinvest);
        if (IsMissing(table, "Lua_GetSongLiaoGuidFromlist")) table.Register("Lua_GetSongLiaoGuidFromlist", LAG_DataPool_Lua_GetSongLiaoGuidFromlist);
        if (IsMissing(table, "Lua_GetSuperRecoinEnumAttr")) table.Register("Lua_GetSuperRecoinEnumAttr", LAG_DataPool_Lua_GetSuperRecoinEnumAttr);
        if (IsMissing(table, "Lua_GetSuperRecoinNum")) table.Register("Lua_GetSuperRecoinNum", LAG_DataPool_Lua_GetSuperRecoinNum);
        if (IsMissing(table, "Lua_GetTSPhoenixCamp")) table.Register("Lua_GetTSPhoenixCamp", LAG_DataPool_Lua_GetTSPhoenixCamp);
        if (IsMissing(table, "Lua_GetTSPhoenixData")) table.Register("Lua_GetTSPhoenixData", LAG_DataPool_Lua_GetTSPhoenixData);
        if (IsMissing(table, "Lua_GetTSPhoenixScore")) table.Register("Lua_GetTSPhoenixScore", LAG_DataPool_Lua_GetTSPhoenixScore);
        if (IsMissing(table, "Lua_GetTargetSectMT")) table.Register("Lua_GetTargetSectMT", LAG_DataPool_Lua_GetTargetSectMT);
        if (IsMissing(table, "Lua_GetXiuChangUserRuleDes")) table.Register("Lua_GetXiuChangUserRuleDes", LAG_DataPool_Lua_GetXiuChangUserRuleDes);
        if (IsMissing(table, "Lua_HasSect")) table.Register("Lua_HasSect", LAG_DataPool_Lua_HasSect);
        if (IsMissing(table, "Lua_IsHaveMission")) table.Register("Lua_IsHaveMission", LAG_DataPool_Lua_IsHaveMission);
        if (IsMissing(table, "Lua_IsInTServer")) table.Register("Lua_IsInTServer", LAG_DataPool_Lua_IsInTServer);
        if (IsMissing(table, "Lua_IsMissionComplete")) table.Register("Lua_IsMissionComplete", LAG_DataPool_Lua_IsMissionComplete);
        if (IsMissing(table, "Lua_IsMissionHaveDone")) table.Register("Lua_IsMissionHaveDone", LAG_DataPool_Lua_IsMissionHaveDone);
        if (IsMissing(table, "Lua_OpenFuQiShop")) table.Register("Lua_OpenFuQiShop", LAG_DataPool_Lua_OpenFuQiShop);
        if (IsMissing(table, "Lua_SetFanChangItemInfo")) table.Register("Lua_SetFanChangItemInfo", LAG_DataPool_Lua_SetFanChangItemInfo);
        if (IsMissing(table, "Lua_SetFuQiShopDBConfirmSkip")) table.Register("Lua_SetFuQiShopDBConfirmSkip", LAG_DataPool_Lua_SetFuQiShopDBConfirmSkip);
        if (IsMissing(table, "Lua_SetZNFCShopItemInfo")) table.Register("Lua_SetZNFCShopItemInfo", LAG_DataPool_Lua_SetZNFCShopItemInfo);
        if (IsMissing(table, "Lua_SortDDZRankInfo")) table.Register("Lua_SortDDZRankInfo", LAG_DataPool_Lua_SortDDZRankInfo);
        if (IsMissing(table, "MissionTrackGotoQuestLog")) table.Register("MissionTrackGotoQuestLog", LAG_DataPool_MissionTrackGotoQuestLog);
        if (IsMissing(table, "ModifyGroupingName")) table.Register("ModifyGroupingName", LAG_DataPool_ModifyGroupingName);
        if (IsMissing(table, "NumCityFromOneProvince")) table.Register("NumCityFromOneProvince", LAG_DataPool_NumCityFromOneProvince);
        if (IsMissing(table, "OpenDelCheckBox")) table.Register("OpenDelCheckBox", LAG_DataPool_OpenDelCheckBox);
        if (IsMissing(table, "OpenDelTrustFriendCheckBox")) table.Register("OpenDelTrustFriendCheckBox", LAG_DataPool_OpenDelTrustFriendCheckBox);
        if (IsMissing(table, "OpenFenxianDlg")) table.Register("OpenFenxianDlg", LAG_DataPool_OpenFenxianDlg);
        if (IsMissing(table, "OpenFirstFriendChatInMsgPool")) table.Register("OpenFirstFriendChatInMsgPool", LAG_DataPool_OpenFirstFriendChatInMsgPool);
        if (IsMissing(table, "OpenIMChat")) table.Register("OpenIMChat", LAG_DataPool_OpenIMChat);
        if (IsMissing(table, "OpenMailRead")) table.Register("OpenMailRead", LAG_DataPool_OpenMailRead);
        if (IsMissing(table, "OpenSystemHistroy")) table.Register("OpenSystemHistroy", LAG_DataPool_OpenSystemHistroy);
        if (IsMissing(table, "PetSkinJiHuoType")) table.Register("PetSkinJiHuoType", LAG_DataPool_PetSkinJiHuoType);
        if (IsMissing(table, "PetSoulHandbook_SetCurSelLevel")) table.Register("PetSoulHandbook_SetCurSelLevel", LAG_DataPool_PetSoulHandbook_SetCurSelLevel);
        if (IsMissing(table, "PetSoulHandbook_SetPetModel")) table.Register("PetSoulHandbook_SetPetModel", LAG_DataPool_PetSoulHandbook_SetPetModel);
        if (IsMissing(table, "PetsOneTypeJiHuo_Index")) table.Register("PetsOneTypeJiHuo_Index", LAG_DataPool_PetsOneTypeJiHuo_Index);
        if (IsMissing(table, "PetsOneTypeJiHuo_JiHuoType")) table.Register("PetsOneTypeJiHuo_JiHuoType", LAG_DataPool_PetsOneTypeJiHuo_JiHuoType);
        if (IsMissing(table, "PetsOneType_GetAttr")) table.Register("PetsOneType_GetAttr", LAG_DataPool_PetsOneType_GetAttr);
        if (IsMissing(table, "PetsOneType_SetModel")) table.Register("PetsOneType_SetModel", LAG_DataPool_PetsOneType_SetModel);
        if (IsMissing(table, "PetsOneType_SetModel77")) table.Register("PetsOneType_SetModel77", LAG_DataPool_PetsOneType_SetModel77);
        if (IsMissing(table, "ReConnect")) table.Register("ReConnect", LAG_DataPool_ReConnect);
        if (IsMissing(table, "ResetBugFBtime")) table.Register("ResetBugFBtime", LAG_DataPool_ResetBugFBtime);
        if (IsMissing(table, "RespondChallenge")) table.Register("RespondChallenge", LAG_DataPool_RespondChallenge);
        if (IsMissing(table, "ScriptPlus")) table.Register("ScriptPlus", LAG_DataPool_ScriptPlus);
        if (IsMissing(table, "SearchFriends")) table.Register("SearchFriends", LAG_DataPool_SearchFriends);
        if (IsMissing(table, "SelectTeamMemPetAsTargetByUIIndex")) table.Register("SelectTeamMemPetAsTargetByUIIndex", LAG_DataPool_SelectTeamMemPetAsTargetByUIIndex);
        if (IsMissing(table, "SendBugFB")) table.Register("SendBugFB", LAG_DataPool_SendBugFB);
        if (IsMissing(table, "SetBugFBcount")) table.Register("SetBugFBcount", LAG_DataPool_SetBugFBcount);
        if (IsMissing(table, "SetCampaignTrackOpen")) table.Register("SetCampaignTrackOpen", LAG_DataPool_SetCampaignTrackOpen);
        if (IsMissing(table, "SetCanUseHotKey")) table.Register("SetCanUseHotKey", LAG_DataPool_SetCanUseHotKey);
        if (IsMissing(table, "SetCurrentChatChannel")) table.Register("SetCurrentChatChannel", LAG_DataPool_SetCurrentChatChannel);
        if (IsMissing(table, "SetCurrentChatIndex")) table.Register("SetCurrentChatIndex", LAG_DataPool_SetCurrentChatIndex);
        if (IsMissing(table, "SetDestroyErciQueRen")) table.Register("SetDestroyErciQueRen", LAG_DataPool_SetDestroyErciQueRen);
        if (IsMissing(table, "SetLongHaiZiModel")) table.Register("SetLongHaiZiModel", LAG_DataPool_SetLongHaiZiModel);
        if (IsMissing(table, "SetMissionTrackOpen")) table.Register("SetMissionTrackOpen", LAG_DataPool_SetMissionTrackOpen);
        if (IsMissing(table, "SetMsgRead")) table.Register("SetMsgRead", LAG_DataPool_SetMsgRead);
        if (IsMissing(table, "SetPetFightList_Show1")) table.Register("SetPetFightList_Show1", LAG_DataPool_SetPetFightList_Show1);
        if (IsMissing(table, "SetPetFightList_Show2")) table.Register("SetPetFightList_Show2", LAG_DataPool_SetPetFightList_Show2);
        if (IsMissing(table, "SetPetSkinModel")) table.Register("SetPetSkinModel", LAG_DataPool_SetPetSkinModel);
        if (IsMissing(table, "SetPetTujianModel")) table.Register("SetPetTujianModel", LAG_DataPool_SetPetTujianModel);
        if (IsMissing(table, "SetRabbitModel")) table.Register("SetRabbitModel", LAG_DataPool_SetRabbitModel);
        if (IsMissing(table, "SetRemark")) table.Register("SetRemark", LAG_DataPool_SetRemark);
        if (IsMissing(table, "SetSellErciQueRen")) table.Register("SetSellErciQueRen", LAG_DataPool_SetSellErciQueRen);
        if (IsMissing(table, "SetTeamExpMode")) table.Register("SetTeamExpMode", LAG_DataPool_SetTeamExpMode);
        if (IsMissing(table, "SetTrackFuncShow")) table.Register("SetTrackFuncShow", LAG_DataPool_SetTrackFuncShow);
        if (IsMissing(table, "SetXiuChangSelectRoomInd")) table.Register("SetXiuChangSelectRoomInd", LAG_DataPool_SetXiuChangSelectRoomInd);
        if (IsMissing(table, "Set_RMB_ChatAction")) table.Register("Set_RMB_ChatAction", LAG_DataPool_Set_RMB_ChatAction);
        if (IsMissing(table, "ShowChatHistory")) table.Register("ShowChatHistory", LAG_DataPool_ShowChatHistory);
        if (IsMissing(table, "ShowFriendIMChatHistory")) table.Register("ShowFriendIMChatHistory", LAG_DataPool_ShowFriendIMChatHistory);
        if (IsMissing(table, "ShowMiniWatch")) table.Register("ShowMiniWatch", LAG_DataPool_ShowMiniWatch);
        if (IsMissing(table, "ShowNormalWatch")) table.Register("ShowNormalWatch", LAG_DataPool_ShowNormalWatch);
        if (IsMissing(table, "SortPetTujianList")) table.Register("SortPetTujianList", LAG_DataPool_SortPetTujianList);
        if (IsMissing(table, "StorPetsOneType")) table.Register("StorPetsOneType", LAG_DataPool_StorPetsOneType);
        if (IsMissing(table, "TBSearch_Index_EQU")) table.Register("TBSearch_Index_EQU", LAG_DataPool_TBSearch_Index_EQU);
        if (IsMissing(table, "TeamMemIsSnowMan")) table.Register("TeamMemIsSnowMan", LAG_DataPool_TeamMemIsSnowMan);
        if (IsMissing(table, "ToggleTrustFriendWindow")) table.Register("ToggleTrustFriendWindow", LAG_DataPool_ToggleTrustFriendWindow);
        if (IsMissing(table, "UnInstall_RMB_ChatAction")) table.Register("UnInstall_RMB_ChatAction", LAG_DataPool_UnInstall_RMB_ChatAction);
        if (IsMissing(table, "UnInstall_RMB_ChatAction_BarItem")) table.Register("UnInstall_RMB_ChatAction_BarItem", LAG_DataPool_UnInstall_RMB_ChatAction_BarItem);
        if (IsMissing(table, "UpdateCampaignListByTrack")) table.Register("UpdateCampaignListByTrack", LAG_DataPool_UpdateCampaignListByTrack);
        if (IsMissing(table, "UpdateCampaignTrack")) table.Register("UpdateCampaignTrack", LAG_DataPool_UpdateCampaignTrack);
        if (IsMissing(table, "UpdateFriendInfo")) table.Register("UpdateFriendInfo", LAG_DataPool_UpdateFriendInfo);
        if (IsMissing(table, "UpdateFriendInfoByName")) table.Register("UpdateFriendInfoByName", LAG_DataPool_UpdateFriendInfoByName);
        if (IsMissing(table, "UpdateMissionTrack")) table.Register("UpdateMissionTrack", LAG_DataPool_UpdateMissionTrack);
        if (IsMissing(table, "UpdateQuestLogByTrack")) table.Register("UpdateQuestLogByTrack", LAG_DataPool_UpdateQuestLogByTrack);
        if (IsMissing(table, "UpdateTrackStateButton")) table.Register("UpdateTrackStateButton", LAG_DataPool_UpdateTrackStateButton);
        if (IsMissing(table, "ZhengYouOpenMail")) table.Register("ZhengYouOpenMail", LAG_DataPool_ZhengYouOpenMail);
        if (IsMissing(table, "getPetsOneTypeJiHuo_Num")) table.Register("getPetsOneTypeJiHuo_Num", LAG_DataPool_getPetsOneTypeJiHuo_Num);
        if (IsMissing(table, "getUINumbersFromIpRegion")) table.Register("getUINumbersFromIpRegion", LAG_DataPool_getUINumbersFromIpRegion);
        if (IsMissing(table, "lua_GetDoubleRankingListMyvalue")) table.Register("lua_GetDoubleRankingListMyvalue", LAG_DataPool_lua_GetDoubleRankingListMyvalue);
        if (IsMissing(table, "lua_GetExamRankingListInfo")) table.Register("lua_GetExamRankingListInfo", LAG_DataPool_lua_GetExamRankingListInfo);
        if (IsMissing(table, "lua_GetJSRankingListDataCount")) table.Register("lua_GetJSRankingListDataCount", LAG_DataPool_lua_GetJSRankingListDataCount);
        if (IsMissing(table, "lua_GetJSRankingListGetReward")) table.Register("lua_GetJSRankingListGetReward", LAG_DataPool_lua_GetJSRankingListGetReward);
        if (IsMissing(table, "lua_GetJSRankingListGetRewardEx")) table.Register("lua_GetJSRankingListGetRewardEx", LAG_DataPool_lua_GetJSRankingListGetRewardEx);
        if (IsMissing(table, "lua_GetJSRankingListInfo")) table.Register("lua_GetJSRankingListInfo", LAG_DataPool_lua_GetJSRankingListInfo);
        if (IsMissing(table, "lua_GetJSRankingListMemberInfo")) table.Register("lua_GetJSRankingListMemberInfo", LAG_DataPool_lua_GetJSRankingListMemberInfo);
        if (IsMissing(table, "lua_GetJSRankingListMyInfo")) table.Register("lua_GetJSRankingListMyInfo", LAG_DataPool_lua_GetJSRankingListMyInfo);
        if (IsMissing(table, "lua_GetJSRankingListParam")) table.Register("lua_GetJSRankingListParam", LAG_DataPool_lua_GetJSRankingListParam);
        if (IsMissing(table, "lua_GetJSRankingListRewardInfo")) table.Register("lua_GetJSRankingListRewardInfo", LAG_DataPool_lua_GetJSRankingListRewardInfo);
        if (IsMissing(table, "lua_GetMenPaiWarRankingListMyvalue")) table.Register("lua_GetMenPaiWarRankingListMyvalue", LAG_DataPool_lua_GetMenPaiWarRankingListMyvalue);
        if (IsMissing(table, "lua_GetNormalRankGetRankTime")) table.Register("lua_GetNormalRankGetRankTime", LAG_DataPool_lua_GetNormalRankGetRankTime);
        if (IsMissing(table, "lua_GetNormalRankListCount")) table.Register("lua_GetNormalRankListCount", LAG_DataPool_lua_GetNormalRankListCount);
        if (IsMissing(table, "lua_GetNormalRankListInfo")) table.Register("lua_GetNormalRankListInfo", LAG_DataPool_lua_GetNormalRankListInfo);
        if (IsMissing(table, "lua_GetNormalRankPlayerRewardInfo")) table.Register("lua_GetNormalRankPlayerRewardInfo", LAG_DataPool_lua_GetNormalRankPlayerRewardInfo);
        if (IsMissing(table, "lua_GetNormalRankingBaseRewardInfo")) table.Register("lua_GetNormalRankingBaseRewardInfo", LAG_DataPool_lua_GetNormalRankingBaseRewardInfo);
        if (IsMissing(table, "lua_GetNormalRankingMaxRankNum")) table.Register("lua_GetNormalRankingMaxRankNum", LAG_DataPool_lua_GetNormalRankingMaxRankNum);
        if (IsMissing(table, "lua_GetNormalRankingMaxRewardNum")) table.Register("lua_GetNormalRankingMaxRewardNum", LAG_DataPool_lua_GetNormalRankingMaxRewardNum);
        if (IsMissing(table, "lua_GetNormalRankingPlayerRankInfo")) table.Register("lua_GetNormalRankingPlayerRankInfo", LAG_DataPool_lua_GetNormalRankingPlayerRankInfo);
        if (IsMissing(table, "lua_GetNormalRankingRewardShowIndex")) table.Register("lua_GetNormalRankingRewardShowIndex", LAG_DataPool_lua_GetNormalRankingRewardShowIndex);
        if (IsMissing(table, "lua_GetNormalRankingRewardShowInfo")) table.Register("lua_GetNormalRankingRewardShowInfo", LAG_DataPool_lua_GetNormalRankingRewardShowInfo);
        if (IsMissing(table, "lua_GetNormalRankingStopTime")) table.Register("lua_GetNormalRankingStopTime", LAG_DataPool_lua_GetNormalRankingStopTime);
        if (IsMissing(table, "lua_GetRankServerType")) table.Register("lua_GetRankServerType", LAG_DataPool_lua_GetRankServerType);
        if (IsMissing(table, "lua_GetShaxingRankingListInfo")) table.Register("lua_GetShaxingRankingListInfo", LAG_DataPool_lua_GetShaxingRankingListInfo);
        if (IsMissing(table, "lua_IsNormalRankGetBoutsTime")) table.Register("lua_IsNormalRankGetBoutsTime", LAG_DataPool_lua_IsNormalRankGetBoutsTime);
        if (IsMissing(table, "lua_IsNormalRankingClientShow")) table.Register("lua_IsNormalRankingClientShow", LAG_DataPool_lua_IsNormalRankingClientShow);
        if (IsMissing(table, "lua_OpenLevelRankInfo")) table.Register("lua_OpenLevelRankInfo", LAG_DataPool_lua_OpenLevelRankInfo);
        if (IsMissing(table, "lua_UpdateNormalRankInfo")) table.Register("lua_UpdateNormalRankInfo", LAG_DataPool_lua_UpdateNormalRankInfo);
        if (IsMissing(table, "storPetsOneTypeJiHuo")) table.Register("storPetsOneTypeJiHuo", LAG_DataPool_storPetsOneTypeJiHuo);
    }
}
