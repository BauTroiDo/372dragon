// CY-Source (scene agent): see CYSSceneCommon.h.
#include "CYSSceneCommon.h"

#include <OgreLogManager.h>

#include <cstdlib>
#include <cstring>
#include <set>

namespace WX
{
    namespace CYSScene
    {
        namespace
        {
            inline bool isSeparator(char c)
            {
                return c == ' ' || c == '\t' || c == '\r' || c == '\n' || c == ',' || c == ';' || c == '|';
            }

            inline char lowerAscii(char c)
            {
                return (c >= 'A' && c <= 'Z') ? (char)(c - 'A' + 'a') : c;
            }

            bool equalsNoCase(const char* a, const char* b)
            {
                while (*a && *b)
                {
                    if (lowerAscii(*a) != lowerAscii(*b))
                        return false;
                    ++a;
                    ++b;
                }
                return *a == *b;
            }
        }

        size_t parseFloats(const char* text, float* out, size_t maxCount)
        {
            if (!text || !out)
                return 0;

            size_t count = 0;
            const char* p = text;
            while (*p && count < maxCount)
            {
                while (*p && isSeparator(*p))
                    ++p;
                if (!*p)
                    break;
                char* end = NULL;
                const double v = strtod(p, &end);
                if (end == p)
                    break;      // not a number: stop at the malformed tail
                out[count++] = (float)v;
                p = end;
            }
            return count;
        }

        Real parseReal(const char* text, Real def)
        {
            float v;
            return parseFloats(text, &v, 1) == 1 ? v : def;
        }

        int parseInt(const char* text, int def)
        {
            float v;
            if (parseFloats(text, &v, 1) != 1)
                return def;
            return (int)(v < 0 ? v - 0.5f : v + 0.5f);
        }

        bool parseBool(const char* text, bool def)
        {
            if (!text)
                return def;
            while (*text == ' ' || *text == '\t')
                ++text;
            if (equalsNoCase(text, "true") || equalsNoCase(text, "yes") || equalsNoCase(text, "on") ||
                equalsNoCase(text, "1"))
                return true;
            if (equalsNoCase(text, "false") || equalsNoCase(text, "no") || equalsNoCase(text, "off") ||
                equalsNoCase(text, "0"))
                return false;
            return def;
        }

        Ogre::Vector2 parseVector2(const char* text, const Ogre::Vector2& def)
        {
            float v[2] = { def.x, def.y };
            parseFloats(text, v, 2);
            return Ogre::Vector2(v[0], v[1]);
        }

        Ogre::Vector3 parseVector3(const char* text, const Ogre::Vector3& def)
        {
            float v[3] = { def.x, def.y, def.z };
            parseFloats(text, v, 3);
            return Ogre::Vector3(v[0], v[1], v[2]);
        }

        Ogre::Vector4 parseVector4(const char* text, const Ogre::Vector4& def)
        {
            float v[4] = { def.x, def.y, def.z, def.w };
            parseFloats(text, v, 4);
            return Ogre::Vector4(v[0], v[1], v[2], v[3]);
        }

        Ogre::ColourValue parseColour(const char* text, const Ogre::ColourValue& def)
        {
            float v[4] = { def.r, def.g, def.b, def.a };
            parseFloats(text, v, 4);
            return Ogre::ColourValue(v[0], v[1], v[2], v[3]);
        }

        Ogre::Quaternion parseQuaternion(const char* text, const Ogre::Quaternion& def)
        {
            float v[4] = { def.w, def.x, def.y, def.z };
            parseFloats(text, v, 4);
            return Ogre::Quaternion(v[0], v[1], v[2], v[3]);
        }

        Ogre::ColourValue lerp(const Ogre::ColourValue& a, const Ogre::ColourValue& b, Real t)
        {
            return Ogre::ColourValue(lerp(a.r, b.r, t), lerp(a.g, b.g, t), lerp(a.b, b.b, t), lerp(a.a, b.a, t));
        }

        Ogre::Vector2 lerp(const Ogre::Vector2& a, const Ogre::Vector2& b, Real t)
        {
            return Ogre::Vector2(lerp(a.x, b.x, t), lerp(a.y, b.y, t));
        }

        Ogre::Vector3 lerp(const Ogre::Vector3& a, const Ogre::Vector3& b, Real t)
        {
            return Ogre::Vector3(lerp(a.x, b.x, t), lerp(a.y, b.y, t), lerp(a.z, b.z, t));
        }

        Ogre::Vector4 lerp(const Ogre::Vector4& a, const Ogre::Vector4& b, Real t)
        {
            return Ogre::Vector4(lerp(a.x, b.x, t), lerp(a.y, b.y, t), lerp(a.z, b.z, t), lerp(a.w, b.w, t));
        }

        Real wrapHours(Real hours)
        {
            if (hours >= 0 && hours < 24)
                return hours;
            Real h = hours - 24.0f * (Real)(int)(hours / 24.0f);
            if (h < 0)
                h += 24.0f;
            if (h >= 24.0f)
                h = 0;
            return h;
        }

        String toLowerAscii(const String& s)
        {
            String r(s);
            for (size_t i = 0; i < r.size(); ++i)
                r[i] = lowerAscii(r[i]);
            return r;
        }

        String baseName(const String& fileName)
        {
            size_t start = fileName.find_last_of("/\\");
            start = (start == String::npos) ? 0 : start + 1;
            size_t dot = fileName.find_last_of('.');
            if (dot == String::npos || dot < start)
                dot = fileName.size();
            return fileName.substr(start, dot - start);
        }

        void log(const String& message)
        {
            Ogre::LogManager* lm = Ogre::LogManager::getSingletonPtr();
            if (lm)
                lm->logMessage("CYS scene: " + message);
        }

        void logOnce(const String& key, const String& message)
        {
            static std::set<String> seen;
            if (seen.insert(key).second)
                log(message);
        }
    }

    //-----------------------------------------------------------------------
    CYSSceneStats& CYSSceneStats::instance(void)
    {
        static CYSSceneStats stats;
        return stats;
    }
    //-----------------------------------------------------------------------
    void CYSSceneStats::unknown(const String& key, const String& where)
    {
        const size_t n = ++mUnknowns[key];
        if (n == 1)
            CYSScene::log("unknown " + key + (where.empty() ? String() : " (first seen in '" + where + "')"));
    }
    //-----------------------------------------------------------------------
    void CYSSceneStats::problem(const String& key, const String& where)
    {
        const size_t n = ++mProblems[key];
        if (n == 1)
            CYSScene::log("problem: " + key + (where.empty() ? String() : " (first seen in '" + where + "')"));
    }
    //-----------------------------------------------------------------------
    void CYSSceneStats::clear(void)
    {
        mCounts.clear();
        mUnknowns.clear();
        mDeferred.clear();
        mProblems.clear();
    }
    //-----------------------------------------------------------------------
    size_t CYSSceneStats::getUnknownTotal(void) const
    {
        size_t n = 0;
        for (Counters::const_iterator it = mUnknowns.begin(); it != mUnknowns.end(); ++it)
            n += it->second;
        return n;
    }
}
