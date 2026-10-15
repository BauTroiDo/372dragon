// CY-Source (scene agent): see CYSSkySphereData.h.
#include "CYSSkySphereData.h"
#include "CYSXml.h"

#define TIXML_USE_STL
#include <tinyxml.h>

#include <cstring>

namespace WX
{
    using namespace CYSScene;

    namespace
    {
        const char* const kLayerNames[CYS_SKY_LAYER_COUNT] =
        {
            "background", "far_cloud", "fog", "mountain", "near_cloud"
        };
    }
    //-----------------------------------------------------------------------
    const char* cysSkyLayerName(int id)
    {
        return (id >= 0 && id < CYS_SKY_LAYER_COUNT) ? kLayerNames[id] : "";
    }
    //-----------------------------------------------------------------------
    int cysSkyLayerId(const String& name)
    {
        for (int i = 0; i < CYS_SKY_LAYER_COUNT; ++i)
        {
            if (name == kLayerNames[i])
                return i;
        }
        return -1;
    }
    //-----------------------------------------------------------------------
    Real CYSSkyAlphaCurve::sample(Real dayFraction) const
    {
        if (keys.empty())
            return 1.0f;
        if (keys.size() == 1)
            return keys.front().alpha;
        Real t = dayFraction - (Real)(int)dayFraction;
        if (t < 0)
            t += 1.0f;
        size_t i = 0;
        while (i < keys.size() && keys[i].time <= t)
            ++i;
        const CYSSkyAlphaKey* a;
        const CYSSkyAlphaKey* b;
        Real f;
        if (i == 0 || i == keys.size())
        {
            a = &keys.back();
            b = &keys.front();
            const Real span = b->time + 1.0f - a->time;
            const Real since = (i == 0) ? t + 1.0f - a->time : t - a->time;
            f = span > 1e-6f ? since / span : 0.0f;
        }
        else
        {
            a = &keys[i - 1];
            b = &keys[i];
            const Real span = b->time - a->time;
            f = span > 1e-6f ? (t - a->time) / span : 0.0f;
        }
        return lerp(a->alpha, b->alpha, saturate(f));
    }
    //-----------------------------------------------------------------------
    void CYSSkyAlphaCurve::add(const CYSSkyAlphaKey& key)
    {
        std::vector<CYSSkyAlphaKey>::iterator it = keys.begin();
        while (it != keys.end() && it->time <= key.time)
            ++it;
        keys.insert(it, key);
    }
    //-----------------------------------------------------------------------
    CYSSkyTextureGroup::CYSSkyTextureGroup(void)
    {
        for (int i = 0; i < CYS_SKY_LAYER_COUNT; ++i)
        {
            wraps[i] = 1.0f;
            has[i] = false;
        }
    }
    //-----------------------------------------------------------------------
    void CYSSkySphereData::clear(void)
    {
        fileName.clear();
        enableFixedHeight = false;
        fixedHeight = 0;
        hasEffectLOD = hasParticleLOD = false;
        effectLODMin = effectLODMax = particleLODMin = particleLODMax = 0;
        sunshine.present = false;
        sunshine.distance = 1000;
        sunshine.textureSunrise.clear();
        sunshine.textureSunset.clear();
        sunshine.rotateAxis = Ogre::Vector3::UNIT_Y;
        sunshine.rotateAngle = 0;
        sunshine.startTime = 0;
        sunshine.duration = 0;
        moon.present = false;
        moon.distance = 13000;
        moon.direction = Ogre::Vector3::UNIT_Y;
        moon.dates.clear();
        star.present = false;
        star.count = 0;
        star.size = 8;
        star.radius = 10000;
        star.intensity = 1;
        star.flickerSpeed = 0.2f;
        star.startColour = Ogre::ColourValue(0.1f, 0.1f, 0.1f, 0.1f);
        star.endColour = Ogre::ColourValue::White;
        layers.clear();
        currentWeather.clear();
        weathers.clear();
    }
    //-----------------------------------------------------------------------
    const CYSSkyWeather* CYSSkySphereData::findWeather(const String& name) const
    {
        for (size_t i = 0; i < weathers.size(); ++i)
        {
            if (weathers[i].name == name)
                return &weathers[i];
        }
        for (size_t i = 0; i < weathers.size(); ++i)
        {
            if (weathers[i].name == currentWeather)
                return &weathers[i];
        }
        return weathers.empty() ? NULL : &weathers[0];
    }

