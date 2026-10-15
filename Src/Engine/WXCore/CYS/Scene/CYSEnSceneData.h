#ifndef __CYS_ENSCENEDATA_H__
#define __CYS_ENSCENEDATA_H__

// CY-Source (scene agent): document model of the B ".EnScene" environment file (197 files in client_GL):
// EnScene(version) -> EnSky | EnRegionComposite -> EnRegion(name, maxAffectDistance) -> RegionGroups/polygon/Point
// + EnSky; EnSky -> SkyDome, SkyClouds/SkyCloudsLayer, SkyRingClouds/RingCloudsLayer, Star, Moon, Sun, Ocean,
// LightAndFog/EnvKey. Tree and value ranges: 05 §4, Tools/re/out/scene_xml_inventory.tsv. B reader:
// Fairy::EnSceneObject::_loadImpl (FUN_180147bd0): root "EnScene", attribute version="1.0", then one child node.

#include "CYSEnvKey.h"

class TiXmlElement;

namespace WX
{
    /// Key of a cloud layer's <TimeNodesInfo> (time in hours). Shader mapping (EnScene.hlsl En_cloudp /
    /// En_ringcloudp): control = (fog or fogblend, fadeRange, ambientBlend, alpha).
    struct CYSEnTimeNode
    {
        Real time;
        Real fog;               ///< SkyCloudsLayer "fog" (-1..1): added to the fog-amount texture (control.x)
        Real fogBlend;          ///< RingCloudsLayer "fogblend" (-1..1): same role (control.x)
        Real alpha;             ///< layer opacity (control.w)
        Real ambientBlend;      ///< how much the ambient colour tints the layer (control.z)
        Real cloudSpeed;        ///< SkyCloudsLayer: texture v scroll speed (windSpeed)
        Real rollSpeed;         ///< RingCloudsLayer: rotation speed around the vertical axis (INF)
        Real verticalSpeed;     ///< RingCloudsLayer: texture v scroll speed (offsetParam.y)
        Real fadeRange;         ///< RingCloudsLayer: vertical alpha fade band (control.y)

        CYSEnTimeNode(void);
        static CYSEnTimeNode lerp(const CYSEnTimeNode& a, const CYSEnTimeNode& b, Real t);
    };

    /// SkyCloudsLayer (dome clouds, mesh enskycloud*.mesh) or RingCloudsLayer (horizon ring, ringcloud.mesh).
    struct CYSEnCloudLayer
    {
        bool ring;
        String name;
        int layer;                  ///< draw order among the sky elements
        bool turnoverMesh;          ///< mesh flipped upside down (cloud sea below the viewer)
        String meshName;
        String textureName;         ///< GBK resource name

        Real skyCloudHeight;        ///< SkyCloudsLayer: vertical offset in mesh units
        Real rotAngle;              ///< SkyCloudsLayer: yaw in radians
        Ogre::Vector4 textureTile;  ///< SkyCloudsLayer: (u tile, v tile, -, -)

        Real cloudHeight;           ///< RingCloudsLayer: vertical offset
        Real cloudScale;            ///< RingCloudsLayer: size factor
        Real textureRepeat;         ///< RingCloudsLayer: u repeat around the ring
        Real cloudOffset;           ///< RingCloudsLayer: yaw offset in degrees (INF)
        Real parallax;              ///< RingCloudsLayer: camera-height parallax (offsetParam.z)

        Real scatteringStrength, scatteringPower, rimStrength, rimPower, rimDetectPower, rimDetectWidth;

        std::vector<CYSEnTimeNode> timeNodes;   ///< sorted by time

        CYSEnCloudLayer(void);
        CYSEnTimeNode sample(Real hours) const;
        /// EnScene.hlsl rimParam = (rimStrength, rimPower, rimDetectPower, rimDetectWidth).
        Ogre::Vector4 getRimParam(void) const { return Ogre::Vector4(rimStrength, rimPower, rimDetectPower, rimDetectWidth); }
    };

