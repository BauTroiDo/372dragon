/*
CYS: UIParticle effect element (9 elements in client_GL all.effect).  B renders it through
ParticleSystemManager::createUiParticleSystem into the UI render queue; 0.85 has no such call, so this reuses the
normal ParticleElement (same keywords) and puts the particle system in the overlay render queue so it still shows
on top - Docs/specs/render/04-effects-particles.md.  A proper CEGUI-integrated UI particle needs the OGRE change
requested in the report.
*/
#ifndef __WXUIParticleElement_H__
#define __WXUIParticleElement_H__

#include "EffectSystem/WXParticleElement.h"
#include "EffectSystem/WXEffectElementFactory.h"

namespace WX {

    class UIParticleElement : public ParticleElement
    {
    public:
        UIParticleElement(System* system);

        virtual bool createRenderInstance(void);
    };

    //-----------------------------------------------------------------------
    class UIParticleElementFactory : public EffectElementFactory
    {
    public:
        virtual String getName() const { return "UIParticle"; }
        virtual EffectElement* createElement(System* system);
    };

}

#endif
