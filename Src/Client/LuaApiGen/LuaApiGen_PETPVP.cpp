




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_PETPVP_GetBattleData(LuaPlus::LuaState* state) { return Stub(state, "PETPVP", "GetBattleData", "n"); }

        int LAG_PETPVP_GetBattlePlayerRankInfo(LuaPlus::LuaState* state) { return Stub(state, "PETPVP", "GetBattlePlayerRankInfo", "n"); }

        int LAG_PETPVP_GetBattleTeamInfo(LuaPlus::LuaState* state) { return Stub(state, "PETPVP", "GetBattleTeamInfo", "t"); }

        int LAG_PETPVP_IsInBattleScene(LuaPlus::LuaState* state) { return Stub(state, "PETPVP", "IsInBattleScene", "n"); }

        int LAG_PETPVP_IsInBattleSceneAndTransfer(LuaPlus::LuaState* state) { return Stub(state, "PETPVP", "IsInBattleSceneAndTransfer", "n"); }
    }

    void Register_PETPVP(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "GetBattleData")) table.Register("GetBattleData", LAG_PETPVP_GetBattleData);
        if (IsMissing(table, "GetBattlePlayerRankInfo")) table.Register("GetBattlePlayerRankInfo", LAG_PETPVP_GetBattlePlayerRankInfo);
        if (IsMissing(table, "GetBattleTeamInfo")) table.Register("GetBattleTeamInfo", LAG_PETPVP_GetBattleTeamInfo);
        if (IsMissing(table, "IsInBattleScene")) table.Register("IsInBattleScene", LAG_PETPVP_IsInBattleScene);
        if (IsMissing(table, "IsInBattleSceneAndTransfer")) table.Register("IsInBattleSceneAndTransfer", LAG_PETPVP_IsInBattleSceneAndTransfer);
    }
}
