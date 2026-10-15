/********************************************************************
filename:   FairyParticleElement.cpp

purpose:    a particle system effect element.
*********************************************************************/

#include "WXParticleElement.h"
#include "WXEffectManager.h"

// ogre header
#include <OgreParticleSystem.h>
#include <OgreSceneManager.h>
#include <OgreSceneNode.h>
#include <OgreStringConverter.h>
#include <OgreParticleEmitter.h>
#include <OgreParticleAffector.h>
#include <OgreParticleSystemManager.h>

#include "OgreExt/OgreMeshParticleRenderer.h"
#include "OgreExt/OgreMeshParticleVisualData.h"	// CYS: sub-effects on mesh particles
#include "Core/WXSystem.h"						// CYS: collision effects (terrain)
#include "Core/TerrainData.h"					// CYS
#include "Core/TerrainTypeInfos.h"				// CYS
#include <OgreEntity.h>							// CYS

namespace WX	{

	ParticleElement::CmdParticleSystem ParticleElement::msParticleSystemCmd;
	bool ParticleElement::msSubEffectsEnabled = true;	// CYS: sub-effect master switch (default on)
	// CYS: sub-effect / collision commands
	ParticleElement::CmdParEffectName          ParticleElement::msParEffectNameCmd;
	ParticleElement::CmdColEffectName          ParticleElement::msColEffectNameCmd;
	ParticleElement::CmdUseParticleEffect      ParticleElement::msUseParticleEffectCmd;
	ParticleElement::CmdUseParticleCollision   ParticleElement::msUseParticleCollisionCmd;
	ParticleElement::CmdUseEnergyWave          ParticleElement::msUseEnergyWaveCmd;
	ParticleElement::CmdLegacyPosForSubEffect  ParticleElement::msLegacyPosForSubEffectCmd;
	ParticleElement::CmdPassRotationToSubEffect ParticleElement::msPassRotationToSubEffectCmd;

