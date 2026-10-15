#ifndef __CYS_ENVIRONMENTPROVIDER_H__
#define __CYS_ENVIRONMENTPROVIDER_H__

// CY-Source (scene agent): bridge from CYSEnvironment (EnScene / SkySphere EnvKeys at the current time of day)
// to the B auto constants of OgreMain, through the materials agent's Ogre::AutoParamExternalProvider
// (OgreAutoParamExternalProvider.h). Sets, when the scene has environment keys and the environment is enabled:
//   EP_ACTOR_LIGHTS  actor_lightone/lighttwo_params = (actor light rgb, intensity)    [B setActorLightOne/Two]
//   EP_ACTOR_AMBIENT actor_ambient_params source   = actor_light_ambient             [B setActAmbientLight]
//   EP_PBR_AMBIENT   derived_pbr_scene_colour src  = pbr_ambient                     [B setPbrAmbientLight]
//   EP_SKYDOME       skydome_ambient_color         = (skyDomeAmbientColor, strength) [B setSkyDomeAmbientColor]
//   EP_WIND          wind_control_params.xyz       = (dir x, dir z, strength): B initialiser (1, 0, 16) unless
//                                                    CYSEnvironmentManager::setWind was called (no B scene data)
//   EP_FOG           fog_type / fog_colour / fog_params = the fog given to SceneManager::setFog (EnvKey fog after
//                                                    the height-fog fallback), so shaders and fixed function agree
// The shadow and render-flag blocks belong to other systems (they can read CYSEnvironment::current()).

#include "CYSSceneCommon.h"

#include <OgreAutoParamExternalProvider.h>

namespace WX
{
    class CYSEnvironmentProvider : public Ogre::AutoParamExternalProvider
    {
    public:
        bool getEnvironmentParams(const Ogre::Camera* camera, Ogre::EnvironmentParamBlock& out) const;
    };
}

#endif // __CYS_ENVIRONMENTPROVIDER_H__
