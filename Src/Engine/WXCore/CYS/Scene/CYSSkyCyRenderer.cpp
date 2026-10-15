// CYS-SKY (sky-enscene): see CYSSkyCyRenderer.h and Docs/specs/render/sky-enscene-cy_vi.md.
#include "CYSSkyCyRenderer.h"
#include "CYSSkyRenderer.h"
#include "CYSEnvironment.h"

#include "Core/WXSystem.h"

#include <OgreSceneManager.h>
#include <OgreSceneNode.h>
#include <OgreCamera.h>
#include <OgreSimpleRenderable.h>
#include <OgreRenderQueue.h>
#include <OgreMaterialManager.h>
#include <OgreTextureManager.h>
#include <OgreMeshManager.h>
#include <OgreSubMesh.h>
#include <OgreTechnique.h>
#include <OgrePass.h>
#include <OgreTextureUnitState.h>
#include <OgreGpuProgram.h>
#include <OgreGpuProgramManager.h>
#include <OgreHighLevelGpuProgramManager.h>
#include <OgreHardwareBufferManager.h>
#include <OgreResourceGroupManager.h>
#include <OgreStringConverter.h>
#include <OgreException.h>

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>

namespace WX
{
    using namespace CYSScene;

    //////////////////////////////////////////////////////////////////////////
    // CYSSkyMesh: one submesh drawn with a render queue group AND a priority, like Fairy's
    // Entity::setRenderQueueGroup(group, priority) (CY OgreMain extension; OGRE 1.2 entities have no priority).
    //////////////////////////////////////////////////////////////////////////
    class CYSSkyMesh : public Ogre::SimpleRenderable
    {
    public:
        CYSSkyMesh(const Ogre::MeshPtr& mesh, Ogre::uint8 queue, Ogre::ushort priority)
            : mMesh(mesh), mPriority(priority)
        {
            mRenderQueueID = queue;
            mRenderQueueIDSet = true;
            setCastShadows(false);
            setQueryFlags(0);
            // The EnScene / SkySphereLayer vertex programs put every vertex on the far plane: never cull by bounds.
            setBoundingBox(Ogre::AxisAlignedBox(-1e6f, -1e6f, -1e6f, 1e6f, 1e6f, 1e6f));
        }
        void setMaterialPtr(const Ogre::MaterialPtr& material) { m_pMaterial = material; m_strMatName = material->getName(); }
        virtual void getRenderOperation(Ogre::RenderOperation& op)
        {
            mMesh->getSubMesh(0)->_getRenderOperation(op, 0);
        }
        virtual void _updateRenderQueue(Ogre::RenderQueue* queue)
        {
            queue->addRenderable(this, mRenderQueueID, mPriority);
        }
        virtual Ogre::Real getSquaredViewDepth(const Ogre::Camera* cam) const
        {
            return mParentNode ? mParentNode->getSquaredViewDepth(cam) : 0.0f;
        }
        virtual Ogre::Real getBoundingRadius(void) const { return 1e6f; }
        virtual const String& getMovableType(void) const
        {
            static const String type = "CYSSkyMesh";
            return type;
        }
    private:
        Ogre::MeshPtr mMesh;
        Ogre::ushort mPriority;
    };

    //////////////////////////////////////////////////////////////////////////
    // Item
    //////////////////////////////////////////////////////////////////////////
    struct CYSSkyCyRenderer::Item
    {
        enum Kind { DOME, CLOUD, RING, MOON, SUN, SPHERE_LAYER };

        int kind;
        String label;
        Ogre::SceneNode* node;          ///< follows the camera
        Ogre::SceneNode* child;         ///< moon / sun plane at (0, 0, -+9000)
        CYSSkyMesh* object;
        Ogre::MaterialPtr material;
        Ogre::GpuProgramParametersSharedPtr vp, fp;

        CYSEnSkyDome dome;
        CYSEnCloudLayer layer;
        CYSEnCelestial celestial;
        CYSSkyLayerDef sphereLayer;
        std::vector<CYSSkyAlphaCurve> curves;       ///< SkySphere: alpha curve per texture group
        std::vector<String> textures;               ///< SkySphere: layer texture per texture group
        std::vector<Real> uWraps;
        std::vector<int> active;                    ///< SkySphere: groups in the material (alpha >= 0.001)
        bool fogLayer;

        Real windSpeed;         ///< EnCloud +0x100
        Real vScroll;           ///< EnRingCloud +0x104
        bool turned;            ///< EnCloud +0x107 / EnRingCloud +0x125
        bool visible;

        Item(void)
            : kind(DOME), node(0), child(0), object(0), fogLayer(false), windSpeed(0), vScroll(0), turned(false)
            , visible(true)
        {
        }
    };

    //////////////////////////////////////////////////////////////////////////
    // helpers
    //////////////////////////////////////////////////////////////////////////
    namespace
    {
        const Real kCelestialDistance = 9000.0f;        // EnMoon child node (0, 0, -9000): hex 0x1802c3a04

        bool envFlag(const char* name, bool def)
        {
            const char* v = getenv(name);
            if (!v || !*v)
                return def;
            return !(v[0] == '0' || v[0] == 'n' || v[0] == 'N' || v[0] == 'f' || v[0] == 'F');
        }

        void setConst(const Ogre::GpuProgramParametersSharedPtr& p, const char* name, Real v)
        {
            if (!p.isNull() && p->hasNamedConstant(name))
                p->setNamedConstant(name, v);
        }
        void setConst(const Ogre::GpuProgramParametersSharedPtr& p, const char* name, const Ogre::Vector3& v)
        {
            if (!p.isNull() && p->hasNamedConstant(name))
                p->setNamedConstant(name, v);
        }
        void setConst(const Ogre::GpuProgramParametersSharedPtr& p, const char* name, const Ogre::Vector4& v)
        {
            if (!p.isNull() && p->hasNamedConstant(name))
                p->setNamedConstant(name, v);
        }

