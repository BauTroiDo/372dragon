// CysPostFxTest - CY-Source post-processing test (component postfx_test; Docs/specs/render/02-postfx.md).
//
// Renders client_GL LogicModels (Tests/oracle/cases.json model cases) on a lit ground plane under a backdrop sky with
// a sun, then runs the CY-Source post filters off/on through WX::PostFilterManager (the API the game uses) and saves
// back-buffer PNGs; --bench also measures event-query-synchronised frame times per case. The world is frozen after a
// warm-up, so every case renders the same geometry. client_GL data is only read.
// CYS fx-render 2026-09-13: --bench also records D3D9 timestamps at every render-target update and before every
// post-chain pass (CysPostFx::setPassObserver) -> GPU ms per filter, plus the CPU submit time per frame; cases
// "preset" / "preset_fog" are the shipped start-up set (CysPostFx::applyStartup).
//
//   CysPostFxTest.exe [--data DIR] [--out DIR] [--width W --height H] [--models M07,M09,...] [--cases a,b,...]
//                     [--frames N] [--warmup N] [--bench N] [--show] [--no-matsys] [--list]
//
// The lenient script loading (per-file parsing, effect / particle lines 0.85 rejects) follows TlbbViewer.
#include <windows.h>
#include <dbghelp.h>
#include <d3d9.h>
#include <d3dx9.h>

#include <OgreRoot.h>
#include <OgreRenderWindow.h>
#include <OgreRenderSystem.h>
#include <OgreCamera.h>
#include <OgreViewport.h>
#include <OgreSceneManager.h>
#include <OgreSceneNode.h>
#include <OgreEntity.h>
#include <OgreLight.h>
#include <OgreRectangle2D.h>
#include <OgreMaterialManager.h>
#include <OgreMaterial.h>
#include <OgreTechnique.h>
#include <OgrePass.h>
#include <OgreTextureManager.h>
#include <OgreTextureUnitState.h>
#include <OgreMeshManager.h>
#include <OgreImage.h>
#include <OgreResourceGroupManager.h>
#include <OgreScriptLoader.h>
#include <OgreArchive.h>
#include <OgreDataStream.h>
#include <OgreParticleSystem.h>
#include <OgreParticleSystemManager.h>
#include <OgreCompositorManager.h>
#include <OgreFontManager.h>
#include <OgreOverlayManager.h>
#include <OgreLogManager.h>
#include <OgreStringConverter.h>
#include <OgreException.h>
#include <OgreFrameListener.h>
#include <OgreRenderTargetListener.h>
#include <OgreMath.h>

#include "Core/WXSystem.h"
#include "Core/FrameStatsListener.h"
#include "ModelSystem/WXLogicModel.h"
#include "ModelSystem/WXLogicModelManager.h"
#include "EffectSystem/WXEffectManager.h"
#include "PostFilter/WXPostFilterManager.h"
#include "PostFilter/WXPostFilter.h"
#include "PostFilter/WXPostFilters.h"
#include "CYS/PostFX/CysPostFx.h"
#ifdef CYS_WXRENDER_MATERIAL_SYSTEM
#include "MaterialSystem/CysMaterialSystem.h"
#endif

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <functional>
#include <map>
#include <set>
#include <sstream>
#include <string>
#include <vector>

namespace
{
    //=======================================================================
    // options, output
    //=======================================================================
    struct Options
    {
        int width = 1920;
        int height = 1080;
        std::string data = "C:\\TLBB\\085\\client_GL\\Data";
        std::string out = "C:\\TLBB\\085\\CY-Source\\Build\\Logs\\2026-09-12-postfx";
        std::string models = "M27,D01,D02,M34";
        std::string cases;          // empty = all
        int frames = 4;
        int warmup = 60;
        int bench = 0;
        bool show = false;
        bool list = false;
        bool matsys = true;
    };

    /// Oracle model cases (Tests/oracle/cases.json); names are GBK bytes (execution charset 936).
    /// M07-M26, M28-M29, M38-M43 carry the 6-value (min, max) BoundingBox attribute of the 2023+ data, which
    /// 0.85's LogicModel::_createBoundingBoxFromExternal rejects ("parameter count must be 3"); the defaults
    /// are models without it (D01/D02 = the TlbbViewer reference models).
    struct ModelDef
    {
        const char* id;
        const char* obj;
    };
    const ModelDef kModels[] =
    {
        { "D01", "女主角大理高模.obj" },
        { "D02", "男主角大理高模.obj" },
        { "M27", "W_cloth_2024白晶晶npc.obj" },
        { "M34", "dweapon_2026七夕项羽战旗五级.obj" },
        { "M01", "dweapon_2025情人节银狼伞开男主角1级.obj" },
        { "M07", "npc女主角曼陀套装高模展示.obj" },
        { "M08", "npc男主角曼陀套装高模展示.obj" },
        { "M09", "pet_2026狐狸小萝莉五级.obj" },
        { "M14", "pet_2026情人节丘比特五级02.obj" },
        { "M20", "骑乘230706比武招亲花轿高级.obj" },
        { "M30", "dweapon_2026夏日海洋法杖.obj" },
        { "M40", "npc_2026夏日预热盈霜花树五态.obj" },
        { "M42", "npc_2026象棋pvp车汉.obj" },
    };

    FILE* gSummary = NULL;
    char gDumpPath[MAX_PATH] = { 0 };

    void say(const std::string& text)
    {
        std::printf("%s\n", text.c_str());
        std::fflush(stdout);
        if (Ogre::LogManager::getSingletonPtr())
            Ogre::LogManager::getSingleton().logMessage("[CysPostFxTest] " + text, Ogre::LML_CRITICAL);
        if (gSummary)
        {
            std::fprintf(gSummary, "%s\n", text.c_str());
            std::fflush(gSummary);
        }
    }

    std::vector<std::string> split(const std::string& s, char sep)
    {
        std::vector<std::string> r;
        std::string cur;
        for (size_t i = 0; i <= s.size(); ++i)
        {
            if (i == s.size() || s[i] == sep)
            {
                if (!cur.empty())
                    r.push_back(cur);
                cur.clear();
            }
            else
            {
                cur += s[i];
            }
        }
        return r;
    }

    std::string trimmed(const std::string& s)
    {
        const char* ws = " \t\r\n";
        const size_t b = s.find_first_not_of(ws);
        if (b == std::string::npos)
            return std::string();
        return s.substr(b, s.find_last_not_of(ws) - b + 1);
    }

    bool endsWithNoCase(const std::string& s, const std::string& suffix)
    {
        if (s.size() < suffix.size())
            return false;
        for (size_t i = 0; i < suffix.size(); ++i)
        {
            if (tolower((unsigned char)s[s.size() - suffix.size() + i]) != tolower((unsigned char)suffix[i]))
                return false;
        }
        return true;
    }

    std::string narrow(const wchar_t* w)
    {
        char buffer[4096] = { 0 };
        WideCharToMultiByte(CP_ACP, 0, w, -1, buffer, sizeof(buffer) - 1, NULL, NULL);
        return buffer;
    }

    void makeDirectories(const std::string& path)
    {
        for (size_t i = 3; i <= path.size(); ++i)
        {
            if (i == path.size() || path[i] == '\\' || path[i] == '/')
                CreateDirectoryA(path.substr(0, i).c_str(), NULL);
        }
    }

    LONG WINAPI crashFilter(EXCEPTION_POINTERS* ep)
    {
        static volatile LONG entered = 0;
        if (InterlockedExchange(&entered, 1) != 0)
            TerminateProcess(GetCurrentProcess(), 5);
        void* address = (ep && ep->ExceptionRecord) ? ep->ExceptionRecord->ExceptionAddress : NULL;
        HMODULE module = NULL;
        char moduleName[MAX_PATH] = "?";
        if (address && GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                                          (LPCSTR)address, &module))
            GetModuleFileNameA(module, moduleName, MAX_PATH);
        std::fprintf(stderr, "CysPostFxTest: CRASH 0x%08lX at %s+0x%llX\n",
                     ep && ep->ExceptionRecord ? ep->ExceptionRecord->ExceptionCode : 0, moduleName,
                     (unsigned long long)((const char*)address - (const char*)module));
        if (gDumpPath[0])
        {
            HANDLE file = CreateFileA(gDumpPath, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
            if (file != INVALID_HANDLE_VALUE)
            {
                MINIDUMP_EXCEPTION_INFORMATION info;
                info.ThreadId = GetCurrentThreadId();
                info.ExceptionPointers = ep;
                info.ClientPointers = FALSE;
                MiniDumpWriteDump(GetCurrentProcess(), GetCurrentProcessId(), file,
                                  (MINIDUMP_TYPE)(MiniDumpWithIndirectlyReferencedMemory | MiniDumpScanMemory), &info, NULL, NULL);
                CloseHandle(file);
            }
        }
        std::fflush(stderr);
        TerminateProcess(GetCurrentProcess(), 5);
        return EXCEPTION_EXECUTE_HANDLER;
    }

