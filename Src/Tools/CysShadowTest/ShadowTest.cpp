// CysShadowTest - test bench of the CY-Source cascaded shadow maps (component shadow_test).
// CYS: new tool (2026-09-12).
//
//   CysShadowTest.exe [--data DIR] [--out DIR] [--models M07,M08,...] [--cases FILE] [--size 4096]
//                     [--width 1920] [--height 1080] [--timing N] [--stability N] [--no-shots] [--show]
//                     [--full-scripts] [--media DIR] [--test-media DIR]
//
// client_GL data is used READ-ONLY. The tool boots WX::System (script files parsed one by one, a broken file does
// not stop the others - as TlbbViewer), installs the WXRender runtime material system with SHADOWMAP_TYPE=1 so
// client_GL's templates receive shadows through ShaderLib/CalcShadow.inc (sampler s5 = "CYS/Shadow/0"), puts the
// oracle models (Tests/oracle/cases.json) and three props (pillar, ramp, sphere) on a ground plane under one
// directional sun, runs WX::CYSShadowSystem and writes into --out:
//   01_shadows_off.png  02_csm_<size>.png  03_cascades.png (tint per cascade + atlas strip)  04_atlas_<size>.png
//   05_gameview_*.png  06_closeup_*.png  07_b_receiver.png (ground shaded by B's CalcShadow.inc)  08_csm_2048.png
//   09_atlas_2048.png  10_simple.png  stability_stable.png / stability_tight.png (per-pixel change heat maps)
//   timing.tsv  shadow_summary.txt  Ogre.log
// The ground and props use the local test shader CysShadowTestReceiver.hlsl (engine CYSShadowLib.inc); the models
// keep their client_GL materials.

#include <windows.h>
#include <d3d9.h>
#include <d3dx9.h>
#include <dbghelp.h>

#include <algorithm>
#include <cmath>
#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <map>
#include <sstream>
#include <string>
#include <vector>

#include <OgreArchive.h>
#include <OgreCamera.h>
#include <OgreCompositorManager.h>
#include <OgreDataStream.h>
#include <OgreEntity.h>
#include <OgreException.h>
#include <OgreFontManager.h>
#include <OgreFrameListener.h>
#include <OgreHighLevelGpuProgram.h>
#include <OgreHighLevelGpuProgramManager.h>
#include <OgreGpuProgram.h>
#include <OgreLight.h>
#include <OgreLogManager.h>
#include <OgreManualObject.h>
#include <OgreMaterial.h>
#include <OgreMaterialManager.h>
#include <OgreMesh.h>
#include <OgreOverlayManager.h>
#include <OgreParticleSystem.h>
#include <OgreParticleSystemManager.h>
#include <OgrePass.h>
#include <OgreRenderSystem.h>
#include <OgreRenderTexture.h>
#include <OgreRenderWindow.h>
#include <OgreResourceGroupManager.h>
#include <OgreRoot.h>
#include <OgreSceneManager.h>
#include <OgreSceneNode.h>
#include <OgreScriptLoader.h>
#include <OgreStringConverter.h>
#include <OgreSubEntity.h>
#include <OgreTechnique.h>
#include <OgreTextureUnitState.h>
#include <OgreViewport.h>

#include "Core/FrameStatsListener.h"
#include "Core/WXSystem.h"
#include "EffectSystem/WXEffectManager.h"
#include "ModelSystem/WXLogicModel.h"
#include "ModelSystem/WXLogicModelManager.h"
#include "CYS/Shadow/CYSShadowHost.h"
#include "CYS/Shadow/CYSShadowPrograms.h"
#include "CYS/Shadow/CYSShadowSystem.h"
#include "MaterialSystem/CysMaterialSystem.h"

namespace
{
    const char* const kGroup = "CYSShadow";

    // ================================================================== options, text, logging
    struct Options
    {
        std::string data;
        std::string out;
        std::string cases;
        std::string media;
        std::string testMedia;
        std::vector<std::string> models;
        int width;
        int height;
        unsigned int size;
        int timingFrames;
        int stabilityFrames;
        bool show;
        bool fullScripts;
        bool shots;
        bool diag;              ///< CYS-SHADOW: receiver diagnostic (auto constants, s5, luminance in shade)
        std::string receivers;  ///< CYS-SHADOW: "cy" (default, B/CY rule) or "asis" (no receiver promotion)
        int level;              ///< CYS-SHADOW: --level N = CYSShadowHost::configForLevel(N) (-1: B defaults + --size)

        Options(void)
            : data("C:\\TLBB\\085\\client_GL\\Data")
            , out("C:\\TLBB\\085\\CY-Source\\Build\\Logs\\2026-09-12-shadow")
            , cases(CYS_ORACLE_CASES)
            , media(CYS_SHADOW_MEDIA_DIR)
            , testMedia(CYS_SHADOW_TEST_MEDIA_DIR)
            , width(1920)
            , height(1080)
            , size(4096)
            , timingFrames(150)
            , stabilityFrames(40)
            , show(false)
            , fullScripts(false)
            , shots(true)
            , diag(false)
            , receivers("cy")
            , level(-1)
        {
        }
    };

    std::string g_summary;
    char g_dumpPath[MAX_PATH] = { 0 };

    std::string convertCodePage(const std::string& s, UINT from, UINT to)
    {
        if (s.empty())
            return s;
        int wn = MultiByteToWideChar(from, 0, s.data(), (int)s.size(), NULL, 0);
        if (wn <= 0)
            return s;
        std::wstring w(wn, L'\0');
        MultiByteToWideChar(from, 0, s.data(), (int)s.size(), &w[0], wn);
        int n = WideCharToMultiByte(to, 0, w.data(), wn, NULL, 0, NULL, NULL);
        std::string r(n, '\0');
        WideCharToMultiByte(to, 0, w.data(), wn, &r[0], n, NULL, NULL);
        return r;
    }

    std::string utf8ToGbk(const std::string& s) { return convertCodePage(s, CP_UTF8, 936); }
    std::string gbkToUtf8(const std::string& s) { return convertCodePage(s, 936, CP_UTF8); }

    std::string wideToUtf8(const wchar_t* w)
    {
        int n = WideCharToMultiByte(CP_UTF8, 0, w, -1, NULL, 0, NULL, NULL);
        std::string r(n > 0 ? n - 1 : 0, '\0');
        if (n > 1)
            WideCharToMultiByte(CP_UTF8, 0, w, -1, &r[0], n, NULL, NULL);
        return r;
    }

    std::string format(const char* f, ...)
    {
        char buf[4096];
        va_list ap;
        va_start(ap, f);
        vsnprintf(buf, sizeof(buf), f, ap);
        va_end(ap);
        return buf;
    }

    void say(const std::string& s)
    {
        g_summary += s + "\n";
        std::printf("%s\n", s.c_str());
        std::fflush(stdout);
        if (Ogre::LogManager::getSingletonPtr())
            Ogre::LogManager::getSingleton().logMessage("[CysShadowTest] " + s, Ogre::LML_CRITICAL);
    }

    std::string exeDir(void)
    {
        char buf[MAX_PATH];
        DWORD n = GetModuleFileNameA(NULL, buf, MAX_PATH);
        std::string p(buf, n);
        size_t s = p.find_last_of("\\/");
        return s == std::string::npos ? std::string(".") : p.substr(0, s);
    }

    std::vector<std::string> split(const std::string& s, char sep)
    {
        std::vector<std::string> out;
        std::stringstream ss(s);
        std::string item;
        while (std::getline(ss, item, sep))
            if (!item.empty())
                out.push_back(item);
        return out;
    }

    LONG WINAPI crashFilter(EXCEPTION_POINTERS* ep)
    {
        void* address = (ep && ep->ExceptionRecord) ? ep->ExceptionRecord->ExceptionAddress : NULL;
        HMODULE module = NULL;
        char moduleName[MAX_PATH] = "?";
        if (address && GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
                                          GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT, (LPCSTR)address, &module))
            GetModuleFileNameA(module, moduleName, MAX_PATH);
        std::fprintf(stderr, "CysShadowTest: CRASH 0x%08lX at %s+0x%llX\n",
                     ep && ep->ExceptionRecord ? ep->ExceptionRecord->ExceptionCode : 0, moduleName,
                     (unsigned long long)((const char*)address - (const char*)module));
        if (g_dumpPath[0])
        {
            HANDLE file = CreateFileA(g_dumpPath, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
            if (file != INVALID_HANDLE_VALUE)
            {
                MINIDUMP_EXCEPTION_INFORMATION info;
                info.ThreadId = GetCurrentThreadId();
                info.ExceptionPointers = ep;
                info.ClientPointers = FALSE;
                MiniDumpWriteDump(GetCurrentProcess(), GetCurrentProcessId(), file, MiniDumpNormal, &info, NULL, NULL);
                CloseHandle(file);
            }
        }
        std::fflush(stderr);
        TerminateProcess(GetCurrentProcess(), 3);
        return EXCEPTION_EXECUTE_HANDLER;
    }

    bool parseArgs(int argc, wchar_t** argv, Options& o)
    {
        for (int i = 1; i < argc; ++i)
        {
            const std::string a = wideToUtf8(argv[i]);
            const bool next = i + 1 < argc;
            if (a == "--data" && next) o.data = wideToUtf8(argv[++i]);
            else if (a == "--out" && next) o.out = wideToUtf8(argv[++i]);
            else if (a == "--cases" && next) o.cases = wideToUtf8(argv[++i]);
            else if (a == "--media" && next) o.media = wideToUtf8(argv[++i]);
            else if (a == "--test-media" && next) o.testMedia = wideToUtf8(argv[++i]);
            else if (a == "--models" && next) o.models = split(wideToUtf8(argv[++i]), ',');
            else if (a == "--width" && next) o.width = std::atoi(wideToUtf8(argv[++i]).c_str());
            else if (a == "--height" && next) o.height = std::atoi(wideToUtf8(argv[++i]).c_str());
            else if (a == "--size" && next) o.size = (unsigned int)std::atoi(wideToUtf8(argv[++i]).c_str());
            else if (a == "--timing" && next) o.timingFrames = std::atoi(wideToUtf8(argv[++i]).c_str());
            else if (a == "--stability" && next) o.stabilityFrames = std::atoi(wideToUtf8(argv[++i]).c_str());
            else if (a == "--no-shots") o.shots = false;
            else if (a == "--show") o.show = true;
            else if (a == "--full-scripts") o.fullScripts = true;
            else if (a == "--diag") o.diag = true;
            else if (a == "--receivers" && next) o.receivers = wideToUtf8(argv[++i]);
            else if (a == "--level" && next) o.level = std::atoi(wideToUtf8(argv[++i]).c_str());
            else
            {
                std::printf("usage: CysShadowTest [--data DIR] [--out DIR] [--models M07,M08,...] [--cases FILE]\n"
                            "       [--size 4096] [--width 1920] [--height 1080] [--timing N] [--stability N]\n"
                            "       [--no-shots] [--show] [--full-scripts] [--media DIR] [--test-media DIR]\n"
                            "       [--diag] [--receivers cy|asis]\n");
                return false;
            }
        }
        if (o.models.empty())
            o.models = split("M07,M08,M09,M19,M38,M40", ',');
        return true;
    }

    /// Tests/oracle/cases.json: model id -> obj name (UTF-8)
    std::string jsonValueAfter(const std::string& text, size_t keyEnd)
    {
        size_t colon = text.find(':', keyEnd);
        size_t q0 = colon == std::string::npos ? colon : text.find('"', colon);
        size_t q1 = q0 == std::string::npos ? q0 : text.find('"', q0 + 1);
        return (q0 == std::string::npos || q1 == std::string::npos) ? std::string() : text.substr(q0 + 1, q1 - q0 - 1);
    }

