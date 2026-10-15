// CY-Source (post-processing agent, 2026-09-12): CysPostFxPipeline / CysPostFxBuilder - see CysPostFxPipeline.h.
#include "CysPostFxPipeline.h"
#include "CysPostFxDepth.h"
#include "CysPostFx.h"
#include "CYS/Scene/CYSEnvironment.h"

#include <OgreRoot.h>
#include <OgreRenderSystem.h>
#include <OgreViewport.h>
#include <OgreCamera.h>
#include <OgreLight.h>
#include <OgreSceneManager.h>
#include <OgreSceneManagerEnumerator.h>
#include <OgreRenderTarget.h>
#include <OgreRenderTexture.h>
#include <OgreHardwarePixelBuffer.h>
#include <OgreTextureManager.h>
#include <OgreImage.h>
#include <OgreCompositorManager.h>
#include <OgreCompositor.h>
#include <OgreCompositorChain.h>
#include <OgreCompositionTechnique.h>
#include <OgreCompositionTargetPass.h>
#include <OgreCompositionPass.h>
#include <OgreMaterialManager.h>
#include <OgreTechnique.h>
#include <OgrePass.h>
#include <OgreTextureUnitState.h>
#include <OgreRenderQueue.h>
#include <OgreRenderQueueSortingGrouping.h>
#include <OgreAutoParamExternalProvider.h>
#include <OgreStringConverter.h>
#include <OgreException.h>
#include <OgreMath.h>

#include <algorithm>

namespace WX
{
    using Ogre::StringConverter;

    const String CysPostFxBuilder::NODE_OUTPUT("<node>");
    const String CysPostFxPipeline::DEPTH_TEXTURE("CYS/Compositor/SceneRender/depth_buffer");
    const String CysPostFxPipeline::SSAO_TEXTURE("CYS/Global/SSAO");

    namespace
    {
        typedef std::map<Ogre::Viewport*, CysPostFxPipeline*> PipelineMap;

        PipelineMap& pipelines(void)
        {
            static PipelineMap m;
            return m;
        }

        unsigned int gSerial = 0;

        /// CYS fx-render: preset of all pipelines (false = B-exact 8-bit targets, true = cinematic FP16)
        bool gCinematic = false;

        /// Pass identifiers of the pipeline itself (slot 0).
        enum InternalPassId
        {
            ID_DEPTH_CLEAR = 1,
            ID_FINAL = 2
        };

        struct ByOrder
        {
            bool operator()(const CysPostFxStage* a, const CysPostFxStage* b) const
            {
                return a->getOrder() < b->getOrder();
            }
        };

        /// Collects the renderables of a queued collection (pass-grouped or sorted).
        class CollectRenderables : public Ogre::QueuedRenderableVisitor
        {
        public:
            explicit CollectRenderables(std::vector<Ogre::Renderable*>& out) : mOut(out) {}
            void visit(const Ogre::RenderablePass* rp) { mOut.push_back(rp->renderable); }
            bool visit(const Ogre::Pass* p) { return true; }
            void visit(const Ogre::Renderable* r) { mOut.push_back(const_cast<Ogre::Renderable*>(r)); }

        private:
            CollectRenderables& operator=(const CollectRenderables&);
            std::vector<Ogre::Renderable*>& mOut;
        };

        /// Turns on the material system's linear-colour / HDR shading (isystem_userdata.y / .z,
        /// OgreAutoParamExternalProvider.h RF_COLOUR_SPACE) for the cameras of pipelines whose NewHDRBloom
        /// tone-maps (UseHDR): the scene may then exceed 1 in the FP16 target and the tone map compresses it.
        class HdrShadingProvider : public Ogre::AutoParamExternalProvider
        {
        public:
            HdrShadingProvider() : mRegistered(false) {}

            bool getRenderFlagsParams(const Ogre::Camera* camera, Ogre::RenderFlagsParamBlock& out) const
            {
                for (std::set<const CysPostFxPipeline*>::const_iterator i = mRequests.begin(); i != mRequests.end(); ++i)
                {
                    if ((*i)->getCamera() == camera)
                    {
                        out.linearColourSpace = 1;
                        out.colourGreaterOne = 1;
                        out.valid |= Ogre::RenderFlagsParamBlock::RF_COLOUR_SPACE;
                        return true;
                    }
                }
                return false;
            }

            void set(const CysPostFxPipeline* p, bool on)
            {
                if (on)
                    mRequests.insert(p);
                else
                    mRequests.erase(p);
                const bool want = !mRequests.empty();
                Ogre::Root* root = Ogre::Root::getSingletonPtr();
                if (want && !mRegistered && root)
                {
                    root->addAutoParamExternalProvider(this);
                    mRegistered = true;
                    CysPostFxUtil::log("CysPostFX: linear-colour / HDR shading flags on (NewHDRBloom UseHDR)");
                }
                else if (!want && mRegistered)
                {
                    if (root)
                        root->removeAutoParamExternalProvider(this);
                    mRegistered = false;
                    CysPostFxUtil::log("CysPostFX: linear-colour / HDR shading flags off");
                }
            }

        private:
            std::set<const CysPostFxPipeline*> mRequests;
            bool mRegistered;
        };

        HdrShadingProvider& hdrProvider(void)
        {
            static HdrShadingProvider p;
            return p;
        }

        bool sceneManagerAlive(Ogre::SceneManager* sm)
        {
            if (!sm || !Ogre::Root::getSingletonPtr())
                return false;
            Ogre::SceneManagerEnumerator::SceneManagerIterator it = Ogre::Root::getSingleton().getSceneManagerIterator();
            while (it.hasMoreElements())
            {
                if (it.getNext() == sm)
                    return true;
            }
            return false;
        }

