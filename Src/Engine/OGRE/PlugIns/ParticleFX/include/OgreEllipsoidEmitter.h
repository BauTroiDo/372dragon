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
#ifndef __EllipsoidEmitter_H__
#define __EllipsoidEmitter_H__

#include "OgreParticleFXPrerequisites.h"
#include "OgreAreaEmitter.h"
#include "OgreVector2.h" // CYS

namespace Ogre {

    /** Particle emitter which emits particles randomly from points inside an ellipsoid.
    @remarks
        This basic particle emitter emits particles from a ellipsoid area.
        The initial direction of these particles can either be a single
        direction (i.e. a line), a random scattering inside a cone, or a random
        scattering in all directions, depending the 'angle' parameter, which
        is the angle across which to scatter the particles either side of the
        base direction of the emitter.
    @par
        CYS: client_GL (B Plugin_ParticleFX) ellipsoid, see Docs/specs/render/07b-particles_vi.md:
        'inner_width/height/depth' hollow the volume (all 0 = solid, the default; all 1 = the surface
        only), 'angle_range' (degrees) limits the angle around the emitter axis and 'height_range'
        (0..1) the band along it. The height along the axis is drawn by inverting the exact volume
        (or area) distribution of the band.
    */
    class _OgreParticleFXExport EllipsoidEmitter : public AreaEmitter
    {
    public:
        // See AreaEmitter

        EllipsoidEmitter(ParticleSystem* psys);

        /** See ParticleEmitter. */
        void _initParticle(Particle* pParticle);

        // CYS: client_GL keys
        void setInnerSize(Real x, Real y, Real z) { mCysInner = Vector3(x, y, z); }
        void setInnerSizeX(Real x) { mCysInner.x = x; }
        void setInnerSizeY(Real y) { mCysInner.y = y; }
        void setInnerSizeZ(Real z) { mCysInner.z = z; }
        const Vector3& getInnerSize(void) const { return mCysInner; }
        /// 'angle_range': angle around the axis in degrees (min, max); default (0, 360)
        void setAngleRange(const Vector2& degrees) { mCysAngleRange = degrees; }
        const Vector2& getAngleRange(void) const { return mCysAngleRange; }
        /// 'height_range': band along the axis as fractions 0..1 (min, max); default (0, 1)
        void setHeightRange(const Vector2& range) { mCysHeightRange = range; }
        const Vector2& getHeightRange(void) const { return mCysHeightRange; }

        /** CYS: point of the unit volume for the random numbers of one particle, as coefficients of
            (X range, Y range, Z range). 'u' is the draw of the height distribution (or the height itself
            for the surface), 'phi' the angle in degrees and 'w' the unit random of the radius.
            Exposed for the unit tests; _initParticle draws u, phi, w in that order. */
        Vector3 samplePoint(Real u, Real phi, Real w) const;
        /** CYS: range of 'u' for the current keys (the draw is RangeRandom(first, second)). */
        Vector2 heightDrawRange(void) const;
        /** CYS: 0 = solid, 1 = surface, 2 = hollow (which formula the current keys select). */
        int sampleMode(void) const;

        /** Command objects (see ParamCommand). */
        class CmdInnerX : public ParamCommand
        { public: String doGet(const void* target) const; void doSet(void* target, const String& val); };
        class CmdInnerY : public ParamCommand
        { public: String doGet(const void* target) const; void doSet(void* target, const String& val); };
        class CmdInnerZ : public ParamCommand
        { public: String doGet(const void* target) const; void doSet(void* target, const String& val); };
        class CmdAngleRange : public ParamCommand
        { public: String doGet(const void* target) const; void doSet(void* target, const String& val); };
        class CmdHeightRange : public ParamCommand
        { public: String doGet(const void* target) const; void doSet(void* target, const String& val); };

    protected:
        static CmdInnerX msCmdInnerX;           // CYS
        static CmdInnerY msCmdInnerY;           // CYS
        static CmdInnerZ msCmdInnerZ;           // CYS
        static CmdAngleRange msCmdAngleRange;   // CYS
        static CmdHeightRange msCmdHeightRange; // CYS

        Vector3 mCysInner;       // CYS: inner_width / inner_height / inner_depth
        Vector2 mCysAngleRange;  // CYS: degrees
        Vector2 mCysHeightRange; // CYS: 0..1
    };

}

#endif

