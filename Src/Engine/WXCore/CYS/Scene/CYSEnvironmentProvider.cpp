// CY-Source (scene agent): see CYSEnvironmentProvider.h.
#include "CYSEnvironmentProvider.h"
#include "CYSEnvironment.h"
#include <cstdlib>

namespace WX
{
    bool CYSEnvironmentProvider::getEnvironmentParams(const Ogre::Camera* camera, Ogre::EnvironmentParamBlock& out) const
    {
        (void)camera;   // the environment is the same for every camera (shadow / render-texture cameras too)
        const CYSEnvironmentManager& manager = CYSEnvironmentManager::getSingleton();
        const CYSEnvironment& env = manager.getEnvironment();
        if (env.source == CYSEnvironment::SOURCE_NONE || !manager.isEnvironmentEnabled())
            return false;   // no EnScene / SkySphere keys (or CYS_ENV=0): OGRE's own values stay

        out.actorLightOne = Ogre::ColourValue(env.actorLightOne.r, env.actorLightOne.g, env.actorLightOne.b,
                                              env.actorLightOneIntensity);
        out.actorLightTwo = Ogre::ColourValue(env.actorLightTwo.r, env.actorLightTwo.g, env.actorLightTwo.b,
                                              env.actorLightTwoIntensity);
        out.actorAmbient = Ogre::ColourValue(env.actorAmbient.r, env.actorAmbient.g, env.actorAmbient.b, 1.0f);
        out.pbrAmbient = Ogre::ColourValue(env.pbrAmbient.r, env.pbrAmbient.g, env.pbrAmbient.b, 1.0f);
        out.skyDomeAmbient = env.skyDomeAmbient;

        // wind_control_params.xyz = (dir x, dir z, strength); default = the B shader initialiser (1, 0, 16).
        out.windControl = Ogre::Vector3(env.windDirection.x, env.windDirection.z, env.windStrength);

        // Fog exactly as given to SceneManager::setFog (after the height-fog fallback), OGRE's weight convention.
        switch (env.appliedFogMode)
        {
        case Ogre::FOG_EXP:    out.fogType = Ogre::Vector4(0, 1, 0, 0); break;
        case Ogre::FOG_EXP2:   out.fogType = Ogre::Vector4(0, 0, 1, 0); break;
        case Ogre::FOG_LINEAR: out.fogType = Ogre::Vector4(0, 0, 0, 1); break;
        default:               out.fogType = Ogre::Vector4(1, 0, 0, 0); break;   // FOG_NONE: factor 1 = unfogged
        }
        out.fogColour = env.appliedFogColour;
        const Real span = env.appliedFogEnd - env.appliedFogStart;
        out.fogParams = Ogre::Vector4(env.appliedFogDensity, env.appliedFogStart, env.appliedFogEnd,
                                      span != 0 ? 1.0f / span : 0.0f);

        out.valid |= Ogre::EnvironmentParamBlock::EP_ACTOR_LIGHTS | Ogre::EnvironmentParamBlock::EP_ACTOR_AMBIENT |
                     Ogre::EnvironmentParamBlock::EP_PBR_AMBIENT | Ogre::EnvironmentParamBlock::EP_SKYDOME |
                     Ogre::EnvironmentParamBlock::EP_WIND | Ogre::EnvironmentParamBlock::EP_FOG;
        // CYS-PARITY (d3d9-trace L6): FACT CY 3.71 Dali trace (SkySphere scene, keys actor_light_ambient 0.494118):
        // actor_ambient_params = surface ambient x SCENE ambient (0.372549) + emissive, while actor_lightone/two take the
        // key values (0.494118). EnScene scenes use the key ambient (erengu_DL: 0.439216 0.419608 0.509804 = key).
        // INF: CY's SkySphere path does not set the actor ambient. CYS_PARITY_ACTOR=0 keeps the key ambient.
        static const bool parity = []() {
            const char* v = getenv("CYS_PARITY_ACTOR");
            return !(v && v[0] == '0');
        }();
        if (parity && env.source == CYSEnvironment::SOURCE_SKYSPHERE)
            out.valid &= ~Ogre::EnvironmentParamBlock::EP_ACTOR_AMBIENT;
        return true;
    }
}
