// CY-Source (fix-projector): see CYSProjectorObject.h.
#include "CYSProjectorObject.h"
#include "CYSSceneObjects.h"
#include "CYSSceneCommon.h"

#include "Core/WXEnviromentObject.h"
#include "Core/WXObjectFactory.h"
#include "Core/WXProjector.h"
#include "Core/WXPropertyHelper.h"
#include "Core/WXSceneInfo.h"
#include "Core/WXSystem.h"

#include <OgreMaterialManager.h>
#include <OgreMath.h>
#include <OgrePass.h>
#include <OgreResourceGroupManager.h>
#include <OgreSceneManager.h>
#include <OgreSceneNode.h>
#include <OgreStringConverter.h>
#include <OgreTechnique.h>
#include <OgreTextureUnitState.h>

#include <cstdio>
#include <cstdlib>

namespace WX
{
    using namespace CYSScene;

    const String CYSProjectorObject::msType = "Projector";
    const String CYSProjectorObject::msCategory = "Projector";

    namespace
    {
        size_t gLiveProjectors = 0;
        unsigned gNameCounter = 0;

        inline CYSProjectorObject* self(void* p)
        {
            return static_cast<CYSProjectorObject*>(static_cast<Object*>(static_cast<PropertyInterface*>(p)));
        }
        inline const CYSProjectorObject* self(const void* p)
        {
            return static_cast<const CYSProjectorObject*>(
                static_cast<const Object*>(static_cast<const PropertyInterface*>(p)));
        }

        class CYSProjectorObjectFactory : public ObjectFactory
        {
        public:
            const String& getType(void) const { return CYSProjectorObject::msType; }
            Object* createInstance(void) { return new CYSProjectorObject; }
        };


        const Constant kBlendModes[] =
        {
            { "modulate", Ogre::SBT_MODULATE },
            { "colour_blend", Ogre::SBT_TRANSPARENT_COLOUR },
            { "alpha_blend", Ogre::SBT_TRANSPARENT_ALPHA },
            { "add", Ogre::SBT_ADD },
            { NULL, 0 },
        };

        /// Text-driven member command: unparsable text keeps the previous value (rule "log and skip", no throw).
        template <typename T, T CYSProjectorObject::*Member>
        struct MemberCmd : PropertyCommand
        {
            Variant doGet(const void* source) const { return self(source)->*Member; }
            String doGetAsString(const void* source) const { return toText(self(source)->*Member); }
            void doSet(void* target, const Variant& value)
            {
                const T* v = VariantCast<T>(&value);
                if (v)
                {
                    self(target)->*Member = *v;
                    self(target)->updateRenderInstance();
                }
                else
                {
                    const String* s = VariantCast<String>(&value);
                    if (s)
                        doSetAsString(target, *s);
                }
            }
            void doSetAsString(void* target, const String& value)
            {
                CYSProjectorObject* o = self(target);
                o->*Member = fromText(value, o->*Member);
                o->updateRenderInstance();
            }

            static String toText(Real v) { return Ogre::StringConverter::toString(v); }
            static String toText(int v) { return Ogre::StringConverter::toString(v); }
            static String toText(bool v) { return v ? "true" : "false"; }
            static String toText(const String& v) { return v; }
            static String toText(const Ogre::ColourValue& c)
            {
                char buf[96];
                sprintf(buf, "%g %g %g", c.r, c.g, c.b);
                return buf;
            }
            static Real fromText(const String& s, Real def) { return parseReal(s.c_str(), def); }
            static int fromText(const String& s, int def)
            {
                return static_cast<int>(parseReal(s.c_str(), static_cast<Real>(def)));
            }
            static bool fromText(const String& s, bool def) { return parseBool(s.c_str(), def); }
            static String fromText(const String& s, const String&) { return s; }
            static Ogre::ColourValue fromText(const String& s, const Ogre::ColourValue& def)
            {
                Ogre::ColourValue c = parseColour(s.c_str(), def);
                c.a = 1.0f;     // "ColourRGB"
                return c;
            }
        };

