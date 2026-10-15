// CY-Source (water-cy agent, 2026-09-14): see CysWaterRender.h and Docs/specs/render/water-cy_vi.md.
#include "CysWaterRender.h"

#include "Core/WXSystem.h"
#include "Core/WXTerrainLiquidObject.h"
#include "PostFilter/WXPostFilterManager.h"
#include "PostFilter/WXPostFilters.h"
#include "CYS/PostFX/CysPostFx.h"
#include "CYS/PostFX/CysPostFxStage.h"
#include "CYS/PostFX/CysPostFxDepth.h"
#include "CYS/PostFX/CysPostFxPipeline.h"   // CYS-PARITY: parityFp16

#include <OgreRoot.h>
#include <OgreRenderSystem.h>
#include <OgreRenderSystemCapabilities.h>
#include <OgreSceneManager.h>
#include <OgreCamera.h>
#include <OgreViewport.h>
#include <OgreRenderTexture.h>
#include <OgreHardwarePixelBuffer.h>
#include <OgreTextureManager.h>
#include <OgreMaterialManager.h>
#include <OgreTechnique.h>
#include <OgrePass.h>
#include <OgreGpuProgram.h>
#include <OgreTextureUnitState.h>
#include <OgreRenderQueue.h>
#include <OgreRenderQueueSortingGrouping.h>
#include <OgreStringConverter.h>
#include <OgreTimer.h>
#include <OgreException.h>

#include <cstdlib>
#include <cstring>
#include <cmath>

namespace WX
{
    const String CysWaterRender::SCENE_BUFFER_TEXTURE("CYS/Compositor/SceneRender/scene_buffer");
    const String CysWaterRender::MIRROR_TEXTURE("waterMirrorReflectTex");
    const String CysWaterRender::MIRROR_CAMERA("ReflectRTCamera");
    const String CysWaterRender::POSTFX_STAGE_TYPE("Water");

    namespace
    {
        CysWaterRender* gInstance = 0;

        const Ogre::uint8 QUEUE_WATER_SURFACE = 77;     // CY 'M' (FUN_1801ef510, FUN_18021e7b0 pass 6: 77..85)

        void waterLog(const String& message)
        {
            CysPostFxUtil::log("CYS water: " + message);
        }

        String environmentValue(const char* name)
        {
            const char* v = std::getenv(name);
            return v ? String(v) : String();
        }

        double nowMs(void)
        {
            Ogre::Root* root = Ogre::Root::getSingletonPtr();
            Ogre::Timer* timer = root ? root->getTimer() : 0;
            return timer ? timer->getMicroseconds() / 1000.0 : 0.0;
        }

        /// "Water" post-FX stage (CY post filter name): no passes of its own, it keeps the depth node
        /// (SceneDepthForWater) and the scene render target alive while new water exists.
        class CysWaterStage : public CysPostFxStage
        {
        public:
            CysWaterStage(const String& name, const String& type)
                : CysPostFxStage(name, type, 1)
            {
            }

            bool needsDepth(void) const { return true; }
            // CYS-PARITY (L2): water fog / FakeLight boxes take CY's _DSIntZ materials (CYSScene::chooseWaterMaterial,
            // CYSFakeLightObject) and read the INTZ scene depth
            bool supportsIntzDepth(void) const { return true; }

            bool isActive(void) const
            {
                CysWaterRender* water = CysWaterRender::getSingletonPtr();
                return water && water->needsDepthNode(); // CYS-PARITY: FakeLight boxes read the depth too
            }

            String buildChain(CysPostFxBuilder& b, const String& input, const String& free)
            {
                return input;
            }
        };

        /// Stops at the first queued renderable.
        class AnyRenderable : public Ogre::QueuedRenderableVisitor
        {
        public:
            AnyRenderable() : found(false) {}
            void visit(const Ogre::RenderablePass* rp) { found = true; }
            bool visit(const Ogre::Pass* p) { return !found; }
            void visit(const Ogre::Renderable* r) { found = true; }
            bool found;
        };

