// CY-Source (scene agent): see CYSEnvironment.h.
#include "CYSEnvironment.h"
#include "CYSEnvironmentProvider.h"
#include "CYSSkyRenderer.h"
#include "CYSSkyCyRenderer.h"
#include "CYSSceneObjects.h"

#include "Core/WXSystem.h"
#include "Core/WXSceneInfo.h"
#include "Core/WXEnviromentObject.h"
#include "Core/WXLightObject.h"
#include "Core/WXObjectFactoryManager.h"
#include "EffectSystem/WXEffectManager.h"
#include "EffectSystem/WXMainSceneLight.h"

#include <OgreRoot.h>
#include <OgreSceneManager.h>
#include <OgreCamera.h>
#include <OgreViewport.h>
#include <OgreResourceGroupManager.h>
#include <OgreException.h>

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>

namespace WX
{
    using namespace CYSScene;

    //////////////////////////////////////////////////////////////////////////
    // CYSEnvironment
    //////////////////////////////////////////////////////////////////////////
    CYSEnvironment::CYSEnvironment(void)
        : revision(0)
        , source(SOURCE_NONE)
        , timeOfDay(12.0f)
        , regionWeight(0)
        , ambient(0, 0, 0, 1)
        , lightOneDiffuse(0, 0, 0, 1)
        , lightOneSpecular(0, 0, 0, 1)
        , lightOneIntensity(1.0f)
        , lightOneDirection(0, -1, 0)
        , lightTwoDiffuse(0, 0, 0, 1)
        , lightTwoSpecular(0, 0, 0, 1)
        , lightTwoIntensity(1.0f)
        , lightTwoDirection(0, -1, 0)
        , sunDirection(0, 1, 0)
        , sunColour(0, 0, 0, 1)
        , pbrAmbient(0, 0, 0, 1)
        , actorLightOne(0, 0, 0, 1)
        , actorLightOneIntensity(1.0f)
        , actorLightTwo(0, 0, 0, 1)
        , actorLightTwoIntensity(1.0f)
        , actorAmbient(0, 0, 0, 1)
        , selectActorLight(0.5f, 0.5f, 0.5f, 1.0f)
        , skyDomeAmbient(1, 1, 1, 1)
        , lightSpecularIntensity(0)
        , fakePointLightIntensity(1.0f)
        , shadowStrength(1.0f)
        , pbrShadowStrength(1.0f)
        , fogMode(Ogre::FOG_NONE)
        , fogColour(0, 0, 0, 1)
        , fogStart(0)
        , fogEnd(1)
        , fogDensity(0.001f)
        , skyFogColour(0, 0, 0, 1)
        , appliedFogMode(Ogre::FOG_NONE)
        , appliedFogColour(0, 0, 0, 1)
        , appliedFogStart(0)
        , appliedFogEnd(1)
        , appliedFogDensity(0.001f)
        , heightFogEnabled(false)
        , heightFog(CYSHeightFogParams::zero())
        , warmColour(0.5f, 0.5f, 0.5f)
        , coldColour(0.5f, 0.5f, 0.5f)
        , enhanceContrast(1, 1, 1)
        , overlayImage(0.5f, 0.5f, 0.5f)
        , radialBlur(1.0f, 0.1f)
        , windDirection(1, 0, 0)
        , windStrength(16.0f)       // B wind_control_params default initialiser (1, 0, 16)
        , windTime(0)
    {
    }
    //-----------------------------------------------------------------------
    const CYSEnvironment& CYSEnvironment::current(void)
    {
        return CYSEnvironmentManager::getSingleton().getEnvironment();
    }

    //////////////////////////////////////////////////////////////////////////
    // helpers
    //////////////////////////////////////////////////////////////////////////
    namespace
    {
        Real envReal(const char* name, Real def)
        {
            const char* v = getenv(name);
            return (v && *v) ? parseReal(v, def) : def;
        }

        bool envBool(const char* name, bool def)
        {
            const char* v = getenv(name);
            return (v && *v) ? parseBool(v, def) : def;
        }

        inline bool differs(Real a, Real b, Real tolerance)
        {
            return std::fabs(a - b) > tolerance;
        }

        inline bool differs(const Ogre::ColourValue& a, const Ogre::ColourValue& b)
        {
            return differs(a.r, b.r, 1e-3f) || differs(a.g, b.g, 1e-3f) || differs(a.b, b.b, 1e-3f);
        }

        inline bool differs(const Ogre::Vector3& a, const Ogre::Vector3& b)
        {
            return differs(a.x, b.x, 1e-3f) || differs(a.y, b.y, 1e-3f) || differs(a.z, b.z, 1e-3f);
        }

