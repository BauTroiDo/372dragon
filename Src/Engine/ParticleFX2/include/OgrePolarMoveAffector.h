/*
CYS: PolarMove affector (Plugin_ParticleFX2) - 13 blocks in client_GL all.particle (spiral/orbit paths of pets,
buffs and weapon showcases).  B implements it in Render.dll (PolarMoveAffector, ctor 0x18012e4f0,
_affectParticles 0x180130370); this is a clean-room implementation of the behaviour described in
Docs/specs/render/04-effects-particles.md section 2.7.

Each particle follows a path in spherical coordinates around its birth position:
  t' = fmod(reset_radius_count * normalised_age, 1);   segment i with times[i] <= t' <= times[i+1]
  use_polar_step true : r/theta/phi interpolated linearly inside the segment,
                        x = r cos(phi) sin(theta), y = r sin(phi), z = r cos(phi) cos(theta)  (y/z swapped by
                        flip_yz_axis); with activate_disturbance an extra planar "disturbance curve" is added in
                        the frame (normal, binormal) of the path (quadratic Bezier through knots i, i+1, i+2):
                        curve k in 0..4 (picked at random among those with disturbance_force[k] >= 0) of
                        amplitude disturbance_scope[k], frequency disturbance_force[k], random direction
                        (clockwise_probability[k]), start angle disturbance_initial_offset[k] (-1 = random),
                        rotation about the tangent disturbance_rotation[k] degrees (-1 = random) and an optional
                        random tilt (use_tilt).
  use_polar_step false: one random point of the segment's r/theta/phi ranges, kept for the segment.
Angles are degrees.  Outside the time range the particle stops.
Keywords: times radiuses thetas phis (lists), disturbance_force disturbance_scope clockwise_probability
disturbance_rotation disturbance_initial_offset (5 values), use_polar_step activate_disturbance use_tilt
flip_yz_axis (bool), reset_radius_count (int >= 1).
*/
#ifndef __PolarMoveAffector_H__
#define __PolarMoveAffector_H__

#include "OgreParticleFX2Prerequisites.h"
#include "OgreParticleFX2ParamHelpers.h"
#include "OgreParticleAffector.h"
#include "OgreVector3.h"

#include <map>
#include <vector>

namespace Ogre {

    namespace FX2 {
        /// 5 per-curve values of the PolarMove disturbance keywords
        struct CurveValues
        {
            Real v[5];
        };
        /// list of reals ("times", "radiuses", ...); an empty list parses as a single 0
        struct RealListCodec
        {
            typedef std::vector<Real> Type;
            static void parse(const String& s, Type& v)
            {
                v = parseRealList(s);
                if (v.empty())
                    v.push_back(0.0f);
            }
            static String str(const Type& v) { return v.empty() ? String("0") : realsToString(&v[0], v.size()); }
        };
        /// 5 reals, missing values filled with Fill/1000 (Fill is an integer template argument)
        template <int FillMilli>
        struct CurveCodec
        {
            typedef CurveValues Type;
            static void parse(const String& s, Type& v)
            {
                size_t n = parseReals(s, v.v, 5);
                for (; n < 5; ++n)
                    v.v[n] = FillMilli / 1000.0f;
            }
            static String str(const Type& v) { return realsToString(v.v, 5); }
        };
    }

    class _OgreParticleFX2Export PolarMoveAffector : public ParticleAffector
    {
    public:
        enum { NUM_CURVES = 5 };

        PolarMoveAffector(ParticleSystem* psys);

        /** See ParticleAffector. */
        void _initParticle(Particle* pParticle);
        /** See ParticleAffector. */
        void _affectParticles(ParticleSystem* pSystem, Real timeElapsed);

        /// validates the knot lists / curve selection and forgets the per-particle state
        void _notifyParameterChanged(void);

    public:
        std::vector<Real> mTimes;
        std::vector<Real> mRadiuses;
        std::vector<Real> mThetas;
        std::vector<Real> mPhis;
        FX2::CurveValues  mDisturbanceForce;
        FX2::CurveValues  mDisturbanceScope;
        FX2::CurveValues  mClockwiseProbability;
        FX2::CurveValues  mDisturbanceRotation;
        FX2::CurveValues  mDisturbanceInitialOffset;
        bool mUsePolarStep;
        bool mActivateDisturbance;
        bool mUseTilt;
        bool mFlipYZAxis;
        int  mResetRadiusCount;

