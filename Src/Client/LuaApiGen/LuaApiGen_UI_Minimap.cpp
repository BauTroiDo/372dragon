




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_UI_Minimap_SetFlagShow(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_Minimap", "SetFlagShow", ""); }
    }

    void Register_UI_Minimap(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "SetFlagShow")) table.Register("SetFlagShow", LAG_UI_Minimap_SetFlagShow);
    }
}
