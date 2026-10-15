/*
-----------------------------------------------------------------------------
This source file is part of OGRE
    (Object-oriented Graphics Rendering Engine)
For the latest info, see http://www.ogre3d.org/

Copyright (c) 2000-2005 The OGRE Team
Also see acknowledgements in Readme.html

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU Lesser General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place - Suite 330, Boston, MA 02111-1307, USA, or go to
http://www.gnu.org/copyleft/lesser.txt.
-----------------------------------------------------------------------------
*/
#include "OgreEllipsoidEmitter.h"
#include "OgreParticle.h"
#include "OgreException.h"
#include "OgreStringConverter.h"
#include "OgreMath.h"


/* Implements an Emitter whose emitting points all lie inside an ellipsoid.

   CYS: client_GL (B) version, Docs/specs/render/07b-particles_vi.md section Ellipsoid.
   The emitter frame is (X, Y, Z) = (width, height, depth) ranges; Z is the emitter direction.
   A point is (r cos phi, r sin phi, z) in that frame. z is drawn by inverting the cumulative volume
   of the unit ball (solid), of the unit sphere surface (all inner sizes 1) or of the shell between the
   unit ball and the inner ellipsoid (a, b, c) (hollow); height_range limits z to [2h0-1, 2h1-1] and
   angle_range limits phi. The radius inside the slice at height z is sqrt(1 - z^2) scaled by
   (1 - w^2); inside the hollow band it is a blend of the inner ellipse and the outer circle.
*/

namespace Ogre {

    // CYS: client_GL keys
    EllipsoidEmitter::CmdInnerX EllipsoidEmitter::msCmdInnerX;
    EllipsoidEmitter::CmdInnerY EllipsoidEmitter::msCmdInnerY;
    EllipsoidEmitter::CmdInnerZ EllipsoidEmitter::msCmdInnerZ;
    EllipsoidEmitter::CmdAngleRange EllipsoidEmitter::msCmdAngleRange;
    EllipsoidEmitter::CmdHeightRange EllipsoidEmitter::msCmdHeightRange;

    namespace
    {
        /// equality tolerance of the client_GL checks (Math::RealEqual with FLT_EPSILON)
        const Real cysEps = 1.1920929e-07f;

        /// "a b" -> (a, b); a single number is used for both components
        Vector2 cysParseVector2(const String& val, const Vector2& fallback)
        {
            const StringVector v = StringUtil::split(val);
            if (v.empty())
                return fallback;
            const Real a = StringConverter::parseReal(v[0]);
            return Vector2(a, v.size() > 1 ? StringConverter::parseReal(v[1]) : a);
        }
        String cysToString(const Vector2& v)
        {
            return StringConverter::toString(v.x) + " " + StringConverter::toString(v.y);
        }

        /// cube root keeping the sign
        Real cysCbrt(Real x)
        {
            return (x < 0.0f) ? -Math::Pow(-x, 1.0f / 3.0f) : Math::Pow(x, 1.0f / 3.0f);
        }

        /** Root in [-1, 1] of z^3 - 3z + (2 - 2 arg) = 0, i.e. 2 cos(acos(arg) / 3 + 4 pi / 3)
            (Math::ACos clamps its argument like the original). */
        Real cysCapRoot(Real arg)
        {
            return 2.0f * Math::Cos(Math::ACos(arg).valueRadians() / 3.0f + Math::TWO_PI * 2.0f / 3.0f);
        }

        /// cumulative volume of the unit ball below height z (times 3/pi)
        inline Real cysBallCdf(Real z)
        {
            return ((z * 3.0f - z * z * z) + 2.0f) / 3.0f;
        }
    }