    std::map<std::string, std::string> loadCases(const std::string& path)
    {
        std::map<std::string, std::string> cases;
        std::ifstream f(path.c_str(), std::ios::binary);
        std::stringstream ss;
        ss << f.rdbuf();
        const std::string text = ss.str();
        size_t pos = 0;
        while ((pos = text.find("\"id\"", pos)) != std::string::npos)
        {
            const std::string id = jsonValueAfter(text, pos + 4);
            const size_t next = text.find("\"id\"", pos + 4);
            const size_t obj = text.find("\"obj\"", pos + 4);
            if (obj != std::string::npos && (next == std::string::npos || obj < next))
                cases[id] = jsonValueAfter(text, obj + 5);
            pos += 4;
        }
        return cases;
    }

    // ================================================================== WX::System with per-file script parsing
    class TestSystem : public WX::System
    {
    public:
        explicit TestSystem(bool fullScripts) : mFull(fullScripts), mFiles(0), mErrors(0) {}
        size_t scriptFiles(void) const { return mFiles; }
        size_t scriptErrors(void) const { return mErrors; }

    protected:
        virtual void _createResourceListener(void)
        {
            // Bootstrap is initialised in _loadResources like every other group.
        }

        virtual void _loadResources(void)
        {
            Ogre::ResourceGroupManager& rgm = Ogre::ResourceGroupManager::getSingleton();
            loadGroup(Ogre::ResourceGroupManager::BOOTSTRAP_RESOURCE_GROUP_NAME);
            const Ogre::StringVector groups = rgm.getResourceGroups();
            for (size_t i = 0; i < groups.size(); ++i)
                if (groups[i] != Ogre::ResourceGroupManager::BOOTSTRAP_RESOURCE_GROUP_NAME)
                    loadGroup(groups[i]);
        }

    private:
        struct ByOrder
        {
            bool operator()(Ogre::ScriptLoader* a, Ogre::ScriptLoader* b) const
            {
                return a->getLoadingOrder() < b->getLoadingOrder();
            }
        };

        void loadGroup(const Ogre::String& group)
        {
            Ogre::ResourceGroupManager& rgm = Ogre::ResourceGroupManager::getSingleton();
            std::vector<Ogre::ScriptLoader*> loaders;
            loaders.push_back(Ogre::MaterialManager::getSingletonPtr());
            if (Ogre::CompositorManager::getSingletonPtr())
                loaders.push_back(Ogre::CompositorManager::getSingletonPtr());
            if (Ogre::FontManager::getSingletonPtr())
                loaders.push_back(Ogre::FontManager::getSingletonPtr());
            Ogre::ScriptLoader* particles = Ogre::ParticleSystemManager::getSingletonPtr();
            loaders.push_back(particles);
            // EffectManager / LogicModelManager inherit ScriptLoader privately (C-style cast, as TlbbViewer)
            Ogre::ScriptLoader* effects = WX::EffectManager::getSingletonPtr() ?
                (Ogre::ScriptLoader*)WX::EffectManager::getSingletonPtr() : NULL;
            if (effects)
                loaders.push_back(effects);
            if (WX::LogicModelManager::getSingletonPtr())
                loaders.push_back((Ogre::ScriptLoader*)WX::LogicModelManager::getSingletonPtr());
            if (Ogre::OverlayManager::getSingletonPtr())
                loaders.push_back(Ogre::OverlayManager::getSingletonPtr());
            std::stable_sort(loaders.begin(), loaders.end(), ByOrder());

            for (size_t i = 0; i < loaders.size(); ++i)
                rgm._unregisterScriptLoader(loaders[i]);
            try
            {
                rgm.initialiseResourceGroup(group);
            }
            catch (const Ogre::Exception& e)
            {
                ++mErrors;
                say("initialiseResourceGroup(" + group + ") failed: " + e.getDescription());
            }
            for (size_t i = 0; i < loaders.size(); ++i)
                rgm._registerScriptLoader(loaders[i]);

            for (size_t i = 0; i < loaders.size(); ++i)
            {
                Ogre::ScriptLoader* loader = loaders[i];
                if (!mFull && (loader == particles || loader == effects))
                    continue; // effects / particles / skills are not needed for shadows (and take ~30 s)
                const Ogre::StringVector& patterns = loader->getScriptPatterns();
                for (Ogre::StringVector::const_iterator p = patterns.begin(); p != patterns.end(); ++p)
                {
                    Ogre::FileInfoListPtr files = rgm.findResourceFileInfo(group, *p);
                    for (Ogre::FileInfoList::iterator fi = files->begin(); fi != files->end(); ++fi)
                    {
                        ++mFiles;
                        try
                        {
                            Ogre::DataStreamPtr stream = fi->archive->open(fi->filename);
                            if (!stream.isNull())
                                loader->parseScript(stream, group);
                        }
                        catch (const Ogre::Exception& e)
                        {
                            ++mErrors;
                            Ogre::LogManager::getSingleton().logMessage("CysShadowTest: script error in " +
                                fi->filename + " (rest of the file skipped): " + e.getDescription());
                        }
                        catch (const std::exception& e)
                        {
                            ++mErrors;
                            Ogre::LogManager::getSingleton().logMessage("CysShadowTest: script error in " +
                                fi->filename + ": " + e.what());
                        }
                    }
                }
            }
        }

        bool mFull;
        size_t mFiles;
        size_t mErrors;
    };

    // ================================================================== GPU timing (D3D9 timestamp queries)
    class GpuTimer : public Ogre::RenderTargetListener
    {
    public:
        GpuTimer(void)
            : mDisjoint(0), mFreq(0), mFrameBegin(0), mFrameEnd(0), mShadowBegin(0), mShadowEnd(0),
              mShadowIssued(false), mActive(false)
        {
        }
        ~GpuTimer() { release(); }

        bool init(IDirect3DDevice9* dev)
        {
            release();
            if (!dev)
                return false;
            bool ok = SUCCEEDED(dev->CreateQuery(D3DQUERYTYPE_TIMESTAMPDISJOINT, &mDisjoint)) &&
                      SUCCEEDED(dev->CreateQuery(D3DQUERYTYPE_TIMESTAMPFREQ, &mFreq)) &&
                      SUCCEEDED(dev->CreateQuery(D3DQUERYTYPE_TIMESTAMP, &mFrameBegin)) &&
                      SUCCEEDED(dev->CreateQuery(D3DQUERYTYPE_TIMESTAMP, &mFrameEnd)) &&
                      SUCCEEDED(dev->CreateQuery(D3DQUERYTYPE_TIMESTAMP, &mShadowBegin)) &&
                      SUCCEEDED(dev->CreateQuery(D3DQUERYTYPE_TIMESTAMP, &mShadowEnd));
            if (!ok)
                release();
            return ok;
        }

        void release(void)
        {
            IDirect3DQuery9** qs[] = { &mDisjoint, &mFreq, &mFrameBegin, &mFrameEnd, &mShadowBegin, &mShadowEnd };
            for (size_t i = 0; i < sizeof(qs) / sizeof(qs[0]); ++i)
            {
                if (*qs[i])
                    (*qs[i])->Release();
                *qs[i] = 0;
            }
            mActive = false;
        }

        void beginFrame(void)
        {
            if (!mDisjoint)
                return;
            mDisjoint->Issue(D3DISSUE_BEGIN);
            mFrameBegin->Issue(D3DISSUE_END);
            mShadowIssued = false;
            mActive = true;
        }

        void endFrame(void)
        {
            if (!mActive)
                return;
            mFrameEnd->Issue(D3DISSUE_END);
            mDisjoint->Issue(D3DISSUE_END);
            mFreq->Issue(D3DISSUE_END);
        }

        void preRenderTargetUpdate(const Ogre::RenderTargetEvent&)
        {
            if (mActive)
                mShadowBegin->Issue(D3DISSUE_END);
        }

        void postRenderTargetUpdate(const Ogre::RenderTargetEvent&)
        {
            if (mActive)
            {
                mShadowEnd->Issue(D3DISSUE_END);
                mShadowIssued = true;
            }
        }

        /// Waits for the queries of the last frame: GPU ms of the whole frame and of the shadow atlas.
        bool resolve(double& frameMs, double& shadowMs)
        {
            if (!mActive)
                return false;
            mActive = false;
            BOOL disjoint = TRUE;
            UINT64 freq = 0, f0 = 0, f1 = 0, s0 = 0, s1 = 0;
            if (!wait(mDisjoint, &disjoint, sizeof(disjoint)) || !wait(mFreq, &freq, sizeof(freq)) ||
                !wait(mFrameBegin, &f0, sizeof(f0)) || !wait(mFrameEnd, &f1, sizeof(f1)))
                return false;
            if (mShadowIssued && (!wait(mShadowBegin, &s0, sizeof(s0)) || !wait(mShadowEnd, &s1, sizeof(s1))))
                return false;
            if (disjoint || !freq)
                return false;
            frameMs = double(f1 - f0) * 1000.0 / double(freq);
            shadowMs = mShadowIssued ? double(s1 - s0) * 1000.0 / double(freq) : 0.0;
            return true;
        }

    private:
        static bool wait(IDirect3DQuery9* q, void* data, DWORD size)
        {
            const DWORD start = GetTickCount();
            for (;;)
            {
                HRESULT hr = q->GetData(data, size, D3DGETDATA_FLUSH);
                if (hr == S_OK)
                    return true;
                if (hr != S_FALSE || GetTickCount() - start > 3000)
                    return false;
            }
        }

        IDirect3DQuery9* mDisjoint;
        IDirect3DQuery9* mFreq;
        IDirect3DQuery9* mFrameBegin;
        IDirect3DQuery9* mFrameEnd;
        IDirect3DQuery9* mShadowBegin;
        IDirect3DQuery9* mShadowEnd;
        bool mShadowIssued;
        bool mActive;
    };

    // ================================================================== small helpers
    double median(std::vector<double> v)
    {
        if (v.empty())
            return 0.0;
        std::sort(v.begin(), v.end());
        return v[v.size() / 2];
    }

    double mean(const std::vector<double>& v)
    {
        double s = 0;
        for (size_t i = 0; i < v.size(); ++i)
            s += v[i];
        return v.empty() ? 0.0 : s / double(v.size());
    }

    /// PNG through D3DX from 8-bit RGB rows.
    bool saveRgbPng(IDirect3DDevice9* dev, const std::string& path, unsigned w, unsigned h,
                    const std::vector<unsigned char>& rgb)
    {
        IDirect3DSurface9* s = NULL;
        if (!dev || FAILED(dev->CreateOffscreenPlainSurface(w, h, D3DFMT_A8R8G8B8, D3DPOOL_SYSTEMMEM, &s, NULL)))
            return false;
        D3DLOCKED_RECT lr;
        if (FAILED(s->LockRect(&lr, NULL, 0)))
        {
            s->Release();
            return false;
        }
        for (unsigned y = 0; y < h; ++y)
        {
            unsigned char* row = (unsigned char*)lr.pBits + (size_t)y * lr.Pitch;
            const unsigned char* src = &rgb[(size_t)y * w * 3];
            for (unsigned x = 0; x < w; ++x)
            {
                row[x * 4 + 0] = src[x * 3 + 2];
                row[x * 4 + 1] = src[x * 3 + 1];
                row[x * 4 + 2] = src[x * 3 + 0];
                row[x * 4 + 3] = 255;
            }
        }
        s->UnlockRect();
        HRESULT hr = D3DXSaveSurfaceToFileA(path.c_str(), D3DXIFF_PNG, s, NULL, NULL);
        s->Release();
        return SUCCEEDED(hr);
    }

