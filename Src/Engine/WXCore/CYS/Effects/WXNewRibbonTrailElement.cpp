/*
CYS: NewRibbonTrail effect element - see WXNewRibbonTrailElement.h.
*/
#include "WXNewRibbonTrailElement.h"
#include "WXNewRibbonTrail.h"

#include "Core/WXSystem.h"

#include <OgreSceneNode.h>
#include <OgreSceneManager.h>
#include <OgreMaterialManager.h>
#include <OgreStringConverter.h>

namespace WX {

    NewRibbonTrailElement::CmdTrailLength       NewRibbonTrailElement::msTrailLengthCmd;
    NewRibbonTrailElement::CmdMaxChainElements  NewRibbonTrailElement::msMaxChainElementsCmd;
    NewRibbonTrailElement::CmdInitialWidth      NewRibbonTrailElement::msInitialWidthCmd;
    NewRibbonTrailElement::CmdWidthChange       NewRibbonTrailElement::msWidthChangeCmd;
    NewRibbonTrailElement::CmdTailWidth         NewRibbonTrailElement::msTailWidthCmd;
    NewRibbonTrailElement::CmdLowWidthCut       NewRibbonTrailElement::msLowWidthCutCmd;
    NewRibbonTrailElement::CmdHighWidthCut      NewRibbonTrailElement::msHighWidthCutCmd;
    NewRibbonTrailElement::CmdAlphaColourCut    NewRibbonTrailElement::msAlphaColourCutCmd;
    NewRibbonTrailElement::CmdLiftTime          NewRibbonTrailElement::msLiftTimeCmd;
    NewRibbonTrailElement::CmdColourTime        NewRibbonTrailElement::msColourTimeCmd[NewRibbonTrailElement::NUM_COLOUR_KEYS];
    NewRibbonTrailElement::CmdColour            NewRibbonTrailElement::msColourCmd[NewRibbonTrailElement::NUM_COLOUR_KEYS];
    NewRibbonTrailElement::CmdMaterial          NewRibbonTrailElement::msMaterialCmd;
    NewRibbonTrailElement::CmdBillboardType     NewRibbonTrailElement::msBillboardTypeCmd;
    NewRibbonTrailElement::CmdDirectionOrPoint  NewRibbonTrailElement::msDirectionOrPointCmd;

    namespace {
        const char* const kBillboardTypeNames[] = { "camera", "point", "oriented", "perpendicular", "follow_bone" };
        const int kNumBillboardTypes = 5;
        unsigned int sTrailCount = 0;
    }

