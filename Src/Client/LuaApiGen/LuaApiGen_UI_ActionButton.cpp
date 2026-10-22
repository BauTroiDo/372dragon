




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_UI_ActionButton_GetActionItem(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_ActionButton", "GetActionItem", "n"); }


        int LAG_UI_ActionButton_SetDrawCorner(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_ActionButton", "SetDrawCorner", ""); }


        int LAG_UI_ActionButton_SetNewFlash(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_ActionButton", "SetNewFlash", ""); }


        int LAG_UI_ActionButton_ShowPercentage(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_ActionButton", "ShowPercentage", ""); }
    }

    void Register_UI_ActionButton(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "GetActionItem")) table.Register("GetActionItem", LAG_UI_ActionButton_GetActionItem);
        if (IsMissing(table, "SetDrawCorner")) table.Register("SetDrawCorner", LAG_UI_ActionButton_SetDrawCorner);
        if (IsMissing(table, "SetNewFlash")) table.Register("SetNewFlash", LAG_UI_ActionButton_SetNewFlash);
        if (IsMissing(table, "ShowPercentage")) table.Register("ShowPercentage", LAG_UI_ActionButton_ShowPercentage);
    }
}