        /// What a consumer reads when the render node is not produced: SSAO = 1x1 white (no occlusion, as the
        /// material system's placeholder), depth = 1x1 R32F far value.
        void createPlaceholder(const String& name, Real depthFar)
        {
            Ogre::TextureManager* tm = Ogre::TextureManager::getSingletonPtr();
            if (!tm || !tm->getByName(name).isNull())
                return;
            try
            {
                Ogre::Image img;
                if (name == CysPostFxPipeline::DEPTH_TEXTURE)
                {
                    static float farValue[1];
                    farValue[0] = depthFar;
                    img.loadDynamicImage(reinterpret_cast<Ogre::uchar*>(farValue), 1, 1, 1, Ogre::PF_FLOAT32_R);
                }
                else
                {
                    static Ogre::uchar white[4] = { 255, 255, 255, 255 };
                    img.loadDynamicImage(white, 1, 1, 1, Ogre::PF_BYTE_RGBA);
                }
                tm->loadImage(name, Ogre::ResourceGroupManager::INTERNAL_RESOURCE_GROUP_NAME, img, Ogre::TEX_TYPE_2D, 0);
            }
            catch (Ogre::Exception& e)
            {
                CysPostFxUtil::log("CysPostFX: placeholder " + name + " failed: " + e.getDescription());
            }
        }
    }

    //=======================================================================
    // CysPostFxBuilder
    //=======================================================================
    CysPostFxBuilder::CysPostFxBuilder(CysPostFxPipeline& pipeline, Ogre::CompositionTechnique* technique,
                                       size_t viewportWidth, size_t viewportHeight)
        : mPipeline(pipeline)
        , mMain(technique)
        , mTechnique(technique)
        , mWidth(viewportWidth)
        , mHeight(viewportHeight)
        , mScopeWidth(viewportWidth)
        , mScopeHeight(viewportHeight)
        , mSlot(0)
        , mNodeCount(0)
        , mColourFormat(Ogre::PF_FLOAT16_RGBA)
    {
    }
    //-----------------------------------------------------------------------
    String CysPostFxBuilder::scopePrefix(void) const
    {
        String p = "s" + StringConverter::toString(mSlot);
        if (mTechnique != mMain)
            p += "n" + StringConverter::toString(mNodeCount);
        return p + "_";
    }
    //-----------------------------------------------------------------------
    String CysPostFxBuilder::texture(const String& localName, Ogre::PixelFormat format, Real factor)
    {
        return _define(scopePrefix() + localName, format, factor, 0, 0);
    }
    //-----------------------------------------------------------------------
    String CysPostFxBuilder::textureFixed(const String& localName, Ogre::PixelFormat format, size_t width, size_t height)
    {
        return _define(scopePrefix() + localName, format, 0, width, height);
    }
    //-----------------------------------------------------------------------
    String CysPostFxBuilder::_define(const String& name, Ogre::PixelFormat format, Real factor, size_t width, size_t height)
    {
        Ogre::CompositionTechnique::TextureDefinition* td = mTechnique->createTextureDefinition(name);
        size_t w, h;
        if (width > 0 && height > 0)
        {
            td->width = Ogre::CompositionTechnique::TextureDim((int)width, 0, 0);
            td->height = Ogre::CompositionTechnique::TextureDim((int)height, 0, 0);
            w = width;
            h = height;
        }
        else
        {
            td->width = Ogre::CompositionTechnique::TextureDim(0, factor, 0);
            td->height = Ogre::CompositionTechnique::TextureDim(0, factor, 0);
            // same arithmetic as CompositorInstance::createResources
            const int iw = static_cast<int>((int)mScopeWidth * factor);
            const int ih = static_cast<int>((int)mScopeHeight * factor);
            w = iw > 0 ? (size_t)iw : 1;
            h = ih > 0 ? (size_t)ih : 1;
        }
        td->format = format;
        mSizes[name] = std::make_pair(w, h);
        if (mTechnique == mMain)
            mMainTextures.insert(name);
        return name;
    }
    //-----------------------------------------------------------------------
    void CysPostFxBuilder::beginNode(const String& textureName, Ogre::PixelFormat format, Real factor)
    {
        if (mTechnique != mMain)
            endNode();
        NodeSpec s;
        s.textureName = textureName;
        s.format = format;
        const int iw = static_cast<int>((int)mWidth * factor);
        const int ih = static_cast<int>((int)mHeight * factor);
        s.width = iw > 0 ? (size_t)iw : 1;
        s.height = ih > 0 ? (size_t)ih : 1;
        s.compositorName = "CysPostFX/Node/" + StringConverter::toString(++gSerial);
        Ogre::CompositorPtr c = Ogre::CompositorManager::getSingleton().create(
            s.compositorName, Ogre::ResourceGroupManager::INTERNAL_RESOURCE_GROUP_NAME);
        mCompositors.push_back(s.compositorName);
        mTechnique = c->createTechnique();
        mScopeWidth = s.width;
        mScopeHeight = s.height;
        mSizes[textureName] = std::make_pair(s.width, s.height);
        mNodes.push_back(s);
        ++mNodeCount;
    }
    //-----------------------------------------------------------------------
    void CysPostFxBuilder::endNode(void)
    {
        mTechnique = mMain;
        mScopeWidth = mWidth;
        mScopeHeight = mHeight;
    }
    //-----------------------------------------------------------------------
    void CysPostFxBuilder::getSize(const String& textureName, size_t& width, size_t& height) const
    {
        std::map<String, std::pair<size_t, size_t> >::const_iterator it = mSizes.find(textureName);
        if (it != mSizes.end())
        {
            width = it->second.first;
            height = it->second.second;
        }
        else
        {
            width = mWidth;
            height = mHeight;
        }
    }
    //-----------------------------------------------------------------------
    Ogre::CompositionPass* CysPostFxBuilder::quad(const String& output, const String& material, Ogre::uint32 localId,
                                                 const String& in0, const String& in1, const String& in2, const String& in3)
    {
        const String inputs[4] = { in0, in1, in2, in3 };
        size_t n = 4;
        while (n > 0 && inputs[n - 1].empty())
            --n;
        return _quad(_target(output), material, (mSlot << 16) | (localId & 0xFFFF), inputs, n);
    }
    //-----------------------------------------------------------------------
    Ogre::CompositionTargetPass* CysPostFxBuilder::_target(const String& output)
    {
        if (output == NODE_OUTPUT)
        {
            if (mTechnique == mMain)
                _error("NODE_OUTPUT used outside beginNode() / endNode()");
            Ogre::CompositionTargetPass* tp = mTechnique->getOutputTargetPass();
            tp->setInputMode(Ogre::CompositionTargetPass::IM_NONE);
            return tp;
        }
        Ogre::CompositionTargetPass* tp = mTechnique->createTargetPass();
        tp->setInputMode(Ogre::CompositionTargetPass::IM_NONE);
        tp->setOutputName(output);
        return tp;
    }
    //-----------------------------------------------------------------------
    Ogre::CompositionPass* CysPostFxBuilder::_quad(Ogre::CompositionTargetPass* tp, const String& material,
                                                  Ogre::uint32 id, const String* inputs, size_t count)
    {
        checkMaterial(material);
        Ogre::CompositionPass* p = tp->createPass();
        p->setType(Ogre::CompositionPass::PT_RENDERQUAD);
        p->setMaterialName(material);
        p->setIdentifier(id);
        for (size_t i = 0; i < count; ++i)
        {
            if (inputs[i].empty())
                continue;
            if (inputs[i][0] == '@')
                mExternal[id].push_back(std::make_pair((unsigned short)i, inputs[i].substr(1)));
            else
                p->setInput(i, inputs[i]);
        }
        return p;
    }
    //-----------------------------------------------------------------------
    void CysPostFxBuilder::checkMaterial(const String& name)
    {
        std::map<String, String>::const_iterator it = mMaterialErrors.find(name);
        if (it != mMaterialErrors.end())
        {
            if (!it->second.empty())
                _error(it->second);
            return;
        }
        String err;
        Ogre::MaterialPtr m = Ogre::MaterialManager::getSingleton().getByName(name);
        if (m.isNull())
        {
            err = "material '" + name + "' not found (CysPostFX.material not loaded?)";
        }
        else
        {
            try
            {
                m->load();
            }
            catch (Ogre::Exception& e)
            {
                err = "material '" + name + "': " + e.getDescription();
            }
            if (err.empty() && m->getNumSupportedTechniques() == 0)
                err = "material '" + name + "' has no supported technique (shader compile error? see the Ogre log)";
        }
        mMaterialErrors[name] = err;
        if (!err.empty())
            _error(err);
    }
    //-----------------------------------------------------------------------
    void CysPostFxBuilder::_error(const String& message)
    {
        CysPostFxUtil::log("CysPostFX: build error (slot " + StringConverter::toString(mSlot) + "): " + message);
        mErrorSlots.insert(mSlot);
    }

