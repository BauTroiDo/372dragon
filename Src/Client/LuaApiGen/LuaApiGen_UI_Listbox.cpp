




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_UI_Listbox_ClearSelectState(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_Listbox", "ClearSelectState", ""); }


        int LAG_UI_Listbox_EnsureItemIsVisable(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_Listbox", "EnsureItemIsVisable", "o"); }


        int LAG_UI_Listbox_GetClickItem(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_Listbox", "GetClickItem", "n"); }


        int LAG_UI_Listbox_GetCurrentFirstItem(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_Listbox", "GetCurrentFirstItem", "n"); }


        int LAG_UI_Listbox_GetItemByText(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_Listbox", "GetItemByText", "n"); }


        int LAG_UI_Listbox_GetItemNumByItemId(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_Listbox", "GetItemNumByItemId", "n"); }


        int LAG_UI_Listbox_GetItemNumber(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_Listbox", "GetItemNumber", "n"); }


        int LAG_UI_Listbox_GetItemUserData(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_Listbox", "GetItemUserData", "n"); }


        int LAG_UI_Listbox_SetCurrentFirstItem(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_Listbox", "SetCurrentFirstItem", ""); }


        int LAG_UI_Listbox_SetItemUserData(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_Listbox", "SetItemUserData", ""); }
    }

    void Register_UI_Listbox(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "ClearSelectState")) table.Register("ClearSelectState", LAG_UI_Listbox_ClearSelectState);
        if (IsMissing(table, "EnsureItemIsVisable")) table.Register("EnsureItemIsVisable", LAG_UI_Listbox_EnsureItemIsVisable);
        if (IsMissing(table, "GetClickItem")) table.Register("GetClickItem", LAG_UI_Listbox_GetClickItem);
        if (IsMissing(table, "GetCurrentFirstItem")) table.Register("GetCurrentFirstItem", LAG_UI_Listbox_GetCurrentFirstItem);
        if (IsMissing(table, "GetItemByText")) table.Register("GetItemByText", LAG_UI_Listbox_GetItemByText);
        if (IsMissing(table, "GetItemNumByItemId")) table.Register("GetItemNumByItemId", LAG_UI_Listbox_GetItemNumByItemId);
        if (IsMissing(table, "GetItemNumber")) table.Register("GetItemNumber", LAG_UI_Listbox_GetItemNumber);
        if (IsMissing(table, "GetItemUserData")) table.Register("GetItemUserData", LAG_UI_Listbox_GetItemUserData);
        if (IsMissing(table, "SetCurrentFirstItem")) table.Register("SetCurrentFirstItem", LAG_UI_Listbox_SetCurrentFirstItem);
        if (IsMissing(table, "SetItemUserData")) table.Register("SetItemUserData", LAG_UI_Listbox_SetItemUserData);
    }
}
