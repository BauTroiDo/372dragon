/********************************************************************
filename:   WXEffectElement.cpp

purpose:    a effect contains a lot of effect elements,these elements may be particle
system, or a mesh, or other things.
*********************************************************************/

// ogre header
#include <OgreSceneNode.h>
#include <OgreStringConverter.h>
#include <OgreSceneManager.h>

// fairy header
#include "WXEffectElement.h"
#include "WXEffectManager.h"
#include "WXEffect.h"
#include "Core/WXSystem.h"

namespace WX	{

	EffectElement::CmdStartTime EffectElement::msStartTimeCmd;
	EffectElement::CmdLifeTime EffectElement::msLifeTimeCmd;
	EffectElement::CmdRelPos EffectElement::msRelPosCmd;
    EffectElement::CmdRelOrientation EffectElement::msRelOrientationCmd;
    EffectElement::CmdCreateLevel EffectElement::msCreateLevelCmd;           // CYS
    EffectElement::CmdParentSpaceLock EffectElement::msParentSpaceLockCmd;   // CYS

	EffectElement::EffectElement(const String &type, System *system)	:
	EffectBasic(system),
	mElementType(type),
	mEffectParent(NULL),	
	mIsRenderInstanceCreated(false),
	mLifeTime(0.0f),
	mStartTime(0.0f),
	mCurrentLifeTime(0.0f),
	mCurrentStartTime(0.0f),
	mRelPos(Ogre::Vector3::ZERO),
    mRelOrientation(Ogre::Quaternion::IDENTITY),
	mIsActive(true),
	mIsDestroy(false),
	mCreateLevel(100),			// CYS: B default (the B EffectElement ctor writes CreateLevel = 100)
	mHiddenByLevel(false),		// CYS
	mParentSpaceLock(false)		// CYS
	{
	}

	EffectElement::~EffectElement()
	{
	}	

	void EffectElement::dump(std::ofstream &of) const
	{
		of << "element " << getType() << std::endl;
		of << "parameters" << std::endl;

		const Ogre::ParameterList &list = this->getParameters();

		for ( size_t count = 0; count < list.size(); ++count )
		{
			of << list[count].name << std::endl;
		}		
	}

