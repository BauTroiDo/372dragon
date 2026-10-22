#ifndef __CYS_WATER_RENDER_H__
#define __CYS_WATER_RENDER_H__






















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
        static const String POSTFX_STAGE_TYPE;

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