    //=======================================================================
    // lenient script loading (as TlbbViewer)
    //=======================================================================
    /// Drops 'element <Type>' blocks of all.effect whose type has no factory (else the rest of the file is lost).
    std::string filterEffectScript(const std::string& text, const std::set<std::string>& known)
    {
        std::string result;
        result.reserve(text.size());
        enum { NORMAL, WAIT_OPEN, IN_BLOCK } state = NORMAL;
        size_t pos = 0;
        while (pos < text.size())
        {
            size_t eol = text.find('\n', pos);
            size_t next = (eol == std::string::npos) ? text.size() : eol + 1;
            const std::string line = trimmed(text.substr(pos, next - pos));
            bool keep = true;
            if (state == NORMAL)
            {
                if (line.compare(0, 7, "element") == 0)
                {
                    std::istringstream tokens(line);
                    std::string keyword, type;
                    tokens >> keyword >> type;
                    if (keyword == "element" && !type.empty() && known.find(type) == known.end())
                    {
                        keep = false;
                        state = WAIT_OPEN;
                    }
                }
            }
            else if (state == WAIT_OPEN)
            {
                keep = false;
                if (line == "{")
                    state = IN_BLOCK;
            }
            else
            {
                keep = false;
                if (line == "}")
                    state = NORMAL;
            }
            if (keep)
                result.append(text, pos, next - pos);
            pos = next;
        }
        return result;
    }

    /// Drops particle attribute values 0.85's renderers reject (one such line aborts all.particle).
    std::string filterParticleScript(const std::string& text)
    {
        struct Rule { const char* key; const char* values; };
        static const Rule rules[] =
        {
            { "orientation_type",        " oriented_origin oriented_self " },
            { "billboard_type",          " point oriented_common oriented_self perpendicular_common perpendicular_self " },
            { "billboard_origin",        " top_left top_center top_right center_left center center_right"
                                         " bottom_left bottom_center bottom_right " },
            { "billboard_rotation_type", " vertex texcoord " },
        };
        std::string result;
        result.reserve(text.size());
        size_t pos = 0;
        while (pos < text.size())
        {
            size_t eol = text.find('\n', pos);
            size_t next = (eol == std::string::npos) ? text.size() : eol + 1;
            bool keep = true;
            const std::string line = trimmed(text.substr(pos, next - pos));
            for (size_t r = 0; r < sizeof(rules) / sizeof(rules[0]); ++r)
            {
                const size_t n = strlen(rules[r].key);
                if (line.size() > n && line.compare(0, n, rules[r].key) == 0 && (line[n] == ' ' || line[n] == '\t'))
                {
                    const std::string value = trimmed(line.substr(n));
                    keep = std::string(rules[r].values).find(" " + value + " ") != std::string::npos;
                    break;
                }
            }
            if (keep)
                result.append(text, pos, next - pos);
            pos = next;
        }
        return result;
    }

    class TestSystem : public WX::System
    {
    public:
        size_t scriptFiles = 0;
        size_t scriptErrors = 0;

        void initialiseGroup(const Ogre::String& group)
        {
            Ogre::ResourceGroupManager& rgm = Ogre::ResourceGroupManager::getSingleton();
            std::vector<Ogre::ScriptLoader*> loaders;
            loaders.push_back(Ogre::MaterialManager::getSingletonPtr());
            if (Ogre::CompositorManager::getSingletonPtr())
                loaders.push_back(Ogre::CompositorManager::getSingletonPtr());
            if (Ogre::FontManager::getSingletonPtr())
                loaders.push_back(Ogre::FontManager::getSingletonPtr());
            loaders.push_back(Ogre::ParticleSystemManager::getSingletonPtr());
            Ogre::ScriptLoader* effectLoader = NULL;
            if (WX::EffectManager::getSingletonPtr())
            {
                effectLoader = (Ogre::ScriptLoader*)WX::EffectManager::getSingletonPtr();
                loaders.push_back(effectLoader);
            }
            if (WX::LogicModelManager::getSingletonPtr())
                loaders.push_back((Ogre::ScriptLoader*)WX::LogicModelManager::getSingletonPtr());
            if (Ogre::OverlayManager::getSingletonPtr())
                loaders.push_back(Ogre::OverlayManager::getSingletonPtr());
            struct ByOrder
            {
                bool operator()(Ogre::ScriptLoader* a, Ogre::ScriptLoader* b) const
                {
                    return a->getLoadingOrder() < b->getLoadingOrder();
                }
            };
            std::stable_sort(loaders.begin(), loaders.end(), ByOrder());
            for (size_t i = 0; i < loaders.size(); ++i)
                rgm._unregisterScriptLoader(loaders[i]);
            try
            {
                rgm.initialiseResourceGroup(group);
            }
            catch (const Ogre::Exception& e)
            {
                ++scriptErrors;
                say("initialiseResourceGroup(" + group + ") failed: " + e.getDescription());
            }
            for (size_t i = 0; i < loaders.size(); ++i)
                rgm._registerScriptLoader(loaders[i]);

            std::set<std::string> knownElements;
            if (effectLoader)
            {
                WX::EffectManager::ElementFactoryIterator it = WX::EffectManager::getSingleton().getElementFactoryIterator();
                while (it.hasMoreElements())
                {
                    knownElements.insert(it.peekNextKey());
                    it.moveNext();
                }
            }
            for (size_t i = 0; i < loaders.size(); ++i)
            {
                const Ogre::StringVector& patterns = loaders[i]->getScriptPatterns();
                for (Ogre::StringVector::const_iterator p = patterns.begin(); p != patterns.end(); ++p)
                {
                    Ogre::FileInfoListPtr files = rgm.findResourceFileInfo(group, *p);
                    for (Ogre::FileInfoList::iterator fi = files->begin(); fi != files->end(); ++fi)
                        parseOne(loaders[i], loaders[i] == effectLoader, knownElements, *fi, group);
                }
            }
        }

    protected:
        virtual void _createResourceListener(void) {}

        virtual void _loadResources(void)
        {
            Ogre::ResourceGroupManager& rgm = Ogre::ResourceGroupManager::getSingleton();
            initialiseGroup(Ogre::ResourceGroupManager::BOOTSTRAP_RESOURCE_GROUP_NAME);
            Ogre::StringVector groups = rgm.getResourceGroups();
            for (size_t i = 0; i < groups.size(); ++i)
            {
                if (groups[i] != Ogre::ResourceGroupManager::BOOTSTRAP_RESOURCE_GROUP_NAME)
                    initialiseGroup(groups[i]);
            }
        }

    private:
        void parseOne(Ogre::ScriptLoader* loader, bool effect, const std::set<std::string>& known,
                      const Ogre::FileInfo& file, const Ogre::String& group)
        {
            ++scriptFiles;
            try
            {
                Ogre::DataStreamPtr stream = file.archive->open(file.filename);
                if (stream.isNull())
                    return;
                std::string text;
                bool filtered = false;
                if (effect && endsWithNoCase(file.filename, ".effect"))
                {
                    text = filterEffectScript(stream->getAsString(), known);
                    filtered = true;
                }
                else if (loader == Ogre::ParticleSystemManager::getSingletonPtr() && endsWithNoCase(file.filename, ".particle"))
                {
                    text = filterParticleScript(stream->getAsString());
                    filtered = true;
                }
                if (filtered)
                {
                    stream.setNull();
                    Ogre::MemoryDataStream* memory = new Ogre::MemoryDataStream(file.filename, text.size(), true);
                    if (!text.empty())
                        memcpy(memory->getPtr(), text.data(), text.size());
                    stream = Ogre::DataStreamPtr(memory);
                }
                loader->parseScript(stream, group);
            }
            catch (const Ogre::Exception& e)
            {
                ++scriptErrors;
                Ogre::LogManager::getSingleton().logMessage("[CysPostFxTest] script error in " + file.filename + ": " +
                                                            e.getDescription(), Ogre::LML_CRITICAL);
            }
        }
    };