        bool groupHasRenderables(Ogre::RenderQueueGroup* group)
        {
            if (!group)
                return false;
            Ogre::RenderQueueGroup::PriorityMapIterator pit = group->getIterator();
            while (pit.hasMoreElements())
            {
                Ogre::RenderPriorityGroup* pg = pit.getNext();
                AnyRenderable v;
                pg->getSolidsBasic().acceptVisitor(&v, Ogre::QueuedRenderableCollection::OM_PASS_GROUP);
                if (!v.found)
                    pg->getSolidsDiffuseSpecular().acceptVisitor(&v, Ogre::QueuedRenderableCollection::OM_PASS_GROUP);
                if (!v.found)
                    pg->getSolidsDecal().acceptVisitor(&v, Ogre::QueuedRenderableCollection::OM_PASS_GROUP);
                if (!v.found)
                    pg->getSolidsNoShadowReceive().acceptVisitor(&v, Ogre::QueuedRenderableCollection::OM_PASS_GROUP);
                if (!v.found)
                    pg->getTransparents().acceptVisitor(&v, Ogre::QueuedRenderableCollection::OM_SORT_DESCENDING);
                if (v.found)
                    return true;
            }
            return false;
        }

        Ogre::Technique* effectTechnique(const Ogre::MaterialPtr& material)
        {
            if (material.isNull())
                return 0;
            Ogre::Material* m = const_cast<Ogre::Material*>(material.get());
            for (unsigned short i = 0; i < m->getNumTechniques(); ++i)
            {
                Ogre::Technique* t = m->getTechnique(i);
                if (t && t->getName() == "Effect")
                    return t;
            }
            return m->getNumTechniques() > 1 ? m->getTechnique(1) : 0;
        }
    }

    PostFilterFactory* getCysWaterFactory(void)
    {
        static CysPostFxFactory<CysWaterStage> f("Water");
        return &f;
    }

