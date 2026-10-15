/*
CYS: SequenceFrame affector - see WXSequenceFrameAffector.h.
*/
#include "WXSequenceFrameAffector.h"

#include <OgreParticleSystem.h>
#include <OgreParticle.h>
#include <OgreMath.h>

#include <algorithm>

namespace WX {

    SequenceFrameAffector::CmdPlayMode     SequenceFrameAffector::msPlayModeCmd;
    SequenceFrameAffector::CmdStacks       SequenceFrameAffector::msStacksCmd;
    SequenceFrameAffector::CmdSlices       SequenceFrameAffector::msSlicesCmd;
    SequenceFrameAffector::CmdRepeatTimes  SequenceFrameAffector::msRepeatTimesCmd;
    SequenceFrameAffector::CmdPingPong     SequenceFrameAffector::msPingPongCmd;
    SequenceFrameAffector::CmdLoop         SequenceFrameAffector::msLoopCmd;
    SequenceFrameAffector::CmdStartRange   SequenceFrameAffector::msStartRangeCmd;
    SequenceFrameAffector::CmdHeadAndTail  SequenceFrameAffector::msHeadAndTailCmd;
    SequenceFrameAffector::CmdPlayTimes    SequenceFrameAffector::msPlayTimesCmd;
    SequenceFrameAffector::CmdBannedFrames SequenceFrameAffector::msBannedFramesCmd;

    namespace {
        inline bool isNone(const Fx::String& val)
        {
            return val.empty() || val == "none";
        }
        inline std::vector<Fx::String> tokens(const Fx::String& val)
        {
            return Ogre::StringUtil::split(val, " \t");
        }
    }

