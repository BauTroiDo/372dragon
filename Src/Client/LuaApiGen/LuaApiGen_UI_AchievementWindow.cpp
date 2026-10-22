




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_UI_AchievementWindow_AddItemElement(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_AchievementWindow", "AddItemElement", "o"); }


        int LAG_UI_AchievementWindow_CleanAllElement(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_AchievementWindow", "CleanAllElement", ""); }


        int LAG_UI_AchievementWindow_Flash(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_AchievementWindow", "Flash", ""); }


        int LAG_UI_AchievementWindow_GetVertScrollbarPosition(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_AchievementWindow", "GetVertScrollbarPosition", "n"); }


        int LAG_UI_AchievementWindow_SetElementsInView(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_AchievementWindow", "SetElementsInView", ""); }


        int LAG_UI_AchievementWindow_SetVertScrollbarHide(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_AchievementWindow", "SetVertScrollbarHide", ""); }


        int LAG_UI_AchievementWindow_SetVertScrollbarPosition(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_AchievementWindow", "SetVertScrollbarPosition", ""); }
    }

    void Register_UI_AchievementWindow(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "AddItemElement")) table.Register("AddItemElement", LAG_UI_AchievementWindow_AddItemElement);
        if (IsMissing(table, "CleanAllElement")) table.Register("CleanAllElement", LAG_UI_AchievementWindow_CleanAllElement);
        if (IsMissing(table, "Flash")) table.Register("Flash", LAG_UI_AchievementWindow_Flash);
        if (IsMissing(table, "GetVertScrollbarPosition")) table.Register("GetVertScrollbarPosition", LAG_UI_AchievementWindow_GetVertScrollbarPosition);
        if (IsMissing(table, "SetElementsInView")) table.Register("SetElementsInView", LAG_UI_AchievementWindow_SetElementsInView);
        if (IsMissing(table, "SetVertScrollbarHide")) table.Register("SetVertScrollbarHide", LAG_UI_AchievementWindow_SetVertScrollbarHide);
        if (IsMissing(table, "SetVertScrollbarPosition")) table.Register("SetVertScrollbarPosition", LAG_UI_AchievementWindow_SetVertScrollbarPosition);
    }
}
