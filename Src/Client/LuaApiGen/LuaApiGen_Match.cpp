




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_Match_ClearHuaShanGRMatchScore(LuaPlus::LuaState* state) { return Stub(state, "Match", "ClearHuaShanGRMatchScore", ""); }

        int LAG_Match_CloseHuaShanGRMatchScoreMultiTable(LuaPlus::LuaState* state) { return Stub(state, "Match", "CloseHuaShanGRMatchScoreMultiTable", ""); }

        int LAG_Match_GetHuaShanGRMatchScore(LuaPlus::LuaState* state) { return Stub(state, "Match", "GetHuaShanGRMatchScore", "nsnnnnn"); }

        int LAG_Match_OpenHuaShanGRMatchScoreMultiTable(LuaPlus::LuaState* state) { return Stub(state, "Match", "OpenHuaShanGRMatchScoreMultiTable", ""); }
    }

    void Register_Match(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "ClearHuaShanGRMatchScore")) table.Register("ClearHuaShanGRMatchScore", LAG_Match_ClearHuaShanGRMatchScore);
        if (IsMissing(table, "CloseHuaShanGRMatchScoreMultiTable")) table.Register("CloseHuaShanGRMatchScoreMultiTable", LAG_Match_CloseHuaShanGRMatchScoreMultiTable);
        if (IsMissing(table, "GetHuaShanGRMatchScore")) table.Register("GetHuaShanGRMatchScore", LAG_Match_GetHuaShanGRMatchScore);
        if (IsMissing(table, "OpenHuaShanGRMatchScoreMultiTable")) table.Register("OpenHuaShanGRMatchScoreMultiTable", LAG_Match_OpenHuaShanGRMatchScoreMultiTable);
    }
}
