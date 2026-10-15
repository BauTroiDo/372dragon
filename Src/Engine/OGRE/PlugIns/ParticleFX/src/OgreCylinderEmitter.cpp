/*
-----------------------------------------------------------------------------
This source file is part of OGRE
    (Object-oriented Graphics Rendering Engine)
For the latest info, see http://www.ogre3d.org/

Copyright ) 2002 Tels <http://bloodgate.com> based on EllipsoidEmitter
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
#include "OgreCylinderEmitter.h"
#include "OgreParticle.h"
#include "OgreQuaternion.h"
#include "OgreException.h"
#include "OgreStringConverter.h"


/* Implements an Emitter whose emitting points all lie inside a cylinder.
*/

namespace Ogre {

    // CYS: B/Fairy keys
    CylinderEmitter::CmdInnerX CylinderEmitter::msCmdInnerX;
    CylinderEmitter::CmdInnerY CylinderEmitter::msCmdInnerY;
    CylinderEmitter::CmdAngleRange CylinderEmitter::msCmdAngleRange;
    CylinderEmitter::CmdTopDownRatio CylinderEmitter::msCmdTopDownRatio;
    CylinderEmitter::CmdCurve CylinderEmitter::msCmdCurve;
    CylinderEmitter::CmdBendAngle CylinderEmitter::msCmdBendAngle;

    namespace
    {
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
    }