        typedef FX2::MemberCmd<PolarMoveAffector, FX2::RealListCodec, &PolarMoveAffector::mTimes> CmdTimes;
        typedef FX2::MemberCmd<PolarMoveAffector, FX2::RealListCodec, &PolarMoveAffector::mRadiuses> CmdRadiuses;
        typedef FX2::MemberCmd<PolarMoveAffector, FX2::RealListCodec, &PolarMoveAffector::mThetas> CmdThetas;
        typedef FX2::MemberCmd<PolarMoveAffector, FX2::RealListCodec, &PolarMoveAffector::mPhis> CmdPhis;
        typedef FX2::MemberCmd<PolarMoveAffector, FX2::CurveCodec<-1000>, &PolarMoveAffector::mDisturbanceForce> CmdDisturbanceForce;
        typedef FX2::MemberCmd<PolarMoveAffector, FX2::CurveCodec<0>, &PolarMoveAffector::mDisturbanceScope> CmdDisturbanceScope;
        typedef FX2::MemberCmd<PolarMoveAffector, FX2::CurveCodec<0>, &PolarMoveAffector::mClockwiseProbability> CmdClockwiseProbability;
        typedef FX2::MemberCmd<PolarMoveAffector, FX2::CurveCodec<0>, &PolarMoveAffector::mDisturbanceRotation> CmdDisturbanceRotation;
        typedef FX2::MemberCmd<PolarMoveAffector, FX2::CurveCodec<0>, &PolarMoveAffector::mDisturbanceInitialOffset> CmdDisturbanceInitialOffset;
        typedef FX2::MemberCmd<PolarMoveAffector, FX2::BoolCodec, &PolarMoveAffector::mUsePolarStep> CmdUsePolarStep;
        typedef FX2::MemberCmd<PolarMoveAffector, FX2::BoolCodec, &PolarMoveAffector::mActivateDisturbance> CmdActivateDisturbance;
        typedef FX2::MemberCmd<PolarMoveAffector, FX2::BoolCodec, &PolarMoveAffector::mUseTilt> CmdUseTilt;
        typedef FX2::MemberCmd<PolarMoveAffector, FX2::BoolCodec, &PolarMoveAffector::mFlipYZAxis> CmdFlipYZAxis;
        typedef FX2::MemberCmd<PolarMoveAffector, FX2::IntCodec, &PolarMoveAffector::mResetRadiusCount> CmdResetRadiusCount;

        static CmdTimes                    msTimesCmd;
        static CmdRadiuses                 msRadiusesCmd;
        static CmdThetas                   msThetasCmd;
        static CmdPhis                     msPhisCmd;
        static CmdDisturbanceForce         msDisturbanceForceCmd;
        static CmdDisturbanceScope         msDisturbanceScopeCmd;
        static CmdClockwiseProbability     msClockwiseProbabilityCmd;
        static CmdDisturbanceRotation      msDisturbanceRotationCmd;
        static CmdDisturbanceInitialOffset msDisturbanceInitialOffsetCmd;
        static CmdUsePolarStep             msUsePolarStepCmd;
        static CmdActivateDisturbance      msActivateDisturbanceCmd;
        static CmdUseTilt                  msUseTiltCmd;
        static CmdFlipYZAxis               msFlipYZAxisCmd;
        static CmdResetRadiusCount         msResetRadiusCountCmd;

    protected:
        /// state kept per living particle (keyed by the pooled Particle object)
        struct ParticleState
        {
            Vector3 start;      ///< birth position
            int     curve;      ///< disturbance curve 0..4
            Real    phase;      ///< start angle of the disturbance curve (turns)
            Real    rotation;   ///< rotation of the curve plane about the tangent (degrees)
            Real    tilt;       ///< tilt about the normal (radians)
            bool    clockwise;
            bool    pickPoint;  ///< non-step mode: pick a random point when entering the next segment
            Vector3 lastOffset; ///< non-step mode: offset picked for the current segment
            Vector3 tangent;    ///< previous path frame (fallback for degenerate paths)
            Vector3 normal;
            Vector3 binormal;
        };
        typedef std::map<const Particle*, ParticleState> ParticleStateMap;

        ParticleState& _state(Particle* p);
        void _resetState(ParticleState& s, const Particle* p);
        Vector3 _pathPosition(size_t seg, Real f, const Vector3& previousOffset, ParticleState& s) const;
        void _pathFrame(size_t seg, Real f, ParticleState& s) const;
        Vector3 _disturbance(Real t, ParticleState& s) const;
        Vector3 _spherical(Real r, Real thetaDeg, Real phiDeg) const;

        ParticleStateMap  mStates;
        std::vector<int>  mActiveCurves;
    };

}

#endif
