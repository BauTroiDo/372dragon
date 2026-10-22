




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_CSongliaoWarData_ClearSongliaoData(LuaPlus::LuaState* state) { return Stub(state, "CSongliaoWarData", "ClearSongliaoData", ""); }

        int LAG_CSongliaoWarData_GetCampScore(LuaPlus::LuaState* state) { return Stub(state, "CSongliaoWarData", "GetCampScore", "nn"); }

        int LAG_CSongliaoWarData_GetCampStateScore(LuaPlus::LuaState* state) { return Stub(state, "CSongliaoWarData", "GetCampStateScore", "n"); }

        int LAG_CSongliaoWarData_GetMaxKillNumData(LuaPlus::LuaState* state) { return Stub(state, "CSongliaoWarData", "GetMaxKillNumData", "sn"); }

        int LAG_CSongliaoWarData_GetMyScore(LuaPlus::LuaState* state) { return Stub(state, "CSongliaoWarData", "GetMyScore", "nsnnnnnn"); }

        int LAG_CSongliaoWarData_GetPlayerNum(LuaPlus::LuaState* state) { return Stub(state, "CSongliaoWarData", "GetPlayerNum", "n"); }

        int LAG_CSongliaoWarData_GetScoreByIndex(LuaPlus::LuaState* state) { return Stub(state, "CSongliaoWarData", "GetScoreByIndex", "nnsnnnnn"); }

        int LAG_CSongliaoWarData_GetSongliaoKillInfoByGuid(LuaPlus::LuaState* state) { return Stub(state, "CSongliaoWarData", "GetSongliaoKillInfoByGuid", "nnsnnnn"); }

        int LAG_CSongliaoWarData_GetStateWinner(LuaPlus::LuaState* state) { return Stub(state, "CSongliaoWarData", "GetStateWinner", "n"); }

        int LAG_CSongliaoWarData_GetTick(LuaPlus::LuaState* state) { return Stub(state, "CSongliaoWarData", "GetTick", "n"); }

        int LAG_CSongliaoWarData_OpenSongliaoWarMulti(LuaPlus::LuaState* state) { return Stub(state, "CSongliaoWarData", "OpenSongliaoWarMulti", ""); }

        int LAG_CSongliaoWarData_SetMyScore(LuaPlus::LuaState* state) { return Stub(state, "CSongliaoWarData", "SetMyScore", ""); }
    }

    void Register_CSongliaoWarData(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "ClearSongliaoData")) table.Register("ClearSongliaoData", LAG_CSongliaoWarData_ClearSongliaoData);
        if (IsMissing(table, "GetCampScore")) table.Register("GetCampScore", LAG_CSongliaoWarData_GetCampScore);
        if (IsMissing(table, "GetCampStateScore")) table.Register("GetCampStateScore", LAG_CSongliaoWarData_GetCampStateScore);
        if (IsMissing(table, "GetMaxKillNumData")) table.Register("GetMaxKillNumData", LAG_CSongliaoWarData_GetMaxKillNumData);
        if (IsMissing(table, "GetMyScore")) table.Register("GetMyScore", LAG_CSongliaoWarData_GetMyScore);
        if (IsMissing(table, "GetPlayerNum")) table.Register("GetPlayerNum", LAG_CSongliaoWarData_GetPlayerNum);
        if (IsMissing(table, "GetScoreByIndex")) table.Register("GetScoreByIndex", LAG_CSongliaoWarData_GetScoreByIndex);
        if (IsMissing(table, "GetSongliaoKillInfoByGuid")) table.Register("GetSongliaoKillInfoByGuid", LAG_CSongliaoWarData_GetSongliaoKillInfoByGuid);
        if (IsMissing(table, "GetStateWinner")) table.Register("GetStateWinner", LAG_CSongliaoWarData_GetStateWinner);
        if (IsMissing(table, "GetTick")) table.Register("GetTick", LAG_CSongliaoWarData_GetTick);
        if (IsMissing(table, "OpenSongliaoWarMulti")) table.Register("OpenSongliaoWarMulti", LAG_CSongliaoWarData_OpenSongliaoWarMulti);
        if (IsMissing(table, "SetMyScore")) table.Register("SetMyScore", LAG_CSongliaoWarData_SetMyScore);
    }
}
