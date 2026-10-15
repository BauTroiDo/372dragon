#ifndef __CYS_WATER_RENDER_H__
#define __CYS_WATER_RENDER_H__

// CY-Source (water-cy agent, 2026-09-14): the CY 3.71 "new water" render targets behind CYSWaterRenderHooks.
// Specification and evidence: Docs/specs/render/water-cy_vi.md (CY Render.dll b91401fc..., Ghidra on a copy).
//
// What CY does (FACT unless marked INF in the spec) and what this class reproduces:
//   * TerrainLiquid::_updateRenderQueue (FUN_1801ef510): a material with a "WaterFog" technique renders technique 0
//     (the under-water fog, alpha forced to 0) in queue 76 and technique 1 (the surface) in queue 77, priority 100
//     -> WXTerrainLiquid.cpp (hook CYS-WATER) through CYSScene::getNewWaterTechniques.
//   * SceneRender node (FUN_18021e7b0): scene_buffer A8R8G8B8 1.0 x 1.0; with water the scene is drawn up to queue 76,
//     copied (node 3 "FrameCopy", FUN_18021f580) and the queues 77..85 are drawn on top
//     -> renderQueueStarted(77) copies the active render target into "CYS/Compositor/SceneRender/scene_buffer"
//        (RenderSystem::_copyActiveRenderTarget, a D3D9 StretchRect), the RefractTex of every water material.
//   * SceneDepthForWater node (FUN_18021eeb0): depth_buffer R32F linear view depth, material scheme "Depth"
//     -> the post-FX pipeline depth node, requested by the "Water" stage below while new water exists.
//   * mirror water (TerrainLiquidObject::_createMirrorReflectRenderTexture, FUN_18011ef40): material name contains
//     "mirror"; ONE shared 1024 x 1024 render texture "waterMirrorReflectTex", camera "ReflectRTCamera", viewport
//     without overlays / skies, clear colour white every frame; unit 1 of technique 1 pass 0 ("ReflectTexInput")
//     samples it -> a reflected copy of the main camera clipped at the water plane (0.85 ReflectRenderTargetListener).
//
// Switches: CYS_WATER=0 (environment) or setEnabled(false) keeps B/CY's low-quality fallback (replaceMaterial);
// CYS_WATER_MIRROR=0 skips the mirror texture (mirror water then reflects nothing), CYS_WATER_MIRROR_SIZE=<pixels>.

#include "CYS/Scene/CYSWater.h"

#include <OgreRenderQueueListener.h>
#include <OgreRenderTargetListener.h>
#include <OgreFrameListener.h>
#include <OgreTexture.h>
#include <OgrePlane.h>

#include <vector>

namespace WX
{
    class System;
    class TerrainLiquidObject;

    class CysWaterRender : public CYSWaterRenderHooks, public Ogre::RenderQueueListener, public Ogre::FrameListener
    {
    public:
        /// Resource names (CY names where CY has one).
        static const String SCENE_BUFFER_TEXTURE;   ///< "CYS/Compositor/SceneRender/scene_buffer"
        static const String MIRROR_TEXTURE;         ///< "waterMirrorReflectTex"
        static const String MIRROR_CAMERA;          ///< "ReflectRTCamera"
        static const String POSTFX_STAGE_TYPE;      ///< "Water" (CY post filter name, FUN_180046f00)

        struct Stats
        {
            size_t liquids;         ///< registered liquids using a new-water material
            size_t mirrors;         ///< of which mirror water
            unsigned long copies;   ///< scene_buffer copies done
            unsigned long copyFailures;
            unsigned long mirrorUpdates;
            unsigned long mirrorVisibleFrames;
            unsigned long mirrorActivityChanges;
            double copyMs;          ///< CPU time spent in the copy calls (the GPU work is queued)
            double mirrorMs;        ///< CPU time of the mirror render texture updates
            size_t sceneBufferWidth, sceneBufferHeight;
        };

        /// Installs the hooks for `system` (idempotent). Never throws.
        static CysWaterRender* install(System* system);
        /// Removes the hooks and releases the render targets.
        static void uninstall(void);
        static CysWaterRender* getSingletonPtr(void);