    void mergeBounds(Ogre::SceneNode* node, Ogre::AxisAlignedBox& box)
    {
        Ogre::SceneNode::ObjectIterator objects = node->getAttachedObjectIterator();
        while (objects.hasMoreElements())
        {
            Ogre::MovableObject* object = objects.getNext();
            if (!object->isVisible() || object->getMovableType() != "Entity")
                continue;
            if (static_cast<Ogre::Entity*>(object)->getNumSubEntities() == 0)
                continue;
            const Ogre::AxisAlignedBox& b = object->getWorldBoundingBox(true);
            if (!b.isNull())
            {
                const Ogre::Vector3 size = b.getMaximum() - b.getMinimum();
                if (size.x < 1e6f && size.y < 1e6f && size.z < 1e6f)
                    box.merge(b);
            }
        }
        Ogre::Node::ChildNodeIterator children = node->getChildIterator();
        while (children.hasMoreElements())
            mergeBounds(static_cast<Ogre::SceneNode*>(children.getNext()), box);
    }

    float smooth(float e0, float e1, float x)
    {
        float t = (x - e0) / (e1 - e0);
        t = t < 0.0f ? 0.0f : (t > 1.0f ? 1.0f : t);
        return t * t * (3.0f - 2.0f * t);
    }

    unsigned int hash2(int x, int y)
    {
        unsigned int h = (unsigned int)(x * 374761393 + y * 668265263);
        h = (h ^ (h >> 13)) * 1274126177u;
        return h ^ (h >> 16);
    }

    //=======================================================================
    // GPU timestamps (CYS fx-render 2026-09-13)
    //=======================================================================
    /// D3D9 timestamp queries at the frame start, at every render-target update (render nodes, compositor targets,
    /// the window) and right before every post-chain pass; a segment is attributed to the mark that starts it.
    class GpuProfiler : public Ogre::RenderTargetListener
    {
    public:
        bool init(IDirect3DDevice9* device)
        {
            mDevice = device;
            if (!device || FAILED(device->CreateQuery(D3DQUERYTYPE_TIMESTAMP, NULL)) ||
                FAILED(device->CreateQuery(D3DQUERYTYPE_TIMESTAMPDISJOINT, &mDisjoint)) ||
                FAILED(device->CreateQuery(D3DQUERYTYPE_TIMESTAMPFREQ, &mFreq)))
                return false;
            mOk = true;
            return true;
        }

        void release(void)
        {
            for (size_t i = 0; i < mPool.size(); ++i)
                mPool[i]->Release();
            mPool.clear();
            if (mDisjoint)
                mDisjoint->Release();
            if (mFreq)
                mFreq->Release();
            mDisjoint = mFreq = NULL;
            mOk = false;
        }

        bool ok(void) const { return mOk; }

        /// Every render target, again each frame: pipelines re-create their render nodes when they rebuild.
        void attachTargets(bool attach)
        {
            Ogre::RenderSystem::RenderTargetIterator it = Ogre::Root::getSingleton().getRenderSystem()->getRenderTargetIterator();
            while (it.hasMoreElements())
            {
                Ogre::RenderTarget* t = it.getNext();
                t->removeListener(this);
                if (attach)
                    t->addListener(this);
            }
        }

        void beginFrame(void)
        {
            if (!mOk)
                return;
            mUsed = 0;
            mLabels.clear();
            mActive = true;
            mDisjoint->Issue(D3DISSUE_BEGIN);
            mark("begin");
        }

        void mark(const std::string& label)
        {
            if (!mActive)
                return;
            if (mUsed == mPool.size())
            {
                IDirect3DQuery9* q = NULL;
                if (FAILED(mDevice->CreateQuery(D3DQUERYTYPE_TIMESTAMP, &q)))
                    return;
                mPool.push_back(q);
            }
            mPool[mUsed++]->Issue(D3DISSUE_END);
            mLabels.push_back(label);
        }

        void endFrame(void)
        {
            if (!mActive)
                return;
            mark("end");
            mDisjoint->Issue(D3DISSUE_END);
            mFreq->Issue(D3DISSUE_END);
            mActive = false;
        }

        /// Waits for the frame's queries; ms per mark label (segment to the next mark) and the frame total.
        bool collect(std::map<std::string, double>& ms, double& total)
        {
            ms.clear();
            total = 0.0;
            if (!mOk || mUsed < 2)
                return false;
            BOOL disjoint = TRUE;
            UINT64 frequency = 0;
            while (mDisjoint->GetData(&disjoint, sizeof(disjoint), D3DGETDATA_FLUSH) == S_FALSE)
            {
            }
            while (mFreq->GetData(&frequency, sizeof(frequency), D3DGETDATA_FLUSH) == S_FALSE)
            {
            }
            if (disjoint || frequency == 0)
                return false;
            std::vector<UINT64> ts(mUsed, 0);
            for (size_t i = 0; i < mUsed; ++i)
            {
                while (mPool[i]->GetData(&ts[i], sizeof(UINT64), D3DGETDATA_FLUSH) == S_FALSE)
                {
                }
            }
            for (size_t i = 0; i + 1 < mUsed; ++i)
                ms[mLabels[i]] += double(ts[i + 1] - ts[i]) * 1000.0 / double(frequency);
            total = double(ts[mUsed - 1] - ts[0]) * 1000.0 / double(frequency);
            return true;
        }

        void preRenderTargetUpdate(const Ogre::RenderTargetEvent& evt)
        {
            mark("target " + evt.source->getName());
        }

    private:
        IDirect3DDevice9* mDevice = NULL;
        IDirect3DQuery9* mDisjoint = NULL;
        IDirect3DQuery9* mFreq = NULL;
        std::vector<IDirect3DQuery9*> mPool;
        std::vector<std::string> mLabels;
        size_t mUsed = 0;
        bool mOk = false;
        bool mActive = false;
    };

    /// CysPostFx pass observer -> profiler mark ("pass <stage type>", pipeline passes: depth node / final copy).
    void observePass(void* user, const Ogre::String& type, unsigned int id)
    {
        std::string label = "pass " + type;
        if (type == "Pipeline")
            label += id == 1 ? " depth node" : (id == 2 ? " final copy" : "");
        static_cast<GpuProfiler*>(user)->mark(label);
    }

    double medianOf(std::vector<double> v)
    {
        if (v.empty())
            return 0.0;
        std::sort(v.begin(), v.end());
        return v[v.size() / 2];
    }

    //=======================================================================
    // the test
    //=======================================================================
    class App
    {
    public:
        explicit App(const Options& o) : mOpt(o) {}

        int run(HWND hwnd)
        {
            mHwnd = hwnd;
            initEngine();
            createContent();
            say("warm-up " + Ogre::StringConverter::toString(mOpt.warmup) + " frames (dt 1/30 s), then the world is frozen");
            for (int i = 0; i < mOpt.warmup; ++i)
            {
                pump();
                renderFrame(1.0f / 30.0f, NULL);
            }
            buildCases();
            if (mOpt.list)
            {
                for (size_t i = 0; i < mCases.size(); ++i)
                    say(mCases[i].name + " - " + mCases[i].what);
                return 0;
            }
            std::set<std::string> wanted;
            std::vector<std::string> names = split(mOpt.cases, ',');
            wanted.insert(names.begin(), names.end());
            int failures = 0;
            for (size_t i = 0; i < mCases.size(); ++i)
            {
                if (!wanted.empty() && !wanted.count(mCases[i].name))
                    continue;
                if (!runCase(mCases[i]))
                    ++failures;
            }
            resetFilters();
            renderFrame(0.0f, NULL);
            writeBenchSummary();
#ifdef CYS_WXRENDER_MATERIAL_SYSTEM
            if (mOpt.matsys)    // CYS fx-render: per-frame cost of the material system's render-queue hook
                say("material system: " + CYS::MaterialSystem::getSingleton().getFrameStats());
#endif
            shutdown();
            return failures ? 4 : 0;
        }

        void shutdown(void)
        {
            if (!mSystem)
                return;
            WX::CysPostFx::setPassObserver(0, 0);    // CYS fx-render
            if (mProfiler.ok())
            {
                mProfiler.attachTargets(false);
                mProfiler.release();
            }
            resetFilters();
            WX::LogicModelManager* lm = WX::LogicModelManager::getSingletonPtr();
            for (size_t i = 0; i < mModels.size(); ++i)
            {
                if (lm)
                    lm->destroyLogicModel(mModels[i]);
            }
            mModels.clear();
            Ogre::SceneManager* sm = mSystem->getSceneManager();
            if (mSky)
            {
                mSkyNode->detachAllObjects();
                delete mSky;
                mSky = NULL;
            }
            if (sm)
            {
                if (mGround)
                {
                    mGroundNode->detachAllObjects();
                    sm->destroyEntity(mGround);
                    mGround = NULL;
                }
                for (size_t i = 0; i < mLights.size(); ++i)
                    sm->destroyLight(mLights[i]);
                mLights.clear();
            }
#ifdef CYS_WXRENDER_MATERIAL_SYSTEM
            if (mOpt.matsys)
                CYS::MaterialSystem::getSingleton().uninstall();
#endif
            delete mSystem;
            mSystem = NULL;
        }

