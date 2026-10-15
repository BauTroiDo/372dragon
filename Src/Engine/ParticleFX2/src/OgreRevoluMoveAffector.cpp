/*
CYS: RevoluMove affector - see OgreRevoluMoveAffector.h for the keyword list and the behaviour summary.
*/
#include "OgreRevoluMoveAffector.h"
#include "OgreParticleSystem.h"
#include "OgreParticle.h"
#include "OgreNode.h"
#include "OgreQuaternion.h"
#include "OgreMatrix3.h"

namespace Ogre {

    RevoluMoveAffector::CmdRotationSpeed           RevoluMoveAffector::msRotationSpeedCmd;
    RevoluMoveAffector::CmdRotationAxis            RevoluMoveAffector::msRotationAxisCmd;
    RevoluMoveAffector::CmdRadiusIncrement         RevoluMoveAffector::msRadiusIncrementCmd;
    RevoluMoveAffector::CmdRadiusIncrementScale    RevoluMoveAffector::msRadiusIncrementScaleCmd[MAX_STAGES];
    RevoluMoveAffector::CmdTime                    RevoluMoveAffector::msTimeCmd[MAX_STAGES];
    RevoluMoveAffector::CmdRepeatTimes             RevoluMoveAffector::msRepeatTimesCmd;
    RevoluMoveAffector::CmdCenterOffsetMin         RevoluMoveAffector::msCenterOffsetMinCmd;
    RevoluMoveAffector::CmdCenterOffsetMax         RevoluMoveAffector::msCenterOffsetMaxCmd;
    RevoluMoveAffector::CmdUseRadiusIncrementScale RevoluMoveAffector::msUseRadiusIncrementScaleCmd;
    RevoluMoveAffector::CmdMoveVelocity            RevoluMoveAffector::msMoveVelocityCmd;
    RevoluMoveAffector::CmdMoveVelocityPoint       RevoluMoveAffector::msMoveVelocityPointCmd[MAX_STAGES];
    RevoluMoveAffector::CmdMoveTime                RevoluMoveAffector::msMoveTimeCmd[MAX_STAGES];
    RevoluMoveAffector::CmdMoveRepeatTimes         RevoluMoveAffector::msMoveRepeatTimesCmd;
    RevoluMoveAffector::CmdMoveUseVariableVelocity RevoluMoveAffector::msMoveUseVariableVelocityCmd;

