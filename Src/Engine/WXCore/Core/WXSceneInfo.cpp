#include "WXSceneInfo.h"
#include "WXSceneSerializer.h"
#include "Terrain.h"
#include "WXSystem.h"
#include "CYS/Scene/CYSEnvironment.h"   // CYS
#include "CYS/Scene/CYSSceneCommon.h"   // CYS ci-cy: CYSSceneStats (missing .Terrain = data problem)
#include "CYS/Perf/CysPerf.h"      // CYS-PERF
#include "CYS/Scene/CYSSceneObjects.h" // CYS-PERF-FIX camdiscull: SceneConfig property bag
#include "WXStaticEntityObject.h"    // CYS-PERF-FIX camdiscull
#include <OgreEntity.h>                // CYS-PERF-FIX camdiscull
#include <OgreTimer.h>                 // CYS-PERF-FIX camdiscull
#include <vector>
#include <OgreCysPerf.h>           // CYS-PERF
#include <OgreResourceGroupManager.h>   // CYS ci-cy
#include <OgreLogManager.h>             // CYS ci-cy
#include <OgreStringConverter.h>         // CYS-FIX fix-projector

#include <OgreSceneManager.h>
#include <OgreFrameListener.h>
#include <OgreRoot.h>
#include <OgreCamera.h>

namespace WX
{
#define STARTUP_BUILD_OBJECTS   64
#define RUNNING_BUILD_OBJECTS   1



#define CYS_RUNNING_BUILD_OBJECTS_PER_SECOND 30.0f
const float MAX_DISTANCE = 2000.0f;
const float MAX_DISTANCE_SQUARED = MAX_DISTANCE * MAX_DISTANCE;

    // CYS-PARTICLE: one place that builds one scene object and survives bad data, used by BOTH paths of
    // SceneInfo::initialise. Before this, only the immediate path had a try/catch; the incremental path (the
    // one the game actually runs) called createRenderInstance() bare, so a single scene object whose data is
    // missing - proven case: a "particle system name" that is not a template of all.particle, which makes
    // Ogre::ParticleSystemManager::createSystem throw ERR_INVALIDPARAMS - terminated the client.
    // Returns true when the render instance was created.
    //
    // CYS-PARTICLE: CYS_PARTICLE_NOCATCH=1 restores the pre-patch behaviour (build bare, let the exception
    // out). It exists for exactly one reason: the acceptance rule of this project is "same binary, one
    // variable different, and the control arm must DIE". Without it the control arm would need a second
    // staged DLL cluster, i.e. a second variable. Default OFF; the first call announces which arm is running
    // so no run can be misread afterwards. Never set it outside an A/B measurement.
    static bool CysBuildNoCatch(void)
    {
        static int s_mode = -1;
        if (s_mode < 0)
        {
            const char* v = getenv("CYS_PARTICLE_NOCATCH");
            s_mode = (v && strcmp(v, "1") == 0) ? 1 : 0;
            Ogre::LogManager::getSingleton().logMessage(
                s_mode ? "CYS-PARTICLE: ARM=control (CYS_PARTICLE_NOCATCH=1) - a missing scene object will"
                         " terminate the process, as before the patch"
                       : "CYS-PARTICLE: ARM=patched - a missing scene object is logged and skipped",
                Ogre::LML_CRITICAL);
        }
        return s_mode != 0;
    }

    static bool CysBuildObject(System* system, const ObjectPtr& object)
    {
        if (CysBuildNoCatch())
        {
            object->createRenderInstance(system);   // control arm: bare, exactly as HEAD did
            return true;
        }
        try
        {
            object->createRenderInstance(system);
            return true;
        }
        // LML_CRITICAL, not the default LML_NORMAL: this line is now the ONLY trace a skipped object leaves,
        // and both the game and TlbbViewer run the Ogre log at LL_LOW, which drops everything below critical.
        catch (Ogre::Exception& e)
        {
            Ogre::LogManager::getSingleton().logMessage(
                "CYS-PARTICLE: scene object '" + object->getName() + "' (" + object->getType() +
                ") not created, skipped: " + e.getDescription(), Ogre::LML_CRITICAL);
            system->addExceptionInfo(e.getDescription(), System::ExceptionInfo(object->getName()));
        }
        catch (std::exception& e)
        {
            Ogre::LogManager::getSingleton().logMessage(
                "CYS-PARTICLE: scene object '" + object->getName() + "' (" + object->getType() +
                ") not created, skipped: " + Ogre::String(e.what()), Ogre::LML_CRITICAL);
            system->addExceptionInfo(e.what(), System::ExceptionInfo(object->getName()));
        }
        return false;
    }