    //-----------------------------------------------------------------------
    SequenceFrameAffector::SequenceFrameAffector(Ogre::ParticleSystem* psys)
        : Ogre::ParticleAffector(psys)
        , mPlayMode(PM_NORMAL)
        , mStacks(1)
        , mSlices(1)
        , mRepeatTimes(1.0f)
        , mPingPong(false)
        , mLoop(true)
        , mHead(0), mTail(0), mHeadTailKind(0)
        , mHoldHead(0), mHoldTail(0), mHoldKind(0)
        , mStartA(0), mStartB(0)
        , mHasStartRange(false)
        , mStartLo(0), mStartHi(0)
        , mSingleStart(0)
        , mNextOrdinal(0)
        , mDirty(true)
        , mBoundRenderer(NULL)
    {
        mType = "SequenceFrame";

        if (createParamDictionary("SequenceFrameAffector"))
        {
            addBaseParameters();
            Ogre::ParamDictionary* dict = getParamDictionary();

            dict->addParameter(Ogre::ParameterDef("play_mode",
                "normal, random or single.", Ogre::PT_STRING), &msPlayModeCmd);
            dict->addParameter(Ogre::ParameterDef("stacks",
                "the rows of the frame atlas.", Ogre::PT_UNSIGNED_LONG), &msStacksCmd);
            dict->addParameter(Ogre::ParameterDef("slices",
                "the columns of the frame atlas.", Ogre::PT_UNSIGNED_LONG), &msSlicesCmd);
            dict->addParameter(Ogre::ParameterDef("repeat_times",
                "flip-book cycles over the particle life.", Ogre::PT_REAL), &msRepeatTimesCmd);
            dict->addParameter(Ogre::ParameterDef("pingpang",
                "play forward then backward.", Ogre::PT_BOOL), &msPingPongCmd);
            dict->addParameter(Ogre::ParameterDef("start_range",
                "random start frame range (1-based).", Ogre::PT_STRING), &msStartRangeCmd);
            dict->addParameter(Ogre::ParameterDef("loop",
                "loop the flip-book.", Ogre::PT_BOOL), &msLoopCmd);
            dict->addParameter(Ogre::ParameterDef("head_and_tail",
                "first and last frame played (1-based).", Ogre::PT_STRING), &msHeadAndTailCmd);
            dict->addParameter(Ogre::ParameterDef("play_times",
                "hold fractions of the first and last frame.", Ogre::PT_STRING), &msPlayTimesCmd);
            dict->addParameter(Ogre::ParameterDef("baned_frames",
                "frames skipped by the flip-book (1-based).", Ogre::PT_STRING), &msBannedFramesCmd);
        }
    }
    //-----------------------------------------------------------------------
    SequenceFrameAffector::~SequenceFrameAffector()
    {
        // the particle system destroys its affectors before its renderer: unbind from a renderer still using us
        if (mBoundRenderer && mParent && mParent->getRenderer() == mBoundRenderer &&
            mBoundRenderer->getTexCoordIndexSource() == this)
        {
            mBoundRenderer->setTexCoordIndexSource(NULL);
        }
    }
    //-----------------------------------------------------------------------
    int SequenceFrameAffector::_frameCount(void) const
    {
        return std::max(1, mStacks) * std::max(1, mSlices);
    }
    //-----------------------------------------------------------------------
    void SequenceFrameAffector::setPlayMode(const Fx::String& val)
    {
        if (val == "normal")
            mPlayMode = PM_NORMAL;
        else if (val == "random")
            mPlayMode = PM_RANDOM;
        else if (val == "single")
            mPlayMode = PM_SINGLE;
        else
            Fx::logOnce("SequenceFrame.play_mode=" + val, "SequenceFrame: unknown play_mode '" + val + "', kept normal");
        mDirty = true;
    }
    Fx::String SequenceFrameAffector::getPlayModeString(void) const
    {
        return mPlayMode == PM_RANDOM ? "random" : (mPlayMode == PM_SINGLE ? "single" : "normal");
    }
    //-----------------------------------------------------------------------
    void SequenceFrameAffector::setHeadAndTail(const Fx::String& val)
    {
        if (isNone(val))
            return;

        const int total = _frameCount();
        std::vector<Fx::String> t = tokens(val);
        if (t.size() == 2 && val[0] != '-')
        {
            const int a = Ogre::StringConverter::parseInt(t[0]);
            const int b = Ogre::StringConverter::parseInt(t[1]);
            if (a > 0 && b > 0 && a <= total && b <= total)
            {
                mHead = static_cast<Ogre::uint16>(a);
                mTail = static_cast<Ogre::uint16>(b);
                mHeadTailKind = (a < b) ? 1 : (a > b ? 2 : 3);
                if (mHeadTailKind == 3)
                    mBannedFrames.clear();
                mDirty = true;
                return;
            }
        }
        // invalid: play every frame
        mHeadTailKind = 0;
        mHead = 1;
        mTail = static_cast<Ogre::uint16>(total);
        mDirty = true;
    }
    Fx::String SequenceFrameAffector::getHeadAndTailString(void) const
    {
        if (mHeadTailKind == 0)
            return "none";
        return Ogre::StringConverter::toString(mHead) + " " + Ogre::StringConverter::toString(mTail);
    }
    //-----------------------------------------------------------------------
    void SequenceFrameAffector::setPlayTimes(const Fx::String& val)
    {
        if (isNone(val))
            return;

        std::vector<Fx::String> t = tokens(val);
        if (t.size() == 2 && val[0] != '-')
        {
            const Fx::Real a = Ogre::StringConverter::parseReal(t[0]);
            const Fx::Real b = Ogre::StringConverter::parseReal(t[1]);
            if (a + b <= 1.0f)
            {
                mHoldHead = a;
                mHoldTail = b;
                mHoldKind = (a + b == 0.0f) ? 0 : (a * b == 0.0f ? 1 : 2);
                mDirty = true;
                return;
            }
        }
        mHoldHead = mHoldTail = 0.0f;
        mHoldKind = 0;
        mDirty = true;
    }
    Fx::String SequenceFrameAffector::getPlayTimesString(void) const
    {
        if (mHoldHead == 0.0f && mHoldTail == 0.0f)
            return "none";
        return Ogre::StringConverter::toString(mHoldHead) + " " + Ogre::StringConverter::toString(mHoldTail);
    }
    //-----------------------------------------------------------------------
    void SequenceFrameAffector::setBannedFrames(const Fx::String& val)
    {
        mBannedFrames.clear();
        mDirty = true;
        if (isNone(val) || mHeadTailKind == 3)
            return;

        const int total = _frameCount();
        int lo = 1, hi = total;
        if (mHead != 0)
        {
            lo = std::min<int>(mHead, mTail);
            hi = std::max<int>(mHead, mTail);
        }
        std::vector<Fx::String> t = tokens(val);
        for (size_t i = 0; i < t.size(); ++i)
        {
            const int f = Ogre::StringConverter::parseInt(t[i]);
            if (f > 0 && f <= total && f >= lo && f <= hi &&
                std::find(mBannedFrames.begin(), mBannedFrames.end(), static_cast<Ogre::uint16>(f)) == mBannedFrames.end())
            {
                mBannedFrames.push_back(static_cast<Ogre::uint16>(f));
            }
        }
        std::sort(mBannedFrames.begin(), mBannedFrames.end());
    }
    Fx::String SequenceFrameAffector::getBannedFramesString(void) const
    {
        if (mBannedFrames.empty())
            return "none";
        Fx::String s;
        for (size_t i = 0; i < mBannedFrames.size(); ++i)
            s += (i ? " " : "") + Ogre::StringConverter::toString(mBannedFrames[i]);
        return s;
    }
    //-----------------------------------------------------------------------
    void SequenceFrameAffector::setStartRange(const Fx::String& val)
    {
        mStartA = mStartB = 0;
        mDirty = true;

        std::vector<Fx::String> t = tokens(val);
        if (t.size() != 2 || mHeadTailKind == 3)
            return;

        int range = std::abs(static_cast<int>(mTail) - static_cast<int>(mHead)) + 1 - static_cast<int>(mBannedFrames.size());
        if (mHeadTailKind == 0)
            range += _frameCount() - 1;

        const int a = Ogre::StringConverter::parseInt(t[0]);
        const int b = Ogre::StringConverter::parseInt(t[1]);
        if (a > 0 && b > 0 && a <= range && b <= range)
        {
            mStartA = static_cast<Ogre::uint16>(a);
            mStartB = static_cast<Ogre::uint16>(b);
        }
    }
    Fx::String SequenceFrameAffector::getStartRangeString(void) const
    {
        return Ogre::StringConverter::toString(mStartA) + " " + Ogre::StringConverter::toString(mStartB);
    }
    //-----------------------------------------------------------------------
    void SequenceFrameAffector::copyTo(SequenceFrameAffector& o) const
    {
        o.mPlayMode = mPlayMode;
        o.mStacks = mStacks;
        o.mSlices = mSlices;
        o.mRepeatTimes = mRepeatTimes;
        o.mPingPong = mPingPong;
        o.mLoop = mLoop;
        o.mHead = mHead;
        o.mTail = mTail;
        o.mHeadTailKind = mHeadTailKind;
        o.mHoldHead = mHoldHead;
        o.mHoldTail = mHoldTail;
        o.mHoldKind = mHoldKind;
        o.mBannedFrames = mBannedFrames;
        o.mStartA = mStartA;
        o.mStartB = mStartB;
        o.mDirty = true;
    }
    //-----------------------------------------------------------------------
    void SequenceFrameAffector::_rebuild(void)
    {
        const int total = _frameCount();

        int head = mHead, tail = mTail;
        if (mHeadTailKind == 0 || head == 0 || tail == 0)
        {
            head = 1;
            tail = total;
        }
        const int step = (mHeadTailKind == 2) ? -1 : 1;

        mFrames.clear();
        if (mHoldHead == 1.0f)
        {
            mFrames.push_back(static_cast<Ogre::uint16>(head));
        }
        else if (mHoldTail == 1.0f)
        {
            mFrames.push_back(static_cast<Ogre::uint16>(tail));
        }
        else
        {
            for (int f = head; f != tail + step; f += step)
            {
                if (std::find(mBannedFrames.begin(), mBannedFrames.end(), static_cast<Ogre::uint16>(f)) == mBannedFrames.end())
                    mFrames.push_back(static_cast<Ogre::uint16>(f));
            }
        }
        if (mFrames.empty())
            mFrames.push_back(1);

        // start_range is 1-based into the playable list; "0 0" (or out of range) means "start at the first frame"
        const int n = static_cast<int>(mFrames.size());
        const int lo = static_cast<int>(mStartA) - 1;
        const int hi = static_cast<int>(mStartB) - 1;
        mHasStartRange = false;
        mStartLo = mStartHi = 0;
        if (lo >= 0 && hi >= 0 && lo < n && hi < n && (lo != 0 || hi != 0))
        {
            mStartLo = static_cast<Ogre::uint16>(std::min(lo, hi));
            mStartHi = static_cast<Ogre::uint16>(std::max(lo, hi));
            mHasStartRange = true;
        }

        mSingleStart = _rollStart();
        mStates.clear();
        mNextOrdinal = 0;
        mDirty = false;
    }
    //-----------------------------------------------------------------------
    Ogre::uint16 SequenceFrameAffector::_rollStart(void) const
    {
        if (!mHasStartRange)
            return 0;
        int s = static_cast<int>(Ogre::Math::RangeRandom(mStartLo, mStartHi + 1.0f));
        if (s > mStartHi)
            s = mStartHi;
        return static_cast<Ogre::uint16>(s);
    }
    //-----------------------------------------------------------------------
    void SequenceFrameAffector::_resetState(ParticleState& s)
    {
        s.start = _rollStart();
        s.ordinal = mNextOrdinal++;
        s.phase = -1.0f;
        s.lastTtl = -1.0f;
    }
    //-----------------------------------------------------------------------
    SequenceFrameAffector::ParticleState& SequenceFrameAffector::_state(Ogre::Particle* p)
    {
        ParticleStateMap::iterator i = mStates.find(p);
        if (i == mStates.end())
        {
            i = mStates.insert(ParticleStateMap::value_type(p, ParticleState())).first;
            _resetState(i->second);
        }
        return i->second;
    }
    //-----------------------------------------------------------------------
    void SequenceFrameAffector::_initParticle(Ogre::Particle* pParticle)
    {
        if (mDirty)
            _rebuild();
        _resetState(mStates[pParticle]);
    }
    //-----------------------------------------------------------------------
    void SequenceFrameAffector::_bindRenderer(Ogre::ParticleSystem* pSystem)
    {
        Ogre::ParticleSystemRenderer* renderer = pSystem->getRenderer();
        if (!renderer || renderer->getType() != "texcoord_billboard")
        {
            // B also drives ribbon / mesh renderers through a shader constant; no such data in client_GL
            Fx::logOnce("SequenceFrame.renderer=" + (renderer ? renderer->getType() : Fx::String("none")),
                "SequenceFrame: renderer '" + (renderer ? renderer->getType() : Fx::String("none")) +
                "' is not texcoord_billboard, flip-book ignored");
            mBoundRenderer = NULL;
            return;
        }

        Ogre::TexCoordBillboardParticleRenderer* tex = static_cast<Ogre::TexCoordBillboardParticleRenderer*>(renderer);
        if (tex != mBoundRenderer || tex->getStacks() != static_cast<Ogre::ulong>(std::max(1, mStacks)) ||
            tex->getSlices() != static_cast<Ogre::ulong>(std::max(1, mSlices)))
        {
            tex->setStacks(std::max(1, mStacks));
            tex->setSlices(std::max(1, mSlices));
        }
        tex->setTexCoordIndexSource(this);
        mBoundRenderer = tex;
    }
    //-----------------------------------------------------------------------
    void SequenceFrameAffector::_affectParticles(Ogre::ParticleSystem* pSystem, Fx::Real timeElapsed)
    {
        if (mDirty)
            _rebuild();
        _bindRenderer(pSystem);
    }
    //-----------------------------------------------------------------------
    Ogre::uint16 SequenceFrameAffector::_getTexCoordIndex(Ogre::Particle* p, Ogre::uint16 numTexCoords)
    {
        if (mDirty)
            _rebuild();

        ParticleState& s = _state(p);
        const Fx::Real total = p->totalTimeToLive;
        const Fx::Real ttl = p->timeToLive;

        const Ogre::uint16* list = &mFrames[0];
        int count = static_cast<int>(mFrames.size());
        Fx::Real offset = 0.0f;
        int index = 0;

        if (mPlayMode != PM_RANDOM && mHasStartRange)
        {
            const int start = std::min<int>(s.start, count - 1);
            if (mPlayMode == PM_NORMAL && !mLoop)
            {
                // play the remaining frames once
                list += start;
                count -= start;
            }
            else if (mHoldKind == 0)
            {
                offset = static_cast<Fx::Real>(start) / count;
            }
            else if (start == count - 1)
            {
                offset = 1.0f - mHoldTail;
            }
            else if (start != 0)
            {
                offset = ((1.0f - (mHoldHead + mHoldTail)) * (start - 1)) / (count - mHoldKind) + mHoldHead;
            }
        }

        if (mPlayMode == PM_SINGLE)
        {
            // every particle shows one fixed frame, consecutive particles take consecutive frames
            const int base = mHasStartRange ? mSingleStart : 0;
            if (!mPingPong || count < 2)
            {
                index = (base + s.ordinal) % count;
            }
            else
            {
                const int period = 2 * count - 2;
                const int k = (base + s.ordinal) % period;
                index = (k < count) ? k : period - k;
            }
        }
        else
        {
            Fx::Real t;
            if (mPlayMode == PM_RANDOM)
            {
                // a new random cycle position each time the particle lived 1 / (frames * repeat) of its life
                if (s.phase < 0.0f || (total > 0 &&
                    Ogre::Math::Abs((s.lastTtl - ttl) * mRepeatTimes / total) * count >= 1.0f))
                {
                    s.phase = (total > 0) ? 1.0f - Ogre::Math::RangeRandom(0.0f, total) / total : 0.0f;
                    s.lastTtl = ttl;
                }
                t = s.phase;
            }
            else
            {
                const Fx::Real age = Fx::normalisedAge(ttl, total);
                if (!mPingPong)
                {
                    t = (age + offset) * mRepeatTimes;
                }
                else
                {
                    const Fx::Real x = fmod(age * mRepeatTimes, 1.0f);
                    const Fx::Real o = mRepeatTimes * offset;
                    t = (x > 0.5f) ? fmod((1.0f - x) * 2.0f + o, 1.0f) : fmod(o + x * 2.0f, 1.0f);
                }
            }

            Fx::Real x = fmod(t, 1.0f);
            if (x < 0.0f)
                x += 1.0f;
            if (x < 1.0f - mHoldTail)
            {
                if (mHoldHead <= x)
                {
                    int base = 0;
                    if (mHoldHead != 0.0f)
                    {
                        x -= mHoldHead;
                        base = 1;
                    }
                    const Fx::Real span = 1.0f - (mHoldTail + mHoldHead);
                    index = base + static_cast<int>((count - mHoldKind) * (span > 0.0f ? x / span : 0.0f));
                }
            }
            else
            {
                index = count - 1;
            }
        }

        if (index < 0)
            index = 0;
        if (index >= count)
            index = count - 1;

        int rect = static_cast<int>(list[index]) - 1;
        if (rect < 0)
            rect = 0;
        if (numTexCoords > 0 && rect >= numTexCoords)
            rect = numTexCoords - 1;
        return static_cast<Ogre::uint16>(rect);
    }

