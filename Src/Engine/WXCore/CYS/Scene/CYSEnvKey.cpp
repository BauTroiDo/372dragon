// CY-Source (scene agent): see CYSEnvKey.h.
#include "CYSEnvKey.h"
#include "CYSXml.h"

#define TIXML_USE_STL
#include <tinyxml.h>

#include <algorithm>
#include <cmath>
#include <cstdio>

namespace WX
{
    using namespace CYSScene;

    //////////////////////////////////////////////////////////////////////////
    // CYSHeightFogParams
    //////////////////////////////////////////////////////////////////////////
    CYSHeightFogParams::CYSHeightFogParams(void)
        : fogColour(0.314f, 0.631f, 0.765f, 1.0f)
        , hDensity(1.0f)
        , hHeight(-10.0f)
        , hHeightFalloff(0.01f)
        , hPowFactor(5.0f)
        , dDensity(1.0f)
        , dHeightFalloff(0.4f)
        , dStartDistance(0.0f)
        , inscatteringFactor(2.0f)
        , dirInscatteringColour(1.0f, 1.0f, 1.0f, 1.0f)
    {
    }
    //-----------------------------------------------------------------------
    CYSHeightFogParams CYSHeightFogParams::zero(void)
    {
        CYSHeightFogParams p;
        p.fogColour = Ogre::ColourValue(0, 0, 0, 0);
        p.hDensity = p.hHeight = p.hHeightFalloff = p.hPowFactor = 0;
        p.dDensity = p.dHeightFalloff = p.dStartDistance = 0;
        p.inscatteringFactor = 0;
        p.dirInscatteringColour = Ogre::ColourValue(0, 0, 0, 0);
        return p;
    }
    //-----------------------------------------------------------------------
    Real CYSHeightFogParams::evaluate(Real y, Real distance) const
    {
        const Real heightAbove = std::max(0.0f, y - hHeight);
        Real hFog = hDensity * std::exp(-hHeightFalloff / 1000.0f * heightAbove);
        hFog = hFog > 0 ? std::pow(hFog, hPowFactor) : 0.0f;
        const Real rayLength = std::max(0.0f, distance - dStartDistance);
        const Real dFog = 1.0f - dDensity * std::exp(-dHeightFalloff / 1000.0f * rayLength);
        return saturate(hFog * dFog);
    }
    //-----------------------------------------------------------------------
    CYSHeightFogParams CYSHeightFogParams::lerp(const CYSHeightFogParams& a, const CYSHeightFogParams& b, Real t)
    {
        CYSHeightFogParams r;
        r.fogColour = CYSScene::lerp(a.fogColour, b.fogColour, t);
        r.hDensity = CYSScene::lerp(a.hDensity, b.hDensity, t);
        r.hHeight = CYSScene::lerp(a.hHeight, b.hHeight, t);
        r.hHeightFalloff = CYSScene::lerp(a.hHeightFalloff, b.hHeightFalloff, t);
        r.hPowFactor = CYSScene::lerp(a.hPowFactor, b.hPowFactor, t);
        r.dDensity = CYSScene::lerp(a.dDensity, b.dDensity, t);
        r.dHeightFalloff = CYSScene::lerp(a.dHeightFalloff, b.dHeightFalloff, t);
        r.dStartDistance = CYSScene::lerp(a.dStartDistance, b.dStartDistance, t);
        r.inscatteringFactor = CYSScene::lerp(a.inscatteringFactor, b.inscatteringFactor, t);
        r.dirInscatteringColour = CYSScene::lerp(a.dirInscatteringColour, b.dirInscatteringColour, t);
        return r;
    }
    //-----------------------------------------------------------------------
    bool cysParseHeightFogParam(const String& text, CYSHeightFogParams& out)
    {
        // Split on '|' into exactly 10 fields.
        std::vector<String> fields;
        size_t start = 0;
        for (;;)
        {
            const size_t bar = text.find('|', start);
            fields.push_back(text.substr(start, bar == String::npos ? String::npos : bar - start));
            if (bar == String::npos)
                break;
            start = bar + 1;
        }
        if (fields.size() != 10)
            return false;

        float c0[4] = { 0, 0, 0, 1 };
        float c1[4] = { 0, 0, 0, 1 };
        if (parseFloats(fields[0].c_str(), c0, 4) < 3 || parseFloats(fields[1].c_str(), c1, 4) < 3)
            return false;
        float s[8];
        for (size_t i = 0; i < 8; ++i)
        {
            if (parseFloats(fields[2 + i].c_str(), &s[i], 1) != 1)
                return false;
        }

        out.fogColour = Ogre::ColourValue(c0[0], c0[1], c0[2], c0[3]);
        out.dirInscatteringColour = Ogre::ColourValue(c1[0], c1[1], c1[2], c1[3]);
        out.hDensity = s[0];
        out.hHeight = s[1];
        out.hHeightFalloff = s[2];
        out.hPowFactor = s[3];
        out.dDensity = s[4];
        out.dHeightFalloff = s[5];
        out.dStartDistance = s[6];
        out.inscatteringFactor = s[7];
        return true;
    }
    //-----------------------------------------------------------------------
    String cysFormatHeightFogParam(const CYSHeightFogParams& p)
    {
        char buf[512];
        sprintf(buf, "%g %g %g %g|%g %g %g %g|%g|%g|%g|%g|%g|%g|%g|%g",
                p.fogColour.r, p.fogColour.g, p.fogColour.b, p.fogColour.a,
                p.dirInscatteringColour.r, p.dirInscatteringColour.g, p.dirInscatteringColour.b,
                p.dirInscatteringColour.a,
                p.hDensity, p.hHeight, p.hHeightFalloff, p.hPowFactor,
                p.dDensity, p.dHeightFalloff, p.dStartDistance, p.inscatteringFactor);
        return buf;
    }

