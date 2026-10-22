




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_UI_NotSuperListItem_GetSubItem(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_NotSuperListItem", "GetSubItem", "o"); }


        int LAG_UI_NotSuperListItem_SetSubItemEvent(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_NotSuperListItem", "SetSubItemEvent", ""); }
    }

    void Register_UI_NotSuperListItem(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "GetSubItem")) table.Register("GetSubItem", LAG_UI_NotSuperListItem_GetSubItem);
        if (IsMissing(table, "SetSubItemEvent")) table.Register("SetSubItemEvent", LAG_UI_NotSuperListItem_SetSubItemEvent);
    }
}
