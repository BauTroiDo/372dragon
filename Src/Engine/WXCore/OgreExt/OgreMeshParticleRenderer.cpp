/********************************************************************
filename:   OgreMeshParticleRenderer.cpp

purpose:    Specialisation of ParticleSystemRenderer to render particles using
mesh.
*********************************************************************/

#include "OgreMeshParticleRenderer.h"
#include "OgreStringConverter.h"
#include "OgreMeshParticleVisualData.h"
#include "OgreMaterialManager.h"
#include "OgreException.h"
#include "OgreNode.h"
#include "OgreCamera.h"		// CYS: oriented_camera
#include "OgreEntity.h"
#include "OgreLogManager.h"	// CYS: log-once for unknown orientation types

#include <set>

namespace Ogre	{

	MeshParticleRenderer::CmdMeshName MeshParticleRenderer::msMeshNameCmd;
	MeshParticleRenderer::CmdOrientationType MeshParticleRenderer::msOrientationTypeCmd;
	MeshParticleRenderer::CmdCommonDirection MeshParticleRenderer::msCommonDirectionCmd;	// CYS
	MeshParticleRenderer::CmdCommonUpVector MeshParticleRenderer::msCommonUpVectorCmd;	// CYS
	MeshParticleRenderer::CmdLocalRotation MeshParticleRenderer::msLocalRotationCmd;		// CYS
	MeshParticleRenderer::CmdLocalPosition MeshParticleRenderer::msLocalPositionCmd;		// CYS

	String meshRendererTypeName = "mesh";

	// CYS: report an unknown mesh orientation type only once (B throws; here it is non-fatal)
	static void meshRendererLogOnce(const String& key, const String& message)
	{
		static std::set<String> reported;
		if (reported.insert(key).second && LogManager::getSingletonPtr())
			LogManager::getSingleton().logMessage("CYS FX: " + message + " (reported once)");
	}

