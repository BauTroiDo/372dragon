




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_UI_Window_GetAlpha(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_Window", "GetAlpha", "n"); }


        int LAG_UI_Window_GetPixelRect(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_Window", "GetPixelRect", "nnnn"); }


        int LAG_UI_Window_GetToolTip(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_Window", "GetToolTip", "s"); }


        int LAG_UI_Window_GetWindowSize(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_Window", "GetWindowSize", "nn"); }


        int LAG_UI_Window_SetEvent(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_Window", "SetEvent", ""); }


        int LAG_UI_Window_SetWindowSize(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_Window", "SetWindowSize", ""); }


        int LAG_UI_Window_SetXAttachPos(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_Window", "SetXAttachPos", "n"); }


        int LAG_UI_Window_StartFade(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_Window", "StartFade", ""); }


        int LAG_UI_Window_Tween_Play(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_Window", "Tween_Play", ""); }


        int LAG_UI_Window_Tween_Reset(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_Window", "Tween_Reset", ""); }


        int LAG_UI_Window_Tween_SetInfo(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_Window", "Tween_SetInfo", ""); }
    }

    void Register_UI_Window(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "GetAlpha")) table.Register("GetAlpha", LAG_UI_Window_GetAlpha);
        if (IsMissing(table, "GetPixelRect")) table.Register("GetPixelRect", LAG_UI_Window_GetPixelRect);
        if (IsMissing(table, "GetToolTip")) table.Register("GetToolTip", LAG_UI_Window_GetToolTip);
        if (IsMissing(table, "GetWindowSize")) table.Register("GetWindowSize", LAG_UI_Window_GetWindowSize);
        if (IsMissing(table, "SetEvent")) table.Register("SetEvent", LAG_UI_Window_SetEvent);
        if (IsMissing(table, "SetWindowSize")) table.Register("SetWindowSize", LAG_UI_Window_SetWindowSize);
        if (IsMissing(table, "SetXAttachPos")) table.Register("SetXAttachPos", LAG_UI_Window_SetXAttachPos);
        if (IsMissing(table, "StartFade")) table.Register("StartFade", LAG_UI_Window_StartFade);
        if (IsMissing(table, "Tween_Play")) table.Register("Tween_Play", LAG_UI_Window_Tween_Play);
        if (IsMissing(table, "Tween_Reset")) table.Register("Tween_Reset", LAG_UI_Window_Tween_Reset);
        if (IsMissing(table, "Tween_SetInfo")) table.Register("Tween_SetInfo", LAG_UI_Window_Tween_SetInfo);
    }
}