    void collectEntities(Ogre::SceneNode* node, std::vector<Ogre::Entity*>& out)
    {
        Ogre::SceneNode::ObjectIterator it = node->getAttachedObjectIterator();
        while (it.hasMoreElements())
        {
            Ogre::Entity* e = dynamic_cast<Ogre::Entity*>(it.getNext());
            if (e)
                out.push_back(e);
        }
        Ogre::Node::ChildNodeIterator children = node->getChildIterator();
        while (children.hasMoreElements())
            collectEntities(static_cast<Ogre::SceneNode*>(children.getNext()), out);
    }

    Ogre::AxisAlignedBox worldBounds(Ogre::SceneNode* node)
    {
        node->_update(true, false);
        std::vector<Ogre::Entity*> ents;
        collectEntities(node, ents);
        Ogre::AxisAlignedBox box;
        for (size_t i = 0; i < ents.size(); ++i)
            box.merge(ents[i]->getWorldBoundingBox(true));
        return box;
    }

    /// Sets a fragment constant on the materials an entity actually renders (runtime variants included).
    void setEntityFragmentParam(Ogre::Entity* ent, const Ogre::String& name, const Ogre::Vector4& value)
    {
        for (unsigned int i = 0; i < ent->getNumSubEntities(); ++i)
        {
            Ogre::MaterialPtr m = ent->getSubEntity(i)->getMaterial();
            for (unsigned short t = 0; !m.isNull() && t < m->getNumTechniques(); ++t)
                for (unsigned short p = 0; p < m->getTechnique(t)->getNumPasses(); ++p)
                {
                    Ogre::Pass* pass = m->getTechnique(t)->getPass(p);
                    if (pass->hasFragmentProgram())
                        WX::CYSShadowPrograms::setConstant(pass->getFragmentProgramParameters(), name, value);
                }
        }
    }

    // ================================================================== CYS-SHADOW: receiver diagnostic
    /// Name of the constant whose register is 'reg' ("" = none), from the program's constant definitions.
    std::string constantAtRegister(const Ogre::GpuProgramParameters& p, size_t reg)
    {
        for (size_t d = 0; d < p.getNumConstantDefinitions(); ++d)
        {
            const Ogre::GpuProgramParameters::ConstantDefinition* def = p.getConstantDefinition(d);
            if (def && def->entryIndex == reg && def->elementType == Ogre::GpuProgramParameters::ET_REAL)
                return def->name;
        }
        return std::string();
    }

    std::string programDefines(const Ogre::String& programName)
    {
        if (programName.empty())
            return "-";
        Ogre::HighLevelGpuProgramPtr p = Ogre::HighLevelGpuProgramManager::getSingleton().getByName(programName);
        return p.isNull() ? "(low level)" : p->getParameter("preprocessor_defines");
    }

    /// One TSV row per rendered pass: programs, defines, s5 unit, the shadow / light auto constants with their
    /// registers and last values, and every array auto constant that writes into a register of another uniform.
    void describePassDiag(std::ostream& o, const std::string& prefix, Ogre::Pass* pass, size_t& clobbers)
    {
        typedef Ogre::GpuProgramParameters GP;
        o << prefix << '\t' << (pass->hasVertexProgram() ? pass->getVertexProgramName() : "-") << '\t'
          << (pass->hasFragmentProgram() ? pass->getFragmentProgramName() : "-") << '\t'
          << programDefines(pass->hasFragmentProgram() ? pass->getFragmentProgramName() : Ogre::StringUtil::BLANK) << '\t';
        bool s5 = false;
        for (unsigned short t = 0; t < pass->getNumTextureUnitStates(); ++t)
        {
            const Ogre::TextureUnitState* u = pass->getTextureUnitState(t);
            if (u->getSamplerRegisterIndex() == 5 && u->getContentType() == Ogre::TextureUnitState::CONTENT_SHADOW)
                s5 = true;
        }
        o << (s5 ? "s5=shadow" : "s5=none") << '\t';
        if (!pass->hasFragmentProgram())
        {
            o << "\n";
            return;
        }
        Ogre::GpuProgramParametersSharedPtr fp = pass->getFragmentProgramParameters();
        static const char* const names[] = { "light_diffuse_colour_array[0]", "light_diffuse_colour_array[1]",
            "light_diffuse_colour_array[2]", "light_position_array[0]", "shadow_param", "shadow_csm_param",
            "isystem_userdata", "imodel_userdata", "derived_scene_colour", "actor_lightone_params" };
        for (size_t n = 0; n < sizeof(names) / sizeof(names[0]); ++n)
        {
            const GP::ConstantDefinition* def = fp->getConstantDefinition(names[n]);
            if (!def)
            {
                o << names[n] << "=absent ";
                continue;
            }
            o << names[n] << "@c" << def->entryIndex;
            GP::RealConstantIterator it = fp->getRealConstantIterator();
            size_t reg = 0;
            while (it.hasMoreElements())
            {
                const GP::RealConstantEntry& e = it.getNext();
                if (reg++ == def->entryIndex)
                {
                    o << format("=(%.3g,%.3g,%.3g,%.3g)%s", e.val[0], e.val[1], e.val[2], e.val[3], e.isSet ? "" : "unset");
                    break;
                }
            }
            o << ' ';
        }
        GP::AutoConstantIterator ai = fp->getAutoConstantIterator();
        while (ai.hasMoreElements())
        {
            const GP::AutoConstantEntry& a = ai.getNext();
            if (a.paramType < GP::ACT_DERIVED_LIGHT_DIFFUSE_COLOUR_ARRAY || a.paramType > GP::ACT_LIGHT_POWER_SCALE_ARRAY ||
                a.paramType == GP::ACT_LIGHT_COUNT)
                continue;
            const GP::AutoConstantDefinition* ad = GP::getAutoConstantDefinition(static_cast<size_t>(a.paramType));
            for (size_t k = 1; k < a.data; ++k)
            {
                const std::string victim = constantAtRegister(*fp, a.index + k);
                if (!victim.empty() && victim.find('[') == std::string::npos)
                {
                    o << "CLOBBER " << (ad ? ad->name : std::string("?")) << "[" << k << "]->" << victim << ' ';
                    ++clobbers;
                }
            }
        }
        o << "\n";
    }

    /// mean Rec.601 luma of the pixels with mask[i] != 0
    double maskedLuma(const std::vector<unsigned char>& rgb, const std::vector<unsigned char>& mask, size_t& count)
    {
        double sum = 0;
        count = 0;
        for (size_t i = 0; i < mask.size() && (i + 1) * 3 <= rgb.size(); ++i)
            if (mask[i])
            {
                sum += 0.299 * rgb[i * 3] + 0.587 * rgb[i * 3 + 1] + 0.114 * rgb[i * 3 + 2];
                ++count;
            }
        return count ? sum / count : 0.0;
    }

    // ================================================================== the test
    struct ModelInfo
    {
        std::string id;
        std::string objUtf8;
        WX::LogicModel* model;
        Ogre::AxisAlignedBox bounds;
        std::string anim;

        ModelInfo(void) : model(0) {}
    };

    class ShadowTest
    {
    public:
        explicit ShadowTest(const Options& opt)
            : mOpt(opt), mHwnd(NULL), mLog(NULL), mSystem(NULL), mWindow(NULL), mCamera(NULL), mSceneMgr(NULL),
              mSun(NULL), mFitCamera(NULL), mGround(NULL), mDevice(NULL), mTiming(false), mHasB(false),
              mSceneRadius(1000.0f), mShutdown(false)
        {
        }

        ~ShadowTest() { shutdown(); }

        int run(HWND hwnd)
        {
            mHwnd = hwnd;
            try
            {
                initEngine();
                initShadows();
                buildScene();
                createModels();
                frameScene();
                settle(40, 1.0f / 30.0f); // shader variants compile on first use
                if (mOpt.diag)
                    runReceiverDiag();
                if (mOpt.shots)
                    runShots();
                if (mOpt.timingFrames > 0)
                    runTiming();
                if (mOpt.stabilityFrames > 0)
                    runStability();
            }
            catch (const Ogre::Exception& e)
            {
                say("FATAL Ogre::Exception: " + e.getFullDescription());
                writeSummary();
                return 1;
            }
            catch (const std::exception& e)
            {
                say(std::string("FATAL std::exception: ") + e.what());
                writeSummary();
                return 1;
            }
            writeSummary();
            return 0;
        }

        void shutdown(void)
        {
            if (mShutdown)
                return;
            mShutdown = true;
            if (mSystem)
            {
                if (WX::LogicModelManager::getSingletonPtr())
                {
                    for (size_t i = 0; i < mModels.size(); ++i)
                        if (mModels[i].model)
                            WX::LogicModelManager::getSingleton().destroyLogicModel(mModels[i].model);
                }
                mModels.clear();
                WX::CYSShadowSystem::getSingleton().shutdown();
                mTimer.release();
                if (mFitCamera && mSceneMgr)
                    mSceneMgr->destroyCamera(mFitCamera);
                mFitCamera = NULL;
                CYS::MaterialSystem::getSingleton().uninstall();
                delete mSystem;
                mSystem = NULL;
            }
            if (Ogre::LogManager::getSingletonPtr() == mLog)
                CopyFileA((mOpt.out + "\\Ogre.log").c_str(), (mOpt.out + "\\Ogre.log.bak").c_str(), FALSE);
            delete mLog;
            mLog = NULL;
        }

    private:
        // ------------------------------------------------------------------ engine
        void initEngine(void)
        {
            const std::string logFile = mOpt.out + "\\Ogre.log";
            mLog = new Ogre::LogManager();
            mLog->createLog(logFile, true, false, false);
            mLog->setLogDetail(Ogre::LL_NORMAL);

            mSystem = new TestSystem(mOpt.fullScripts);
            mSystem->init("", "", "", logFile);
            addResourceLocations();
            Ogre::Root* root = mSystem->getRoot();
            root->loadRenderPlugins_D3D9();
            root->loadInnerPlugins();
            Ogre::MaterialManager::getSingleton().setDefaultTextureFiltering(Ogre::TFO_ANISOTROPIC);
            Ogre::MaterialManager::getSingleton().setDefaultAnisotropy(8);

            // client_GL templates with runtime vertex-program pairing; SHADOWMAP_TYPE 1 = CSM receivers whose s5
            // sampler the material system binds to "CYS/Shadow/0" (the atlas).
            CYS::MaterialSystem& ms = CYS::MaterialSystem::getSingleton();
            ms.install(exeDir() + "\\ShaderCache", mOpt.data + "\\MaterialTemplates.zip");
            ms.setGlobalDefine("SHADOWMAP_TYPE", "1");
            ms.setShadowReceiverLighting(mOpt.receivers != "asis"); // CYS-SHADOW: VS-lit characters receive

            WX::System::NameValuePairList params;
            params["FSAA"] = "4";
            params["vsync"] = "false";
            const DWORD start = GetTickCount();
            mSystem->setup((size_t)(UINT_PTR)mHwnd, &params);
            say(format("engine ready in %.1f s: %u script files, %u script errors (effect/particle/skill scripts %s)",
                       (GetTickCount() - start) / 1000.0, (unsigned)mSystem->scriptFiles(),
                       (unsigned)mSystem->scriptErrors(), mOpt.fullScripts ? "parsed" : "skipped"));

            mWindow = mSystem->getRenderWindow();
            mWindow->setAutoUpdated(false); // rendered by renderFrame so the back buffer can be read first
            mCamera = mSystem->getCamera();
            mSceneMgr = mSystem->getSceneManager();
            mCamera->setNearClipDistance(25.0f);   // WX _adjustCamera: 0.25 * base scale 100
            mCamera->setFarClipDistance(30000.0f);
            mCamera->setFOVy(Ogre::Degree(45));
            Ogre::ParticleSystem::setDefaultIterationInterval(0.033f);
            WX::FrameStatsListener* stats = mSystem->getFrameStatsListener();
            if (stats)
            {
                stats->showLogoPanel(false);
                stats->showStatPanel(false);
                stats->showDebugOverlay(false);
            }
            WX::EffectManager& effects = WX::EffectManager::getSingleton();
            if (!effects.getTemplate("Effect_Error"))
                effects.createEffectTemplate("Effect_Error"); // missing effects fall back to it
            mWindow->getCustomAttribute("D3DDEVICE", &mDevice);
            say(format("window %ux%u, FSAA 4, render system %s", mWindow->getWidth(), mWindow->getHeight(),
                       Ogre::Root::getSingleton().getRenderSystem()->getName().c_str()));
        }

