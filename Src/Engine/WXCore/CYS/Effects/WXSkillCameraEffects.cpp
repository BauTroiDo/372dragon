/*
CYS: CameraShake / ComplexBlur runtime and parameter classes - see WXSkillCameraEffects.h.
*/
#include "WXSkillCameraEffects.h"

#include "EffectSystem/WXSkill.h"
#include "Core/WXSystem.h"
#include "PostFilter/WXPostFilterManager.h"

#include <OgreCamera.h>
#include <OgreStringConverter.h>

#include <map>
#include <cstdlib>

namespace WX {

    AnimationCameraShake::CmdAttachTime     AnimationCameraShake::msAttachTimeCmd;
    AnimationCameraShake::CmdDuration       AnimationCameraShake::msDurationCmd;
    AnimationCameraShake::CmdRotAmplitude   AnimationCameraShake::msRotAmplitudeCmd;
    AnimationCameraShake::CmdRotFrequency   AnimationCameraShake::msRotFrequencyCmd;
    AnimationCameraShake::CmdLocAmplitude   AnimationCameraShake::msLocAmplitudeCmd;
    AnimationCameraShake::CmdLocFrequency   AnimationCameraShake::msLocFrequencyCmd;
    AnimationCameraShake::CmdFovAmplitude   AnimationCameraShake::msFovAmplitudeCmd;
    AnimationCameraShake::CmdFovFrequency   AnimationCameraShake::msFovFrequencyCmd;
    AnimationCameraShake::CmdShakeManner    AnimationCameraShake::msShakeMannerCmd;
    AnimationCameraShake::CmdIsLocalVisible AnimationCameraShake::msIsLocalVisibleCmd;

    AnimationComplexBlur::CmdAttachTime     AnimationComplexBlur::msAttachTimeCmd;
    AnimationComplexBlur::CmdStartTime      AnimationComplexBlur::msStartTimeCmd;
    AnimationComplexBlur::CmdMidTime        AnimationComplexBlur::msMidTimeCmd;
    AnimationComplexBlur::CmdEndTime        AnimationComplexBlur::msEndTimeCmd;
    AnimationComplexBlur::CmdStrength       AnimationComplexBlur::msStrengthCmd;
    AnimationComplexBlur::CmdUnblured       AnimationComplexBlur::msUnbluredCmd;
    AnimationComplexBlur::CmdFinalDistance  AnimationComplexBlur::msFinalDistanceCmd;
    AnimationComplexBlur::CmdIsLocalVisible AnimationComplexBlur::msIsLocalVisibleCmd;