    //-----------------------------------------------------------------------
    EllipsoidEmitter::EllipsoidEmitter(ParticleSystem* psys)
        : AreaEmitter(psys)
    {
        if (initDefaults("Ellipsoid"))
        {
            // CYS: client_GL keys (emitter lines are lower-cased by the script parser)
            ParamDictionary* dict = getParamDictionary();
            const char* hollow = "Parametric value describing the proportion of the shape which is hollow.";
            dict->addParameter(ParameterDef("inner_width", hollow, PT_REAL), &msCmdInnerX);
            dict->addParameter(ParameterDef("inner_height", hollow, PT_REAL), &msCmdInnerY);
            dict->addParameter(ParameterDef("inner_depth", hollow, PT_REAL), &msCmdInnerZ);
            dict->addParameter(ParameterDef("angle_range",
                "Angle around the emitter axis in degrees (min max).", PT_STRING), &msCmdAngleRange);
            dict->addParameter(ParameterDef("height_range",
                "Band along the emitter axis as fractions 0..1 (min max).", PT_STRING), &msCmdHeightRange);
        }
        // CYS: client_GL defaults - solid, full turn, full height
        mCysInner = Vector3::ZERO;
        mCysAngleRange = Vector2(0.0f, 360.0f);
        mCysHeightRange = Vector2(0.0f, 1.0f);
    }
    //-----------------------------------------------------------------------
    int EllipsoidEmitter::sampleMode(void) const
    {
        if (Math::RealEqual(0.0f, mCysInner.x, cysEps) || Math::RealEqual(0.0f, mCysInner.y, cysEps) ||
            Math::RealEqual(0.0f, mCysInner.z, cysEps))
            return 0;
        if (Math::RealEqual(1.0f, mCysInner.x, cysEps) && Math::RealEqual(1.0f, mCysInner.y, cysEps) &&
            Math::RealEqual(1.0f, mCysInner.z, cysEps))
            return 1;
        return 2;
    }
    //-----------------------------------------------------------------------
    Vector2 EllipsoidEmitter::heightDrawRange(void) const
    {
        const Real z0 = mCysHeightRange.x * 2.0f - 1.0f;
        const Real z1 = mCysHeightRange.y * 2.0f - 1.0f;
        const int mode = sampleMode();
        if (mode == 1)
            return Vector2(z0, z1);
        if (mode == 0)
            return Vector2(cysBallCdf(z0), cysBallCdf(z1));

        // hollow: cumulative volume of the shell (outer unit ball minus the inner ellipsoid a, b, c)
        const Real a = mCysInner.x, b = mCysInner.y, c = mCysInner.z;
        const Real ab = a * b;
        const Real k = a * 4.0f * b * c;
        const Real cc = c * c;
        struct Band
        {
            static Real mid(Real z, Real ab, Real cc, Real c, Real abc2)
            {
                return ((ab - cc) * z * z * z) / (c * 3.0f * c) + (1.0f - ab) * z + (2.0f - abc2) / 3.0f;
            }
        };
        const Real abc2 = a * 2.0f * b * c;
        // lower bound: below the inner ellipsoid, inside its band, above it
        Real lo = cysBallCdf(z0);
        if (-c < z0)
            lo = Band::mid(z0, ab, cc, c, abc2);
        if (c < z0)
            lo = (((z0 * 3.0f - z0 * z0 * z0) + 2.0f) - k) / 3.0f;
        // upper bound, same pieces tested from the top
        Real hi = (((z1 * 3.0f - z1 * z1 * z1) + 2.0f) - k) / 3.0f;
        if (z1 < c)
            hi = Band::mid(z1, ab, cc, c, abc2);
        if (z1 < -c)
            hi = cysBallCdf(z1);
        return Vector2(lo, hi);
    }
    //-----------------------------------------------------------------------
    Vector3 EllipsoidEmitter::samplePoint(Real u, Real phi, Real w) const
    {
        const Real rad = Degree(phi).valueRadians();
        const Real cs = Math::Cos(rad);
        const Real sn = Math::Sin(rad);
        const int mode = sampleMode();

        if (mode == 1)
        {
            // surface: u is the height itself (the sphere area is uniform in z)
            const Real s = Math::Sqrt(1.0f - u * u);
            return Vector3(s * cs, s * sn, u);
        }
        if (mode == 0)
        {
            const Real z = cysCapRoot(1.0f - u * 1.5f);
            const Real s = Math::Sqrt(1.0f - z * z) * (1.0f - w * w);
            return Vector3(s * cs, s * sn, z);
        }

        const Real a = mCysInner.x, b = mCysInner.y, c = mCysInner.z;
        const Real ab = a * b;
        const Real abc2 = a * 2.0f * b * c;
        const Real k = a * 4.0f * b * c;
        const Real cc = c * c;
        const Real g0 = ((cc * c - c * 3.0f) + 2.0f) / 3.0f;          // volume below the inner ellipsoid
        const Real g1 = (((c * 3.0f - cc * c) - k) + 2.0f) / 3.0f;    // ... up to its top
        const Real top = (4.0f - k) / 3.0f;                           // whole shell
        // CYS: the original leaves the particle position unset past the top (only reachable by rounding)
        if (u < 0.0f) u = 0.0f;
        if (u > top) u = top;

        if (u <= g0)
        {
            // cap below the inner ellipsoid: a plain ball slice
            const Real z = cysCapRoot(1.0f - u * 1.5f);
            const Real s = Math::Sqrt(1.0f - z * z) * (1.0f - w * w);
            return Vector3(s * cs, s * sn, z);
        }
        if (u >= g1)
        {
            // cap above the inner ellipsoid
            const Real z = cysCapRoot((1.0f - abc2) - u * 1.5f);
            const Real s = Math::Sqrt(1.0f - z * z) * (1.0f - w * w);
            return Vector3(s * cs, s * sn, z);
        }

        // band of the inner ellipsoid: invert (ab - c^2) z^3 / 3c^2 + (1 - ab) z + (2 - 2abc)/3 = u
        Real z;
        if (Math::RealEqual(ab, cc, cysEps))
        {
            z = (u - (2.0f - abc2) / 3.0f) / (1.0f - ab);
        }
        else
        {
            const Real den = ab - cc;
            const Real p = (c * 3.0f * c * (1.0f - ab)) / den;
            const Real q = (((2.0f - abc2) - u * 3.0f) * c * c) / den;
            const Real p3 = p / 3.0f;
            const Real q2 = q * 0.5f;
            const Real disc = p3 * p3 * p3 + q2 * q2;
            if (disc >= 0.0f)
            {
                const Real s = Math::Sqrt(disc);
                z = cysCbrt(s - q2) + cysCbrt(-q2 - s);
            }
            else
            {
                const Real r = Math::Sqrt((p * p * p) / -27.0f);
                z = Math::Cos(Math::ACos((q * -0.5f) / r).valueRadians() / 3.0f + Math::TWO_PI * 2.0f / 3.0f) *
                    Math::Pow(r, 1.0f / 3.0f) * 2.0f;
            }
        }
        const Real inner = Math::Sqrt(1.0f - ((z * z) / c) / c); // inner ellipse at this height
        const Real outer = Math::Sqrt(1.0f - z * z);             // outer circle at this height
        const Real t = w * w;
        return Vector3(t * inner * cs * a + (1.0f - t) * outer * cs,
                       t * inner * sn * b + (1.0f - t) * outer * sn,
                       z);
    }
    //-----------------------------------------------------------------------
    void EllipsoidEmitter::_initParticle(Particle* pParticle)
    {
        // Call superclass
        AreaEmitter::_initParticle(pParticle);

        // CYS: client_GL sampling (draw order: height, angle, radius)
        const Vector2 range = heightDrawRange();
        const Real u = Math::RangeRandom(range.x, range.y);
        const Real phi = Math::RangeRandom(mCysAngleRange.x, mCysAngleRange.y);
        const Real w = (sampleMode() == 1) ? 0.0f : Math::UnitRandom();
        const Vector3 k = samplePoint(u, phi, w);

        pParticle->position = mPosition + k.x * mXRange + k.y * mYRange + k.z * mZRange;

        // Generate complex data by reference
        genEmissionColour(pParticle->colour);
        genEmissionDirection(pParticle->direction);
        genEmissionVelocity(pParticle->direction);

        // Generate simpler data
        pParticle->timeToLive = pParticle->totalTimeToLive = genEmissionTTL();

    }
    //-----------------------------------------------------------------------
    // CYS: command objects
    String EllipsoidEmitter::CmdInnerX::doGet(const void* target) const
    {
        return StringConverter::toString(static_cast<const EllipsoidEmitter*>(target)->getInnerSize().x);
    }
    void EllipsoidEmitter::CmdInnerX::doSet(void* target, const String& val)
    {
        static_cast<EllipsoidEmitter*>(target)->setInnerSizeX(StringConverter::parseReal(val));
    }
    String EllipsoidEmitter::CmdInnerY::doGet(const void* target) const
    {
        return StringConverter::toString(static_cast<const EllipsoidEmitter*>(target)->getInnerSize().y);
    }
    void EllipsoidEmitter::CmdInnerY::doSet(void* target, const String& val)
    {
        static_cast<EllipsoidEmitter*>(target)->setInnerSizeY(StringConverter::parseReal(val));
    }
    String EllipsoidEmitter::CmdInnerZ::doGet(const void* target) const
    {
        return StringConverter::toString(static_cast<const EllipsoidEmitter*>(target)->getInnerSize().z);
    }
    void EllipsoidEmitter::CmdInnerZ::doSet(void* target, const String& val)
    {
        static_cast<EllipsoidEmitter*>(target)->setInnerSizeZ(StringConverter::parseReal(val));
    }
    String EllipsoidEmitter::CmdAngleRange::doGet(const void* target) const
    {
        return cysToString(static_cast<const EllipsoidEmitter*>(target)->getAngleRange());
    }
    void EllipsoidEmitter::CmdAngleRange::doSet(void* target, const String& val)
    {
        EllipsoidEmitter* e = static_cast<EllipsoidEmitter*>(target);
        e->setAngleRange(cysParseVector2(val, e->getAngleRange()));
    }
    String EllipsoidEmitter::CmdHeightRange::doGet(const void* target) const
    {
        return cysToString(static_cast<const EllipsoidEmitter*>(target)->getHeightRange());
    }
    void EllipsoidEmitter::CmdHeightRange::doSet(void* target, const String& val)
    {
        EllipsoidEmitter* e = static_cast<EllipsoidEmitter*>(target);
        e->setHeightRange(cysParseVector2(val, e->getHeightRange()));
    }

}