        void addFolderTree(const std::string& dir, const std::string& group, size_t& count)
        {
            Ogre::ResourceGroupManager::getSingleton().addResourceLocation(dir, "FileSystem", group, false);
            ++count;
            WIN32_FIND_DATAA fd;
            HANDLE h = FindFirstFileA((dir + "\\*").c_str(), &fd);
            if (h == INVALID_HANDLE_VALUE)
                return;
            std::vector<std::string> subdirs;
            do
            {
                if ((fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) && std::strcmp(fd.cFileName, ".") != 0 &&
                    std::strcmp(fd.cFileName, "..") != 0)
                    subdirs.push_back(dir + "\\" + fd.cFileName);
            } while (FindNextFileA(h, &fd));
            FindClose(h);
            for (size_t i = 0; i < subdirs.size(); ++i)
                addFolderTree(subdirs[i], group, count);
        }

        void addResourceLocations(void)
        {
            Ogre::ResourceGroupManager& rgm = Ogre::ResourceGroupManager::getSingleton();
            static const char* const zips[] = { "OgreCore.zip", "MaterialTemplates.zip" };
            for (size_t i = 0; i < 2; ++i)
                rgm.addResourceLocation(mOpt.data + "\\" + zips[i], "Zip",
                                        Ogre::ResourceGroupManager::BOOTSTRAP_RESOURCE_GROUP_NAME, false);
            // Models, materials, textures (client_GL\Bin\FairyResources.cfg layout); EffectFolder for its textures.
            static const char* const folders[] = { "ModelFolder", "Model2Folder", "Model3Folder", "Model4Folder",
                "Model5Folder", "Model6Folder", "Model7Folder", "Model8Folder", "MaterialFolder", "Material2Folder",
                "Material3Folder", "Material4Folder", "Material5Folder", "Material6Folder", "Material7Folder",
                "Material8Folder", "EffectFolder" };
            size_t count = 0;
            for (size_t i = 0; i < sizeof(folders) / sizeof(folders[0]); ++i)
            {
                const std::string dir = mOpt.data + "\\" + folders[i];
                DWORD attr = GetFileAttributesA(dir.c_str());
                if (attr != INVALID_FILE_ATTRIBUTES && (attr & FILE_ATTRIBUTE_DIRECTORY))
                    addFolderTree(dir, "General", count);
            }
            // shadow media: engine (caster fallback, debug view, CYSShadowLib.inc) + this tool's receivers
            rgm.addResourceLocation(mOpt.media, "FileSystem", kGroup, false);
            rgm.addResourceLocation(mOpt.testMedia, "FileSystem", kGroup, false);
            say(format("%u resource locations under %s; media %s, %s", (unsigned)count, mOpt.data.c_str(),
                       mOpt.media.c_str(), mOpt.testMedia.c_str()));
        }

        // ------------------------------------------------------------------ shadows + test programs
        void initShadows(void)
        {
            WX::CYSShadowConfig cfg;     // B defaults (CSM, 4 cascades), tile from the command line
            if (mOpt.level >= 0)         // CYS-SHADOW: the game's View_HumanLightmap level (CY constants)
                cfg = WX::CYSShadowHost::configForLevel(mOpt.level);
            else
                cfg.mapSize = mOpt.size;
            cfg.applyEnvironment();      // CYS_SHADOW_* overrides for experiments
            WX::CYSShadowSystem& shadows = WX::CYSShadowSystem::getSingleton();
            shadows.setUseEnvironment(false); // no scene: the test sun below drives the light
            if (!shadows.initialise(cfg, kGroup))
                throw std::runtime_error("CYSShadowSystem::initialise failed");
            shadows.attach(mSceneMgr, mCamera);
            mTimer.init(mDevice);
            ensureTimerListener();
            say("shadow config: " + shadows.getConfig().describe());
            say(format("atlas %s %ux%u R32F, %.0f MB (colour + depth), casters: %s",
                       shadows.getTextureName().c_str(), shadows.getAtlasTarget()->getWidth(),
                       shadows.getAtlasTarget()->getHeight(), shadows.getAtlasBytes() / 1048576.0,
                       shadows.getCasterProgramSource().c_str()));
            createPrograms();
        }

        void createPrograms(void)
        {
            using namespace WX::CYSShadowPrograms;
            typedef Ogre::GpuProgramParameters GP;
            const std::string pcf = "CYS_SHADOW_PCF_RADIUS=" +
                Ogre::StringConverter::toString(WX::CYSShadowSystem::getSingleton().getConfig().softness);
            Ogre::HighLevelGpuProgramPtr vs = createHlsl("CYSShadowTest/Receiver_VS", kGroup, "CysShadowTestReceiver.hlsl",
                "receiverVS", "vs_3_0", pcf, Ogre::GPT_VERTEX_PROGRAM);
            Ogre::HighLevelGpuProgramPtr ps = createHlsl("CYSShadowTest/Receiver_PS", kGroup, "CysShadowTestReceiver.hlsl",
                "receiverPS", "ps_3_0", pcf, Ogre::GPT_FRAGMENT_PROGRAM);
            if (vs.isNull() || ps.isNull())
                throw std::runtime_error("test receiver shaders do not compile (see Ogre.log)");
            Ogre::GpuProgramParametersSharedPtr d = vs->getDefaultParameters();
            setAuto(d, "world_matrix", GP::ACT_WORLD_MATRIX);
            setAuto(d, "viewproj_matrix", GP::ACT_VIEWPROJ_MATRIX);
            d = ps->getDefaultParameters();
            setAuto(d, "light_position", GP::ACT_LIGHT_POSITION, 0);
            setAuto(d, "light_diffuse_colour", GP::ACT_LIGHT_DIFFUSE_COLOUR, 0);
            setAuto(d, "ambient_light_colour", GP::ACT_AMBIENT_LIGHT_COLOUR);
            setAuto(d, "camera_position", GP::ACT_CAMERA_POSITION);
            bindShadowAutos(d);

            // same ground through client_GL's ShaderLib/CalcShadow.inc (validation of the provider)
            Ogre::HighLevelGpuProgramPtr bvs = createHlsl("CYSShadowTest/ReceiverB_VS", kGroup,
                "CysShadowTestReceiverB.hlsl", "receiverBVS", "vs_3_0", "SHADOWMAP_TYPE=1", Ogre::GPT_VERTEX_PROGRAM);
            Ogre::HighLevelGpuProgramPtr bps = createHlsl("CYSShadowTest/ReceiverB_PS", kGroup,
                "CysShadowTestReceiverB.hlsl", "receiverBPS", "ps_3_0", "SHADOWMAP_TYPE=1", Ogre::GPT_FRAGMENT_PROGRAM);
            mHasB = !bvs.isNull() && !bps.isNull();
            if (mHasB)
            {
                // Light arrays are bound by OgreMain's by-name binding with the element count the compiled program
                // allocates (here 1). An explicit count of 3 would write lights 1-2 into the registers after
                // element 0, which belong to other uniforms (it zeroed light_diffuse_colour_array[0]).
                d = bvs->getDefaultParameters();
                setAuto(d, "world_matrix", GP::ACT_WORLD_MATRIX);
                setAuto(d, "viewproj_matrix", GP::ACT_VIEWPROJ_MATRIX);
                bindShadowAutos(d);
                d = bps->getDefaultParameters();
                setAuto(d, "ambient_light_colour", GP::ACT_AMBIENT_LIGHT_COLOUR);
                setAuto(d, "camera_position", GP::ACT_CAMERA_POSITION);
                bindShadowAutos(d);
            }
            say(std::string("test receivers: CYSShadowLib.inc ok, B CalcShadow.inc path ") + (mHasB ? "ok" : "UNAVAILABLE"));
        }

        static void bindShadowAutos(const Ogre::GpuProgramParametersSharedPtr& d)
        {
            using namespace WX::CYSShadowPrograms;
            typedef Ogre::GpuProgramParameters GP;
            setAuto(d, "shadow_view_matrix", GP::ACT_SHADOW_VIEW_MATRIX);
            setAuto(d, "shadow_proj_matrix", GP::ACT_SHADOW_PROJ_MATRIX);
            setAuto(d, "shadow_param", GP::ACT_SHADOW_PARAMS);
            setAuto(d, "shadow_csm_param", GP::ACT_SHADOW_CSM_PARAMS);
            setAuto(d, "shadow_csm_proj_scale", GP::ACT_SHADOW_CSM_PROJ_SCALE);
            setAuto(d, "shadow_csm_proj_offset", GP::ACT_SHADOW_CSM_PROJ_OFFSET);
            setAuto(d, "isystem_userdata", GP::ACT_ISYSTEM_USERDATA);
        }

        void receiverMaterial(const std::string& name, bool bPath, const Ogre::Vector4& albedo)
        {
            Ogre::MaterialPtr mat = Ogre::MaterialManager::getSingleton().create(name, kGroup);
            Ogre::Pass* p = mat->getTechnique(0)->getPass(0);
            p->setCullingMode(Ogre::CULL_NONE);
            p->setVertexProgram(bPath ? "CYSShadowTest/ReceiverB_VS" : "CYSShadowTest/Receiver_VS");
            p->setFragmentProgram(bPath ? "CYSShadowTest/ReceiverB_PS" : "CYSShadowTest/Receiver_PS");
            Ogre::TextureUnitState* t = p->createTextureUnitState();
            t->setContentType(Ogre::TextureUnitState::CONTENT_SHADOW); // "CYS/Shadow/0"
            t->setCompositorReference(Ogre::StringUtil::BLANK, Ogre::StringUtil::BLANK, 0);
            t->setSamplerRegisterIndex(5);
            t->setTextureFiltering(Ogre::TFO_NONE);
            t->setTextureAddressingMode(Ogre::TextureUnitState::TAM_CLAMP);
            WX::CYSShadowPrograms::setConstant(p->getFragmentProgramParameters(), "albedo", albedo);
            WX::CYSShadowPrograms::setConstant(p->getFragmentProgramParameters(), "gridParams",
                                               Ogre::Vector4(100.0f, 0.0f, 0.0f, 1.0f));
            mat->load();
        }