    //-----------------------------------------------------------------------
    RevoluMoveAffector::RevoluMoveAffector(ParticleSystem* psys)
        : ParticleAffector(psys)
        , mRotationSpeed(0)
        , mRotationAxis(Vector3::UNIT_Y)
        , mRadiusIncrement(0)
        , mRepeatTimes(1.0f)
        , mCenterOffsetMin(Vector3::ZERO)
        , mCenterOffsetMax(Vector3::ZERO)
        , mUseRadiusIncrementScale(false)
        , mMoveVelocity(Vector3::ZERO)
        , mMoveRepeatTimes(1.0f)
        , mMoveUseVariableVelocity(false)
    {
        mType = "RevoluMove";

        for (int i = 0; i < MAX_STAGES; ++i)
        {
            mRadiusIncrementScale[i] = 0.0f;
            mTime[i] = 1.0f;
            mMoveVelocityPoint[i] = Vector3::ZERO;
            mMoveTime[i] = 1.0f;
        }

        if (createParamDictionary("RevoluMoveAffector"))
        {
            addBaseParameters();
            ParamDictionary* dict = getParamDictionary();

            dict->addParameter(ParameterDef("rotation_speed",
                "the speed of particle circle rotation.", PT_REAL), &msRotationSpeedCmd);
            dict->addParameter(ParameterDef("rotation_axis",
                "the axis of the circle rotation.", PT_VECTOR3), &msRotationAxisCmd);
            dict->addParameter(ParameterDef("radius_increment",
                "the radial speed of the particles.", PT_REAL), &msRadiusIncrementCmd);
            dict->addParameter(ParameterDef("center_offset_min",
                "the minimum random offset of the rotation centre.", PT_VECTOR3), &msCenterOffsetMinCmd);
            dict->addParameter(ParameterDef("center_offset_max",
                "the maximum random offset of the rotation centre.", PT_VECTOR3), &msCenterOffsetMaxCmd);

            for (int i = 0; i < MAX_STAGES; ++i)
            {
                String stage = StringConverter::toString(i);

                msRadiusIncrementScaleCmd[i].mIndex = i;
                msTimeCmd[i].mIndex = i;
                msMoveVelocityPointCmd[i].mIndex = i;
                msMoveTimeCmd[i].mIndex = i;

                dict->addParameter(ParameterDef("radius_increment_scale" + stage,
                    "Stage " + stage + " RadiusIncrementScale.", PT_REAL), &msRadiusIncrementScaleCmd[i]);
                dict->addParameter(ParameterDef("time" + stage,
                    "Stage " + stage + " time.", PT_REAL), &msTimeCmd[i]);
                dict->addParameter(ParameterDef("move_velocity_point" + stage,
                    "Stage " + stage + " velocity.", PT_VECTOR3), &msMoveVelocityPointCmd[i]);
                dict->addParameter(ParameterDef("move_time" + stage,
                    "Stage " + stage + " time.", PT_REAL), &msMoveTimeCmd[i]);
            }

            dict->addParameter(ParameterDef("use_radius_increment_scale",
                "use the radius increment stage curve.", PT_BOOL), &msUseRadiusIncrementScaleCmd);
            dict->addParameter(ParameterDef("repeat_times",
                "the repeat times of the radius increment curve.", PT_REAL), &msRepeatTimesCmd);
            dict->addParameter(ParameterDef("move_velocity",
                "The velocity of the movement", PT_VECTOR3), &msMoveVelocityCmd);
            dict->addParameter(ParameterDef("move_repeattimes",
                "repeattimes", PT_REAL), &msMoveRepeatTimesCmd);
            dict->addParameter(ParameterDef("move_usevariablevelocity",
                "Use VariableVelocity movement", PT_BOOL), &msMoveUseVariableVelocityCmd);
        }
    }
    //-----------------------------------------------------------------------
    Real RevoluMoveAffector::_radiusIncrementAt(Real age) const
    {
        if (!mUseRadiusIncrementScale)
            return mRadiusIncrement;

        Real t = age;
        if (mRepeatTimes != 1.0f)
            t = fmod(t * mRepeatTimes, 1.0f);

        Real result = 0.0f;
        FX2::evalStages(mTime, mRadiusIncrementScale, MAX_STAGES, t, result);
        return result;
    }
    //-----------------------------------------------------------------------
    Vector3 RevoluMoveAffector::_moveVelocityAt(Real age) const
    {
        if (!mMoveUseVariableVelocity)
            return mMoveVelocity;

        Real t = age;
        if (mMoveRepeatTimes != 1.0f)
            t = fmod(t * mMoveRepeatTimes, 1.0f);

        Vector3 result = Vector3::ZERO;
        FX2::evalStages(mMoveTime, mMoveVelocityPoint, MAX_STAGES, t, result);
        return result;
    }
    //-----------------------------------------------------------------------
    void RevoluMoveAffector::_affectParticles(ParticleSystem* pSystem, Real timeElapsed)
    {
        // the velocity below is a displacement divided by the step: nothing to do for an empty step
        if (Math::RealEqual(timeElapsed, 0.0f))
            return;

        // rotation performed during this step
        Matrix3 rotation;
        Quaternion(mRotationSpeed * timeElapsed, mRotationAxis).ToRotationMatrix(rotation);

        // one random centre offset per step, shared by all particles
        Vector3 centre(Math::RangeRandom(mCenterOffsetMin.x, mCenterOffsetMax.x),
                       Math::RangeRandom(mCenterOffsetMin.y, mCenterOffsetMax.y),
                       Math::RangeRandom(mCenterOffsetMin.z, mCenterOffsetMax.z));

        // world space particles orbit around the system position, local space ones around the origin
        if (!pSystem->getKeepParticlesInLocalSpace() && pSystem->getParentNode())
            centre += pSystem->getParentNode()->_getDerivedPosition();

        const Real invStep = 1.0f / timeElapsed;

        ParticleIterator pi = pSystem->_getIterator();
        while (!pi.end())
        {
            Particle* p = pi.getNext();

            Vector3 relative = p->position - centre;
            Vector3 radial = relative;
            radial.normalise();

            // velocity which brings the particle to its rotated place at the end of the step
            p->direction = (centre + rotation * relative - p->position) * invStep;

            const Real age = (p->totalTimeToLive > 0) ? 1.0f - p->timeToLive / p->totalTimeToLive : 1.0f;

            // radius growth
            p->direction += radial * _radiusIncrementAt(age);

            // additional translation
            p->direction += _moveVelocityAt(age);
        }
    }

}