    //-----------------------------------------------------------------------
    AnimationCameraShake::AnimationCameraShake(void)
        : mAttachTime(0.0f)
        , mDuration(0.0f)
        , mRotAmplitude(Ogre::Vector3::ZERO)
        , mRotFrequency(Ogre::Vector3::UNIT_SCALE)
        , mLocAmplitude(Ogre::Vector3::ZERO)
        , mLocFrequency(Ogre::Vector3::UNIT_SCALE)
        , mFovAmplitude(0.0f)
        , mFovFrequency(1.0f)
        , mShakeManner("LinearDecrease")
        , mIsLocalVisible(true)
    {
        if (createParamDictionary("AnimationCameraShake"))
        {
            Ogre::ParamDictionary* dict = getParamDictionary();
            dict->addParameter(Ogre::ParameterDef("AttachTime", "normalised anim time.", Ogre::PT_REAL), &msAttachTimeCmd);
            dict->addParameter(Ogre::ParameterDef("Duration", "duration in seconds.", Ogre::PT_REAL), &msDurationCmd);
            dict->addParameter(Ogre::ParameterDef("RotAmplitude", "rotation amplitude (degrees).", Ogre::PT_VECTOR3), &msRotAmplitudeCmd);
            dict->addParameter(Ogre::ParameterDef("RotFrequency", "rotation frequency.", Ogre::PT_VECTOR3), &msRotFrequencyCmd);
            dict->addParameter(Ogre::ParameterDef("LocAmplitude", "location amplitude.", Ogre::PT_VECTOR3), &msLocAmplitudeCmd);
            dict->addParameter(Ogre::ParameterDef("LocFrequency", "location frequency.", Ogre::PT_VECTOR3), &msLocFrequencyCmd);
            dict->addParameter(Ogre::ParameterDef("FovAmplitude", "fov amplitude (degrees).", Ogre::PT_REAL), &msFovAmplitudeCmd);
            dict->addParameter(Ogre::ParameterDef("FovFrequency", "fov frequency.", Ogre::PT_REAL), &msFovFrequencyCmd);
            dict->addParameter(Ogre::ParameterDef("ShakeManner", "LinearDecrease/Increase, QuadraticDecrease/Increase.", Ogre::PT_STRING), &msShakeMannerCmd);
            dict->addParameter(Ogre::ParameterDef("IsLocalVisible", "only shake for the local player.", Ogre::PT_BOOL), &msIsLocalVisibleCmd);
        }
    }
    //-----------------------------------------------------------------------
    void AnimationCameraShake::copyParameters(AnimationCameraShake& o) const
    {
        o.mAttachTime = mAttachTime; o.mDuration = mDuration;
        o.mRotAmplitude = mRotAmplitude; o.mRotFrequency = mRotFrequency;
        o.mLocAmplitude = mLocAmplitude; o.mLocFrequency = mLocFrequency;
        o.mFovAmplitude = mFovAmplitude; o.mFovFrequency = mFovFrequency;
        o.mShakeManner = mShakeManner; o.mIsLocalVisible = mIsLocalVisible;
    }
    //-----------------------------------------------------------------------
    AnimationComplexBlur::AnimationComplexBlur(void)
        : mAttachTime(0.0f)
        , mStartTime(0.0f)
        , mMidTime(0.0f)
        , mEndTime(0.0f)
        , mStrength(0.05f)
        , mUnblured(0.1f)
        , mFinalDistance(24.0f)
        , mIsLocalVisible(true)
    {
        if (createParamDictionary("AnimationComplexBlur"))
        {
            Ogre::ParamDictionary* dict = getParamDictionary();
            dict->addParameter(Ogre::ParameterDef("AttachTime", "normalised anim time.", Ogre::PT_REAL), &msAttachTimeCmd);
            dict->addParameter(Ogre::ParameterDef("StartTime", "ramp-in duration (s).", Ogre::PT_REAL), &msStartTimeCmd);
            dict->addParameter(Ogre::ParameterDef("MidTime", "hold duration (s).", Ogre::PT_REAL), &msMidTimeCmd);
            dict->addParameter(Ogre::ParameterDef("EndTime", "ramp-out duration (s).", Ogre::PT_REAL), &msEndTimeCmd);
            dict->addParameter(Ogre::ParameterDef("Strength", "blur strength.", Ogre::PT_REAL), &msStrengthCmd);
            dict->addParameter(Ogre::ParameterDef("Unblured", "unblurred amount.", Ogre::PT_REAL), &msUnbluredCmd);
            dict->addParameter(Ogre::ParameterDef("FinalDistance", "blur distance at full strength.", Ogre::PT_REAL), &msFinalDistanceCmd);
            dict->addParameter(Ogre::ParameterDef("IsLocalVisible", "only blur for the local player.", Ogre::PT_BOOL), &msIsLocalVisibleCmd);
        }
    }
    //-----------------------------------------------------------------------
    void AnimationComplexBlur::copyParameters(AnimationComplexBlur& o) const
    {
        o.mAttachTime = mAttachTime; o.mStartTime = mStartTime; o.mMidTime = mMidTime; o.mEndTime = mEndTime;
        o.mStrength = mStrength; o.mUnblured = mUnblured; o.mFinalDistance = mFinalDistance;
        o.mIsLocalVisible = mIsLocalVisible;
    }

    //=======================================================================
    // runtime
    //=======================================================================
    namespace {
        const void* gLocalPlayerModel = NULL;
        bool gApplyToAll = false;

