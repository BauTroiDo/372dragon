/*
-----------------------------------------------------------------------------
CYS (CY-Source) addition to OGRE 1.2 "Dagon", 2026-09-12.

Engine-state provider for the B/Fairy auto constants. Systems outside OgreMain (WXCore scene
environment, cascaded shadows, post-processing) register an AutoParamExternalProvider and supply
the values of the shadow_*, fog_*, actor/PBR ambient, sky-dome, wind, isystem_userdata,
imodel_userdata.w and depth_camera_params auto constants without editing OGRE.

Contract
 - Every provider is asked once per rendered camera (SceneManager::_renderScene ->
   AutoParamDataSource::setCurrentCamera), also for shadow / render-texture cameras.
 - Each block arrives pre-filled with OGRE's current values (SceneManager setters or the
   defaults) and valid = 0. Set the fields you own plus their valid bits; fields whose bit stays
   clear keep OGRE's value. Providers are asked in registration order, so a later provider
   overrides an earlier one for the bits it sets. The return value only says "I set something".
 - Blocks are plain data (no STL), so they may cross DLL boundaries.
 - Register with Root::addAutoParamExternalProvider (or AutoParamDataSource::addExternalProvider),
   unregister before the provider is destroyed. At most 8 providers.

Shader semantics are those of client_GL Data\MaterialTemplates.zip (ShaderLib/CalcShadow.inc,
Fog.inc, Utility.inc, CalcLight.inc, CalcPos.inc).
-----------------------------------------------------------------------------
*/
#ifndef __CYS_AutoParamExternalProvider_H__
#define __CYS_AutoParamExternalProvider_H__

#include "OgrePrerequisites.h"
#include "OgreColourValue.h"
#include "OgreMatrix4.h"
#include "OgreVector3.h"
#include "OgreVector4.h"

namespace Ogre
{
    /** CYS: shadow state (cascaded shadow system).
        Model_* pixel shaders compiled with SHADOWMAP_TYPE = 1 (CSM) or 2 (simple) read the shadow
        map from sampler s5; the WXRender material system binds the texture named "CYS/Shadow/0"
        there. The map stores light-view linear depth (-z in light view space, world units) in .r;
        0 = no occluder. CSM: one atlas, cascades side by side, width = params.z * cascade count,
        height = params.z. */
    struct ShadowParamBlock
    {
        enum { MAX_CASCADES = 4 };
        enum ValidBits
        {
            SP_MATRICES = 1 << 0, ///< viewMatrix, projMatrix, viewProjMatrix
            SP_PARAMS   = 1 << 1, ///< params
            SP_CSM      = 1 << 2, ///< csmParams, csmProjScale, csmProjOffset
            SP_BIAS     = 1 << 3  ///< constantBias, normalBias
        };
        unsigned int valid;

        /// shadow_view_matrix: world -> light view (OGRE convention, p' = M * p). Both types.
        Matrix4 viewMatrix;
        /// shadow_proj_matrix: light view -> clip, SHADOWMAP_TYPE 2 only
        Matrix4 projMatrix;
        /// shadow_viewproj_matrix: projMatrix * viewMatrix (declared, not read by the templates)
        Matrix4 viewProjMatrix;
        /** shadow_param: x = shadow strength of non-PBR models (0..1), y = strength of PBR models,
            z = shadow map / cascade size in texels (PCF texel size, CSM border), w = unused */
        Vector4 params;
        /** shadow_csm_param: x = cascade count (1..4), y = 1 / cascade count, z = unused (blend band,
            commented out in B), w = shadow distance (fades out from 0.95 w to w from the camera) */
        Vector4 csmParams;
        /** shadow_csm_proj_scale / _offset, row i = cascade i: t = posInLightView * scale + offset must
            give x, y in [0,1] (u, v inside the cascade; v down) and z in [0,1] (cascade depth range);
            the first cascade whose t lies inside [0,1]^3 is used. For an orthographic cascade
            projection P (OGRE, clip z in -1..1): scale = (0.5 P00, -0.5 P11, 0.5 P22, 0),
            offset = (0.5 P03 + 0.5, -0.5 P13 + 0.5, 0.5 P23 + 0.5, 0). */
        Vector4 csmProjScale[MAX_CASCADES];
        Vector4 csmProjOffset[MAX_CASCADES];
        /// isystem_userdata.x: added to the stored depth before the compare (world units)
        Real constantBias;
        /// isystem_userdata.w: CSM receiver offset along the world normal * sin(angle to light 0)
        Real normalBias;
    };