        // ------------------------------------------------------------------ scene
        Ogre::Entity* addEntity(const std::string& name, const std::string& mesh, const std::string& material,
                                const Ogre::Vector3& pos, const Ogre::Vector3& scale, const Ogre::Quaternion& q,
                                bool casts)
        {
            Ogre::Entity* e = mSceneMgr->createEntity(name, mesh);
            e->setMaterialName(material);
            e->setCastShadows(casts);
            Ogre::SceneNode* n = mSystem->getBaseSceneNode()->createChildSceneNode();
            n->setPosition(pos);
            n->setScale(scale);
            n->setOrientation(q);
            n->attachObject(e);
            e->setNormaliseNormals(true);
            return e;
        }

        void buildBoxMesh(void)
        {
            Ogre::ManualObject* mo = mSceneMgr->createManualObject("CYSShadowTest/BoxBuilder");
            mo->begin("CYSShadowTest/Prop");
            // faces: normal n, in-plane axes u, v with u x v = n (counter-clockwise seen from outside)
            const Ogre::Vector3 axes[6][3] = {
                { Ogre::Vector3::UNIT_X, Ogre::Vector3::UNIT_Y, Ogre::Vector3::UNIT_Z },
                { Ogre::Vector3::NEGATIVE_UNIT_X, Ogre::Vector3::UNIT_Z, Ogre::Vector3::UNIT_Y },
                { Ogre::Vector3::UNIT_Y, Ogre::Vector3::UNIT_Z, Ogre::Vector3::UNIT_X },
                { Ogre::Vector3::NEGATIVE_UNIT_Y, Ogre::Vector3::UNIT_X, Ogre::Vector3::UNIT_Z },
                { Ogre::Vector3::UNIT_Z, Ogre::Vector3::UNIT_X, Ogre::Vector3::UNIT_Y },
                { Ogre::Vector3::NEGATIVE_UNIT_Z, Ogre::Vector3::UNIT_Y, Ogre::Vector3::UNIT_X },
            };
            for (int f = 0; f < 6; ++f)
            {
                const Ogre::Vector3& n = axes[f][0];
                const Ogre::Vector3& u = axes[f][1];
                const Ogre::Vector3& v = axes[f][2];
                const float su[4] = { -1, 1, 1, -1 }, sv[4] = { -1, -1, 1, 1 };
                for (int k = 0; k < 4; ++k)
                {
                    mo->position((n + u * su[k] + v * sv[k]) * 0.5f);
                    mo->normal(n);
                }
                const Ogre::uint16 b = Ogre::uint16(f * 4);
                mo->quad(b, b + 1, b + 2, b + 3);
            }
            mo->end();
            mo->convertToMesh("CYSShadowTest/Box.mesh", kGroup);
            mSceneMgr->destroyManualObject(mo);
        }

        void buildSphereMesh(void)
        {
            Ogre::ManualObject* mo = mSceneMgr->createManualObject("CYSShadowTest/SphereBuilder");
            mo->begin("CYSShadowTest/Prop");
            const int rings = 24, segments = 48;
            for (int r = 0; r <= rings; ++r)
            {
                const float theta = Ogre::Math::PI * float(r) / rings;
                for (int s = 0; s <= segments; ++s)
                {
                    const float phi = 2.0f * Ogre::Math::PI * float(s) / segments;
                    const Ogre::Vector3 p(std::sin(theta) * std::cos(phi), std::cos(theta), std::sin(theta) * std::sin(phi));
                    mo->position(p);
                    mo->normal(p);
                }
            }
            for (int r = 0; r < rings; ++r)
                for (int s = 0; s < segments; ++s)
                {
                    const Ogre::uint16 i0 = Ogre::uint16(r * (segments + 1) + s), i1 = Ogre::uint16(i0 + segments + 1);
                    mo->triangle(i0, Ogre::uint16(i0 + 1), i1);
                    mo->triangle(Ogre::uint16(i0 + 1), Ogre::uint16(i1 + 1), i1);
                }
            mo->end();
            mo->convertToMesh("CYSShadowTest/Sphere.mesh", kGroup);
            mSceneMgr->destroyManualObject(mo);
        }

        void buildScene(void)
        {
            mSceneMgr->setAmbientLight(Ogre::ColourValue(0.40f, 0.42f, 0.48f));
            mSun = mSceneMgr->createLight("CYSShadowTest/Sun");
            mSun->setType(Ogre::Light::LT_DIRECTIONAL);
            mSun->setDirection(Ogre::Vector3(0.78f, -0.56f, -0.28f).normalisedCopy()); // 3/4 light from the left
            mSun->setDiffuseColour(1.0f, 0.95f, 0.86f);
            mSun->setSpecularColour(0.6f, 0.6f, 0.6f);
            WX::CYSShadowSystem::getSingleton().setLight(mSun);

            receiverMaterial("CYSShadowTest/Ground", false, Ogre::Vector4(0.50f, 0.48f, 0.44f, 0.30f));
            receiverMaterial("CYSShadowTest/Prop", false, Ogre::Vector4(0.80f, 0.76f, 0.70f, 0.0f));
            if (mHasB)
                receiverMaterial("CYSShadowTest/GroundB", true, Ogre::Vector4(0.50f, 0.48f, 0.44f, 0.30f));

            Ogre::ManualObject* mo = mSceneMgr->createManualObject("CYSShadowTest/GroundBuilder");
            mo->begin("CYSShadowTest/Ground");
            const float s = 12000.0f;
            const float corners[4][2] = { { -s, -s }, { -s, s }, { s, s }, { s, -s } };
            for (int k = 0; k < 4; ++k)
            {
                mo->position(corners[k][0], 0.0f, corners[k][1]);
                mo->normal(0.0f, 1.0f, 0.0f);
            }
            mo->quad(0, 1, 2, 3);
            mo->end();
            mo->convertToMesh("CYSShadowTest/Ground.mesh", kGroup);
            mSceneMgr->destroyManualObject(mo);
            mGround = addEntity("CYSShadowTest/GroundEnt", "CYSShadowTest/Ground.mesh", "CYSShadowTest/Ground",
                                Ogre::Vector3::ZERO, Ogre::Vector3::UNIT_SCALE, Ogre::Quaternion::IDENTITY, false);

            // props: self-shadowing and acne checks on flat, sloped and curved casters that also receive
            buildBoxMesh();
            buildSphereMesh();
            mProps.push_back(addEntity("CYSShadowTest/Pillar", "CYSShadowTest/Box.mesh", "CYSShadowTest/Prop",
                Ogre::Vector3(-1650, 210, 380), Ogre::Vector3(110, 420, 110), Ogre::Quaternion::IDENTITY, true));
            mProps.push_back(addEntity("CYSShadowTest/Ramp", "CYSShadowTest/Box.mesh", "CYSShadowTest/Prop",
                Ogre::Vector3(-1250, 90, 560), Ogre::Vector3(460, 24, 240),
                Ogre::Quaternion(Ogre::Degree(24), Ogre::Vector3::UNIT_Z), true));
            mProps.push_back(addEntity("CYSShadowTest/Sphere", "CYSShadowTest/Sphere.mesh", "CYSShadowTest/Prop",
                Ogre::Vector3(-1500, 95, 820), Ogre::Vector3(95, 95, 95), Ogre::Quaternion::IDENTITY, true));
        }

        void createModels(void)
        {
            const std::map<std::string, std::string> cases = loadCases(mOpt.cases);
            WX::LogicModelManager& lm = WX::LogicModelManager::getSingleton();
            lm.setShadowCastable(true); // WX default: LogicModels do not cast (B: ShadowCast flag per model)
            static const char* const anims[] = { "休闲", "站立", "待机", "普通待机", "idle", "stand" };
            for (size_t i = 0; i < mOpt.models.size(); ++i)
            {
                ModelInfo info;
                info.id = mOpt.models[i];
                std::map<std::string, std::string>::const_iterator c = cases.find(info.id);
                if (c == cases.end())
                {
                    say("model " + info.id + ": not in " + mOpt.cases);
                    continue;
                }
                info.objUtf8 = c->second;
                const std::string obj = utf8ToGbk(info.objUtf8);
                if (!lm.getTemplateByName(obj))
                {
                    say("model " + info.id + " (" + info.objUtf8 + "): not in all.obj");
                    continue;
                }
                try
                {
                    info.model = lm.createLogicModel("CYSShadowTest/" + info.id, obj);
                    info.model->setParentSceneNode(mSystem->getBaseSceneNode());
                    Ogre::Vector3 origin = Ogre::Vector3::ZERO;
                    info.model->setPosition(origin);
                    info.model->setShadowCastable(true);
                    for (size_t a = 0; a < sizeof(anims) / sizeof(anims[0]) && info.anim.empty(); ++a)
                    {
                        try
                        {
                            info.model->createSkill(anims[a], true, false);
                        }
                        catch (const Ogre::Exception&)
                        {
                        }
                        if (!info.model->getCurrentAnimName().empty())
                            info.anim = gbkToUtf8(info.model->getCurrentAnimName());
                    }
                }
                catch (const Ogre::Exception& e)
                {
                    say("model " + info.id + " (" + info.objUtf8 + "): creation failed: " + e.getDescription());
                    info.model = NULL;
                    continue;
                }
                mModels.push_back(info);
            }
            layoutModels();
        }

        void layoutModels(void)
        {
            // Small models (actors, pets) in a front row, big ones (mounts, floats, trees) behind them.
            std::vector<size_t> front, back;
            for (size_t i = 0; i < mModels.size(); ++i)
            {
                Ogre::AxisAlignedBox b = worldBounds(mModels[i].model->getSceneNode());
                if (b.isNull())
                    b.setExtents(-50, 0, -50, 50, 180, 50);
                mModels[i].bounds = b;
                const Ogre::Vector3 size = b.getMaximum() - b.getMinimum();
                (size.y > 450 || std::max(size.x, size.z) > 700 ? back : front).push_back(i);
            }
            placeRow(front, 250.0f);
            placeRow(back, -700.0f);
            Ogre::AxisAlignedBox all;
            for (size_t i = 0; i < mModels.size(); ++i)
            {
                mModels[i].bounds = worldBounds(mModels[i].model->getSceneNode());
                all.merge(mModels[i].bounds);
                const Ogre::Vector3 size = mModels[i].bounds.getMaximum() - mModels[i].bounds.getMinimum();
                say(format("model %s %s: %.0f x %.0f x %.0f, animation '%s'", mModels[i].id.c_str(),
                           mModels[i].objUtf8.c_str(), size.x, size.y, size.z, mModels[i].anim.c_str()));
            }
            for (size_t i = 0; i < mProps.size(); ++i)
                all.merge(mProps[i]->getWorldBoundingBox(true));
            mSceneCentre = all.isNull() ? Ogre::Vector3(0, 100, 0) : all.getCenter();
            mSceneRadius = all.isNull() ? 1000.0f : all.getHalfSize().length();
        }

        void placeRow(const std::vector<size_t>& row, float z)
        {
            const float gap = 170.0f;
            float total = 0;
            for (size_t k = 0; k < row.size(); ++k)
                total += (mModels[row[k]].bounds.getMaximum().x - mModels[row[k]].bounds.getMinimum().x) + gap;
            float x = -0.5f * (total - gap) + 250.0f; // props stand at x < -1000
            for (size_t k = 0; k < row.size(); ++k)
            {
                ModelInfo& m = mModels[row[k]];
                const float w = m.bounds.getMaximum().x - m.bounds.getMinimum().x;
                Ogre::Vector3 pos(x + 0.5f * w - m.bounds.getCenter().x, -m.bounds.getMinimum().y,
                                  z - m.bounds.getCenter().z);
                m.model->setPosition(pos);
                x += w + gap;
            }
        }

