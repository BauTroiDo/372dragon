/*
CYS: RotationCurve affector - see WXRotationCurveAffector.h.
*/
#include "WXRotationCurveAffector.h"

#include <OgreParticleSystem.h>
#include <OgreParticle.h>
#include <OgreParticleIterator.h>
#include <OgreParticleSystemRenderer.h>
#include <OgreMath.h>

#include "OgreExt/OgreMeshParticleVisualData.h"

namespace WX {

    RotationCurveAffector::CmdYawKey       RotationCurveAffector::msYawKeyCmd[RotationCurveAffector::NUM_KEYS];
    RotationCurveAffector::CmdPitchKey     RotationCurveAffector::msPitchKeyCmd[RotationCurveAffector::NUM_KEYS];
    RotationCurveAffector::CmdRollKey      RotationCurveAffector::msRollKeyCmd[RotationCurveAffector::NUM_KEYS];
    RotationCurveAffector::CmdInitRotStart RotationCurveAffector::msInitRotStartCmd;
    RotationCurveAffector::CmdInitRotEnd   RotationCurveAffector::msInitRotEndCmd;

    //-----------------------------------------------------------------------
    RotationCurveAffector::RotationCurveAffector(Ogre::ParticleSystem* psys)
        : Ogre::ParticleAffector(psys)
        , mInitRotStart(Ogre::Vector3::ZERO)
        , mInitRotEnd(Ogre::Vector3::ZERO)
        , mDirty(true)
    {
        mType = "RotationCurve";

        for (size_t i = 0; i < NUM_KEYS; ++i)
        {
            mYawKeys[i].x = mYawKeys[i].y = 0.0f;
            mPitchKeys[i].x = mPitchKeys[i].y = 0.0f;
            mRollKeys[i].x = mRollKeys[i].y = 0.0f;
            mYawTangents[i] = mPitchTangents[i] = mRollTangents[i] = 0.0f;
        }

        if (createParamDictionary("RotationCurveAffector"))
        {
            addBaseParameters();
            Ogre::ParamDictionary* dict = getParamDictionary();

            for (size_t i = 0; i < NUM_KEYS; ++i)
            {
                const Ogre::String index = Ogre::StringConverter::toString(i);
                msYawKeyCmd[i].mIndex = i;
                msPitchKeyCmd[i].mIndex = i;
                msRollKeyCmd[i].mIndex = i;
                dict->addParameter(Ogre::ParameterDef("yaw_speed" + index,
                    "yaw speed key 'degrees_per_second time'.", Ogre::PT_STRING), &msYawKeyCmd[i]);
                dict->addParameter(Ogre::ParameterDef("pitch_speed" + index,
                    "pitch speed key 'degrees_per_second time'.", Ogre::PT_STRING), &msPitchKeyCmd[i]);
                dict->addParameter(Ogre::ParameterDef("roll_speed" + index,
                    "roll speed key 'degrees_per_second time'.", Ogre::PT_STRING), &msRollKeyCmd[i]);
            }
            dict->addParameter(Ogre::ParameterDef("init_rot_range_start",
                "initial rotation range start (yaw pitch roll, degrees).", Ogre::PT_VECTOR3), &msInitRotStartCmd);
            dict->addParameter(Ogre::ParameterDef("init_rot_range_end",
                "initial rotation range end (yaw pitch roll, degrees).", Ogre::PT_VECTOR3), &msInitRotEndCmd);
        }
    }
    //-----------------------------------------------------------------------
    void RotationCurveAffector::computeTangents(const Fx::Real2* keys, Fx::Real* tangents)
    {
        const Fx::Real eps = 1e-5f;

        tangents[0] = 0.0f;
        tangents[NUM_KEYS - 1] = 0.0f;
        for (int i = 1; i < NUM_KEYS - 1; ++i)
        {
            const Fx::Real dv0 = keys[i].x - keys[i - 1].x;
            const Fx::Real dt0 = keys[i].y - keys[i - 1].y;
            const Fx::Real dv1 = keys[i + 1].x - keys[i].x;
            const Fx::Real dt1 = keys[i + 1].y - keys[i].y;

            const Fx::Real s0 = (Ogre::Math::Abs(dt0) > eps) ? dv0 / dt0 : 0.0f;
            const Fx::Real s1 = (Ogre::Math::Abs(dt1) > eps) ? dv1 / dt1 : 0.0f;

            const bool sameSign = (s0 > 0.0f && s1 > 0.0f) || (s0 < 0.0f && s1 < 0.0f);
            if (!sameSign)
            {
                // local extremum (or flat side): flat tangent, no overshoot
                tangents[i] = 0.0f;
                continue;
            }

            const Fx::Real dt = dt0 + dt1;
            const Fx::Real sum = dv0 + dv1;
            const Fx::Real average = (Ogre::Math::Abs(dt) > eps) ? sum / dt : 0.0f;
            const Fx::Real quarter = 0.25f * sum;
            const Fx::Real threeQuarters = 0.75f * sum;

            // the tangent fades to zero when the key is close to one of its neighbours (monotone curve)
            if (Ogre::Math::Abs(dv0) < Ogre::Math::Abs(threeQuarters))
            {
                if (Ogre::Math::Abs(quarter) <= Ogre::Math::Abs(dv0))
                    tangents[i] = average;
                else
                    tangents[i] = (dv0 / quarter) * average;
            }
            else
            {
                tangents[i] = (1.0f - (dv0 - threeQuarters) / quarter) * average;
            }
        }
    }
    //-----------------------------------------------------------------------
    Fx::Real RotationCurveAffector::evaluate(const Fx::Real2* keys, const Fx::Real* tangents, Fx::Real t)
    {
        if (t < keys[0].y)
            return keys[0].x;

        for (int i = 0; i < NUM_KEYS - 1; ++i)
        {
            const Fx::Real t0 = keys[i].y;
            const Fx::Real t1 = keys[i + 1].y;
            if (t0 <= t && t < t1)
            {
                const Fx::Real dt = t1 - t0;
                const Fx::Real u = (t - t0) / dt;
                const Fx::Real u2 = u * u;
                const Fx::Real u3 = u2 * u;
                return (u3 - 2.0f * u2 + u) * (dt * tangents[i])
                    + (2.0f * u3 - 3.0f * u2 + 1.0f) * keys[i].x
                    + (u3 - u2) * (dt * tangents[i + 1])
                    + (3.0f * u2 - 2.0f * u3) * keys[i + 1].x;
            }
        }
        return keys[NUM_KEYS - 1].x;
    }
    //-----------------------------------------------------------------------
    void RotationCurveAffector::_rebuild(void)
    {
        computeTangents(mYawKeys, mYawTangents);
        computeTangents(mPitchKeys, mPitchTangents);
        computeTangents(mRollKeys, mRollTangents);
        mDirty = false;
    }
    //-----------------------------------------------------------------------
    bool RotationCurveAffector::_isMeshRenderer(Ogre::ParticleSystem* pSystem) const
    {
        Ogre::ParticleSystemRenderer* renderer = pSystem ? pSystem->getRenderer() : NULL;
        return renderer && renderer->getType() == "mesh";
    }
    //-----------------------------------------------------------------------
    void RotationCurveAffector::_initParticle(Ogre::Particle* pParticle)
    {
        if (_isMeshRenderer(mParent))
        {
            Ogre::MeshParticleVisualData* vd = static_cast<Ogre::MeshParticleVisualData*>(pParticle->getVisualData());
            if (vd)
            {
                vd->mYawRotation = Ogre::Radian(Ogre::Degree(Ogre::Math::RangeRandom(mInitRotStart.x, mInitRotEnd.x)));
                vd->mPitchRotation = Ogre::Radian(Ogre::Degree(Ogre::Math::RangeRandom(mInitRotStart.y, mInitRotEnd.y)));
                vd->mRollRotation = Ogre::Radian(Ogre::Degree(Ogre::Math::RangeRandom(mInitRotStart.z, mInitRotEnd.z)));
            }
        }
        else
        {
            pParticle->rotation = Ogre::Radian(Ogre::Degree(Ogre::Math::RangeRandom(mInitRotStart.z, mInitRotEnd.z)));
        }
    }
    //-----------------------------------------------------------------------
    void RotationCurveAffector::_affectParticles(Ogre::ParticleSystem* pSystem, Fx::Real timeElapsed)
    {
        if (mDirty)
            _rebuild();

        const bool mesh = _isMeshRenderer(pSystem);

        Ogre::ParticleIterator it = pSystem->_getIterator();
        while (!it.end())
        {
            Ogre::Particle* p = it.getNext();
            const Fx::Real t = Fx::normalisedAge(p->timeToLive, p->totalTimeToLive);

            if (mesh)
            {
                Ogre::MeshParticleVisualData* vd = static_cast<Ogre::MeshParticleVisualData*>(p->getVisualData());
                if (!vd)
                    continue;
                vd->mYawRotation += Ogre::Radian(Ogre::Degree(evaluate(mYawKeys, mYawTangents, t) * timeElapsed));
                vd->mPitchRotation += Ogre::Radian(Ogre::Degree(evaluate(mPitchKeys, mPitchTangents, t) * timeElapsed));
                vd->mRollRotation += Ogre::Radian(Ogre::Degree(evaluate(mRollKeys, mRollTangents, t) * timeElapsed));
            }
            else
            {
                p->rotation += Ogre::Radian(Ogre::Degree(evaluate(mRollKeys, mRollTangents, t) * timeElapsed));
            }
        }

        // the mesh renderer only applies yaw / pitch / roll once a rotating affector notified it
        pSystem->_notifyParticleRotated();
    }

}