    //////////////////////////////////////////////////////////////////////////
    // CYSEnvKey
    //////////////////////////////////////////////////////////////////////////
    CYSEnvKey::CYSEnvKey(void)
        : time(0)
        , ambient(0, 0, 0, 1)
        , pbrAmbient(0, 0, 0, 1)
        , shadowStrength(1.0f)
        , pbrShadowStrength(1.0f)
        , fog(0, 0, 0, 1)
        , fogNear(0)
        , fogFar(0)
        , skyFog(0, 0, 0, 1)
        , hasSkyFog(false)
        , lightOne(0, 0, 0, 1)
        , lightOneSpecular(0, 0, 0, 1)
        , lightOneDirection(Ogre::Vector3::ZERO)
        , lightOneIntensity(1.0f)
        , lightTwo(0, 0, 0, 1)
        , lightTwoSpecular(0, 0, 0, 1)
        , lightTwoDirection(Ogre::Vector3::ZERO)
        , lightTwoIntensity(1.0f)
        , fakePointLightIntensity(1.0f)
        , warmColour(0.5f, 0.5f, 0.5f)
        , coldColour(0.5f, 0.5f, 0.5f)
        , enhanceContrast(1.0f, 1.0f, 1.0f)
        , overlayImage(0.5f, 0.5f, 0.5f)
        , radialBlur(1.0f, 0.1f)
        , lightSpecularIntensity(0.1f)
        , actorLightOne(0, 0, 0, 1)
        , actorLightOneIntensity(1.0f)
        , actorLightTwo(0, 0, 0, 1)
        , actorLightTwoIntensity(1.0f)
        , actorAmbient(0, 0, 0, 1)
        , selectActorLight(0.5f, 0.5f, 0.5f, 1.0f)
        , heightFogEnabled(false)
        , heightFog(CYSHeightFogParams::zero())
        , skyDomeAmbientColour(1.0f, 1.0f, 1.0f)
        , skyDomeAmbientStrength(1.0f)
    {
    }
    //-----------------------------------------------------------------------
    namespace
    {
        Ogre::Vector3 lerpDirection(const Ogre::Vector3& a, const Ogre::Vector3& b, Real t)
        {
            // (0,0,0) means "keep the scene's light direction" (B applies the direction only when non-zero).
            if (a == Ogre::Vector3::ZERO)
                return b;
            if (b == Ogre::Vector3::ZERO)
                return a;
            Ogre::Vector3 d = CYSScene::lerp(a, b, t);
            if (d.squaredLength() < 1e-12f)
                return t < 0.5f ? a : b;
            return d;
        }
    }
    //-----------------------------------------------------------------------
    CYSEnvKey CYSEnvKey::lerp(const CYSEnvKey& a, const CYSEnvKey& b, Real t)
    {
        using CYSScene::lerp;
        CYSEnvKey r;
        r.time = lerp(a.time, b.time, t);
        r.ambient = lerp(a.ambient, b.ambient, t);
        r.pbrAmbient = lerp(a.pbrAmbient, b.pbrAmbient, t);
        r.shadowStrength = lerp(a.shadowStrength, b.shadowStrength, t);
        r.pbrShadowStrength = lerp(a.pbrShadowStrength, b.pbrShadowStrength, t);
        r.fog = lerp(a.fog, b.fog, t);
        r.fogNear = lerp(a.fogNear, b.fogNear, t);
        r.fogFar = lerp(a.fogFar, b.fogFar, t);
        r.hasSkyFog = a.hasSkyFog || b.hasSkyFog;
        r.skyFog = lerp(a.hasSkyFog ? a.skyFog : a.fog, b.hasSkyFog ? b.skyFog : b.fog, t);
        r.lightOne = lerp(a.lightOne, b.lightOne, t);
        r.lightOneSpecular = lerp(a.lightOneSpecular, b.lightOneSpecular, t);
        r.lightOneDirection = lerpDirection(a.lightOneDirection, b.lightOneDirection, t);
        r.lightOneIntensity = lerp(a.lightOneIntensity, b.lightOneIntensity, t);
        r.lightTwo = lerp(a.lightTwo, b.lightTwo, t);
        r.lightTwoSpecular = lerp(a.lightTwoSpecular, b.lightTwoSpecular, t);
        r.lightTwoDirection = lerpDirection(a.lightTwoDirection, b.lightTwoDirection, t);
        r.lightTwoIntensity = lerp(a.lightTwoIntensity, b.lightTwoIntensity, t);
        r.fakePointLightIntensity = lerp(a.fakePointLightIntensity, b.fakePointLightIntensity, t);
        r.warmColour = lerp(a.warmColour, b.warmColour, t);
        r.coldColour = lerp(a.coldColour, b.coldColour, t);
        r.enhanceContrast = lerp(a.enhanceContrast, b.enhanceContrast, t);
        r.overlayImage = lerp(a.overlayImage, b.overlayImage, t);
        r.radialBlur = lerp(a.radialBlur, b.radialBlur, t);
        r.lightSpecularIntensity = lerp(a.lightSpecularIntensity, b.lightSpecularIntensity, t);
        r.actorLightOne = lerp(a.actorLightOne, b.actorLightOne, t);
        r.actorLightOneIntensity = lerp(a.actorLightOneIntensity, b.actorLightOneIntensity, t);
        r.actorLightTwo = lerp(a.actorLightTwo, b.actorLightTwo, t);
        r.actorLightTwoIntensity = lerp(a.actorLightTwoIntensity, b.actorLightTwoIntensity, t);
        r.actorAmbient = lerp(a.actorAmbient, b.actorAmbient, t);
        r.selectActorLight = lerp(a.selectActorLight, b.selectActorLight, t);
        if (a.heightFogEnabled && b.heightFogEnabled)
        {
            r.heightFogEnabled = true;
            r.heightFog = CYSHeightFogParams::lerp(a.heightFog, b.heightFog, t);
        }
        else if (a.heightFogEnabled || b.heightFogEnabled)
        {
            // Only one side has height fog: switch at the midpoint, keep that side's parameters (INF).
            r.heightFogEnabled = t < 0.5f ? a.heightFogEnabled : b.heightFogEnabled;
            r.heightFog = a.heightFogEnabled ? a.heightFog : b.heightFog;
        }
        else
        {
            r.heightFogEnabled = false;
            r.heightFog = CYSHeightFogParams::lerp(a.heightFog, b.heightFog, t);
        }
        r.skyDomeAmbientColour = lerp(a.skyDomeAmbientColour, b.skyDomeAmbientColour, t);
        r.skyDomeAmbientStrength = lerp(a.skyDomeAmbientStrength, b.skyDomeAmbientStrength, t);
        return r;
    }

