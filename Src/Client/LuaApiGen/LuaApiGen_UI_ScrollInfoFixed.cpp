




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_UI_ScrollInfoFixed_ClearInfo(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_ScrollInfoFixed", "ClearInfo", ""); }


        int LAG_UI_ScrollInfoFixed_SetScrollInfoFixed(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_ScrollInfoFixed", "SetScrollInfoFixed", ""); }
    }

    void Register_UI_ScrollInfoFixed(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "ClearInfo")) table.Register("ClearInfo", LAG_UI_ScrollInfoFixed_ClearInfo);
        if (IsMissing(table, "SetScrollInfoFixed")) table.Register("SetScrollInfoFixed", LAG_UI_ScrollInfoFixed_SetScrollInfoFixed);
    }
}
