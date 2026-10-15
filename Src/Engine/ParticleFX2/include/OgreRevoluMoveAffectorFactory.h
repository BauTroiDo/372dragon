/*
CYS: factory of the RevoluMove affector (Plugin_ParticleFX2).
*/
#ifndef __RevoluMoveAffectorFactory_H__
#define __RevoluMoveAffectorFactory_H__

#include "OgreParticleFX2Prerequisites.h"
#include "OgreParticleAffectorFactory.h"
#include "OgreRevoluMoveAffector.h"

namespace Ogre {

    class _OgreParticleFX2Export RevoluMoveAffectorFactory : public ParticleAffectorFactory
    {
        String getName() const { return "RevoluMove"; }

        ParticleAffector* createAffector(ParticleSystem* psys)
        {
            ParticleAffector* p = new RevoluMoveAffector(psys);
            mAffectors.push_back(p);
            return p;
        }
    };

}

#endif
