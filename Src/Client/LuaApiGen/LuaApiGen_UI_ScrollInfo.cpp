




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_UI_ScrollInfo_SetScrollInfo(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_ScrollInfo", "SetScrollInfo", ""); }
    }

    void Register_UI_ScrollInfo(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "SetScrollInfo")) table.Register("SetScrollInfo", LAG_UI_ScrollInfo_SetScrollInfo);
    }
}
