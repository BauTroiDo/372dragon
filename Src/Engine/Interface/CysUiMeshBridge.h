#pragma once

// CYS plugin bridges carry only borrowed data for the duration of the call.
// Keep the existing tFakeObjSystem and CRenderSystem virtual interfaces intact.
namespace CysUiMeshBridge
{
    typedef void (__cdecl *Hook)(const char* windowName, const char* objectName,
        unsigned int width, unsigned int height, const char* backgroundName);
    typedef void (__cdecl *Create)(void* renderer, const char* objectName,
        void* entity, const char* cameraName, unsigned int width,
        unsigned int height, const char* backgroundName);

    // CYS-MESHWIN 19/09: the eight MetaTable_Control_MeshWindow:*Ex Lua functions of CY 3.71 talk to a second
    // kernel node "bin\fakeEx" (g_pFakeSystemEx, CFakeObjSystemEx, CY Game.exe vtable 0x140af4898). This tree maps
    // them onto the one classic fake system ("bin\fake"); the camera / rest-pose calls need the render layer, so
    // they travel the same additive export road as Hook/Create above (no new virtual slots):
    //   UI_CEGUI.dll -> Game.exe exports CysFakeObjCameraGet/CameraSet/RestPose/Exists (keyed by WINDOW name,
    //   as CY vt[21]/vt[22]/vt[20]/vt[23] are) -> Render.dll exports CysFakeObjRttCameraGet/CameraSet/CameraReset
    //   (keyed by OBJECT name, as CFakeObjectManager is).
    // Return 1 = done, 0 = unknown window/object or renderer inactive. Height/distance/pitch are the three
    // numbers CY's GetCameraEx pushes (Lua: "local fHeight, fDistance, fPitch = X:GetCameraEx()"); xOffset is the
    // optional 4th argument of SetCameraEx (DressPreview.lua:655 fXOffset), 0 when absent.
    typedef int (__cdecl *CameraGet)(const char* windowName, float* height, float* distance, float* pitch, float* xOffset);
    typedef int (__cdecl *CameraSet)(const char* windowName, float height, float distance, float pitch, float xOffset);
    typedef int (__cdecl *RestPose)(const char* windowName);
    typedef int (__cdecl *ObjectExists)(const char* objectName);
    typedef int (__cdecl *RttCameraGet)(const char* objectName, float* height, float* distance, float* pitch, float* xOffset);
    typedef int (__cdecl *RttCameraSet)(const char* objectName, float height, float distance, float pitch, float xOffset);
    typedef int (__cdecl *RttCameraReset)(const char* objectName);
}