        /// FUN_180236000 (moon) / FUN_1802378a0 (sun): fraction of the day arc, 0.25 at rise .. 0.75 at set (moon: the
        /// same with the rise/set roles swapped at the call site).
        Real sunArc(Real hours, Real up, Real down)
        {
            if (down < up)
            {
                if (hours <= up)
                {
                    if (down <= hours)
                        return (hours - down) / ((up - down) * 2.0f) + 0.75f;
                    hours += 24.0f;
                }
                down += 24.0f;
            }
            else
            {
                if (down < hours)
                    return (hours - down) / (((24.0f - down) + up) * 2.0f) + 0.75f;
                if (hours < up)
                    return ((hours + 24.0f) - down) / (((24.0f - down) + up) * 2.0f) + 0.75f;
            }
            return (hours - up) / ((down - up) * 2.0f) + 0.25f;
        }

        /// FUN_1802378a0: node orientation = rot(-Y, orient + 180) * rot(-X, -angle) * rot(-Y, arc * 360), sun direction =
        /// orientation * (0, 0, 1) (checked against SUN_POSITION of the CY login trace: 0.3933 day -> 0.621, 0.600, 0.504).
        Ogre::Quaternion celestialOrientation(const CYSEnCelestial& c, Real hours, bool sun)
        {
            Ogre::Quaternion q = Ogre::Quaternion(Ogre::Degree(c.orient + 180.0f), Ogre::Vector3::NEGATIVE_UNIT_Y) *
                                 Ogre::Quaternion(Ogre::Degree(-c.angle), Ogre::Vector3::NEGATIVE_UNIT_X);
            Real arc;
            if (sun)
                arc = c.fixed ? 0.5f : sunArc(hours, c.upTime, c.downTime);
            else if (c.fixed)
                return q;           // FUN_180236000: moonfix skips the day rotation
            else
                arc = sunArc(hours, c.downTime, c.upTime);
            return q * Ogre::Quaternion(Ogre::Degree(arc * 360.0f), Ogre::Vector3::NEGATIVE_UNIT_Y);
        }

        bool programExists(const char* name)
        {
            return !Ogre::HighLevelGpuProgramManager::getSingleton().getByName(name).isNull() ||
                   !Ogre::GpuProgramManager::getSingleton().getByName(name).isNull();
        }
    }

