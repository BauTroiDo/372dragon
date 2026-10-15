// CY-Source Tests/fx/particles: engine set-up shared by CYSParticleUnitTest and CYSParticleBench.
// Root without plugins.cfg, the D3D9 render system and the inner plugins like WXRender (loadRenderPlugins_D3D9 /
// loadInnerPlugins), the WXCore particle renderers / affectors (as WX::System::_registerExtraPlugins) and
// Plugin_ParticleFX2. The render window uses a HIDDEN Win32 window (externalWindowHandle), so nothing shows on
// the desktop and no focus is taken from a running game.
#ifndef CYS_TESTS_FX_PARTICLE_ENV_H
#define CYS_TESTS_FX_PARTICLE_ENV_H

#include <windows.h>

#include "OgreExt/OgreMeshParticleRenderer.h"
#include "OgreExt/OgreTexCoordBillboardParticleRenderer.h"
#include "OgreExt/OgreRibbonRenderer.h"
#include "OgreExt/OgreMeshRotationAffectorFactory.h"
#include "OgreExt/OgreMeshAnimationAffectorFactory.h"
#include "CYS/Effects/WXSequenceFrameAffector.h"
#include "CYS/Effects/WXDissolveAffector.h"
#include "CYS/Effects/WXRotationCurveAffector.h"

#include <OgreRoot.h>
#include <OgreRenderWindow.h>
#include <OgreSceneManager.h>
#include <OgreCamera.h>
#include <OgreViewport.h>
#include <OgreParticleSystemManager.h>
#include <OgreStringConverter.h>
#include <OgreException.h>

namespace cysfx
{
    struct Env
    {
        Ogre::Root* root;
        Ogre::RenderWindow* window;
        Ogre::SceneManager* scene;
        Ogre::Camera* camera;
        HWND hwnd;
        bool fx2;
        Env() : root(0), window(0), scene(0), camera(0), hwnd(0), fx2(false) {}
    };

    inline LRESULT CALLBACK envWndProc(HWND h, UINT m, WPARAM w, LPARAM l)
    {
        return DefWindowProcA(h, m, w, l);
    }

    inline HWND createHiddenWindow(int width, int height)
    {
        WNDCLASSA wc;
        ZeroMemory(&wc, sizeof(wc));
        wc.lpfnWndProc = envWndProc;
        wc.hInstance = GetModuleHandleA(0);
        wc.lpszClassName = "CYSParticleTestWindow";
        RegisterClassA(&wc);
        // no WS_VISIBLE and no ShowWindow: the window stays hidden
        return CreateWindowExA(0, wc.lpszClassName, "CYS particle test", WS_OVERLAPPEDWINDOW, 0, 0, width, height,
            0, 0, wc.hInstance, 0);
    }

    /** withRenderSystem = false: parsers / math only (no device). */
    inline bool initEnv(Env& env, const Ogre::String& logPath, bool withRenderSystem, int width = 320, int height = 240)
    {
        env.root = new Ogre::Root("", "", logPath);
        if (withRenderSystem)
            env.root->loadRenderPlugins_D3D9();
        env.root->loadInnerPlugins();

        Ogre::ParticleSystemManager& psm = Ogre::ParticleSystemManager::getSingleton();
        psm.addRendererFactory(new Ogre::TexCoordBillboardParticleRendererFactory());
        psm.addRendererFactory(new Ogre::MeshParticleRendererFactory());
        psm.addRendererFactory(new Ogre::RibbonRendererFactory());
        psm.addAffectorFactory(new Ogre::MeshRotationAffectorFactory());
        psm.addAffectorFactory(new Ogre::MeshAnimationAffectorFactory());
        psm.addAffectorFactory(new WX::SequenceFrameAffectorFactory());
        psm.addAffectorFactory(new WX::DissolveAffectorFactory());
        psm.addAffectorFactory(new WX::RotationCurveAffectorFactory());
        try { env.root->loadPlugin("Plugin_ParticleFX2"); env.fx2 = true; }
        catch (Ogre::Exception&) {}

        if (!withRenderSystem)
            return true;
        if (!env.root->getRenderSystem())
            return false;
        env.root->initialise(false);
        env.hwnd = createHiddenWindow(width, height);
        Ogre::NameValuePairList misc;
        misc["externalWindowHandle"] = Ogre::StringConverter::toString((unsigned long)(UINT_PTR)env.hwnd);
        misc["vsync"] = "false";
        misc["FSAA"] = "0";
        env.window = env.root->createRenderWindow("CYS particle test", width, height, false, &misc);
        env.window->setAutoUpdated(false);
        env.scene = env.root->createSceneManager(Ogre::ST_GENERIC, "cys_particle_test");
        env.root->_setCurrentSceneManager(env.scene); // mesh particles create their entities in the current one
        env.camera = env.scene->createCamera("cys_particle_camera");
        env.camera->setNearClipDistance(10.0f);
        env.camera->setFarClipDistance(200000.0f);
        env.window->addViewport(env.camera);
        return true;
    }

    inline void shutdownEnv(Env& env)
    {
        // Root unloads Plugin_ParticleFX2 before it deletes the particle manager: systems and templates holding
        // affectors / emitters of the plug-in must go first
        if (env.scene)
            env.scene->destroyAllParticleSystems();
        Ogre::ParticleSystemManager::ParticleSystemTemplateIterator it =
            Ogre::ParticleSystemManager::getSingleton().getTemplateIterator();
        while (it.hasMoreElements())
        {
            Ogre::ParticleSystem* t = it.getNext();
            t->removeAllAffectors();
            t->removeAllEmitters();
        }
        delete env.root;
        env.root = 0;
        if (env.hwnd)
            DestroyWindow(env.hwnd);
        env.hwnd = 0;
    }
}

#endif
