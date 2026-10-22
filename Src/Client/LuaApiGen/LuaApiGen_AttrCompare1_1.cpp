




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {

        int LAG_AttrCompare1_1_GetAttrCmpStr(LuaPlus::LuaState* state) { return Stub(state, "AttrCompare1_1", "GetAttrCmpStr", "z"); }
    }

    void Register_AttrCompare1_1(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "GetAttrCmpStr")) table.Register("GetAttrCmpStr", LAG_AttrCompare1_1_GetAttrCmpStr);
    }
}
