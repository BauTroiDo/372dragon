/*
CYS: parameter helpers for the CYS affectors of Plugin_ParticleFX2 (RevoluMove, PolarMove).
  - tolerant parsing of "a b c ..." real lists (missing values keep the current value, extra values are ignored),
  - generic ParamCommand classes bound to a data member (or to one element of a member array), so every
    script keyword does not need its own hand-written command class.
The owner class exposes a public typedef per command so the pointer-to-member is formed inside the class.
*/
#ifndef __ParticleFX2ParamHelpers_H__
#define __ParticleFX2ParamHelpers_H__

#include "OgreParticleFX2Prerequisites.h"
#include "OgreStringInterface.h"
#include "OgreStringConverter.h"
#include "OgreString.h"
#include "OgreVector3.h"
#include "OgreMath.h"

#include <vector>

namespace Ogre {
namespace FX2 {

    /// Parses up to 'count' blank separated reals; returns how many were read (others are left untouched).
    inline size_t parseReals(const String& val, Real* out, size_t count)
    {
        std::vector<String> tokens = StringUtil::split(val, " \t");
        size_t n = 0;
        for (; n < count && n < tokens.size(); ++n)
            out[n] = StringConverter::parseReal(tokens[n]);
        return n;
    }

    /// Parses every blank separated real of 'val'.
    inline std::vector<Real> parseRealList(const String& val)
    {
        std::vector<String> tokens = StringUtil::split(val, " \t");
        std::vector<Real> result;
        result.reserve(tokens.size());
        for (size_t i = 0; i < tokens.size(); ++i)
            result.push_back(StringConverter::parseReal(tokens[i]));
        return result;
    }

    inline String realsToString(const Real* v, size_t count)
    {
        StringUtil::StrStreamType s;
        for (size_t i = 0; i < count; ++i)
        {
            if (i)
                s << ' ';
            s << v[i];
        }
        return s.str();
    }

    //-----------------------------------------------------------------------
    // value codecs: parse(text, value) / str(value)
    struct RealCodec
    {
        typedef Real Type;
        static void parse(const String& s, Type& v) { v = StringConverter::parseReal(s); }
        static String str(const Type& v) { return StringConverter::toString(v); }
    };
    struct IntCodec
    {
        typedef int Type;
        static void parse(const String& s, Type& v) { v = StringConverter::parseInt(s); }
        static String str(const Type& v) { return StringConverter::toString(v); }
    };
    struct BoolCodec
    {
        typedef bool Type;
        static void parse(const String& s, Type& v) { v = StringConverter::parseBool(s); }
        static String str(const Type& v) { return StringConverter::toString(v); }
    };
    struct Vector3Codec
    {
        typedef Vector3 Type;
        static void parse(const String& s, Type& v) { parseReals(s, &v.x, 3); }
        static String str(const Type& v) { return StringConverter::toString(v); }
    };
    /// angle in the current OGRE angle unit (degrees by default), stored as Radian
    struct AngleCodec
    {
        typedef Radian Type;
        static void parse(const String& s, Type& v) { v = StringConverter::parseAngle(s); }
        static String str(const Type& v) { return StringConverter::toString(v); }
    };

    //-----------------------------------------------------------------------
    /** ParamCommand bound to a data member of Owner. */
    template <class Owner, class Codec, typename Codec::Type Owner::*Member>
    class MemberCmd : public ParamCommand
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

    /** ParamCommand bound to element mIndex of a member array of Owner (keywords like "time0".."time5"). */
    template <class Owner, class Codec, size_t N, typename Codec::Type (Owner::*Member)[N]>
    class ArrayElementCmd : public ParamCommand
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

    /** Piecewise-linear key curve used by the "time<i>/<value><i>" stage keywords of the WX/Fairy affectors:
        t <= key0 -> value0, t >= keyLast -> valueLast, otherwise lerp inside the first stage [t_i, t_i+1)
        that contains t.  Returns false (value untouched) when no stage contains t (non monotonic keys). */
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

    /// normalised age of a particle in [0,1], optionally wrapped 'repeat' times over the life
    inline Real normalisedAge(Real timeToLive, Real totalTimeToLive, Real repeat)
    {
        Real t = (totalTimeToLive > 0) ? 1.0f - timeToLive / totalTimeToLive : 1.0f;
        if (repeat != 1.0f)
            t = fmod(t * repeat, 1.0f);
        return t;
    }

} // namespace FX2
} // namespace Ogre

#endif
