




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_UI_AnimateWindow_GetItemElementsString(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_AnimateWindow", "GetItemElementsString", "s"); }


        int LAG_UI_AnimateWindow_Play(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_AnimateWindow", "Play", ""); }


        int LAG_UI_AnimateWindow_SetAnimateID(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_AnimateWindow", "SetAnimateID", ""); }


        int LAG_UI_AnimateWindow_SetBlinkText(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_AnimateWindow", "SetBlinkText", ""); }


        int LAG_UI_AnimateWindow_SetItemElementsString(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_AnimateWindow", "SetItemElementsString", ""); }


        int LAG_UI_AnimateWindow_SetSelected(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_AnimateWindow", "SetSelected", ""); }
    }

    void Register_UI_AnimateWindow(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "GetItemElementsString")) table.Register("GetItemElementsString", LAG_UI_AnimateWindow_GetItemElementsString);
        if (IsMissing(table, "Play")) table.Register("Play", LAG_UI_AnimateWindow_Play);
        if (IsMissing(table, "SetAnimateID")) table.Register("SetAnimateID", LAG_UI_AnimateWindow_SetAnimateID);
        if (IsMissing(table, "SetBlinkText")) table.Register("SetBlinkText", LAG_UI_AnimateWindow_SetBlinkText);
        if (IsMissing(table, "SetItemElementsString")) table.Register("SetItemElementsString", LAG_UI_AnimateWindow_SetItemElementsString);
        if (IsMissing(table, "SetSelected")) table.Register("SetSelected", LAG_UI_AnimateWindow_SetSelected);
    }
}