    //-----------------------------------------------------------------------
    class IncrementalSceneBuilder : public Ogre::FrameListener
    {
    public:
        IncrementalSceneBuilder(WX::System* system)
            : mSystem(system)
            , mObjectsPerFrame(STARTUP_BUILD_OBJECTS)
            , mDisableCreateObjects(false)
            , mImmediatelyCreateObjects(false)
            , mEnableStaticGeometry(false)
            , mStaticGeometryBaked(false)
            , mCysBuildBudget(0.0f) // CYS-PERF-FIX scenebuild
            , mCysBuildStartup(true)
            , mCysBuildLegacy(false)
            , mCysCullOn(false)
            , mCysCullDepth(0)
            , mCysCullParam(0)
            , mCysCullCursor(0)
            , mCysCullLogAt(0)
        {
            const char* cysMode = getenv("CYS_PERF_SCENEBUILD"); // CYS-PERF-FIX scenebuild: legacy = 1 object per frame
            mCysBuildLegacy = cysMode && _stricmp(cysMode, "legacy") == 0;
            const char* s = getenv("Fairy_Hack");
            if (s)
            {
                mDisableCreateObjects = strstr(s, "DisableCreateObjects") != 0;
                mImmediatelyCreateObjects = strstr(s, "ImmediatelyCreateObjects") != 0;
                mEnableStaticGeometry = strstr(s, "EnableStaticGeometry") != 0;
            }

            mSystem->getRoot()->addFrameListener(this);
        }

        ~IncrementalSceneBuilder()
        {
            mSystem->getRoot()->removeFrameListener(this);
        }

        bool frameStarted(const Ogre::FrameEvent& evt)
        {
            cysUpdateCamDisCull(); // CYS-PERF-FIX camdiscull
            if (!objects.empty())
            {
                Ogre::CysPerf::Scope cysPerfScope(Ogre::CysPerf::PH_SCENE_BUILD); // CYS-PERF
                if (mCysBuildLegacy)
                {
                    for (size_t count = mObjectsPerFrame; count; --count)
                    {
                        if (!buildOneObject())
                        {
                            break;
                        }
                    }
                }
                else
                {
                    // CYS-PERF-FIX scenebuild: CY budget (64 on the first frame, then 30 per second of frame time)
                    mCysBuildBudget += mCysBuildStartup ? float(STARTUP_BUILD_OBJECTS)
                                                        : CYS_RUNNING_BUILD_OBJECTS_PER_SECOND * evt.timeSinceLastFrame;
                    mCysBuildStartup = false;
                    while (mCysBuildBudget >= 1.0f)
                    {
                        mCysBuildBudget -= 1.0f;
                        if (!buildOneObject())
                        {
                            mCysBuildBudget = 0.0f;
                            break;
                        }
                    }
                }

                mObjectsPerFrame = RUNNING_BUILD_OBJECTS;
                if (objects.empty()) CYS::Perf::mark("scene-built"); // CYS-PERF
            }
            else if (mEnableStaticGeometry && !mStaticGeometryBaked)
            {
                mStaticGeometryBaked = true;
                mSystem->bakeStaticGeometries(0);
            }

            return true;
        }

