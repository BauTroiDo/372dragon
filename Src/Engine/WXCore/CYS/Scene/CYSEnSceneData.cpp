// CY-Source (scene agent): see CYSEnSceneData.h.
#include "CYSEnSceneData.h"
#include "CYSXml.h"

#define TIXML_USE_STL
#include <tinyxml.h>

#include <algorithm>
#include <cmath>
#include <cstring>

namespace WX
{
    using namespace CYSScene;

    //////////////////////////////////////////////////////////////////////////
    CYSEnTimeNode::CYSEnTimeNode(void)
        : time(0), fog(0), fogBlend(0), alpha(1), ambientBlend(0), cloudSpeed(0), rollSpeed(0), verticalSpeed(0)
        , fadeRange(0)
    {
    }
    //-----------------------------------------------------------------------
    CYSEnTimeNode CYSEnTimeNode::lerp(const CYSEnTimeNode& a, const CYSEnTimeNode& b, Real t)
    {
        using CYSScene::lerp;
        CYSEnTimeNode r;
        r.time = lerp(a.time, b.time, t);
        r.fog = lerp(a.fog, b.fog, t);
        r.fogBlend = lerp(a.fogBlend, b.fogBlend, t);
        r.alpha = lerp(a.alpha, b.alpha, t);
        r.ambientBlend = lerp(a.ambientBlend, b.ambientBlend, t);
        r.cloudSpeed = lerp(a.cloudSpeed, b.cloudSpeed, t);
        r.rollSpeed = lerp(a.rollSpeed, b.rollSpeed, t);
        r.verticalSpeed = lerp(a.verticalSpeed, b.verticalSpeed, t);
        r.fadeRange = lerp(a.fadeRange, b.fadeRange, t);
        return r;
    }
    //-----------------------------------------------------------------------
    CYSEnCloudLayer::CYSEnCloudLayer(void)
        : ring(false), layer(0), turnoverMesh(false)
        , skyCloudHeight(0), rotAngle(0), textureTile(1, 1, 0, 0)
        , cloudHeight(0), cloudScale(1), textureRepeat(1), cloudOffset(0), parallax(0)
        , scatteringStrength(0), scatteringPower(1), rimStrength(0), rimPower(1), rimDetectPower(1), rimDetectWidth(0)
    {
    }
    //-----------------------------------------------------------------------
    CYSEnTimeNode CYSEnCloudLayer::sample(Real hours) const
    {
        if (timeNodes.empty())
            return CYSEnTimeNode();
        if (timeNodes.size() == 1)
            return timeNodes.front();
        const Real h = wrapHours(hours);
        size_t i = 0;
        while (i < timeNodes.size() && timeNodes[i].time <= h)
            ++i;
        const CYSEnTimeNode* a;
        const CYSEnTimeNode* b;
        Real f;
        if (i == 0 || i == timeNodes.size())
        {
            a = &timeNodes.back();
            b = &timeNodes.front();
            const Real span = b->time + 24.0f - a->time;
            const Real since = (i == 0) ? h + 24.0f - a->time : h - a->time;
            f = span > 1e-6f ? since / span : 0.0f;
        }
        else
        {
            a = &timeNodes[i - 1];
            b = &timeNodes[i];
            const Real span = b->time - a->time;
            f = span > 1e-6f ? (h - a->time) / span : 0.0f;
        }
        return CYSEnTimeNode::lerp(*a, *b, saturate(f));
    }
    //-----------------------------------------------------------------------
    CYSEnSkyDome::CYSEnSkyDome(void)
        : present(false), height(0), mieAmount(0.01f), vertexHeightEffect(1), sunHeightEffect(1), power(1)
    {
    }
    //-----------------------------------------------------------------------
    CYSEnCelestial::CYSEnCelestial(void)
        : present(false), enable(false), scale(10), orient(0), angle(50), upTime(6), downTime(18), fixed(false)
        , layer(0), hasLayer(false), useSunFlare(false), intensityStep(0.1f), useLensFlare(false)
    {
    }
    //-----------------------------------------------------------------------
    CYSEnStar::CYSEnStar(void)
        : present(false), enable(false), count(2000), radius(10000), intensity(1), size(10), flickerSpeed(0.2f)
        , startColour(0.5f, 0.5f, 0.5f, 0.5f), endColour(1, 1, 1, 1), fixed(false)
    {
    }
    //-----------------------------------------------------------------------
    namespace
    {
        bool pointInPolygon(const CYSEnRegion::Polygon& poly, Real x, Real z)
        {
            bool inside = false;
            const size_t n = poly.size();
            for (size_t i = 0, j = n - 1; i < n; j = i++)
            {
                const Ogre::Vector2& a = poly[i];
                const Ogre::Vector2& b = poly[j];
                if (((a.y > z) != (b.y > z)) && (x < (b.x - a.x) * (z - a.y) / (b.y - a.y) + a.x))
                    inside = !inside;
            }
            return inside;
        }

