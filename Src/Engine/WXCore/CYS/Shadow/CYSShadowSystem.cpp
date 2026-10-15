// CY-Source (shadow agent): cascaded shadow maps. See CYSShadowSystem.h.
#include "CYSShadowSystem.h"
#include "CYSShadowFitting.h"
#include "CYSShadowPrograms.h"
#include "../Scene/CYSEnvironment.h"

#include <OgreCamera.h>
#include <OgreException.h>
#include <OgreHardwarePixelBuffer.h>
#include <OgreLight.h>
#include <OgreMaterial.h>
#include <OgreMaterialManager.h>
#include <OgrePass.h>
#include <OgreRectangle2D.h>
#include <OgreRenderSystem.h>
#include <OgreRenderTexture.h>
#include <OgreResourceGroupManager.h>
#include <OgreRoot.h>
#include <OgreSceneManager.h>
#include <OgreSceneNode.h>
#include <OgreStringConverter.h>
#include <OgreStringVector.h>
#include <OgreTechnique.h>
#include <OgreTexture.h>
#include <OgreTextureManager.h>
#include <OgreTextureUnitState.h>
#include <OgreTimer.h>
#include <OgreViewport.h>

#include <algorithm>
#include <cmath>
#include <sstream>

namespace WX
{
    namespace
    {
        const char* const kDebugMaterial = "CYS/Shadow/DebugView";

        double dotd(const Ogre::Vector3& a, const Ogre::Vector3& b)
        {
            return double(a.x) * b.x + double(a.y) * b.y + double(a.z) * b.z;
        }

        unsigned long nowMicroseconds(void)
        {
            Ogre::Root* root = Ogre::Root::getSingletonPtr();
            return (root && root->getTimer()) ? root->getTimer()->getMicroseconds() : 0;
        }

        Ogre::String str(size_t v)
        {
            return Ogre::StringConverter::toString(v);
        }
    }