    //////////////////////////////////////////////////////////////////////////
    // Parser
    //////////////////////////////////////////////////////////////////////////
    namespace
    {

        const char* const kEnSceneKeyAttrs[] =
        {
            "time", "ambient", "pbr_ambient", "shadow_strength", "pbr_shadow_strength", "fog",
            "fog_near_distance", "fog_far_distance", "light_one", "light_one_specular", "light_one_direction",
            "light_one_intensity", "light_two", "light_two_specular", "light_two_direction", "light_two_intensity",
            "fake_point_light_intensity", "warm_color", "cold_color", "enhance_constrast", "overlay_image",
            "radial_blur", "light_specular_intensity", "actor_light_one", "actor_light_one_intensity",
            "actor_light_two", "actor_light_two_intensity", "actor_light_ambient", "selectactor_light",
            "height_fog_enabled", "height_fog_param", "skyDomeAmbientColor", "skyDomeAmbientColorStrength",
            NULL
        };
        // SkySphere keys (FairySkySphere reader): the same names plus sky_fog, and the data writes
        // "actor_light_Two_intensity" with a capital T (440 keys).
        const char* const kSkySphereKeyAttrs[] =
        {
            "time", "ambient", "pbr_ambient", "shadow_strength", "pbr_shadow_strength", "fog", "sky_fog",
            "fog_near_distance", "fog_far_distance", "light_one", "light_one_specular", "light_one_direction",
            "light_one_intensity", "light_two", "light_two_specular", "light_two_direction", "light_two_intensity",
            "fake_point_light_intensity", "warm_color", "cold_color", "enhance_constrast", "overlay_image",
            "radial_blur", "light_specular_intensity", "actor_light_one", "actor_light_one_intensity",
            "actor_light_two", "actor_light_two_intensity", "actor_light_Two_intensity", "actor_light_ambient",
            "selectactor_light", "height_fog_enabled", "height_fog_param", "skyDomeAmbientColor",
            "skyDomeAmbientColorStrength",
            NULL
        };

