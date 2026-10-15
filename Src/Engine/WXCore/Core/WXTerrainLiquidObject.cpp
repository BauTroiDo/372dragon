#include "WXTerrainLiquidObject.h"
#include "WXTerrainLiquid.h"
#include "WXPropertyHelper.h"
#include "WXObjectFactory.h"
#include "WXSystem.h"
#include "WXSceneInfo.h"

#include <OgreSceneNode.h>
#include <OgreStringConverter.h>
#include <OgreRenderTexture.h>
#include <OgreMaterialManager.h>
#include <OgreRoot.h>
#include <OgreRenderSystem.h>
#include <OgreCamera.h>
#include <OgrePlane.h>
#include <OgreLogManager.h>
#include <OgreEntity.h>             // CYS
#include <OgreSceneManager.h>       // CYS

#include "CYS/Scene/CYSSceneCommon.h"   // CYS

#if ((OGRE_VERSION_MAJOR << 16) | (OGRE_VERSION_MINOR << 8) | OGRE_VERSION_PATCH) >= 0x010100
#include <OgreTextureManager.h>
#include <OgreHardwarePixelBuffer.h>
#endif

namespace WX {

    void ReflectRenderTargetListener::preRenderTargetUpdate(const Ogre::RenderTargetEvent& evt)
    {
        assert (mTerrainLiquid);
        mTerrainLiquid->setVisible(false);

        mCamera->enableReflection(*mPlane);
        mCamera->enableCustomNearClipPlane(*mPlane);
    }

    void ReflectRenderTargetListener::postRenderTargetUpdate(const Ogre::RenderTargetEvent& evt)
    {
        assert (mTerrainLiquid);
        mTerrainLiquid->setVisible(true);

        mCamera->disableReflection();
        mCamera->disableCustomNearClipPlane();
    }

    void RefractRenderTargetListener::preRenderTargetUpdate(const Ogre::RenderTargetEvent& evt)
    {
        assert (mTerrainLiquid);
        mTerrainLiquid->setVisible(false);

        mCamera->enableCustomNearClipPlane(*mPlane);
    }

    void RefractRenderTargetListener::postRenderTargetUpdate(const Ogre::RenderTargetEvent& evt)
    {
        assert (mTerrainLiquid);
        mTerrainLiquid->setVisible(true);

        mCamera->disableCustomNearClipPlane();
    }

    static const size_t TERRAIN_LIQUID_VERTEX_LIMIT = 32768;

    const String TerrainLiquidObject::msType = "TerrainLiquid";
    const String TerrainLiquidObject::msCategory = "StaticObject";

    // the name of the material that can reflect and refract the scene.
    const String WaterReflectRefractMaterialName = "waterReflectRefractMat";
    const String waterReflectRefractMatNamePrefixion = "# Fairy/waterReflectRefractMat/";

    enum TexUnit
    {
        NOISE,
        REFLECT,
        REFRACT,
        TEXUNITCONUT,
    };

    //////////////////////////////////////////////////////////////////////////
    // Factory
    //////////////////////////////////////////////////////////////////////////

    class TerrainLiquidObject::Factory : public ObjectFactory
    {
    public:
        const String& getType(void) const
        {
            return msType;
        }

        Object* createInstance(void)
        {
            return new TerrainLiquidObject;
        }
    };

    //////////////////////////////////////////////////////////////////////////
    // Commands
    //////////////////////////////////////////////////////////////////////////

    namespace
    {
        typedef ObjectMemberPropertyCommand<TerrainLiquidObject, String, &TerrainLiquidObject::mMaterialName> MaterialNameCmd;
        typedef ObjectMemberPropertyCommand<TerrainLiquidObject, Ogre::Vector3, &TerrainLiquidObject::mPosition> PositionCmd;
        typedef ObjectMemberPropertyCommand<TerrainLiquidObject, size_t, &TerrainLiquidObject::mSubdivision> SubdivisionCmd;
        typedef ObjectMemberPropertyCommand<TerrainLiquidObject, Real, &TerrainLiquidObject::mTexcoordScale> TexcoordScaleCmd;
        typedef ObjectMemberPropertyCommand<TerrainLiquidObject, Real, &TerrainLiquidObject::mTexcoordRotate> TexcoordRotateCmd;
        typedef ObjectMemberPropertyCommand<TerrainLiquidObject, bool, &TerrainLiquidObject::mDepthTexLayerEnabled> DepthTexLayerEnabledCmd;
        typedef ObjectMemberPropertyCommand<TerrainLiquidObject, Real, &TerrainLiquidObject::mDepthTexLayerScale> DepthTexLayerScaleCmd;
        typedef ObjectMemberPropertyCommand<TerrainLiquidObject, Real, &TerrainLiquidObject::mDepthTexLayerAdjust> DepthTexLayerAdjustCmd;
        typedef ObjectMemberPropertyCommand<TerrainLiquidObject, String, &TerrainLiquidObject::mProjectorName> ProjectorNameCmd;
        typedef ObjectMemberPropertyCommand<TerrainLiquidObject, Real, &TerrainLiquidObject::mProjectorSize> ProjectorSizeCmd;