        bool buildOneObject(void)
        {
            Ogre::Camera* currentCam = mSystem->getCamera();

            // get the position of current camera
            Ogre::Vector3 cameraPos = currentCam->getDerivedPosition();;
            const Ogre::Vector3 cysEye = cameraPos; // CYS-PERF-FIX camdiscull: CY compares with Camera::getDerivedPosition

            // get the position of terrain intersect point
            Ogre::Vector3 position;

            Ogre::Ray cameraRay( currentCam->getPosition(), currentCam->getDirection() );
            bool hit = mSystem->getTerrainIntersects(cameraRay, position);

            // if we find the intersect point
            if (hit)
            {
                // if the intersect point is to far, adjust it.
                if ( (position - cameraPos).squaredLength() > MAX_DISTANCE_SQUARED )
                    cameraPos += currentCam->getDirection() * MAX_DISTANCE;
                else
                    cameraPos = position;
            }  

            ObjectPtr bestObject;
            Real bestDistance = 0;
            for (ObjectInfos::iterator it = objects.begin(); it != objects.end(); )
            {
                ObjectPtr object = it->first.lock();
                // CYS-PERF-FIX camdiscull: CY does not create a StaticEntity farther than SetCamDisCullDepth from the eye
                // (its radius is unknown before the mesh exists); it stays pending until the camera comes closer.
                if (object && mCysCullOn && object->getType() == StaticEntityObject::msType &&
                    (it->second - cysEye).squaredLength() > mCysCullDepth * mCysCullDepth)
                {
                    ++it;
                    continue;
                }
                if (object)
                {
                    Real distance = (it->second - cameraPos).squaredLength();

                    if (!bestObject || distance < bestDistance)
                    {
                        bestObject = object;
                        bestDistance = distance;
                        if (!distance)
                            break;
                    }

                    ++it;
                }
                else
                {
					ObjectInfos::iterator itErase = it++;
                    objects.erase(itErase);
                }
            }

            if (!bestObject)
                return false;

            // CYS-PARTICLE: the incremental path used to call createRenderInstance() BARE, while the immediate
            // path 300 lines below (SceneInfo::initialise, DisableIncrementalBuildScene / editor / TlbbViewer)
            // has always wrapped the very same call in try/catch. One missing data item - e.g. a scene whose
            // ParticleSystem object names a template that is not in all.particle - therefore threw
            // Ogre::Exception ERR_INVALIDPARAMS (OgreParticleSystemManager.cpp:335) out of frameStarted, past
            // CGameProcedure::MainLoop's catch(...) - which only logs and rethrows (GameProcedure.cpp:1119) -
            // into _tWinMain's __except and TerminateProcess. A decorative effect killed the session.
            // Two consequences, both fixed here:
            //   (a) the object is now skipped instead of killing the process (same policy as the immediate path);
            //   (b) the erase below used to be UNREACHABLE on a throw, so the builder retried the SAME object on
            //       every frame and never built the rest of the scene - a permanent stall even if something
            //       higher up had swallowed the exception.
            if (!cysCreateRenderInstance(bestObject))
            {
                objects.erase(bestObject);
                return true;
            }
            if (mCysCullOn && bestObject->getType() == StaticEntityObject::msType) // CYS-PERF-FIX camdiscull
            {
                CysCulled entry;
                entry.object = bestObject;
                entry.position = objects[bestObject];
                entry.hidden = false;
                mCysCulled.push_back(entry);
            }
            Ogre::CysPerf::count(Ogre::CysPerf::C_SCENE_OBJECTS); // CYS-PERF
            objects.erase(bestObject);
            return true;
        }

        // CYS-PARTICLE: create one scene object the way the immediate path does - log and skip what the data
        // cannot supply, never take the process down with it. Returns false when the object was NOT created.
        bool cysCreateRenderInstance(const ObjectPtr& object)
        {
            return CysBuildObject(mSystem, object);
        }

        bool addObject(const ObjectPtr& object)
        {
            if (object->getType() == "SceneConfig") // CYS-PERF-FIX camdiscull
                cysReadSceneConfig(object);
            if (object->getCategory() == "Enviroment" ||
                object->getCategory() == "Light")
                return false;
            if (object->getType() == "TerrainLiquid")
                return false;
            Variant v = object->getProperty("position");
            if (v.empty())
                return false;

            if (mImmediatelyCreateObjects)
                return mDisableCreateObjects;

            if (!mDisableCreateObjects)
            {
                objects[object] = VariantCast<Ogre::Vector3>(v);
            }

            return true;
        }

        void reset(void)
        {
            objects.clear();
            mObjectsPerFrame = STARTUP_BUILD_OBJECTS;
            mCysBuildBudget = 0.0f; // CYS-PERF-FIX scenebuild
            mCysCullOn = false; // CYS-PERF-FIX camdiscull
            mCysCulled.clear();
            mCysCullCursor = 0;
            mCysBuildStartup = true;
            mStaticGeometryBaked = false;
        }

    protected:
        WX::System* mSystem;
        size_t mObjectsPerFrame;
        bool mDisableCreateObjects;
        bool mImmediatelyCreateObjects;
        bool mEnableStaticGeometry;
        bool mStaticGeometryBaked;
        float mCysBuildBudget;   // CYS-PERF-FIX scenebuild: fractional objects still allowed
        bool mCysBuildStartup;   // next build is the 64-object startup batch
        bool mCysBuildLegacy;    // CYS_PERF_SCENEBUILD=legacy









