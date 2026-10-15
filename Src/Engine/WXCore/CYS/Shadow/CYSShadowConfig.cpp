// CY-Source (shadow agent): shadow configuration. See CYSShadowConfig.h.
#include "CYSShadowConfig.h"

#include <OgreRenderQueue.h>
#include <OgreStringConverter.h>
#include <OgreStringVector.h>

#include <algorithm>
#include <cstdlib>
#include <fstream>
#include <sstream>

namespace WX
{
    namespace
    {
        Ogre::String trimmed(const Ogre::String& s)
        {
            Ogre::String r = s;
            Ogre::StringUtil::trim(r);
            return r;
        }

        Ogre::String lowerTrimmed(const Ogre::String& s)
        {
            Ogre::String r = trimmed(s);
            Ogre::StringUtil::toLowerCase(r);
            return r;
        }

        template <typename T>
        T clampValue(T v, T lo, T hi)
        {
            return v < lo ? lo : (v > hi ? hi : v);
        }

        /// "const,normal" | "auto"
        void parseBias(const Ogre::String& value, Ogre::Real& constBias, Ogre::Real& normalBias)
        {
            const Ogre::String v = lowerTrimmed(value);
            if (v.empty() || v == "auto")
            {
                constBias = normalBias = -1.0f;
                return;
            }
            Ogre::StringVector parts = Ogre::StringUtil::split(v, ", \t");
            if (!parts.empty())
                constBias = parts[0] == "auto" ? -1.0f : Ogre::StringConverter::parseReal(parts[0]);
            if (parts.size() > 1)
                normalBias = parts[1] == "auto" ? -1.0f : Ogre::StringConverter::parseReal(parts[1]);
        }
    }

