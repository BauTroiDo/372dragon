// CYS-PERF (CY-Source): frame collector (see CysPerf.h and OgreMain/include/OgreCysPerf.h).
//
// One record per frame = the time between two Root::_fireFrameStarted calls, so the Game loop (logic tick,
// events, message pump, pacer wait) and the OGRE frame (listeners, controllers, culling, draw, Present) of the
// same period land in the same record. GPU times come from D3D9 timestamp queries read back a few frames
// later without flushing; rows wait for them in a short queue.
#include "CysPerf.h"

#include <OgreCysPerf.h>
#include <OgreRoot.h>
#include <OgreRenderWindow.h>
#include <OgreRenderSystem.h>
#include <OgreRenderTargetListener.h>
#include <OgreSceneManager.h>
#include <OgreParticleSystem.h>
#include <OgreLogManager.h>
#include <OgreMaterialManager.h>
#include <OgreTextureManager.h>
#include <OgreMeshManager.h>
#include <OgreSkeletonManager.h>
#include <OgreFrameListener.h>

#ifndef WIN32_LEAN_AND_MEAN
#   define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#   define NOMINMAX
#endif
#include <windows.h>
#include <d3d9.h>

#include <algorithm>
#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <deque>
#include <map>
#include <string>
#include <typeinfo>
#include <utility>
#include <vector>

namespace CYS
{
namespace Perf
{
namespace
{
    namespace P = Ogre::CysPerf;

    const char* const kPhaseNames[P::PH_COUNT] =
    {
        "msg", "wait", "tick", "input", "ui", "net", "world", "object", "script", "harness", "events", "render",
        "fstart", "build", "ctrl", "sanim", "graph", "cull", "anim", "draw", "uidraw", "present", "fend", "targets"
    };
    const char* const kCounterNames[P::C_COUNT] =
    {
        "draws", "prims", "tex", "vs", "ps", "rs", "ss", "decl", "stream", "index", "vsc", "psc",
        "scenes", "ents", "animdirty", "swskin", "animext", "built", "uirebuild", "uivbfill", "uiquads", "uibatches",
        "texload", "shadercreate", // CYS-PERF-C2
        "casterbuild", "caster_us", "variantbuild", "variant_us", "matload", "matload_us" // CYS-PERF-C3
    };
    static_assert(sizeof(kPhaseNames) / sizeof(kPhaseNames[0]) == P::PH_COUNT, "phase names");
    static_assert(sizeof(kCounterNames) / sizeof(kCounterNames[0]) == P::C_COUNT, "counter names");

    //-------------------------------------------------------------------------------------------------------
    std::string envString(const char* name)
    {
        char buffer[1024];
        const DWORD n = GetEnvironmentVariableA(name, buffer, sizeof(buffer));
        return (n && n < sizeof(buffer)) ? std::string(buffer, n) : std::string();
    }
    int envInt(const char* name, int fallback)
    {
        const std::string s = envString(name);
        return s.empty() ? fallback : atoi(s.c_str());
    }
    double envDouble(const char* name, double fallback)
    {
        const std::string s = envString(name);
        const double v = s.empty() ? 0.0 : atof(s.c_str());
        return v > 0.0 ? v : fallback;
    }
    void appendf(std::string& out, const char* format, ...)
    {
        char buffer[1024];
        va_list args;
        va_start(args, format);
        const int n = _vsnprintf_s(buffer, sizeof(buffer), _TRUNCATE, format, args);
        va_end(args);
        if (n > 0)
            out.append(buffer, size_t(n));
        else if (n < 0)
            out.append(buffer);
    }
    FILE* gPerfLog = 0;   // CYS_PERF_LOG: copy of the CYS-PERF lines (TlbbViewer writes no OGRE log file)
    void logLine(const std::string& line)
    {
        if (Ogre::LogManager::getSingletonPtr())
            Ogre::LogManager::getSingleton().logMessage(line);
        if (gPerfLog)
        {
            fputs(line.c_str(), gPerfLog);
            fputc('\n', gPerfLog);
            fflush(gPerfLog);
        }
    }
    double percentile(std::vector<float>& values, double q)
    {
        if (values.empty())
            return 0.0;
        size_t k = size_t(q * double(values.size() - 1) + 0.5);
        if (k >= values.size())
            k = values.size() - 1;
        std::nth_element(values.begin(), values.begin() + k, values.end());
        return values[k];
    }

    //-------------------------------------------------------------------------------------------------------
    // Heap allocation counting: the CRT heap imports (api-ms-win-crt-heap / ucrtbase) of the engine modules are
    // redirected to tiny thunks that count and jump on. The counters and thunks live in pages that are never
    // freed, so modules may keep calling them after this one unloads; nothing is ever un-patched.
    struct AllocName { const char* name; int variant; };
    const AllocName kAllocNames[] =
    {
        { "malloc", 0 }, { "_malloc_base", 0 }, { "_aligned_malloc", 0 },       // size in rcx
        { "realloc", 1 }, { "_realloc_base", 1 }, { "_aligned_realloc", 1 },    // size in rdx
        { "calloc", 2 }, { "_calloc_base", 2 }, { "_recalloc", 2 },             // counted only
        { "free", 3 }, { "_free_base", 3 }, { "_aligned_free", 3 },
    };
    const char* const kHookedModules[] =
    {
        "OgreMain.dll", "Render.dll", "RenderSystem_Direct3D9.dll", "Plugin_ParticleFX2.dll", "Plugin_Scorpio.dll",
        "Plugin_CgProgramManager.dll", "CEGUIBase.dll", "CEGUIFalagard.dll", "CEGUIOgreRenderer.dll",
        "UI_CEGUI.dll", "LuaPlus.dll", "PathLib.dll"
    };

    class AllocHooks
    {
    public:
        AllocHooks() : mCounters(0), mCode(0), mUsed(0), mImports(0) {}

        bool init(void)
        {
            if (mCounters)
                return true;
            mCounters = static_cast<volatile LONG64*>(
                VirtualAlloc(0, 4096, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE));
            mCode = static_cast<unsigned char*>(
                VirtualAlloc(0, kCodeBytes, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE));
            return mCounters && mCode;
        }

        /// Patches the engine modules loaded so far (each module once).
        void patchLoadedModules(void)
        {
            if (!mCounters || !mCode)
                return;
            patch(GetModuleHandleA(0));
            for (size_t i = 0; i < sizeof(kHookedModules) / sizeof(kHookedModules[0]); ++i)
                patch(GetModuleHandleA(kHookedModules[i]));
        }

        LONG64 allocs(void) const { return total(0); }
        LONG64 allocBytes(void) const { return total(1); }
        LONG64 frees(void) const { return total(2); }
        size_t modules(void) const { return mPatched.size(); }
        size_t imports(void) const { return mImports; }

        /// Allocations so far of every patched module (module file name, count).
        void perModule(std::vector<std::pair<std::string, LONG64> >& out) const
        {
            out.clear();
            for (size_t m = 0; mCounters && m < mNames.size() && m < kMaxModules; ++m)
                out.push_back(std::make_pair(mNames[m], LONG64(mCounters[m * 4])));
        }

    private:
        enum { kMaxModules = 64, kCodeBytes = 8192 };   // counters: 4 LONG64 per module in one 4 KB page

        LONG64 total(int k) const
        {
            LONG64 sum = 0;
            for (size_t m = 0; mCounters && m < mPatched.size() && m < kMaxModules; ++m)
                sum += mCounters[m * 4 + k];
            return sum;
        }

        void* thunk(void* target, int variant, size_t slot)
        {
            const std::pair<void*, int> key(target, variant + 16 * int(slot));
            std::map<std::pair<void*, int>, void*>::const_iterator found = mThunks.find(key);
            if (found != mThunks.end())
                return found->second;
            if (mUsed + 32 > kCodeBytes || slot >= kMaxModules)
                return 0;
            unsigned char* start = mCode + mUsed;
            unsigned char* p = start;
            const ULONG64 counter = reinterpret_cast<ULONG64>(variant == 3 ? &mCounters[slot * 4 + 2] : &mCounters[slot * 4]);
            *p++ = 0x48; *p++ = 0xB8; memcpy(p, &counter, 8); p += 8;              // mov rax, counter
            *p++ = 0xF0; *p++ = 0x48; *p++ = 0xFF; *p++ = 0x00;                    // lock inc qword [rax]
            if (variant == 0)
            {
                *p++ = 0xF0; *p++ = 0x48; *p++ = 0x01; *p++ = 0x48; *p++ = 0x08;   // lock add [rax+8], rcx
            }
            else if (variant == 1)
            {
                *p++ = 0xF0; *p++ = 0x48; *p++ = 0x01; *p++ = 0x50; *p++ = 0x08;   // lock add [rax+8], rdx
            }
            const ULONG64 jump = reinterpret_cast<ULONG64>(target);
            *p++ = 0x48; *p++ = 0xB8; memcpy(p, &jump, 8); p += 8;                 // mov rax, target
            *p++ = 0xFF; *p++ = 0xE0;                                              // jmp rax
            mUsed += 32;
            FlushInstructionCache(GetCurrentProcess(), start, 32);
            mThunks[key] = start;
            return start;
        }