        Real distanceToPolygon(const CYSEnRegion::Polygon& poly, Real x, Real z)
        {
            Real best = 1e30f;
            const size_t n = poly.size();
            const Ogre::Vector2 p(x, z);
            for (size_t i = 0; i < n; ++i)
            {
                const Ogre::Vector2& a = poly[i];
                const Ogre::Vector2& b = poly[(i + 1) % n];
                const Ogre::Vector2 ab = b - a;
                const Real len2 = ab.squaredLength();
                Real t = len2 > 0 ? (p - a).dotProduct(ab) / len2 : 0;
                t = saturate(t);
                const Ogre::Vector2 q = a + ab * t;
                best = std::min(best, (p - q).length());
            }
            return best;
        }
    }
    //-----------------------------------------------------------------------
    Real CYSEnRegion::weightAt(Real x, Real z) const
    {
        Real weight = 0;
        for (size_t i = 0; i < polygons.size(); ++i)
        {
            const Polygon& poly = polygons[i];
            if (poly.size() < 3)
                continue;
            if (pointInPolygon(poly, x, z))
                return 1.0f;
            if (maxAffectDistance > 0)
                weight = std::max(weight, 1.0f - distanceToPolygon(poly, x, z) / maxAffectDistance);
        }
        return saturate(weight);
    }
    //-----------------------------------------------------------------------
    void CYSEnSceneData::clear(void)
    {
        fileName.clear();
        version.clear();
        sky = CYSEnSky();
        regions.clear();
        timesAsDayFraction = false;
    }
    //-----------------------------------------------------------------------
    const CYSEnSky* CYSEnSceneData::getBaseSky(void) const
    {
        if (sky.present)
            return &sky;
        for (size_t i = 0; i < regions.size(); ++i)
        {
            if (regions[i].polygons.empty() && regions[i].sky.present)
                return &regions[i].sky;
        }
        for (size_t i = 0; i < regions.size(); ++i)
        {
            if (regions[i].sky.present)
                return &regions[i].sky;
        }
        return NULL;
    }
    //-----------------------------------------------------------------------
    size_t CYSEnSceneData::getNumPositionalRegions(void) const
    {
        size_t n = 0;
        for (size_t i = 0; i < regions.size(); ++i)
        {
            if (!regions[i].polygons.empty())
                ++n;
        }
        return n;
    }

    //////////////////////////////////////////////////////////////////////////
    // Parser
    //////////////////////////////////////////////////////////////////////////
    namespace
    {
        const char* const kKind = "EnScene";

