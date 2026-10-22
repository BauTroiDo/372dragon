




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_UI_NotSuperList_AddChild(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_NotSuperList", "AddChild", "o"); }


        int LAG_UI_NotSuperList_Clear(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_NotSuperList", "Clear", ""); }


        int LAG_UI_NotSuperList_GetListItemAt(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_NotSuperList", "GetListItemAt", "o"); }


        int LAG_UI_NotSuperList_GetListItemCount(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_NotSuperList", "GetListItemCount", "n"); }


        int LAG_UI_NotSuperList_GetScrollPosition(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_NotSuperList", "GetScrollPosition", "n"); }


        int LAG_UI_NotSuperList_GetSelected(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_NotSuperList", "GetSelected", "n"); }


        int LAG_UI_NotSuperList_RefreshLayout(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_NotSuperList", "RefreshLayout", ""); }


        int LAG_UI_NotSuperList_SetScrollPosition(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_NotSuperList", "SetScrollPosition", ""); }


        int LAG_UI_NotSuperList_SetScrollPosition4Index(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_NotSuperList", "SetScrollPosition4Index", ""); }


        int LAG_UI_NotSuperList_SetSelected(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_NotSuperList", "SetSelected", ""); }
    }

    void Register_UI_NotSuperList(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "AddChild")) table.Register("AddChild", LAG_UI_NotSuperList_AddChild);
        if (IsMissing(table, "Clear")) table.Register("Clear", LAG_UI_NotSuperList_Clear);
        if (IsMissing(table, "GetListItemAt")) table.Register("GetListItemAt", LAG_UI_NotSuperList_GetListItemAt);
        if (IsMissing(table, "GetListItemCount")) table.Register("GetListItemCount", LAG_UI_NotSuperList_GetListItemCount);
        if (IsMissing(table, "GetScrollPosition")) table.Register("GetScrollPosition", LAG_UI_NotSuperList_GetScrollPosition);
        if (IsMissing(table, "GetSelected")) table.Register("GetSelected", LAG_UI_NotSuperList_GetSelected);
        if (IsMissing(table, "RefreshLayout")) table.Register("RefreshLayout", LAG_UI_NotSuperList_RefreshLayout);
        if (IsMissing(table, "SetScrollPosition")) table.Register("SetScrollPosition", LAG_UI_NotSuperList_SetScrollPosition);
        if (IsMissing(table, "SetScrollPosition4Index")) table.Register("SetScrollPosition4Index", LAG_UI_NotSuperList_SetScrollPosition4Index);
        if (IsMissing(table, "SetSelected")) table.Register("SetSelected", LAG_UI_NotSuperList_SetSelected);
    }
}
