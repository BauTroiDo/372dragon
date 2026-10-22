




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_ZBS_AskTeamListInfo(LuaPlus::LuaState* state) { return Stub(state, "ZBS", "AskTeamListInfo", ""); }

        int LAG_ZBS_CancelGMWatch(LuaPlus::LuaState* state) { return Stub(state, "ZBS", "CancelGMWatch", "n"); }


        int LAG_ZBS_CreateTeam(LuaPlus::LuaState* state) { return Stub(state, "ZBS", "CreateTeam", ""); }


        int LAG_ZBS_DeleteMember(LuaPlus::LuaState* state) { return Stub(state, "ZBS", "DeleteMember", ""); }


        int LAG_ZBS_GetBattleMemberInfo(LuaPlus::LuaState* state) { return Stub(state, "ZBS", "GetBattleMemberInfo", "nnnnnsn"); }


        int LAG_ZBS_GetBattleMemberZoneID(LuaPlus::LuaState* state) { return Stub(state, "ZBS", "GetBattleMemberZoneID", "n"); }

        int LAG_ZBS_GetBattleTeamInfo(LuaPlus::LuaState* state) { return Stub(state, "ZBS", "GetBattleTeamInfo", "nnnss"); }

        int LAG_ZBS_GetBattleType(LuaPlus::LuaState* state) { return Stub(state, "ZBS", "GetBattleType", "n"); }

        int LAG_ZBS_GetMyTeamInfo(LuaPlus::LuaState* state) { return Stub(state, "ZBS", "GetMyTeamInfo", "nnnnns"); }


        int LAG_ZBS_GetRestBattleInfo(LuaPlus::LuaState* state) { return Stub(state, "ZBS", "GetRestBattleInfo", "nnnsn"); }


        int LAG_ZBS_GetRestTeamInfo(LuaPlus::LuaState* state) { return Stub(state, "ZBS", "GetRestTeamInfo", "nnssn"); }


        int LAG_ZBS_GetTeamListInfo(LuaPlus::LuaState* state) { return Stub(state, "ZBS", "GetTeamListInfo", "nssnn"); }

        int LAG_ZBS_GetTeamMemberCountMax(LuaPlus::LuaState* state) { return Stub(state, "ZBS", "GetTeamMemberCountMax", "n"); }


        int LAG_ZBS_GetTeamMemberInfo(LuaPlus::LuaState* state) { return Stub(state, "ZBS", "GetTeamMemberInfo", "nnnnns"); }


        int LAG_ZBS_GetTeamMemberInfoByName(LuaPlus::LuaState* state) { return Stub(state, "ZBS", "GetTeamMemberInfoByName", "nnnnns"); }

        int LAG_ZBS_GetTeamName(LuaPlus::LuaState* state) { return Stub(state, "ZBS", "GetTeamName", "s"); }


        int LAG_ZBS_GetTeamProtomeInfo(LuaPlus::LuaState* state) { return Stub(state, "ZBS", "GetTeamProtomeInfo", "nssn"); }

        int LAG_ZBS_GetTeamScore(LuaPlus::LuaState* state) { return Stub(state, "ZBS", "GetTeamScore", "t"); }


        int LAG_ZBS_GetViewTeamInfo(LuaPlus::LuaState* state) { return Stub(state, "ZBS", "GetViewTeamInfo", "nnnn"); }

        int LAG_ZBS_IsCanGetTargetEquip(LuaPlus::LuaState* state) { return Stub(state, "ZBS", "IsCanGetTargetEquip", "b"); }

        int LAG_ZBS_IsDeputy(LuaPlus::LuaState* state) { return Stub(state, "ZBS", "IsDeputy", "n"); }

        int LAG_ZBS_IsHasDeputy(LuaPlus::LuaState* state) { return Stub(state, "ZBS", "IsHasDeputy", "n"); }

        int LAG_ZBS_IsLeader(LuaPlus::LuaState* state) { return Stub(state, "ZBS", "IsLeader", "n"); }

        int LAG_ZBS_IsViewerWatching(LuaPlus::LuaState* state) { return Stub(state, "ZBS", "IsViewerWatching", "n"); }


        int LAG_ZBS_SetBattleMainTargetByIdx(LuaPlus::LuaState* state) { return Stub(state, "ZBS", "SetBattleMainTargetByIdx", ""); }


        int LAG_ZBS_SetPlayerWatchPosDirection(LuaPlus::LuaState* state) { return Stub(state, "ZBS", "SetPlayerWatchPosDirection", "n"); }
    }

    void Register_ZBS(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "AskTeamListInfo")) table.Register("AskTeamListInfo", LAG_ZBS_AskTeamListInfo);
        if (IsMissing(table, "CancelGMWatch")) table.Register("CancelGMWatch", LAG_ZBS_CancelGMWatch);
        if (IsMissing(table, "CreateTeam")) table.Register("CreateTeam", LAG_ZBS_CreateTeam);
        if (IsMissing(table, "DeleteMember")) table.Register("DeleteMember", LAG_ZBS_DeleteMember);
        if (IsMissing(table, "GetBattleMemberInfo")) table.Register("GetBattleMemberInfo", LAG_ZBS_GetBattleMemberInfo);
        if (IsMissing(table, "GetBattleMemberZoneID")) table.Register("GetBattleMemberZoneID", LAG_ZBS_GetBattleMemberZoneID);
        if (IsMissing(table, "GetBattleTeamInfo")) table.Register("GetBattleTeamInfo", LAG_ZBS_GetBattleTeamInfo);
        if (IsMissing(table, "GetBattleType")) table.Register("GetBattleType", LAG_ZBS_GetBattleType);
        if (IsMissing(table, "GetMyTeamInfo")) table.Register("GetMyTeamInfo", LAG_ZBS_GetMyTeamInfo);
        if (IsMissing(table, "GetRestBattleInfo")) table.Register("GetRestBattleInfo", LAG_ZBS_GetRestBattleInfo);
        if (IsMissing(table, "GetRestTeamInfo")) table.Register("GetRestTeamInfo", LAG_ZBS_GetRestTeamInfo);
        if (IsMissing(table, "GetTeamListInfo")) table.Register("GetTeamListInfo", LAG_ZBS_GetTeamListInfo);
        if (IsMissing(table, "GetTeamMemberCountMax")) table.Register("GetTeamMemberCountMax", LAG_ZBS_GetTeamMemberCountMax);
        if (IsMissing(table, "GetTeamMemberInfo")) table.Register("GetTeamMemberInfo", LAG_ZBS_GetTeamMemberInfo);
        if (IsMissing(table, "GetTeamMemberInfoByName")) table.Register("GetTeamMemberInfoByName", LAG_ZBS_GetTeamMemberInfoByName);
        if (IsMissing(table, "GetTeamName")) table.Register("GetTeamName", LAG_ZBS_GetTeamName);
        if (IsMissing(table, "GetTeamProtomeInfo")) table.Register("GetTeamProtomeInfo", LAG_ZBS_GetTeamProtomeInfo);
        if (IsMissing(table, "GetTeamScore")) table.Register("GetTeamScore", LAG_ZBS_GetTeamScore);
        if (IsMissing(table, "GetViewTeamInfo")) table.Register("GetViewTeamInfo", LAG_ZBS_GetViewTeamInfo);
        if (IsMissing(table, "IsCanGetTargetEquip")) table.Register("IsCanGetTargetEquip", LAG_ZBS_IsCanGetTargetEquip);
        if (IsMissing(table, "IsDeputy")) table.Register("IsDeputy", LAG_ZBS_IsDeputy);
        if (IsMissing(table, "IsHasDeputy")) table.Register("IsHasDeputy", LAG_ZBS_IsHasDeputy);
        if (IsMissing(table, "IsLeader")) table.Register("IsLeader", LAG_ZBS_IsLeader);
        if (IsMissing(table, "IsViewerWatching")) table.Register("IsViewerWatching", LAG_ZBS_IsViewerWatching);
        if (IsMissing(table, "SetBattleMainTargetByIdx")) table.Register("SetBattleMainTargetByIdx", LAG_ZBS_SetBattleMainTargetByIdx);
        if (IsMissing(table, "SetPlayerWatchPosDirection")) table.Register("SetPlayerWatchPosDirection", LAG_ZBS_SetPlayerWatchPosDirection);
    }
}