    /// <SkyDome>: `texture` is a sky-colour table sampled at (time of day / 24, 1 - view elevation)
    /// (EnScene.hlsl En_sky_dome_v/p: tc1 = (EN_DOME_PARAM1.x, saturate(1 - normalize(pos).y))).
    struct CYSEnSkyDome
    {
        bool present;
        String texture;
        Real height;                ///< "hight": vertical shift of the dome (EN_DOME_PARAM1.y)
        Real mieAmount;             ///< EN_DOME_PARAM1.z
        Real vertexHeightEffect;    ///< EN_DOME_PARAM2.y
        Real sunHeightEffect;       ///< EN_DOME_PARAM2.z
        Real power;                 ///< EN_DOME_PARAM2.w
        CYSEnSkyDome(void);
    };

    /// <Sun> or <Moon>.
    struct CYSEnCelestial
    {
        bool present;
        bool enable;
        String texture;             ///< sun_tex_name / moon_tex_name
        Real scale;
        Real orient;                ///< sunOrient / moonOrient (degrees)
        Real angle;                 ///< sunAngle / moonAngle (degrees)
        Real upTime, downTime;      ///< hours
        bool fixed;                 ///< sunfix / moonfix
        int layer;
        bool hasLayer;
        // Sun only
        bool useSunFlare;
        String flareTexture;
        Real intensityStep;
        String lensFlareSettings;
        bool useLensFlare;

        CYSEnCelestial(void);
    };

    struct CYSEnStar
    {
        bool present;
        bool enable;
        int count;
        Real radius, intensity, size, flickerSpeed;
        Ogre::ColourValue startColour, endColour;
        bool fixed;
        CYSEnStar(void);
    };

    struct CYSEnSky
    {
        bool present;
        CYSEnSkyDome dome;
        std::vector<CYSEnCloudLayer> clouds;
        std::vector<CYSEnCloudLayer> ringClouds;
        CYSEnStar star;
        CYSEnCelestial moon;
        CYSEnCelestial sun;
        bool oceanPresent;
        bool oceanEnable;
        int oceanVisible;
        CYSEnvKeyTrack keys;        ///< <LightAndFog><EnvKey>
        std::vector<String> effects;///< CY 3.71 <Effects><Effect effect_name=".."/>: all.effect names (not played yet)

        CYSEnSky(void) : present(false), oceanPresent(false), oceanEnable(false), oceanVisible(0) {}
    };

    struct CYSEnRegion
    {
        typedef std::vector<Ogre::Vector2> Polygon;     ///< (x, z) world coordinates

        String name;
        Real maxAffectDistance;
        std::vector<Polygon> polygons;
        CYSEnSky sky;

        CYSEnRegion(void) : maxAffectDistance(0) {}
        /// 1 inside a polygon, fading linearly to 0 at maxAffectDistance outside it; 0 without polygons (INF).
        Real weightAt(Real x, Real z) const;
    };

    struct CYSEnSceneData
    {
        String fileName;
        String version;
        CYSEnSky sky;                           ///< <EnScene><EnSky>
        std::vector<CYSEnRegion> regions;       ///< <EnScene><EnRegionComposite><EnRegion>
        bool timesAsDayFraction;                ///< see CYSScene::parseEnScene

        CYSEnSceneData(void) : timesAsDayFraction(false) {}
        void clear(void);
        /// <EnSky>; else the region without polygons (42 files use one called "backgroud"); else region 0.
        const CYSEnSky* getBaseSky(void) const;
        /// Regions that have polygons (blended by position).
        size_t getNumPositionalRegions(void) const;
    };

    namespace CYSScene
    {
        /// Parses a document root. EnvKey times are hours as in B; a file whose base keys are all <= 1 with
        /// more than one key (cy4_taohuadao.EnScene, converted from a .skysphere) is read as day fractions
        /// (CY-Source deviation, logged). Unknown elements/attributes go to CYSSceneStats ("EnScene ...").
        bool parseEnScene(const TiXmlElement* root, const String& file, CYSEnSceneData& out, String* error);
        bool loadEnScene(const String& name, const String& group, CYSEnSceneData& out, String* error);
    }
}

#endif // __CYS_ENSCENEDATA_H__
