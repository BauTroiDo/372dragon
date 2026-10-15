/*
-----------------------------------------------------------------------------
This source file is part of OGRE
    (Object-oriented Graphics Rendering Engine)
For the latest info, see http://www.ogre3d.org/

Copyright ) 2002 Tels <http://bloodgate.com> based on CylinderEmitter
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
#ifndef __CylinderEmitter_H__
#define __CylinderEmitter_H__

#include "OgreParticleFXPrerequisites.h"
#include "OgreAreaEmitter.h"
#include "OgreVector2.h" // CYS

namespace Ogre {

    /** Particle emitter which emits particles randomly from points inside a cylinder.
    @remarks
        This basic particle emitter emits particles from a cylinder area. The
        initial direction of these particles can either be a single direction
        (i.e. a line), a random scattering inside a cone, or a random
        scattering in all directions, depending the 'angle' parameter, which
        is the angle across which to scatter the particles either side of the
        base direction of the emitter. 
    */
    class _OgreParticleFXExport CylinderEmitter : public AreaEmitter
    {
    public:
        // See AreaEmitter

        CylinderEmitter(ParticleSystem* psys);

        /** See ParticleEmitter. */
        void _initParticle(Particle* pParticle);

        // CYS: B/Fairy cylinder (client_GL all.particle; keys of B Plugin_ParticleFX). The axis
        // is the emitter direction (depth), the cross-section spans width and height.
        /** Hollow part as a fraction of the radius across width / height ('inner_width',
            'inner_height'). B default 0.5 = a tube; 1 = particles on the surface only. */
        void setInnerSize(Real x, Real y);
        void setInnerSizeX(Real x) { mInnerSize.x = x; }
        void setInnerSizeY(Real y) { mInnerSize.y = y; }
        Real getInnerSizeX(void) const { return mInnerSize.x; }
        Real getInnerSizeY(void) const { return mInnerSize.y; }
        /// 'angle_range': sector around the axis in degrees (min, max); default (0, 360)
        void setAngleRange(const Vector2& degrees) { mAngleRange = degrees; }
        const Vector2& getAngleRange(void) const { return mAngleRange; }
        /// 'topdown_ratio': radius factor at the direction end (top) and at the other end (down)
        void setTopDownRatio(const Vector2& ratio) { mTopDownRatio = ratio; }
        const Vector2& getTopDownRatio(void) const { return mTopDownRatio; }
        /// 'curve': radius factor 1 + curve * (1 - h^2) along the axis h = -1..1 (barrel / waist)
        void setCurve(Real curve) { mCurve = curve; }
        Real getCurve(void) const { return mCurve; }
        /// 'BendAngle' (scripts: 'bendangle', 'bend_angle'): bends the axis along an arc of this many degrees
        void setBendAngle(Real degrees) { mBendAngle = degrees; }
        Real getBendAngle(void) const { return mBendAngle; }

        /** Command objects (see ParamCommand). */
        class CmdInnerX : public ParamCommand
        { public: String doGet(const void* target) const; void doSet(void* target, const String& val); };
        class CmdInnerY : public ParamCommand
        { public: String doGet(const void* target) const; void doSet(void* target, const String& val); };
        class CmdAngleRange : public ParamCommand
        { public: String doGet(const void* target) const; void doSet(void* target, const String& val); };
        class CmdTopDownRatio : public ParamCommand
        { public: String doGet(const void* target) const; void doSet(void* target, const String& val); };
        class CmdCurve : public ParamCommand
        { public: String doGet(const void* target) const; void doSet(void* target, const String& val); };
        class CmdBendAngle : public ParamCommand
        { public: String doGet(const void* target) const; void doSet(void* target, const String& val); };

    protected:
        // See AreaEmitter
        static CmdInnerX msCmdInnerX;             // CYS
        static CmdInnerY msCmdInnerY;             // CYS
        static CmdAngleRange msCmdAngleRange;     // CYS
        static CmdTopDownRatio msCmdTopDownRatio; // CYS
        static CmdCurve msCmdCurve;               // CYS
        static CmdBendAngle msCmdBendAngle;       // CYS
        Vector2 mInnerSize;    // CYS
        Vector2 mAngleRange;   // CYS: degrees
        Vector2 mTopDownRatio; // CYS
        Real mCurve;           // CYS
        Real mBendAngle;       // CYS: degrees




    };

}

#endif

