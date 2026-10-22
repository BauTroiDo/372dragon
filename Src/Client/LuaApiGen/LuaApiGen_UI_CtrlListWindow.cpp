




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_UI_CtrlListWindow_AddNewButtonItem(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_CtrlListWindow", "AddNewButtonItem", ""); }


        int LAG_UI_CtrlListWindow_AddNewItemTooltips(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_CtrlListWindow", "AddNewItemTooltips", ""); }


        int LAG_UI_CtrlListWindow_GetRowUserData(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_CtrlListWindow", "GetRowUserData", "n"); }


        int LAG_UI_CtrlListWindow_RemoveColumnByPos(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_CtrlListWindow", "RemoveColumnByPos", ""); }


        int LAG_UI_CtrlListWindow_SetItemTooltip(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_CtrlListWindow", "SetItemTooltip", ""); }


        int LAG_UI_CtrlListWindow_SetRowTooltip(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_CtrlListWindow", "SetRowTooltip", ""); }


        int LAG_UI_CtrlListWindow_SetRowUserData(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_CtrlListWindow", "SetRowUserData", ""); }


        int LAG_UI_CtrlListWindow_SetSelectItem(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_CtrlListWindow", "SetSelectItem", ""); }


        int LAG_UI_CtrlListWindow_SetVertScollPosition(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_CtrlListWindow", "SetVertScollPosition", ""); }
    }

    void Register_UI_CtrlListWindow(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "AddNewButtonItem")) table.Register("AddNewButtonItem", LAG_UI_CtrlListWindow_AddNewButtonItem);
        if (IsMissing(table, "AddNewItemTooltips")) table.Register("AddNewItemTooltips", LAG_UI_CtrlListWindow_AddNewItemTooltips);
        if (IsMissing(table, "GetRowUserData")) table.Register("GetRowUserData", LAG_UI_CtrlListWindow_GetRowUserData);
        if (IsMissing(table, "RemoveColumnByPos")) table.Register("RemoveColumnByPos", LAG_UI_CtrlListWindow_RemoveColumnByPos);
        if (IsMissing(table, "SetItemTooltip")) table.Register("SetItemTooltip", LAG_UI_CtrlListWindow_SetItemTooltip);
        if (IsMissing(table, "SetRowTooltip")) table.Register("SetRowTooltip", LAG_UI_CtrlListWindow_SetRowTooltip);
        if (IsMissing(table, "SetRowUserData")) table.Register("SetRowUserData", LAG_UI_CtrlListWindow_SetRowUserData);
        if (IsMissing(table, "SetSelectItem")) table.Register("SetSelectItem", LAG_UI_CtrlListWindow_SetSelectItem);
        if (IsMissing(table, "SetVertScollPosition")) table.Register("SetVertScollPosition", LAG_UI_CtrlListWindow_SetVertScollPosition);
    }
}
