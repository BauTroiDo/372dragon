/********************************************************************
filename:   WXParticleElement.h

purpose:    a particle system effect element.
*********************************************************************/

#ifndef __PARTICLEELEMENT_H__
#define __PARTICLEELEMENT_H__

// fairy header
#include "WXEffectElement.h"
#include "Core/WXPrerequisites.h"
#include "CYS/Effects/WXFxParamHelpers.h"	// CYS: sub-effect keyword commands

// ogre header
#include <list>
#include <unordered_map>

namespace Ogre	{
	class ParticleSystem;
	class Particle;	// CYS
}

namespace WX	{

	class ParticleElement : public EffectElement
	{
	public:

		// 参数命令
		class CmdParticleSystem : public Ogre::ParamCommand
        {
        public:
            String doGet(const void* target) const;
            void doSet(void* target, const String& val);
#if OGRE_STRING_INTERFACE_COPY
            virtual void doCopy(void* target, const void* source);
#endif
        };

		/////////////////////////////////////////////////////////////
		ParticleElement(const String &type, System *system);
		~ParticleElement();
		
		virtual bool createRenderInstance(void);
		virtual void destroyRenderInstance(void);
		virtual void updateRenderInstance( Real time, TransformInfo &info );

		virtual void destroyMe(void);

		void setParticleSystemName(const String &name);

		const String &getParticleSystemName(void) const	{	return mParticleSystemName;	}

		Ogre::ParticleSystem * getParticleSystem(void)	
		{
			return mParticleSystem;
		}

		void setParticleSystem(Ogre::ParticleSystem *system)
		{
			assert (system);
			mParticleSystem = system;
		}

		String mParticleSystemName;

		// CYS: sub-effect / collision keys of the B ParticleElement. ParEffectName + use_particle_effect: one effect
		// per live particle following it (_updateParticleEffects); ColEffectName + use_particle_collision: an effect
		// where a particle lands (_updateCollisionEffects). use_energy_wave registers the system in B's screen
		// distortion mask (render pipeline, not an effect element feature): stored only.
		String mParEffectName;
		String mColEffectName;
		bool   mUseParticleEffect;
		bool   mUseParticleCollision;
		bool   mUseEnergyWave;
		bool   mLegacyPosForSubEffect;
		bool   mPassRotationToSubEffect;

		typedef Fx::MemberCmd<ParticleElement, Fx::StringCodec, &ParticleElement::mParEffectName> CmdParEffectName;
		typedef Fx::MemberCmd<ParticleElement, Fx::StringCodec, &ParticleElement::mColEffectName> CmdColEffectName;
		typedef Fx::MemberCmd<ParticleElement, Fx::BoolCodec, &ParticleElement::mUseParticleEffect> CmdUseParticleEffect;
		typedef Fx::MemberCmd<ParticleElement, Fx::BoolCodec, &ParticleElement::mUseParticleCollision> CmdUseParticleCollision;
		typedef Fx::MemberCmd<ParticleElement, Fx::BoolCodec, &ParticleElement::mUseEnergyWave> CmdUseEnergyWave;
		typedef Fx::MemberCmd<ParticleElement, Fx::BoolCodec, &ParticleElement::mLegacyPosForSubEffect> CmdLegacyPosForSubEffect;
		typedef Fx::MemberCmd<ParticleElement, Fx::BoolCodec, &ParticleElement::mPassRotationToSubEffect> CmdPassRotationToSubEffect;

		static CmdParEffectName          msParEffectNameCmd;
		static CmdColEffectName          msColEffectNameCmd;
		static CmdUseParticleEffect      msUseParticleEffectCmd;
		static CmdUseParticleCollision   msUseParticleCollisionCmd;
		static CmdUseEnergyWave          msUseEnergyWaveCmd;
		static CmdLegacyPosForSubEffect  msLegacyPosForSubEffectCmd;
		static CmdPassRotationToSubEffect msPassRotationToSubEffectCmd;

		void _notifyParameterChanged(void) {}	// CYS: required by Fx::MemberCmd

		/// CYS: number of live sub-effects / collision effects (tests, perf counters)
		size_t _getNumParticleEffects(void) const	{	return mParticleEffects.size();	}
		size_t _getNumCollisionEffects(void) const	{	return mCollisionEffects.size();	}

		/// CYS: master switch for the particle sub-effect / collision-effect system (default on). Turn it off to
		/// fall back to 0.85 behaviour (no per-particle sub-effects) without a rebuild; the viewer sets it from
		/// --no-sub-effects and the env var CYS_FX_SUB_EFFECTS=0.
		static void setSubEffectsEnabled(bool on)	{	msSubEffectsEnabled = on;	}
		static bool getSubEffectsEnabled(void)		{	return msSubEffectsEnabled;	}

		virtual void sleep(void);
		
		virtual void active(void);

		virtual bool existVisualElements(void);

		virtual void shutdown(void);

        virtual void setColour( const Ogre::ColourValue& colour );

        /// 设置visible flag
        virtual void setVisibleFlag(uint32 flags);

        /// 设置特效的显示或隐藏
        virtual void setVisible(bool visible);

	protected:

		bool _createParticleSystem(void);
		void _destroyParticleSystem(void);

        /// 设置colour affector中的颜色
        void _setAffectorColour(void);

	protected:

		Ogre::ParticleSystem *mParticleSystem;

		bool mIsEmitterEnabled;

        /// 保存粒子系统中原来的颜色，可能是颜色影响器中的原颜色，也可能是粒子系统的颜色
        typedef std::map<String, Ogre::ColourValue> ColourMap;
        ColourMap mColourMap;

        /// 需要在update的时候更改颜色
        bool mNeedUpdateColour;
        /// 当前设置的颜色
        Ogre::ColourValue mCurrentColour;

		/// CYS: B sub-effects (ParticleElement+0x150): one ParEffectName effect per live particle
		struct ParticleEffectInfo
		{
			Ogre::Particle* mParticle;	///< NULL once the particle is gone
			Effect* mEffect;
			unsigned int mStamp;		///< update stamp of the last time the particle was seen alive
		};
		typedef std::list<ParticleEffectInfo> ParticleEffectList;
		typedef std::unordered_map<Ogre::Particle*, ParticleEffectList::iterator> ParticleEffectIndex;
		ParticleEffectList mParticleEffects;
		ParticleEffectIndex mParticleEffectIndex;	///< CYS: O(1) lookup instead of B's list scans
		unsigned int mParticleEffectStamp;

		/// CYS: B collision effects (ParticleElement+0x188): one ColEffectName effect per particle pool slot
		typedef std::unordered_map<Ogre::Particle*, Effect*> CollisionEffectMap;
		CollisionEffectMap mCollisionEffects;

		void _updateParticleEffects(void);		///< B FUN_180216c10 + FUN_180216e90
		void _updateCollisionEffects(void);		///< B FUN_180216800 (_updateColPsys)
		void _removeParticleEffects(void);		///< B FUN_180215e30
		void _removeCollisionEffects(void);		///< B FUN_180215ee0
		/// the system is attached to this element's node (B checks this before dropping the sub-effects)
		bool _isSystemAttached(void) const;

		/// CYS: sub-effect master switch, see setSubEffectsEnabled
		static bool msSubEffectsEnabled;

		////////////////////////////////////////////////////////////////
		static CmdParticleSystem msParticleSystemCmd;
	};
}

#endif