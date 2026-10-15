// CYS-HUD: Falagard/PS. See the header for the evidence from client_GL.
#include "FalagardParticleSystem.h"
#include "CEGUIPropertyHelper.h"
#include "CEGUILogger.h"

namespace CEGUI
{
    namespace
    {
        class EffectProperty : public Property
        {
        public:
            EffectProperty() : Property("Effect", "Property to get/set the effect (EffectFolder name) hosted by this window.", "") {}
            String get(const PropertyReceiver* r) const { return static_cast<const FalagardParticleSystem*>(r)->getEffectName(); }
            void set(PropertyReceiver* r, const String& v) { static_cast<FalagardParticleSystem*>(r)->setEffectName(v); }
        };
        class EffectAutoProperty : public Property
        {
        public:
            EffectAutoProperty() : Property("EffectAuto", "True: the effect is created and played whenever the window is shown.", "False") {}
            String get(const PropertyReceiver* r) const { return PropertyHelper::boolToString(static_cast<const FalagardParticleSystem*>(r)->getAuto()); }
            void set(PropertyReceiver* r, const String& v) { static_cast<FalagardParticleSystem*>(r)->setAuto(PropertyHelper::stringToBool(v)); }
        };
        EffectProperty s_effect;
        EffectAutoProperty s_effectAuto;
    }

    const utf8 FalagardParticleSystem::WidgetTypeName[] = "Falagard/PS";
    const String FalagardParticleSystem::EventNamespace("PS");
    const String FalagardParticleSystem::EventEffectShown("EffectShown");
    const String FalagardParticleSystem::EventEffectHidden("EffectHidden");
    const String FalagardParticleSystem::EventEffectPlay("EffectPlay");

    FalagardParticleSystem::FalagardParticleSystem(const String& type, const String& name) :
        Window(type, name), d_auto(false), d_playing(false)
    {
        CEGUI_START_ADD_STATICPROPERTY(FalagardParticleSystem)
            CEGUI_ADD_STATICPROPERTY(&s_effect);
            CEGUI_ADD_STATICPROPERTY(&s_effectAuto);
        CEGUI_END_ADD_STATICPROPERTY
        addEvent(EventEffectShown);
        addEvent(EventEffectHidden);
        addEvent(EventEffectPlay);
        // GL layouts always make PS windows mouse-transparent; keep that when a layout forgets it.
        setMouseHollow(true);
    }

    FalagardParticleSystem::~FalagardParticleSystem() {}

    void FalagardParticleSystem::setEffectName(const String& name)
    {
        if (d_effectName == name) return;
        const bool wasPlaying = d_playing;
        if (wasPlaying) stop();
        d_effectName = name;
        if (wasPlaying || (d_auto && isVisible())) play();
    }

    void FalagardParticleSystem::play()
    {
        if (d_effectName.empty()) return;
        d_playing = true;
        WindowEventArgs args(this);
        fireEvent(EventEffectShown, args, EventNamespace);
        fireEvent(EventEffectPlay, args, EventNamespace);
    }

    void FalagardParticleSystem::rePlay()
    {
        stop();
        play();
    }

    void FalagardParticleSystem::stop()
    {
        if (!d_playing) return;
        d_playing = false;
        WindowEventArgs args(this);
        fireEvent(EventEffectHidden, args, EventNamespace);
    }

    void FalagardParticleSystem::onShown(WindowEventArgs& e)
    {
        Window::onShown(e);
        if (d_auto) play();
    }

    void FalagardParticleSystem::onHidden(WindowEventArgs& e)
    {
        Window::onHidden(e);
        stop();
    }

    void FalagardParticleSystem::onParentHidden()
    {
        Window::onParentHidden();
        stop();
    }

    void FalagardParticleSystem::onDestructionStarted(WindowEventArgs& e)
    {
        stop();
        Window::onDestructionStarted(e);
    }
}
