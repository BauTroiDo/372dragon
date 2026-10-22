




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_Raid_ClearApplicant(LuaPlus::LuaState* state) { return Stub(state, "Raid", "ClearApplicant", ""); }

        int LAG_Raid_CloseRaidSquadWindowByIdx(LuaPlus::LuaState* state) { return Stub(state, "Raid", "CloseRaidSquadWindowByIdx", "n"); }

        int LAG_Raid_CloseSquadMemWindowByGUID(LuaPlus::LuaState* state) { return Stub(state, "Raid", "CloseSquadMemWindowByGUID", ""); }

        int LAG_Raid_ConfirmShowAllSquad(LuaPlus::LuaState* state) { return Stub(state, "Raid", "ConfirmShowAllSquad", ""); }


        int LAG_Raid_EraseApplicantByIdx(LuaPlus::LuaState* state) { return Stub(state, "Raid", "EraseApplicantByIdx", ""); }


        int LAG_Raid_ExchangeMemberPosition(LuaPlus::LuaState* state) { return Stub(state, "Raid", "ExchangeMemberPosition", ""); }

        int LAG_Raid_GetApplicantCount(LuaPlus::LuaState* state) { return Stub(state, "Raid", "GetApplicantCount", "n"); }

        int LAG_Raid_GetApplicantUIModelNameByIdx(LuaPlus::LuaState* state) { return Stub(state, "Raid", "GetApplicantUIModelNameByIdx", "s"); }

        int LAG_Raid_GetApplyMemberInfoByIdx(LuaPlus::LuaState* state) { return Stub(state, "Raid", "GetApplyMemberInfoByIdx", "snnnnnnnnnnns"); }

        int LAG_Raid_GetInvitationByIdx(LuaPlus::LuaState* state) { return Stub(state, "Raid", "GetInvitationByIdx", "ss"); }

        int LAG_Raid_GetInvitationCount(LuaPlus::LuaState* state) { return Stub(state, "Raid", "GetInvitationCount", "n"); }

        int LAG_Raid_GetMemCount(LuaPlus::LuaState* state) { return Stub(state, "Raid", "GetMemCount", "n"); }

        int LAG_Raid_GetMemberBufInfoByIdx(LuaPlus::LuaState* state) { return Stub(state, "Raid", "GetMemberBufInfoByIdx", ""); }

        int LAG_Raid_GetMemberBufNumByIdx(LuaPlus::LuaState* state) { return Stub(state, "Raid", "GetMemberBufNumByIdx", "n"); }

        int LAG_Raid_GetMemberBufPriorityByIdx(LuaPlus::LuaState* state) { return Stub(state, "Raid", "GetMemberBufPriorityByIdx", "n"); }

        int LAG_Raid_GetMemberBuffIsShowIcon(LuaPlus::LuaState* state) { return Stub(state, "Raid", "GetMemberBuffIsShowIcon", "n"); }

        int LAG_Raid_GetMemberDetailByIdx(LuaPlus::LuaState* state) { return Stub(state, "Raid", "GetMemberDetailByIdx", "ssnnnnnnnnnnssn"); }

        int LAG_Raid_GetMemberGUIDByIdx(LuaPlus::LuaState* state) { return Stub(state, "Raid", "GetMemberGUIDByIdx", "n"); }

        int LAG_Raid_GetMemberIndexByGUID(LuaPlus::LuaState* state) { return Stub(state, "Raid", "GetMemberIndexByGUID", "nn"); }

        int LAG_Raid_GetMemberInfoByIdx(LuaPlus::LuaState* state) { return Stub(state, "Raid", "GetMemberInfoByIdx", "snnnnsnsnns"); }

        int LAG_Raid_GetMemberNameByGUID(LuaPlus::LuaState* state) { return Stub(state, "Raid", "GetMemberNameByGUID", "ss"); }

        int LAG_Raid_GetMySquadMemCount(LuaPlus::LuaState* state) { return Stub(state, "Raid", "GetMySquadMemCount", "n"); }

        int LAG_Raid_GetMySquadMemIdxByUIIdx(LuaPlus::LuaState* state) { return Stub(state, "Raid", "GetMySquadMemIdxByUIIdx", "nn"); }

        int LAG_Raid_IsLeaderByIdx(LuaPlus::LuaState* state) { return Stub(state, "Raid", "IsLeaderByIdx", "n"); }

        int LAG_Raid_IsMemberInSceneByIdx(LuaPlus::LuaState* state) { return Stub(state, "Raid", "IsMemberInSceneByIdx", "n"); }

        int LAG_Raid_IsRaidSquadWindowShow(LuaPlus::LuaState* state) { return Stub(state, "Raid", "IsRaidSquadWindowShow", "n"); }

        int LAG_Raid_LuaFnIsDiffSceneRaid(LuaPlus::LuaState* state) { return Stub(state, "Raid", "LuaFnIsDiffSceneRaid", "n"); }

        int LAG_Raid_LuaFnIsDiffSceneTeam(LuaPlus::LuaState* state) { return Stub(state, "Raid", "LuaFnIsDiffSceneTeam", "n"); }

        int LAG_Raid_OpenRaidSquadWindowByIdx(LuaPlus::LuaState* state) { return Stub(state, "Raid", "OpenRaidSquadWindowByIdx", "n"); }

        int LAG_Raid_OpenSquadMemWindowByIdx(LuaPlus::LuaState* state) { return Stub(state, "Raid", "OpenSquadMemWindowByIdx", ""); }

        int LAG_Raid_SelectAsTargetByIdx(LuaPlus::LuaState* state) { return Stub(state, "Raid", "SelectAsTargetByIdx", ""); }

        int LAG_Raid_SetModelHeadLookByIdx(LuaPlus::LuaState* state) { return Stub(state, "Raid", "SetModelHeadLookByIdx", "s"); }

        int LAG_Raid_SetModelLookByIdx(LuaPlus::LuaState* state) { return Stub(state, "Raid", "SetModelLookByIdx", "s"); }

        int LAG_Raid_ShowMemberContMenu(LuaPlus::LuaState* state) { return Stub(state, "Raid", "ShowMemberContMenu", ""); }
    }

    void Register_Raid(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "ClearApplicant")) table.Register("ClearApplicant", LAG_Raid_ClearApplicant);
        if (IsMissing(table, "CloseRaidSquadWindowByIdx")) table.Register("CloseRaidSquadWindowByIdx", LAG_Raid_CloseRaidSquadWindowByIdx);
        if (IsMissing(table, "CloseSquadMemWindowByGUID")) table.Register("CloseSquadMemWindowByGUID", LAG_Raid_CloseSquadMemWindowByGUID);
        if (IsMissing(table, "ConfirmShowAllSquad")) table.Register("ConfirmShowAllSquad", LAG_Raid_ConfirmShowAllSquad);
        if (IsMissing(table, "EraseApplicantByIdx")) table.Register("EraseApplicantByIdx", LAG_Raid_EraseApplicantByIdx);
        if (IsMissing(table, "ExchangeMemberPosition")) table.Register("ExchangeMemberPosition", LAG_Raid_ExchangeMemberPosition);
        if (IsMissing(table, "GetApplicantCount")) table.Register("GetApplicantCount", LAG_Raid_GetApplicantCount);
        if (IsMissing(table, "GetApplicantUIModelNameByIdx")) table.Register("GetApplicantUIModelNameByIdx", LAG_Raid_GetApplicantUIModelNameByIdx);
        if (IsMissing(table, "GetApplyMemberInfoByIdx")) table.Register("GetApplyMemberInfoByIdx", LAG_Raid_GetApplyMemberInfoByIdx);
        if (IsMissing(table, "GetInvitationByIdx")) table.Register("GetInvitationByIdx", LAG_Raid_GetInvitationByIdx);
        if (IsMissing(table, "GetInvitationCount")) table.Register("GetInvitationCount", LAG_Raid_GetInvitationCount);
        if (IsMissing(table, "GetMemCount")) table.Register("GetMemCount", LAG_Raid_GetMemCount);
        if (IsMissing(table, "GetMemberBufInfoByIdx")) table.Register("GetMemberBufInfoByIdx", LAG_Raid_GetMemberBufInfoByIdx);
        if (IsMissing(table, "GetMemberBufNumByIdx")) table.Register("GetMemberBufNumByIdx", LAG_Raid_GetMemberBufNumByIdx);
        if (IsMissing(table, "GetMemberBufPriorityByIdx")) table.Register("GetMemberBufPriorityByIdx", LAG_Raid_GetMemberBufPriorityByIdx);
        if (IsMissing(table, "GetMemberBuffIsShowIcon")) table.Register("GetMemberBuffIsShowIcon", LAG_Raid_GetMemberBuffIsShowIcon);
        if (IsMissing(table, "GetMemberDetailByIdx")) table.Register("GetMemberDetailByIdx", LAG_Raid_GetMemberDetailByIdx);
        if (IsMissing(table, "GetMemberGUIDByIdx")) table.Register("GetMemberGUIDByIdx", LAG_Raid_GetMemberGUIDByIdx);
        if (IsMissing(table, "GetMemberIndexByGUID")) table.Register("GetMemberIndexByGUID", LAG_Raid_GetMemberIndexByGUID);
        if (IsMissing(table, "GetMemberInfoByIdx")) table.Register("GetMemberInfoByIdx", LAG_Raid_GetMemberInfoByIdx);
        if (IsMissing(table, "GetMemberNameByGUID")) table.Register("GetMemberNameByGUID", LAG_Raid_GetMemberNameByGUID);
        if (IsMissing(table, "GetMySquadMemCount")) table.Register("GetMySquadMemCount", LAG_Raid_GetMySquadMemCount);
        if (IsMissing(table, "GetMySquadMemIdxByUIIdx")) table.Register("GetMySquadMemIdxByUIIdx", LAG_Raid_GetMySquadMemIdxByUIIdx);
        if (IsMissing(table, "IsLeaderByIdx")) table.Register("IsLeaderByIdx", LAG_Raid_IsLeaderByIdx);
        if (IsMissing(table, "IsMemberInSceneByIdx")) table.Register("IsMemberInSceneByIdx", LAG_Raid_IsMemberInSceneByIdx);
        if (IsMissing(table, "IsRaidSquadWindowShow")) table.Register("IsRaidSquadWindowShow", LAG_Raid_IsRaidSquadWindowShow);
        if (IsMissing(table, "LuaFnIsDiffSceneRaid")) table.Register("LuaFnIsDiffSceneRaid", LAG_Raid_LuaFnIsDiffSceneRaid);
        if (IsMissing(table, "LuaFnIsDiffSceneTeam")) table.Register("LuaFnIsDiffSceneTeam", LAG_Raid_LuaFnIsDiffSceneTeam);
        if (IsMissing(table, "OpenRaidSquadWindowByIdx")) table.Register("OpenRaidSquadWindowByIdx", LAG_Raid_OpenRaidSquadWindowByIdx);
        if (IsMissing(table, "OpenSquadMemWindowByIdx")) table.Register("OpenSquadMemWindowByIdx", LAG_Raid_OpenSquadMemWindowByIdx);
        if (IsMissing(table, "SelectAsTargetByIdx")) table.Register("SelectAsTargetByIdx", LAG_Raid_SelectAsTargetByIdx);
        if (IsMissing(table, "SetModelHeadLookByIdx")) table.Register("SetModelHeadLookByIdx", LAG_Raid_SetModelHeadLookByIdx);
        if (IsMissing(table, "SetModelLookByIdx")) table.Register("SetModelLookByIdx", LAG_Raid_SetModelLookByIdx);
        if (IsMissing(table, "ShowMemberContMenu")) table.Register("ShowMemberContMenu", LAG_Raid_ShowMemberContMenu);
    }
}
