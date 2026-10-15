// CYS-HUD: Falagard/SuperBarButton + Falagard/TripperTooltip. See the header for the evidence from client_GL.
#include "FalagardSuperBarButton.h"
#include "FalagardAchievementWindow.h"
#include "CEGUIWindowManager.h"
#include "CEGUILogger.h"
#include "CEGUIExceptions.h"
#include "CEGUIScriptModule.h"
#include "CEGUIPropertyHelper.h"
#include "elements/CEGUIPushButton.h"
#include "elements/CEGUICheckbox.h"
#include "falagard/CEGUIFalWidgetLookManager.h"
#include "falagard/CEGUIFalWidgetLookFeel.h"
#include <cstdio>

namespace CEGUI
{
    namespace
    {
        class HoverProperty : public Property
        {
        public:
            HoverProperty() : Property("SuperBarButtonHover", "imagery section drawn while the mouse hovers the row.", "SuperBarHoverSection") {}
            String get(const PropertyReceiver* r) const { return static_cast<const FalagardSuperBarButton*>(r)->getHoverSection(); }
            void set(PropertyReceiver* r, const String& v) { static_cast<FalagardSuperBarButton*>(r)->setHoverSection(v); }
        };
        HoverProperty s_hover;
    }

    const utf8 FalagardSuperBarButton::WidgetTypeName[] = "Falagard/SuperBarButton";
    const String FalagardSuperBarButton::EventNamespace("SuperBarButton");
    const String FalagardSuperBarButton::EventItemClick("ItemClick");
    const String FalagardSuperBarButton::EventSubButtonClick("SubButtonClick");
    const utf8 FalagardTripperTooltip::WidgetTypeName[] = "Falagard/TripperTooltip";

    FalagardSuperBarButton::FalagardSuperBarButton(const String& type, const String& name) :
        Window(type, name), d_hoverSection("SuperBarHoverSection"), d_hovering(false), d_clicked(-1)
    {
        CEGUI_START_ADD_STATICPROPERTY(FalagardSuperBarButton)
            CEGUI_ADD_STATICPROPERTY(&s_hover);
        CEGUI_END_ADD_STATICPROPERTY
        addEvent(EventItemClick);
        addEvent(EventSubButtonClick);
    }

    FalagardSuperBarButton::~FalagardSuperBarButton() {}

    void FalagardSuperBarButton::initialise()
    {
        WindowManager& wm = WindowManager::getSingleton();
        char buf[48];
        for (int i = 1; i <= 7; ++i)
        {
            std::sprintf(buf, "__auto_SuperBarButton%d__", i);
            if (!wm.isWindowPresent(getName() + buf)) continue;
            Window* b = wm.getWindow(getName() + buf);
            d_buttons[b] = i;
            b->subscribeEvent(PushButton::EventClicked, Event::Subscriber(&FalagardSuperBarButton::handleSubButton, this));
        }
        if (wm.isWindowPresent(getName() + "__auto_SuperBarCheckButton1__"))
        {
            Window* c = wm.getWindow(getName() + "__auto_SuperBarCheckButton1__");
            d_buttons[c] = 0;
            c->subscribeEvent(Checkbox::EventCheckStateChanged, Event::Subscriber(&FalagardSuperBarButton::handleSubButton, this));
        }
    }

    bool FalagardSuperBarButton::handleSubButton(const EventArgs& e)
    {
        const Window* w = static_cast<const WindowEventArgs&>(e).window;
        std::map<const Window*, int>::const_iterator i = d_buttons.find(w);
        if (i == d_buttons.end()) return false;
        d_clicked = i->second;
        WindowEventArgs args(this);
        fireEvent(EventSubButtonClick, args, EventNamespace);
        // forward to the owning AchievementWindow (SweepAll.layout subscribes EventElementButtonNClick there)
        for (Window* p = getParent(); p; p = p->getParent())
        {
            if (!p->testClassName("FalagardAchievementWindow")) continue;
            char name[40];
            if (d_clicked == 0) std::sprintf(name, "EventElementCheckButton1Click");
            else std::sprintf(name, "EventElementButton%dClick", d_clicked);
            WindowEventArgs fwd(this);
            p->fireEvent(name, fwd, FalagardAchievementWindow::EventNamespace);
            break;
        }
        return true;
    }