	//-----------------------------------------------------------------------
	MeshParticleRenderer::MeshParticleRenderer() :
	mMaterialName(""),
	mMeshName(""),
	mWorldSpace(false),
	mParticleSystemNode(NULL),
	mMeshRotation(false),
	mMeshSizeChanged(false),
	mDefaultWidth(1.0f),
	mDefaultHeight(1.0f),
	mMeshOrientationType(MOT_ORIENTED_ORIGIN),
    mNextPoolIndex(0),
	mCommonDirection(Vector3::UNIT_Z),	// CYS
	mCommonUpVector(Vector3::UNIT_Y),	// CYS
    mCameraPosition(Vector3::ZERO),
    mCameraOrientation(Quaternion::IDENTITY),
    mVisibilityFlags(0xFFFFFFFF),
	mLocalRotation(Quaternion::IDENTITY),	// CYS
	mLocalPosition(Vector3::ZERO),		// CYS
	mHasLocalOffset(false),				// CYS
	mDefaultDepth(0.0f),				// CYS: client_GL particle_depth default
	mApplyColour(false)					// CYS: set by the system (ColourFading / ColourInterpolator present)
	{
		if (createParamDictionary("MeshParticleRenderer"))
		{
			ParamDictionary* dict = getParamDictionary();
			dict->addParameter(ParameterDef("mesh_name",
				"the name of the mesh.",
				PT_STRING),
				&msMeshNameCmd);

			dict->addParameter(ParameterDef("orientation_type",
				"the orientation type of mesh particle,"
				"'oriented_origin', 'oriented_self', 'oriented_camera', 'oriented_common', "
				"'perpendicular_common' or 'perpendicular_self'.",
				PT_STRING),
				&msOrientationTypeCmd);

			// CYS: common direction / up-vector for the oriented_common / perpendicular_* types
			dict->addParameter(ParameterDef("common_direction",
				"common direction for oriented_common / perpendicular_common.",
				PT_VECTOR3),
				&msCommonDirectionCmd);

			dict->addParameter(ParameterDef("common_up_vector",
				"common up-vector for perpendicular_common / perpendicular_self.",
				PT_VECTOR3),
				&msCommonUpVectorCmd);

			// CYS: client_GL local transform of the mesh inside the particle frame
			dict->addParameter(ParameterDef("local_rotation",
				"local rotation of every mesh particle (quaternion w x y z).",
				PT_QUATERNION),
				&msLocalRotationCmd);

			dict->addParameter(ParameterDef("local_position",
				"local position of every mesh particle (scaled by the particle size).",
				PT_VECTOR3),
				&msLocalPositionCmd);
		}

		_freeParticleMeshVisualDatas();
	}
	//-----------------------------------------------------------------------
	MeshParticleRenderer::~MeshParticleRenderer()
	{
		_freeParticleMeshVisualDatas();
	}
	//-----------------------------------------------------------------------
	const String& MeshParticleRenderer::getType(void) const
	{
		return meshRendererTypeName;
	}
	//-----------------------------------------------------------------------
	void MeshParticleRenderer::_updateRenderQueue(RenderQueue* queue,
		std::list<Particle*>& currentParticles, bool cullIndividually)
	{
        // not implement
	}
    //-----------------------------------------------------------------------
    // CYS: client_GL mesh particle transform (B Render.dll mesh particle renderer)
    void MeshParticleRenderer::computeTransform(MeshOrientationType type, const Vector3& position,
        const Vector3& direction, const Vector3& size, bool rotate, const Radian& yaw, const Radian& pitch,
        const Radian& roll, const Vector3& commonDirection, const Vector3& commonUp,
        const Vector3& cameraPosition, const Quaternion& cameraOrientation, const Quaternion& parent,
        const Quaternion& localRotation, const Vector3& localPosition,
        Vector3& outPosition, Quaternion& outOrientation)
    {
        Quaternion facing = Quaternion::IDENTITY;
        bool applyRotation = rotate;
        // the camera 'back' axis (the mesh X axis is kept across the view for the direction based types)
        const Vector3 cameraAxis = cameraOrientation * Vector3::UNIT_Z;
        switch (type)
        {
        case MOT_ORIENTED_SELF:
        case MOT_ORIENTED_COMMON:
            {
                // mesh Y along the direction, X across the view, Z = X x Y
                Vector3 y = (type == MOT_ORIENTED_SELF) ? direction : commonDirection;
                y.normalise();
                Vector3 x = y.crossProduct(cameraAxis);
                x.normalise();
                const Vector3 z = x.crossProduct(y);
                facing.FromAxes(x, y, z);
            }
            break;
        case MOT_ORIENTED_CAMERA:
            {
                // mesh Z towards the camera, Y along the camera up
                Vector3 z = cameraPosition - position;
                z.normalise();
                const Vector3 up = cameraOrientation * Vector3::UNIT_Y;
                Vector3 x = up.crossProduct(z);
                x.normalise();
                const Vector3 y = z.crossProduct(x);
                facing.FromAxes(x, y, z);
                if (applyRotation)
                {
                    // a camera facing mesh only turns about its Z axis (by the roll)
                    facing = facing * Quaternion(roll, Vector3::UNIT_Z);
                    applyRotation = false;
                }
            }
            break;
        case MOT_PERPENDICULAR_COMMON:
        case MOT_PERPENDICULAR_SELF:
            {
                // mesh plane perpendicular to the direction, the common up-vector kept up
                const Vector3& d = (type == MOT_PERPENDICULAR_COMMON) ? commonDirection : direction;
                Vector3 x = commonUp.crossProduct(d);
                x.normalise();
                Vector3 y = d.crossProduct(x);
                y.normalise();
                const Vector3 z = x.crossProduct(y);
                facing.FromAxes(x, y, z);
            }
            break;
        default:
            break; // oriented_origin: the mesh keeps its own orientation
        }

        Quaternion frame = parent;
        if (applyRotation)
            frame = frame * Quaternion(yaw, Vector3::UNIT_Y) * Quaternion(pitch, Vector3::UNIT_X) *
                Quaternion(roll, Vector3::UNIT_Z);
        frame = frame * facing;

        // the mesh sits in the particle frame with the local transform (a child node in client_GL, so the
        // local position is scaled by the particle size)
        outOrientation = frame * localRotation;
        outPosition = position + frame * (size * localPosition);
    }
    //-----------------------------------------------------------------------
    void MeshParticleRenderer::_notifyParticleMoved(std::list<Particle*>& currentParticles)
    {
        // 如果送进来的粒子总数为0(有可能是调用了ParticleSystem::clear()),就马上隐藏所有的mesh particle
        if (currentParticles.size() == 0)
        {
            removeAllMeshParticle();

            return;
        }

        // CYS: client_GL transforms (see computeTransform). The particles are in world space (mWorldSpace) or
        // in the system node space; the camera is brought to the same space.
        const Quaternion nodeOrientation = mParticleSystemNode->_getDerivedOrientation();
        const Vector3 nodePosition = mParticleSystemNode->_getDerivedPosition();
        const Vector3 nodeScale = mParticleSystemNode->_getDerivedScale();
        const Quaternion nodeInverse = nodeOrientation.UnitInverse();
        Vector3 cameraPosition = mCameraPosition;
        Quaternion cameraOrientation = mCameraOrientation;
        {
            if (!mWorldSpace)
            {
                cameraOrientation = nodeInverse * cameraOrientation;
                cameraPosition = (nodeInverse * (cameraPosition - nodePosition)) / nodeScale;
            }
        }
        // client_GL gives world space mesh particles the system orientation as parent orientation
        const Quaternion parent = mWorldSpace ? nodeOrientation : Quaternion::IDENTITY;

        for (std::list<Particle*>::iterator i = currentParticles.begin();
            i != currentParticles.end(); ++i)
        {
            Particle* p = *i;
            MeshParticleVisualData *pVisualData = static_cast<MeshParticleVisualData *>(p->getVisualData());

            // 如果visual data还没创建过（每个particle第一次进入这个函数），就先创建
            if ( false == pVisualData->isInit() )
            {
                pVisualData->createVisualData(mMeshName, mMaterialName, mParticleSystemNode);
                if ( false == pVisualData->isInit() )
                    continue; // CYS-SFX: mesh missing in the data (see MeshParticleVisualData::createVisualData)
                pVisualData->getEntity()->setVisibilityFlags(mVisibilityFlags);
            }

            // CYS: client_GL scale = (width, height, depth): the particle size once an affector resized
            // particles, the system default size otherwise
            Vector3 size = mMeshSizeChanged ? Vector3(p->mWidth, p->mHeight, p->mDepth) :
                Vector3(mDefaultWidth, mDefaultHeight, mDefaultDepth);
            // CYS: client_GL (Render.dll FUN_1801e9b90) scales Z by the width when the depth is 0 - most mesh
            // templates set no particle_depth (default 0), a zero Z scale would flatten them
            if (size.z == 0.0f)
                size.z = size.x;

            Vector3 position;
            Quaternion orientation;
            computeTransform(mMeshOrientationType, p->position, p->direction, size, mMeshRotation,
                pVisualData->mYawRotation, pVisualData->mPitchRotation, pVisualData->mRollRotation,
                mCommonDirection, mCommonUpVector, cameraPosition, cameraOrientation, parent,
                mLocalRotation, mLocalPosition, position, orientation);

            if (mWorldSpace)
            {
                // client_GL hangs world space mesh particles under the scene root; here they hang under the
                // system node, so express the world transform in that node's space
                pVisualData->setNodeTransform((nodeInverse * (position - nodePosition)) / nodeScale,
                    nodeInverse * orientation, size / nodeScale);
            }
            else
            {
                pVisualData->setNodeTransform(position, orientation, size);
            }

            // CYS: client_GL only colours the mesh when the system has a colour affector
            if (mApplyColour)
                pVisualData->setColour(p->colour);

            // 设置动作属性
            // 如果经过了animation affector影响了之后，就更新动作时间
            if (pVisualData->mAnimationUpdated)
                pVisualData->updateAnimation();
            else
                pVisualData->resetAnimation();

            // 重置更新标志
            pVisualData->mAnimationUpdated = false;

            if (false == pVisualData->getVisible())
                pVisualData->setVisible(true);
        }
    }
    //-----------------------------------------------------------------------
    void MeshParticleRenderer::_notifyParticleExpired(Particle* particle)
    {
        MeshParticleVisualData* data = static_cast<MeshParticleVisualData*>(particle->getVisualData());
        if (data->isInit())
        {
            data->setVisible(false);
            data->resetAnimation();
        }
    }
	//-----------------------------------------------------------------------
	void MeshParticleRenderer::_setMaterial(MaterialPtr& mat)
	{
		setMaterialName(mat->getName());
	}
	//-----------------------------------------------------------------------
	void MeshParticleRenderer::_notifyCurrentCamera(Camera* cam)
	{
        // CYS: kept for the camera dependent orientation types (used by _notifyParticleMoved)
        if(cam) {
            mCameraPosition=cam->getDerivedPosition();
            mCameraOrientation=cam->getDerivedOrientation();
        }
	}
	//-----------------------------------------------------------------------
	void MeshParticleRenderer::_notifyParticleRotated(void)
	{
		mMeshRotation = true;
	}
	//-----------------------------------------------------------------------
	void MeshParticleRenderer::_notifyDefaultDimensions(Real width, Real height)
	{
		mDefaultWidth = width;
		mDefaultHeight = height;
	}
	//-----------------------------------------------------------------------
	void MeshParticleRenderer::_notifyParticleResized(void)
	{
		mMeshSizeChanged = true;
	}
	//-----------------------------------------------------------------------
	void MeshParticleRenderer::_notifyParticleQuota(size_t equota)
	{
        size_t currentSize = mMeshParticleVisualDataPool.size();

        if (currentSize >= equota)
            return;

        // 删除原来的
        _freeParticleMeshVisualDatas();

        mMeshParticleVisualDataPool.resize(equota);

        for (size_t i=0; i<mMeshParticleVisualDataPool.size(); ++i)
        {
            mMeshParticleVisualDataPool[i] = new MeshParticleVisualData;
        }

        mNextPoolIndex = 0;
	}
	//-----------------------------------------------------------------------
	void MeshParticleRenderer::_notifyAttached(Node* parent, bool isTagPoint)
	{
		mParticleSystemNode = parent;
	}
	//-----------------------------------------------------------------------
	void MeshParticleRenderer::setRenderQueueGroup(uint8 queueID)
	{
        for (size_t i=0; i<mMeshParticleVisualDataPool.size(); ++i)
        {
            mMeshParticleVisualDataPool[i]->setRenderQueueGroup(queueID);
        }
	}
	//-----------------------------------------------------------------------
	void MeshParticleRenderer::setKeepParticlesInLocalSpace(bool keepLocal)
	{
		mWorldSpace = !keepLocal;
	}
    //-----------------------------------------------------------------------
    Ogre::SortMode MeshParticleRenderer::_getSortMode(void) const
    {
        return Ogre::SM_DISTANCE;
    }
	//-----------------------------------------------------------------------
	ParticleVisualData* MeshParticleRenderer::_createVisualData(void)
	{
        MeshParticleVisualData* visualData = mMeshParticleVisualDataPool[mNextPoolIndex];

        assert (mNextPoolIndex < mMeshParticleVisualDataPool.size());
        visualData->setPoolIndex( mNextPoolIndex );

        // 数组下标递增
        ++mNextPoolIndex;

		return visualData;
	}
	//-----------------------------------------------------------------------
	void MeshParticleRenderer::_destroyVisualData(ParticleVisualData* vis)
	{
		if (vis)
		{
            size_t index = static_cast<MeshParticleVisualData*>(vis)->getPoolIndex();

            delete mMeshParticleVisualDataPool[index];
			mMeshParticleVisualDataPool[index] = NULL;
		}
        // 这里并不需要把mMeshParticleVisualDataPool中的对应项erase，因为MeshParticleVisualData
        // 记录的是mMeshParticleVisualDataPool的下标，如果erase，会使这个下标实效
	}
    //-----------------------------------------------------------------------
    void MeshParticleRenderer::setVisibilityFlags(uint32 flags)
    {
        if(mVisibilityFlags==flags) return;
        mVisibilityFlags=flags;
        for(auto data:mMeshParticleVisualDataPool)
            if(data && data->isInit()) data->getEntity()->setVisibilityFlags(flags);
    }
    void MeshParticleRenderer::removeAllMeshParticle(void)
    {
        for ( MeshParticleVisualDataPool::iterator i = mMeshParticleVisualDataPool.begin();
            i != mMeshParticleVisualDataPool.end(); ++i )
        {
            MeshParticleVisualData* data = *i;
            if (data && data->isInit())
            {
                data->setVisible(false);
                data->resetAnimation();
            }
        }
    }
	//---------------------------------------------------------------------
	void MeshParticleRenderer::setMeshName(const String &name)
	{
		mMeshName = name;

		for ( MeshParticleVisualDataPool::iterator i = mMeshParticleVisualDataPool.begin();
			i != mMeshParticleVisualDataPool.end(); ++i )
		{
			if (*i)
			{
				if ( (*i)->isInit() )
					(*i)->modifyMesh(name);
			}
		}
	}
	//---------------------------------------------------------------------
	void MeshParticleRenderer::_freeParticleMeshVisualDatas(void)
	{
		for ( MeshParticleVisualDataPool::iterator i = mMeshParticleVisualDataPool.begin();
			i != mMeshParticleVisualDataPool.end(); ++i )
		{
			if (*i)
			{
				delete *i;
				*i = NULL;
			}
		}
		mMeshParticleVisualDataPool.clear();
	}
	//-----------------------------------------------------------------------
    void MeshParticleRenderer::setMaterialName( const String& name )
    {
        mMaterialName = name;

		if ( "" != mMaterialName )
		{
			mpMaterial = MaterialManager::getSingleton().getByName(name);

			if (mpMaterial.isNull())
				OGRE_EXCEPT( Exception::ERR_ITEM_NOT_FOUND, "Could not find material " + name,
					"BillboardSet::setMaterialName" );

			/* Ensure that the new material was loaded (will not load again if
			   already loaded anyway)
			*/
			mpMaterial->load();
		}

		for ( MeshParticleVisualDataPool::iterator i = mMeshParticleVisualDataPool.begin();
			i != mMeshParticleVisualDataPool.end(); ++i )
		{
			if (*i)
			{
				if ( (*i)->isInit() )
					(*i)->modifyMaterial(name);
			}
		}
    }
	//-----------------------------------------------------------------------
	void MeshParticleRenderer::setMeshOrientationType(MeshOrientationType mot)
	{
		mMeshOrientationType = mot;

		if (mMeshOrientationType == MOT_ORIENTED_ORIGIN)
		{
			for ( MeshParticleVisualDataPool::iterator i = mMeshParticleVisualDataPool.begin();
				i != mMeshParticleVisualDataPool.end(); ++i )
			{
				if (*i)
				{
					if ( (*i)->isInit() )
						(*i)->setOrientation(Quaternion::IDENTITY);
				}
			}
		}
	}
	//-----------------------------------------------------------------------
	MeshOrientationType MeshParticleRenderer::getMeshOrientationType(void) const
	{
		return mMeshOrientationType;
	}
	//////////////////////////////////////////////////////////////////////////
	String MeshParticleRenderer::CmdMeshName::doGet(const void* target) const
	{
		return static_cast<const MeshParticleRenderer*>(target)->getMeshName();
	}
	void MeshParticleRenderer::CmdMeshName::doSet(void* target, const String& val)
	{
		static_cast<MeshParticleRenderer *>(target)->setMeshName(val);
	}
	//-----------------------------------------------------------------------
	String MeshParticleRenderer::CmdOrientationType::doGet(const void* target) const
	{
		MeshOrientationType t = static_cast<const MeshParticleRenderer*>(target)->getMeshOrientationType();
		switch(t)
		{
		case MOT_ORIENTED_ORIGIN:		return "oriented_origin";
		case MOT_ORIENTED_SELF:			return "oriented_self";
		case MOT_ORIENTED_CAMERA:		return "oriented_camera";		// CYS
		case MOT_ORIENTED_COMMON:		return "oriented_common";		// CYS
		case MOT_PERPENDICULAR_COMMON:	return "perpendicular_common";	// CYS
		case MOT_PERPENDICULAR_SELF:	return "perpendicular_self";	// CYS
		}
		// Compiler nicety
		return "oriented_origin";
	}
	void MeshParticleRenderer::CmdOrientationType::doSet(void* target, const String& val)
	{
		MeshOrientationType t;
		if (val == "oriented_origin")
			t = MOT_ORIENTED_ORIGIN;
		else if (val == "oriented_self")
			t = MOT_ORIENTED_SELF;
		else if (val == "oriented_camera")			// CYS
			t = MOT_ORIENTED_CAMERA;
		else if (val == "oriented_common")			// CYS
			t = MOT_ORIENTED_COMMON;
		else if (val == "perpendicular_common")		// CYS
			t = MOT_PERPENDICULAR_COMMON;
		else if (val == "perpendicular_self")		// CYS
			t = MOT_PERPENDICULAR_SELF;
		else
		{
			// CYS: B throws here and aborts the whole file; keep going with the default and log once
			meshRendererLogOnce("mesh.orientation_type=" + val,
				"MeshParticleRenderer: unknown orientation_type '" + val + "', oriented_origin used");
			t = MOT_ORIENTED_ORIGIN;
		}

		static_cast<MeshParticleRenderer*>(target)->setMeshOrientationType(t);
	}
	//-----------------------------------------------------------------------
	// CYS: common direction / up-vector commands
	String MeshParticleRenderer::CmdCommonDirection::doGet(const void* target) const
	{
		return StringConverter::toString(
			static_cast<const MeshParticleRenderer*>(target)->getCommonDirection());
	}
	void MeshParticleRenderer::CmdCommonDirection::doSet(void* target, const String& val)
	{
		static_cast<MeshParticleRenderer*>(target)->setCommonDirection(StringConverter::parseVector3(val));
	}
	//-----------------------------------------------------------------------
	String MeshParticleRenderer::CmdCommonUpVector::doGet(const void* target) const
	{
		return StringConverter::toString(
			static_cast<const MeshParticleRenderer*>(target)->getCommonUpVector());
	}
	void MeshParticleRenderer::CmdCommonUpVector::doSet(void* target, const String& val)
	{
		static_cast<MeshParticleRenderer*>(target)->setCommonUpVector(StringConverter::parseVector3(val));
	}
	//-----------------------------------------------------------------------
	String MeshParticleRenderer::CmdLocalRotation::doGet(const void* target) const
	{
		return StringConverter::toString(
			static_cast<const MeshParticleRenderer*>(target)->getLocalRotation());
	}
	void MeshParticleRenderer::CmdLocalRotation::doSet(void* target, const String& val)
	{
		// CYS: client_GL parses a quaternion "w x y z" (anything else gives the identity)
		static_cast<MeshParticleRenderer*>(target)->setLocalRotation(StringConverter::parseQuaternion(val));
	}
	//-----------------------------------------------------------------------
	String MeshParticleRenderer::CmdLocalPosition::doGet(const void* target) const
	{
		return StringConverter::toString(
			static_cast<const MeshParticleRenderer*>(target)->getLocalPosition());
	}
	void MeshParticleRenderer::CmdLocalPosition::doSet(void* target, const String& val)
	{
		static_cast<MeshParticleRenderer*>(target)->setLocalPosition(StringConverter::parseVector3(val));
	}
	//-----------------------------------------------------------------------
	//-----------------------------------------------------------------------
	//-----------------------------------------------------------------------
	const String& MeshParticleRendererFactory::getType() const
	{
		return meshRendererTypeName;
	}
	//-----------------------------------------------------------------------
	ParticleSystemRenderer* MeshParticleRendererFactory::createInstance(
		const String& name )
	{
		return new MeshParticleRenderer();
	}
	//-----------------------------------------------------------------------
	void MeshParticleRendererFactory::destroyInstance(
		ParticleSystemRenderer* inst)
	{
		delete inst;
	}
}
