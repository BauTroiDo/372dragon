// CY-Source (scene agent): see CYSSceneObjects.h.
#include "CYSSceneObjects.h"
#include "CYSSceneCommon.h"
#include "CYSProjectorObject.h"    // CYS-FIX fix-projector

#include "Core/WXObjectFactory.h"
#include "Core/WXObjectFactoryManager.h"
#include "Core/WXPropertyHelper.h"
#include "Core/WXSystem.h"

#include <OgreSceneManager.h>
#include <OgreSceneNode.h>
#include <OgreLight.h>
#include <OgreStringConverter.h>
#include <OgreEntity.h>             // CYS-PARITY: FakeLight volumes
#include <OgreManualObject.h>
#include <OgreMaterialManager.h>
#include <OgreMeshManager.h>
#include <OgreTechnique.h>
#include <OgrePass.h>
#include <OgreGpuProgram.h>
#include <OgreLogManager.h>
#include <OgreRenderQueue.h>
#include <OgreResourceGroupManager.h>
#include <cstring>
#include "CYS/Water/CysWaterRender.h"   // CYS-PARITY: FakeLight boxes need the scene depth node
#include "CYS/PostFX/CysPostFxPipeline.h"   // CYS-PARITY (L2): INTZ scene depth

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <set>

namespace WX
{
    using namespace CYSScene;

    const String CYSScene::GROUP_PROPERTY = "#group";

    namespace
    {
        struct FakeLightState
        {
            bool enabled;
            Real globalIntensity;
            std::set<CYSFakeLightObject*> live;

            FakeLightState(void) : enabled(true), globalIntensity(1.0f)
            {
                const char* env = getenv("CYS_FAKELIGHT");
                if (env && env[0] == '0')
                    enabled = false;
            }
        };

        FakeLightState& fakeLights(void)
        {
            static FakeLightState state;
            return state;
        }

        // CYS-PARITY: FakeLight light boxes as CY 3.71 draws them (Docs/specs/render/d3d9-parity_vi.md, L4).
        const char* const kFakeLightMaterial = "Mtl_FakePointLight";   // MaterialTemplates Mtl_Character.material
        const char* const kFakeLightMesh = "CYS/FakeLightBox";

        bool fakeLightVolumes(void)
        {
            static const bool on = []() {
                const char* v = getenv("CYS_FAKELIGHT_MODE");
                return !(v && strcmp(v, "light") == 0);
            }();
            return on;
        }

        void fakeLightLog(const String& message)
        {
            static std::set<String> once;
            if (once.insert(message).second && Ogre::LogManager::getSingletonPtr())
                Ogre::LogManager::getSingleton().logMessage("CYS parity: fake light: " + message);
        }

        /// Unit light box, half extent 50 (Model_FakePointLight_ps clips |0.01 * objectPos| > 0.5), triangles
        /// counter-clockwise seen from outside: the material culls those, so the inner faces draw and the light
        /// stays visible with the camera inside the box.
        bool ensureFakeLightMesh(Ogre::SceneManager* sm)
        {
            if (!Ogre::MeshManager::getSingleton().getByName(kFakeLightMesh).isNull())
                return true;
            static const int tri[12][3] = { { 1, 3, 7 }, { 1, 7, 5 }, { 0, 6, 2 }, { 0, 4, 6 }, { 2, 7, 3 }, { 2, 6, 7 },
                                            { 0, 1, 5 }, { 0, 5, 4 }, { 4, 5, 7 }, { 4, 7, 6 }, { 0, 3, 1 }, { 0, 2, 3 } };
            Ogre::ManualObject* mo = 0;
            try
            {
                mo = sm->createManualObject("CYS/FakeLightBoxBuilder");
                mo->begin("BaseWhiteNoLighting", Ogre::RenderOperation::OT_TRIANGLE_LIST);
                for (int i = 0; i < 8; ++i)
                    mo->position((i & 1) ? 50.0f : -50.0f, (i & 2) ? 50.0f : -50.0f, (i & 4) ? 50.0f : -50.0f);
                for (int t = 0; t < 12; ++t)
                    mo->triangle(tri[t][0], tri[t][1], tri[t][2]);
                mo->end();
                mo->convertToMesh(kFakeLightMesh, Ogre::ResourceGroupManager::INTERNAL_RESOURCE_GROUP_NAME);
            }
            catch (Ogre::Exception& e)
            {
                fakeLightLog("box mesh failed: " + e.getDescription());
            }
            if (mo)
                sm->destroyManualObject(mo);
            return !Ogre::MeshManager::getSingleton().getByName(kFakeLightMesh).isNull();
        }

