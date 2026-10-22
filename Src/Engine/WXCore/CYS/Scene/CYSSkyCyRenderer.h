#ifndef __CYS_SKYCYRENDERER_H__
#define __CYS_SKYCYRENDERER_H__














#include "CYSEnSceneData.h"
#include "CYSSkySphereData.h"

#include <OgreMaterial.h>
#include <OgreMesh.h>

namespace Ogre
{
    class SceneManager;
    class SceneNode;
    class Pass;
}

namespace WX
{
    class System;
    struct CYSEnvironment;
    class CYSSkyRenderer;
    class CYSSkyMesh;

    class CYSSkyCyRenderer
    {
    public:
        explicit CYSSkyCyRenderer(System* system);
        ~CYSSkyCyRenderer();

        /// CYS_SKY_SHADER (default on) and the EnScene / SkySphereLayer programs are available.
        static bool isEnabled(void);

        static Ogre::Vector3 sunDirection(const CYSEnCelestial& sun, Real hours);

        void buildEnScene(const CYSEnSky& sky, const String& sceneName);
        void buildSkySphere(const CYSSkySphereData& data, const CYSSkyWeather* weather, const String& sceneName);
        void destroy(void);

        void update(Real dt, const CYSEnvironment& env);
        void setVisible(bool visible);

        size_t getNumElements(void) const;
        bool isEmpty(void) const { return getNumElements() == 0; }

        struct Item;

    private:
        Item* addItem(int kind, const String& label);
        String makeName(const String& label);
        bool prepareTexture(const String& name, bool noMipmaps);
        Ogre::MaterialPtr cloneMaterial(const String& source, const String& name);
        Ogre::MeshPtr loadMesh(const String& name);
        Ogre::MeshPtr skySphereMesh(Real pitchStart, Real pitchEnd);
        void attach(Item* item, const Ogre::MeshPtr& mesh, Ogre::uint8 queue, Ogre::ushort priority);

        void buildDome(const CYSEnSkyDome& dome);
        void buildCloud(const CYSEnCloudLayer& layer);
        void buildRing(const CYSEnCloudLayer& layer);
        void buildCelestial(const CYSEnCelestial& c, bool sun);
        void buildSphereLayer(const CYSSkyLayerDef& def, const CYSSkyWeather& weather, int order);
        void rebuildSphereMaterial(Item* item, const std::vector<Real>& alphas);

        void updateItem(Item* item, Real dt, const CYSEnvironment& env, const Ogre::Vector3& cameraPos);

        System* mSystem;
        Ogre::SceneManager* mSceneManager;
        Ogre::SceneNode* mRoot;
        std::vector<Item*> mItems;
        std::vector<String> mMeshes;        ///< generated meshes to remove
        String mPrefix;
        size_t mCounter;
        CYSEnCelestial mSun;                ///< EnScene <Sun> (defaults when absent) -> sun direction of the constants
        bool mSkySphere;
        bool mFixedHeight;
        Real mFixedHeightValue;
        CYSSkyRenderer* mExtras;            ///< fixed-function stars / sun flare / SkySphere moon
    };
}

#endif // __CYS_SKYCYRENDERER_H__
