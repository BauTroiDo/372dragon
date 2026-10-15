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
#include "OgreRevolutionAffector.h"
#include "OgreParticleSystem.h"
#include "OgreParticle.h"
#include "OgreStringConverter.h"
#include "OgreNode.h"
#include "OgreSceneNode.h"
#include "OgreMatrix3.h"     // CYS
#include "OgreQuaternion.h"  // CYS

#include <math.h>            // CYS: fmodf

namespace Ogre {

    // Instantiate statics
    RevolutionAffector::CmdRotationSpeed RevolutionAffector::msRotationSpeedCmd;
    RevolutionAffector::CmdRotationAxis RevolutionAffector::msRotationAxisCmd;
	RevolutionAffector::CmdRadiusIncrement RevolutionAffector::msRadiusIncrementCmd;
	RevolutionAffector::CmdRadiusIncrementAdjust		RevolutionAffector::msRadiusIncrementAdjustCmd[MAX_STAGES];
	RevolutionAffector::CmdTimeAdjust		RevolutionAffector::msTimeCmd[MAX_STAGES];
	RevolutionAffector::CmdRepeatTimes		RevolutionAffector::msRepeatTimesCmd;


	RevolutionAffector::CmdUseRadiusIncrementScale		RevolutionAffector::msUseRadiusIncrementScaleCmd;
	RevolutionAffector::CmdCenterOffsetMin      RevolutionAffector::msCenterOffsetMinCmd;
	RevolutionAffector::CmdCenterOffsetMax      RevolutionAffector::msCenterOffsetMaxCmd;