        /// One command per stored property name; kept until exit like the static commands of 0.85.
        CYSStoredPropertyCommand* storedCommand(const String& name)
        {
            static std::map<String, CYSStoredPropertyCommand*> commands;
            std::map<String, CYSStoredPropertyCommand*>::iterator it = commands.find(name);
            if (it != commands.end())
                return it->second;
            CYSStoredPropertyCommand* cmd = new CYSStoredPropertyCommand(name);
            commands[name] = cmd;
            return cmd;
        }

        inline const Object* asObject(const void* p)
        {
            return static_cast<const Object*>(static_cast<const PropertyInterface*>(p));
        }

        inline Object* asObject(void* p)
        {
            return static_cast<Object*>(static_cast<PropertyInterface*>(p));
        }

        const char* const kStoredUuid[] = { "uuid", NULL };
    }

    //////////////////////////////////////////////////////////////////////////
    // CYSStoredPropertyCommand
    //////////////////////////////////////////////////////////////////////////
    Variant CYSStoredPropertyCommand::doGet(const void* source) const
    {
        return Variant();
    }
    //-----------------------------------------------------------------------
    void CYSStoredPropertyCommand::doSet(void* target, const Variant& value)
    {
        const String* text = VariantCast<String>(&value);
        if (text)
            asObject(target)->setCYSExtraProperty(mName, *text);
    }
    //-----------------------------------------------------------------------
    String CYSStoredPropertyCommand::doGetAsString(const void* source) const
    {
        const String* v = asObject(source)->getCYSExtraProperty(mName);
        return v ? *v : String();
    }
    //-----------------------------------------------------------------------
    void CYSStoredPropertyCommand::doSetAsString(void* target, const String& value)
    {
        asObject(target)->setCYSExtraProperty(mName, value);
    }

    //////////////////////////////////////////////////////////////////////////
    // CYSEnSceneObject
    //////////////////////////////////////////////////////////////////////////
    const String CYSEnSceneObject::msType = "EnScene";
    const String CYSEnSceneObject::msCategory = "Enviroment";

    namespace
    {
        class EnSceneFactory : public ObjectFactory
        {
        public:
            const String& getType(void) const { return CYSEnSceneObject::msType; }
            Object* createInstance(void) { return new CYSEnSceneObject; }
        };

        typedef ObjectMemberPropertyCommand<CYSEnSceneObject, String, &CYSEnSceneObject::mConfigFile> EnSceneConfigFileCmd;
        typedef ObjectMemberPropertyCommand<CYSEnSceneObject, bool, &CYSEnSceneObject::mEnabled> EnSceneEnabledCmd;
    }
    //-----------------------------------------------------------------------
    CYSEnSceneObject::CYSEnSceneObject(void)
        : Object()
        , mConfigFile()
        , mEnabled(false)
    {
        if (createPropertyDictionary("EnScene"))
        {
            static EnSceneConfigFileCmd configFileCmd;
            defineProperty("config_file", "The .EnScene environment file of the scene.", "String", &configFileCmd, 0);
            static EnSceneEnabledCmd enabledCmd;
            defineProperty("enabled", "Set when the .EnScene file was loaded (as B SceneInfo::load).", "Bool",
                           &enabledCmd, 0);
            addStoredProperties(this, kStoredUuid);
        }
    }
    CYSEnSceneObject::~CYSEnSceneObject() {}
    const String& CYSEnSceneObject::getType(void) const { return msType; }
    const String& CYSEnSceneObject::getCategory(void) const { return msCategory; }
    ObjectFactory* CYSEnSceneObject::getFactory(void)
    {
        static EnSceneFactory factory;
        return &factory;
    }

    //////////////////////////////////////////////////////////////////////////
    // CYSSkySphereObject
    //////////////////////////////////////////////////////////////////////////
    const String CYSSkySphereObject::msType = "SkySphere";
    const String CYSSkySphereObject::msCategory = "Enviroment";