        const char* const kRootAttrs[] = { "version", NULL };
        const char* const kRootChildren[] = { "EnSky", "EnRegionComposite", NULL };
        const char* const kCompositeChildren[] = { "EnRegion", NULL };
        const char* const kRegionAttrs[] = { "name", "maxAffectDistance", NULL };
        const char* const kRegionChildren[] = { "RegionGroups", "EnSky", NULL };
        const char* const kRegionGroupsChildren[] = { "polygon", NULL };
        const char* const kPolygonChildren[] = { "Point", NULL };
        // "Effects": CY 3.71 EnScene (CanonicalCY, 18 regions) - <Effects><Effect effect_name="..."/></Effects>,
        // an all.effect effect played with the region's sky (e.g. snow); parsed into CYSEnSky::effects, not applied.
        const char* const kSkyChildren[] =
        {
            "SkyDome", "SkyClouds", "SkyRingClouds", "Star", "Moon", "Sun", "Ocean", "LightAndFog", "Effects", NULL
        };
        const char* const kEffectsChildren[] = { "Effect", NULL };
        const char* const kEffectAttrs[] = { "effect_name", NULL };
        const char* const kDomeChildren[] =
        {
            "texture", "hight", "mieAmount", "vertexHeightEffect", "sunHeightEffect", "power", NULL
        };
        const char* const kCloudsChildren[] = { "SkyCloudsLayer", NULL };
        const char* const kRingCloudsChildren[] = { "RingCloudsLayer", NULL };
        const char* const kCloudLayerChildren[] =
        {
            "name", "layer", "turnoverMesh", "skyCloudHeight", "meshname", "texturename", "rotangle", "textureTile",
            "scatteringStrength", "scatteringPower", "rimStrength", "rimPower", "rimDetectPower", "rimDetectWidth",
            "TimeNodesInfo", NULL
        };
        const char* const kRingLayerChildren[] =
        {
            "name", "layer", "meshname", "turnoverMesh", "texturename", "CloudHeight", "CloudScale", "TextureRepeat",
            "CloudOffset", "parallax", "scatteringStrength", "scatteringPower", "rimStrength", "rimPower",
            "rimDetectPower", "rimDetectWidth", "TimeNodesInfo", NULL
        };
        const char* const kTimeNodesChildren[] = { "TimeNode", NULL };
        const char* const kCloudNodeAttrs[] = { "time", "fog", "alpha", "cloudspeed", "ambientBlend", NULL };
        const char* const kRingNodeAttrs[] =
        {
            "time", "fogblend", "ambientBlend", "alpha", "rollspeed", "verticalSpeed", "fadeRange", NULL
        };
        const char* const kStarAttrs[] =
        {
            "Enable", "StarCount", "Radius", "Intensity", "Size", "FlickerSpeed", "StartColour", "EndColour",
            "starfix", NULL
        };
        const char* const kMoonAttrs[] =
        {
            "Enable", "moon_tex_name", "scale", "moonOrient", "moonAngle", "moonUpTime", "moonDownTime", "moonfix",
            "layer", NULL
        };
        const char* const kSunAttrs[] =
        {
            "Enable", "sun_tex_name", "useSunFlare", "sunflare_tex_name", "scale", "sunOrient", "sunAngle",
            "sunUpTime", "sunDownTime", "intensityStep", "sunfix", "lensFlare_settings_name", "useLensFlare",
            "layer", NULL
        };
        const char* const kOceanAttrs[] = { "Enable", "OceanVisible", NULL };
        const char* const kLightAndFogChildren[] = { "EnvKey", NULL };

        /// Leaf elements (<hight>102</hight>) must carry neither attributes nor child elements.
        /// (TimeNodesInfo is a list, not a leaf: it is checked by the caller.)
        void checkLeaves(const TiXmlElement* e, const char* const* leafNames, const String& path, const String& file)
        {
            for (const TiXmlElement* c = e->FirstChildElement(); c; c = c->NextSiblingElement())
            {
                if (strcmp(c->Value(), "TimeNodesInfo") == 0)
                    continue;
                for (const char* const* n = leafNames; *n; ++n)
                {
                    if (strcmp(*n, c->Value()) == 0)
                    {
                        checkXmlKeys(c, NULL, NULL, kKind, path + "/" + c->Value(), file);
                        break;
                    }
                }
            }
        }

