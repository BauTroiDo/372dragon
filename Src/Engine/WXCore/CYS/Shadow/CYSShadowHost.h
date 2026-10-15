#ifndef __CYS_SHADOW_HOST_H__
#define __CYS_SHADOW_HOST_H__

// CY-Source (shadow-cy): start-up / run-time glue of the cascaded shadow maps for a host (Game.exe WXRender
// CRenderSystem, TlbbViewer). Keeps the hooks in the hosts to a few lines (// CYS-SHADOW:).
//
//   Game (WXRender RenderSystem.cpp):
//     WX::CYSShadowConfig cfg = WX::CYSShadowHost::readConfig(lookup, user);      // before resources are parsed
//     CYS::MaterialSystem::getSingleton().setGlobalDefine("SHADOWMAP_TYPE", WX::CYSShadowHost::shaderDefine(cfg));
//     ... System::setup ...
//     WX::CYSShadowHost::start(cfg, sceneManager, camera);                         // after setup
//     WX::CYSShadowHost::applyVariable(key, value);                                // VARIABLE_CHANGED
//     WX::CYSShadowHost::stop();                                                   // before Ogre::Root goes
//
// Quality levels and keys: Docs\specs\render\shadow-cy_vi.md.

#include "CYSShadowConfig.h"

namespace Ogre
{
    class Camera;
    class SceneManager;
}

namespace WX
{
    class CYSShadowHost
    {
    public:
        /// key -> value of the host configuration (System.cfg / variable system); false = key not set
        typedef bool (*Lookup)(void* user, const Ogre::String& key, Ogre::String& value);

        /// Quality level key of the options (0 off, 1 low, 2 high)
        static const char* const kLevelKey;
        /// Default level when the configuration does not set kLevelKey
        static int defaultLevel(void);
        /// Configuration of a quality level (before the Gfx_Shadow* fine keys)
        static CYSShadowConfig configForLevel(int level);
        /// Level from kLevelKey, then the Gfx_Shadow* keys, then CYS_SHADOW* environment overrides
        static CYSShadowConfig readConfig(Lookup lookup, void* user);
        /// SHADOWMAP_TYPE macro value for the material system ("" when off: no receiver variants)
        static Ogre::String shaderDefine(const CYSShadowConfig& config);

        /// Creates the atlas and attaches to the scene (media folder "Media\CysShadow" next to the exe is optional:
        /// casters use MaterialTemplates' Depth_* programs). LogicModels cast.
        static bool start(const CYSShadowConfig& config, Ogre::SceneManager* sceneManager, Ogre::Camera* camera);
        /// Run-time change of kLevelKey or a Gfx_Shadow* key; true if the key belongs to the shadows. Switching on a
        /// renderer started with shadows off needs a restart (receivers were compiled without shadows).
        static bool applyVariable(const Ogre::String& key, const Ogre::String& value);
        /** CYS-LOOK: per-scene rule of CY 3.71 (Render.dll vtable 0x260 FUN_18002b5e0 / 0x228 FUN_18002b710):
            the login scene (erengu_DL) turns the shadows on with setShadowDis(18000, 1000), the character screen
            (tl3chuangjian) turns them off; every other scene follows View_HumanLightmap again, as Game.exe resends
            the key on each EnterScene. Pass the scene file name (with or without folders / extension). */
        static void onSceneLoaded(const Ogre::String& sceneFile);
        static void stop(void);
        static bool isStarted(void);
    };
}

#endif // __CYS_SHADOW_HOST_H__
