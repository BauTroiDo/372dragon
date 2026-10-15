/*
CYS: NewRibbonTrail - the trail renderable of the NewRibbonTrail effect element (294 elements in client_GL
all.effect).  Clean-room implementation of the behaviour of B Render.dll FairyRibbonTrail (derived from the
B OgreMain BillboardChain, vtable 0x1802db760) - Docs/specs/render/04-effects-particles.md.

The trail follows a tracked scene node (the element node).  Elements are kept about TrailLength / (MaxChainElements - 2)
apart; a jump longer than TrailLength rebuilds a straight chain.  The total length is kept at TrailLength by
shortening the tail segment.  Each frame (only when LiftTime, WidthChange or the colour keys make it change) every
element ages, its width changes by WidthChange per second, its colour follows the five colour keys, and the chain is
cut at the first element older than LiftTime (LiftTime > 0) or whose width / alpha leaves the
[LowWidthCut, HighWidthCut] / AlphaColourCut limits.  Widths taper from the head width to TailWidth along the
chain; the texture u runs from 0 at the head to 1 at the tail.
Billboard types: camera (faces the camera), point (faces Direction_or_Point), oriented (perpendicular =
Direction_or_Point), perpendicular (tangent x Direction_or_Point), follow_bone (perpendicular = x axis of the
tracked node).  With ParentSpaceLock the chain moves rigidly with the effect transform.
*/
#ifndef __WXNewRibbonTrail_H__
#define __WXNewRibbonTrail_H__

#include <OgreBillboardChain.h>
#include <OgreNode.h>
#include <OgreColourValue.h>
#include <OgreQuaternion.h>

#include <vector>

namespace WX {

    class NewRibbonTrail : public Ogre::BillboardChain, public Ogre::Node::Listener
    {
    public:
        enum BillboardType
        {
            BT_CAMERA = 0,
            BT_POINT = 1,
            BT_ORIENTED = 2,
            BT_PERPENDICULAR = 3,
            BT_FOLLOW_BONE = 4
        };
        enum { NUM_COLOUR_KEYS = 5 };

        NewRibbonTrail(const Ogre::String& name, size_t maxElements);
        ~NewRibbonTrail();

        // parameters ------------------------------------------------------------------------------
        void setTrailLength(Ogre::Real length);
        Ogre::Real getTrailLength(void) const { return mTrailLength; }
        /// BillboardChain override: also resizes the per element ages and restarts the trail
        void setMaxChainElements(size_t maxElements);
        void setInitialWidth(Ogre::Real width) { mInitialWidth = width; }
        void setWidthChange(Ogre::Real change) { mWidthChange = change; }
        void setTailWidth(Ogre::Real width) { mTailWidth = width; }
        void setLowWidthCut(Ogre::Real cut) { mLowWidthCut = cut; }
        void setHighWidthCut(Ogre::Real cut) { mHighWidthCut = cut; }
        void setAlphaColourCut(Ogre::Real cut) { mAlphaColourCut = cut; }
        void setLiftTime(Ogre::Real time) { mLiftTime = time; }
        void setColourKey(size_t index, Ogre::Real time, const Ogre::ColourValue& colour);
        void setBillboardType(BillboardType type) { mBillboardType = type; }
        void setDirectionOrPoint(const Ogre::Vector3& v) { mDirectionOrPoint = v; }

        // runtime -----------------------------------------------------------------------------------
        /// starts following a node (the chain restarts at its position); NULL stops following
        void setTrackedNode(Ogre::Node* node);
        Ogre::Node* getTrackedNode(void) const { return mTrackedNode; }
        /// false: node movements are ignored (element asleep or not started yet)
        void setEnabled(bool enabled) { mEnabled = enabled; }
        bool getEnabled(void) const { return mEnabled; }
        /// restarts the chain with two elements at the tracked node position
        void resetTrail(void);
        /// ParentSpaceLock: moves the whole chain rigidly with the effect transform (world space)
        void setLogicTransform(const Ogre::Vector3& position, const Ogre::Quaternion& orientation);
        /// ages the elements (frame time, seconds)
        void timeUpdate(Ogre::Real timeElapsed);
        /// follows the tracked node when it could not be monitored with a node listener
        void pollTrackedNode(void);

        // Node::Listener
        void nodeUpdated(const Ogre::Node* node);
        void nodeDestroyed(const Ogre::Node* node);

    protected:
        /// BillboardChain override: perpendicular chosen by the billboard type
        void updateVertexBuffer(Ogre::Camera* cam);

        size_t _next(size_t index) const { return (index + 1 == mMaxElementsPerChain) ? 0 : index + 1; }
        size_t _prev(size_t index) const { return (index == 0) ? mMaxElementsPerChain - 1 : index - 1; }
        size_t _count(void) const;
        Element& _element(size_t index) { return mChainElementList[mChainSegmentList[0].start + index]; }

        /// adds a new head element (the oldest element is recycled when the chain is full)
        void _pushHead(const Ogre::Vector3& position);
        /// the tracked node moved: extend / move the head, keep the total length
        void _followNode(void);
        void _updateWidthsAndTexCoords(void);
        void _applyWidthRule(Ogre::Real& width, Ogre::Real target) const;
        Ogre::ColourValue _colourAt(Ogre::Real age) const;
        bool _needsTimeUpdate(void) const;
        Ogre::Vector3 _toLocal(const Ogre::Vector3& worldPosition) const;
        Ogre::Quaternion _toLocal(const Ogre::Quaternion& worldOrientation) const;
        void _markDirty(bool structureChanged);

    protected:
        Ogre::Real          mTrailLength;
        Ogre::Real          mElemLength;
        Ogre::Real          mInitialWidth;
        Ogre::Real          mWidthChange;
        Ogre::Real          mTailWidth;
        Ogre::Real          mLowWidthCut;
        Ogre::Real          mHighWidthCut;
        Ogre::Real          mAlphaColourCut;
        Ogre::Real          mLiftTime;
        Ogre::Real          mColourTimes[NUM_COLOUR_KEYS];
        Ogre::ColourValue   mColours[NUM_COLOUR_KEYS];
        BillboardType       mBillboardType;
        Ogre::Vector3       mDirectionOrPoint;

        Ogre::Node*         mTrackedNode;
        bool                mListening;
        bool                mEnabled;
        std::vector<Ogre::Real> mAges;

        bool                mHasLogicTransform;
        Ogre::Vector3       mLogicPosition;
        Ogre::Quaternion    mLogicOrientation;
    };

}

#endif