    //---------------------------------------------------------------------------------------------------------------
    CYSShadowSystem::Stats::Stats(void)
        : cpuMs(0)
        , updates(0)
    {
        for (size_t i = 0; i < CYS_SHADOW_MAX_CASCADES; ++i)
            casters[i] = 0;
    }
    //---------------------------------------------------------------------------------------------------------------
    CYSShadowSystem& CYSShadowSystem::getSingleton(void)
    {
        static CYSShadowSystem instance;
        return instance;
    }
    //---------------------------------------------------------------------------------------------------------------
    CYSShadowSystem::CYSShadowSystem(void)
        : mInitialised(false)
        , mEnabled(false)
        , mTarget(0)
        , mSceneManager(0)
        , mCamera(0)
        , mHasLightOverride(false)
        , mLightOverride(0, -1, 0)
        , mLight(0)
        , mUseEnvironment(true)
        , mLightUsed(0, -1, 0)
        , mLightUsedValid(false)
        , mSink(0)
        , mPrevListener(0)
        , mListenerInstalled(false)
        , mCpuStart(0)
        , mDebugView(false)
        , mDebugRect(0)
        , mDebugNode(0)
    {
        for (size_t i = 0; i < CYS_SHADOW_MAX_CASCADES; ++i)
        {
            mCascadeCameras[i] = 0;
            mViewports[i] = 0;
        }
    }
    //---------------------------------------------------------------------------------------------------------------
    CYSShadowSystem::~CYSShadowSystem()
    {
        // Static destruction: Ogre is gone, shutdown() released everything while it was alive.
    }
    //---------------------------------------------------------------------------------------------------------------
    bool CYSShadowSystem::initialise(const CYSShadowConfig& config, const Ogre::String& resourceGroup)
    {
        CYSShadowConfig cfg = config;
        cfg.validate();
        const bool rebuild = !mInitialised || !mTarget || resourceGroup != mGroup || cfg.mapSize != mConfig.mapSize ||
                             cfg.effectiveCascades() != mConfig.effectiveCascades();
        // A size / mode change from the options must not re-enable shadows the host switched off.
        const bool enable = cfg.mode != CYSShadowConfig::MODE_OFF &&
                            (!mInitialised || cfg.mode != mConfig.mode || mEnabled);
        mConfig = cfg;
        mGroup = resourceGroup;

        Ogre::ResourceGroupManager& rgm = Ogre::ResourceGroupManager::getSingleton();
        const Ogre::StringVector groups = rgm.getResourceGroups();
        if (std::find(groups.begin(), groups.end(), mGroup) == groups.end())
            rgm.createResourceGroup(mGroup);

        mCasters.initialise(mGroup);
        mCasters.setQueueRange(mConfig.casterQueueMin, mConfig.casterQueueMax);
        mCasters.setAlphaTest(mConfig.alphaTestCasters);

        if (rebuild)
        {
            destroyDebugView();
            destroyCascadeViews();
            destroyAtlas();
            if (!createAtlas())
            {
                mInitialised = false;
                publishDisabled();
                CYSShadowPrograms::log("no shadow atlas could be created: shadows off");
                return false;
            }
        }
        mInitialised = true;
        mEnabled = enable;
        mProvider.registerWithRoot();
        if (mSceneManager && !mViewports[0])
            createCascadeViews();

        std::ostringstream o;
        o << "atlas " << mParams.textureName << " " << mTarget->getWidth() << "x" << mTarget->getHeight()
          << " R32F (" << getAtlasBytes() / (1024 * 1024) << " MB with its depth buffer), receivers SHADOWMAP_TYPE "
          << mConfig.shaderType() << ", casters: " << mCasters.getProgramSource();
        CYSShadowPrograms::log("config: " + mConfig.describe());
        CYSShadowPrograms::log(o.str());
        setDebugView(mConfig.debugView);
        refreshActive();
        return true;
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowSystem::shutdown(void)
    {
        destroyDebugView();
        destroyCascadeViews();
        destroyAtlas();
        mCasters.shutdown();
        mProvider.clear();
        mProvider.unregisterFromRoot();
        mSceneManager = 0;
        mCamera = 0;
        mLight = 0;
        mInitialised = false;
        mLightUsedValid = false;
    }
    //---------------------------------------------------------------------------------------------------------------
    bool CYSShadowSystem::createAtlas(void)
    {
        const unsigned int tiles = mConfig.effectiveCascades();
        unsigned int size = mConfig.mapSize;
        Ogre::TextureManager& tm = Ogre::TextureManager::getSingleton();
        mTarget = 0;
        while (size >= 256 && !mTarget)
        {
            try
            {
                if (!tm.getByName(mParams.textureName).isNull())
                    tm.remove(mParams.textureName);
                Ogre::TexturePtr tex = tm.createManual(mParams.textureName, mGroup, Ogre::TEX_TYPE_2D, size * tiles,
                                                       size, 0, Ogre::PF_FLOAT32_R, Ogre::TU_RENDERTARGET);
                mTarget = tex->getBuffer()->getRenderTarget();
            }
            catch (Ogre::Exception& e)
            {
                CYSShadowPrograms::log("atlas " + str(size * tiles) + "x" + str(size) + " R32F failed: " +
                                       e.getDescription());
                mTarget = 0;
            }
            if (!mTarget)
                size /= 2;
        }
        if (!mTarget)
            return false;
        if (size != mConfig.mapSize)
            CYSShadowPrograms::log("tile size reduced to " + str(size));
        mConfig.mapSize = size;
        mTarget->setAutoUpdated(true);
        mTarget->addListener(this);
        mParams.mapSize = size;
        mParams.cascadeCount = tiles;
        mParams.atlasWidth = size * tiles;
        mParams.atlasHeight = size;
        return true;
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowSystem::destroyAtlas(void)
    {
        if (mTarget)
        {
            mTarget->removeListener(this);
            mTarget->removeAllViewports();
            mTarget = 0;
        }
        for (size_t i = 0; i < CYS_SHADOW_MAX_CASCADES; ++i)
            mViewports[i] = 0;
        if (Ogre::TextureManager::getSingletonPtr() &&
            !Ogre::TextureManager::getSingleton().getByName(mParams.textureName).isNull())
            Ogre::TextureManager::getSingleton().remove(mParams.textureName);
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowSystem::createCascadeViews(void)
    {
        if (!mTarget || !mSceneManager)
            return;
        const size_t n = mConfig.effectiveCascades();
        const float width = float(mTarget->getWidth());
        const float tile = float(mConfig.mapSize);
        for (size_t i = 0; i < n; ++i)
        {
            const Ogre::String name = "CYS/Shadow/Cascade" + str(i);
            Ogre::Camera* c = mSceneManager->hasCamera(name) ? mSceneManager->getCamera(name) :
                                                               mSceneManager->createCamera(name);
            c->setAutoAspectRatio(false);
            c->setAspectRatio(1.0f);
            c->setProjectionType(Ogre::PT_ORTHOGRAPHIC);
            c->setNearClipDistance(1.0f);
            c->setFarClipDistance(100000.0f);
            c->setLodBias(1000.0f);             // casters at full mesh detail, whatever the distance to the light
            c->setUseRenderingDistance(false);  // no rendering-distance culling from the light's point of view
            c->setCustomViewMatrix(true, Ogre::Matrix4::IDENTITY);
            c->setCustomProjectionMatrix(true, Ogre::Matrix4::IDENTITY);
            mCascadeCameras[i] = c;
            // +0.25 texel: Viewport::_updateDimensions truncates relative * target width
            Ogre::Viewport* vp = mTarget->addViewport(c, int(i), (float(i) * tile + 0.25f) / width, 0.0f,
                                                      (tile + 0.25f) / width, 1.0f);
            vp->setClearEveryFrame(true, Ogre::FBT_COLOUR | Ogre::FBT_DEPTH);
            vp->setBackgroundColour(Ogre::ColourValue(0, 0, 0, 0)); // depth 0 = no caster (CalcShadow.inc)
            vp->setOverlaysEnabled(false);
            vp->setSkiesEnabled(false);
            vp->setShadowsEnabled(false);
            vp->setMaterialScheme(CYSShadowCasters::SCHEME);
            mViewports[i] = vp;
        }
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowSystem::destroyCascadeViews(void)
    {
        if (mTarget)
            mTarget->removeAllViewports();
        for (size_t i = 0; i < CYS_SHADOW_MAX_CASCADES; ++i)
        {
            if (mCascadeCameras[i] && mSceneManager)
                mSceneManager->destroyCamera(mCascadeCameras[i]);
            mCascadeCameras[i] = 0;
            mViewports[i] = 0;
        }
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowSystem::attach(Ogre::SceneManager* sceneManager, Ogre::Camera* camera)
    {
        if (mSceneManager && mSceneManager != sceneManager)
            detach();
        mSceneManager = sceneManager;
        mCamera = camera;
        if (mInitialised && mSceneManager && !mViewports[0])
            createCascadeViews();
        if (mDebugView)
            createDebugView();
        refreshActive();
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowSystem::detach(void)
    {
        destroyDebugView();
        destroyCascadeViews();
        mSceneManager = 0;
        mCamera = 0;
        refreshActive();
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowSystem::setCamera(Ogre::Camera* camera)
    {
        mCamera = camera;
        refreshActive();
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowSystem::setEnabled(bool enabled)
    {
        mEnabled = enabled && mConfig.mode != CYSShadowConfig::MODE_OFF;
        refreshActive();
    }
    //---------------------------------------------------------------------------------------------------------------
    bool CYSShadowSystem::isActive(void) const
    {
        return mInitialised && mEnabled && mTarget && mSceneManager && mCamera && mViewports[0];
    }
    //---------------------------------------------------------------------------------------------------------------
    bool CYSShadowSystem::setMapSize(unsigned int size)
    {
        CYSShadowConfig cfg = mConfig;
        cfg.mapSize = size;
        return initialise(cfg, mGroup);
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowSystem::setMode(CYSShadowConfig::Mode mode)
    {
        CYSShadowConfig cfg = mConfig;
        cfg.mode = mode;
        initialise(cfg, mGroup);
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowSystem::setBias(Ogre::Real constBias, Ogre::Real normalBias)
    {
        mConfig.constBias = constBias;
        mConfig.normalBias = normalBias;
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowSystem::setSoftness(int radius)
    {
        mConfig.softness = std::max(0, std::min(3, radius));
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowSystem::setMaxDistance(Ogre::Real distance)
    {
        mConfig.maxDistance = std::max(distance, Ogre::Real(100));
        mConfig.splits.clear();
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowSystem::setLightDirection(const Ogre::Vector3& direction)
    {
        mLightOverride = direction;
        mHasLightOverride = direction.squaredLength() > 1e-12f;
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowSystem::clearLightDirection(void)
    {
        mHasLightOverride = false;
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowSystem::setLight(Ogre::Light* light)
    {
        mLight = light;
    }
    //---------------------------------------------------------------------------------------------------------------
    size_t CYSShadowSystem::getAtlasBytes(void) const
    {
        return mTarget ? size_t(mTarget->getWidth()) * mTarget->getHeight() * 8 : 0;
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowSystem::refreshActive(void)
    {
        const bool active = isActive();
        if (mTarget)
            mTarget->setActive(active);
        if (!active)
            publishDisabled();
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowSystem::publish(void)
    {
        mProvider.applyShadowParams(mParams);
        if (mSink)
            mSink->applyShadowParams(mParams);
        updateDebugView();
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowSystem::publishDisabled(void)
    {
        mParams.enabled = false;
        mParams.pack();
        mProvider.applyShadowParams(mParams);
        if (mSink)
            mSink->applyShadowParams(mParams);
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowSystem::preRenderTargetUpdate(const Ogre::RenderTargetEvent& evt)
    {
        (void)evt;
        mCpuStart = nowMicroseconds();
        if (!mSceneManager || !mCamera)
            return;
        updateCascades();
        Ogre::RenderQueue* queue = mSceneManager->getRenderQueue();
        Ogre::RenderQueue::RenderableListener* previous = queue->getRenderableListener();
        mPrevListener = previous == &mCasters ? 0 : previous; // an aborted frame may have left ours installed
        queue->setRenderableListener(&mCasters);
        mListenerInstalled = true;
        mCasters.beginUpdate();
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowSystem::preViewportUpdate(const Ogre::RenderTargetViewportEvent& evt)
    {
        for (size_t i = 0; i < CYS_SHADOW_MAX_CASCADES; ++i)
        {
            if (mViewports[i] && evt.source == mViewports[i])
            {
                mCasters.setCurrentCascade(i);
                break;
            }
        }
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowSystem::postRenderTargetUpdate(const Ogre::RenderTargetEvent& evt)
    {
        (void)evt;
        if (mListenerInstalled && mSceneManager)
            mSceneManager->getRenderQueue()->setRenderableListener(mPrevListener);
        mListenerInstalled = false;
        mPrevListener = 0;
        for (size_t i = 0; i < CYS_SHADOW_MAX_CASCADES; ++i)
            mParams.cascades[i].casters = mStats.casters[i] = mCasters.getQueued(i);
        mStats.cpuMs = double(nowMicroseconds() - mCpuStart) / 1000.0;
        ++mStats.updates;
        publish();
    }
    //---------------------------------------------------------------------------------------------------------------
    Ogre::Vector3 CYSShadowSystem::resolveLightDirection(void)
    {
        Ogre::Vector3 dir = Ogre::Vector3::ZERO;
        if (mHasLightOverride)
            dir = mLightOverride;
        else if (mLight)
            dir = mLight->getDerivedDirection();
        else
        {
            if (mUseEnvironment)
            {
                const CYSEnvironment& env = CYSEnvironment::current();
                if (env.source != CYSEnvironment::SOURCE_NONE)
                    dir = env.lightOneDirection;
            }
            if (dir.squaredLength() < 1e-8f && mSceneManager)
            {
                // the brightest visible directional light
                try
                {
                    Ogre::Real best = -1;
                    Ogre::SceneManager::MovableObjectIterator it = mSceneManager->getMovableObjectIterator("Light");
                    while (it.hasMoreElements())
                    {
                        Ogre::Light* light = static_cast<Ogre::Light*>(it.getNext());
                        if (light->getType() != Ogre::Light::LT_DIRECTIONAL || !light->getVisible())
                            continue;
                        const Ogre::ColourValue& c = light->getDiffuseColour();
                        const Ogre::Real luma = 0.299f * c.r + 0.587f * c.g + 0.114f * c.b;
                        if (luma > best)
                        {
                            best = luma;
                            dir = light->getDerivedDirection();
                        }
                    }
                }
                catch (Ogre::Exception&)
                {
                }
            }
        }
        if (dir.squaredLength() < 1e-8f)
            dir = Ogre::Vector3(0.35f, -0.85f, 0.4f);
        dir.normalise();

        // A grazing sun would stretch shadows over the whole map: keep a minimum elevation.
        const Ogre::Real minSin = std::sin(Ogre::Degree(mConfig.minLightElevationDeg).valueRadians());
        if (-dir.y < minSin)
        {
            Ogre::Vector3 flat(dir.x, 0, dir.z);
            if (flat.squaredLength() < 1e-8f)
                flat = Ogre::Vector3::UNIT_X;
            flat.normalise();
            dir = flat * std::sqrt(1.0f - minSin * minSin) + Ogre::Vector3(0, -minSin, 0);
        }
        // Follow a moving sun in small steps: every change re-rasterises all shadow edges.
        const Ogre::Real cosEps = std::cos(Ogre::Degree(mConfig.lightEpsilonDeg).valueRadians());
        if (!mLightUsedValid || mLightUsed.dotProduct(dir) < cosEps || mConfig.lightEpsilonDeg <= 0)
        {
            mLightUsed = dir;
            mLightUsedValid = true;
        }
        return mLightUsed;
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowSystem::updateCascades(void)
    {
        using namespace CYSShadowFitting;
        const size_t n = mConfig.effectiveCascades();
        const double tile = double(mConfig.mapSize);
        const double interior = tile - 2.0; // texels receivers address: CalcShadow.inc keeps a 1-texel border

        ViewDesc view;
        view.position = mCamera->getDerivedPosition();
        view.direction = mCamera->getDerivedDirection();
        view.up = mCamera->getDerivedUp();
        view.right = mCamera->getDerivedRight();
        view.fovY = mCamera->getFOVy().valueRadians();
        view.aspect = mCamera->getAspectRatio();
        view.orthographic = mCamera->getProjectionType() == Ogre::PT_ORTHOGRAPHIC;
        view.orthoHalfHeight = std::tan(0.5f * view.fovY) * mCamera->getNearClipDistance();

        Ogre::Real farD = mConfig.maxDistance;
        const Ogre::Real camFar = mCamera->getFarClipDistance();
        if (camFar > 0 && camFar < farD && mConfig.splits.empty())
            farD = camFar;
        Ogre::Real nearD = mConfig.nearDistance > 0 ? mConfig.nearDistance : mCamera->getNearClipDistance();
        nearD = std::max(std::min(nearD, farD * 0.5f), Ogre::Real(0.01f));
        Ogre::Real splitFar[CYS_SHADOW_MAX_CASCADES];
        computeSplits(nearD, farD, n, mConfig.splitLambda, mConfig.splits, splitFar);

        const Ogre::Vector3 dir = resolveLightDirection();
        Ogre::Vector3 lx, ly, lz;
        lightBasis(dir, lx, ly, lz);

        struct Region
        {
            double a, b;        // view-depth slice
            double cx, cy;      // light-space centre of the interior
            double hx, hy;      // light-space half extents of the interior
            double dMin, dMax;  // receiver depth range along the light
        };
        Region region[CYS_SHADOW_MAX_CASCADES];
        double depthOrigin = 1.0e30;
        for (size_t i = 0; i < n; ++i)
        {
            Region& r = region[i];
            r.a = i ? splitFar[i - 1] : nearD;
            r.b = splitFar[i];
            if (mConfig.fit == CYSShadowConfig::FIT_STABLE)
            {
                Ogre::Vector3 centre;
                Ogre::Real radius;
                sliceSphere(view, Ogre::Real(r.a), Ogre::Real(r.b), centre, radius);
                // one texel of slack for the snapped centre, which moves by up to half a texel
                const double h = double(radius) * interior / (interior - 2.0);
                const double texel = 2.0 * h / interior;
                r.cx = snap(dotd(lx, centre), texel);
                r.cy = snap(dotd(ly, centre), texel);
                r.hx = r.hy = h;
                const double d = dotd(dir, centre);
                r.dMin = d - radius;
                r.dMax = d + radius;
            }
            else
            {
                Ogre::Vector3 corners[8];
                sliceCorners(view, Ogre::Real(r.a), Ogre::Real(r.b), corners);
                double x0 = 1e30, x1 = -1e30, y0 = 1e30, y1 = -1e30, d0 = 1e30, d1 = -1e30;
                for (int k = 0; k < 8; ++k)
                {
                    const double x = dotd(lx, corners[k]), y = dotd(ly, corners[k]), d = dotd(dir, corners[k]);
                    x0 = std::min(x0, x);
                    x1 = std::max(x1, x);
                    y0 = std::min(y0, y);
                    y1 = std::max(y1, y);
                    d0 = std::min(d0, d);
                    d1 = std::max(d1, d);
                }
                r.cx = 0.5 * (x0 + x1);
                r.cy = 0.5 * (y0 + y1);
                r.hx = std::max(0.5 * (x1 - x0), 1.0);
                r.hy = std::max(0.5 * (y1 - y0), 1.0);
                r.dMin = d0;
                r.dMax = d1;
            }
            depthOrigin = std::min(depthOrigin, r.dMin);
        }
        depthOrigin -= mConfig.backoff; // casters up to 'backoff' above the highest receiver still cast

        const Ogre::Matrix4 lightView = lightViewMatrix(lx, ly, lz, Ogre::Real(depthOrigin));
        Ogre::RenderSystem* rs = Ogre::Root::getSingleton().getRenderSystem();
        const double hOff = rs ? rs->getHorizontalTexelOffset() : 0.0;
        const double vOff = rs ? rs->getVerticalTexelOffset() : 0.0;
        Ogre::Quaternion orientation;
        orientation.FromAxes(lx, ly, lz);
        double coarsest = 0.0;
        for (size_t i = 0; i < n; ++i)
        {
            const Region& r = region[i];
            CYSShadowCascade& c = mParams.cascades[i];
            const double tx = 2.0 * r.hx / interior, ty = 2.0 * r.hy / interior;
            const double fx = r.hx + tx, fy = r.hy + ty; // whole tile = interior + one texel on each side
            const double depthFar = r.dMax - depthOrigin + 1.0;
            c.splitNear = Ogre::Real(r.a);
            c.splitFar = Ogre::Real(r.b);
            c.halfWidth = Ogre::Real(r.hx);
            c.halfHeight = Ogre::Real(r.hy);
            c.texelWidth = Ogre::Real(tx);
            c.texelHeight = Ogre::Real(ty);
            c.depthFar = Ogre::Real(depthFar);
            c.centre = lx * Ogre::Real(r.cx) + ly * Ogre::Real(r.cy) + dir * Ogre::Real(0.5 * (r.dMin + r.dMax));
            c.proj = orthoProjection(r.cx - fx, r.cx + fx, r.cy - fy, r.cy + fy, 0.0, depthFar);
            // Receivers (t = posInView * scale + offset): the orthographic formula of OgreAutoParamExternalProvider.h
            // applied to the interior box [cx +- hx] x [cy +- hy] x depth [0, depthFar].
            c.texScale = Ogre::Vector4(Ogre::Real(0.5 / r.hx), Ogre::Real(-0.5 / r.hy), Ogre::Real(-1.0 / depthFar), 0);
            c.texOffset = Ogre::Vector4(Ogre::Real(0.5 - 0.5 * r.cx / r.hx), Ogre::Real(0.5 + 0.5 * r.cy / r.hy), 0, 0);
            c.atlasRect = Ogre::Vector4(Ogre::Real(i) / Ogre::Real(n), 0, Ogre::Real(i + 1) / Ogre::Real(n), 1);
            coarsest = std::max(coarsest, std::max(tx, ty));

            Ogre::Camera* cam = mCascadeCameras[i];
            if (cam)
            {
                // D3D9 samples pixel centres at integer window coordinates: shift half a texel so that texel k holds
                // the depth at its centre, where the receivers' point samples read it.
                Ogre::Matrix4 shift = Ogre::Matrix4::IDENTITY;
                shift[0][3] = Ogre::Real(2.0 * hOff / tile);
                shift[1][3] = Ogre::Real(-2.0 * vOff / tile);
                cam->setCustomViewMatrix(true, lightView);
                cam->setCustomProjectionMatrix(true, shift * c.proj);
                cam->setFarClipDistance(Ogre::Real(depthFar));
                // the tile's eye on the light plane (camera position for LOD and sorting)
                cam->setPosition(lx * Ogre::Real(r.cx) + ly * Ogre::Real(r.cy) + dir * Ogre::Real(depthOrigin));
                cam->setOrientation(orientation);
            }
        }
        for (size_t i = n; i < CYS_SHADOW_MAX_CASCADES; ++i)
            mParams.cascades[i] = CYSShadowCascade();

        mParams.constBias = mConfig.constBias >= 0 ? mConfig.constBias : Ogre::Real(mConfig.autoConstBias * coarsest);
        mParams.normalBias = mConfig.normalBias >= 0 ? mConfig.normalBias : Ogre::Real(mConfig.autoNormalBias * coarsest);
        mParams.strength = mConfig.strength;
        mParams.pbrStrength = mConfig.pbrStrength;
        if (mUseEnvironment && mConfig.useEnvironmentStrength)
        {
            const CYSEnvironment& env = CYSEnvironment::current();
            if (env.source != CYSEnvironment::SOURCE_NONE)
            {
                mParams.strength = env.shadowStrength;
                mParams.pbrStrength = env.pbrShadowStrength;
            }
        }
        mParams.enabled = true;
        mParams.shaderType = mConfig.shaderType();
        mParams.cascadeCount = n;
        mParams.mapSize = mConfig.mapSize;
        mParams.atlasWidth = mTarget->getWidth();
        mParams.atlasHeight = mTarget->getHeight();
        mParams.lightDirection = dir;
        mParams.lightView = lightView;
        mParams.simpleProj = mParams.cascades[0].proj;
        mParams.maxDistance = farD;
        mParams.blendBand = mConfig.blendBand;
        mParams.pcfRadius = mConfig.softness;
        ++mParams.frame;
        mParams.pack();
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowSystem::setDebugView(bool on)
    {
        mDebugView = on;
        if (on && !mDebugRect)
            createDebugView();
        if (mDebugRect)
            mDebugRect->setVisible(on);
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowSystem::createDebugView(void)
    {
        if (mDebugRect || !mSceneManager || !mInitialised)
            return;
        using namespace CYSShadowPrograms;
        Ogre::HighLevelGpuProgramPtr vs = createHlsl("CYS/Shadow/Debug_VS", mGroup, "CYSShadowDebug.hlsl", "debugVS",
                                                     "vs_3_0", "", Ogre::GPT_VERTEX_PROGRAM);
        Ogre::HighLevelGpuProgramPtr ps = createHlsl("CYS/Shadow/Debug_PS", mGroup, "CYSShadowDebug.hlsl", "debugPS",
                                                     "ps_3_0", "", Ogre::GPT_FRAGMENT_PROGRAM);
        if (vs.isNull() || ps.isNull())
        {
            log("debug view unavailable (CYSShadowDebug.hlsl is not in resource group " + mGroup + ")");
            return;
        }
        Ogre::MaterialManager& mm = Ogre::MaterialManager::getSingleton();
        Ogre::MaterialPtr mat = mm.getByName(kDebugMaterial);
        if (mat.isNull())
        {
            mat = mm.create(kDebugMaterial, mGroup);
            Ogre::Pass* p = mat->getTechnique(0)->getPass(0);
            p->setLightingEnabled(false);
            p->setDepthCheckEnabled(false);
            p->setDepthWriteEnabled(false);
            p->setFog(true, Ogre::FOG_NONE);
            p->setCullingMode(Ogre::CULL_NONE);
            p->setVertexProgram(vs->getName());
            p->setFragmentProgram(ps->getName());
            Ogre::TextureUnitState* t = p->createTextureUnitState();
            t->setContentType(Ogre::TextureUnitState::CONTENT_SHADOW);
            t->setCompositorReference(Ogre::StringUtil::BLANK, Ogre::StringUtil::BLANK, 0);
            t->setTextureFiltering(Ogre::TFO_NONE);
            t->setTextureAddressingMode(Ogre::TextureUnitState::TAM_CLAMP);
            mat->load();
        }
        mDebugRect = new Ogre::Rectangle2D(true);
        mDebugRect->setMaterial(kDebugMaterial);
        mDebugRect->setRenderQueueGroup(Ogre::RENDER_QUEUE_OVERLAY - 1);
        Ogre::AxisAlignedBox box;
        box.setExtents(-1e8f, -1e8f, -1e8f, 1e8f, 1e8f, 1e8f);
        mDebugRect->setBoundingBox(box);
        mDebugRect->setCastShadows(false);
        mDebugNode = mSceneManager->getRootSceneNode()->createChildSceneNode();
        mDebugNode->attachObject(mDebugRect);
        mDebugRect->setVisible(mDebugView);
        layoutDebugView();
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowSystem::layoutDebugView(void)
    {
        if (!mDebugRect)
            return;
        Ogre::Real aspect = 16.0f / 9.0f;
        Ogre::Viewport* vp = mCamera ? mCamera->getViewport() : 0;
        if (vp && vp->getActualHeight() > 0)
            aspect = Ogre::Real(vp->getActualWidth()) / Ogre::Real(vp->getActualHeight());
        const Ogre::Real tiles = Ogre::Real(mConfig.effectiveCascades());
        const Ogre::Real width = 1.2f;  // 60 % of the screen width, square tiles
        const Ogre::Real height = std::min(width / tiles * aspect, Ogre::Real(1.0f));
        mDebugRect->setCorners(-1.0f, -1.0f + height, -1.0f + width, -1.0f);
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowSystem::updateDebugView(void)
    {
        if (!mDebugRect || !mDebugView)
            return;
        layoutDebugView();
        Ogre::MaterialPtr mat = Ogre::MaterialManager::getSingleton().getByName(kDebugMaterial);
        if (mat.isNull() || !mat->getNumTechniques())
            return;
        Ogre::Real depthRange = 1.0f;
        for (size_t i = 0; i < mParams.cascadeCount && i < CYS_SHADOW_MAX_CASCADES; ++i)
            depthRange = std::max(depthRange, mParams.cascades[i].depthFar);
        Ogre::GpuProgramParametersSharedPtr fp = mat->getTechnique(0)->getPass(0)->getFragmentProgramParameters();
        CYSShadowPrograms::setConstant(fp, "depthScale", 1.0f / depthRange);
        CYSShadowPrograms::setConstant(fp, "cascades", Ogre::Real(mConfig.effectiveCascades()));
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowSystem::destroyDebugView(void)
    {
        if (mDebugNode)
        {
            mDebugNode->detachAllObjects();
            if (mSceneManager)
                mSceneManager->destroySceneNode(mDebugNode->getName());
            mDebugNode = 0;
        }
        delete mDebugRect;
        mDebugRect = 0;
    }
}
