#ifndef __CYS_ENVKEY_H__
#define __CYS_ENVKEY_H__

// CY-Source (scene agent): time-of-day environment keys ("EnvKey") of .EnScene (<LightAndFog>) and .skysphere
// (<SkyEnviromentList>) files, and the height-fog parameter block shared with the per-scene .hfog file.
// Field list, defaults and fix-ups follow the B reader (Render.dll FUN_1801f4b70, 05 §4); the application to the
// engine follows FUN_180182550 (see CYSEnvironment.h).

#include "CYSSceneCommon.h"

class TiXmlElement;

namespace WX
{
    /// Height-fog parameters in the order of the B HeightFog post filter (02 §2, 05 §2):
    /// FogColor, HFogDensity, HFogHeight, HFogHeightFalloff, HFogPowFactor, DFogDensity, DFogHeightFalloff,
    /// DFogStartDistance, InscatteringFactor, DirectionalInscatteringColor.
    struct CYSHeightFogParams
    {
        Ogre::ColourValue fogColour;            ///< FogColor (RGBA)
        Real hDensity;                          ///< HFogDensity
        Real hHeight;                           ///< HFogHeight (world y where the height fog starts to thin out)
        Real hHeightFalloff;                    ///< HFogHeightFalloff (per 1000 units)
        Real hPowFactor;                        ///< HFogPowFactor
        Real dDensity;                          ///< DFogDensity
        Real dHeightFalloff;                    ///< DFogHeightFalloff (distance falloff, per 1000 units)
        Real dStartDistance;                    ///< DFogStartDistance
        Real inscatteringFactor;                ///< InscatteringFactor (exponent of the sun in-scattering lobe)
        Ogre::ColourValue dirInscatteringColour;///< DirectionalInscatteringColor (RGBA)

        /// Defaults of the B .hfog reader when the file is absent (05 §2).
        CYSHeightFogParams(void);
        /// All zero (EnvKey height_fog_param "0 0 0 0|0 0 0 0|0|0|0|0|0|0|0|0").
        static CYSHeightFogParams zero(void);

        /// Shader packing of HeightFog_ps.hlsl: HFogParams = (HFogDensity, HFogHeight, HFogHeightFalloff,
        /// HFogPowFactor), DFogParams = (DFogDensity, DFogHeightFalloff, DFogStartDistance, 0),
        /// FogColorParams = FogColor, DirectionalInscatteringColor = (rgb, InscatteringFactor) [w: INF].
        Ogre::Vector4 getHFogParams(void) const { return Ogre::Vector4(hDensity, hHeight, hHeightFalloff, hPowFactor); }
        Ogre::Vector4 getDFogParams(void) const { return Ogre::Vector4(dDensity, dHeightFalloff, dStartDistance, 0); }
        Ogre::Vector4 getFogColorParams(void) const { return Ogre::Vector4(fogColour.r, fogColour.g, fogColour.b, fogColour.a); }
        Ogre::Vector4 getDirectionalInscatteringColor(void) const
        {
            return Ogre::Vector4(dirInscatteringColour.r, dirInscatteringColour.g, dirInscatteringColour.b, inscatteringFactor);
        }

        /// Fog amount of the HeightFog pass (0..1, without the in-scattering colour choice) for a receiver at
        /// world height `y` and `distance` from the camera (HeightFog_ps.hlsl, evaluated on the CPU).
        Real evaluate(Real y, Real distance) const;

        static CYSHeightFogParams lerp(const CYSHeightFogParams& a, const CYSHeightFogParams& b, Real t);
    };

    /// Parses EnvKey height_fog_param: "r g b a|r g b a|HD|HH|HF|HP|DD|DF|DS|IF" (10 '|' fields: FogColor,
    /// DirectionalInscatteringColor, then the 8 scalars in .hfog order - INF order, matches the data ranges).
    /// Returns false and leaves `out` untouched for malformed text.
    bool cysParseHeightFogParam(const String& text, CYSHeightFogParams& out);
    String cysFormatHeightFogParam(const CYSHeightFogParams& p);

    /// One environment key. Times are hours in [0, 24).
    struct CYSEnvKey
    {
        Real time;