	void EffectElement::update( Real time, TransformInfo &info )
	{
		// calculate the born time
		Real currentStartTime = mCurrentStartTime + time;
		if ( currentStartTime < mStartTime )
		{
			mCurrentStartTime = currentStartTime;
			return;
		}





		if ( static_cast<unsigned int>(mCreateLevel) < EffectManager::getSingleton().getCreateLevel() )
		{
			if ( false == mHiddenByLevel )
			{
				setVisible(false);
				mHiddenByLevel = true;
			}
			return;		// hidden: do not create or update the render instance this frame
		}
		if ( mHiddenByLevel )
		{
			setVisible(true);
			mHiddenByLevel = false;
		}

		if ( false == mIsRenderInstanceCreated )
		{
            if ( createRenderInstance() ) {
                mIsRenderInstanceCreated = true;
                // Delayed elements are born after the parent's mask was set.
                if (mEffectParent) setVisibleFlag(mEffectParent->getVisibleFlag());
            }
		}

		//　calculate the life time
		Real currentTime = mCurrentLifeTime + time;

		// if the life time is zero, the element will not be deleted.
		if ( (currentTime > mLifeTime) && (mLifeTime > 0.0f) )
		{
			// destroy (the effect removes the element next frame; do not update it this frame)
			destroyMe();
		}
		else
		{
			mCurrentLifeTime = currentTime;

			updateRenderInstance(time,info);
		}
	}
	//---------------------------------------------------------------------
	void EffectElement::setRelPos( const Ogre::Vector3 &pos )
	{	
		mRelPos = pos;
		if (mBasicNode)
			mBasicNode->setPosition(mRelPos);
	}
    //---------------------------------------------------------------------
    void EffectElement::setRelOrientation( const Ogre::Quaternion& orientation )
    {	
        mRelOrientation = orientation;
        if (mBasicNode)
            mBasicNode->setOrientation(mRelOrientation);
    }
	//---------------------------------------------------------------------
	bool EffectElement::initDefaults(const String &mType)
	{		
		if (createParamDictionary(mType + "EffectElement"))
		{
			Ogre::ParamDictionary* dict = getParamDictionary();

			dict->addParameter(Ogre::ParameterDef("StartTime", 
				"the start time of this element.",
				Ogre::PT_REAL),&msStartTimeCmd);

			dict->addParameter(Ogre::ParameterDef("LifeTime", 
				"the life time of this element.",
				Ogre::PT_REAL),&msLifeTimeCmd);

			dict->addParameter(Ogre::ParameterDef("Position", 
				"the relative pos from parent.",
				Ogre::PT_VECTOR3),&msRelPosCmd);

            dict->addParameter(Ogre::ParameterDef("Orientation",
                "the relative orientation from parent.",
                Ogre::PT_QUATERNION),&msRelOrientationCmd);

            // CYS: B/Fairy base keys (client_GL .effect)
            dict->addParameter(Ogre::ParameterDef("CreateLevel",
                "level to decide whether the effect element need to be created.",
                Ogre::PT_UNSIGNED_INT),&msCreateLevelCmd);

            dict->addParameter(Ogre::ParameterDef("ParentSpaceLock",
                "lock in parent space.",
                Ogre::PT_BOOL),&msParentSpaceLockCmd);

			return true;

		}
		return false;
	}
	//---------------------------------------------------------------------
	void EffectElement::sleep(void)
	{
		mCurrentLifeTime = 0.0f;
		mCurrentStartTime = 0.0f;

		mIsDestroy = false;
		//		mIsVisible = true;
		mIsActive = false;

        setVisible(false);
		//if (mBasicNode)
		//	mBasicNode->setVisible(false);
	}
	//---------------------------------------------------------------------
	void EffectElement::active(void)
	{
		mIsActive = true;

		/*if (mBasicNode)
		mBasicNode->setVisible(true);	*/
	}
	//---------------------------------------------------------------------
	void EffectElement::createSceneNode( Ogre::SceneNode *parentNode )
	{
		assert (parentNode);

		assert ( NULL == mBasicNode );

		mBasicNode = parentNode->createChildSceneNode(mRelPos, mRelOrientation);

		assert (mBasicNode);

		//	dumpSceneNode(mBasicNode);		
	}
	//---------------------------------------------------------------------
	void EffectElement::destroyMe(void)
	{
		// 设置自己的destroy状态
		mIsDestroy = true;
	}
	//---------------------------------------------------------------------
	void EffectElement::setTransformInfo( const TransformInfo &info )
	{
		if ( mBasicNode )
		{
			Ogre::Matrix3 mat(Ogre::Matrix3::IDENTITY);
			info.mRotation.ToRotationMatrix(mat);




			mBasicNode->setPosition(info.mPosition + mat * (info.mScale * mRelPos));
			mBasicNode->setOrientation(info.mRotation * mRelOrientation);
			mBasicNode->setScale(info.mScale);

		//	mBasicNode->_update(true,true);
		}
	}
	///////////////////////////////////////////
	String EffectElement::CmdStartTime::doGet(const void* target) const
    {
        return Ogre::StringConverter::toString(
            static_cast<const EffectElement*>(target)->getStartTime() );
    }
    void EffectElement::CmdStartTime::doSet(void* target, const String& val)
    {
        static_cast<EffectElement *>(target)->setStartTime(Ogre::StringConverter::parseReal(val));
    }
#if OGRE_STRING_INTERFACE_COPY
    //-----------------------------------------------------------------------
    void EffectElement::CmdStartTime::doCopy(void* target, const void* source)
    {
        static_cast<EffectElement *>(target)->setStartTime(
            static_cast<const EffectElement*>(source)->getStartTime() );
    }
#endif
    //-----------------------------------------------------------------------
	String EffectElement::CmdLifeTime::doGet(const void* target) const
    {
        return Ogre::StringConverter::toString(
            static_cast<const EffectElement *>(target)->getLifeTime() );
    }
    void EffectElement::CmdLifeTime::doSet(void* target, const String& val)
    {
        static_cast<EffectElement *>(target)->setLifeTime(Ogre::StringConverter::parseReal(val));
    }
#if OGRE_STRING_INTERFACE_COPY
    //-----------------------------------------------------------------------
    void EffectElement::CmdLifeTime::doCopy(void* target, const void* source)
    {
        static_cast<EffectElement *>(target)->setLifeTime(
            static_cast<const EffectElement*>(source)->getLifeTime() );
    }
#endif
    //---------------------------------------------------------------------
	String EffectElement::CmdRelPos::doGet(const void* target) const
    {
        return Ogre::StringConverter::toString(
            static_cast<const EffectElement *>(target)->getRelPos() );
    }
    void EffectElement::CmdRelPos::doSet(void* target, const String& val)
    {
		static_cast<EffectElement *>(target)->setRelPos(Ogre::StringConverter::parseVector3(val));
    } 
#if OGRE_STRING_INTERFACE_COPY
    //-----------------------------------------------------------------------
    void EffectElement::CmdRelPos::doCopy(void* target, const void* source)
    {
        static_cast<EffectElement *>(target)->setRelPos(
            static_cast<const EffectElement*>(source)->getRelPos() );
    }
#endif
    //---------------------------------------------------------------------
    String EffectElement::CmdRelOrientation::doGet(const void* target) const
    {
        return Ogre::StringConverter::toString(
            static_cast<const EffectElement *>(target)->getRelOrientation() );
    }
    void EffectElement::CmdRelOrientation::doSet(void* target, const String& val)
    {
        static_cast<EffectElement *>(target)->setRelOrientation(Ogre::StringConverter::parseQuaternion(val));
    }
#if OGRE_STRING_INTERFACE_COPY
    //-----------------------------------------------------------------------
    void EffectElement::CmdRelOrientation::doCopy(void* target, const void* source)
    {
        static_cast<EffectElement *>(target)->setRelOrientation(
            static_cast<const EffectElement*>(source)->getRelOrientation() );
    }
#endif
    //---------------------------------------------------------------------
    // CYS: base keys of the B/Fairy effect elements
    String EffectElement::CmdCreateLevel::doGet(const void* target) const
    {
        return Ogre::StringConverter::toString(
            static_cast<const EffectElement *>(target)->getCreateLevel() );
    }
    void EffectElement::CmdCreateLevel::doSet(void* target, const String& val)
    {
        static_cast<EffectElement *>(target)->setCreateLevel(Ogre::StringConverter::parseInt(val));
    }
#if OGRE_STRING_INTERFACE_COPY
    void EffectElement::CmdCreateLevel::doCopy(void* target, const void* source)
    {
        static_cast<EffectElement *>(target)->setCreateLevel(
            static_cast<const EffectElement*>(source)->getCreateLevel() );
    }
#endif
    //---------------------------------------------------------------------
    String EffectElement::CmdParentSpaceLock::doGet(const void* target) const
    {
        return Ogre::StringConverter::toString(
            static_cast<const EffectElement *>(target)->getParentSpaceLock() );
    }
    void EffectElement::CmdParentSpaceLock::doSet(void* target, const String& val)
    {
        static_cast<EffectElement *>(target)->setParentSpaceLock(Ogre::StringConverter::parseBool(val));
    }
#if OGRE_STRING_INTERFACE_COPY
    void EffectElement::CmdParentSpaceLock::doCopy(void* target, const void* source)
    {
        static_cast<EffectElement *>(target)->setParentSpaceLock(
            static_cast<const EffectElement*>(source)->getParentSpaceLock() );
    }
#endif
}