        // CYS: B/C water properties stored in TerrainLiquidObject::mCYSWater (CYS/Scene/CYSWater.h).
        //      Field 0..12 = ShaderParams (CYSWaterSettings::ShaderParam), the others below.
        enum CYSWaterField
        {
            CYS_WF_REPLACE_MATERIAL = 100,
            CYS_WF_MESH_NAME,
            CYS_WF_NEW_WATER,
            CYS_WF_MIRROR_WATER,
            CYS_WF_ORIENTATION,
            CYS_WF_SCALE,
            CYS_WF_MESH_TEXTURE_SCALE,
            CYS_WF_TEXTURE_DEPTH,
        };

        struct CYSWaterPropertyCmd : PropertyCommand
        {
            int mField;
            explicit CYSWaterPropertyCmd(int field) : mField(field) {}

            Variant doGet(const void* source) const
            {
                return doGetAsString(source);
            }

            String doGetAsString(const void* source) const
            {
                const CYSWaterSettings& w = static_cast<const TerrainLiquidObject*>(source)->mCYSWater;
                switch (mField)
                {
                case CYS_WF_REPLACE_MATERIAL: return w.replaceMaterial;
                case CYS_WF_MESH_NAME: return w.meshName;
                case CYS_WF_NEW_WATER: return Ogre::StringConverter::toString(w.showNewWater);
                case CYS_WF_MIRROR_WATER: return Ogre::StringConverter::toString(w.showMirrorReflectWater);
                case CYS_WF_ORIENTATION: return Ogre::StringConverter::toString(w.orientation);
                case CYS_WF_SCALE: return Ogre::StringConverter::toString(w.scale);
                case CYS_WF_MESH_TEXTURE_SCALE: return Ogre::StringConverter::toString(w.meshLowLevelTextureScale);
                case CYS_WF_TEXTURE_DEPTH: return Ogre::StringConverter::toString(w.textureDepth);
                default: return w.getShaderParam(mField);
                }
            }

            void doSet(void* target, const Variant& value)
            {
                const String* text = VariantCast<String>(&value);
                if (text)
                    doSetAsString(target, *text);
            }

            void doSetAsString(void* target, const String& value)
            {
                TerrainLiquidObject* object = static_cast<TerrainLiquidObject*>(target);
                CYSWaterSettings& w = object->mCYSWater;
                const char* t = value.c_str();
                switch (mField)
                {
                case CYS_WF_REPLACE_MATERIAL: w.replaceMaterial = value; break;
                case CYS_WF_MESH_NAME: w.meshName = value; break;
                case CYS_WF_NEW_WATER: w.showNewWater = CYSScene::parseBool(t, false); break;
                case CYS_WF_MIRROR_WATER: w.showMirrorReflectWater = CYSScene::parseBool(t, false); break;
                case CYS_WF_ORIENTATION: w.orientation = CYSScene::parseQuaternion(t, Ogre::Quaternion::IDENTITY); break;
                case CYS_WF_SCALE: w.scale = CYSScene::parseVector3(t, Ogre::Vector3::UNIT_SCALE); break;
                case CYS_WF_MESH_TEXTURE_SCALE: w.meshLowLevelTextureScale = CYSScene::parseReal(t, 0); break;
                case CYS_WF_TEXTURE_DEPTH: w.textureDepth = CYSScene::parseReal(t, 0); break;
                default: w.setShaderParam(mField, value); break;
                }
                object->updateRenderInstance();
            }
        };
    }