        // ------------------------------------------------------------------ cameras
        void lookAt(const Ogre::Vector3& eye, const Ogre::Vector3& target)
        {
            mCamera->setPosition(eye);
            mCamera->lookAt(target);
        }

        void frameScene(void)
        {
            const Ogre::Real dist = std::max(Ogre::Real(1800), mSceneRadius * 1.9f);
            mOverviewTarget = mSceneCentre - Ogre::Vector3(0, mSceneCentre.y * 0.4f, 0);
            mOverviewEye = mOverviewTarget + Ogre::Vector3(0, std::sin(Ogre::Degree(24).valueRadians()),
                                                           std::cos(Ogre::Degree(24).valueRadians())) * dist;
            lookAt(mOverviewEye, mOverviewTarget);
        }

        void viewOverview(void) { lookAt(mOverviewEye, mOverviewTarget); }

        const ModelInfo* findModel(const std::string& id) const
        {
            for (size_t i = 0; i < mModels.size(); ++i)
                if (mModels[i].id == id)
                    return &mModels[i];
            return mModels.empty() ? NULL : &mModels[0];
        }

        void viewModel(const ModelInfo& m, float distanceScale, float heightScale)
        {
            const Ogre::Vector3 size = m.bounds.getMaximum() - m.bounds.getMinimum();
            const Ogre::Real extent = std::max(size.y, std::max(size.x, size.z) * 0.7f);
            const Ogre::Vector3 target = m.bounds.getCenter();
            lookAt(target + Ogre::Vector3(-0.35f, heightScale, 1.0f).normalisedCopy() * extent * distanceScale, target);
        }

        // ------------------------------------------------------------------ frames and captures
        void pumpMessages(void)
        {
            MSG msg;
            while (PeekMessage(&msg, NULL, 0U, 0U, PM_REMOVE))
            {
                TranslateMessage(&msg);
                DispatchMessage(&msg);
            }
        }

        void renderFrame(float dt, const std::string* png, std::vector<unsigned char>* pixels)
        {
            pumpMessages();
            Ogre::Root& root = Ogre::Root::getSingleton();
            Ogre::FrameEvent evt;
            evt.timeSinceLastEvent = dt;
            evt.timeSinceLastFrame = dt;
            root._fireFrameStarted(evt);
            if (mTiming)
                mTimer.beginFrame();
            root._updateAllRenderTargets(); // the atlas (render textures update first)
            mWindow->update(false);
            if (mTiming)
                mTimer.endFrame();
            if (png || pixels)
                capture(png, pixels);
            mWindow->swapBuffers(false);
            root._fireFrameEnded(evt);
        }

        void settle(int frames, float dt)
        {
            for (int i = 0; i < frames; ++i)
                renderFrame(dt, NULL, NULL);
        }

        bool capture(const std::string* png, std::vector<unsigned char>* pixels)
        {
            IDirect3DSurface9* backBuffer = NULL;
            mWindow->getCustomAttribute("DDBACKBUFFER", &backBuffer); // not AddRef'd
            if (!mDevice || !backBuffer)
                return false;
            D3DSURFACE_DESC desc;
            backBuffer->GetDesc(&desc);
            IDirect3DSurface9* resolved = NULL;
            IDirect3DSurface9* system = NULL;
            HRESULT hr = mDevice->CreateRenderTarget(desc.Width, desc.Height, desc.Format, D3DMULTISAMPLE_NONE, 0,
                                                     FALSE, &resolved, NULL);
            if (SUCCEEDED(hr))
                hr = mDevice->StretchRect(backBuffer, NULL, resolved, NULL, D3DTEXF_NONE);
            if (SUCCEEDED(hr))
                hr = mDevice->CreateOffscreenPlainSurface(desc.Width, desc.Height, desc.Format, D3DPOOL_SYSTEMMEM,
                                                          &system, NULL);
            if (SUCCEEDED(hr))
                hr = mDevice->GetRenderTargetData(resolved, system);
            if (SUCCEEDED(hr) && png)
                hr = D3DXSaveSurfaceToFileA(png->c_str(), D3DXIFF_PNG, system, NULL, NULL);
            if (SUCCEEDED(hr) && pixels)
            {
                D3DLOCKED_RECT lr;
                hr = system->LockRect(&lr, NULL, D3DLOCK_READONLY);
                if (SUCCEEDED(hr))
                {
                    pixels->resize((size_t)desc.Width * desc.Height * 3);
                    for (unsigned y = 0; y < desc.Height; ++y)
                    {
                        const unsigned char* row = (const unsigned char*)lr.pBits + (size_t)y * lr.Pitch;
                        unsigned char* dst = &(*pixels)[(size_t)y * desc.Width * 3];
                        for (unsigned x = 0; x < desc.Width; ++x)
                        {
                            dst[x * 3 + 0] = row[x * 4 + 2];
                            dst[x * 3 + 1] = row[x * 4 + 1];
                            dst[x * 3 + 2] = row[x * 4 + 0];
                        }
                    }
                    system->UnlockRect();
                }
            }
            if (system)
                system->Release();
            if (resolved)
                resolved->Release();
            if (FAILED(hr))
                say(format("capture failed (0x%08lX)", (unsigned long)hr));
            return SUCCEEDED(hr);
        }

        void logCascades(const std::string& label)
        {
            const WX::CYSShadowSystem& sh = WX::CYSShadowSystem::getSingleton();
            const WX::CYSShadowParams& p = sh.getParams();
            std::ostringstream o;
            o.setf(std::ios::fixed);
            o.precision(2);
            o << label << ": shadow CPU " << sh.getStats().cpuMs << " ms, bias const " << p.constBias << " normal "
              << p.normalBias << ", light (" << p.lightDirection.x << ", " << p.lightDirection.y << ", "
              << p.lightDirection.z << ")";
            for (size_t i = 0; i < p.cascadeCount; ++i)
            {
                const WX::CYSShadowCascade& c = p.cascades[i];
                o << "\n    cascade " << i << ": view depth " << c.splitNear << " .. " << c.splitFar << ", region "
                  << 2 * c.halfWidth << " x " << 2 * c.halfHeight << ", texel " << c.texelWidth << ", depth range "
                  << c.depthFar << ", casters " << c.casters;
            }
            say(o.str());
        }

        void shot(const std::string& file, int frames = 6)
        {
            settle(frames - 1, 1.0f / 30.0f);
            const std::string path = mOpt.out + "\\" + file;
            renderFrame(1.0f / 30.0f, &path, NULL);
            mFiles.push_back(file);
            say("shot " + file);
        }

        bool saveAtlas(const std::string& file)
        {
            const std::string path = mOpt.out + "\\" + file;
            Ogre::RenderTexture* rt = WX::CYSShadowSystem::getSingleton().getAtlasTarget();
            IDirect3DSurface9* surfaces[8] = { 0 };
            if (!rt || !mDevice)
                return false;
            rt->getCustomAttribute("DDBACKBUFFER", &surfaces);
            IDirect3DSurface9* src = surfaces[0];
            if (!src)
                return false;
            D3DSURFACE_DESC d;
            src->GetDesc(&d);
            IDirect3DSurface9* sys = NULL;
            if (FAILED(mDevice->CreateOffscreenPlainSurface(d.Width, d.Height, d.Format, D3DPOOL_SYSTEMMEM, &sys, NULL)))
                return false;
            bool ok = false;
            D3DLOCKED_RECT lr;
            if (SUCCEEDED(mDevice->GetRenderTargetData(src, sys)) && SUCCEEDED(sys->LockRect(&lr, NULL, D3DLOCK_READONLY)))
            {
                // max 4096 px wide; per output pixel the nearest caster of its block, normalised per tile
                const unsigned tiles = (unsigned)WX::CYSShadowSystem::getSingleton().getParams().cascadeCount;
                const unsigned f = std::max(1u, d.Width / 4096u);
                const unsigned ow = d.Width / f, oh = d.Height / f, tileW = d.Width / std::max(1u, tiles);
                std::vector<float> lo(tiles, 1e30f), hi(tiles, 0.0f);
                for (unsigned y = 0; y < d.Height; ++y)
                {
                    const float* row = (const float*)((const unsigned char*)lr.pBits + (size_t)y * lr.Pitch);
                    for (unsigned x = 0; x < d.Width; ++x)
                        if (row[x] > 0.0f)
                        {
                            const unsigned t = std::min(tiles - 1, x / tileW);
                            lo[t] = std::min(lo[t], row[x]);
                            hi[t] = std::max(hi[t], row[x]);
                        }
                }
                std::vector<unsigned char> rgb((size_t)ow * oh * 3);
                size_t filled = 0;
                for (unsigned oy = 0; oy < oh; ++oy)
                    for (unsigned ox = 0; ox < ow; ++ox)
                    {
                        float nearest = 0.0f;
                        for (unsigned yy = 0; yy < f; ++yy)
                        {
                            const float* row = (const float*)((const unsigned char*)lr.pBits + (size_t)(oy * f + yy) * lr.Pitch);
                            for (unsigned xx = 0; xx < f; ++xx)
                            {
                                const float v = row[ox * f + xx];
                                if (v > 0.0f && (nearest == 0.0f || v < nearest))
                                    nearest = v;
                            }
                        }
                        unsigned char* px = &rgb[((size_t)oy * ow + ox) * 3];
                        const unsigned t = std::min(tiles - 1, (ox * f) / tileW);
                        const bool border = (ox * f) % tileW < f * 2 || oy < 2 || oy + 2 >= oh;
                        if (border)
                        {
                            px[0] = 240; px[1] = 120; px[2] = 30;
                        }
                        else if (nearest > 0.0f)
                        {
                            ++filled;
                            const float range = std::max(hi[t] - lo[t], 1.0f);
                            const float g = 1.0f - (nearest - lo[t]) / range;
                            const unsigned char v = (unsigned char)(60.0f + 195.0f * std::max(0.0f, std::min(1.0f, g)));
                            px[0] = v; px[1] = v; px[2] = (unsigned char)(v * 0.92f);
                        }
                        else
                        {
                            px[0] = 18; px[1] = 22; px[2] = 40;
                        }
                    }
                sys->UnlockRect();
                ok = saveRgbPng(mDevice, path, ow, oh, rgb);
                std::ostringstream o;
                o << "atlas " << file << ": " << d.Width << "x" << d.Height << " read back, "
                  << (100.0 * filled / std::max<size_t>(1, (size_t)ow * oh)) << " % of the texels hold a caster";
                for (unsigned t = 0; t < tiles; ++t)
                    o << "; tile " << t << " depth " << (hi[t] > 0 ? lo[t] : 0.0f) << ".." << hi[t];
                say(o.str());
            }
            sys->Release();
            if (ok)
                mFiles.push_back(file);
            return ok;
        }