        void parseCloudLayer(const TiXmlElement* e, bool ring, CYSEnCloudLayer& out, const String& path,
                             const String& file)
        {
            const char* const* children = ring ? kRingLayerChildren : kCloudLayerChildren;
            checkXmlKeys(e, NULL, children, kKind, path, file);
            checkLeaves(e, children, path, file);   // TimeNodesInfo is checked below, as a list it is harmless

            out.ring = ring;
            out.name = textString(e, "name");
            out.layer = textInt(e, "layer", 0);
            out.turnoverMesh = textBool(e, "turnoverMesh", false);
            out.meshName = textString(e, "meshname");
            out.textureName = textString(e, "texturename");
            out.scatteringStrength = textReal(e, "scatteringStrength", out.scatteringStrength);
            out.scatteringPower = textReal(e, "scatteringPower", out.scatteringPower);
            out.rimStrength = textReal(e, "rimStrength", out.rimStrength);
            out.rimPower = textReal(e, "rimPower", out.rimPower);
            out.rimDetectPower = textReal(e, "rimDetectPower", out.rimDetectPower);
            out.rimDetectWidth = textReal(e, "rimDetectWidth", out.rimDetectWidth);
            if (ring)
            {
                out.cloudHeight = textReal(e, "CloudHeight", out.cloudHeight);
                out.cloudScale = textReal(e, "CloudScale", out.cloudScale);
                out.textureRepeat = textReal(e, "TextureRepeat", out.textureRepeat);
                out.cloudOffset = textReal(e, "CloudOffset", out.cloudOffset);
                out.parallax = textReal(e, "parallax", out.parallax);
            }
            else
            {
                out.skyCloudHeight = textReal(e, "skyCloudHeight", out.skyCloudHeight);
                out.rotAngle = textReal(e, "rotangle", out.rotAngle);
                out.textureTile = parseVector4(childText(e, "textureTile"), out.textureTile);
            }

            const TiXmlElement* info = e->FirstChildElement("TimeNodesInfo");
            if (info)
            {
                const String infoPath = path + "/TimeNodesInfo";
                checkXmlKeys(info, NULL, kTimeNodesChildren, kKind, infoPath, file);
                for (const TiXmlElement* n = info->FirstChildElement("TimeNode"); n;
                     n = n->NextSiblingElement("TimeNode"))
                {
                    checkXmlKeys(n, ring ? kRingNodeAttrs : kCloudNodeAttrs, NULL, kKind, infoPath + "/TimeNode", file);
                    CYSEnTimeNode node;
                    node.time = wrapHours(attrReal(n, "time", 0));
                    node.alpha = attrReal(n, "alpha", node.alpha);
                    node.ambientBlend = attrReal(n, "ambientBlend", node.ambientBlend);
                    if (ring)
                    {
                        node.fogBlend = attrReal(n, "fogblend", node.fogBlend);
                        node.rollSpeed = attrReal(n, "rollspeed", node.rollSpeed);
                        node.verticalSpeed = attrReal(n, "verticalSpeed", node.verticalSpeed);
                        node.fadeRange = attrReal(n, "fadeRange", node.fadeRange);
                    }
                    else
                    {
                        node.fog = attrReal(n, "fog", node.fog);
                        node.cloudSpeed = attrReal(n, "cloudspeed", node.cloudSpeed);
                    }
                    std::vector<CYSEnTimeNode>::iterator it = out.timeNodes.begin();
                    while (it != out.timeNodes.end() && it->time <= node.time)
                        ++it;
                    out.timeNodes.insert(it, node);
                }
            }
        }

        void parseCelestial(const TiXmlElement* e, bool sun, CYSEnCelestial& out, const String& path,
                            const String& file)
        {
            checkXmlKeys(e, sun ? kSunAttrs : kMoonAttrs, NULL, kKind, path, file);
            out.present = true;
            out.enable = attrBool(e, "Enable", false);
            out.texture = attrString(e, sun ? "sun_tex_name" : "moon_tex_name");
            out.scale = attrReal(e, "scale", out.scale);
            out.orient = attrReal(e, sun ? "sunOrient" : "moonOrient", out.orient);
            out.angle = attrReal(e, sun ? "sunAngle" : "moonAngle", out.angle);
            out.upTime = attrReal(e, sun ? "sunUpTime" : "moonUpTime", sun ? 6.0f : 18.0f);
            out.downTime = attrReal(e, sun ? "sunDownTime" : "moonDownTime", sun ? 18.0f : 6.0f);
            out.fixed = attrBool(e, sun ? "sunfix" : "moonfix", false);
            out.hasLayer = attr(e, "layer") != NULL;
            out.layer = attrInt(e, "layer", 0);
            if (sun)
            {
                out.useSunFlare = attrBool(e, "useSunFlare", false);
                out.flareTexture = attrString(e, "sunflare_tex_name");
                out.intensityStep = attrReal(e, "intensityStep", out.intensityStep);
                out.lensFlareSettings = attrString(e, "lensFlare_settings_name");
                out.useLensFlare = attrBool(e, "useLensFlare", false);
            }
        }

