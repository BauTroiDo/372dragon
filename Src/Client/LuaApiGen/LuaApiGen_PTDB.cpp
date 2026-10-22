




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_PTDB_LuaFnGetAwardType(LuaPlus::LuaState* state) { return Stub(state, "PTDB", "LuaFnGetAwardType", "n"); }

        int LAG_PTDB_LuaFnGetGuildBoxData(LuaPlus::LuaState* state) { return Stub(state, "PTDB", "LuaFnGetGuildBoxData", "nnnnnnn"); }


        int LAG_PTDB_LuaFnGetTowerDetailData(LuaPlus::LuaState* state) { return Stub(state, "PTDB", "LuaFnGetTowerDetailData", "t"); }

        int LAG_PTDB_LuaFnIsCanRelive(LuaPlus::LuaState* state) { return Stub(state, "PTDB", "LuaFnIsCanRelive", "n"); }


        int LAG_PTDB_LuaFnIsPTDBScene(LuaPlus::LuaState* state) { return Stub(state, "PTDB", "LuaFnIsPTDBScene", "n"); }
    }

    void Register_PTDB(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "LuaFnGetAwardType")) table.Register("LuaFnGetAwardType", LAG_PTDB_LuaFnGetAwardType);
        if (IsMissing(table, "LuaFnGetGuildBoxData")) table.Register("LuaFnGetGuildBoxData", LAG_PTDB_LuaFnGetGuildBoxData);
        if (IsMissing(table, "LuaFnGetTowerDetailData")) table.Register("LuaFnGetTowerDetailData", LAG_PTDB_LuaFnGetTowerDetailData);
        if (IsMissing(table, "LuaFnIsCanRelive")) table.Register("LuaFnIsCanRelive", LAG_PTDB_LuaFnIsCanRelive);
        if (IsMissing(table, "LuaFnIsPTDBScene")) table.Register("LuaFnIsPTDBScene", LAG_PTDB_LuaFnIsPTDBScene);
    }
}
