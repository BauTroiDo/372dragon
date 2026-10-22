




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_UI_SceneMapWindow_DoScroll(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_SceneMapWindow", "DoScroll", ""); }


        int LAG_UI_SceneMapWindow_GetBaseOffset(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_SceneMapWindow", "GetBaseOffset", "nn"); }


        int LAG_UI_SceneMapWindow_GetSceneZoomMode(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_SceneMapWindow", "GetSceneZoomMode", "n"); }


        int LAG_UI_SceneMapWindow_HideBuleCircle(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_SceneMapWindow", "HideBuleCircle", ""); }


        int LAG_UI_SceneMapWindow_SetFixMode(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_SceneMapWindow", "SetFixMode", ""); }


        int LAG_UI_SceneMapWindow_SetFlagShow(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_SceneMapWindow", "SetFlagShow", ""); }


        int LAG_UI_SceneMapWindow_ShowBuleCircle(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_SceneMapWindow", "ShowBuleCircle", ""); }


        int LAG_UI_SceneMapWindow_UpdateFlag(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_SceneMapWindow", "UpdateFlag", ""); }


        int LAG_UI_SceneMapWindow_ZoomOutBlueCircle(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_SceneMapWindow", "ZoomOutBlueCircle", ""); }
    }

    void Register_UI_SceneMapWindow(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "DoScroll")) table.Register("DoScroll", LAG_UI_SceneMapWindow_DoScroll);
        if (IsMissing(table, "GetBaseOffset")) table.Register("GetBaseOffset", LAG_UI_SceneMapWindow_GetBaseOffset);
        if (IsMissing(table, "GetSceneZoomMode")) table.Register("GetSceneZoomMode", LAG_UI_SceneMapWindow_GetSceneZoomMode);
        if (IsMissing(table, "HideBuleCircle")) table.Register("HideBuleCircle", LAG_UI_SceneMapWindow_HideBuleCircle);
        if (IsMissing(table, "SetFixMode")) table.Register("SetFixMode", LAG_UI_SceneMapWindow_SetFixMode);
        if (IsMissing(table, "SetFlagShow")) table.Register("SetFlagShow", LAG_UI_SceneMapWindow_SetFlagShow);
        if (IsMissing(table, "ShowBuleCircle")) table.Register("ShowBuleCircle", LAG_UI_SceneMapWindow_ShowBuleCircle);
        if (IsMissing(table, "UpdateFlag")) table.Register("UpdateFlag", LAG_UI_SceneMapWindow_UpdateFlag);
        if (IsMissing(table, "ZoomOutBlueCircle")) table.Register("ZoomOutBlueCircle", LAG_UI_SceneMapWindow_ZoomOutBlueCircle);
    }
}
