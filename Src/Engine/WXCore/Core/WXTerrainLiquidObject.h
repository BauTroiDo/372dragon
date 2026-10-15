#ifndef __FAIRYTERRAINLIQUIDOBJECT_H__
#define __FAIRYTERRAINLIQUIDOBJECT_H__

#include "WXObject.h"

#include <OgreVector3.h>
#include <OgreRenderTargetListener.h>
#include <OgreTexture.h>
#include <OgreMaterial.h>

#include "CYS/Scene/CYSWater.h"     // CYS

namespace Ogre
{
    class Entity;       // CYS
    class SceneNode;    // CYS
}

class Ogre::Camera;
class Ogre::Plane;
class Ogre::RenderTexture;

namespace WX {

    class ObjectFactory;
    class System;
    class TerrainLiquid;

    class LiquidRenderTargetListener : public Ogre::RenderTargetListener
    {
    public:
        void setCamera(Ogre::Camera *camera) { assert(camera); mCamera = camera; }
        void setPlane(Ogre::Plane *plane) { assert(plane); mPlane = plane; }

        void setTerrainLiquid(TerrainLiquid *liquid) { assert(liquid); mTerrainLiquid = liquid; }

    protected:
        TerrainLiquid *mTerrainLiquid;
        Ogre::Camera *mCamera;
        Ogre::Plane *mPlane;
    };

    class ReflectRenderTargetListener : public LiquidRenderTargetListener
    {
    public:
        virtual void preRenderTargetUpdate(const Ogre::RenderTargetEvent& evt);
        virtual void postRenderTargetUpdate(const Ogre::RenderTargetEvent& evt);
    };

    class RefractRenderTargetListener : public LiquidRenderTargetListener
    {
    public:
        virtual void preRenderTargetUpdate(const Ogre::RenderTargetEvent& evt);
        virtual void postRenderTargetUpdate(const Ogre::RenderTargetEvent& evt);
    };

    class TerrainLiquidObject : public Object
    {
    protected:
        class Factory;

    public:
        TerrainLiquidObject(void);
        virtual ~TerrainLiquidObject();

        const String& getType(void) const;
        const String& getCategory(void) const;

        void createRenderInstance(System* system);
        void destroyRenderInstance(void);
        void updateRenderInstance(void);

        //////////////////////////////////////////////////////////////////////////

        static const String msType;
        static const String msCategory;

        static ObjectFactory* getFactory(void);

        //////////////////////////////////////////////////////////////////////////

        TerrainLiquid * getTerrainLiquid(void)
        {
            assert(mTerrainLiquid);
            return mTerrainLiquid;
        }

        /// CYS-WATER: hides / shows the rendered liquid (grid or mesh) around the mirror render texture update.
        void _cysSetRenderVisible(bool visible);
        /// CYS-WATER: world bounds of the rendered liquid; false when nothing is rendered.
        bool _cysGetWorldBounds(Ogre::AxisAlignedBox& bounds) const;

    protected:
        System* mSystem;
        TerrainLiquid *mTerrainLiquid;
        Ogre::MaterialPtr mProjectionMaterial;
        Ogre::Camera *mProjectionCamera;

        void createTerrainLiquid(void);
        void destroyTerrainLiquid(void);

    public:     // Intend for direct access by property commands only, DO NOT access outside
        String mMaterialName;
        Ogre::Vector3 mPosition;
        size_t mSubdivision;
        Ogre::Real mTexcoordScale;
        Ogre::Real mTexcoordRotate;
        bool mDepthTexLayerEnabled;
        Real mDepthTexLayerScale;
        Real mDepthTexLayerAdjust;
        String mProjectorName;
        Real mProjectorSize;
        CYSWaterSettings mCYSWater;     // CYS: B/C replaceMaterial, mesh water, new/mirror switches, ShaderParams

        /////////////////////////////
    protected:
        // CYS: mesh-shaped water, per-object material clone carrying the ShaderParams, material in use.
        Ogre::Entity* mCYSMeshEntity;
        Ogre::SceneNode* mCYSMeshNode;
        Ogre::MaterialPtr mCYSMaterialClone;
        String mCYSEffectiveMaterial;
        String _cysPrepareMaterial(void);
        void _cysCreateMeshWater(const String& material);
        void _cysDestroyMeshWater(void);
        void _cysReleaseMaterialClone(void);

    protected:

        Ogre::Plane *mReflectPlane;
        Ogre::Plane *mRefractPlane;
        ReflectRenderTargetListener *mReflectRenderTargetListener;
        RefractRenderTargetListener *mRefractRenderTargetListener;

#if ((OGRE_VERSION_MAJOR << 16) | (OGRE_VERSION_MINOR << 8) | OGRE_VERSION_PATCH) >= 0x010100
        Ogre::TexturePtr mReflectTexture;
        Ogre::TexturePtr mRefractTexture;
#else
        Ogre::RenderTexture *mReflectRenderTexture;
        Ogre::RenderTexture *mRefractRenderTexture;
#endif

        String mReflectTextureName;
        String mRefractTextureName;

    protected:
        void _prepareProjector(void);

        void _createRenderTexture(void);
        void _setReflectPlane(void);

        void _deleteRenderTextureRelative(void);
    };
}

#endif // __FairyTerrainLiquidObject_H__
