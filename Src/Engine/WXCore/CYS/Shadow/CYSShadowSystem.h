#ifndef __CYS_SHADOW_SYSTEM_H__
#define __CYS_SHADOW_SYSTEM_H__

// CY-Source (shadow agent): cascaded shadow maps for the WX/Fairy renderer (Docs\specs\render\03-shadows.md).
//
// One PF_FLOAT32_R atlas "CYS/Shadow/0" of (tile * cascades) x tile texels is created by initialise() and kept for
// the life of the renderer: nothing is allocated per scene (Docs\08-BAY-VA-QUY-TAC_vi.md §3.7). Render textures
// update before windows, so every frame, before the main view renders, the atlas update:
//   1. takes the light direction: explicit > Ogre::Light > scene environment (EnScene/SkySphere EnvKey, main light
//      one) > brightest directional light, clamped to a minimum elevation and followed with a small hysteresis;
//   2. splits [near, max distance] of the fitting camera (the game camera) into cascades (practical log/linear
//      scheme, or explicit splits);
//   3. fits each cascade with the bounding sphere of its frustum slice - its size does not depend on the camera
//      orientation - and snaps its centre to the texel grid of a world-anchored light space: moving or turning
//      the camera never shimmers;
//   4. renders each cascade into its tile: one light view for all tiles, a per-tile orthographic projection one
//      texel larger than the region receivers use, frustum culling per cascade camera, and the caster technique
//      swapped in by CYSShadowCasters (static / skinned / alpha-tested);
//   5. publishes CYSShadowParams to Ogre through an AutoParamExternalProvider (shadow_*, isystem_userdata.x/.w,
//      the constants client_GL's ShaderLib/CalcShadow.inc reads) and to an optional extra sink.
//
// Integration (game / WXRender):
//   WX::CYSShadowConfig cfg;               // B defaults: CSM, 4 cascades, tile 4096
//   cfg.applyFile(systemCfgPath);          // Gfx_Shadow* keys, read once at start-up
//   CYS::MaterialSystem::getSingleton().setGlobalDefine("SHADOWMAP_TYPE", toString(cfg.shaderType()));
//   ... resources parsed (MaterialTemplates.zip provides the Depth_* caster programs) ...
//   WX::CYSShadowSystem& shadows = WX::CYSShadowSystem::getSingleton();
//   shadows.initialise(cfg);               // after the render system and the resource groups are up
//   shadows.attach(system->getSceneManager(), system->getCamera());
//   WX::LogicModelManager::getSingleton().setShadowCastable(true);   // actors cast (default false in WX)
//   ...
//   shadows.shutdown();                    // before Ogre::Root is deleted

#include <OgrePrerequisites.h>

#include "CYSShadowCasters.h"
#include "CYSShadowConfig.h"
#include "CYSShadowParams.h"

#include <OgreRenderTargetListener.h>
#include <OgreVector3.h>

namespace Ogre
{
    class Camera;
    class Light;
    class Rectangle2D;
    class RenderTexture;
    class SceneManager;
    class SceneNode;
    class Viewport;
}

namespace WX
{
    class CYSShadowSystem : public Ogre::RenderTargetListener
    {
    public:
        struct Stats
        {
            double cpuMs;                               ///< CPU time of the last atlas update (fit + cull + submit)
            size_t casters[CYS_SHADOW_MAX_CASCADES];    ///< renderables drawn per tile in the last update
            unsigned long updates;

            Stats(void);
        };

        static CYSShadowSystem& getSingleton(void);

        /** Creates the atlas and the caster programs (render system and resource groups must be up). Calling it
            again with another config only reallocates the atlas when the tile size or the number of tiles
            changes. resourceGroup holds the caster materials, the atlas and the media programs
            (CYSShadowCaster.hlsl, CYSShadowDebug.hlsl, CYSShadowLib.inc). */
        bool initialise(const CYSShadowConfig& config, const Ogre::String& resourceGroup = "CYSShadow");
        /// Releases everything; call before Ogre::Root is deleted.
        void shutdown(void);
        bool isInitialised(void) const { return mInitialised; }

        /// Scene manager and camera whose view the cascades cover (creates the cascade cameras).
        void attach(Ogre::SceneManager* sceneManager, Ogre::Camera* camera);
        /// Before the scene manager is destroyed.
        void detach(void);
        /// The camera the cascades are fitted to (normally the rendering camera).
        void setCamera(Ogre::Camera* camera);
        Ogre::Camera* getCamera(void) const { return mCamera; }
        Ogre::SceneManager* getSceneManager(void) const { return mSceneManager; }

