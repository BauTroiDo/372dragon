/*
CYS: RevoluMove affector (Plugin_ParticleFX2) - the most used particle affector of the 2024-2026 effect data
(3,164 blocks in client_GL all.particle).  Written from the behaviour spec in
Docs/specs/render/04-effects-particles.md section 2.3 (B = client_GL Bin64/Plugin_ParticleFX2.dll,
exported class Ogre::RevoluMoveAffector, _affectParticles @ 0x180009da0; clean-room implementation).

Every step each particle
  1. orbits a centre (system position in world space, or the origin in local space, plus one random offset in
     [center_offset_min, center_offset_max] per step) around rotation_axis at rotation_speed (degrees/s);
  2. moves along its radial direction by radius_increment, or by the stage curve radius_increment_scale<i> at
     time<i> (normalised life, wrapped repeat_times) when use_radius_increment_scale is true;
  3. translates with move_velocity, or with the stage curve move_velocity_point<i> at move_time<i> (normalised
     life wrapped move_repeattimes) when move_usevariablevelocity is true.
The resulting velocity is written to Particle::direction (the system integrates the position).

Keywords (all lower case, OGRE lower-cases affector lines): rotation_speed rotation_axis radius_increment
center_offset_min center_offset_max radius_increment_scale0..5 time0..5 use_radius_increment_scale repeat_times
move_velocity move_velocity_point0..5 move_time0..5 move_repeattimes move_usevariablevelocity.
Defaults: speed 0, axis (0,1,0), increment 0, scales 0, times 1, repeat 1, offsets 0, velocities 0, move times 1.
*/
#ifndef __RevoluMoveAffector_H__
#define __RevoluMoveAffector_H__

#include "OgreParticleFX2Prerequisites.h"
#include "OgreParticleFX2ParamHelpers.h"
#include "OgreParticleAffector.h"
#include "OgreVector3.h"

namespace Ogre {

    class _OgreParticleFX2Export RevoluMoveAffector : public ParticleAffector
    {
    public:
        enum { MAX_STAGES = 6 };

        RevoluMoveAffector(ParticleSystem* psys);

        /** See ParticleAffector. */
        void _affectParticles(ParticleSystem* pSystem, Real timeElapsed);

        /// called by the parameter commands after a value changed (nothing cached here)
        void _notifyParameterChanged(void) {}

    protected:
        /// radial speed of one particle at normalised age t (radius_increment or its stage curve)
        Real _radiusIncrementAt(Real age) const;
        /// extra translation velocity at normalised age t (move_velocity or its stage curve)
        Vector3 _moveVelocityAt(Real age) const;

    public:
        Radian  mRotationSpeed;
        Vector3 mRotationAxis;
        Real    mRadiusIncrement;
        Real    mRadiusIncrementScale[MAX_STAGES];
        Real    mTime[MAX_STAGES];
        Real    mRepeatTimes;
        Vector3 mCenterOffsetMin;
        Vector3 mCenterOffsetMax;
        bool    mUseRadiusIncrementScale;

        Vector3 mMoveVelocity;
        Vector3 mMoveVelocityPoint[MAX_STAGES];
        Real    mMoveTime[MAX_STAGES];
        Real    mMoveRepeatTimes;
        bool    mMoveUseVariableVelocity;

        typedef FX2::MemberCmd<RevoluMoveAffector, FX2::AngleCodec, &RevoluMoveAffector::mRotationSpeed> CmdRotationSpeed;
        typedef FX2::MemberCmd<RevoluMoveAffector, FX2::Vector3Codec, &RevoluMoveAffector::mRotationAxis> CmdRotationAxis;
        typedef FX2::MemberCmd<RevoluMoveAffector, FX2::RealCodec, &RevoluMoveAffector::mRadiusIncrement> CmdRadiusIncrement;
        typedef FX2::ArrayElementCmd<RevoluMoveAffector, FX2::RealCodec, MAX_STAGES, &RevoluMoveAffector::mRadiusIncrementScale> CmdRadiusIncrementScale;
        typedef FX2::ArrayElementCmd<RevoluMoveAffector, FX2::RealCodec, MAX_STAGES, &RevoluMoveAffector::mTime> CmdTime;
        typedef FX2::MemberCmd<RevoluMoveAffector, FX2::RealCodec, &RevoluMoveAffector::mRepeatTimes> CmdRepeatTimes;
        typedef FX2::MemberCmd<RevoluMoveAffector, FX2::Vector3Codec, &RevoluMoveAffector::mCenterOffsetMin> CmdCenterOffsetMin;
        typedef FX2::MemberCmd<RevoluMoveAffector, FX2::Vector3Codec, &RevoluMoveAffector::mCenterOffsetMax> CmdCenterOffsetMax;
        typedef FX2::MemberCmd<RevoluMoveAffector, FX2::BoolCodec, &RevoluMoveAffector::mUseRadiusIncrementScale> CmdUseRadiusIncrementScale;
        typedef FX2::MemberCmd<RevoluMoveAffector, FX2::Vector3Codec, &RevoluMoveAffector::mMoveVelocity> CmdMoveVelocity;
        typedef FX2::ArrayElementCmd<RevoluMoveAffector, FX2::Vector3Codec, MAX_STAGES, &RevoluMoveAffector::mMoveVelocityPoint> CmdMoveVelocityPoint;
        typedef FX2::ArrayElementCmd<RevoluMoveAffector, FX2::RealCodec, MAX_STAGES, &RevoluMoveAffector::mMoveTime> CmdMoveTime;
        typedef FX2::MemberCmd<RevoluMoveAffector, FX2::RealCodec, &RevoluMoveAffector::mMoveRepeatTimes> CmdMoveRepeatTimes;
        typedef FX2::MemberCmd<RevoluMoveAffector, FX2::BoolCodec, &RevoluMoveAffector::mMoveUseVariableVelocity> CmdMoveUseVariableVelocity;

        static CmdRotationSpeed           msRotationSpeedCmd;
        static CmdRotationAxis            msRotationAxisCmd;
        static CmdRadiusIncrement         msRadiusIncrementCmd;
        static CmdRadiusIncrementScale    msRadiusIncrementScaleCmd[MAX_STAGES];
        static CmdTime                    msTimeCmd[MAX_STAGES];
        static CmdRepeatTimes             msRepeatTimesCmd;
        static CmdCenterOffsetMin         msCenterOffsetMinCmd;
        static CmdCenterOffsetMax         msCenterOffsetMaxCmd;
        static CmdUseRadiusIncrementScale msUseRadiusIncrementScaleCmd;
        static CmdMoveVelocity            msMoveVelocityCmd;
        static CmdMoveVelocityPoint       msMoveVelocityPointCmd[MAX_STAGES];
        static CmdMoveTime                msMoveTimeCmd[MAX_STAGES];
        static CmdMoveRepeatTimes         msMoveRepeatTimesCmd;
        static CmdMoveUseVariableVelocity msMoveUseVariableVelocityCmd;
    };

}

#endif