        // did the normalised animation time cross 'attach' between oldTime and currTime (with wrap)?
        inline bool crossed(Fx::Real attach, Fx::Real oldTime, Fx::Real currTime)
        {
            if (currTime >= oldTime)
                return attach >= oldTime && attach < currTime;
            return attach >= oldTime || attach < currTime;   // animation wrapped around
        }
        inline Fx::Real osc(Fx::Real t, Fx::Real amplitude, Fx::Real frequency)
        {
            if (frequency <= 0.0f)
                return 0.0f;
            return amplitude * Ogre::Math::Cos(Ogre::Radian(Ogre::Math::TWO_PI * frequency * t));
        }
    }
    //-----------------------------------------------------------------------
    SkillCameraEffectState::SkillCameraEffectState(void)
        : mSystem(NULL)
        , mShakeIndex(0)
        , mShaking(false)
        , mShakeElapsed(0.0f)
        , mAppliedRotation(Ogre::Vector3::ZERO)
        , mAppliedLocation(Ogre::Vector3::ZERO)
        , mSavedFov(Ogre::Radian(0.0f))
        , mBlurActive(false)
        , mBlurApplied(false)
        , mBlurElapsed(0.0f)
    {
    }
    //-----------------------------------------------------------------------
    SkillCameraEffectState::~SkillCameraEffectState()
    {
        stop();
    }
    //-----------------------------------------------------------------------
    void SkillCameraEffectState::stop(void)
    {
        if (mShaking)
            _endShake();
        if (mBlurActive || mBlurApplied)
            _stopBlur();
    }
    //-----------------------------------------------------------------------
    void SkillCameraEffectState::_startShake(const AnimationCameraShake& shake)
    {
        Ogre::Camera* cam = mSystem ? mSystem->getCamera() : NULL;
        if (!cam)
            return;
        mShaking = true;
        mShakeElapsed = 0.0f;
        mAppliedRotation = Ogre::Vector3::ZERO;
        mAppliedLocation = Ogre::Vector3::ZERO;
        mSavedFov = cam->getFOVy();
    }
    //-----------------------------------------------------------------------
    void SkillCameraEffectState::_updateShake(const AnimationCameraShake& shake, Fx::Real delta)
    {
        Ogre::Camera* cam = mSystem ? mSystem->getCamera() : NULL;
        if (!cam)
        {
            mShaking = false;
            return;
        }

        mShakeElapsed += delta;
        if (shake.mDuration > 0.0f && mShakeElapsed >= shake.mDuration)
        {
            _endShake();
            return;
        }

        const Fx::Real t = mShakeElapsed;
        const Fx::Real d = (shake.mDuration > 0.0f) ? shake.mDuration : 1.0f;
        const Fx::Real x = t / d;

        Fx::Real factor;
        if (shake.mShakeManner == "QuadraticDecrease")     factor = (1.0f - x) * (1.0f - x);
        else if (shake.mShakeManner == "QuadraticIncrease") factor = x * x;
        else if (shake.mShakeManner == "LinearDecrease")    factor = 1.0f - x;
        else if (shake.mShakeManner == "LinearIncrease")    factor = x;
        else                                                factor = 1.0f;

        // rotation (degrees): apply the delta from the previous frame's offset
        const Ogre::Vector3 rot(
            osc(t, shake.mRotAmplitude.x, shake.mRotFrequency.x) * factor,
            osc(t, shake.mRotAmplitude.y, shake.mRotFrequency.y) * factor,
            osc(t, shake.mRotAmplitude.z, shake.mRotFrequency.z) * factor);
        cam->pitch(Ogre::Degree(rot.x - mAppliedRotation.x));
        cam->yaw(Ogre::Degree(rot.y - mAppliedRotation.y));
        cam->roll(Ogre::Degree(rot.z - mAppliedRotation.z));
        mAppliedRotation = rot;

        // location: apply the delta relative to the camera axes
        const Ogre::Vector3 loc(
            osc(t, shake.mLocAmplitude.x, shake.mLocFrequency.x) * factor,
            osc(t, shake.mLocAmplitude.y, shake.mLocFrequency.y) * factor,
            osc(t, shake.mLocAmplitude.z, shake.mLocFrequency.z) * factor);
        cam->moveRelative(loc - mAppliedLocation);
        mAppliedLocation = loc;

        // fov around the saved value
        cam->setFOVy(mSavedFov + Ogre::Degree(osc(t, shake.mFovAmplitude, shake.mFovFrequency) * factor));
    }
    //-----------------------------------------------------------------------
    void SkillCameraEffectState::_endShake(void)
    {
        Ogre::Camera* cam = mSystem ? mSystem->getCamera() : NULL;
        if (cam)
        {
            // undo the last offsets, restore the fov
            cam->pitch(Ogre::Degree(-mAppliedRotation.x));
            cam->yaw(Ogre::Degree(-mAppliedRotation.y));
            cam->roll(Ogre::Degree(-mAppliedRotation.z));
            cam->moveRelative(-mAppliedLocation);
            cam->setFOVy(mSavedFov);
        }
        mShaking = false;
        mAppliedRotation = Ogre::Vector3::ZERO;
        mAppliedLocation = Ogre::Vector3::ZERO;
    }
    //-----------------------------------------------------------------------
    void SkillCameraEffectState::_stopBlur(void)
    {
        if (mSystem && mBlurApplied)
        {
            PostFilterManager* pfm = mSystem->getPostFilterManager();
            if (pfm && pfm->hasPostFilter("ComplexBlur"))
                pfm->setPostFilterEnabled("ComplexBlur", false);
        }
        mBlurActive = false;
        mBlurApplied = false;
        mBlurElapsed = 0.0f;
    }
    //-----------------------------------------------------------------------
    void SkillCameraEffectState::_updateBlur(const AnimationComplexBlur& blur, bool triggered, Fx::Real delta)
    {
        if (triggered && !mBlurActive)
        {
            mBlurActive = true;
            mBlurElapsed = 0.0f;
        }
        if (!mBlurActive)
            return;

        mBlurElapsed += delta;
        const Fx::Real total = blur.mStartTime + blur.mMidTime + blur.mEndTime;
        if (mBlurElapsed > total)
        {
            _stopBlur();
            return;
        }

        PostFilterManager* pfm = mSystem ? mSystem->getPostFilterManager() : NULL;
        if (!pfm || !pfm->hasPostFilter("ComplexBlur"))
        {
            // 0.85 has no ComplexBlur post filter; report once and let the phase timer run out
            Fx::logOnce("ComplexBlur.missing", "ComplexBlur: post filter 'ComplexBlur' not available in this build");
            return;
        }

        // distance ramps 0 -> FinalDistance during Start, holds during Mid, FinalDistance -> 0 during End
        Fx::Real distance;
        if (mBlurElapsed < blur.mStartTime)
            distance = (blur.mStartTime > 0.0f) ? blur.mFinalDistance * (mBlurElapsed / blur.mStartTime) : blur.mFinalDistance;
        else if (mBlurElapsed < blur.mStartTime + blur.mMidTime)
            distance = blur.mFinalDistance;
        else
        {
            const Fx::Real endElapsed = mBlurElapsed - blur.mStartTime - blur.mMidTime;
            distance = (blur.mEndTime > 0.0f) ? blur.mFinalDistance * (1.0f - endElapsed / blur.mEndTime) : 0.0f;
        }

        pfm->setPostFilterEnabled("ComplexBlur", true);
        pfm->setPostFilterParameter("ComplexBlur", "Unblured", Ogre::StringConverter::toString(blur.mUnblured));
        pfm->setPostFilterParameter("ComplexBlur", "Strength", Ogre::StringConverter::toString(blur.mStrength));
        pfm->setPostFilterParameter("ComplexBlur", "Distance", Ogre::StringConverter::toString(distance));
        mBlurApplied = true;
    }
    //-----------------------------------------------------------------------
    void SkillCameraEffectState::update(Skill* skill, bool isLocalPlayer, Fx::Real oldTime, Fx::Real currTime, Fx::Real delta)
    {
        mSystem = skill->getSystem();

        // -------- camera shake --------
        const unsigned short numShakes = skill->getNumAnimationCameraShakes();
        if (numShakes > 0)
        {
            if (mShaking)
            {
                _updateShake(*skill->getAnimationCameraShake(mShakeIndex % numShakes), delta);
            }
            else
            {
                for (unsigned short i = 0; i < numShakes; ++i)
                {
                    const AnimationCameraShake* shake = skill->getAnimationCameraShake(i);
                    const bool allowed = isLocalPlayer || !shake->mIsLocalVisible || gApplyToAll;
                    if (allowed && crossed(shake->mAttachTime, oldTime, currTime))
                    {
                        mShakeIndex = i;
                        _startShake(*shake);
                        _updateShake(*shake, delta);
                        break;
                    }
                }
            }
        }

        // -------- complex blur --------
        const unsigned short numBlurs = skill->getNumAnimationComplexBlurs();
        if (numBlurs > 0)
        {
            const AnimationComplexBlur* blur = skill->getAnimationComplexBlur(0);
            const bool allowed = isLocalPlayer || !blur->mIsLocalVisible || gApplyToAll;
            const bool triggered = allowed && crossed(blur->mAttachTime, oldTime, currTime);
            _updateBlur(*blur, triggered, delta);
        }
    }

