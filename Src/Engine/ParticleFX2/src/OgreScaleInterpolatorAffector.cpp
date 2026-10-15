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
#include "OgreScaleInterpolatorAffector.h"
#include "OgreParticleSystem.h"
#include "OgreParticle.h"
#include "OgreStringConverter.h"

#include <math.h>

namespace Ogre {

    // init statics
    ScaleInterpolatorAffector::CmdUseUniformSize ScaleInterpolatorAffector::msUseUniformSizeCmd;
    ScaleInterpolatorAffector::CmdWidthRangeStart ScaleInterpolatorAffector::msWidthRangeStartCmd;
    ScaleInterpolatorAffector::CmdWidthRangeEnd ScaleInterpolatorAffector::msWidthRangeEndCmd;
    ScaleInterpolatorAffector::CmdHeightRangeStart ScaleInterpolatorAffector::msHeightRangeStartCmd;
    ScaleInterpolatorAffector::CmdHeightRangeEnd ScaleInterpolatorAffector::msHeightRangeEndCmd;
    ScaleInterpolatorAffector::CmdDepthRangeStart ScaleInterpolatorAffector::msDepthRangeStartCmd;
    ScaleInterpolatorAffector::CmdDepthRangeEnd ScaleInterpolatorAffector::msDepthRangeEndCmd;
    ScaleInterpolatorAffector::CmdUseConstantScale ScaleInterpolatorAffector::msUseConstantScaleCmd;
    ScaleInterpolatorAffector::CmdConstantScale ScaleInterpolatorAffector::msConstantScaleCmd;
    ScaleInterpolatorAffector::CmdUseInterpolatedScale ScaleInterpolatorAffector::msUseInterpolatedScaleCmd;
    ScaleInterpolatorAffector::CmdScaleAdjust ScaleInterpolatorAffector::msScaleCmd[MAX_STAGES];
    ScaleInterpolatorAffector::CmdTimeAdjust ScaleInterpolatorAffector::msTimeCmd[MAX_STAGES];
    ScaleInterpolatorAffector::CmdRepeatTimes ScaleInterpolatorAffector::msRepeatTimesCmd;
    ScaleInterpolatorAffector::CmdUseInterpolatedIncrement ScaleInterpolatorAffector::msUseInterpolatedIncrementCmd;
    ScaleInterpolatorAffector::CmdIncrementValue ScaleInterpolatorAffector::msIncrementValueCmd[MAX_STAGES];
    ScaleInterpolatorAffector::CmdIncrementTime ScaleInterpolatorAffector::msIncrementTimeCmd[MAX_STAGES];
    ScaleInterpolatorAffector::CmdIncrementRepeatTimes ScaleInterpolatorAffector::msIncrementRepeatTimesCmd;

    namespace
    {
        /** Stage curve of the client_GL affectors: t <= key0 -> v0, t >= key5 -> v5, otherwise the first
            segment [t_i, t_i+1) containing t is interpolated. False = no segment (value unchanged). */
        bool cysStageCurve(const Real* times, const Vector3* values, int count, Real t, Vector3& out)
        {
            if (!(times[0] < t))
            {
                out = values[0];
                return true;
            }
            if (!(t < times[count - 1]))
            {
                out = values[count - 1];
                return true;
            }
            for (int i = 0; i < count - 1; ++i)
            {
                if (times[i] <= t && t < times[i + 1])
                {
                    const Real f = (t - times[i]) / (times[i + 1] - times[i]);
                    out = values[i] * (1.0f - f) + values[i + 1] * f;
                    return true;
                }
            }
            return false;
        }

        inline Real cysWrap(Real age, Real repeat)
        {
            return (repeat != 1.0f) ? fmodf(age * repeat, 1.0f) : age;
        }
    }