    //-----------------------------------------------------------------------
    CysWaterRender* CysWaterRender::install(System* system)
    {
        if (!system)
            return 0;
        if (gInstance && gInstance->mSystem == system)
            return gInstance;
        uninstall();
        try
        {
            gInstance = new CysWaterRender(system);
            CYSScene::setWaterRenderHooks(gInstance);
            waterLog("installed: " + gInstance->describe());
        }
        catch (const Ogre::Exception& e)
        {
            waterLog("install failed: " + e.getFullDescription());
            delete gInstance;
            gInstance = 0;
        }
        return gInstance;
    }
    //-----------------------------------------------------------------------
    void CysWaterRender::uninstall(void)
    {
        if (!gInstance)
            return;
        if (CYSScene::getWaterRenderHooks() == gInstance)
            CYSScene::setWaterRenderHooks(0);
        waterLog("uninstalled: " + gInstance->describe());
        delete gInstance;
        gInstance = 0;
    }
    //-----------------------------------------------------------------------
    CysWaterRender* CysWaterRender::getSingletonPtr(void)
    {
        return gInstance;
    }
    //-----------------------------------------------------------------------
    CysWaterRender::CysWaterRender(System* system)
        : mSystem(system)
        , mSceneManager(0)
        , mEnabled(true)
        , mDepthUsers(0)
        , mMirrorEnabled(true)
        , mMirrorSize(1024)             // CY: 0x400 x 0x400 (FUN_18011ef40)
        , mSurfaceQueued(false)
        , mMirrorQueued(false)
        , mMirrorSeenThisFrame(false)
        , mMirrorLegacy(environmentValue("CYS_WATER_MIRROR_LEGACY") == "1")
        , mMirrorLog(environmentValue("CYS_WATER_MIRROR_LOG") == "1")
        , mMeshSurfaces(0)
        , mMirrorCamera(0)
        , mMirrorListener(*this)
        , mMirrorPlane(Ogre::Vector3::UNIT_Y, 0)
        , mMirrorActive(false)
        , mMirrorStart(0)
        , mLoggedCopyFailure(false)
    {
        std::memset(&mStats, 0, sizeof(mStats));
        const String water = environmentValue("CYS_WATER");
        if (!water.empty() && water[0] == '0')
            mEnabled = false;
        const String mirror = environmentValue("CYS_WATER_MIRROR");
        if (!mirror.empty() && mirror[0] == '0')
            mMirrorEnabled = false;
        const String size = environmentValue("CYS_WATER_MIRROR_SIZE");
        if (!size.empty())
        {
            const int s = std::atoi(size.c_str());
            if (s >= 64 && s <= 4096)
                mMirrorSize = (size_t)s;
        }
        Ogre::Root::getSingleton().addFrameListener(this);
    }
    //-----------------------------------------------------------------------
    CysWaterRender::~CysWaterRender()
    {
        if (Ogre::Root* root = Ogre::Root::getSingletonPtr())
            root->removeFrameListener(this);
        releaseMirror();
        releaseSceneBuffer();
        detachSceneManager();
    }
    //-----------------------------------------------------------------------
    String CysWaterRender::describe(void) const
    {
        return String("enabled=") + (mEnabled ? "1" : "0") + " supported=" + (supportsNewWater() ? "1" : "0") +
               " mirror=" + (mMirrorEnabled ? "1" : "0") + " mirror_size=" + Ogre::StringConverter::toString(mMirrorSize) +
               " liquids=" + Ogre::StringConverter::toString(mStats.liquids) +
               " mirrors=" + Ogre::StringConverter::toString(mStats.mirrors) +
               " copies=" + Ogre::StringConverter::toString((unsigned long)mStats.copies) +
               " copy_failures=" + Ogre::StringConverter::toString((unsigned long)mStats.copyFailures) +
               " copy_cpu_ms=" + Ogre::StringConverter::toString((Real)mStats.copyMs) +
               " mirror_updates=" + Ogre::StringConverter::toString((unsigned long)mStats.mirrorUpdates) +
               " mirror_visible_frames=" + Ogre::StringConverter::toString(mStats.mirrorVisibleFrames) +
               " mirror_activity_changes=" + Ogre::StringConverter::toString(mStats.mirrorActivityChanges) +
               " mirror_legacy=" + (mMirrorLegacy ? "1" : "0") +
               " mirror_cpu_ms=" + Ogre::StringConverter::toString((Real)mStats.mirrorMs) +
               " scene_buffer=" + Ogre::StringConverter::toString(mStats.sceneBufferWidth) + "x" +
               Ogre::StringConverter::toString(mStats.sceneBufferHeight);
    }
    //-----------------------------------------------------------------------
    void CysWaterRender::setEnabled(bool enabled)
    {
        if (enabled == mEnabled)
            return;
        mEnabled = enabled;
        waterLog(String("new water ") + (enabled ? "enabled" : "disabled") +
                 " (takes effect when the liquids are created again)");
    }
    //-----------------------------------------------------------------------
    bool CysWaterRender::supportsNewWater(void) const
    {
        if (!mEnabled)
            return false;
        Ogre::Root* root = Ogre::Root::getSingletonPtr();
        Ogre::RenderSystem* rs = root ? root->getRenderSystem() : 0;
        const Ogre::RenderSystemCapabilities* caps = rs ? rs->getCapabilities() : 0;
        if (!caps || !caps->hasCapability(Ogre::RSC_FRAGMENT_PROGRAM))
            return false;
        // the water programs are ps_3_0 / vs_3_0 (WaterReflectionReraction.hlsl, Model_Water_ps.hlsl)
        const String& ps = caps->getMaxFragmentProgramVersion();
        return ps.size() >= 6 && ps.compare(0, 3, "ps_") == 0 && ps[3] >= '3';
    }
    //-----------------------------------------------------------------------
    void CysWaterRender::liquidCreated(TerrainLiquidObject& liquid, const Ogre::MaterialPtr& material)
    {
        if (material.isNull())
            return;
        const String& name = material->getName();
        const bool newWater = name.find("shader") != String::npos || name.find("PBRScene_Water") != String::npos;
        if (!newWater || !supportsNewWater())
            return;

        for (size_t i = 0; i < mLiquids.size(); ++i)
        {
            if (mLiquids[i].liquid == &liquid)
            {
                mLiquids.erase(mLiquids.begin() + i);
                break;
            }
        }
        Entry e;
        e.liquid = &liquid;
        e.material = name;
        e.mirror = name.find("mirror") != String::npos;     // CY FUN_18011ef40: find("mirror")
        e.height = liquid.mPosition.y;
        mLiquids.push_back(e);
        if (!liquid.mCYSWater.meshName.empty())
            ++mMeshSurfaces;

        attachSceneManager();
        ensurePostFxStage();
        applyDebug(material);
        if (e.mirror && mMirrorEnabled && ensureMirror())
            bindMirrorTexture(material);

        mStats.liquids = mLiquids.size();
        mStats.mirrors = 0;
        for (size_t i = 0; i < mLiquids.size(); ++i)
            mStats.mirrors += mLiquids[i].mirror ? 1 : 0;
        if (mStats.liquids == 1)
            waterLog("first new-water liquid: material " + name + (e.mirror ? " (mirror)" : ""));
    }
    //-----------------------------------------------------------------------
    // Diagnostics only (CYS_WATER_DEBUG=fog,surface,log): exaggerated constants make each pass visible on its own.
    void CysWaterRender::applyDebug(const Ogre::MaterialPtr& material)
    {
        const String debug = environmentValue("CYS_WATER_DEBUG");
        if (debug.empty())
            return;
        const bool fog = debug.find("fog") != String::npos;
        const bool surface = debug.find("surface") != String::npos;
        Ogre::Material* m = const_cast<Ogre::Material*>(material.get());
        for (unsigned short t = 0; t < m->getNumTechniques(); ++t)
        {
            Ogre::Technique* tech = m->getTechnique(t);
            waterLog("debug: " + m->getName() + " technique " + Ogre::StringConverter::toString(t) + " '" +
                     tech->getName() + "' supported=" + (tech->isSupported() ? "1" : "0") + " passes=" +
                     Ogre::StringConverter::toString(tech->getNumPasses()));
            for (unsigned short p = 0; p < tech->getNumPasses(); ++p)
            {
                Ogre::Pass* pass = tech->getPass(p);
                if (!pass->hasFragmentProgram())
                    continue;
                Ogre::GpuProgramParametersSharedPtr params = pass->getFragmentProgramParameters();
                try
                {
                    if (fog && t == 0)
                        params->setNamedConstant("FogColorDensity", Ogre::Vector4(1, 0, 0, 200000));
                    if (surface && t == 1)
                    {
                        params->setNamedConstant("SunShinePow", Ogre::Vector4(1, 0, 0, 0));
                        params->setNamedConstant("SunMultiplier", Ogre::Vector4(5, 0, 0, 0));
                    }
                }
                catch (const Ogre::Exception& e)
                {
                    waterLog("debug: " + e.getDescription());
                }
            }
        }
    }
    //-----------------------------------------------------------------------
    void CysWaterRender::liquidDestroyed(TerrainLiquidObject& liquid)
    {
        for (size_t i = 0; i < mLiquids.size(); ++i)
        {
            if (mLiquids[i].liquid == &liquid)
            {
                if (!liquid.mCYSWater.meshName.empty() && mMeshSurfaces > 0)
                    --mMeshSurfaces;
                mLiquids.erase(mLiquids.begin() + i);
                break;
            }
        }
        mStats.liquids = mLiquids.size();
        mStats.mirrors = 0;
        for (size_t i = 0; i < mLiquids.size(); ++i)
            mStats.mirrors += mLiquids[i].mirror ? 1 : 0;
        if (mStats.mirrors == 0 && !mMirrorTexture.isNull())
            releaseMirror();
        if (mLiquids.empty())
            waterLog("scene without new water: " + describe());
    }
    //-----------------------------------------------------------------------
    void CysWaterRender::attachSceneManager(void)
    {
        Ogre::SceneManager* sm = mSystem ? mSystem->getSceneManager() : 0;
        if (sm == mSceneManager)
            return;
        detachSceneManager();
        if (sm)
        {
            sm->addRenderQueueListener(this);
            mSceneManager = sm;
        }
    }
    //-----------------------------------------------------------------------
    void CysWaterRender::detachSceneManager(void)
    {
        if (mSceneManager)
        {
            mSceneManager->removeRenderQueueListener(this);
            mSceneManager = 0;
        }
    }
    //-----------------------------------------------------------------------
    void CysWaterRender::addDepthUser(void)
    {
        if (++mDepthUsers == 1)
            ensurePostFxStage();
    }
    //-----------------------------------------------------------------------
    void CysWaterRender::removeDepthUser(void)
    {
        if (mDepthUsers > 0)
            --mDepthUsers;
    }
    //-----------------------------------------------------------------------
    void CysWaterRender::ensurePostFxStage(void)
    {
        PostFilterManager* filters = mSystem ? mSystem->getPostFilterManager() : 0;
        Ogre::Viewport* vp = mSystem ? mSystem->getViewport() : 0;
        if (!filters || !vp)
            return;
        try
        {
            if (filters->getFactoryList().find(POSTFX_STAGE_TYPE) == filters->getFactoryList().end())
            {
                if (filters->getFactoryList().empty())
                    registerAllPostFilterFactories(filters);
                else
                    CysPostFx::registerFactories(filters);
            }
            PostFilter* stage = CysPostFx::ensureFilter(filters, vp, POSTFX_STAGE_TYPE);
            if (stage && !stage->getEnabled())
                stage->setEnabled(true);
            if (!stage)
                waterLog("post filter 'Water' not available: no depth node (water fog / refraction depth read 0)");
        }
        catch (const Ogre::Exception& e)
        {
            waterLog("post filter 'Water': " + e.getDescription());
        }
    }
    //-----------------------------------------------------------------------
    bool CysWaterRender::ensureSceneBuffer(size_t width, size_t height)
    {
        if (width == 0 || height == 0)
            return false;
        // CYS-PARITY: the copy destination has the format of the scene target (StretchRect cannot convert FP16 to
        // RGBA8); FACT trace: CY's refraction input (rt4) is A16B16G16R16F.
        const Ogre::PixelFormat format = CysPostFxPipeline::parityFp16() ? Ogre::PF_FLOAT16_RGBA : Ogre::PF_A8R8G8B8;
        if (!mSceneBuffer.isNull() && mSceneBuffer->getWidth() == width && mSceneBuffer->getHeight() == height &&
            mSceneBuffer->getFormat() == format)
            return true;
        releaseSceneBuffer();
        try
        {
            // CY: SceneRender scene_buffer, format 0xc = PF_A8R8G8B8, 1.0 x 1.0 of the viewport (FUN_18021e7b0)
            mSceneBuffer = Ogre::TextureManager::getSingleton().createManual(SCENE_BUFFER_TEXTURE,
                Ogre::ResourceGroupManager::INTERNAL_RESOURCE_GROUP_NAME, Ogre::TEX_TYPE_2D,
                (Ogre::uint)width, (Ogre::uint)height, 0, format, Ogre::TU_RENDERTARGET);
            Ogre::RenderTarget* rt = mSceneBuffer->getBuffer()->getRenderTarget();
            rt->setAutoUpdated(false);      // a copy destination only
            mStats.sceneBufferWidth = width;
            mStats.sceneBufferHeight = height;
            return true;
        }
        catch (const Ogre::Exception& e)
        {
            waterLog("scene_buffer " + Ogre::StringConverter::toString(width) + "x" +
                     Ogre::StringConverter::toString(height) + " not created: " + e.getDescription());
            mSceneBuffer.setNull();
            return false;
        }
    }
    //-----------------------------------------------------------------------
    void CysWaterRender::releaseSceneBuffer(void)
    {
        if (mSceneBuffer.isNull())
            return;
        const String name = mSceneBuffer->getName();
        mSceneBuffer.setNull();
        if (Ogre::TextureManager::getSingletonPtr())
            Ogre::TextureManager::getSingleton().remove(name);
        mStats.sceneBufferWidth = mStats.sceneBufferHeight = 0;
    }
    //-----------------------------------------------------------------------
    bool CysWaterRender::ensureMirror(void)
    {
        if (!mMirrorTexture.isNull())
            return true;
        Ogre::SceneManager* sm = mSystem ? mSystem->getSceneManager() : 0;
        if (!sm)
            return false;
        try
        {
            // CY: createManual("waterMirrorReflectTex", 2d, 1024, 1024, depth 1, 0 mips, format 0xb, TU_RENDERTARGET)
            mMirrorTexture = Ogre::TextureManager::getSingleton().createManual(MIRROR_TEXTURE,
                Ogre::ResourceGroupManager::INTERNAL_RESOURCE_GROUP_NAME, Ogre::TEX_TYPE_2D,
                (Ogre::uint)mMirrorSize, (Ogre::uint)mMirrorSize, 0, Ogre::PF_X8R8G8B8, Ogre::TU_RENDERTARGET);
            mMirrorCamera = sm->hasCamera(MIRROR_CAMERA) ? sm->getCamera(MIRROR_CAMERA) : sm->createCamera(MIRROR_CAMERA);
            mMirrorCamera->setAutoAspectRatio(false);
            Ogre::RenderTarget* rt = mMirrorTexture->getBuffer()->getRenderTarget();
            Ogre::Viewport* vp = rt->addViewport(mMirrorCamera);
            vp->setOverlaysEnabled(false);
            vp->setClearEveryFrame(true, Ogre::FBT_COLOUR | Ogre::FBT_DEPTH);
            vp->setSkiesEnabled(false);
            vp->setShadowsEnabled(true);
            vp->setBackgroundColour(Ogre::ColourValue::White);
            rt->addListener(&mMirrorListener);
            rt->setAutoUpdated(true);
            waterLog("mirror render texture " + MIRROR_TEXTURE + " " + Ogre::StringConverter::toString(mMirrorSize) +
                     "x" + Ogre::StringConverter::toString(mMirrorSize) + " created");
            return true;
        }
        catch (const Ogre::Exception& e)
        {
            waterLog("mirror render texture not created: " + e.getDescription());
            releaseMirror();
            return false;
        }
    }
    //-----------------------------------------------------------------------
    void CysWaterRender::releaseMirror(void)
    {
        if (!mMirrorTexture.isNull())
        {
            try
            {
                Ogre::RenderTarget* rt = mMirrorTexture->getBuffer()->getRenderTarget();
                rt->removeListener(&mMirrorListener);
                rt->removeAllViewports();
            }
            catch (const Ogre::Exception&)
            {
            }
            const String name = mMirrorTexture->getName();
            mMirrorTexture.setNull();
            if (Ogre::TextureManager::getSingletonPtr())
                Ogre::TextureManager::getSingleton().remove(name);
        }
        if (mMirrorCamera)
        {
            Ogre::SceneManager* sm = mSystem ? mSystem->getSceneManager() : 0;
            if (sm && sm->hasCamera(MIRROR_CAMERA))
                sm->destroyCamera(mMirrorCamera);
            mMirrorCamera = 0;
        }
    }
    //-----------------------------------------------------------------------
    void CysWaterRender::bindMirrorTexture(const Ogre::MaterialPtr& material)
    {
        // CY: technique 1, pass 0, texture unit 1 named "ReflectTexInput" -> "waterMirrorReflectTex"
        Ogre::Technique* t = effectTechnique(material);
        if (!t || t->getNumPasses() == 0)
            return;
        Ogre::Pass* p = t->getPass(0);
        if (p->getNumTextureUnitStates() < 2)
            return;
        Ogre::TextureUnitState* tus = p->getTextureUnitState(1);
        if (tus->getTextureName() == "ReflectTexInput" || tus->getTextureName() == MIRROR_TEXTURE)
        {
            tus->setTextureName(MIRROR_TEXTURE);
            tus->setTextureAddressingMode(Ogre::TextureUnitState::TAM_CLAMP);
        }
    }
    //-----------------------------------------------------------------------
    void CysWaterRender::setLiquidsVisible(bool visible)
    {
        for (size_t i = 0; i < mLiquids.size(); ++i)
            mLiquids[i].liquid->_cysSetRenderVisible(visible);
    }
    //-----------------------------------------------------------------------
    void CysWaterRender::preMirrorUpdate(void)
    {
        mMirrorActive = false;
        mMirrorStart = nowMs();
        Ogre::Camera* main = mSystem ? mSystem->getCamera() : 0;
        if (!main || !mMirrorCamera)
            return;
        // INF (CY listener body not decompiled): the mirror plane of the mirror liquid nearest to the camera.
        const Ogre::Vector3 eye = main->getDerivedPosition();
        Real best = -1;
        Real height = 0;
        for (size_t i = 0; i < mLiquids.size(); ++i)
        {
            if (!mLiquids[i].mirror)
                continue;
            const Ogre::Vector3& p = mLiquids[i].liquid->mPosition;
            const Real d = (p.x - eye.x) * (p.x - eye.x) + (p.z - eye.z) * (p.z - eye.z);
            if (best < 0 || d < best)
            {
                best = d;
                height = p.y;
            }
        }
        if (best < 0 || eye.y <= height)
            return;     // no mirror liquid, or the camera is under its plane: clear to white only
        mMirrorPlane = Ogre::Plane(Ogre::Vector3::UNIT_Y, height);
        mMirrorCamera->setPosition(eye);
        mMirrorCamera->setOrientation(main->getDerivedOrientation());
        mMirrorCamera->setProjectionType(main->getProjectionType());
        mMirrorCamera->setFOVy(main->getFOVy());
        mMirrorCamera->setAspectRatio(main->getAspectRatio());
        mMirrorCamera->setNearClipDistance(main->getNearClipDistance());
        mMirrorCamera->setFarClipDistance(main->getFarClipDistance());
        mMirrorCamera->setLodBias(main->getLodBias());
        mMirrorCamera->enableReflection(mMirrorPlane);
        mMirrorCamera->enableCustomNearClipPlane(mMirrorPlane);
        setLiquidsVisible(false);
        mMirrorActive = true;
    }
    //-----------------------------------------------------------------------
    void CysWaterRender::postMirrorUpdate(void)
    {
        if (mMirrorActive)
        {
            setLiquidsVisible(true);
            mMirrorCamera->disableReflection();
            mMirrorCamera->disableCustomNearClipPlane();
            mMirrorActive = false;
        }
        ++mStats.mirrorUpdates;
        mStats.mirrorMs += nowMs() - mMirrorStart;
    }
    //-----------------------------------------------------------------------
    void CysWaterRender::renderQueueStarted(Ogre::uint8 queueGroupId, const String& invocation, bool& skipThisInvocation)
    {
        if (queueGroupId != QUEUE_WATER_SURFACE || !mEnabled || mLiquids.empty() || skipThisInvocation)
            return;
        Ogre::RenderSystem* rs = Ogre::Root::getSingleton().getRenderSystem();
        Ogre::Viewport* vp = rs ? rs->_getViewport() : 0;
        if (!vp || !mSystem || vp->getCamera() != mSystem->getCamera())
            return;     // the mirror texture, shadow cameras
        if (Ogre::MaterialManager::getSingleton().getActiveScheme() == CysDepthMaterials::getSchemeName())
            return;     // the depth node
        // Every compositor quad pass renders through the scene manager as well and fires this event with the main
        // camera, but without a scene traversal: only a pass that queued water (or mesh water) is the scene pass.
        if (!mSurfaceQueued && mMeshSurfaces == 0 && !groupHasRenderables(mSceneManager ?
                mSceneManager->getRenderQueue()->getQueueGroup(queueGroupId) : 0))
            return;
        if (mStats.copies < 6 && environmentValue("CYS_WATER_DEBUG").find("log") != String::npos)
        {
            waterLog("debug: queue 77 target='" + vp->getTarget()->getName() + "' scheme='" +
                     Ogre::MaterialManager::getSingleton().getActiveScheme() + "' surfaceQueued=" +
                     (mSurfaceQueued ? "1" : "0") + " mirrorQueued=" + (mMirrorQueued ? "1" : "0"));
        }
        if (mMirrorLegacy)
            updateMirrorActivity();
        mSurfaceQueued = false;

        // CY SceneRender: the scene so far (queues <= 76, the water fog included) becomes the RefractTex
        Ogre::RenderTarget* target = vp->getTarget();
        if (!target || !ensureSceneBuffer(target->getWidth(), target->getHeight()))
            return;
        const double start = nowMs();
        const bool ok = rs->_copyActiveRenderTarget(mSceneBuffer.get());
        mStats.copyMs += nowMs() - start;
        if (ok)
        {
            ++mStats.copies;
        }
        else
        {
            ++mStats.copyFailures;
            if (!mLoggedCopyFailure)
            {
                mLoggedCopyFailure = true;
                waterLog("render system cannot copy the render target: RefractTex stays empty");
            }
        }
    }
    //-----------------------------------------------------------------------
    void CysWaterRender::surfaceQueued(bool mirror)
    {
        mSurfaceQueued = true;
        mMirrorQueued = mMirrorQueued || mirror; // original per-pass state, retained for the A/B arm
        if (!mirror || !mEnabled || !mSystem)
            return;
        Ogre::RenderSystem* rs = Ogre::Root::getSingleton().getRenderSystem();
        Ogre::Viewport* vp = rs ? rs->_getViewport() : 0;
        // SceneManager sets the viewport before _findVisibleObjects queues the liquids.
        if (vp && vp->getCamera() == mSystem->getCamera() &&
            Ogre::MaterialManager::getSingleton().getActiveScheme() != CysDepthMaterials::getSchemeName())
            mMirrorSeenThisFrame = true;
    }
    //-----------------------------------------------------------------------
    bool CysWaterRender::frameStarted(const Ogre::FrameEvent& evt)
    {
        mMirrorSeenThisFrame = false;
        return true;
    }
    //-----------------------------------------------------------------------
    bool CysWaterRender::frameEnded(const Ogre::FrameEvent& evt)
    {
        if (mMirrorSeenThisFrame)
            ++mStats.mirrorVisibleFrames;
        if (!mMirrorLegacy)
            updateMirrorActivity();
        if (mMirrorLog && Ogre::Root::getSingleton().getCurrentFrameNumber() % 60 == 0)
            waterLog("mirror sample: visible=" + String(mMirrorSeenThisFrame ? "1" : "0") + " " + describe());
        return true;
    }
    //-----------------------------------------------------------------------
    // CY-Source cost guard (not in CY, INF: CY updates its mirror texture from the manager's list): the mirror
    // texture renders the whole scene once more, so it only updates while a mirror liquid is inside the main
    // camera's frustum (decided in the main pass, applied from the next frame; the texture keeps its last image).
    void CysWaterRender::updateMirrorActivity(void)
    {
        if (mMirrorTexture.isNull())
            return;
        // V2: compositor passes can fire queue 77 repeatedly without queueing any new liquid. Consume visibility
        // once per FRAME, including frames with no visible liquid. The legacy arm reproduces per-pass consumption.
        const bool visible = mMirrorLegacy ? mMirrorQueued : mMirrorSeenThisFrame;
        mMirrorQueued = false;
        Ogre::RenderTarget* rt = mMirrorTexture->getBuffer()->getRenderTarget();
        if (rt->isAutoUpdated() != visible)
        {
            rt->setAutoUpdated(visible);
            ++mStats.mirrorActivityChanges;
            if (mMirrorLog)
                waterLog(String("mirror texture updates ") + (visible ? "on (mirror water in view)" : "off (no mirror water in view)"));
        }
    }
    //-----------------------------------------------------------------------
    void CysWaterRender::renderQueueEnded(Ogre::uint8 queueGroupId, const String& invocation, bool& repeatThisInvocation)
    {
    }
}