    namespace
    {
        class SkySphereFactory : public ObjectFactory
        {
        public:
            const String& getType(void) const { return CYSSkySphereObject::msType; }
            Object* createInstance(void) { return new CYSSkySphereObject; }
        };

        typedef ObjectMemberPropertyCommand<CYSSkySphereObject, bool, &CYSSkySphereObject::mEnabled> SkySphereEnabledCmd;
    }
    //-----------------------------------------------------------------------
    CYSSkySphereObject::CYSSkySphereObject(void)
        : Object()
        , mEnabled(false)
    {
        if (createPropertyDictionary("SkySphere"))
        {
            static SkySphereEnabledCmd enabledCmd;
            defineProperty("enabled", "Set when the .skysphere file was loaded (as B SceneInfo::load).", "Bool",
                           &enabledCmd, 0);
            addStoredProperties(this, kStoredUuid);
        }
    }
    CYSSkySphereObject::~CYSSkySphereObject() {}
    const String& CYSSkySphereObject::getType(void) const { return msType; }
    const String& CYSSkySphereObject::getCategory(void) const { return msCategory; }
    ObjectFactory* CYSSkySphereObject::getFactory(void)
    {
        static SkySphereFactory factory;
        return &factory;
    }

    //////////////////////////////////////////////////////////////////////////
    // CYSFakeLightObject
    //////////////////////////////////////////////////////////////////////////
    const String CYSFakeLightObject::msType = "FakeLight";
    const String CYSFakeLightObject::msCategory = "FakeLight";

    namespace
    {
        class FakeLightFactory : public ObjectFactory
        {
        public:
            const String& getType(void) const { return CYSFakeLightObject::msType; }
            Object* createInstance(void) { return new CYSFakeLightObject; }
        };

        typedef ObjectMemberPropertyCommand<CYSFakeLightObject, Real, &CYSFakeLightObject::mSize> FakeLightSizeCmd;
        typedef ObjectMemberPropertyCommand<CYSFakeLightObject, Real, &CYSFakeLightObject::mIntensity> FakeLightIntensityCmd;
        typedef ObjectMemberPropertyCommand<CYSFakeLightObject, Real, &CYSFakeLightObject::mBeginBrightness> FakeLightBeginCmd;
        typedef ObjectMemberPropertyCommand<CYSFakeLightObject, Real, &CYSFakeLightObject::mEndBrightness> FakeLightEndCmd;