        typedef MemberCmd<String, &CYSProjectorObject::mTextureName> TextureNameCmd;
        typedef MemberCmd<Real, &CYSProjectorObject::mProjectorSize> SizeCmd;
        typedef MemberCmd<Real, &CYSProjectorObject::mUScale> UScaleCmd;
        typedef MemberCmd<Real, &CYSProjectorObject::mVScale> VScaleCmd;
        typedef MemberCmd<Ogre::ColourValue, &CYSProjectorObject::mColour> ColourCmd;
        typedef MemberCmd<bool, &CYSProjectorObject::mShowFrustum> ShowFrustumCmd;
        typedef MemberCmd<Real, &CYSProjectorObject::mNearClip> NearCmd;
        typedef MemberCmd<Real, &CYSProjectorObject::mFarClip> FarCmd;
        typedef MemberCmd<bool, &CYSProjectorObject::mUWave> UWaveCmd;
        typedef MemberCmd<bool, &CYSProjectorObject::mVWave> VWaveCmd;
        typedef MemberCmd<Real, &CYSProjectorObject::mWaveFrequency> WaveFrequencyCmd;
        typedef MemberCmd<Real, &CYSProjectorObject::mWaveAmplitude> WaveAmplitudeCmd;
        typedef MemberCmd<int, &CYSProjectorObject::mTerrainGridLimit> GridLimitCmd;
        typedef MemberCmd<int, &CYSProjectorObject::mVertexLimit> VertexLimitCmd;

        struct BlendModeCmd : PropertyCommand
        {
            Variant doGet(const void* source) const { return doGetAsString(source); }
            String doGetAsString(const void* source) const
            {
                String label;
                if (!mapEnumLabel(kBlendModes, self(source)->mBlendMode, label))
                    label = Ogre::StringConverter::toString(self(source)->mBlendMode);
                return label;
            }
            void doSet(void* target, const Variant& value)
            {
                const String* s = VariantCast<String>(&value);
                if (s)
                    doSetAsString(target, *s);
            }
            void doSetAsString(void* target, const String& value)
            {
                int mode;
                if (!mapEnumValue(kBlendModes, value, mode, false))
                {
                    // CY throws ERR_INVALIDPARAMS here; CY-Source logs and keeps the previous mode.
                    logOnce("projector blend " + value, "Projector: unknown blend mode '" + value + "' ignored");
                    return;
                }
                self(target)->mBlendMode = mode;
                self(target)->updateRenderInstance();
            }
        };

        bool resourceExistsAnyGroup(const String& name)
        {
            Ogre::ResourceGroupManager& rgm = Ogre::ResourceGroupManager::getSingleton();
            if (rgm.resourceExists(Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME, name))
                return true;
            const Ogre::StringVector groups = rgm.getResourceGroups();
            for (Ogre::StringVector::const_iterator g = groups.begin(); g != groups.end(); ++g)
            {
                if (rgm.resourceExists(*g, name))
                    return true;
            }
            return false;
        }
    }

