#ifndef __CYS_SCENE_COMMON_H__
#define __CYS_SCENE_COMMON_H__





#include "Core/WXPrerequisites.h"

#include <OgreVector2.h>
#include <OgreVector3.h>
#include <OgreVector4.h>
#include <OgreColourValue.h>
#include <OgreQuaternion.h>

#include <map>
#include <vector>

namespace WX
{
    namespace CYSScene
    {
        /// Tolerant number-list parser: reads up to maxCount numbers separated by blanks, ',', ';' or '|'.
        /// Never throws; returns how many numbers were read (the remaining entries of `out` are untouched).
        size_t parseFloats(const char* text, float* out, size_t maxCount);

        Real parseReal(const char* text, Real def);
        int parseInt(const char* text, int def);
        /// true/yes/on/1 and false/no/off/0 (case-insensitive); anything else gives `def`.
        bool parseBool(const char* text, bool def);
        Ogre::Vector2 parseVector2(const char* text, const Ogre::Vector2& def);
        Ogre::Vector3 parseVector3(const char* text, const Ogre::Vector3& def);
        Ogre::Vector4 parseVector4(const char* text, const Ogre::Vector4& def);
        /// "r g b" or "r g b a" (a missing alpha keeps def.a).
        Ogre::ColourValue parseColour(const char* text, const Ogre::ColourValue& def);
        /// "w x y z" (OGRE order).
        Ogre::Quaternion parseQuaternion(const char* text, const Ogre::Quaternion& def);

        inline Real lerp(Real a, Real b, Real t) { return a + (b - a) * t; }
        Ogre::ColourValue lerp(const Ogre::ColourValue& a, const Ogre::ColourValue& b, Real t);
        Ogre::Vector2 lerp(const Ogre::Vector2& a, const Ogre::Vector2& b, Real t);
        Ogre::Vector3 lerp(const Ogre::Vector3& a, const Ogre::Vector3& b, Real t);
        Ogre::Vector4 lerp(const Ogre::Vector4& a, const Ogre::Vector4& b, Real t);
        inline Real saturate(Real v) { return v < 0 ? 0 : (v > 1 ? 1 : v); }

        /// Wraps an hour value into [0, 24).
        Real wrapHours(Real hours);

        /// Lower-case copy (ASCII only; GBK bytes are kept).
        String toLowerAscii(const String& s);
        /// "dir/name.ext" -> "name" (no directory, no extension).
        String baseName(const String& fileName);

        /// One line in the OGRE log (prefix "CYS scene: ") when a LogManager exists.
        void log(const String& message);
        /// Logs only the first time `key` is seen (one line per unknown key, not one per occurrence).
        void logOnce(const String& key, const String& message);
    }

    /// Scene-data load statistics shared by the serializers, the new parsers and Tests/scene: feature counters
    /// (off by default, the game does not need them) and unknown keys (always kept, logged once per key).
    class CYSSceneStats
    {
    public:
        typedef std::map<String, size_t> Counters;

        static CYSSceneStats& instance(void);

        void setCountingEnabled(bool on) { mCounting = on; }
        bool isCountingEnabled(void) const { return mCounting; }

        /// Feature counter, e.g. count("Scene object FakeLight").
        void count(const String& feature, size_t n = 1)
        {
            if (mCounting)
                mCounts[feature] += n;
        }
        /// Unknown key, e.g. unknown("Scene element Foo", "x.Scene"); logged once per key with the first file.
        void unknown(const String& key, const String& where);
        /// A key that is understood but deliberately not applied yet (kept for the report, not an error).
        void deferred(const String& key)
        {
            if (mCounting)
                mDeferred[key] += 1;
        }
        /// A data problem that is not an unknown key (missing referenced file, malformed file); logged once.
        void problem(const String& key, const String& where);

        void clear(void);

        const Counters& getCounts(void) const { return mCounts; }
        const Counters& getUnknowns(void) const { return mUnknowns; }
        const Counters& getDeferred(void) const { return mDeferred; }
        const Counters& getProblems(void) const { return mProblems; }
        size_t getUnknownTotal(void) const;

    private:
        CYSSceneStats(void) : mCounting(false) {}

        bool mCounting;
        Counters mCounts;
        Counters mUnknowns;
        Counters mDeferred;
        Counters mProblems;
    };
}

#endif // __CYS_SCENE_COMMON_H__