        /// "r g b a" (the data always writes four components).
        struct FakeLightDiffuseCmd : PropertyCommand
        {
            Variant doGet(const void* source) const
            {
                return static_cast<const CYSFakeLightObject*>(asObject(source))->mDiffuse;
            }
            String doGetAsString(const void* source) const
            {
                const Ogre::ColourValue& c = static_cast<const CYSFakeLightObject*>(asObject(source))->mDiffuse;
                char buf[128];
                sprintf(buf, "%g %g %g %g", c.r, c.g, c.b, c.a);
                return buf;
            }
            void doSet(void* target, const Variant& value)
            {
                CYSFakeLightObject* o = static_cast<CYSFakeLightObject*>(asObject(target));
                o->mDiffuse = VariantCast<Ogre::ColourValue>(value);
                o->updateRenderInstance();
            }
            void doSetAsString(void* target, const String& value)
            {
                CYSFakeLightObject* o = static_cast<CYSFakeLightObject*>(asObject(target));
                o->mDiffuse = parseColour(value.c_str(), Ogre::ColourValue::White);
                o->updateRenderInstance();
            }
        };
    }
    //-----------------------------------------------------------------------
    CYSFakeLightObject::CYSFakeLightObject(void)
        : PlacementObject()
        , mLight(NULL)
        , mVolume(NULL)
        , mSize(1.5f)
        , mDiffuse(Ogre::ColourValue::White)
        , mIntensity(1.0f)
        , mBeginBrightness(0.0f)
        , mEndBrightness(1.0f)
    {
        if (createPropertyDictionary("FakeLight"))
        {
            addBaseProperty();
            static FakeLightSizeCmd sizeCmd;
            defineProperty("size", "Falloff sharpness of the light box (lightParams.w of Model_FakePointLight_ps).",
                           "Real", &sizeCmd, 0);
            static FakeLightDiffuseCmd diffuseCmd;
            defineProperty("diffuse", "Colour of the fake light.", "ColourRGBA", &diffuseCmd, 0);
            static FakeLightIntensityCmd intensityCmd;
            defineProperty("intensity", "Colour multiplier.", "Real", &intensityCmd, 0);
            static FakeLightBeginCmd beginCmd;
            defineProperty("begin brightness", "B/C parameter kept as data (meaning not yet known).", "Real",
                           &beginCmd, 0);
            static FakeLightEndCmd endCmd;
            defineProperty("end brightness", "B/C parameter kept as data (meaning not yet known).", "Real",
                           &endCmd, 0);
            addStoredProperties(this, kStoredUuid);
        }
    }
    //-----------------------------------------------------------------------
    CYSFakeLightObject::~CYSFakeLightObject()
    {
        destroyRenderInstance();
    }
    const String& CYSFakeLightObject::getType(void) const { return msType; }
    const String& CYSFakeLightObject::getCategory(void) const { return msCategory; }
    ObjectFactory* CYSFakeLightObject::getFactory(void)
    {
        static FakeLightFactory factory;
        return &factory;
    }
    //-----------------------------------------------------------------------
    void CYSFakeLightObject::createRenderInstance(System* system)
    {
        PlacementObject::createRenderInstance(system);
        fakeLights().live.insert(this);
        applyLight();
    }
    //-----------------------------------------------------------------------
    void CYSFakeLightObject::destroyRenderInstance(void)
    {
        fakeLights().live.erase(this);
        if (mLight)
        {
            mLight->destroy();
            mLight = NULL;
        }
        destroyVolume();
        PlacementObject::destroyRenderInstance();
    }
    //-----------------------------------------------------------------------
    void CYSFakeLightObject::updateRenderInstance(void)
    {
        applyLight();
    }
    //-----------------------------------------------------------------------
    Real CYSFakeLightObject::getRadius(void) const
    {
        const Ogre::Vector3& s = mTransform.scale;
        Real m = std::max(std::fabs(s.x), std::max(std::fabs(s.y), std::fabs(s.z)));
        return 50.0f * (m > 0 ? m : 1.0f);
    }
    //-----------------------------------------------------------------------
    void CYSFakeLightObject::applyLight(void)
    {
        if (!mSceneNode || !mSystem)
            return;
        FakeLightState& state = fakeLights();
        if (!state.enabled)
        {
            if (mLight)
            {
                mLight->destroy();
                mLight = NULL;
            }
            destroyVolume();
            return;
        }
        if (fakeLightVolumes() && applyVolume(getColour()))
        {
            if (mLight)
            {
                mLight->destroy();
                mLight = NULL;
            }
            return;
        }
        if (!mLight)
        {
            mLight = mSceneNode->getCreator()->createLight(mSceneNode->getName() + "/CYSFakeLight");
            mLight->setType(Ogre::Light::LT_POINT);
            mLight->setCastShadows(false);
            mSceneNode->attachObject(mLight);
        }
        Ogre::ColourValue c = getColour() * state.globalIntensity;
        c.a = 1.0f;
        mLight->setDiffuseColour(c);
        mLight->setSpecularColour(Ogre::ColourValue::Black);
        const Real r = getRadius();
        // Reaches about 1/9 at the edge of the B light box; OGRE cuts the light at `range`.
        mLight->setAttenuation(r, 1.0f, 0.0f, 8.0f / (r * r));
    }