    //-----------------------------------------------------------------------
    ScaleInterpolatorAffector::ScaleInterpolatorAffector(ParticleSystem* psys)
        : ParticleAffector(psys)
    {
        // CYS: client_GL defaults (07b-particles_vi.md): scale stages 1, stage 0 at life 0 and the others at 1;
        // the interpolated scale is ON by default; increments 1 at every stage, all increment times 1.
        for (int i=0;i<MAX_STAGES;i++)
        {
            mScaleAdj[i]	= Vector3(1.0f, 1.0f, 1.0f);
            mTimeAdj[i]		= 1.0f;
            mIncrementAdj[i] = Vector3(1.0f, 1.0f, 1.0f);
            mIncrementTimeAdj[i] = 1.0f;
        }
        mTimeAdj[0] = 0.0f;

		mRepeatTimes = 1.0f;
		mIncrementRepeatTimes = 1.0f;

		mConstantScaleValue = Vector3(1.0f, 1.0f, 1.0f);
		mUseConstantScale = false;
		mUseInterpolatedScale = true;
		mUseUniformSize = true;
		mUseInterpolatedIncrement = false;

		// the born size range is the system default size unless the script changes it
		mWidthRangeStart = mWidthRangeEnd = psys ? psys->getDefaultWidth() : 1.0f;
		mHeightRangeStart = mHeightRangeEnd = psys ? psys->getDefaultHeight() : 1.0f;
		mDepthRangeStart = mDepthRangeEnd = psys ? psys->getDefaultDepth() : 0.0f;

        mType = "ScaleInterpolator";

        // Init parameters
        if (createParamDictionary("ScaleInterpolatorAffector"))
        {
            ParamDictionary* dict = getParamDictionary();

			dict->addParameter(ParameterDef("uniform_size",
				"If true the born width is used for height and depth too.", PT_BOOL), &msUseUniformSizeCmd);
			dict->addParameter(ParameterDef("width_range_start",
				"The minimum width of particles in world units.", PT_REAL), &msWidthRangeStartCmd);
			dict->addParameter(ParameterDef("width_range_end",
				"The maximum width of particles in world units.", PT_REAL), &msWidthRangeEndCmd);
			dict->addParameter(ParameterDef("height_range_start",
				"The minimum height of particles in world units.", PT_REAL), &msHeightRangeStartCmd);
			dict->addParameter(ParameterDef("height_range_end",
				"The maximum height of particles in world units.", PT_REAL), &msHeightRangeEndCmd);
			// CYS: client_GL third dimension
			dict->addParameter(ParameterDef("depth_range_start",
				"The minimum depth of particles in world units.", PT_REAL), &msDepthRangeStartCmd);
			dict->addParameter(ParameterDef("depth_range_end",
				"The maximum depth of particles in world units.", PT_REAL), &msDepthRangeEndCmd);
			dict->addParameter(ParameterDef("use_constant_scale",
				"Grow by constant_scale per second.", PT_BOOL), &msUseConstantScaleCmd);
			dict->addParameter(ParameterDef("constant_scale",
				"Size change per second (width height depth).", PT_VECTOR3), &msConstantScaleCmd);
			dict->addParameter(ParameterDef("use_interpolated_scale",
				"Size = system default size x the scale stage curve.", PT_BOOL), &msUseInterpolatedScaleCmd);

            for (int i=0;i<MAX_STAGES;i++)
            {
                msScaleCmd[i].mIndex	= i;
                msTimeCmd[i].mIndex		= i;

                StringUtil::StrStreamType stage;
                stage << i;
                const String n = stage.str();
                dict->addParameter(ParameterDef("scale" + n, "Stage " + n + " scale.", PT_VECTOR3), &msScaleCmd[i]);
                dict->addParameter(ParameterDef("time" + n, "Stage " + n + " time.", PT_REAL), &msTimeCmd[i]);
            }

			dict->addParameter(ParameterDef("repeat_times",
				"the repeat times of the scale curve.", PT_REAL), &msRepeatTimesCmd);

			// CYS: client_GL increment curve
			dict->addParameter(ParameterDef("use_interpolated_increment",
				"Grow by the increment stage curve per second.", PT_BOOL), &msUseInterpolatedIncrementCmd);
            for (int i=0;i<MAX_STAGES;i++)
            {
                msIncrementValueCmd[i].mIndex = i;
                msIncrementTimeCmd[i].mIndex = i;

                StringUtil::StrStreamType stage;
                stage << i;
                const String n = stage.str();
                dict->addParameter(ParameterDef("increment_value" + n, "Stage " + n + " increment value.", PT_VECTOR3),
                    &msIncrementValueCmd[i]);
                dict->addParameter(ParameterDef("increment_time" + n, "Stage " + n + " increment time.", PT_REAL),
                    &msIncrementTimeCmd[i]);
            }
			dict->addParameter(ParameterDef("increment_repeat_times",
				"the repeat times of the increment.", PT_REAL), &msIncrementRepeatTimesCmd);
        }
    }
	/** See ParticleAffector. */
	void ScaleInterpolatorAffector::_initParticle(Particle* pParticle)
	{
		const Real w = mParent->getDefaultWidth();
		const Real h = mParent->getDefaultHeight();
		const Real d = mParent->getDefaultDepth();
		if (mWidthRangeStart != w || mWidthRangeEnd != w ||
			mHeightRangeStart != h || mHeightRangeEnd != h ||
			mDepthRangeStart != d || mDepthRangeEnd != d)
		{
			if (mUseUniformSize)
			{
				const Real size = Math::RangeRandom(mWidthRangeStart, mWidthRangeEnd);
				pParticle->setDimensions(size, size, size);
			}
			else
			{
				// CYS: same draw order as client_GL (depth, height, width)
				const Real nd = Math::RangeRandom(mDepthRangeStart, mDepthRangeEnd);
				const Real nh = Math::RangeRandom(mHeightRangeStart, mHeightRangeEnd);
				const Real nw = Math::RangeRandom(mWidthRangeStart, mWidthRangeEnd);
				pParticle->setDimensions(nw, nh, nd);
			}
		}
	}
    //-----------------------------------------------------------------------
    bool ScaleInterpolatorAffector::evaluate(bool hasOwn, const Vector3& current, const Vector3& def, Real age,
        Real timeElapsed, Vector3& result) const
    {
        if (!hasOwn)
        {
            // a particle without own dimensions first takes the system default size
            result = def;
            return true;
        }
        if (mUseConstantScale)
        {
            result = current + mConstantScaleValue * timeElapsed;
            result.makeCeil(Vector3::ZERO);
            return true;
        }
        if (mUseInterpolatedScale)
        {
            Vector3 scale;
            if (!cysStageCurve(mTimeAdj, mScaleAdj, MAX_STAGES, cysWrap(age, mRepeatTimes), scale))
                return false;
            result = def * scale;
            return true;
        }
        if (mUseInterpolatedIncrement)
        {
            Vector3 inc;
            if (!cysStageCurve(mIncrementTimeAdj, mIncrementAdj, MAX_STAGES, cysWrap(age, mIncrementRepeatTimes), inc))
                return false;
            result = current + inc * timeElapsed;
            result.makeCeil(Vector3::ZERO);
            return true;
        }
        return false;
    }
    //-----------------------------------------------------------------------
    void ScaleInterpolatorAffector::_affectParticles(ParticleSystem* pSystem, Real timeElapsed)
    {
        ParticleIterator	pi				= pSystem->_getIterator();
        const Vector3 def(pSystem->getDefaultWidth(), pSystem->getDefaultHeight(), pSystem->getDefaultDepth());

        while (!pi.end())
        {
            Particle* p = pi.getNext();
            const Real age = (p->totalTimeToLive > 0.0f) ? 1.0f - (p->timeToLive / p->totalTimeToLive) : 1.0f;
            const Vector3 current(p->mWidth, p->mHeight, p->mDepth);
            Vector3 dims;
            // CYS perf: an unchanged size is not set again - setDimensions notifies the system and the renderer
            // for every particle, and the flags those calls raise are already raised (same result)
            if (evaluate(p->mOwnDimensions, current, def, age, timeElapsed, dims) &&
                (!p->mOwnDimensions || dims != current))
                p->setDimensions(dims.x, dims.y, dims.z);
        }
    }

}

