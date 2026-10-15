/*
CYS: PolarMove affector - see OgrePolarMoveAffector.h for the behaviour summary and the keyword list.
*/
#include "OgrePolarMoveAffector.h"
#include "OgreParticleSystem.h"
#include "OgreParticle.h"
#include "OgreQuaternion.h"
#include "OgreMatrix3.h"

namespace Ogre {

    PolarMoveAffector::CmdTimes                    PolarMoveAffector::msTimesCmd;
    PolarMoveAffector::CmdRadiuses                 PolarMoveAffector::msRadiusesCmd;
    PolarMoveAffector::CmdThetas                   PolarMoveAffector::msThetasCmd;
    PolarMoveAffector::CmdPhis                     PolarMoveAffector::msPhisCmd;
    PolarMoveAffector::CmdDisturbanceForce         PolarMoveAffector::msDisturbanceForceCmd;
    PolarMoveAffector::CmdDisturbanceScope         PolarMoveAffector::msDisturbanceScopeCmd;
    PolarMoveAffector::CmdClockwiseProbability     PolarMoveAffector::msClockwiseProbabilityCmd;
    PolarMoveAffector::CmdDisturbanceRotation      PolarMoveAffector::msDisturbanceRotationCmd;
    PolarMoveAffector::CmdDisturbanceInitialOffset PolarMoveAffector::msDisturbanceInitialOffsetCmd;
    PolarMoveAffector::CmdUsePolarStep             PolarMoveAffector::msUsePolarStepCmd;
    PolarMoveAffector::CmdActivateDisturbance      PolarMoveAffector::msActivateDisturbanceCmd;
    PolarMoveAffector::CmdUseTilt                  PolarMoveAffector::msUseTiltCmd;
    PolarMoveAffector::CmdFlipYZAxis               PolarMoveAffector::msFlipYZAxisCmd;
    PolarMoveAffector::CmdResetRadiusCount         PolarMoveAffector::msResetRadiusCountCmd;

    namespace {
        const Real kDegenerate = 1e-12f;

        /// quadratic Bezier through three knots and its derivative
        inline void bezier(Real p0, Real p1, Real p2, Real u, Real& value, Real& derivative)
        {
            const Real a = p2 - 2.0f * p1 + p0;
            const Real b = p1 - p0;
            value = a * u * u + 2.0f * b * u + p0;
            derivative = 2.0f * a * u + 2.0f * b;
        }

        inline void padTo(std::vector<Real>& v, size_t n)
        {
            if (v.empty())
                v.push_back(0.0f);
            while (v.size() < n)
                v.push_back(v.back());
        }
    }