    //////////////////////////////////////////////////////////////////////////
    // Parser
    //////////////////////////////////////////////////////////////////////////
    namespace
    {
        const char* const kKind = "SkySphere";

        const char* const kRootChildren[] =
        {
            "SkyHeight", "EffectLOD", "ParticleLOD", "SkySunshine", "SkyMoon", "SkyStar", "SkyWeathers",
            "SkySphereLayers", NULL
        };
        const char* const kHeightAttrs[] = { "enable_fixed_height", "fixed_height", NULL };
        const char* const kLodAttrs[] = { "min_distance", "max_distance", NULL };
        const char* const kSunshineAttrs[] =
        {
            "distance", "texture_sunrise", "texture_sunset", "rotate_axis", "rotate_angle", "start_time", "duration",
            NULL
        };
        const char* const kMoonAttrs[] = { "distance", "direction", NULL };
        const char* const kMoonChildren[] = { "DateConfig", NULL };
        const char* const kDateAttrs[] = { "date", "texture", NULL };
        const char* const kAlphaListHolderChildren[] = { "AlphaKeyList", NULL };
        const char* const kAlphaListChildren[] = { "KeyAlpha", NULL };
        const char* const kKeyAlphaAttrs[] = { "time", "alpha", NULL };
        const char* const kStarAttrs[] =
        {
            "star_count", "star_size", "radius", "intensity", "flicker_speed", "start_colour", "end_colour", NULL
        };
        const char* const kWeathersAttrs[] = { "current_weather", NULL };
        const char* const kWeathersChildren[] = { "Weather", NULL };
        const char* const kWeatherAttrs[] = { "name", NULL };
        const char* const kWeatherChildren[] = { "SkyEnviromentList", "SkySphereTextureGroups", "SkyEffectParams", NULL };
        const char* const kEnvListChildren[] = { "EnvKey", NULL };
        const char* const kGroupsChildren[] = { "TextureGroup", NULL };
        const char* const kGroupAttrs[] =
        {
            "background_texture", "background_wrap", "far_cloud_texture", "far_cloud_wrap", "fog_texture", "fog_wrap",
            "mountain_texture", "mountain_wrap", "near_cloud_texture", "near_cloud_wrap", NULL
        };
        const char* const kEffectParamsAttrs[] = { "show_moon", "show_star", "show_sun_flares", "show_sunshine", NULL };
        const char* const kEffectParamsChildren[] = { "Effect", NULL };
        const char* const kEffectAttrs[] = { "name", NULL };
        const char* const kEffectChildren[] = { "Parameter", NULL };
        const char* const kParameterAttrs[] = { "name", "value", NULL };
        const char* const kLayersChildren[] = { "SkyLayer", NULL };
        const char* const kLayerAttrs[] =
        {
            "name", "pitch_start", "pitch_end", "distance", "rotate_speed", "texture_count", NULL
        };

        void parseAlphaList(const TiXmlElement* holder, CYSSkyAlphaCurve& curve, const String& path, const String& file)
        {
            const TiXmlElement* list = holder->FirstChildElement("AlphaKeyList");
            if (!list)
                return;
            const String p = path + "/AlphaKeyList";
            checkXmlKeys(list, NULL, kAlphaListChildren, kKind, p, file);
            for (const TiXmlElement* k = list->FirstChildElement("KeyAlpha"); k; k = k->NextSiblingElement("KeyAlpha"))
            {
                checkXmlKeys(k, kKeyAlphaAttrs, NULL, kKind, p + "/KeyAlpha", file);
                CYSSkyAlphaKey key;
                key.time = attrReal(k, "time", 0);
                key.alpha = attrReal(k, "alpha", 1);
                curve.add(key);
            }
        }