        Ogre::ColourValue ambient;              ///< -> Enviroment "ambient" (SceneManager ambient)
        Ogre::ColourValue pbrAmbient;           ///< -> SceneManager::setPbrAmbientLight (B)
        Real shadowStrength;                    ///< -> shadow config +0x44 (shadow_param.x)
        Real pbrShadowStrength;                 ///< -> shadow config +0x48 (shadow_param.y)
        Ogre::ColourValue fog;                  ///< -> Enviroment "fog.colour"
        Real fogNear;                           ///< -> Enviroment "fog.linear start"
        Real fogFar;                            ///< -> Enviroment "fog.linear end"
        Ogre::ColourValue skyFog;               ///< SkySphere only: colour of the sky layers' fog band
        bool hasSkyFog;

        Ogre::ColourValue lightOne;             ///< -> #FairyMainLightOne "diffuse"
        Ogre::ColourValue lightOneSpecular;     ///< -> #FairyMainLightOne "specular"
        Ogre::Vector3 lightOneDirection;        ///< -> "direction" when not (0,0,0)
        Real lightOneIntensity;                 ///< -> "intensity"
        Ogre::ColourValue lightTwo;
        Ogre::ColourValue lightTwoSpecular;
        Ogre::Vector3 lightTwoDirection;
        Real lightTwoIntensity;

        Real fakePointLightIntensity;           ///< global FakeLight multiplier (B DAT_1803a3b00)
        Ogre::Vector3 warmColour;               ///< grading filters, inactive in B (02 §2)
        Ogre::Vector3 coldColour;
        Ogre::Vector3 enhanceContrast;
        Ogre::Vector3 overlayImage;
        Ogre::Vector2 radialBlur;
        Real lightSpecularIntensity;

        Ogre::ColourValue actorLightOne;        ///< -> SceneManager::setActorLightOne (B); ZERO in file = light one
        Real actorLightOneIntensity;
        Ogre::ColourValue actorLightTwo;        ///< -> setActorLightTwo; ZERO in file = light two
        Real actorLightTwoIntensity;
        Ogre::ColourValue actorAmbient;         ///< -> setActAmbientLight; ZERO in file = ambient
        Ogre::ColourValue selectActorLight;     ///< renderer "selected actor" light colour (B renderer +0x2f4)

        bool heightFogEnabled;                  ///< HeightFog post filter on/off
        CYSHeightFogParams heightFog;           ///< HeightFog parameters for this key

        Ogre::Vector3 skyDomeAmbientColour;     ///< -> setSkyDomeAmbientColor(Vector4(rgb, strength)); ZERO = white
        Real skyDomeAmbientStrength;            ///< 0 in file = 1

        CYSEnvKey(void);

        /// Component-wise interpolation (colours/vectors/scalars linear; the height-fog switch and its
        /// parameters follow the enabled key when only one side is enabled).
        static CYSEnvKey lerp(const CYSEnvKey& a, const CYSEnvKey& b, Real t);
    };

    enum CYSEnvKeySource
    {
        CYS_ENVKEY_ENSCENE,     ///< .EnScene <EnvKey>: time in hours
        CYS_ENVKEY_SKYSPHERE,   ///< .skysphere <EnvKey>: time as a fraction of the day, plus sky_fog
    };

    /// Parses one <EnvKey>. `timeScale` converts the file's time unit to hours (1 or 24).
    /// Unknown attributes are recorded in CYSSceneStats under "<kind> <path>@<attr>".
    CYSEnvKey cysParseEnvKey(const TiXmlElement* e, CYSEnvKeySource source, Real timeScale,
                             const String& kind, const String& path, const String& file);

    /// Keys sorted by time; sampled with linear interpolation that wraps around midnight.
    class CYSEnvKeyTrack
    {
    public:
        typedef std::vector<CYSEnvKey> Keys;

        void clear(void) { mKeys.clear(); }
        void add(const CYSEnvKey& key);
        bool empty(void) const { return mKeys.empty(); }
        size_t size(void) const { return mKeys.size(); }
        const Keys& getKeys(void) const { return mKeys; }

        CYSEnvKey sample(Real hours) const;

    private:
        Keys mKeys;
    };
}

#endif // __CYS_ENVKEY_H__
