




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_AbilityTeacher_GetNeedLevel(LuaPlus::LuaState* state) { return Stub(state, "AbilityTeacher", "GetNeedLevel", "n"); }
    }

    void Register_AbilityTeacher(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "GetNeedLevel")) table.Register("GetNeedLevel", LAG_AbilityTeacher_GetNeedLevel);
    }
}
