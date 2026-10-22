




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_BWZQ_CancelGMWatch(LuaPlus::LuaState* state) { return Stub(state, "BWZQ", "CancelGMWatch", "n"); }

        int LAG_BWZQ_LuaFnGetBWZQSponsorInfo(LuaPlus::LuaState* state) { return Stub(state, "BWZQ", "LuaFnGetBWZQSponsorInfo", "ns"); }

        int LAG_BWZQ_LuaFnGetBattleLiveInfo(LuaPlus::LuaState* state) { return Stub(state, "BWZQ", "LuaFnGetBattleLiveInfo", "sssnnn"); }

        int LAG_BWZQ_LuaFnUpdateSponsorExterior(LuaPlus::LuaState* state) { return Stub(state, "BWZQ", "LuaFnUpdateSponsorExterior", ""); }

        int LAG_BWZQ_SetPlayerWatchPosDirection(LuaPlus::LuaState* state) { return Stub(state, "BWZQ", "SetPlayerWatchPosDirection", "n"); }

        int LAG_BWZQ_SetSpecialSceneFlag(LuaPlus::LuaState* state) { return Stub(state, "BWZQ", "SetSpecialSceneFlag", ""); }
    }

    void Register_BWZQ(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "CancelGMWatch")) table.Register("CancelGMWatch", LAG_BWZQ_CancelGMWatch);
        if (IsMissing(table, "LuaFnGetBWZQSponsorInfo")) table.Register("LuaFnGetBWZQSponsorInfo", LAG_BWZQ_LuaFnGetBWZQSponsorInfo);
        if (IsMissing(table, "LuaFnGetBattleLiveInfo")) table.Register("LuaFnGetBattleLiveInfo", LAG_BWZQ_LuaFnGetBattleLiveInfo);
        if (IsMissing(table, "LuaFnUpdateSponsorExterior")) table.Register("LuaFnUpdateSponsorExterior", LAG_BWZQ_LuaFnUpdateSponsorExterior);
        if (IsMissing(table, "SetPlayerWatchPosDirection")) table.Register("SetPlayerWatchPosDirection", LAG_BWZQ_SetPlayerWatchPosDirection);
        if (IsMissing(table, "SetSpecialSceneFlag")) table.Register("SetSpecialSceneFlag", LAG_BWZQ_SetSpecialSceneFlag);
    }
}