    private:
        struct Case
        {
            std::string name;
            std::string what;
            std::function<void()> setup;
        };

        //-------------------------------------------------------------------
        void initEngine(void)
        {
            makeDirectories(mOpt.out);
            mLog = new Ogre::LogManager();
            mLog->createLog(mOpt.out + "\\CysPostFxTest.log", true, false, false);
            mLog->setLogDetail(Ogre::LL_LOW);

            mSystem = new TestSystem();
            mSystem->init("", "", "", mOpt.out + "\\CysPostFxTest.log");
            addResourceLocations();
            Ogre::Root* root = mSystem->getRoot();
            root->loadRenderPlugins_D3D9();
            root->loadInnerPlugins();
            Ogre::MaterialManager::getSingleton().setDefaultTextureFiltering(Ogre::TFO_ANISOTROPIC);
            Ogre::MaterialManager::getSingleton().setDefaultAnisotropy(8);
#ifdef CYS_WXRENDER_MATERIAL_SYSTEM
            if (mOpt.matsys)
            {
                // the WXRender runtime material system (materials agent): pairs vertex programs with client_GL's
                // pixel-only templates; installed before the scripts compile programs, as OgreSmoke does
                CYS::MaterialSystem::getSingleton().install(mOpt.out + "\\ShaderCache", mOpt.data + "\\MaterialTemplates.zip");
                say("material system installed");
            }
#endif
            WX::System::NameValuePairList params;
            params["FSAA"] = "0";          // the post pipeline renders the scene into a non-multisampled target
            params["vsync"] = "false";
            const DWORD t0 = GetTickCount();
            mSystem->setup((size_t)(UINT_PTR)mHwnd, &params);
            say("engine ready in " + Ogre::StringConverter::toString((int)(GetTickCount() - t0)) + " ms; scripts " +
                Ogre::StringConverter::toString(mSystem->scriptFiles) + " files, " +
                Ogre::StringConverter::toString(mSystem->scriptErrors) + " aborted");
            mWindow = mSystem->getRenderWindow();
            mCamera = mSystem->getCamera();
            mViewport = mSystem->getViewport();
            mWindow->setAutoUpdated(false);
            Ogre::ParticleSystem::setDefaultIterationInterval(0.033f);
            if (mSystem->getFrameStatsListener())
            {
                mSystem->getFrameStatsListener()->showLogoPanel(false);
                mSystem->getFrameStatsListener()->showStatPanel(false);
                mSystem->getFrameStatsListener()->showDebugOverlay(false);
            }
            if (!WX::EffectManager::getSingleton().getTemplate("Effect_Error"))
                WX::EffectManager::getSingleton().createEffectTemplate("Effect_Error");

            mFilters = mSystem->getPostFilterManager();
            WX::registerAllPostFilterFactories(mFilters);       // 0.85 filters + CY-Source filters
            say(std::string("CY-Source post-processing media: ") + (WX::CysPostFx::initialiseMedia() ? "loaded" : "MISSING"));

            // CYS fx-render: GPU timestamps for --bench
            IDirect3DDevice9* device = NULL;
            mWindow->getCustomAttribute("D3DDEVICE", &device);
            if (mOpt.bench > 0 && mProfiler.init(device))
            {
                WX::CysPostFx::setPassObserver(observePass, &mProfiler);
                say("GPU timestamps: on (per render target and post pass)");
            }
        }

        void addResourceLocations(void)
        {
            Ogre::ResourceGroupManager& rgm = Ogre::ResourceGroupManager::getSingleton();
            static const char* zips[] = { "OgreCore.zip", "MaterialTemplates.zip" };
            for (size_t i = 0; i < sizeof(zips) / sizeof(zips[0]); ++i)
                rgm.addResourceLocation(mOpt.data + "\\" + zips[i], "Zip", Ogre::ResourceGroupManager::BOOTSTRAP_RESOURCE_GROUP_NAME, false);
            struct Folder { const char* name; const char* group; };
            static const Folder folders[] =
            {
                { "EffectFolder", "General" }, { "ModelFolder", "General" }, { "Model2Folder", "General" },
                { "Model3Folder", "General" }, { "Model4Folder", "General" }, { "Model5Folder", "General" },
                { "Model6Folder", "General" }, { "Model7Folder", "General" }, { "Model8Folder", "General" },
                { "InterfaceFolder", "General" }, { "MaterialFolder", "General" }, { "Material2Folder", "General" },
                { "Material3Folder", "General" }, { "Material4Folder", "General" }, { "Material5Folder", "General" },
                { "Material6Folder", "General" }, { "Material7Folder", "General" }, { "Material8Folder", "General" },
                { "SoundFolder", "General" }, { "ConfigFolder", "General" }, { "BrushesFolder", "Brushes" },
                { "SceneFolder", "Scene" },
            };
            size_t count = 0;
            for (size_t i = 0; i < sizeof(folders) / sizeof(folders[0]); ++i)
            {
                const std::string dir = mOpt.data + "\\" + folders[i].name;
                const DWORD a = GetFileAttributesA(dir.c_str());
                if (a != INVALID_FILE_ATTRIBUTES && (a & FILE_ATTRIBUTE_DIRECTORY))
                    addFolderTree(dir, folders[i].group, count);
            }
            say(Ogre::StringConverter::toString(count) + " resource locations under " + mOpt.data);
        }

        void addFolderTree(const std::string& dir, const std::string& group, size_t& count)
        {
            Ogre::ResourceGroupManager::getSingleton().addResourceLocation(dir, "FileSystem", group, false);
            ++count;
            std::vector<std::string> subdirs;
            WIN32_FIND_DATAA fd;
            HANDLE h = FindFirstFileA((dir + "\\*").c_str(), &fd);
            if (h == INVALID_HANDLE_VALUE)
                return;
            do
            {
                if ((fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) && strcmp(fd.cFileName, ".") && strcmp(fd.cFileName, ".."))
                    subdirs.push_back(fd.cFileName);
            } while (FindNextFileA(h, &fd));
            FindClose(h);
            std::sort(subdirs.begin(), subdirs.end());
            for (size_t i = 0; i < subdirs.size(); ++i)
                addFolderTree(dir + "\\" + subdirs[i], group, count);
        }

        //-------------------------------------------------------------------
        void createContent(void)
        {
            createModels();
            frameCamera();
            createLights();
            createGround();
            createSky();
        }

        void createModels(void)
        {
            WX::LogicModelManager& mgr = WX::LogicModelManager::getSingleton();
            std::vector<std::string> ids = split(mOpt.models, ',');
            for (size_t i = 0; i < ids.size(); ++i)
            {
                const ModelDef* def = NULL;
                for (size_t k = 0; k < sizeof(kModels) / sizeof(kModels[0]); ++k)
                {
                    if (ids[i] == kModels[k].id)
                        def = &kModels[k];
                }
                if (!def)
                {
                    say("unknown model id " + ids[i]);
                    continue;
                }
                if (!mgr.getTemplateByName(def->obj))
                {
                    say("model " + ids[i] + " is not in all.obj");
                    continue;
                }
                try
                {
                    WX::LogicModel* m = mgr.createLogicModel("CysPostFxTest/" + ids[i], def->obj);
                    m->setParentSceneNode(mSystem->getBaseSceneNode());
                    Ogre::Vector3 origin = Ogre::Vector3::ZERO;     // LogicModel::setPosition takes Vector3&
                    m->setPosition(origin);
                    mModels.push_back(m);
                    mModelIds.push_back(ids[i]);
                }
                catch (const Ogre::Exception& e)
                {
                    say("model " + ids[i] + " failed: " + e.getDescription());
                }
            }

            // one row on the ground, feet on y = 0, slightly staggered in depth
            mSystem->getSceneManager()->getRootSceneNode()->_update(true, false);
            std::vector<Ogre::AxisAlignedBox> boxes;
            float total = 0.0f, maxHeight = 0.0f;
            for (size_t i = 0; i < mModels.size(); ++i)
            {
                Ogre::AxisAlignedBox b;
                b.setNull();
                if (mModels[i]->getSceneNode())
                    mergeBounds(mModels[i]->getSceneNode(), b);
                if (b.isNull())
                    b.setExtents(-50, 0, -50, 50, 150, 50);
                boxes.push_back(b);
                total += b.getMaximum().x - b.getMinimum().x;
                maxHeight = std::max(maxHeight, b.getMaximum().y - b.getMinimum().y);
            }
            const float gap = std::max(25.0f, maxHeight * 0.12f);
            total += gap * (mModels.empty() ? 0 : (float)(mModels.size() - 1));
            float x = -total * 0.5f;
            for (size_t i = 0; i < mModels.size(); ++i)
            {
                const Ogre::AxisAlignedBox& b = boxes[i];
                const float z = (i % 2) ? -0.25f * maxHeight : 0.1f * maxHeight;
                Ogre::Vector3 position(x - b.getMinimum().x, -b.getMinimum().y, z - b.getCenter().z);
                mModels[i]->setPosition(position);
                x += (b.getMaximum().x - b.getMinimum().x) + gap;
                say("model " + mModelIds[i] + " size " + Ogre::StringConverter::toString(b.getMaximum() - b.getMinimum()));
            }
        }

