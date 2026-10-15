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
#ifndef __ScaleInterpolatorAffector_H__
#define __ScaleInterpolatorAffector_H__

#include "OgreParticleFX2Prerequisites.h"
#include "OgreParticleAffector.h"
#include "OgreStringInterface.h"
#include "OgreVector3.h"
#include "OgreParticleFX2ParamHelpers.h" // CYS

namespace Ogre {

    typedef Ogre::Vector3 ScaleValue;

    /** Particle size over the life (client_GL "ScaleInterpolator").
    @remarks
        CYS: behaviour of the client_GL (B) plug-in, see Docs/specs/render/07b-particles_vi.md.
        Particles have three dimensions (width, height, depth). At birth a size is drawn from the
        *_range_start/_end keys when they differ from the system default size. Every update applies
        the first enabled mode: use_constant_scale (size += constant_scale per second),
        use_interpolated_scale (size = system default size x scaleN curve; the DEFAULT mode),
        use_interpolated_increment (size += increment_valueN curve per second).
    */
    class _OgreParticleFX2Export ScaleInterpolatorAffector : public ParticleAffector
    {

    public:

        enum { MAX_STAGES = 6 };

        // CYS: data members first - the command typedefs below take their addresses

		/// the minimum / maximum size of a born particle
		Real mWidthRangeStart;
		Real mWidthRangeEnd;
		Real mHeightRangeStart;
		Real mHeightRangeEnd;
		Real mDepthRangeStart; // CYS
		Real mDepthRangeEnd;   // CYS

		ScaleValue              mConstantScaleValue;
        ScaleValue				mScaleAdj[MAX_STAGES];
        Real					mTimeAdj[MAX_STAGES];
		Real                    mRepeatTimes;

		ScaleValue              mIncrementAdj[MAX_STAGES];     // CYS: increment_valueN
		Real                    mIncrementTimeAdj[MAX_STAGES]; // CYS: increment_timeN
		Real                    mIncrementRepeatTimes;         // CYS

		bool                    mUseConstantScale;
		bool                    mUseInterpolatedScale;
		bool                    mUseUniformSize;
		bool                    mUseInterpolatedIncrement;     // CYS


        // CYS: command objects bound to members (OgreParticleFX2ParamHelpers.h)
        typedef FX2::MemberCmd<ScaleInterpolatorAffector, FX2::BoolCodec, &ScaleInterpolatorAffector::mUseUniformSize> CmdUseUniformSize;
        typedef FX2::MemberCmd<ScaleInterpolatorAffector, FX2::RealCodec, &ScaleInterpolatorAffector::mWidthRangeStart> CmdWidthRangeStart;
        typedef FX2::MemberCmd<ScaleInterpolatorAffector, FX2::RealCodec, &ScaleInterpolatorAffector::mWidthRangeEnd> CmdWidthRangeEnd;
        typedef FX2::MemberCmd<ScaleInterpolatorAffector, FX2::RealCodec, &ScaleInterpolatorAffector::mHeightRangeStart> CmdHeightRangeStart;
        typedef FX2::MemberCmd<ScaleInterpolatorAffector, FX2::RealCodec, &ScaleInterpolatorAffector::mHeightRangeEnd> CmdHeightRangeEnd;
        typedef FX2::MemberCmd<ScaleInterpolatorAffector, FX2::RealCodec, &ScaleInterpolatorAffector::mDepthRangeStart> CmdDepthRangeStart;
        typedef FX2::MemberCmd<ScaleInterpolatorAffector, FX2::RealCodec, &ScaleInterpolatorAffector::mDepthRangeEnd> CmdDepthRangeEnd;
        typedef FX2::MemberCmd<ScaleInterpolatorAffector, FX2::BoolCodec, &ScaleInterpolatorAffector::mUseConstantScale> CmdUseConstantScale;
        typedef FX2::MemberCmd<ScaleInterpolatorAffector, FX2::Vector3Codec, &ScaleInterpolatorAffector::mConstantScaleValue> CmdConstantScale;
        typedef FX2::MemberCmd<ScaleInterpolatorAffector, FX2::BoolCodec, &ScaleInterpolatorAffector::mUseInterpolatedScale> CmdUseInterpolatedScale;
        typedef FX2::ArrayElementCmd<ScaleInterpolatorAffector, FX2::Vector3Codec, MAX_STAGES, &ScaleInterpolatorAffector::mScaleAdj> CmdScaleAdjust;
        typedef FX2::ArrayElementCmd<ScaleInterpolatorAffector, FX2::RealCodec, MAX_STAGES, &ScaleInterpolatorAffector::mTimeAdj> CmdTimeAdjust;
        typedef FX2::MemberCmd<ScaleInterpolatorAffector, FX2::RealCodec, &ScaleInterpolatorAffector::mRepeatTimes> CmdRepeatTimes;
        typedef FX2::MemberCmd<ScaleInterpolatorAffector, FX2::BoolCodec, &ScaleInterpolatorAffector::mUseInterpolatedIncrement> CmdUseInterpolatedIncrement;
        typedef FX2::ArrayElementCmd<ScaleInterpolatorAffector, FX2::Vector3Codec, MAX_STAGES, &ScaleInterpolatorAffector::mIncrementAdj> CmdIncrementValue;
        typedef FX2::ArrayElementCmd<ScaleInterpolatorAffector, FX2::RealCodec, MAX_STAGES, &ScaleInterpolatorAffector::mIncrementTimeAdj> CmdIncrementTime;
        typedef FX2::MemberCmd<ScaleInterpolatorAffector, FX2::RealCodec, &ScaleInterpolatorAffector::mIncrementRepeatTimes> CmdIncrementRepeatTimes;