    Window* FalagardSuperBarButton::GetChildItem(const String& suffix) const
    {
        WindowManager& wm = WindowManager::getSingleton();
        const String name = getName() + suffix;
        return wm.isWindowPresent(name) ? wm.getWindow(name) : 0;
    }

    bool FalagardSuperBarButton::SetChildItemEvent(const String& suffix, const String& event, const String& function)
    {
        Window* w = GetChildItem(suffix);
        if (!w) return false;
        w->subscribeEvent(event, ScriptFunctor(function));
        w->cysRecordScriptedEvent(event, function);
        return true;
    }

    void FalagardSuperBarButton::showChild(const char* suffix, bool show)
    {
        if (Window* w = GetChildItem(suffix)) w->setVisible(show);
    }

    void FalagardSuperBarButton::SetImageTe(const String& image)
    {
        Window* w = GetChildItem("__auto_SuperBarImage_Te__");
        if (!w) return;
        try { w->setProperty("Image", image); }
        catch (Exception&) { Logger::getSingleton().logEvent("SuperBarButton '" + getName() + "': image '" + image + "' ignored.", Errors); }
    }

    void FalagardSuperBarButton::SetButtonActive(int index, bool active)
    {
        char buf[48];
        std::sprintf(buf, "__auto_SuperBarButton%d__", index);
        if (Window* w = GetChildItem(buf)) w->setEnabled(active);
    }

    void FalagardSuperBarButton::SetButtonSelected(int index, bool selected)
    {
        char buf[48];
        std::sprintf(buf, "__auto_SuperBarButton%d__", index);
        if (Window* w = GetChildItem(buf))
        {
            try { w->setProperty("Selected", PropertyHelper::boolToString(selected)); }
            catch (Exception&) {}
        }
    }

    void FalagardSuperBarButton::populateRenderCache()
    {
        if (d_lookName.empty()) return;
        const WidgetLookFeel& wlf = WidgetLookManager::getSingleton().getWidgetLook(d_lookName);
        const char* state = isDisabled() ? "DisabledBackground" : "EnabledBackground";
        if (wlf.isStateImageryPresent(state)) wlf.getStateImagery(state).render(*this);
        else if (wlf.isStateImageryPresent(isDisabled() ? "Disabled" : "Enabled")) wlf.getStateImagery(isDisabled() ? "Disabled" : "Enabled").render(*this);
        if (d_hovering && !d_hoverSection.empty())
        {
            try { wlf.getImagerySection(d_hoverSection).render(*this, 0.0f); }
            catch (UnknownObjectException&) {}
        }
    }

    void FalagardSuperBarButton::onMouseEnters(MouseEventArgs& e)
    {
        Window::onMouseEnters(e);
        d_hovering = true;
        requestRedraw();
    }

    void FalagardSuperBarButton::onMouseLeaves(MouseEventArgs& e)
    {
        Window::onMouseLeaves(e);
        d_hovering = false;
        requestRedraw();
    }

    void FalagardSuperBarButton::onMouseButtonDown(MouseEventArgs& e)
    {
        Window::onMouseButtonDown(e);
        if (e.button == LeftButton)
        {
            WindowEventArgs args(this);
            fireEvent(EventItemClick, args, EventNamespace);
        }
    }

    //////////////////////////////////////////////////////////////////////////
    FalagardTripperTooltip::FalagardTripperTooltip(const String& type, const String& name) : FalagardTooltip(type, name) {}

    void FalagardTripperTooltip::setTripperText(uint id, const String& text)
    {
        d_lines[id] = text;
        refreshText();
    }

    void FalagardTripperTooltip::clearTripperText(uint id)
    {
        d_lines.erase(id);
        refreshText();
    }

    void FalagardTripperTooltip::refreshText()
    {
        String all;
        for (std::map<uint, String>::const_iterator i = d_lines.begin(); i != d_lines.end(); ++i)
        {
            if (!all.empty()) all += "\n";
            all += i->second;
        }
        setText(all);
    }
}
