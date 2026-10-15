#ifndef __CYS_POSTFX_PIPELINE_H__
#define __CYS_POSTFX_PIPELINE_H__

// CY-Source (post-processing agent, 2026-09-12): the render-node style post-processing pipeline of one viewport
// (02-postfx.md 1 and 4.1), built on the OGRE 1.2 compositor without changing OgreMain.
//
// B builds each of its 29 filters as a code-built compositor on an extended compositor API (RT aliases, ping-pong,
// cross-compositor texture references) plus a SceneRender filter holding the render nodes. OGRE 1.2 has none of
// those extensions, so the pipeline compiles every enabled stage into ONE compositor technique that it rebuilds
// when the set of enabled stages (or a structural parameter) changes, like B rebuilds its SceneRender technique:
//
//   render nodes (named render textures, own compositors, updated with the render textures before the window):
//     depth node  "CYS/Compositor/SceneRender/depth_buffer"  R32F linear view depth (clear to the far value, then
//                 the scene with material scheme "Depth", queues 10..90, opaque only)
//     stage nodes e.g. GenSSAO -> "CYS/Global/SSAO" (sampled at s12 by the material system's lighting shaders)
//   main compositor (head of the viewport's chain):
//     [scene]   rt_ping: clear with the viewport colour, render queues 0..99
//     [stages]  in B's order, each reads the current ping-pong target and writes the other one
//     [output]  copy to the back buffer
// CYS fx-render 2026-09-13 (B-exact default): rt_ping / rt_pong are 8-bit A8R8G8B8 like B's SceneRender scene_buffer
// (Render.dll FUN_180213940, format 0xc) and the output is a plain copy like B's FinalPass/FrameCopy. The
// "cinematic" preset (setCinematic, PostFX.Preset=cinematic) keeps FP16 targets and a 0.5 LSB dithered copy.
//
// The texture names are the ones TextureUnitState uses for 'content_type compositor <C> <T>' / 'global' units
// (CY-Source OgreMain), so B's own materials that reference SceneRender/depth_buffer read the depth node. The 0.85
// filters (IM_PREVIOUS) run after the main compositor. Everything is resized when the viewport size changes.

#include "CysPostFxStage.h"

#include <OgreCompositorInstance.h>
#include <OgreFrameListener.h>
#include <OgreRenderQueueListener.h>
#include <OgrePixelFormat.h>
#include <OgreTexture.h>

#include <map>
#include <set>
#include <utility>
#include <vector>

namespace Ogre
{
    class CompositionTechnique;
    class CompositionTargetPass;
    class CompositionPass;
}

namespace WX
{
    class CysDepthMaterials;

    /// Adds the passes of one stage to the main compositor technique or to a render node.
    class CysPostFxBuilder
    {
    public:
        /// Special output name: the output of the node being built (beginNode .. endNode).
        static const String NODE_OUTPUT;

        CysPostFxBuilder(CysPostFxPipeline& pipeline, Ogre::CompositionTechnique* technique,
                         size_t viewportWidth, size_t viewportHeight);

        /// Render target sized (viewport or node) * factor, at least 1 pixel. Returns the name to pass to
        /// quad(); local names are private to the stage.
        String texture(const String& localName, Ogre::PixelFormat format, Real factor);
        /// Fixed-size render target.
        String textureFixed(const String& localName, Ogre::PixelFormat format, size_t width, size_t height);
        /// Input naming a texture that is not a target of the technique being built (a render node or any
        /// texture resource): pass external(name) as quad() input.
        static String external(const String& textureName) { return "@" + textureName; }
        /// One target pass writing `output` (a texture of this technique or NODE_OUTPUT) with a full-screen
        /// quad; inputs go to texture units 0..3 (an empty input keeps the material's own texture).
        Ogre::CompositionPass* quad(const String& output, const String& material, Ogre::uint32 localId,
                                    const String& in0 = String(), const String& in1 = String(),
                                    const String& in2 = String(), const String& in3 = String());
        /// Starts a render node: a render texture with a fixed resource name (e.g. "CYS/Global/SSAO"), sized
        /// viewport * factor, written by NODE_OUTPUT passes. Textures declared until endNode() belong to it.
        void beginNode(const String& textureName, Ogre::PixelFormat format, Real factor);
        void endNode(void);
        /// Size in pixels of a texture (technique target, node output or render node texture name).
        void getSize(const String& textureName, size_t& width, size_t& height) const;
        /// Resource name of the depth node texture ("" when no enabled stage needs depth).
        const String& getDepthTexture(void) const { return mDepth; }
        size_t getViewportWidth(void) const { return mWidth; }
        size_t getViewportHeight(void) const { return mHeight; }
        Ogre::PixelFormat getColourFormat(void) const { return mColourFormat; }