    //-----------------------------------------------------------------------
    bool CYSFakeLightObject::applyVolume(const Ogre::ColourValue& colour)
    {
        // Writes lightParams / globalIntensity into the light's own material. They must be in place BEFORE the entity
        // takes the material: the material system derives its per-entity variant from the material at that moment
        // (trace proj-login-5..7: constants written afterwards reached lightParams only, globalIntensity kept another
        // shader's register value and the boxes stayed black).
        auto writeParams = [this, &colour](const Ogre::MaterialPtr& m) -> bool
        {
            if (m.isNull() || !m->getNumTechniques() || !m->getTechnique(0)->getNumPasses())
                return false;
            Ogre::Pass* pass = m->getTechnique(0)->getPass(0);
            if (!pass->hasFragmentProgram())
                return false;
            Ogre::GpuProgramParametersSharedPtr fp = pass->getFragmentProgramParameters();
            if (!fp.isNull() && !fp->hasNamedConstant("globalIntensity"))
            {
                // parameters created from the program defaults before its constant table was read: rebuild them
                // from the loaded program (default_params re-adds the auto constants)
                pass->setFragmentProgram(pass->getFragmentProgramName(), true);
                fp = pass->getFragmentProgramParameters();
            }
            if (fp.isNull())
                return false;
            // FACT (trace): lightParams = (diffuse x intensity, size); globalIntensity = EnvKey fake light intensity (1)
            if (fp->hasNamedConstant("lightParams"))
                fp->setNamedConstant("lightParams", Ogre::Vector4(colour.r, colour.g, colour.b, mSize));
            if (fp->hasNamedConstant("globalIntensity"))
                fp->setNamedConstant("globalIntensity", fakeLights().globalIntensity);
            else
                fakeLightLog("globalIntensity not declared by " + pass->getFragmentProgramName() + ": boxes stay dark");
            return true;
        };

        Ogre::SceneManager* sm = mSceneNode->getCreator();
        if (mVolume)
        {
            // colour / size / global intensity change: the source material is followed by the material system
            return writeParams(Ogre::MaterialManager::getSingleton().getByName(mVolumeMaterial));
        }
        Ogre::MaterialPtr base = Ogre::MaterialManager::getSingleton().getByName(kFakeLightMaterial);
        // CYS-PARITY (L2): CY draws the boxes with Mtl_FakePointLight_DSIntZ (PS 1e1f4ac9) on the INTZ scene depth
        if (CysPostFxPipeline::intzSceneDepth())
        {
            Ogre::MaterialPtr intz = Ogre::MaterialManager::getSingleton().getByName(String(kFakeLightMaterial) + "_DSIntZ");
            if (!intz.isNull())
                base = intz;
        }
        if (base.isNull())
        {
            fakeLightLog(String(kFakeLightMaterial) + " not found: OGRE point-light approximation");
            return false;
        }
        if (!ensureFakeLightMesh(sm))
            return false;
        try
        {
            mVolumeMaterial = "CYS/FakeLight/" + mSceneNode->getName();
            Ogre::MaterialPtr mat = Ogre::MaterialManager::getSingleton().getByName(mVolumeMaterial);
            if (mat.isNull())
                mat = base->clone(mVolumeMaterial);
            mat->load();
            if (!mat->getNumSupportedTechniques() || !writeParams(mat))
            {
                fakeLightLog(String(kFakeLightMaterial) + " is not usable: OGRE point-light approximation");
                Ogre::MaterialManager::getSingleton().remove(mat->getHandle());
                mVolumeMaterial.clear();
                return false;
            }
            mVolume = sm->createEntity(mSceneNode->getName() + "/CYSFakeLightVolume", kFakeLightMesh);
            mVolume->setMaterialName(mVolumeMaterial);
            mVolume->setCastShadows(false);
            mVolume->setQueryFlags(0);
            mVolume->setRenderQueueGroup(Ogre::RENDER_QUEUE_MAIN); // CY: among the transparents, after the sky
            mSceneNode->attachObject(mVolume);
            if (CysWaterRender* water = CysWaterRender::getSingletonPtr())
                water->addDepthUser();
            else
                fakeLightLog("no water renderer: the light boxes read the placeholder depth (no light)");
            fakeLightLog("light boxes (Mtl_FakePointLight) instead of OGRE point lights");
        }
        catch (Ogre::Exception& e)
        {
            fakeLightLog("volume failed: " + e.getDescription());
            destroyVolume();
            return false;
        }
        return true;
    }
    //-----------------------------------------------------------------------
    void CYSFakeLightObject::destroyVolume(void)
    {
        if (mVolume)
        {
            if (mVolume->getParentSceneNode())
                mVolume->getParentSceneNode()->detachObject(mVolume);
            mVolume->_getManager()->destroyEntity(mVolume);
            mVolume = NULL;
            if (CysWaterRender* water = CysWaterRender::getSingletonPtr())
                water->removeDepthUser();
        }
        if (!mVolumeMaterial.empty() && Ogre::MaterialManager::getSingletonPtr())
            Ogre::MaterialManager::getSingleton().remove(mVolumeMaterial);
        mVolumeMaterial.clear();
    }