    //=======================================================================
    // CysPostFxPipeline
    //=======================================================================
    CysPostFxPipeline* CysPostFxPipeline::get(Ogre::Viewport* vp, bool create)
    {
        PipelineMap& m = pipelines();
        PipelineMap::iterator it = m.find(vp);
        if (it != m.end())
            return it->second;
        if (!create || !vp)
            return 0;
        CysPostFxPipeline* p = new CysPostFxPipeline(vp);
        m[vp] = p;
        return p;
    }
    //-----------------------------------------------------------------------
    void CysPostFxPipeline::updateAll(Real dt)
    {
        std::vector<CysPostFxPipeline*> all;
        for (PipelineMap::iterator it = pipelines().begin(); it != pipelines().end(); ++it)
            all.push_back(it->second);
        for (size_t i = 0; i < all.size(); ++i)
            all[i]->update(dt);
    }
    //-----------------------------------------------------------------------
    void CysPostFxPipeline::setHdrShadingRequest(CysPostFxPipeline* pipeline, bool on)
    {
        hdrProvider().set(pipeline, on);
    }
    //-----------------------------------------------------------------------
    void CysPostFxPipeline::setCinematic(bool on)
    {
        gCinematic = on;
        for (PipelineMap::iterator it = pipelines().begin(); it != pipelines().end(); ++it)
            it->second->setHdrTargets(on);
    }
    //-----------------------------------------------------------------------
    bool CysPostFxPipeline::parityFp16(void)
    {
        // CYS-PARITY (d3d9-trace, Docs/specs/render/d3d9-parity_vi.md L2): FACT CY 3.71 erengu_DL draws the scene into
        // A16B16G16R16F, adds the FakeLight boxes / fog volumes / water there, runs HeightFog FP16 -> FP16 and copies
        // the result to the back buffer without tone mapping or dither.
        static const bool on = []() {
            const char* v = getenv("CYS_PARITY_FP16");
            return !(v && v[0] == '0');
        }();
        return on;
    }
    //-----------------------------------------------------------------------
    bool CysPostFxPipeline::intzSceneDepth(void)
    {
        // CYS-PARITY (d3d9-trace L2): FACT CY 3.71 (trace cy-login-2, cy-world-1): the scene pass renders into FP16 with
        // DS = INTZ 1280x720; the FakeLight boxes (1e1f4ac9) and the water fog volumes (78f6952f) sample that INTZ
        // texture during the scene with depth writes off, HeightFog_DSIntZ (6c52486a) after it; there is no depth
        // render. Render.dll picks "<material>_DSIntZ" (FUN_1801275e0, FUN_1801219e0, FUN_1801bf970).
        static const bool env = []() {
            const char* v = getenv("CYS_PARITY_INTZ");
            return !(v && v[0] == '0');
        }();
        if (!env)
            return false;
        Ogre::RenderSystem* rs = Ogre::Root::getSingletonPtr() ? Ogre::Root::getSingleton().getRenderSystem() : 0;
        return rs && rs->_cysIntzSceneDepthSupported();
    }
    //-----------------------------------------------------------------------
    bool CysPostFxPipeline::isCinematic(void)
    {
        return gCinematic;
    }
    //-----------------------------------------------------------------------
    CysPostFxPipeline::CysPostFxPipeline(Ogre::Viewport* vp)
        : mViewport(vp)
        , mCamera(0)
        , mSceneManager(0)
        , mInstance(0)
        , mDirty(true)
        , mHdr(gCinematic || parityFp16())          // CYS fx-render: B's 8-bit targets unless cinematic; CYS-PARITY FP16
        , mBuiltWidth(0)
        , mBuiltHeight(0)
        , mClearColour(Ogre::ColourValue::Black)
        , mClearPass(0)
        , mDepthViewport(0)
        , mIntzRegistered(false)
        , mDepthFar(50000.0f)
        , mDither(1.0f)
        , mDepthMaterials(new CysDepthMaterials())
    {
        if (Ogre::Root::getSingletonPtr())
            Ogre::Root::getSingleton().addFrameListener(this);
        attachSceneManager();
    }
    //-----------------------------------------------------------------------
    CysPostFxPipeline::~CysPostFxPipeline()
    {
        teardown();
        hdrProvider().set(this, false);
        detachSceneManager();
        if (Ogre::Root::getSingletonPtr())
            Ogre::Root::getSingleton().removeFrameListener(this);
        delete mDepthMaterials;
    }
    //-----------------------------------------------------------------------
    void CysPostFxPipeline::addStage(CysPostFxStage* stage)
    {
        if (std::find(mStages.begin(), mStages.end(), stage) == mStages.end())
            mStages.push_back(stage);
        mDirty = true;
    }
    //-----------------------------------------------------------------------
    void CysPostFxPipeline::removeStage(CysPostFxStage* stage)
    {
        std::vector<CysPostFxStage*>::iterator it = std::find(mStages.begin(), mStages.end(), stage);
        if (it != mStages.end())
            mStages.erase(it);
        if (std::find(mBuilt.begin(), mBuilt.end(), stage) != mBuilt.end())
            teardown();                             // its passes are live: remove them now
        mDirty = true;
        if (mStages.empty())
        {
            pipelines().erase(mViewport);
            delete this;
        }
    }
    //-----------------------------------------------------------------------
    void CysPostFxPipeline::setHdrTargets(bool on)
    {
        on = on || parityFp16(); // CYS-PARITY: FP16 targets stay on (CY) whatever the shading mode
        if (on != mHdr)
        {
            mHdr = on;
            mDirty = true;
        }
    }
    //-----------------------------------------------------------------------
    String CysPostFxPipeline::getTextureName(const String& name) const
    {
        std::map<String, String>::const_iterator it = mRealNames.find(name);
        if (it != mRealNames.end())
            return it->second;
        return producesTexture(name) ? name : String();
    }
    //-----------------------------------------------------------------------
    bool CysPostFxPipeline::producesTexture(const String& resourceName) const
    {
        for (size_t i = 0; i < mNodes.size(); ++i)
        {
            if (mNodes[i].textureName == resourceName && mNodes[i].instance)
                return true;
        }
        return false;
    }
    //-----------------------------------------------------------------------
    bool CysPostFxPipeline::getTextureSize(const String& name, size_t& width, size_t& height) const
    {
        std::map<String, std::pair<size_t, size_t> >::const_iterator it = mSizes.find(name);
        if (it == mSizes.end())
            return false;
        width = it->second.first;
        height = it->second.second;
        return true;
    }
    //-----------------------------------------------------------------------
    Ogre::Camera* CysPostFxPipeline::getCamera(void) const
    {
        return mViewport ? mViewport->getCamera() : 0;
    }
    //-----------------------------------------------------------------------
    Ogre::Vector4 CysPostFxPipeline::getProjectionParams(void) const
    {
        Ogre::Camera* c = getCamera();
        if (!c)
            return Ogre::Vector4(1, 1, 1, 10000);
        const Real ty = Ogre::Math::Tan(c->getFOVy() * 0.5f);
        const Real tx = ty * c->getAspectRatio();
        return Ogre::Vector4(tx, ty, c->getNearClipDistance(), c->getFarClipDistance());
    }
    //-----------------------------------------------------------------------
    Ogre::Vector3 CysPostFxPipeline::getSunDirection(const Ogre::Vector3& fallback) const
    {
        CYSEnvironmentManager& em = CYSEnvironmentManager::getSingleton();
        const CYSEnvironment& env = em.getEnvironment();
        if (!em.getSceneName().empty() && env.source != CYSEnvironment::SOURCE_NONE &&
            env.sunDirection.squaredLength() > 1e-6f)
        {
            return env.sunDirection.normalisedCopy();
        }
        if (mSceneManager)
        {
            // the brightest visible directional light (the viewer and the game name their key light freely)
            Ogre::Light* best = 0;
            Real bestLum = -1;
            Ogre::SceneManager::MovableObjectIterator it = mSceneManager->getMovableObjectIterator("Light");
            while (it.hasMoreElements())
            {
                Ogre::Light* l = static_cast<Ogre::Light*>(it.getNext());
                if (l->getType() != Ogre::Light::LT_DIRECTIONAL || !l->isVisible())
                    continue;
                const Ogre::ColourValue& c = l->getDiffuseColour();
                const Real lum = c.r * 0.299f + c.g * 0.587f + c.b * 0.114f;
                if (lum > bestLum)
                {
                    bestLum = lum;
                    best = l;
                }
            }
            if (best)
                return -best->getDerivedDirection().normalisedCopy();
        }
        return fallback.normalisedCopy();
    }
    //-----------------------------------------------------------------------
    void CysPostFxPipeline::attachSceneManager(void)
    {
        Ogre::Camera* cam = mViewport ? mViewport->getCamera() : 0;
        Ogre::SceneManager* sm = cam ? cam->getSceneManager() : 0;
        if (sm == mSceneManager)
            return;
        detachSceneManager();
        mSceneManager = sm;
        if (sm)
            sm->addRenderQueueListener(this);
    }
    //-----------------------------------------------------------------------
    void CysPostFxPipeline::detachSceneManager(void)
    {
        if (mSceneManager && sceneManagerAlive(mSceneManager))
            mSceneManager->removeRenderQueueListener(this);
        mSceneManager = 0;
    }
    //-----------------------------------------------------------------------
    bool CysPostFxPipeline::frameStarted(const Ogre::FrameEvent& evt)
    {
        update(evt.timeSinceLastFrame);
        return true;
    }
    //-----------------------------------------------------------------------
    void CysPostFxPipeline::update(Real dt)
    {
        if (!mViewport)
            return;
        attachSceneManager();
        for (size_t i = 0; i < mStages.size(); ++i)
        {
            if (mStages[i]->getEnabled())
                mStages[i]->onFrame(dt);
        }
        // CYS fx-render: rebuild when the set of stages that want passes changes - an enabled stage can be inactive in
        // this scene (HeightFog without height fog) and costs nothing until the environment turns it on
        if (!mDirty)
        {
            collectWanted(mWantScratch);
            if (mWantScratch != mLastWanted)
                mDirty = true;
        }
        if (mInstance || !mNodes.empty())
        {
            if ((size_t)mViewport->getActualWidth() != mBuiltWidth ||
                (size_t)mViewport->getActualHeight() != mBuiltHeight ||
                mViewport->getCamera() != mCamera)
            {
                mDirty = true;
            }
        }
        if (mDirty)
            rebuild();
        if (mInstance && mClearPass)
        {
            const Ogre::ColourValue& bg = mViewport->getBackgroundColour();
            if (bg != mClearColour)
            {
                mClearColour = bg;
                mClearPass->setClearColour(bg);
                mInstance->getChain()->_markDirty();
            }
        }
    }
    //-----------------------------------------------------------------------
    void CysPostFxPipeline::rebuild(void)
    {
        mDirty = false;
        teardown();
        std::vector<CysPostFxStage*> active;
        collectWanted(active);
        mLastWanted = active;                       // CYS fx-render: update() rebuilds when this set changes
        if (!mViewport || !Ogre::CompositorManager::getSingletonPtr())
            return;
        if (active.empty())
            return;
        if (!CysPostFx::initialiseMedia())
        {
            CysPostFxUtil::log("CysPostFX: media not available - post filters stay off");
            return;
        }

        for (int attempt = 0; attempt < 4 && !active.empty(); ++attempt)
        {
            std::vector<size_t> failed;
            if (build(active, failed))
                return;
            if (failed.empty())
            {
                CysPostFxUtil::log("CysPostFX: pipeline build failed - post filters off");
                return;
            }
            std::sort(failed.begin(), failed.end());
            failed.erase(std::unique(failed.begin(), failed.end()), failed.end());
            for (size_t k = failed.size(); k-- > 0;)
            {
                if (failed[k] >= active.size())
                    continue;
                CysPostFxStage* s = active[failed[k]];
                s->_setBroken(true);
                CysPostFxUtil::log("CysPostFX: " + s->getName() + " disabled: its passes failed (see above); "
                                   "enable it again or change a parameter to retry");
                active.erase(active.begin() + failed[k]);
            }
        }
    }
    //-----------------------------------------------------------------------
    void CysPostFxPipeline::collectWanted(std::vector<CysPostFxStage*>& out) const
    {
        out.clear();
        for (size_t i = 0; i < mStages.size(); ++i)
        {
            if (mStages[i]->getEnabled() && !mStages[i]->_isBroken() && mStages[i]->isActive())
                out.push_back(mStages[i]);
        }
        std::stable_sort(out.begin(), out.end(), ByOrder());
    }
    //-----------------------------------------------------------------------
    void CysPostFxPipeline::buildDepthNode(CysPostFxBuilder& b)
    {
        b.beginNode(DEPTH_TEXTURE, Ogre::PF_FLOAT32_R, 1.0f);
        Ogre::CompositionTargetPass* tp = b._target(CysPostFxBuilder::NODE_OUTPUT);
        tp->setMaterialScheme(CysDepthMaterials::getSchemeName());
        Ogre::CompositionPass* clear = tp->createPass();
        clear->setType(Ogre::CompositionPass::PT_CLEAR);
        clear->setClearBuffers(Ogre::FBT_DEPTH | Ogre::FBT_STENCIL);
        clear->setClearDepth(1.0f);
        b._quad(tp, "CysPostFX/DepthClear", ID_DEPTH_CLEAR, 0, 0);    // colour = far value (sky)
        Ogre::CompositionPass* scene = tp->createPass();
        scene->setType(Ogre::CompositionPass::PT_RENDERSCENE);
        scene->setFirstRenderQueue(Ogre::RENDER_QUEUE_1);
        scene->setLastRenderQueue(Ogre::RENDER_QUEUE_9);
        b.endNode();
        b._setDepth(DEPTH_TEXTURE);
    }
    //-----------------------------------------------------------------------
    bool CysPostFxPipeline::build(const std::vector<CysPostFxStage*>& active, std::vector<size_t>& failed)
    {
        Ogre::CompositorManager& cm = Ogre::CompositorManager::getSingleton();
        const size_t w = (size_t)std::max(1, mViewport->getActualWidth());
        const size_t h = (size_t)std::max(1, mViewport->getActualHeight());

        mCompositorName = "CysPostFX/Pipeline/" + StringConverter::toString(++gSerial);
        Ogre::CompositorPtr comp = cm.create(mCompositorName, Ogre::ResourceGroupManager::INTERNAL_RESOURCE_GROUP_NAME);
        mCompositorResources.push_back(mCompositorName);
        Ogre::CompositionTechnique* t = comp->createTechnique();

        CysPostFxBuilder b(*this, t, w, h);
        const Ogre::PixelFormat colour = mHdr ? Ogre::PF_FLOAT16_RGBA : Ogre::PF_A8R8G8B8;
        b._setColourFormat(colour);
        b._define("rt_ping", colour, 1.0f, 0, 0);
        b._define("rt_pong", colour, 1.0f, 0, 0);

        // render nodes
        bool depth = false;
        const bool intz = intzSceneDepth();
        for (size_t i = 0; i < active.size(); ++i)          // CYS-PARITY (L2): INTZ readers need no depth node
            depth = depth || (active[i]->needsDepth() && !(intz && active[i]->supportsIntzDepth()));
        if (depth)
        {
            b._setStage(0);
            buildDepthNode(b);
        }
        for (size_t i = 0; i < active.size(); ++i)
        {
            b._setStage((Ogre::uint32)(i + 1));
            active[i]->buildNode(b);
            b.endNode();
        }

        // scene colour: our own clear + render_scene over every queue (OGRE's implicit "Ogre/Scene" would drop
        // RENDER_QUEUE_BACKGROUND and, from the second compile on, lose the viewport clear)
        b._setStage(0);
        Ogre::CompositionTargetPass* tp = b._target("rt_ping");
        tp->setMaterialScheme(mViewport->getMaterialScheme());
        mClearColour = mViewport->getBackgroundColour();
        mClearPass = tp->createPass();
        mClearPass->setType(Ogre::CompositionPass::PT_CLEAR);
        mClearPass->setClearBuffers(Ogre::FBT_COLOUR | Ogre::FBT_DEPTH | Ogre::FBT_STENCIL);
        mClearPass->setClearColour(mClearColour);
        mClearPass->setClearDepth(1.0f);
        Ogre::CompositionPass* scene = tp->createPass();
        scene->setType(Ogre::CompositionPass::PT_RENDERSCENE);
        scene->setFirstRenderQueue(Ogre::RENDER_QUEUE_BACKGROUND);
        scene->setLastRenderQueue((Ogre::uint8)(Ogre::RENDER_QUEUE_OVERLAY - 1));

        // stages, ping-ponging between the two viewport-sized targets
        String cur = "rt_ping", spare = "rt_pong";
        for (size_t i = 0; i < active.size(); ++i)
        {
            b._setStage((Ogre::uint32)(i + 1));
            const String r = active[i]->buildChain(b, cur, spare);
            if (r == spare)
                std::swap(cur, spare);
            else if (r != cur)
                b._error("buildChain returned '" + r + "', neither its input nor the free target");
        }

        // output: current target -> back buffer (dithered only from FP16)
        b._setStage(0);
        Ogre::CompositionTargetPass* out = t->getOutputTargetPass();
        out->setInputMode(Ogre::CompositionTargetPass::IM_NONE);
        const String finalInput[1] = { cur };
        b._quad(out, "CysPostFX/Final", ID_FINAL, finalInput, 1);

        const std::vector<String>& nodeCompositors = b._getCompositors();
        mCompositorResources.insert(mCompositorResources.end(), nodeCompositors.begin(), nodeCompositors.end());

        if (b._hasErrors())
        {
            const std::set<Ogre::uint32>& slots = b._getErrorSlots();
            for (std::set<Ogre::uint32>::const_iterator it = slots.begin(); it != slots.end(); ++it)
            {
                if (*it > 0)
                    failed.push_back(*it - 1);
            }
            teardown();
            return false;
        }

        mExternal = b._getExternalInputs();
        mSizes = b._getSizes();
        mCamera = mViewport->getCamera();
        mBuilt = active;
        mBuiltWidth = w;
        mBuiltHeight = h;

        // render nodes first: render textures, updated with the other render textures before the window
        const std::vector<CysPostFxBuilder::NodeSpec>& nodes = b._getNodes();
        for (size_t i = 0; i < nodes.size(); ++i)
        {
            if (!createNode(nodes[i]))
            {
                teardown();
                return false;
            }
        }

        mInstance = cm.addCompositor(mViewport, mCompositorName, 0);
        if (!mInstance)
        {
            CysPostFxUtil::log("CysPostFX: the pipeline compositor is not supported (render target formats?)");
            teardown();
            return false;
        }
        mInstance->addListener(this);
        mInstance->setEnabled(true);
        const std::set<String>& mainTextures = b._getMainTextures();
        for (std::set<String>::const_iterator it = mainTextures.begin(); it != mainTextures.end(); ++it)
            mRealNames[*it] = mInstance->getTextureInstanceName(*it);
        if (intz)   // CYS-PARITY (L2): the scene target renders with the INTZ depth-stencil texture
        {
            Ogre::TexturePtr ping = Ogre::TextureManager::getSingleton().getByName(mRealNames["rt_ping"]);
            Ogre::RenderSystem* rs = Ogre::Root::getSingleton().getRenderSystem();
            if (!ping.isNull() && rs && rs->_cysSetIntzSceneDepthTarget(ping->getBuffer()->getRenderTarget()))
                mIntzRegistered = true;
            else
                CysPostFxUtil::log("CysPostFX: INTZ scene depth could not be attached to rt_ping");
        }

        String summary = "CysPostFX: pipeline " + mCompositorName + " " + StringConverter::toString(w) + "x" +
            StringConverter::toString(h) + (mHdr ? " FP16" : " RGBA8") + (mIntzRegistered ? " DS INTZ" : "") + ", " + StringConverter::toString(active.size()) +
            " filter(s)";
        for (size_t i = 0; i < mNodes.size(); ++i)
        {
            size_t nw = 0, nh = 0;
            getTextureSize(mNodes[i].textureName, nw, nh);
            summary += ", node " + mNodes[i].textureName + " " + StringConverter::toString(nw) + "x" +
                       StringConverter::toString(nh);
        }
        CysPostFxUtil::log(summary);
        for (size_t i = 0; i < active.size(); ++i)
        {
            CysPostFxUtil::log("CysPostFX:   " + StringConverter::toString(i + 1) + ". " + active[i]->getType() +
                               " '" + active[i]->getName() + "' order " + StringConverter::toString(active[i]->getOrder()));
            active[i]->onBuilt(*this);
        }
        return true;
    }
    //-----------------------------------------------------------------------
    bool CysPostFxPipeline::createNode(const CysPostFxBuilder::NodeSpec& spec)
    {
        Ogre::TextureManager& tm = Ogre::TextureManager::getSingleton();
        if (!tm.getByName(spec.textureName).isNull())
            tm.remove(spec.textureName);            // placeholder of the material system, or our own

        Node n;
        n.textureName = spec.textureName;
        n.compositorName = spec.compositorName;
        n.viewport = 0;
        n.instance = 0;
        try
        {
            n.texture = tm.createManual(spec.textureName, Ogre::ResourceGroupManager::INTERNAL_RESOURCE_GROUP_NAME,
                                        Ogre::TEX_TYPE_2D, (Ogre::uint)spec.width, (Ogre::uint)spec.height, 0,
                                        spec.format, Ogre::TU_RENDERTARGET);
        }
        catch (Ogre::Exception& e)
        {
            CysPostFxUtil::log("CysPostFX: render node " + spec.textureName + " failed: " + e.getDescription());
            createPlaceholder(spec.textureName, mDepthFar);
            return false;
        }
        Ogre::RenderTexture* rt = n.texture->getBuffer()->getRenderTarget();
        rt->setAutoUpdated(true);                   // render textures are updated before the windows
        Ogre::Camera* cam = mViewport->getCamera();
        Ogre::Viewport* oldViewport = cam->getViewport();
        const Real aspect = cam->getAspectRatio();
        n.viewport = rt->addViewport(cam);
        cam->setAspectRatio(aspect);                // as CompositorInstance::createResources: do not disturb
        cam->_notifyViewport(oldViewport);          // the camera of the main viewport
        n.viewport->setClearEveryFrame(false);
        n.viewport->setOverlaysEnabled(false);
        n.viewport->setShadowsEnabled(false);
        n.viewport->setSkiesEnabled(false);
        mNodes.push_back(n);

        Node& node = mNodes.back();
        node.instance = Ogre::CompositorManager::getSingleton().addCompositor(node.viewport, node.compositorName);
        if (!node.instance)
        {
            CysPostFxUtil::log("CysPostFX: render node " + spec.textureName + ": compositor not supported");
            return false;
        }
        node.instance->addListener(this);
        node.instance->setEnabled(true);
        if (spec.textureName == DEPTH_TEXTURE)
            mDepthViewport = node.viewport;
        return true;
    }
    //-----------------------------------------------------------------------
    void CysPostFxPipeline::destroyNodes(void)
    {
        Ogre::CompositorManager* cm = Ogre::CompositorManager::getSingletonPtr();
        Ogre::TextureManager* tm = Ogre::TextureManager::getSingletonPtr();
        for (size_t i = mNodes.size(); i-- > 0;)
        {
            Node& n = mNodes[i];
            if (n.instance)
                n.instance->removeListener(this);
            // the chain is keyed by the viewport: delete it before the render texture (and viewport) goes
            if (cm && n.viewport && cm->hasCompositorChain(n.viewport))
                cm->removeCompositorChain(n.viewport);
            n.instance = 0;
            n.viewport = 0;
            if (!n.texture.isNull())
            {
                n.texture.setNull();
                if (tm)
                    tm->remove(n.textureName);
            }
            if (tm)
                createPlaceholder(n.textureName, mDepthFar);
        }
        mNodes.clear();
        mDepthViewport = 0;
    }
    //-----------------------------------------------------------------------
    void CysPostFxPipeline::teardown(void)
    {
        Ogre::CompositorManager* cm = Ogre::CompositorManager::getSingletonPtr();
        if (mIntzRegistered)    // CYS-PARITY (L2): before rt_ping goes
        {
            Ogre::RenderSystem* rs = Ogre::Root::getSingletonPtr() ? Ogre::Root::getSingleton().getRenderSystem() : 0;
            if (rs)
                rs->_cysSetIntzSceneDepthTarget(0);
            mIntzRegistered = false;
        }
        if (mInstance)
        {
            mInstance->removeListener(this);
            if (cm && cm->hasCompositorChain(mViewport))
                cm->removeCompositor(mViewport, mCompositorName);
            mInstance = 0;
        }
        destroyNodes();
        if (cm)
        {
            for (size_t i = 0; i < mCompositorResources.size(); ++i)
                cm->remove(mCompositorResources[i]);
        }
        mCompositorResources.clear();
        mCompositorName.clear();
        mBuilt.clear();
        mRealNames.clear();
        mSizes.clear();
        mExternal.clear();
        mClearPass = 0;
        if (mDepthMaterials)
            mDepthMaterials->clearCache();
        hdrProvider().set(this, false);             // NewHDRBloom asks again in onBuilt
    }
    //-----------------------------------------------------------------------
    void CysPostFxPipeline::notifyMaterialSetup(Ogre::uint32 passId, Ogre::MaterialPtr& mat)
    {
        std::map<Ogre::uint32, CysPostFxBuilder::ExternalInputs>::const_iterator e = mExternal.find(passId);
        if (e != mExternal.end() && !mat.isNull() && mat->getNumTechniques() > 0)
        {
            Ogre::Technique* t = mat->getTechnique(0);
            for (unsigned short pi = 0; pi < t->getNumPasses(); ++pi)
            {
                Ogre::Pass* p = t->getPass(pi);
                for (size_t k = 0; k < e->second.size(); ++k)
                {
                    const unsigned short unit = e->second[k].first;
                    if (unit < p->getNumTextureUnitStates())
                        p->getTextureUnitState(unit)->setTextureName(e->second[k].second);
                    else
                        CysPostFxUtil::log("CysPostFX: material " + mat->getName() + " has no texture unit " +
                                           StringConverter::toString(unit) + " for " + e->second[k].second);
                }
            }
        }
        const Ogre::uint32 slot = passId >> 16;
        if (slot > 0 && slot <= mBuilt.size())
            mBuilt[slot - 1]->onMaterialSetup(passId & 0xFFFF, mat);
    }
    //-----------------------------------------------------------------------
    void CysPostFxPipeline::notifyMaterialRender(Ogre::uint32 passId, Ogre::MaterialPtr& mat)
    {
        const Ogre::uint32 slot = passId >> 16;
        const Ogre::uint32 local = passId & 0xFFFF;
        if (CysPostFx::_hasPassObserver())          // CYS fx-render: GPU profiling (CysPostFxTest --bench)
        {
            static const String kPipeline("Pipeline");
            CysPostFx::_notifyPass((slot == 0 || slot > mBuilt.size()) ? kPipeline : mBuilt[slot - 1]->getType(), local);
        }
        if (slot == 0)
        {
            Ogre::GpuProgramParametersSharedPtr fp = CysPostFxUtil::fragmentParams(mat);
            if (local == ID_DEPTH_CLEAR)
                CysPostFxUtil::setConst(fp, "farValue", mDepthFar);
            else if (local == ID_FINAL)                 // CYS fx-render: 8-bit source = B's plain FrameCopy
                CysPostFxUtil::setConst(fp, "ditherAmount", (mHdr && gCinematic) ? mDither : 0.0f); // CYS-PARITY: CY copies without dither
            return;
        }
        if (slot <= mBuilt.size())
            mBuilt[slot - 1]->onMaterialRender(local, mat);
    }
    //-----------------------------------------------------------------------
    void CysPostFxPipeline::renderQueueStarted(Ogre::uint8 queueGroupId, const String& invocation, bool& skipThisInvocation)
    {
        if (!mDepthViewport || !mSceneManager || mSceneManager->getCurrentViewport() != mDepthViewport)
            return;
        if (queueGroupId < Ogre::RENDER_QUEUE_1 || queueGroupId > Ogre::RENDER_QUEUE_9)
            return;
        Ogre::RenderQueueGroup* group = mSceneManager->getRenderQueue()->getQueueGroup(queueGroupId);
        if (group)
            requeueForDepth(group);
    }
    //-----------------------------------------------------------------------
    void CysPostFxPipeline::renderQueueEnded(Ogre::uint8 queueGroupId, const String& invocation, bool& repeatThisInvocation)
    {
    }
    //-----------------------------------------------------------------------
    void CysPostFxPipeline::requeueForDepth(Ogre::RenderQueueGroup* group)
    {
        // Replace the queued techniques by depth techniques (and drop what must not write depth) before the group
        // renders: the depth target then gets linear depth from every opaque renderable whatever its material.
        mQueueScratch.clear();
        Ogre::RenderQueueGroup::PriorityMapIterator pit = group->getIterator();
        while (pit.hasMoreElements())
        {
            const Ogre::ushort priority = pit.peekNextKey();
            Ogre::RenderPriorityGroup* pg = pit.getNext();
            mRenderableScratch.clear();
            CollectRenderables v(mRenderableScratch);
            pg->getSolidsBasic().acceptVisitor(&v, Ogre::QueuedRenderableCollection::OM_PASS_GROUP);
            pg->getSolidsDiffuseSpecular().acceptVisitor(&v, Ogre::QueuedRenderableCollection::OM_PASS_GROUP);
            pg->getSolidsDecal().acceptVisitor(&v, Ogre::QueuedRenderableCollection::OM_PASS_GROUP);
            pg->getSolidsNoShadowReceive().acceptVisitor(&v, Ogre::QueuedRenderableCollection::OM_PASS_GROUP);
            std::sort(mRenderableScratch.begin(), mRenderableScratch.end());
            mRenderableScratch.erase(std::unique(mRenderableScratch.begin(), mRenderableScratch.end()),
                                     mRenderableScratch.end());
            for (size_t i = 0; i < mRenderableScratch.size(); ++i)
                mQueueScratch.push_back(std::make_pair(mRenderableScratch[i], priority));
        }
        group->clear(false);
        for (size_t i = 0; i < mQueueScratch.size(); ++i)
        {
            Ogre::Technique* t = mDepthMaterials->choose(mQueueScratch[i].first);
            if (t)
                group->addRenderable(mQueueScratch[i].first, t, mQueueScratch[i].second);
        }
    }
}