    //-----------------------------------------------------------------------
    PolarMoveAffector::PolarMoveAffector(ParticleSystem* psys)
        : ParticleAffector(psys)
        , mUsePolarStep(true)
        , mActivateDisturbance(true)
        , mUseTilt(false)
        , mFlipYZAxis(false)
        , mResetRadiusCount(1)
    {
        mType = "PolarMove";

        mTimes.push_back(0.0f);
        mTimes.push_back(1.0f);
        mRadiuses.assign(2, 0.0f);
        mThetas.assign(2, 0.0f);
        mPhis.assign(2, 0.0f);
        for (int k = 0; k < NUM_CURVES; ++k)
        {
            mDisturbanceForce.v[k] = -1.0f;
            mDisturbanceScope.v[k] = 0.0f;
            mClockwiseProbability.v[k] = 0.0f;
            mDisturbanceRotation.v[k] = 0.0f;
            mDisturbanceInitialOffset.v[k] = 0.0f;
        }

        if (createParamDictionary("PolarMoveAffector"))
        {
            addBaseParameters();
            ParamDictionary* dict = getParamDictionary();

            dict->addParameter(ParameterDef("times",
                "the time breakpoint at which the influencer is in effect", PT_STRING), &msTimesCmd);
            dict->addParameter(ParameterDef("radiuses",
                "the radius at every time breakpoint", PT_STRING), &msRadiusesCmd);
            dict->addParameter(ParameterDef("thetas",
                "the theta at every time breakpoint", PT_STRING), &msThetasCmd);
            dict->addParameter(ParameterDef("phis",
                "the phi at every time breakpoint", PT_STRING), &msPhisCmd);
            dict->addParameter(ParameterDef("disturbance_force",
                "affects the frequency of disturbance", PT_STRING), &msDisturbanceForceCmd);
            dict->addParameter(ParameterDef("disturbance_scope",
                "the size of disturbance scope", PT_STRING), &msDisturbanceScopeCmd);
            dict->addParameter(ParameterDef("clockwise_probability",
                "the direction of rotation of each curve", PT_STRING), &msClockwiseProbabilityCmd);
            dict->addParameter(ParameterDef("disturbance_rotation",
                "the angle of rotation of each curve at starting", PT_STRING), &msDisturbanceRotationCmd);
            dict->addParameter(ParameterDef("disturbance_initial_offset",
                "the angle of offset of each curve at starting", PT_STRING), &msDisturbanceInitialOffsetCmd);
            dict->addParameter(ParameterDef("use_polar_step",
                "interpolate the polar coordinates between the breakpoints", PT_BOOL), &msUsePolarStepCmd);
            dict->addParameter(ParameterDef("activate_disturbance",
                "turn on the disturbance or not on", PT_BOOL), &msActivateDisturbanceCmd);
            dict->addParameter(ParameterDef("use_tilt",
                "turn on the tilt or not on while disturbance is activited", PT_BOOL), &msUseTiltCmd);
            dict->addParameter(ParameterDef("flip_yz_axis",
                "swap the y and z axis of the polar coordinates", PT_BOOL), &msFlipYZAxisCmd);
            dict->addParameter(ParameterDef("reset_radius_count",
                "how many times the path is run over the particle life", PT_INT), &msResetRadiusCountCmd);
        }

        _notifyParameterChanged();
    }
    //-----------------------------------------------------------------------
    void PolarMoveAffector::_notifyParameterChanged(void)
    {
        padTo(mTimes, 2);
        padTo(mRadiuses, mTimes.size());
        padTo(mThetas, mTimes.size());
        padTo(mPhis, mTimes.size());
        if (mResetRadiusCount < 1)
            mResetRadiusCount = 1;

        mActiveCurves.clear();
        for (int k = 0; k < NUM_CURVES; ++k)
        {
            if (mDisturbanceForce.v[k] >= 0.0f)
                mActiveCurves.push_back(k);
        }

        mStates.clear();
    }
    //-----------------------------------------------------------------------
    void PolarMoveAffector::_resetState(ParticleState& s, const Particle* p)
    {
        s.start = p->position;

        s.curve = 0;
        if (!mActiveCurves.empty())
        {
            size_t pick = static_cast<size_t>(Math::UnitRandom() * mActiveCurves.size());
            if (pick >= mActiveCurves.size())
                pick = mActiveCurves.size() - 1;
            s.curve = mActiveCurves[pick];
        }

        const Real offset = mDisturbanceInitialOffset.v[s.curve];
        s.phase = (offset >= -1e-6f) ? offset : Math::UnitRandom();
        s.rotation = Math::RangeRandom(0.0f, 360.0f);
        s.tilt = Math::RangeRandom(0.0f, Math::PI * 0.25f);
        s.clockwise = Math::UnitRandom() < mClockwiseProbability.v[s.curve];
        s.pickPoint = true;
        s.lastOffset = Vector3::ZERO;
        s.tangent = s.normal = s.binormal = Vector3::ZERO;
    }
    //-----------------------------------------------------------------------
    PolarMoveAffector::ParticleState& PolarMoveAffector::_state(Particle* p)
    {
        ParticleStateMap::iterator i = mStates.find(p);
        if (i == mStates.end())
        {
            i = mStates.insert(ParticleStateMap::value_type(p, ParticleState())).first;
            _resetState(i->second, p);
        }
        return i->second;
    }
    //-----------------------------------------------------------------------
    void PolarMoveAffector::_initParticle(Particle* pParticle)
    {
        _resetState(mStates[pParticle], pParticle);
    }
    //-----------------------------------------------------------------------
    Vector3 PolarMoveAffector::_spherical(Real r, Real thetaDeg, Real phiDeg) const
    {
        const Real sinT = Math::Sin(Degree(thetaDeg));
        const Real cosT = Math::Cos(Degree(thetaDeg));
        const Real sinP = Math::Sin(Degree(phiDeg));
        const Real cosP = Math::Cos(Degree(phiDeg));

        const Real x = r * cosP * sinT;
        const Real a = r * sinP;
        const Real b = r * cosP * cosT;
        return mFlipYZAxis ? Vector3(x, b, a) : Vector3(x, a, b);
    }
    //-----------------------------------------------------------------------
    void PolarMoveAffector::_pathFrame(size_t seg, Real f, ParticleState& s) const
    {
        const size_t last = mTimes.size() - 1;
        const size_t i1 = seg + 1;
        const size_t i2 = (seg + 2 < last) ? seg + 2 : last;

        Real r, th, ph, dr, dth, dph;
        bezier(mRadiuses[seg], mRadiuses[i1], mRadiuses[i2], f, r, dr);
        bezier(mThetas[seg], mThetas[i1], mThetas[i2], f, th, dth);
        bezier(mPhis[seg], mPhis[i1], mPhis[i2], f, ph, dph);

        const Real sinT = Math::Sin(Degree(th));
        const Real cosT = Math::Cos(Degree(th));
        const Real sinP = Math::Sin(Degree(ph));
        const Real cosP = Math::Cos(Degree(ph));

        // derivative of the spherical position (angle rates kept in degrees, as the original data expects)
        const Real tx = sinT * cosP * dr - r * sinT * sinP * dph + r * cosP * cosT * dth;
        const Real ta = sinP * dr + r * cosP * dph;
        const Real tb = cosT * cosP * dr - cosT * r * sinP * dph - r * cosP * sinT * dth;

        const Vector3 up = mFlipYZAxis ? Vector3::UNIT_Z : Vector3::UNIT_Y;
        const Vector3 side = mFlipYZAxis ? Vector3::UNIT_Y : Vector3::UNIT_Z;

        Vector3 tangent = mFlipYZAxis ? Vector3(tx, tb, ta) : Vector3(tx, ta, tb);
        tangent.normalise();
        Vector3 radial = _spherical(r, th, ph);
        radial.normalise();

        Vector3 normal = radial;
        Vector3 binormal = radial.crossProduct(tangent);

        if (binormal.squaredLength() < kDegenerate)
        {
            if (tangent.squaredLength() < kDegenerate)
            {
                if (radial.squaredLength() < kDegenerate)
                {
                    normal = Vector3::UNIT_X;
                    binormal = up;
                    tangent = side;
                }
                else if (s.tangent.squaredLength() < kDegenerate)
                {
                    tangent = radial;
                    normal = up.crossProduct(tangent);
                    binormal = tangent.crossProduct(normal);
                }
                else
                {
                    tangent = s.tangent;
                    normal = s.normal;
                    binormal = s.binormal;
                }
            }
            else
            {
                binormal = up;
                normal = binormal.crossProduct(tangent);
                if (normal.squaredLength() >= kDegenerate)
                {
                    binormal = tangent.crossProduct(normal);
                }
                else
                {
                    tangent = up;
                    binormal = side;
                    normal = Vector3::UNIT_X;
                }
            }
        }

        tangent.normalise();
        normal.normalise();
        binormal.normalise();
        s.tangent = tangent;
        s.normal = normal;
        s.binormal = binormal;
    }
    //-----------------------------------------------------------------------
    Vector3 PolarMoveAffector::_disturbance(Real t, ParticleState& s) const
    {
        const int k = s.curve;

        // orient the plane of the disturbance curve: rotation about the tangent (+ optional tilt)
        const Real rotationDeg = (mDisturbanceRotation.v[k] >= -1e-6f) ? mDisturbanceRotation.v[k] : s.rotation;
        Matrix3 frame;
        Quaternion(Degree(rotationDeg), s.tangent).ToRotationMatrix(frame);
        if (mUseTilt)
        {
            Matrix3 tilt;
            Quaternion(Radian(s.tilt), s.normal).ToRotationMatrix(tilt);
            frame = frame * tilt;
        }
        const Vector3 normal = frame * s.normal;
        const Vector3 binormal = frame * s.binormal;

        const Real x = fmod(t * mDisturbanceForce.v[k] + s.phase, 1.0f);
        const Real scope = mDisturbanceScope.v[k];
        Real angle = 0.0f;
        Real amplitude = 0.0f;

        switch (k)
        {
        case 0: // wobbling loop
            angle = Math::TWO_PI * x;
            if (s.clockwise)
                angle = Math::TWO_PI - angle;
            amplitude = Math::Cos(Math::Sin(angle) * 0.6f) * scope;
            break;
        case 1: // figure of eight
            angle = Math::TWO_PI * x;
            if (s.clockwise)
                angle = Math::TWO_PI - angle;
            if (angle > Math::PI)
                angle = Math::PI - angle;
            amplitude = Math::Sin(angle) * Math::Sin(angle) * scope;
            break;
        case 2: // three petal rose
            angle = Math::PI * x;
            if (s.clockwise)
                angle = Math::PI - angle;
            amplitude = Math::Cos(angle * 3.0f) * scope;
            break;
        case 3: // four petal rose
            angle = Math::TWO_PI * x;
            if (s.clockwise)
                angle = Math::TWO_PI - angle;
            amplitude = Math::Cos(angle) * Math::Sin(angle) * scope * 2.0f;
            break;
        default: // three lobes with flat arcs
            angle = Math::TWO_PI * 3.0f * x;
            if (s.clockwise)
                angle = Math::TWO_PI * 3.0f - angle;
            if ((Math::PI < angle && angle < Math::TWO_PI) || (Math::PI * 4.0f < angle && angle < Math::PI * 5.0f))
                amplitude = 1.0f;
            else if (Math::TWO_PI <= angle && angle <= Math::PI * 4.0f)
                amplitude = 2.0f - Math::Cos(angle);
            else
                amplitude = Math::Cos(angle) + 2.0f;
            amplitude *= scope / 3.0f;
            break;
        }

        return (normal * Math::Cos(angle) + binormal * Math::Sin(angle)) * amplitude;
    }
    //-----------------------------------------------------------------------
    Vector3 PolarMoveAffector::_pathPosition(size_t seg, Real f, const Vector3& previousOffset, ParticleState& s) const
    {
        if (!mUsePolarStep)
        {
            // one random point of the current segment ranges, picked on the first update and then kept
            if (!s.pickPoint)
                return previousOffset;
            s.pickPoint = false;
            const size_t i1 = seg + 1;
            return _spherical(Math::RangeRandom(mRadiuses[seg], mRadiuses[i1]),
                              Math::RangeRandom(mThetas[seg], mThetas[i1]),
                              Math::RangeRandom(mPhis[seg], mPhis[i1]));
        }

        const size_t i1 = seg + 1;
        return _spherical(mRadiuses[seg] + (mRadiuses[i1] - mRadiuses[seg]) * f,
                          mThetas[seg] + (mThetas[i1] - mThetas[seg]) * f,
                          mPhis[seg] + (mPhis[i1] - mPhis[seg]) * f);
    }
    //-----------------------------------------------------------------------
    void PolarMoveAffector::_affectParticles(ParticleSystem* pSystem, Real timeElapsed)
    {
        if (Math::RealEqual(timeElapsed, 0.0f))
            return;

        const Real invStep = 1.0f / timeElapsed;
        const size_t count = mTimes.size();
        const bool disturb = mUsePolarStep && mActivateDisturbance && !mActiveCurves.empty();

        ParticleIterator pi = pSystem->_getIterator();
        while (!pi.end())
        {
            Particle* p = pi.getNext();
            ParticleState& s = _state(p);

            const Real age = (p->totalTimeToLive > 0) ? 1.0f - p->timeToLive / p->totalTimeToLive : 1.0f;
            const Real t = fmod(static_cast<Real>(mResetRadiusCount) * age, 1.0f);

            bool found = false;
            Vector3 offset = Vector3::ZERO;
            if (t >= mTimes[0])
            {
                for (size_t i = 0; i + 1 < count; ++i)
                {
                    if (mTimes[i] <= t && t <= mTimes[i + 1])
                    {
                        const Real span = mTimes[i + 1] - mTimes[i];
                        const Real f = (span != 0.0f) ? (t - mTimes[i]) / span : 0.0f;
                        offset = _pathPosition(i, f, p->position - s.start, s);
                        if (disturb)
                        {
                            _pathFrame(i, f, s);
                            offset += _disturbance(t, s);
                        }
                        found = true;
                        break;
                    }
                }
            }

            if (found)
                p->direction = (s.start + offset - p->position) * invStep;
            else
                p->direction = Vector3::ZERO;
        }
    }

}
