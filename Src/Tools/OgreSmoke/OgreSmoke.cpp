// CY-Source OgreSmoke: x64 smoke test for OgreMain.dll + RenderSystem_Direct3D9.dll (component ogre_smoke).
// CYS: new tool (2026-09-12).
//
//   OgreSmoke.exe [--data DIR] [--out DIR] [--mesh NAME[+NAME...]]... [--list FILE] [--frames N]
//                 [--batch N] [--seed N] [--width W] [--height H] [--yaw DEG] [--no-render]
//                 [--no-fallback] [--no-batch] [--no-shots] [--shader-cache DIR|off] [--no-variants]
//                 [--fsaa N] [--intz] [--provider-test] [--set-param GROUP:NAME=x,y,z,w]...
//                 [--no-ff-convert] [--particles] [--cylinder-test]
//
// CYS 2026-09-12 (material parity test): --mesh groups (a+b+c share one node and animation),
//   --list FILE (UTF-8 lines "label<TAB>a.mesh+b.mesh", names converted to GBK), key + fill
//   directional lights + ambient, grid screenshot (grid.png) + one framed shot per group
//   (shot_NN.png), Ogre.log warning census (warnings.txt) and a copy of Ogre.log in --out.
//
// * Creates Ogre::Root without config dialog or plugins.cfg, then loads the render system and the
//   inner plugins exactly like Render.dll does (Root::loadRenderPlugins_D3D9 / loadInnerPlugins).
// * Everything under --data (default C:\TLBB\085\client_GL\Data) is used READ-ONLY, with the resource
//   layout of client_GL\Bin\FairyResources.cfg (Bootstrap: OgreCore.zip + MaterialTemplates.zip,
//   General: Model*/Material* folders). File names stay GBK bytes (ACP 1252 opens them unchanged).
// * Renders the --mesh entities with an idle/first animation for N frames and saves
//   ogre_smoke.png (back buffer before Present, own PNG writer: DevIL has no PNG in this build) and
//   ogre_smoke_front.bmp (RenderWindow::writeContentsToFile, front buffer via DevIL).
// * Submeshes whose material is missing or has no supported technique get a fixed-function fallback
//   material that reuses the resolved texture (reported in smoke_summary.txt).
// * Batch: loads N random .mesh and N random .skeleton files from ModelFolder and checks the data
//   (bounds, index counts, bone/keyframe sanity incl. the Fairy 0x4120 keyframe-list chunk);
//   results in batch_results.csv.
// Ogre.log is written next to the exe.

#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <d3d9.h>
#include <dbghelp.h>
#include <zlib.h>

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <fstream>
#include <map>
#include <random>
#include <sstream>
#include <string>
#include <vector>

#include "Ogre.h"
#include "OgreArchiveManager.h"
#include "OgreSkeletonManager.h"
#include "OgreGpuProgramManager.h" // CYS: shader cache statistics
#include "OgreHighLevelGpuProgramManager.h" // CYS: --intz debug shaders
#include "OgreHardwarePixelBuffer.h"        // CYS: --intz render texture
#include "OgreRenderTexture.h"              // CYS
#include "OgreRectangle2D.h"                // CYS
#include "OgreAutoParamExternalProvider.h"  // CYS: --provider-test
#include "OgreParticleSystemManager.h"      // CYS: --particles, --cylinder-test
#include "OgreParticleSystem.h"             // CYS
#include "OgreParticleEmitter.h"            // CYS
#include "CysMeshUpgrade.h"          // CYS: CPU-only pinned stage conversion
#ifdef CYS_WXRENDER_MATERIAL_SYSTEM
#include "MaterialSystem/CysMaterialSystem.h" // CYS: WXRender runtime material system (see ogre_smoke.cmake)
#endif

using namespace Ogre;

namespace
{
    struct Options
    {
        std::string data = "C:\\TLBB\\085\\client_GL\\Data";
        std::string out;
        std::vector<std::string> meshes; // CYS: each entry may be a group "a.mesh+b.mesh"
        std::vector<std::string> labels; // CYS: report label per entry (UTF-8)
        std::string list;                // CYS: UTF-8 list file (label<TAB>group)
        std::string shaderCache;         // CYS: shader microcode cache dir ("" = default, "off")
        int frames = 60;
        int batch = 200;
        unsigned seed = 20260912;
        int width = 1280;
        int height = 720;
        float yawDeg = 0.0f;
        bool render = true;
        bool fallback = true;
        bool doBatch = true;
        bool shots = true;               // CYS: one framed screenshot per group
        bool variants = true;            // CYS: runtime shader variants (WXRender material system)
        int fsaa = 4;                    // CYS: --fsaa N (window multisampling; --intz forces 0)
        bool intz = false;               // CYS: --intz: scene depth in an INTZ texture -> intz_depth.png
        bool providerTest = false;       // CYS: --provider-test: fog from an AutoParamExternalProvider
        std::vector<std::string> setParams; // CYS: --set-param G:NAME=x,y,z,w (per-entity constants)
        bool ffConvert = true;           // CYS: --no-ff-convert keeps fixed-function passes
        bool particles = false;          // CYS: --particles parses client_GL EffectFolder\all.particle
        bool cylinderTest = false;       // CYS: --cylinder-test renders B cylinder keys -> cylinder.png
    };

    std::string g_summary;

    void say(const std::string& s)
    {
        g_summary += s;
        g_summary += "\n";
        std::printf("%s\n", s.c_str());
        std::fflush(stdout);
        if (LogManager::getSingletonPtr())
            LogManager::getSingleton().logMessage("CYS smoke: " + s);
    }

    std::string g_outDir;