    //-----------------------------------------------------------------------
    namespace SkillCameraEffects {

        namespace {
            typedef std::map<const void*, SkillCameraEffectState> StateMap;
            StateMap& states(void)
            {
                static StateMap sStates;
                return sStates;
            }
        }

        void setLocalPlayerModel(const void* model)
        {
            gLocalPlayerModel = model;
        }
        void setApplyToAllModels(bool all)
        {
            gApplyToAll = all;
        }
        void update(const void* model, Skill* skill, Fx::Real oldTime, Fx::Real currTime, Fx::Real delta)
        {
            if (!skill)
                return;
            if (skill->getNumAnimationCameraShakes() == 0 && skill->getNumAnimationComplexBlurs() == 0)
                return;

            // one-time opt-in for the viewer / debug: play IsLocalVisible blocks for every model
            static bool checkedEnv = false;
            if (!checkedEnv)
            {
                checkedEnv = true;
                const char* env = std::getenv("CYS_FX_CAMERA_EFFECTS_ALL");
                if (env && env[0] == '1')
                    gApplyToAll = true;
            }

            // only the local player's IsLocalVisible blocks play; if the game never sets a local player, they
            // stay off (unless CYS_FX_CAMERA_EFFECTS_ALL=1) so a scene full of models does not shake the camera
            const bool isLocalPlayer = (gLocalPlayerModel != NULL && gLocalPlayerModel == model);
            states()[model].update(skill, isLocalPlayer, oldTime, currTime, delta);
        }
    }

}