    //---------------------------------------------------------------------------------------------------------------
    CYSShadowConfig::CYSShadowConfig(void)
        : mode(MODE_CSM)
        , mapSize(4096)
        , cascadeCount(4)
        , maxDistance(5000.0f)
        , splitLambda(0.75f)
        , nearDistance(0.0f)
        , constBias(-1.0f)
        , normalBias(-1.0f)
        , autoConstBias(0.25f)
        , autoNormalBias(1.5f)
        , softness(2)
        , strength(1.0f)
        , pbrStrength(1.0f)
        , useEnvironmentStrength(true)
        , backoff(8000.0f)
        , blendBand(0.1f)
        , fit(FIT_STABLE)
        , lightEpsilonDeg(0.25f)
        , minLightElevationDeg(12.0f)
        , casterQueueMin(Ogre::RENDER_QUEUE_WORLD_GEOMETRY_1)
        , casterQueueMax(Ogre::RENDER_QUEUE_7)
        , alphaTestCasters(true)
        , debugView(false)
    {
    }
    //---------------------------------------------------------------------------------------------------------------
    size_t CYSShadowConfig::apply(const std::map<Ogre::String, Ogre::String>& keyValues)
    {
        size_t used = 0;
        for (std::map<Ogre::String, Ogre::String>::const_iterator it = keyValues.begin(); it != keyValues.end(); ++it)
        {
            const Ogre::String key = lowerTrimmed(it->first);
            const Ogre::String value = trimmed(it->second);
            if (key.compare(0, 10, "gfx_shadow") != 0)
                continue;
            ++used;
            if (key == "gfx_shadow")
            {
                const int m = Ogre::StringConverter::parseInt(value);
                mode = m <= 0 ? MODE_OFF : (m == 1 ? MODE_SIMPLE : MODE_CSM);
            }
            else if (key == "gfx_shadowsize")
                mapSize = (unsigned int)std::max(0, Ogre::StringConverter::parseInt(value));
            else if (key == "gfx_shadowcascades")
                cascadeCount = (unsigned int)std::max(0, Ogre::StringConverter::parseInt(value));
            else if (key == "gfx_shadowdistance")
                maxDistance = Ogre::StringConverter::parseReal(value);
            else if (key == "gfx_shadowsplitlambda")
                splitLambda = Ogre::StringConverter::parseReal(value);
            else if (key == "gfx_shadowsplits")
            {
                splits.clear();
                Ogre::StringVector parts = Ogre::StringUtil::split(value, ", \t");
                for (size_t i = 0; i < parts.size(); ++i)
                    splits.push_back(Ogre::StringConverter::parseReal(parts[i]));
            }
            else if (key == "gfx_shadownear")
                nearDistance = Ogre::StringConverter::parseReal(value);
            else if (key == "gfx_shadowbias")
                parseBias(value, constBias, normalBias);
            else if (key == "gfx_shadowsoftness")
                softness = Ogre::StringConverter::parseInt(value);
            else if (key == "gfx_shadowstrength")
                strength = Ogre::StringConverter::parseReal(value);
            else if (key == "gfx_shadowpbrstrength")
                pbrStrength = Ogre::StringConverter::parseReal(value);
            else if (key == "gfx_shadowbackoff")
                backoff = Ogre::StringConverter::parseReal(value);
            else if (key == "gfx_shadowblend")
                blendBand = Ogre::StringConverter::parseReal(value);
            else if (key == "gfx_shadowfit")
                fit = lowerTrimmed(value) == "tight" ? FIT_TIGHT : FIT_STABLE;
            else if (key == "gfx_shadowdebug")
                debugView = Ogre::StringConverter::parseBool(value) || value == "1";
            else
                --used;
        }
        validate();
        return used;
    }
    //---------------------------------------------------------------------------------------------------------------
    bool CYSShadowConfig::applyFile(const Ogre::String& path)
    {
        std::ifstream f(path.c_str(), std::ios::binary);
        if (!f)
            return false;
        std::map<Ogre::String, Ogre::String> kv;
        std::string line;
        while (std::getline(f, line))
        {
            size_t cut = line.find_first_of("#;");
            const size_t slashes = line.find("//");
            if (slashes != std::string::npos && (cut == std::string::npos || slashes < cut))
                cut = slashes;
            if (cut != std::string::npos)
                line.erase(cut);
            size_t sep = line.find('=');
            if (sep == std::string::npos)
                sep = line.find_first_of(" \t");
            if (sep == std::string::npos)
                continue;
            const Ogre::String key = trimmed(line.substr(0, sep));
            if (!key.empty())
                kv[key] = trimmed(line.substr(sep + 1));
        }
        apply(kv);
        return true;
    }
    //---------------------------------------------------------------------------------------------------------------
    size_t CYSShadowConfig::applyEnvironment(void)
    {
        static const char* const names[][2] = {
            { "CYS_SHADOW", "Gfx_Shadow" },
            { "CYS_SHADOW_SIZE", "Gfx_ShadowSize" },
            { "CYS_SHADOW_CASCADES", "Gfx_ShadowCascades" },
            { "CYS_SHADOW_DISTANCE", "Gfx_ShadowDistance" },
            { "CYS_SHADOW_SOFTNESS", "Gfx_ShadowSoftness" },
            { "CYS_SHADOW_FIT", "Gfx_ShadowFit" },
            { "CYS_SHADOW_BIAS", "Gfx_ShadowBias" },
        };
        std::map<Ogre::String, Ogre::String> kv;
        for (size_t i = 0; i < sizeof(names) / sizeof(names[0]); ++i)
        {
            const char* v = std::getenv(names[i][0]);
            if (v && *v)
                kv[names[i][1]] = v;
        }
        return kv.empty() ? 0 : apply(kv);
    }
    //---------------------------------------------------------------------------------------------------------------
    void CYSShadowConfig::validate(void)
    {
        // Even tile sizes keep the texel grid of a snapped cascade aligned with its tile (CYSShadowSystem).
        mapSize = clampValue(mapSize, 256u, 4096u) & ~15u;
        cascadeCount = clampValue(cascadeCount, 1u, 4u);
        maxDistance = std::max(maxDistance, Ogre::Real(100));
        splitLambda = clampValue(splitLambda, Ogre::Real(0), Ogre::Real(1));
        std::vector<Ogre::Real> s;
        for (size_t i = 0; i < splits.size(); ++i)
            if (splits[i] > 0)
                s.push_back(splits[i]);
        std::sort(s.begin(), s.end());
        if (s.size() >= cascadeCount)
        {
            s.resize(cascadeCount);
            maxDistance = s.back();
            splits = s;
        }
        else
        {
            splits.clear(); // incomplete list: the split scheme decides
        }
        nearDistance = std::max(nearDistance, Ogre::Real(0));
        autoConstBias = clampValue(autoConstBias, Ogre::Real(0), Ogre::Real(8));
        autoNormalBias = clampValue(autoNormalBias, Ogre::Real(0), Ogre::Real(8));
        softness = clampValue(softness, 0, 3);
        strength = clampValue(strength, Ogre::Real(0), Ogre::Real(2));
        pbrStrength = clampValue(pbrStrength, Ogre::Real(0), Ogre::Real(2));
        backoff = std::max(backoff, Ogre::Real(0));
        blendBand = clampValue(blendBand, Ogre::Real(0), Ogre::Real(0.5f));
        lightEpsilonDeg = clampValue(lightEpsilonDeg, Ogre::Real(0), Ogre::Real(10));
        minLightElevationDeg = clampValue(minLightElevationDeg, Ogre::Real(1), Ogre::Real(60));
        if (casterQueueMin > casterQueueMax)
            std::swap(casterQueueMin, casterQueueMax);
    }
    //---------------------------------------------------------------------------------------------------------------
    Ogre::String CYSShadowConfig::describe(void) const
    {
        std::ostringstream o;
        static const char* const modes[] = { "off", "simple", "csm" };
        o << "mode " << modes[mode] << ", tile " << mapSize << ", cascades " << effectiveCascades()
          << ", distance " << maxDistance << ", lambda " << splitLambda;
        if (!splits.empty())
        {
            o << ", splits";
            for (size_t i = 0; i < splits.size(); ++i)
                o << (i ? "," : " ") << splits[i];
        }
        o << ", bias ";
        if (constBias < 0)
            o << "auto(" << autoConstBias << " texel)";
        else
            o << constBias;
        o << "/";
        if (normalBias < 0)
            o << "auto(" << autoNormalBias << " texel)";
        else
            o << normalBias;
        o << ", softness " << softness << ", strength " << strength << "/" << pbrStrength
          << (useEnvironmentStrength ? " (EnvKey wins)" : "") << ", backoff " << backoff << ", blend " << blendBand
          << ", fit " << (fit == FIT_STABLE ? "stable" : "tight") << ", caster queues " << int(casterQueueMin)
          << ".." << int(casterQueueMax) << (alphaTestCasters ? ", alpha-tested casters" : "");
        return o.str();
    }
    //---------------------------------------------------------------------------------------------------------------
    int CYSShadowConfig::shaderType(void) const
    {
        switch (mode)
        {
        case MODE_CSM:
            return 1;
        case MODE_SIMPLE:
            return 2;
        default:
            return 0;
        }
    }
}