        inline bool isZeroRGB(const Ogre::ColourValue& c)
        {
            return c.r == 0 && c.g == 0 && c.b == 0;
        }

        Ogre::ColourValue colourAttr(const TiXmlElement* e, const char* name, const Ogre::ColourValue& def)
        {
            const char* v = attr(e, name);
            if (!v)
                return def;
            // EnvKey colours are "r g b"; the alpha stays 1.
            Ogre::ColourValue c = parseColour(v, Ogre::ColourValue(def.r, def.g, def.b, 1.0f));
            c.a = 1.0f;
            return c;
        }
    }
    //-----------------------------------------------------------------------
    CYSEnvKey cysParseEnvKey(const TiXmlElement* e, CYSEnvKeySource source, Real timeScale,
                             const String& kind, const String& path, const String& file)
    {
        CYSEnvKey k;
        if (!e)
            return k;

        checkXmlKeys(e, source == CYS_ENVKEY_SKYSPHERE ? kSkySphereKeyAttrs : kEnSceneKeyAttrs, NULL,
                     kind, path, file);

        const Real rawTime = attrReal(e, "time", 0);
        k.time = wrapHours(rawTime * timeScale);
        // B derives the default specular intensity from the raw time value before reading the attribute.
        k.lightSpecularIntensity = (rawTime < 12.0f || rawTime > 24.0f) ? rawTime / 60.0f + 0.1f
                                                                         : 0.5f - rawTime / 60.0f;

        k.ambient = colourAttr(e, "ambient", k.ambient);
        k.pbrAmbient = colourAttr(e, "pbr_ambient", k.pbrAmbient);
        k.shadowStrength = attrReal(e, "shadow_strength", k.shadowStrength);
        k.pbrShadowStrength = attrReal(e, "pbr_shadow_strength", k.pbrShadowStrength);
        k.fog = colourAttr(e, "fog", k.fog);
        k.fogNear = attrReal(e, "fog_near_distance", k.fogNear);
        k.fogFar = attrReal(e, "fog_far_distance", k.fogFar);
        if (attr(e, "sky_fog"))
        {
            k.skyFog = colourAttr(e, "sky_fog", k.skyFog);
            k.hasSkyFog = true;
        }
        else
        {
            k.skyFog = k.fog;
        }

        k.lightOne = colourAttr(e, "light_one", k.lightOne);
        k.lightOneSpecular = colourAttr(e, "light_one_specular", k.lightOneSpecular);
        k.lightOneDirection = parseVector3(attr(e, "light_one_direction"), k.lightOneDirection);
        k.lightOneIntensity = attrReal(e, "light_one_intensity", k.lightOneIntensity);
        k.lightTwo = colourAttr(e, "light_two", k.lightTwo);
        k.lightTwoSpecular = colourAttr(e, "light_two_specular", k.lightTwoSpecular);
        k.lightTwoDirection = parseVector3(attr(e, "light_two_direction"), k.lightTwoDirection);
        k.lightTwoIntensity = attrReal(e, "light_two_intensity", k.lightTwoIntensity);

        k.fakePointLightIntensity = attrReal(e, "fake_point_light_intensity", k.fakePointLightIntensity);
        k.warmColour = parseVector3(attr(e, "warm_color"), k.warmColour);
        k.coldColour = parseVector3(attr(e, "cold_color"), k.coldColour);
        k.enhanceContrast = parseVector3(attr(e, "enhance_constrast"), k.enhanceContrast);
        k.overlayImage = parseVector3(attr(e, "overlay_image"), k.overlayImage);
        k.radialBlur = parseVector2(attr(e, "radial_blur"), k.radialBlur);
        k.lightSpecularIntensity = attrReal(e, "light_specular_intensity", k.lightSpecularIntensity);

        k.actorLightOne = colourAttr(e, "actor_light_one", k.actorLightOne);
        k.actorLightOneIntensity = attrReal(e, "actor_light_one_intensity", k.actorLightOneIntensity);
        k.actorLightTwo = colourAttr(e, "actor_light_two", k.actorLightTwo);
        k.actorLightTwoIntensity = attrReal(e, "actor_light_two_intensity", k.actorLightTwoIntensity);
        if (source == CYS_ENVKEY_SKYSPHERE)
            k.actorLightTwoIntensity = attrReal(e, "actor_light_Two_intensity", k.actorLightTwoIntensity);
        k.actorAmbient = colourAttr(e, "actor_light_ambient", k.actorAmbient);
        k.selectActorLight = colourAttr(e, "selectactor_light", k.selectActorLight);

        k.heightFogEnabled = attrBool(e, "height_fog_enabled", k.heightFogEnabled);
        const char* hfog = attr(e, "height_fog_param");
        if (hfog && !cysParseHeightFogParam(hfog, k.heightFog))
            CYSSceneStats::instance().unknown(kind + " " + path + "@height_fog_param (malformed value)", file);

        k.skyDomeAmbientColour = parseVector3(attr(e, "skyDomeAmbientColor"), Ogre::Vector3::ZERO);
        k.skyDomeAmbientStrength = attrReal(e, "skyDomeAmbientColorStrength", 0.0f);

        // Fix-ups of the B reader: unset actor lights follow the scene lights; unset sky-dome ambient is white.
        if (isZeroRGB(k.actorLightOne))
            k.actorLightOne = k.lightOne;
        if (isZeroRGB(k.actorLightTwo))
            k.actorLightTwo = k.lightTwo;
        if (isZeroRGB(k.actorAmbient))
            k.actorAmbient = k.ambient;
        if (k.skyDomeAmbientColour == Ogre::Vector3::ZERO)
            k.skyDomeAmbientColour = Ogre::Vector3(1.0f, 1.0f, 1.0f);
        if (k.skyDomeAmbientStrength == 0.0f)
            k.skyDomeAmbientStrength = 1.0f;
        return k;
    }

