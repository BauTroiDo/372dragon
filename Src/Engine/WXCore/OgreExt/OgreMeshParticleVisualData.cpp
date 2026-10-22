/********************************************************************
filename:   OgreMeshParticleVisualData.cpp

purpose:    keep the data that used to render the mesh particle.
*********************************************************************/

#include "OgreMeshParticleVisualData.h"
#include "OgreMaterialManager.h"
#include "OgreSceneManager.h"
#include "OgreRoot.h"
#include "OgreEntity.h"
#include "OgreSubEntity.h"
#include "OgreSubMesh.h"
#include "OgreHardwareBuffer.h"
#include "OgreLogManager.h"
#include "OgreTechnique.h"	// CYS: per pass colour
#include "OgrePass.h"		// CYS
#include <set>			// CYS-SFX

namespace Ogre	{

	MeshParticleVisualData::MeshParticleVisualData() :
	mSceneNode(NULL),
	mEntity(NULL),
	mYawRotationSpeed(0),
	mPitchRotationSpeed(0),
	mRollRotationSpeed(0),
	mYawRotation(0),
	mPitchRotation(0),
	mRollRotation(0),
	mInit(false),
	mVisible(false),
	mOrientation(Quaternion::IDENTITY),
    mAnimState(NULL),
    mAnimationLoop(false),
    mAnimationName(""),
    mDeltaTime(0.0f),
    mAnimationUpdated(false),
    mAnimationSpeedFactor(1.0f),
    mPoolIndex(0),
    mCysAnimPos(0.0f)	// CYS
	{
	}
    //-----------------------------------------------------------------------
	MeshParticleVisualData::~MeshParticleVisualData()
	{
		destroyVisualData();		
	}
    //-----------------------------------------------------------------------
	void MeshParticleVisualData::createVisualData(const String &meshName, const String &matName, Node* parentNode)
	{
		SceneManager *sceneMgr = Root::getSingleton()._getCurrentSceneManager();

		// CYS-SFX: CY data points some mesh renderers at meshes that do not exist (g01_buff12_01 -> "ZHUAN DI1.mesh",
		// 07e 1.3). CY 3.71 keeps running and draws the rest of the effect (run-24-fx e1-buffs); the uncaught
		// Ogre::Exception ended the replay p24-2. A missing mesh is remembered and its particles stay without a visual.
		static std::set<String> s_missingMeshes;
		if ( !meshName.empty() && s_missingMeshes.count(meshName) )
			return;

		// create scene node and entity
		mSceneNode = sceneMgr->createSceneNode();

        parentNode->addChild(mSceneNode);

		// if the name of mesh is empty, we will use the prefab plane.
		if ( "" == meshName )
			mEntity = sceneMgr->createEntity( mSceneNode->getName(), Ogre::SceneManager::PT_PLANE );
		else
		{
			try
			{
				mEntity = sceneMgr->createEntity( mSceneNode->getName(), meshName );
			}
			catch (const Ogre::Exception& e)
			{
				s_missingMeshes.insert(meshName);
				LogManager::getSingleton().logMessage("[CYS-SFX] mesh particle '" + meshName + "' skipped: " + e.getDescription());
				parentNode->removeChild(mSceneNode);
				sceneMgr->destroySceneNode(mSceneNode->getName());
				mSceneNode = NULL;
				mEntity = NULL;
				return;
			}
		}

		assert (mEntity);

		mSceneNode->attachObject(mEntity);

		cloneMaterial(matName);

        mEntity->setCastShadows(false);

		mEntity->setMaterialName(mMaterial->getName());

		mInit = true;
	}
    //-----------------------------------------------------------------------
	void MeshParticleVisualData::destroyVisualData(void)
	{
		if (mInit)
		{
			assert(mEntity);
			mEntity->destroy();
			mEntity = NULL;

			assert (mSceneNode);
			mSceneNode->destroy();
			mSceneNode = NULL;

			if (!mMaterial.isNull())
			{
				MaterialManager::getSingleton().remove(mMaterial->getHandle());
			}

			mInit = false;
		}		
	}
    //-----------------------------------------------------------------------
	void MeshParticleVisualData::setPosition( const Vector3 &pos )
	{
		mSceneNode->setPosition(pos);
	}
    //-----------------------------------------------------------------------
	void MeshParticleVisualData::setDirection( const Vector3 &dir, const Quaternion& parentOrientation )
	{
		Vector3 yAdjustVec = dir;
        yAdjustVec.normalise();
        
        Vector3 xVec = mSceneNode->getOrientation().zAxis().crossProduct( yAdjustVec );
        xVec.normalise();

        Vector3 zVec = xVec.crossProduct( yAdjustVec );
        zVec.normalise();   

		mOrientation = parentOrientation * Quaternion( xVec, yAdjustVec, zVec );
	}
    //-----------------------------------------------------------------------
	void MeshParticleVisualData::setScale( Real xzSize, Real ySize )
	{
		mSceneNode->setScale(xzSize, ySize, xzSize);
	}
    //-----------------------------------------------------------------------
	void MeshParticleVisualData::setOrientation( const Radian &yaw, const Radian &pitch, const Radian &roll )
	{
		Quaternion yawQua(Degree(yaw.valueDegrees()), Vector3::UNIT_Y);
		Quaternion pitchQua(Degree(pitch.valueDegrees()), Vector3::UNIT_X);
		Quaternion rollQua(Degree(roll.valueDegrees()), Vector3::UNIT_Z);

		mSceneNode->setOrientation(yawQua * pitchQua * rollQua);
	}
    //-----------------------------------------------------------------------
	void MeshParticleVisualData::setOrientation( const Quaternion& q )
	{
		mOrientation = q;
	}
    //-----------------------------------------------------------------------
	void MeshParticleVisualData::setOrientation(bool rotate, const Quaternion& parentOrientation)
	{
		if (rotate)
		{
			Quaternion yawQua(Degree(mYawRotation.valueDegrees()), Vector3::UNIT_Y);
			Quaternion pitchQua(Degree(mPitchRotation.valueDegrees()), Vector3::UNIT_X);
			Quaternion rollQua(Degree(mRollRotation.valueDegrees()), Vector3::UNIT_Z);
			mSceneNode->setOrientation(yawQua * pitchQua * rollQua * mOrientation);
		}
		else
		{
			mSceneNode->setOrientation(mOrientation);
		}
	}
    //-----------------------------------------------------------------------
	void MeshParticleVisualData::setVisible(bool visible)
	{
		mVisible = visible;
		mSceneNode->setVisible(visible);
	}
    //-----------------------------------------------------------------------
	void MeshParticleVisualData::setNodeTransform(const Vector3& position, const Quaternion& orientation,
		const Vector3& scale)
	{
		// CYS: client_GL mesh particle node (see MeshParticleRenderer::computeTransform)
		mSceneNode->setPosition(position);
		mSceneNode->setOrientation(orientation);
		mSceneNode->setScale(scale);
	}
    //-----------------------------------------------------------------------
	void MeshParticleVisualData::setColour( const ColourValue &colour )
	{
		// CYS: client_GL (Material::setSelfIlluminationAndDiffuseAlpha): the particle RGB becomes the
		// self-illumination of every pass and the particle alpha the diffuse alpha (so meshes fade out);
		// 0.85 only set the self-illumination colour
		if (mMaterial.isNull())
			return;
		Material::TechniqueIterator ti = mMaterial->getTechniqueIterator();
		while (ti.hasMoreElements())
		{
			Technique::PassIterator pi = ti.getNext()->getPassIterator();
			while (pi.hasMoreElements())
			{
				Pass* pass = pi.getNext();
				pass->setSelfIllumination(colour.r, colour.g, colour.b);
				ColourValue diffuse = pass->getDiffuse();
				diffuse.a = colour.a;
				pass->setDiffuse(diffuse);
			}
		}
		return;
		/*if (mMaterial->getTechnique(0)->getPass(0)->getNumTextureUnitStates() > 0)
		{
			TextureUnitState *texture = mMaterial->getTechnique(0)->getPass(0)->getTextureUnitState(0);

			LayerBlendModeEx mode = texture->getColourBlendMode();
			texture->setColourOperationEx( mode.operation, mode.source1, mode.source2, colour, colour );
		}*/
	}
    //-----------------------------------------------------------------------
	void MeshParticleVisualData::modifyMesh(const String &meshName)
	{
		// destroy old entity
		assert(mEntity);

		Ogre::SceneNode* parent = mEntity->getParentSceneNode();
		assert(parent);
		Ogre::SceneManager* creator = parent->getCreator();
		assert(creator);

		parent->detachObject(mEntity->getName());
		creator->destroyMovableObject(mEntity);

		mEntity = NULL;

		// create new entity
		mEntity = creator->createEntity( mSceneNode->getName(), meshName );
		assert (mEntity);

		mSceneNode->attachObject(mEntity);
	}
    //-----------------------------------------------------------------------
	void MeshParticleVisualData::modifyMaterial(const String &matName)
	{
		assert(mEntity);
		
		if (!mMaterial.isNull())
		{
			MaterialManager::getSingleton().remove(mMaterial->getHandle());
		}

		cloneMaterial(matName);

		mEntity->setMaterialName(mMaterial->getName());
	}
    //-----------------------------------------------------------------------
    void MeshParticleVisualData::updateAnimation(void)
    {



        if (!mAnimState && mEntity)
        {
            AnimationStateSet* states = mEntity->getAllAnimationStates();
            if (states && states->hasAnimationState(mAnimationName))
                mAnimState = mEntity->getAnimationState(mAnimationName);
        }

        if (mAnimState)
        {
            mAnimState->setLoop(mAnimationLoop);

            if (false == mAnimState->getEnabled())
                mAnimState->setEnabled(true);

            mAnimState->setTimePosition(mAnimState->getLength() * mCysAnimPos);
        }
    }
    //-----------------------------------------------------------------------
    void MeshParticleVisualData::resetAnimation(void)
    {
        if (mAnimState)
        {
            mAnimationName = "";
            mAnimationLoop = false;
            mAnimationUpdated = false;

            mAnimState->setTimePosition(0.0f);
            mAnimState->setLoop(mAnimationLoop);
            mAnimState->setEnabled(false);
            mAnimState = NULL;
            mDeltaTime = 0.0f;
        }
    }
    //-----------------------------------------------------------------------
	void MeshParticleVisualData::cloneMaterial(const String& matName)
	{
		// clone material
		MaterialPtr material;
		String materialName;

		if ( matName == "" && (mEntity->getNumSubEntities() > 0) )
		{			
			// use origin material
			materialName = mEntity->getSubEntity(0)->getMaterialName();
		}
		else
		{
			// use new material
			materialName = matName;
		}

		material = MaterialManager::getSingleton().getByName(materialName);			

		if (material.isNull())
		{
			OGRE_EXCEPT(Exception::ERR_ITEM_NOT_FOUND,"Could not find material " + materialName,
				"MeshParticleVisualData::cloneMaterial");
		}

		material = material->clone(mSceneNode->getName());
		mMaterial = material;
	}
    //-----------------------------------------------------------------------
    void MeshParticleVisualData::setRenderQueueGroup(uint8 queueID)
    {
        if (mEntity)
            mEntity->setRenderQueueGroup(queueID);
    }
}