


















#ifndef __WXSequenceFrameAffector_H__
#define __WXSequenceFrameAffector_H__

#include "WXFxParamHelpers.h"

#include <OgreParticleAffector.h>
#include <OgreParticleAffectorFactory.h>
#include "OgreExt/OgreTexCoordBillboardParticleRenderer.h"

#include <map>
#include <unordered_map> // CYS-PERF-FIX seqframe
#include <vector>

namespace WX {

    class SequenceFrameAffector : public Ogre::ParticleAffector, public Ogre::TexCoordIndexSource
    {
    public:
        enum PlayMode { PM_NORMAL = 0, PM_RANDOM = 1, PM_SINGLE = 2 };

        SequenceFrameAffector(Ogre::ParticleSystem* psys);
        ~SequenceFrameAffector();

        /** See ParticleAffector. */
        void _initParticle(Ogre::Particle* pParticle);
        /** See ParticleAffector. */
        void _affectParticles(Ogre::ParticleSystem* pSystem, Fx::Real timeElapsed);
        /** See TexCoordIndexSource. */
        Ogre::uint16 _getTexCoordIndex(Ogre::Particle* p, Ogre::uint16 numTexCoords);

        void _notifyParameterChanged(void) { mDirty = true; }

        // parsing helpers used by the command objects (they validate like the original data tools)
        void setPlayMode(const Fx::String& val);
        Fx::String getPlayModeString(void) const;
        void setHeadAndTail(const Fx::String& val);
        Fx::String getHeadAndTailString(void) const;
        void setPlayTimes(const Fx::String& val);
        Fx::String getPlayTimesString(void) const;
        void setBannedFrames(const Fx::String& val);
        Fx::String getBannedFramesString(void) const;
        void setStartRange(const Fx::String& val);
        Fx::String getStartRangeString(void) const;
        void copyTo(SequenceFrameAffector& other) const;

    public:
        int         mPlayMode;
        int         mStacks;
        int         mSlices;
        Fx::Real    mRepeatTimes;
        bool        mPingPong;
        bool        mLoop;

        // head_and_tail: frames (1-based), kind 0 = none, 1 = forward, 2 = backward, 3 = fixed frame
        Ogre::uint16 mHead, mTail, mHeadTailKind;
        // play_times: hold fractions of the first / last frame, kind = number of non zero holds
        Fx::Real    mHoldHead, mHoldTail;
        int         mHoldKind;
        std::vector<Ogre::uint16> mBannedFrames;
        Ogre::uint16 mStartA, mStartB;

        typedef Fx::MemberCmd<SequenceFrameAffector, Fx::IntCodec, &SequenceFrameAffector::mStacks> CmdStacks;
        typedef Fx::MemberCmd<SequenceFrameAffector, Fx::IntCodec, &SequenceFrameAffector::mSlices> CmdSlices;
        typedef Fx::MemberCmd<SequenceFrameAffector, Fx::RealCodec, &SequenceFrameAffector::mRepeatTimes> CmdRepeatTimes;
        typedef Fx::MemberCmd<SequenceFrameAffector, Fx::BoolCodec, &SequenceFrameAffector::mPingPong> CmdPingPong;
        typedef Fx::MemberCmd<SequenceFrameAffector, Fx::BoolCodec, &SequenceFrameAffector::mLoop> CmdLoop;

        /// command objects forwarding to the setters above (copy = full state copy)
        class CmdPlayMode : public Ogre::ParamCommand
        {
        public:
            Fx::String doGet(const void* target) const;
            void doSet(void* target, const Fx::String& val);
            void doCopy(void* target, const void* source);
        };
        class CmdHeadAndTail : public Ogre::ParamCommand
        {
        public:
            Fx::String doGet(const void* target) const;
            void doSet(void* target, const Fx::String& val);
            void doCopy(void* target, const void* source);
        };
        class CmdPlayTimes : public Ogre::ParamCommand
        {
        public:
            Fx::String doGet(const void* target) const;
            void doSet(void* target, const Fx::String& val);
            void doCopy(void* target, const void* source);
        };
        class CmdBannedFrames : public Ogre::ParamCommand
        {
        public:
            Fx::String doGet(const void* target) const;
            void doSet(void* target, const Fx::String& val);
            void doCopy(void* target, const void* source);
        };
        class CmdStartRange : public Ogre::ParamCommand
        {
        public:
            Fx::String doGet(const void* target) const;
            void doSet(void* target, const Fx::String& val);
            void doCopy(void* target, const void* source);
        };

        static CmdPlayMode     msPlayModeCmd;
        static CmdStacks       msStacksCmd;
        static CmdSlices       msSlicesCmd;
        static CmdRepeatTimes  msRepeatTimesCmd;
        static CmdPingPong     msPingPongCmd;
        static CmdLoop         msLoopCmd;
        static CmdStartRange   msStartRangeCmd;
        static CmdHeadAndTail  msHeadAndTailCmd;
        static CmdPlayTimes    msPlayTimesCmd;
        static CmdBannedFrames msBannedFramesCmd;

    protected:
        struct ParticleState
        {
            Ogre::uint16 start;     ///< start index in the frame list (start_range)
            Ogre::uint16 ordinal;   ///< birth order, used by the "single" mode
            Fx::Real     phase;     ///< random mode: current random cycle position (<0 = none yet)
            Fx::Real     lastTtl;   ///< random mode: timeToLive when the phase was chosen
        };
        // CYS-PERF-FIX seqframe: _getTexCoordIndex looks every particle up on every frame (texcoord submit +35 %
        // with std::map, fx-particles bench). A hash map makes the lookup O(1); nothing iterates the states in order.
        typedef std::unordered_map<const Ogre::Particle*, ParticleState> ParticleStateMap; // CYS-PERF-FIX seqframe

        int _frameCount(void) const;
        void _rebuild(void);
        void _bindRenderer(Ogre::ParticleSystem* pSystem);
        ParticleState& _state(Ogre::Particle* p);
        void _resetState(ParticleState& s);
        Ogre::uint16 _rollStart(void) const;

        /// playable frames (1-based atlas cells) after head_and_tail / play_times / baned_frames
        std::vector<Ogre::uint16> mFrames;
        bool mHasStartRange;
        Ogre::uint16 mStartLo, mStartHi;
        Ogre::uint16 mSingleStart;
        Ogre::uint16 mNextOrdinal;
        bool mDirty;
        ParticleStateMap mStates;
        Ogre::TexCoordBillboardParticleRenderer* mBoundRenderer;
    };

    //-----------------------------------------------------------------------
    class SequenceFrameAffectorFactory : public Ogre::ParticleAffectorFactory
    {
    public:
        Ogre::String getName() const { return "SequenceFrame"; }
        Ogre::ParticleAffector* createAffector(Ogre::ParticleSystem* psys)
        {
            Ogre::ParticleAffector* p = new SequenceFrameAffector(psys);
            mAffectors.push_back(p);
            return p;
        }
    };

}

#endif
