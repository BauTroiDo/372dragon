




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_UI_ScrollBar_GetThumbPositionX(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_ScrollBar", "GetThumbPositionX", "s"); }
    }

    void Register_UI_ScrollBar(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "GetThumbPositionX")) table.Register("GetThumbPositionX", LAG_UI_ScrollBar_GetThumbPositionX);
    }
}