    //-----------------------------------------------------------------------
    RevolutionAffector::RevolutionAffector(ParticleSystem* psys)
        :ParticleAffector(psys)
    {
        mType = "Revolution";

		mRotateAxis = Ogre::Vector3::UNIT_Y;
		mRotationSpeed = 0.0f;

		for (int i=0;i<MAX_STAGES;i++)
		{
			// set default colour to transparent grey, transparent since we might not want to display the particle here
			// grey because when a colour component is 0.5f the maximum difference to another colour component is 0.5f
			mRadiusIncrementAdj[i]	= 0.0f;
			mTimeAdj[i]		= 1.0f;
		}

		mRepeatTimes = 1.0f;

		mCenterOffsetMin = Ogre::Vector3::ZERO;
		mCenterOffsetMax = Ogre::Vector3::ZERO;

		mUseRadiusIncrementScale = false;

		mRadiusIncrement = 0.0f;

        // Default to gravity-like

        // Set up parameters
        if (createParamDictionary("RevolutionAffector"))
        {
            addBaseParameters();
            // Add extra paramaters
            ParamDictionary* dict = getParamDictionary();

			dict->addParameter(ParameterDef("rotation_speed", 
                "the speed of particle circle rotation.",
                PT_REAL),&msRotationSpeedCmd);

            dict->addParameter(ParameterDef("rotation_axis", 
                "The vector representing the force to apply.",
                PT_VECTOR3),&msRotationAxisCmd);

			dict->addParameter(ParameterDef("radius_increment", 
				"the speed of particle circle rotation.",
				PT_REAL),&msRadiusIncrementCmd);

			dict->addParameter(ParameterDef("center_offset_min", 
				"The vector representing the force to apply.",
				PT_VECTOR3),&msCenterOffsetMinCmd);

			dict->addParameter(ParameterDef("center_offset_max", 
				"The vector representing the force to apply.",
				PT_VECTOR3),&msCenterOffsetMaxCmd);

			for (int i=0;i<MAX_STAGES;i++)
			{
				msRadiusIncrementAdjustCmd[i].mIndex	= i;
				msTimeCmd[i].mIndex		= i;

				StringUtil::StrStreamType stage;
				stage << i;
				String	speed_title	= String("radius_increment_scale") + stage.str();
				String	time_title		= String("time") + stage.str();
				String	speed_descr	= String("Stage ") + stage.str() + String(" RadiusIncrementScale.");
				String	time_descr		= String("Stage ") + stage.str() + String(" time.");

				dict->addParameter(ParameterDef(speed_title, speed_descr, PT_REAL), &msRadiusIncrementAdjustCmd[i]);
				dict->addParameter(ParameterDef(time_title,   time_descr,   PT_REAL),		 &msTimeCmd[i]);
			}		

			dict->addParameter(ParameterDef("use_radius_increment_scale", 
				"the repeat times of the colour interpolate.",
				PT_BOOL), &msUseRadiusIncrementScaleCmd);

			dict->addParameter(ParameterDef("repeat_times", 
				"the repeat times of the colour interpolate.",
				PT_REAL), &msRepeatTimesCmd);
        }

    }
    //-----------------------------------------------------------------------
    //-----------------------------------------------------------------------
    // CYS: client_GL RevolutionAffector (Docs/specs/render/07b-particles_vi.md, section Revolution)
    Vector3 RevolutionAffector::_stepVelocity(const Vector3& position, Real timeToLive, Real totalTimeToLive,
        const Vector3& centre, const Matrix3& rotation, Real step, bool lifeAtStepStart) const
    {
        const Vector3 rel = position - centre;

        // velocity which puts the particle at its rotated place at the end of the step
        Vector3 v = (centre + rotation * rel - position) / step;

        Real increment = mRadiusIncrement;
        if (mUseRadiusIncrementScale)
        {
            const Real life = lifeAtStepStart ? timeToLive + step : timeToLive;
            Real t = (totalTimeToLive > 0.0f) ? 1.0f - life / totalTimeToLive : 1.0f;
            if (!Math::RealEqual(mRepeatTimes, 1.0f))
                t = fmodf(t * mRepeatTimes, 1.0f);

            increment = 0.0f;
            if (!(mTimeAdj[0] < t))
                increment = mRadiusIncrementAdj[0];
            else if (!(t < mTimeAdj[MAX_STAGES - 1]))
                increment = mRadiusIncrementAdj[MAX_STAGES - 1];
            else
            {
                for (int i = 0; i < MAX_STAGES - 1; ++i)
                {
                    if (mTimeAdj[i] <= t && t < mTimeAdj[i + 1])
                    {
                        const Real f = (t - mTimeAdj[i]) / (mTimeAdj[i + 1] - mTimeAdj[i]);
                        increment = (1.0f - f) * mRadiusIncrementAdj[i] + f * mRadiusIncrementAdj[i + 1];
                        break;
                    }
                }
            }
        }
        // (the radial direction costs a square root: skipped when it would be scaled by 0 - same result)
        if (increment != 0.0f)
        {
            Vector3 radial = rel;
            radial.normalise();
            v += radial * increment;
        }

        // a shrinking orbit must not jump across the centre: land on it instead
        const Vector3 toCentre = centre - position;
        const Vector3 move = v * step;
        const Vector3 beyond = position + move - centre;
        const Real toCentreSq = toCentre.squaredLength();
        const Real moveSq = move.squaredLength();
        if (beyond.squaredLength() + toCentreSq - moveSq < 0.1f && toCentreSq < moveSq)
            v = toCentre / step;
        return v;
    }
    //-----------------------------------------------------------------------
    void RevolutionAffector::_affectParticles(ParticleSystem* pSystem, Real timeElapsed)
    {
        // the velocity is a displacement divided by the step: nothing to do for an empty step
        if (Math::RealEqual(timeElapsed, 0.0f))
            return;

        // CYS: client_GL splits a step longer than 0.02 s in two halves (the game updates particles at a
        // fixed 0.033 s, so this is the normal path there)
        const bool split = timeElapsed > 0.02f;
        const Real step = split ? timeElapsed * 0.5f : timeElapsed;

        Matrix3 rotation;
        Quaternion(mRotationSpeed * step, mRotateAxis).ToRotationMatrix(rotation);

        // one random centre per update, shared by all particles
        Vector3 centre;
        centre.x = Math::RangeRandom(mCenterOffsetMin.x, mCenterOffsetMax.x);
        centre.y = Math::RangeRandom(mCenterOffsetMin.y, mCenterOffsetMax.y);
        centre.z = Math::RangeRandom(mCenterOffsetMin.z, mCenterOffsetMax.z);
        // world space particles turn about the system position, local ones about the origin
        if (!pSystem->getKeepParticlesInLocalSpace() && pSystem->getParentNode())
            centre += pSystem->getParentNode()->_getDerivedPosition();

        ParticleIterator pi = pSystem->_getIterator();
        while (!pi.end())
        {
            Particle* p = pi.getNext();
            if (p->position == centre)
            {
                p->direction = Vector3::ZERO;
                continue;
            }
            if (!split)
            {
                p->direction = _stepVelocity(p->position, p->timeToLive, p->totalTimeToLive,
                    centre, rotation, step, false);
            }
            else
            {
                // first half: move here; second half: through the direction (_applyMotion adds direction * dt)
                const Vector3 first = _stepVelocity(p->position, p->timeToLive, p->totalTimeToLive,
                    centre, rotation, step, true);
                p->position += first * step;
                const Vector3 second = _stepVelocity(p->position, p->timeToLive, p->totalTimeToLive,
                    centre, rotation, step, false);
                p->direction = second * 0.5f;
            }
        }
    }

