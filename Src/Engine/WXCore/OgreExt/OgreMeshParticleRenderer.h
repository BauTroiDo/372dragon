/********************************************************************
filename:   OgreMeshParticleRenderer.h

purpose:    Specialisation of ParticleSystemRenderer to render particles using
			mesh.
*********************************************************************/

#ifndef __MeshParticleRenderer_H__
#define __MeshParticleRenderer_H__

#include "OgrePrerequisites.h"
#include "OgreParticleSystemRenderer.h"
#include "OgreMaterial.h"
#include "OgreVector3.h"	// CYS: common direction / up-vector
#include "OgreQuaternion.h"	// CYS: local_rotation

namespace Ogre	{

	class MeshParticleVisualData;
	class Node;

	/** The type of billboard to use. */
	enum MeshOrientationType
	{
		/// origin mesh orientation
		MOT_ORIENTED_ORIGIN,
		/// oriented speed direction
		MOT_ORIENTED_SELF,
		// CYS: extra orientation types of the B mesh particle renderer (client_GL all.particle)
		/// the mesh faces the camera
		MOT_ORIENTED_CAMERA,
		/// the mesh is oriented around the common direction
		MOT_ORIENTED_COMMON,
		/// the mesh is perpendicular to the common direction (common up-vector kept up)
		MOT_PERPENDICULAR_COMMON,
		/// the mesh is perpendicular to its own direction (common up-vector kept up)
		MOT_PERPENDICULAR_SELF,
	};

	class MeshParticleRenderer : public ParticleSystemRenderer
	{
	public:

		/** Command object for mesh name (see ParamCommand).*/
		class _OgrePrivate CmdMeshName : public ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
		};