        void frameCamera(void)
        {
            mSystem->getSceneManager()->getRootSceneNode()->_update(true, false);
            Ogre::AxisAlignedBox box;
            box.setNull();
            for (size_t i = 0; i < mModels.size(); ++i)
            {
                if (mModels[i]->getSceneNode())
                    mergeBounds(mModels[i]->getSceneNode(), box);
            }
            if (box.isNull())
                box.setExtents(-200, 0, -100, 200, 200, 100);
            const float fov = 38.0f;
            const float aspect = (float)mViewport->getActualWidth() / (float)std::max(1, mViewport->getActualHeight());
            const float ty = std::tan(Ogre::Degree(fov * 0.5f).valueRadians());
            const Ogre::Vector3 half = box.getHalfSize();
            mTarget = box.getCenter() + Ogre::Vector3(0.0f, -0.08f * half.y, 0.0f);
            mDist = std::max(half.x / (ty * aspect), half.y / ty) * 1.12f + half.z;
            const float yaw = Ogre::Degree(16.0f).valueRadians();
            const float pitch = Ogre::Degree(8.0f).valueRadians();
            const Ogre::Vector3 eye = mTarget + Ogre::Vector3(std::cos(pitch) * std::sin(yaw), std::sin(pitch),
                                                              std::cos(pitch) * std::cos(yaw)) * mDist;
            mCamera->setPosition(eye);
            mCamera->lookAt(mTarget);
            mCamera->setFOVy(Ogre::Degree(fov));
            mCamera->setAspectRatio(aspect);
            mCamera->setNearClipDistance(std::max(1.0f, mDist * 0.01f));
            mCamera->setFarClipDistance(std::max(mDist * 60.0f, 30000.0f));

            // low sun in the upper left of the frame, behind the models: rim light, god rays, fog in-scattering
            const Ogre::Vector3 f = mCamera->getDerivedDirection();
            const Ogre::Vector3 r = mCamera->getDerivedRight();
            const Ogre::Vector3 u = mCamera->getDerivedUp();
            mSunDir = (f * 1.0f - r * 0.50f + u * 0.30f).normalisedCopy();
            if (mSunDir.y < 0.12f)
            {
                mSunDir.y = 0.12f;
                mSunDir.normalise();
            }
            say("camera distance " + Ogre::StringConverter::toString(mDist) + ", target " +
                Ogre::StringConverter::toString(mTarget) + ", sun " + Ogre::StringConverter::toString(mSunDir));
        }

        void createLights(void)
        {
            Ogre::SceneManager* sm = mSystem->getSceneManager();
            sm->setAmbientLight(Ogre::ColourValue(0.40f, 0.42f, 0.48f));
            Ogre::Light* sun = sm->createLight("CysPostFxTest/Sun");
            sun->setType(Ogre::Light::LT_DIRECTIONAL);
            sun->setDirection(-mSunDir);
            sun->setDiffuseColour(1.05f, 0.95f, 0.82f);
            sun->setSpecularColour(0.7f, 0.66f, 0.60f);
            mLights.push_back(sun);
            const Ogre::Vector3 f = mCamera->getDerivedDirection();
            const Ogre::Vector3 r = mCamera->getDerivedRight();
            const Ogre::Vector3 u = mCamera->getDerivedUp();
            Ogre::Light* fill = sm->createLight("CysPostFxTest/Fill");
            fill->setType(Ogre::Light::LT_DIRECTIONAL);
            fill->setDirection((f - u * 0.45f + r * 0.35f).normalisedCopy());
            fill->setDiffuseColour(0.50f, 0.53f, 0.60f);
            fill->setSpecularColour(0.12f, 0.12f, 0.14f);
            mLights.push_back(fill);
        }

        void createGround(void)
        {
            const int n = 512;
            std::vector<unsigned char> px(n * n * 3);
            for (int y = 0; y < n; ++y)
            {
                for (int x = 0; x < n; ++x)
                {
                    const int tx = x / 64, ty = y / 64, gx = x % 64, gy = y % 64;
                    const float grout = (gx < 2 || gy < 2) ? 0.55f : 1.0f;
                    const float tile = ((hash2(tx, ty) & 255) / 255.0f - 0.5f) * 0.10f;
                    const float grain = ((hash2(x * 7, y * 13) & 255) / 255.0f - 0.5f) * 0.06f;
                    const float v = (0.52f + tile + grain) * grout;
                    unsigned char* p = &px[(y * n + x) * 3];
                    p[0] = (unsigned char)std::min(255.0f, v * 1.03f * 255.0f);
                    p[1] = (unsigned char)std::min(255.0f, v * 0.99f * 255.0f);
                    p[2] = (unsigned char)std::min(255.0f, v * 0.92f * 255.0f);
                }
            }
            Ogre::Image img;
            img.loadDynamicImage(&px[0], n, n, 1, Ogre::PF_BYTE_RGB);
            Ogre::TextureManager::getSingleton().loadImage("CysPostFxTest/GroundTex", "General", img, Ogre::TEX_TYPE_2D, -1);

            Ogre::MaterialPtr mat = Ogre::MaterialManager::getSingleton().create("CysPostFxTest/Ground", "General");
            if (mat->getNumTechniques() == 0)
                mat->createTechnique();
            if (mat->getTechnique(0)->getNumPasses() == 0)
                mat->getTechnique(0)->createPass();
            Ogre::Pass* p = mat->getTechnique(0)->getPass(0);
            p->setLightingEnabled(true);
            p->setAmbient(0.9f, 0.9f, 0.9f);
            p->setDiffuse(0.85f, 0.85f, 0.85f, 1.0f);
            p->setSpecular(0.06f, 0.06f, 0.06f, 1.0f);
            p->setShininess(24.0f);
            Ogre::TextureUnitState* tu = p->createTextureUnitState("CysPostFxTest/GroundTex");
            tu->setTextureFiltering(Ogre::TFO_ANISOTROPIC);
            tu->setTextureAnisotropy(8);

            Ogre::MeshManager::getSingleton().createPlane("CysPostFxTest/GroundMesh", "General",
                Ogre::Plane(Ogre::Vector3::UNIT_Y, 0.0f), 16000.0f, 16000.0f, 48, 48, true, 1, 48.0f, 48.0f, Ogre::Vector3::UNIT_Z);
            Ogre::SceneManager* sm = mSystem->getSceneManager();
            mGround = sm->createEntity("CysPostFxTest/Ground", "CysPostFxTest/GroundMesh");
            mGround->setMaterialName("CysPostFxTest/Ground");
            mGround->setCastShadows(false);
            mGroundNode = mSystem->getBaseSceneNode()->createChildSceneNode();
            mGroundNode->setPosition(mTarget.x, 0.0f, mTarget.z);
            mGroundNode->attachObject(mGround);
        }

        Ogre::Vector3 skyColour(const Ogre::Vector3& d) const
        {
            const Ogre::Vector3 horizon(0.72f, 0.80f, 0.90f), zenith(0.22f, 0.40f, 0.72f), ground(0.50f, 0.50f, 0.52f);
            Ogre::Vector3 c;
            if (d.y >= 0.0f)
                c = horizon + (zenith - horizon) * std::pow(std::min(1.0f, d.y / 0.55f), 0.6f);
            else
                c = horizon + (ground - horizon) * std::min(1.0f, -d.y * 8.0f);
            const float cs = std::max(0.0f, d.dotProduct(mSunDir));
            const float disc = smooth(0.99975f, 0.99990f, cs);
            const float glow = std::pow(cs, 600.0f) * 1.5f + std::pow(cs, 60.0f) * 0.25f + std::pow(cs, 8.0f) * 0.06f;
            return c + Ogre::Vector3(1.0f, 0.86f, 0.66f) * glow + Ogre::Vector3(1.0f, 0.97f, 0.90f) * (disc * 14.0f);
        }