        void parseSky(const TiXmlElement* e, CYSEnSky& sky, const String& path, const String& file)
        {
            checkXmlKeys(e, NULL, kSkyChildren, kKind, path, file);
            sky.present = true;

            if (const TiXmlElement* d = e->FirstChildElement("SkyDome"))
            {
                const String p = path + "/SkyDome";
                checkXmlKeys(d, NULL, kDomeChildren, kKind, p, file);
                checkLeaves(d, kDomeChildren, p, file);
                sky.dome.present = true;
                sky.dome.texture = textString(d, "texture");
                sky.dome.height = textReal(d, "hight", sky.dome.height);
                sky.dome.mieAmount = textReal(d, "mieAmount", sky.dome.mieAmount);
                sky.dome.vertexHeightEffect = textReal(d, "vertexHeightEffect", sky.dome.vertexHeightEffect);
                sky.dome.sunHeightEffect = textReal(d, "sunHeightEffect", sky.dome.sunHeightEffect);
                sky.dome.power = textReal(d, "power", sky.dome.power);
            }
            if (const TiXmlElement* c = e->FirstChildElement("SkyClouds"))
            {
                const String p = path + "/SkyClouds";
                checkXmlKeys(c, NULL, kCloudsChildren, kKind, p, file);
                for (const TiXmlElement* l = c->FirstChildElement("SkyCloudsLayer"); l;
                     l = l->NextSiblingElement("SkyCloudsLayer"))
                {
                    sky.clouds.push_back(CYSEnCloudLayer());
                    parseCloudLayer(l, false, sky.clouds.back(), p + "/SkyCloudsLayer", file);
                }
            }
            if (const TiXmlElement* c = e->FirstChildElement("SkyRingClouds"))
            {
                const String p = path + "/SkyRingClouds";
                checkXmlKeys(c, NULL, kRingCloudsChildren, kKind, p, file);
                for (const TiXmlElement* l = c->FirstChildElement("RingCloudsLayer"); l;
                     l = l->NextSiblingElement("RingCloudsLayer"))
                {
                    sky.ringClouds.push_back(CYSEnCloudLayer());
                    parseCloudLayer(l, true, sky.ringClouds.back(), p + "/RingCloudsLayer", file);
                }
            }
            if (const TiXmlElement* s = e->FirstChildElement("Star"))
            {
                checkXmlKeys(s, kStarAttrs, NULL, kKind, path + "/Star", file);
                CYSEnStar& star = sky.star;
                star.present = true;
                star.enable = attrBool(s, "Enable", false);
                star.count = attrInt(s, "StarCount", star.count);
                star.radius = attrReal(s, "Radius", star.radius);
                star.intensity = attrReal(s, "Intensity", star.intensity);
                star.size = attrReal(s, "Size", star.size);
                star.flickerSpeed = attrReal(s, "FlickerSpeed", star.flickerSpeed);
                star.startColour = parseColour(attr(s, "StartColour"), star.startColour);
                star.endColour = parseColour(attr(s, "EndColour"), star.endColour);
                star.fixed = attrBool(s, "starfix", false);
            }
            if (const TiXmlElement* m = e->FirstChildElement("Moon"))
                parseCelestial(m, false, sky.moon, path + "/Moon", file);
            if (const TiXmlElement* s = e->FirstChildElement("Sun"))
                parseCelestial(s, true, sky.sun, path + "/Sun", file);
            if (const TiXmlElement* o = e->FirstChildElement("Ocean"))
            {
                checkXmlKeys(o, kOceanAttrs, NULL, kKind, path + "/Ocean", file);
                sky.oceanPresent = true;
                sky.oceanEnable = attrBool(o, "Enable", false);
                sky.oceanVisible = attrInt(o, "OceanVisible", 0);
            }
            if (const TiXmlElement* fx = e->FirstChildElement("Effects"))
            {
                const String p = path + "/Effects";
                checkXmlKeys(fx, NULL, kEffectsChildren, kKind, p, file);
                for (const TiXmlElement* f = fx->FirstChildElement("Effect"); f; f = f->NextSiblingElement("Effect"))
                {
                    checkXmlKeys(f, kEffectAttrs, NULL, kKind, p + "/Effect", file);
                    const String name = attrString(f, "effect_name");
                    if (!name.empty())
                        sky.effects.push_back(name);
                }
                if (!sky.effects.empty())
                    CYSSceneStats::instance().deferred("EnScene EnSky/Effects (CY sky effect kept, not played)");
            }
            if (const TiXmlElement* lf = e->FirstChildElement("LightAndFog"))
            {
                const String p = path + "/LightAndFog";
                checkXmlKeys(lf, NULL, kLightAndFogChildren, kKind, p, file);
                for (const TiXmlElement* k = lf->FirstChildElement("EnvKey"); k; k = k->NextSiblingElement("EnvKey"))
                    sky.keys.add(cysParseEnvKey(k, CYS_ENVKEY_ENSCENE, 1.0f, kKind, p + "/EnvKey", file));
            }
        }

