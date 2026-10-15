/*
CYS: parameter helpers shared by the CYS effect classes of WXCore (affectors, elements, skill blocks):
  - tolerant parsing of "a b c ..." real lists (missing values keep the current value, extra ones are ignored),
  - value codecs and generic Ogre::ParamCommand classes bound to a data member or to one element of a member
    array, so that every script keyword does not need its own hand-written command class.
The owner class must provide  void _notifyParameterChanged(void)  (may be empty) and a public typedef per
command, so the pointer-to-member is formed inside the owner class.
*/
#ifndef __WXFxParamHelpers_H__
#define __WXFxParamHelpers_H__

#include <OgreStringInterface.h>
#include <OgreStringConverter.h>
#include <OgreString.h>
#include <OgreVector3.h>
#include <OgreVector4.h>
#include <OgreColourValue.h>
#include <OgreQuaternion.h>

#include <vector>

namespace WX {
namespace Fx {

    typedef Ogre::String String;
    typedef Ogre::Real   Real;

    /// Parses up to 'count' blank separated reals; returns how many were read (others are left untouched).
    inline size_t parseReals(const String& val, Real* out, size_t count)
    {
        std::vector<String> tokens = Ogre::StringUtil::split(val, " \t");
        size_t n = 0;
        for (; n < count && n < tokens.size(); ++n)
            out[n] = Ogre::StringConverter::parseReal(tokens[n]);
        return n;
    }

    inline String realsToString(const Real* v, size_t count)
    {
        Ogre::StringUtil::StrStreamType s;
        for (size_t i = 0; i < count; ++i)
        {
            if (i)
                s << ' ';
            s << v[i];
        }
        return s.str();
    }

    //-----------------------------------------------------------------------
    struct RealCodec
    {
        typedef Real Type;
        static void parse(const String& s, Type& v) { v = Ogre::StringConverter::parseReal(s); }
        static String str(const Type& v) { return Ogre::StringConverter::toString(v); }
    };
    struct IntCodec
    {
        typedef int Type;
        static void parse(const String& s, Type& v) { v = Ogre::StringConverter::parseInt(s); }
        static String str(const Type& v) { return Ogre::StringConverter::toString(v); }
    };
    struct BoolCodec
    {
        typedef bool Type;
        static void parse(const String& s, Type& v) { v = Ogre::StringConverter::parseBool(s); }
        static String str(const Type& v) { return Ogre::StringConverter::toString(v); }
    };
    struct StringCodec
    {
        typedef String Type;
        static void parse(const String& s, Type& v) { v = s; }
        static String str(const Type& v) { return v; }
    };
    struct Vector3Codec
    {
        typedef Ogre::Vector3 Type;
        static void parse(const String& s, Type& v) { parseReals(s, &v.x, 3); }
        static String str(const Type& v) { return Ogre::StringConverter::toString(v); }
    };
    struct Vector4Codec
    {
        typedef Ogre::Vector4 Type;
        static void parse(const String& s, Type& v) { parseReals(s, &v.x, 4); }
        static String str(const Type& v) { return realsToString(&v.x, 4); }
    };
    struct ColourCodec
    {
        typedef Ogre::ColourValue Type;
        static void parse(const String& s, Type& v) { parseReals(s, &v.r, 4); }
        static String str(const Type& v) { return Ogre::StringConverter::toString(v); }
    };
    /// two reals kept in a plain struct (Vector2 is not in OGRE 1.2)
    struct Real2
    {
        Real x, y;
    };
    struct Real2Codec
    {
        typedef Real2 Type;
        static void parse(const String& s, Type& v) { parseReals(s, &v.x, 2); }
        static String str(const Type& v) { return realsToString(&v.x, 2); }
    };

    //-----------------------------------------------------------------------
    /** Ogre::ParamCommand bound to a data member of Owner. */
    template <class Owner, class Codec, typename Codec::Type Owner::*Member>
    class MemberCmd : public Ogre::ParamCommand
    {
    public:
        String doGet(const void* target) const
        {
            return Codec::str(static_cast<const Owner*>(target)->*Member);
        }
        void doSet(void* target, const String& val)
        {
            Codec::parse(val, static_cast<Owner*>(target)->*Member);
            static_cast<Owner*>(target)->_notifyParameterChanged();
        }
#if OGRE_STRING_INTERFACE_COPY
        void doCopy(void* target, const void* source)
        {
            static_cast<Owner*>(target)->*Member = static_cast<const Owner*>(source)->*Member;
            static_cast<Owner*>(target)->_notifyParameterChanged();
        }
#endif
    };

    /** Ogre::ParamCommand bound to element mIndex of a member array of Owner ("time0".."time5"). */
    template <class Owner, class Codec, size_t N, typename Codec::Type (Owner::*Member)[N]>
    class ArrayElementCmd : public Ogre::ParamCommand
    {
    public:
        size_t mIndex;

        ArrayElementCmd() : mIndex(0) {}

        String doGet(const void* target) const
        {
            return Codec::str((static_cast<const Owner*>(target)->*Member)[mIndex]);
        }
        void doSet(void* target, const String& val)
        {
            Codec::parse(val, (static_cast<Owner*>(target)->*Member)[mIndex]);
            static_cast<Owner*>(target)->_notifyParameterChanged();
        }
#if OGRE_STRING_INTERFACE_COPY
        void doCopy(void* target, const void* source)
        {
            (static_cast<Owner*>(target)->*Member)[mIndex] = (static_cast<const Owner*>(source)->*Member)[mIndex];
            static_cast<Owner*>(target)->_notifyParameterChanged();
        }
#endif
    };

    /** Stage curve of the "time<i> / <value><i>" keywords of the Fairy affectors:
        t <= t0 -> v0, t >= tLast -> vLast, otherwise linear inside the first stage [t_i, t_i+1) containing t.
        Returns false (result untouched) when no stage contains t (keys not monotonic). */
    template <class V>
    inline bool evalStages(const Real* times, const V* values, size_t count, Real t, V& result)
    {
        if (count == 0)
            return false;
        if (t <= times[0])
        {
            result = values[0];
            return true;
        }
        if (t >= times[count - 1])
        {
            result = values[count - 1];
            return true;
        }
        for (size_t i = 0; i + 1 < count; ++i)
        {
            if (t >= times[i] && t < times[i + 1])
            {
                Real f = (t - times[i]) / (times[i + 1] - times[i]);
                result = values[i] * (1.0f - f) + values[i + 1] * f;
                return true;
            }
        }
        return false;
    }

    /// normalised particle age in [0,1]
    inline Real normalisedAge(Real timeToLive, Real totalTimeToLive)
    {
        return (totalTimeToLive > 0) ? 1.0f - timeToLive / totalTimeToLive : 1.0f;
    }

    /** Logs a message once per key (unknown keyword / value reports must not flood the log). */
    void logOnce(const String& key, const String& message);

} // namespace Fx
} // namespace WX

#endif