    //////////////////////////////////////////////////////////////////////////
    CYSSkyCyRenderer::CYSSkyCyRenderer(System* system)
        : mSystem(system)
        , mSceneManager(system ? system->getSceneManager() : 0)
        , mRoot(0)
        , mCounter(0)
        , mSkySphere(false)
        , mFixedHeight(false)
        , mFixedHeightValue(0)
        , mExtras(0)
    {
    }
    //-----------------------------------------------------------------------
    CYSSkyCyRenderer::~CYSSkyCyRenderer()
    {
        destroy();
    }
    //-----------------------------------------------------------------------
    bool CYSSkyCyRenderer::isEnabled(void)
    {
        if (!envFlag("CYS_SKY_SHADER", true))
            return false;
        try
        {
            const bool ok = !Ogre::MaterialManager::getSingleton().getByName("EnScene/skyDome").isNull() &&
                            programExists("SkySphereLayerBlend_OneTexture_VS_1_1_hlsl");
            if (!ok)
                logOnce("sky shader unavailable", "CYS-SKY: EnScene/skyDome or SkySphereLayer programs missing, "
                                                  "using the fixed-function sky");
            return ok;
        }
        catch (const Ogre::Exception&)
        {
            return false;
        }
    }
    //-----------------------------------------------------------------------
    Ogre::Vector3 CYSSkyCyRenderer::sunDirection(const CYSEnCelestial& sun, Real hours)
    {
        return celestialOrientation(sun, hours, true) * Ogre::Vector3::UNIT_Z;
    }
    //-----------------------------------------------------------------------
    size_t CYSSkyCyRenderer::getNumElements(void) const
    {
        return mItems.size() + (mExtras ? mExtras->getNumElements() : 0);
    }
    //-----------------------------------------------------------------------
    String CYSSkyCyRenderer::makeName(const String& label)
    {
        return mPrefix + label + "#" + Ogre::StringConverter::toString(mCounter++);
    }
    //-----------------------------------------------------------------------
    CYSSkyCyRenderer::Item* CYSSkyCyRenderer::addItem(int kind, const String& label)
    {
        if (!mRoot)
            mRoot = mSystem->getBaseSceneNode()->createChildSceneNode();
        Item* item = new Item;
        item->kind = kind;
        item->label = label;
        item->node = mRoot->createChildSceneNode();
        mItems.push_back(item);
        return item;
    }
    //-----------------------------------------------------------------------
    bool CYSSkyCyRenderer::prepareTexture(const String& name, bool noMipmaps)
    {
        if (name.empty())
            return false;
        Ogre::TextureManager& tm = Ogre::TextureManager::getSingleton();
        if (!tm.getByName(name).isNull())
            return true;
        Ogre::ResourceGroupManager& rgm = Ogre::ResourceGroupManager::getSingleton();
        Ogre::StringVector groups = rgm.getResourceGroups();
        for (size_t i = 0; i < groups.size(); ++i)
        {
            try
            {
                if (!rgm.resourceExists(groups[i], name))
                    continue;
                // FUN_180239970 (dome) and the cloud loaders: the colour table / cloud images are single level
                // (trace: 64x256, 2048x512 ... A8R8G8B8 levels 1); .dds keep their own chain.
                const String lower = toLowerAscii(name);
                const bool dds = lower.size() > 4 && lower.substr(lower.size() - 4) == ".dds";
                if (noMipmaps && !dds)
                    tm.load(name, groups[i], Ogre::TEX_TYPE_2D, 0);
                else
                    tm.load(name, groups[i]);
                return true;
            }
            catch (const Ogre::Exception& e)
            {
                logOnce("sky texture load:" + name, "CYS-SKY: texture '" + name + "': " + e.getDescription());
                return false;
            }
        }
        logOnce("sky texture:" + name, "CYS-SKY: texture '" + name + "' not found");
        return false;
    }
    //-----------------------------------------------------------------------
    Ogre::MaterialPtr CYSSkyCyRenderer::cloneMaterial(const String& source, const String& name)
    {
        Ogre::MaterialPtr src = Ogre::MaterialManager::getSingleton().getByName(source);
        if (src.isNull())
        {
            logOnce("sky material:" + source, "CYS-SKY: material '" + source + "' not found");
            return Ogre::MaterialPtr();
        }
        src->load();
        return src->clone(name);
    }
    //-----------------------------------------------------------------------
    Ogre::MeshPtr CYSSkyCyRenderer::loadMesh(const String& name)
    {
        try
        {
            return Ogre::MeshManager::getSingleton().load(name, Ogre::ResourceGroupManager::AUTODETECT_RESOURCE_GROUP_NAME);
        }
        catch (const Ogre::Exception& e)
        {
            logOnce("sky mesh:" + name, "CYS-SKY: mesh '" + name + "' not loaded: " + e.getDescription());
            return Ogre::MeshPtr();
        }
    }
    //-----------------------------------------------------------------------
    void CYSSkyCyRenderer::attach(Item* item, const Ogre::MeshPtr& mesh, Ogre::uint8 queue, Ogre::ushort priority)
    {
        CYSSkyMesh* object = new CYSSkyMesh(mesh, queue, priority);
        object->setMaterialPtr(item->material);
        item->object = object;
        (item->child ? item->child : item->node)->attachObject(object);
        Ogre::Pass* pass = item->material->getTechnique(0)->getPass(0);
        if (pass->hasVertexProgram())
            item->vp = pass->getVertexProgramParameters();
        if (pass->hasFragmentProgram())
            item->fp = pass->getFragmentProgramParameters();
    }
    //-----------------------------------------------------------------------
    void CYSSkyCyRenderer::destroy(void)
    {
        for (size_t i = 0; i < mItems.size(); ++i)
        {
            Item* item = mItems[i];
            if (item->object)
            {
                if (item->object->getParentNode())
                    static_cast<Ogre::SceneNode*>(item->object->getParentNode())->detachObject(item->object);
                delete item->object;
            }
            item->vp.setNull();
            item->fp.setNull();
            if (!item->material.isNull())
            {
                const String name = item->material->getName();
                item->material.setNull();
                try
                {
                    Ogre::MaterialManager::getSingleton().remove(name);
                }
                catch (const Ogre::Exception&)
                {
                }
            }
            delete item;
        }
        mItems.clear();
        for (size_t i = 0; i < mMeshes.size(); ++i)
        {
            try
            {
                Ogre::MeshManager::getSingleton().remove(mMeshes[i]);
            }
            catch (const Ogre::Exception&)
            {
            }
        }
        mMeshes.clear();
        if (mRoot && mSceneManager)
        {
            mRoot->removeAndDestroyAllChildren();
            mSceneManager->destroySceneNode(mRoot->getName());
        }
        mRoot = 0;
        delete mExtras;
        mExtras = 0;
    }
    //-----------------------------------------------------------------------
    void CYSSkyCyRenderer::setVisible(bool visible)
    {
        if (mRoot)
            mRoot->setVisible(visible, true);
        if (mExtras)
            mExtras->setVisible(visible);
    }