    //////////////////////////////////////////////////////////////////////////
    CYSProjectorObject::CYSProjectorObject(void)
        : PlacementObject()
        , mProjector(NULL)
        , mProjectorNode(NULL)
        , mTextureName("BaseWhite")
        , mProjectorSize(200.0f)
        , mUScale(1.0f)
        , mVScale(1.0f)
        , mColour(Ogre::ColourValue::White)
        , mShowFrustum(true)
        , mNearClip(100.0f)
        , mFarClip(1000.0f)
        , mUWave(false)
        , mVWave(false)
        , mWaveFrequency(0.1f)
        , mWaveAmplitude(0.05f)
        , mBlendMode(Ogre::SBT_MODULATE)
        , mTerrainGridLimit(256)
        , mVertexLimit(4096)
    {
        if (createPropertyDictionary("Projector"))
        {
            static TextureNameCmd textureNameCmd;
            defineProperty("texture name", "The effect template name use to create this effect object.", "String",
                           &textureNameCmd, PF_PRIMARY);
            static SizeCmd sizeCmd;
            defineProperty("projector size", "Size of projector frustum", "Real", &sizeCmd, PF_PRIMARY);
            static UScaleCmd uScaleCmd;
            defineProperty("U Scale", "Scale along texture's U direction", "Real", &uScaleCmd, PF_PRIMARY);
            static VScaleCmd vScaleCmd;
            defineProperty("V Scale", "Scale along texture's V direction", "Real", &vScaleCmd, PF_PRIMARY);
            static ColourCmd colourCmd;
            defineProperty("projector colour", "use this colour to multiply with image's pixel colour", "ColourRGB",
                           &colourCmd, PF_PRIMARY);
            static ShowFrustumCmd showFrustumCmd;
            defineProperty("show frustum", "enable show frustum", "Bool", &showFrustumCmd, PF_PRIMARY);
            static NearCmd nearCmd;
            defineProperty("near clip distance", "near clip distance", "Real", &nearCmd, PF_PRIMARY);
            static FarCmd farCmd;
            defineProperty("far clip distance", "far clip distance", "Real", &farCmd, PF_PRIMARY);
            static UWaveCmd uWaveCmd;
            defineProperty("u wave", "enable texture wave along u direction", "Bool", &uWaveCmd, PF_PRIMARY);
            static VWaveCmd vWaveCmd;
            defineProperty("v wave", "enable texture wave along v direction", "Bool", &vWaveCmd, PF_PRIMARY);
            static WaveFrequencyCmd waveFrequencyCmd;
            defineProperty("wave frequency", "wave frequency", "Real", &waveFrequencyCmd, PF_PRIMARY);
            static WaveAmplitudeCmd waveAmplitudeCmd;
            defineProperty("wave amplitude", "wave amplitude", "Real", &waveAmplitudeCmd, PF_PRIMARY);
            static BlendModeCmd blendModeCmd;
            defineProperty("blend mode", "The projector blend mode", getEnumTypeString("BlendMode", kBlendModes),
                           &blendModeCmd, PF_PRIMARY);
            static GridLimitCmd gridLimitCmd;
            defineProperty("terrain grid limit", "limit of grid number", "Integer", &gridLimitCmd, PF_PRIMARY);
            static VertexLimitCmd vertexLimitCmd;
            defineProperty("vertex limit", "limit of max vertex number", "Integer", &vertexLimitCmd, PF_PRIMARY);

            addBaseProperty();      // position, orientation, scale, create level (as CY)
            const char* const stored[] = { "uuid", NULL };
            addStoredProperties(this, stored);
        }
    }
    //-----------------------------------------------------------------------
    CYSProjectorObject::~CYSProjectorObject()
    {
        destroyRenderInstance();
    }
    const String& CYSProjectorObject::getType(void) const { return msType; }
    const String& CYSProjectorObject::getCategory(void) const { return msCategory; }
    size_t CYSProjectorObject::getNumLiveProjectors(void) { return gLiveProjectors; }
    ObjectFactory* CYSProjectorObject::getFactory(void)
    {
        static CYSProjectorObjectFactory factory;
        return &factory;
    }
    //-----------------------------------------------------------------------
    void CYSProjectorObject::createRenderInstance(System* system)
    {
        PlacementObject::createRenderInstance(system);
        createProjector();
    }
    //-----------------------------------------------------------------------
    void CYSProjectorObject::destroyRenderInstance(void)
    {
        destroyProjector();
        PlacementObject::destroyRenderInstance();
    }
    //-----------------------------------------------------------------------
    void CYSProjectorObject::updateRenderInstance(void)
    {
        if (!mSceneNode)
            return;         // still loading: the render instance is built by createRenderInstance
        destroyProjector();
        createProjector();
    }
    //-----------------------------------------------------------------------
    bool CYSProjectorObject::resolveTexture(String& name) const
    {



        name = mTextureName;
        if (name.empty() || name == "BaseWhite")
            return false;
        if (resourceExistsAnyGroup(name))
            return true;
        if (mSystem && mSystem->isEditable())
            return false;
        if (name.find("dds") != String::npos)
            return false;
        String::size_type dot = name.rfind('.');
        if (dot == String::npos)
            return false;
        String ext = name.substr(dot + 1);
        Ogre::StringUtil::toLowerCase(ext);
        name.replace(dot, 4, ".dds");
        String::size_type slash = name.rfind('/');
        name.insert(slash == String::npos ? 0 : slash + 1, ext + "_");
        return resourceExistsAnyGroup(name);
    }
    //-----------------------------------------------------------------------
    void CYSProjectorObject::buildMaterial(const String& texture)
    {
        Ogre::MaterialManager& mm = Ogre::MaterialManager::getSingleton();
        String name;
        do
        {
            name = "ProjectorObjectMaterial" + Ogre::StringConverter::toString(++gNameCounter);
        } while (!mm.getByName(name).isNull());
        mMaterial = mm.create(name, Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);

        Ogre::Technique* technique = mMaterial->getTechnique(0);
        Ogre::Pass* pass = technique ? technique->getPass(0) : NULL;
        if (!pass)
            return;
        pass->removeAllTextureUnitStates();
        pass->setLightingEnabled(false);

        // CY: modulate / colour_blend decals fog towards white (neutral for those blends) with the scene fog range.
        if (mBlendMode == Ogre::SBT_MODULATE || mBlendMode == Ogre::SBT_TRANSPARENT_COLOUR)
        {
            SceneInfo* sceneInfo = mSystem ? mSystem->getSceneInfo() : NULL;
            if (sceneInfo)
            {
                Scene::ObjectsByTypeRange range = sceneInfo->findObjectsByType(EnviromentObject::msType);
                if (range.first != range.second)
                {
                    const EnviromentObject* env = static_cast<const EnviromentObject*>(range.first->get());
                    pass->setFog(true, env->mFogMode, Ogre::ColourValue::White, env->mFogExpDensity,
                                 env->mFogLinearStart, env->mFogLinearEnd);
                }
            }
        }
        pass->setDepthWriteEnabled(false);
        pass->setDepthBias(1);
        pass->setSceneBlending(static_cast<Ogre::SceneBlendType>(mBlendMode));

        Ogre::TextureUnitState* tus = pass->createTextureUnitState(texture, 0);
        tus->_load();
        if (tus->isBlank())
            logOnce("projector texture " + texture, "Projector: texture '" + texture + "' can not be found");
        tus->setTextureAddressingMode(Ogre::TextureUnitState::TAM_CLAMP);
        tus->setTextureScale(mUScale, mVScale);
        tus->setColourOperationEx(Ogre::LBX_MODULATE, Ogre::LBS_TEXTURE, Ogre::LBS_MANUAL,
                                  Ogre::ColourValue::White, mColour);
        if (mUWave || mVWave)
        {
            tus->setTransformAnimation(mUWave ? Ogre::TextureUnitState::TT_TRANSLATE_U
                                              : Ogre::TextureUnitState::TT_TRANSLATE_V,
                                       Ogre::WFT_SINE, 0.0f, mWaveFrequency, 0.0f, mWaveAmplitude);
        }
        mMaterial->compile();
    }
    //-----------------------------------------------------------------------
    void CYSProjectorObject::createProjector(void)
    {
        if (mProjector || !mSceneNode || !mSystem)
            return;
        // Diagnostic switch (A/B images): CYS_PROJECTOR=0 keeps scene projectors as data only.
        static const bool enabled = !(getenv("CYS_PROJECTOR") && getenv("CYS_PROJECTOR")[0] == '0');
        if (!enabled)
            return;
        if (!resolveTexture(mResolvedTexture))
        {
            if (!mTextureName.empty() && mTextureName != "BaseWhite")
                logOnce("projector missing " + mTextureName,
                        "Projector: texture '" + mTextureName + "' not found; projector not created (as CY)");
            return;
        }
        if (!(mNearClip > 0.0f))
        {
            // CY _getFovFromProjectionSize throws ERR_INVALIDPARAMS; CY-Source logs and skips the object.
            logOnce("projector near", "Projector: the near clip distance of projector must be larger than zero");
            return;
        }

        try
        {
            buildMaterial(mResolvedTexture);

            const String name = "FairyProjectorObject_" + Ogre::StringConverter::toString(++gNameCounter);
            mProjectorNode = mSceneNode->createChildSceneNode(name + "_SceneNode");
            mProjector = static_cast<Projector*>(
                mSystem->getSceneManager()->createMovableObject(name, ProjectorFactory::FACTORY_TYPE_NAME));
            ++gLiveProjectors;
            mProjector->setProjectionType(Ogre::PT_ORTHOGRAPHIC);
            mProjector->setTerrain(mSystem->getTerrain());
            mProjector->setAspectRatio(1.0f);
            mProjector->setShowFrustum(mShowFrustum);
            mProjector->setEnableClipPlanes(false);
            mProjector->setPatchMaterial(mMaterial->getName());
            mProjector->setCastShadows(false);
            mProjector->setNearClipDistance(mNearClip);
            mProjector->setFarClipDistance(mFarClip);


            mProjector->setFOVy(Ogre::Math::ATan(mProjectorSize / (mNearClip * 2.0f)) * 2.0f);
            mProjector->setTerrainGridLimit(mTerrainGridLimit > 0 ? mTerrainGridLimit : 1);
            mProjector->setVertexLimit(static_cast<size_t>(mVertexLimit > 0 ? mVertexLimit : 0));
            mProjectorNode->attachObject(mProjector);
            mProjectorNode->setDirection(Ogre::Vector3::NEGATIVE_UNIT_Y, Ogre::Node::TS_PARENT,
                                         Ogre::Vector3::NEGATIVE_UNIT_Z);
        }
        catch (Ogre::Exception& e)
        {
            log("Projector '" + mTextureName + "' not created: " + e.getDescription());
            destroyProjector();
        }
    }
    //-----------------------------------------------------------------------
    void CYSProjectorObject::destroyProjector(void)
    {
        if (mProjector)
        {
            if (mProjectorNode)
                mProjectorNode->detachObject(mProjector);
            mProjector->destroy();
            mProjector = NULL;
            --gLiveProjectors;
        }
        if (mProjectorNode)
        {
            mProjectorNode->destroy();
            mProjectorNode = NULL;
        }
        if (!mMaterial.isNull())
        {
            Ogre::MaterialManager::getSingleton().remove(mMaterial->getHandle());
            mMaterial.setNull();
        }
    }
}
