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
#ifndef __MeshAnimationAffector_H__
#define __MeshAnimationAffector_H__

#include "OgreParticleAffector.h"
#include "OgreVector3.h"


namespace Ogre {

    /** This class defines a ParticleAffector which applies a animation update
        to the mesh particle
    @remarks
        CYS: client_GL behaviour (Render.dll 18013ddc0, Docs/specs/render/07b-particles_vi.md): the
        animation position of a mesh particle is a function of its life. On the first update a 4-key curve
        is built from the animation length and the life of the first emitter's particles (the animation
        plays once at its own speed and holds its last frame; with animation_loop or an animation longer
        than the life the position follows the life and the speed is scaled by life / length).
        animation_range_begin / animation_range_end (0..1) map that position into a part of the animation.
    */
    class MeshAnimationAffector : public ParticleAffector
    {
    public:

        class CmdAnimationName : public ParamCommand
        {
        public:
            String doGet(const void* target) const;
            void doSet(void* target, const String& val);
        };

        class CmdAnimationLoop : public ParamCommand
        {
        public:
            String doGet(const void* target) const;
            void doSet(void* target, const String& val);
        };

        class CmdAnimationSpeedFactor : public ParamCommand
        {
        public:
            String doGet(const void* target) const;
            void doSet(void* target, const String& val);
        };

        // CYS: client_GL animation range (normalised positions)
        class CmdAnimationRangeBegin : public ParamCommand
        {
        public:
            String doGet(const void* target) const;
            void doSet(void* target, const String& val);
        };
        class CmdAnimationRangeEnd : public ParamCommand
        {
        public:
            String doGet(const void* target) const;
            void doSet(void* target, const String& val);
        };

	    /// Default constructor
        MeshAnimationAffector(ParticleSystem* psys);

        /** See ParticleAffector. */
        void _affectParticles(ParticleSystem* pSystem, Real timeElapsed);

		void setAnimationName(const String& animName)
        {
            mAnimationName = animName;
        }
        const String& getAnimationName(void) const
        {
            return mAnimationName;
        }

        void setAnimationLoop(bool loop)
        {
            mAnimationLoop = loop;
        }
        bool getAnimationLoop(void) const
        {
            return mAnimationLoop;
        }

        void setAnimationSpeedFactor(Real factor)
        {
            mAnimationSpeedFactor = factor;
        }
        Real getAnimationSpeedFactor(void) const
        {
            return mAnimationSpeedFactor;
        }

        // CYS: client_GL range
        void setAnimationRangeBegin(Real v) { mRangeBegin = v; }
        Real getAnimationRangeBegin(void) const { return mRangeBegin; }
        void setAnimationRangeEnd(Real v) { mRangeEnd = v; }
        Real getAnimationRangeEnd(void) const { return mRangeEnd; }

        /** CYS: builds the position curve from the animation length and a particle life (client_GL), and
            scales the speed when the position follows the life. Exposed for the unit tests. */
        void _cysSetupKeys(Real length, Real timeToLive);
        /** CYS: normalised animation position (0..1) of a particle at normalised life 'age'. */
        Real _animationPosition(Real age) const;

		//////////////////////////////////////////////////////////////////////////
		static CmdAnimationName	msAnimationNameCmd;
		static CmdAnimationLoop	msAnimationLoopCmd;
		static CmdAnimationSpeedFactor msAnimationSpeedFactorCmd;
        static CmdAnimationRangeBegin msAnimationRangeBeginCmd; // CYS
        static CmdAnimationRangeEnd msAnimationRangeEndCmd;     // CYS

    protected:

        /// CYS: builds the curve on the first update (false = the mesh or its animation is not there yet)
        bool _cysBuildKeys(ParticleSystem* pSystem);

		String mAnimationName;
        bool mAnimationLoop;
        Real mAnimationSpeedFactor;
        Real mRangeBegin;   // CYS: animation_range_begin (default 0)
        Real mRangeEnd;     // CYS: animation_range_end (default 1)
        Real mCysKeys[8];   // CYS: 4 keys (position, life) of the curve; all 0 = not built yet (client_GL)
    };
}

#endif

