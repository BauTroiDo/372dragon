/********************************************************************
filename:   OgreTexCoordBillboardParticleRenderer.h

purpose:    this particle renderer is used to renderer particle that want to 
			change the texture coordinate at runtime. 
*********************************************************************/

#ifndef __TexCoordBillboardParticleRenderer_H__
#define __TexCoordBillboardParticleRenderer_H__

#include "OgrePrerequisites.h"
#include "OgreBillboardParticleRenderer.h"
#include "OgreParticle.h"

namespace Ogre	{

	// CYS: per-particle texture-rect provider (the SequenceFrame affector of the 2024+ effect data binds itself
	// here; without a source the renderer keeps its 0.85 life-based flip-book).
	class TexCoordIndexSource
	{
	public:
		virtual ~TexCoordIndexSource() {}
		/// index in [0, numTexCoords) of the texture rect used by particle p
		virtual uint16 _getTexCoordIndex(Particle* p, uint16 numTexCoords) = 0;
	};

	//////////////////////////////////////////////////////////////////////////
	class TexCoordBillboardParticleRenderer : public BillboardParticleRenderer
	{
	public:

		/** Command object for texture coord stacks (see ParamCommand).*/
		class CmdStacks : public ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
		};
		/** Command object for texture coord slices (see ParamCommand).*/
		class CmdSlices : public ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
		};
		/** Command object for texture coord slices (see ParamCommand).*/
		class CmdRepeatTimes : public ParamCommand
		{
		public:
			String doGet(const void* target) const;
			void doSet(void* target, const String& val);
		};

		//////////////////////////////////////////////////////////////////////////
		TexCoordBillboardParticleRenderer();

		/// @copydoc ParticleSystemRenderer::getType
		virtual const String& getType(void) const;
		/// @copydoc ParticleSystemRenderer::_updateRenderQueue
		virtual void _updateRenderQueue(RenderQueue* queue, 
			std::list<Particle*>& currentParticles, bool cullIndividually);
		
		/** sets of the stacks of texture coordinates */
		void setStacks(ulong stacks);
		ulong getStacks(void) const
		{
			return mStacks;
		}

		/** sets of the slices of texture coordinates */
		void setSlices(ulong slices);
		ulong getSlices(void) const
		{
			return mSlices;
		}

		/** sets of the repeat times */
		void setRepeatTimes(Real times)
		{
			mRepeatTimes = times;
		}
		Real getRepeatTimes(void) const
		{
			return mRepeatTimes;
		}

		// CYS: SequenceFrame hook (see TexCoordIndexSource)
		void setTexCoordIndexSource(TexCoordIndexSource* source) { mIndexSource = source; }
		TexCoordIndexSource* getTexCoordIndexSource(void) const { return mIndexSource; }

	protected:

		/// CYS: optional per-particle rect provider
		TexCoordIndexSource* mIndexSource;

		/// the stacks of texture coordinates
		ulong mStacks;
		/// the slices of texture coordinates
		ulong mSlices;

		Real                    mRepeatTimes;

		//////////////////////////////////////////////////////////////////////////
		static CmdStacks msStacksCmd;
		static CmdSlices msSlicesCmd;
		static CmdRepeatTimes   msRepeatTimesCmd;
	};

	/** Factory class for MeshParticleRenderer */
	class TexCoordBillboardParticleRendererFactory : public ParticleSystemRendererFactory
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