	ParticleElement::ParticleElement(const String &type, System *system) :
	EffectElement(type, system),
	mParticleSystem(NULL),
	mParticleSystemName(""),
	mIsEmitterEnabled(false),
    mNeedUpdateColour(false),
    mCurrentColour(Ogre::ColourValue::White),
	mParEffectName(""),					// CYS
	mColEffectName(""),					// CYS
	mUseParticleEffect(false),			// CYS
	mUseParticleCollision(false),		// CYS
	mUseEnergyWave(false),				// CYS
	mLegacyPosForSubEffect(false),		// CYS
	mPassRotationToSubEffect(false),	// CYS
	mParticleEffectStamp(0)				// CYS
	{
		if ( initDefaults(mElementType) )
		{
			Ogre::ParamDictionary* dict = getParamDictionary();

        // Custom params
			dict->addParameter(Ogre::ParameterDef("ParticleSystem",
			  "the name of particle system.",
				Ogre::PT_STRING),&msParticleSystemCmd);

			// CYS: sub-effect / collision keys (stored for parity, see header)
			dict->addParameter(Ogre::ParameterDef("ParEffectName",
				"name of the particle sub-effect.", Ogre::PT_STRING), &msParEffectNameCmd);
			dict->addParameter(Ogre::ParameterDef("ColEffectName",
				"name of the collision sub-effect.", Ogre::PT_STRING), &msColEffectNameCmd);
			dict->addParameter(Ogre::ParameterDef("use_particle_effect",
				"spawn ParEffectName per particle.", Ogre::PT_BOOL), &msUseParticleEffectCmd);
			dict->addParameter(Ogre::ParameterDef("use_particle_collision",
				"spawn ColEffectName on collision.", Ogre::PT_BOOL), &msUseParticleCollisionCmd);
			dict->addParameter(Ogre::ParameterDef("use_energy_wave",
				"use the energy wave collision.", Ogre::PT_BOOL), &msUseEnergyWaveCmd);
			dict->addParameter(Ogre::ParameterDef("legacy_pos_for_sub_effect",
				"use the legacy position for the sub-effect.", Ogre::PT_BOOL), &msLegacyPosForSubEffectCmd);
			dict->addParameter(Ogre::ParameterDef("pass_rotation_to_sub_effect",
				"pass the particle rotation to the sub-effect.", Ogre::PT_BOOL), &msPassRotationToSubEffectCmd);
		}
	}
	//---------------------------------------------------------------------
	ParticleElement::~ParticleElement()
	{
		// CYS: B drops the sub-effects and the collision effects first (FUN_180215a70)
		_removeParticleEffects();
		_removeCollisionEffects();

		destroyRenderInstance();
	}	
	//---------------------------------------------------------------------
	bool ParticleElement::createRenderInstance(void)
	{
		return _createParticleSystem();
	}
	//---------------------------------------------------------------------
	void ParticleElement::destroyRenderInstance(void)
	{
		_destroyParticleSystem();

		EffectElement::destroyRenderInstance();
	}
	//---------------------------------------------------------------------
	void ParticleElement::updateRenderInstance( Real time, TransformInfo &info )
	{
		if ( false == mIsEmitterEnabled )
		{
			if (mParticleSystem)
			{
				for ( unsigned short i = 0; i < mParticleSystem->getNumEmitters(); ++i )
				{
					Ogre::ParticleEmitter* emitter = mParticleSystem->getEmitter(i);

					if (emitter && false == emitter->getEnabled())
						emitter->setEnabled(true);
				}
			}

			mIsEmitterEnabled = true;
		}

        // 真正地进行颜色的改变
        if (mNeedUpdateColour)
        {
            _setAffectorColour();
            mNeedUpdateColour = false;
        }

		// CYS: B ParticleElement::updateRenderInstance (FUN_180218070): sub-effects, then collision effects.
		// Guarded by the sub-effect master switch so it can be disabled at runtime without a rebuild.
		if ( msSubEffectsEnabled )
		{
			if ( mUseParticleEffect && mParticleSystem && mBasicNode &&
				false == mParEffectName.empty() && mParEffectName != "NullEffect" )
				_updateParticleEffects();

			if ( mUseParticleCollision && mParticleSystem && mBasicNode &&
				false == mColEffectName.empty() && mColEffectName != "NullEffect" )
				_updateCollisionEffects();
		}
	}
	//---------------------------------------------------------------------
	void ParticleElement::destroyMe(void)
	{
		EffectElement::destroyMe();
	//	if (mParticleSystem)
	//		mParticleSystem->removeAllEmitters();
	}
	//---------------------------------------------------------------------
	void ParticleElement::sleep(void)
	{
		if (mParticleSystem)
		{
			// CYS: B sleep drops the sub-effects / collision effects of an attached system (FUN_180217e40)
			if (_isSystemAttached())
			{
				_removeParticleEffects();
				_removeCollisionEffects();
			}

            // detach from parent first
            if (mParticleSystem->getParentNode() &&
                mParticleSystem->getParentNode() == mParticleSystem->getParentSceneNode())
            {
                mParticleSystem->getParentSceneNode()->detachObject(mParticleSystem);
            }

			for ( unsigned short i = 0; i < mParticleSystem->getNumEmitters(); ++i )
			{
				Ogre::ParticleEmitter* emitter = mParticleSystem->getEmitter(i);

				if (emitter && emitter->getEnabled())
					emitter->setEnabled(false);
			}

			mIsEmitterEnabled = false;

			mParticleSystem->clear();

			// 消除MeshParticleRenderer残留的粒子
			Ogre::ParticleSystemRenderer *renderer = mParticleSystem->getRenderer();

			assert (renderer);

			if (renderer->getType() == "mesh")
			{
				static_cast<Ogre::MeshParticleRenderer *>(renderer)->removeAllMeshParticle();
			}
		}

        mCurrentColour = Ogre::ColourValue::White;
        mNeedUpdateColour = false;

		EffectElement::sleep();		
	}
	//---------------------------------------------------------------------
	void ParticleElement::active(void)
	{
        // attach to basic scene node in case if wake up from sleeping
        if (mParticleSystem && !mParticleSystem->getParentNode() && mBasicNode)
        {
            mBasicNode->attachObject(mParticleSystem);
        }

		EffectElement::active();

		// 先不激活emitter，因为现在可能还没到start time，如果现在激活，会使粒子播放时间减少，应在到start time
		// 时才激活
		/*if (mParticleSystem)
		{
			for ( unsigned short i = 0; i < mParticleSystem->getNumEmitters(); ++i )
			{
				mParticleSystem->getEmitter(i)->setEnabled(true);
			}
		}*/
	}	
	//---------------------------------------------------------------------
	void ParticleElement::setParticleSystemName(const String &name)
	{	
		mParticleSystemName = name;

		_destroyParticleSystem();

		mIsRenderInstanceCreated = false;
	}		
	//---------------------------------------------------------------------
	bool ParticleElement::_createParticleSystem(void)
	{
		assert( mParticleSystem == NULL );
		//assert( false == mParticleSystemName.empty() );

		if ( false == mParticleSystemName.empty() )
		{
			Ogre::SceneNode* parent = mBasicNode;

			if (parent)
			{
                mParticleSystem = parent->getCreator()->createParticleSystem( parent->getName(), mParticleSystemName );
                assert(mParticleSystem);

                Ogre::ParticleSystem* pTemplate = Ogre::ParticleSystemManager::getSingleton().getTemplate( mParticleSystemName );

                EffectManager& effectMgr = EffectManager::getSingleton();

                EffectLevel effectLevel = effectMgr.getEffectLevel();

                if (effectLevel == EL_MID)
                {
                    // 中级特效，quota为原来的50%，特效不迭代
                    size_t newQuota = (size_t)(pTemplate->getParticleQuota() * 0.5);

                    if (newQuota == 0)
                        newQuota = 1;

                    mParticleSystem->setParticleQuota(newQuota);

                    mParticleSystem->setIterationInterval(0.0f);
                }
                else if (effectLevel == EL_LOW)
                {
                    // 中级特效，quota为原来的10%，特效不迭代
                    size_t newQuota = (size_t)(pTemplate->getParticleQuota() * 0.1);

                    if (newQuota == 0)
                        newQuota = 1;

                    mParticleSystem->setParticleQuota(newQuota);

                    mParticleSystem->setIterationInterval(0.0f);
                }

                mParticleSystem->setRenderQueueGroup(Ogre::RENDER_QUEUE_8);

                mParticleSystem->setCastShadows(false);

                mParticleSystem->setVisible(mVisible);

				parent->attachObject(mParticleSystem);

				return true;
			}
		}       

		return false;
	}
	//---------------------------------------------------------------------
	void ParticleElement::_destroyParticleSystem(void)
	{
		if (mParticleSystem)
		{
			mParticleSystem->destroy();
			mParticleSystem = NULL;
		} 
	}
	//---------------------------------------------------------------------
	// CYS: sub-effects and collision effects of the B ParticleElement (client_GL Render.dll)
	//---------------------------------------------------------------------
	namespace
	{
		/// the node carrying the entity of a mesh particle (B: particle visual -> entity -> parent node)
		Ogre::Node* _meshParticleNode(Ogre::Particle* particle)
		{
			Ogre::MeshParticleVisualData* visual =
				static_cast<Ogre::MeshParticleVisualData*>(particle->getVisualData());
			Ogre::Entity* entity = visual ? visual->getEntity() : NULL;
			return entity ? entity->getParentNode() : NULL;
		}
	}
	//---------------------------------------------------------------------
	bool ParticleElement::_isSystemAttached(void) const
	{
		return mParticleSystem && mParticleSystem->getParentNode() &&
			mParticleSystem->getParentNode() == mParticleSystem->getParentSceneNode();
	}
	//---------------------------------------------------------------------
	void ParticleElement::_updateParticleEffects(void)
	{
		EffectManager& effectMgr = EffectManager::getSingleton();

		// B FUN_180216c10: every live particle gets an entry, appended in particle order; an entry whose particle
		// is no longer alive loses it. Particles are identified by address as in B, so a pool slot that is
		// reused between two updates keeps its entry and its effect.
		++mParticleEffectStamp;

		Ogre::ParticleIterator it = mParticleSystem->_getIterator();
		while ( false == it.end() )
		{
			Ogre::Particle* particle = it.getNext();

			ParticleEffectIndex::iterator found = mParticleEffectIndex.find(particle);
			if ( found == mParticleEffectIndex.end() )
			{
				ParticleEffectInfo info;
				info.mParticle = particle;
				info.mEffect = NULL;
				info.mStamp = mParticleEffectStamp;
				mParticleEffects.push_back(info);
				mParticleEffectIndex.insert(ParticleEffectIndex::value_type(particle, --mParticleEffects.end()));
			}
			else
			{
				found->second->mStamp = mParticleEffectStamp;
			}
		}

		for ( ParticleEffectList::iterator i = mParticleEffects.begin(); i != mParticleEffects.end(); ++i )
		{
			if ( i->mParticle && i->mStamp != mParticleEffectStamp )
			{
				mParticleEffectIndex.erase(i->mParticle);
				i->mParticle = NULL;
			}
		}

		// B FUN_180216e90: the effect of a dead particle goes back to the pool at once, a new particle gets its
		// effect, and every effect is placed on its particle.
		const bool localSpace = mParticleSystem->getKeepParticlesInLocalSpace();
		const bool meshRenderer = ( mParticleSystem->getRendererName() == "mesh" );

		ParticleEffectList::iterator i = mParticleEffects.begin();
		while ( i != mParticleEffects.end() )
		{
			if ( NULL == i->mParticle )
			{
				if ( i->mEffect )
					effectMgr.removeEffect(i->mEffect, false, true);	// CYS: keep the pooled node attached-free (removeParentSceneNode)

				i = mParticleEffects.erase(i);
				continue;
			}

			if ( NULL == i->mEffect )
			{
				i->mEffect = effectMgr.createEffect(mParEffectName);
				i->mEffect->createSceneNode();
				i->mEffect->setVisibleFlag(mParticleSystem->getVisibilityFlags());
				i->mEffect->setVisible(mParticleSystem->isVisible());
			}

			Ogre::Particle* particle = i->mParticle;

			TransformInfo info;	// ZERO, IDENTITY, UNIT_SCALE

			if ( false == localSpace )
			{
				// world-space particles: the particle position itself
				info.mPosition = particle->position;
			}
			else
			{
				if ( false == mLegacyPosForSubEffect )
				{
					Ogre::Node* meshNode = meshRenderer ? _meshParticleNode(particle) : NULL;

					if (meshNode)
						info.mPosition = meshNode->_getDerivedPosition();
					else
						info.mPosition = mBasicNode->_getFullTransform() * particle->position;
				}
				else
				{
					// legacy position: the particle offset added to the node position (no rotation, no scale)
					info.mPosition = particle->position + mBasicNode->_getDerivedPosition();
				}

				info.mScale = mBasicNode->_getDerivedScale();
			}

			if ( mPassRotationToSubEffect && meshRenderer )
			{
				Ogre::Node* meshNode = _meshParticleNode(particle);
				if (meshNode)
					info.mRotation = meshNode->_getDerivedOrientation();
			}

			i->mEffect->setTransformInfo(info);

			++i;
		}
	}
	//---------------------------------------------------------------------
	void ParticleElement::_updateCollisionEffects(void)
	{
		// B FUN_180216800 (_updateColPsys): a particle within 10 units of the ground (the terrain height, or the
		// water surface kept in the terrain type info) makes the collision effect of its pool slot appear there
		// (a slot's effect is shut down and reborn when one of its particles lands again) and is expired.
		EffectManager& effectMgr = EffectManager::getSingleton();

		TerrainData* terrainData = mSystem ? mSystem->getTerrainData() : NULL;
		TerrainTypeInfos* typeInfos = mSystem ? mSystem->getTerrainTypeInfos() : NULL;

		const bool localSpace = mParticleSystem->getKeepParticlesInLocalSpace();
		const Ogre::Vector3 nodePosition = mBasicNode ? mBasicNode->_getDerivedPosition() : Ogre::Vector3::ZERO;

		Ogre::ParticleIterator it = mParticleSystem->_getIterator();
		while ( false == it.end() )
		{
			Ogre::Particle* particle = it.getNext();

			// B: a local-space particle is only offset by the node position here
			const Ogre::Vector3 position = localSpace ? ( nodePosition + particle->position ) : particle->position;

			const TerrainTypeInfos::TerrainTypeInfo* typeInfo =
				typeInfos ? typeInfos->findTerrainTypeInfo(position.x, position.z) : NULL;

			Real groundHeight;
			if ( typeInfo && typeInfo->mTerrainType == TerrainTypeInfos::TerrainType_LIQUID )
				groundHeight = typeInfo->mExtraData;
			else
				groundHeight = terrainData ? terrainData->getHeightAt(position.x, position.z) : 0.0f;

			if ( position.y - groundHeight < 10.0f )
			{
				Effect*& effect = mCollisionEffects[particle];

				if (effect)
				{
					effect->shutdown();
					effect->reborn();
				}
				else
				{
					effect = effectMgr.createEffect(mColEffectName);
					effect->createSceneNode();
				}

				effect->setTransformInfo( TransformInfo( Ogre::Vector3(position.x, groundHeight, position.z) ) );
                effect->setVisibleFlag(mParticleSystem->getVisibilityFlags());

				particle->timeToLive = 0.0f;
			}
		}
	}
	//---------------------------------------------------------------------
	void ParticleElement::_removeParticleEffects(void)
	{
		// B FUN_180215e30
		if ( false == mParticleEffects.empty() )
		{
			EffectManager& effectMgr = EffectManager::getSingleton();

			for ( ParticleEffectList::iterator i = mParticleEffects.begin(); i != mParticleEffects.end(); ++i )
			{
				if ( i->mEffect )
					effectMgr.removeEffect(i->mEffect, false, true);	// CYS: keep the pooled node attached-free (removeParentSceneNode)
			}

			mParticleEffects.clear();
		}

		mParticleEffectIndex.clear();
	}
	//---------------------------------------------------------------------
	void ParticleElement::_removeCollisionEffects(void)
	{
		// B FUN_180215ee0
		if ( false == mCollisionEffects.empty() )
		{
			EffectManager& effectMgr = EffectManager::getSingleton();

			for ( CollisionEffectMap::iterator i = mCollisionEffects.begin(); i != mCollisionEffects.end(); ++i )
			{
				if ( i->second )
					effectMgr.removeEffect(i->second, false, true);	// CYS
			}

			mCollisionEffects.clear();
		}
	}
	//---------------------------------------------------------------------
	bool ParticleElement::existVisualElements(void)
	{
		if (mParticleSystem)
		{
			return (mParticleSystem->getNumParticles() > 0);
		}
		else
			return false;
	}
	//---------------------------------------------------------------------
	void ParticleElement::shutdown(void)
	{
		// CYS: B shutdown drops the sub-effects / collision effects when it disables an emitter (FUN_180217d80)
		if (mParticleSystem)
		{
			for ( unsigned short e = 0; e < mParticleSystem->getNumEmitters(); ++e )
			{
				Ogre::ParticleEmitter* emitter = mParticleSystem->getEmitter(e);
				if (emitter && emitter->getEnabled())
				{
					_removeParticleEffects();
					_removeCollisionEffects();
					break;
				}
			}
		}

		if (mParticleSystem)
		{
			for ( unsigned short i = 0; i < mParticleSystem->getNumEmitters(); ++i )
			{
				Ogre::ParticleEmitter* emitter = mParticleSystem->getEmitter(i);

				if (emitter && emitter->getEnabled())
					emitter->setEnabled(false);
			}
		}
	}
    //---------------------------------------------------------------------
    void ParticleElement::setColour( const Ogre::ColourValue& colour )
    {
        mCurrentColour = colour;
        mNeedUpdateColour = true;        
    }
    //---------------------------------------------------------------------
    void ParticleElement::_setAffectorColour(void)
    {
        // 改变colour fader影响器中的颜色
        if (mParticleSystem)
        {
            for ( unsigned short i = 0; i < mParticleSystem->getNumAffectors(); ++i )
            {
                Ogre::ParticleAffector* affector = mParticleSystem->getAffector(i);

                assert (affector);
                if (affector->getType() == "ColourFading")
                {
                    for ( unsigned short num = 0; num < 6; ++num )
                    {
                        String paraName = "colour" + Ogre::StringConverter::toString(num);

                        ColourMap::iterator i = mColourMap.find(paraName);

                        Ogre::ColourValue originColour;

                        // 如果之前已经保存过原来的颜色，就直接获取
                        if (i != mColourMap.end())
                        {
                            originColour = i->second;
                        }
                        else
                        {
                            originColour = 
                                Ogre::StringConverter::parseColourValue( affector->getParameter(paraName) );

                            /// 保存原来的颜色
                            mColourMap.insert( ColourMap::value_type(paraName, originColour) );
                        }

                        /// 用原来的颜色与要设定的颜色进行相乘
                        affector->setParameter( paraName, 
                            Ogre::StringConverter::toString(originColour * mCurrentColour) );
                    }

                }
            }
        }
    }
    //-----------------------------------------------------------------------
    void ParticleElement::setVisibleFlag(uint32 flags)
    {
        if (mParticleSystem)
        {
            mParticleSystem->setVisibilityFlags(flags);
            if(mParticleSystem->getRendererName()=="mesh")
                static_cast<Ogre::MeshParticleRenderer*>(mParticleSystem->getRenderer())->setVisibilityFlags(flags);
        }
        for (auto& child:mParticleEffects) if(child.mEffect) child.mEffect->setVisibleFlag(flags);
        for (auto& child:mCollisionEffects) if(child.second) child.second->setVisibleFlag(flags);
    }
    //-----------------------------------------------------------------------
    void ParticleElement::setVisible(bool visible)
    {
        // CYS: B hiding an attached system drops its sub-effects / collision effects (FUN_180217bf0)
        if (false == visible && mParticleSystem && _isSystemAttached())
        {
            _removeParticleEffects();
            _removeCollisionEffects();
        }

        if (mParticleSystem)
        {
            if (visible)
            {
                // 如果要重新显示,就把粒子重新挂接上去
                if (!mParticleSystem->getParentNode() && mBasicNode)
                {
                    mBasicNode->attachObject(mParticleSystem);
                }
            }
            else
            {
                // 如果要隐藏这个粒子系统,要先把它从父节点上解挂,这样,就不会调用粒子系统的update()
                if (mParticleSystem->getParentNode() &&
                    mParticleSystem->getParentNode() == mParticleSystem->getParentSceneNode())
                {
                    mParticleSystem->getParentSceneNode()->detachObject(mParticleSystem);
                }

                // 对于mesh粒子,要隐藏它生成的mesh particle
                Ogre::ParticleSystemRenderer *renderer = mParticleSystem->getRenderer();

                assert (renderer);

                if (renderer->getType() == "mesh")
                {
                    static_cast<Ogre::MeshParticleRenderer *>(renderer)->removeAllMeshParticle();
                }
            }
        }

        // 要先执行上面的detach和attach之后，才来设置scene node的visible，因为这时候particle system
        // 才挂在scene node上，set visible才会对它进行设置
        EffectBasic::setVisible(visible);        
    }
    ///////////////////////////////////////////
	String ParticleElement::CmdParticleSystem::doGet(const void* target) const
    {
        return static_cast<const ParticleElement*>(target)->getParticleSystemName();
    }
    void ParticleElement::CmdParticleSystem::doSet(void* target, const String& val)
    {
        static_cast<ParticleElement *>(target)->setParticleSystemName(val);
    }  
#if OGRE_STRING_INTERFACE_COPY
    //-----------------------------------------------------------------------
    void ParticleElement::CmdParticleSystem::doCopy(void* target, const void* source)
    {
        static_cast<ParticleElement *>(target)->setParticleSystemName(
            static_cast<const ParticleElement*>(source)->getParticleSystemName() );
    }
#endif
}
