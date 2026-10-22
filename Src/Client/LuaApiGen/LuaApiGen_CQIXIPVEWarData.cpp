




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_CQIXIPVEWarData_Lua_GetQIXIPVESceneMyRankInfo(LuaPlus::LuaState* state) { return Stub(state, "CQIXIPVEWarData", "Lua_GetQIXIPVESceneMyRankInfo", "t"); }

        int LAG_CQIXIPVEWarData_Lua_GetQIXIPVESceneRankInfo(LuaPlus::LuaState* state) { return Stub(state, "CQIXIPVEWarData", "Lua_GetQIXIPVESceneRankInfo", "t"); }

        int LAG_CQIXIPVEWarData_Lua_GetQIXIPVESceneRankNum(LuaPlus::LuaState* state) { return Stub(state, "CQIXIPVEWarData", "Lua_GetQIXIPVESceneRankNum", "n"); }
    }

    void Register_CQIXIPVEWarData(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "Lua_GetQIXIPVESceneMyRankInfo")) table.Register("Lua_GetQIXIPVESceneMyRankInfo", LAG_CQIXIPVEWarData_Lua_GetQIXIPVESceneMyRankInfo);
        if (IsMissing(table, "Lua_GetQIXIPVESceneRankInfo")) table.Register("Lua_GetQIXIPVESceneRankInfo", LAG_CQIXIPVEWarData_Lua_GetQIXIPVESceneRankInfo);
        if (IsMissing(table, "Lua_GetQIXIPVESceneRankNum")) table.Register("Lua_GetQIXIPVESceneRankNum", LAG_CQIXIPVEWarData_Lua_GetQIXIPVESceneRankNum);
    }
}