    //////////////////////////////////////////////////////////////////////////
    // TerrainLiquidObject class
    //////////////////////////////////////////////////////////////////////////
    TerrainLiquidObject::TerrainLiquidObject(void)
        : Object()
        , mSystem()
        , mTerrainLiquid()
        , mProjectionMaterial()
        , mProjectionCamera()
        , mMaterialName()
        , mPosition(Ogre::Vector3::ZERO)
        , mSubdivision(1)
        , mTexcoordScale(1)
        , mTexcoordRotate(0.0f)
        , mDepthTexLayerEnabled(false)
        , mDepthTexLayerScale(1.0f)
        , mDepthTexLayerAdjust(0.0f)
        , mProjectorName()
        , mProjectorSize(0.0f)
        , mCYSWater()               // CYS
        , mCYSMeshEntity(NULL)
        , mCYSMeshNode(NULL)
        , mCYSMaterialClone()
        , mCYSEffectiveMaterial()
        , mReflectPlane(NULL)
        , mRefractPlane(NULL)
        , mReflectRenderTargetListener(NULL)
        , mRefractRenderTargetListener(NULL)
#if ((OGRE_VERSION_MAJOR << 16) | (OGRE_VERSION_MINOR << 8) | OGRE_VERSION_PATCH) >= 0x010100
        , mReflectTexture()
        , mRefractTexture()
#else
        , mReflectRenderTexture(NULL)
        , mRefractRenderTexture(NULL)
#endif
    {
        if (createPropertyDictionary("TerrainLiquid"))
        {
            static MaterialNameCmd materialNameCmd;
            defineProperty(
                "material",
                "The material name use to rendering this terrain liquid.",
                "MaterialName",
                &materialNameCmd,
                PF_PRIMARY);

            static PositionCmd positionCmd;
            defineProperty(
                "position",
                "The position of the terrain liquid.",
                "Position",
                &positionCmd,
                0);

            static SubdivisionCmd subdivisionCmd;
            defineProperty(
                "subdivision",
                "The subdivision of the terrain liquid grid.",
                "PositiveInteger",
                &subdivisionCmd,
                0);

            static TexcoordRotateCmd texcoordRotateCmd;
            defineProperty(
                "texture rotate",
                "The texture uv rotate of the terrain liquid.",
                "Real",
                &texcoordRotateCmd,
                0);

            static TexcoordScaleCmd texcoordScaleCmd;
            defineProperty(
                "texture scale",
                "The texture uv factor of the terrain liquid.",
                "Real",
                &texcoordScaleCmd,
                0);

            static DepthTexLayerEnabledCmd depthTexLayerEnabledCmd;
            defineProperty(
                "depth texture layer.enable",
                "Enable depth texture layer of the terrain liquid.",
                "Bool",
                &depthTexLayerEnabledCmd,
                0);

            static DepthTexLayerScaleCmd depthTexLayerScaleCmd;
            defineProperty(
                "depth texture layer.height scale",
                "The height scale factor to generate texcoords for depth texture layer.",
                "Real",
                &depthTexLayerScaleCmd,
                0);

            static DepthTexLayerAdjustCmd depthTexLayerAdjustCmd;
            defineProperty(
                "depth texture layer.height adjust",
                "The height adjust to generate texcoords for depth texture layer.",
                "Real",
                &depthTexLayerAdjustCmd,
                0);

            static ProjectorNameCmd projectorNameCmd;
            defineProperty(
                "projector name",
                "The object name use to project texture.",
                "String",
                &projectorNameCmd,
                0);

            static ProjectorSizeCmd projectorSizeCmd;
            defineProperty(
                "projector size",
                "The size used to scale the projected texture.",
                "Real",
                &projectorSizeCmd,
                0);

            // CYS: B/C water properties (Render.dll ParameterDefs FUN_180110360, 05 §5).
            static CYSWaterPropertyCmd replaceMaterialCmd(CYS_WF_REPLACE_MATERIAL);
            defineProperty("replaceMaterial",
                "The material name use to replace the current liquid when the hardware not support.",
                "MaterialName", &replaceMaterialCmd, 0);
            static CYSWaterPropertyCmd meshNameCmd(CYS_WF_MESH_NAME);
            defineProperty("mesh name", "The mesh name use to water.", "MeshName", &meshNameCmd, 0);
            static CYSWaterPropertyCmd newWaterCmd(CYS_WF_NEW_WATER);
            defineProperty("showNewWaterEnabled", "Show New Water or Not.", "Bool", &newWaterCmd, 0);
            static CYSWaterPropertyCmd mirrorWaterCmd(CYS_WF_MIRROR_WATER);
            defineProperty("showMirrorReflectWaterEnabled", "Show Mirror Reflect Water or Not.", "Bool",
                &mirrorWaterCmd, 0);
            static CYSWaterPropertyCmd orientationCmd(CYS_WF_ORIENTATION);
            defineProperty("orientation", "The orientation factor applied to this liquid.", "Orientation",
                &orientationCmd, 0);
            static CYSWaterPropertyCmd scaleCmd(CYS_WF_SCALE);
            defineProperty("scale", "The scaling factor applied to this liquid.", "Scale", &scaleCmd, 0);
            static CYSWaterPropertyCmd meshTextureScaleCmd(CYS_WF_MESH_TEXTURE_SCALE);
            defineProperty("texture scale for mesh water low level", "The texture uv factor of the terrain liquid.",
                "Real", &meshTextureScaleCmd, 0);
            static CYSWaterPropertyCmd textureDepthCmd(CYS_WF_TEXTURE_DEPTH);
            defineProperty("texture depth", "The texture depth factor for mesh.", "Real", &textureDepthCmd, 0);
            static CYSWaterPropertyCmd shaderParamCmds[CYSWaterSettings::SP_COUNT] =
            {
                CYSWaterPropertyCmd(0), CYSWaterPropertyCmd(1), CYSWaterPropertyCmd(2), CYSWaterPropertyCmd(3),
                CYSWaterPropertyCmd(4), CYSWaterPropertyCmd(5), CYSWaterPropertyCmd(6), CYSWaterPropertyCmd(7),
                CYSWaterPropertyCmd(8), CYSWaterPropertyCmd(9), CYSWaterPropertyCmd(10), CYSWaterPropertyCmd(11),
                CYSWaterPropertyCmd(12),
            };
            for (int i = 0; i < CYSWaterSettings::SP_COUNT; ++i)
            {
                defineProperty(CYSWaterSettings::getShaderParamName(i), "Water shader parameter (Model_Water_ps).",
                    i == CYSWaterSettings::SP_WATER_FOG_COLOR ? "ColourRGB" : "String", &shaderParamCmds[i], 0);
            }
        }
    }
    //-----------------------------------------------------------------------
    TerrainLiquidObject::~TerrainLiquidObject()
    {
        destroyRenderInstance();
    }
    //-----------------------------------------------------------------------
    const String& TerrainLiquidObject::getType(void) const
    {
        return msType;
    }
    //-----------------------------------------------------------------------
    const String& TerrainLiquidObject::getCategory(void) const
    {
        return msCategory;
    }
    //-----------------------------------------------------------------------
    void TerrainLiquidObject::createRenderInstance(System* system)
    {
        assert(system);
        mSystem = system;

        if (!mMaterialName.empty())
        {
            createTerrainLiquid();
        }
    }
    //-----------------------------------------------------------------------
    void TerrainLiquidObject::destroyRenderInstance(void)
    {
        if (mTerrainLiquid || mCYSMeshEntity)   // CYS: + mesh water
        {
            destroyTerrainLiquid();
        }
    }
    //-----------------------------------------------------------------------
    void TerrainLiquidObject::updateRenderInstance()
    {
        if (mTerrainLiquid || mCYSMeshEntity)   // CYS: + mesh water
        {
            destroyTerrainLiquid();
        }

        if (mSystem && !mMaterialName.empty())
        {
            createTerrainLiquid();
        }
    }
    //-----------------------------------------------------------------------
    void TerrainLiquidObject::createTerrainLiquid(void)
    {
        // CYS: B material choice (replaceMaterial when the water material cannot render, CYSWater.h) instead of
        //      the exception of TerrainLiquid::setMaterialName; mesh-shaped water replaces the flood grid.
        const String cysMaterial = _cysPrepareMaterial();
        if (cysMaterial.empty())
        {
            CYSSceneStats::instance().problem("TerrainLiquid without a usable material", mMaterialName);
            return;
        }
        if (!mCYSWater.meshName.empty())
        {
            _cysCreateMeshWater(cysMaterial);
            return;
        }

        assert(!mTerrainLiquid);
        assert(mProjectionMaterial.isNull());
        assert(!mProjectionCamera);
        assert(mSystem);
        assert(!mMaterialName.empty());

        Ogre::SceneNode* parent = mSystem->getBaseSceneNode()->createChildSceneNode();
        assert(parent);

        mTerrainLiquid = new TerrainLiquid(mSystem, mPosition, mSubdivision, TERRAIN_LIQUID_VERTEX_LIMIT);
        assert(mTerrainLiquid);

        parent->attachObject(mTerrainLiquid);

        mTerrainLiquid->setTexcoordScale(mTexcoordScale);
        mTerrainLiquid->setTexcoordRotate(Ogre::Radian(mTexcoordRotate));
        mTerrainLiquid->setDepthTexLayerSettings(
            mDepthTexLayerEnabled,
            mDepthTexLayerScale,
            mDepthTexLayerAdjust);

        _createRenderTexture();
        _setReflectPlane();

        _prepareProjector();

        if (!mProjectionMaterial.isNull())
            mTerrainLiquid->setMaterialName(mProjectionMaterial->getName());
        else if (mMaterialName.find(waterReflectRefractMatNamePrefixion) != String::npos)
            mTerrainLiquid->setMaterialName(mMaterialName);
        else
            mTerrainLiquid->setMaterialName(cysMaterial);  // CYS: the material chosen above

        // CYS: plug-in point of the reflection/refraction/depth render targets (CYSWaterRenderHooks).
        if (CYSWaterRenderHooks* hooks = CYSScene::getWaterRenderHooks())
            hooks->liquidCreated(*this, Ogre::MaterialManager::getSingleton().getByName(mTerrainLiquid->getMaterialName()));
    }
    //-----------------------------------------------------------------------
    void TerrainLiquidObject::destroyTerrainLiquid(void)
    {
        // CYS: render-target hooks, mesh water, per-object material clone
        if (CYSWaterRenderHooks* hooks = CYSScene::getWaterRenderHooks())
            hooks->liquidDestroyed(*this);
        if (mCYSMeshEntity || mCYSMeshNode)
        {
            _cysDestroyMeshWater();
            if (!mTerrainLiquid)
            {
                _cysReleaseMaterialClone();
                return;
            }
        }

        _deleteRenderTextureRelative();

        assert(mTerrainLiquid);

        Ogre::SceneNode* parent = mTerrainLiquid->getParentSceneNode();
        assert(parent);

        if (!mProjectionMaterial.isNull())
        {
            Ogre::MaterialManager::getSingleton().remove(mProjectionMaterial->getHandle());
            mProjectionMaterial.setNull();
        }

        if (mProjectionCamera)
        {
            parent->getCreator()->destroyCamera(mProjectionCamera);
            mProjectionCamera = 0;
        }

        parent->destroy();

        delete mTerrainLiquid;
        mTerrainLiquid = NULL;

        _cysReleaseMaterialClone();     // CYS
    }
    //-----------------------------------------------------------------------
    // CYS: material in use = chooseWaterMaterial(material, replaceMaterial); a per-object clone carries the
    //      ShaderParams (shared materials such as shader_water01 differ per object) or the mesh-water tiling.
    String TerrainLiquidObject::_cysPrepareMaterial(void)
    {
        _cysReleaseMaterialClone();
        bool replaced = false;
        String material = CYSScene::chooseWaterMaterial(mMaterialName, mCYSWater, &replaced);
        mCYSEffectiveMaterial = material;
        if (material.empty())
            return material;
        CYSSceneStats::instance().count(replaced ? "TerrainLiquid replaceMaterial used" : "TerrainLiquid material used");

        Ogre::MaterialPtr base = Ogre::MaterialManager::getSingleton().getByName(material);
        const bool programs = CYSScene::materialHasPrograms(base);
        const bool shaderParams = programs && mCYSWater.hasShaderParams();
        const bool tiling = !programs && !mCYSWater.meshName.empty() && mCYSWater.meshLowLevelTextureScale > 0;
        if (shaderParams || tiling)
        {
            const String cloneName = material + "#CYSWater" + Ogre::StringConverter::toString((size_t)this);
            mCYSMaterialClone = base->clone(cloneName);
            mCYSMaterialClone->load();
            if (shaderParams)
                CYSScene::applyWaterShaderParams(mCYSMaterialClone, mCYSWater, mTexcoordRotate, mTexcoordScale);
            if (tiling)
                CYSScene::applyTextureTiling(mCYSMaterialClone, mCYSWater.meshLowLevelTextureScale);
            material = cloneName;
        }
        mCYSEffectiveMaterial = material;
        return material;
    }
    //-----------------------------------------------------------------------
    void TerrainLiquidObject::_cysReleaseMaterialClone(void)
    {
        if (!mCYSMaterialClone.isNull())
        {
            Ogre::MaterialManager::getSingleton().remove(mCYSMaterialClone->getHandle());
            mCYSMaterialClone.setNull();
        }
    }
    //-----------------------------------------------------------------------
    // CYS: "mesh name" water (62 objects): the mesh at position/orientation/scale with the water material.
    void TerrainLiquidObject::_cysCreateMeshWater(const String& material)
    {
        assert(mSystem);
        Ogre::SceneManager* sceneManager = mSystem->getSceneManager();
        const String name = "CYSWaterMesh#" + Ogre::StringConverter::toString((size_t)this);
        try
        {
            mCYSMeshEntity = sceneManager->createEntity(name, mCYSWater.meshName);
        }
        catch (const Ogre::Exception&)
        {
            CYSSceneStats::instance().problem("TerrainLiquid mesh not loaded", mCYSWater.meshName);
            mCYSMeshEntity = NULL;
            _cysReleaseMaterialClone();
            return;
        }
        mCYSMeshEntity->setMaterialName(material);
        mCYSMeshEntity->setCastShadows(false);
        // CYS-WATER: CY FUN_1801219e0 - PBRScene_Water on a mesh renders in queue 77 (0x4d) when the new water renders
        //            (it reads the scene_buffer copy made before that queue); other mesh water stays in 75 (0x4b).
        const bool cysNewMeshWater = material.find("PBRScene_Water") != String::npos &&
            CYSScene::getWaterRenderHooks() && CYSScene::getWaterRenderHooks()->supportsNewWater();
        mCYSMeshEntity->setRenderQueueGroup(cysNewMeshWater ? (Ogre::uint8)77 : (Ogre::uint8)Ogre::RENDER_QUEUE_WORLD_GEOMETRY_2);
        mCYSMeshNode = mSystem->getBaseSceneNode()->createChildSceneNode(mPosition, mCYSWater.orientation);
        mCYSMeshNode->setScale(mCYSWater.scale);
        mCYSMeshNode->attachObject(mCYSMeshEntity);
        CYSSceneStats::instance().count("TerrainLiquid mesh water");

        if (CYSWaterRenderHooks* hooks = CYSScene::getWaterRenderHooks())
            hooks->liquidCreated(*this, Ogre::MaterialManager::getSingleton().getByName(material));
    }
    //-----------------------------------------------------------------------
    // CYS-WATER: used by CysWaterRender around the mirror render texture update.
    void TerrainLiquidObject::_cysSetRenderVisible(bool visible)
    {
        if (mTerrainLiquid)
            mTerrainLiquid->setVisible(visible);
        if (mCYSMeshEntity)
            mCYSMeshEntity->setVisible(visible);
    }
    //-----------------------------------------------------------------------
    bool TerrainLiquidObject::_cysGetWorldBounds(Ogre::AxisAlignedBox& bounds) const
    {
        if (mTerrainLiquid)
        {
            bounds = mTerrainLiquid->getWorldBoundingBox(true);
            return true;
        }
        if (mCYSMeshEntity)
        {
            bounds = mCYSMeshEntity->getWorldBoundingBox(true);
            return true;
        }
        return false;
    }
    //-----------------------------------------------------------------------
    void TerrainLiquidObject::_cysDestroyMeshWater(void)
    {
        if (mCYSMeshEntity)
        {
            if (mCYSMeshNode)
                mCYSMeshNode->detachObject(mCYSMeshEntity);
            mSystem->getSceneManager()->destroyEntity(mCYSMeshEntity);
            mCYSMeshEntity = NULL;
        }
        if (mCYSMeshNode)
        {
            mCYSMeshNode->destroy();
            mCYSMeshNode = NULL;
        }
    }
    //-----------------------------------------------------------------------
    void TerrainLiquidObject::_prepareProjector(void)
    {
        if (mProjectorName.empty() || !mProjectorSize)
            return;

        // CYS: the material chosen by _cysPrepareMaterial (replaceMaterial fallback)
        Ogre::MaterialPtr material = Ogre::MaterialManager::getSingleton().getByName(
            mCYSEffectiveMaterial.empty() ? mMaterialName : mCYSEffectiveMaterial);
        if (material.isNull())
            return;

        bool hasProjector = false;
        {
            Ogre::Material::TechniqueIterator ti = material->getTechniqueIterator();
            while (ti.hasMoreElements())
            {
                Ogre::Technique* technique = ti.getNext();
                Ogre::Technique::PassIterator pi = technique->getPassIterator();
                while (pi.hasMoreElements())
                {
                    Ogre::Pass* pass = pi.getNext();
                    Ogre::Pass::TextureUnitStateIterator tusi = pass->getTextureUnitStateIterator();
                    while (tusi.hasMoreElements())
                    {
                        Ogre::TextureUnitState* tus = tusi.getNext();
                        if (Ogre::StringUtil::startsWith(tus->getName(), "Fairy/Projector", false))
                        {
                            hasProjector = true;
                        }
                    }
                }
            }
        }
        if (!hasProjector)
            return;

        ObjectPtr object = mSystem->getSceneInfo()->findObjectByName(mProjectorName);
        if (!object)
            return;

        Variant directionValue = object->getProperty("direction");
        if (directionValue.empty() || directionValue.type() != typeid(Ogre::Vector3))
            return;

        Ogre::Vector3 direction = VariantCast<Ogre::Vector3>(directionValue);
        direction.normalise();

        String name = material->getName() + Ogre::StringConverter::toString((size_t)this);	// CYS: ulong truncated the pointer (x64)

        mProjectionCamera = mTerrainLiquid->getParentSceneNode()->getCreator()->createCamera(name);
        mProjectionCamera->setAutoAspectRatio(false);
        mProjectionCamera->setAspectRatio(1.0f);
        mProjectionCamera->setFixedYawAxis(false);
        mProjectionCamera->setProjectionType(Ogre::PT_ORTHOGRAPHIC);
        mProjectionCamera->setFOVy(Ogre::Degree(90));
        mProjectionCamera->setDirection(-direction);
        mProjectionCamera->setNearClipDistance(mProjectorSize / 2);
        mProjectionCamera->setFarClipDistance(mProjectorSize + 5000.0f);

        mTerrainLiquid->setProjectionCamera(mProjectionCamera);

        mProjectionMaterial = material->clone(name);
        {
            Ogre::Material::TechniqueIterator ti = mProjectionMaterial->getTechniqueIterator();
            while (ti.hasMoreElements())
            {
                Ogre::Technique* technique = ti.getNext();
                Ogre::Technique::PassIterator pi = technique->getPassIterator();
                while (pi.hasMoreElements())
                {
                    Ogre::Pass* pass = pi.getNext();
                    Ogre::Pass::TextureUnitStateIterator tusi = pass->getTextureUnitStateIterator();
                    while (tusi.hasMoreElements())
                    {
                        Ogre::TextureUnitState* tus = tusi.getNext();
                        if (Ogre::StringUtil::startsWith(tus->getName(), "Fairy/Projector", false))
                        {
                            tus->setProjectiveTexturing(true, mProjectionCamera);
                        }
                    }
                }
            }
        }
        mProjectionMaterial->load();
    }
    //-----------------------------------------------------------------------
    ObjectFactory* TerrainLiquidObject::getFactory(void)
    {
        static Factory factory;
        return &factory;
    }

