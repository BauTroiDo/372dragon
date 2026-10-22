



















#ifndef __WXSkillCameraEffects_H__
#define __WXSkillCameraEffects_H__

#include "WXFxParamHelpers.h"

#include <OgreStringInterface.h>
#include <OgreVector3.h>
#include <OgreMath.h>

namespace WX {

    class Skill;
    class System;

    //-----------------------------------------------------------------------
    class AnimationCameraShake : public Ogre::StringInterface
    {
    public:
        AnimationCameraShake(void);

        void _notifyParameterChanged(void) {}
        void copyParameters(AnimationCameraShake& other) const;

    public:
        Fx::Real        mAttachTime;
        Fx::Real        mDuration;
        Ogre::Vector3   mRotAmplitude;
        Ogre::Vector3   mRotFrequency;
        Ogre::Vector3   mLocAmplitude;
        Ogre::Vector3   mLocFrequency;
        Fx::Real        mFovAmplitude;
        Fx::Real        mFovFrequency;
        Fx::String      mShakeManner;
        bool            mIsLocalVisible;

        typedef Fx::MemberCmd<AnimationCameraShake, Fx::RealCodec, &AnimationCameraShake::mAttachTime> CmdAttachTime;
        typedef Fx::MemberCmd<AnimationCameraShake, Fx::RealCodec, &AnimationCameraShake::mDuration> CmdDuration;
        typedef Fx::MemberCmd<AnimationCameraShake, Fx::Vector3Codec, &AnimationCameraShake::mRotAmplitude> CmdRotAmplitude;
        typedef Fx::MemberCmd<AnimationCameraShake, Fx::Vector3Codec, &AnimationCameraShake::mRotFrequency> CmdRotFrequency;
        typedef Fx::MemberCmd<AnimationCameraShake, Fx::Vector3Codec, &AnimationCameraShake::mLocAmplitude> CmdLocAmplitude;
        typedef Fx::MemberCmd<AnimationCameraShake, Fx::Vector3Codec, &AnimationCameraShake::mLocFrequency> CmdLocFrequency;
        typedef Fx::MemberCmd<AnimationCameraShake, Fx::RealCodec, &AnimationCameraShake::mFovAmplitude> CmdFovAmplitude;
        typedef Fx::MemberCmd<AnimationCameraShake, Fx::RealCodec, &AnimationCameraShake::mFovFrequency> CmdFovFrequency;
        typedef Fx::MemberCmd<AnimationCameraShake, Fx::StringCodec, &AnimationCameraShake::mShakeManner> CmdShakeManner;
        typedef Fx::MemberCmd<AnimationCameraShake, Fx::BoolCodec, &AnimationCameraShake::mIsLocalVisible> CmdIsLocalVisible;

        static CmdAttachTime     msAttachTimeCmd;
        static CmdDuration       msDurationCmd;
        static CmdRotAmplitude   msRotAmplitudeCmd;
        static CmdRotFrequency   msRotFrequencyCmd;
        static CmdLocAmplitude   msLocAmplitudeCmd;
        static CmdLocFrequency   msLocFrequencyCmd;
        static CmdFovAmplitude   msFovAmplitudeCmd;
        static CmdFovFrequency   msFovFrequencyCmd;
        static CmdShakeManner    msShakeMannerCmd;
        static CmdIsLocalVisible msIsLocalVisibleCmd;
    };

    //-----------------------------------------------------------------------
    class AnimationComplexBlur : public Ogre::StringInterface
    {
    public:
        AnimationComplexBlur(void);

        void _notifyParameterChanged(void) {}
        void copyParameters(AnimationComplexBlur& other) const;

    public:
        Fx::Real    mAttachTime;
        Fx::Real    mStartTime;
        Fx::Real    mMidTime;
        Fx::Real    mEndTime;
        Fx::Real    mStrength;
        Fx::Real    mUnblured;
        Fx::Real    mFinalDistance;
        bool        mIsLocalVisible;

        typedef Fx::MemberCmd<AnimationComplexBlur, Fx::RealCodec, &AnimationComplexBlur::mAttachTime> CmdAttachTime;
        typedef Fx::MemberCmd<AnimationComplexBlur, Fx::RealCodec, &AnimationComplexBlur::mStartTime> CmdStartTime;
        typedef Fx::MemberCmd<AnimationComplexBlur, Fx::RealCodec, &AnimationComplexBlur::mMidTime> CmdMidTime;
        typedef Fx::MemberCmd<AnimationComplexBlur, Fx::RealCodec, &AnimationComplexBlur::mEndTime> CmdEndTime;
        typedef Fx::MemberCmd<AnimationComplexBlur, Fx::RealCodec, &AnimationComplexBlur::mStrength> CmdStrength;
        typedef Fx::MemberCmd<AnimationComplexBlur, Fx::RealCodec, &AnimationComplexBlur::mUnblured> CmdUnblured;
        typedef Fx::MemberCmd<AnimationComplexBlur, Fx::RealCodec, &AnimationComplexBlur::mFinalDistance> CmdFinalDistance;
        typedef Fx::MemberCmd<AnimationComplexBlur, Fx::BoolCodec, &AnimationComplexBlur::mIsLocalVisible> CmdIsLocalVisible;

        static CmdAttachTime     msAttachTimeCmd;
        static CmdStartTime      msStartTimeCmd;
        static CmdMidTime        msMidTimeCmd;
        static CmdEndTime        msEndTimeCmd;
        static CmdStrength       msStrengthCmd;
        static CmdUnblured       msUnbluredCmd;
        static CmdFinalDistance  msFinalDistanceCmd;
        static CmdIsLocalVisible msIsLocalVisibleCmd;
    };

    //-----------------------------------------------------------------------
    /** Runtime state of the camera effects of one skill instance (owned by the Skill). */
    class SkillCameraEffectState
    {
    public:
        SkillCameraEffectState(void);
        /// undoes an active shake and disables an active blur
        ~SkillCameraEffectState();

        void update(Skill* skill, bool isLocalPlayer, Fx::Real oldTime, Fx::Real currTime, Fx::Real delta);
        void stop(void);

    protected:
        void _startShake(const AnimationCameraShake& shake);
        void _updateShake(const AnimationCameraShake& shake, Fx::Real delta);
        void _endShake(void);
        void _updateBlur(const AnimationComplexBlur& blur, bool triggered, Fx::Real delta);
        void _stopBlur(void);

        System*         mSystem;
        unsigned short  mShakeIndex;
        bool            mShaking;
        Fx::Real        mShakeElapsed;
        Ogre::Vector3   mAppliedRotation;   ///< degrees (pitch, yaw, roll)
        Ogre::Vector3   mAppliedLocation;
        Ogre::Radian    mSavedFov;
        bool            mBlurActive;
        bool            mBlurApplied;
        Fx::Real        mBlurElapsed;
    };

    //-----------------------------------------------------------------------
    namespace SkillCameraEffects
    {
        /** Called by LogicModel::execute for the current skill (normalised animation times, frame time). */
        void update(const void* model, Skill* skill, Fx::Real oldTime, Fx::Real currTime, Fx::Real delta);
        /** The model of the local player (IsLocalVisible blocks only play for it). */
        void setLocalPlayerModel(const void* model);
        /** Debug / viewer: play IsLocalVisible blocks for every model (environment CYS_FX_CAMERA_EFFECTS_ALL=1). */
        void setApplyToAllModels(bool all);
    }

}

#endif
