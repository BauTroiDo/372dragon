#ifndef __CYS_SKYSPHEREDATA_H__
#define __CYS_SKYSPHEREDATA_H__

// CY-Source (scene agent): document model of the B ".skysphere" file (305 files in client_GL), referenced by the
// <SkySphere enabled filename objectname/> element of a .Scene. Tree (05 §3, scene_xml_inventory.tsv):
// SkySphere -> SkyHeight, EffectLOD, ParticleLOD, SkySunshine, SkyMoon/DateConfig/AlphaKeyList/KeyAlpha, SkyStar,
// SkySphereLayers/SkyLayer, SkyWeathers(current_weather)/Weather(name) -> SkyEnviromentList/EnvKey,
// SkySphereTextureGroups/TextureGroup(<layer>_texture, <layer>_wrap, AlphaKeyList), SkyEffectParams/Effect/Parameter.
// B reader: Fairy::SkySphereObject::loadFrom (FUN_1800f1120 -> FUN_1800e9980). Times in this file are day
// fractions (0..1); they are converted to hours for the EnvKeys and kept as fractions for the alpha curves.

#include "CYSEnvKey.h"

class TiXmlElement;

namespace WX
{
    struct CYSSkyAlphaKey
    {
        Real time;      ///< day fraction 0..1
        Real alpha;
    };

    /// KeyAlpha curve over the day (linear, wrapping).
    struct CYSSkyAlphaCurve
    {
        std::vector<CYSSkyAlphaKey> keys;
        Real sample(Real dayFraction) const;
        void add(const CYSSkyAlphaKey& key);
    };

    struct CYSSkyMoonDate
    {
        int date;               ///< day of the lunar month 0..30
        String texture;
        CYSSkyAlphaCurve alpha;
    };

    enum CYSSkyLayerId
    {
        CYS_SKY_BACKGROUND,
        CYS_SKY_FAR_CLOUD,
        CYS_SKY_FOG,
        CYS_SKY_MOUNTAIN,
        CYS_SKY_NEAR_CLOUD,
        CYS_SKY_LAYER_COUNT
    };

    /// Layer names as written in the files ("background", "far_cloud", "fog", "mountain", "near_cloud").
    const char* cysSkyLayerName(int id);
    int cysSkyLayerId(const String& name);      ///< -1 when unknown

    struct CYSSkyLayerDef
    {
        String name;
        int id;                 ///< CYSSkyLayerId or -1
        Real pitchStart;        ///< radians from the zenith (0 = straight up, pi/2 = horizon)
        Real pitchEnd;
        Real distance;
        Real rotateSpeed;       ///< radians per second (INF)
        int textureCount;       ///< how many texture groups are blended on this layer (0..3)
    };

    /// One set of layer textures with an alpha curve; a layer blends up to three groups (BLEND_TEXTURE_NUM).
    struct CYSSkyTextureGroup
    {
        String textures[CYS_SKY_LAYER_COUNT];
        Real wraps[CYS_SKY_LAYER_COUNT];        ///< horizontal repeat count
        bool has[CYS_SKY_LAYER_COUNT];
        CYSSkyAlphaCurve alpha;
        CYSSkyTextureGroup(void);
    };

    struct CYSSkyEffectParam
    {
        String name, value;
    };

    struct CYSSkyEffect
    {
        String name;            ///< "Thunder" | "WeatherParticle"
        std::vector<CYSSkyEffectParam> params;
    };

    struct CYSSkyWeather
    {
        String name;
        CYSEnvKeyTrack keys;
        std::vector<CYSSkyTextureGroup> textureGroups;
        bool hasEffectParams;
        bool showMoon, showStar, showSunFlares, showSunshine;
        std::vector<CYSSkyEffect> effects;
        CYSSkyWeather(void) : hasEffectParams(false), showMoon(false), showStar(false), showSunFlares(false), showSunshine(false) {}
    };

    struct CYSSkySphereData
    {
        String fileName;

        bool enableFixedHeight;
        Real fixedHeight;
        bool hasEffectLOD, hasParticleLOD;
        Real effectLODMin, effectLODMax, particleLODMin, particleLODMax;

        struct Sunshine
        {
            bool present;
            Real distance;
            String textureSunrise, textureSunset;
            Ogre::Vector3 rotateAxis;
            Real rotateAngle;       ///< degrees
            Real startTime;         ///< day fraction
            Real duration;          ///< day fraction
        } sunshine;

        struct Moon
        {
            bool present;
            Real distance;
            Ogre::Vector3 direction;
            std::vector<CYSSkyMoonDate> dates;
        } moon;

        struct Star
        {
            bool present;
            int count;
            Real size, radius, intensity, flickerSpeed;
            Ogre::ColourValue startColour, endColour;
        } star;

        std::vector<CYSSkyLayerDef> layers;
        String currentWeather;
        std::vector<CYSSkyWeather> weathers;

        CYSSkySphereData(void) { clear(); }
        void clear(void);
        /// Weather by name; falls back to current_weather, then to the first one. NULL when there is none.
        const CYSSkyWeather* findWeather(const String& name) const;
    };

    namespace CYSScene
    {
        bool parseSkySphere(const TiXmlElement* root, const String& file, CYSSkySphereData& out, String* error);
        bool loadSkySphere(const String& name, const String& group, CYSSkySphereData& out, String* error);
    }
}

#endif // __CYS_SKYSPHEREDATA_H__