    //-----------------------------------------------------------------------
    NewRibbonTrailElement::NewRibbonTrailElement(const String& type, System* system)
        : EffectElement(type, system)
        , mTrailLength(100.0f)
        , mMaxChainElements(80)
        , mInitialWidth(20.0f)
        , mWidthChange(0.0f)
        , mTailWidth(0.0f)
        , mLowWidthCut(0.0f)
        , mHighWidthCut(100.0f)
        , mAlphaColourCut(0.0f)
        , mLiftTime(0.0f)
        , mMaterialName("")
        , mBillboardType(NewRibbonTrail::BT_CAMERA)
        , mDirectionOrPoint(Ogre::Vector3::ZERO)
        , mTrail(NULL)
        , mTrailNode(NULL)
        , mParamsDirty(true)
        , mNeedRestart(true)
    {
        for (size_t i = 0; i < NUM_COLOUR_KEYS; ++i)
        {
            mColourTimes[i] = 0.0f;
            mColours[i] = Ogre::ColourValue::Black;
        }

        if (initDefaults(mElementType))
        {
            Ogre::ParamDictionary* dict = getParamDictionary();

            dict->addParameter(Ogre::ParameterDef("TrailLength",
                "the length of the trail.", Ogre::PT_REAL), &msTrailLengthCmd);
            dict->addParameter(Ogre::ParameterDef("MaxChainElements",
                "the max number of chain elements.", Ogre::PT_INT), &msMaxChainElementsCmd);
            dict->addParameter(Ogre::ParameterDef("InitialWidth",
                "the width of a new element.", Ogre::PT_REAL), &msInitialWidthCmd);
            dict->addParameter(Ogre::ParameterDef("WidthChange",
                "the width change per second.", Ogre::PT_REAL), &msWidthChangeCmd);
            dict->addParameter(Ogre::ParameterDef("TailWidth",
                "the width of the tail.", Ogre::PT_REAL), &msTailWidthCmd);
            dict->addParameter(Ogre::ParameterDef("LowWidthCut",
                "elements thinner than this are cut.", Ogre::PT_REAL), &msLowWidthCutCmd);
            dict->addParameter(Ogre::ParameterDef("HighWidthCut",
                "elements wider than this are cut.", Ogre::PT_REAL), &msHighWidthCutCmd);
            for (size_t i = 0; i < NUM_COLOUR_KEYS; ++i)
            {
                const String index = Ogre::StringConverter::toString(i);
                msColourTimeCmd[i].mIndex = i;
                msColourCmd[i].mIndex = i;
                dict->addParameter(Ogre::ParameterDef("ColourFadingTime" + index,
                    "time of the colour key (seconds of element age).", Ogre::PT_REAL), &msColourTimeCmd[i]);
                dict->addParameter(Ogre::ParameterDef("ColourFadingColour" + index,
                    "colour of the colour key.", Ogre::PT_COLOURVALUE), &msColourCmd[i]);
            }
            dict->addParameter(Ogre::ParameterDef("AlphaColourCut",
                "elements more transparent than this are cut.", Ogre::PT_REAL), &msAlphaColourCutCmd);
            dict->addParameter(Ogre::ParameterDef("LiftTime",
                "life time of an element (0 = unlimited, < 0 = sliding texture).", Ogre::PT_REAL), &msLiftTimeCmd);
            dict->addParameter(Ogre::ParameterDef("Material",
                "the material of the trail.", Ogre::PT_STRING), &msMaterialCmd);
            dict->addParameter(Ogre::ParameterDef("BillboardType",
                "camera, point, oriented, perpendicular or follow_bone.", Ogre::PT_STRING), &msBillboardTypeCmd);
            dict->addParameter(Ogre::ParameterDef("Direction_or_Point",
                "direction (oriented / perpendicular) or point (point) of the billboard type.",
                Ogre::PT_VECTOR3), &msDirectionOrPointCmd);
        }
    }
    //-----------------------------------------------------------------------
    NewRibbonTrailElement::~NewRibbonTrailElement()
    {
        destroyRenderInstance();
    }
    //-----------------------------------------------------------------------
    void NewRibbonTrailElement::setBillboardTypeFromString(const String& val)
    {
        for (int i = 0; i < kNumBillboardTypes; ++i)
        {
            if (val == kBillboardTypeNames[i])
            {
                mBillboardType = i;
                mParamsDirty = true;
                return;
            }
        }
        // B throws here; keep the camera facing trail
        Fx::logOnce("NewRibbonTrail.BillboardType=" + val,
            "NewRibbonTrail: unknown BillboardType '" + val + "', camera used");
    }
    //-----------------------------------------------------------------------
    String NewRibbonTrailElement::getBillboardTypeString(void) const
    {
        return (mBillboardType >= 0 && mBillboardType < kNumBillboardTypes) ? kBillboardTypeNames[mBillboardType] : "camera";
    }
    //-----------------------------------------------------------------------
    void NewRibbonTrailElement::_applyParameters(void)
    {
        if (!mTrail)
            return;

        mTrail->setMaxChainElements(static_cast<size_t>(std::max(3, mMaxChainElements)));
        mTrail->setTrailLength(mTrailLength);
        mTrail->setInitialWidth(mInitialWidth);
        mTrail->setWidthChange(mWidthChange);
        mTrail->setTailWidth(mTailWidth);
        mTrail->setLowWidthCut(mLowWidthCut);
        mTrail->setHighWidthCut(mHighWidthCut);
        mTrail->setAlphaColourCut(mAlphaColourCut);
        mTrail->setLiftTime(mLiftTime);
        for (size_t i = 0; i < NUM_COLOUR_KEYS; ++i)
            mTrail->setColourKey(i, mColourTimes[i], mColours[i]);
        mTrail->setBillboardType(static_cast<NewRibbonTrail::BillboardType>(mBillboardType));
        mTrail->setDirectionOrPoint(mDirectionOrPoint);

        if (!mMaterialName.empty() && mMaterialName != mTrail->getMaterialName())
        {
            if (Ogre::MaterialManager::getSingleton().resourceExists(mMaterialName))
            {
                mTrail->setMaterialName(mMaterialName);
            }
            else
            {
                Fx::logOnce("NewRibbonTrail.Material=" + mMaterialName,
                    "NewRibbonTrail: material '" + mMaterialName + "' not found, BaseWhiteNoLighting used");
            }
        }
        mParamsDirty = false;
    }
    //-----------------------------------------------------------------------
    bool NewRibbonTrailElement::createRenderInstance(void)
    {
        if (!mBasicNode)
            return false;

        if (!mTrail)
        {
            Ogre::SceneNode* baseNode = mSystem->getBaseSceneNode();
            if (!baseNode)
                return false;

            // B: the trail lives in world space on its own node and watches the element node
            mTrailNode = baseNode->createChildSceneNode();
            mTrail = new NewRibbonTrail("CYS/NewRibbonTrail/" + Ogre::StringConverter::toString(++sTrailCount),
                static_cast<size_t>(std::max(3, mMaxChainElements)));
            mTrail->setRenderQueueGroup(Ogre::RENDER_QUEUE_8);
            mTrail->setCastShadows(false);
            mTrailNode->attachObject(mTrail);
            mTrail->setVisible(mVisible);
            mParamsDirty = true;
        }

        _applyParameters();
        mNeedRestart = true;
        return true;
    }
    //-----------------------------------------------------------------------
    void NewRibbonTrailElement::destroyRenderInstance(void)
    {
        if (mTrail)
        {
            mTrail->setTrackedNode(NULL);
            if (mTrailNode)
                mTrailNode->detachObject(mTrail);
            delete mTrail;
            mTrail = NULL;
        }
        if (mTrailNode)
        {
            mTrailNode->getCreator()->destroySceneNode(mTrailNode->getName());
            mTrailNode = NULL;
        }

        EffectElement::destroyRenderInstance();
    }
    //-----------------------------------------------------------------------
    void NewRibbonTrailElement::updateRenderInstance(Real time, TransformInfo& info)
    {
        if (!mTrail)
            return;

        if (mParamsDirty)
            _applyParameters();

        if (mNeedRestart)
        {
            // first update after creation / wake up: start the chain at the element node
            mTrail->setEnabled(true);
            if (mTrail->getTrackedNode() != mBasicNode)
                mTrail->setTrackedNode(mBasicNode);
            else
                mTrail->resetTrail();
            mNeedRestart = false;
        }

        // ParentSpaceLock: the chain moves rigidly with the effect (B keeps the trail in the parent space)
        if (getParentSpaceLock())
            mTrail->setLogicTransform(info.mPosition, info.mRotation);

        mTrail->timeUpdate(time);
        mTrail->pollTrackedNode();
    }
    //-----------------------------------------------------------------------
    void NewRibbonTrailElement::sleep(void)
    {
        if (mTrail)
        {
            mTrail->setEnabled(false);
            mTrail->resetTrail();
        }
        mNeedRestart = true;

        EffectElement::sleep();
    }
    //-----------------------------------------------------------------------
    void NewRibbonTrailElement::active(void)
    {
        mNeedRestart = true;
        EffectElement::active();
    }
    //-----------------------------------------------------------------------
    void NewRibbonTrailElement::setVisible(bool visible)
    {
        if (mTrail)
            mTrail->setVisible(visible);
        EffectElement::setVisible(visible);
    }
    //-----------------------------------------------------------------------
    void NewRibbonTrailElement::setVisibleFlag(uint32 flags)
    {
        if (mTrail)
            mTrail->setVisibilityFlags(flags);
    }
    //-----------------------------------------------------------------------
    String NewRibbonTrailElement::CmdBillboardType::doGet(const void* target) const
    {
        return static_cast<const NewRibbonTrailElement*>(target)->getBillboardTypeString();
    }
    void NewRibbonTrailElement::CmdBillboardType::doSet(void* target, const String& val)
    {
        static_cast<NewRibbonTrailElement*>(target)->setBillboardTypeFromString(val);
    }
#if OGRE_STRING_INTERFACE_COPY
    void NewRibbonTrailElement::CmdBillboardType::doCopy(void* target, const void* source)
    {
        static_cast<NewRibbonTrailElement*>(target)->mBillboardType =
            static_cast<const NewRibbonTrailElement*>(source)->mBillboardType;
        static_cast<NewRibbonTrailElement*>(target)->mParamsDirty = true;
    }
#endif
    //-----------------------------------------------------------------------
    EffectElement* NewRibbonTrailElementFactory::createElement(System* system)
    {
        EffectElement* element = new NewRibbonTrailElement("NewRibbonTrail", system);
        mElements.push_back(element);
        return element;
    }

}
