#ifndef __CYS_ENVIRONMENT_H__
#define __CYS_ENVIRONMENT_H__
















#include "CYSEnSceneData.h"
#include "CYSSkySphereData.h"
#include "CYSSceneFiles.h"

#include <OgreFrameListener.h>
#include <OgreCommon.h>

namespace WX
{
    class System;
    class SceneInfo;
    class CYSSkyRenderer;
    class CYSSkyCyRenderer;

    struct CYSEnvironment
    {
        enum Source
        {
            SOURCE_NONE,        ///< neither EnScene nor SkySphere keys: the 0.85 Enviroment object rules
            SOURCE_ENSCENE,
            SOURCE_SKYSPHERE,
        };

        unsigned long revision;         ///< incremented whenever a published value changed
        Source source;
        Real timeOfDay;                 ///< hours [0, 24)
        String weather;                 ///< SkySphere weather in use
        String regionName;              ///< EnScene region blended in ("" = base sky only)
        Real regionWeight;

        // Scene lighting as applied to Enviroment "ambient" and the two main lights.
        Ogre::ColourValue ambient;
        Ogre::ColourValue lightOneDiffuse, lightOneSpecular;
        Real lightOneIntensity;
        Ogre::Vector3 lightOneDirection;        ///< direction the light travels (normalised)
        Ogre::ColourValue lightTwoDiffuse, lightTwoSpecular;
        Real lightTwoIntensity;
        Ogre::Vector3 lightTwoDirection;
        Ogre::Vector3 sunDirection;             ///< unit vector from the scene towards the sun (= -lightOneDirection)
        Ogre::ColourValue sunColour;            ///< lightOneDiffuse * lightOneIntensity

        // B-only SceneManager state (auto constants actor_*, pbr ambient, skydome_ambient_color, 01 §4).
        Ogre::ColourValue pbrAmbient;           ///< setPbrAmbientLight
        Ogre::ColourValue actorLightOne;        ///< setActorLightOne(colour, actorLightOneIntensity)
        Real actorLightOneIntensity;
        Ogre::ColourValue actorLightTwo;        ///< setActorLightTwo(colour, actorLightTwoIntensity)
        Real actorLightTwoIntensity;
        Ogre::ColourValue actorAmbient;         ///< setActAmbientLight
        Ogre::ColourValue selectActorLight;     ///< renderer "selected actor" light colour
        Ogre::Vector4 skyDomeAmbient;           ///< setSkyDomeAmbientColor(Vector4(rgb, strength)); shaders use rgb*w
        Real lightSpecularIntensity;
        Real fakePointLightIntensity;           ///< FakeLight global multiplier
        Real shadowStrength;                    ///< shadow config +0x44 -> shadow_param.x
        Real pbrShadowStrength;                 ///< shadow config +0x48 -> shadow_param.y

        // Fog: EnvKey values and what was finally given to OGRE (after the height-fog fallback).
        Ogre::FogMode fogMode;
        Ogre::ColourValue fogColour;
        Real fogStart, fogEnd, fogDensity;
        Ogre::ColourValue skyFogColour;         ///< SkySphere sky_fog (= fogColour otherwise)
        Ogre::FogMode appliedFogMode;
        Ogre::ColourValue appliedFogColour;
        Real appliedFogStart, appliedFogEnd, appliedFogDensity;

        // Height fog (B HeightFog post filter; .hfog + EnvKey height_fog_enabled/param).
        bool heightFogEnabled;
        CYSHeightFogParams heightFog;

        // EnvKey grading keys (inactive in B, 02 §2).
        Ogre::Vector3 warmColour, coldColour, enhanceContrast, overlayImage;
        Ogre::Vector2 radialBlur;

        // Wind for vegetation / water shaders (no B scene data: defaults, advanced with the clock).
        Ogre::Vector3 windDirection;
        Real windStrength;
        Real windTime;                          ///< seconds since the scene started

        // Per-scene post-filter files.
        CYSSceneFileParams sceneFiles;

        CYSEnvironment(void);

        /// The process-wide state (= CYSEnvironmentManager::getSingleton().getEnvironment()).
        static const CYSEnvironment& current(void);
    };

    /// Notified after every change (e.g. WXRender pushes the B-only values into its SceneManager setters).
    class CYSEnvironmentListener
    {
    public:
        virtual ~CYSEnvironmentListener() {}
        virtual void environmentChanged(const CYSEnvironment& env) = 0;
        virtual void environmentReset(void) {}
    };

    class CYSEnvironmentManager : public Ogre::FrameListener
    {
    public:
        static CYSEnvironmentManager& getSingleton(void);

