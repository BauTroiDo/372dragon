#pragma once
#include <windows.h>
#include <stdexcept>
class CRenderSystem;
// CYS: keep the engine implementation behind its existing plugin boundary.
inline void cysCaptureOfflineUi(CRenderSystem* renderer, const char* filename)
{
    typedef BOOL (__cdecl *Capture)(CRenderSystem*, const char*);
    HMODULE module=GetModuleHandleA("Render.dll");
    Capture capture=module ? reinterpret_cast<Capture>(GetProcAddress(module,"CysCaptureOfflineUi")) : 0;
    if (!capture) throw std::runtime_error("UI capture: Render plugin export unavailable");
    if (!capture(renderer,filename)) throw std::runtime_error("UI capture failed; see WXRender.log");
}