        void patch(HMODULE module)
        {
            if (!module || std::find(mPatched.begin(), mPatched.end(), module) != mPatched.end())
                return;
            const size_t slot = mPatched.size();
            mPatched.push_back(module);
            char path[MAX_PATH] = { 0 };
            GetModuleFileNameA(module, path, MAX_PATH);
            const char* baseName = strrchr(path, '\\');
            mNames.push_back(baseName ? baseName + 1 : path);
            unsigned char* base = reinterpret_cast<unsigned char*>(module);
            const IMAGE_DOS_HEADER* dos = reinterpret_cast<const IMAGE_DOS_HEADER*>(base);
            if (dos->e_magic != IMAGE_DOS_SIGNATURE)
                return;
            const IMAGE_NT_HEADERS* nt = reinterpret_cast<const IMAGE_NT_HEADERS*>(base + dos->e_lfanew);
            if (nt->Signature != IMAGE_NT_SIGNATURE)
                return;
            const IMAGE_DATA_DIRECTORY& dir = nt->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT];
            if (!dir.VirtualAddress || !dir.Size)
                return;
            for (const IMAGE_IMPORT_DESCRIPTOR* d =
                     reinterpret_cast<const IMAGE_IMPORT_DESCRIPTOR*>(base + dir.VirtualAddress); d->Name; ++d)
            {
                const char* dll = reinterpret_cast<const char*>(base + d->Name);
                if (_stricmp(dll, "api-ms-win-crt-heap-l1-1-0.dll") != 0 && _stricmp(dll, "ucrtbase.dll") != 0)
                    continue;
                if (!d->OriginalFirstThunk || !d->FirstThunk)
                    continue;
                const IMAGE_THUNK_DATA* names = reinterpret_cast<const IMAGE_THUNK_DATA*>(base + d->OriginalFirstThunk);
                IMAGE_THUNK_DATA* slots = reinterpret_cast<IMAGE_THUNK_DATA*>(base + d->FirstThunk);
                for (; names->u1.AddressOfData; ++names, ++slots)
                {
                    if (IMAGE_SNAP_BY_ORDINAL(names->u1.Ordinal))
                        continue;
                    const IMAGE_IMPORT_BY_NAME* byName =
                        reinterpret_cast<const IMAGE_IMPORT_BY_NAME*>(base + names->u1.AddressOfData);
                    int variant = -1;
                    for (size_t i = 0; i < sizeof(kAllocNames) / sizeof(kAllocNames[0]); ++i)
                    {
                        if (strcmp(reinterpret_cast<const char*>(byName->Name), kAllocNames[i].name) == 0)
                        {
                            variant = kAllocNames[i].variant;
                            break;
                        }
                    }
                    if (variant < 0)
                        continue;
                    void* stub = thunk(reinterpret_cast<void*>(slots->u1.Function), variant, slot);
                    if (!stub)
                        return;
                    DWORD old = 0;
                    if (VirtualProtect(&slots->u1.Function, sizeof(slots->u1.Function), PAGE_READWRITE, &old))
                    {
                        slots->u1.Function = reinterpret_cast<ULONG_PTR>(stub);
                        VirtualProtect(&slots->u1.Function, sizeof(slots->u1.Function), old, &old);
                        ++mImports;
                    }
                }
            }
        }

        volatile LONG64* mCounters;   // per module: [0] allocations, [1] allocated bytes (sized calls), [2] frees
        unsigned char* mCode;
        size_t mUsed;
        size_t mImports;
        std::map<std::pair<void*, int>, void*> mThunks;
        std::vector<HMODULE> mPatched;
        std::vector<std::string> mNames;
    };

    //-------------------------------------------------------------------------------------------------------
    // Optional on-screen text: a GDI-rendered ASCII atlas in a managed texture, drawn with pre-transformed
    // vertices after the main window update. No default-pool resource, so device resets need no handling.
    class Overlay
    {
    public:
        Overlay() : mTexture(0), mScale(1), mFailed(false) {}
        ~Overlay() { release(); }

        void release(void)
        {
            if (mTexture)
                mTexture->Release();
            mTexture = 0;
        }

