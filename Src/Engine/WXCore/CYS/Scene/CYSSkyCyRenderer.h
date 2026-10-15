#ifndef __CYS_SKYCYRENDERER_H__
#define __CYS_SKYCYRENDERER_H__

// CYS-SKY (sky-enscene, Docs/specs/render/sky-enscene-cy_vi.md): the sky of CY 3.71 drawn the way its Render.dll does,
// with the shaders of MaterialTemplates.zip EnScene.hlsl / SkySphereLayer.hlsl and the materials of all.material:
//   EnScene  : EnDome (FUN_1802391e0 / FUN_18023a0e0)  entity enskydome.mesh, "EnScene/skyDome", queue 5 prio 100
//              EnCloud (FUN_18023a350 / FUN_18023b200) <meshname>, clone of "EnScene/cloud", queue 59 prio 90+layer
//              EnRingCloud (FUN_18023b940 / FUN_18023c7a0) <meshname>, clone of "EnScene/ringcloud", queue 59 prio 110+layer
//              EnMoon / EnSun (FUN_180235a10 / FUN_180236000, FUN_180236220 / FUN_1802378a0) plane 200x200 at 9000,
//              "EnScene/moon" / "EnScene/sun", queue 59 prio 90+layer
//   SkySphere: SkySphereLayer (FUN_1801d0440 / FUN_1801d0ba0 / FUN_1801ce6f0) generated band mesh, pass with
//              SkySphereLayerBlend_<One|Two|Three>Texture_VS_1_1_hlsl / _PS_2_0_hlsl, queue 5 prio 100
// The per-frame constants follow the CY update functions (hours = CYSEnvironment::timeOfDay). Stars, sun flare, the
// SkySphere moon and stars have no CY shader draw in the captured frames; they stay on the fixed-function
// CYSSkyRenderer (built as "extras"). Switch: CYS_SKY_SHADER=0 -> the former fixed-function sky only.

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
        /// Direction towards the EnScene sun at `hours` (FUN_1802378a0; <Sun> defaults when absent).
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