        struct CysCulled
        {
            ObjectWeakPtr object;
            Ogre::Vector3 position;
            bool hidden;
        };
        std::vector<CysCulled> mCysCulled;
        bool mCysCullOn;
        Ogre::Real mCysCullDepth;
        Ogre::Real mCysCullParam;
        size_t mCysCullCursor;
        unsigned long mCysCullLogAt;

    public:
        // CYS-PERF-FIX camdiscull: immediate scene build (TlbbViewer / setDisableIncrementalBuildScene): every object is
        // created at once, the far StaticEntity are then hidden by the same per-frame rule.
        void cysTrackImmediate(const ObjectPtr& object)
        {
            if (object->getType() == "SceneConfig")
            {
                cysReadSceneConfig(object);
                return;
            }
            if (!mCysCullOn || object->getType() != StaticEntityObject::msType)
                return;
            Variant v = object->getProperty("position");
            if (v.empty())
                return;
            CysCulled entry;
            entry.object = object;
            entry.position = VariantCast<Ogre::Vector3>(v);
            entry.hidden = false;
            mCysCulled.push_back(entry);
        }
    protected:
        void cysReadSceneConfig(const ObjectPtr& object)
        {
            const CYSPropertyBagObject* bag = dynamic_cast<const CYSPropertyBagObject*>(object.get());
            if (!bag)
                return;
            const char* env = getenv("CYS_PERF_CAMDISCULL");
            const bool disabled = env && env[0] == '0';
            const bool enable = bag->getBool("EnableCamDisCull", false);
            const Ogre::Real depth = bag->getReal("SetCamDisCullDepth", 0);
            const Ogre::Real param = bag->getReal("SetCamDisCullParam", 0);
            mCysCullDepth = (depth > 100 && depth < 10000) ? depth : 0;
            mCysCullParam = param > 0 ? Ogre::Real(int(param)) : 0;
            mCysCullOn = enable && !disabled && mCysCullDepth > 0;
            Ogre::LogManager::getSingleton().logMessage("CYS-PERF camdiscull: SceneConfig enable=" +
                Ogre::StringConverter::toString(enable) + " depth=" + Ogre::StringConverter::toString(depth) + " param=" +
                Ogre::StringConverter::toString(param) + (disabled ? " (CYS_PERF_CAMDISCULL=0)" : "") +
                " -> " + (mCysCullOn ? "on" : "off"));
        }

        // Visits up to 512 created StaticEntity objects per frame (a full pass over dali_new_320 in ~11 frames).
        void cysUpdateCamDisCull(void)
        {
            if (!mCysCullOn || mCysCulled.empty())
                return;
            Ogre::Camera* camera = mSystem->getCamera();
            if (!camera)
                return;
            const Ogre::Vector3 eye = camera->getDerivedPosition();
            const Ogre::Real depth2 = mCysCullDepth * mCysCullDepth;
            size_t visits = mCysCulled.size() < 512 ? mCysCulled.size() : 512;
            while (visits--)
            {
                if (mCysCullCursor >= mCysCulled.size())
                    mCysCullCursor = 0;
                CysCulled& entry = mCysCulled[mCysCullCursor];
                ObjectPtr object = entry.object.lock();
                StaticEntityObject* se = object ? static_cast<StaticEntityObject*>(object.get()) : 0;
                Ogre::Entity* entity = se ? se->getEntity() : 0;
                if (!entity)
                {
                    mCysCulled[mCysCullCursor] = mCysCulled.back();
                    mCysCulled.pop_back();
                    continue;
                }
                const Ogre::Real keep = entity->getBoundingRadius() * mCysCullParam;
                const Ogre::Real dist2 = (entry.position - eye).squaredLength();
                const bool hide = dist2 > depth2 && dist2 > keep * keep;
                if (hide != entry.hidden)
                {
                    entity->setVisible(!hide);
                    entry.hidden = hide;
                }
                ++mCysCullCursor;
            }
            const unsigned long now = Ogre::Root::getSingleton().getTimer()->getMilliseconds();
            if (Ogre::CysPerf::on() && now - mCysCullLogAt >= 10000)
            {
                mCysCullLogAt = now;
                size_t hidden = 0;
                for (size_t i = 0; i < mCysCulled.size(); ++i)
                    hidden += mCysCulled[i].hidden ? 1 : 0;
                Ogre::LogManager::getSingleton().logMessage("CYS-PERF camdiscull: created=" +
                    Ogre::StringConverter::toString(mCysCulled.size()) + " hidden=" + Ogre::StringConverter::toString(hidden) +
                    " pending=" + Ogre::StringConverter::toString(objects.size()));
            }
        }