    //////////////////////////////////////////////////////////////////////////
    // CYSEnvKeyTrack
    //////////////////////////////////////////////////////////////////////////
    namespace
    {
        struct KeyTimeLess
        {
            bool operator()(const CYSEnvKey& a, const CYSEnvKey& b) const { return a.time < b.time; }
            bool operator()(Real t, const CYSEnvKey& b) const { return t < b.time; }
        };
    }
    //-----------------------------------------------------------------------
    void CYSEnvKeyTrack::add(const CYSEnvKey& key)
    {
        Keys::iterator it = std::upper_bound(mKeys.begin(), mKeys.end(), key, KeyTimeLess());
        mKeys.insert(it, key);
    }
    //-----------------------------------------------------------------------
    CYSEnvKey CYSEnvKeyTrack::sample(Real hours) const
    {
        if (mKeys.empty())
            return CYSEnvKey();
        const Real h = wrapHours(hours);
        if (mKeys.size() == 1)
        {
            CYSEnvKey k = mKeys.front();
            k.time = h;
            return k;
        }

        Keys::const_iterator upper = std::upper_bound(mKeys.begin(), mKeys.end(), h, KeyTimeLess());
        const CYSEnvKey* a;
        const CYSEnvKey* b;
        Real f;
        if (upper == mKeys.begin() || upper == mKeys.end())
        {
            // Between the last key and the first key of the next day.
            a = &mKeys.back();
            b = &mKeys.front();
            const Real span = b->time + 24.0f - a->time;
            const Real since = (upper == mKeys.begin()) ? h + 24.0f - a->time : h - a->time;
            f = span > 1e-6f ? since / span : 0.0f;
        }
        else
        {
            b = &*upper;
            a = &*(upper - 1);
            const Real span = b->time - a->time;
            f = span > 1e-6f ? (h - a->time) / span : 0.0f;
        }
        CYSEnvKey k = CYSEnvKey::lerp(*a, *b, saturate(f));
        k.time = h;
        return k;
    }
}
