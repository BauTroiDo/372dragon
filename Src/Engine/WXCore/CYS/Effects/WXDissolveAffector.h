/*
CYS: Dissolve affector - animates the dissolve threshold of the particle material over the particle life
(362 blocks in client_GL all.particle, all of them on mesh renderers).  Clean-room implementation of the
behaviour of B Render.dll (FairyDissolveAffector, ctor 0x180129440) - Docs/specs/render/04-effects-particles.md.

Keywords (lower case):
  time0..time5     stage times in normalised particle age        default 0 1 1 1 1 1
  clip0..clip5     dissolve threshold at each stage              default 0 1 1 1 1 1
  colora, colorb   edge colours "r g b a"                        default 0 0 0 1 / 1 1 1 1
  params           four shader parameters                        default 0.02 0.005 0.02 0.01
  uv_repeat        noise repeat "u v"                            default 1 1
  soft_edge_width                                                default 0
Per particle: t <= time0 -> clip0, t >= time5 -> clip5, otherwise linear inside the first stage containing t.
The values go to the program constants dissolveClip, dissolveColorA, dissolveColorB, dissolveParams,
dissolveUVRepeat, dissolveSoftEdgeWidth (and dissolveBox = 0 when a program declares it) of every pass whose
programs declare dissolveClip.  Mesh particles own one cloned material each (per particle value); billboard
renderers share one material, so the last particle's value wins as in B.  Programs without the constants are
left untouched (the particle then renders without dissolve).
*/
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
