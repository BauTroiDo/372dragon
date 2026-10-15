/*
CYS: RotationCurve affector - rotation speed curves over the particle life (23 blocks in client_GL all.particle,
all on mesh renderers).  Clean-room implementation of the behaviour of B Render.dll (FairyRotationCurveAffector)
- Docs/specs/render/04-effects-particles.md.

Keywords (lower case):
  yaw_speed0..4, pitch_speed0..4, roll_speed0..4
                  "speed time": rotation speed in degrees per second at a normalised particle age;
                  the five keys are used in the given order and interpolated with a cubic Hermite curve
                  whose tangents are limited so that the curve does not overshoot (flat at the end keys)
  init_rot_range_start, init_rot_range_end
                  "yaw pitch roll" in degrees: random initial rotation of each particle
Mesh renderer: the three curves drive yaw / pitch / roll of the mesh.  Other renderers: the roll curve drives
the billboard rotation and the initial roll range sets the initial billboard rotation.
*/
#ifndef __WXRotationCurveAffector_H__
#define __WXRotationCurveAffector_H__

#include "WXFxParamHelpers.h"

#include <OgreParticleAffector.h>
#include <OgreParticleAffectorFactory.h>

namespace WX {

    class RotationCurveAffector : public Ogre::ParticleAffector
    {
    public:
        enum { NUM_KEYS = 5 };

        RotationCurveAffector(Ogre::ParticleSystem* psys);

        /** See ParticleAffector. */
        void _initParticle(Ogre::Particle* pParticle);
        /** See ParticleAffector. */
        void _affectParticles(Ogre::ParticleSystem* pSystem, Fx::Real timeElapsed);

        void _notifyParameterChanged(void) { mDirty = true; }

        /// curve value (degrees per second) at normalised age t
        static Fx::Real evaluate(const Fx::Real2* keys, const Fx::Real* tangents, Fx::Real t);
        /// tangents of the five keys (flat at both ends, limited inside)
        static void computeTangents(const Fx::Real2* keys, Fx::Real* tangents);

    public:
        /// keys: x = speed (degrees / second), y = normalised particle age
        Fx::Real2       mYawKeys[NUM_KEYS];
        Fx::Real2       mPitchKeys[NUM_KEYS];
        Fx::Real2       mRollKeys[NUM_KEYS];
        /// initial rotation range, degrees (x = yaw, y = pitch, z = roll)
        Ogre::Vector3   mInitRotStart;
        Ogre::Vector3   mInitRotEnd;

        typedef Fx::ArrayElementCmd<RotationCurveAffector, Fx::Real2Codec, NUM_KEYS, &RotationCurveAffector::mYawKeys> CmdYawKey;
        typedef Fx::ArrayElementCmd<RotationCurveAffector, Fx::Real2Codec, NUM_KEYS, &RotationCurveAffector::mPitchKeys> CmdPitchKey;
        typedef Fx::ArrayElementCmd<RotationCurveAffector, Fx::Real2Codec, NUM_KEYS, &RotationCurveAffector::mRollKeys> CmdRollKey;
        typedef Fx::MemberCmd<RotationCurveAffector, Fx::Vector3Codec, &RotationCurveAffector::mInitRotStart> CmdInitRotStart;
        typedef Fx::MemberCmd<RotationCurveAffector, Fx::Vector3Codec, &RotationCurveAffector::mInitRotEnd> CmdInitRotEnd;

        static CmdYawKey        msYawKeyCmd[NUM_KEYS];
        static CmdPitchKey      msPitchKeyCmd[NUM_KEYS];
        static CmdRollKey       msRollKeyCmd[NUM_KEYS];
        static CmdInitRotStart  msInitRotStartCmd;
        static CmdInitRotEnd    msInitRotEndCmd;

    protected:
        void _rebuild(void);
        bool _isMeshRenderer(Ogre::ParticleSystem* pSystem) const;

        Fx::Real    mYawTangents[NUM_KEYS];
        Fx::Real    mPitchTangents[NUM_KEYS];
        Fx::Real    mRollTangents[NUM_KEYS];
        bool        mDirty;
    };

    //-----------------------------------------------------------------------
    class RotationCurveAffectorFactory : public Ogre::ParticleAffectorFactory
    {
    public:
        Ogre::String getName() const { return "RotationCurve"; }
        Ogre::ParticleAffector* createAffector(Ogre::ParticleSystem* psys)
        {
            Ogre::ParticleAffector* p = new RotationCurveAffector(psys);
            mAffectors.push_back(p);
            return p;
        }
    };

}

#endif
