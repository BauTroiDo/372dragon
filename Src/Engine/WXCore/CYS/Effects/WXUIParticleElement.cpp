/*
CYS: UIParticle effect element - see WXUIParticleElement.h.
*/
#include "WXUIParticleElement.h"

#include <OgreParticleSystem.h>
#include <OgreRenderQueue.h>

namespace WX {

    //-----------------------------------------------------------------------
    UIParticleElement::UIParticleElement(System* system)
        : ParticleElement("UIParticle", system)
    {
    }
    //-----------------------------------------------------------------------
    bool UIParticleElement::createRenderInstance(void)
    {
        if (!ParticleElement::createRenderInstance())
            return false;

        // draw on top like a UI particle (B uses a dedicated UI particle system / render queue)
        if (mParticleSystem)
            mParticleSystem->setRenderQueueGroup(Ogre::RENDER_QUEUE_OVERLAY);
        return true;
    }
    //-----------------------------------------------------------------------
    EffectElement* UIParticleElementFactory::createElement(System* system)
    {
        EffectElement* element = new UIParticleElement(system);
        mElements.push_back(element);
        return element;
    }

}
