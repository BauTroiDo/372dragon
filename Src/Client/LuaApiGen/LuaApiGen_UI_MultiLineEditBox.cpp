




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_UI_MultiLineEditBox_GetString(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_MultiLineEditBox", "GetString", "s"); }


        int LAG_UI_MultiLineEditBox_SetSelected(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_MultiLineEditBox", "SetSelected", ""); }
    }

    void Register_UI_MultiLineEditBox(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "GetString")) table.Register("GetString", LAG_UI_MultiLineEditBox_GetString);
        if (IsMissing(table, "SetSelected")) table.Register("SetSelected", LAG_UI_MultiLineEditBox_SetSelected);
    }
}