        void draw(IDirect3DDevice9* device, const std::string& text, int scale)
        {
            if (!device || text.empty() || mFailed)
                return;
            if (!mTexture && !create(device))
            {
                mFailed = true;
                return;
            }
            mScale = scale < 1 ? 1 : scale;

            struct Vertex { float x, y, z, rhw; DWORD colour; float u, v; };
            std::vector<Vertex> glyphs;
            glyphs.reserve(text.size() * 6);
            const float cw = float(kCellW * mScale), ch = float(kCellH * mScale);
            const float x0 = 8.0f, y0 = 8.0f;
            int line = 0, column = 0, widest = 0;
            for (size_t i = 0; i < text.size(); ++i)
            {
                const unsigned char c = static_cast<unsigned char>(text[i]);
                if (c == '\n')
                {
                    ++line;
                    column = 0;
                    continue;
                }
                if (c > 32 && c < 128)
                {
                    const int cell = c - 32;
                    const float u0 = float((cell % kCols) * kCellW) / kTexW, v0 = float((cell / kCols) * kCellH) / kTexH;
                    const float u1 = u0 + float(kCellW) / kTexW, v1 = v0 + float(kCellH) / kTexH;
                    const float x = x0 + column * cw - 0.5f, y = y0 + line * ch - 0.5f;
                    const Vertex quad[6] =
                    {
                        { x, y, 0, 1, 0xFFFFFF60, u0, v0 }, { x + cw, y, 0, 1, 0xFFFFFF60, u1, v0 },
                        { x, y + ch, 0, 1, 0xFFFFFF60, u0, v1 }, { x + cw, y, 0, 1, 0xFFFFFF60, u1, v0 },
                        { x + cw, y + ch, 0, 1, 0xFFFFFF60, u1, v1 }, { x, y + ch, 0, 1, 0xFFFFFF60, u0, v1 },
                    };
                    glyphs.insert(glyphs.end(), quad, quad + 6);
                }
                ++column;
                widest = std::max(widest, column);
            }
            if (glyphs.empty())
                return;
            const float bw = widest * cw + 8.0f, bh = (line + 1) * ch + 8.0f;
            const Vertex back[6] =
            {
                { x0 - 4.5f, y0 - 4.5f, 0, 1, 0xB0000000, 0, 0 }, { x0 - 4.5f + bw, y0 - 4.5f, 0, 1, 0xB0000000, 0, 0 },
                { x0 - 4.5f, y0 - 4.5f + bh, 0, 1, 0xB0000000, 0, 0 }, { x0 - 4.5f + bw, y0 - 4.5f, 0, 1, 0xB0000000, 0, 0 },
                { x0 - 4.5f + bw, y0 - 4.5f + bh, 0, 1, 0xB0000000, 0, 0 }, { x0 - 4.5f, y0 - 4.5f + bh, 0, 1, 0xB0000000, 0, 0 },
            };

            // Save what we touch. OGRE reads render/stage/sampler states back from the device before changing
            // them, but caches the texture of stage 0 and the bound programs, so those are restored exactly.
            static const D3DRENDERSTATETYPE kStates[] =
            {
                D3DRS_ZENABLE, D3DRS_ZWRITEENABLE, D3DRS_ALPHABLENDENABLE, D3DRS_SRCBLEND, D3DRS_DESTBLEND,
                D3DRS_BLENDOP, D3DRS_CULLMODE, D3DRS_LIGHTING, D3DRS_FOGENABLE, D3DRS_ALPHATESTENABLE,
                D3DRS_STENCILENABLE, D3DRS_SCISSORTESTENABLE, D3DRS_COLORWRITEENABLE, D3DRS_SRGBWRITEENABLE,
                D3DRS_FILLMODE, D3DRS_CLIPPLANEENABLE, D3DRS_SEPARATEALPHABLENDENABLE
            };
            const size_t stateCount = sizeof(kStates) / sizeof(kStates[0]);
            DWORD states[sizeof(kStates) / sizeof(kStates[0])];
            for (size_t i = 0; i < stateCount; ++i)
                device->GetRenderState(kStates[i], &states[i]);
            static const D3DTEXTURESTAGESTATETYPE kStage0[] =
            {
                D3DTSS_COLOROP, D3DTSS_COLORARG1, D3DTSS_COLORARG2, D3DTSS_ALPHAOP, D3DTSS_ALPHAARG1,
                D3DTSS_ALPHAARG2, D3DTSS_TEXCOORDINDEX, D3DTSS_TEXTURETRANSFORMFLAGS
            };
            const size_t stageCount = sizeof(kStage0) / sizeof(kStage0[0]);
            DWORD stage0[sizeof(kStage0) / sizeof(kStage0[0])];
            for (size_t i = 0; i < stageCount; ++i)
                device->GetTextureStageState(0, kStage0[i], &stage0[i]);
            DWORD stage1Colour = 0, stage1Alpha = 0;
            device->GetTextureStageState(1, D3DTSS_COLOROP, &stage1Colour);
            device->GetTextureStageState(1, D3DTSS_ALPHAOP, &stage1Alpha);
            static const D3DSAMPLERSTATETYPE kSampler[] =
            {
                D3DSAMP_MINFILTER, D3DSAMP_MAGFILTER, D3DSAMP_MIPFILTER, D3DSAMP_ADDRESSU, D3DSAMP_ADDRESSV,
                D3DSAMP_SRGBTEXTURE
            };
            const size_t samplerCount = sizeof(kSampler) / sizeof(kSampler[0]);
            DWORD sampler[sizeof(kSampler) / sizeof(kSampler[0])];
            for (size_t i = 0; i < samplerCount; ++i)
                device->GetSamplerState(0, kSampler[i], &sampler[i]);
            IDirect3DVertexShader9* vs = 0;
            IDirect3DPixelShader9* ps = 0;
            IDirect3DBaseTexture9* texture0 = 0;
            IDirect3DVertexDeclaration9* declaration = 0;
            DWORD fvf = 0;
            D3DVIEWPORT9 viewport;
            device->GetVertexShader(&vs);
            device->GetPixelShader(&ps);
            device->GetTexture(0, &texture0);
            device->GetVertexDeclaration(&declaration);
            device->GetFVF(&fvf);
            device->GetViewport(&viewport);

            if (SUCCEEDED(device->BeginScene()))
            {
                IDirect3DSurface9* backBuffer = 0;
                if (SUCCEEDED(device->GetRenderTarget(0, &backBuffer)) && backBuffer)
                {
                    D3DSURFACE_DESC desc;
                    backBuffer->GetDesc(&desc);
                    backBuffer->Release();
                    D3DVIEWPORT9 full = { 0, 0, desc.Width, desc.Height, 0.0f, 1.0f };
                    device->SetViewport(&full);
                }
                device->SetVertexShader(0);
                device->SetPixelShader(0);
                device->SetFVF(D3DFVF_XYZRHW | D3DFVF_DIFFUSE | D3DFVF_TEX1);
                device->SetRenderState(D3DRS_ZENABLE, D3DZB_FALSE);
                device->SetRenderState(D3DRS_ZWRITEENABLE, FALSE);
                device->SetRenderState(D3DRS_ALPHABLENDENABLE, TRUE);
                device->SetRenderState(D3DRS_SRCBLEND, D3DBLEND_SRCALPHA);
                device->SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA);
                device->SetRenderState(D3DRS_BLENDOP, D3DBLENDOP_ADD);
                device->SetRenderState(D3DRS_CULLMODE, D3DCULL_NONE);
                device->SetRenderState(D3DRS_LIGHTING, FALSE);
                device->SetRenderState(D3DRS_FOGENABLE, FALSE);
                device->SetRenderState(D3DRS_ALPHATESTENABLE, FALSE);
                device->SetRenderState(D3DRS_STENCILENABLE, FALSE);
                device->SetRenderState(D3DRS_SCISSORTESTENABLE, FALSE);
                device->SetRenderState(D3DRS_COLORWRITEENABLE, 0xF);
                device->SetRenderState(D3DRS_SRGBWRITEENABLE, FALSE);
                device->SetRenderState(D3DRS_FILLMODE, D3DFILL_SOLID);
                device->SetRenderState(D3DRS_CLIPPLANEENABLE, 0);
                device->SetRenderState(D3DRS_SEPARATEALPHABLENDENABLE, FALSE);
                device->SetTextureStageState(0, D3DTSS_TEXCOORDINDEX, 0);
                device->SetTextureStageState(0, D3DTSS_TEXTURETRANSFORMFLAGS, D3DTTFF_DISABLE);
                device->SetTextureStageState(1, D3DTSS_COLOROP, D3DTOP_DISABLE);
                device->SetTextureStageState(1, D3DTSS_ALPHAOP, D3DTOP_DISABLE);
                device->SetSamplerState(0, D3DSAMP_MINFILTER, D3DTEXF_POINT);
                device->SetSamplerState(0, D3DSAMP_MAGFILTER, D3DTEXF_POINT);
                device->SetSamplerState(0, D3DSAMP_MIPFILTER, D3DTEXF_NONE);
                device->SetSamplerState(0, D3DSAMP_ADDRESSU, D3DTADDRESS_CLAMP);
                device->SetSamplerState(0, D3DSAMP_ADDRESSV, D3DTADDRESS_CLAMP);
                device->SetSamplerState(0, D3DSAMP_SRGBTEXTURE, FALSE);

                // background: diffuse only
                device->SetTexture(0, 0);
                device->SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG1);
                device->SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_DIFFUSE);
                device->SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1);
                device->SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_DIFFUSE);
                device->DrawPrimitiveUP(D3DPT_TRIANGLELIST, 2, back, sizeof(Vertex));
                // glyphs: texture alpha x diffuse
                device->SetTexture(0, mTexture);
                device->SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
                device->SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
                device->SetTextureStageState(0, D3DTSS_COLORARG2, D3DTA_DIFFUSE);
                device->SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
                device->SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
                device->SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE);
                device->DrawPrimitiveUP(D3DPT_TRIANGLELIST, UINT(glyphs.size() / 3), &glyphs[0], sizeof(Vertex));
                device->EndScene();
            }

            for (size_t i = 0; i < stateCount; ++i)
                device->SetRenderState(kStates[i], states[i]);
            for (size_t i = 0; i < stageCount; ++i)
                device->SetTextureStageState(0, kStage0[i], stage0[i]);
            device->SetTextureStageState(1, D3DTSS_COLOROP, stage1Colour);
            device->SetTextureStageState(1, D3DTSS_ALPHAOP, stage1Alpha);
            for (size_t i = 0; i < samplerCount; ++i)
                device->SetSamplerState(0, kSampler[i], sampler[i]);
            device->SetTexture(0, texture0);
            device->SetVertexShader(vs);
            device->SetPixelShader(ps);
            if (declaration)
                device->SetVertexDeclaration(declaration);
            else
                device->SetFVF(fvf);
            device->SetViewport(&viewport);
            if (texture0) texture0->Release();
            if (vs) vs->Release();
            if (ps) ps->Release();
            if (declaration) declaration->Release();
        }

    private:
        enum { kCols = 16, kRows = 6, kCellW = 8, kCellH = 16, kTexW = 128, kTexH = 128 };

        bool create(IDirect3DDevice9* device)
        {
            const int bmpW = kCols * kCellW, bmpH = kRows * kCellH;
            BITMAPINFO info;
            memset(&info, 0, sizeof(info));
            info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
            info.bmiHeader.biWidth = bmpW;
            info.bmiHeader.biHeight = -bmpH;
            info.bmiHeader.biPlanes = 1;
            info.bmiHeader.biBitCount = 32;
            info.bmiHeader.biCompression = BI_RGB;
            void* bits = 0;
            HDC dc = CreateCompatibleDC(0);
            if (!dc)
                return false;
            HBITMAP bitmap = CreateDIBSection(dc, &info, DIB_RGB_COLORS, &bits, 0, 0);
            HFONT font = CreateFontW(-13, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE, ANSI_CHARSET, OUT_DEFAULT_PRECIS,
                                     CLIP_DEFAULT_PRECIS, ANTIALIASED_QUALITY, FIXED_PITCH | FF_MODERN, L"Consolas");
            bool ok = bitmap && bits && font;
            if (ok)
            {
                HGDIOBJ oldBitmap = SelectObject(dc, bitmap);
                HGDIOBJ oldFont = SelectObject(dc, font);
                memset(bits, 0, size_t(bmpW) * bmpH * 4);
                SetBkMode(dc, TRANSPARENT);
                SetTextColor(dc, RGB(255, 255, 255));
                for (int c = 33; c < 128; ++c)
                {
                    const wchar_t glyph = wchar_t(c);
                    const int cell = c - 32;
                    TextOutW(dc, (cell % kCols) * kCellW, (cell / kCols) * kCellH, &glyph, 1);
                }
                GdiFlush();
                ok = SUCCEEDED(device->CreateTexture(kTexW, kTexH, 1, 0, D3DFMT_A8R8G8B8, D3DPOOL_MANAGED, &mTexture, 0));
                D3DLOCKED_RECT locked;
                if (ok && SUCCEEDED(mTexture->LockRect(0, &locked, 0, 0)))
                {
                    const DWORD* src = static_cast<const DWORD*>(bits);
                    for (int y = 0; y < kTexH; ++y)
                    {
                        DWORD* row = reinterpret_cast<DWORD*>(static_cast<unsigned char*>(locked.pBits) + y * locked.Pitch);
                        for (int x = 0; x < kTexW; ++x)
                        {
                            DWORD alpha = 0;
                            if (x < bmpW && y < bmpH)
                            {
                                const DWORD p = src[y * bmpW + x];
                                alpha = std::max(std::max(p & 0xFF, (p >> 8) & 0xFF), (p >> 16) & 0xFF);
                            }
                            row[x] = (alpha << 24) | 0x00FFFFFF;
                        }
                    }
                    mTexture->UnlockRect(0);
                }
                else
                {
                    ok = false;
                }
                SelectObject(dc, oldFont);
                SelectObject(dc, oldBitmap);
            }
            if (font) DeleteObject(font);
            if (bitmap) DeleteObject(bitmap);
            DeleteDC(dc);
            if (!ok)
                release();
            return ok;
        }

        IDirect3DTexture9* mTexture;
        int mScale;
        bool mFailed;
    };

    //-------------------------------------------------------------------------------------------------------
    struct FrameRec
    {
        unsigned long long index;
        double startMs;
        double frameMs;
        float phase[P::PH_COUNT];
        unsigned long long counter[P::C_COUNT];
        long long allocs, allocBytes, frees;
        float gpuFrame, gpuWindow, gpuTarget, gpuUi;   // -1 = unknown
        unsigned targetUpdates;
        bool gpuResolved;
    };

    struct Interval
    {
        std::vector<float> frames;
        double phase[P::PH_COUNT];
        double counter[P::C_COUNT];
        double gpu[4];
        unsigned gpuFrames;
        double allocs, allocBytes, frees, targetUpdates;
        double startMs;

        void reset(double start)
        {
            frames.clear();
            memset(phase, 0, sizeof(phase));
            memset(counter, 0, sizeof(counter));
            memset(gpu, 0, sizeof(gpu));
            gpuFrames = 0;
            allocs = allocBytes = frees = targetUpdates = 0;
            startMs = start;
        }
    };

    struct ListenerStat
    {
        std::string name;
        long long intervalTicks;
        long long totalTicks;
    };

    struct Segment
    {
        std::string label;
        size_t firstFrame;   // index into mAllFrames
        double startMs;
    };

    enum { kGpuRing = 6, kMaxMarks = 64 };

    struct GpuSet
    {
        IDirect3DQuery9* disjoint;
        IDirect3DQuery9* frequency;
        IDirect3DQuery9* stamps[kMaxMarks];
        int ids[kMaxMarks];
        int count;
        bool open;
        bool pending;
        unsigned long long frame;
    };

    //-------------------------------------------------------------------------------------------------------
    class Collector : public Ogre::RenderTargetListener, public Ogre::RenderSystem::Listener
    {
    public:
        Collector(Ogre::Root* root, Ogre::RenderWindow* window, Ogre::SceneManager* sceneManager)
            : mRoot(root), mWindow(window), mSceneManager(sceneManager), mDevice(0)
            , mIntervalMs(1000.0 * envDouble("CYS_PERF_INTERVAL", 2.0))
            , mWantGpu(envInt("CYS_PERF_GPU", 1) != 0)
            , mWantAlloc(envInt("CYS_PERF_ALLOC", 1) != 0)
            , mOverlayScale(envInt("CYS_PERF_OVERLAY", 0))
            , mListenerTiming(envInt("CYS_PERF_LISTENERS", 1) != 0)
            , mCsv(0), mStart(P::ticks()), mLastBegin(0), mFrameIndex(0), mFreq(double(P::ticksPerSecond()))
            , mLastAllocs(0), mLastAllocBytes(0), mLastFrees(0), mTargetUpdates(0), mSelfTicks(0)
            , mGpuActive(false), mGpuFailed(false), mGpuSuspended(false), mGpuCurrent(-1), mGpuNext(0)
            , mLastMaterials(0), mLastTextures(0)
        {
            memset(mSets, 0, sizeof(mSets));
            mInterval.reset(0.0);
        }

        ~Collector()
        {
            gpuRelease();
            mOverlay.release();
            if (mCsv)
                fclose(mCsv);
        }

        void start(void)
        {
            if (mWantAlloc && mAlloc.init())
                mAlloc.patchLoadedModules();
            mLastAllocs = mAlloc.allocs();
            mLastAllocBytes = mAlloc.allocBytes();
            mLastFrees = mAlloc.frees();

            const std::string csv = envString("CYS_PERF_CSV");
            if (!csv.empty())
            {
                if (fopen_s(&mCsv, csv.c_str(), "w") != 0)
                    mCsv = 0;
                if (mCsv)
                {
                    setvbuf(mCsv, 0, _IOFBF, 1 << 16);
                    std::string header = "frame,t_ms,frame_ms";
                    for (int i = 0; i < P::PH_COUNT; ++i)
                        appendf(header, ",cpu_%s_ms", kPhaseNames[i]);
                    header += ",gpu_frame_ms,gpu_window_ms,gpu_rtt_ms,gpu_ui_ms";
                    for (int i = 0; i < P::C_COUNT; ++i)
                        appendf(header, ",%s", kCounterNames[i]);
                    header += ",rtt_updates,allocs,alloc_bytes,frees\n";
                    fputs(header.c_str(), mCsv);
                }
            }

            describe();
            if (mRoot && mRoot->getRenderSystem())
                mRoot->getRenderSystem()->addListener(this);
        }

        void finish(void)
        {
            while (!mPending.empty())
                flushFront();
            std::string line;
            appendSummary(line, "summary all", 0, mAllFrames.size(), mAllFrames.empty() ? 0.0 : 0.0);
            logLine(line);
            for (size_t s = 0; s < mSegments.size(); ++s)
            {
                const size_t end = (s + 1 < mSegments.size()) ? mSegments[s + 1].firstFrame : mAllFrames.size();
                line.clear();
                appendSummary(line, ("segment " + mSegments[s].label).c_str(), mSegments[s].firstFrame, end,
                              mSegments[s].startMs);
                logLine(line);
            }
            if (!mListeners.empty())
            {
                std::vector<std::pair<long long, std::string> > top;
                for (std::map<const void*, ListenerStat>::const_iterator it = mListeners.begin(); it != mListeners.end(); ++it)
                    top.push_back(std::make_pair(it->second.totalTicks, it->second.name));
                std::sort(top.rbegin(), top.rend());
                line = "CYS-PERF listeners (total ms):";
                for (size_t i = 0; i < top.size() && i < 12; ++i)
                    appendf(line, " %s=%.1f", top[i].second.c_str(), 1000.0 * double(top[i].first) / mFreq);
                logLine(line);
            }
            if (mCsv)
                fflush(mCsv);
        }

        void detach(void)
        {
            if (mRoot && mRoot->getRenderSystem())
            {
                Ogre::RenderSystem* rs = mRoot->getRenderSystem();
                rs->removeListener(this);
                Ogre::RenderSystem::RenderTargetIterator it = rs->getRenderTargetIterator();
                while (it.hasMoreElements())
                {
                    const Ogre::String name = it.peekNextKey();
                    Ogre::RenderTarget* target = it.getNext();
                    std::map<Ogre::String, Ogre::RenderTarget*>::const_iterator a = mAttached.find(name);
                    if (a != mAttached.end() && a->second == target)
                        target->removeListener(this);
                }
            }
            mAttached.clear();
            gpuRelease();
            mOverlay.release();
        }

        //---------------------------------------------------------------------------------------------------
        void frameBegin(void)
        {
            const long long now = P::ticks();
            if (mLastBegin)
            {
                FrameRec rec;
                memset(&rec, 0, sizeof(rec));
                rec.index = mFrameIndex;
                rec.startMs = ms(mLastBegin - mStart);
                rec.frameMs = ms(now - mLastBegin);
                for (int i = 0; i < P::PH_COUNT; ++i)
                    rec.phase[i] = float(ms(P::gBlock.phaseTicks[i]));
                for (int i = 0; i < P::C_COUNT; ++i)
                    rec.counter[i] = P::gBlock.counters[i];
                const LONG64 allocs = mAlloc.allocs(), bytes = mAlloc.allocBytes(), frees = mAlloc.frees();
                rec.allocs = allocs - mLastAllocs;
                rec.allocBytes = bytes - mLastAllocBytes;
                rec.frees = frees - mLastFrees;
                mLastAllocs = allocs;
                mLastAllocBytes = bytes;
                mLastFrees = frees;
                rec.gpuFrame = rec.gpuWindow = rec.gpuTarget = rec.gpuUi = -1.0f;
                rec.targetUpdates = mTargetUpdates;
                rec.gpuResolved = !(mGpuActive && mGpuCurrent >= 0 && mSets[mGpuCurrent].frame == mFrameIndex);
                mPending.push_back(rec);
                ++mFrameIndex;
            }
            else
            {
                // First boundary: engine and resource initialisation since install() are not frame 0's work.
                mLastAllocs = mAlloc.allocs();
                mLastAllocBytes = mAlloc.allocBytes();
                mLastFrees = mAlloc.frees();
            }
            memset(const_cast<long long*>(P::gBlock.phaseTicks), 0, sizeof(P::gBlock.phaseTicks));
            memset(const_cast<unsigned int*>(P::gBlock.phaseCalls), 0, sizeof(P::gBlock.phaseCalls));
            memset(const_cast<unsigned long long*>(P::gBlock.counters), 0, sizeof(P::gBlock.counters));
            mTargetUpdates = 0;
            mLastBegin = now;

            gpuFrameBoundary();
            while (!mPending.empty() && (mPending.front().gpuResolved || mPending.size() > kGpuRing + 2))
                flushFront();
            attachTargets();
            mSelfTicks += P::ticks() - now;   // the collector's own cost, reported as "self"
        }

        void gpuMark(int marker)
        {
            if (!mGpuActive || mGpuCurrent < 0)
                return;
            GpuSet& g = mSets[mGpuCurrent];
            if (!g.open || g.count >= kMaxMarks)
                return;
            if (FAILED(g.stamps[g.count]->Issue(D3DISSUE_END)))
                return;
            g.ids[g.count++] = marker;
            if (marker == P::MK_PRESENT)
                gpuClose(mGpuCurrent);
        }

        void mark(const char* label)
        {
            const std::string text = label ? label : "";
            char row[512];
            _snprintf_s(row, sizeof(row), _TRUNCATE, "#mark,%llu,%.3f,%s\n", mFrameIndex,
                        ms(P::ticks() - mStart), text.c_str());
            mMarkRows.push_back(std::make_pair(mFrameIndex, std::string(row)));
            std::string line;
            appendf(line, "CYS-PERF mark frame=%llu t=%.3f s %s", mFrameIndex, ms(P::ticks() - mStart) / 1000.0,
                    text.c_str());
            logLine(line);
            Segment segment;
            segment.label = text;
            segment.firstFrame = mAllFrames.size() + mPending.size();
            segment.startMs = ms(P::ticks() - mStart);
            mSegments.push_back(segment);
        }

        void listenerTime(const void* listener, int ended, long long ticks)
        {
            (void)ended;
            if (!mListenerTiming)
                return;
            std::map<const void*, ListenerStat>::iterator it = mListeners.find(listener);
            if (it == mListeners.end())
            {
                ListenerStat stat;
                stat.intervalTicks = stat.totalTicks = 0;
                try
                {
                    stat.name = typeid(*static_cast<const Ogre::FrameListener*>(listener)).name();
                }
                catch (...)
                {
                    stat.name = "?";
                }
                if (stat.name.compare(0, 6, "class ") == 0)
                    stat.name.erase(0, 6);
                it = mListeners.insert(std::make_pair(listener, stat)).first;
            }
            it->second.intervalTicks += ticks;
            it->second.totalTicks += ticks;
        }

        // Ogre::RenderTargetListener
        void preRenderTargetUpdate(const Ogre::RenderTargetEvent& evt)
        {
            if (evt.source == mWindow)
                gpuMark(P::MK_WINDOW_BEGIN);
            else
            {
                gpuMark(P::MK_TARGET_BEGIN);
                ++mTargetUpdates;
            }
        }
        void postRenderTargetUpdate(const Ogre::RenderTargetEvent& evt)
        {
            if (evt.source == mWindow)
            {
                gpuMark(P::MK_WINDOW_END);
                if (mOverlayScale > 0 && device())
                    mOverlay.draw(mDevice, mOverlayText, mOverlayScale);
            }
            else
                gpuMark(P::MK_TARGET_END);
        }

        // Ogre::RenderSystem::Listener
        void eventOccurred(const Ogre::String& eventName, const Ogre::NameValuePairList* parameters)
        {
            (void)parameters;
            if (eventName == "DeviceLost")
            {
                gpuRelease();
                mGpuSuspended = true;
                logLine("CYS-PERF: device lost, GPU timing suspended");
            }
            else if (eventName == "DeviceRestored")
            {
                mGpuSuspended = false;
                logLine("CYS-PERF: device restored");
            }
        }

    private:
        double ms(long long ticks) const { return 1000.0 * double(ticks) / mFreq; }

        IDirect3DDevice9* device(void)
        {
            if (!mDevice && mWindow)
                mWindow->getCustomAttribute("D3DDEVICE", &mDevice);
            return mDevice;
        }

        void describe(void)
        {
            std::string line = "CYS-PERF install:";
            if (mWindow)
                appendf(line, " window=%ux%u", mWindow->getWidth(), mWindow->getHeight());
            if (mRoot && mRoot->getRenderSystem())
                appendf(line, " rs=\"%s\" vsync=%d", mRoot->getRenderSystem()->getName().c_str(),
                        mRoot->getRenderSystem()->getWaitForVerticalBlank() ? 1 : 0);
            if (mSceneManager)
                appendf(line, " scene_manager=%s(%s)", mSceneManager->getTypeName().c_str(),
                        mSceneManager->getName().c_str());
            appendf(line, " interval=%.1fs gpu=%d alloc=%d(modules=%u imports=%u) overlay=%d listeners=%d csv=%s",
                    mIntervalMs / 1000.0, mWantGpu ? 1 : 0, mWantAlloc ? 1 : 0, unsigned(mAlloc.modules()),
                    unsigned(mAlloc.imports()), mOverlayScale, mListenerTiming ? 1 : 0, mCsv ? "on" : "off");
            logLine(line);

            IDirect3DDevice9* dev = device();
            if (!dev)
                return;
            line = "CYS-PERF device:";
            D3DDEVICE_CREATION_PARAMETERS cp;
            if (SUCCEEDED(dev->GetCreationParameters(&cp)))
            {
                const DWORD b = cp.BehaviorFlags;
                appendf(line, " adapter=%u type=%s vp=%s pure=%d fpu_preserve=%d multithreaded=%d",
                        cp.AdapterOrdinal, cp.DeviceType == D3DDEVTYPE_HAL ? "HAL" : "other",
                        (b & D3DCREATE_HARDWARE_VERTEXPROCESSING) ? "hardware" :
                        (b & D3DCREATE_MIXED_VERTEXPROCESSING) ? "mixed" : "software",
                        (b & D3DCREATE_PUREDEVICE) ? 1 : 0, (b & D3DCREATE_FPU_PRESERVE) ? 1 : 0,
                        (b & D3DCREATE_MULTITHREADED) ? 1 : 0);
                IDirect3D9* d3d = 0;
                if (SUCCEEDED(dev->GetDirect3D(&d3d)) && d3d)
                {
                    D3DADAPTER_IDENTIFIER9 id;
                    if (SUCCEEDED(d3d->GetAdapterIdentifier(cp.AdapterOrdinal, 0, &id)))
                        appendf(line, " gpu=\"%s\"", id.Description);
                    d3d->Release();
                }
            }
            IDirect3DSwapChain9* chain = 0;
            if (SUCCEEDED(dev->GetSwapChain(0, &chain)) && chain)
            {
                D3DPRESENT_PARAMETERS pp;
                if (SUCCEEDED(chain->GetPresentParameters(&pp)))
                    appendf(line, " backbuffer=%ux%u fmt=%d count=%u swap=%d interval=%s msaa=%d windowed=%d depth_fmt=%d",
                            pp.BackBufferWidth, pp.BackBufferHeight, int(pp.BackBufferFormat), pp.BackBufferCount,
                            int(pp.SwapEffect), pp.PresentationInterval == D3DPRESENT_INTERVAL_IMMEDIATE ? "immediate" :
                            pp.PresentationInterval == D3DPRESENT_INTERVAL_ONE ? "one" : "other",
                            int(pp.MultiSampleType), pp.Windowed ? 1 : 0, int(pp.AutoDepthStencilFormat));
                chain->Release();
            }
            logLine(line);
        }

        void attachTargets(void)
        {
            if (!mRoot || !mRoot->getRenderSystem())
                return;
            std::map<Ogre::String, Ogre::RenderTarget*> seen;
            Ogre::RenderSystem::RenderTargetIterator it = mRoot->getRenderSystem()->getRenderTargetIterator();
            while (it.hasMoreElements())
            {
                const Ogre::String name = it.peekNextKey();
                Ogre::RenderTarget* target = it.getNext();
                std::map<Ogre::String, Ogre::RenderTarget*>::const_iterator a = mAttached.find(name);
                if (a == mAttached.end() || a->second != target)
                    target->addListener(this);
                seen[name] = target;
            }
            mAttached.swap(seen);
        }

        //---------------------------------------------------------------------------------------------------
        // GPU timestamps
        bool gpuInit(void)
        {
            if (!mWantGpu || mGpuFailed || mGpuSuspended)
                return false;
            IDirect3DDevice9* dev = device();
            if (!dev)
            {
                mGpuFailed = true;
                return false;
            }
            memset(mSets, 0, sizeof(mSets));
            for (int s = 0; s < kGpuRing; ++s)
            {
                GpuSet& g = mSets[s];
                bool ok = SUCCEEDED(dev->CreateQuery(D3DQUERYTYPE_TIMESTAMPDISJOINT, &g.disjoint)) &&
                          SUCCEEDED(dev->CreateQuery(D3DQUERYTYPE_TIMESTAMPFREQ, &g.frequency));
                for (int m = 0; ok && m < kMaxMarks; ++m)
                    ok = SUCCEEDED(dev->CreateQuery(D3DQUERYTYPE_TIMESTAMP, &g.stamps[m]));
                if (!ok)
                {
                    gpuRelease();
                    mGpuFailed = true;
                    logLine("CYS-PERF: D3D9 timestamp queries unavailable, GPU timing off");
                    return false;
                }
            }
            mGpuActive = true;
            mGpuCurrent = -1;
            mGpuNext = 0;
            mGpuQueue.clear();
            return true;
        }

        void gpuRelease(void)
        {
            for (int s = 0; s < kGpuRing; ++s)
            {
                GpuSet& g = mSets[s];
                if (g.disjoint) g.disjoint->Release();
                if (g.frequency) g.frequency->Release();
                for (int m = 0; m < kMaxMarks; ++m)
                    if (g.stamps[m]) g.stamps[m]->Release();
            }
            memset(mSets, 0, sizeof(mSets));
            for (std::deque<FrameRec>::iterator it = mPending.begin(); it != mPending.end(); ++it)
                it->gpuResolved = true;
            mGpuQueue.clear();
            mGpuActive = false;
            mGpuCurrent = -1;
            mGpuNext = 0;
        }

        void gpuClose(int s)
        {
            GpuSet& g = mSets[s];
            g.disjoint->Issue(D3DISSUE_END);
            g.frequency->Issue(D3DISSUE_END);
            g.open = false;
            g.pending = true;
            mGpuQueue.push_back(s);
        }

        void gpuFrameBoundary(void)
        {
            if (!mGpuActive && !gpuInit())
                return;
            if (mGpuCurrent >= 0 && mSets[mGpuCurrent].open)
                gpuClose(mGpuCurrent);
            gpuResolve();
            GpuSet& g = mSets[mGpuNext];
            if (g.pending)
            {
                // The GPU is more than a ring behind: give up on the oldest frame.
                gpuFinished(g.frame);
                g.pending = false;
                std::deque<int>::iterator q = std::find(mGpuQueue.begin(), mGpuQueue.end(), mGpuNext);
                if (q != mGpuQueue.end())
                    mGpuQueue.erase(q);
            }
            g.count = 0;
            g.frame = mFrameIndex;
            g.open = SUCCEEDED(g.disjoint->Issue(D3DISSUE_BEGIN));
            mGpuCurrent = mGpuNext;
            mGpuNext = (mGpuNext + 1) % kGpuRing;
            if (g.open)
                gpuMark(P::MK_FRAME_BEGIN);
        }

        void gpuResolve(void)
        {
            while (!mGpuQueue.empty())
            {
                GpuSet& g = mSets[mGpuQueue.front()];
                BOOL disjoint = TRUE;
                UINT64 frequency = 0;
                HRESULT hr = g.disjoint->GetData(&disjoint, sizeof(disjoint), 0);
                if (hr == S_FALSE)
                    return;
                bool ok = SUCCEEDED(hr);
                if (ok)
                {
                    hr = g.frequency->GetData(&frequency, sizeof(frequency), 0);
                    if (hr == S_FALSE)
                        return;
                    ok = SUCCEEDED(hr);
                }
                UINT64 t[kMaxMarks];
                for (int i = 0; ok && i < g.count; ++i)
                {
                    hr = g.stamps[i]->GetData(&t[i], sizeof(UINT64), 0);
                    if (hr == S_FALSE)
                        return;
                    ok = SUCCEEDED(hr);
                }
                if (ok && !disjoint && frequency)
                    gpuApply(g, t, double(frequency));
                gpuFinished(g.frame);
                g.pending = false;
                mGpuQueue.pop_front();
            }
        }

        void gpuApply(const GpuSet& g, const UINT64* t, double frequency)
        {
            FrameRec* rec = pendingFrame(g.frame);
            if (!rec)
                return;
            const double k = 1000.0 / frequency;
            int first = -1, last = -1, window = 0, target = 0, ui = 0;
            UINT64 windowStart = 0, targetStart = 0, uiStart = 0;
            double windowMs = 0, targetMs = 0, uiMs = 0;
            for (int i = 0; i < g.count; ++i)
            {
                switch (g.ids[i])
                {
                case P::MK_FRAME_BEGIN: if (first < 0) first = i; break;
                case P::MK_PRESENT: last = i; break;
                case P::MK_WINDOW_BEGIN: if (window++ == 0) windowStart = t[i]; break;
                case P::MK_WINDOW_END:
                    if (window > 0 && --window == 0 && t[i] >= windowStart) windowMs += double(t[i] - windowStart) * k;
                    break;
                case P::MK_TARGET_BEGIN: if (target++ == 0) targetStart = t[i]; break;
                case P::MK_TARGET_END:
                    if (target > 0 && --target == 0 && t[i] >= targetStart) targetMs += double(t[i] - targetStart) * k;
                    break;
                case P::MK_UI_BEGIN: if (ui++ == 0) uiStart = t[i]; break;
                case P::MK_UI_END:
                    if (ui > 0 && --ui == 0 && t[i] >= uiStart) uiMs += double(t[i] - uiStart) * k;
                    break;
                default: break;
                }
            }
            if (last < 0)
                last = g.count - 1;
            if (first >= 0 && last > first && t[last] >= t[first])
                rec->gpuFrame = float(double(t[last] - t[first]) * k);
            rec->gpuWindow = float(windowMs);
            rec->gpuTarget = float(targetMs);
            rec->gpuUi = float(uiMs);
        }

        void gpuFinished(unsigned long long frame)
        {
            if (FrameRec* rec = pendingFrame(frame))
                rec->gpuResolved = true;
        }

        FrameRec* pendingFrame(unsigned long long frame)
        {
            for (std::deque<FrameRec>::iterator it = mPending.begin(); it != mPending.end(); ++it)
                if (it->index == frame)
                    return &*it;
            return 0;
        }

        //---------------------------------------------------------------------------------------------------
        void flushFront(void)
        {
            const FrameRec rec = mPending.front();
            mPending.pop_front();

            while (!mMarkRows.empty() && mMarkRows.front().first <= rec.index)
            {
                if (mCsv)
                    fputs(mMarkRows.front().second.c_str(), mCsv);
                mMarkRows.pop_front();
            }
            if (mCsv)
            {
                std::string row;
                appendf(row, "%llu,%.3f,%.3f", rec.index, rec.startMs, rec.frameMs);
                for (int i = 0; i < P::PH_COUNT; ++i)
                    appendf(row, ",%.3f", rec.phase[i]);
                const float gpu[4] = { rec.gpuFrame, rec.gpuWindow, rec.gpuTarget, rec.gpuUi };
                for (int i = 0; i < 4; ++i)
                {
                    if (gpu[i] >= 0.0f)
                        appendf(row, ",%.3f", gpu[i]);
                    else
                        row += ",";
                }
                for (int i = 0; i < P::C_COUNT; ++i)
                    appendf(row, ",%llu", rec.counter[i]);
                appendf(row, ",%u,%lld,%lld,%lld\n", rec.targetUpdates, rec.allocs, rec.allocBytes, rec.frees);
                fputs(row.c_str(), mCsv);
            }

            mAllFrames.push_back(float(rec.frameMs));
            mInterval.frames.push_back(float(rec.frameMs));
            for (int i = 0; i < P::PH_COUNT; ++i)
                mInterval.phase[i] += rec.phase[i];
            for (int i = 0; i < P::C_COUNT; ++i)
                mInterval.counter[i] += double(rec.counter[i]);
            if (rec.gpuFrame >= 0.0f)
            {
                mInterval.gpu[0] += rec.gpuFrame;
                mInterval.gpu[1] += rec.gpuWindow;
                mInterval.gpu[2] += rec.gpuTarget;
                mInterval.gpu[3] += rec.gpuUi;
                ++mInterval.gpuFrames;
            }
            mInterval.allocs += double(rec.allocs);
            mInterval.allocBytes += double(rec.allocBytes);
            mInterval.frees += double(rec.frees);
            mInterval.targetUpdates += rec.targetUpdates;
            if (rec.startMs + rec.frameMs - mInterval.startMs >= mIntervalMs)
            {
                logInterval(rec.startMs + rec.frameMs);
                mInterval.reset(rec.startMs + rec.frameMs);
            }
        }

        void logInterval(double nowMs)
        {
            Interval& v = mInterval;
            const size_t n = v.frames.size();
            if (!n)
                return;
            double sum = 0, maxMs = 0;
            unsigned h33 = 0, h50 = 0, h100 = 0;
            for (size_t i = 0; i < n; ++i)
            {
                sum += v.frames[i];
                maxMs = std::max(maxMs, double(v.frames[i]));
                h33 += v.frames[i] > 33.4f ? 1 : 0;
                h50 += v.frames[i] > 50.0f ? 1 : 0;
                h100 += v.frames[i] > 100.0f ? 1 : 0;
            }
            const double mean = sum / n;
            std::vector<float> sorted(v.frames);
            const double p50 = percentile(sorted, 0.50), p95 = percentile(sorted, 0.95), p99 = percentile(sorted, 0.99);
            const double inv = 1.0 / n;

            std::string line;
            appendf(line, "CYS-PERF t=%.1f n=%u fps=%.1f ms avg=%.2f p50=%.2f p95=%.2f p99=%.2f max=%.1f h33=%u h50=%u h100=%u |",
                    nowMs / 1000.0, unsigned(n), 1000.0 / mean, mean, p50, p95, p99, maxMs, h33, h50, h100);
            line += " cpu";
            for (int i = 0; i < P::PH_COUNT; ++i)
                if (v.phase[i] * inv >= 0.005)
                    appendf(line, " %s=%.2f", kPhaseNames[i], v.phase[i] * inv);
            if (v.gpuFrames)
            {
                const double g = 1.0 / v.gpuFrames;
                appendf(line, " | gpu frame=%.2f window=%.2f rtt=%.2f ui=%.2f (n=%u)", v.gpu[0] * g, v.gpu[1] * g,
                        v.gpu[2] * g, v.gpu[3] * g, v.gpuFrames);
            }
            line += " |";
            for (int i = 0; i < P::C_COUNT; ++i)
                if (v.counter[i] > 0)
                    appendf(line, " %s=%.1f", kCounterNames[i], v.counter[i] * inv);
            appendf(line, " rtt=%.1f alloc=%.0f (%.1f KB) free=%.0f | self=%.3f", v.targetUpdates * inv, v.allocs * inv,
                    v.allocBytes * inv / 1024.0, v.frees * inv, ms(mSelfTicks) * inv);
            mSelfTicks = 0;
            logLine(line);
            if (mCsv)
                fflush(mCsv);   // a killed process loses at most one interval of rows

            std::string detail = "CYS-PERF scene:";
            sceneStats(detail);
            if (mListenerTiming && !mListeners.empty())
            {
                std::vector<std::pair<long long, std::string> > top;
                for (std::map<const void*, ListenerStat>::iterator it = mListeners.begin(); it != mListeners.end(); ++it)
                {
                    if (it->second.intervalTicks > 0)
                        top.push_back(std::make_pair(it->second.intervalTicks, it->second.name));
                    it->second.intervalTicks = 0;
                }
                std::sort(top.rbegin(), top.rend());
                detail += " | listeners(ms/frame)";
                for (size_t i = 0; i < top.size() && i < 5; ++i)
                    appendf(detail, " %s=%.2f", top[i].second.c_str(), 1000.0 * double(top[i].first) / mFreq * inv);
            }
            logLine(detail);

            mOverlayText.clear();
            appendf(mOverlayText, "CYS-PERF %.1f fps  %.2f ms  p95 %.1f  p99 %.1f  max %.0f  >50ms %u\n",
                    1000.0 / mean, mean, p95, p99, maxMs, h50);
            appendf(mOverlayText, "cpu tick %.2f ev %.2f fs %.2f ctl %.2f cull %.2f anim %.2f draw %.2f ui %.2f pres %.2f wait %.2f\n",
                    v.phase[P::PH_GAME_TICK] * inv, v.phase[P::PH_GAME_EVENTS] * inv, v.phase[P::PH_FRAME_STARTED] * inv,
                    v.phase[P::PH_CONTROLLERS] * inv, v.phase[P::PH_CULL_QUEUE] * inv, v.phase[P::PH_ANIMATION] * inv,
                    v.phase[P::PH_DRAW] * inv, v.phase[P::PH_UI_DRAW] * inv, v.phase[P::PH_PRESENT] * inv,
                    v.phase[P::PH_GAME_WAIT] * inv);
            if (v.gpuFrames)
            {
                const double g = 1.0 / v.gpuFrames;
                appendf(mOverlayText, "gpu frame %.2f window %.2f rtt %.2f ui %.2f\n", v.gpu[0] * g, v.gpu[1] * g,
                        v.gpu[2] * g, v.gpu[3] * g);
            }
            appendf(mOverlayText, "draws %.0f prims %.0fk tex %.0f vs %.0f ps %.0f alloc %.0f ui-rebuild %.2f",
                    v.counter[P::C_DRAW] * inv, v.counter[P::C_PRIMS] * inv / 1000.0, v.counter[P::C_TEXTURE] * inv,
                    v.counter[P::C_VS] * inv, v.counter[P::C_PS] * inv, v.allocs * inv, v.counter[P::C_UI_REBUILD] * inv);

            if (mWantAlloc)
            {
                // heap allocations per frame of each engine module in this interval (top 6)
                std::vector<std::pair<std::string, LONG64> > modules;
                mAlloc.perModule(modules);
                std::vector<std::pair<LONG64, std::string> > top;
                for (size_t m = 0; m < modules.size(); ++m)
                {
                    const LONG64 before = m < mLastModuleAllocs.size() ? mLastModuleAllocs[m] : 0;
                    if (modules[m].second > before)
                        top.push_back(std::make_pair(modules[m].second - before, modules[m].first));
                }
                mLastModuleAllocs.resize(modules.size());
                for (size_t m = 0; m < modules.size(); ++m)
                    mLastModuleAllocs[m] = modules[m].second;
                std::sort(top.rbegin(), top.rend());
                std::string allocLine = "CYS-PERF alloc/frame by module:";
                for (size_t i = 0; i < top.size() && i < 6; ++i)
                    appendf(allocLine, " %s=%.1f", top[i].second.c_str(), double(top[i].first) * inv);
                logLine(allocLine);
                mAlloc.patchLoadedModules();
            }
        }

        void sceneStats(std::string& out)
        {
            if (!mSceneManager)
                return;
            size_t entities = 0, systems = 0, visibleSystems = 0, particles = 0, quota = 0, maxQuota = 0;
            size_t billboards = 0, ribbons = 0;
            try
            {
                Ogre::SceneManager::MovableObjectIterator e = mSceneManager->getMovableObjectIterator("Entity");
                while (e.hasMoreElements()) { e.getNext(); ++entities; }
                Ogre::SceneManager::MovableObjectIterator p = mSceneManager->getMovableObjectIterator("ParticleSystem");
                while (p.hasMoreElements())
                {
                    Ogre::ParticleSystem* ps = static_cast<Ogre::ParticleSystem*>(p.getNext());
                    ++systems;
                    if (ps->isVisible() && ps->isInScene())
                        ++visibleSystems;
                    particles += ps->getNumParticles();
                    quota += ps->getParticleQuota();
                    maxQuota = std::max(maxQuota, ps->getParticleQuota());
                }
                Ogre::SceneManager::MovableObjectIterator b = mSceneManager->getMovableObjectIterator("BillboardSet");
                while (b.hasMoreElements()) { b.getNext(); ++billboards; }
                Ogre::SceneManager::MovableObjectIterator r = mSceneManager->getMovableObjectIterator("RibbonTrail");
                while (r.hasMoreElements()) { r.getNext(); ++ribbons; }
            }
            catch (...)
            {
            }
            appendf(out, " entities=%u psys=%u(in-scene %u) particles=%u quota=%u maxquota=%u billboardsets=%u ribbons=%u",
                    unsigned(entities), unsigned(systems), unsigned(visibleSystems), unsigned(particles), unsigned(quota),
                    unsigned(maxQuota), unsigned(billboards), unsigned(ribbons));

            size_t materials = 0, materialsLoaded = 0, textures = 0, texturesLoaded = 0, meshes = 0, meshesLoaded = 0;
            size_t materialBytes = 0, textureBytes = 0, meshBytes = 0;
            countResources(Ogre::MaterialManager::getSingleton(), materials, materialsLoaded, materialBytes);
            countResources(Ogre::TextureManager::getSingleton(), textures, texturesLoaded, textureBytes);
            countResources(Ogre::MeshManager::getSingleton(), meshes, meshesLoaded, meshBytes);
            appendf(out, " | res materials=%u(+%d) loaded=%u textures=%u(+%d) loaded=%u %.0fMB meshes=%u loaded=%u %.0fMB",
                    unsigned(materials), int(materials) - int(mLastMaterials), unsigned(materialsLoaded),
                    unsigned(textures), int(textures) - int(mLastTextures), unsigned(texturesLoaded),
                    double(textureBytes) / (1024.0 * 1024.0), unsigned(meshes), unsigned(meshesLoaded),
                    double(meshBytes) / (1024.0 * 1024.0));
            mLastMaterials = materials;
            mLastTextures = textures;
        }

        static void countResources(Ogre::ResourceManager& manager, size_t& total, size_t& loaded, size_t& bytes)
        {
            Ogre::ResourceManager::ResourceMapIterator it = manager.getResourceIterator();
            while (it.hasMoreElements())
            {
                Ogre::ResourcePtr resource = it.getNext();
                ++total;
                if (!resource.isNull() && resource->isLoaded())
                {
                    ++loaded;
                    bytes += resource->getSize();
                }
            }
        }

        void appendSummary(std::string& line, const char* label, size_t begin, size_t end, double startMs)
        {
            if (end > mAllFrames.size())
                end = mAllFrames.size();
            if (begin >= end)
            {
                appendf(line, "CYS-PERF %s: no frames", label);
                return;
            }
            std::vector<float> v(mAllFrames.begin() + begin, mAllFrames.begin() + end);
            double sum = 0, maxMs = 0;
            unsigned h33 = 0, h50 = 0, h100 = 0;
            for (size_t i = 0; i < v.size(); ++i)
            {
                sum += v[i];
                maxMs = std::max(maxMs, double(v[i]));
                h33 += v[i] > 33.4f ? 1 : 0;
                h50 += v[i] > 50.0f ? 1 : 0;
                h100 += v[i] > 100.0f ? 1 : 0;
            }
            const double mean = sum / v.size();
            const double p50 = percentile(v, 0.50), p95 = percentile(v, 0.95), p99 = percentile(v, 0.99);
            appendf(line, "CYS-PERF %s: start=%.1fs frames=%u seconds=%.1f fps=%.1f ms avg=%.2f p50=%.2f p95=%.2f p99=%.2f max=%.1f h33=%u h50=%u h100=%u",
                    label, startMs / 1000.0, unsigned(end - begin), sum / 1000.0, 1000.0 / mean, mean, p50, p95, p99,
                    maxMs, h33, h50, h100);
        }

        Ogre::Root* mRoot;
        Ogre::RenderWindow* mWindow;
        Ogre::SceneManager* mSceneManager;
        IDirect3DDevice9* mDevice;
        const double mIntervalMs;
        const bool mWantGpu;
        const bool mWantAlloc;
        const int mOverlayScale;
        const bool mListenerTiming;
        FILE* mCsv;
        const long long mStart;
        long long mLastBegin;
        unsigned long long mFrameIndex;
        const double mFreq;
        LONG64 mLastAllocs, mLastAllocBytes, mLastFrees;
        unsigned mTargetUpdates;
        long long mSelfTicks;
        AllocHooks mAlloc;
        std::vector<LONG64> mLastModuleAllocs;
        Overlay mOverlay;
        std::string mOverlayText;
        std::deque<FrameRec> mPending;
        std::deque<std::pair<unsigned long long, std::string> > mMarkRows;
        std::vector<float> mAllFrames;
        std::vector<Segment> mSegments;
        Interval mInterval;
        std::map<const void*, ListenerStat> mListeners;
        std::map<Ogre::String, Ogre::RenderTarget*> mAttached;
        GpuSet mSets[kGpuRing];
        bool mGpuActive, mGpuFailed, mGpuSuspended;
        int mGpuCurrent, mGpuNext;
        std::deque<int> mGpuQueue;
        size_t mLastMaterials, mLastTextures;
    };

    Collector* gCollector = 0;

    void hookFrameBegin(void) { if (gCollector) gCollector->frameBegin(); }
    void hookGpuMark(int marker) { if (gCollector) gCollector->gpuMark(marker); }
    void hookMark(const char* label) { if (gCollector) gCollector->mark(label); }
    void hookListener(const void* listener, int ended, long long ticks)
    {
        if (gCollector) gCollector->listenerTime(listener, ended, ticks);
    }
}