        /** Default constructor. */
        ScaleInterpolatorAffector(ParticleSystem* psys);

		/** See ParticleAffector. */
		void _initParticle(Particle* pParticle);

        /** See ParticleAffector. */
        void _affectParticles(ParticleSystem* pSystem, Real timeElapsed);

        /// called by the command objects after a value changed (nothing is cached)
        void _notifyParameterChanged(void) {}

        void setScaleAdjust(size_t index, ScaleValue& scale) { mScaleAdj[index] = scale; }
        ScaleValue getScaleAdjust(size_t index) const { return mScaleAdj[index]; }

        void setTimeAdjust(size_t index, Real time) { mTimeAdj[index] = time; }
        Real getTimeAdjust(size_t index) const { return mTimeAdj[index]; }

		void setRepeatTimes(Real times) { mRepeatTimes = times; }
		Real getRepeatTimes(void) const { return mRepeatTimes; }

		void setConstantScale(ScaleValue& scale) { mConstantScaleValue = scale; }
		ScaleValue getConstantScale(void) const { return mConstantScaleValue; }

		void setWidthRangeStart(Real v) { mWidthRangeStart = v; }
		Real getWidthRangeStart(void) const { return mWidthRangeStart; }
		void setWidthRangeEnd(Real v) { mWidthRangeEnd = v; }
		Real getWidthRangeEnd(void) const { return mWidthRangeEnd; }
		void setHeightRangeStart(Real v) { mHeightRangeStart = v; }
		Real getHeightRangeStart(void) const { return mHeightRangeStart; }
		void setHeightRangeEnd(Real v) { mHeightRangeEnd = v; }
		Real getHeightRangeEnd(void) const { return mHeightRangeEnd; }
		void setDepthRangeStart(Real v) { mDepthRangeStart = v; }       // CYS
		Real getDepthRangeStart(void) const { return mDepthRangeStart; } // CYS
		void setDepthRangeEnd(Real v) { mDepthRangeEnd = v; }           // CYS
		Real getDepthRangeEnd(void) const { return mDepthRangeEnd; }     // CYS

		void setUseConstantScale(bool use) { mUseConstantScale = use; }
		bool getUseConstantScale(void) const { return mUseConstantScale; }
		void setUseInterpolatedScale(bool use) { mUseInterpolatedScale = use; }
		bool getUseInterpolatedScale(void) const { return mUseInterpolatedScale; }
		void setUseUniformSize(bool use) { mUseUniformSize = use; }
		bool getUseUniformSize(void) const { return mUseUniformSize; }
		void setUseInterpolatedIncrement(bool use) { mUseInterpolatedIncrement = use; } // CYS
		bool getUseInterpolatedIncrement(void) const { return mUseInterpolatedIncrement; } // CYS

        /** CYS: new dimensions of one particle (w, h, d) for one update, or false when this update does
            not change them. 'current' = own dimensions (hasOwn) and 'def' = the system default size.
            Exposed for the unit tests. */
        bool evaluate(bool hasOwn, const Vector3& current, const Vector3& def, Real age, Real timeElapsed,
            Vector3& result) const;

		static CmdUseUniformSize msUseUniformSizeCmd;
		static CmdWidthRangeStart msWidthRangeStartCmd;
		static CmdWidthRangeEnd msWidthRangeEndCmd;
		static CmdHeightRangeStart msHeightRangeStartCmd;
		static CmdHeightRangeEnd msHeightRangeEndCmd;
		static CmdDepthRangeStart msDepthRangeStartCmd;         // CYS
		static CmdDepthRangeEnd msDepthRangeEndCmd;             // CYS
		static CmdUseConstantScale msUseConstantScaleCmd;
		static CmdConstantScale msConstantScaleCmd;
		static CmdUseInterpolatedScale msUseInterpolatedScaleCmd;
        static CmdScaleAdjust	msScaleCmd[MAX_STAGES];
        static CmdTimeAdjust	msTimeCmd[MAX_STAGES];
		static CmdRepeatTimes   msRepeatTimesCmd;
		static CmdUseInterpolatedIncrement msUseInterpolatedIncrementCmd; // CYS
		static CmdIncrementValue msIncrementValueCmd[MAX_STAGES];        // CYS
		static CmdIncrementTime msIncrementTimeCmd[MAX_STAGES];          // CYS
		static CmdIncrementRepeatTimes msIncrementRepeatTimesCmd;        // CYS

    };


}


#endif
