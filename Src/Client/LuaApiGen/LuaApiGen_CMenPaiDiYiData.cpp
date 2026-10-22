




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_CMenPaiDiYiData_ClearDDZData(LuaPlus::LuaState* state) { return Stub(state, "CMenPaiDiYiData", "ClearDDZData", ""); }

        int LAG_CMenPaiDiYiData_GetCampScore(LuaPlus::LuaState* state) { return Stub(state, "CMenPaiDiYiData", "GetCampScore", "nn"); }

        int LAG_CMenPaiDiYiData_GetMyScore(LuaPlus::LuaState* state) { return Stub(state, "CMenPaiDiYiData", "GetMyScore", "nsnnnnnn"); }

        int LAG_CMenPaiDiYiData_GetPlayerNum(LuaPlus::LuaState* state) { return Stub(state, "CMenPaiDiYiData", "GetPlayerNum", "n"); }

        int LAG_CMenPaiDiYiData_GetResult(LuaPlus::LuaState* state) { return Stub(state, "CMenPaiDiYiData", "GetResult", "n"); }


        int LAG_CMenPaiDiYiData_GetScoreByIndex(LuaPlus::LuaState* state) { return Stub(state, "CMenPaiDiYiData", "GetScoreByIndex", "nnsnnnn"); }

        int LAG_CMenPaiDiYiData_GetTargetScore(LuaPlus::LuaState* state) { return Stub(state, "CMenPaiDiYiData", "GetTargetScore", "nsnnnnnn"); }

        int LAG_CMenPaiDiYiData_GetTick(LuaPlus::LuaState* state) { return Stub(state, "CMenPaiDiYiData", "GetTick", "n"); }

        int LAG_CMenPaiDiYiData_GetUnitId(LuaPlus::LuaState* state) { return Stub(state, "CMenPaiDiYiData", "GetUnitId", "n"); }


        int LAG_CMenPaiDiYiData_LuaSetShowResultFlag(LuaPlus::LuaState* state) { return Stub(state, "CMenPaiDiYiData", "LuaSetShowResultFlag", ""); }
    }

    void Register_CMenPaiDiYiData(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "ClearDDZData")) table.Register("ClearDDZData", LAG_CMenPaiDiYiData_ClearDDZData);
        if (IsMissing(table, "GetCampScore")) table.Register("GetCampScore", LAG_CMenPaiDiYiData_GetCampScore);
        if (IsMissing(table, "GetMyScore")) table.Register("GetMyScore", LAG_CMenPaiDiYiData_GetMyScore);
        if (IsMissing(table, "GetPlayerNum")) table.Register("GetPlayerNum", LAG_CMenPaiDiYiData_GetPlayerNum);
        if (IsMissing(table, "GetResult")) table.Register("GetResult", LAG_CMenPaiDiYiData_GetResult);
        if (IsMissing(table, "GetScoreByIndex")) table.Register("GetScoreByIndex", LAG_CMenPaiDiYiData_GetScoreByIndex);
        if (IsMissing(table, "GetTargetScore")) table.Register("GetTargetScore", LAG_CMenPaiDiYiData_GetTargetScore);
        if (IsMissing(table, "GetTick")) table.Register("GetTick", LAG_CMenPaiDiYiData_GetTick);
        if (IsMissing(table, "GetUnitId")) table.Register("GetUnitId", LAG_CMenPaiDiYiData_GetUnitId);
        if (IsMissing(table, "LuaSetShowResultFlag")) table.Register("LuaSetShowResultFlag", LAG_CMenPaiDiYiData_LuaSetShowResultFlag);
    }
}
