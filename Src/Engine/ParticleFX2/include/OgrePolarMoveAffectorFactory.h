/*
CYS: factory of the PolarMove affector (Plugin_ParticleFX2).
*/
#ifndef __PolarMoveAffectorFactory_H__
#define __PolarMoveAffectorFactory_H__

#include "OgreParticleFX2Prerequisites.h"
#include "OgreParticleAffectorFactory.h"
#include "OgrePolarMoveAffector.h"

namespace Ogre {

    class _OgreParticleFX2Export PolarMoveAffectorFactory : public ParticleAffectorFactory
    {
        String getName() const { return "PolarMove"; }

        ParticleAffector* createAffector(ParticleSystem* psys)
        {
            ParticleAffector* p = new PolarMoveAffector(psys);
            mAffectors.push_back(p);
            return p;
        }
    };

}

#endif