        // ------------------------------------------------------------------ scenarios
        void runShots(void)
        {
            WX::CYSShadowSystem& sh = WX::CYSShadowSystem::getSingleton();
            const std::string size = Ogre::StringConverter::toString(sh.getConfig().mapSize);
            viewOverview();
            sh.setEnabled(false);
            shot("01_shadows_off.png");
            sh.setEnabled(true);
            shot("02_csm_" + size + ".png");
            logCascades("overview, CSM " + size);

            setEntityFragmentParam(mGround, "gridParams", Ogre::Vector4(100, 0, 1, 1)); // cascade tint
            sh.setDebugView(true);
            shot("03_cascades.png");
            sh.setDebugView(false);
            setEntityFragmentParam(mGround, "gridParams", Ogre::Vector4(100, 0, 0, 1));
            saveAtlas("04_atlas_" + size + ".png");

            // game-like third-person view on the first actor
            const ModelInfo* actor = findModel(mOpt.models.empty() ? std::string() : mOpt.models[0]);
            if (actor)
            {
                const Ogre::Vector3 t = actor->bounds.getCenter();
                lookAt(t + Ogre::Vector3(-380, 620, 1150), t);
                shot("05_gameview_csm.png");
                logCascades("game view, CSM " + size);
                sh.setEnabled(false);
                shot("05b_gameview_off.png");
                sh.setEnabled(true);
                viewModel(*actor, 1.25f, 0.25f);
                shot("06_closeup_actor.png");
                logCascades("actor close-up");
            }
            const ModelInfo* tree = findModel("M40");
            if (tree && tree->id == "M40")
            {
                viewModel(*tree, 1.6f, 0.45f);
                shot("06_closeup_tree.png");
            }
            if (!mProps.empty())
            {
                const Ogre::Vector3 t = mProps[1]->getWorldBoundingBox(true).getCenter();
                lookAt(t + Ogre::Vector3(-250, 380, 720), t);
                shot("06_closeup_props.png");
                logCascades("props close-up");
            }
            if (mHasB)
            {
                viewOverview();
                mGround->setMaterialName("CYSShadowTest/GroundB");
                shot("07_b_receiver.png");
                mGround->setMaterialName("CYSShadowTest/Ground");
            }
            viewOverview();
            sh.setMapSize(2048);
            shot("08_csm_2048.png");
            saveAtlas("09_atlas_2048.png");
            sh.setMode(WX::CYSShadowConfig::MODE_SIMPLE);
            setEntityFragmentParam(mGround, "gridParams", Ogre::Vector4(100, 0, 0, 2));
            for (size_t i = 0; i < mProps.size(); ++i)
                setEntityFragmentParam(mProps[i], "gridParams", Ogre::Vector4(100, 0, 0, 2));
            shot("10_simple.png");
            logCascades("simple mode");
            setEntityFragmentParam(mGround, "gridParams", Ogre::Vector4(100, 0, 0, 1));
            for (size_t i = 0; i < mProps.size(); ++i)
                setEntityFragmentParam(mProps[i], "gridParams", Ogre::Vector4(100, 0, 0, 1));
            sh.setMode(WX::CYSShadowConfig::MODE_CSM);
            sh.setMapSize(mOpt.size);
        }

        // ------------------------------------------------------------------ CYS-SHADOW: receiver diagnostic
        void setModelVisible(ModelInfo& m, bool on)
        {
            std::vector<Ogre::Entity*> ents;
            collectEntities(m.model->getSceneNode(), ents);
            for (size_t i = 0; i < ents.size(); ++i)
                ents[i]->setVisible(on);
        }

        /// receiver_diag.tsv (per rendered pass of every model) + receiver_luma.tsv: each model under a sunward slab
        /// that puts it completely in shade; model mask = pixels that change when the model is hidden (shadows off);
        /// luminance of the mask and of the shaded ground around it with shadows on / off.
        void runReceiverDiag(void)
        {
            WX::CYSShadowSystem& sh = WX::CYSShadowSystem::getSingleton();
            size_t clobbers = 0, passes = 0, receivers = 0;
            std::ostringstream d;
            d << "model\tentity\tsub\tmaterial\tpass\tvertex_program\tfragment_program\tfp_defines\ts5\tconstants\n";
            viewOverview();
            settle(3, 1.0f / 30.0f); // last values of the auto constants belong to this view
            for (size_t i = 0; i < mModels.size(); ++i)
            {
                std::vector<Ogre::Entity*> ents;
                collectEntities(mModels[i].model->getSceneNode(), ents);
                for (size_t e = 0; e < ents.size(); ++e)
                    for (unsigned int s = 0; s < ents[e]->getNumSubEntities(); ++s)
                    {
                        Ogre::SubEntity* se = ents[e]->getSubEntity(s);
                        Ogre::Technique* tech = se->getTechnique();
                        if (Ogre::MaterialManager::getSingleton().getVariantResolver())
                            tech = Ogre::MaterialManager::getSingleton().getVariantResolver()->resolveTechnique(se, tech);
                        if (!tech)
                            continue;
                        for (unsigned short p = 0; p < tech->getNumPasses(); ++p)
                        {
                            Ogre::Pass* pass = tech->getPass(p);
                            std::ostringstream prefix;
                            prefix << mModels[i].id << '\t' << gbkToUtf8(ents[e]->getName()) << '\t' << s << '\t'
                                   << gbkToUtf8(tech->getParent()->getName()) << '\t' << p;
                            describePassDiag(d, prefix.str(), pass, clobbers);
                            ++passes;
                            if (pass->hasFragmentProgram() &&
                                programDefines(pass->getFragmentProgramName()).find("LIGHT_CALC_TYPE=2") != std::string::npos &&
                                programDefines(pass->getFragmentProgramName()).find("SHADOWMAP_TYPE=1") != std::string::npos)
                                ++receivers;
                        }
                    }
            }
            {
                std::ofstream f((mOpt.out + "\\receiver_diag.tsv").c_str(), std::ios::binary);
                f << "\xEF\xBB\xBF" << d.str();
            }
            mFiles.push_back("receiver_diag.tsv");
            say(format("receiver diagnostic (--receivers %s): %u passes, %u compiled as receivers "
                       "(LIGHT_CALC_TYPE=2 + SHADOWMAP_TYPE=1), %u light-array writes into other uniforms",
                       mOpt.receivers.c_str(), (unsigned)passes, (unsigned)receivers, (unsigned)clobbers));

            // sunward slab
            Ogre::Entity* slab = addEntity("CYSShadowTest/ShadeSlab", "CYSShadowTest/Box.mesh", "CYSShadowTest/Prop",
                                           Ogre::Vector3::ZERO, Ogre::Vector3(10, 10, 10), Ogre::Quaternion::IDENTITY, true);
            Ogre::Vector3 dir = mSun->getDirection().normalisedCopy();
            std::ostringstream t;
            t << "receivers\tmodel\tmask_px\tluma_off\tluma_on\tratio_on_off\tground_px\tground_luma_off\tground_luma_on\tground_ratio\n";
            for (size_t i = 0; i < mModels.size(); ++i)
            {
                ModelInfo& m = mModels[i];
                const Ogre::Vector3 size = m.bounds.getMaximum() - m.bounds.getMinimum();
                const Ogre::Vector3 c = m.bounds.getCenter();
                const float lift = size.y + 900.0f;
                const Ogre::Vector3 at = c - dir * (lift / std::max(0.2f, -dir.y));
                const float span = std::max(size.x, size.z) * 1.6f + 260.0f;
                slab->getParentSceneNode()->setPosition(at);
                slab->getParentSceneNode()->setScale(span, 30.0f, span);
                slab->setVisible(true);
                viewModel(m, 1.25f, 0.25f);
                std::vector<unsigned char> offVis, offHid, onVis, onHid;
                sh.setEnabled(false);
                settle(4, 1.0f / 30.0f);
                renderFrame(0.0f, NULL, &offVis);
                setModelVisible(m, false);
                renderFrame(0.0f, NULL, &offHid);
                sh.setEnabled(true);
                settle(3, 0.0f);
                renderFrame(0.0f, NULL, &onHid);
                setModelVisible(m, true);
                const std::string pngOn = mOpt.out + "\\11_shade_" + m.id + "_" + mOpt.receivers + "_on.png";
                const std::string pngOff = mOpt.out + "\\11_shade_" + m.id + "_" + mOpt.receivers + "_off.png";
                renderFrame(0.0f, &pngOn, &onVis);
                sh.setEnabled(false);
                renderFrame(0.0f, &pngOff, NULL);
                sh.setEnabled(true);
                mFiles.push_back("11_shade_" + m.id + "_" + mOpt.receivers + "_on.png");
                if (offVis.empty() || offVis.size() != offHid.size() || offVis.size() != onVis.size() ||
                    onVis.size() != onHid.size())
                    continue;
                const size_t px = offVis.size() / 3;
                std::vector<unsigned char> mask(px, 0), ground(px, 0);
                for (size_t q = 0; q < px; ++q)
                {
                    const int dm = std::abs(int(offVis[q * 3]) - int(offHid[q * 3])) +
                                   std::abs(int(offVis[q * 3 + 1]) - int(offHid[q * 3 + 1])) +
                                   std::abs(int(offVis[q * 3 + 2]) - int(offHid[q * 3 + 2]));
                    mask[q] = dm > 24 ? 1 : 0;
                    const int dg = std::abs(int(onHid[q * 3]) - int(offHid[q * 3])) +
                                   std::abs(int(onHid[q * 3 + 1]) - int(offHid[q * 3 + 1])) +
                                   std::abs(int(onHid[q * 3 + 2]) - int(offHid[q * 3 + 2]));
                    ground[q] = (!mask[q] && dg > 24) ? 1 : 0;
                }
                size_t nMask = 0, nMask2 = 0, nGround = 0, nGround2 = 0;
                const double lOff = maskedLuma(offVis, mask, nMask), lOn = maskedLuma(onVis, mask, nMask2);
                const double gOff = maskedLuma(offHid, ground, nGround), gOn = maskedLuma(onHid, ground, nGround2);
                t << mOpt.receivers << '\t' << m.id << '\t' << nMask << '\t' << lOff << '\t' << lOn << '\t'
                  << (lOff > 0 ? lOn / lOff : 0.0) << '\t' << nGround << '\t' << gOff << '\t' << gOn << '\t'
                  << (gOff > 0 ? gOn / gOff : 0.0) << "\n";
                say(format("shade %s (%s): model %u px luma off %.1f on %.1f ratio %.3f | shaded ground %u px ratio %.3f",
                           m.id.c_str(), m.objUtf8.c_str(), (unsigned)nMask, lOff, lOn, lOff > 0 ? lOn / lOff : 0.0,
                           (unsigned)nGround, gOff > 0 ? gOn / gOff : 0.0));
            }
            slab->setVisible(false);
            slab->setCastShadows(false);
            std::ofstream f((mOpt.out + "\\receiver_luma_" + mOpt.receivers + ".tsv").c_str(), std::ios::binary);
            f << t.str();
            mFiles.push_back("receiver_luma_" + mOpt.receivers + ".tsv");
            viewOverview();
        }

        struct Timing
        {
            std::string label;
            double gpuShadow, gpuFrame, gpuFrameMean, cpuShadow;
            size_t frames;
        };

        /// The atlas render target is recreated by setMapSize / setMode: (re)attach the GPU timer to the current one.
        void ensureTimerListener(void)
        {
            Ogre::RenderTexture* rt = WX::CYSShadowSystem::getSingleton().getAtlasTarget();
            if (rt)
            {
                rt->removeListener(&mTimer); // at most one registration, even if a new target reuses the address
                rt->addListener(&mTimer);
            }
        }