        /// Only changes that matter for what the 0.85 renderer is given (lights, ambient, fog, fake lights).
        bool significantChange(const CYSEnvKey& a, const CYSEnvKey& b)
        {
            return differs(a.ambient, b.ambient) || differs(a.fog, b.fog) ||
                differs(a.fogNear, b.fogNear, 1.0f) || differs(a.fogFar, b.fogFar, 1.0f) ||
                differs(a.lightOne, b.lightOne) || differs(a.lightOneSpecular, b.lightOneSpecular) ||
                differs(a.lightOneIntensity, b.lightOneIntensity, 1e-3f) ||
                differs(a.lightOneDirection, b.lightOneDirection) ||
                differs(a.lightTwo, b.lightTwo) || differs(a.lightTwoSpecular, b.lightTwoSpecular) ||
                differs(a.lightTwoIntensity, b.lightTwoIntensity, 1e-3f) ||
                differs(a.lightTwoDirection, b.lightTwoDirection) ||
                differs(a.fakePointLightIntensity, b.fakePointLightIntensity, 1e-3f) ||
                differs(a.actorLightOne, b.actorLightOne) || differs(a.actorLightTwo, b.actorLightTwo) ||
                differs(a.actorAmbient, b.actorAmbient) || differs(a.pbrAmbient, b.pbrAmbient) ||
                differs(a.skyDomeAmbientColour, b.skyDomeAmbientColour) ||
                differs(a.skyDomeAmbientStrength, b.skyDomeAmbientStrength, 1e-3f) ||
                differs(a.shadowStrength, b.shadowStrength, 1e-3f) ||
                differs(a.pbrShadowStrength, b.pbrShadowStrength, 1e-3f) ||
                a.heightFogEnabled != b.heightFogEnabled ||
                differs(a.heightFog.hDensity, b.heightFog.hDensity, 1e-4f) ||
                differs(a.heightFog.hHeight, b.heightFog.hHeight, 0.5f) ||
                differs(a.heightFog.dDensity, b.heightFog.dDensity, 1e-4f) ||
                differs(a.heightFog.fogColour, b.heightFog.fogColour) ||
                differs(a.skyFog, b.skyFog);
        }

        LightObject* findLight(SceneInfo* scene, const char* name)
        {
            if (!scene)
                return NULL;
            const ObjectPtr& object = scene->findObjectByName(name);
            if (!object || object->getType() != LightObject::msType)
                return NULL;
            return static_cast<LightObject*>(object.get());
        }

        EnviromentObject* findEnviroment(SceneInfo* scene)
        {
            if (!scene)
                return NULL;
            Scene::ObjectsByTypeRange range = scene->findObjectsByType(EnviromentObject::msType);
            if (range.first == range.second)
                return NULL;
            return static_cast<EnviromentObject*>(range.first->get());
        }

        ObjectPtr findFirstOfType(Scene* scene, const String& type)
        {
            Scene::ObjectsByTypeRange range = scene->findObjectsByType(type);
            if (range.first == range.second)
                return ObjectPtr();
            return *range.first;
        }

        std::vector<String> lookupGroups(const String& group)
        {
            std::vector<String> groups;
            groups.push_back(group);
            if (group != "Scene")
                groups.push_back("Scene");
            if (group != Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME)
                groups.push_back(Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
            return groups;
        }

        bool findGroup(const String& name, const std::vector<String>& groups, String& found)
        {
            Ogre::ResourceGroupManager& rgm = Ogre::ResourceGroupManager::getSingleton();
            for (size_t i = 0; i < groups.size(); ++i)
            {
                try
                {
                    if (rgm.resourceExists(groups[i], name))
                    {
                        found = groups[i];
                        return true;
                    }
                }
                catch (const Ogre::Exception&)
                {
                }
            }
            return false;
        }

        /// Values of the scene before any time-of-day application, restored when the environment is disabled.
        struct SceneSnapshot
        {
            bool valid;
            Ogre::ColourValue ambient;
            Ogre::FogMode fogMode;
            Ogre::ColourValue fogColour;
            Real fogDensity, fogStart, fogEnd;
            struct Light
            {
                bool valid;
                Ogre::ColourValue diffuse, specular;
                Ogre::Vector3 direction;
                Real intensity;
            } lights[2];
            SceneSnapshot(void) : valid(false) {}
        };

        SceneSnapshot& snapshot(void)
        {
            static SceneSnapshot s;
            return s;
        }

        /// The auto-constant bridge (one per process, registered with Ogre::Root while a System exists).
        CYSEnvironmentProvider& autoParamProvider(void)
        {
            static CYSEnvironmentProvider provider;
            return provider;
        }

        const char* const kMainLightNames[2] = { "#FairyMainLightOne", "#FairyMainLightTwo" };
    }

