#pragma once
// CYS-HUD: Falagard/PS (GL "particle system" window: an in-UI effect host; absent from 0.85).
// Evidence: client_GL CEGUIFalagard.dll exports FalagardParticleSystem::{WidgetTypeName = "Falagard/PS",
// setEffectName, getEffectName, getEffect, createEffect, autoCreateEffect, play, rePlay, setAuto, getAuto,
// d_EffectAuto, d_ParicleSystemProperty, onShown, onHidden, onParentShown, onParentHidden}; property strings
// "Effect" (effect name of EffectFolder, e.g. UI_CBT_2024) and "EffectAuto" (True: create/play when shown).
// GL Lua (UI_CEGUI.dll MetaTable_Control_Effect): playEffect, replayEffect. The window draws nothing itself: the
// game layer (UISystem/world) subscribes EffectShown/EffectHidden/EffectPlay and renders the named effect over the
// window rectangle - the same split as MeshWindow (MeshShown/MeshHidden).
#include "FalModule.h"
#include "CEGUIWindowFactory.h"

namespace CEGUI
{
    class FALAGARDBASE_API FalagardParticleSystem : public Window
    {
    public:
        static const utf8 WidgetTypeName[];
        static const String EventNamespace;
        static const String EventEffectShown;   //!< the window became visible and wants its effect created
        static const String EventEffectHidden;  //!< the window (or an ancestor) was hidden: destroy the effect
        static const String EventEffectPlay;    //!< play()/rePlay() requested (Lua playEffect/replayEffect)

        FalagardParticleSystem(const String& type, const String& name);
        ~FalagardParticleSystem();

        void setEffectName(const String& name);
        const String& getEffectName() const { return d_effectName; }
        void setAuto(bool value) { d_auto = value; }
        bool getAuto() const { return d_auto; }
        bool isPlaying() const { return d_playing; }

        void play();     //!< GL play: create the effect if needed and start it
        void rePlay();   //!< GL rePlay: restart from the beginning
        void stop();

    protected:
        virtual void onShown(WindowEventArgs& e);
        virtual void onHidden(WindowEventArgs& e);
        virtual void onParentHidden();
        virtual void onDestructionStarted(WindowEventArgs& e);
        virtual bool testClassName_impl(const String& class_name) const
        {
            if (class_name == (const utf8*)"FalagardParticleSystem") return true;
            return Window::testClassName_impl(class_name);
        }

        String d_effectName;
        bool d_auto;
        bool d_playing;
    };

    class FALAGARDBASE_API FalagardParticleSystemFactory : public WindowFactory
    {
    public:
        FalagardParticleSystemFactory() : WindowFactory(FalagardParticleSystem::WidgetTypeName) {}
        Window* createWindow(const String& name) { return new FalagardParticleSystem(d_type, name); }
        void destroyWindow(Window* window) { delete window; }
    };
}