    //-----------------------------------------------------------------------
    // command objects
    //-----------------------------------------------------------------------
    Fx::String SequenceFrameAffector::CmdPlayMode::doGet(const void* target) const
    {
        return static_cast<const SequenceFrameAffector*>(target)->getPlayModeString();
    }
    void SequenceFrameAffector::CmdPlayMode::doSet(void* target, const Fx::String& val)
    {
        static_cast<SequenceFrameAffector*>(target)->setPlayMode(val);
    }
    void SequenceFrameAffector::CmdPlayMode::doCopy(void* target, const void* source)
    {
        static_cast<const SequenceFrameAffector*>(source)->copyTo(*static_cast<SequenceFrameAffector*>(target));
    }
    //-----------------------------------------------------------------------
    Fx::String SequenceFrameAffector::CmdHeadAndTail::doGet(const void* target) const
    {
        return static_cast<const SequenceFrameAffector*>(target)->getHeadAndTailString();
    }
    void SequenceFrameAffector::CmdHeadAndTail::doSet(void* target, const Fx::String& val)
    {
        static_cast<SequenceFrameAffector*>(target)->setHeadAndTail(val);
    }
    void SequenceFrameAffector::CmdHeadAndTail::doCopy(void* target, const void* source)
    {
        static_cast<const SequenceFrameAffector*>(source)->copyTo(*static_cast<SequenceFrameAffector*>(target));
    }
    //-----------------------------------------------------------------------
    Fx::String SequenceFrameAffector::CmdPlayTimes::doGet(const void* target) const
    {
        return static_cast<const SequenceFrameAffector*>(target)->getPlayTimesString();
    }
    void SequenceFrameAffector::CmdPlayTimes::doSet(void* target, const Fx::String& val)
    {
        static_cast<SequenceFrameAffector*>(target)->setPlayTimes(val);
    }
    void SequenceFrameAffector::CmdPlayTimes::doCopy(void* target, const void* source)
    {
        static_cast<const SequenceFrameAffector*>(source)->copyTo(*static_cast<SequenceFrameAffector*>(target));
    }
    //-----------------------------------------------------------------------
    Fx::String SequenceFrameAffector::CmdBannedFrames::doGet(const void* target) const
    {
        return static_cast<const SequenceFrameAffector*>(target)->getBannedFramesString();
    }
    void SequenceFrameAffector::CmdBannedFrames::doSet(void* target, const Fx::String& val)
    {
        static_cast<SequenceFrameAffector*>(target)->setBannedFrames(val);
    }
    void SequenceFrameAffector::CmdBannedFrames::doCopy(void* target, const void* source)
    {
        static_cast<const SequenceFrameAffector*>(source)->copyTo(*static_cast<SequenceFrameAffector*>(target));
    }
    //-----------------------------------------------------------------------
    Fx::String SequenceFrameAffector::CmdStartRange::doGet(const void* target) const
    {
        return static_cast<const SequenceFrameAffector*>(target)->getStartRangeString();
    }
    void SequenceFrameAffector::CmdStartRange::doSet(void* target, const Fx::String& val)
    {
        static_cast<SequenceFrameAffector*>(target)->setStartRange(val);
    }
    void SequenceFrameAffector::CmdStartRange::doCopy(void* target, const void* source)
    {
        static_cast<const SequenceFrameAffector*>(source)->copyTo(*static_cast<SequenceFrameAffector*>(target));
    }

}