        Timing measure(const std::string& label)
        {
            Timing t;
            t.label = label;
            ensureTimerListener();
            settle(15, 1.0f / 60.0f);
            std::vector<double> gs, gf, cs;
            mTiming = true;
            for (int i = 0; i < mOpt.timingFrames; ++i)
            {
                renderFrame(1.0f / 60.0f, NULL, NULL);
                double frameMs = 0, shadowMs = 0;
                if (mTimer.resolve(frameMs, shadowMs))
                {
                    gf.push_back(frameMs);
                    gs.push_back(shadowMs);
                }
                cs.push_back(WX::CYSShadowSystem::getSingleton().isActive() ?
                             WX::CYSShadowSystem::getSingleton().getStats().cpuMs : 0.0);
            }
            mTiming = false;
            t.gpuShadow = median(gs);
            t.gpuFrame = median(gf);
            t.gpuFrameMean = mean(gf);
            t.cpuShadow = median(cs);
            t.frames = gf.size();
            say(format("timing %-18s GPU shadow pass %.3f ms, GPU frame %.3f ms (mean %.3f), CPU shadow update %.3f ms "
                       "(%u frames, %dx%d)", label.c_str(), t.gpuShadow, t.gpuFrame, t.gpuFrameMean, t.cpuShadow,
                       (unsigned)t.frames, mOpt.width, mOpt.height));
            return t;
        }

        void runTiming(void)
        {
            WX::CYSShadowSystem& sh = WX::CYSShadowSystem::getSingleton();
            std::vector<Timing> rows;
            const ModelInfo* actor = findModel(mOpt.models.empty() ? std::string() : mOpt.models[0]);
            for (int view = 0; view < 2; ++view)
            {
                const std::string v = view ? "game" : "overview";
                if (view == 0)
                    viewOverview();
                else if (actor)
                    lookAt(actor->bounds.getCenter() + Ogre::Vector3(-380, 620, 1150), actor->bounds.getCenter());
                sh.setEnabled(false);
                rows.push_back(measure(v + " off"));
                sh.setEnabled(true);
                static const unsigned sizes[] = { 4096, 2048, 1024 };
                for (size_t i = 0; i < 3; ++i)
                {
                    sh.setMapSize(sizes[i]);
                    rows.push_back(measure(v + " csm" + Ogre::StringConverter::toString(sizes[i])));
                }
                sh.setMapSize(mOpt.size);
            }
            std::ofstream f((mOpt.out + "\\timing.tsv").c_str(), std::ios::binary);
            f << "config\tgpu_shadow_ms_median\tgpu_frame_ms_median\tgpu_frame_ms_mean\tcpu_shadow_update_ms_median\tframes\n";
            for (size_t i = 0; i < rows.size(); ++i)
                f << rows[i].label << "\t" << rows[i].gpuShadow << "\t" << rows[i].gpuFrame << "\t" << rows[i].gpuFrameMean
                  << "\t" << rows[i].cpuShadow << "\t" << rows[i].frames << "\n";
            mFiles.push_back("timing.tsv");
        }

        /// Shimmer: the view stays fixed while the camera the cascades are fitted to moves and turns a little
        /// (a walking, turning player). Stable cascades must leave the shadows on screen unchanged.
        void stabilityRun(WX::CYSShadowConfig::Fit fit, const std::string& file, double& meanDiff, double& changed)
        {
            WX::CYSShadowSystem& sh = WX::CYSShadowSystem::getSingleton();
            if (!mFitCamera)
            {
                mFitCamera = mSceneMgr->createCamera("CYSShadowTest/FitCamera");
                mFitCamera->setNearClipDistance(mCamera->getNearClipDistance());
                mFitCamera->setFarClipDistance(mCamera->getFarClipDistance());
                mFitCamera->setFOVy(mCamera->getFOVy());
                mFitCamera->setAspectRatio(mCamera->getAspectRatio());
            }
            const ModelInfo* actor = findModel(mOpt.models.empty() ? std::string() : mOpt.models[0]);
            const Ogre::Vector3 target = actor ? actor->bounds.getCenter() : mSceneCentre;
            const Ogre::Vector3 eye = target + Ogre::Vector3(-380, 620, 1150);
            lookAt(eye, target);
            sh.setFit(fit);
            sh.setCamera(mFitCamera);
            std::vector<unsigned char> prev, cur;
            std::vector<unsigned char> heat;
            double sumDiff = 0, sumChanged = 0;
            int pairs = 0;
            for (int f = 0; f < mOpt.stabilityFrames; ++f)
            {
                const float s = float(f);
                mFitCamera->setPosition(eye + Ogre::Vector3(37.0f * std::sin(s * 0.45f), 0, 23.0f * std::sin(s * 0.31f)));
                mFitCamera->lookAt(target);
                mFitCamera->yaw(Ogre::Degree(2.5f * std::sin(s * 0.27f)));
                renderFrame(0.0f, NULL, &cur); // dt 0: animations frozen, only the cascades move
                if (!prev.empty() && prev.size() == cur.size())
                {
                    if (heat.empty())
                        heat.assign(cur.size() / 3, 0);
                    double diff = 0;
                    size_t n = 0;
                    for (size_t p = 0, q = 0; p < cur.size(); p += 3, ++q)
                    {
                        const int d = std::abs(int(cur[p]) - int(prev[p])) + std::abs(int(cur[p + 1]) - int(prev[p + 1])) +
                                      std::abs(int(cur[p + 2]) - int(prev[p + 2]));
                        diff += d / 3.0;
                        if (d > 3 * 6)
                            ++n;
                        heat[q] = (unsigned char)std::min(255, std::max(int(heat[q]), d * 2));
                    }
                    sumDiff += diff / double(cur.size() / 3);
                    sumChanged += double(n) / double(cur.size() / 3);
                    ++pairs;
                }
                prev.swap(cur);
            }
            sh.setCamera(mCamera);
            sh.setFit(WX::CYSShadowConfig::FIT_STABLE);
            meanDiff = pairs ? sumDiff / pairs : 0.0;
            changed = pairs ? 100.0 * sumChanged / pairs : 0.0;
            if (!heat.empty())
            {
                std::vector<unsigned char> rgb(heat.size() * 3);
                for (size_t q = 0; q < heat.size(); ++q)
                {
                    rgb[q * 3 + 0] = heat[q];
                    rgb[q * 3 + 1] = (unsigned char)(heat[q] / 3);
                    rgb[q * 3 + 2] = 0;
                }
                if (saveRgbPng(mDevice, mOpt.out + "\\" + file, mWindow->getWidth(), mWindow->getHeight(), rgb))
                    mFiles.push_back(file);
            }
        }

        void runStability(void)
        {
            double stableDiff = 0, stableChanged = 0, tightDiff = 0, tightChanged = 0;
            stabilityRun(WX::CYSShadowConfig::FIT_STABLE, "stability_stable.png", stableDiff, stableChanged);
            stabilityRun(WX::CYSShadowConfig::FIT_TIGHT, "stability_tight.png", tightDiff, tightChanged);
            say(format("shimmer test (%d frames, fitting camera moves +-37/23 units and turns +-2.5 deg, view fixed):\n"
                       "    stable fit (sphere + texel snap): mean |dRGB| %.4f per pixel per frame, %.4f %% pixels changed\n"
                       "    tight fit (per-frame AABB, B-like): mean |dRGB| %.4f per pixel per frame, %.4f %% pixels changed",
                       mOpt.stabilityFrames, stableDiff, stableChanged, tightDiff, tightChanged));
        }

        void writeSummary(void)
        {
            std::string files;
            for (size_t i = 0; i < mFiles.size(); ++i)
                files += (i ? ", " : "") + mFiles[i];
            say("files: " + files);
            FILE* f = std::fopen((mOpt.out + "\\shadow_summary.txt").c_str(), "wb");
            if (f)
            {
                std::fputs("\xEF\xBB\xBF", f);
                std::fputs(g_summary.c_str(), f);
                std::fclose(f);
            }
        }

        Options mOpt;
        HWND mHwnd;
        Ogre::LogManager* mLog;
        TestSystem* mSystem;
        Ogre::RenderWindow* mWindow;
        Ogre::Camera* mCamera;
        Ogre::SceneManager* mSceneMgr;
        Ogre::Light* mSun;
        Ogre::Camera* mFitCamera;
        Ogre::Entity* mGround;
        std::vector<Ogre::Entity*> mProps;
        std::vector<ModelInfo> mModels;
        IDirect3DDevice9* mDevice;
        GpuTimer mTimer;
        bool mTiming;
        bool mHasB;
        Ogre::Vector3 mSceneCentre;
        Ogre::Real mSceneRadius;
        Ogre::Vector3 mOverviewEye;
        Ogre::Vector3 mOverviewTarget;
        std::vector<std::string> mFiles;
        bool mShutdown;
    };

    LRESULT CALLBACK wndProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp)
    {
        switch (msg)
        {
        case WM_GETMINMAXINFO:
            {
                MINMAXINFO* info = reinterpret_cast<MINMAXINFO*>(lp);
                info->ptMaxTrackSize.x = 16384;
                info->ptMaxTrackSize.y = 16384;
                return 0;
            }
        case WM_ERASEBKGND:
            return 1;
        case WM_CLOSE:
            PostQuitMessage(0);
            return 0;
        default:
            return DefWindowProcW(hwnd, msg, wp, lp);
        }
    }

    HWND createWindow(const Options& opt)
    {
        HINSTANCE instance = GetModuleHandleW(NULL);
        WNDCLASSEXW wc;
        ZeroMemory(&wc, sizeof(wc));
        wc.cbSize = sizeof(wc);
        wc.style = CS_HREDRAW | CS_VREDRAW;
        wc.lpfnWndProc = wndProc;
        wc.hInstance = instance;
        wc.hCursor = LoadCursor(NULL, IDC_ARROW);
        wc.hbrBackground = (HBRUSH)GetStockObject(BLACK_BRUSH);
        wc.lpszClassName = L"CysShadowTestWindow";
        RegisterClassExW(&wc);
        RECT rc = { 0, 0, opt.width, opt.height };
        AdjustWindowRect(&rc, WS_OVERLAPPEDWINDOW, FALSE);
        HWND hwnd = CreateWindowExW(0, wc.lpszClassName, L"CysShadowTest", WS_OVERLAPPEDWINDOW, CW_USEDEFAULT,
                                    CW_USEDEFAULT, rc.right - rc.left, rc.bottom - rc.top, NULL, NULL, instance, NULL);
        if (!hwnd)
            return NULL;
        RECT client;
        GetClientRect(hwnd, &client);
        if (client.right != opt.width || client.bottom != opt.height)
        {
            RECT outer;
            GetWindowRect(hwnd, &outer);
            SetWindowPos(hwnd, NULL, 0, 0, (outer.right - outer.left) + (opt.width - client.right),
                         (outer.bottom - outer.top) + (opt.height - client.bottom), SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
        }
        if (opt.show)
        {
            ShowWindow(hwnd, SW_SHOWNORMAL);
            UpdateWindow(hwnd);
        }
        return hwnd;
    }
}

int wmain(int argc, wchar_t** argv)
{
    SetErrorMode(SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX | SEM_NOOPENFILEERRORBOX);
    SetConsoleOutputCP(CP_UTF8);
    SetProcessDPIAware();
    Options opt;
    if (!parseArgs(argc, argv, opt))
        return 2;
    CreateDirectoryA(opt.out.c_str(), NULL);
    std::strncpy(g_dumpPath, (opt.out + "\\CysShadowTest.dmp").c_str(), MAX_PATH - 1);
    SetUnhandledExceptionFilter(crashFilter);

    HWND hwnd = createWindow(opt);
    if (!hwnd)
    {
        std::printf("cannot create the window\n");
        return 1;
    }
    int rc = 0;
    {
        ShadowTest test(opt);
        rc = test.run(hwnd);
        test.shutdown();
    }
    DestroyWindow(hwnd);
    return rc;
}
