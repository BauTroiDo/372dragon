// CY-Source (scene agent): see CYSSkyRenderer.h.
#include "CYSSkyRenderer.h"
#include "CYSEnvironment.h"

#include "Core/WXSystem.h"

#include <OgreSceneManager.h>
#include <OgreSceneNode.h>
#include <OgreCamera.h>
#include <OgreEntity.h>
#include <OgreSubEntity.h>
#include <OgreManualObject.h>
#include <OgreBillboardSet.h>
#include <OgreBillboard.h>
#include <OgreMaterialManager.h>
#include <OgreTextureManager.h>
#include <OgreTechnique.h>
#include <OgrePass.h>
#include <OgreTextureUnitState.h>
#include <OgreResourceGroupManager.h>
#include <OgreImage.h>
#include <OgreStringConverter.h>
#include <OgreException.h>
#include <OgreMesh.h>

#include <algorithm>
#include <cmath>
#include <ctime>

namespace WX
{
    using namespace CYSScene;

    //////////////////////////////////////////////////////////////////////////
    // Element
    //////////////////////////////////////////////////////////////////////////
    struct CYSSkyRenderer::Element
    {
        enum Kind
        {
            DOME,
            CLOUD,
            RING,
            SUN,
            SUN_FLARE,
            MOON,
            STARS,
            SPHERE_LAYER,
            SPHERE_MOON,
        };

        int kind;
        Real order;
        String label;
        Ogre::SceneNode* node;
        Ogre::MovableObject* object;
        String materialName;
        Ogre::Pass* pass;
        Ogre::TextureUnitState* unit0;
        Ogre::TextureUnitState* unit1;
        Ogre::TextureUnitState* unit2;

        CYSEnSkyDome dome;
        CYSEnCloudLayer layer;
        CYSEnCelestial celestial;
        CYSSkyLayerDef sphereLayer;
        int sphereLayerId;
        CYSSkyAlphaCurve curve0;
        Real wrap0;
        // SkySphere layer: one texture stage per texture group, weighted by the group alpha curves.
        std::vector<CYSSkyAlphaCurve> groupCurves;
        std::vector<Ogre::TextureUnitState*> groupUnits;
        std::vector<Real> lastWeights;

        Real scrollU, scrollV;
        Real yaw;
        Real size;
        bool alwaysVisible;
        Real intensity;
        Ogre::Vector3 fixedDirection;
        bool hasFixedDirection;

        // last values given to OGRE (to avoid dirtying pass hashes every frame)
        Ogre::ColourValue lastTint;
        Ogre::ColourValue lastFog;
        Real lastFactor;
        Real lastAlpha;

        Element(void)
            : kind(DOME), order(0), node(0), object(0), pass(0), unit0(0), unit1(0), unit2(0)
            , sphereLayerId(-1), wrap0(1)
            , scrollU(0), scrollV(0), yaw(0), size(0.1f), alwaysVisible(false), intensity(1)
            , fixedDirection(Ogre::Vector3::UNIT_Y), hasFixedDirection(false)
            , lastTint(-1, -1, -1, -1), lastFog(-1, -1, -1, -1), lastFactor(-1), lastAlpha(-1)
        {
        }
    };

    //////////////////////////////////////////////////////////////////////////
    // helpers
    //////////////////////////////////////////////////////////////////////////
    namespace
    {
        // enskydome.mesh bounds: x/z +-3170.03, y +-1769.53 (Tools/re: M_MESH_BOUNDS); ringcloud.mesh: radius
        // 217.5, half height 71.4.
        const Real kDomeRadius = 3170.03f;
        const Real kDomeHalfHeight = 1769.53f;
        const Real kRingRadius = 217.5f;
        const Real kRingHalfHeight = 71.4f;

        const Ogre::uint8 kQueueSlots[] = { 1, 2, 3, 4, 6, 7, 8, 9 };

        inline bool changed(const Ogre::ColourValue& a, const Ogre::ColourValue& b)
        {
            return std::fabs(a.r - b.r) > 1e-3f || std::fabs(a.g - b.g) > 1e-3f || std::fabs(a.b - b.b) > 1e-3f ||
                   std::fabs(a.a - b.a) > 1e-3f;
        }






        const Real kCyMoonDistance = 9000.0f;
        const Real kCyMoonPlane = 200.0f;

        Real cyMoonDayFraction(Real hours, Real up, Real down)
        {
            if (up < down)
            {
                if (down < hours) return (hours - down) / (((24.0f - down) + up) * 2.0f) + 0.25f;
                if (hours < up) return ((hours + 24.0f) - down) / (((24.0f - down) + up) * 2.0f) + 0.25f;
            }
            else
            {
                if (hours <= up)
                {
                    if (down <= hours) return (hours - down) / ((up - down) * 2.0f) + 0.25f;
                    hours += 24.0f;
                }
                down += 24.0f;
            }
            return (hours - up) / ((down - up) * 2.0f) + 0.75f;
        }

        Ogre::Vector3 cyMoonDirection(const CYSEnCelestial& c, Real hours)
        {
            Ogre::Quaternion q = Ogre::Quaternion(Ogre::Degree(c.orient + 180.0f), Ogre::Vector3::NEGATIVE_UNIT_Y) *
                                 Ogre::Quaternion(Ogre::Degree(-c.angle), Ogre::Vector3::NEGATIVE_UNIT_X);
            if (!c.fixed)
                q = q * Ogre::Quaternion(Ogre::Degree(cyMoonDayFraction(hours, c.upTime, c.downTime) * 360.0f),
                                         Ogre::Vector3::NEGATIVE_UNIT_Y);
            return q * Ogre::Vector3::NEGATIVE_UNIT_Z;
        }

        /// Direction from azimuth (degrees, 0 = +Z, clockwise seen from above towards +X) and elevation (degrees).
        Ogre::Vector3 directionFromAngles(Real azimuthDeg, Real elevationDeg)
        {
            const Real az = Ogre::Math::DegreesToRadians(azimuthDeg);
            const Real el = Ogre::Math::DegreesToRadians(elevationDeg);
            return Ogre::Vector3(std::cos(el) * std::sin(az), std::sin(el), std::cos(el) * std::cos(az));
        }

