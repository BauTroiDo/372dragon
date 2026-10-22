


















#ifndef __WXDissolveAffector_H__
#define __WXDissolveAffector_H__

#include "WXFxParamHelpers.h"

#include <OgreParticleAffector.h>
#include <OgreParticleAffectorFactory.h>
#include <OgreMaterial.h>
#include <OgreGpuProgram.h>

namespace WX {

    class DissolveAffector : public Ogre::ParticleAffector
    {
    public:
        enum { NUM_STAGES = 6 };

        DissolveAffector(Ogre::ParticleSystem* psys);

        /** See ParticleAffector. */
        void _initParticle(Ogre::Particle* pParticle);
        /** See ParticleAffector. */
        void _affectParticles(Ogre::ParticleSystem* pSystem, Fx::Real timeElapsed);

        void _notifyParameterChanged(void) {}

    public:
        Fx::Real            mTimes[NUM_STAGES];
        Fx::Real            mClips[NUM_STAGES];
        Ogre::ColourValue   mColourA;
        Ogre::ColourValue   mColourB;
        Ogre::Vector4       mParams;
        Fx::Real2           mUVRepeat;
        Fx::Real            mSoftEdgeWidth;

        typedef Fx::ArrayElementCmd<DissolveAffector, Fx::RealCodec, NUM_STAGES, &DissolveAffector::mTimes> CmdTime;
        typedef Fx::ArrayElementCmd<DissolveAffector, Fx::RealCodec, NUM_STAGES, &DissolveAffector::mClips> CmdClip;
        typedef Fx::MemberCmd<DissolveAffector, Fx::ColourCodec, &DissolveAffector::mColourA> CmdColourA;
        typedef Fx::MemberCmd<DissolveAffector, Fx::ColourCodec, &DissolveAffector::mColourB> CmdColourB;
        typedef Fx::MemberCmd<DissolveAffector, Fx::Vector4Codec, &DissolveAffector::mParams> CmdParams;
        typedef Fx::MemberCmd<DissolveAffector, Fx::Real2Codec, &DissolveAffector::mUVRepeat> CmdUVRepeat;
        typedef Fx::MemberCmd<DissolveAffector, Fx::RealCodec, &DissolveAffector::mSoftEdgeWidth> CmdSoftEdgeWidth;

        static CmdTime          msTimeCmd[NUM_STAGES];
        static CmdClip          msClipCmd[NUM_STAGES];
        static CmdColourA       msColourACmd;
        static CmdColourB       msColourBCmd;
        static CmdParams        msParamsCmd;
        static CmdUVRepeat      msUVRepeatCmd;
        static CmdSoftEdgeWidth msSoftEdgeWidthCmd;

    protected:
        /// dissolve threshold of a particle at its current age
        Fx::Real _clipAt(const Ogre::Particle* p) const;
        /// writes the constants to every pass of the material that declares dissolveClip
        void _apply(const Ogre::MaterialPtr& material, Fx::Real clip) const;
        void _applyTo(const Ogre::GpuProgramParametersSharedPtr& params, Fx::Real clip) const;
    };

    //-----------------------------------------------------------------------
    class DissolveAffectorFactory : public Ogre::ParticleAffectorFactory
    {
    public:
        Ogre::String getName() const { return "Dissolve"; }
        Ogre::ParticleAffector* createAffector(Ogre::ParticleSystem* psys)
        {
            Ogre::ParticleAffector* p = new DissolveAffector(psys);
            mAffectors.push_back(p);
            return p;
        }
    };

}

#endif