        void createSky(void)
        {
            // Backdrop for the fixed camera: gradient + HDR sun disc (values > 1 reach the FP16 scene target through
            // CysPostFX/CopyFP). Queue SKIES_EARLY, no depth: the depth node keeps the far value there (sky).
            const int w = 480, h = 270;
            std::vector<float> px(w * h * 3);
            const Ogre::Quaternion q = mCamera->getDerivedOrientation();
            const float ty = Ogre::Math::Tan(mCamera->getFOVy() * 0.5f);
            const float tx = ty * mCamera->getAspectRatio();
            for (int y = 0; y < h; ++y)
            {
                for (int x = 0; x < w; ++x)
                {
                    const float nx = ((x + 0.5f) / w) * 2.0f - 1.0f;
                    const float ny = 1.0f - ((y + 0.5f) / h) * 2.0f;
                    const Ogre::Vector3 d = (q * Ogre::Vector3(nx * tx, ny * ty, -1.0f)).normalisedCopy();
                    const Ogre::Vector3 c = skyColour(d);
                    float* p = &px[(y * w + x) * 3];
                    p[0] = c.x;
                    p[1] = c.y;
                    p[2] = c.z;
                }
            }
            Ogre::Image img;
            img.loadDynamicImage(reinterpret_cast<Ogre::uchar*>(&px[0]), w, h, 1, Ogre::PF_FLOAT32_RGB);
            Ogre::TextureManager::getSingleton().loadImage("CysPostFxTest/SkyTex", "General", img, Ogre::TEX_TYPE_2D, 0);

            Ogre::MaterialPtr mat = Ogre::MaterialManager::getSingleton().create("CysPostFxTest/Sky", "General");
            if (mat->getNumTechniques() == 0)
                mat->createTechnique();
            if (mat->getTechnique(0)->getNumPasses() == 0)
                mat->getTechnique(0)->createPass();
            Ogre::Pass* p = mat->getTechnique(0)->getPass(0);
            p->setLightingEnabled(false);
            p->setDepthCheckEnabled(false);
            p->setDepthWriteEnabled(false);
            p->setCullingMode(Ogre::CULL_NONE);
            p->setFog(true, Ogre::FOG_NONE);
            if (!Ogre::MaterialManager::getSingleton().getByName("CysPostFX/Copy").isNull())
            {
                p->setVertexProgram("CysPostFX/QuadVS");
                p->setFragmentProgram("CysPostFX/CopyFP");
            }
            Ogre::TextureUnitState* tu = p->createTextureUnitState("CysPostFxTest/SkyTex");
            tu->setTextureAddressingMode(Ogre::TextureUnitState::TAM_CLAMP);
            tu->setTextureFiltering(Ogre::TFO_BILINEAR);

            mSky = new Ogre::Rectangle2D(true);
            mSky->setCorners(-1.0f, 1.0f, 1.0f, -1.0f);
            mSky->setMaterial("CysPostFxTest/Sky");
            mSky->setRenderQueueGroup(Ogre::RENDER_QUEUE_SKIES_EARLY);
            mSky->setBoundingBox(Ogre::AxisAlignedBox(-1e7f, -1e7f, -1e7f, 1e7f, 1e7f, 1e7f));
            mSkyNode = mSystem->getSceneManager()->getRootSceneNode()->createChildSceneNode();
            mSkyNode->attachObject(mSky);
        }

        //-------------------------------------------------------------------
        WX::PostFilter* filter(const char* type)
        {
            WX::PostFilter* f = WX::CysPostFx::ensureFilter(mFilters, mViewport, type);
            if (!f)
                say(std::string("  no post filter type ") + type);
            return f;
        }

        void param(const char* type, const char* name, const std::string& value)
        {
            WX::PostFilter* f = filter(type);
            if (!f)
                return;
            try
            {
                f->setParameter(name, value);
            }
            catch (const Ogre::Exception& e)
            {
                say(std::string("  ") + type + "." + name + ": " + e.getDescription());
            }
        }

        void enable(const char* type)
        {
            WX::PostFilter* f = filter(type);
            if (f)
                f->setEnabled(true);
        }

        void resetFilters(void)
        {
            if (!mFilters)
                return;
            std::vector<std::string> names;
            const WX::PostFilterManager::PostFilterList& all = mFilters->getPostFilters();
            for (WX::PostFilterManager::PostFilterList::const_iterator it = all.begin(); it != all.end(); ++it)
                names.push_back(it->first);
            for (size_t i = 0; i < names.size(); ++i)
                mFilters->destroyPostFilter(names[i]);
            WX::CysPostFx::applyVariable(mFilters, mViewport, "PostFX.Preset", "b");   // CYS fx-render: every case starts B
        }

        void bloomGL(void)
        {
            // the values client_GL ships in 522 of its 548 .newhdrbloom files (hdr_tune.py, 02 3)
            param("NewHDRBloom", "UseSceneFile", "0");
            param("NewHDRBloom", "UseHDR", "0");
            param("NewHDRBloom", "Intensity", "3");
            param("NewHDRBloom", "Threshold", "0.65");
            param("NewHDRBloom", "SoftKnee", "0.35");
            param("NewHDRBloom", "Exposure", "0");
            param("NewHDRBloom", "BloomColor", "1 1 1 1");
            enable("NewHDRBloom");
        }

        void hdrBloom(void)
        {
            param("NewHDRBloom", "UseSceneFile", "0");
            param("NewHDRBloom", "UseAutoExposure", "1");
            param("NewHDRBloom", "Intensity", "1.0");
            param("NewHDRBloom", "Threshold", "1.0");
            param("NewHDRBloom", "SoftKnee", "0.5");
            param("NewHDRBloom", "Exposure", "0");
            enable("NewHDRBloom");
        }

        void heightFog(void)
        {
            param("HeightFog", "UseEnvironment", "0");  // B .hfog defaults (no scene loaded)
            enable("HeightFog");
        }