        /// Enable / disable without releasing the atlas (disabled receivers are fully lit).
        void setEnabled(bool enabled);
        bool isEnabled(void) const { return mEnabled; }
        /// The atlas renders this frame (enabled, initialised, attached).
        bool isActive(void) const;
        /// Options menu: reallocates the atlas; never called per scene.
        bool setMapSize(unsigned int size);
        void setMode(CYSShadowConfig::Mode mode);
        void setFit(CYSShadowConfig::Fit fit) { mConfig.fit = fit; }
        /// World units; negative = automatic from the texel size of the coarsest cascade.
        void setBias(Ogre::Real constBias, Ogre::Real normalBias);
        void setSoftness(int radius);
        void setMaxDistance(Ogre::Real distance);
        /// CYS-LOOK: caster range kept above the receivers (CY setShadowDis: 8000 in the world, 18000 at the login scene)
        void setBackoff(Ogre::Real backoff) { mConfig.backoff = backoff; }
        void setDebugView(bool on);
        bool getDebugView(void) const { return mDebugView; }

        void setLightDirection(const Ogre::Vector3& direction);
        void clearLightDirection(void);
        void setLight(Ogre::Light* light);
        /// Read the sun / EnvKey shadow strengths from WX::CYSEnvironment (default on)
        void setUseEnvironment(bool on) { mUseEnvironment = on; }

        /// Extra receiver of every update (tests); the Ogre provider is always fed.
        void setParamSink(CYSShadowParamSink* sink) { mSink = sink; }
        const CYSShadowParams& getParams(void) const { return mParams; }
        const CYSShadowConfig& getConfig(void) const { return mConfig; }
        const Stats& getStats(void) const { return mStats; }
        Ogre::RenderTexture* getAtlasTarget(void) const { return mTarget; }
        const Ogre::String& getTextureName(void) const { return mParams.textureName; }
        /// Video memory of the atlas: R32F colour + the D24S8 depth buffer D3D9 pairs with it.
        size_t getAtlasBytes(void) const;
        const Ogre::String& getCasterProgramSource(void) const { return mCasters.getProgramSource(); }

        // Ogre::RenderTargetListener (the atlas)
        void preRenderTargetUpdate(const Ogre::RenderTargetEvent& evt);
        void postRenderTargetUpdate(const Ogre::RenderTargetEvent& evt);
        void preViewportUpdate(const Ogre::RenderTargetViewportEvent& evt);

    private:
        CYSShadowSystem(void);
        ~CYSShadowSystem();
        CYSShadowSystem(const CYSShadowSystem&);
        CYSShadowSystem& operator=(const CYSShadowSystem&);

        bool createAtlas(void);
        void destroyAtlas(void);
        void createCascadeViews(void);
        void destroyCascadeViews(void);
        void refreshActive(void);
        void publish(void);
        void publishDisabled(void);
        Ogre::Vector3 resolveLightDirection(void);
        void updateCascades(void);
        void createDebugView(void);
        void layoutDebugView(void);
        void updateDebugView(void);
        void destroyDebugView(void);

        bool mInitialised;
        bool mEnabled;
        CYSShadowConfig mConfig;
        Ogre::String mGroup;
        Ogre::RenderTexture* mTarget;
        Ogre::SceneManager* mSceneManager;
        Ogre::Camera* mCamera;
        Ogre::Camera* mCascadeCameras[CYS_SHADOW_MAX_CASCADES];
        Ogre::Viewport* mViewports[CYS_SHADOW_MAX_CASCADES];

        bool mHasLightOverride;
        Ogre::Vector3 mLightOverride;
        Ogre::Light* mLight;
        bool mUseEnvironment;
        Ogre::Vector3 mLightUsed;
        bool mLightUsedValid;

        CYSShadowParams mParams;
        CYSShadowCasters mCasters;
        CYSShadowAutoParamProvider mProvider;
        CYSShadowParamSink* mSink;
        Ogre::RenderQueue::RenderableListener* mPrevListener;
        bool mListenerInstalled;

        Stats mStats;
        unsigned long mCpuStart;

        bool mDebugView;
        Ogre::Rectangle2D* mDebugRect;
        Ogre::SceneNode* mDebugNode;
    };
}

#endif // __CYS_SHADOW_SYSTEM_H__