    //-----------------------------------------------------------------------
    CylinderEmitter::CylinderEmitter(ParticleSystem* psys)
        : AreaEmitter(psys)
    {
        if (initDefaults("Cylinder"))
        {
            // CYS: B/Fairy keys. Emitter script lines are lower-cased by the particle script
            // parser, so B's 'BendAngle' arrives as 'bendangle' ('bend_angle' is another client's
            // spelling; the mixed-case name serves setParameter calls from code).
            ParamDictionary* dict = getParamDictionary();
            const char* hollow = "Parametric value describing the proportion of the shape which is hollow.";
            dict->addParameter(ParameterDef("inner_width", hollow, PT_REAL), &msCmdInnerX);
            dict->addParameter(ParameterDef("inner_height", hollow, PT_REAL), &msCmdInnerY);
            dict->addParameter(ParameterDef("angle_range",
                "Sector around the axis in degrees (min max).", PT_STRING), &msCmdAngleRange);
            dict->addParameter(ParameterDef("topdown_ratio",
                "Radius factor at the top (direction end) and at the bottom.", PT_STRING), &msCmdTopDownRatio);
            dict->addParameter(ParameterDef("curve",
                "Barrel (> 0) or waist (< 0) of the radius along the axis.", PT_REAL), &msCmdCurve);
            dict->addParameter(ParameterDef("bendangle",
                "Bends the axis along an arc of this many degrees.", PT_REAL), &msCmdBendAngle);
            dict->addParameter(ParameterDef("bend_angle",
                "Alias of bendangle.", PT_REAL), &msCmdBendAngle);
            dict->addParameter(ParameterDef("BendAngle",
                "Alias of bendangle.", PT_REAL), &msCmdBendAngle);
        }
        // CYS: B defaults - a tube (inner 0.5), full circle, same radius at both ends, straight
        mInnerSize = Vector2(0.5f, 0.5f);
        mAngleRange = Vector2(0.0f, 360.0f);
        mTopDownRatio = Vector2(1.0f, 1.0f);
        mCurve = 0.0f;
        mBendAngle = 0.0f;
    }
    //-----------------------------------------------------------------------
    void CylinderEmitter::setInnerSize(Real x, Real y)
    {
        // CYS: as B, the pair is only taken when both are proper fractions
        if (x > 0 && x < 1 && y > 0 && y < 1)
            mInnerSize = Vector2(x, y);
    }
    //-----------------------------------------------------------------------
    void CylinderEmitter::_initParticle(Particle* pParticle)
    {
        // Call superclass
        AreaEmitter::_initParticle(pParticle);

        // CYS: B/Fairy cylinder, replacing the uniform disc of OGRE 1.2. A point is picked at an
        // angle inside angle_range, at a radius fraction between inner_width/inner_height and 1
        // per cross-section axis, and at h in -1..1 along the axis. The radius is scaled by the
        // barrel curve and by the top/down ratio; then the axis is bent along an arc of BendAngle
        // degrees (arc radius 2/k for the axis length 2). The bend is computed in depth units,
        // so as in B a cylinder of depth 0 loses its width offset.
        const Radian theta = Degree(Math::RangeRandom(mAngleRange.x, mAngleRange.y));
        const Real ra = Math::RangeRandom(mInnerSize.x, 1.0f);
        const Real rb = Math::RangeRandom(mInnerSize.y, 1.0f);
        Real h = Math::SymmetricRandom();

        Real scale = 1.0f;
        if (Math::Abs(mCurve) >= 0.05f)
            scale = 1.0f + mCurve * (1.0f - h * h);
        scale *= mTopDownRatio.y + (mTopDownRatio.x - mTopDownRatio.y) * (h + 1.0f) * 0.5f;

        const Real across = Math::Sin(theta) * ra * scale; // along mXRange (width)
        const Real up = Math::Cos(theta) * rb * scale;     // along mYRange (height)

        const Real xLen = mXRange.length();
        const Real zLen = mZRange.length();
        Real bendX = zLen > 0 ? across * xLen / zLen : 0.0f;
        if (Math::Abs(mBendAngle) >= 0.05f)
        {
            const Real k = -Degree(mBendAngle).valueRadians();
            const Real arcRadius = 2.0f / k;
            const Radian phi(h * 0.5f * k);
            const Real r = bendX + arcRadius;
            bendX = r * Math::Cos(phi) - arcRadius;
            h = r * Math::Sin(phi);
        }
        const Real x = xLen > 0 ? bendX * zLen / xLen : 0.0f;

        pParticle->position = mPosition + x * mXRange + up * mYRange + h * mZRange;

        // Generate complex data by reference
        genEmissionColour(pParticle->colour);
        genEmissionDirection(pParticle->direction);
        genEmissionVelocity(pParticle->direction);

        // Generate simpler data
        pParticle->timeToLive = pParticle->totalTimeToLive = genEmissionTTL();

    }
    //-----------------------------------------------------------------------
    // CYS: command objects
    String CylinderEmitter::CmdInnerX::doGet(const void* target) const
    {
        return StringConverter::toString(static_cast<const CylinderEmitter*>(target)->getInnerSizeX());
    }
    void CylinderEmitter::CmdInnerX::doSet(void* target, const String& val)
    {
        static_cast<CylinderEmitter*>(target)->setInnerSizeX(StringConverter::parseReal(val));
    }
    String CylinderEmitter::CmdInnerY::doGet(const void* target) const
    {
        return StringConverter::toString(static_cast<const CylinderEmitter*>(target)->getInnerSizeY());
    }
    void CylinderEmitter::CmdInnerY::doSet(void* target, const String& val)
    {
        static_cast<CylinderEmitter*>(target)->setInnerSizeY(StringConverter::parseReal(val));
    }
    String CylinderEmitter::CmdAngleRange::doGet(const void* target) const
    {
        return cysToString(static_cast<const CylinderEmitter*>(target)->getAngleRange());
    }
    void CylinderEmitter::CmdAngleRange::doSet(void* target, const String& val)
    {
        CylinderEmitter* e = static_cast<CylinderEmitter*>(target);
        e->setAngleRange(cysParseVector2(val, e->getAngleRange()));
    }
    String CylinderEmitter::CmdTopDownRatio::doGet(const void* target) const
    {
        return cysToString(static_cast<const CylinderEmitter*>(target)->getTopDownRatio());
    }
    void CylinderEmitter::CmdTopDownRatio::doSet(void* target, const String& val)
    {
        CylinderEmitter* e = static_cast<CylinderEmitter*>(target);
        e->setTopDownRatio(cysParseVector2(val, e->getTopDownRatio()));
    }
    String CylinderEmitter::CmdCurve::doGet(const void* target) const
    {
        return StringConverter::toString(static_cast<const CylinderEmitter*>(target)->getCurve());
    }
    void CylinderEmitter::CmdCurve::doSet(void* target, const String& val)
    {
        static_cast<CylinderEmitter*>(target)->setCurve(StringConverter::parseReal(val));
    }
    String CylinderEmitter::CmdBendAngle::doGet(const void* target) const
    {
        return StringConverter::toString(static_cast<const CylinderEmitter*>(target)->getBendAngle());
    }
    void CylinderEmitter::CmdBendAngle::doSet(void* target, const String& val)
    {
        static_cast<CylinderEmitter*>(target)->setBendAngle(StringConverter::parseReal(val));
    }

}


