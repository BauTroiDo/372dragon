




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_XBHZT_GetBattleCampData(LuaPlus::LuaState* state) { return Stub(state, "XBHZT", "GetBattleCampData", "t"); }

        int LAG_XBHZT_GetBattleData(LuaPlus::LuaState* state) { return Stub(state, "XBHZT", "GetBattleData", "t"); }

        int LAG_XBHZT_GetBattleRankData(LuaPlus::LuaState* state) { return Stub(state, "XBHZT", "GetBattleRankData", "t"); }

        int LAG_XBHZT_GetGroupOperateForbidInfo(LuaPlus::LuaState* state) { return Stub(state, "XBHZT", "GetGroupOperateForbidInfo", "nnn"); }

        int LAG_XBHZT_GetGroupPlayerMaxNum(LuaPlus::LuaState* state) { return Stub(state, "XBHZT", "GetGroupPlayerMaxNum", "nn"); }

        int LAG_XBHZT_GetGuildBattleCount(LuaPlus::LuaState* state) { return Stub(state, "XBHZT", "GetGuildBattleCount", "n"); }

        int LAG_XBHZT_GetGuildBattleInfo(LuaPlus::LuaState* state) { return Stub(state, "XBHZT", "GetGuildBattleInfo", "nn"); }

        int LAG_XBHZT_GetGuildGroupFlag(LuaPlus::LuaState* state) { return Stub(state, "XBHZT", "GetGuildGroupFlag", "n"); }

        int LAG_XBHZT_GetGuildLevelStage(LuaPlus::LuaState* state) { return Stub(state, "XBHZT", "GetGuildLevelStage", "n"); }

        int LAG_XBHZT_GetGuildLevelStageInfo(LuaPlus::LuaState* state) { return Stub(state, "XBHZT", "GetGuildLevelStageInfo", "nnn"); }

        int LAG_XBHZT_GetGuildLevelStageStar(LuaPlus::LuaState* state) { return Stub(state, "XBHZT", "GetGuildLevelStageStar", "n"); }

        int LAG_XBHZT_GetGuildRank(LuaPlus::LuaState* state) { return Stub(state, "XBHZT", "GetGuildRank", "n"); }

        int LAG_XBHZT_GetGuildSubLevelStage(LuaPlus::LuaState* state) { return Stub(state, "XBHZT", "GetGuildSubLevelStage", "n"); }

        int LAG_XBHZT_GetGuildWinCount(LuaPlus::LuaState* state) { return Stub(state, "XBHZT", "GetGuildWinCount", "n"); }

        int LAG_XBHZT_GetMyGroupData(LuaPlus::LuaState* state) { return Stub(state, "XBHZT", "GetMyGroupData", "nnnn"); }

        int LAG_XBHZT_GetRankBaseInfo(LuaPlus::LuaState* state) { return Stub(state, "XBHZT", "GetRankBaseInfo", "n"); }

        int LAG_XBHZT_GetRankGuildInfo(LuaPlus::LuaState* state) { return Stub(state, "XBHZT", "GetRankGuildInfo", "t"); }

        int LAG_XBHZT_GetSeasonInfo(LuaPlus::LuaState* state) { return Stub(state, "XBHZT", "GetSeasonInfo", "nnn"); }

        int LAG_XBHZT_IsInBattleScene(LuaPlus::LuaState* state) { return Stub(state, "XBHZT", "IsInBattleScene", "n"); }
    }

    void Register_XBHZT(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "GetBattleCampData")) table.Register("GetBattleCampData", LAG_XBHZT_GetBattleCampData);
        if (IsMissing(table, "GetBattleData")) table.Register("GetBattleData", LAG_XBHZT_GetBattleData);
        if (IsMissing(table, "GetBattleRankData")) table.Register("GetBattleRankData", LAG_XBHZT_GetBattleRankData);
        if (IsMissing(table, "GetGroupOperateForbidInfo")) table.Register("GetGroupOperateForbidInfo", LAG_XBHZT_GetGroupOperateForbidInfo);
        if (IsMissing(table, "GetGroupPlayerMaxNum")) table.Register("GetGroupPlayerMaxNum", LAG_XBHZT_GetGroupPlayerMaxNum);
        if (IsMissing(table, "GetGuildBattleCount")) table.Register("GetGuildBattleCount", LAG_XBHZT_GetGuildBattleCount);
        if (IsMissing(table, "GetGuildBattleInfo")) table.Register("GetGuildBattleInfo", LAG_XBHZT_GetGuildBattleInfo);
        if (IsMissing(table, "GetGuildGroupFlag")) table.Register("GetGuildGroupFlag", LAG_XBHZT_GetGuildGroupFlag);
        if (IsMissing(table, "GetGuildLevelStage")) table.Register("GetGuildLevelStage", LAG_XBHZT_GetGuildLevelStage);
        if (IsMissing(table, "GetGuildLevelStageInfo")) table.Register("GetGuildLevelStageInfo", LAG_XBHZT_GetGuildLevelStageInfo);
        if (IsMissing(table, "GetGuildLevelStageStar")) table.Register("GetGuildLevelStageStar", LAG_XBHZT_GetGuildLevelStageStar);
        if (IsMissing(table, "GetGuildRank")) table.Register("GetGuildRank", LAG_XBHZT_GetGuildRank);
        if (IsMissing(table, "GetGuildSubLevelStage")) table.Register("GetGuildSubLevelStage", LAG_XBHZT_GetGuildSubLevelStage);
        if (IsMissing(table, "GetGuildWinCount")) table.Register("GetGuildWinCount", LAG_XBHZT_GetGuildWinCount);
        if (IsMissing(table, "GetMyGroupData")) table.Register("GetMyGroupData", LAG_XBHZT_GetMyGroupData);
        if (IsMissing(table, "GetRankBaseInfo")) table.Register("GetRankBaseInfo", LAG_XBHZT_GetRankBaseInfo);
        if (IsMissing(table, "GetRankGuildInfo")) table.Register("GetRankGuildInfo", LAG_XBHZT_GetRankGuildInfo);
        if (IsMissing(table, "GetSeasonInfo")) table.Register("GetSeasonInfo", LAG_XBHZT_GetSeasonInfo);
        if (IsMissing(table, "IsInBattleScene")) table.Register("IsInBattleScene", LAG_XBHZT_IsInBattleScene);
    }
}