		/** Command object for orientation type (see ParamCommand).*/
		class _OgrePrivate CmdOrientationType : public ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
		};

		// CYS: common direction / up-vector for the oriented_common / perpendicular_* types
		class _OgrePrivate CmdCommonDirection : public ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
		};
		class _OgrePrivate CmdCommonUpVector : public ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
		};
		class _OgrePrivate CmdLocalRotation : public ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
		};
		class _OgrePrivate CmdLocalPosition : public ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
		};

		typedef std::vector<MeshParticleVisualData *> MeshParticleVisualDataPool;

		//////////////////////////////////////////////////////////////////////////
		MeshParticleRenderer();
		~MeshParticleRenderer();
        void setVisibilityFlags(uint32 flags);

		/// @copydoc ParticleSystemRenderer::getType
		virtual const String& getType(void) const;
		/// @copydoc ParticleSystemRenderer::_updateRenderQueue
		virtual void _updateRenderQueue(RenderQueue* queue,
			std::list<Particle*>& currentParticles, bool cullIndividually);
		/// @copydoc ParticleSystemRenderer::_setMaterial
		virtual void _setMaterial(MaterialPtr& mat);
		/// @copydoc ParticleSystemRenderer::_notifyCurrentCamera
		virtual void _notifyCurrentCamera(Camera* cam);
		/// @copydoc ParticleSystemRenderer::_notifyParticleRotated
		virtual void _notifyParticleRotated(void);
		/// @copydoc ParticleSystemRenderer::_notifyParticleResized
		virtual void _notifyParticleResized(void);
		/// @copydoc ParticleSystemRenderer::_notifyParticleQuota
		virtual void _notifyParticleQuota(size_t quota);
		/// @copydoc ParticleSystemRenderer::_notifyAttached
		virtual void _notifyAttached(Node* parent, bool isTagPoint = false);
		/// @copydoc ParticleSystemRenderer::_notifyDefaultDimensions
		virtual void _notifyDefaultDimensions(Real width, Real height);
		/// @copydoc ParticleSystemRenderer::setRenderQueueGroup
		virtual void setRenderQueueGroup(uint8 queueID);
		/// @copydoc ParticleSystemRenderer::setKeepParticlesInLocalSpace
		virtual void setKeepParticlesInLocalSpace(bool keepLocal);
        /// @copydoc ParticleSystemRenderer::_getSortMode
        virtual Ogre::SortMode _getSortMode(void) const;
		/// @copydoc ParticleSystemRenderer::_createVisualData
		virtual ParticleVisualData* _createVisualData(void);
		/// @copydoc ParticleSystemRenderer::_destroyVisualData
		virtual void _destroyVisualData(ParticleVisualData* vis);
        /** Optional callback notified when particles moved */
        virtual void _notifyParticleMoved(std::list<Particle*>& currentParticles);
        /** Optional callback notified when particle expired */
        virtual void _notifyParticleExpired(Particle* particle);

		/// sets the name of the mesh that particle used.
		void setMeshName(const String& name);
		const String& getMeshName(void) const	{	return mMeshName;	}

		/// set the material of the mesh
		void setMaterialName( const String& name );

		/// sets the mesh orientation type
		void setMeshOrientationType(MeshOrientationType mot);
		MeshOrientationType getMeshOrientationType(void) const;

		// CYS: common direction / up-vector accessors
		void setCommonDirection(const Vector3& v)	{	mCommonDirection = v;	}
		const Vector3& getCommonDirection(void) const	{	return mCommonDirection;	}
		void setCommonUpVector(const Vector3& v)	{	mCommonUpVector = v;	}
		const Vector3& getCommonUpVector(void) const	{	return mCommonUpVector;	}
		// CYS: client_GL local_rotation (quaternion "w x y z") / local_position of every mesh particle: the
		// transform of the mesh inside the particle frame (B hangs the entity on a child node carrying it)
		void setLocalRotation(const Quaternion& q)		{	mLocalRotation = q; mHasLocalOffset = true;	}
		const Quaternion& getLocalRotation(void) const	{	return mLocalRotation;	}
		void setLocalPosition(const Vector3& v)		{	mLocalPosition = v; mHasLocalOffset = true;	}
		const Vector3& getLocalPosition(void) const	{	return mLocalPosition;	}
		/// CYS: client_GL - third default dimension and the "system has a colour affector" flag
		virtual void _notifyDefaultDepth(Real depth)	{	mDefaultDepth = depth;	}
		virtual void _notifyParticleHaveColourAffector(bool has)	{	mApplyColour = has;	}

		/** CYS: transform of one mesh particle following client_GL (07b-particles_vi.md, mesh renderer).
			All vectors are in the particle space (world or system local). 'parent' is the orientation
			client_GL gives the particle frame (the system node orientation for world space particles,
			identity otherwise). 'size' = (width, height, depth); yaw/pitch/roll come from MeshRotator and
			are used when 'rotate' is true. Output: position and orientation of the mesh in that space
			(the local transform is applied inside the particle frame, scaled by the size).
			Exposed for the unit tests. */
		static void computeTransform(MeshOrientationType type, const Vector3& position, const Vector3& direction,
			const Vector3& size, bool rotate, const Radian& yaw, const Radian& pitch, const Radian& roll,
			const Vector3& commonDirection, const Vector3& commonUp, const Vector3& cameraPosition,
			const Quaternion& cameraOrientation, const Quaternion& parent, const Quaternion& localRotation,
			const Vector3& localPosition, Vector3& outPosition, Quaternion& outOrientation);

		/// remove all visible mesh particle
		void removeAllMeshParticle(void);

	protected:

		/// destroy all the mesh particle in the renderer
		void _freeParticleMeshVisualDatas(void);

	protected:

		/// the name of the mesh.
		String mMeshName;
		/// Name of the material to use.
        String mMaterialName;
        /// Pointer to the material to use.
        MaterialPtr mpMaterial;

		/// whether the mesh in move in world space.
		bool mWorldSpace;

		/// whether the mesh will be rotated.
		bool mMeshRotation;

		/// whether the size of the mesh will be changed.
		bool mMeshSizeChanged;

		/// the parent node of the particle system attached.
		Node *mParticleSystemNode;

		Real mDefaultWidth;
		Real mDefaultHeight;

		MeshOrientationType mMeshOrientationType;

		MeshParticleVisualDataPool mMeshParticleVisualDataPool;

        size_t mNextPoolIndex;

		// CYS: common direction / up-vector and the current camera (oriented_camera / *_common types)
		Vector3 mCommonDirection;
		Vector3 mCommonUpVector;
        // The RTT camera can be destroyed between particle ticks.
        Vector3 mCameraPosition;
        Quaternion mCameraOrientation;
        uint32 mVisibilityFlags;
		// CYS: extra per-mesh local rotation / position offset
		Quaternion mLocalRotation;
		Vector3 mLocalPosition;
		bool mHasLocalOffset;
		// CYS: default depth (particle_depth) and whether the particle colour is applied to the mesh
		Real mDefaultDepth;
		bool mApplyColour;

	protected:

		static CmdMeshName msMeshNameCmd;
		static CmdOrientationType msOrientationTypeCmd;
		static CmdCommonDirection msCommonDirectionCmd;		// CYS
		static CmdCommonUpVector msCommonUpVectorCmd;		// CYS
		static CmdLocalRotation msLocalRotationCmd;			// CYS
		static CmdLocalPosition msLocalPositionCmd;			// CYS
	};

	/** Factory class for MeshParticleRenderer */
	class MeshParticleRendererFactory : public ParticleSystemRendererFactory
	{
	public:
		/// @copydoc FactoryObj::getType
		virtual const String& getType() const;
		/// @copydoc FactoryObj::createInstance
		virtual ParticleSystemRenderer* createInstance( const String& name );
		/// @copydoc FactoryObj::destroyInstance
		virtual void destroyInstance( ParticleSystemRenderer* inst);
	};
}

#endif
