#pragma once

// Borrowed renderer/entity pointers, valid only during this main-thread call.
// The login showroom uses normal scene visibility instead of an RTT window.
// This additive export leaves the existing plugin virtual interfaces intact.
namespace CysLoginSceneBridge
{
    typedef int (__cdecl *ActorVisible)(void* renderer, void* entity, int visible);
    typedef int (__cdecl *ActorScale)(void* renderer, void* entity, float scale);
    typedef int (__cdecl *CameraPose)(void* renderer, const float* eyeXYZ,
                                     const float* orientationWXYZ, float fovYDegrees);
    // CYS-CHARSEL: far clip of the active character-view camera (CY login camera: 40000).
    typedef int (__cdecl *CameraFarClip)(void* renderer, float farClip);
    // CYS-SKY: the CY Render.dll day clock runs (60 s per day) in the procedure scenes, where Game.exe never sets the time.
    typedef int (__cdecl *SkyClock)(void* renderer, int running);

    typedef int (__cdecl *SkyTime)(void* renderer, int dayOfMonth, float dayFraction);
}
