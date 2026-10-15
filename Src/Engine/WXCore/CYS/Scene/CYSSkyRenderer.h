#ifndef __CYS_SKYRENDERER_H__
#define __CYS_SKYRENDERER_H__

// CY-Source (scene agent): sky of the modern client drawn with fixed-function materials, i.e. with what the 0.85
// renderer can do today (the B sky shaders EnScene.hlsl / SkySphereLayer.hlsl need the SM3 material pipeline).
//   EnScene: sky dome = the <SkyDome><texture> colour table sampled at (time of day / 24, 1 - elevation) exactly as
//            En_sky_dome_v/p (the Mie term is ~0 with the data's mieAmount 0.01) on the flattened dome of
//            enskydome.mesh (radius 3170, half height 1769.5) shifted by <hight>; cloud dome layers (their mesh,
//            tiled/scrolled texture, ambient blend, fog blend, alpha); horizon ring clouds (generated ring with
//            ringcloud.mesh proportions and the shader's vertical fade); sun + flare, moon and stars billboards.
//   SkySphere: texture bands per <SkyLayer> (background, far_cloud, mountain, near_cloud, fog tinted by sky_fog)
//            with up to two blended texture groups, rotation, plus moon (lunar date texture) and stars.
// All sky geometry follows the camera, is drawn in render queues 1-9 (before the scene, no depth writes, no fog)
// and scales with the camera far clip. Values marked INF in the .cpp are approximations of shader terms.

#include "CYSEnSceneData.h"
#include "CYSSkySphereData.h"

namespace Ogre
{
    class SceneManager;
    class SceneNode;
    class MovableObject;
    class TextureUnitState;
    class Pass;
}

namespace WX
{
    class System;
    struct CYSEnvironment;

    class CYSSkyRenderer
    {
    public:
        explicit CYSSkyRenderer(System* system);
        ~CYSSkyRenderer();

        void buildEnScene(const CYSEnSky& sky, const String& sceneName);
        void buildSkySphere(const CYSSkySphereData& data, const CYSSkyWeather* weather, const String& sceneName);
        void destroy(void);

        /// Per frame: follow the camera, animate, update colours from the environment.
        void update(Real dt, const CYSEnvironment& env);

        void setVisible(bool visible);
        /// CYS-SKY: build only what CYSSkyCyRenderer does not draw with CY shaders (stars, sun flare, SkySphere moon).
        void setExtrasOnly(bool extras) { mExtrasOnly = extras; }
        size_t getNumElements(void) const { return mElements.size(); }
        bool isEmpty(void) const { return mElements.empty(); }

        struct Element;

    private:
        Element* addElement(int kind, Real order, const String& label);
        String makeName(const String& label);
        Ogre::Pass* createMaterial(Element* e, const String& texture, bool alphaBlend, bool vertexColour);
        void assignRenderQueues(void);
        bool textureExists(const String& name) const;

        void buildDome(const CYSEnSkyDome& dome);
        void buildCloudLayer(const CYSEnCloudLayer& layer);
        void buildRingLayer(const CYSEnCloudLayer& layer);
        void buildCelestial(const CYSEnCelestial& c, bool sun);
        void buildStars(int count, Real size, const Ogre::ColourValue& start, const Ogre::ColourValue& end,
                        bool alwaysVisible, Real intensity);
        void buildSkySphereLayer(const CYSSkyLayerDef& def, const CYSSkyWeather& weather);
        void buildSkySphereMoon(const CYSSkySphereData& data);

        void updateElement(Element* e, Real dt, const CYSEnvironment& env, Real radius);

        System* mSystem;
        Ogre::SceneManager* mSceneManager;
        Ogre::SceneNode* mRoot;
        std::vector<Element*> mElements;
        String mPrefix;
        size_t mCounter;
        Real mTime;
        CYSEnCelestial mSun;            ///< EnScene sun (for the sun position when the key has no direction)
        bool mHasSun;
        bool mExtrasOnly;               ///< CYS-SKY
    };
}

#endif // __CYS_SKYRENDERER_H__