    /** CYS: scene environment (WX scene / EnvKey state: sun, ambient, fog, sky, wind). */
    struct EnvironmentParamBlock
    {
        enum ValidBits
        {
            EP_ACTOR_LIGHTS  = 1 << 0, ///< actorLightOne, actorLightTwo
            EP_ACTOR_AMBIENT = 1 << 1, ///< actorAmbient
            EP_PBR_AMBIENT   = 1 << 2, ///< pbrAmbient
            EP_SKYDOME       = 1 << 3, ///< skyDomeAmbient
            EP_WIND          = 1 << 4, ///< windControl
            EP_FOG           = 1 << 5  ///< fogType, fogColour, fogParams
        };
        unsigned int valid;

        /** actor_lightone_params / actor_lighttwo_params: colour of lights 0 / 1 for actors
            (shaders: rgb * a, blended with the scene lights by imodel_userdata.x). Without the bit:
            SceneManager::setActorLightOne/Two, else the renderable's lights 0 / 1 (a = power). */
        ColourValue actorLightOne;
        ColourValue actorLightTwo;
        /// actor_ambient_params = surface ambient * actorAmbient + surface emissive (a = diffuse alpha)
        ColourValue actorAmbient;
        /// derived_pbr_scene_colour = surface ambient * pbrAmbient + surface emissive (a = diffuse alpha)
        ColourValue pbrAmbient;
        /// skydome_ambient_color
        Vector4 skyDomeAmbient;
        /// wind_control_params.xyz = (wind dir x, wind dir z, strength); .w = time_0_x(300) from OGRE
        Vector3 windControl;
        /** fog_type = weights (none, exp, exp2, linear): Fog.inc factor f = x + y exp(-d density) +
            z exp(-(d density)^2) + w saturate((end - d) / (end - start)), 1 = unfogged */
        Vector4 fogType;
        /// fog_colour
        ColourValue fogColour;
        /// fog_params = (exp density, linear start, linear end, 1 / (end - start))
        Vector4 fogParams;
    };

    /** CYS: render-wide flags (post-processing / HDR / depth). */
    struct RenderFlagsParamBlock
    {
        enum ValidBits
        {
            RF_BRIGHTNESS   = 1 << 0, ///< brightness
            RF_COLOUR_SPACE = 1 << 1, ///< linearColourSpace, colourGreaterOne
            RF_DEPTH_CAMERA = 1 << 2  ///< depthCameraParams
        };
        unsigned int valid;

        /// imodel_userdata.w (Model_Emissive_ps shows the emissive map when brightness <= 0.4)
        Real brightness;
        /// isystem_userdata.y: 1 = shaders convert textures to linear space and back (Utility.inc)
        int linearColourSpace;
        /// isystem_userdata.z: 1 = lighting is not clamped to 1 (HDR) and the shadow mask ignores the sun brightness
        int colourGreaterOne;
        /// depth_camera_params (not read by the shipped templates; passed through unchanged)
        Vector4 depthCameraParams;
    };

    /** CYS: interface of an engine-state provider (see the contract at the top of this file).
        Override only the blocks you own. */
    class _OgreExport AutoParamExternalProvider
    {
    public:
        virtual ~AutoParamExternalProvider() {}
        virtual bool getShadowParams(const Camera* camera, ShadowParamBlock& out) const
        { (void)camera; (void)out; return false; }
        virtual bool getEnvironmentParams(const Camera* camera, EnvironmentParamBlock& out) const
        { (void)camera; (void)out; return false; }
        virtual bool getRenderFlagsParams(const Camera* camera, RenderFlagsParamBlock& out) const
        { (void)camera; (void)out; return false; }
    };
}

#endif