    //////////////////////////////////////////////////////////////////////////
    // EnScene
    //////////////////////////////////////////////////////////////////////////
    void CYSSkyCyRenderer::buildEnScene(const CYSEnSky& sky, const String& sceneName)
    {
        destroy();
        mPrefix = "CYS/SkyCY/" + sceneName + "/";
        mSkySphere = false;
        mSun = sky.sun;                 // FUN_180236220 defaults (orient 0, angle 50, 6..18 h) when <Sun> is absent

        if (sky.dome.present)
            buildDome(sky.dome);
        for (size_t i = 0; i < sky.clouds.size(); ++i)
            buildCloud(sky.clouds[i]);
        for (size_t i = 0; i < sky.ringClouds.size(); ++i)
            buildRing(sky.ringClouds[i]);
        if (sky.moon.present && sky.moon.enable)
            buildCelestial(sky.moon, false);
        if (sky.sun.present && sky.sun.enable)
            buildCelestial(sky.sun, true);

        // Stars and the sun flare: fixed-function extras (no CY shader draw captured).
        const bool flare = sky.sun.present && sky.sun.enable && sky.sun.useSunFlare;
        if ((sky.star.present && sky.star.enable) || flare)
        {
            mExtras = new CYSSkyRenderer(mSystem);
            mExtras->setExtrasOnly(true);
            mExtras->buildEnScene(sky, sceneName + "/extras");
            if (mExtras->isEmpty())
            {
                delete mExtras;
                mExtras = 0;
            }
        }

        char buf[160];
        sprintf(buf, "CYS-SKY: EnScene sky '%s' with CY shaders: %u draws (+%u fixed-function extras)", sceneName.c_str(),
                (unsigned)mItems.size(), (unsigned)(mExtras ? mExtras->getNumElements() : 0));
        log(buf);
    }
    //-----------------------------------------------------------------------
    void CYSSkyCyRenderer::buildDome(const CYSEnSkyDome& dome)
    {
        // FUN_1802391e0: entity "en_skydome" of enskydome.mesh, material EnScene/skyDome, queue (5, 100), node at the
        // camera; FUN_180239ad0 adds the <texture> colour table (u wrap, v/w clamp) and "TextureUnitEx" (the second
        // Rayleigh table of a region blend; the trace binds the same table on s1 and s2).
        if (!prepareTexture(dome.texture, true))
            return;
        Ogre::MeshPtr mesh = loadMesh("enskydome.mesh");
        if (mesh.isNull())
            return;
        Item* item = addItem(Item::DOME, "Dome");
        item->dome = dome;
        item->material = cloneMaterial("EnScene/skyDome", makeName("EnScene/skyDome"));
        if (item->material.isNull())
            return;
        Ogre::Pass* pass = item->material->getTechnique(0)->getPass(0);
        Ogre::TextureUnitState* rayleigh = pass->createTextureUnitState(dome.texture);
        rayleigh->setTextureAddressingMode(Ogre::TextureUnitState::TAM_WRAP, Ogre::TextureUnitState::TAM_CLAMP,
                                           Ogre::TextureUnitState::TAM_CLAMP);
        rayleigh->setName(dome.texture);
        Ogre::TextureUnitState* rayleighEx = pass->createTextureUnitState(dome.texture);
        rayleighEx->setTextureAddressingMode(Ogre::TextureUnitState::TAM_WRAP, Ogre::TextureUnitState::TAM_CLAMP,
                                             Ogre::TextureUnitState::TAM_CLAMP);
        rayleighEx->setName("TextureUnitEx");
        for (unsigned short i = 0; i < pass->getNumTextureUnitStates(); ++i)
            pass->getTextureUnitState(i)->setTextureFiltering(Ogre::TFO_BILINEAR);       // trace: MIN/MAG LINEAR, MIP POINT
        item->material->load();
        attach(item, mesh, Ogre::RENDER_QUEUE_SKIES_EARLY, 100);
    }
    //-----------------------------------------------------------------------
    void CYSSkyCyRenderer::buildCloud(const CYSEnCloudLayer& layer)
    {
        // FUN_18023a350: entity "cloud_<name>", clone of EnScene/cloud, queue (59, 90 + layer); FUN_18023ac50 texture
        // units: <texturename> (wrap) then the fog-amount map bmp_overhead_weak_fog.dds (clamp).
        const String meshName = layer.meshName.empty() ? String("enskycloud.mesh") : layer.meshName;
        if (!prepareTexture(layer.textureName, true))
            return;
        Ogre::MeshPtr mesh = loadMesh(meshName);
        if (mesh.isNull())
            return;
        Item* item = addItem(Item::CLOUD, "Cloud");
        item->layer = layer;
        item->material = cloneMaterial("EnScene/cloud", makeName("cloud_" + layer.name));
        if (item->material.isNull())
            return;
        Ogre::Pass* pass = item->material->getTechnique(0)->getPass(0);
        Ogre::TextureUnitState* tex = pass->createTextureUnitState(layer.textureName);
        tex->setTextureAddressingMode(Ogre::TextureUnitState::TAM_WRAP);
        tex->setTextureFiltering(Ogre::TFO_BILINEAR);
        prepareTexture("bmp_overhead_weak_fog.dds", false);
        Ogre::TextureUnitState* fog = pass->createTextureUnitState("bmp_overhead_weak_fog.dds");
        fog->setTextureAddressingMode(Ogre::TextureUnitState::TAM_CLAMP);
        fog->setTextureFiltering(Ogre::TFO_BILINEAR);
        item->material->load();
        attach(item, mesh, 59, (Ogre::ushort)std::max(0, 90 + layer.layer));
        // INF: rotangle (radians) turns the cloud node about Y; the per-frame FUN_18023b200 keeps the orientation.
        item->node->setOrientation(Ogre::Quaternion(Ogre::Radian(layer.rotAngle), Ogre::Vector3::UNIT_Y));
    }
    //-----------------------------------------------------------------------
    void CYSSkyCyRenderer::buildRing(const CYSEnCloudLayer& layer)
    {
        // FUN_18023b940: entity "ringcloud_<name>" under EnRingCloudRoot, clone of EnScene/ringcloud, queue (59, 110 + layer);
        // FUN_18023c2b0: <texturename> (u wrap, v/w clamp) then bmp_horizon_fog_strong.dds (u wrap, v/w clamp).
        const String meshName = layer.meshName.empty() ? String("ringcloud.mesh") : layer.meshName;
        if (!prepareTexture(layer.textureName, true))
            return;
        Ogre::MeshPtr mesh = loadMesh(meshName);
        if (mesh.isNull())
            return;
        Item* item = addItem(Item::RING, "Ring");
        item->layer = layer;
        item->material = cloneMaterial("EnScene/ringcloud", makeName("ringcloud_" + layer.name));
        if (item->material.isNull())
            return;
        Ogre::Pass* pass = item->material->getTechnique(0)->getPass(0);
        Ogre::TextureUnitState* tex = pass->createTextureUnitState(layer.textureName);
        tex->setTextureAddressingMode(Ogre::TextureUnitState::TAM_WRAP, Ogre::TextureUnitState::TAM_CLAMP,
                                      Ogre::TextureUnitState::TAM_CLAMP);
        tex->setTextureFiltering(Ogre::TFO_BILINEAR);
        prepareTexture("bmp_horizon_fog_strong.dds", false);
        Ogre::TextureUnitState* fog = pass->createTextureUnitState("bmp_horizon_fog_strong.dds");
        fog->setTextureAddressingMode(Ogre::TextureUnitState::TAM_WRAP, Ogre::TextureUnitState::TAM_CLAMP,
                                      Ogre::TextureUnitState::TAM_CLAMP);
        fog->setTextureFiltering(Ogre::TFO_BILINEAR);
        item->material->load();
        attach(item, mesh, 59, (Ogre::ushort)std::max(0, 110 + layer.layer));
    }
    //-----------------------------------------------------------------------
    void CYSSkyCyRenderer::buildCelestial(const CYSEnCelestial& c, bool sun)
    {
        // FUN_180235a10 / FUN_180236220: prefab plane (200 x 200, facing +Z) on a child node at (0, 0, -9000) scaled by
        // `scale`, material EnScene/moon / EnScene/sun with the texture replaced; queue 59, priority 90 + layer (the
        // erengu_DL moon, layer 30, draws between ring priorities 118 and 121 in the CY trace).
        if (!prepareTexture(c.texture, true))
            return;
        Ogre::MeshPtr mesh = Ogre::MeshManager::getSingleton().getByName("Prefab_Plane");
        if (mesh.isNull())
            return;
        Item* item = addItem(sun ? Item::SUN : Item::MOON, sun ? "Sun" : "Moon");
        item->celestial = c;
        item->material = cloneMaterial(sun ? "EnScene/sun" : "EnScene/moon", makeName(sun ? "en_sun" : "en_moon"));
        if (item->material.isNull())
            return;
        Ogre::Pass* pass = item->material->getTechnique(0)->getPass(0);
        if (pass->getNumTextureUnitStates() == 0)
            pass->createTextureUnitState(c.texture);
        else
            pass->getTextureUnitState(0)->setTextureName(c.texture);
        pass->getTextureUnitState(0)->setTextureAddressingMode(Ogre::TextureUnitState::TAM_CLAMP);
        pass->getTextureUnitState(0)->setTextureFiltering(Ogre::TFO_BILINEAR);
        item->material->load();
        item->child = item->node->createChildSceneNode(Ogre::Vector3(0, 0, sun ? kCelestialDistance : -kCelestialDistance));
        item->child->setScale(c.scale, c.scale, c.scale);
        if (sun)        // INF: the sun plane faces the camera from +Z
            item->child->setOrientation(Ogre::Quaternion(Ogre::Degree(180.0f), Ogre::Vector3::UNIT_Y));
        const int layer = c.hasLayer ? c.layer : (sun ? 5 : 25);
        attach(item, mesh, 59, (Ogre::ushort)std::max(0, 90 + layer));
    }

