/*
CYS: NewRibbonTrail - see WXNewRibbonTrail.h.
*/
#include "WXNewRibbonTrail.h"
#include "WXFxParamHelpers.h"

#include <OgreCamera.h>
#include <OgreRoot.h>
#include <OgreHardwareBufferManager.h>
#include <OgreMath.h>

#include <algorithm>

namespace WX {

    //-----------------------------------------------------------------------
    NewRibbonTrail::NewRibbonTrail(const Ogre::String& name, size_t maxElements)
        : Ogre::BillboardChain(name, std::max<size_t>(maxElements, 3), 1, true, true, true)
        , mTrailLength(100.0f)
        , mElemLength(1.0f)
        , mInitialWidth(20.0f)
        , mWidthChange(0.0f)
        , mTailWidth(0.0f)
        , mLowWidthCut(0.0f)
        , mHighWidthCut(100.0f)
        , mAlphaColourCut(0.0f)
        , mLiftTime(0.0f)
        , mBillboardType(BT_CAMERA)
        , mDirectionOrPoint(Ogre::Vector3::ZERO)
        , mTrackedNode(NULL)
        , mListening(false)
        , mEnabled(true)
        , mHasLogicTransform(false)
        , mLogicPosition(Ogre::Vector3::ZERO)
        , mLogicOrientation(Ogre::Quaternion::IDENTITY)
    {
        for (size_t i = 0; i < NUM_COLOUR_KEYS; ++i)
        {
            mColourTimes[i] = 0.0f;
            mColours[i] = Ogre::ColourValue::Black;
        }
        mAges.assign(mMaxElementsPerChain, 0.0f);
        setTrailLength(mTrailLength);
    }
    //-----------------------------------------------------------------------
    NewRibbonTrail::~NewRibbonTrail()
    {
        setTrackedNode(NULL);
    }
    //-----------------------------------------------------------------------
    void NewRibbonTrail::setTrailLength(Ogre::Real length)
    {
        mTrailLength = length;
        mElemLength = (mMaxElementsPerChain > 2) ? length / static_cast<Ogre::Real>(mMaxElementsPerChain - 2) : length;
    }
    //-----------------------------------------------------------------------
    void NewRibbonTrail::setMaxChainElements(size_t maxElements)
    {
        maxElements = std::max<size_t>(maxElements, 3);
        if (maxElements == mMaxElementsPerChain)
            return;

        Ogre::BillboardChain::setMaxChainElements(maxElements);
        mAges.assign(mMaxElementsPerChain, 0.0f);
        setTrailLength(mTrailLength);
        resetTrail();
    }
    //-----------------------------------------------------------------------
    void NewRibbonTrail::setColourKey(size_t index, Ogre::Real time, const Ogre::ColourValue& colour)
    {
        if (index < NUM_COLOUR_KEYS)
        {
            mColourTimes[index] = time;
            mColours[index] = colour;
        }
    }
    //-----------------------------------------------------------------------
    size_t NewRibbonTrail::_count(void) const
    {
        const ChainSegment& seg = mChainSegmentList[0];
        if (seg.head == SEGMENT_EMPTY)
            return 0;
        return ((seg.tail + mMaxElementsPerChain - seg.head) % mMaxElementsPerChain) + 1;
    }
    //-----------------------------------------------------------------------
    Ogre::Vector3 NewRibbonTrail::_toLocal(const Ogre::Vector3& worldPosition) const
    {
        if (!mParentNode)
            return worldPosition;
        return mParentNode->_getDerivedOrientation().UnitInverse() *
            (worldPosition - mParentNode->_getDerivedPosition()) / mParentNode->_getDerivedScale();
    }
    //-----------------------------------------------------------------------
    Ogre::Quaternion NewRibbonTrail::_toLocal(const Ogre::Quaternion& worldOrientation) const
    {
        if (!mParentNode)
            return worldOrientation;
        return mParentNode->_getDerivedOrientation().UnitInverse() * worldOrientation;
    }
    //-----------------------------------------------------------------------
    void NewRibbonTrail::_markDirty(bool structureChanged)
    {
        mBoundsDirty = true;
        if (structureChanged)
            mIndexContentDirty = true;
        // may be called while the scene graph is being updated (node listener): defer the bounds update
        if (mParentNode)
            Ogre::Node::queueNeedUpdate(mParentNode);
    }
    //-----------------------------------------------------------------------
    void NewRibbonTrail::_pushHead(const Ogre::Vector3& position)
    {
        ChainSegment& seg = mChainSegmentList[0];
        if (seg.head == SEGMENT_EMPTY)
        {
            seg.tail = mMaxElementsPerChain - 1;
            seg.head = seg.tail;
        }
        else
        {
            seg.head = _prev(seg.head);
            // chain full: the tail element is recycled as the new head
            if (seg.head == seg.tail)
                seg.tail = _prev(seg.tail);
        }

        Element& e = _element(seg.head);
        e.position = position;
        e.width = mInitialWidth;
        e.texCoord = 0.0f;
        e.colour = mColours[0];
        mAges[seg.head] = 0.0f;

        mIndexContentDirty = true;
        mBoundsDirty = true;
    }
    //-----------------------------------------------------------------------
    void NewRibbonTrail::resetTrail(void)
    {
        ChainSegment& seg = mChainSegmentList[0];
        seg.head = seg.tail = SEGMENT_EMPTY;
        mHasLogicTransform = false;

        if (mTrackedNode)
        {
            const Ogre::Vector3 position = _toLocal(mTrackedNode->_getDerivedPosition());
            _pushHead(position);
            _pushHead(position);
        }
        _markDirty(true);
    }
    //-----------------------------------------------------------------------
    void NewRibbonTrail::setTrackedNode(Ogre::Node* node)
    {
        if (mTrackedNode && mListening && mTrackedNode->getListener() == this)
            mTrackedNode->setListener(NULL);

        mTrackedNode = node;
        mListening = false;

        if (mTrackedNode)
        {
            if (mTrackedNode->getListener() == NULL)
            {
                mTrackedNode->setListener(this);
                mListening = true;
            }
            else
            {
                // B refuses such a node; follow it by polling from the element update instead
                Fx::logOnce("NewRibbonTrail.listener",
                    "NewRibbonTrail: node '" + mTrackedNode->getName() + "' already has a listener, the trail polls it");
            }
            resetTrail();
        }
    }
    //-----------------------------------------------------------------------
    void NewRibbonTrail::nodeUpdated(const Ogre::Node* node)
    {
        if (mEnabled && node == mTrackedNode)
            _followNode();
    }
    //-----------------------------------------------------------------------
    void NewRibbonTrail::nodeDestroyed(const Ogre::Node* node)
    {
        if (node == mTrackedNode)
        {
            mTrackedNode = NULL;
            mListening = false;
        }
    }
    //-----------------------------------------------------------------------
    void NewRibbonTrail::pollTrackedNode(void)
    {
        if (mEnabled && mTrackedNode && !mListening)
            _followNode();
    }
    //-----------------------------------------------------------------------
    void NewRibbonTrail::_followNode(void)
    {
        if (_count() < 2)
        {
            resetTrail();
            return;
        }

        ChainSegment& seg = mChainSegmentList[0];
        const Ogre::Vector3 newPosition = _toLocal(mTrackedNode->_getDerivedPosition());
        const Ogre::Vector3 nextPosition = _element(_next(seg.head)).position;

        const Ogre::Vector3 diff = newPosition - nextPosition;
        const Ogre::Real distance = diff.length();
        Ogre::Real headSegment = 0.0f;

        if (distance <= mTrailLength)
        {
            if (distance <= mElemLength)
            {
                // still inside the first segment: just move the head
                _element(seg.head).position = newPosition;
                headSegment = distance;
            }
            else
            {
                // close the head segment at one element length, fill the rest with new elements
                const Ogre::Vector3 step = diff * (mElemLength / distance);
                _element(seg.head).position = nextPosition + step;

                Ogre::Real remaining = (newPosition - _element(seg.head).position).length();
                for (int guard = 1000; remaining > mElemLength && guard > 0; --guard)
                {
                    const Ogre::Vector3 position = _element(seg.head).position + step;
                    _pushHead(position);
                    remaining -= mElemLength;
                }
                _pushHead(newPosition);
                headSegment = remaining;
            }
        }
        else
        {
            // jump longer than the trail: straight chain along the jump, ending at the new position
            const Ogre::Vector3 direction = diff / distance;
            const Ogre::Vector3 start = newPosition - direction * mTrailLength;
            for (size_t i = 0; i + 1 < mMaxElementsPerChain; ++i)
                _pushHead(start + direction * (static_cast<Ogre::Real>(i) * mElemLength));
            _pushHead(newPosition);
            headSegment = 0.0f;
        }

        // full chain: shorten the tail segment so that the whole trail stays TrailLength long
        if (_count() == mMaxElementsPerChain)
        {
            Element& tail = _element(seg.tail);
            const Ogre::Vector3 before = _element(_prev(seg.tail)).position;
            const Ogre::Vector3 v = tail.position - before;
            const Ogre::Real length = v.length();
            const Ogre::Real wanted = std::max(0.0f, mElemLength - headSegment);
            if (length > 1e-6f && wanted < length)
                tail.position = before + v * (wanted / length);
        }

        _updateWidthsAndTexCoords();
        _markDirty(true);
    }
    //-----------------------------------------------------------------------
    void NewRibbonTrail::_applyWidthRule(Ogre::Real& width, Ogre::Real target) const
    {
        // growing trails never get thinner than the taper, shrinking ones never thicker
        if (mWidthChange < 0.0f)
            width = std::min(width, target);
        else if (mWidthChange > 0.0f)
            width = std::max(width, target);
        else
            width = target;
    }
    //-----------------------------------------------------------------------
    void NewRibbonTrail::_updateWidthsAndTexCoords(void)
    {
        const size_t count = _count();
        if (count < 2)
            return;

        ChainSegment& seg = mChainSegmentList[0];
        const size_t head = seg.head;
        const size_t tail = seg.tail;

        const Ogre::Real headSegment = (_element(head).position - _element(_next(head)).position).length();
        const Ogre::Real tailSegment = (_element(tail).position - _element(_prev(tail)).position).length();

        Ogre::Real total;
        if (count == 2)
            total = headSegment;
        else if (count == 3)
            total = headSegment + tailSegment;
        else
            total = static_cast<Ogre::Real>(count - 3) * mElemLength + headSegment + tailSegment;

        const Ogre::Real headWidth = _element(head).width;
        const Ogre::Real headCoord = _element(head).texCoord;
        Ogre::Real tailWidth = mTailWidth;
        Ogre::Real tailCoord = 1.0f;
        Ogre::Real distance = tailSegment;     // distance of the current element from the tail

        for (size_t i = tail; i != head; i = _prev(i))
        {
            Element& e = _element(i);
            if (i == tail)
            {
                _applyWidthRule(e.width, mTailWidth);
                tailWidth = e.width;
                if (mLiftTime < 0.0f)
                {
                    if (headCoord == 0.0f)
                        e.texCoord = (mTrailLength > 0.0f) ? total / mTrailLength : 1.0f;
                }
                else
                {
                    e.texCoord = 1.0f;
                }
                tailCoord = e.texCoord;
            }
            else
            {
                const Ogre::Real target = (total > 0.0f) ?
                    (headWidth - tailWidth) * distance / total + tailWidth : headWidth;
                _applyWidthRule(e.width, target);

                Ogre::Real step;
                if (mLiftTime <= 0.0f)
                    step = (mTrailLength > 0.0f) ? distance / mTrailLength : 0.0f;
                else
                    step = (total > 0.0f) ? (tailCoord - headCoord) * distance / total : 0.0f;
                e.texCoord = tailCoord - step;
                if (e.texCoord > 1.0f)
                    e.colour.a = 0.0f;

                distance += mElemLength;
            }
        }
        if (_element(head).texCoord > 1.0f)
            _element(head).colour.a = 0.0f;
    }
    //-----------------------------------------------------------------------
    Ogre::ColourValue NewRibbonTrail::_colourAt(Ogre::Real age) const
    {
        // the first key later than the age closes the interpolated stage; keys past the last one give the last colour
        for (size_t i = 0; i < NUM_COLOUR_KEYS; ++i)
        {
            if (age < mColourTimes[i])
            {
                if (i == 0)
                    return mColours[0];
                const Ogre::Real f = (age - mColourTimes[i - 1]) / (mColourTimes[i] - mColourTimes[i - 1]);
                return mColours[i - 1] * (1.0f - f) + mColours[i] * f;
            }
        }
        return mColours[NUM_COLOUR_KEYS - 1];
    }
    //-----------------------------------------------------------------------
    bool NewRibbonTrail::_needsTimeUpdate(void) const
    {
        if (mLiftTime != 0.0f || mWidthChange != 0.0f)
            return true;
        for (size_t i = 1; i < NUM_COLOUR_KEYS; ++i)
        {
            if (mColours[i] != mColours[0])
                return true;
        }
        return false;
    }
    //-----------------------------------------------------------------------
    void NewRibbonTrail::timeUpdate(Ogre::Real timeElapsed)
    {
        if (!mEnabled || !_needsTimeUpdate() || _count() < 2)
            return;

        ChainSegment& seg = mChainSegmentList[0];
        bool cut = false;

        for (size_t i = seg.head; ; i = _next(i))
        {
            Element& e = _element(i);
            mAges[i] += timeElapsed;
            e.width = std::max(0.0f, e.width + timeElapsed * mWidthChange);
            e.colour = _colourAt(mAges[i]);
            e.colour.saturate();

            if (mLiftTime < 0.0f)
            {
                // negative lift time: the texture slides along the trail, elements past the end fade out
                e.texCoord -= timeElapsed / mLiftTime;
                if (e.texCoord > 1.0f || e.width > mHighWidthCut || e.width <= mLowWidthCut ||
                    e.colour.a <= mAlphaColourCut)
                {
                    e.colour.a = 0.0f;
                }
                if (i == seg.tail)
                    break;
                continue;
            }

            if (i == seg.tail)
                break;

            // the first element that is too old, too thin, too wide or too transparent becomes the tail
            if ((mLiftTime != 0.0f && mLiftTime < mAges[i]) || e.width <= mLowWidthCut ||
                mHighWidthCut <= e.width || e.colour.a <= mAlphaColourCut)
            {
                seg.tail = i;
                cut = true;
                break;
            }
        }

        if (seg.head == seg.tail)
        {
            resetTrail();
            return;
        }
        _updateWidthsAndTexCoords();
        _markDirty(cut);
    }
    //-----------------------------------------------------------------------
    void NewRibbonTrail::setLogicTransform(const Ogre::Vector3& position, const Ogre::Quaternion& orientation)
    {
        const Ogre::Vector3 localPosition = _toLocal(position);
        const Ogre::Quaternion localOrientation = _toLocal(orientation);

        if (!mHasLogicTransform)
        {
            mLogicPosition = localPosition;
            mLogicOrientation = localOrientation;
            mHasLogicTransform = true;
            return;
        }
        if (localPosition == mLogicPosition && localOrientation == mLogicOrientation)
            return;

        if (_count() > 0)
        {
            // a zero quaternion carries no rotation: translate only
            const bool rotate = !(orientation == Ogre::Quaternion::ZERO);
            const Ogre::Quaternion delta = localOrientation * mLogicOrientation.Inverse();
            const Ogre::Vector3 move = localPosition - mLogicPosition;

            ChainSegment& seg = mChainSegmentList[0];
            for (size_t i = seg.head; ; i = _next(i))
            {
                Element& e = _element(i);
                if (rotate)
                    e.position = localPosition + delta * (e.position - mLogicPosition);
                else
                    e.position += move;
                if (i == seg.tail)
                    break;
            }
            _markDirty(false);
        }

        mLogicPosition = localPosition;
        mLogicOrientation = localOrientation;
    }
    //-----------------------------------------------------------------------
    void NewRibbonTrail::updateVertexBuffer(Ogre::Camera* cam)
    {
        setupBuffers();
        Ogre::HardwareVertexBufferSharedPtr buffer = mVertexData->vertexBufferBinding->getBuffer(0);
        void* bufferStart = buffer->lock(Ogre::HardwareBuffer::HBL_DISCARD);

        const Ogre::Vector3 eyePosition = _toLocal(cam->getDerivedPosition());
        Ogre::Vector3 boneAxis = Ogre::Vector3::UNIT_X;
        if (mBillboardType == BT_FOLLOW_BONE && mTrackedNode)
            boneAxis = _toLocal(mTrackedNode->_getDerivedOrientation()).xAxis();

        const ChainSegment& seg = mChainSegmentList[0];
        if (seg.head != SEGMENT_EMPTY && seg.head != seg.tail)
        {
            size_t last = seg.tail;
            for (size_t e = seg.head; ; e = _next(e))
            {
                const Element& elem = mChainElementList[seg.start + e];
                const size_t next = _next(e);

                Ogre::Vector3 tangent;
                if (e == seg.head)
                    tangent = mChainElementList[seg.start + next].position - elem.position;
                else if (e == seg.tail)
                    tangent = elem.position - mChainElementList[seg.start + last].position;
                else
                    tangent = mChainElementList[seg.start + next].position - mChainElementList[seg.start + last].position;

                Ogre::Vector3 perpendicular;
                switch (mBillboardType)
                {
                case BT_POINT:
                    perpendicular = tangent.crossProduct(mDirectionOrPoint - elem.position);
                    break;
                case BT_ORIENTED:
                    perpendicular = mDirectionOrPoint;
                    break;
                case BT_PERPENDICULAR:
                    perpendicular = tangent.crossProduct(mDirectionOrPoint);
                    break;
                case BT_FOLLOW_BONE:
                    perpendicular = boneAxis;
                    break;
                default:
                    perpendicular = tangent.crossProduct(eyePosition - elem.position);
                    break;
                }
                perpendicular.normalise();
                perpendicular *= elem.width * 0.5f;

                const Ogre::Vector3 corners[2] = { elem.position - perpendicular, elem.position + perpendicular };
                const Ogre::uint16 baseIndex = static_cast<Ogre::uint16>((e + seg.start) * 2);
                char* vertex = static_cast<char*>(bufferStart) + buffer->getVertexSize() * baseIndex;

                for (int side = 0; side < 2; ++side)
                {
                    float* f = reinterpret_cast<float*>(vertex);
                    *f++ = corners[side].x;
                    *f++ = corners[side].y;
                    *f++ = corners[side].z;
                    vertex = reinterpret_cast<char*>(f);

                    if (mUseVertexColour)
                    {
                        Ogre::RGBA* colour = reinterpret_cast<Ogre::RGBA*>(vertex);
                        Ogre::Root::getSingleton().convertColourValue(elem.colour, colour);
                        vertex = reinterpret_cast<char*>(colour + 1);
                    }
                    if (mUseTexCoords)
                    {
                        f = reinterpret_cast<float*>(vertex);
                        if (mTexCoordDir == TCD_U)
                        {
                            *f++ = elem.texCoord;
                            *f++ = mOtherTexCoordRange[side];
                        }
                        else
                        {
                            *f++ = mOtherTexCoordRange[side];
                            *f++ = elem.texCoord;
                        }
                        vertex = reinterpret_cast<char*>(f);
                    }
                }

                if (e == seg.tail)
                    break;
                last = e;
            }
        }

        buffer->unlock();
    }

}
