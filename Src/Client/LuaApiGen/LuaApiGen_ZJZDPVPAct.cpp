




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_ZJZDPVPAct_Lua_GetZJZDPVPData(LuaPlus::LuaState* state) { return Stub(state, "ZJZDPVPAct", "Lua_GetZJZDPVPData", "snsns"); }
    }

    void Register_ZJZDPVPAct(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "Lua_GetZJZDPVPData")) table.Register("Lua_GetZJZDPVPData", LAG_ZJZDPVPAct_Lua_GetZJZDPVPData);
    }
}