    //////////////////////////////////////////////////////////////////////////
    // SkySphere
    //////////////////////////////////////////////////////////////////////////
    Ogre::MeshPtr CYSSkyCyRenderer::skySphereMesh(Real pitchStart, Real pitchEnd)
    {
        // FUN_1801d0ba0 with the steps of FUN_1800f0260: pitch step PI/10, yaw step 2PI/40, vertical shift 0.05.
        const Real stepPitch = Ogre::Math::PI / 10.0f;
        const Real stepYaw = Ogre::Math::TWO_PI / 40.0f;
        const Real shift = 0.05f;
        const int rows = (int)((pitchEnd - pitchStart) / stepPitch);
        const int quadRows = rows + 1;
        const int cols = (int)(Ogre::Math::TWO_PI / stepYaw);
        const int ring = cols + 1;
        const int perRow = cols + 2;
        const int vertexRows = rows + 2;
        const Real dPitch = (pitchEnd - pitchStart) / (Real)quadRows;

        std::vector<float> vertices;
        vertices.reserve((size_t)(vertexRows * perRow * 8));
        for (int i = 0; i < vertexRows; ++i)
        {
            const Real pitch = (Real)i * dPitch + pitchStart;
            const Real cp = std::cos(pitch), sp = std::sin(pitch);
            const Real v = (0.5f - (Real)(i / quadRows)) * 0.01f + (Real)i / (Real)quadRows;
            for (int j = 0; j < perRow; ++j)
            {
                const Real yaw = (Real)j * (Ogre::Math::TWO_PI / (Real)ring);
                const Real cy = std::cos(yaw), sy = std::sin(yaw);
                vertices.push_back(cy * sp);
                vertices.push_back(cp - shift);
                vertices.push_back(sy * sp);
                vertices.push_back(-(cy * sp));
                vertices.push_back(-cp);
                vertices.push_back(-(sy * sp));
                vertices.push_back((Real)j / (Real)ring);
                vertices.push_back(v);
            }
        }
        std::vector<Ogre::uint16> indices;
        indices.reserve((size_t)(ring * quadRows * 6));
        for (int r = 0; r < quadRows; ++r)
        {
            for (int k = 0; k < ring; ++k)
            {
                const Ogre::uint16 a = (Ogre::uint16)(r * perRow + k);
                const Ogre::uint16 b = (Ogre::uint16)(a + perRow);
                indices.push_back(a);
                indices.push_back(b);
                indices.push_back((Ogre::uint16)(a + 1));
                indices.push_back((Ogre::uint16)(b + 1));
                indices.push_back((Ogre::uint16)(a + 1));
                indices.push_back(b);
            }
        }

        const String name = makeName("SkySphere_");
        Ogre::MeshPtr mesh = Ogre::MeshManager::getSingleton().createManual(name,
            Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
        Ogre::SubMesh* sub = mesh->createSubMesh();
        mesh->sharedVertexData = new Ogre::VertexData();
        mesh->sharedVertexData->vertexCount = (size_t)(vertexRows * perRow);
        Ogre::VertexDeclaration* decl = mesh->sharedVertexData->vertexDeclaration;
        size_t offset = 0;
        decl->addElement(0, offset, Ogre::VET_FLOAT3, Ogre::VES_POSITION);
        offset += Ogre::VertexElement::getTypeSize(Ogre::VET_FLOAT3);
        decl->addElement(0, offset, Ogre::VET_FLOAT3, Ogre::VES_NORMAL);
        offset += Ogre::VertexElement::getTypeSize(Ogre::VET_FLOAT3);
        decl->addElement(0, offset, Ogre::VET_FLOAT2, Ogre::VES_TEXTURE_COORDINATES, 0);
        offset += Ogre::VertexElement::getTypeSize(Ogre::VET_FLOAT2);
        Ogre::HardwareVertexBufferSharedPtr vbuf = Ogre::HardwareBufferManager::getSingleton().createVertexBuffer(
            offset, mesh->sharedVertexData->vertexCount, Ogre::HardwareBuffer::HBU_STATIC_WRITE_ONLY);
        vbuf->writeData(0, vbuf->getSizeInBytes(), &vertices[0], true);
        mesh->sharedVertexData->vertexBufferBinding->setBinding(0, vbuf);
        Ogre::HardwareIndexBufferSharedPtr ibuf = Ogre::HardwareBufferManager::getSingleton().createIndexBuffer(
            Ogre::HardwareIndexBuffer::IT_16BIT, indices.size(), Ogre::HardwareBuffer::HBU_STATIC_WRITE_ONLY);
        ibuf->writeData(0, ibuf->getSizeInBytes(), &indices[0], true);
        sub->useSharedVertices = true;
        sub->indexData->indexBuffer = ibuf;
        sub->indexData->indexCount = indices.size();
        sub->indexData->indexStart = 0;
        mesh->_setBounds(Ogre::AxisAlignedBox(-1, -1, -1, 1, 1, 1), true);
        mesh->_setBoundingSphereRadius(Ogre::Math::Sqrt(3.0f));
        mesh->load();
        mMeshes.push_back(name);
        return mesh;
    }
    //-----------------------------------------------------------------------
    void CYSSkyCyRenderer::buildSkySphere(const CYSSkySphereData& data, const CYSSkyWeather* weather,
                                          const String& sceneName)
    {
        destroy();
        mPrefix = "CYS/SkyCY/" + sceneName + "/";
        mSkySphere = true;
        mFixedHeight = data.enableFixedHeight;
        mFixedHeightValue = data.fixedHeight;
        if (!weather)
            return;
        // Draw order of the CY Dali trace (all queue 5 priority 100, same view depth): background, far_cloud,
        // mountain, near_cloud, fog. CY-Source keeps that order with priorities 100..104.
        static const int kOrder[] = { CYS_SKY_BACKGROUND, CYS_SKY_FAR_CLOUD, CYS_SKY_MOUNTAIN, CYS_SKY_NEAR_CLOUD, CYS_SKY_FOG };
        for (int o = 0; o < 5; ++o)
        {
            for (size_t i = 0; i < data.layers.size(); ++i)
            {
                if (data.layers[i].id == kOrder[o])
                    buildSphereLayer(data.layers[i], *weather, o);
            }
        }

        if ((weather->showMoon && data.moon.present) || (weather->showStar && data.star.present))
        {
            mExtras = new CYSSkyRenderer(mSystem);
            mExtras->setExtrasOnly(true);
            mExtras->buildSkySphere(data, weather, sceneName + "/extras");
            if (mExtras->isEmpty())
            {
                delete mExtras;
                mExtras = 0;
            }
        }
        char buf[160];
        sprintf(buf, "CYS-SKY: SkySphere sky '%s' with SkySphereLayer shaders: %u layers (+%u fixed-function extras)",
                sceneName.c_str(), (unsigned)mItems.size(), (unsigned)(mExtras ? mExtras->getNumElements() : 0));
        log(buf);
    }
    //-----------------------------------------------------------------------
    void CYSSkyCyRenderer::buildSphereLayer(const CYSSkyLayerDef& def, const CYSSkyWeather& weather, int order)
    {
        if (def.id < 0 || def.textureCount <= 0)
            return;
        Item* item = 0;
        for (size_t i = 0; i < weather.textureGroups.size(); ++i)
        {
            const CYSSkyTextureGroup& g = weather.textureGroups[i];
            if (!g.has[def.id] || !prepareTexture(g.textures[def.id], true))
                continue;
            if (!item)
                item = addItem(Item::SPHERE_LAYER, String("SkySphereLayer_") + def.name);
            item->curves.push_back(g.alpha);
            item->textures.push_back(g.textures[def.id]);
            item->uWraps.push_back(g.wraps[def.id] > 0 ? g.wraps[def.id] : 1.0f);
        }
        if (!item)
            return;
        item->sphereLayer = def;
        item->fogLayer = def.id == CYS_SKY_FOG;
        Ogre::MeshPtr mesh = skySphereMesh(def.pitchStart, def.pitchEnd);
        // FUN_1801d0440: node scale sqrt(distance^2 / (1 - 0.05^2)) (irrelevant on screen: blend_vp sets z = 0.999999 w).
        const Real scale = Ogre::Math::Sqrt(def.distance * def.distance / (1.0f - 0.05f * 0.05f));
        item->node->setScale(scale, scale, scale);

        const String name = makeName("SkySphere_" + def.name);
        item->material = Ogre::MaterialManager::getSingleton().create(name,
            Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
        std::vector<Real> alphas(item->curves.size(), 0.0f);
        rebuildSphereMaterial(item, alphas);
        attach(item, mesh, Ogre::RENDER_QUEUE_SKIES_EARLY, (Ogre::ushort)(100 + order));
    }
    //-----------------------------------------------------------------------
    void CYSSkyCyRenderer::rebuildSphereMaterial(Item* item, const std::vector<Real>& alphas)
    {
        // FUN_1801ce6f0 (shader branch): one pass, alpha blend, no depth write, no lighting, fog none; one texture unit
        // per active group (at most 3, u wrap); texUWrap/texVWrap = group wraps, blendFactor = alpha_i / sum with
        // w = min(sum, 1), blendColour = layer colour (sky_fog on the fog layer).
        item->active.clear();
        for (size_t i = 0; i < alphas.size() && item->active.size() < 3; ++i)
        {
            if (alphas[i] >= 0.001f)
                item->active.push_back((int)i);
        }
        Ogre::Material* m = item->material.get();
        m->removeAllTechniques();
        Ogre::Pass* pass = m->createTechnique()->createPass();
        if (item->active.empty())
        {
            // no group visible: nothing is written (FUN_1801ce6f0 colour write off + entity hidden)
            pass->setColourWriteEnabled(false);
            pass->setDepthWriteEnabled(false);
            pass->setLightingEnabled(false);
            m->load();
            item->vp.setNull();
            item->fp.setNull();
            return;
        }
        pass->setSceneBlending(Ogre::SBF_SOURCE_ALPHA, Ogre::SBF_ONE_MINUS_SOURCE_ALPHA);
        pass->setDepthWriteEnabled(false);
        pass->setLightingEnabled(false);
        pass->setAmbient(0, 0, 0);
        pass->setDiffuse(1, 1, 1, 1);
        pass->setSpecular(1, 1, 1, 1);
        pass->setFog(true, Ogre::FOG_NONE);
        static const char* const kCount[] = { "One", "Two", "Three" };
        const String count = kCount[item->active.size() - 1];
        pass->setVertexProgram("SkySphereLayerBlend_" + count + "Texture_VS_1_1_hlsl");
        pass->setFragmentProgram("SkySphereLayerBlend_" + count + "Texture_PS_2_0_hlsl");
        Real sum = 0;
        Ogre::Vector4 uWrap(1, 1, 1, 1), vWrap(1, 1, 1, 1), factor(0, 0, 0, 0);
        for (size_t k = 0; k < item->active.size(); ++k)
            sum += alphas[item->active[k]];
        for (size_t k = 0; k < item->active.size(); ++k)
        {
            const int g = item->active[k];
            Ogre::TextureUnitState* tex = pass->createTextureUnitState(item->textures[g]);
            tex->setTextureAddressingMode(Ogre::TextureUnitState::TAM_WRAP);
            uWrap[k] = item->uWraps[g];
            factor[k] = sum > 0 ? alphas[g] / sum : 0.0f;
        }
        factor[3] = std::min(sum, 1.0f);
        m->load();
        item->vp = pass->getVertexProgramParameters();
        item->fp = pass->getFragmentProgramParameters();
        setConst(item->vp, "texUWrap", uWrap);
        setConst(item->vp, "texVWrap", vWrap);
        setConst(item->fp, "blendFactor", factor);
        setConst(item->fp, "blendColour", Ogre::Vector4(1, 1, 1, 1));
    }

    //////////////////////////////////////////////////////////////////////////
    // Per frame
    //////////////////////////////////////////////////////////////////////////
    void CYSSkyCyRenderer::update(Real dt, const CYSEnvironment& env)
    {
        if (mExtras)
            mExtras->update(dt, env);
        if (!mRoot || !mSystem)
            return;
        Ogre::Camera* camera = mSystem->getCamera();
        if (!camera)
            return;
        Ogre::Vector3 cameraPos = camera->getDerivedPosition();
        if (mSkySphere && mFixedHeight)         // FUN_1801d0a50: enable_fixed_height keeps the root at fixed_height
            cameraPos.y = mFixedHeightValue;
        for (size_t i = 0; i < mItems.size(); ++i)
            updateItem(mItems[i], dt, env, cameraPos);
    }
    //-----------------------------------------------------------------------
    void CYSSkyCyRenderer::updateItem(Item* item, Real dt, const CYSEnvironment& env, const Ogre::Vector3& cameraPos)
    {
        const Real hours = env.timeOfDay;
        // FUN_1802378a0 -> sun direction and FUN_1801ea5c0: the dome and clouds get (sun direction, light one colour).
        const Ogre::Vector3 sunDir = celestialOrientation(mSun, hours, true) * Ogre::Vector3::UNIT_Z;
        const Ogre::Vector3 lightOne(env.lightOneDiffuse.r, env.lightOneDiffuse.g, env.lightOneDiffuse.b);

        switch (item->kind)
        {
        case Item::DOME:
        {
            // FUN_18023a0e0
            item->node->setPosition(cameraPos);
            setConst(item->vp, "SUN_POSITION", sunDir);
            setConst(item->vp, "SUN_COLOUR", lightOne);
            setConst(item->vp, "EN_DOME_PARAM1", Ogre::Vector3(hours / 24.0f, item->dome.height, item->dome.mieAmount));
            setConst(item->vp, "EN_DOME_PARAM2", Ogre::Vector4(0.2f, item->dome.vertexHeightEffect,
                                                               item->dome.sunHeightEffect, item->dome.power));
            setConst(item->fp, "weight", 1.0f);
            break;
        }
        case Item::CLOUD:
        {
            // FUN_18023b200
            const CYSEnTimeNode n = item->layer.sample(hours);
            const bool visible = n.alpha > 0.0f;
            if (visible != item->visible)
            {
                item->object->setVisible(visible);
                item->visible = visible;
            }
            item->node->setPosition(cameraPos);
            item->windSpeed += n.cloudSpeed * dt * 0.1f;
            if (item->layer.turnoverMesh && !item->turned)
            {
                item->node->roll(Ogre::Radian(Ogre::Math::PI));
                item->turned = true;
            }
            const CYSEnCloudLayer& l = item->layer;
            setConst(item->vp, "textureTile", Ogre::Vector4(l.textureTile.x, l.textureTile.y, l.skyCloudHeight * 15.0f,
                                                            l.textureTile.w));
            setConst(item->vp, "windSpeed", item->windSpeed);
            setConst(item->fp, "control", Ogre::Vector4(n.fog, n.cloudSpeed, n.ambientBlend, n.alpha));
            setConst(item->fp, "rimParam", Ogre::Vector4(l.rimStrength, l.rimPower, l.rimDetectPower, l.rimDetectWidth));
            setConst(item->fp, "dLight", Ogre::Vector4(sunDir.x, sunDir.y, sunDir.z, l.scatteringStrength));
            setConst(item->fp, "lcolor", Ogre::Vector4(lightOne.x, lightOne.y, lightOne.z, l.scatteringPower));
            break;
        }
        case Item::RING:
        {
            // FUN_18023c7a0
            const CYSEnTimeNode n = item->layer.sample(hours);
            const bool visible = n.alpha > 0.0f;
            if (visible != item->visible)
            {
                item->object->setVisible(visible);
                item->visible = visible;
            }
            const CYSEnCloudLayer& l = item->layer;
            item->node->setPosition(cameraPos + Ogre::Vector3(0, l.cloudHeight, 0));
            item->node->setScale(1.0f, l.cloudScale, 1.0f);
            if (n.rollSpeed == 0.0f)
            {
                item->node->setOrientation(Ogre::Quaternion(Ogre::Degree(l.cloudOffset), Ogre::Vector3::UNIT_Y));
                if (l.turnoverMesh)
                    item->node->roll(Ogre::Radian(Ogre::Math::PI));
            }
            else
            {
                item->node->yaw(Ogre::Degree(n.rollSpeed * dt));
                if (l.turnoverMesh != item->turned)
                {
                    item->node->roll(Ogre::Radian(l.turnoverMesh ? Ogre::Math::PI : -Ogre::Math::PI));
                    item->turned = l.turnoverMesh;
                }
            }
            item->vScroll += dt * n.verticalSpeed;
            if (item->vScroll > 1.0f)
                item->vScroll -= 1.0f;
            else if (item->vScroll < -1.0f)
                item->vScroll += 1.0f;
            setConst(item->vp, "offsetParam", Ogre::Vector4(l.textureRepeat, item->vScroll, l.parallax, 1.0f));
            setConst(item->fp, "control", Ogre::Vector4(n.fogBlend, n.fadeRange, n.ambientBlend, n.alpha));
            setConst(item->fp, "rimParam", Ogre::Vector4(l.rimStrength, l.rimPower, l.rimDetectPower, l.rimDetectWidth));
            setConst(item->fp, "dLight", Ogre::Vector4(sunDir.x, sunDir.y, sunDir.z, l.scatteringStrength));
            setConst(item->fp, "lcolor", Ogre::Vector4(lightOne.x, lightOne.y, lightOne.z, l.scatteringPower));
            break;
        }
        case Item::MOON:
        case Item::SUN:
        {
            // FUN_180236000 / FUN_1802378a0: parent node at the camera, orientation from orient/angle/day arc.
            item->node->setPosition(cameraPos);
            item->node->setOrientation(celestialOrientation(item->celestial, hours, item->kind == Item::SUN));
            break;
        }
        case Item::SPHERE_LAYER:
        {
            // FUN_1801d0a50: root at the camera, yaw rotate_speed * real seconds; FUN_1800f53b0: group alphas at the
            // day fraction, rebuild when the visible set changes, else blendFactor = (a0, a1, a2, sum) (FUN_1801ce0f0).
            item->node->setPosition(cameraPos);
            if (item->sphereLayer.rotateSpeed != 0.0f)
                item->node->yaw(Ogre::Radian(item->sphereLayer.rotateSpeed * dt));
            const Real day = hours / 24.0f;
            std::vector<Real> alphas(item->curves.size());
            std::vector<int> active;
            for (size_t i = 0; i < alphas.size(); ++i)
            {
                alphas[i] = item->curves[i].sample(day);
                if (alphas[i] >= 0.001f && active.size() < 3)
                    active.push_back((int)i);
            }
            if (active != item->active)
            {
                rebuildSphereMaterial(item, alphas);
            }
            else if (!item->active.empty())
            {
                Ogre::Vector4 factor(0, 0, 0, 0);
                for (size_t k = 0; k < item->active.size(); ++k)
                {
                    factor[k] = alphas[item->active[k]];
                    factor[3] += factor[k];
                }
                setConst(item->fp, "blendFactor", factor);
            }
            const bool visible = !item->active.empty();
            if (visible != item->visible)
            {
                item->object->setVisible(visible);
                item->visible = visible;
            }
            if (item->fogLayer)
                setConst(item->fp, "blendColour", Ogre::Vector4(env.skyFogColour.r, env.skyFogColour.g,
                                                                env.skyFogColour.b, env.skyFogColour.a));
            break;
        }
        default:
            break;
        }
    }
}