//-----------------------------------------------------------------------------------------------------------
void install(Ogre::Root* root, Ogre::RenderWindow* window, Ogre::SceneManager* sceneManager)
{
    if (gCollector || !root || !window)
        return;
    const std::string flag = envString("CYS_PERF");
    if (flag.empty() || flag == "0")
        return;
    const std::string perfLog = envString("CYS_PERF_LOG");
    if (!perfLog.empty() && !gPerfLog && fopen_s(&gPerfLog, perfLog.c_str(), "a") != 0)
        gPerfLog = 0;
    if (P::gBlock.version != P::BLOCK_VERSION)
    {
        logLine("CYS-PERF: OgreMain perf block version mismatch, collector not installed");
        return;
    }
    try
    {
        gCollector = new Collector(root, window, sceneManager);
        gCollector->start();
    }
    catch (...)
    {
        delete gCollector;
        gCollector = 0;
        logLine("CYS-PERF: collector failed to start");
        return;
    }
    memset(const_cast<long long*>(P::gBlock.phaseTicks), 0, sizeof(P::gBlock.phaseTicks));
    memset(const_cast<unsigned long long*>(P::gBlock.counters), 0, sizeof(P::gBlock.counters));
    P::gBlock.frameBegin = &hookFrameBegin;
    P::gBlock.gpuMark = &hookGpuMark;
    P::gBlock.mark = &hookMark;
    P::gBlock.listenerTime = &hookListener;
    P::gBlock.enabled = 1;
}

void shutdown(void)
{
    if (!gCollector)
        return;
    P::gBlock.enabled = 0;
    P::gBlock.frameBegin = 0;
    P::gBlock.gpuMark = 0;
    P::gBlock.mark = 0;
    P::gBlock.listenerTime = 0;
    Collector* collector = gCollector;
    gCollector = 0;
    try
    {
        collector->finish();
        collector->detach();
    }
    catch (...)
    {
    }
    delete collector;
    if (gPerfLog)
    {
        fclose(gPerfLog);
        gPerfLog = 0;
    }
}

void mark(const char* label)
{
    if (gCollector)
        gCollector->mark(label);
}

bool installed(void)
{
    return gCollector != 0;
}

}
}