        /// Fraction [0,1] of the way from `up` to `down` hours (wrapping midnight); <0 or >1 when outside.
        Real arcProgress(Real hours, Real up, Real down)
        {
            Real span = down - up;
            if (span <= 0)
                span += 24.0f;
            Real since = hours - up;
            if (since < 0)
                since += 24.0f;
            return since / span;
        }

        /// 1 in daylight between sunrise and sunset, 0 at night, one-hour ramps (INF).
        Real daylight(Real hours, Real up, Real down)
        {
            const Real rise = saturate((hours - (up - 0.5f)) / 1.0f);
            const Real set = saturate(((down + 0.5f) - hours) / 1.0f);
            return (up < down) ? std::min(rise, set) : std::max(rise, set);
        }

        /// A small soft round dot used for stars (created once per process).
        const String& starTextureName(void)
        {
            static const String name = "CYS/Sky/StarDot";
            Ogre::TextureManager& tm = Ogre::TextureManager::getSingleton();
            if (tm.getByName(name).isNull())
            {
                const int size = 16;
                std::vector<unsigned char> pixels(size * size * 4);
                for (int y = 0; y < size; ++y)
                {
                    for (int x = 0; x < size; ++x)
                    {
                        const Real dx = (x + 0.5f) / size * 2 - 1;
                        const Real dy = (y + 0.5f) / size * 2 - 1;
                        const Real r = std::sqrt(dx * dx + dy * dy);
                        const Real a = saturate(1.0f - r);
                        const unsigned char v = (unsigned char)(255.0f * a * a + 0.5f);
                        unsigned char* p = &pixels[(y * size + x) * 4];
                        p[0] = p[1] = p[2] = v;     // B G R
                        p[3] = v;                   // A
                    }
                }
                Ogre::Image image;
                image.loadDynamicImage(&pixels[0], size, size, Ogre::PF_A8R8G8B8);
                tm.loadImage(name, Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME, image, Ogre::TEX_TYPE_2D, 0);
            }
            return name;
        }

        /// Deterministic pseudo random numbers for the star field.
        struct Lcg
        {
            unsigned int s;
            explicit Lcg(unsigned int seed) : s(seed) {}
            Real next(void)
            {
                s = s * 1664525u + 1013904223u;
                return (Real)((s >> 8) & 0xFFFFFF) / (Real)0x1000000;
            }
        };
    }

