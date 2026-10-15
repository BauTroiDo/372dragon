#ifndef __CYS_SHADOW_CONFIG_H__
#define __CYS_SHADOW_CONFIG_H__

// CY-Source (shadow agent): configuration of the cascaded shadow maps, Docs\specs\render\03-shadows.md §2 and §5.
// Read once at start-up (System.cfg keys Gfx_Shadow*, test overrides CYS_SHADOW*). The atlas is allocated from it
// once and never per scene (Docs\08-BAY-VA-QUY-TAC_vi.md §3.7: B allocates a 4096^2 RT + cascades on every load).
//
// Keys (case-insensitive; unknown keys are ignored):
//   Gfx_Shadow            0 off | 1 simple (one map, SHADOWMAP_TYPE 2) | 2 cascaded (SHADOWMAP_TYPE 1)   default 2
//   Gfx_ShadowSize        texels per cascade tile = shadow_param.z, 256..4096; atlas = size*cascades x size 4096
//   Gfx_ShadowCascades    1..4                                                                            4
//   Gfx_ShadowDistance    shadow range along the view direction, world units (cm)                         5000
//   Gfx_ShadowSplitLambda 0 = linear .. 1 = logarithmic ("practical" split scheme)                        0.75
//   Gfx_ShadowSplits      a,b,c,d = explicit far distance per cascade (overrides lambda and distance)
//   Gfx_ShadowNear        start of cascade 0 (0 = camera near clip)                                       0
//   Gfx_ShadowBias        const,normal in world units, or auto (derived from the texel size)             auto
//   Gfx_ShadowSoftness    PCF radius in texels for CYSShadowLib.inc receivers (B CalcShadow.inc = 1)      2
//   Gfx_ShadowStrength    shadow_param.x when the scene has no EnvKey shadow_strength                     1.0
//   Gfx_ShadowPbrStrength shadow_param.y (EnvKey pbr_shadow_strength)                                      1.0
//   Gfx_ShadowBackoff     caster range kept towards the light above each cascade (B +0x38 = 8000)         8000
//   Gfx_ShadowBlend       cascade blend band as a fraction of a tile (shadow_csm_param.z)                 0.1
//   Gfx_ShadowFit         stable (bounding sphere + texel snapping) | tight (per-frame AABB, like B)      stable
//   Gfx_ShadowDebug       1 = atlas strip over the main viewport                                          0

#include <OgrePrerequisites.h>
#include <OgreString.h>

#include <map>
#include <vector>

namespace WX
{
    struct CYSShadowConfig
    {
        enum Mode
        {
            MODE_OFF = 0,
            MODE_SIMPLE = 1,    ///< one focused map, receivers compiled with SHADOWMAP_TYPE 2
            MODE_CSM = 2,       ///< cascades side by side in one atlas, SHADOWMAP_TYPE 1
        };
        enum Fit
        {
            FIT_STABLE = 0,     ///< bounding sphere per slice + texel snapping: no shimmering when the camera moves
            FIT_TIGHT = 1,      ///< per-frame light-space AABB of the slice (B's approach), for comparisons
        };

        Mode mode;
        unsigned int mapSize;           ///< texels per cascade tile
        unsigned int cascadeCount;
        Ogre::Real maxDistance;
        Ogre::Real splitLambda;
        std::vector<Ogre::Real> splits;
        Ogre::Real nearDistance;
        Ogre::Real constBias;           ///< isystem_userdata.x; negative = auto
        Ogre::Real normalBias;          ///< isystem_userdata.w; negative = auto
        Ogre::Real autoConstBias;       ///< auto biases in texels of the coarsest cascade
        Ogre::Real autoNormalBias;
        int softness;
        Ogre::Real strength;
        Ogre::Real pbrStrength;
        bool useEnvironmentStrength;    ///< EnvKey shadow_strength / pbr_shadow_strength win when a scene sets them
        Ogre::Real backoff;
        Ogre::Real blendBand;
        Fit fit;
        Ogre::Real lightEpsilonDeg;     ///< the light direction used by the cascades follows the sun in steps
        Ogre::Real minLightElevationDeg;///< sun elevations below this are clamped (endless shadows at dusk)
        unsigned char casterQueueMin;   ///< render queue groups whose entities cast
        unsigned char casterQueueMax;
        bool alphaTestCasters;          ///< alpha-rejected passes cast through their texture (hair, leaves)
        bool debugView;

        CYSShadowConfig(void);

        /// Applies Gfx_Shadow* keys, then validate(). Returns the number of keys used.
        size_t apply(const std::map<Ogre::String, Ogre::String>& keyValues);
        /// Reads "key=value" lines (System.cfg style, '#', ';' and '//' comments); false if unreadable.
        bool applyFile(const Ogre::String& path);
        /// Test overrides: CYS_SHADOW, CYS_SHADOW_SIZE, CYS_SHADOW_CASCADES, CYS_SHADOW_DISTANCE,
        /// CYS_SHADOW_SOFTNESS, CYS_SHADOW_FIT, CYS_SHADOW_BIAS (same values as the Gfx_ keys).
        size_t applyEnvironment(void);
        /// Clamps every field to its valid range.
        void validate(void);
        /// One line for the log.
        Ogre::String describe(void) const;

        /// SHADOWMAP_TYPE the receivers must be compiled with (ParamNamed.inc: 0 none, 1 CSM, 2 simple).
        int shaderType(void) const;
        /// Tiles in the atlas.
        unsigned int effectiveCascades(void) const { return mode == MODE_CSM ? cascadeCount : 1; }
    };
}

#endif // __CYS_SHADOW_CONFIG_H__