    //////////////////////////////////////////////////////////////////////////
    // CYSPropertyBagObject
    //////////////////////////////////////////////////////////////////////////
    CYSPropertyBagObject::CYSPropertyBagObject(const String& type, const String& category,
                                               const char* const* propertyNames)
        : Object()
        , mType(type)
        , mCategory(category)
    {
        if (createPropertyDictionary("CYS:" + type))
        {
            if (propertyNames)
                addStoredProperties(this, propertyNames);
            addStoredProperties(this, kStoredUuid);
        }
    }
    CYSPropertyBagObject::~CYSPropertyBagObject() {}
    //-----------------------------------------------------------------------
    String CYSPropertyBagObject::getString(const String& name, const String& def) const
    {
        const String* v = getCYSExtraProperty(name);
        return v ? *v : def;
    }
    //-----------------------------------------------------------------------
    Real CYSPropertyBagObject::getReal(const String& name, Real def) const
    {
        const String* v = getCYSExtraProperty(name);
        return v ? parseReal(v->c_str(), def) : def;
    }
    //-----------------------------------------------------------------------
    bool CYSPropertyBagObject::getBool(const String& name, bool def) const
    {
        const String* v = getCYSExtraProperty(name);
        return v ? parseBool(v->c_str(), def) : def;
    }

    //////////////////////////////////////////////////////////////////////////
    // Registration
    //////////////////////////////////////////////////////////////////////////
    namespace
    {
        class BagFactory : public ObjectFactory
        {
        public:
            BagFactory(const String& type, const String& category, const char* const* names)
                : mType(type), mCategory(category), mNames(names)
            {
            }
            const String& getType(void) const { return mType; }
            Object* createInstance(void) { return new CYSPropertyBagObject(mType, mCategory, mNames); }

        private:
            String mType;
            String mCategory;
            const char* const* mNames;
        };

        const char* const kSceneConfigProps[] = { "SetCamDisCullDepth", "SetCamDisCullParam", "EnableCamDisCull", NULL };
        const char* const kHierarchyProps[] =
        {
            "attached objects", "child hierarchy nodes", "parent", "position", "orientation", "scale", NULL
        };
        // CYS-FIX fix-projector 15/09: "Projector" is no longer a property bag (its stored "create level" returned an
        // empty Variant -> SceneInfo::initialise bad_any_cast); it is CYSProjectorObject (CY Fairy::ProjectorObject).

        const char* const kStoredLight[] = { "uuid", "end brightness", "attenuation", NULL };
        // CY 3.71 (CanonicalCY) additions, kept verbatim and not applied (ci-cy 14/09/2026):
        //   StaticEntity "index" (editor ordinal, 851 uses), "Distance Cull", "HeightMapEnable", "Buildcollision"
        //   (Scene2Folder, 56 uses, always false); Model "UseHighLight"; ParticleSystem "active",
        //   "beginSceneBrightness", "endSceneBrightness".
        const char* const kStoredStaticEntity[] =
        {
            "uuid", "lockHeight", "Final transparency", "transparency switch", "HeightMapDouble", "index",
            "Distance Cull", "HeightMapEnable", "Buildcollision", NULL
        };
        const char* const kStoredModel[] =
        {
            "uuid", "lockHeight", "Final transparency", "transparency switch", "transparency", "receive shadows",
            "UseHighLight", NULL
        };
        const char* const kStoredPlaced[] = { "uuid", "lockHeight", NULL };
        const char* const kStoredParticle[] =
        {
            "uuid", "lockHeight", "active", "beginSceneBrightness", "endSceneBrightness", NULL
        };
        const char* const kStoredActor[] = { "uuid", "lockHeight", "actor cull", NULL };

        struct StoredSet
        {
            const char* type;
            const char* const* names;
        };

