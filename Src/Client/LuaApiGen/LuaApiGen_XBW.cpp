




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_XBW_CanQueryRankingAgain(LuaPlus::LuaState* state) { return Stub(state, "XBW", "CanQueryRankingAgain", "n"); }

        int LAG_XBW_GetBWTroopsPK_LeftTimes(LuaPlus::LuaState* state) { return Stub(state, "XBW", "GetBWTroopsPK_LeftTimes", "n"); }

        int LAG_XBW_GetBWTroopsPK_Result_Info(LuaPlus::LuaState* state) { return Stub(state, "XBW", "GetBWTroopsPK_Result_Info", "n"); }

        int LAG_XBW_GetCalcBattleScoreAndDuanweiInfoByIdx(LuaPlus::LuaState* state) { return Stub(state, "XBW", "GetCalcBattleScoreAndDuanweiInfoByIdx", "nn"); }

        int LAG_XBW_GetCopySceneBWFirstKillerType(LuaPlus::LuaState* state) { return Stub(state, "XBW", "GetCopySceneBWFirstKillerType", "n"); }

        int LAG_XBW_GetCopySceneBWPlayerInfoByIdx(LuaPlus::LuaState* state) { return Stub(state, "XBW", "GetCopySceneBWPlayerInfoByIdx", "t"); }

        int LAG_XBW_GetLobbyInfo(LuaPlus::LuaState* state) { return Stub(state, "XBW", "GetLobbyInfo", "n"); }

        int LAG_XBW_GetMatchId(LuaPlus::LuaState* state) { return Stub(state, "XBW", "GetMatchId", "n"); }


        int LAG_XBW_GetMembersInfo(LuaPlus::LuaState* state) { return Stub(state, "XBW", "GetMembersInfo", "s"); }

        int LAG_XBW_GetMyUIDirInfo(LuaPlus::LuaState* state) { return Stub(state, "XBW", "GetMyUIDirInfo", "n"); }

        int LAG_XBW_GetRankListInfoByIndex(LuaPlus::LuaState* state) { return Stub(state, "XBW", "GetRankListInfoByIndex", "snnnnnnnn"); }

        int LAG_XBW_GetRankListNum(LuaPlus::LuaState* state) { return Stub(state, "XBW", "GetRankListNum", "n"); }

        int LAG_XBW_GetRankMatchID(LuaPlus::LuaState* state) { return Stub(state, "XBW", "GetRankMatchID", "n"); }

        int LAG_XBW_GetResultData(LuaPlus::LuaState* state) { return Stub(state, "XBW", "GetResultData", "nnnnnnnnnn"); }

        int LAG_XBW_GetSelfInfo(LuaPlus::LuaState* state) { return Stub(state, "XBW", "GetSelfInfo", "nsnn"); }

        int LAG_XBW_GetTeamBattleInfo(LuaPlus::LuaState* state) { return Stub(state, "XBW", "GetTeamBattleInfo", "nnn"); }

        int LAG_XBW_GetXbwDayAward(LuaPlus::LuaState* state) { return Stub(state, "XBW", "GetXbwDayAward", ""); }


        int LAG_XBW_GetXbwDayAward_New(LuaPlus::LuaState* state) { return Stub(state, "XBW", "GetXbwDayAward_New", ""); }

        int LAG_XBW_GetXbwDuanweinfo(LuaPlus::LuaState* state) { return Stub(state, "XBW", "GetXbwDuanweinfo", "n"); }

        int LAG_XBW_GetXbwGetCurSeasonLockInfo(LuaPlus::LuaState* state) { return Stub(state, "XBW", "GetXbwGetCurSeasonLockInfo", "nnn"); }

        int LAG_XBW_GetXbwGetRecentSeasonInfo(LuaPlus::LuaState* state) { return Stub(state, "XBW", "GetXbwGetRecentSeasonInfo", "nnn"); }

        int LAG_XBW_GetXbwMaxDuanWei2(LuaPlus::LuaState* state) { return Stub(state, "XBW", "GetXbwMaxDuanWei2", "n"); }

        int LAG_XBW_GetXbwSeasonAward(LuaPlus::LuaState* state) { return Stub(state, "XBW", "GetXbwSeasonAward", ""); }

        int LAG_XBW_LuaGetPortraitInfo(LuaPlus::LuaState* state) { return Stub(state, "XBW", "LuaGetPortraitInfo", "s"); }

        int LAG_XBW_SetBMMainTargetByUIIdx(LuaPlus::LuaState* state) { return Stub(state, "XBW", "SetBMMainTargetByUIIdx", ""); }

        int LAG_XBW_Show_PopMemu(LuaPlus::LuaState* state) { return Stub(state, "XBW", "Show_PopMemu", ""); }
    }

    void Register_XBW(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "CanQueryRankingAgain")) table.Register("CanQueryRankingAgain", LAG_XBW_CanQueryRankingAgain);
        if (IsMissing(table, "GetBWTroopsPK_LeftTimes")) table.Register("GetBWTroopsPK_LeftTimes", LAG_XBW_GetBWTroopsPK_LeftTimes);
        if (IsMissing(table, "GetBWTroopsPK_Result_Info")) table.Register("GetBWTroopsPK_Result_Info", LAG_XBW_GetBWTroopsPK_Result_Info);
        if (IsMissing(table, "GetCalcBattleScoreAndDuanweiInfoByIdx")) table.Register("GetCalcBattleScoreAndDuanweiInfoByIdx", LAG_XBW_GetCalcBattleScoreAndDuanweiInfoByIdx);
        if (IsMissing(table, "GetCopySceneBWFirstKillerType")) table.Register("GetCopySceneBWFirstKillerType", LAG_XBW_GetCopySceneBWFirstKillerType);
        if (IsMissing(table, "GetCopySceneBWPlayerInfoByIdx")) table.Register("GetCopySceneBWPlayerInfoByIdx", LAG_XBW_GetCopySceneBWPlayerInfoByIdx);
        if (IsMissing(table, "GetLobbyInfo")) table.Register("GetLobbyInfo", LAG_XBW_GetLobbyInfo);
        if (IsMissing(table, "GetMatchId")) table.Register("GetMatchId", LAG_XBW_GetMatchId);
        if (IsMissing(table, "GetMembersInfo")) table.Register("GetMembersInfo", LAG_XBW_GetMembersInfo);
        if (IsMissing(table, "GetMyUIDirInfo")) table.Register("GetMyUIDirInfo", LAG_XBW_GetMyUIDirInfo);
        if (IsMissing(table, "GetRankListInfoByIndex")) table.Register("GetRankListInfoByIndex", LAG_XBW_GetRankListInfoByIndex);
        if (IsMissing(table, "GetRankListNum")) table.Register("GetRankListNum", LAG_XBW_GetRankListNum);
        if (IsMissing(table, "GetRankMatchID")) table.Register("GetRankMatchID", LAG_XBW_GetRankMatchID);
        if (IsMissing(table, "GetResultData")) table.Register("GetResultData", LAG_XBW_GetResultData);
        if (IsMissing(table, "GetSelfInfo")) table.Register("GetSelfInfo", LAG_XBW_GetSelfInfo);
        if (IsMissing(table, "GetTeamBattleInfo")) table.Register("GetTeamBattleInfo", LAG_XBW_GetTeamBattleInfo);
        if (IsMissing(table, "GetXbwDayAward")) table.Register("GetXbwDayAward", LAG_XBW_GetXbwDayAward);
        if (IsMissing(table, "GetXbwDayAward_New")) table.Register("GetXbwDayAward_New", LAG_XBW_GetXbwDayAward_New);
        if (IsMissing(table, "GetXbwDuanweinfo")) table.Register("GetXbwDuanweinfo", LAG_XBW_GetXbwDuanweinfo);
        if (IsMissing(table, "GetXbwGetCurSeasonLockInfo")) table.Register("GetXbwGetCurSeasonLockInfo", LAG_XBW_GetXbwGetCurSeasonLockInfo);
        if (IsMissing(table, "GetXbwGetRecentSeasonInfo")) table.Register("GetXbwGetRecentSeasonInfo", LAG_XBW_GetXbwGetRecentSeasonInfo);
        if (IsMissing(table, "GetXbwMaxDuanWei2")) table.Register("GetXbwMaxDuanWei2", LAG_XBW_GetXbwMaxDuanWei2);
        if (IsMissing(table, "GetXbwSeasonAward")) table.Register("GetXbwSeasonAward", LAG_XBW_GetXbwSeasonAward);
        if (IsMissing(table, "LuaGetPortraitInfo")) table.Register("LuaGetPortraitInfo", LAG_XBW_LuaGetPortraitInfo);
        if (IsMissing(table, "SetBMMainTargetByUIIdx")) table.Register("SetBMMainTargetByUIIdx", LAG_XBW_SetBMMainTargetByUIIdx);
        if (IsMissing(table, "Show_PopMemu")) table.Register("Show_PopMemu", LAG_XBW_Show_PopMemu);
    }
}
