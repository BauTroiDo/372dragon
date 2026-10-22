




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_ANS_IsHideNameScene(LuaPlus::LuaState* state) { return Stub(state, "ANS", "IsHideNameScene", "n"); }

        int LAG_ANS_Lua_CheckMainTargetAndMyselfFromAnonymousCommon(LuaPlus::LuaState* state) { return Stub(state, "ANS", "Lua_CheckMainTargetAndMyselfFromAnonymousCommon", "n"); }
    }

    void Register_ANS(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "IsHideNameScene")) table.Register("IsHideNameScene", LAG_ANS_IsHideNameScene);
        if (IsMissing(table, "Lua_CheckMainTargetAndMyselfFromAnonymousCommon")) table.Register("Lua_CheckMainTargetAndMyselfFromAnonymousCommon", LAG_ANS_Lua_CheckMainTargetAndMyselfFromAnonymousCommon);
    }
}
