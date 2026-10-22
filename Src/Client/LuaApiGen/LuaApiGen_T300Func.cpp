




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_T300Func_IsNoDifOpen(LuaPlus::LuaState* state) { return Stub(state, "T300Func", "IsNoDifOpen", "n"); }
    }

    void Register_T300Func(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "IsNoDifOpen")) table.Register("IsNoDifOpen", LAG_T300Func_IsNoDifOpen);
    }
}