    //////////////////////////////////////////////////////////////////////////
    // CYSEnvironmentManager
    //////////////////////////////////////////////////////////////////////////
    CYSEnvironmentManager& CYSEnvironmentManager::getSingleton(void)
    {
        static CYSEnvironmentManager manager;
        return manager;
    }
    //-----------------------------------------------------------------------
    CYSEnvironmentManager::CYSEnvironmentManager(void)
        : mSystem(NULL)
        , mListening(false)
        , mHasEnScene(false)
        , mHasSkySphere(false)
        , mTimeOfDay(12.0f)
        , mTimeScale(0)
        , mEnvironmentEnabled(true)
        , mSkyEnabled(true)
        , mHeightFogFallback(true)
        , mApplied(false)
        , mSceneFogMode(Ogre::FOG_NONE)
        , mSceneBackground(Ogre::ColourValue::Black)
        , mSky(NULL)
        , mCySky(NULL)
        , mCyFreeClock(false)
        , mCyClockAllowed(true)
        , mCyDayFraction(0)
        , mDayOfMonth(1)
        , mFixedTimeOfDay(12.0f)
        , mProviderRegistered(false)
    {
        mTimeOfDay = wrapHours(envReal("CYS_TIME_OF_DAY", 12.0f));
        mTimeScale = envReal("CYS_TIME_SCALE", 0.0f);
        if (const char* w = getenv("CYS_WEATHER"))
            mWeather = w;
        mSkyEnabled = envBool("CYS_SKY", true);
        mEnvironmentEnabled = envBool("CYS_ENV", true);
        mHeightFogFallback = envBool("CYS_HEIGHTFOG_FALLBACK", true);
        mEnv.timeOfDay = mTimeOfDay;
        // CYS-SKY: the CY free day clock only when no fixed test time was requested
        mCyClockAllowed = envBool("CYS_SKY_CLOCK", true) && getenv("CYS_TIME_OF_DAY") == NULL;
        mFixedTimeOfDay = mTimeOfDay;
    }
    //-----------------------------------------------------------------------
    CYSEnvironmentManager::~CYSEnvironmentManager()
    {
        // Process exit: OGRE is gone by now, render objects were released by _onSystemDestroyed.
    }
    //-----------------------------------------------------------------------
    void CYSEnvironmentManager::_onSceneLoaded(SceneInfo* scene, const String& sceneFile, const String& groupName)
    {
        _onSceneReset();
        if (mCyFreeClock)               // CYS-SKY: the procedure code re-enables it after loading its scene; a world scene
        {                               // keeps the fixed time (the CY clock phase of the login must not leak into it)
            mCyFreeClock = false;
            mTimeOfDay = mFixedTimeOfDay;
            mEnv.timeOfDay = mTimeOfDay;
        }
        if (!scene)
            return;

        mSceneName = baseName(sceneFile);
        mGroupName = groupName;
        const std::vector<String> groups = lookupGroups(groupName);
        CYSSceneStats& stats = CYSSceneStats::instance();

        // SkySphere: as B SceneInfo::load - create the object when the header names a file, enabled = loaded.
        const CYSSceneHeader& header = scene->mCYSHeader;
        if (header.hasSkySphere && !header.skySphereFile.empty())
        {
            ObjectPtr object = findFirstOfType(scene, CYSSkySphereObject::msType);
            ObjectFactoryManager* factories = ObjectFactoryManager::getSingletonPtr();
            if (!object && factories && factories->hasFactory(CYSSkySphereObject::msType))
            {
                object = factories->createInstance(CYSSkySphereObject::msType);
                String name = header.skySphereObjectName.empty() ? String("#FairySkySphere") : header.skySphereObjectName;
                if (scene->findObjectByName(name))
                    name = scene->generateAutoName(object);
                object->setName(name);
                scene->addObject(object);
            }
            String group, error;
            if (findGroup(header.skySphereFile, groups, group))
                mHasSkySphere = loadSkySphere(header.skySphereFile, group, mSkySphere, &error);
            else
                error = "file not found";
            if (object)
                object->setPropertyAsString("enabled", mHasSkySphere ? "true" : "false");
            if (mHasSkySphere)
                stats.count("SkySphere files loaded");
            else
                stats.problem("SkySphere file not loaded: " + error, header.skySphereFile);
        }

        // EnScene: first object of type "EnScene" (B finds it by type), property config_file.
        ObjectPtr enScene = findFirstOfType(scene, CYSEnSceneObject::msType);
        if (enScene)
        {
            const String file = enScene->getPropertyAsString("config_file");
            String group, error;
            bool loaded = false;
            if (file.empty())
                error = "no config_file";
            else if (findGroup(file, groups, group))
                loaded = loadEnScene(file, group, mEnScene, &error);
            else
                error = "file not found";
            mHasEnScene = loaded && mEnScene.getBaseSky() != NULL;
            enScene->setPropertyAsString("enabled", loaded ? "true" : "false");
            if (loaded)
            {
                stats.count("EnScene files loaded");
                log("EnScene : successfully load EnScene config file '" + file + "'");
            }
            else
            {
                stats.problem("EnScene file not loaded: " + error, file.empty() ? mSceneName : file);
            }
        }

        // Per-scene post-filter parameter files (defaults when absent).
        loadSceneFileParams(mSceneName, groupName, mEnv.sceneFiles);
    }
    //-----------------------------------------------------------------------
    void CYSEnvironmentManager::_onSceneInitialised(System* system)
    {
        if (!system)
            return;
        mSystem = system;
        if (!mListening && system->getRoot())
        {
            system->getRoot()->addFrameListener(this);
            mListening = true;
        }
        // B auto constants (actor lights, PBR / actor ambient, sky-dome ambient) through OgreMain's provider list.
        if (!mProviderRegistered && system->getRoot())
        {
            try
            {
                system->getRoot()->addAutoParamExternalProvider(&autoParamProvider());
                mProviderRegistered = true;
            }
            catch (const Ogre::Exception& e)
            {
                log("auto-constant provider not registered: " + e.getDescription());
            }
        }

        // The scene's own Enviroment values: the keys keep its fog mode (as B) and are restored on disable.
        SceneSnapshot& snap = snapshot();
        snap = SceneSnapshot();
        SceneInfo* sceneInfo = system->getSceneInfo();
        EnviromentObject* env = findEnviroment(sceneInfo);
        mSceneFogMode = env ? env->mFogMode : Ogre::FOG_NONE;
        mSceneBackground = env ? env->mBackgroundColour : Ogre::ColourValue::Black;
        if (env)
        {
            snap.valid = true;
            snap.ambient = env->mAmbientLight;
            snap.fogMode = env->mFogMode;
            snap.fogColour = env->mFogColour;
            snap.fogDensity = env->mFogExpDensity;
            snap.fogStart = env->mFogLinearStart;
            snap.fogEnd = env->mFogLinearEnd;
        }
        for (int i = 0; i < 2; ++i)
        {
            LightObject* light = findLight(sceneInfo, kMainLightNames[i]);
            snap.lights[i].valid = light != NULL;
            if (light)
            {
                snap.lights[i].diffuse = light->mDiffuse;
                snap.lights[i].specular = light->mSpecular;
                snap.lights[i].direction = light->mDirection;
                snap.lights[i].intensity = light->mIntensity;
            }
        }

        mApplied = false;
        rebuildSky();
        update(0);

        char buf[256];
        sprintf(buf, "scene '%s': EnScene %s (%u regions), SkySphere %s, sky elements %u, time %.2f h",
                mSceneName.c_str(), mHasEnScene ? "yes" : "no", (unsigned)mEnScene.regions.size(),
                mHasSkySphere ? "yes" : "no",
                (unsigned)(mSky ? mSky->getNumElements() : (mCySky ? mCySky->getNumElements() : 0)), mTimeOfDay);
        log(buf);
    }
    //-----------------------------------------------------------------------
    void CYSEnvironmentManager::setWind(const Ogre::Vector3& direction, Real strength)
    {
        mEnv.windDirection = direction;
        mEnv.windStrength = strength;
        ++mEnv.revision;
        notifyListeners();
    }
    //-----------------------------------------------------------------------
    void CYSEnvironmentManager::_onSceneReset(void)
    {
        delete mSky;
        mSky = NULL;
        delete mCySky;                  // CYS-SKY
        mCySky = NULL;
        const bool hadData = mHasEnScene || mHasSkySphere || mEnv.source != CYSEnvironment::SOURCE_NONE;
        mHasEnScene = false;
        mHasSkySphere = false;
        mEnScene.clear();
        mSkySphere.clear();
        mSceneName.clear();

        const unsigned long revision = mEnv.revision;
        mEnv = CYSEnvironment();
        mEnv.revision = revision + 1;
        mEnv.timeOfDay = mTimeOfDay;
        mApplied = false;
        mAppliedKey = CYSEnvKey();
        mLastKey = CYSEnvKey();
        snapshot() = SceneSnapshot();
        CYSScene::setFakeLightGlobalIntensity(1.0f);

        if (hadData)
        {
            for (size_t i = 0; i < mListeners.size(); ++i)
                mListeners[i]->environmentReset();
        }
    }
    //-----------------------------------------------------------------------
    void CYSEnvironmentManager::_onSystemDestroyed(System* system)
    {
        if (mSystem && system != mSystem)
            return;
        _onSceneReset();
        if (mListening && system && system->getRoot())
            system->getRoot()->removeFrameListener(this);
        mListening = false;
        if (mProviderRegistered && system && system->getRoot())
            system->getRoot()->removeAutoParamExternalProvider(&autoParamProvider());
        mProviderRegistered = false;
        mSystem = NULL;
    }
    //-----------------------------------------------------------------------
    void CYSEnvironmentManager::setCyFreeClock(bool running)
    {
        // CYS-SKY
        const bool was = mCyFreeClock;
        mCyFreeClock = running && mCyClockAllowed;
        if (mCyFreeClock)
            mTimeOfDay = std::min(mCyDayFraction * 24.0f, 23.9f);
        else if (was)
            mTimeOfDay = mFixedTimeOfDay;
        if (mSystem && (mCyFreeClock || was))
            update(0);
        log(String("CYS-SKY: CY day clock ") + (mCyFreeClock ? "running (60 s per day)" : "stopped"));
    }
    //-----------------------------------------------------------------------
    void CYSEnvironmentManager::setWorldTime(int dayOfMonth, Real dayFraction)
    {
        // CYS-SKY
        mDayOfMonth = dayOfMonth;
        const bool pinned = getenv("CYS_TIME_OF_DAY") != NULL;
        const Real before = mTimeOfDay;
        if (!pinned)
            setTimeOfDay(dayFraction * 24.0f);
        Ogre::Vector3 sun = mEnv.sunDirection;          // SkySphere / no sky: the lighting sun
        if (mHasEnScene && mEnScene.getBaseSky())         // EnScene: the sun of the sky constants (SUN_POSITION)
            sun = CYSSkyCyRenderer::sunDirection(mEnScene.getBaseSky()->sun, mTimeOfDay);
        char buf[240];
        sprintf(buf, "CYS-SKY: world time day %d fraction %.4f -> %.3f h (was %.3f h%s), sun direction (%.3f, %.3f, %.3f)",
                dayOfMonth, dayFraction, mTimeOfDay, before, pinned ? ", CYS_TIME_OF_DAY pins it" : "", sun.x, sun.y, sun.z);
        log(buf);
    }
    //-----------------------------------------------------------------------
    void CYSEnvironmentManager::setTimeOfDay(Real hours)
    {
        mCyFreeClock = false;
        mTimeOfDay = wrapHours(hours);
        mFixedTimeOfDay = mTimeOfDay;
        if (mSystem)
            update(0);
    }
    //-----------------------------------------------------------------------
    void CYSEnvironmentManager::setWeather(const String& name)
    {
        if (mWeather == name)
            return;
        mWeather = name;
        if (mSystem && mHasSkySphere && !mHasEnScene)
            rebuildSky();
        if (mSystem)
            update(0);
    }
    //-----------------------------------------------------------------------
    void CYSEnvironmentManager::setEnvironmentEnabled(bool enabled)
    {
        if (mEnvironmentEnabled == enabled)
            return;
        mEnvironmentEnabled = enabled;
        mApplied = false;
        if (!mSystem)
            return;
        if (!enabled)
        {
            // Restore the scene's own values.
            SceneSnapshot& snap = snapshot();
            SceneInfo* sceneInfo = mSystem->getSceneInfo();
            if (snap.valid)
            {
                if (EnviromentObject* env = findEnviroment(sceneInfo))
                    env->_cysApplyEnvironment(snap.ambient, snap.fogMode, snap.fogColour, snap.fogDensity,
                                              snap.fogStart, snap.fogEnd);
            }
            for (int i = 0; i < 2; ++i)
            {
                LightObject* light = findLight(sceneInfo, kMainLightNames[i]);
                if (!light || !snap.lights[i].valid)
                    continue;
                light->setProperty("diffuse", Variant(snap.lights[i].diffuse));
                light->setProperty("specular", Variant(snap.lights[i].specular));
                light->setProperty("direction", Variant(snap.lights[i].direction));
                light->setProperty("intensity", Variant(snap.lights[i].intensity));
            }
            CYSScene::setFakeLightGlobalIntensity(1.0f);
        }
        else
        {
            update(0);
        }
    }
    //-----------------------------------------------------------------------
    void CYSEnvironmentManager::setSkyEnabled(bool enabled)
    {
        if (mSkyEnabled == enabled)
            return;
        mSkyEnabled = enabled;
        if (mSystem)
            rebuildSky();
    }
    //-----------------------------------------------------------------------
    void CYSEnvironmentManager::setHeightFogFallbackEnabled(bool enabled)
    {
        if (mHeightFogFallback == enabled)
            return;
        mHeightFogFallback = enabled;
        mApplied = false;
        if (mSystem)
            update(0);
    }
    //-----------------------------------------------------------------------
    void CYSEnvironmentManager::addListener(CYSEnvironmentListener* listener)
    {
        if (listener && std::find(mListeners.begin(), mListeners.end(), listener) == mListeners.end())
            mListeners.push_back(listener);
    }
    //-----------------------------------------------------------------------
    void CYSEnvironmentManager::removeListener(CYSEnvironmentListener* listener)
    {
        mListeners.erase(std::remove(mListeners.begin(), mListeners.end(), listener), mListeners.end());
    }
    //-----------------------------------------------------------------------
    bool CYSEnvironmentManager::frameStarted(const Ogre::FrameEvent& evt)
    {
        update(evt.timeSinceLastFrame);
        return true;
    }
    //-----------------------------------------------------------------------
    void CYSEnvironmentManager::update(Real dt)
    {
        if (!mSystem)
            return;
        if (dt > 0)
        {


            mCyDayFraction += dt / 60.0f;
            mCyDayFraction -= (Real)(int)mCyDayFraction;
            if (mCyFreeClock)
                mTimeOfDay = std::min(mCyDayFraction * 24.0f, 23.9f);
            else if (mTimeScale != 0)
                mTimeOfDay = wrapHours(mTimeOfDay + dt * mTimeScale);
            mEnv.windTime += dt;
        }

        Ogre::Camera* camera = mSystem->getCamera();
        const Ogre::Vector3 viewPos = camera ? camera->getDerivedPosition() : Ogre::Vector3::ZERO;

        CYSEnvKey key;
        if (mEnvironmentEnabled && sampleKey(key, viewPos))
        {
            publish(key, viewPos);
            applyToScene(false);
        }
        else
        {
            mEnv.timeOfDay = mTimeOfDay;
        }

        if (mSky)
            mSky->update(dt, mEnv);
        if (mCySky)                     // CYS-SKY
            mCySky->update(dt, mEnv);





        static const bool brightnessParity = []() {
            const char* v = getenv("CYS_PARITY_BRIGHTNESS");
            return !(v && v[0] == '0');
        }();
        Ogre::SceneManager* sm = mSystem->getSceneManager();
        if (brightnessParity && sm)
        {
            const Ogre::ColourValue& a = sm->getAmbientLight();
            Real sum = a.r + a.g + a.b;
            SceneInfo* sceneInfo = mSystem->getSceneInfo();
            for (int i = 0; i < 2; ++i)
            {
                LightObject* light = findLight(sceneInfo, kMainLightNames[i]);
                Ogre::Light* ogreLight = light ? light->getLight() : NULL;
                if (ogreLight)
                {
                    const Ogre::ColourValue& d = ogreLight->getDiffuseColour();
                    sum += d.r + d.g + d.b;
                }
            }
            sm->setBrightness(sum / 9.0f);
        }
    }
    //-----------------------------------------------------------------------
    bool CYSEnvironmentManager::sampleKey(CYSEnvKey& key, const Ogre::Vector3& viewPos)
    {
        mEnv.timeOfDay = mTimeOfDay;
        mEnv.regionName.clear();
        mEnv.regionWeight = 0;
        mEnv.weather.clear();

        if (mHasEnScene)
        {
            const CYSEnSky* base = mEnScene.getBaseSky();
            if (base && !base->keys.empty())
            {
                key = base->keys.sample(mTimeOfDay);
                // Positional regions (INF: weight 1 inside the polygon, fading over maxAffectDistance).
                const CYSEnRegion* best = NULL;
                Real bestWeight = 0;
                for (size_t i = 0; i < mEnScene.regions.size(); ++i)
                {
                    const CYSEnRegion& region = mEnScene.regions[i];
                    if (region.polygons.empty() || region.sky.keys.empty() || &region.sky == base)
                        continue;
                    const Real w = region.weightAt(viewPos.x, viewPos.z);
                    if (w > bestWeight)
                    {
                        bestWeight = w;
                        best = &region;
                    }
                }
                if (best)
                {
                    key = CYSEnvKey::lerp(key, best->sky.keys.sample(mTimeOfDay), bestWeight);
                    mEnv.regionName = best->name;
                    mEnv.regionWeight = bestWeight;
                }
                mEnv.source = CYSEnvironment::SOURCE_ENSCENE;
                return true;
            }
        }
        if (mHasSkySphere)
        {
            const CYSSkyWeather* weather = mSkySphere.findWeather(mWeather);
            if (weather && !weather->keys.empty())
            {
                key = weather->keys.sample(mTimeOfDay);
                mEnv.weather = weather->name;
                mEnv.source = CYSEnvironment::SOURCE_SKYSPHERE;
                return true;
            }
        }
        mEnv.source = CYSEnvironment::SOURCE_NONE;
        return false;
    }
    //-----------------------------------------------------------------------
    void CYSEnvironmentManager::publish(const CYSEnvKey& key, const Ogre::Vector3& viewPos)
    {
        mLastKey = key;
        SceneInfo* sceneInfo = mSystem ? mSystem->getSceneInfo() : NULL;

        mEnv.ambient = key.ambient;
        mEnv.lightOneDiffuse = key.lightOne;
        mEnv.lightOneSpecular = key.lightOneSpecular;
        mEnv.lightOneIntensity = key.lightOneIntensity;
        mEnv.lightTwoDiffuse = key.lightTwo;
        mEnv.lightTwoSpecular = key.lightTwoSpecular;
        mEnv.lightTwoIntensity = key.lightTwoIntensity;

        // Directions: the key's when set, else the scene's main lights (B applies non-zero directions only).
        Ogre::Vector3 dirs[2] = { key.lightOneDirection, key.lightTwoDirection };
        for (int i = 0; i < 2; ++i)
        {
            if (dirs[i] == Ogre::Vector3::ZERO)
            {
                LightObject* light = findLight(sceneInfo, kMainLightNames[i]);
                SceneSnapshot& snap = snapshot();
                if (snap.lights[i].valid)
                    dirs[i] = snap.lights[i].direction;
                else if (light)
                    dirs[i] = light->mDirection;
            }
            if (dirs[i].squaredLength() < 1e-12f)
                dirs[i] = Ogre::Vector3(0, -1, 0);
            dirs[i].normalise();
        }
        mEnv.lightOneDirection = dirs[0];
        mEnv.lightTwoDirection = dirs[1];
        mEnv.sunDirection = -dirs[0];
        mEnv.sunColour = key.lightOne * key.lightOneIntensity;
        mEnv.sunColour.a = 1.0f;

        mEnv.pbrAmbient = key.pbrAmbient;
        mEnv.actorLightOne = key.actorLightOne;
        mEnv.actorLightOneIntensity = key.actorLightOneIntensity;
        mEnv.actorLightTwo = key.actorLightTwo;
        mEnv.actorLightTwoIntensity = key.actorLightTwoIntensity;
        mEnv.actorAmbient = key.actorAmbient;
        mEnv.selectActorLight = key.selectActorLight;
        mEnv.skyDomeAmbient = Ogre::Vector4(key.skyDomeAmbientColour.x, key.skyDomeAmbientColour.y,
                                            key.skyDomeAmbientColour.z, key.skyDomeAmbientStrength);
        mEnv.lightSpecularIntensity = key.lightSpecularIntensity;
        mEnv.fakePointLightIntensity = key.fakePointLightIntensity;
        mEnv.shadowStrength = key.shadowStrength;
        mEnv.pbrShadowStrength = key.pbrShadowStrength;

        mEnv.fogMode = mSceneFogMode;
        mEnv.fogColour = key.fog;
        mEnv.fogStart = key.fogNear;
        mEnv.fogEnd = key.fogFar;
        const SceneSnapshot& snap = snapshot();
        mEnv.fogDensity = snap.valid ? snap.fogDensity : 0.001f;
        mEnv.skyFogColour = key.hasSkyFog ? key.skyFog : key.fog;

        mEnv.heightFogEnabled = key.heightFogEnabled;
        mEnv.heightFog = key.heightFog;

        mEnv.warmColour = key.warmColour;
        mEnv.coldColour = key.coldColour;
        mEnv.enhanceContrast = key.enhanceContrast;
        mEnv.overlayImage = key.overlayImage;
        mEnv.radialBlur = key.radialBlur;

        computeFogFallback(viewPos);
    }
    //-----------------------------------------------------------------------
    void CYSEnvironmentManager::computeFogFallback(const Ogre::Vector3& viewPos)
    {
        mEnv.appliedFogMode = mEnv.fogMode;
        mEnv.appliedFogColour = mEnv.fogColour;
        mEnv.appliedFogStart = mEnv.fogStart;
        mEnv.appliedFogEnd = mEnv.fogEnd;
        mEnv.appliedFogDensity = mEnv.fogDensity;
        if (!mHeightFogFallback || !mEnv.heightFogEnabled)
            return;

        // Standard OGRE fog cannot fog by height; fit one linear fog to the combined fog seen along a horizontal
        // view ray at eye height: 1 - (1 - scene fog(d)) * (1 - height fog(eye y, d)) (INF approximation of the
        // B HeightFog pass on top of the linear fog).
        const CYSHeightFogParams& h = mEnv.heightFog;
        const Ogre::FogMode mode = mEnv.fogMode;
        const Real start = mEnv.fogStart, end = mEnv.fogEnd, density = mEnv.fogDensity;
        struct Local
        {
            static Real linear(Ogre::FogMode m, Real s, Real e, Real dens, Real d)
            {
                switch (m)
                {
                case Ogre::FOG_LINEAR:
                    return e > s ? saturate((d - s) / (e - s)) : (d >= e ? 1.0f : 0.0f);
                case Ogre::FOG_EXP:
                    return 1.0f - std::exp(-dens * d);
                case Ogre::FOG_EXP2:
                    return 1.0f - std::exp(-(dens * d) * (dens * d));
                default:
                    return 0.0f;
                }
            }
        };
        const Real y = viewPos.y;
        const Real maxDistance = std::max(end, 100000.0f);
        Real d10 = -1, d90 = -1;
        for (Real d = 10.0f; d <= maxDistance; d *= 1.15f)
        {
            const Real f = 1.0f - (1.0f - Local::linear(mode, start, end, density, d)) * (1.0f - h.evaluate(y, d));
            if (d10 < 0 && f >= 0.1f)
                d10 = d;
            if (f >= 0.9f)
            {
                d90 = d;
                break;
            }
        }
        if (d10 < 0)
            return;         // the height fog never shows along the horizon: keep the scene fog
        if (d90 < 0)
            d90 = maxDistance;
        const Real span = std::max(1.0f, (d90 - d10) / 0.8f);
        const Real fitStart = std::max(0.0f, d10 - 0.1f * span);
        const Real mid = 0.5f * (d10 + d90);
        const Real wLinear = Local::linear(mode, start, end, density, mid);
        const Real wHeight = h.evaluate(y, mid);
        const Real t = wHeight / (wLinear + wHeight + 1e-6f);
        const Ogre::ColourValue heightColour = lerp(h.fogColour, h.dirInscatteringColour, 0.25f);

        mEnv.appliedFogMode = Ogre::FOG_LINEAR;
        mEnv.appliedFogStart = fitStart;
        mEnv.appliedFogEnd = fitStart + span;
        mEnv.appliedFogColour = lerp(mEnv.fogColour, heightColour, t);
        mEnv.appliedFogColour.a = 1.0f;
    }
    //-----------------------------------------------------------------------
    void CYSEnvironmentManager::applyToScene(bool force)
    {
        if (!mSystem || mEnv.source == CYSEnvironment::SOURCE_NONE)
            return;
        SceneInfo* sceneInfo = mSystem->getSceneInfo();

        static Ogre::FogMode sAppliedMode = Ogre::FOG_NONE;
        static Ogre::ColourValue sAppliedColour;
        static Real sAppliedStart = 0, sAppliedEnd = 0;
        const bool keyChanged = force || !mApplied || significantChange(mLastKey, mAppliedKey);
        const bool fogChanged = keyChanged || sAppliedMode != mEnv.appliedFogMode ||
            differs(sAppliedColour, mEnv.appliedFogColour) || differs(sAppliedStart, mEnv.appliedFogStart, 1.0f) ||
            differs(sAppliedEnd, mEnv.appliedFogEnd, 1.0f);
        if (!keyChanged && !fogChanged)
            return;

        // Enviroment object: ambient + fog (B sets "ambient", "fog.colour", "fog.linear start/end").
        EnviromentObject* env = findEnviroment(sceneInfo);
        if (env)
        {
            env->_cysApplyEnvironment(mEnv.ambient, mEnv.appliedFogMode, mEnv.appliedFogColour, mEnv.appliedFogDensity,
                                      mEnv.appliedFogStart, mEnv.appliedFogEnd);
        }
        else if (Ogre::SceneManager* sm = mSystem->getSceneManager())
        {
            sm->setAmbientLight(mEnv.ambient);
            sm->setFog(mEnv.appliedFogMode, mEnv.appliedFogColour, mEnv.appliedFogDensity, mEnv.appliedFogStart,
                       mEnv.appliedFogEnd);
            if (Ogre::Viewport* vp = mSystem->getViewport())
                vp->setBackgroundColour(mEnv.appliedFogMode == Ogre::FOG_NONE ? mSceneBackground : mEnv.appliedFogColour);
        }
        sAppliedMode = mEnv.appliedFogMode;
        sAppliedColour = mEnv.appliedFogColour;
        sAppliedStart = mEnv.appliedFogStart;
        sAppliedEnd = mEnv.appliedFogEnd;

        if (keyChanged)
        {
            // Main lights: diffuse, specular, intensity, and the direction when the key has one.
            const CYSEnvKey& key = mLastKey;
            for (int i = 0; i < 2; ++i)
            {
                LightObject* light = findLight(sceneInfo, kMainLightNames[i]);
                if (!light)
                    continue;
                light->setProperty("diffuse", Variant(i == 0 ? key.lightOne : key.lightTwo));
                light->setProperty("specular", Variant(i == 0 ? key.lightOneSpecular : key.lightTwoSpecular));
                light->setProperty("intensity", Variant(i == 0 ? key.lightOneIntensity : key.lightTwoIntensity));
                const Ogre::Vector3& dir = i == 0 ? key.lightOneDirection : key.lightTwoDirection;
                if (dir != Ogre::Vector3::ZERO)
                    light->setProperty("direction", Variant(dir));
            }
            // Effects remember the scene light colours to restore them after a light flash.
            if (EffectManager* effects = EffectManager::getSingletonPtr())
            {
                if (MainSceneLight* mainLight = effects->getMainSceneLight())
                    mainLight->updateLightInfo();
            }
            CYSScene::setFakeLightGlobalIntensity(mEnv.source == CYSEnvironment::SOURCE_ENSCENE ?
                                                  key.fakePointLightIntensity : 1.0f);
            mAppliedKey = key;
        }
        mApplied = true;
        ++mEnv.revision;
        notifyListeners();
    }
    //-----------------------------------------------------------------------
    void CYSEnvironmentManager::notifyListeners(void)
    {
        for (size_t i = 0; i < mListeners.size(); ++i)
            mListeners[i]->environmentChanged(mEnv);
    }
    //-----------------------------------------------------------------------
    void CYSEnvironmentManager::rebuildSky(void)
    {
        delete mSky;
        mSky = NULL;
        delete mCySky;
        mCySky = NULL;
        if (!mSkyEnabled || !mSystem || !mSystem->getSceneManager())
            return;
        // CYS-SKY: CY shader sky (EnScene.hlsl / SkySphereLayer.hlsl, Docs/specs/render/sky-enscene-cy_vi.md); A/B switch
        // CYS_SKY_SHADER=0 keeps the former fixed-function CYSSkyRenderer.
        if ((mHasEnScene || mHasSkySphere) && CYSSkyCyRenderer::isEnabled())
        {
            try
            {
                mCySky = new CYSSkyCyRenderer(mSystem);
                if (mHasEnScene)
                {
                    if (const CYSEnSky* sky = mEnScene.getBaseSky())
                        mCySky->buildEnScene(*sky, mSceneName);
                }
                else
                {
                    mCySky->buildSkySphere(mSkySphere, mSkySphere.findWeather(mWeather), mSceneName);
                }
            }
            catch (const Ogre::Exception& e)
            {
                log("CYS-SKY: CY shader sky not built (" + e.getDescription() + "), using the fixed-function sky");
                delete mCySky;
                mCySky = NULL;
            }
            if (mCySky && !mCySky->isEmpty())
                return;
            delete mCySky;
            mCySky = NULL;
        }
        try
        {
            if (mHasEnScene)
            {
                if (const CYSEnSky* sky = mEnScene.getBaseSky())
                {
                    mSky = new CYSSkyRenderer(mSystem);
                    mSky->buildEnScene(*sky, mSceneName);
                }
            }
            else if (mHasSkySphere)
            {
                mSky = new CYSSkyRenderer(mSystem);
                mSky->buildSkySphere(mSkySphere, mSkySphere.findWeather(mWeather), mSceneName);
            }
        }
        catch (const Ogre::Exception& e)
        {
            log("sky not built: " + e.getDescription());
            delete mSky;
            mSky = NULL;
        }
        if (mSky && mSky->isEmpty())
        {
            delete mSky;
            mSky = NULL;
        }
    }
}