        void setEnabled(bool enabled);
        bool isEnabled(void) const { return mEnabled; }
        const Stats& getStats(void) const { return mStats; }
        /// One-line summary for logs.
        String describe(void) const;
        /// True while at least one registered liquid needs the water nodes (read by the "Water" post-FX stage).
        bool hasNewWater(void) const { return mEnabled && !mLiquids.empty(); }
        /// CYS-PARITY (d3d9-trace): other consumers of the scene depth node (FakeLight light boxes) keep the "Water"
        /// post-FX stage, i.e. the depth node, alive in scenes without new water.
        void addDepthUser(void);
        void removeDepthUser(void);
        bool needsDepthNode(void) const { return hasNewWater() || mDepthUsers > 0; }

        // ---- CYSWaterRenderHooks ----
        bool supportsNewWater(void) const;
        void liquidCreated(TerrainLiquidObject& liquid, const Ogre::MaterialPtr& material);
        void liquidDestroyed(TerrainLiquidObject& liquid);
        void surfaceQueued(bool mirror);

        // Commit visibility once after all scene and compositor passes, for the next RT update.
        bool frameStarted(const Ogre::FrameEvent& evt);
        bool frameEnded(const Ogre::FrameEvent& evt);

        // ---- Ogre::RenderQueueListener ----
        void renderQueueStarted(Ogre::uint8 queueGroupId, const String& invocation, bool& skipThisInvocation);
        void renderQueueEnded(Ogre::uint8 queueGroupId, const String& invocation, bool& repeatThisInvocation);

    private:
        int mDepthUsers;                ///< CYS-PARITY: addDepthUser / removeDepthUser
        struct Entry
        {
            TerrainLiquidObject* liquid;
            String material;
            bool mirror;
            Real height;
        };

        class MirrorListener : public Ogre::RenderTargetListener
        {
        public:
            explicit MirrorListener(CysWaterRender& owner) : mOwner(owner) {}
            void preRenderTargetUpdate(const Ogre::RenderTargetEvent& evt) { mOwner.preMirrorUpdate(); }
            void postRenderTargetUpdate(const Ogre::RenderTargetEvent& evt) { mOwner.postMirrorUpdate(); }
        private:
            MirrorListener& operator=(const MirrorListener&);
            CysWaterRender& mOwner;
        };

        explicit CysWaterRender(System* system);
        ~CysWaterRender();
        CysWaterRender(const CysWaterRender&);
        CysWaterRender& operator=(const CysWaterRender&);

        void attachSceneManager(void);
        void detachSceneManager(void);
        void ensurePostFxStage(void);
        bool ensureSceneBuffer(size_t width, size_t height);
        void releaseSceneBuffer(void);
        bool ensureMirror(void);
        void releaseMirror(void);
        void bindMirrorTexture(const Ogre::MaterialPtr& material);
        void preMirrorUpdate(void);
        void postMirrorUpdate(void);
        void setLiquidsVisible(bool visible);
        void updateMirrorActivity(void);
        void applyDebug(const Ogre::MaterialPtr& material);

        System* mSystem;
        Ogre::SceneManager* mSceneManager;
        bool mEnabled;
        bool mMirrorEnabled;
        size_t mMirrorSize;
        bool mSurfaceQueued;
        bool mMirrorQueued;      ///< a mirror surface was queued for the main camera this frame
        bool mMirrorSeenThisFrame;
        bool mMirrorLegacy;
        bool mMirrorLog;
        size_t mMeshSurfaces;
        std::vector<Entry> mLiquids;
        Ogre::TexturePtr mSceneBuffer;
        Ogre::TexturePtr mMirrorTexture;
        Ogre::Camera* mMirrorCamera;
        MirrorListener mMirrorListener;
        Ogre::Plane mMirrorPlane;
        bool mMirrorActive;
        double mMirrorStart;
        bool mLoggedCopyFailure;
        Stats mStats;
    };
}

#endif // __CYS_WATER_RENDER_H__