    // Unhandled SEH exception -> symbolised stack (DbgHelp, PDBs next to the DLLs) + minidump.
    LONG WINAPI crashFilter(EXCEPTION_POINTERS* ep)
    {
        HANDLE proc = GetCurrentProcess();
        char head[160];
        std::sprintf(head, "CRASH: exception 0x%08lX at %p\n", ep->ExceptionRecord->ExceptionCode,
                     ep->ExceptionRecord->ExceptionAddress);
        std::string txt = head;
        SymSetOptions(SYMOPT_LOAD_LINES | SYMOPT_UNDNAME | SYMOPT_DEFERRED_LOADS);
        SymInitialize(proc, NULL, TRUE);
        CONTEXT ctx = *ep->ContextRecord;
        STACKFRAME64 sf;
        ZeroMemory(&sf, sizeof(sf));
        sf.AddrPC.Offset = ctx.Rip;
        sf.AddrPC.Mode = AddrModeFlat;
        sf.AddrFrame.Offset = ctx.Rbp;
        sf.AddrFrame.Mode = AddrModeFlat;
        sf.AddrStack.Offset = ctx.Rsp;
        sf.AddrStack.Mode = AddrModeFlat;
        for (int i = 0; i < 40; ++i)
        {
            if (!StackWalk64(IMAGE_FILE_MACHINE_AMD64, proc, GetCurrentThread(), &sf, &ctx, NULL,
                             SymFunctionTableAccess64, SymGetModuleBase64, NULL) || !sf.AddrPC.Offset)
                break;
            DWORD64 addr = sf.AddrPC.Offset;
            char mod[MAX_PATH] = "?";
            HMODULE hm = NULL;
            if (GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                                   (LPCSTR)addr, &hm))
                GetModuleFileNameA(hm, mod, MAX_PATH);
            const char* modBase = std::strrchr(mod, '\\');
            char symbuf[sizeof(SYMBOL_INFO) + 512];
            ZeroMemory(symbuf, sizeof(symbuf));
            SYMBOL_INFO* sym = (SYMBOL_INFO*)symbuf;
            sym->SizeOfStruct = sizeof(SYMBOL_INFO);
            sym->MaxNameLen = 511;
            DWORD64 disp = 0;
            IMAGEHLP_LINE64 line;
            ZeroMemory(&line, sizeof(line));
            line.SizeOfStruct = sizeof(line);
            DWORD ldisp = 0;
            bool hasSym = SymFromAddr(proc, addr, &disp, sym) != FALSE;
            bool hasLine = SymGetLineFromAddr64(proc, addr, &ldisp, &line) != FALSE;
            char buf[1400];
            std::sprintf(buf, "#%02d %s!%s+0x%llx  %s:%lu\n", i, modBase ? modBase + 1 : mod, hasSym ? sym->Name : "?",
                         (unsigned long long)disp, hasLine ? line.FileName : "", hasLine ? (unsigned long)line.LineNumber : 0UL);
            txt += buf;
        }
        std::printf("%s", txt.c_str());
        std::fflush(stdout);
        std::string dir = g_outDir.empty() ? std::string(".") : g_outDir;
        FILE* f = std::fopen((dir + "\\smoke_crash.txt").c_str(), "wb");
        if (f)
        {
            std::fputs(txt.c_str(), f);
            std::fputs("\n--- summary so far ---\n", f);
            std::fputs(g_summary.c_str(), f);
            std::fclose(f);
        }
        HANDLE hf = CreateFileA((dir + "\\smoke_crash.dmp").c_str(), GENERIC_WRITE, 0, NULL, CREATE_ALWAYS,
                               FILE_ATTRIBUTE_NORMAL, NULL);
        if (hf != INVALID_HANDLE_VALUE)
        {
            MINIDUMP_EXCEPTION_INFORMATION mei;
            mei.ThreadId = GetCurrentThreadId();
            mei.ExceptionPointers = ep;
            mei.ClientPointers = FALSE;
            MiniDumpWriteDump(proc, GetCurrentProcessId(), hf, MiniDumpNormal, &mei, NULL, NULL);
            CloseHandle(hf);
        }
        return EXCEPTION_EXECUTE_HANDLER;
    }

    // Resource names are GBK bytes; reports are UTF-8.
    std::string gbkToUtf8(const std::string& s)
    {
        if (s.empty())
            return s;
        int wn = MultiByteToWideChar(936, 0, s.data(), (int)s.size(), NULL, 0);
        if (wn <= 0)
            return s;
        std::wstring w(wn, L'\0');
        MultiByteToWideChar(936, 0, s.data(), (int)s.size(), &w[0], wn);
        int un = WideCharToMultiByte(CP_UTF8, 0, w.data(), wn, NULL, 0, NULL, NULL);
        std::string u(un, '\0');
        WideCharToMultiByte(CP_UTF8, 0, w.data(), wn, &u[0], un, NULL, NULL);
        return u;
    }

    // CYS: list files are UTF-8, resource names are GBK bytes.
    std::string utf8ToGbk(const std::string& s)
    {
        if (s.empty())
            return s;
        int wn = MultiByteToWideChar(CP_UTF8, 0, s.data(), (int)s.size(), NULL, 0);
        if (wn <= 0)
            return s;
        std::wstring w(wn, L'\0');
        MultiByteToWideChar(CP_UTF8, 0, s.data(), (int)s.size(), &w[0], wn);
        int gn = WideCharToMultiByte(936, 0, w.data(), wn, NULL, 0, NULL, NULL);
        std::string g(gn, '\0');
        WideCharToMultiByte(936, 0, w.data(), wn, &g[0], gn, NULL, NULL);
        return g;
    }

    std::string trimCopy(const std::string& s)
    {
        size_t b = s.find_first_not_of(" \t\r\n");
        if (b == std::string::npos)
            return std::string();
        size_t e = s.find_last_not_of(" \t\r\n");
        return s.substr(b, e - b + 1);
    }

    std::vector<std::string> splitGroup(const std::string& s)
    {
        std::vector<std::string> out;
        size_t p = 0;
        while (p <= s.size())
        {
            size_t q = s.find('+', p);
            std::string item = trimCopy(s.substr(p, q == std::string::npos ? std::string::npos : q - p));
            if (!item.empty())
                out.push_back(item);
            if (q == std::string::npos)
                break;
            p = q + 1;
        }
        return out;
    }

    // CYS: "label<TAB>a.mesh+b.mesh" lines (UTF-8, '#' comments) -> opt.meshes (GBK) + opt.labels.
    bool loadList(const std::string& path, std::vector<std::string>& meshes, std::vector<std::string>& labels)
    {
        std::ifstream f(path.c_str(), std::ios::binary);
        if (!f)
            return false;
        std::string line;
        bool first = true;
        while (std::getline(f, line))
        {
            if (first && line.size() >= 3 && (unsigned char)line[0] == 0xEF && (unsigned char)line[1] == 0xBB &&
                (unsigned char)line[2] == 0xBF)
                line.erase(0, 3);
            first = false;
            line = trimCopy(line);
            if (line.empty() || line[0] == '#')
                continue;
            size_t tab = line.find('\t');
            std::string label = tab == std::string::npos ? line : trimCopy(line.substr(0, tab));
            std::string group = tab == std::string::npos ? line : trimCopy(line.substr(tab + 1));
            meshes.push_back(utf8ToGbk(group));
            labels.push_back(label);
        }
        return true;
    }

    std::string exeDir()
    {
        char buf[MAX_PATH];
        DWORD n = GetModuleFileNameA(NULL, buf, MAX_PATH);
        std::string p(buf, n);
        size_t s = p.find_last_of("\\/");
        return s == std::string::npos ? std::string(".") : p.substr(0, s);
    }

    double nowSec()
    {
        static LARGE_INTEGER f = {};
        if (!f.QuadPart)
            QueryPerformanceFrequency(&f);
        LARGE_INTEGER c;
        QueryPerformanceCounter(&c);
        return double(c.QuadPart) / double(f.QuadPart);
    }

    void pumpMessages()
    {
        MSG msg;
        while (PeekMessage(&msg, NULL, 0U, 0U, PM_REMOVE))
        {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
    }

    bool finite3(const Vector3& v)
    {
        for (int i = 0; i < 3; ++i)
            if (!(std::fabs(v[i]) < 1.0e7f))
                return false;
        return true;
    }

    // ---------------------------------------------------------------- PNG writer (zlib)
    void pngChunk(FILE* f, const char* type, const unsigned char* data, size_t len)
    {
        unsigned char be[4] = { (unsigned char)(len >> 24), (unsigned char)(len >> 16),
                                (unsigned char)(len >> 8), (unsigned char)len };
        std::fwrite(be, 1, 4, f);
        std::fwrite(type, 1, 4, f);
        if (len)
            std::fwrite(data, 1, len, f);
        uLong crc = crc32(0L, Z_NULL, 0);
        crc = crc32(crc, (const Bytef*)type, 4);
        if (len)
            crc = crc32(crc, data, (uInt)len);
        unsigned char c[4] = { (unsigned char)(crc >> 24), (unsigned char)(crc >> 16),
                               (unsigned char)(crc >> 8), (unsigned char)crc };
        std::fwrite(c, 1, 4, f);
    }

    bool writePng(const std::string& path, unsigned w, unsigned h, const std::vector<unsigned char>& rgb)
    {
        std::vector<unsigned char> raw;
        raw.reserve((size_t)h * (w * 3 + 1));
        for (unsigned y = 0; y < h; ++y)
        {
            raw.push_back(0); // filter: none
            raw.insert(raw.end(), rgb.begin() + (size_t)y * w * 3, rgb.begin() + (size_t)(y + 1) * w * 3);
        }
        uLongf clen = compressBound((uLong)raw.size());
        std::vector<unsigned char> comp(clen);
        if (compress2(&comp[0], &clen, &raw[0], (uLong)raw.size(), 6) != Z_OK)
            return false;
        FILE* f = std::fopen(path.c_str(), "wb");
        if (!f)
            return false;
        static const unsigned char sig[8] = { 137, 80, 78, 71, 13, 10, 26, 10 };
        std::fwrite(sig, 1, 8, f);
        unsigned char ihdr[13] = { (unsigned char)(w >> 24), (unsigned char)(w >> 16), (unsigned char)(w >> 8), (unsigned char)w,
                                   (unsigned char)(h >> 24), (unsigned char)(h >> 16), (unsigned char)(h >> 8), (unsigned char)h,
                                   8, 2, 0, 0, 0 }; // 8-bit RGB
        pngChunk(f, "IHDR", ihdr, 13);
        pngChunk(f, "IDAT", &comp[0], clen);
        pngChunk(f, "IEND", NULL, 0);
        std::fclose(f);
        return true;
    }

    // Copy the (not yet presented) back buffer to system memory as RGB.
    bool captureBackBuffer(RenderWindow* win, std::vector<unsigned char>& rgb, unsigned& w, unsigned& h, std::string& err,
                           RenderTarget* from = NULL) // CYS: 'from' = a render texture instead of the window
    {
        IDirect3DDevice9* dev = NULL;
        IDirect3DSurface9* bbs[8] = { NULL };
        win->getCustomAttribute("D3DDEVICE", &dev);
        (from ? static_cast<RenderTarget*>(from) : win)->getCustomAttribute("DDBACKBUFFER", bbs); // not AddRef'ed
        IDirect3DSurface9* bb = bbs[0];
        if (!dev || !bb)
        {
            err = "no D3DDEVICE/DDBACKBUFFER";
            return false;
        }
        D3DSURFACE_DESC d;
        bb->GetDesc(&d);
        IDirect3DSurface9* src = bb;
        IDirect3DSurface9* resolved = NULL;
        if (d.MultiSampleType != D3DMULTISAMPLE_NONE)
        {
            if (FAILED(dev->CreateRenderTarget(d.Width, d.Height, d.Format, D3DMULTISAMPLE_NONE, 0, FALSE, &resolved, NULL)) ||
                FAILED(dev->StretchRect(bb, NULL, resolved, NULL, D3DTEXF_NONE)))
            {
                err = "MSAA resolve failed";
                if (resolved)
                    resolved->Release();
                return false;
            }
            src = resolved;
        }
        IDirect3DSurface9* sys = NULL;
        bool ok = false;
        if (SUCCEEDED(dev->CreateOffscreenPlainSurface(d.Width, d.Height, d.Format, D3DPOOL_SYSTEMMEM, &sys, NULL)) &&
            SUCCEEDED(dev->GetRenderTargetData(src, sys)))
        {
            D3DLOCKED_RECT lr;
            if (SUCCEEDED(sys->LockRect(&lr, NULL, D3DLOCK_READONLY)))
            {
                w = d.Width;
                h = d.Height;
                rgb.resize((size_t)w * h * 3);
                ok = true;
                for (unsigned y = 0; y < h && ok; ++y)
                {
                    const unsigned char* row = (const unsigned char*)lr.pBits + (size_t)y * lr.Pitch;
                    unsigned char* dst = &rgb[(size_t)y * w * 3];
                    for (unsigned x = 0; x < w; ++x)
                    {
                        if (d.Format == D3DFMT_X8R8G8B8 || d.Format == D3DFMT_A8R8G8B8)
                        {
                            dst[0] = row[x * 4 + 2];
                            dst[1] = row[x * 4 + 1];
                            dst[2] = row[x * 4 + 0];
                        }
                        else if (d.Format == D3DFMT_R5G6B5)
                        {
                            unsigned v = ((const unsigned short*)row)[x];
                            dst[0] = (unsigned char)(((v >> 11) & 31) * 255 / 31);
                            dst[1] = (unsigned char)(((v >> 5) & 63) * 255 / 63);
                            dst[2] = (unsigned char)((v & 31) * 255 / 31);
                        }
                        else
                        {
                            err = "unsupported back buffer format " + StringConverter::toString((int)d.Format);
                            ok = false;
                            break;
                        }
                        dst += 3;
                    }
                }
                sys->UnlockRect();
            }
            else
                err = "LockRect failed";
        }
        else
            err = "GetRenderTargetData failed";
        if (sys)
            sys->Release();
        if (resolved)
            resolved->Release();
        return ok;
    }

    // ---------------------------------------------------------------- materials
    // First texture name of the material that exists as a resource.
    String firstTexture(const MaterialPtr& mat)
    {
        if (mat.isNull())
            return StringUtil::BLANK;
        for (unsigned short t = 0; t < mat->getNumTechniques(); ++t)
        {
            Technique* tech = mat->getTechnique(t);
            for (unsigned short p = 0; p < tech->getNumPasses(); ++p)
            {
                Pass* pass = tech->getPass(p);
                for (unsigned short u = 0; u < pass->getNumTextureUnitStates(); ++u)
                {
                    const String& tex = pass->getTextureUnitState(u)->getTextureName();
                    if (!tex.empty() && ResourceGroupManager::getSingleton().resourceExists("General", tex))
                        return tex;
                }
            }
        }
        return StringUtil::BLANK;
    }

    String describeMaterial(const MaterialPtr& mat)
    {
        std::ostringstream o;
        if (mat.isNull())
            return "missing";
        o << "techniques=" << mat->getNumTechniques() << " supported=" << mat->getNumSupportedTechniques();
        if (mat->getNumTechniques())
        {
            Technique* tech = mat->getTechnique(0);
            for (unsigned short p = 0; p < tech->getNumPasses(); ++p)
            {
                Pass* pass = tech->getPass(p);
                o << " [pass" << p;
                if (pass->hasVertexProgram())
                    o << " vp=" << pass->getVertexProgramName();
                if (pass->hasFragmentProgram())
                    o << " fp=" << pass->getFragmentProgramName();
                if (pass->getNumTextureUnitStates())
                    o << " tex=" << pass->getTextureUnitState(0)->getTextureName();
                o << "]";
            }
        }
        return o.str();
    }

    void applyMaterialsOrFallback(Entity* ent, bool allowFallback, int& fallbacks)
    {
        for (unsigned int i = 0; i < ent->getNumSubEntities(); ++i)
        {
            SubEntity* se = ent->getSubEntity(i);
            String name = se->getMaterialName();
            // CYS: the material actually rendered (a runtime shader variant of 'name' when the
            // material system paired vertex programs with it)
            MaterialPtr mat = se->getMaterial();
            if (mat.isNull() || mat->getName() != name)
                say("  submesh " + StringConverter::toString(i) + " renders variant '" +
                    (mat.isNull() ? String("?") : gbkToUtf8(mat->getName())) + "'");
            if (!mat.isNull() && mat->getName() == "BaseWhite" && name != "BaseWhite")
                mat.setNull(); // material missing: SubEntity fell back to BaseWhite
            bool supported = false;
            String why;
            if (mat.isNull())
                why = "material not defined";
            else
            {
                try
                {
                    mat->load();
                    supported = mat->getNumSupportedTechniques() > 0;
                    if (!supported)
                        why = "no supported technique";
                }
                catch (Exception& e)
                {
                    why = "load failed: " + e.getDescription();
                }
            }
            say("  submesh " + StringConverter::toString(i) + " material '" + gbkToUtf8(name) + "': " +
                describeMaterial(mat) + (supported ? "  OK" : "  -> " + why));
            if (supported || !allowFallback)
                continue;
            String tex = firstTexture(mat);
            String fbName = "CYS/Fallback/" + name;
            MaterialPtr fb = MaterialManager::getSingleton().getByName(fbName);
            if (fb.isNull())
            {
                fb = MaterialManager::getSingleton().create(fbName, "General");
                Pass* pass = fb->getTechnique(0)->getPass(0);
                pass->setLightingEnabled(true);
                pass->setAmbient(ColourValue(1, 1, 1));
                pass->setDiffuse(ColourValue(1, 1, 1));
                pass->setAlphaRejectSettings(CMPF_GREATER, 128);
                if (!tex.empty())
                    pass->createTextureUnitState(tex);
                fb->load();
            }
            se->setMaterialName(fbName);
            ++fallbacks;
            say("    fallback material (fixed function) texture='" + gbkToUtf8(tex) + "'");
        }
    }

    AnimationState* pickAnimation(Entity* ent)
    {
        AnimationStateSet* set = ent->getAllAnimationStates();
        if (!set)
        {
            say("  no skeleton / animation states");
            return NULL;
        }
        std::vector<AnimationState*> all;
        AnimationStateIterator it = set->getAnimationStateIterator();
        std::string names;
        while (it.hasMoreElements())
        {
            AnimationState* s = it.getNext();
            all.push_back(s);
            if (names.size() < 600)
                names += gbkToUtf8(s->getAnimationName()) + " ";
        }
        say("  animations (" + StringConverter::toString((int)all.size()) + "): " + names);
        if (all.empty())
            return NULL;
        // Idle-ish names first. Literals compile to GBK bytes (/execution-charset:.936), like the data.
        static const char* const preferred[] = { "休闲", "站立", "跑步", "攻击", "idle", "stand" };
        for (size_t p = 0; p < sizeof(preferred) / sizeof(preferred[0]); ++p)
            for (size_t i = 0; i < all.size(); ++i)
                if (all[i]->getAnimationName().find(preferred[p]) != String::npos)
                    return all[i];
        return all[0];
    }

    // ---------------------------------------------------------------- batch checks
    struct BatchItem
    {
        bool isMesh;
        std::string name;
        bool ok;
        std::string detail;
    };

    void checkMesh(BatchItem& c)
    {
        bool preloaded = !MeshManager::getSingleton().getByName(c.name).isNull();
        MeshPtr m = MeshManager::getSingleton().load(c.name, "General");
        size_t verts = m->sharedVertexData ? m->sharedVertexData->vertexCount : 0;
        size_t idx = 0;
        bool sane = true;
        std::ostringstream d;
        for (unsigned short i = 0; i < m->getNumSubMeshes(); ++i)
        {
            SubMesh* sm = m->getSubMesh(i);
            if (!sm->useSharedVertices && sm->vertexData)
                verts += sm->vertexData->vertexCount;
            if (sm->indexData)
            {
                idx += sm->indexData->indexCount;
                if (sm->operationType == RenderOperation::OT_TRIANGLE_LIST && sm->indexData->indexCount % 3)
                {
                    sane = false;
                    d << " BAD-INDEX-COUNT(sub" << i << ")";
                }
            }
        }
        const AxisAlignedBox& b = m->getBounds();
        if (!finite3(b.getMinimum()) || !finite3(b.getMaximum()))
        {
            sane = false;
            d << " BAD-BOUNDS";
        }
        d << " sub=" << m->getNumSubMeshes() << " verts=" << verts << " idx=" << idx;
        if (m->hasSkeleton())
        {
            d << " skel=" << gbkToUtf8(m->getSkeletonName());
            if (m->getSkeleton().isNull())
            {
                sane = false;
                d << "(NOT-LOADED)";
            }
            else
                d << "(bones=" << m->getSkeleton()->getNumBones() << ")";
        }
        c.ok = sane;
        c.detail = d.str();
        if (!preloaded)
        {
            m->unload();
            MeshManager::getSingleton().remove(m->getHandle());
        }
    }

    void checkSkeleton(BatchItem& c)
    {
        bool preloaded = !SkeletonManager::getSingleton().getByName(c.name).isNull();
        SkeletonPtr s = SkeletonManager::getSingleton().load(c.name, "General");
        unsigned short nb = s->getNumBones();
        unsigned short na = s->getNumAnimations();
        size_t keys = 0, badKeys = 0;
        Real maxLen = 0;
        bool sane = nb > 0;
        std::ostringstream d;
        for (unsigned short a = 0; a < na; ++a)
        {
            Animation* an = s->getAnimation(a);
            Real len = an->getLength();
            if (!(len >= 0 && len < 1.0e5f))
                sane = false;
            maxLen = std::max(maxLen, len);
            Animation::NodeTrackIterator it = an->getNodeTrackIterator();
            while (it.hasMoreElements())
            {
                NodeAnimationTrack* t = it.getNext();
                Real prev = -1;
                for (unsigned short k = 0; k < t->getNumKeyFrames(); ++k)
                {
                    TransformKeyFrame* kf = t->getNodeKeyFrame(k);
                    Real tm = kf->getTime();
                    Real qn = kf->getRotation().Norm();
                    ++keys;
                    if (!(tm >= prev - 1.0e-4f && tm <= len + 1.0e-3f) || !(std::fabs(qn - 1.0f) < 0.05f) ||
                        !finite3(kf->getTranslate()) || !finite3(kf->getScale()))
                        ++badKeys;
                    prev = tm;
                }
            }
        }
        if (badKeys)
            sane = false;
        d << " bones=" << nb << " anims=" << na << " keys=" << keys << " badKeys=" << badKeys << " maxLen=" << maxLen;
        c.ok = sane;
        c.detail = d.str();
        if (!preloaded)
        {
            s->unload();
            SkeletonManager::getSingleton().remove(s->getHandle());
        }
    }

    void batchOne(void* p)
    {
        BatchItem* c = static_cast<BatchItem*>(p);
        try
        {
            if (c->isMesh)
                checkMesh(*c);
            else
                checkSkeleton(*c);
        }
        catch (Exception& e)
        {
            c->ok = false;
            c->detail = "Ogre::Exception: " + e.getFullDescription();
        }
        catch (std::exception& e)
        {
            c->ok = false;
            c->detail = std::string("std::exception: ") + e.what();
        }
    }

    // SEH guard (no C++ objects in this frame): a malformed file must not kill the whole batch.
    int sehInvoke(void (*fn)(void*), void* ctx, unsigned long* code)
    {
        __try
        {
            fn(ctx);
            return 0;
        }
        __except (EXCEPTION_EXECUTE_HANDLER)
        {
            *code = GetExceptionCode();
            return 1;
        }
    }

    std::string csvField(std::string s)
    {
        for (size_t i = 0; i < s.size(); ++i)
            if (s[i] == '"' || s[i] == '\n' || s[i] == '\r')
                s[i] = '\'';
        return "\"" + s + "\"";
    }

    void runBatch(const Options& opt)
    {
        Archive* arc = ArchiveManager::getSingleton().load(opt.data + "\\ModelFolder", "FileSystem");
        StringVectorPtr meshes = arc->find("*.mesh", false);
        StringVectorPtr skels = arc->find("*.skeleton", false);
        std::vector<std::string> ms(meshes->begin(), meshes->end());
        std::vector<std::string> ss(skels->begin(), skels->end());
        std::sort(ms.begin(), ms.end());
        std::sort(ss.begin(), ss.end());
        std::mt19937 rng(opt.seed);
        std::shuffle(ms.begin(), ms.end(), rng);
        std::shuffle(ss.begin(), ss.end(), rng);
        if ((int)ms.size() > opt.batch)
            ms.resize(opt.batch);
        if ((int)ss.size() > opt.batch)
            ss.resize(opt.batch);
        say("batch: ModelFolder has " + StringConverter::toString((int)meshes->size()) + " .mesh / " +
            StringConverter::toString((int)skels->size()) + " .skeleton; testing " +
            StringConverter::toString((int)ss.size()) + " skeletons + " + StringConverter::toString((int)ms.size()) +
            " meshes (seed " + StringConverter::toString(opt.seed) + ")");

        std::vector<BatchItem> items;
        for (size_t i = 0; i < ss.size(); ++i)
            items.push_back(BatchItem{ false, ss[i], false, "" });
        for (size_t i = 0; i < ms.size(); ++i)
            items.push_back(BatchItem{ true, ms[i], false, "" });

        int okMesh = 0, okSkel = 0, failMesh = 0, failSkel = 0;
        std::map<std::string, int> reasons;
        double t0 = nowSec();
        for (size_t i = 0; i < items.size(); ++i)
        {
            unsigned long code = 0;
            if (sehInvoke(&batchOne, &items[i], &code))
            {
                items[i].ok = false;
                char buf[64];
                std::sprintf(buf, "SEH exception 0x%08lX", code);
                items[i].detail = buf;
            }
            if (items[i].ok)
                (items[i].isMesh ? okMesh : okSkel)++;
            else
            {
                (items[i].isMesh ? failMesh : failSkel)++;
                reasons[items[i].detail.substr(0, 90)]++;
            }
            if (i % 50 == 49)
                pumpMessages();
        }
        double dt = nowSec() - t0;

        FILE* f = std::fopen((opt.out + "\\batch_results.csv").c_str(), "wb");
        if (f)
        {
            std::fputs("\xEF\xBB\xBFkind,name,ok,detail\r\n", f);
            for (size_t i = 0; i < items.size(); ++i)
            {
                std::string line = std::string(items[i].isMesh ? "mesh," : "skeleton,") + csvField(gbkToUtf8(items[i].name)) +
                                   (items[i].ok ? ",1," : ",0,") + csvField(gbkToUtf8(items[i].detail)) + "\r\n";
                std::fputs(line.c_str(), f);
            }
            std::fclose(f);
        }
        say("batch: skeletons ok " + StringConverter::toString(okSkel) + " / fail " + StringConverter::toString(failSkel) +
            "; meshes ok " + StringConverter::toString(okMesh) + " / fail " + StringConverter::toString(failMesh) +
            "; " + StringConverter::toString(Real(dt)) + " s");
        for (std::map<std::string, int>::iterator it = reasons.begin(); it != reasons.end(); ++it)
            say("  fail x" + StringConverter::toString(it->second) + ": " + gbkToUtf8(it->first));
    }

    // ---------------------------------------------------------------- CYS: Ogre.log census
    // Counts the material/shader/texture problems the material-parity work targets.
    struct Census
    {
        std::map<std::string, int> byKey; // "category: detail" -> count
        std::map<std::string, int> totals; // category -> count
        void add(const std::string& cat, const std::string& detail)
        {
            totals[cat]++;
            byKey[cat + ": " + detail]++;
        }
    };

    std::string afterToken(const std::string& line, const char* token)
    {
        size_t p = line.find(token);
        if (p == std::string::npos)
            return std::string();
        return trimCopy(line.substr(p + std::strlen(token)));
    }

    void censusLog(const std::string& logPath, const std::string& outPath)
    {
        std::ifstream f(logPath.c_str(), std::ios::binary);
        if (!f)
        {
            say("census: cannot open " + logPath);
            return;
        }
        Census c;
        std::string line;
        while (std::getline(f, line))
        {
            if (!line.empty() && line[line.size() - 1] == '\r')
                line.erase(line.size() - 1);
            std::string v;
            if (!(v = afterToken(line, "Unrecognised command:")).empty())
                c.add("unknown keyword", v);
            else if (line.find("Bad lighting attribute") != std::string::npos)
                c.add("bad lighting attribute", "lighting");
            else if (!(v = afterToken(line, "Invalid param_named_auto attribute - ")).empty() ||
                     !(v = afterToken(line, "Invalid param_indexed_auto attribute - ")).empty())
                c.add("unknown auto constant", v);
            else if (!(v = afterToken(line, "Invalid param_named attribute - ")).empty())
                c.add("bad param_named", v.substr(0, 120));
            else if (!(v = afterToken(line, "Cannot find codec for extension")).empty())
                c.add("missing image codec", v);
            else if (!(v = afterToken(line, "Error loading texture")).empty())
                c.add("texture load error", v.substr(0, v.find(". Texture layer")));
            else if (!(v = afterToken(line, "Cannot assemble D3D9 high-level shader")).empty())
                c.add("shader compile error", v.substr(0, v.find(' ')));
            else if (line.find("encountered an error during loading") != std::string::npos)
                c.add("program not supported", line.substr(line.find(':') == std::string::npos ? 0 : 10, 120));
            else if (!(v = afterToken(line, "Can't assign material")).empty())
                c.add("missing material", v.substr(0, v.find(" to SubEntity")));
            else if (line.find("Error in material") != std::string::npos || line.find("Error at line") != std::string::npos)
                c.add("other script error", line.substr(10, 160));
            // CYS: particle scripts (--particles)
            else if (!(v = afterToken(line, "Bad particle system attribute line: '")).empty())
                c.add("bad particle system attribute", v.substr(0, v.find_first_of(" \t'")));
            else if (!(v = afterToken(line, "Bad particle emitter attribute line: '")).empty())
                c.add("bad particle emitter attribute", v.substr(0, v.find_first_of(" \t'")) + " @" +
                    trimCopy(afterToken(v, "' for emitter").substr(0, afterToken(v, "' for emitter").find(" ("))));
            else if (!(v = afterToken(line, "Bad particle affector attribute line: '")).empty())
                c.add("bad particle affector attribute", v.substr(0, v.find_first_of(" \t'")) + " @" +
                    trimCopy(afterToken(v, "' for affector").substr(0, afterToken(v, "' for affector").find(" ("))));
            else if (!(v = afterToken(line, "Particle system emitter doesn't exists at line: '")).empty())
                c.add("unknown particle emitter type", trimCopy(v.substr(7, v.find('\'') - 7)));
            else if (!(v = afterToken(line, "Particle system affector doesn't exists at line: '")).empty())
                c.add("unknown particle affector type", trimCopy(v.substr(8, v.find('\'') - 8)));
            else if (!(v = afterToken(line, "CYS: particle script")).empty())
                c.add("particle script error", v.substr(v.rfind("': ") == std::string::npos ? 0 : v.rfind("': ") + 3, 100));
        }
        std::ostringstream o;
        o << "Ogre.log census: " << gbkToUtf8(logPath) << "\n\nTotals by category\n";
        for (std::map<std::string, int>::iterator it = c.totals.begin(); it != c.totals.end(); ++it)
            o << "  " << it->first << ": " << it->second << "\n";
        o << "\nDetails (count  category: detail)\n";
        for (std::map<std::string, int>::iterator it = c.byKey.begin(); it != c.byKey.end(); ++it)
            o << "  " << it->second << "  " << gbkToUtf8(it->first) << "\n";
        FILE* w = std::fopen(outPath.c_str(), "wb");
        if (w)
        {
            std::fputs("\xEF\xBB\xBF", w);
            std::fputs(o.str().c_str(), w);
            std::fclose(w);
        }
        for (std::map<std::string, int>::iterator it = c.totals.begin(); it != c.totals.end(); ++it)
            say("census: " + it->first + " = " + StringConverter::toString(it->second));
        if (c.totals.empty())
            say("census: no material/shader/texture warnings");
    }

    // ---------------------------------------------------------------- CYS: scene helpers
    struct Group
    {
        std::string label;
        std::vector<Entity*> ents;
        SceneNode* node;
        AxisAlignedBox bounds; // world bounds after placement
        std::vector<AnimationState*> anims;
    };

    void setGroupVisible(std::vector<Group>& groups, int only)
    {
        for (size_t g = 0; g < groups.size(); ++g)
            for (size_t e = 0; e < groups[g].ents.size(); ++e)
                groups[g].ents[e]->setVisible(only < 0 || (int)g == only);
    }

    // CYS: --provider-test. An AutoParamExternalProvider (OgreAutoParamExternalProvider.h) that fogs
    // the scene linearly in a warm grey between fogStart and fogEnd: checks the hook end to end.
    class SmokeProvider : public AutoParamExternalProvider
    {
    public:
        SmokeProvider() : fogStart(10), fogEnd(30), calls(0) {}
        Real fogStart, fogEnd;
        mutable size_t calls;
        bool getEnvironmentParams(const Camera* camera, EnvironmentParamBlock& out) const
        {
            (void)camera;
            ++calls;
            out.fogType = Vector4(0, 0, 0, 1); // linear
            out.fogColour = ColourValue(0.66f, 0.42f, 0.36f);
            out.fogParams = Vector4(0, fogStart, fogEnd, 1.0f / std::max(Real(0.001f), fogEnd - fogStart));
            out.valid |= EnvironmentParamBlock::EP_FOG;
            return true;
        }
    };

    // CYS: --intz. Shows the INTZ scene depth of the last window frame: a second scene manager draws a
    // full-screen quad whose pixel shader samples a 'content_type dsintz' unit (texture "CYS/DSIntZ")
    // into a render texture - which has its own depth buffer, so the INTZ texture is not bound as
    // depth while it is read - and that texture is saved as PNG. The hardware depth is linearised
    // with the main camera's near/far and mapped from zFrom (black) to zTo (white).
    bool captureIntzDepth(Root* root, RenderWindow* win, Real nearClip, Real farClip, Real zFrom, Real zTo,
                          const std::string& png)
    {
        const String grp = ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME;
        HighLevelGpuProgramManager& hm = HighLevelGpuProgramManager::getSingleton();
        HighLevelGpuProgramPtr vs = hm.createProgram("CYS/IntzDebug_VS", grp, "hlsl", GPT_VERTEX_PROGRAM);
        vs->setSource(
            "void main_vs(float4 pos : POSITION, float2 uv : TEXCOORD0,\n"
            "             out float4 oPos : POSITION, out float2 oUv : TEXCOORD0)\n"
            "{ oPos = float4(pos.xy, 0.5, 1); oUv = uv; }\n");
        vs->setParameter("entry_point", "main_vs");
        vs->setParameter("target", "vs_2_0");
        HighLevelGpuProgramPtr ps = hm.createProgram("CYS/IntzDebug_PS", grp, "hlsl", GPT_FRAGMENT_PROGRAM);
        ps->setSource(
            "sampler2D depthTex : register(s0);\n"
            "float4 main_ps(float2 uv : TEXCOORD0, uniform float4 range) : COLOR\n"
            "{\n"
            "    float d = tex2D(depthTex, uv).r;\n"
            "    float z = range.x * range.y / (range.y - d * (range.y - range.x));\n"
            "    float v = saturate((z - range.z) / (range.w - range.z));\n"
            "    return float4(v, v, v, 1);\n"
            "}\n");
        ps->setParameter("entry_point", "main_ps");
        ps->setParameter("target", "ps_2_0");
        vs->load();
        ps->load();
        if (vs->hasCompileError() || ps->hasCompileError())
        {
            say("INTZ debug shaders failed to compile");
            return false;
        }
        MaterialPtr m = MaterialManager::getSingleton().create("CYS/IntzDebug", grp);
        Pass* p = m->getTechnique(0)->getPass(0);
        p->setLightingEnabled(false);
        p->setDepthCheckEnabled(false);
        p->setDepthWriteEnabled(false);
        p->setCullingMode(CULL_NONE);
        p->setVertexProgram("CYS/IntzDebug_VS");
        p->setFragmentProgram("CYS/IntzDebug_PS");
        p->getFragmentProgramParameters()->setNamedConstant("range", Vector4(nearClip, farClip, zFrom, zTo));
        TextureUnitState* t = p->createTextureUnitState();
        t->setContentType(TextureUnitState::CONTENT_DSINTZ);
        t->setTextureFiltering(TFO_NONE);
        t->setTextureAddressingMode(TextureUnitState::TAM_CLAMP);
        m->load();

        SceneManager* sm2 = root->createSceneManager(ST_GENERIC, "CYSIntzDebug");
        Camera* cam2 = sm2->createCamera("IntzCam");
        Rectangle2D* quad = new Rectangle2D(true);
        quad->setCorners(-1, 1, 1, -1);
        quad->setBoundingBox(AxisAlignedBox(Vector3(-1e6f, -1e6f, -1e6f), Vector3(1e6f, 1e6f, 1e6f)));
        quad->setMaterial("CYS/IntzDebug");
        sm2->getRootSceneNode()->attachObject(quad);
        TexturePtr tex = TextureManager::getSingleton().createManual("CYS/IntzDebugRT", grp, TEX_TYPE_2D,
            win->getWidth(), win->getHeight(), 0, PF_X8R8G8B8, TU_RENDERTARGET);
        RenderTarget* rt = tex->getBuffer()->getRenderTarget();
        rt->setAutoUpdated(false);
        Viewport* v = rt->addViewport(cam2);
        v->setBackgroundColour(ColourValue(1, 0, 1)); // magenta = the quad was not drawn
        v->setOverlaysEnabled(false);
        rt->update();
        std::vector<unsigned char> rgb;
        unsigned w = 0, h = 0;
        std::string err;
        const bool ok = captureBackBuffer(win, rgb, w, h, err, rt) && writePng(png, w, h, rgb);
        size_t near_ = 0, magenta = 0;
        for (size_t i = 0; i + 2 < rgb.size(); i += 3)
        {
            if (rgb[i] > 250 && rgb[i + 1] < 5 && rgb[i + 2] > 250)
                ++magenta;
            else if (rgb[i] < 250)
                ++near_;
        }
        const Real px = Real(std::max<size_t>(1, rgb.size() / 3));
        say("INTZ depth -> " + png + (ok ? std::string() : " FAILED (" + err + ")") + ": pixels nearer than the far range " +
            StringConverter::toString(Real(near_) * 100 / px) + " %, undrawn (magenta) " +
            StringConverter::toString(Real(magenta) * 100 / px) + " %");
        sm2->getRootSceneNode()->detachObject(quad);
        delete quad;
        rt->removeAllViewports();
        root->destroySceneManager(sm2);
        return ok;
    }

    bool renderAndCapture(Root* root, RenderWindow* win, std::vector<AnimationState*>& anims, int frames,
                          const std::string& png); // CYS: defined below

    // CYS: --particles. Parses client_GL EffectFolder\all.particle (read-only) with OGRE's particle
    // script parser. Only OGRE's ParticleFX emitter / affector types exist in this tool, so the
    // ParticleFX2 / Render.dll types show up as unknown in the census - but no block may abort the file.
    void parseParticleScripts(const std::string& path)
    {
        std::ifstream* in = new std::ifstream(path.c_str(), std::ios::in | std::ios::binary);
        if (!in->good())
        {
            delete in;
            say("particles: cannot open " + path);
            return;
        }
        DataStreamPtr stream(new FileStreamDataStream(path, in, true));
        ParticleSystemManager& pm = ParticleSystemManager::getSingleton();
        size_t before = 0, after = 0;
        for (ParticleSystemManager::ParticleSystemTemplateIterator it = pm.getTemplateIterator(); it.hasMoreElements(); it.moveNext())
            ++before;
        const double t0 = nowSec();
        try
        {
            pm.parseScript(stream, ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
        }
        catch (Exception& e)
        {
            say("particles: parse ABORTED: " + e.getDescription());
        }
        const double t1 = nowSec();
        for (ParticleSystemManager::ParticleSystemTemplateIterator it = pm.getTemplateIterator(); it.hasMoreElements(); it.moveNext())
            ++after;
        say("particles: " + path + " -> " + StringConverter::toString((int)(after - before)) + " templates in " +
            StringConverter::toString(Real(t1 - t0)) + " s");
    }

    // CYS: --cylinder-test. A Cylinder emitter with B's keys (inner_width / inner_height, angle_range,
    // topdown_ratio, curve, bendangle) is fast-forwarded and captured: a bent, waisted, open tube.
    bool cylinderTest(Root* root, RenderWindow* win, SceneManager* sm, Camera* cam, const Vector3& at,
                      const std::string& png)
    {
        const String grp = ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME;
        MaterialPtr m = MaterialManager::getSingleton().create("CYS/ParticleDot", grp);
        Pass* p = m->getTechnique(0)->getPass(0);
        p->setLightingEnabled(false);
        p->setSceneBlending(SBT_ADD);
        p->setDepthWriteEnabled(false);
        m->load();
        ParticleSystem* ps = sm->createParticleSystem("CYS/CylinderTest", 6000);
        ps->setMaterialName("CYS/ParticleDot");
        ps->setDefaultDimensions(0.03f, 0.03f);
        ParticleEmitter* em = ps->addEmitter("Cylinder");
        static const char* const keys[][2] = {
            { "width", "1.6" }, { "height", "1.6" }, { "depth", "2.4" }, { "direction", "0 1 0" },
            { "emission_rate", "6000" }, { "time_to_live", "1000" }, { "velocity", "0" }, { "angle", "0" },
            { "inner_width", "0.9" }, { "inner_height", "0.9" }, { "angle_range", "0 300" },
            { "topdown_ratio", "0.5 1" }, { "curve", "0.8" }, { "bendangle", "70" } };
        int rejected = 0;
        for (size_t k = 0; k < sizeof(keys) / sizeof(keys[0]); ++k)
        {
            if (!em->setParameter(keys[k][0], keys[k][1]))
            {
                ++rejected;
                say(std::string("cylinder test: key not accepted: ") + keys[k][0]);
            }
        }
        SceneNode* node = sm->getRootSceneNode()->createChildSceneNode(at);
        node->attachObject(ps);
        node->_update(true, false);
        ps->fastForward(1.5f, 0.05f);
        const Vector3 oldPos = cam->getPosition();
        const Quaternion oldRot = cam->getOrientation();
        cam->setPosition(at + Vector3(0.0f, 0.4f, 6.5f));
        cam->lookAt(at);
        std::vector<AnimationState*> none;
        const bool ok = renderAndCapture(root, win, none, 2, png);
        say("cylinder test -> " + png + ": particles " + StringConverter::toString((int)ps->getNumParticles()) +
            ", keys rejected " + StringConverter::toString(rejected) + ", inner " + em->getParameter("inner_width") +
            ", angle_range " + em->getParameter("angle_range") + ", topdown_ratio " + em->getParameter("topdown_ratio") +
            ", curve " + em->getParameter("curve") + ", bendangle " + em->getParameter("bendangle"));
        node->detachObject(ps);
        sm->destroyParticleSystem(ps);
        sm->destroySceneNode(node->getName());
        cam->setPosition(oldPos);
        cam->setOrientation(oldRot);
        return ok && rejected == 0;
    }

    // Render warm-up frames, then one frame without Present that is read back from the back buffer.
    bool renderAndCapture(Root* root, RenderWindow* win, std::vector<AnimationState*>& anims, int frames,
                          const std::string& png)
    {
        for (int f = 0; f < frames; ++f)
        {
            pumpMessages();
            for (size_t i = 0; i < anims.size(); ++i)
                anims[i]->addTime(1.0f / 30.0f);
            root->renderOneFrame();
        }
        win->update(false);
        std::vector<unsigned char> rgb;
        unsigned w = 0, h = 0;
        std::string err;
        bool ok = captureBackBuffer(win, rgb, w, h, err) && writePng(png, w, h, rgb);
        win->swapBuffers(false);
        pumpMessages();
        if (!ok)
            say("capture FAILED (" + err + "): " + png);
        return ok;
    }

    bool parseArgs(int argc, char** argv, Options& o)
    {
        for (int i = 1; i < argc; ++i)
        {
            std::string a = argv[i];
            bool hasNext = i + 1 < argc;
            if (a == "--data" && hasNext) o.data = argv[++i];
            else if (a == "--out" && hasNext) o.out = argv[++i];
            else if (a == "--mesh" && hasNext) o.meshes.push_back(argv[++i]);
            else if (a == "--frames" && hasNext) o.frames = std::atoi(argv[++i]);
            else if (a == "--batch" && hasNext) o.batch = std::atoi(argv[++i]);
            else if (a == "--seed" && hasNext) o.seed = (unsigned)std::strtoul(argv[++i], NULL, 10);
            else if (a == "--width" && hasNext) o.width = std::atoi(argv[++i]);
            else if (a == "--height" && hasNext) o.height = std::atoi(argv[++i]);
            else if (a == "--yaw" && hasNext) o.yawDeg = (float)std::atof(argv[++i]);
            else if (a == "--no-render") o.render = false;
            else if (a == "--no-fallback") o.fallback = false;
            else if (a == "--no-batch") o.doBatch = false;
            else if (a == "--list" && hasNext) o.list = argv[++i];                // CYS
            else if (a == "--shader-cache" && hasNext) o.shaderCache = argv[++i];  // CYS
            else if (a == "--no-shots") o.shots = false;                           // CYS
            else if (a == "--no-variants") o.variants = false;                     // CYS
            else if (a == "--fsaa" && hasNext) o.fsaa = std::atoi(argv[++i]);      // CYS
            else if (a == "--intz") o.intz = true;                                  // CYS
            else if (a == "--provider-test") o.providerTest = true;                 // CYS
            else if (a == "--set-param" && hasNext) o.setParams.push_back(argv[++i]); // CYS
            else if (a == "--no-ff-convert") o.ffConvert = false;                   // CYS
            else if (a == "--particles") o.particles = true;                        // CYS
            else if (a == "--cylinder-test") o.cylinderTest = true;                 // CYS
            else
            {
                std::printf("usage: OgreSmoke [--data DIR] [--out DIR] [--mesh NAME[+NAME]]... [--list FILE]\n"
                            "                 [--frames N] [--batch N] [--seed N] [--width W] [--height H]\n"
                            "                 [--yaw DEG] [--no-render] [--no-fallback] [--no-batch] [--no-shots]\n"
                            "                 [--shader-cache DIR|off] [--no-variants] [--fsaa N] [--intz]\n"
                            "                 [--provider-test] [--set-param GROUP:NAME=x,y,z,w]...\n"
                            "                 [--no-ff-convert] [--particles] [--cylinder-test]\n");
                return false;
            }
        }
        if (o.out.empty())
            o.out = exeDir();
        for (size_t i = o.labels.size(); i < o.meshes.size(); ++i)
            o.labels.push_back(gbkToUtf8(o.meshes[i]));
        if (!o.list.empty() && !loadList(o.list, o.meshes, o.labels)) // CYS
        {
            std::printf("cannot read --list %s\n", o.list.c_str());
            return false;
        }
        if (o.meshes.empty())
        {
            o.meshes.push_back("npc_CR_2021zuoqijineng.mesh");
            o.labels.push_back("npc_CR_2021zuoqijineng.mesh");
        }
        return true;
    }
}

int main(int argc, char** argv)
{
    if (argc > 1 && std::strcmp(argv[1], "--upgrade-login-mesh") == 0)
        return CysMeshUpgrade::run(argc, argv);
    SetConsoleOutputCP(CP_UTF8);
    Options opt;
    if (!parseArgs(argc, argv, opt))
        return 2;
    CreateDirectoryA(opt.out.c_str(), NULL);
    g_outDir = opt.out;
    SetUnhandledExceptionFilter(&crashFilter); // stack + minidump into --out on a crash

    int rc = 0;
    Root* root = NULL;
    SmokeProvider provider; // CYS: --provider-test
    try
    {
        double t0 = nowSec();
        root = new Root("", "", exeDir() + "\\Ogre.log"); // no plugins.cfg, no ogre.cfg, no dialog
        say("OgreSmoke x64: Root created (OGRE " + StringConverter::toString(OGRE_VERSION_MAJOR) + "." +
            StringConverter::toString(OGRE_VERSION_MINOR) + "." + StringConverter::toString(OGRE_VERSION_PATCH) + ")");

        root->loadRenderPlugins_D3D9(); // as WXRender RenderSystem.cpp:411
        root->loadInnerPlugins();       // as WXRender RenderSystem.cpp:413
        RenderSystem* rs = root->getRenderSystem();
        say("render system: " + (rs ? rs->getName() : String("NONE")));
        if (!rs)
            OGRE_EXCEPT(Exception::ERR_RENDERINGAPI_ERROR, "no render system", "OgreSmoke");

        root->initialise(false);
        NameValuePairList misc;
        misc["vsync"] = "false";
        misc["FSAA"] = StringConverter::toString(opt.intz ? 0 : opt.fsaa); // CYS: INTZ depth needs FSAA 0
        if (opt.intz)
            misc["cysIntzDepth"] = "true"; // CYS: scene depth readable as 'content_type dsintz'
        RenderWindow* win = root->createRenderWindow("CYS OgreSmoke x64", opt.width, opt.height, false, &misc);
        say("window " + StringConverter::toString(opt.width) + "x" + StringConverter::toString(opt.height) + " created");
        if (opt.providerTest)
            root->addAutoParamExternalProvider(&provider); // CYS

        // READ-ONLY resource locations, same layout as client_GL\Bin\FairyResources.cfg
        ResourceGroupManager& rgm = ResourceGroupManager::getSingleton();
        rgm.createResourceGroup("Bootstrap");
        rgm.addResourceLocation(opt.data + "\\OgreCore.zip", "Zip", "Bootstrap");
        rgm.addResourceLocation(opt.data + "\\MaterialTemplates.zip", "Zip", "Bootstrap");
        static const char* const folders[] = { "ModelFolder", "Model2Folder", "Model3Folder", "MaterialFolder",
                                               "Material2Folder", "Material3Folder", "Material4Folder", "Material5Folder" };
        for (size_t i = 0; i < sizeof(folders) / sizeof(folders[0]); ++i)
            rgm.addResourceLocation(opt.data + "\\" + folders[i], "FileSystem", "General");

        MaterialManager::getSingleton().setDefaultTextureFiltering(TFO_ANISOTROPIC);
        MaterialManager::getSingleton().setDefaultAnisotropy(8);

#ifdef CYS_WXRENDER_MATERIAL_SYSTEM
        {
            // CYS: as WXRender CRenderSystem does before parsing scripts (they compile programs)
            std::string cache = opt.shaderCache.empty() ? exeDir() + "\\ShaderCache" :
                (opt.shaderCache == "off" ? std::string() : opt.shaderCache);
            CYS::MaterialSystem::getSingleton().install(cache, opt.data + "\\MaterialTemplates.zip");
            CYS::MaterialSystem::getSingleton().setVariantsEnabled(opt.variants);
            CYS::MaterialSystem::getSingleton().setFixedFunctionConversion(opt.ffConvert); // CYS
            say(std::string("material system: runtime variants ") + (opt.variants ? "on" : "off") +
                ", shader cache " + (cache.empty() ? std::string("off") : cache));
        }
#endif

        double t1 = nowSec();
        rgm.initialiseResourceGroup("Bootstrap");
        double t2 = nowSec();
        rgm.initialiseResourceGroup("General");
        double t3 = nowSec();
#ifdef CYS_OGRE_MATERIAL_PARITY
        say("shader cache after scripts: hits " + StringConverter::toString(GpuProgramManager::getMicrocodeCacheHits()) +
            ", misses (compiled) " + StringConverter::toString(GpuProgramManager::getMicrocodeCacheMisses()));
#endif
        int nMat = 0;
        {
            ResourceManager::ResourceMapIterator it = MaterialManager::getSingleton().getResourceIterator();
            while (it.hasMoreElements())
            {
                it.getNext();
                ++nMat;
            }
        }
        say("resources: Bootstrap " + StringConverter::toString(Real(t2 - t1)) + " s, General " +
            StringConverter::toString(Real(t3 - t2)) + " s, materials defined: " + StringConverter::toString(nMat));
        if (opt.particles) // CYS
            parseParticleScripts(opt.data + "\\EffectFolder\\all.particle");

        if (opt.render)
        {
            SceneManager* sm = root->createSceneManager(ST_GENERIC, "CYSSmoke");
            // CYS: key + fill directional lights + ambient, so that per-pixel shading is visible.
            // Directions point from the light into the scene; the camera looks down -Z.
            const ColourValue ambient(0.30f, 0.31f, 0.36f);
            const ColourValue keyCol(1.00f, 0.95f, 0.86f);
            const ColourValue fillCol(0.42f, 0.48f, 0.60f);
            sm->setAmbientLight(ambient);
            Light* key = sm->createLight("Key");
            key->setType(Light::LT_DIRECTIONAL);
            key->setDirection(Vector3(0.55f, -0.62f, -0.56f).normalisedCopy());
            key->setDiffuseColour(keyCol);
            key->setSpecularColour(ColourValue(1.0f, 1.0f, 1.0f));
            Light* fill = sm->createLight("Fill");
            fill->setType(Light::LT_DIRECTIONAL);
            fill->setDirection(Vector3(-0.75f, -0.20f, -0.35f).normalisedCopy());
            fill->setDiffuseColour(fillCol);
            fill->setSpecularColour(ColourValue(0.25f, 0.25f, 0.3f));
            say("lights: key " + StringConverter::toString(keyCol) + ", fill " + StringConverter::toString(fillCol) +
                ", ambient " + StringConverter::toString(ambient));
            Camera* cam = sm->createCamera("Cam");
            Viewport* vp = win->addViewport(cam);
            vp->setBackgroundColour(ColourValue(0.21f, 0.23f, 0.28f));
            vp->setOverlaysEnabled(false);
            cam->setAspectRatio(Real(vp->getActualWidth()) / Real(vp->getActualHeight()));

            // Build the groups; each is normalised to radius 1 and placed in a grid cell.
            std::vector<Group> groups;
            int fallbacks = 0;
            int entSerial = 0;
            for (size_t i = 0; i < opt.meshes.size(); ++i)
            {
                Group grp;
                grp.label = opt.labels[i];
                grp.node = sm->getRootSceneNode()->createChildSceneNode();
                say("group " + StringConverter::toString((int)i) + ": " + grp.label);
                std::vector<std::string> parts = splitGroup(opt.meshes[i]);
                String animName;
                for (size_t p = 0; p < parts.size(); ++p)
                {
                    Entity* ent = NULL;
                    try
                    {
                        ent = sm->createEntity("Ent" + StringConverter::toString(entSerial++), parts[p]);
                    }
                    catch (Exception& e)
                    {
                        say("  mesh " + gbkToUtf8(parts[p]) + " FAILED: " + e.getDescription());
                        continue;
                    }
                    MeshPtr mesh = ent->getMesh();
                    say("  mesh " + gbkToUtf8(parts[p]) + ": submeshes=" + StringConverter::toString(mesh->getNumSubMeshes()) +
                        " skeleton='" + gbkToUtf8(mesh->getSkeletonName()) + "' bones=" +
                        (mesh->getSkeleton().isNull() ? String("0") : StringConverter::toString(mesh->getSkeleton()->getNumBones())));
                    applyMaterialsOrFallback(ent, opt.fallback, fallbacks);
                    ent->setNormaliseNormals(true); // groups are scaled
                    AnimationState* st = NULL;
                    if (!animName.empty() && ent->getAllAnimationStates() &&
                        ent->getAllAnimationStates()->hasAnimationState(animName))
                        st = ent->getAnimationState(animName);
                    else if (animName.empty())
                        st = pickAnimation(ent);
                    if (st)
                    {
                        st->setEnabled(true);
                        st->setLoop(true);
                        grp.anims.push_back(st);
                        if (animName.empty())
                        {
                            animName = st->getAnimationName();
                            say("  playing '" + gbkToUtf8(animName) + "' length " + StringConverter::toString(st->getLength()) + " s");
                        }
                    }
                    grp.node->attachObject(ent);
                    grp.ents.push_back(ent);
                }
                grp.node->yaw(Degree(opt.yawDeg));
                grp.node->_update(true, false);
                AxisAlignedBox b;
                for (size_t e = 0; e < grp.ents.size(); ++e)
                    b.merge(grp.ents[e]->getWorldBoundingBox(true));
                if (b.isNull())
                    b.setExtents(Vector3(-1, 0, -1), Vector3(1, 2, 1));
                Real r = std::max(Real(0.001), b.getHalfSize().length());
                Real s = Real(1) / r;
                grp.node->setScale(s, s, s);
                // centre on x/z, feet on y = 0 (in scaled units)
                Vector3 c = b.getCenter();
                grp.node->setPosition(-c.x * s, -b.getMinimum().y * s, -c.z * s);
                groups.push_back(grp);
            }
            const int n = (int)groups.size();
            const Real aspect = Real(vp->getActualWidth()) / Real(vp->getActualHeight());
            int cols = std::max(1, (int)std::ceil(std::sqrt(n * aspect)));
            int rows = std::max(1, (n + cols - 1) / cols);
            const Real cell = 2.3f;
            std::vector<AnimationState*> anims;
            AxisAlignedBox all;
            for (int g = 0; g < n; ++g)
            {
                int cx = g % cols, cy = g / cols;
                Vector3 off((cx - (cols - 1) * 0.5f) * cell, ((rows - 1) * 0.5f - cy) * cell * 1.15f - 1.0f, 0);
                groups[g].node->translate(off);
                groups[g].node->_update(true, false);
                AxisAlignedBox b;
                for (size_t e = 0; e < groups[g].ents.size(); ++e)
                    b.merge(groups[g].ents[e]->getWorldBoundingBox(true));
                groups[g].bounds = b;
                all.merge(b);
                anims.insert(anims.end(), groups[g].anims.begin(), groups[g].anims.end());
            }
            const Real fovy = Degree(30).valueRadians();
            cam->setFOVy(Radian(fovy));
            cam->setNearClipDistance(0.05f);
            cam->setFarClipDistance(500.0f);
            Vector3 gc = all.isNull() ? Vector3::ZERO : all.getCenter();
            Real halfH = rows * cell * 1.15f * 0.5f * 1.04f, halfW = cols * cell * 0.5f * 1.04f;
            Real dist = std::max(halfH / std::tan(fovy * 0.5f), halfW / (std::tan(fovy * 0.5f) * aspect)) + 1.0f;
            cam->setPosition(gc + Vector3(0, 0, dist));
            cam->lookAt(gc);
            say("grid " + StringConverter::toString(cols) + "x" + StringConverter::toString(rows) + ", fallback materials " +
                StringConverter::toString(fallbacks));
            // CYS: fog of --provider-test across the depth of the grid
            provider.fogStart = dist - 1.0f;
            provider.fogEnd = dist + 2.0f;
#ifdef CYS_WXRENDER_MATERIAL_SYSTEM
            // CYS: --set-param GROUP:NAME=x,y,z,w - per-entity named constant (Render.dll instance params)
            for (size_t k = 0; k < opt.setParams.size(); ++k)
            {
                const std::string& spec = opt.setParams[k];
                const size_t colon = spec.find(':'), eq = spec.find('=');
                if (colon == std::string::npos || eq == std::string::npos || eq < colon)
                {
                    say("--set-param " + spec + ": expected GROUP:NAME=x,y,z,w");
                    continue;
                }
                const int g = std::atoi(spec.substr(0, colon).c_str());
                const String pname = spec.substr(colon + 1, eq - colon - 1);
                float val[4] = { 0, 0, 0, 0 };
                std::sscanf(spec.c_str() + eq + 1, "%f,%f,%f,%f", &val[0], &val[1], &val[2], &val[3]);
                if (g < 0 || g >= n)
                {
                    say("--set-param " + spec + ": no group " + StringConverter::toString(g));
                    continue;
                }
                int applied = 0;
                for (size_t e = 0; e < groups[g].ents.size(); ++e)
                    if (CYS::MaterialSystem::getSingleton().setEntityParam(groups[g].ents[e], pname,
                            Vector4(val[0], val[1], val[2], val[3])))
                        ++applied;
                char vbuf[96];
                std::sprintf(vbuf, "(%g, %g, %g, %g)", val[0], val[1], val[2], val[3]);
                say("set-param group " + StringConverter::toString(g) + " (" + groups[g].label + "): " + pname + " = " +
                    vbuf + " on " + StringConverter::toString(applied) + " of " +
                    StringConverter::toString((int)groups[g].ents.size()) + " entities");
            }
#endif

            double tr0 = nowSec();
            std::string gridPng = opt.out + "\\grid.png";
            if (!renderAndCapture(root, win, anims, opt.frames, gridPng))
                rc = 1;
            double tr1 = nowSec();
            say("rendered " + StringConverter::toString(opt.frames) + " frames in " + StringConverter::toString(Real(tr1 - tr0)) +
                " s (incl. first-use shader compiles); last frame " + StringConverter::toString(win->getLastFPS()) +
                " fps, triangles " + StringConverter::toString(win->getTriangleCount()) + " -> grid.png");
#ifdef CYS_WXRENDER_MATERIAL_SYSTEM
            say("material system: " + CYS::MaterialSystem::getSingleton().getStats());
#endif
            if (opt.providerTest) // CYS
                say("auto-constant provider: " + StringConverter::toString(provider.calls) + " environment calls, fog " +
                    StringConverter::toString(provider.fogStart) + " .. " + StringConverter::toString(provider.fogEnd));
            if (opt.intz && !captureIntzDepth(root, win, cam->getNearClipDistance(), cam->getFarClipDistance(),
                                              dist - 1.5f, dist + 1.5f, opt.out + "\\intz_depth.png")) // CYS
                rc = 1;
            if (opt.cylinderTest) // CYS
            {
                setGroupVisible(groups, (int)groups.size()); // hide the models
                if (!cylinderTest(root, win, sm, cam, gc, opt.out + "\\cylinder.png"))
                    rc = 1;
                setGroupVisible(groups, -1);
            }

            if (opt.shots)
            {
                for (int g = 0; g < n; ++g)
                {
                    setGroupVisible(groups, g);
                    const AxisAlignedBox& b = groups[g].bounds;
                    if (b.isNull())
                        continue;
                    Vector3 c = b.getCenter();
                    Real r = std::max(Real(0.01), b.getHalfSize().length());
                    Real d = r / std::sin(fovy * 0.5f) * 1.02f;
                    Vector3 dir = Vector3(0.0f, 0.22f, 1.0f).normalisedCopy();
                    cam->setPosition(c + dir * d);
                    cam->lookAt(c);
                    char nm[64];
                    std::sprintf(nm, "\\shot_%02d.png", g);
                    if (renderAndCapture(root, win, anims, 3, opt.out + nm))
                        say("shot " + StringConverter::toString(g) + " -> " + (nm + 1) + "  (" + groups[g].label + ")");
                }
                setGroupVisible(groups, -1);
            }
        }

        if (opt.doBatch && opt.batch > 0)
            runBatch(opt);

        say("total " + StringConverter::toString(Real(nowSec() - t0)) + " s");
        censusLog(exeDir() + "\\Ogre.log", opt.out + "\\warnings.txt"); // CYS
    }
    catch (Exception& e)
    {
        say("FATAL Ogre::Exception: " + e.getFullDescription());
        rc = 1;
    }
    catch (std::exception& e)
    {
        say(std::string("FATAL std::exception: ") + e.what());
        rc = 1;
    }

    FILE* f = std::fopen((opt.out + "\\smoke_summary.txt").c_str(), "wb");
    if (f)
    {
        std::fputs("\xEF\xBB\xBF", f);
        std::fputs(g_summary.c_str(), f);
        std::fclose(f);
    }
#ifdef CYS_WXRENDER_MATERIAL_SYSTEM
    CYS::MaterialSystem::getSingleton().uninstall(); // CYS: drop material references before Root goes
#endif
    if (root && opt.providerTest)
        root->removeAutoParamExternalProvider(&provider); // CYS
    if (root)
    {
        try
        {
            delete root;
            std::printf("Root deleted cleanly\n");
        }
        catch (...)
        {
            std::printf("exception while deleting Root\n");
            rc = 1;
        }
    }
    // CYS: keep the log of this run next to its screenshots
    CopyFileA((exeDir() + "\\Ogre.log").c_str(), (opt.out + "\\Ogre.log").c_str(), FALSE);
    return rc;
}
