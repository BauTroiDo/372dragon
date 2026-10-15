// TlbbViewer - engine setup (WX::System on OgreMain + D3D9), client_GL resources, content, camera, frame loop and
// back-buffer capture.
//
// Compatibility shims (all disabled by --strict, all logged): 0.85 WXCore cannot load client_GL data as-is, so the
// viewer (a) parses each script file on its own and keeps going after an exception, (b) only with --legacy-prefilter
// (CYS fx-audit 13/09: the runtime now skips unknown element types and bad particle lines itself and logs them with
// file:line, so the viewer no longer hides them) drops all.effect element blocks without a factory and all.particle
// lines with values 0.85 rejected, (c) provides an
// empty "Effect_Error" template for missing effects, and (d) reads .Scene/.Terrain XML through a proxy handler that
// skips unknown elements / object types and treats <Group> as a transparent container. Data files are never modified.
#include "ViewerApp.h"

#include <OgreRoot.h>
#include <OgreRenderWindow.h>
#include <OgreRenderSystem.h>
#include <OgreCamera.h>
#include <OgreViewport.h>
#include <OgreSceneManager.h>
#include <OgreSceneNode.h>
#include <OgreEntity.h>
#include <OgreSubEntity.h>
#include <OgreLight.h>
#include <OgreManualObject.h>
#include <OgreRectangle2D.h>
#include <OgreMaterialManager.h>
#include <OgreMaterial.h>
#include <OgreTechnique.h>
#include <OgrePass.h>
#include <OgreTextureManager.h>
#include <OgreTextureUnitState.h>
#include <OgreImage.h>
#include <OgreResourceGroupManager.h>
#include <OgreScriptLoader.h>
#include <OgreArchive.h>
#include <OgreDataStream.h>
#include <OgreParticleSystemManager.h>
#include <OgreParticleSystem.h>
#include <OgreCompositorManager.h>
#include <OgreFontManager.h>
#include <OgreOverlayManager.h>
#include <OgreHighLevelGpuProgramManager.h>
#include <OgreHighLevelGpuProgram.h>
#include <OgreLogManager.h>
#include <OgreStringConverter.h>
#include <OgreException.h>
#include <OgreAnimation.h>
#include <OgreFrameListener.h>

#include "Core/WXSystem.h"
#include "Core/Terrain.h"
#include "Core/TerrainData.h"
#include "Core/WXExpatParser.h"
#ifdef CYS_WXRENDER_MATERIAL_SYSTEM
#include "CysMaterialSystem.h" // CYS: WXRender runtime material system (see viewer.cmake)
#endif
#include "Core/WXXMLParser.h"
#include "Core/WXXMLHandler.h"
#include "Core/WXXMLAttributes.h"
#include "Core/WXSceneInfo.h"
#include "CYS/Scene/CYSProjectorObject.h"   // CYS-FIX fix-projector
#include "Core/FrameStatsListener.h"
#include "CYS/Scene/CYSEnvironment.h" // CYS: --time-of-day / --time-scale
#include "ModelSystem/WXLogicModel.h"
#include "ModelSystem/WXLogicModelManager.h"
#include "EffectSystem/WXEffectManager.h"
#include "EffectSystem/WXEffect.h"
#include "EffectSystem/WXEffectBasic.h"
#include "EffectSystem/WXParticleElement.h"	// CYS: fx-effects sub-effect master switch
#include "PostFilter/WXPostFilterManager.h"
#include "PostFilter/WXPostFilters.h"
#include "CYS/PostFX/CysPostFx.h" // CYS fx-render: --postfx
#include "CYS/Shadow/CYSShadowHost.h" // CYS-SHADOW: --shadow
#include "CYS/Water/CysWaterRender.h" // CYS-WATER: CY 3.71 water render targets (CYS_WATER=0 turns them off)

#include <d3d9.h>
#include <d3dx9.h>

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib> // CYS fx-audit: srand
#include <cstring>
#include <ctime>
#include <map>
#include <set>
#include <sstream>

namespace tlbbv
{
    namespace
    {
        const char* const VIEWER_GROUP = "TlbbViewer";

        void logLine(const std::string& text)
        {
            // Critical level: kept even at the default (LL_LOW) log detail.
            if (Ogre::LogManager::getSingletonPtr())
                Ogre::LogManager::getSingleton().logMessage(text, Ogre::LML_CRITICAL);
        }

        void report(const std::string& text)
        {
            out(text);
            logLine(text);
        }

        void reportError(const std::string& text)
        {
            err(text);
            logLine(text);
        }

        std::string trimmed(const std::string& s)
        {
            const char* ws = " \t\r\n";
            size_t b = s.find_first_not_of(ws);
            if (b == std::string::npos)
                return std::string();
            size_t e = s.find_last_not_of(ws);
            return s.substr(b, e - b + 1);
        }

        std::string sizeText(size_t n)
        {
            char buffer[32];
            sprintf(buffer, "%u", (unsigned)n);
            return buffer;
        }

        bool endsWithNoCase(const std::string& s, const std::string& suffix)
        {
            return s.size() >= suffix.size() &&
                   asciiLower(s.substr(s.size() - suffix.size())) == asciiLower(suffix);
        }

        std::string fullPath(const std::string& path)
        {
            char buffer[MAX_PATH * 2] = { 0 };
            DWORD n = GetFullPathNameA(path.c_str(), sizeof(buffer), buffer, NULL);
            std::string r = (n > 0 && n < sizeof(buffer)) ? std::string(buffer, n) : path;
            while (!r.empty() && (r[r.size() - 1] == '\\' || r[r.size() - 1] == '/'))
                r.erase(r.size() - 1);
            return asciiLower(r);
        }

        bool isDirectory(const std::string& path) // CYS fx-audit
        {
            const DWORD attributes = GetFileAttributesA(path.c_str());
            return attributes != INVALID_FILE_ATTRIBUTES && (attributes & FILE_ATTRIBUTE_DIRECTORY) != 0;
        }

        void makeParentDirectories(const std::string& path)
        {
            for (size_t i = 3; i < path.size(); ++i)
            {
                if (path[i] == '\\' || path[i] == '/')
                    CreateDirectoryA(path.substr(0, i).c_str(), NULL);
            }
        }

        // Removes 'element <Type>' blocks whose type has no registered factory. Mirrors how
        // EffectManager::parseEffectFile / skipToNextOpenBrace / parseNewElement consume lines, so the rest of the
        // file stays aligned. Without this, the first unknown type (all.effect:2752, NewRibbonTrail) throws in
        // EffectManager::createElement and every effect after it is lost.
        std::string filterEffectScript(const std::string& text, const std::set<std::string>& known,
                                       std::map<std::string, size_t>& removed)
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
                            ++removed[type];
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

