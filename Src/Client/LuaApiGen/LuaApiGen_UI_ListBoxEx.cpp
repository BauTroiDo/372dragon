




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_UI_ListBoxEx_AddFriendItemExWithoutLayout(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_ListBoxEx", "AddFriendItemExWithoutLayout", ""); }


        int LAG_UI_ListBoxEx_AddItemEx(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_ListBoxEx", "AddItemEx", ""); }


        int LAG_UI_ListBoxEx_AddItemExWithoutLayout(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_ListBoxEx", "AddItemExWithoutLayout", ""); }


        int LAG_UI_ListBoxEx_ClearListBoxEx(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_ListBoxEx", "ClearListBoxEx", ""); }


        int LAG_UI_ListBoxEx_DelItemEx(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_ListBoxEx", "DelItemEx", ""); }


        int LAG_UI_ListBoxEx_GetClickedButtonItem(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_ListBoxEx", "GetClickedButtonItem", "n"); }


        int LAG_UI_ListBoxEx_GetItemNumByMissionId(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_ListBoxEx", "GetItemNumByMissionId", "n"); }


        int LAG_UI_ListBoxEx_RequestLayout(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_ListBoxEx", "RequestLayout", ""); }


        int LAG_UI_ListBoxEx_SetVScrollbarAlpha(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_ListBoxEx", "SetVScrollbarAlpha", ""); }
    }

    void Register_UI_ListBoxEx(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "AddFriendItemExWithoutLayout")) table.Register("AddFriendItemExWithoutLayout", LAG_UI_ListBoxEx_AddFriendItemExWithoutLayout);
        if (IsMissing(table, "AddItemEx")) table.Register("AddItemEx", LAG_UI_ListBoxEx_AddItemEx);
        if (IsMissing(table, "AddItemExWithoutLayout")) table.Register("AddItemExWithoutLayout", LAG_UI_ListBoxEx_AddItemExWithoutLayout);
        if (IsMissing(table, "ClearListBoxEx")) table.Register("ClearListBoxEx", LAG_UI_ListBoxEx_ClearListBoxEx);
        if (IsMissing(table, "DelItemEx")) table.Register("DelItemEx", LAG_UI_ListBoxEx_DelItemEx);
        if (IsMissing(table, "GetClickedButtonItem")) table.Register("GetClickedButtonItem", LAG_UI_ListBoxEx_GetClickedButtonItem);
        if (IsMissing(table, "GetItemNumByMissionId")) table.Register("GetItemNumByMissionId", LAG_UI_ListBoxEx_GetItemNumByMissionId);
        if (IsMissing(table, "RequestLayout")) table.Register("RequestLayout", LAG_UI_ListBoxEx_RequestLayout);
        if (IsMissing(table, "SetVScrollbarAlpha")) table.Register("SetVScrollbarAlpha", LAG_UI_ListBoxEx_SetVScrollbarAlpha);
    }
}
