




#include "LuaApiGen.h"

namespace LuaApiGen
{
    namespace
    {


        int LAG_UI_MeshWindow_AttachWindowEx(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_MeshWindow", "AttachWindowEx", ""); }


        int LAG_UI_MeshWindow_ChangeCameraDistanceEx(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_MeshWindow", "ChangeCameraDistanceEx", ""); }


        int LAG_UI_MeshWindow_DetachWindowEx(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_MeshWindow", "DetachWindowEx", ""); }


        int LAG_UI_MeshWindow_GetCameraEx(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_MeshWindow", "GetCameraEx", "nnn"); }


        int LAG_UI_MeshWindow_RestPositonEx(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_MeshWindow", "RestPositonEx", ""); }


        int LAG_UI_MeshWindow_RotateBeginEx(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_MeshWindow", "RotateBeginEx", ""); }


        int LAG_UI_MeshWindow_RotateEndEx(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_MeshWindow", "RotateEndEx", ""); }


        int LAG_UI_MeshWindow_SetCameraEx(LuaPlus::LuaState* state) { return Stub(state, "MetaTable_Control_MeshWindow", "SetCameraEx", ""); }
    }

    void Register_UI_MeshWindow(LuaPlus::LuaObject& table)
    {
        if (IsMissing(table, "AttachWindowEx")) table.Register("AttachWindowEx", LAG_UI_MeshWindow_AttachWindowEx);
        if (IsMissing(table, "ChangeCameraDistanceEx")) table.Register("ChangeCameraDistanceEx", LAG_UI_MeshWindow_ChangeCameraDistanceEx);
        if (IsMissing(table, "DetachWindowEx")) table.Register("DetachWindowEx", LAG_UI_MeshWindow_DetachWindowEx);
        if (IsMissing(table, "GetCameraEx")) table.Register("GetCameraEx", LAG_UI_MeshWindow_GetCameraEx);
        if (IsMissing(table, "RestPositonEx")) table.Register("RestPositonEx", LAG_UI_MeshWindow_RestPositonEx);
        if (IsMissing(table, "RotateBeginEx")) table.Register("RotateBeginEx", LAG_UI_MeshWindow_RotateBeginEx);
        if (IsMissing(table, "RotateEndEx")) table.Register("RotateEndEx", LAG_UI_MeshWindow_RotateEndEx);
        if (IsMissing(table, "SetCameraEx")) table.Register("SetCameraEx", LAG_UI_MeshWindow_SetCameraEx);
    }
}