	void RevolutionAffector::setRadiusIncrementAdjust(size_t index, Real speed)
	{
		mRadiusIncrementAdj[index] = speed;
	}
	//-----------------------------------------------------------------------
	Real RevolutionAffector::getRadiusIncrementAdjust(size_t index) const
	{
		return mRadiusIncrementAdj[index];
	}


	//-----------------------------------------------------------------------
	void RevolutionAffector::setTimeAdjust(size_t index, Real time)
	{
		mTimeAdj[index] = time;
	}
	//-----------------------------------------------------------------------
	Real RevolutionAffector::getTimeAdjust(size_t index) const
	{
		return mTimeAdj[index];
	}

	//-----------------------------------------------------------------------
	String RevolutionAffector::CmdRepeatTimes::doGet(const void* target) const
	{
		return StringConverter::toString(
			static_cast<const RevolutionAffector*>(target)->getRepeatTimes() );
	}
	void RevolutionAffector::CmdRepeatTimes::doSet(void* target, const String& val)
	{
		static_cast<RevolutionAffector*>(target)->setRepeatTimes(
			StringConverter::parseReal(val));
	}
#if OGRE_STRING_INTERFACE_COPY
    //-----------------------------------------------------------------------
    void RevolutionAffector::CmdRepeatTimes::doCopy(void* target, const void* source)
    {
        static_cast<RevolutionAffector*>(target)->setRepeatTimes(
            static_cast<const RevolutionAffector*>(source)->getRepeatTimes() );
    }
#endif
	String RevolutionAffector::CmdCenterOffsetMin::doGet(const void* target) const
	{
		return StringConverter::toString(
			static_cast<const RevolutionAffector*>(target)->getCenterOffsetMin() );
	}
	void RevolutionAffector::CmdCenterOffsetMin::doSet(void* target, const String& val)
	{
		static_cast<RevolutionAffector*>(target)->setCenterOffsetMin(
			StringConverter::parseVector3(val));
	}
#if OGRE_STRING_INTERFACE_COPY
    //-----------------------------------------------------------------------
    void RevolutionAffector::CmdCenterOffsetMin::doCopy(void* target, const void* source)
    {
        static_cast<RevolutionAffector*>(target)->setCenterOffsetMin(
            static_cast<const RevolutionAffector*>(source)->getCenterOffsetMin() );
    }
#endif
	String RevolutionAffector::CmdCenterOffsetMax::doGet(const void* target) const
	{
		return StringConverter::toString(
			static_cast<const RevolutionAffector*>(target)->getCenterOffsetMax() );
	}
	void RevolutionAffector::CmdCenterOffsetMax::doSet(void* target, const String& val)
	{
		static_cast<RevolutionAffector*>(target)->setCenterOffsetMax(
			StringConverter::parseVector3(val));
	}
#if OGRE_STRING_INTERFACE_COPY
    //-----------------------------------------------------------------------
    void RevolutionAffector::CmdCenterOffsetMax::doCopy(void* target, const void* source)
    {
        static_cast<RevolutionAffector*>(target)->setCenterOffsetMax(
            static_cast<const RevolutionAffector*>(source)->getCenterOffsetMax() );
    }
#endif
	String RevolutionAffector::CmdRadiusIncrementAdjust::doGet(const void* target) const
	{
		return StringConverter::toString(
			static_cast<const RevolutionAffector*>(target)->getRadiusIncrementAdjust(mIndex) );
	}
	void RevolutionAffector::CmdRadiusIncrementAdjust::doSet(void* target, const String& val)
	{
		static_cast<RevolutionAffector*>(target)->setRadiusIncrementAdjust(mIndex,
			StringConverter::parseReal(val));
	}
#if OGRE_STRING_INTERFACE_COPY
    //-----------------------------------------------------------------------
    void RevolutionAffector::CmdRadiusIncrementAdjust::doCopy(void* target, const void* source)
    {
        static_cast<RevolutionAffector*>(target)->setRadiusIncrementAdjust(mIndex,
            static_cast<const RevolutionAffector*>(source)->getRadiusIncrementAdjust(mIndex) );
    }
#endif
	//-----------------------------------------------------------------------
	String RevolutionAffector::CmdTimeAdjust::doGet(const void* target) const
	{
		return StringConverter::toString(
			static_cast<const RevolutionAffector*>(target)->getTimeAdjust(mIndex) );
	}
	void RevolutionAffector::CmdTimeAdjust::doSet(void* target, const String& val)
	{
		static_cast<RevolutionAffector*>(target)->setTimeAdjust(mIndex,
			StringConverter::parseReal(val));
	}
#if OGRE_STRING_INTERFACE_COPY
    //-----------------------------------------------------------------------
    void RevolutionAffector::CmdTimeAdjust::doCopy(void* target, const void* source)
    {
        static_cast<RevolutionAffector*>(target)->setTimeAdjust(mIndex,
            static_cast<const RevolutionAffector*>(source)->getTimeAdjust(mIndex) );
    }
#endif
	String RevolutionAffector::CmdUseRadiusIncrementScale::doGet(const void* target) const
	{
		return StringConverter::toString(
			static_cast<const RevolutionAffector*>(target)->getUseRadiusIncrementScale() );
	}
	void RevolutionAffector::CmdUseRadiusIncrementScale::doSet(void* target, const String& val)
	{
		static_cast<RevolutionAffector*>(target)->setUseRadiusIncrementScale(
			StringConverter::parseBool(val));
	}
#if OGRE_STRING_INTERFACE_COPY
    //-----------------------------------------------------------------------
    void RevolutionAffector::CmdUseRadiusIncrementScale::doCopy(void* target, const void* source)
    {
        static_cast<RevolutionAffector*>(target)->setUseRadiusIncrementScale(
            static_cast<const RevolutionAffector*>(source)->getUseRadiusIncrementScale() );
    }
#endif
    //-----------------------------------------------------------------------
    //-----------------------------------------------------------------------
    // Command objects
    //-----------------------------------------------------------------------
    //-----------------------------------------------------------------------   
	
