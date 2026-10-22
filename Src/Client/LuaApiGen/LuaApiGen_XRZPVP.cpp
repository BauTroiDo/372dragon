




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_XRZPVP_GetBattleBaseInfo(LuaPlus::LuaState* state) { return Stub(state, "XRZPVP", "GetBattleBaseInfo", "t"); }

        int LAG_XRZPVP_GetBattlePlayerRankInfo(LuaPlus::LuaState* state) { return Stub(state, "XRZPVP", "GetBattlePlayerRankInfo", "t"); }

        int LAG_XRZPVP_GetBattleRankInfo(LuaPlus::LuaState* state) { return Stub(state, "XRZPVP", "GetBattleRankInfo", "nnnnn"); }

        int LAG_XRZPVP_IsInBattleScene(LuaPlus::LuaState* state) { return Stub(state, "XRZPVP", "IsInBattleScene", "n"); }

        int LAG_XRZPVP_IsInBattleSceneAndTransfer(LuaPlus::LuaState* state) { return Stub(state, "XRZPVP", "IsInBattleSceneAndTransfer", "n"); }

        int LAG_XRZPVP_IsInBattleSceneAndTransfer_TargetID(LuaPlus::LuaState* state) { return Stub(state, "XRZPVP", "IsInBattleSceneAndTransfer_TargetID", "n"); }
    }

    void Register_XRZPVP(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "GetBattleBaseInfo")) table.Register("GetBattleBaseInfo", LAG_XRZPVP_GetBattleBaseInfo);
        if (IsMissing(table, "GetBattlePlayerRankInfo")) table.Register("GetBattlePlayerRankInfo", LAG_XRZPVP_GetBattlePlayerRankInfo);
        if (IsMissing(table, "GetBattleRankInfo")) table.Register("GetBattleRankInfo", LAG_XRZPVP_GetBattleRankInfo);
        if (IsMissing(table, "IsInBattleScene")) table.Register("IsInBattleScene", LAG_XRZPVP_IsInBattleScene);
        if (IsMissing(table, "IsInBattleSceneAndTransfer")) table.Register("IsInBattleSceneAndTransfer", LAG_XRZPVP_IsInBattleSceneAndTransfer);
        if (IsMissing(table, "IsInBattleSceneAndTransfer_TargetID")) table.Register("IsInBattleSceneAndTransfer_TargetID", LAG_XRZPVP_IsInBattleSceneAndTransfer_TargetID);
    }
}