        void parseWeather(const TiXmlElement* w, CYSSkyWeather& weather, const String& path, const String& file)
        {
            checkXmlKeys(w, kWeatherAttrs, kWeatherChildren, kKind, path, file);
            weather.name = attrString(w, "name");

            if (const TiXmlElement* list = w->FirstChildElement("SkyEnviromentList"))
            {
                const String p = path + "/SkyEnviromentList";
                checkXmlKeys(list, NULL, kEnvListChildren, kKind, p, file);
                for (const TiXmlElement* k = list->FirstChildElement("EnvKey"); k; k = k->NextSiblingElement("EnvKey"))
                    weather.keys.add(cysParseEnvKey(k, CYS_ENVKEY_SKYSPHERE, 24.0f, kKind, p + "/EnvKey", file));
            }
            if (const TiXmlElement* groups = w->FirstChildElement("SkySphereTextureGroups"))
            {
                const String p = path + "/SkySphereTextureGroups";
                checkXmlKeys(groups, NULL, kGroupsChildren, kKind, p, file);
                for (const TiXmlElement* g = groups->FirstChildElement("TextureGroup"); g;
                     g = g->NextSiblingElement("TextureGroup"))
                {
                    const String gp = p + "/TextureGroup";
                    checkXmlKeys(g, kGroupAttrs, kAlphaListHolderChildren, kKind, gp, file);
                    CYSSkyTextureGroup group;
                    for (int i = 0; i < CYS_SKY_LAYER_COUNT; ++i)
                    {
                        const String base = kLayerNames[i];
                        const char* tex = attr(g, (base + "_texture").c_str());
                        group.textures[i] = tex ? tex : "";
                        group.has[i] = tex && *tex;
                        group.wraps[i] = attrReal(g, (base + "_wrap").c_str(), 1.0f);
                    }
                    parseAlphaList(g, group.alpha, gp, file);
                    weather.textureGroups.push_back(group);
                }
            }
            if (const TiXmlElement* fx = w->FirstChildElement("SkyEffectParams"))
            {
                const String p = path + "/SkyEffectParams";
                checkXmlKeys(fx, kEffectParamsAttrs, kEffectParamsChildren, kKind, p, file);
                weather.hasEffectParams = true;
                weather.showMoon = attrBool(fx, "show_moon", false);
                weather.showStar = attrBool(fx, "show_star", false);
                weather.showSunFlares = attrBool(fx, "show_sun_flares", false);
                weather.showSunshine = attrBool(fx, "show_sunshine", false);
                for (const TiXmlElement* e = fx->FirstChildElement("Effect"); e; e = e->NextSiblingElement("Effect"))
                {
                    checkXmlKeys(e, kEffectAttrs, kEffectChildren, kKind, p + "/Effect", file);
                    CYSSkyEffect effect;
                    effect.name = attrString(e, "name");
                    for (const TiXmlElement* prm = e->FirstChildElement("Parameter"); prm;
                         prm = prm->NextSiblingElement("Parameter"))
                    {
                        checkXmlKeys(prm, kParameterAttrs, NULL, kKind, p + "/Effect/Parameter", file);
                        CYSSkyEffectParam param;
                        param.name = attrString(prm, "name");
                        param.value = attrString(prm, "value");
                        effect.params.push_back(param);
                    }
                    weather.effects.push_back(effect);
                }
            }
        }
    }
    //-----------------------------------------------------------------------
    bool CYSScene::parseSkySphere(const TiXmlElement* root, const String& file, CYSSkySphereData& out, String* error)
    {
        out.clear();
        out.fileName = file;
        if (!root || strcmp(root->Value(), "SkySphere") != 0)
        {
            if (error)
                *error = "root element is not <SkySphere>";
            return false;
        }
        checkXmlKeys(root, NULL, kRootChildren, kKind, "SkySphere", file);

        if (const TiXmlElement* h = root->FirstChildElement("SkyHeight"))
        {
            checkXmlKeys(h, kHeightAttrs, NULL, kKind, "SkySphere/SkyHeight", file);
            out.enableFixedHeight = attrBool(h, "enable_fixed_height", false);
            out.fixedHeight = attrReal(h, "fixed_height", 0);
        }
        if (const TiXmlElement* l = root->FirstChildElement("EffectLOD"))
        {
            checkXmlKeys(l, kLodAttrs, NULL, kKind, "SkySphere/EffectLOD", file);
            out.hasEffectLOD = true;
            out.effectLODMin = attrReal(l, "min_distance", 0);
            out.effectLODMax = attrReal(l, "max_distance", 0);
        }
        if (const TiXmlElement* l = root->FirstChildElement("ParticleLOD"))
        {
            checkXmlKeys(l, kLodAttrs, NULL, kKind, "SkySphere/ParticleLOD", file);
            out.hasParticleLOD = true;
            out.particleLODMin = attrReal(l, "min_distance", 0);
            out.particleLODMax = attrReal(l, "max_distance", 0);
        }
        if (const TiXmlElement* s = root->FirstChildElement("SkySunshine"))
        {
            checkXmlKeys(s, kSunshineAttrs, NULL, kKind, "SkySphere/SkySunshine", file);
            out.sunshine.present = true;
            out.sunshine.distance = attrReal(s, "distance", out.sunshine.distance);
            out.sunshine.textureSunrise = attrString(s, "texture_sunrise");
            out.sunshine.textureSunset = attrString(s, "texture_sunset");
            out.sunshine.rotateAxis = parseVector3(attr(s, "rotate_axis"), out.sunshine.rotateAxis);
            out.sunshine.rotateAngle = attrReal(s, "rotate_angle", 0);
            out.sunshine.startTime = attrReal(s, "start_time", 0);
            out.sunshine.duration = attrReal(s, "duration", 0);
        }
        if (const TiXmlElement* m = root->FirstChildElement("SkyMoon"))
        {
            checkXmlKeys(m, kMoonAttrs, kMoonChildren, kKind, "SkySphere/SkyMoon", file);
            out.moon.present = true;
            out.moon.distance = attrReal(m, "distance", out.moon.distance);
            out.moon.direction = parseVector3(attr(m, "direction"), out.moon.direction);
            for (const TiXmlElement* d = m->FirstChildElement("DateConfig"); d; d = d->NextSiblingElement("DateConfig"))
            {
                const String p = "SkySphere/SkyMoon/DateConfig";
                checkXmlKeys(d, kDateAttrs, kAlphaListHolderChildren, kKind, p, file);
                CYSSkyMoonDate date;
                date.date = attrInt(d, "date", 0);
                date.texture = attrString(d, "texture");
                parseAlphaList(d, date.alpha, p, file);
                out.moon.dates.push_back(date);
            }
        }
        if (const TiXmlElement* s = root->FirstChildElement("SkyStar"))
        {
            checkXmlKeys(s, kStarAttrs, NULL, kKind, "SkySphere/SkyStar", file);
            out.star.present = true;
            out.star.count = attrInt(s, "star_count", 0);
            out.star.size = attrReal(s, "star_size", out.star.size);
            out.star.radius = attrReal(s, "radius", out.star.radius);
            out.star.intensity = attrReal(s, "intensity", out.star.intensity);
            out.star.flickerSpeed = attrReal(s, "flicker_speed", out.star.flickerSpeed);
            out.star.startColour = parseColour(attr(s, "start_colour"), out.star.startColour);
            out.star.endColour = parseColour(attr(s, "end_colour"), out.star.endColour);
        }
        if (const TiXmlElement* ws = root->FirstChildElement("SkyWeathers"))
        {
            checkXmlKeys(ws, kWeathersAttrs, kWeathersChildren, kKind, "SkySphere/SkyWeathers", file);
            out.currentWeather = attrString(ws, "current_weather");
            for (const TiXmlElement* w = ws->FirstChildElement("Weather"); w; w = w->NextSiblingElement("Weather"))
            {
                out.weathers.push_back(CYSSkyWeather());
                parseWeather(w, out.weathers.back(), "SkySphere/SkyWeathers/Weather", file);
            }
        }
        if (const TiXmlElement* ls = root->FirstChildElement("SkySphereLayers"))
        {
            checkXmlKeys(ls, NULL, kLayersChildren, kKind, "SkySphere/SkySphereLayers", file);
            for (const TiXmlElement* l = ls->FirstChildElement("SkyLayer"); l; l = l->NextSiblingElement("SkyLayer"))
            {
                checkXmlKeys(l, kLayerAttrs, NULL, kKind, "SkySphere/SkySphereLayers/SkyLayer", file);
                CYSSkyLayerDef def;
                def.name = attrString(l, "name");
                def.id = cysSkyLayerId(def.name);
                if (def.id < 0)
                    CYSSceneStats::instance().unknown("SkySphere layer name '" + def.name + "'", file);
                def.pitchStart = attrReal(l, "pitch_start", 0);
                def.pitchEnd = attrReal(l, "pitch_end", Ogre::Math::HALF_PI);
                def.distance = attrReal(l, "distance", 3000);
                def.rotateSpeed = attrReal(l, "rotate_speed", 0);
                def.textureCount = attrInt(l, "texture_count", 0);
                out.layers.push_back(def);
            }
        }
        return true;
    }
    //-----------------------------------------------------------------------
    bool CYSScene::loadSkySphere(const String& name, const String& group, CYSSkySphereData& out, String* error)
    {
        TiXmlDocument doc;
        if (!loadXmlResource(doc, name, group, error))
        {
            out.clear();
            return false;
        }
        return parseSkySphere(doc.RootElement(), name, out, error);
    }
}