        // ---- engine hooks (SceneInfo::load, System::_postprocessScene / resetScene / ~System) ----
        void _onSceneLoaded(SceneInfo* scene, const String& sceneFile, const String& groupName);
        void _onSceneInitialised(System* system);
        void _onSceneReset(void);
        void _onSystemDestroyed(System* system);

        // ---- time of day / weather ----
        void setTimeOfDay(Real hours);
        Real getTimeOfDay(void) const { return mTimeOfDay; }
        /// Game hours per real second (0 = frozen, 1/3600 = real time).
        void setTimeScale(Real gameHoursPerSecond) { mTimeScale = gameHoursPerSecond; }
        Real getTimeScale(void) const { return mTimeScale; }
        void setWeather(const String& name);
        const String& getWeather(void) const { return mWeather; }
        /// Wind of the vegetation / water shaders (wind_control_params = dir x, dir z, strength). B scenes carry no
        /// wind: the default is the B shader initialiser, direction (1, 0, 0) and strength 16.
        void setWind(const Ogre::Vector3& direction, Real strength);




        void setCyFreeClock(bool running);


        void setWorldTime(int dayOfMonth, Real dayFraction);
        int getDayOfMonth(void) const { return mDayOfMonth; }
        bool isCyFreeClock(void) const { return mCyFreeClock; }

        // ---- switches ----
        void setEnvironmentEnabled(bool enabled);
        bool isEnvironmentEnabled(void) const { return mEnvironmentEnabled; }
        void setSkyEnabled(bool enabled);
        bool isSkyEnabled(void) const { return mSkyEnabled; }
        void setHeightFogFallbackEnabled(bool enabled);
        bool isHeightFogFallbackEnabled(void) const { return mHeightFogFallback; }

        // ---- state ----
        const CYSEnvironment& getEnvironment(void) const { return mEnv; }
        bool hasEnScene(void) const { return mHasEnScene; }
        const CYSEnSceneData& getEnSceneData(void) const { return mEnScene; }
        bool hasSkySphere(void) const { return mHasSkySphere; }
        const CYSSkySphereData& getSkySphereData(void) const { return mSkySphere; }
        const String& getSceneName(void) const { return mSceneName; }
        const CYSSkyRenderer* getSkyRenderer(void) const { return mSky; }
        const CYSSkyCyRenderer* getCySkyRenderer(void) const { return mCySky; }     ///< CYS-SKY

        void addListener(CYSEnvironmentListener* listener);
        void removeListener(CYSEnvironmentListener* listener);

        /// Re-samples the keys and applies them now (camera position from the system camera).
        void update(Real dt);

        bool frameStarted(const Ogre::FrameEvent& evt);

    private:
        CYSEnvironmentManager(void);
        ~CYSEnvironmentManager();

        bool sampleKey(CYSEnvKey& key, const Ogre::Vector3& viewPos);
        void publish(const CYSEnvKey& key, const Ogre::Vector3& viewPos);
        void applyToScene(bool force);
        void computeFogFallback(const Ogre::Vector3& viewPos);
        void rebuildSky(void);
        void notifyListeners(void);

        System* mSystem;
        bool mListening;
        String mSceneName;
        String mGroupName;

        bool mHasEnScene;
        CYSEnSceneData mEnScene;
        bool mHasSkySphere;
        CYSSkySphereData mSkySphere;

        Real mTimeOfDay;
        Real mTimeScale;
        String mWeather;
        bool mEnvironmentEnabled;
        bool mSkyEnabled;
        bool mHeightFogFallback;

        CYSEnvironment mEnv;
        CYSEnvKey mLastKey;             ///< key published last
        CYSEnvKey mAppliedKey;          ///< key given to the lights last
        bool mApplied;
        Ogre::FogMode mSceneFogMode;        ///< fog mode of the scene's Enviroment object (keys keep it, as B)
        Ogre::ColourValue mSceneBackground;

        CYSSkyRenderer* mSky;
        CYSSkyCyRenderer* mCySky;       ///< CYS-SKY: sky with the CY shaders (CYS_SKY_SHADER, default)
        bool mCyFreeClock;              ///< CYS-SKY: CY Render.dll day clock running (procedure scenes)
        bool mCyClockAllowed;           ///< CYS_SKY_CLOCK / CYS_TIME_OF_DAY not set
        Real mCyDayFraction;            ///< CY clock value (day fraction), process-wide like DAT_1803b5d68
        int mDayOfMonth;                ///< CYS-SKY: lunar date given with the world time (SkySphere moon)
        Real mFixedTimeOfDay;           ///< CYS-SKY: time restored when the CY clock stops (default / setTimeOfDay)
        std::vector<CYSEnvironmentListener*> mListeners;
        bool mProviderRegistered;       ///< CYSEnvironmentProvider registered with Ogre::Root
    };
}

#endif // __CYS_ENVIRONMENT_H__