        const StoredSet kStoredSets[] =
        {
            { "Enviroment", kStoredUuid },
            { "Light", kStoredLight },
            { "StaticEntity", kStoredStaticEntity },
            { "Model", kStoredModel },
            { "ParticleSystem", kStoredParticle },
            { "Effect", kStoredPlaced },
            { "Actor", kStoredActor },
            { "LogicModel", kStoredPlaced },
            { "TerrainLiquid", kStoredUuid },
            { "SkyDome", kStoredUuid },
            { "SkyBox", kStoredUuid },
            { "SkyPlane", kStoredUuid },
        };
    }
    //-----------------------------------------------------------------------
    size_t CYSScene::addStoredProperties(PropertyInterface* instance, const char* const* names)
    {
        if (!instance || !names)
            return 0;
        PropertyDictionary* dict = instance->getPropertyDictionary();
        if (!dict)
            return 0;
        size_t added = 0;
        for (; *names; ++names)
        {
            bool exists = false;
            const PropertyList& defs = dict->getProperties();
            for (PropertyList::const_iterator it = defs.begin(); it != defs.end(); ++it)
            {
                if (it->name == *names)
                {
                    exists = true;
                    break;
                }
            }
            if (exists)
                continue;
            dict->addProperty(PropertyDef(*names, "B/C scene property kept verbatim (CY-Source).", "String", String(), 0),
                              storedCommand(*names));
            ++added;
        }
        return added;
    }
    //-----------------------------------------------------------------------
    void CYSScene::registerSceneObjectTypes(ObjectFactoryManager* manager)
    {
        if (!manager)
            return;

        static BagFactory sceneConfigFactory("SceneConfig", "Enviroment", kSceneConfigProps);
        static BagFactory hierarchyFactory("HierarchyNode", "HierarchyNode", kHierarchyProps);

        ObjectFactory* factories[] =
        {
            CYSEnSceneObject::getFactory(),
            CYSSkySphereObject::getFactory(),
            CYSFakeLightObject::getFactory(),
            &sceneConfigFactory,
            &hierarchyFactory,
            CYSProjectorObject::getFactory(),     // CYS-FIX fix-projector
        };
        for (size_t i = 0; i < sizeof(factories) / sizeof(factories[0]); ++i)
        {
            if (!manager->hasFactory(factories[i]->getType()))
                manager->registerFactory(factories[i]);
        }

        for (size_t i = 0; i < sizeof(kStoredSets) / sizeof(kStoredSets[0]); ++i)
        {
            if (!manager->hasFactory(kStoredSets[i].type))
                continue;
            try
            {
                ObjectPtr probe = manager->createInstance(kStoredSets[i].type);
                addStoredProperties(probe.get(), kStoredSets[i].names);
            }
            catch (...)
            {
                log(String("cannot extend the property dictionary of '") + kStoredSets[i].type + "'");
            }
        }
    }
    //-----------------------------------------------------------------------
    ObjectPtr CYSScene::createGenericObject(const String& type)
    {
        return ObjectPtr(new CYSPropertyBagObject(type, "Unknown", NULL));
    }
    //-----------------------------------------------------------------------
    void CYSScene::onUnknownProperty(Object& object, const String& name, const String& value, const String& file)
    {
        object.setCYSExtraProperty(name, value);
        CYSSceneStats::instance().unknown("Scene property " + object.getType() + "." + name, file);
    }
    //-----------------------------------------------------------------------
    void CYSScene::setFakeLightsEnabled(bool enabled)
    {
        FakeLightState& state = fakeLights();
        if (state.enabled == enabled)
            return;
        state.enabled = enabled;
        std::set<CYSFakeLightObject*> copy(state.live);
        for (std::set<CYSFakeLightObject*>::iterator it = copy.begin(); it != copy.end(); ++it)
            (*it)->applyLight();
    }
    //-----------------------------------------------------------------------
    bool CYSScene::getFakeLightsEnabled(void)
    {
        return fakeLights().enabled;
    }
    //-----------------------------------------------------------------------
    void CYSScene::setFakeLightGlobalIntensity(Real intensity)
    {
        FakeLightState& state = fakeLights();
        if (std::fabs(state.globalIntensity - intensity) < 1e-4f)
            return;
        state.globalIntensity = intensity;
        std::set<CYSFakeLightObject*> copy(state.live);
        for (std::set<CYSFakeLightObject*>::iterator it = copy.begin(); it != copy.end(); ++it)
            (*it)->applyLight();
    }
    //-----------------------------------------------------------------------
    Real CYSScene::getFakeLightGlobalIntensity(void)
    {
        return fakeLights().globalIntensity;
    }
    //-----------------------------------------------------------------------
    size_t CYSScene::getNumLiveFakeLights(void)
    {
        return fakeLights().live.size();
    }
}