        typedef std::pair<ObjectWeakPtr, Ogre::Vector3> ObjectInfo;
        typedef std::map<ObjectWeakPtr, Ogre::Vector3> ObjectInfos;
        ObjectInfos objects;
    };

    //-----------------------------------------------------------------------
    //-----------------------------------------------------------------------
    //-----------------------------------------------------------------------
    SceneInfo::SceneInfo()
        : mTerrain(NULL)
        , mTerrainData(NULL)
        , mIncrementalSceneBuilder(NULL)
    {
        mTerrain = new Terrain;
        mTerrainData = mTerrain->getData();
    }
    //-----------------------------------------------------------------------
    SceneInfo::~SceneInfo()
    {
        delete mIncrementalSceneBuilder;
        delete mTerrain;
    }
    //-----------------------------------------------------------------------
    void SceneInfo::load(XMLParser* parser, const String& filename, const String& groupName, bool completely)
    {
        SceneSerializer serializer;
        serializer.load(this, parser, filename, groupName);

        if (!mTerrainFilename.empty())
        {
            // CYS ci-cy 14/09/2026: CY 3.71 ships Scene2Folder\SnowWorld_GeCao_Xiuxi.Scene with its .Heightmap but
            // without the .Terrain (absent in Scene2.axp and DataCY; CYHJ/GL have it). The original engine throws
            // here and the scene cannot be entered. Rule "unknown data: log and skip": load the rest of the scene
            // without terrain and record a data problem (visible in Tests/scene reports as "Data problems").
            // CYS cs2-world 14/09: resourceExists(group) looks in ONE group, while openResource searches every group
            // (searchGroupsIfNotFound). CY scenes keep their .Terrain in the "Scene" group with groupName 'General', so
            // the one-group test said "missing" for tl3chuangjian.Terrain (the CY login scene), the terrain was skipped,
            // the heightmap stayed empty and TerrainLiquid::build read a null heightmap (replay-run-10/12 AV in
            // Render.dll). Ask every group before declaring the file absent.
            bool cysTerrainExists = Ogre::ResourceGroupManager::getSingleton().resourceExists(groupName, mTerrainFilename);
            if (!cysTerrainExists)
            {
                const Ogre::StringVector cysGroups = Ogre::ResourceGroupManager::getSingleton().getResourceGroups();
                for (Ogre::StringVector::const_iterator g = cysGroups.begin(); g != cysGroups.end() && !cysTerrainExists; ++g)
                    cysTerrainExists = Ogre::ResourceGroupManager::getSingleton().resourceExists(*g, mTerrainFilename);
            }
            if (!cysTerrainExists)
            {
                CYSSceneStats::instance().problem("Scene <Terrain> file not found (scene loaded without terrain)", mTerrainFilename);
                Ogre::LogManager::getSingleton().logMessage("CYS: scene '" + filename + "': terrain file '" +
                    mTerrainFilename + "' not found in group '" + groupName + "'; loading without terrain");
            }
            else
            {
                getTerrainData()->load(parser, mTerrainFilename, groupName, completely);
            }
        }

        // CYS: the scene's B/C side files (.skysphere, .EnScene, .hdr/.newhdrbloom/.hfog/.godrays) as B's
        //      SceneInfo::load does (05 §1); the render side is built in System::_postprocessScene.
        CYSEnvironmentManager::getSingleton()._onSceneLoaded(this, filename, groupName);
    }
    //-----------------------------------------------------------------------
    void SceneInfo::save(XMLWriter* writer, const String& filename)
    {
        String baseName, path;
        Ogre::StringUtil::splitFilename(filename, baseName, path);
        if (Ogre::StringUtil::endsWith(baseName, ".scene"))
            baseName.erase(baseName.length() - (sizeof(".scene") - 1));

        mName = baseName;
        mTerrainFilename = baseName + ".Terrain";
        getTerrainData()->save(writer, path + mTerrainFilename);

        SceneSerializer serializer;
        serializer.save(this, writer, filename);
    }
    //-----------------------------------------------------------------------
    void SceneInfo::destroy(void)
    {
        if (mIncrementalSceneBuilder)
        {
            mIncrementalSceneBuilder->reset();
        }

        for (Objects::const_iterator it = mObjects.begin(); it != mObjects.end(); ++it)
        {
            const ObjectPtr& object = *it;
            object->destroyRenderInstance();
        }

        getTerrain()->clearGeometry();
    }
    //-----------------------------------------------------------------------
    void SceneInfo::reset(void)
    {
        destroy();

        Scene::reset();
        getTerrain()->reset();
    }
    //-----------------------------------------------------------------------
    void SceneInfo::initialise(WX::System* system)
    {
        assert(system);
        system->getSceneManager()->setAmbientLight(Ogre::ColourValue::Black);

        getTerrain()->buildGeometry(system->getBaseSceneNode(), system->isEditable());

        if (system->getDisableIncrementalBuildScene() || system->isEditable())
        {
            if (mIncrementalSceneBuilder)
            {
                mIncrementalSceneBuilder->reset();
            }
            // CYS-PERF-FIX camdiscull: the SceneConfig first (the immediate path creates objects in file order)
            if (!system->isEditable())
            {
                if (!mIncrementalSceneBuilder)
                    mIncrementalSceneBuilder = new IncrementalSceneBuilder(system);
                mIncrementalSceneBuilder->reset();
                for (Objects::const_iterator it = mObjects.begin(); it != mObjects.end(); ++it)
                    if ((*it)->getType() == "SceneConfig")
                        mIncrementalSceneBuilder->cysTrackImmediate(*it);
            }

            for (Objects::const_iterator it = mObjects.begin(); it != mObjects.end(); ++it)
            {
			    try
			    {
				    const ObjectPtr& object = *it;

                    if (object->hasProperty("create level"))
                    {
                        // CYS-FIX fix-projector 15/09/2026: VariantCast<Real>(Variant) throws boost::bad_any_cast when
                        // the command does not return a Real (a stored/verbatim CYS property returns an empty Variant:
                        // ci-cy put "create level" on the Projector bag -> TlbbViewer died on luoyang_new/suzhou_new).
                        // Read the Real if there is one, else parse the text; no value = no create-level filter.
                        Variant cysLevel = object->getProperty("create level");
                        const Real* cysLevelReal = VariantCast<Real>(&cysLevel);
                        Real cysLevelValue = 0;
                        bool cysHasLevel = cysLevelReal != NULL;
                        if (cysLevelReal)
                            cysLevelValue = *cysLevelReal;
                        else
                        {
                            const String cysText = object->getPropertyAsString("create level");
                            cysHasLevel = !cysText.empty();
                            if (cysHasLevel)
                                cysLevelValue = Ogre::StringConverter::parseReal(cysText);
                        }
                        if (cysHasLevel && false == system->_determineCreateLevel(cysLevelValue))
                            continue;
                    }

				    object->createRenderInstance(system);
				    if (mIncrementalSceneBuilder && !system->isEditable() && object->getType() != "SceneConfig")
				        mIncrementalSceneBuilder->cysTrackImmediate(object); // CYS-PERF-FIX camdiscull
			    }
			    catch ( Ogre::Exception &e )
			    {
				    system->addExceptionInfo( e.getDescription(), System::ExceptionInfo( (*it)->getName() ) );
			    }
                // CYS-FIX fix-projector: a std::exception from one object (bad_any_cast, bad_alloc...) is logged like an
                // OGRE exception instead of terminating the process (rule: unknown data -> log and skip).
                catch (std::exception& e)
                {
                    Ogre::LogManager::getSingleton().logMessage("CYS: scene object '" + (*it)->getName() + "' (" +
                        (*it)->getType() + ") not created: " + e.what());
                    system->addExceptionInfo( e.what(), System::ExceptionInfo( (*it)->getName() ) );
                }
            }
        }
        else
        {
            if (!mIncrementalSceneBuilder)
            {
                mIncrementalSceneBuilder = new IncrementalSceneBuilder(system);
            }

            mIncrementalSceneBuilder->reset();

            for (Objects::const_iterator it = mObjects.begin(); it != mObjects.end(); ++it)
            {
                const ObjectPtr& object = *it;
                if (!mIncrementalSceneBuilder->addObject(object))
                {
                    // CYS-PARTICLE: the objects addObject() refuses (Enviroment, Light, TerrainLiquid, and
                    // anything without a "position") are created RIGHT HERE, before the first frame, and this
                    // call was bare too. That is the deadlier half of the bug: an Enviroment object whose
                    // "weather.particle system name" is missing from all.particle killed the client at scene
                    // load - no frame, no world, no clue - while a ParticleSystem object only kills it seconds
                    // later, when the incremental builder reaches it. Same policy now: log and skip.
                    CysBuildObject(system, object);
                }
            }
        }
    }

}
