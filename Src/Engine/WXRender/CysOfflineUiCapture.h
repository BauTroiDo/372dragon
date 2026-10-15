#pragma once
#include "OgreRenderWindow.h"
#include "OgreImage.h"
#include <d3d9.h>
#include <stdexcept>
#include <vector>
#include <cstdio>

// CYS: opt-in diagnostics for the private offline capture probe.
inline void cysCheckCaptureHeap(const char* boundary)
{
    if (!GetEnvironmentVariableA("CYS_UI_CAPTURE_DIAGNOSTICS",0,0)) return;
    HANDLE heaps[256];
    const DWORD count=GetProcessHeaps(256,heaps);
    if (count>256) throw std::runtime_error("UI capture: heap diagnostic capacity exceeded");
    for (DWORD i=0;i<count;++i) {
        const BOOL valid=HeapValidate(heaps[i],0,0);
        char message[192];
        const int length=std::snprintf(message,sizeof(message),"boundary=%s heap=%lu valid=%d\r\n",boundary,i,valid);
        HANDLE log=CreateFileA("cys-capture-heap.log",FILE_APPEND_DATA,FILE_SHARE_READ,0,OPEN_ALWAYS,FILE_ATTRIBUTE_NORMAL,0);
        if (log!=INVALID_HANDLE_VALUE) {
            DWORD written=0;
            WriteFile(log,message,static_cast<DWORD>(length),&written,0);
            CloseHandle(log);
        }
        if (!valid) throw std::runtime_error("UI capture: invalid heap before encoder");
    }
}

// CYS: the OGRE 1.2 screenshot API reads the desktop front buffer. Offline UI
// evidence must read this render window's own surface before Present instead.
inline void cysCaptureOfflineUi(Ogre::RenderWindow* window, const char* filename)
{
    cysCheckCaptureHeap("before-update");
    window->update(false);
    cysCheckCaptureHeap("after-update");
    IDirect3DDevice9* device = 0;
    IDirect3DSurface9* back = 0;
    window->getCustomAttribute("D3DDEVICE",&device);
    window->getCustomAttribute("DDBACKBUFFER",&back); // borrowed; do not Release
    if (!device || !back) throw std::runtime_error("UI capture: no D3D9 surface");
    D3DSURFACE_DESC desc = {};
    if (FAILED(back->GetDesc(&desc))) throw std::runtime_error("UI capture: surface description failed");
    if (desc.Format != D3DFMT_A8R8G8B8 && desc.Format != D3DFMT_X8R8G8B8)
        throw std::runtime_error("UI capture: expected a 32-bit back buffer");
    struct Surface { IDirect3DSurface9* p = 0; ~Surface() { if(p) p->Release(); } } resolved, memory;
    IDirect3DSurface9* source = back;
    if (desc.MultiSampleType != D3DMULTISAMPLE_NONE)
    {
        if (FAILED(device->CreateRenderTarget(desc.Width,desc.Height,desc.Format,D3DMULTISAMPLE_NONE,0,FALSE,&resolved.p,0)) ||
            FAILED(device->StretchRect(back,0,resolved.p,0,D3DTEXF_NONE)))
            throw std::runtime_error("UI capture: multisample resolve failed");
        source = resolved.p;
    }
    if (FAILED(device->CreateOffscreenPlainSurface(desc.Width,desc.Height,desc.Format,D3DPOOL_SYSTEMMEM,&memory.p,0)) ||
        FAILED(device->GetRenderTargetData(source,memory.p)))
        throw std::runtime_error("UI capture: readback failed");
    std::vector<unsigned char> pixels(static_cast<size_t>(desc.Width)*desc.Height*3);
    D3DLOCKED_RECT locked = {};
    if (FAILED(memory.p->LockRect(&locked,0,D3DLOCK_READONLY))) throw std::runtime_error("UI capture: lock failed");
    for (unsigned y=0;y<desc.Height;++y)
    {
        const unsigned char* src=static_cast<const unsigned char*>(locked.pBits)+static_cast<size_t>(y)*locked.Pitch;
        unsigned char* dst=pixels.data()+static_cast<size_t>(y)*desc.Width*3;
        for (unsigned x=0;x<desc.Width;++x) { *dst++=src[x*4+2]; *dst++=src[x*4+1]; *dst++=src[x*4]; }
    }
    memory.p->UnlockRect();
    cysCheckCaptureHeap("after-readback");
    if (GetEnvironmentVariableA("CYS_UI_CAPTURE_DIAGNOSTICS",0,0)) {
        const std::string rawName=std::string(filename)+".rgb";
        FILE* raw=std::fopen(rawName.c_str(),"wb");
        if (!raw) throw std::runtime_error("UI capture: diagnostic file open failed");
        const size_t written=std::fwrite(pixels.data(),1,pixels.size(),raw);
        std::fclose(raw);
        if (written!=pixels.size()) throw std::runtime_error("UI capture: diagnostic file write failed");
    }
    Ogre::Image image;
    image.loadDynamicImage(pixels.data(),desc.Width,desc.Height,Ogre::PF_BYTE_RGB);
    cysCheckCaptureHeap("before-save");
    image.save(filename);
    window->swapBuffers(false);
}