        void buildCases(void)
        {
            mCases.clear();
            add("none", "no post filter (reference)", [this] {});
            add("fxaa", "FXAA (B AntiAlias.hlsl FXAA_PS_NOLUMA)", [this] { enable("FXAA"); });
            add("fxaaquality", "FXAAQuality (luma + FXAA 3.11 quality 12)", [this] { enable("FXAAQuality"); });
            add("dlaa", "DLAA (edge + directional blend)", [this] { enable("DLAA"); });
            add("bloom_gl", "NewHDRBloom, client_GL scene values 3 / 0.65 / 0.35, UseHDR 0", [this] { bloomGL(); });
            add("hdr_auto", "NewHDRBloom, B defaults: no bloom, ACES + auto exposure", [this] {
                param("NewHDRBloom", "UseSceneFile", "0");
                param("NewHDRBloom", "UseAutoExposure", "1");
                enable("NewHDRBloom");
            });
            add("hdr_bloom", "NewHDRBloom HDR: bloom 1.0, ACES, auto exposure + adaptation", [this] { hdrBloom(); });
            add("ssao", "GenSSAO (CYS/Global/SSAO + composite)", [this] { enable("GenSSAO"); });
            add("ssao_view", "GenSSAO AO buffer (ShowAO)", [this] { param("GenSSAO", "ShowAO", "1"); enable("GenSSAO"); });
            add("heightfog", "HeightFog, B .hfog defaults", [this] { heightFog(); });
            add("godrays", "GodRays (sun mask, B radial march + blur)", [this] { enable("GodRays"); });
            add("dof", "DoF focused on the models", [this] {
                param("DoF", "FocalDistance", Ogre::StringConverter::toString(mDist));
                param("DoF", "NearBlurDistance", Ogre::StringConverter::toString(mDist * 0.5f));
                param("DoF", "FarBlurDistance", Ogre::StringConverter::toString(mDist * 1.8f));
                param("DoF", "MaxFarBlur", "1");
                enable("DoF");
            });
            add("colorlut", "ColorLUT LUT_06.png", [this] { param("ColorLUT", "LUTImage", "LUT_06.png"); enable("ColorLUT"); });
            add("complexblur", "ComplexBlur (CYS-FX fx-cy: skill radial blur, CY material PostFilters/ComplexBlur; CG_zhuanchang skill values Distance 24 / Unblured 0.1 / Strength 0.08)", [this] {
                param("ComplexBlur", "Distance", "24");
                param("ComplexBlur", "Unblured", "0.1");
                param("ComplexBlur", "Strength", "0.08");
                enable("ComplexBlur");
            });
            add("floodlighting", "0.85 Floodlighting (legacy WX filter, B materials)", [this] { enable("Floodlighting"); });
            add("all", "GenSSAO + FXAA + NewHDRBloom HDR + HeightFog + GodRays", [this] {
                enable("GenSSAO");
                enable("FXAA");
                hdrBloom();
                heightFog();
                enable("GodRays");
            });
            add("all_gl", "GenSSAO + FXAA + NewHDRBloom client_GL values + HeightFog + GodRays", [this] {
                enable("GenSSAO");
                enable("FXAA");
                bloomGL();
                heightFog();
                enable("GodRays");
            });
            add("config", "same set as 'all' from a start-up configuration file (CysPostFx::applyConfigFile)", [this] {
                const std::string path = mOpt.out + "\\postfx_test.cfg";
                FILE* f = std::fopen(path.c_str(), "wb");
                if (f)
                {
                    std::fputs("# CysPostFxTest start-up configuration (the keys of System.cfg / PostFX.cfg)\n"
                               "View_HDRFilter=1\n"
                               "View_Fanhunjiao=1\n"
                               "Gfx_SSAO=1\n"
                               "Gfx_HeightFog=1\n"
                               "Gfx_GodRays=1\n"
                               "PostFX.NewHDRBloom.UseSceneFile=0\n"
                               "PostFX.NewHDRBloom.Intensity=1.0\n"
                               "PostFX.NewHDRBloom.Threshold=1.0\n"
                               "PostFX.NewHDRBloom.UseAutoExposure=1\n"
                               "PostFX.HeightFog.UseEnvironment=0\n", f);
                    std::fclose(f);
                }
                say("  applied " + Ogre::StringConverter::toString(WX::CysPostFx::applyConfigFile(mFilters, mViewport, path)) +
                    " configuration keys from " + path);
            });
            // CYS fx-render: the shipped start-up set (what Render.dll applies when System.cfg sets nothing), with the
            // bloom values client_GL ships per scene since no scene is loaded here
            add("preset", "shipped default: CysPostFx::applyStartup = FXAA + NewHDRBloom (client_GL scene values)", [this] {
                WX::CysPostFx::applyStartup(mFilters, mViewport, NULL, NULL);
                WX::CysPostFx::applyVariable(mFilters, mViewport, "Gfx_HeightFog", "0");  // a scene without height fog
                bloomGL();
            });
            add("preset_fog", "shipped default in a height-fog scene: FXAA + NewHDRBloom + HeightFog", [this] {
                WX::CysPostFx::applyStartup(mFilters, mViewport, NULL, NULL);
                bloomGL();
                heightFog();
            });
            // CYS fx-render: the earlier CY-Source look (FP16 targets, Intensity as a plain weight, ACES path) for A/B
            add("bloom_gl_cinematic", "NewHDRBloom client_GL values on the cinematic preset (before B-exact)", [this] {
                WX::CysPostFx::applyVariable(mFilters, mViewport, "PostFX.Preset", "cinematic");
                bloomGL();
            });
            add("preset_cinematic", "start-up set on the cinematic preset: FXAA + NewHDRBloom (FP16 targets)", [this] {
                WX::CysPostFx::applyStartup(mFilters, mViewport, NULL, NULL);
                WX::CysPostFx::applyVariable(mFilters, mViewport, "Gfx_HeightFog", "0");
                WX::CysPostFx::applyVariable(mFilters, mViewport, "PostFX.Preset", "cinematic");
                bloomGL();
            });
        }

        void add(const char* name, const char* what, std::function<void()> setup)
        {
            Case c;
            c.name = name;
            c.what = what;
            c.setup = setup;
            mCases.push_back(c);
        }

        bool runCase(const Case& c)
        {
            resetFilters();
            say("case " + c.name + ": " + c.what);
            try
            {
                c.setup();
            }
            catch (const Ogre::Exception& e)
            {
                say("  setup failed: " + e.getDescription());
                return false;
            }
            const std::string png = mOpt.out + "\\shot_" + c.name + ".png";
            mCaptureOk = false;
            try
            {
                for (int f = 0; f < mOpt.frames; ++f)
                {
                    pump();
                    renderFrame(0.0f, f == mOpt.frames - 1 ? &png : NULL);
                }
            }
            catch (const Ogre::Exception& e)
            {
                say("  render failed: " + e.getDescription());
                return false;
            }
            std::string enabled;
            const WX::PostFilterManager::PostFilterList& all = mFilters->getPostFilters();
            for (WX::PostFilterManager::PostFilterList::const_iterator it = all.begin(); it != all.end(); ++it)
            {
                if (it->second->getEnabled())
                    enabled += (enabled.empty() ? "" : ", ") + it->first;
            }
            say("  filters on: " + (enabled.empty() ? std::string("(none)") : enabled) + " -> " +
                (mCaptureOk ? png : std::string("CAPTURE FAILED")));
            if (mOpt.bench > 0)
            {
                const BenchResult r = bench(mOpt.bench);
                mBench.push_back(std::make_pair(c.name, r));
                char line[256];
                std::sprintf(line, "  GPU-synchronised frame time: median %.3f ms over %d frames; CPU submit %.3f ms; "
                             "GPU %.3f ms", r.wall, mOpt.bench, r.cpu, r.gpu);
                say(line);
                std::string parts = "  GPU ms by segment:";
                for (std::map<std::string, double>::const_iterator it = r.gpuBy.begin(); it != r.gpuBy.end(); ++it)
                {
                    char part[160];
                    std::sprintf(part, " %s %.3f;", it->first.c_str(), it->second);
                    parts += part;
                }
                say(parts);
            }
            return mCaptureOk;
        }

        //-------------------------------------------------------------------
        void pump(void)
        {
            MSG msg;
            while (PeekMessageW(&msg, NULL, 0, 0, PM_REMOVE))
            {
                TranslateMessage(&msg);
                DispatchMessageW(&msg);
            }
        }

        void renderFrame(float dt, const std::string* capturePath)
        {
            Ogre::Root& root = Ogre::Root::getSingleton();
            Ogre::FrameEvent evt;
            evt.timeSinceLastEvent = dt;
            evt.timeSinceLastFrame = dt;
            root._fireFrameStarted(evt);            // CY-Source pipelines rebuild here
            if (mProfiling)
            {
                mProfiler.attachTargets(true);      // CYS fx-render: GPU timestamps
                mProfiler.beginFrame();
            }
            root._updateAllRenderTargets();         // render textures, incl. the depth / SSAO render nodes
            mWindow->update(false);
            if (mProfiling)
                mProfiler.endFrame();
            if (capturePath)
                mCaptureOk = capture(*capturePath);
            mWindow->swapBuffers(false);
            root._fireFrameEnded(evt);
        }

        bool capture(const std::string& path)
        {
            IDirect3DDevice9* device = NULL;
            IDirect3DSurface9* backBuffer = NULL;
            mWindow->getCustomAttribute("D3DDEVICE", &device);
            mWindow->getCustomAttribute("DDBACKBUFFER", &backBuffer);
            if (!device || !backBuffer)
                return false;
            D3DSURFACE_DESC desc;
            backBuffer->GetDesc(&desc);
            IDirect3DSurface9* resolved = NULL;
            IDirect3DSurface9* system = NULL;
            HRESULT hr = device->CreateRenderTarget(desc.Width, desc.Height, desc.Format, D3DMULTISAMPLE_NONE, 0, FALSE, &resolved, NULL);
            if (SUCCEEDED(hr))
                hr = device->StretchRect(backBuffer, NULL, resolved, NULL, D3DTEXF_NONE);
            if (SUCCEEDED(hr))
                hr = device->CreateOffscreenPlainSurface(desc.Width, desc.Height, desc.Format, D3DPOOL_SYSTEMMEM, &system, NULL);
            if (SUCCEEDED(hr))
                hr = device->GetRenderTargetData(resolved, system);
            if (SUCCEEDED(hr))
                hr = D3DXSaveSurfaceToFileA(path.c_str(), D3DXIFF_PNG, system, NULL, NULL);
            if (system)
                system->Release();
            if (resolved)
                resolved->Release();
            return SUCCEEDED(hr);
        }

        /// CYS fx-render: medians of one bench run.
        struct BenchResult
        {
            double wall = 0.0;                      ///< frame incl. the wait for the GPU (event query)
            double cpu = 0.0;                       ///< frame submit on the CPU (frame listeners .. Present)
            double gpu = 0.0;                       ///< GPU timestamps, frame start -> end
            std::map<std::string, double> gpuBy;    ///< GPU ms per segment group
        };

        /// Segment group of a profiler mark: post passes by stage, the window, the other render targets.
        std::string groupOf(const std::string& label) const
        {
            if (label.compare(0, 5, "pass ") == 0)
                return label.substr(5);
            if (label == "target " + mWindow->getName())
                return "window";
            if (label.compare(0, 7, "target ") == 0)
                return "scene+targets";
            return label;
        }

