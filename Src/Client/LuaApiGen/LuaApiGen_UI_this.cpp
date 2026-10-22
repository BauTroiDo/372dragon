




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_UI_this_Activate(LuaPlus::LuaState* state) { return Stub(state, "this", "Activate", ""); }


        int LAG_UI_this_ClickHide(LuaPlus::LuaState* state) { return Stub(state, "this", "ClickHide", "b"); }


        int LAG_UI_this_GetChildOffset(LuaPlus::LuaState* state) { return Stub(state, "this", "GetChildOffset", "nn"); }
    }

    void Register_UI_this(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "Activate")) table.Register("Activate", LAG_UI_this_Activate);
        if (IsMissing(table, "ClickHide")) table.Register("ClickHide", LAG_UI_this_ClickHide);
        if (IsMissing(table, "GetChildOffset")) table.Register("GetChildOffset", LAG_UI_this_GetChildOffset);
    }
}