        // ---- pipeline internals ----
        struct NodeSpec
        {
            String textureName;
            String compositorName;
            Ogre::PixelFormat format;
            size_t width, height;
        };
        typedef std::vector<std::pair<unsigned short, String> > ExternalInputs;

        void _setStage(Ogre::uint32 slot) { mSlot = slot; }
        void _setDepth(const String& name) { mDepth = name; }
        void _setColourFormat(Ogre::PixelFormat f) { mColourFormat = f; }
        String _define(const String& name, Ogre::PixelFormat format, Real factor, size_t width, size_t height);
        Ogre::CompositionTargetPass* _target(const String& output);
        Ogre::CompositionPass* _quad(Ogre::CompositionTargetPass* tp, const String& material, Ogre::uint32 id,
                                     const String* inputs, size_t count);
        void _error(const String& message);
        bool _hasErrors(void) const { return !mErrorSlots.empty(); }
        const std::set<Ogre::uint32>& _getErrorSlots(void) const { return mErrorSlots; }
        const std::vector<NodeSpec>& _getNodes(void) const { return mNodes; }
        const std::map<Ogre::uint32, ExternalInputs>& _getExternalInputs(void) const { return mExternal; }
        const std::map<String, std::pair<size_t, size_t> >& _getSizes(void) const { return mSizes; }
        const std::vector<String>& _getCompositors(void) const { return mCompositors; }
        const std::set<String>& _getMainTextures(void) const { return mMainTextures; }

    private:
        void checkMaterial(const String& name);
        String scopePrefix(void) const;

        CysPostFxPipeline& mPipeline;
        Ogre::CompositionTechnique* mMain;
        Ogre::CompositionTechnique* mTechnique;   ///< main or current node
        size_t mWidth, mHeight;                   ///< main viewport
        size_t mScopeWidth, mScopeHeight;         ///< size textures are relative to (viewport or node)
        Ogre::uint32 mSlot;
        int mNodeCount;
        String mDepth;
        Ogre::PixelFormat mColourFormat;
        std::map<String, std::pair<size_t, size_t> > mSizes;
        std::set<String> mMainTextures;           ///< texture definitions of the main technique
        std::map<String, String> mMaterialErrors; ///< material -> error ("" = usable)
        std::set<Ogre::uint32> mErrorSlots;
        std::vector<NodeSpec> mNodes;
        std::map<Ogre::uint32, ExternalInputs> mExternal;
        std::vector<String> mCompositors;         ///< compositor resources created (main first)
    };