        /// Median wall time of frames that each wait for the GPU (D3D event query); the world is frozen.
        /// CYS fx-render: plus the CPU submit time and the GPU timestamps of every frame.
        BenchResult bench(int frames)
        {
            IDirect3DDevice9* device = NULL;
            mWindow->getCustomAttribute("D3DDEVICE", &device);
            IDirect3DQuery9* query = NULL;
            if (device)
                device->CreateQuery(D3DQUERYTYPE_EVENT, &query);
            LARGE_INTEGER freq, t0, t1, t2;
            QueryPerformanceFrequency(&freq);
            std::vector<double> wall, cpu, gpu;
            std::map<std::string, std::vector<double> > by;
            mProfiling = mProfiler.ok();
            for (int i = 0; i < frames + 8; ++i)
            {
                pump();
                QueryPerformanceCounter(&t0);
                renderFrame(0.0f, NULL);
                QueryPerformanceCounter(&t1);
                if (query)
                {
                    query->Issue(D3DISSUE_END);
                    while (query->GetData(NULL, 0, D3DGETDATA_FLUSH) == S_FALSE)
                    {
                    }
                }
                QueryPerformanceCounter(&t2);
                std::map<std::string, double> segments;
                double total = 0.0;
                const bool haveGpu = mProfiling && mProfiler.collect(segments, total);
                if (i < 8)
                    continue;
                wall.push_back(double(t2.QuadPart - t0.QuadPart) * 1000.0 / double(freq.QuadPart));
                cpu.push_back(double(t1.QuadPart - t0.QuadPart) * 1000.0 / double(freq.QuadPart));
                if (haveGpu)
                {
                    gpu.push_back(total);
                    std::map<std::string, double> grouped;
                    for (std::map<std::string, double>::const_iterator it = segments.begin(); it != segments.end(); ++it)
                        grouped[groupOf(it->first)] += it->second;
                    for (std::map<std::string, double>::const_iterator it = grouped.begin(); it != grouped.end(); ++it)
                        by[it->first].push_back(it->second);
                }
            }
            mProfiling = false;
            if (mProfiler.ok())
                mProfiler.attachTargets(false);
            if (query)
                query->Release();
            BenchResult r;
            r.wall = medianOf(wall);
            r.cpu = medianOf(cpu);
            r.gpu = medianOf(gpu);
            for (std::map<std::string, std::vector<double> >::const_iterator it = by.begin(); it != by.end(); ++it)
                r.gpuBy[it->first] = medianOf(it->second);
            return r;
        }

        void writeBenchSummary(void)
        {
            if (mBench.empty())
                return;
            const BenchResult* base = NULL;
            for (size_t i = 0; i < mBench.size(); ++i)
            {
                if (mBench[i].first == "none")
                    base = &mBench[i].second;
            }
            char line[320];
            std::sprintf(line, "bench %dx%d (median of %d GPU-synchronised frames, world frozen):", mOpt.width, mOpt.height, mOpt.bench);
            say(line);
            say("  case            wall ms  vs none | CPU submit  vs none |   GPU ms  vs none | GPU ms of the post passes");
            for (size_t i = 0; i < mBench.size(); ++i)
            {
                const BenchResult& r = mBench[i].second;
                std::string post;
                double postSum = 0.0;
                for (std::map<std::string, double>::const_iterator it = r.gpuBy.begin(); it != r.gpuBy.end(); ++it)
                {
                    if (it->first == "begin" || it->first == "window" || it->first == "scene+targets")
                        continue;
                    char part[96];
                    std::sprintf(part, " %s %.3f", it->first.c_str(), it->second);
                    post += part;
                    postSum += it->second;
                }
                std::sprintf(line, "  %-14s %7.3f %+7.3f | %7.3f %+8.3f | %7.3f %+7.3f | sum %.3f:%s",
                             mBench[i].first.c_str(), r.wall, base ? r.wall - base->wall : 0.0, r.cpu,
                             base ? r.cpu - base->cpu : 0.0, r.gpu, base ? r.gpu - base->gpu : 0.0, postSum, post.c_str());
                say(line);
            }
        }

        Options mOpt;
        HWND mHwnd = NULL;
        Ogre::LogManager* mLog = NULL;
        TestSystem* mSystem = NULL;
        Ogre::RenderWindow* mWindow = NULL;
        Ogre::Camera* mCamera = NULL;
        Ogre::Viewport* mViewport = NULL;
        WX::PostFilterManager* mFilters = NULL;
        std::vector<WX::LogicModel*> mModels;
        std::vector<std::string> mModelIds;
        Ogre::Entity* mGround = NULL;
        Ogre::SceneNode* mGroundNode = NULL;
        Ogre::Rectangle2D* mSky = NULL;
        Ogre::SceneNode* mSkyNode = NULL;
        std::vector<Ogre::Light*> mLights;
        Ogre::Vector3 mTarget = Ogre::Vector3::ZERO;
        Ogre::Vector3 mSunDir = Ogre::Vector3::UNIT_Y;
        float mDist = 600.0f;
        bool mCaptureOk = false;
        std::vector<Case> mCases;
        std::vector<std::pair<std::string, BenchResult> > mBench;
        GpuProfiler mProfiler;                      // CYS fx-render
        bool mProfiling = false;
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
        wc.lpszClassName = L"CysPostFxTestWindow";
        RegisterClassExW(&wc);
        const DWORD style = WS_OVERLAPPEDWINDOW;
        RECT rc = { 0, 0, opt.width, opt.height };
        AdjustWindowRect(&rc, style, FALSE);
        HWND hwnd = CreateWindowExW(0, wc.lpszClassName, L"CysPostFxTest", style, CW_USEDEFAULT, CW_USEDEFAULT,
                                    rc.right - rc.left, rc.bottom - rc.top, NULL, NULL, instance, NULL);
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
            ShowWindow(hwnd, SW_SHOWNORMAL);
        return hwnd;
    }

    bool parseOptions(int argc, wchar_t** argv, Options& o)
    {
        for (int i = 1; i < argc; ++i)
        {
            const std::string a = narrow(argv[i]);
            const bool hasValue = i + 1 < argc;
            if (a == "--data" && hasValue) o.data = narrow(argv[++i]);
            else if (a == "--out" && hasValue) o.out = narrow(argv[++i]);
            else if (a == "--width" && hasValue) o.width = _wtoi(argv[++i]);
            else if (a == "--height" && hasValue) o.height = _wtoi(argv[++i]);
            else if (a == "--models" && hasValue) o.models = narrow(argv[++i]);
            else if (a == "--cases" && hasValue) o.cases = narrow(argv[++i]);
            else if (a == "--frames" && hasValue) o.frames = std::max(2, _wtoi(argv[++i]));
            else if (a == "--warmup" && hasValue) o.warmup = std::max(0, _wtoi(argv[++i]));
            else if (a == "--bench" && hasValue) o.bench = std::max(0, _wtoi(argv[++i]));
            else if (a == "--show") o.show = true;
            else if (a == "--no-matsys") o.matsys = false;
            else if (a == "--list") o.list = true;
            else
            {
                std::printf("usage: CysPostFxTest [--data DIR] [--out DIR] [--width W --height H] [--models M07,M09,...]\n"
                            "                     [--cases a,b,...] [--frames N] [--warmup N] [--bench N] [--show]\n"
                            "                     [--no-matsys] [--list]\n");
                return false;
            }
        }
        return true;
    }

    bool guardedShutdown(App* app)
    {
        __try
        {
            app->shutdown();
            return true;
        }
        __except (EXCEPTION_EXECUTE_HANDLER)
        {
            return false;
        }
    }
}

int wmain(int argc, wchar_t** argv)
{
    SetErrorMode(SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX | SEM_NOOPENFILEERRORBOX);
    SetProcessDPIAware();
    Options opt;
    if (!parseOptions(argc, argv, opt))
        return 1;
    makeDirectories(opt.out);
    std::strncpy(gDumpPath, (opt.out + "\\CysPostFxTest.dmp").c_str(), MAX_PATH - 1);
    SetUnhandledExceptionFilter(crashFilter);
    gSummary = std::fopen((opt.out + "\\summary.txt").c_str(), "wb");

    HWND hwnd = createWindow(opt);
    if (!hwnd)
    {
        say("cannot create the window");
        return 3;
    }
    int rc = 0;
    {
        App app(opt);
        try
        {
            rc = app.run(hwnd);
        }
        catch (const Ogre::Exception& e)
        {
            say("FATAL: " + e.getFullDescription());
            rc = 3;
        }
        if (!guardedShutdown(&app))
            say("warning: fault during engine shutdown (ignored)");
    }
    DestroyWindow(hwnd);
    if (gSummary)
        std::fclose(gSummary);
    return rc;
}