        void parseRegion(const TiXmlElement* e, CYSEnRegion& region, const String& path, const String& file)
        {
            checkXmlKeys(e, kRegionAttrs, kRegionChildren, kKind, path, file);
            region.name = attrString(e, "name");
            region.maxAffectDistance = attrReal(e, "maxAffectDistance", 0);
            if (const TiXmlElement* groups = e->FirstChildElement("RegionGroups"))
            {
                const String gp = path + "/RegionGroups";
                checkXmlKeys(groups, NULL, kRegionGroupsChildren, kKind, gp, file);
                for (const TiXmlElement* poly = groups->FirstChildElement("polygon"); poly;
                     poly = poly->NextSiblingElement("polygon"))
                {
                    checkXmlKeys(poly, NULL, kPolygonChildren, kKind, gp + "/polygon", file);
                    CYSEnRegion::Polygon points;
                    for (const TiXmlElement* pt = poly->FirstChildElement("Point"); pt;
                         pt = pt->NextSiblingElement("Point"))
                    {
                        checkXmlKeys(pt, NULL, NULL, kKind, gp + "/polygon/Point", file);
                        points.push_back(parseVector2(pt->GetText(), Ogre::Vector2::ZERO));
                    }
                    region.polygons.push_back(points);
                }
            }
            if (const TiXmlElement* sky = e->FirstChildElement("EnSky"))
                parseSky(sky, region.sky, path + "/EnSky", file);
        }

        void rescaleTimes(CYSEnvKeyTrack& track, Real scale)
        {
            CYSEnvKeyTrack scaled;
            for (size_t i = 0; i < track.getKeys().size(); ++i)
            {
                CYSEnvKey k = track.getKeys()[i];
                k.time = wrapHours(k.time * scale);
                scaled.add(k);
            }
            track = scaled;
        }

        bool allKeysWithinFirstHour(const CYSEnvKeyTrack& track)
        {
            if (track.size() < 2)
                return false;
            for (size_t i = 0; i < track.getKeys().size(); ++i)
            {
                if (track.getKeys()[i].time > 1.0f)
                    return false;
            }
            return true;
        }
    }
    //-----------------------------------------------------------------------
    bool CYSScene::parseEnScene(const TiXmlElement* root, const String& file, CYSEnSceneData& out, String* error)
    {
        out.clear();
        out.fileName = file;
        if (!root || strcmp(root->Value(), "EnScene") != 0)
        {
            if (error)
                *error = "Bad file format for EnScene config!";
            return false;
        }
        checkXmlKeys(root, kRootAttrs, kRootChildren, kKind, "EnScene", file);
        out.version = attrString(root, "version");
        if (out.version != "1.0")
            CYSSceneStats::instance().unknown("EnScene version '" + out.version + "'", file);

        if (const TiXmlElement* sky = root->FirstChildElement("EnSky"))
            parseSky(sky, out.sky, "EnScene/EnSky", file);
        if (const TiXmlElement* comp = root->FirstChildElement("EnRegionComposite"))
        {
            checkXmlKeys(comp, NULL, kCompositeChildren, kKind, "EnScene/EnRegionComposite", file);
            for (const TiXmlElement* r = comp->FirstChildElement("EnRegion"); r; r = r->NextSiblingElement("EnRegion"))
            {
                out.regions.push_back(CYSEnRegion());
                parseRegion(r, out.regions.back(), "EnScene/EnRegionComposite/EnRegion", file);
            }
        }

        // CY-Source deviation: keys written in day fractions (all <= 1, several keys) are rescaled to hours.
        const CYSEnSky* base = out.getBaseSky();
        if (base && allKeysWithinFirstHour(base->keys))
        {
            out.timesAsDayFraction = true;
            rescaleTimes(out.sky.keys, 24.0f);
            for (size_t i = 0; i < out.regions.size(); ++i)
                rescaleTimes(out.regions[i].sky.keys, 24.0f);
            logOnce("dayfraction:" + file, "EnScene '" + file + "': EnvKey times <= 1 read as day fractions");
        }
        return true;
    }
    //-----------------------------------------------------------------------
    bool CYSScene::loadEnScene(const String& name, const String& group, CYSEnSceneData& out, String* error)
    {
        TiXmlDocument doc;
        if (!loadXmlResource(doc, name, group, error))
        {
            out.clear();
            return false;
        }
        return parseEnScene(doc.RootElement(), name, out, error);
    }
}
