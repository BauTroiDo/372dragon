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
#ifndef __ColourFadingAffector_H__
#define __ColourFadingAffector_H__

#include "OgreParticleFX2Prerequisites.h"
#include "OgreParticleAffector.h"
#include "OgreColourValue.h"

namespace Ogre {

	/** Colour / opacity curve over the particle life (client_GL "ColourFading").
	@remarks
		CYS: behaviour of the client_GL (B) plug-in, see Docs/specs/render/07b-particles_vi.md.
		Six stages: colourN (RGB; the alpha written in the script is not used), opacityN (alpha)
		and timeN (normalised life 0..1). Defaults: colours black, opacities 1, time0 = 0 and
		time1..5 = 1. 'repeat_times' wraps the stage curve over the life; 'opacity',
		'fade_in_time' and 'fade_out_time' shape a global opacity envelope over the real life.
	*/
	class _OgreParticleFX2Export ColourFadingAffector : public ParticleAffector
	{
	public:

		enum { MAX_STAGES = 6 };

		/** Command object for colour of each stage (see ParamCommand).*/
		class CmdColourAdjust : public ParamCommand
		{
		public:
			size_t		mIndex;

		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif
		};

		/** Command object for time of each stage (see ParamCommand).*/
		class CmdTimeAdjust : public ParamCommand
		{
		public:
			size_t		mIndex;

		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif
        };

		/** CYS: command object for the opacity of each stage (B 'opacityN').*/
		class CmdOpacityAdjust : public ParamCommand
		{
		public:
			size_t		mIndex;

		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif
		};

		/** Command object for repeat times (see ParamCommand).*/
		class CmdRepeatTimes : public ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif
        };

		/** Command object for opacity (see ParamCommand).*/
		class CmdOpacity : public ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif
        };

		/** Command object for the time of fading in (see ParamCommand).*/
		class CmdFadeInTime : public ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif
        };

		/** Command object for the time of fading out (see ParamCommand).*/
		class CmdFadeOutTime : public ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif
        };

		/// Default constructor
		ColourFadingAffector(ParticleSystem* psys);

		/** See ParticleAffector. Born particles start black (the emitter colour is not used). */
		void _initParticle(Particle* pParticle);

		/** See ParticleAffector. */
		void _affectParticles(ParticleSystem* pSystem, Real timeElapsed);

		void setColourAdjust(size_t index, ColourValue colour);
		ColourValue getColourAdjust(size_t index) const;

		void setTimeAdjust(size_t index, Real time);
		Real getTimeAdjust(size_t index) const;

		/// CYS: B 'opacityN' - alpha of stage N
		void setOpacityAdjust(size_t index, Real opacity);
		Real getOpacityAdjust(size_t index) const;

		void setRepeatTimes(Real times)
		{
			mRepeatTimes = times;
		}

		Real getRepeatTimes(void) const
		{
			return mRepeatTimes;
		}

		void setOpacity(Real opacity)
		{
			mOpacity = opacity;
		}

		Real getOpacity(void) const
		{
			return mOpacity;
		}

		void setFadeInTime(Real time)
		{
			mFadeInTime = time;
		}

		Real getFadeInTime(void) const
		{
			return mFadeInTime;
		}

		void setFadeOutTime(Real time)
		{
			mFadeOutTime = time;
		}

		Real getFadeOutTime(void) const
		{
			return mFadeOutTime;
		}

		/** CYS: colour of a particle at normalised life 'age' (0..1), starting from 'previous' (kept
			when the stage table has no segment for the age, as B does). Exposed for the unit tests. */
		ColourValue evaluate(Real age, const ColourValue& previous) const;

		static CmdColourAdjust	msColourCmd[MAX_STAGES];
		static CmdTimeAdjust	msTimeCmd[MAX_STAGES];
		static CmdOpacityAdjust	msOpacityAdjCmd[MAX_STAGES];	// CYS
		static CmdRepeatTimes   msRepeatTimesCmd;
		static CmdOpacity msOpacityCmd;
		static CmdFadeInTime msFadeInTimeCmd;
		static CmdFadeOutTime msFadeOutTimeCmd;

	protected:

		/// global opacity of the particle (envelope maximum)
		Real mOpacity;
		/** fade in time (normalised life): the envelope rises from 0 to mOpacity until this life */
		Real mFadeInTime;

		/** fade out time (normalised life): the envelope falls from mOpacity to 0 after this life */
		Real mFadeOutTime;

		ColourValue				mColourAdj[MAX_STAGES];
		Real					mTimeAdj[MAX_STAGES];
		Real					mOpacityAdj[MAX_STAGES];	// CYS: B 'opacityN'
		Real                    mRepeatTimes;
	};
}

#endif

