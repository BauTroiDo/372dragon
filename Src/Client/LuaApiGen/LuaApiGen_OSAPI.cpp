




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_OSAPI_GetTickCount(LuaPlus::LuaState* state) { return Stub(state, "OSAPI", "GetTickCount", "n"); }

        int LAG_OSAPI_timeGetTime(LuaPlus::LuaState* state) { return Stub(state, "OSAPI", "timeGetTime", "n"); }
    }

    void Register_OSAPI(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "GetTickCount")) table.Register("GetTickCount", LAG_OSAPI_GetTickCount);
        if (IsMissing(table, "timeGetTime")) table.Register("timeGetTime", LAG_OSAPI_timeGetTime);
    }
}
