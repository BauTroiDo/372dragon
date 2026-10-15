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
#include "OgreColourFadingAffector.h"
#include "OgreParticleSystem.h"
#include "OgreParticle.h"
#include "OgreStringConverter.h"

#include <math.h>

namespace Ogre {

	// Instantiate statics
	ColourFadingAffector::CmdOpacity ColourFadingAffector::msOpacityCmd;
	ColourFadingAffector::CmdFadeInTime ColourFadingAffector::msFadeInTimeCmd;
	ColourFadingAffector::CmdFadeOutTime ColourFadingAffector::msFadeOutTimeCmd;
	ColourFadingAffector::CmdColourAdjust		ColourFadingAffector::msColourCmd[MAX_STAGES];
	ColourFadingAffector::CmdTimeAdjust		ColourFadingAffector::msTimeCmd[MAX_STAGES];
	ColourFadingAffector::CmdOpacityAdjust	ColourFadingAffector::msOpacityAdjCmd[MAX_STAGES]; // CYS
	ColourFadingAffector::CmdRepeatTimes		ColourFadingAffector::msRepeatTimesCmd;

	//-----------------------------------------------------------------------
	ColourFadingAffector::ColourFadingAffector(ParticleSystem* psys)
		:ParticleAffector(psys)
	{
		mType = "ColourFading";

		mOpacity = 1.0f;
		mFadeInTime = 0.0f;
		mFadeOutTime = 1.0f;

		// CYS: client_GL defaults - black stages of full opacity; stage 0 at life 0, the others at 1.
		// (0.85: transparent grey stages, every time 1.0 - which pinned most client_GL curves to stage 0)
		for (int i=0;i<MAX_STAGES;i++)
		{
			mColourAdj[i]	= ColourValue::Black;
			mTimeAdj[i]		= 1.0f;
			mOpacityAdj[i]	= 1.0f;
		}
		mTimeAdj[0] = 0.0f;

		mRepeatTimes = 1.0f;

		// Set up parameters
		if (createParamDictionary("ColourFadingAffector"))
		{
			addBaseParameters();
			// Add extra paramaters
			ParamDictionary* dict = getParamDictionary();

			for (int i=0;i<MAX_STAGES;i++)
			{
				msColourCmd[i].mIndex	= i;
				msTimeCmd[i].mIndex		= i;
				msOpacityAdjCmd[i].mIndex = i; // CYS

				StringUtil::StrStreamType stage;
				stage << i;
				const String n = stage.str();

				dict->addParameter(ParameterDef("colour" + n, "Stage " + n + " colour.", PT_COLOURVALUE), &msColourCmd[i]);
				dict->addParameter(ParameterDef("time" + n, "Stage " + n + " time.", PT_REAL), &msTimeCmd[i]);
				// CYS: B per-stage alpha
				dict->addParameter(ParameterDef("opacity" + n, "Stage " + n + " opacity.", PT_REAL), &msOpacityAdjCmd[i]);
			}

			dict->addParameter(ParameterDef("repeat_times",
				"the repeat times of the colour interpolate.",
				PT_REAL), &msRepeatTimesCmd);

			dict->addParameter(ParameterDef("opacity",
				"the opacity of particle.",
				PT_REAL),&msOpacityCmd);
			dict->addParameter(ParameterDef("fade_in_time",
				"life fraction over which the opacity rises from 0 to 'opacity'.",
				PT_REAL),&msFadeInTimeCmd);
			dict->addParameter(ParameterDef("fade_out_time",
				"life fraction after which the opacity falls from 'opacity' to 0.",
				PT_REAL),&msFadeOutTimeCmd);
		}

	}
	void ColourFadingAffector::_initParticle(Particle* pParticle)
	{
		// the colour of a born particle is black, so the emitter colour does not leak into the curve
		pParticle->colour = ColourValue::Black;
	}
	//-----------------------------------------------------------------------
	ColourValue ColourFadingAffector::evaluate(Real age, const ColourValue& previous) const
	{
		// CYS: stage lookup of client_GL ColourFading (07b-particles_vi.md, section ColourFading)
		const Real t = (mRepeatTimes != 1.0f) ? fmodf(age * mRepeatTimes, 1.0f) : age;

		ColourValue c = previous;
		if (!(mTimeAdj[0] < t))
		{
			c = mColourAdj[0];
			c.a = mOpacityAdj[0];
		}
		else if (t < mTimeAdj[MAX_STAGES - 1])
		{
			for (int i = 0; i < MAX_STAGES - 1; ++i)
			{
				const Real t0 = mTimeAdj[i];
				const Real t1 = mTimeAdj[i + 1];
				if (t0 <= t && t < t1)
				{
					const Real f = (t - t0) / (t1 - t0);
					const Real g = 1.0f - f;
					const ColourValue& c0 = mColourAdj[i];
					const ColourValue& c1 = mColourAdj[i + 1];
					c.r = g * c0.r + f * c1.r;
					c.g = g * c0.g + f * c1.g;
					c.b = g * c0.b + f * c1.b;
					c.a = g * mOpacityAdj[i] + f * mOpacityAdj[i + 1];
					break;
				}
			}
		}
		else
		{
			// past the last stage time: the first stage placed at the end of the life (or the last one)
			for (int i = 0; i < MAX_STAGES; ++i)
			{
				if (mTimeAdj[i] >= 1.0f || i == MAX_STAGES - 1)
				{
					c = mColourAdj[i];
					c.a = mOpacityAdj[i];
					break;
				}
			}
		}

		// opacity envelope over the real (not repeated) life
		Real opacity = mOpacity;
		if (mFadeInTime < age || mFadeInTime == 0.0f)
		{
			if (mFadeOutTime <= age && mFadeOutTime != 1.0f)
				opacity *= 1.0f - (age - mFadeOutTime) / (1.0f - mFadeOutTime);
		}
		else
		{
			opacity *= age / mFadeInTime;
		}

		c.r *= opacity;
		c.g *= opacity;
		c.b *= opacity;
		c.a *= opacity;
		return c;
	}
	//-----------------------------------------------------------------------
	void ColourFadingAffector::_affectParticles(ParticleSystem* pSystem, Real timeElapsed)
	{
		ParticleIterator	pi				= pSystem->_getIterator();

		while (!pi.end())
		{
			Particle* p = pi.getNext();
			// CYS: a zero life would give 0/0; such a particle is expired on the next update anyway
			const Real age = (p->totalTimeToLive > 0.0f) ? 1.0f - (p->timeToLive / p->totalTimeToLive) : 1.0f;
			p->colour = evaluate(age, p->colour);
		}
	}
	//-----------------------------------------------------------------------
	void ColourFadingAffector::setColourAdjust(size_t index, ColourValue colour)
	{
		mColourAdj[index] = colour;
	}
	//-----------------------------------------------------------------------
	ColourValue ColourFadingAffector::getColourAdjust(size_t index) const
	{
		return mColourAdj[index];
	}
	//-----------------------------------------------------------------------
	void ColourFadingAffector::setTimeAdjust(size_t index, Real time)
	{
		mTimeAdj[index] = time;
	}
	//-----------------------------------------------------------------------
	Real ColourFadingAffector::getTimeAdjust(size_t index) const
	{
		return mTimeAdj[index];
	}
	//-----------------------------------------------------------------------
	void ColourFadingAffector::setOpacityAdjust(size_t index, Real opacity)
	{
		mOpacityAdj[index] = opacity;
	}
	//-----------------------------------------------------------------------
	Real ColourFadingAffector::getOpacityAdjust(size_t index) const
	{
		return mOpacityAdj[index];
	}
	//-----------------------------------------------------------------------
	//-----------------------------------------------------------------------
	// Command objects
	//-----------------------------------------------------------------------
	//-----------------------------------------------------------------------
	String ColourFadingAffector::CmdColourAdjust::doGet(const void* target) const
	{
		return StringConverter::toString(
			static_cast<const ColourFadingAffector*>(target)->getColourAdjust(mIndex) );
	}
	void ColourFadingAffector::CmdColourAdjust::doSet(void* target, const String& val)
	{
		static_cast<ColourFadingAffector*>(target)->setColourAdjust(mIndex,
			StringConverter::parseColourValue(val));
	}
#if OGRE_STRING_INTERFACE_COPY
    //-----------------------------------------------------------------------
    void ColourFadingAffector::CmdColourAdjust::doCopy(void* target, const void* source)
    {
        static_cast<ColourFadingAffector*>(target)->setColourAdjust(mIndex,
            static_cast<const ColourFadingAffector*>(source)->getColourAdjust(mIndex) );
    }
#endif
	//-----------------------------------------------------------------------
	String ColourFadingAffector::CmdTimeAdjust::doGet(const void* target) const
	{
		return StringConverter::toString(
			static_cast<const ColourFadingAffector*>(target)->getTimeAdjust(mIndex) );
	}
	void ColourFadingAffector::CmdTimeAdjust::doSet(void* target, const String& val)
	{
		static_cast<ColourFadingAffector*>(target)->setTimeAdjust(mIndex,
			StringConverter::parseReal(val));
	}
#if OGRE_STRING_INTERFACE_COPY
    //-----------------------------------------------------------------------
    void ColourFadingAffector::CmdTimeAdjust::doCopy(void* target, const void* source)
    {
        static_cast<ColourFadingAffector*>(target)->setTimeAdjust(mIndex,
            static_cast<const ColourFadingAffector*>(source)->getTimeAdjust(mIndex) );
    }
#endif
	//-----------------------------------------------------------------------
	// CYS: per-stage opacity
	String ColourFadingAffector::CmdOpacityAdjust::doGet(const void* target) const
	{
		return StringConverter::toString(
			static_cast<const ColourFadingAffector*>(target)->getOpacityAdjust(mIndex) );
	}
	void ColourFadingAffector::CmdOpacityAdjust::doSet(void* target, const String& val)
	{
		static_cast<ColourFadingAffector*>(target)->setOpacityAdjust(mIndex,
			StringConverter::parseReal(val));
	}
#if OGRE_STRING_INTERFACE_COPY
    //-----------------------------------------------------------------------
    void ColourFadingAffector::CmdOpacityAdjust::doCopy(void* target, const void* source)
    {
        static_cast<ColourFadingAffector*>(target)->setOpacityAdjust(mIndex,
            static_cast<const ColourFadingAffector*>(source)->getOpacityAdjust(mIndex) );
    }
#endif
	//-----------------------------------------------------------------------
	String ColourFadingAffector::CmdRepeatTimes::doGet(const void* target) const
	{
		return StringConverter::toString(
			static_cast<const ColourFadingAffector*>(target)->getRepeatTimes() );
	}
	void ColourFadingAffector::CmdRepeatTimes::doSet(void* target, const String& val)
	{
		static_cast<ColourFadingAffector*>(target)->setRepeatTimes(
			StringConverter::parseReal(val));
	}
#if OGRE_STRING_INTERFACE_COPY
    //-----------------------------------------------------------------------
    void ColourFadingAffector::CmdRepeatTimes::doCopy(void* target, const void* source)
    {
        static_cast<ColourFadingAffector*>(target)->setRepeatTimes(
            static_cast<const ColourFadingAffector*>(source)->getRepeatTimes() );
    }
#endif
	//-----------------------------------------------------------------------
	String ColourFadingAffector::CmdOpacity::doGet(const void* target) const
	{
		return StringConverter::toString(
			static_cast<const ColourFadingAffector*>(target)->getOpacity() );
	}
	void ColourFadingAffector::CmdOpacity::doSet(void* target, const String& val)
	{
		static_cast<ColourFadingAffector*>(target)->setOpacity( StringConverter::parseReal(val) );
	}
#if OGRE_STRING_INTERFACE_COPY
    //-----------------------------------------------------------------------
    void ColourFadingAffector::CmdOpacity::doCopy(void* target, const void* source)
    {
        static_cast<ColourFadingAffector*>(target)->setOpacity(
            static_cast<const ColourFadingAffector*>(source)->getOpacity() );
    }
#endif
	//-----------------------------------------------------------------------
	String ColourFadingAffector::CmdFadeInTime::doGet(const void* target) const
	{
		return StringConverter::toString(
			static_cast<const ColourFadingAffector*>(target)->getFadeInTime() );
	}
	void ColourFadingAffector::CmdFadeInTime::doSet(void* target, const String& val)
	{
		static_cast<ColourFadingAffector*>(target)->setFadeInTime( StringConverter::parseReal(val) );
	}
#if OGRE_STRING_INTERFACE_COPY
    //-----------------------------------------------------------------------
    void ColourFadingAffector::CmdFadeInTime::doCopy(void* target, const void* source)
    {
        static_cast<ColourFadingAffector*>(target)->setFadeInTime(
            static_cast<const ColourFadingAffector*>(source)->getFadeInTime() );
    }
#endif
	//-----------------------------------------------------------------------
	String ColourFadingAffector::CmdFadeOutTime::doGet(const void* target) const
	{
		return StringConverter::toString(
			static_cast<const ColourFadingAffector*>(target)->getFadeOutTime() );
	}
	void ColourFadingAffector::CmdFadeOutTime::doSet(void* target, const String& val)
	{
		static_cast<ColourFadingAffector*>(target)->setFadeOutTime( StringConverter::parseReal(val) );
	}
#if OGRE_STRING_INTERFACE_COPY
    //-----------------------------------------------------------------------
    void ColourFadingAffector::CmdFadeOutTime::doCopy(void* target, const void* source)
    {
        static_cast<ColourFadingAffector*>(target)->setFadeOutTime(
            static_cast<const ColourFadingAffector*>(source)->getFadeOutTime() );
    }
#endif
}