    //-----------------------------------------------------------------------
    String RevolutionAffector::CmdRotationSpeed::doGet(const void* target) const
    {
        return StringConverter::toString(
            static_cast<const RevolutionAffector*>(target)->mRotationSpeed );
    }
    void RevolutionAffector::CmdRotationSpeed::doSet(void* target, const String& val)
    {
        static_cast<RevolutionAffector*>(target)->mRotationSpeed = StringConverter::parseAngle(val);
    }
#if OGRE_STRING_INTERFACE_COPY
    //-----------------------------------------------------------------------
    void RevolutionAffector::CmdRotationSpeed::doCopy(void* target, const void* source)
    {
        static_cast<RevolutionAffector*>(target)->mRotationSpeed =
            static_cast<const RevolutionAffector*>(source)->mRotationSpeed;
    }
#endif
    String RevolutionAffector::CmdRotationAxis::doGet(const void* target) const
    {
        return StringConverter::toString(
            static_cast<const RevolutionAffector*>(target)->mRotateAxis );
    }
    void RevolutionAffector::CmdRotationAxis::doSet(void* target, const String& val)
    {
        static_cast<RevolutionAffector*>(target)->mRotateAxis = StringConverter::parseVector3(val);
    }
#if OGRE_STRING_INTERFACE_COPY
    //-----------------------------------------------------------------------
    void RevolutionAffector::CmdRotationAxis::doCopy(void* target, const void* source)
    {
        static_cast<RevolutionAffector*>(target)->mRotateAxis =
            static_cast<const RevolutionAffector*>(source)->mRotateAxis;
    }
#endif
	String RevolutionAffector::CmdRadiusIncrement::doGet(const void* target) const
	{
		return StringConverter::toString(
			static_cast<const RevolutionAffector*>(target)->mRadiusIncrement );
	}
	void RevolutionAffector::CmdRadiusIncrement::doSet(void* target, const String& val)
	{
		static_cast<RevolutionAffector*>(target)->mRadiusIncrement = StringConverter::parseReal(val);
	}
#if OGRE_STRING_INTERFACE_COPY
    //-----------------------------------------------------------------------
    void RevolutionAffector::CmdRadiusIncrement::doCopy(void* target, const void* source)
    {
        static_cast<RevolutionAffector*>(target)->mRadiusIncrement = 
            static_cast<const RevolutionAffector*>(source)->mRadiusIncrement;
    }
#endif
}

