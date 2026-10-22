




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_DiGongShop_Lua_GetDiGongShop(LuaPlus::LuaState* state) { return Stub(state, "DiGongShop", "Lua_GetDiGongShop", "t"); }
    }

    void Register_DiGongShop(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "Lua_GetDiGongShop")) table.Register("Lua_GetDiGongShop", LAG_DiGongShop_Lua_GetDiGongShop);
    }
}
