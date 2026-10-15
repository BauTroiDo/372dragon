/*
CYS: NewRibbonTrail effect element (294 elements in client_GL all.effect).  Clean-room implementation of the
behaviour of B Render.dll (ctor 0x18021f2a0, createRenderInstance 0x18021ff90) - see WXNewRibbonTrail.h.

Keywords (as written in .effect files):
  TrailLength 100, MaxChainElements 80, InitialWidth 20, WidthChange 0, TailWidth 0, LowWidthCut 0,
  HighWidthCut 100, AlphaColourCut 0, LiftTime 0, ColourFadingTime0..4 0, ColourFadingColour0..4 "0 0 0 1",
  Material "", BillboardType camera | point | oriented | perpendicular | follow_bone, Direction_or_Point "0 0 0"
  plus the EffectElement keys (StartTime, LifeTime, Position, Orientation, CreateLevel, ParentSpaceLock).
The trail is attached to its own node (world space, render queue 80) and follows the element node.
*/
#ifndef __WXNewRibbonTrailElement_H__
#define __WXNewRibbonTrailElement_H__

#include "EffectSystem/WXEffectElement.h"
#include "EffectSystem/WXEffectElementFactory.h"
#include "WXFxParamHelpers.h"

namespace Ogre {
    class SceneNode;
}

namespace WX {

    class NewRibbonTrail;

    class NewRibbonTrailElement : public EffectElement
    {
    public:
        enum { NUM_COLOUR_KEYS = 5 };

        NewRibbonTrailElement(const String& type, System* system);
        ~NewRibbonTrailElement();

        virtual bool createRenderInstance(void);
        virtual void destroyRenderInstance(void);
        virtual void updateRenderInstance(Real time, TransformInfo& info);
        virtual void sleep(void);
        virtual void active(void);
        virtual void setVisible(bool visible);
        virtual void setVisibleFlag(uint32 flags);

        void _notifyParameterChanged(void) { mParamsDirty = true; }

        void setBillboardTypeFromString(const String& val);
        String getBillboardTypeString(void) const;

    public:
        Real                mTrailLength;
        int                 mMaxChainElements;
        Real                mInitialWidth;
        Real                mWidthChange;
        Real                mTailWidth;
        Real                mLowWidthCut;
        Real                mHighWidthCut;
        Real                mAlphaColourCut;
        Real                mLiftTime;
        Real                mColourTimes[NUM_COLOUR_KEYS];
        Ogre::ColourValue   mColours[NUM_COLOUR_KEYS];
        String              mMaterialName;
        int                 mBillboardType;
        Ogre::Vector3       mDirectionOrPoint;

        typedef Fx::MemberCmd<NewRibbonTrailElement, Fx::RealCodec, &NewRibbonTrailElement::mTrailLength> CmdTrailLength;
        typedef Fx::MemberCmd<NewRibbonTrailElement, Fx::IntCodec, &NewRibbonTrailElement::mMaxChainElements> CmdMaxChainElements;
        typedef Fx::MemberCmd<NewRibbonTrailElement, Fx::RealCodec, &NewRibbonTrailElement::mInitialWidth> CmdInitialWidth;
        typedef Fx::MemberCmd<NewRibbonTrailElement, Fx::RealCodec, &NewRibbonTrailElement::mWidthChange> CmdWidthChange;
        typedef Fx::MemberCmd<NewRibbonTrailElement, Fx::RealCodec, &NewRibbonTrailElement::mTailWidth> CmdTailWidth;
        typedef Fx::MemberCmd<NewRibbonTrailElement, Fx::RealCodec, &NewRibbonTrailElement::mLowWidthCut> CmdLowWidthCut;
        typedef Fx::MemberCmd<NewRibbonTrailElement, Fx::RealCodec, &NewRibbonTrailElement::mHighWidthCut> CmdHighWidthCut;
        typedef Fx::MemberCmd<NewRibbonTrailElement, Fx::RealCodec, &NewRibbonTrailElement::mAlphaColourCut> CmdAlphaColourCut;
        typedef Fx::MemberCmd<NewRibbonTrailElement, Fx::RealCodec, &NewRibbonTrailElement::mLiftTime> CmdLiftTime;
        typedef Fx::ArrayElementCmd<NewRibbonTrailElement, Fx::RealCodec, NUM_COLOUR_KEYS, &NewRibbonTrailElement::mColourTimes> CmdColourTime;
        typedef Fx::ArrayElementCmd<NewRibbonTrailElement, Fx::ColourCodec, NUM_COLOUR_KEYS, &NewRibbonTrailElement::mColours> CmdColour;
        typedef Fx::MemberCmd<NewRibbonTrailElement, Fx::StringCodec, &NewRibbonTrailElement::mMaterialName> CmdMaterial;
        typedef Fx::MemberCmd<NewRibbonTrailElement, Fx::Vector3Codec, &NewRibbonTrailElement::mDirectionOrPoint> CmdDirectionOrPoint;

        class CmdBillboardType : public Ogre::ParamCommand
        {
        public:
            String doGet(const void* target) const;
            void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            void doCopy(void* target, const void* source);
#endif
        };

        static CmdTrailLength       msTrailLengthCmd;
        static CmdMaxChainElements  msMaxChainElementsCmd;
        static CmdInitialWidth      msInitialWidthCmd;
        static CmdWidthChange       msWidthChangeCmd;
        static CmdTailWidth         msTailWidthCmd;
        static CmdLowWidthCut       msLowWidthCutCmd;
        static CmdHighWidthCut      msHighWidthCutCmd;
        static CmdAlphaColourCut    msAlphaColourCutCmd;
        static CmdLiftTime          msLiftTimeCmd;
        static CmdColourTime        msColourTimeCmd[NUM_COLOUR_KEYS];
        static CmdColour            msColourCmd[NUM_COLOUR_KEYS];
        static CmdMaterial          msMaterialCmd;
        static CmdBillboardType     msBillboardTypeCmd;
        static CmdDirectionOrPoint  msDirectionOrPointCmd;

    protected:
        void _applyParameters(void);

        NewRibbonTrail*     mTrail;
        Ogre::SceneNode*    mTrailNode;
        bool                mParamsDirty;
        /// the chain restarts at the element node on the first update after (re)activation
        bool                mNeedRestart;
    };

    //-----------------------------------------------------------------------
    class NewRibbonTrailElementFactory : public EffectElementFactory
    {
    public:
        virtual String getName() const { return "NewRibbonTrail"; }
        virtual EffectElement* createElement(System* system);
    };

}

#endif