    void TerrainLiquidObject::_createRenderTexture(void)
    {
        // only craete the texture when we want the water to reflect and refract
        if (mMaterialName.find(WaterReflectRefractMaterialName) != String::npos)
        {
            Ogre::MaterialPtr mat = Ogre::MaterialManager::getSingleton().getByName(WaterReflectRefractMaterialName);

            if (mat.isNull())
            {
                Ogre::LogManager::getSingleton().logMessage(
                    WaterReflectRefractMaterialName + "does not exist. Have you forgotten to define it in a "
                    ".material script?");
            }
            else
            {
                assert (mat->getTechnique(0)->getPass(0)->getNumTextureUnitStates() >= TEXUNITCONUT );

                // 构建新材质的名称，并判断这个材质是否存在
                Ogre::String newMatName = mTerrainLiquid->getName() + waterReflectRefractMatNamePrefixion + WaterReflectRefractMaterialName;

                Ogre::MaterialPtr newMat = Ogre::MaterialManager::getSingleton().getByName(newMatName);

                if (newMat.isNull() == false)
                {
                    Ogre::LogManager::getSingleton().logMessage(newMat->getName() + "exist.");
                }
                assert (newMat.isNull() == true);

                mat = mat->clone(newMatName);

                assert (false == mat.isNull());
                // create refraction texture
                if ( mat->getTechnique(0)->getPass(0)->getTextureUnitState( REFRACT )->getTextureName() == "<RefractTexInput>" )
                {
                    assert (mTerrainLiquid);
                    mRefractTextureName = mTerrainLiquid->getName() + waterReflectRefractMatNamePrefixion + "waterRefractTex";

                    Ogre::Viewport *v = NULL;

                    Ogre::Viewport* oldViewport = mSystem->getCamera()->getViewport();
                    Real aspect = mSystem->getCamera()->getAspectRatio();

#if ((OGRE_VERSION_MAJOR << 16) | (OGRE_VERSION_MINOR << 8) | OGRE_VERSION_PATCH) >= 0x010100
                    mRefractTexture = Ogre::TextureManager::getSingleton().createManual(
                        mRefractTextureName, Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME,
                        Ogre::TEX_TYPE_2D, 512, 512, 1, 0, Ogre::PF_X8R8G8B8, Ogre::TU_RENDERTARGET);
                    mRefractTexture->load();
                    {
                        v = mRefractTexture->getBuffer()->getRenderTarget()->addViewport( mSystem->getCamera() );
                    }
#else
                    mRefractRenderTexture = mSystem->getRoot()->getRenderSystem()->createRenderTexture( mRefractTextureName, 512, 512 );
                    {
                        v = mRefractRenderTexture->addViewport( mSystem->getCamera() );
                    }
#endif

                    mSystem->getCamera()->_notifyViewport(oldViewport);
                    mSystem->getCamera()->setAspectRatio(aspect);
                    assert (v);
                    mat->getTechnique(0)->getPass(0)->getTextureUnitState( REFRACT )->setTextureName(mRefractTextureName);
                    v->setOverlaysEnabled(false);
                }

                mRefractRenderTargetListener = new RefractRenderTargetListener;
                mRefractRenderTargetListener->setCamera( mSystem->getCamera() );

                mRefractRenderTargetListener->setTerrainLiquid(mTerrainLiquid);

#if ((OGRE_VERSION_MAJOR << 16) | (OGRE_VERSION_MINOR << 8) | OGRE_VERSION_PATCH) >= 0x010100
                assert ( false == mRefractTexture.isNull() );
                mRefractTexture->getBuffer()->getRenderTarget()->addListener(mRefractRenderTargetListener);
#else
                assert (mRefractRenderTexture);
                assert ( mRefractRenderTexture ==
                    mSystem->getRoot()->getRenderSystem()->getRenderTarget(mRefractTextureName) );
                mRefractRenderTexture->addListener(mRefractRenderTargetListener);
#endif

                // create reflection texture
                if ( mat->getTechnique(0)->getPass(0)->getTextureUnitState( REFLECT )->getTextureName() == "<ReflectTexInput>" )
                {
                    assert (mTerrainLiquid);

                    mReflectTextureName = mTerrainLiquid->getName() + waterReflectRefractMatNamePrefixion + "waterReflectTex";

                    Ogre::Viewport *v = NULL;
                    Ogre::Viewport* oldViewport = mSystem->getCamera()->getViewport();
                    Real aspect = mSystem->getCamera()->getAspectRatio();

#if ((OGRE_VERSION_MAJOR << 16) | (OGRE_VERSION_MINOR << 8) | OGRE_VERSION_PATCH) >= 0x010100
                    mReflectTexture = Ogre::TextureManager::getSingleton().createManual(
                        mReflectTextureName, Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME,
                        Ogre::TEX_TYPE_2D, 512, 512, 1, 0, Ogre::PF_X8R8G8B8, Ogre::TU_RENDERTARGET);
                    mReflectTexture->load();
                    {
                        v = mReflectTexture->getBuffer()->getRenderTarget()->addViewport( mSystem->getCamera() );
                    }
#else
                    mReflectRenderTexture = mSystem->getRoot()->getRenderSystem()->createRenderTexture( mReflectTextureName, 512, 512 );
                    {
                        v = mReflectRenderTexture->addViewport( mSystem->getCamera() );
                    }
#endif

                    mSystem->getCamera()->_notifyViewport(oldViewport);
                    mSystem->getCamera()->setAspectRatio(aspect);
                    assert (v);
                    mat->getTechnique(0)->getPass(0)->getTextureUnitState( REFLECT )->setTextureName(mReflectTextureName);
                    v->setOverlaysEnabled(false);
                }

                mReflectRenderTargetListener = new ReflectRenderTargetListener;
                mReflectRenderTargetListener->setTerrainLiquid(mTerrainLiquid);
                mReflectRenderTargetListener->setCamera( mSystem->getCamera() );

#if ((OGRE_VERSION_MAJOR << 16) | (OGRE_VERSION_MINOR << 8) | OGRE_VERSION_PATCH) >= 0x010100
                assert ( false == mReflectTexture.isNull() );
                mReflectTexture->getBuffer()->getRenderTarget()->addListener(mReflectRenderTargetListener);
#else
                assert (mReflectRenderTexture);
                assert ( mReflectRenderTexture ==
                    mSystem->getRoot()->getRenderSystem()->getRenderTarget(mReflectTextureName) );
                mReflectRenderTexture->addListener(mReflectRenderTargetListener);
#endif

                mMaterialName = newMatName;
            }
        }
    }