        // Drops particle attribute lines whose setter would throw: 0.85's renderers accept fewer values than the
        // client_GL data uses (mesh 'orientation_type' oriented_camera / oriented_common / perpendicular_*), and one
        // such line (first at all.particle:5193) aborts the whole file (OgreMeshParticleRenderer.cpp:368 ->
        // ParticleSystemManager::parseScript), leaving 96 of ~43,000 particle templates.
        // CYS fx-audit 13/09: only used with --legacy-prefilter. The WXCore mesh renderer now accepts these four
        // values (OgreExt/OgreMeshParticleRenderer.cpp:486-492) and parseScript no longer aborts on a bad line, so
        // dropping them made the viewer render those mesh particles with the default oriented_origin, unlike the game.
        std::string filterParticleScript(const std::string& text, std::map<std::string, size_t>& removed)
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
                const char first = text[pos] == ' ' || text[pos] == '\t' ? 0 : text[pos];
                if (first == 0 || first == 'o' || first == 'b')
                {
                    const std::string line = trimmed(text.substr(pos, next - pos));
                    for (size_t r = 0; r < sizeof(rules) / sizeof(rules[0]); ++r)
                    {
                        const size_t n = strlen(rules[r].key);
                        if (line.size() > n && line.compare(0, n, rules[r].key) == 0 &&
                            (line[n] == ' ' || line[n] == '\t'))
                        {
                            const std::string value = trimmed(line.substr(n));
                            if (std::string(rules[r].values).find(" " + value + " ") == std::string::npos)
                            {
                                keep = false;
                                ++removed[std::string(rules[r].key) + " " + value];
                            }
                            break;
                        }
                    }
                }
                if (keep)
                    result.append(text, pos, next - pos);
                pos = next;
            }
            return result;
        }

        // XML proxy: forwards to the real WX handler; an element whose startElement throws (unknown element or
        // object type) is skipped with its whole subtree; <Group> is a transparent container.
        class LenientXMLHandler : public WX::XMLHandler
        {
        public:
            explicit LenientXMLHandler(WX::XMLHandler& inner)
                : mInner(inner), mSkipDepth(0), mGroups(0)
            {
            }

            virtual void characters(const WX::String& chars)
            {
                if (mSkipDepth == 0)
                    mInner.characters(chars);
            }

            virtual void startElement(const WX::String& element, const WX::XMLAttributes& attributes)
            {
                if (mSkipDepth > 0)
                {
                    ++mSkipDepth;
                    return;
                }
                if (element == "Group")
                {
                    mForwarded.push_back(false);
                    ++mGroups;
                    return;
                }
                try
                {
                    mInner.startElement(element, attributes);
                    mForwarded.push_back(true);
                }
                catch (const Ogre::Exception& e)
                {
                    skip(element, attributes, e.getDescription());
                }
                catch (const std::exception& e)
                {
                    skip(element, attributes, e.what());
                }
            }

            virtual void endElement(const WX::String& element)
            {
                if (mSkipDepth > 0)
                {
                    --mSkipDepth;
                    return;
                }
                if (mForwarded.empty())
                    return;
                const bool forwarded = mForwarded.back();
                mForwarded.pop_back();
                if (forwarded)
                    mInner.endElement(element);
            }

            std::string summary(void) const
            {
                std::string s;
                for (std::map<std::string, size_t>::const_iterator it = mSkipped.begin(); it != mSkipped.end(); ++it)
                    s += (s.empty() ? "" : ", ") + it->first + " x" + sizeText(it->second);
                if (s.empty())
                    s = "nothing skipped";
                else
                    s = "skipped " + s;
                if (mGroups)
                    s += "; " + sizeText(mGroups) + " <Group> flattened";
                return s;
            }

            size_t skippedCount(void) const
            {
                size_t n = 0;
                for (std::map<std::string, size_t>::const_iterator it = mSkipped.begin(); it != mSkipped.end(); ++it)
                    n += it->second;
                return n;
            }

        private:
            void skip(const WX::String& element, const WX::XMLAttributes& attributes, const std::string& why)
            {
                std::string key = element;
                if (element == "Object" && attributes.exists("type"))
                    key += " type=" + attributes.getValue("type");
                if (++mSkipped[key] == 1)
                    logLine("[TlbbViewer] lenient XML: skipping <" + key + "> (" + why + ")");
                mSkipDepth = 1;
            }

            WX::XMLHandler& mInner;
            size_t mSkipDepth;
            size_t mGroups;
            std::vector<bool> mForwarded;
            std::map<std::string, size_t> mSkipped;
        };

        class LenientXMLParser : public WX::XMLParser
        {
        public:
            virtual void parseXMLFile(WX::XMLHandler& handler, const WX::String& filename,
                                      const WX::String& resourceGroup, const WX::String& schemaName,
                                      const WX::String& schemaResourceGroup)
            {
                LenientXMLHandler proxy(handler);
                WX::ExpatParser expat(NULL);
                expat.parseXMLFile(proxy, filename, resourceGroup, schemaName, schemaResourceGroup);
                mSkipped += proxy.skippedCount();
                report("TlbbViewer: " + filename + ": " + proxy.summary());
            }

            size_t mSkipped = 0;
        };

        void mergeBounds(Ogre::SceneNode* node, Ogre::AxisAlignedBox& box, bool entitiesOnly)
        {
            Ogre::SceneNode::ObjectIterator objects = node->getAttachedObjectIterator();
            while (objects.hasMoreElements())
            {
                Ogre::MovableObject* object = objects.getNext();
                if (!object->isVisible())
                    continue;
                const bool isEntity = object->getMovableType() == "Entity";
                if (entitiesOnly && !isEntity)
                    continue;
                // LogicModel's master skeleton entity uses a null mesh whose bounds cover every bone position.
                if (isEntity && static_cast<Ogre::Entity*>(object)->getNumSubEntities() == 0)
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
                mergeBounds(static_cast<Ogre::SceneNode*>(children.getNext()), box, entitiesOnly);
        }
    }

    //=======================================================================
    // WX::System with lenient, per-file script parsing.
    //=======================================================================
    class ViewerSystem : public WX::System
    {
    public:
        explicit ViewerSystem(bool strict)
            : mStrict(strict), mScriptFiles(0), mScriptErrors(0), mEffectElementsDropped(0),
              mLegacyPrefilter(false) // CYS fx-audit
        {
        }

        bool isStrict(void) const { return mStrict; }
        // CYS fx-audit: old line/block dropping (--legacy-prefilter); default off: the runtime decides and logs
        void setLegacyPrefilter(bool on) { mLegacyPrefilter = on; }
        size_t scriptFiles(void) const { return mScriptFiles; }
        size_t scriptErrors(void) const { return mScriptErrors; }
        size_t effectElementsDropped(void) const { return mEffectElementsDropped; }

        void initialiseGroup(const Ogre::String& group)
        {
            Ogre::ResourceGroupManager& rgm = Ogre::ResourceGroupManager::getSingleton();
            if (mStrict)
            {
                rgm.initialiseResourceGroup(group);
                return;
            }

            // Every script loader of this engine, driven here file by file in the stock loading order:
            // programs/materials 100, compositors 110, fonts 200, then particles, effects/skills and logic models
            // (1000, registration order) and overlays 1100 (which reference materials, so they must come after).
            // EffectManager and LogicModelManager inherit ScriptLoader privately; the C-style cast is the one
            // conversion allowed to an inaccessible base.
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

            // Only declared resources (if any) go through the stock path.
            for (size_t i = 0; i < loaders.size(); ++i)
                rgm._unregisterScriptLoader(loaders[i]);
            try
            {
                rgm.initialiseResourceGroup(group);
            }
            catch (const Ogre::Exception& e)
            {
                ++mScriptErrors;
                reportError("TlbbViewer: initialiseResourceGroup(" + group + ") failed: " + e.getFullDescription());
            }
            for (size_t i = 0; i < loaders.size(); ++i)
                rgm._registerScriptLoader(loaders[i]);

            std::set<std::string> knownElements;
            if (effectLoader)
            {
                WX::EffectManager::ElementFactoryIterator it =
                    WX::EffectManager::getSingleton().getElementFactoryIterator();
                while (it.hasMoreElements())
                {
                    knownElements.insert(it.peekNextKey());
                    it.moveNext();
                }
            }

            for (size_t i = 0; i < loaders.size(); ++i)
            {
                Ogre::ScriptLoader* loader = loaders[i];
                const Ogre::StringVector& patterns = loader->getScriptPatterns();
                for (Ogre::StringVector::const_iterator p = patterns.begin(); p != patterns.end(); ++p)
                {
                    Ogre::FileInfoListPtr files = rgm.findResourceFileInfo(group, *p);
                    for (Ogre::FileInfoList::iterator fi = files->begin(); fi != files->end(); ++fi)
                        parseOne(loader, loader == effectLoader, knownElements, *fi, group);
                }
            }
        }

    protected:
        virtual void _createResourceListener(void)
        {
            // Lenient mode initialises the Bootstrap group in _loadResources, like every other group.
            if (mStrict)
                WX::System::_createResourceListener();
        }

        virtual void _loadResources(void)
        {
            if (mStrict)
            {
                WX::System::_loadResources();
                return;
            }
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
        void parseOne(Ogre::ScriptLoader* loader, bool isEffectLoader, const std::set<std::string>& knownElements,
                      const Ogre::FileInfo& file, const Ogre::String& group)
        {
            ++mScriptFiles;
            const DWORD start = GetTickCount();
            logLine("[TlbbViewer] parsing script " + file.filename + " (group " + group + ")");
            try
            {
                Ogre::DataStreamPtr stream = file.archive->open(file.filename);
                if (stream.isNull())
                    return;
                std::map<std::string, size_t> removed;
                std::string text;
                const char* what = NULL;
                // CYS fx-audit: only with --legacy-prefilter (see filterParticleScript); by default the stream goes
                // to the runtime parser unchanged, as in the game, and every rejection is logged with file:line.
                if (mLegacyPrefilter && isEffectLoader && endsWithNoCase(file.filename, ".effect"))
                {
                    text = filterEffectScript(stream->getAsString(), knownElements, removed);
                    what = "element blocks without a factory";
                }
                else if (mLegacyPrefilter && loader == Ogre::ParticleSystemManager::getSingletonPtr() &&
                         endsWithNoCase(file.filename, ".particle"))
                {
                    text = filterParticleScript(stream->getAsString(), removed);
                    what = "attribute lines with values 0.85 rejects";
                }
                if (what)
                {
                    stream.setNull();
                    if (!removed.empty())
                    {
                        std::string list;
                        for (std::map<std::string, size_t>::const_iterator it = removed.begin(); it != removed.end(); ++it)
                        {
                            list += (list.empty() ? "" : ", ") + it->first + " x" + sizeText(it->second);
                            if (isEffectLoader)
                                mEffectElementsDropped += it->second;
                        }
                        report("TlbbViewer: " + file.filename + ": dropped " + what + ": " + list);
                    }
                    Ogre::MemoryDataStream* memory = new Ogre::MemoryDataStream(file.filename, text.size(), true);
                    if (!text.empty())
                        memcpy(memory->getPtr(), text.data(), text.size());
                    stream = Ogre::DataStreamPtr(memory);
                }
                loader->parseScript(stream, group);
            }
            catch (const Ogre::Exception& e)
            {
                ++mScriptErrors;
                reportError("TlbbViewer: SCRIPT ERROR in " + file.filename + " (rest of this file skipped): " +
                            e.getFullDescription());
            }
            catch (const std::exception& e)
            {
                ++mScriptErrors;
                reportError("TlbbViewer: SCRIPT ERROR in " + file.filename + ": " + e.what());
            }
            const DWORD ms = GetTickCount() - start;
            if (ms >= 100)
                logLine("[TlbbViewer] " + file.filename + " parsed in " + sizeText(ms) + " ms");
        }

        bool mStrict;
        size_t mScriptFiles;
        size_t mScriptErrors;
        size_t mEffectElementsDropped;
        bool mLegacyPrefilter; // CYS fx-audit
    };

    //=======================================================================
    ViewerApp::ViewerApp(const Options& opt)
        : mOpt(opt)
        , mHwnd(NULL)
        , mLogManager(NULL)
        , mSystem(NULL)
        , mWindow(NULL)
        , mCamera(NULL)
        , mModel(NULL)
        , mEffect(NULL)
        , mEffectNode(NULL)
        , mModelEffect(0)
        , mBackground(NULL)
        , mBackgroundNode(NULL)
        , mGrid(NULL)
        , mGridNode(NULL)
        , mCameraLight(NULL)
        , mSceneLoaded(false)
        , mContentOrigin(Ogre::Vector3::ZERO)
        , mTarget(Ogre::Vector3::ZERO)
        , mYaw(0.0f)
        , mPitch(0.0f)
        , mDist(500.0f)
        , mFov(45.0f)
        , mOrbiting(false)
        , mPanning(false)
        , mPaused(false)
        , mQuit(false)
        , mShutdown(false)
        , mCaptureRequested(false)
        , mCaptureOk(false)
        , mAutoFrameEffect(false)
        , mAutoFrameModel(false)
        , mLastX(0)
        , mLastY(0)
        , mCaptureCounter(0)
        , mMissing(0)
        , mSimTime(0.0)
    {
    }
    //-----------------------------------------------------------------------
    ViewerApp::~ViewerApp()
    {
        shutdown();
    }
    //-----------------------------------------------------------------------
    void ViewerApp::shutdown(void)
    {
        if (mShutdown)
            return;
        mShutdown = true;
        if (mSystem)
            destroyContentAndEngine();
        // After the engine, so Root can still log its shutdown.
        delete mLogManager;
        mLogManager = NULL;
    }
    //-----------------------------------------------------------------------
    void ViewerApp::destroyContentAndEngine(void)
    {
        Ogre::SceneManager* sm = mSystem->getSceneManager();
        if (mModel && WX::LogicModelManager::getSingletonPtr())
        {
            WX::LogicModelManager::getSingleton().destroyLogicModel(mModel);
            mModel = NULL;
        }
        destroyEffect();
        if (sm)
        {
            if (mGrid)
            {
                mGridNode->detachAllObjects();
                sm->destroyManualObject(mGrid);
                mGrid = NULL;
            }
            if (mBackground)
            {
                mBackgroundNode->detachAllObjects();
                delete mBackground;
                mBackground = NULL;
            }
            for (size_t i = 0; i < mLights.size(); ++i)
                sm->destroyLight(mLights[i]);
            mLights.clear();
            mCameraLight = NULL;
        }
        WX::CYSShadowHost::stop(); // CYS-SHADOW: before the scene manager and Root go
        if (WX::CysWaterRender::getSingletonPtr()) // CYS-WATER
        {
            report("TlbbViewer: water: " + WX::CysWaterRender::getSingletonPtr()->describe());
            WX::CysWaterRender::uninstall();
        }
#ifdef CYS_WXRENDER_MATERIAL_SYSTEM
        if (CYS::MaterialSystem::getSingleton().isInstalled())
        {
            report("TlbbViewer: material system: " + CYS::MaterialSystem::getSingleton().getStats());
            report("TlbbViewer: material system per frame: " + CYS::MaterialSystem::getSingleton().getFrameStats()); // CYS fx-render
            CYS::MaterialSystem::getSingleton().uninstall(); // drop material references before Root goes
        }
#endif
        delete mSystem;
        mSystem = NULL;
    }
    //-----------------------------------------------------------------------
    WX::System* ViewerApp::wxSystem(void) const
    {
        return mSystem; // CYS fx-audit: ViewerSystem is only a complete type in this file
    }
    //-----------------------------------------------------------------------
    int ViewerApp::run(HWND hwnd)
    {
        mHwnd = hwnd;
        try
        {
            initEngine();
        }
        catch (const Ogre::Exception& e)
        {
            reportError("TlbbViewer: engine initialisation failed: " + e.getFullDescription());
            return EXIT_ENGINE;
        }
        catch (const std::exception& e)
        {
            reportError(std::string("TlbbViewer: engine initialisation failed: ") + e.what());
            return EXIT_ENGINE;
        }
        logResourceSummary();

        // CYS fx-audit: batch modes (ViewerFx.cpp)
        if (!mOpt.fxCensusDir.empty())
            return runFxCensus();
        if (!mOpt.fxSheetList.empty())
            return runFxSheet();

        if (!mOpt.list.empty() && mOpt.list != "anims")
            return listNames();

        try
        {
            if (!mOpt.scene.empty() && !loadScene())
                ++mMissing;

            if (mSceneLoaded)
            {
                if (mOpt.hasCamera)
                    mContentOrigin = terrainPoint(mOpt.camera[3], mOpt.camera[5]);
                else
                    mContentOrigin = sceneDefaultTarget();
            }

            if (!mOpt.model.empty() && !createModel())
                ++mMissing;
            if (!mOpt.effect.empty() && !createEffect())
                ++mMissing;

            if (mOpt.list == "anims")
                return listNames();

            createBackground();
            setupLights();
            if (mOpt.grid)
                createGrid();
            configureExtras();

            if (mOpt.hasCamera)
                setCameraFromOptions();
            else
                frameContent();
            mAutoFrameEffect = !mOpt.hasCamera && !mModel && mEffect && !mSceneLoaded;
            // CYS: the box above is taken before the first update: slot children (weapons, mount + rider on the
            // seat locator) hang on locator nodes under the model's main node but are only posed by the first
            // animation / locator update, so frame again on the union once the model has been ticked.
            mAutoFrameModel = !mOpt.hasCamera && mModel && !mSceneLoaded;
        }
        catch (const Ogre::Exception& e)
        {
            reportError("TlbbViewer: content setup failed: " + e.getFullDescription());
            ++mMissing;
        }

        if (mOpt.model.empty() && mOpt.effect.empty() && mOpt.scene.empty())
            report("TlbbViewer: nothing requested (--model / --effect / --scene); showing an empty stage");

        return mOpt.shot.empty() ? runInteractive() : runShot();
    }
    //-----------------------------------------------------------------------
    // CYS fx-render: --postfx - the CY-Source post chain configured as the game's Render.dll does it
    // (WX::CysPostFx::applyStartup / applyVariable / applyConfigFile). Applied as soon as the device exists, so the
    // shot, interactive and fx-audit sheet modes all render through it; the pipeline builds on the first frame.
    /// CYS-SHADOW: --shadow items as the game's configuration: "0|1|2|off|low|high" = quality level, "key=value" = key
    static bool cysShadowLookup(void* user, const Ogre::String& key, Ogre::String& value)
    {
        const std::vector<std::string>& items = *static_cast<const std::vector<std::string>*>(user);
        bool found = false;
        for (size_t i = 0; i < items.size(); ++i)
        {
            const std::string& item = items[i];
            const size_t eq = item.find('=');
            if (eq == std::string::npos)
            {
                if (key != WX::CYSShadowHost::kLevelKey)
                    continue;
                value = item == "off" ? "0" : item == "low" ? "1" : item == "high" ? "2" : item;
                found = true;
            }
            else if (Ogre::StringUtil::match(item.substr(0, eq), key, false))
            {
                value = item.substr(eq + 1);
                found = true;
            }
        }
        return found;
    }

    static std::string applyCysPostFx(WX::System* system, const std::vector<std::string>& items)
    {
        WX::PostFilterManager* filters = system ? system->getPostFilterManager() : NULL;
        Ogre::Viewport* vp = system ? system->getViewport() : NULL;
        if (!filters || !vp)
            return "TlbbViewer: --postfx: no post filter manager / viewport";
        if (filters->getFactoryList().empty())
            WX::registerAllPostFilterFactories(filters);
        std::string summary = "TlbbViewer: post chain";
        for (size_t i = 0; i < items.size(); ++i)
        {
            const std::string& item = items[i];
            const std::string lower = asciiLower(item);
            const size_t eq = item.find('=');
            try
            {
                if (lower == "b" || lower == "preset" || lower == "default")
                {
                    const size_t n = WX::CysPostFx::applyStartup(filters, vp, NULL, NULL);
                    summary += " | client_GL start-up set (" + Ogre::StringConverter::toString(n) + " keys)";
                }
                else if (eq != std::string::npos)
                {
                    const bool known = WX::CysPostFx::applyVariable(filters, vp, item.substr(0, eq), item.substr(eq + 1));
                    summary += " | " + item + (known ? "" : " (unknown key)");
                }
                else
                {
                    const size_t n = WX::CysPostFx::applyConfigFile(filters, vp, item);
                    summary += " | " + Ogre::StringConverter::toString(n) + " key(s) from " + item;
                }
            }
            catch (const Ogre::Exception& e)
            {
                summary += " | " + item + ": " + e.getDescription();
            }
        }
        return summary;
    }
    //-----------------------------------------------------------------------
    void ViewerApp::initEngine(void)
    {
        // Own log manager (Root reuses an existing one, OgreRoot.cpp:151-156): Root's default log mirrors every
        // line to stderr (OgreLog.cpp:62) and client_GL data produces ~300,000 EffectManager error blocks, so the
        // viewer keeps critical messages only unless --verbose.
        makeParentDirectories(mOpt.logFile);
        mLogManager = new Ogre::LogManager();
        mLogManager->createLog(mOpt.logFile, true, false, false);
        // CYS fx-audit: the census needs the LML_NORMAL parse messages ("Bad particle ... line" with file:line)
        mLogManager->setLogDetail((mOpt.verbose || !mOpt.fxCensusDir.empty()) ? Ogre::LL_NORMAL : Ogre::LL_LOW);
        if (mOpt.hasSeed)
            srand(mOpt.seed); // CYS fx-audit: Ogre::Math::UnitRandom is float(rand()) on x64 (asm_math.h)

        mSystem = new ViewerSystem(mOpt.strict);
        mSystem->setLegacyPrefilter(mOpt.legacyPrefilter); // CYS fx-audit
        // Resource locations are added below (client_GL's Bin\FairyResources.cfg uses a newer syntax than 0.85's
        // System::_setupResources understands); no plugins.cfg, no Fairy.cfg.
        mSystem->init("", "", "", mOpt.logFile);
        logLine("[TlbbViewer] data folder: " + mOpt.dataDir);
        addResourceLocations();
#ifdef CYS_WXRENDER_MATERIAL_SYSTEM
        if (!mOpt.strict)
        {
            // CYS: as WXRender CRenderSystem does before any script is parsed (scripts compile programs): pair the
            // ps_3_0-only client_GL templates with their vertex programs, runtime variants, shader microcode cache
            // in <exe dir>\ShaderCache, reset when the data root's MaterialTemplates.zip changes.
            // CYS fx-audit: --shader-cache (one cache per data set: the cache is reset when the template zip changes);
            // DataCY ships MaterialTemplates unpacked, then the stamp falls back to the exe-relative search.
            const std::string cache = mOpt.shaderCache.empty() ? exeDirectory() + "\\ShaderCache" : mOpt.shaderCache;
            const std::string zip = mOpt.dataDir + "\\MaterialTemplates.zip";
            CYS::MaterialSystem::getSingleton().install(cache,
                GetFileAttributesA(zip.c_str()) != INVALID_FILE_ATTRIBUTES ? zip : std::string());
            // --ff is the fixed-function diagnostic: keep the 0.85 behaviour so it still strips pixel-only passes.
            CYS::MaterialSystem::getSingleton().setVariantsEnabled(!mOpt.ff);
            if (!mOpt.shadow.empty()) // CYS-SHADOW: receivers are compiled with the shadow macros before models load
                CYS::MaterialSystem::getSingleton().setGlobalDefine("SHADOWMAP_TYPE",
                    WX::CYSShadowHost::shaderDefine(WX::CYSShadowHost::readConfig(cysShadowLookup, &mOpt.shadow)));
            report(std::string("TlbbViewer: material system installed, runtime variants ") +
                   (mOpt.ff ? "off (--ff)" : "on") + ", shader cache " + cache);
        }
#endif

        Ogre::Root* root = mSystem->getRoot();
        root->loadRenderPlugins_D3D9();
        root->loadInnerPlugins();

        Ogre::MaterialManager::getSingleton().setDefaultTextureFiltering(Ogre::TFO_ANISOTROPIC);
        Ogre::MaterialManager::getSingleton().setDefaultAnisotropy(mOpt.aniso);

        WX::System::NameValuePairList params;
        params["FSAA"] = Ogre::StringConverter::toString(mOpt.fsaa);
        params["vsync"] = (mOpt.vsync && mOpt.shot.empty()) ? "true" : "false";
        const DWORD start = GetTickCount();
        mSystem->setup((size_t)(UINT_PTR)mHwnd, &params); // CYS: was (WX::ulong) - 32-bit on Win64, truncated the HWND
        // CYS: --time-of-day / --time-scale (same as the CYS_TIME_OF_DAY / CYS_TIME_SCALE environment variables)
        if (mOpt.timeOfDay >= 0.0f)
            WX::CYSEnvironmentManager::getSingleton().setTimeOfDay(mOpt.timeOfDay);
        if (mOpt.timeScale >= 0.0f)
            WX::CYSEnvironmentManager::getSingleton().setTimeScale(mOpt.timeScale);
        // CYS: fx-effects particle sub-effect master switch (--no-sub-effects, or CYS_FX_SUB_EFFECTS=0)
        {
            bool subFx = !mOpt.noSubEffects;
            char envBuf[8] = {0};
            if (GetEnvironmentVariableA("CYS_FX_SUB_EFFECTS", envBuf, sizeof(envBuf)) && envBuf[0] == '0')
                subFx = false;
            WX::ParticleElement::setSubEffectsEnabled(subFx);
            if (!subFx)
                report("TlbbViewer: particle sub-effects disabled");
        }
        report("TlbbViewer: engine ready in " + sizeText(GetTickCount() - start) + " ms");

        mWindow = mSystem->getRenderWindow();
        mCamera = mSystem->getCamera();
        // renderFrame() renders and presents the window itself (so the back buffer can be captured first).
        mWindow->setAutoUpdated(false);
        if ((int)mWindow->getWidth() != mOpt.width || (int)mWindow->getHeight() != mOpt.height)
        {
            report("TlbbViewer: warning: back buffer is " + sizeText(mWindow->getWidth()) + "x" +
                   sizeText(mWindow->getHeight()));
        }

        // Same as CRenderSystem::Initial.
        Ogre::ParticleSystem::setDefaultIterationInterval(0.033f);

        WX::FrameStatsListener* stats = mSystem->getFrameStatsListener();
        if (stats)
        {
            stats->showLogoPanel(false);
            stats->showStatPanel(mOpt.stats);
            stats->showDebugOverlay(mOpt.stats);
        }

        WX::EffectManager& effects = WX::EffectManager::getSingleton();
        if (!mSystem->isStrict() && !effects.getTemplate("Effect_Error"))
        {
            // Missing effect templates otherwise throw from EffectManager::createEffect (neither 0.85 nor
            // client_GL data defines "Effect_Error").
            effects.createEffectTemplate("Effect_Error");
            logLine("[TlbbViewer] created an empty 'Effect_Error' template");
        }
        if (!mOpt.postFx.empty())
            report(applyCysPostFx(mSystem, mOpt.postFx)); // CYS fx-render: --postfx
        if (!mOpt.shadow.empty()) // CYS-SHADOW: --shadow
        {
            const WX::CYSShadowConfig cfg = WX::CYSShadowHost::readConfig(cysShadowLookup, &mOpt.shadow);
            const bool ok = WX::CYSShadowHost::start(cfg, mSystem->getSceneManager(), mCamera);
            report("TlbbViewer: shadows " + cfg.describe() + (ok ? "" : " (not started)"));
            // CYS-LUT: the quality level also drives CY's ColorLUT (level 2 = shadows + scene LUT)
            Ogre::String level;
            if (!mOpt.postFx.empty() && cysShadowLookup(&mOpt.shadow, WX::CYSShadowHost::kLevelKey, level))
                WX::CysPostFx::applyVariable(mSystem->getPostFilterManager(), mSystem->getViewport(),
                                             WX::CYSShadowHost::kLevelKey, level);
        }
        // CYS-WATER: as Render.dll CRenderSystem::Initial, before any scene is loaded
        if (!mOpt.strict && WX::CysWaterRender::install(mSystem))
            report("TlbbViewer: water: " + WX::CysWaterRender::getSingletonPtr()->describe());
    }
    //-----------------------------------------------------------------------
    void ViewerApp::addResourceLocations(void)
    {
        Ogre::ResourceGroupManager& rgm = Ogre::ResourceGroupManager::getSingleton();
        const std::string& data = mOpt.dataDir;
        size_t count = 0;

        // CYS fx-audit: OgreCore / MaterialTemplates as .zip (client_GL, game stage) or as an unpacked folder (DataCY).
        static const char* zips[] = { "OgreCore", "MaterialTemplates" };
        for (size_t i = 0; i < sizeof(zips) / sizeof(zips[0]); ++i)
        {
            const std::string path = data + "\\" + zips[i] + ".zip";
            const std::string folder = data + "\\" + zips[i];
            if (GetFileAttributesA(path.c_str()) != INVALID_FILE_ATTRIBUTES)
            {
                rgm.addResourceLocation(path, "Zip", Ogre::ResourceGroupManager::BOOTSTRAP_RESOURCE_GROUP_NAME, false);
                ++count;
            }
            else if (isDirectory(folder))
            {
                if (mOpt.wideNames) // CYS fx-audit: --wide-names
                    addWideFolderTree(folder, Ogre::ResourceGroupManager::BOOTSTRAP_RESOURCE_GROUP_NAME, count);
                else
                    addFolderTree(folder, Ogre::ResourceGroupManager::BOOTSTRAP_RESOURCE_GROUP_NAME, count);
            }
            else
            {
                reportError("TlbbViewer: missing " + path);
            }
        }

        // Folders and groups as in client_GL\Bin\FairyResources.cfg (plus the B/C-only slots when present).
        // Every sub-directory becomes its own location: 0.85's FileSystemArchive indexes recursive archives by
        // relative path only (OgreFileSystem.cpp findFiles/open), so "x.dds" in a sub-folder would not be found.
        struct Folder { const char* name; const char* group; bool optional; };
        static const Folder folders[] =
        {
            { "EffectFolder",    "General", false },
            { "ModelFolder",     "General", false },
            { "Model2Folder",    "General", false },
            { "Model3Folder",    "General", false },
            { "Model4Folder",    "General", true  },
            { "Model5Folder",    "General", true  },
            { "Model6Folder",    "General", true  },
            { "Model7Folder",    "General", true  },
            { "Model8Folder",    "General", true  },
            { "InterfaceFolder", "General", false },
            { "MaterialFolder",  "General", false },
            { "Material2Folder", "General", false },
            { "Material3Folder", "General", false },
            { "Material4Folder", "General", false },
            { "Material5Folder", "General", false },
            { "Material6Folder", "General", true  },
            { "Material7Folder", "General", true  },
            { "Material8Folder", "General", true  },
            { "SoundFolder",     "General", false },
            { "ConfigFolder",    "General", false },
            { "BrushesFolder",   "Brushes", false },
            { "SceneFolder",     "Scene",   false },
            { "Scene2Folder",    "Scene",   true  },
        };
        // CYS fx-audit: the CY / 0.85 layout, used by the game stage Data folder (Bin64\WXResources.cfg: Effect, Model,
        // Interface, Material, Sound, Config -> General; Brushes; Scene) and by DataCY (+ Model2..8, Material2..8).
        static const Folder cyFolders[] =
        {
            { "Effect",    "General", false },
            { "Model",     "General", false },
            { "Model2",    "General", true  },
            { "Model3",    "General", true  },
            { "Model4",    "General", true  },
            { "Model5",    "General", true  },
            { "Model6",    "General", true  },
            { "Model7",    "General", true  },
            { "Model8",    "General", true  },
            { "Interface", "General", true  },
            { "Material",  "General", false },
            { "Material2", "General", true  },
            { "Material3", "General", true  },
            { "Material4", "General", true  },
            { "Material5", "General", true  },
            { "Material6", "General", true  },
            { "Material7", "General", true  },
            { "Material8", "General", true  },
            { "Sound",     "General", true  },
            { "Config",    "General", true  },
            { "Brushes",   "Brushes", true  },
            { "Scene",     "Scene",   true  },
            { "Scene2",    "Scene",   true  },
        };
        const bool cyLayout = !isDirectory(data + "\\EffectFolder") && isDirectory(data + "\\Effect");
        const Folder* list = cyLayout ? cyFolders : folders;
        const size_t listSize = cyLayout ? sizeof(cyFolders) / sizeof(cyFolders[0])
                                         : sizeof(folders) / sizeof(folders[0]);
        if (cyLayout)
            report("TlbbViewer: CY / 0.85 data layout (Effect, Model, Material, ...)");
        for (size_t i = 0; i < listSize; ++i)
        {
            const std::string dir = data + "\\" + list[i].name;
            DWORD attributes = GetFileAttributesA(dir.c_str());
            if (attributes == INVALID_FILE_ATTRIBUTES || !(attributes & FILE_ATTRIBUTE_DIRECTORY))
            {
                if (!list[i].optional)
                    reportError(std::string("TlbbViewer: missing folder ") + dir);
                continue;
            }
            if (mOpt.wideNames) // CYS fx-audit: --wide-names (CJK file names reachable, as on a CP936 system)
                addWideFolderTree(dir, list[i].group, count);
            else
                addFolderTree(dir, list[i].group, count);
        }
        if (mOpt.wideNames)
            report("TlbbViewer: --wide-names: folders read with FindFirstFileW/CreateFileW (not the game's ANSI layer)");
        report("TlbbViewer: " + sizeText(count) + " resource locations under " + data);

        // CYS: --res <dir> (repeatable): extra folder trees in "General", after the data folders and before the
        // groups are initialised, so their *.obj / *.material / ... scripts are parsed with the rest (first
        // definition of a name wins). A folder inside --data would be indexed twice and is skipped.
        for (size_t r = 0; r < mOpt.resDirs.size(); ++r)
        {
            std::string dir = mOpt.resDirs[r];
            while (dir.size() > 3 && (dir[dir.size() - 1] == '\\' || dir[dir.size() - 1] == '/'))
                dir.erase(dir.size() - 1);
            const std::string dirLower = asciiLower(dir), dataLower = asciiLower(data);
            if (dirLower == dataLower || (dirLower.size() > dataLower.size() &&
                dirLower.compare(0, dataLower.size(), dataLower) == 0 && dirLower[dataLower.size()] == '\\'))
            {
                reportError("TlbbViewer: --res " + dir + " is inside --data; ignored");
                continue;
            }
            const DWORD attributes = GetFileAttributesA(dir.c_str());
            if (attributes == INVALID_FILE_ATTRIBUTES || !(attributes & FILE_ATTRIBUTE_DIRECTORY))
            {
                reportError("TlbbViewer: --res folder not found: " + dir);
                continue;
            }
            size_t extra = 0;
            addFolderTree(dir, "General", extra);
            report("TlbbViewer: " + sizeText(extra) + " extra resource locations under " + dir);
        }
    }
    //-----------------------------------------------------------------------
    void ViewerApp::addFolderTree(const std::string& dir, const std::string& group, size_t& count)
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
            if ((fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) &&
                strcmp(fd.cFileName, ".") != 0 && strcmp(fd.cFileName, "..") != 0)
            {
                subdirs.push_back(fd.cFileName);
            }
        } while (FindNextFileA(h, &fd));
        FindClose(h);

        std::sort(subdirs.begin(), subdirs.end());
        for (size_t i = 0; i < subdirs.size(); ++i)
            addFolderTree(dir + "\\" + subdirs[i], group, count);
    }
    //-----------------------------------------------------------------------
    void ViewerApp::logResourceSummary(void)
    {
        size_t materials = 0;
        {
            Ogre::ResourceManager::ResourceMapIterator it = Ogre::MaterialManager::getSingleton().getResourceIterator();
            while (it.hasMoreElements())
            {
                it.moveNext();
                ++materials;
            }
        }
        size_t particles = 0;
        {
            Ogre::ParticleSystemManager::ParticleSystemTemplateIterator it =
                Ogre::ParticleSystemManager::getSingleton().getTemplateIterator();
            while (it.hasMoreElements())
            {
                it.moveNext();
                ++particles;
            }
        }
        size_t skills = 0;
        {
            WX::EffectManager::SkillIterator it = WX::EffectManager::getSingleton().getSkillIterator();
            while (it.hasMoreElements())
            {
                it.moveNext();
                ++skills;
            }
        }
        size_t models = 0;
        {
            WX::LogicModelManager::LogicModelTemplateIterator it =
                WX::LogicModelManager::getSingleton().getLogicModelTemplateIterator();
            while (it.hasMoreElements())
            {
                it.moveNext();
                ++models;
            }
        }
        const size_t effects = WX::EffectManager::getSingleton().getNumEffectTemplates();

        report("TlbbViewer: scripts " + sizeText(mSystem->scriptFiles()) + " files, " +
               sizeText(mSystem->scriptErrors()) + " aborted by an exception; " +
               sizeText(materials) + " materials, " + sizeText(particles) + " particle systems, " +
               sizeText(effects) + " effects (" + sizeText(mSystem->effectElementsDropped()) +
               " elements dropped), " + sizeText(skills) + " skills, " + sizeText(models) + " logic models");
    }
    //-----------------------------------------------------------------------
    bool ViewerApp::loadScene(void)
    {
        std::string path = mOpt.scene;
        for (size_t i = 0; i < path.size(); ++i)
        {
            if (path[i] == '/')
                path[i] = '\\';
        }
        std::string dir, file = path;
        size_t slash = path.rfind('\\');
        if (slash != std::string::npos)
        {
            dir = path.substr(0, slash);
            file = path.substr(slash + 1);
        }

        mSceneGroup = "Scene";
        if (!dir.empty() && fullPath(dir) != fullPath(mOpt.dataDir + "\\SceneFolder") &&
            fullPath(dir) != fullPath(mOpt.dataDir + "\\Scene")) // CYS fx-audit: CY / 0.85 layout
        {
            mSceneGroup = std::string(VIEWER_GROUP) + "Scene";
            Ogre::ResourceGroupManager::getSingleton().addResourceLocation(dir, "FileSystem", mSceneGroup, false);
            mSystem->initialiseGroup(mSceneGroup);
        }

        const DWORD start = GetTickCount();
        try
        {
            // Build every object now (the game builds them incrementally, one per frame).
            // CYS-PARTICLE: CYS_SCENE_INCREMENTAL=1 keeps the IncrementalSceneBuilder instead, i.e. the exact
            // path Game.exe runs (nearest object to the camera first, 64 on the first frame then 30 per second
            // of frame time). Default OFF - without the variable the viewer behaves exactly as before. This is
            // what lets a missing particle template be reproduced and the fix be proven OFFLINE, with no
            // Game.exe slot, no server and no login. Drive it with a large --dt so the queue drains, e.g.
            //   set CYS_SCENE_INCREMENTAL=1 && TlbbViewer --scene longta_0.Scene --dt 2 --frames 60 --shot x.png
            const char* cysIncremental = getenv("CYS_SCENE_INCREMENTAL");
            const bool cysUseIncremental = cysIncremental && strcmp(cysIncremental, "0") != 0;
            mSystem->setDisableIncrementalBuildScene(!cysUseIncremental);
            if (cysUseIncremental)
                report("TlbbViewer: CYS-PARTICLE: incremental scene build (as Game.exe), not the immediate path");
            if (mSystem->isStrict())
            {
                WX::ExpatParser parser(NULL);
                mSystem->loadSceneFromResource(&parser, file, mSceneGroup);
            }
            else
            {
                LenientXMLParser parser;
                mSystem->loadSceneFromResource(&parser, file, mSceneGroup);
            }
            // As CRenderSystem::Scene_Load + View_LightmapQuality=2 in client_GL's System.cfg.
            WX::Terrain* terrain = mSystem->getTerrain();
            terrain->setLightmapQuality(WX::Terrain::LMQ_HIGH);
            terrain->buildGeometry(mSystem->getBaseSceneNode());
        }
        catch (const Ogre::Exception& e)
        {
            reportError("TlbbViewer: scene load failed: " + e.getFullDescription());
            return false;
        }

        mSceneLoaded = true;
        // CYS-FIX fix-projector: scene Projector objects (CY decals) that really got an OGRE projector.
        {
            size_t cysProjectorObjects = 0;
            WX::Scene::ObjectsByTypeRange cysRange = mSystem->getSceneInfo()->findObjectsByType(WX::CYSProjectorObject::msType);
            for (WX::Scene::ObjectsByTypeIterator it = cysRange.first; it != cysRange.second; ++it)
                ++cysProjectorObjects;
            report("TlbbViewer: projectors: objects=" + Ogre::StringConverter::toString(cysProjectorObjects) +
                   " live=" + Ogre::StringConverter::toString(WX::CYSProjectorObject::getNumLiveProjectors()));
        }
        // CYS-LUT: as CRenderSystem::Scene_Load - the scene's ColorLUT of CY 3.71 (with --postfx and View_HumanLightmap 2)
        if (!mOpt.postFx.empty() && mSystem->getPostFilterManager() && mSystem->getViewport())
        {
            WX::CysPostFx::onSceneLoaded(mSystem->getPostFilterManager(), mSystem->getViewport(), 0, file);
            report("TlbbViewer: ColorLUT " + WX::CysPostFx::describeColorLut());
        }
        size_t failed = 0;
        const WX::System::ExceptionInfoMap& problems = mSystem->getExceptionInfoMap();
        for (WX::System::ExceptionInfoMap::const_iterator it = problems.begin(); it != problems.end(); ++it)
        {
            failed += it->second.size();
            logLine("[TlbbViewer] scene object failure (" + sizeText(it->second.size()) + "x, e.g. " +
                    (it->second.empty() ? std::string("?") : it->second.front().objectName) + "): " + it->first);
        }
        WX::TerrainData* td = mSystem->getTerrainData();
        report("TlbbViewer: scene " + file + " loaded in " + sizeText(GetTickCount() - start) + " ms: " +
               sizeText(mSystem->getSceneInfo()->getObjects().size()) + " objects, " + sizeText(failed) +
               " failed to build, terrain " + sizeText(td ? td->getXSize() : 0) + "x" +
               sizeText(td ? td->getZSize() : 0));
        return true;
    }
    //-----------------------------------------------------------------------
    bool ViewerApp::createModel(void)
    {
        WX::LogicModelManager& manager = WX::LogicModelManager::getSingleton();
        std::string name = mOpt.model;
        if (!manager.getTemplateByName(name))
        {
            if (!endsWithNoCase(name, ".obj") && manager.getTemplateByName(name + ".obj"))
            {
                name += ".obj";
            }
            else
            {
                reportError("TlbbViewer: model not found in all.obj: " + mOpt.model);
                std::string query = asciiLower(name);
                if (endsWithNoCase(query, ".obj"))
                    query.erase(query.size() - 4);
                size_t shown = 0;
                WX::LogicModelManager::LogicModelTemplateIterator it = manager.getLogicModelTemplateIterator();
                while (it.hasMoreElements() && shown < 10)
                {
                    const std::string key = it.peekNextKey();
                    it.moveNext();
                    if (!query.empty() && key.find(query) != std::string::npos)
                    {
                        err("  similar: " + key);
                        ++shown;
                    }
                }
                return false;
            }
        }

        try
        {
            mModel = manager.createLogicModel(std::string(VIEWER_GROUP) + "/Model", name);
        }
        catch (const Ogre::Exception& e)
        {
            reportError("TlbbViewer: model creation failed: " + e.getFullDescription());
            mModel = NULL;
            return false;
        }

        mModel->setParentSceneNode(mSystem->getBaseSceneNode());
        Ogre::Vector3 position = mContentOrigin;
        if (mOpt.hasModelAt) // CYS-PARITY (d3d9-trace): same spot as an NPC of a CY trace
        {
            position = terrainPoint(mOpt.modelAt[0], mOpt.modelAt[1]);
            Ogre::Quaternion q(Ogre::Degree(mOpt.modelAt[2]), Ogre::Vector3::UNIT_Y);
            mModel->setOrientation(q);
        }
        mModel->setPosition(position);
        // CYS: fx-effects --scale
        if (mOpt.modelScale != 1.0f)
            mModel->setScaleFactor(Ogre::Vector3(mOpt.modelScale, mOpt.modelScale, mOpt.modelScale));
        mModel->setEffectFollowScale(mOpt.effectFollowScale);

        if (!mOpt.anim.empty())
        {
            // A skill from all.skill when one exists with this name, else a skeleton animation.
            mModel->createSkill(mOpt.anim, true, false);
            if (mModel->getCurrentAnimName().empty())
            {
                reportError("TlbbViewer: animation/skill not found for this model: " + mOpt.anim +
                            " (see --list anims)");
                return false;
            }
        }
        report("TlbbViewer: model " + name + (mModel->getCurrentAnimName().empty() ? std::string() :
               ", animation " + mModel->getCurrentAnimName()));
        return true;
    }
    //-----------------------------------------------------------------------
    bool ViewerApp::createEffect(void)
    {
        WX::EffectManager& effects = WX::EffectManager::getSingleton();
        if (!effects.getTemplate(mOpt.effect))
        {
            reportError("TlbbViewer: effect not found in all.effect: " + mOpt.effect);
            const std::string query = asciiLower(mOpt.effect);
            size_t shown = 0;
            WX::EffectManager::EffectTemplateIterator it = effects.getEffectTemplateIterator();
            while (it.hasMoreElements() && shown < 10)
            {
                const std::string key = it.peekNextKey();
                it.moveNext();
                if (!query.empty() && asciiLower(key).find(query) != std::string::npos)
                {
                    err("  similar: " + key);
                    ++shown;
                }
            }
            return false;
        }

        if (mModel && !mOpt.locator.empty())
        {
            if (!mModel->isLocatorExist(mOpt.locator))
            {
                reportError("TlbbViewer: locator not found on the model: " + mOpt.locator);
                return false;
            }
            mModelEffect = mModel->addEffect(mOpt.effect, mOpt.locator, WX::LogicModel::GTIT_ALL);
            report("TlbbViewer: effect " + mOpt.effect + " on locator " + mOpt.locator);
            return mModel->getEffect(mModelEffect) != NULL;
        }

        if (!mEffectNode)
        {
            mEffectNode = mSystem->getBaseSceneNode()->createChildSceneNode();
            mEffectNode->setPosition(mContentOrigin);
        }
        mEffect = effects.createEffect(mOpt.effect);
        WX::TransformInfos infos;
        infos.push_back(WX::TransformInfo(Ogre::Vector3::ZERO));
        mEffect->setExtraTransformInfos(infos);
        mEffect->createSceneNode(mEffectNode);
        report("TlbbViewer: effect " + mOpt.effect);
        return true;
    }
    //-----------------------------------------------------------------------
    void ViewerApp::destroyEffect(void)
    {
        if (mEffect && WX::EffectManager::getSingletonPtr())
            WX::EffectManager::getSingleton().destroyEffect(mEffect);
        mEffect = NULL;
    }
    //-----------------------------------------------------------------------
    void ViewerApp::restartFinishedEffect(void)
    {
        // Effects with a finite life time are restarted so the viewer keeps showing them.
        if (mEffect && !mEffect->isAlive())
        {
            destroyEffect();
            WX::EffectManager& effects = WX::EffectManager::getSingleton();
            mEffect = effects.createEffect(mOpt.effect);
            WX::TransformInfos infos;
            infos.push_back(WX::TransformInfo(Ogre::Vector3::ZERO));
            mEffect->setExtraTransformInfos(infos);
            mEffect->createSceneNode(mEffectNode);
        }
    }
    //-----------------------------------------------------------------------
    void ViewerApp::createBackground(void)
    {
        Ogre::Viewport* viewport = mSystem->getViewport();
        Ogre::SceneManager* sm = mSystem->getSceneManager();
        if (mOpt.hasBg)
        {
            viewport->setBackgroundColour(Ogre::ColourValue(mOpt.bg[0], mOpt.bg[1], mOpt.bg[2]));
            return;
        }
        if (mSceneLoaded)
        {
            // Most client_GL scenes use SkySphere/EnScene skies that 0.85 cannot draw: fall back to the fog colour.
            if (sm->getFogMode() != Ogre::FOG_NONE)
                viewport->setBackgroundColour(sm->getFogColour());
            return;
        }

        // Studio backdrop: vertical gradient on a full-screen quad behind everything.
        viewport->setBackgroundColour(Ogre::ColourValue(0.09f, 0.10f, 0.12f));
        const int height = 256;
        std::vector<unsigned char> pixels(2 * height * 4);
        for (int y = 0; y < height; ++y)
        {
            const float t = y / float(height - 1);                 // 0 = top, 1 = bottom
            const float s = t * t * (3.0f - 2.0f * t);
            const float r = 0.33f + (0.07f - 0.33f) * s;
            const float g = 0.37f + (0.075f - 0.37f) * s;
            const float b = 0.45f + (0.095f - 0.45f) * s;
            for (int x = 0; x < 2; ++x)
            {
                unsigned char* p = &pixels[(y * 2 + x) * 4];
                p[0] = (unsigned char)(b * 255.0f + 0.5f);          // PF_A8R8G8B8 in memory: B G R A
                p[1] = (unsigned char)(g * 255.0f + 0.5f);
                p[2] = (unsigned char)(r * 255.0f + 0.5f);
                p[3] = 255;
            }
        }
        Ogre::Image image;
        image.loadDynamicImage(&pixels[0], 2, height, Ogre::PF_A8R8G8B8);
        const std::string textureName = std::string(VIEWER_GROUP) + "/BackgroundGradient";
        Ogre::TextureManager::getSingleton().loadImage(textureName, VIEWER_GROUP, image, Ogre::TEX_TYPE_2D, 0);

        const std::string materialName = std::string(VIEWER_GROUP) + "/Background";
        Ogre::MaterialPtr material(Ogre::MaterialManager::getSingleton().create(materialName, VIEWER_GROUP));
        if (material->getNumTechniques() == 0)
            material->createTechnique()->createPass();
        Ogre::Pass* pass = material->getTechnique(0)->getPass(0);
        pass->setLightingEnabled(false);
        pass->setDepthCheckEnabled(false);
        pass->setDepthWriteEnabled(false);
        pass->setFog(true, Ogre::FOG_NONE);
        pass->setCullingMode(Ogre::CULL_NONE);
        Ogre::TextureUnitState* unit = pass->createTextureUnitState(textureName);
        unit->setTextureAddressingMode(Ogre::TextureUnitState::TAM_CLAMP);
        unit->setTextureFiltering(Ogre::TFO_BILINEAR);

        mBackground = new Ogre::Rectangle2D(true);
        mBackground->setCorners(-1.0f, 1.0f, 1.0f, -1.0f);
        mBackground->setMaterial(materialName);
        mBackground->setRenderQueueGroup(Ogre::RENDER_QUEUE_BACKGROUND);
        mBackground->setBoundingBox(Ogre::AxisAlignedBox(-1e7f, -1e7f, -1e7f, 1e7f, 1e7f, 1e7f));
        mBackgroundNode = sm->getRootSceneNode()->createChildSceneNode();
        mBackgroundNode->attachObject(mBackground);
    }
    //-----------------------------------------------------------------------
    void ViewerApp::createGrid(void)
    {
        if (mGrid)
        {
            mGridNode->setVisible(true);
            return;
        }
        const std::string materialName = std::string(VIEWER_GROUP) + "/Grid";
        Ogre::MaterialPtr material(Ogre::MaterialManager::getSingleton().create(materialName, VIEWER_GROUP));
        if (material->getNumTechniques() == 0)
            material->createTechnique()->createPass();
        Ogre::Pass* pass = material->getTechnique(0)->getPass(0);
        pass->setLightingEnabled(false);
        pass->setSceneBlending(Ogre::SBT_TRANSPARENT_ALPHA);
        pass->setDepthWriteEnabled(false);
        pass->setFog(true, Ogre::FOG_NONE);

        Ogre::SceneManager* sm = mSystem->getSceneManager();
        mGrid = sm->createManualObject(std::string(VIEWER_GROUP) + "/GridObject");
        const int half = 20;
        const float step = 50.0f;
        const float extent = half * step;
        mGrid->begin(materialName, Ogre::RenderOperation::OT_LINE_LIST);
        for (int i = -half; i <= half; ++i)
        {
            const Ogre::ColourValue colour = (i == 0) ? Ogre::ColourValue(0.60f, 0.66f, 0.78f, 0.9f)
                : ((i % 5) == 0 ? Ogre::ColourValue(0.50f, 0.52f, 0.56f, 0.55f)
                                : Ogre::ColourValue(0.45f, 0.47f, 0.50f, 0.25f));
            const float o = i * step;
            mGrid->position(o, 0.0f, -extent); mGrid->colour(colour);
            mGrid->position(o, 0.0f,  extent); mGrid->colour(colour);
            mGrid->position(-extent, 0.0f, o); mGrid->colour(colour);
            mGrid->position( extent, 0.0f, o); mGrid->colour(colour);
        }
        mGrid->end();
        mGridNode = mSystem->getBaseSceneNode()->createChildSceneNode();
        mGridNode->setPosition(mContentOrigin);
        mGridNode->attachObject(mGrid);
    }
    //-----------------------------------------------------------------------
    void ViewerApp::setupLights(void)
    {
        std::string preset = mOpt.lights;
        if (preset.empty())
            preset = mSceneLoaded ? "scene" : "studio";

        Ogre::SceneManager* sm = mSystem->getSceneManager();
        if (preset == "scene")
        {
            report("TlbbViewer: lighting from the scene");
            return;
        }
        if (preset == "flat")
        {
            sm->setAmbientLight(Ogre::ColourValue(1.0f, 1.0f, 1.0f));
        }
        else if (preset == "fake")
        {
            // Like the game's model preview (RFFakeObjectManager.cpp): full ambient + a point light at the camera.
            sm->setAmbientLight(Ogre::ColourValue(1.0f, 1.0f, 1.0f));
            mCameraLight = sm->createLight(std::string(VIEWER_GROUP) + "/CameraLight");
            mLights.push_back(mCameraLight);
        }
        else
        {
            // Studio: soft ambient, warm key from the front-left-top, cool fill from the back-right.
            sm->setAmbientLight(Ogre::ColourValue(0.46f, 0.46f, 0.50f));
            Ogre::Light* key = sm->createLight(std::string(VIEWER_GROUP) + "/KeyLight");
            key->setType(Ogre::Light::LT_DIRECTIONAL);
            key->setDirection(Ogre::Vector3(0.45f, -0.75f, -0.50f).normalisedCopy());
            key->setDiffuseColour(1.0f, 0.95f, 0.88f);
            key->setSpecularColour(0.45f, 0.45f, 0.45f);
            mLights.push_back(key);

            Ogre::Light* fill = sm->createLight(std::string(VIEWER_GROUP) + "/FillLight");
            fill->setType(Ogre::Light::LT_DIRECTIONAL);
            fill->setDirection(Ogre::Vector3(-0.60f, -0.25f, 0.75f).normalisedCopy());
            fill->setDiffuseColour(0.30f, 0.34f, 0.42f);
            fill->setSpecularColour(0.0f, 0.0f, 0.0f);
            mLights.push_back(fill);
        }
        report("TlbbViewer: lighting preset " + preset);
    }
    //-----------------------------------------------------------------------
    void ViewerApp::configureExtras(void)
    {
        if (!mOpt.skybox.empty())
        {
            try
            {
                mSystem->getSceneManager()->setSkyBox(true, mOpt.skybox, 50000.0f);
            }
            catch (const Ogre::Exception& e)
            {
                reportError("TlbbViewer: sky box failed: " + e.getFullDescription());
            }
        }
        if (!mOpt.postFilter.empty())
        {
            try
            {
                WX::PostFilterManager* filters = mSystem->getPostFilterManager();
                if (filters->getFactoryList().empty()) // CYS fx-render: --postfx may have registered them already
                    WX::registerAllPostFilterFactories(filters);
                filters->createPostFilter(mOpt.postFilter, mSystem->getViewport());
                filters->setPostFilterEnabled(mOpt.postFilter, true);
                report("TlbbViewer: post filter " + mOpt.postFilter);
            }
            catch (const Ogre::Exception& e)
            {
                reportError("TlbbViewer: post filter failed: " + e.getFullDescription());
            }
        }
    }
    //-----------------------------------------------------------------------
    int ViewerApp::listNames(void)
    {
        const std::string filter = asciiLower(mOpt.listFilter);
        size_t count = 0;
        #define TLBBV_EMIT(name)                                                        \
            {                                                                           \
                const std::string _n = (name);                                          \
                if (filter.empty() || asciiLower(_n).find(filter) != std::string::npos) \
                {                                                                       \
                    out(_n);                                                            \
                    ++count;                                                            \
                }                                                                       \
            }

        if (mOpt.list == "models")
        {
            WX::LogicModelManager::LogicModelTemplateIterator it =
                WX::LogicModelManager::getSingleton().getLogicModelTemplateIterator();
            while (it.hasMoreElements())
            {
                WX::LogicModel* model = it.peekNextValue();
                const std::string key = it.peekNextKey();
                it.moveNext();
                TLBBV_EMIT(model ? model->getName() : key);
            }
        }
        else if (mOpt.list == "effects")
        {
            WX::EffectManager::EffectTemplateIterator it = WX::EffectManager::getSingleton().getEffectTemplateIterator();
            while (it.hasMoreElements())
            {
                const std::string key = it.peekNextKey();
                it.moveNext();
                TLBBV_EMIT(key);
            }
        }
        else if (mOpt.list == "skills")
        {
            WX::EffectManager::SkillIterator it = WX::EffectManager::getSingleton().getSkillIterator();
            while (it.hasMoreElements())
            {
                const std::string key = it.peekNextKey();
                it.moveNext();
                TLBBV_EMIT(key);
            }
        }
        else if (mOpt.list == "materials")
        {
            Ogre::ResourceManager::ResourceMapIterator it = Ogre::MaterialManager::getSingleton().getResourceIterator();
            while (it.hasMoreElements())
            {
                Ogre::ResourcePtr material = it.getNext();
                TLBBV_EMIT(material->getName());
            }
        }
        else if (mOpt.list == "anims")
        {
            if (!mModel)
                return EXIT_NOT_FOUND;
            std::set<std::string> names;
            for (unsigned short i = 0; i < mModel->getSkeletonAnimationCount(); ++i)
            {
                Ogre::Animation* animation = mModel->getSkeletonAnimation(i);
                if (animation)
                    names.insert(animation->getName());
            }
            WX::LogicModelManager::AnimationSkeletonLinksIterator it =
                WX::LogicModelManager::getSingleton().getAnimationSkeletonLinksIterator(mModel->getName());
            while (it.hasMoreElements())
            {
                names.insert(it.peekNextKey());
                it.moveNext();
            }
            for (std::set<std::string>::const_iterator n = names.begin(); n != names.end(); ++n)
                TLBBV_EMIT(*n);
        }
        #undef TLBBV_EMIT

        err("TlbbViewer: " + sizeText(count) + " " + mOpt.list + " listed");
        return (count || mOpt.listFilter.empty()) ? EXIT_OK : EXIT_NOT_FOUND;
    }
    //-----------------------------------------------------------------------
    namespace
    {
        std::string describeMaterial(const Ogre::MaterialPtr& material)
        {
            if (material.isNull())
                return "(null material)";
            std::ostringstream s;
            s << material->getName() << " [" << material->getNumTechniques() << " tech, "
              << material->getNumSupportedTechniques() << " supported";
            Ogre::Technique* best = material->getBestTechnique();
            if (best)
            {
                s << "; best: " << best->getNumPasses() << " pass";
                for (unsigned short p = 0; p < best->getNumPasses(); ++p)
                {
                    Ogre::Pass* pass = best->getPass(p);
                    s << " {" << pass->getNumTextureUnitStates() << " tex";
                    if (pass->hasVertexProgram())
                    {
                        Ogre::GpuProgramPtr vp = pass->getVertexProgram();
                        s << ", vp " << pass->getVertexProgramName() << (vp->isSupported() ? "" : " UNSUPPORTED")
                          << (vp->hasCompileError() ? " COMPILE-ERROR" : "");
                    }
                    if (pass->hasFragmentProgram())
                    {
                        Ogre::GpuProgramPtr fp = pass->getFragmentProgram();
                        s << ", fp " << pass->getFragmentProgramName() << (fp->isSupported() ? "" : " UNSUPPORTED")
                          << (fp->hasCompileError() ? " COMPILE-ERROR" : "");
                    }
                    s << (pass->getLightingEnabled() ? ", lit" : ", unlit") << "}";
                }
            }
            else
            {
                // First technique's programs, to show why it is unsupported.
                for (unsigned short t = 0; t < material->getNumTechniques() && t < 1; ++t)
                {
                    Ogre::Technique* technique = material->getTechnique(t);
                    for (unsigned short p = 0; p < technique->getNumPasses(); ++p)
                    {
                        Ogre::Pass* pass = technique->getPass(p);
                        if (pass->hasVertexProgram())
                            s << "; vp " << pass->getVertexProgramName()
                              << (pass->getVertexProgram()->hasCompileError() ? " COMPILE-ERROR" : "")
                              << (pass->getVertexProgram()->isSupported() ? "" : " UNSUPPORTED");
                        if (pass->hasFragmentProgram())
                            s << "; fp " << pass->getFragmentProgramName()
                              << (pass->getFragmentProgram()->hasCompileError() ? " COMPILE-ERROR" : "")
                              << (pass->getFragmentProgram()->isSupported() ? "" : " UNSUPPORTED");
                    }
                }
            }
            s << "]";
            return s.str();
        }

        void dumpNode(Ogre::SceneNode* node, int depth, size_t& lines)
        {
            if (lines > 400)
                return;
            const std::string indent(depth * 2, ' ');
            Ogre::SceneNode::ObjectIterator objects = node->getAttachedObjectIterator();
            while (objects.hasMoreElements())
            {
                Ogre::MovableObject* object = objects.getNext();
                std::ostringstream s;
                const Ogre::AxisAlignedBox& b = object->getWorldBoundingBox(true);
                s << indent << object->getMovableType() << " '" << object->getName() << "' visible="
                  << object->isVisible() << " flags=0x" << std::hex << object->getVisibilityFlags() << std::dec
                  << " queue=" << (int)object->getRenderQueueGroup();
                if (!b.isNull())
                    s << " box=(" << b.getMinimum().x << "," << b.getMinimum().y << "," << b.getMinimum().z << ")-("
                      << b.getMaximum().x << "," << b.getMaximum().y << "," << b.getMaximum().z << ")";
                if (object->getMovableType() == "Entity")
                {
                    Ogre::Entity* entity = static_cast<Ogre::Entity*>(object);
                    s << " mesh=" << entity->getMesh()->getName() << " subs=" << entity->getNumSubEntities();
                    report(s.str());
                    ++lines;
                    for (unsigned int i = 0; i < entity->getNumSubEntities() && lines < 400; ++i, ++lines)
                        report(indent + "  sub " + sizeText(i) + ": " + describeMaterial(entity->getSubEntity(i)->getMaterial()));
                    continue;
                }
                if (object->getMovableType() == "ParticleSystem")
                {
                    Ogre::ParticleSystem* ps = static_cast<Ogre::ParticleSystem*>(object);
                    s << " particles=" << ps->getNumParticles() << "/" << ps->getParticleQuota()
                      << " emitters=" << ps->getNumEmitters() << " affectors=" << ps->getNumAffectors()
                      << " renderer=" << ps->getRendererName() << " size=" << ps->getDefaultWidth() << "x"
                      << ps->getDefaultHeight();
                    report(s.str());
                    ++lines;
                    report(indent + "  material: " + describeMaterial(
                        Ogre::MaterialManager::getSingleton().getByName(ps->getMaterialName())));
                    ++lines;
                    continue;
                }
                report(s.str());
                ++lines;
            }
            Ogre::Node::ChildNodeIterator children = node->getChildIterator();
            while (children.hasMoreElements())
                dumpNode(static_cast<Ogre::SceneNode*>(children.getNext()), depth + 1, lines);
        }
    }
    //-----------------------------------------------------------------------
    void ViewerApp::dumpContent(void)
    {
        size_t lines = 0;
        if (mModel && mModel->getSceneNode())
        {
            report("TlbbViewer: dump of model " + mModel->getName());
            dumpNode(mModel->getSceneNode(), 1, lines);
        }
        if (mEffectNode)
        {
            report("TlbbViewer: dump of effect " + mOpt.effect + (mEffect ? (mEffect->isAlive() ? " (alive)" : " (dead)") : ""));
            dumpNode(mEffectNode, 1, lines);
        }
    }
    //-----------------------------------------------------------------------
    Ogre::Vector3 ViewerApp::terrainPoint(float x, float z) const
    {
        WX::TerrainData* td = mSystem->getTerrainData();
        if (!td || td->isEmpty())
            return Ogre::Vector3(x, 0.0f, z);
        return Ogre::Vector3(x, td->getHeightAt(x, z), z);
    }
    //-----------------------------------------------------------------------
    Ogre::Vector3 ViewerApp::sceneDefaultTarget(void) const
    {
        WX::TerrainData* td = mSystem->getTerrainData();
        if (!td || td->isEmpty())
            return Ogre::Vector3::ZERO;
        const float x = td->mPosition.x + td->getXSize() * td->mScale.x * 0.5f;
        const float z = td->mPosition.z + td->getZSize() * td->mScale.z * 0.5f;
        return terrainPoint(x, z);
    }
    //-----------------------------------------------------------------------
    void ViewerApp::frameContent(void)
    {
        mYaw = Ogre::Degree(mOpt.orbitYaw).valueRadians();
        mPitch = Ogre::Degree(mOpt.orbitPitch).valueRadians();
        mFov = mOpt.fov;

        Ogre::SceneManager* sm = mSystem->getSceneManager();
        sm->getRootSceneNode()->_update(true, false);

        Ogre::AxisAlignedBox box;
        box.setNull();
        if (mModel && mModel->getSceneNode())
            mergeBounds(mModel->getSceneNode(), box, true);
        if (box.isNull() && mEffectNode)
            mergeBounds(mEffectNode, box, false);

        if (!box.isNull())
        {
            const float radius = std::max(box.getHalfSize().length(), 5.0f);
            mTarget = box.getCenter();
            mDist = radius / std::sin(Ogre::Degree(mFov * 0.5f).valueRadians()) * 1.05f;
        }
        else if (mSceneLoaded)
        {
            // Roughly the game's scene camera: 27.5 m away (Camera_MaxDistance), 40 degrees pitch.
            mTarget = mContentOrigin;
            mDist = 2750.0f;
            mPitch = Ogre::Degree(40.0f).valueRadians();
        }
        else
        {
            mTarget = mContentOrigin + Ogre::Vector3(0.0f, 100.0f, 0.0f);
            mDist = 600.0f;
        }
        applyCamera();
    }
    //-----------------------------------------------------------------------
    void ViewerApp::setCameraFromOptions(void)
    {
        const Ogre::Vector3 eye(mOpt.camera[0], mOpt.camera[1], mOpt.camera[2]);
        const Ogre::Vector3 target(mOpt.camera[3], mOpt.camera[4], mOpt.camera[5]);
        Ogre::Vector3 offset = eye - target;
        mDist = offset.length();
        if (mDist < 1e-3f)
        {
            mDist = 1.0f;
            offset = Ogre::Vector3(0.0f, 0.0f, 1.0f);
        }
        mTarget = target;
        mPitch = std::asin(std::max(-1.0f, std::min(1.0f, offset.y / mDist)));
        mYaw = std::atan2(offset.x, offset.z);
        mFov = mOpt.camera[6];
        applyCamera();
    }
    //-----------------------------------------------------------------------
    void ViewerApp::applyCamera(void)
    {
        const float limit = 1.55f;
        mPitch = std::max(-limit, std::min(limit, mPitch));
        mDist = std::max(1.0f, std::min(1e6f, mDist));
        const float cp = std::cos(mPitch), sp = std::sin(mPitch);
        const float cy = std::cos(mYaw), sy = std::sin(mYaw);
        const Ogre::Vector3 eye = mTarget + Ogre::Vector3(cp * sy, sp, cp * cy) * mDist;
        mCamera->setPosition(eye);
        mCamera->lookAt(mTarget);
        mCamera->setFOVy(Ogre::Degree(mFov));
        const float nearClip = std::max(1.0f, std::min(50.0f, mDist * 0.01f));
        const float farClip = std::max(mDist * 50.0f, mSceneLoaded ? 30000.0f : 20000.0f);
        mCamera->setNearClipDistance(nearClip);
        mCamera->setFarClipDistance(farClip);
    }
    //-----------------------------------------------------------------------
    void ViewerApp::updateKeyboard(float dt)
    {
        if (GetForegroundWindow() != mHwnd)
            return;
        struct Key { static bool down(int vk) { return (GetAsyncKeyState(vk) & 0x8000) != 0; } };

        Ogre::Vector3 forward = mCamera->getDirection();
        forward.y = 0.0f;
        if (forward.squaredLength() > 1e-6f)
            forward.normalise();
        Ogre::Vector3 right = mCamera->getRight();
        right.y = 0.0f;
        if (right.squaredLength() > 1e-6f)
            right.normalise();

        Ogre::Vector3 move = Ogre::Vector3::ZERO;
        if (Key::down('W')) move += forward;
        if (Key::down('S')) move -= forward;
        if (Key::down('D')) move += right;
        if (Key::down('A')) move -= right;
        if (Key::down('E')) move.y += 1.0f;
        if (Key::down('Q')) move.y -= 1.0f;
        if (move != Ogre::Vector3::ZERO)
        {
            const float speed = mDist * 0.9f * (Key::down(VK_SHIFT) ? 4.0f : 1.0f);
            mTarget += move * (speed * dt);
            applyCamera();
        }
    }
    //-----------------------------------------------------------------------
    bool ViewerApp::handleMessage(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp, LRESULT& result)
    {
        if (!mCamera)
            return false;
        const int x = (int)(short)LOWORD(lp);
        const int y = (int)(short)HIWORD(lp);
        switch (msg)
        {
        case WM_LBUTTONDOWN:
            mOrbiting = true;
            mLastX = x;
            mLastY = y;
            SetCapture(hwnd);
            result = 0;
            return true;
        case WM_RBUTTONDOWN:
        case WM_MBUTTONDOWN:
            mPanning = true;
            mLastX = x;
            mLastY = y;
            SetCapture(hwnd);
            result = 0;
            return true;
        case WM_LBUTTONUP:
            mOrbiting = false;
            if (!mPanning)
                ReleaseCapture();
            result = 0;
            return true;
        case WM_RBUTTONUP:
        case WM_MBUTTONUP:
            mPanning = false;
            if (!mOrbiting)
                ReleaseCapture();
            result = 0;
            return true;
        case WM_MOUSEMOVE:
            if (mOrbiting || mPanning)
            {
                const int dx = x - mLastX;
                const int dy = y - mLastY;
                mLastX = x;
                mLastY = y;
                if (mOrbiting)
                {
                    mYaw -= dx * 0.006f;
                    mPitch += dy * 0.006f;
                }
                else
                {
                    const float scale = mDist * 0.0015f;
                    mTarget += (mCamera->getRight() * (float)-dx + mCamera->getUp() * (float)dy) * scale;
                }
                applyCamera();
            }
            result = 0;
            return true;
        case WM_MOUSEWHEEL:
            {
                const short delta = (short)HIWORD(wp);
                mDist *= std::pow(0.88f, delta / 120.0f);
                applyCamera();
                result = 0;
                return true;
            }
        case WM_KEYDOWN:
            switch (wp)
            {
            case VK_ESCAPE: mQuit = true; break;
            case 'F': frameContent(); break;
            case 'R':
                if (mOpt.hasCamera)
                    setCameraFromOptions();
                else
                    frameContent();
                break;
            case VK_SPACE: mPaused = !mPaused; break;
            case 'G':
                if (mGrid)
                    mGridNode->flipVisibility();
                else
                    createGrid();
                break;
            case VK_F12: mCaptureRequested = true; break;
            default: break;
            }
            result = 0;
            return true;
        case WM_SIZE:
            if (mSystem && wp != SIZE_MINIMIZED && LOWORD(lp) > 0 && HIWORD(lp) > 0)
                mSystem->resizeWindow(LOWORD(lp), HIWORD(lp));
            return false;
        case WM_CLOSE:
            mQuit = true;
            result = 0;
            return true;
        default:
            return false;
        }
    }
    //-----------------------------------------------------------------------
    bool ViewerApp::pumpMessages(void)
    {
        MSG msg;
        while (PeekMessageW(&msg, NULL, 0, 0, PM_REMOVE))
        {
            if (msg.message == WM_QUIT)
            {
                mQuit = true;
                return false;
            }
            TranslateMessage(&msg);
            DispatchMessageW(&msg);
        }
        return !mQuit;
    }
    //-----------------------------------------------------------------------
    namespace
    {
        // Diagnostic (--ff). client_GL templates pair ps_3_0 pixel programs with a vertex shader chosen by the
        // engine (Model_Skin_VS / Model_VS / Particle_VS exist in MaterialTemplates.zip, but Mtl_Particle.material
        // has no vertex_program_ref and Mtl_Character.material only 12 for 109 fragment refs). 0.85 draws such
        // passes with fixed-function vertex processing, which D3D9 does not allow with ps_3_0: white models,
        // invisible particles. Dropping the pixel program shows the mesh / texture / animation data underneath.
        size_t stripPixelOnlyPasses(const Ogre::MaterialPtr& material, std::set<std::string>& done)
        {
            if (material.isNull() || !done.insert(material->getName()).second)
                return 0;
            size_t passes = 0;
            for (unsigned short t = 0; t < material->getNumTechniques(); ++t)
            {
                Ogre::Technique* technique = material->getTechnique(t);
                for (unsigned short p = 0; p < technique->getNumPasses(); ++p)
                {
                    Ogre::Pass* pass = technique->getPass(p);
                    if (pass->hasFragmentProgram() && !pass->hasVertexProgram())
                    {
                        pass->setFragmentProgram("");
                        ++passes;
                    }
                }
            }
            if (passes)
                material->compile();
            return passes;
        }

        void stripNode(Ogre::SceneNode* node, std::set<std::string>& done, size_t& passes)
        {
            Ogre::SceneNode::ObjectIterator objects = node->getAttachedObjectIterator();
            while (objects.hasMoreElements())
            {
                Ogre::MovableObject* object = objects.getNext();
                if (object->getMovableType() == "Entity")
                {
                    Ogre::Entity* entity = static_cast<Ogre::Entity*>(object);
                    for (unsigned int i = 0; i < entity->getNumSubEntities(); ++i)
                        passes += stripPixelOnlyPasses(entity->getSubEntity(i)->getMaterial(), done);
                }
                else if (object->getMovableType() == "ParticleSystem")
                {
                    Ogre::ParticleSystem* ps = static_cast<Ogre::ParticleSystem*>(object);
                    passes += stripPixelOnlyPasses(
                        Ogre::MaterialManager::getSingleton().getByName(ps->getMaterialName()), done);
                }
            }
            Ogre::Node::ChildNodeIterator children = node->getChildIterator();
            while (children.hasMoreElements())
                stripNode(static_cast<Ogre::SceneNode*>(children.getNext()), done, passes);
        }

        std::set<std::string> gFixedFunctionDone;
        size_t gFixedFunctionPasses = 0;
    }
    //-----------------------------------------------------------------------
    void ViewerApp::applyFixedFunctionFallback(void)
    {
        const size_t before = gFixedFunctionPasses;
        if (mModel && mModel->getSceneNode())
            stripNode(mModel->getSceneNode(), gFixedFunctionDone, gFixedFunctionPasses);
        if (mEffectNode)
            stripNode(mEffectNode, gFixedFunctionDone, gFixedFunctionPasses);
        if (gFixedFunctionPasses != before)
            report("TlbbViewer: --ff: pixel program removed from " + sizeText(gFixedFunctionPasses - before) +
                   " pass(es) without a vertex program");
    }
    //-----------------------------------------------------------------------
    void ViewerApp::renderFrame(float dt, const std::string* capturePath)
    {
        Ogre::Root& root = Ogre::Root::getSingleton();
        if (mOpt.ff)
            applyFixedFunctionFallback();
        if (mCameraLight)
            mCameraLight->setPosition(mCamera->getDerivedPosition());

        // Fixed time step for every frame listener and controller (LogicModel, effects, particles).
        Ogre::FrameEvent evt;
        evt.timeSinceLastEvent = dt;
        evt.timeSinceLastFrame = dt;
        root._fireFrameStarted(evt);
        root._updateAllRenderTargets();          // render textures; the window is not auto-updated
        mWindow->update(false);
        if (capturePath)
            mCaptureOk = captureBackBuffer(*capturePath);
        mWindow->swapBuffers(mOpt.vsync && mOpt.shot.empty());
        root._fireFrameEnded(evt);
        mSimTime += dt;
    }
    //-----------------------------------------------------------------------
    bool ViewerApp::captureBackBuffer(const std::string& path)
    {
        IDirect3DDevice9* device = NULL;
        IDirect3DSurface9* backBuffer = NULL;
        mWindow->getCustomAttribute("D3DDEVICE", &device);
        mWindow->getCustomAttribute("DDBACKBUFFER", &backBuffer);    // not AddRef'd
        if (!device || !backBuffer)
            return false;

        D3DSURFACE_DESC desc;
        backBuffer->GetDesc(&desc);
        IDirect3DSurface9* resolved = NULL;
        IDirect3DSurface9* system = NULL;
        // StretchRect resolves a multisampled back buffer; GetRenderTargetData brings it to system memory.
        HRESULT hr = device->CreateRenderTarget(desc.Width, desc.Height, desc.Format, D3DMULTISAMPLE_NONE, 0,
                                                FALSE, &resolved, NULL);
        if (SUCCEEDED(hr))
            hr = device->StretchRect(backBuffer, NULL, resolved, NULL, D3DTEXF_NONE);
        if (SUCCEEDED(hr))
            hr = device->CreateOffscreenPlainSurface(desc.Width, desc.Height, desc.Format, D3DPOOL_SYSTEMMEM,
                                                     &system, NULL);
        if (SUCCEEDED(hr))
            hr = device->GetRenderTargetData(resolved, system);
        if (SUCCEEDED(hr))
        {
            makeParentDirectories(path);
            hr = D3DXSaveSurfaceToFileA(path.c_str(), D3DXIFF_PNG, system, NULL, NULL);
        }
        if (system)
            system->Release();
        if (resolved)
            resolved->Release();
        if (FAILED(hr))
        {
            char code[32];
            sprintf(code, "0x%08lX", (unsigned long)hr);
            reportError("TlbbViewer: capture failed (" + std::string(code) + ") for " + path);
            return false;
        }
        return true;
    }
    //-----------------------------------------------------------------------
    std::string ViewerApp::nextScreenshotPath(void)
    {
        std::string dir = mOpt.logFile;
        size_t slash = dir.find_last_of("\\/");
        dir = (slash == std::string::npos) ? exeDirectory() : dir.substr(0, slash);
        char name[64];
        time_t now = time(NULL);
        struct tm local;
        localtime_s(&local, &now);
        sprintf(name, "\\TlbbViewer_%04d%02d%02d_%02d%02d%02d_%d.png", local.tm_year + 1900, local.tm_mon + 1,
                local.tm_mday, local.tm_hour, local.tm_min, local.tm_sec, ++mCaptureCounter);
        return dir + name;
    }
    //-----------------------------------------------------------------------
    int ViewerApp::runShot(void)
    {
        int errors = 0;
        for (int i = 0; i < mOpt.frames && !mQuit; ++i)
        {
            pumpMessages();
            const bool last = (i == mOpt.frames - 1);
            try
            {
                if (mAutoFrameEffect && mSimTime >= 0.5)
                {
                    frameContent();
                    mAutoFrameEffect = false;
                }
                if (mAutoFrameModel && mSimTime >= 0.1) // CYS: root + slot children, posed
                {
                    frameContent();
                    mAutoFrameModel = false;
                }
                if (mOpt.turntable != 0.0f) // CYS fx-audit: --turntable deg per simulated second
                {
                    mYaw += Ogre::Degree(mOpt.turntable * mOpt.dt).valueRadians();
                    applyCamera();
                }
                restartFinishedEffect();
                // CYS-WATER: wall time of the second half of the frames (vsync off in shot mode; the device queue
                // bounds the render-ahead, so this follows the GPU cost) for water on/off comparisons
                LARGE_INTEGER cysT0, cysT1;
                QueryPerformanceCounter(&cysT0);
                renderFrame(mOpt.dt, last ? &mOpt.shot : NULL);
                QueryPerformanceCounter(&cysT1);
                if (!last && i >= mOpt.frames / 2)
                {
                    LARGE_INTEGER freq;
                    QueryPerformanceFrequency(&freq);
                    mCysFrameMs += 1000.0 * double(cysT1.QuadPart - cysT0.QuadPart) / double(freq.QuadPart);
                    ++mCysFrameCount;
                }
                errors = 0;
            }
            catch (const Ogre::Exception& e)
            {
                reportError("TlbbViewer: frame " + sizeText(i) + ": " + e.getFullDescription());
                ++mCysFrameErrors; // CYS-PARTICLE: total, not the consecutive counter reset above
                if (++errors > 10)
                    return EXIT_ENGINE;
            }
        }
        if (mOpt.dump)
            dumpContent();
        if (!mCaptureOk)
        {
            reportError("TlbbViewer: no screenshot written");
            return EXIT_CAPTURE;
        }
        char info[160];
        sprintf(info, " (%dx%d, %d frames, dt %.4f s, t = %.3f s)", (int)mWindow->getWidth(),
                (int)mWindow->getHeight(), mOpt.frames, mOpt.dt, mSimTime);
        report("TlbbViewer: saved " + mOpt.shot + info);
        if (mCysFrameCount > 0) // CYS-WATER
        {
            char timing[160];
            sprintf(timing, "TlbbViewer: frame time %.3f ms (mean of %d frames, second half)",
                    mCysFrameMs / mCysFrameCount, mCysFrameCount);
            report(timing);
        }
        // CYS-PARTICLE: with CYS_SCENE_INCREMENTAL=1 the objects are built during the frames, so the failures
        // only exist AFTER the loop - loadScene()'s census above ran before a single one had been built.
        if (mSceneLoaded)
        {
            size_t cysFailed = 0;
            const WX::System::ExceptionInfoMap& cysProblems = mSystem->getExceptionInfoMap();
            for (WX::System::ExceptionInfoMap::const_iterator it = cysProblems.begin(); it != cysProblems.end(); ++it)
                cysFailed += it->second.size();
            report("TlbbViewer: CYS-PARTICLE: scene object failures after " + sizeText(mOpt.frames) +
                   " frames: " + sizeText(cysFailed) + " (frame-loop errors: " + sizeText(mCysFrameErrors) + ")");
        }
        return mMissing ? EXIT_NOT_FOUND : EXIT_OK;
    }
    //-----------------------------------------------------------------------
    int ViewerApp::runInteractive(void)
    {
        LARGE_INTEGER frequency, last, now;
        QueryPerformanceFrequency(&frequency);
        QueryPerformanceCounter(&last);
        int errors = 0;
        while (!mQuit)
        {
            if (!pumpMessages())
                break;
            if (IsIconic(mHwnd))
            {
                Sleep(30);
                QueryPerformanceCounter(&last);
                continue;
            }
            QueryPerformanceCounter(&now);
            float dt = float(double(now.QuadPart - last.QuadPart) / double(frequency.QuadPart));
            last = now;
            dt = std::max(0.0f, std::min(0.1f, dt));

            try
            {
                updateKeyboard(dt);
                if (mAutoFrameEffect && mSimTime >= 0.5)
                {
                    frameContent();
                    mAutoFrameEffect = false;
                }
                if (mAutoFrameModel && mSimTime >= 0.1) // CYS: root + slot children, posed
                {
                    frameContent();
                    mAutoFrameModel = false;
                }
                restartFinishedEffect();
                if (mCaptureRequested)
                {
                    const std::string path = nextScreenshotPath();
                    renderFrame(mPaused ? 0.0f : dt, &path);
                    if (mCaptureOk)
                        report("TlbbViewer: saved " + path);
                    mCaptureRequested = false;
                }
                else
                {
                    renderFrame(mPaused ? 0.0f : dt, NULL);
                }
                errors = 0;
            }
            catch (const Ogre::Exception& e)
            {
                reportError("TlbbViewer: frame error: " + e.getFullDescription());
                if (++errors > 10)
                    return EXIT_ENGINE;
            }
        }
        return EXIT_OK;
    }
}
