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











    typedef int (__cdecl *CameraGet)(const char* windowName, float* height, float* distance, float* pitch, float* xOffset);
    typedef int (__cdecl *CameraSet)(const char* windowName, float height, float distance, float pitch, float xOffset);
    typedef int (__cdecl *RestPose)(const char* windowName);
    typedef int (__cdecl *ObjectExists)(const char* objectName);
    typedef int (__cdecl *RttCameraGet)(const char* objectName, float* height, float* distance, float* pitch, float* xOffset);
    typedef int (__cdecl *RttCameraSet)(const char* objectName, float height, float distance, float pitch, float xOffset);
    typedef int (__cdecl *RttCameraReset)(const char* objectName);
}