    void TerrainLiquidObject::_setReflectPlane()
    {
        if (mMaterialName.find(WaterReflectRefractMaterialName) != String::npos)
        {
            if ( mReflectPlane == NULL )
                mReflectPlane = new Ogre::Plane( Ogre::Vector3::UNIT_Y, mPosition.y );
            else
            {
                mReflectPlane->d = mPosition.y;
                mReflectPlane->normal = Ogre::Vector3::UNIT_Y;
            }

            assert (mReflectRenderTargetListener);
            mReflectRenderTargetListener->setPlane(mReflectPlane);

            if ( mRefractPlane == NULL )
                mRefractPlane = new Ogre::Plane( -Ogre::Vector3::UNIT_Y, -mPosition.y );
            else
            {
                mRefractPlane->d = -mPosition.y;
                mRefractPlane->normal = -Ogre::Vector3::UNIT_Y;
            }

            assert (mRefractRenderTargetListener);
            mRefractRenderTargetListener->setPlane(mRefractPlane);
        }
    }

    void TerrainLiquidObject::_deleteRenderTextureRelative(void)
    {
        if (mReflectRenderTargetListener)
        {
#if ((OGRE_VERSION_MAJOR << 16) | (OGRE_VERSION_MINOR << 8) | OGRE_VERSION_PATCH) >= 0x010100
            mReflectTexture->getBuffer()->getRenderTarget()->removeListener(mReflectRenderTargetListener);
#else
            assert (mReflectRenderTexture);
            mReflectRenderTexture->removeListener(mReflectRenderTargetListener);
#endif

            delete mReflectRenderTargetListener;
            mReflectRenderTargetListener = NULL;
        }

        if (mRefractRenderTargetListener)
        {
#if ((OGRE_VERSION_MAJOR << 16) | (OGRE_VERSION_MINOR << 8) | OGRE_VERSION_PATCH) >= 0x010100
            mRefractTexture->getBuffer()->getRenderTarget()->removeListener(mRefractRenderTargetListener);
#else
            assert (mRefractRenderTexture);
            mRefractRenderTexture->removeListener(mRefractRenderTargetListener);
#endif

            delete mRefractRenderTargetListener;
            mRefractRenderTargetListener = NULL;
        }

        if (mReflectPlane)
        {
            delete mReflectPlane;
            mReflectPlane = NULL;
        }

        if (mRefractPlane)
        {
            delete mRefractPlane;
            mRefractPlane = NULL;
        }

#if ((OGRE_VERSION_MAJOR << 16) | (OGRE_VERSION_MINOR << 8) | OGRE_VERSION_PATCH) >= 0x010100
        if ( false == mReflectTexture.isNull() )
        {
            assert( mReflectTexture->getBuffer()->getRenderTarget()->getNumViewports() == 1 );
            mReflectTexture->getBuffer()->getRenderTarget()->removeAllViewports();
            Ogre::TextureManager::getSingleton().remove(mReflectTexture->getName());
            mReflectTexture.setNull();
        }
#else
        if (mReflectRenderTexture)
        {
            assert ( mReflectRenderTexture->getNumViewports() == 1 );
            mReflectRenderTexture->removeAllViewports();
            mSystem->getRoot()->getRenderSystem()->destroyRenderTexture(mReflectTextureName);
            mReflectRenderTexture = NULL;
        }
#endif

#if ((OGRE_VERSION_MAJOR << 16) | (OGRE_VERSION_MINOR << 8) | OGRE_VERSION_PATCH) >= 0x010100
        if ( false == mRefractTexture.isNull() )
        {
            assert( mRefractTexture->getBuffer()->getRenderTarget()->getNumViewports() == 1 );
            mRefractTexture->getBuffer()->getRenderTarget()->removeAllViewports();
            Ogre::TextureManager::getSingleton().remove(mRefractTexture->getName());
            mRefractTexture.setNull();
        }
#else
        if (mRefractRenderTexture)
        {
            assert ( mRefractRenderTexture->getNumViewports() == 1 );
            mRefractRenderTexture->removeAllViewports();
            mSystem->getRoot()->getRenderSystem()->destroyRenderTexture(mRefractTextureName);
            mRefractRenderTexture = NULL;
        }
#endif

        if (mMaterialName.find(waterReflectRefractMatNamePrefixion+WaterReflectRefractMaterialName) != String::npos)
        {
            Ogre::MaterialManager::getSingleton().remove(mMaterialName);
        }
    }
}