    class CysPostFxPipeline
        : public Ogre::CompositorInstance::Listener
        , public Ogre::FrameListener
        , public Ogre::RenderQueueListener
    {
    public:
        /// Resource names of the render nodes (TextureUnitState content types, see CY-Source OgreMain).
        static const String DEPTH_TEXTURE;   ///< "CYS/Compositor/SceneRender/depth_buffer"
        static const String SSAO_TEXTURE;    ///< "CYS/Global/SSAO"

        /// Pipeline of a viewport (created on demand when `create`).
        static CysPostFxPipeline* get(Ogre::Viewport* vp, bool create);
        /// Updates every pipeline (hosts without Root frame events).
        static void updateAll(Real dt);
        /// Any pipeline with an active HDR tone-mapping stage (drives the linear-colour/HDR shader flags).
        static void setHdrShadingRequest(CysPostFxPipeline* pipeline, bool on);
        /// CYS fx-render: preset of every pipeline. false (default) = B-exact: 8-bit scene / ping-pong targets and a
        /// plain final copy, as client_GL; true = "cinematic": FP16 targets and a dithered copy (CY-Source HDR path).
        static void setCinematic(bool on);
        static bool isCinematic(void);
        /// CYS-PARITY: scene colour targets in FP16 like CY 3.71 (trace: A16B16G16R16F scene + copy targets, no tone
        /// map) whatever the HDR shading mode; CYS_PARITY_FP16=0 restores B's 8-bit targets outside cinematic mode.
        static bool parityFp16(void);
        /// CYS-PARITY (L2): the scene target renders with a readable INTZ depth-stencil (CY SceneRender, DS INTZ) and
        /// depth readers use CY's _DSIntZ materials instead of the depth node; CYS_PARITY_INTZ=0 or a render system
        /// without INTZ keeps the R32F depth node.
        static bool intzSceneDepth(void);

        Ogre::Viewport* getViewport(void) const { return mViewport; }
        void addStage(CysPostFxStage* stage);
        /// Detaches a stage; the pipeline deletes itself when its last stage goes.
        void removeStage(CysPostFxStage* stage);
        /// Rebuild before the next frame.
        void markDirty(void) { mDirty = true; }
        bool isActive(void) const { return mInstance != 0; }
        const std::vector<CysPostFxStage*>& getActiveStages(void) const { return mBuilt; }

        /// Real texture name of a main-technique texture ("" if not built); render nodes are named already.
        String getTextureName(const String& name) const;
        /// True if the render node texture `resourceName` is produced by this pipeline now.
        bool producesTexture(const String& resourceName) const;
        /// Size of a texture of the current build (false if unknown).
        bool getTextureSize(const String& name, size_t& width, size_t& height) const;

        /// FP16 scene / ping-pong targets (cinematic preset) or 8-bit (default: B's format, no HDR headroom).
        void setHdrTargets(bool on);
        bool getHdrTargets(void) const { return mHdr; }
        /// Value written to depth pixels no object covers (sky); B clears SceneDepth to 50000.
        void setDepthFarValue(Real v) { mDepthFar = v; }
        Real getDepthFarValue(void) const { return mDepthFar; }
        /// Dither of the final FP16 -> 8-bit copy, in 8-bit steps (0 = off).
        void setDitherAmount(Real v) { mDither = v; }
        Real getDitherAmount(void) const { return mDither; }

        // Camera data for stages (valid during the frame).
        Ogre::Camera* getCamera(void) const;
        /// (tan(fovX/2), tan(fovY/2), near, far) of the viewport camera.
        Ogre::Vector4 getProjectionParams(void) const;
        /// Unit vector from the scene towards the sun: CYSEnvironment (scene loaded), else the first
        /// directional light of the scene manager, else `fallback`.
        Ogre::Vector3 getSunDirection(const Ogre::Vector3& fallback) const;

        void update(Real dt);

        // ---- Ogre::CompositorInstance::Listener ----
        void notifyMaterialSetup(Ogre::uint32 passId, Ogre::MaterialPtr& mat);
        void notifyMaterialRender(Ogre::uint32 passId, Ogre::MaterialPtr& mat);
        // ---- Ogre::FrameListener ----
        bool frameStarted(const Ogre::FrameEvent& evt);
        // ---- Ogre::RenderQueueListener (depth node) ----
        void renderQueueStarted(Ogre::uint8 queueGroupId, const String& invocation, bool& skipThisInvocation);
        void renderQueueEnded(Ogre::uint8 queueGroupId, const String& invocation, bool& repeatThisInvocation);

    private:
        struct Node
        {
            String textureName;
            String compositorName;
            Ogre::TexturePtr texture;
            Ogre::Viewport* viewport;
            Ogre::CompositorInstance* instance;
        };

        explicit CysPostFxPipeline(Ogre::Viewport* vp);
        ~CysPostFxPipeline();
        CysPostFxPipeline(const CysPostFxPipeline&);
        CysPostFxPipeline& operator=(const CysPostFxPipeline&);

        void rebuild(void);
        /// CYS fx-render: enabled, not broken and active stages in chain order.
        void collectWanted(std::vector<CysPostFxStage*>& out) const;
        bool build(const std::vector<CysPostFxStage*>& active, std::vector<size_t>& failed);
        void buildDepthNode(CysPostFxBuilder& b);
        bool createNode(const CysPostFxBuilder::NodeSpec& spec);
        void destroyNodes(void);
        void teardown(void);
        void attachSceneManager(void);
        void detachSceneManager(void);
        void requeueForDepth(Ogre::RenderQueueGroup* group);

        Ogre::Viewport* mViewport;
        Ogre::Camera* mCamera;                  ///< camera the render nodes were built with
        Ogre::SceneManager* mSceneManager;
        std::vector<CysPostFxStage*> mStages;   ///< registered stages
        std::vector<CysPostFxStage*> mBuilt;    ///< stages of the current build, index = slot - 1
        std::vector<CysPostFxStage*> mLastWanted;   ///< CYS fx-render: the set the last rebuild started from
        std::vector<CysPostFxStage*> mWantScratch;
        Ogre::CompositorInstance* mInstance;    ///< main compositor instance
        String mCompositorName;
        std::vector<String> mCompositorResources;
        std::vector<Node> mNodes;
        bool mDirty;
        bool mHdr;
        size_t mBuiltWidth, mBuiltHeight;
        Ogre::ColourValue mClearColour;
        Ogre::CompositionPass* mClearPass;
        Ogre::Viewport* mDepthViewport;
        bool mIntzRegistered;                   ///< CYS-PARITY (L2): rt_ping is the render system's INTZ target
        std::map<String, String> mRealNames;   ///< main technique texture -> texture instance name
        std::map<String, std::pair<size_t, size_t> > mSizes;
        std::map<Ogre::uint32, CysPostFxBuilder::ExternalInputs> mExternal;
        Real mDepthFar;
        Real mDither;
        CysDepthMaterials* mDepthMaterials;
        std::vector<std::pair<Ogre::Renderable*, Ogre::ushort> > mQueueScratch;
        std::vector<Ogre::Renderable*> mRenderableScratch;
    };
}

#endif // __CYS_POSTFX_PIPELINE_H__