    //////////////////////////////////////////////////////////////////////////
    // CYSSkyRenderer
    //////////////////////////////////////////////////////////////////////////
    CYSSkyRenderer::CYSSkyRenderer(System* system)
        : mSystem(system)
        , mSceneManager(system ? system->getSceneManager() : 0)
        , mRoot(0)
        , mCounter(0)
        , mTime(0)
        , mHasSun(false)
        , mExtrasOnly(false)
    {
    }
    //-----------------------------------------------------------------------
    CYSSkyRenderer::~CYSSkyRenderer()
    {
        destroy();
    }
    //-----------------------------------------------------------------------
    String CYSSkyRenderer::makeName(const String& label)
    {
        return mPrefix + label + "#" + Ogre::StringConverter::toString(mCounter++);
    }
    //-----------------------------------------------------------------------
    bool CYSSkyRenderer::textureExists(const String& name) const
    {
        if (name.empty())
            return false;
        if (!Ogre::TextureManager::getSingleton().getByName(name).isNull())
            return true;
        Ogre::ResourceGroupManager& rgm = Ogre::ResourceGroupManager::getSingleton();
        Ogre::StringVector groups = rgm.getResourceGroups();
        for (size_t i = 0; i < groups.size(); ++i)
        {
            try
            {
                if (rgm.resourceExists(groups[i], name))
                    return true;
            }
            catch (const Ogre::Exception&)
            {
            }
        }
        return false;
    }
    //-----------------------------------------------------------------------
    CYSSkyRenderer::Element* CYSSkyRenderer::addElement(int kind, Real order, const String& label)
    {
        if (!mRoot)
        {
            mRoot = mSystem->getBaseSceneNode()->createChildSceneNode();
            mRoot->setInheritScale(false);
        }
        Element* e = new Element;
        e->kind = kind;
        e->order = order;
        e->label = label;
        e->node = mRoot->createChildSceneNode();
        mElements.push_back(e);
        return e;
    }
    //-----------------------------------------------------------------------
    Ogre::Pass* CYSSkyRenderer::createMaterial(Element* e, const String& texture, bool alphaBlend, bool vertexColour)
    {
        e->materialName = makeName(e->label + "/Material");
        Ogre::MaterialPtr material = Ogre::MaterialManager::getSingleton().create(
            e->materialName, Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
        if (material->getNumTechniques() == 0)
            material->createTechnique();
        Ogre::Technique* technique = material->getTechnique(0);
        if (technique->getNumPasses() == 0)
            technique->createPass();
        Ogre::Pass* pass = technique->getPass(0);
        pass->setLightingEnabled(false);
        pass->setDepthCheckEnabled(false);      // drawn before the scene, ordered by render queue
        pass->setDepthWriteEnabled(false);
        pass->setFog(true, Ogre::FOG_NONE);
        pass->setCullingMode(Ogre::CULL_NONE);
        pass->setManualCullingMode(Ogre::MANUAL_CULL_NONE);
        if (alphaBlend)
            pass->setSceneBlending(Ogre::SBT_TRANSPARENT_ALPHA);
        e->pass = pass;
        e->unit0 = pass->createTextureUnitState(texture);
        e->unit0->setTextureFiltering(Ogre::TFO_BILINEAR);
        (void)vertexColour;
        return pass;
    }
    //-----------------------------------------------------------------------
    void CYSSkyRenderer::assignRenderQueues(void)
    {
        // CYS-LOGIN: one render queue per distinct layer value instead of one per element. Elements are sorted inside a
        // queue by view depth, and every sky element sits at the camera (depth 0), so two elements sharing a queue draw
        // in no defined order. Before, the 8 slots ran out after 7 elements and the erengu_DL moon (layer 30, the top
        // layer as in CY) shared the last queue with 7 cloud layers. Cloud/ring layers whose alpha is 0 at every time
        // node draw nothing and take no slot of their own; if more distinct layers remain than slots, the lowest share
        // the first slot.
        struct Local
        {
            static bool invisible(const Element* e)
            {
                if ((e->kind != Element::CLOUD && e->kind != Element::RING) || e->layer.timeNodes.empty())
                    return false;
                for (size_t i = 0; i < e->layer.timeNodes.size(); ++i)
                    if (e->layer.timeNodes[i].alpha > 1e-3f)
                        return false;
                return true;
            }
        };
        std::vector<Real> orders;
        for (size_t i = 0; i < mElements.size(); ++i)
            if (!Local::invisible(mElements[i]))
                orders.push_back(mElements[i]->order);
        std::sort(orders.begin(), orders.end());
        orders.erase(std::unique(orders.begin(), orders.end()), orders.end());
        const size_t slots = sizeof(kQueueSlots) / sizeof(kQueueSlots[0]);
        const size_t shift = orders.size() > slots ? orders.size() - slots : 0;
        for (size_t i = 0; i < mElements.size(); ++i)
        {
            Element* e = mElements[i];
            if (!e->object)
                continue;
            // rank = number of visible distinct layers below or equal to this one, minus one
            size_t rank = (size_t)(std::upper_bound(orders.begin(), orders.end(), e->order) - orders.begin());
            rank = rank > 0 ? rank - 1 : 0;
            rank = rank > shift ? rank - shift : 0;
            e->object->setRenderQueueGroup(kQueueSlots[std::min(rank, slots - 1)]);
        }
    }
    //-----------------------------------------------------------------------
    void CYSSkyRenderer::destroy(void)
    {
        for (size_t i = 0; i < mElements.size(); ++i)
        {
            Element* e = mElements[i];
            if (e->object && mSceneManager)
            {
                if (e->node)
                    e->node->detachObject(e->object);
                const String& type = e->object->getMovableType();
                try
                {
                    if (type == "ManualObject")
                        mSceneManager->destroyManualObject(static_cast<Ogre::ManualObject*>(e->object));
                    else if (type == "BillboardSet")
                        mSceneManager->destroyBillboardSet(static_cast<Ogre::BillboardSet*>(e->object));
                    else if (type == "Entity")
                        mSceneManager->destroyEntity(static_cast<Ogre::Entity*>(e->object));
                }
                catch (const Ogre::Exception&)
                {
                }
            }
            if (!e->materialName.empty())
            {
                try
                {
                    Ogre::MaterialManager::getSingleton().remove(e->materialName);
                }
                catch (const Ogre::Exception&)
                {
                }
            }
            delete e;
        }
        mElements.clear();
        if (mRoot && mSceneManager)
        {
            mRoot->removeAndDestroyAllChildren();
            mSceneManager->destroySceneNode(mRoot->getName());
        }
        mRoot = 0;
    }
    //-----------------------------------------------------------------------
    void CYSSkyRenderer::setVisible(bool visible)
    {
        if (mRoot)
            mRoot->setVisible(visible, true);
    }

    //////////////////////////////////////////////////////////////////////////
    // EnScene
    //////////////////////////////////////////////////////////////////////////
    void CYSSkyRenderer::buildEnScene(const CYSEnSky& sky, const String& sceneName)
    {
        destroy();
        mPrefix = "CYS/Sky/" + sceneName + "/";
        mSun = sky.sun;
        mHasSun = sky.sun.present;

        if (sky.dome.present && !mExtrasOnly)
            buildDome(sky.dome);
        for (size_t i = 0; i < sky.clouds.size() && !mExtrasOnly; ++i)
            buildCloudLayer(sky.clouds[i]);
        for (size_t i = 0; i < sky.ringClouds.size() && !mExtrasOnly; ++i)
            buildRingLayer(sky.ringClouds[i]);
        if (sky.sun.present && sky.sun.enable)
            buildCelestial(sky.sun, true);
        if (sky.moon.present && sky.moon.enable && !mExtrasOnly)
            buildCelestial(sky.moon, false);
        if (sky.star.present && sky.star.enable)
            buildStars(sky.star.count, sky.star.size, sky.star.startColour, sky.star.endColour, sky.star.fixed,
                       sky.star.intensity);
        assignRenderQueues();
    }
    //-----------------------------------------------------------------------
    void CYSSkyRenderer::buildDome(const CYSEnSkyDome& dome)
    {
        if (!textureExists(dome.texture))
        {
            logOnce("sky texture:" + dome.texture, "sky dome texture '" + dome.texture + "' not found");
            return;
        }
        Element* e = addElement(Element::DOME, -1000.0f, "Dome");
        e->dome = dome;
        createMaterial(e, dome.texture, false, false);
        // u = time of day (scrolled per frame), v = 1 - elevation: wrap in u, clamp in v.
        e->unit0->setTextureAddressingMode(Ogre::TextureUnitState::TAM_WRAP, Ogre::TextureUnitState::TAM_CLAMP,
                                           Ogre::TextureUnitState::TAM_CLAMP);

        // Flattened dome of enskydome.mesh, shifted by <hight> like En_sky_dome_v; v from the unshifted direction.
        Ogre::ManualObject* mo = mSceneManager->createManualObject(makeName("DomeObject"));
        const int slices = 48, stacks = 32;
        const Real ry = kDomeHalfHeight / kDomeRadius;
        const Real shift = dome.height / kDomeRadius;
        mo->estimateVertexCount((slices + 1) * (stacks + 1));
        mo->estimateIndexCount(slices * stacks * 6);
        mo->begin(e->materialName);
        for (int j = 0; j <= stacks; ++j)
        {
            const Real phi = Ogre::Math::PI * j / stacks;       // 0 = zenith
            for (int i = 0; i <= slices; ++i)
            {
                const Real theta = Ogre::Math::TWO_PI * i / slices;
                const Ogre::Vector3 p(std::sin(phi) * std::cos(theta), std::cos(phi) * ry, std::sin(phi) * std::sin(theta));
                const Real normY = p.y / std::max(p.length(), 1e-6f);
                mo->position(p.x, p.y + shift, p.z);
                mo->textureCoord(0.0f, saturate(1.0f - normY));
            }
        }
        for (int j = 0; j < stacks; ++j)
        {
            for (int i = 0; i < slices; ++i)
            {
                const Ogre::uint16 a = (Ogre::uint16)(j * (slices + 1) + i);
                const Ogre::uint16 b = (Ogre::uint16)(a + slices + 1);
                mo->triangle(a, b, (Ogre::uint16)(a + 1));
                mo->triangle((Ogre::uint16)(a + 1), b, (Ogre::uint16)(b + 1));
            }
        }
        mo->end();
        e->object = mo;
        e->node->attachObject(mo);
    }
    //-----------------------------------------------------------------------
    void CYSSkyRenderer::buildCloudLayer(const CYSEnCloudLayer& layer)
    {
        if (!textureExists(layer.textureName))
        {
            logOnce("sky texture:" + layer.textureName, "cloud texture '" + layer.textureName + "' not found");
            return;
        }
        Ogre::Entity* entity = 0;
        try
        {
            entity = mSceneManager->createEntity(makeName("CloudEntity"), layer.meshName);
        }
        catch (const Ogre::Exception& ex)
        {
            logOnce("sky mesh:" + layer.meshName, "cloud mesh '" + layer.meshName + "' not loaded: " + ex.getDescription());
            return;
        }
        Element* e = addElement(Element::CLOUD, (Real)layer.layer, "Cloud");
        e->layer = layer;
        createMaterial(e, layer.textureName, true, false);
        const Real tileU = layer.textureTile.x > 0 ? layer.textureTile.x : 1.0f;
        const Real tileV = layer.textureTile.y > 0 ? layer.textureTile.y : 1.0f;
        e->unit0->setTextureScale(1.0f / tileU, 1.0f / tileV);
        e->unit1 = e->pass->createTextureUnitState(layer.textureName);
        e->unit1->setTextureFiltering(Ogre::TFO_BILINEAR);
        e->unit1->setTextureScale(1.0f / tileU, 1.0f / tileV);

        entity->setMaterialName(e->materialName);
        entity->setCastShadows(false);
        entity->setQueryFlags(0);
        e->object = entity;
        e->node->attachObject(entity);

        // Mesh space -> sky unit space; offset and yaw from the layer (INF: skyCloudHeight = textureTile.z).
        Real radius = entity->getMesh()->getBoundingSphereRadius();
        if (radius <= 0)
            radius = 1.0f;
        const Real s = 1.0f / radius;
        e->node->setScale(s, layer.turnoverMesh ? -s : s, s);
        e->node->setPosition(0, layer.skyCloudHeight * s, 0);
        e->yaw = layer.rotAngle;
        e->node->setOrientation(Ogre::Quaternion(Ogre::Radian(e->yaw), Ogre::Vector3::UNIT_Y));
    }
    //-----------------------------------------------------------------------
    void CYSSkyRenderer::buildRingLayer(const CYSEnCloudLayer& layer)
    {
        if (!textureExists(layer.textureName))
        {
            logOnce("sky texture:" + layer.textureName, "ring cloud texture '" + layer.textureName + "' not found");
            return;
        }
        Element* e = addElement(Element::RING, (Real)layer.layer, "Ring");
        e->layer = layer;
        createMaterial(e, layer.textureName, true, true);
        e->unit0->setTextureAddressingMode(Ogre::TextureUnitState::TAM_WRAP, Ogre::TextureUnitState::TAM_CLAMP,
                                           Ogre::TextureUnitState::TAM_CLAMP);
        e->unit1 = e->pass->createTextureUnitState(layer.textureName);
        e->unit1->setTextureFiltering(Ogre::TFO_BILINEAR);
        e->unit1->setTextureAddressingMode(Ogre::TextureUnitState::TAM_WRAP, Ogre::TextureUnitState::TAM_CLAMP,
                                           Ogre::TextureUnitState::TAM_CLAMP);

        // Ring with ringcloud.mesh proportions scaled by CloudScale and lifted by CloudHeight (mesh units);
        // En_ringcloudp's vertical fade min((1 - 2|v - 0.5|) / fadeRange, 1) is baked into the vertex alpha.
        const CYSEnTimeNode node = layer.sample(12.0f);
        const Real fade = node.fadeRange > 1e-4f ? node.fadeRange : 0.0f;
        const Real scale = layer.cloudScale > 0 ? layer.cloudScale : 1.0f;
        const Real halfHeight = kRingHalfHeight * scale;
        const Real radius = kRingRadius * scale;
        const Real lift = layer.cloudHeight;
        const Real repeat = layer.textureRepeat > 0 ? layer.textureRepeat : 1.0f;
        const Real uOffset = layer.cloudOffset / 360.0f;

        Ogre::ManualObject* mo = mSceneManager->createManualObject(makeName("RingObject"));
        const int slices = 72, rows = 8;
        mo->estimateVertexCount((slices + 1) * (rows + 1));
        mo->estimateIndexCount(slices * rows * 6);
        mo->begin(e->materialName);
        for (int j = 0; j <= rows; ++j)
        {
            const Real v = (Real)j / rows;       // 0 = top
            const Real y = (1.0f - 2.0f * v) * halfHeight + lift;
            const Real distance = 1.0f - 2.0f * std::fabs(v - 0.5f);
            const Real alpha = fade > 0 ? std::min(distance / fade, 1.0f) : 1.0f;
            for (int i = 0; i <= slices; ++i)
            {
                const Real u = (Real)i / slices;
                const Real theta = Ogre::Math::TWO_PI * u;
                mo->position(radius * std::cos(theta) / radius, y / radius, radius * std::sin(theta) / radius);
                mo->textureCoord(u * repeat + uOffset, v);
                mo->colour(1.0f, 1.0f, 1.0f, alpha);
            }
        }
        for (int j = 0; j < rows; ++j)
        {
            for (int i = 0; i < slices; ++i)
            {
                const Ogre::uint16 a = (Ogre::uint16)(j * (slices + 1) + i);
                const Ogre::uint16 b = (Ogre::uint16)(a + slices + 1);
                mo->triangle(a, b, (Ogre::uint16)(a + 1));
                mo->triangle((Ogre::uint16)(a + 1), b, (Ogre::uint16)(b + 1));
            }
        }
        mo->end();
        mo->setQueryFlags(0);
        e->object = mo;
        e->node->attachObject(mo);
        e->node->setScale(0.98f, 0.98f, 0.98f);
    }
    //-----------------------------------------------------------------------
    void CYSSkyRenderer::buildCelestial(const CYSEnCelestial& c, bool sun)
    {
        if (!textureExists(c.texture))
        {
            logOnce("sky texture:" + c.texture, String(sun ? "sun" : "moon") + " texture '" + c.texture + "' not found");
            return;
        }
        const Real order = c.hasLayer ? (Real)c.layer : (sun ? -100.0f : -90.0f);
        if (sun && mExtrasOnly)             // CYS-SKY: the sun plane is drawn by CYSSkyCyRenderer, keep only the flare
        {
            if (c.useSunFlare && textureExists(c.flareTexture))
            {
                Element* f = addElement(Element::SUN_FLARE, order + 0.5f, "SunFlare");
                f->celestial = c;
                f->size = std::max(0.01f, c.scale * 0.01f) * 3.0f;
                f->intensity = 0.6f;
                createMaterial(f, c.flareTexture, false, false);
                f->pass->setSceneBlending(Ogre::SBF_SOURCE_ALPHA, Ogre::SBF_ONE);
                f->unit0->setTextureAddressingMode(Ogre::TextureUnitState::TAM_CLAMP);
                Ogre::BillboardSet* flare = mSceneManager->createBillboardSet(makeName("SunFlareSet"), 1);
                flare->setMaterialName(f->materialName);
                flare->setDefaultDimensions(f->size, f->size);
                flare->createBillboard(Ogre::Vector3(0, 0.9f, 0));
                flare->setBounds(Ogre::AxisAlignedBox(-1.5f, -1.5f, -1.5f, 1.5f, 1.5f, 1.5f), 2.6f);
                flare->setCastShadows(false);
                flare->setQueryFlags(0);
                f->object = flare;
                f->node->attachObject(flare);
            }
            return;
        }
        Element* e = addElement(sun ? Element::SUN : Element::MOON, order, sun ? "Sun" : "Moon");
        e->celestial = c;
        e->size = std::max(0.01f, c.scale * 0.01f);         // INF: B scale 6..49 -> share of the sky radius
        if (!sun)                                           // CYS-LOGIN: CY plane 200 * scale at 9000, billboard at 0.95
            e->size = std::max(0.01f, c.scale * kCyMoonPlane / kCyMoonDistance * 0.95f);
        createMaterial(e, c.texture, true, false);
        e->unit0->setTextureAddressingMode(Ogre::TextureUnitState::TAM_CLAMP);
        Ogre::BillboardSet* set = mSceneManager->createBillboardSet(makeName(sun ? "SunSet" : "MoonSet"), 1);
        set->setMaterialName(e->materialName);
        set->setDefaultDimensions(e->size, e->size);
        set->createBillboard(Ogre::Vector3(0, 0.9f, 0));
        // CYS-LOGIN: updateElement moves the billboard with Billboard::setPosition, which does not grow the set bounds
        // (OGRE 1.2): the bounds stayed around the zenith and the frustum culled the moon whenever the camera did not look
        // up (CY login camera pitch -4 deg). The celestial billboard may sit anywhere on the unit sphere.
        set->setBounds(Ogre::AxisAlignedBox(-1.5f, -1.5f, -1.5f, 1.5f, 1.5f, 1.5f), 2.6f);
        set->setCastShadows(false);
        set->setQueryFlags(0);
        e->object = set;
        e->node->attachObject(set);

        if (sun && c.useSunFlare && textureExists(c.flareTexture))
        {
            Element* f = addElement(Element::SUN_FLARE, order + 0.5f, "SunFlare");
            f->celestial = c;
            f->size = e->size * 3.0f;       // INF
            f->intensity = 0.6f;            // INF (En_flare_fp intensity)
            createMaterial(f, c.flareTexture, false, false);
            f->pass->setSceneBlending(Ogre::SBF_SOURCE_ALPHA, Ogre::SBF_ONE);
            f->unit0->setTextureAddressingMode(Ogre::TextureUnitState::TAM_CLAMP);
            Ogre::BillboardSet* flare = mSceneManager->createBillboardSet(makeName("SunFlareSet"), 1);
            flare->setMaterialName(f->materialName);
            flare->setDefaultDimensions(f->size, f->size);
            flare->createBillboard(Ogre::Vector3(0, 0.9f, 0));
            flare->setBounds(Ogre::AxisAlignedBox(-1.5f, -1.5f, -1.5f, 1.5f, 1.5f, 1.5f), 2.6f);     // CYS-LOGIN: as above
            flare->setCastShadows(false);
            flare->setQueryFlags(0);
            f->object = flare;
            f->node->attachObject(flare);
        }
    }
    //-----------------------------------------------------------------------
    void CYSSkyRenderer::buildStars(int count, Real size, const Ogre::ColourValue& start, const Ogre::ColourValue& end,
                                    bool alwaysVisible, Real intensity)
    {
        if (count <= 0)
            return;
        count = std::min(count, 8192);
        Element* e = addElement(Element::STARS, -500.0f, "Stars");
        e->alwaysVisible = alwaysVisible;
        e->intensity = intensity;
        createMaterial(e, starTextureName(), false, true);
        e->pass->setSceneBlending(Ogre::SBT_ADD);
        e->unit0->setTextureAddressingMode(Ogre::TextureUnitState::TAM_CLAMP);
        e->unit0->setColourOperationEx(Ogre::LBX_MODULATE, Ogre::LBS_TEXTURE, Ogre::LBS_DIFFUSE);
        e->unit1 = e->pass->createTextureUnitState(starTextureName());
        e->unit1->setTextureAddressingMode(Ogre::TextureUnitState::TAM_CLAMP);

        Ogre::BillboardSet* set = mSceneManager->createBillboardSet(makeName("StarSet"), count);
        set->setMaterialName(e->materialName);
        const Real dim = std::max(0.0008f, size * 0.0002f);     // INF: a few pixels
        set->setDefaultDimensions(dim, dim);
        Lcg rng(0x5EED1234u + (unsigned int)count);
        for (int i = 0; i < count; ++i)
        {
            // Uniform on the upper hemisphere, slightly below the horizon too.
            const Real z = rng.next() * 1.05f - 0.05f;
            const Real phi = rng.next() * Ogre::Math::TWO_PI;
            const Real r = std::sqrt(std::max(0.0f, 1.0f - z * z));
            const Ogre::ColourValue c = lerp(start, end, rng.next()) * saturate(intensity);
            set->createBillboard(Ogre::Vector3(r * std::cos(phi), z, r * std::sin(phi)) * 0.97f,
                                 Ogre::ColourValue(c.r, c.g, c.b, 1.0f));
        }
        set->setCastShadows(false);
        set->setQueryFlags(0);
        e->object = set;
        e->node->attachObject(set);
    }

    //////////////////////////////////////////////////////////////////////////
    // SkySphere
    //////////////////////////////////////////////////////////////////////////
    void CYSSkyRenderer::buildSkySphere(const CYSSkySphereData& data, const CYSSkyWeather* weather,
                                        const String& sceneName)
    {
        destroy();
        mPrefix = "CYS/Sky/" + sceneName + "/";
        mHasSun = false;
        if (!weather)
            return;
        for (size_t i = 0; i < data.layers.size() && !mExtrasOnly; ++i)
            buildSkySphereLayer(data.layers[i], *weather);
        if (weather->showMoon && data.moon.present)
            buildSkySphereMoon(data);
        if (weather->showStar && data.star.present)
            buildStars(data.star.count, data.star.size * 1.25f, data.star.startColour, data.star.endColour, false,
                       data.star.intensity > 0 ? 1.0f : 0.0f);
        assignRenderQueues();
    }
    //-----------------------------------------------------------------------
    void CYSSkyRenderer::buildSkySphereLayer(const CYSSkyLayerDef& def, const CYSSkyWeather& weather)
    {
        if (def.id < 0 || def.textureCount <= 0)
            return;
        // Every texture group that gives this layer a texture (client_GL: up to 3 per weather, 170 of 309 weathers
        // have 3: night, dusk, day). Their alpha curves are authored as a partition of unity, so the layer shows
        // sum(alpha_i * texture_i): stage i blends texture i in by alpha_i / (alpha_0 + ... + alpha_i).
        const size_t kMaxGroups = 6;        // group stages + the tint stage <= 8 (D3D9 fixed function)
        const size_t maxGroups = std::min(kMaxGroups, (size_t)def.textureCount);
        std::vector<const CYSSkyTextureGroup*> groups;
        for (size_t i = 0; i < weather.textureGroups.size() && groups.size() < maxGroups; ++i)
        {
            const CYSSkyTextureGroup& g = weather.textureGroups[i];
            if (g.has[def.id] && textureExists(g.textures[def.id]))
                groups.push_back(&g);
            else if (g.has[def.id])
                logOnce("sky texture:" + g.textures[def.id], "sky layer texture '" + g.textures[def.id] + "' not found");
        }
        if (groups.empty())
            return;

        // Fixed order: background, far_cloud, mountain, near_cloud, fog (INF; the file lists them alphabetically).
        static const Real kLayerOrder[CYS_SKY_LAYER_COUNT] = { 0, 1, 4, 2, 3 };
        Element* e = addElement(Element::SPHERE_LAYER, -800.0f + kLayerOrder[def.id], String("Layer_") + def.name);
        e->sphereLayer = def;
        e->sphereLayerId = def.id;
        e->wrap0 = groups[0]->wraps[def.id] > 0 ? groups[0]->wraps[def.id] : 1.0f;
        e->curve0 = groups[0]->alpha;
        const bool background = def.id == CYS_SKY_BACKGROUND;
        createMaterial(e, groups[0]->textures[def.id], !background, false);
        e->unit0->setTextureAddressingMode(Ogre::TextureUnitState::TAM_WRAP, Ogre::TextureUnitState::TAM_CLAMP,
                                           Ogre::TextureUnitState::TAM_CLAMP);
        e->unit0->setTextureScale(1.0f / e->wrap0, 1.0f);
        e->groupCurves.push_back(groups[0]->alpha);
        e->groupUnits.push_back(e->unit0);
        for (size_t i = 1; i < groups.size(); ++i)
        {
            const Real wrap = groups[i]->wraps[def.id] > 0 ? groups[i]->wraps[def.id] : 1.0f;
            Ogre::TextureUnitState* unit = e->pass->createTextureUnitState(groups[i]->textures[def.id]);
            unit->setTextureFiltering(Ogre::TFO_BILINEAR);
            unit->setTextureAddressingMode(Ogre::TextureUnitState::TAM_WRAP, Ogre::TextureUnitState::TAM_CLAMP,
                                           Ogre::TextureUnitState::TAM_CLAMP);
            unit->setTextureScale(1.0f / wrap, 1.0f);
            e->groupCurves.push_back(groups[i]->alpha);
            e->groupUnits.push_back(unit);
        }
        // Final tint stage (fog layer: sky_fog colour).
        e->unit2 = e->pass->createTextureUnitState(groups[0]->textures[def.id]);
        e->unit2->setTextureFiltering(Ogre::TFO_BILINEAR);

        // Band between pitch_start and pitch_end (radians from the zenith), u around, v top -> bottom.
        Ogre::ManualObject* mo = mSceneManager->createManualObject(makeName("LayerObject"));
        const int slices = 64, stacks = 16;
        const Real p0 = def.pitchStart, p1 = def.pitchEnd > def.pitchStart ? def.pitchEnd : def.pitchStart + 0.01f;
        mo->estimateVertexCount((slices + 1) * (stacks + 1));
        mo->estimateIndexCount(slices * stacks * 6);
        mo->begin(e->materialName);
        for (int j = 0; j <= stacks; ++j)
        {
            const Real v = (Real)j / stacks;
            const Real pitch = p0 + (p1 - p0) * v;
            for (int i = 0; i <= slices; ++i)
            {
                const Real u = (Real)i / slices;
                const Real theta = Ogre::Math::TWO_PI * u;
                mo->position(std::sin(pitch) * std::cos(theta), std::cos(pitch), std::sin(pitch) * std::sin(theta));
                mo->textureCoord(u, v);
            }
        }
        for (int j = 0; j < stacks; ++j)
        {
            for (int i = 0; i < slices; ++i)
            {
                const Ogre::uint16 a = (Ogre::uint16)(j * (slices + 1) + i);
                const Ogre::uint16 b = (Ogre::uint16)(a + slices + 1);
                mo->triangle(a, b, (Ogre::uint16)(a + 1));
                mo->triangle((Ogre::uint16)(a + 1), b, (Ogre::uint16)(b + 1));
            }
        }
        mo->end();
        mo->setQueryFlags(0);
        e->object = mo;
        e->node->attachObject(mo);
        e->node->setScale(0.99f - 0.001f * kLayerOrder[def.id], 0.99f - 0.001f * kLayerOrder[def.id],
                          0.99f - 0.001f * kLayerOrder[def.id]);
    }
    //-----------------------------------------------------------------------
    void CYSSkyRenderer::buildSkySphereMoon(const CYSSkySphereData& data)
    {
        if (data.moon.dates.empty())
            return;
        // Lunar date: day of the month of the local clock (INF; the game may pass its own date).
        const time_t now = time(0);
        const tm* local = localtime(&now);
        const int day = local ? (local->tm_mday - 1) % 31 : 0;
        const CYSSkyMoonDate* date = &data.moon.dates[0];
        for (size_t i = 0; i < data.moon.dates.size(); ++i)
        {
            if (data.moon.dates[i].date == day)
            {
                date = &data.moon.dates[i];
                break;
            }
        }
        if (!textureExists(date->texture))
            return;
        Element* e = addElement(Element::SPHERE_MOON, -300.0f, "SkySphereMoon");
        e->curve0 = date->alpha;
        e->size = 0.08f;                    // INF
        e->hasFixedDirection = true;
        e->fixedDirection = data.moon.direction.normalisedCopy();
        createMaterial(e, date->texture, true, false);
        e->unit0->setTextureAddressingMode(Ogre::TextureUnitState::TAM_CLAMP);
        Ogre::BillboardSet* set = mSceneManager->createBillboardSet(makeName("SkySphereMoonSet"), 1);
        set->setMaterialName(e->materialName);
        set->setDefaultDimensions(e->size, e->size);
        set->createBillboard(e->fixedDirection * 0.95f);
        set->setCastShadows(false);
        set->setQueryFlags(0);
        e->object = set;
        e->node->attachObject(set);
    }

    //////////////////////////////////////////////////////////////////////////
    // Per frame
    //////////////////////////////////////////////////////////////////////////
    void CYSSkyRenderer::update(Real dt, const CYSEnvironment& env)
    {
        if (!mRoot || !mSystem)
            return;
        mTime += dt;
        Ogre::Camera* camera = mSystem->getCamera();
        if (!camera)
            return;
        Real radius = camera->getFarClipDistance();
        if (radius <= 0)
            radius = 100000.0f;
        radius *= 0.9f;
        mRoot->setPosition(camera->getDerivedPosition());
        mRoot->setScale(radius, radius, radius);

        for (size_t i = 0; i < mElements.size(); ++i)
            updateElement(mElements[i], dt, env, radius);
    }
    //-----------------------------------------------------------------------
    void CYSSkyRenderer::updateElement(Element* e, Real dt, const CYSEnvironment& env, Real radius)
    {
        const Real hours = env.timeOfDay;
        switch (e->kind)
        {
        case Element::DOME:
        {
            // En_sky_dome_p: colour table at u = time of day, times skydome ambient rgb * strength.
            e->unit0->setTextureScroll(hours / 24.0f, 0.0f);
            Ogre::ColourValue tint(env.skyDomeAmbient.x * env.skyDomeAmbient.w, env.skyDomeAmbient.y * env.skyDomeAmbient.w,
                                   env.skyDomeAmbient.z * env.skyDomeAmbient.w, 1.0f);
            if (env.source == CYSEnvironment::SOURCE_NONE)
                tint = Ogre::ColourValue::White;
            if (changed(tint, e->lastTint))
            {
                e->unit0->setColourOperationEx(Ogre::LBX_MODULATE, Ogre::LBS_TEXTURE, Ogre::LBS_MANUAL,
                                               Ogre::ColourValue::White, tint);
                e->lastTint = tint;
            }
            break;
        }
        case Element::CLOUD:
        case Element::RING:
        {
            const CYSEnTimeNode node = e->layer.sample(hours);
            const bool ring = e->kind == Element::RING;
            if (ring)
            {
                // INF speeds: rollspeed rotates the ring (texture u), verticalSpeed scrolls v.
                e->scrollU += node.rollSpeed * 0.002f * dt;
                e->scrollV += node.verticalSpeed * 0.01f * dt;
            }
            else
            {
                e->scrollV += node.cloudSpeed * 0.01f * dt;     // INF windSpeed scale
            }
            e->scrollU -= std::floor(e->scrollU);
            e->scrollV -= std::floor(e->scrollV);
            e->unit0->setTextureScroll(e->scrollU, e->scrollV);
            e->unit1->setTextureScroll(e->scrollU, e->scrollV);

            // En_cloudp / En_ringcloudp without the per-pixel terms: ambient blend, a mean sun scattering term,
            // then the fog blend (fog-amount texture unknown: 0.5 + control.x, INF), alpha = texture * alpha.
            Ogre::ColourValue tint = lerp(Ogre::ColourValue::White, env.ambient, saturate(node.ambientBlend));
            const Real scatter = e->layer.scatteringStrength * std::pow(0.5f, std::max(0.0f, e->layer.scatteringPower)) +
                0.5f * e->layer.rimStrength * std::pow(0.5f, std::max(0.0f, e->layer.rimPower));
            tint += env.sunColour * scatter;
            tint.a = 1.0f;
            const Real fogAmount = saturate(0.5f + (ring ? node.fogBlend : node.fog));
            const Real alpha = saturate(node.alpha);
            Ogre::ColourValue fog = env.fogColour;
            fog.a = 1.0f;
            if (changed(tint, e->lastTint) || changed(fog, e->lastFog) || std::fabs(fogAmount - e->lastFactor) > 1e-3f ||
                std::fabs(alpha - e->lastAlpha) > 1e-3f)
            {
                e->unit0->setColourOperationEx(Ogre::LBX_MODULATE, Ogre::LBS_TEXTURE, Ogre::LBS_MANUAL,
                                               Ogre::ColourValue::White, tint);
                if (ring)
                    e->unit0->setAlphaOperation(Ogre::LBX_MODULATE, Ogre::LBS_TEXTURE, Ogre::LBS_DIFFUSE);
                else
                    e->unit0->setAlphaOperation(Ogre::LBX_SOURCE1, Ogre::LBS_TEXTURE);
                // result = current * (1 - fogAmount) + fog * fogAmount
                e->unit1->setColourOperationEx(Ogre::LBX_BLEND_MANUAL, Ogre::LBS_CURRENT, Ogre::LBS_MANUAL,
                                               Ogre::ColourValue::White, fog, 1.0f - fogAmount);
                e->unit1->setAlphaOperation(Ogre::LBX_MODULATE, Ogre::LBS_CURRENT, Ogre::LBS_MANUAL, 1.0f, alpha);
                e->lastTint = tint;
                e->lastFog = fog;
                e->lastFactor = fogAmount;
                e->lastAlpha = alpha;
            }
            break;
        }
        case Element::SUN:
        case Element::SUN_FLARE:
        case Element::MOON:
        {
            const CYSEnCelestial& c = e->celestial;
            const bool sun = e->kind != Element::MOON;
            Ogre::Vector3 dir;
            bool visible = true;
            if (c.fixed)
            {
                dir = directionFromAngles(c.orient, c.angle);
            }
            else
            {
                // INF arc: rises at upTime, highest (angle) half way, sets at downTime, azimuth sweeps 180 deg.
                const Real p = arcProgress(hours, c.upTime, c.downTime);
                visible = p >= 0.0f && p <= 1.0f;
                const Real elevation = std::max(-5.0f, c.angle * std::sin(Ogre::Math::PI * saturate(p)));
                dir = directionFromAngles(c.orient + (saturate(p) - 0.5f) * 180.0f, elevation);
            }
            if (!sun)
            {
                dir = cyMoonDirection(c, hours);                // CYS-LOGIN: CY EnScene moon; always shown as CY
                visible = true;
            }
            e->node->setVisible(visible);
            Ogre::BillboardSet* set = static_cast<Ogre::BillboardSet*>(e->object);
            if (set && set->getNumBillboards() > 0)
                set->getBillboard(0)->setPosition(dir.normalisedCopy() * 0.95f);
            if (e->kind == Element::SUN_FLARE)
            {
                const Real a = e->intensity;
                if (std::fabs(a - e->lastAlpha) > 1e-3f)
                {
                    e->unit0->setAlphaOperation(Ogre::LBX_MODULATE, Ogre::LBS_TEXTURE, Ogre::LBS_MANUAL, 1.0f, a);
                    e->lastAlpha = a;
                }
            }
            break;
        }
        case Element::STARS:
        {
            Real night = 1.0f;
            if (!e->alwaysVisible)
            {
                const Real up = mHasSun ? mSun.upTime : 6.0f;
                const Real down = mHasSun ? mSun.downTime : 18.0f;
                night = 1.0f - daylight(hours, up, down);
            }
            e->node->setVisible(night > 0.01f);
            const Ogre::ColourValue c(night, night, night, night);
            if (changed(c, e->lastTint))
            {
                e->unit1->setColourOperationEx(Ogre::LBX_MODULATE, Ogre::LBS_CURRENT, Ogre::LBS_MANUAL,
                                               Ogre::ColourValue::White, c);
                e->lastTint = c;
            }
            break;
        }
        case Element::SPHERE_LAYER:
        {
            e->yaw += e->sphereLayer.rotateSpeed * dt;          // INF: radians per second
            e->node->setOrientation(Ogre::Quaternion(Ogre::Radian(e->yaw), Ogre::Vector3::UNIT_Y));
            const Real dayFraction = hours / 24.0f;
            // Weighted sum of the group textures: stage i blends texture i in by a_i / (a_0 + ... + a_i), which
            // leaves sum(a_i * texture_i) / sum(a_i) after the last stage; layer alpha = saturate(sum(a_i)).
            const size_t n = e->groupUnits.size();
            bool weightsChanged = e->lastWeights.size() != n;
            if (weightsChanged)
                e->lastWeights.assign(n, -1.0f);
            std::vector<Real> weights(n, 0.0f);
            Real sum = 0.0f;
            for (size_t i = 0; i < n; ++i)
            {
                const Real a = std::max(0.0f, e->groupCurves[i].sample(dayFraction));
                sum += a;
                weights[i] = (i > 0 && sum > 1e-4f) ? a / sum : 0.0f;
                if (std::fabs(weights[i] - e->lastWeights[i]) > 1e-3f)
                    weightsChanged = true;
            }
            const Real alpha = saturate(sum);
            Ogre::ColourValue tint = Ogre::ColourValue::White;
            if (e->sphereLayerId == CYS_SKY_FOG)
                tint = env.skyFogColour;
            tint.a = 1.0f;
            if (weightsChanged || changed(tint, e->lastTint) || std::fabs(alpha - e->lastAlpha) > 1e-3f)
            {
                e->unit0->setColourOperationEx(Ogre::LBX_SOURCE1, Ogre::LBS_TEXTURE);
                e->unit0->setAlphaOperation(Ogre::LBX_SOURCE1, Ogre::LBS_TEXTURE);
                for (size_t i = 1; i < n; ++i)
                {
                    // current = texture_i * w_i + current * (1 - w_i)
                    e->groupUnits[i]->setColourOperationEx(Ogre::LBX_BLEND_MANUAL, Ogre::LBS_TEXTURE, Ogre::LBS_CURRENT,
                                                           Ogre::ColourValue::White, Ogre::ColourValue::White,
                                                           weights[i]);
                    e->groupUnits[i]->setAlphaOperation(Ogre::LBX_BLEND_MANUAL, Ogre::LBS_TEXTURE, Ogre::LBS_CURRENT,
                                                        1.0f, 1.0f, weights[i]);
                }
                e->unit2->setColourOperationEx(Ogre::LBX_MODULATE, Ogre::LBS_CURRENT, Ogre::LBS_MANUAL,
                                               Ogre::ColourValue::White, tint);
                e->unit2->setAlphaOperation(Ogre::LBX_MODULATE, Ogre::LBS_CURRENT, Ogre::LBS_MANUAL, 1.0f, alpha);
                e->lastWeights = weights;
                e->lastTint = tint;
                e->lastAlpha = alpha;
            }
            break;
        }
        case Element::SPHERE_MOON:
        {
            const Real a = e->curve0.sample(hours / 24.0f);
            if (std::fabs(a - e->lastAlpha) > 1e-3f)
            {
                e->unit0->setAlphaOperation(Ogre::LBX_MODULATE, Ogre::LBS_TEXTURE, Ogre::LBS_MANUAL, 1.0f, a);
                e->lastAlpha = a;
            }
            e->node->setVisible(a > 0.01f);
            break;
        }
        default:
            break;
        }
        (void)radius;
    }
}
