#pragma once
// CYS-HUD: Falagard/SuperBarButton (GL "sweep" row of the achievement list: images, texts, a check button and up to
// seven sub buttons; absent from 0.85) and Falagard/TripperTooltip (GL tooltip with per-request text lines).
// Evidence: client_GL CEGUIFalagard.dll exports FalagardSuperBarButton::{SetButtonActive, SetButtonSelected,
// SetImageTe, SetImageTeShow, SetImageTeHide, GetChildItem, SetChildItemEvent, getHoverSection, setHoverSection,
// handleItemClickEvent, handleItemEntersEvent, handleItemLeavesEvent, onMouseEnters/Leaves/Move/ButtonDown,
// d_SuperBarButtonHoverProperty}; strings "SuperBarButtonHover", "__auto_SuperBarButton%d__" (1..7),
// "%s__auto_SuperBarButton%d__"; look TLBB_Look_SweepButton (children __auto_SuperBarImage1..3__, __auto_SuperBarImage_Te__,
// __auto_SuperBarText1..6__, __auto_SuperBarCheckButton1__, __auto_SuperBarButton1..7__, sections background/background_sp,
// SuperBarHoverSection/_Te, states Enabled/DisabledBackground). Sub-button clicks are forwarded to the owning
// AchievementWindow as EventElementButton%dClick / EventElementCheckButton1Click (the events SweepAll.layout subscribes).
// FalagardTripperTooltip::{setTripperText, clearTripperText, doActive/FadeIn/FadeOut/InactiveState, switchToInactiveState};
// strings "setTripperText Incoming:%u", "clearTripperText Incoming:%u"; look TLBB_GL_Tooltip = a FalagardTooltip look.
#include "FalModule.h"
#include "CEGUIWindowFactory.h"
#include "FalTooltip.h"
#include <map>

namespace CEGUI
{
    class FALAGARDBASE_API FalagardSuperBarButton : public Window
    {
    public:
        static const utf8 WidgetTypeName[];
        static const String EventNamespace;
        static const String EventItemClick;       //!< the row itself was clicked
        static const String EventSubButtonClick;  //!< a sub button was clicked (getClickedButton() = 1..7, 0 = check button)

        FalagardSuperBarButton(const String& type, const String& name);
        ~FalagardSuperBarButton();

        virtual void initialise();

        void SetButtonActive(int index, bool active);
        void SetButtonSelected(int index, bool selected);
        void SetImageTe(const String& image);
        void SetImageTeShow() { showChild("__auto_SuperBarImage_Te__", true); }
        void SetImageTeHide() { showChild("__auto_SuperBarImage_Te__", false); }
        Window* GetChildItem(const String& suffix) const; //!< e.g. "__auto_SuperBarText1__"
        bool SetChildItemEvent(const String& suffix, const String& event, const String& function);
        void setHoverSection(const String& section) { d_hoverSection = section; requestRedraw(); }
        const String& getHoverSection() const { return d_hoverSection; }
        int getClickedButton() const { return d_clicked; }
        bool isHovering() const { return d_hovering; }

    protected:
        virtual void populateRenderCache();
        virtual void onMouseEnters(MouseEventArgs& e);
        virtual void onMouseLeaves(MouseEventArgs& e);
        virtual void onMouseButtonDown(MouseEventArgs& e);
        virtual bool testClassName_impl(const String& class_name) const
        {
            if (class_name == (const utf8*)"FalagardSuperBarButton") return true;
            return Window::testClassName_impl(class_name);
        }
        void showChild(const char* suffix, bool show);
        bool handleSubButton(const EventArgs& e);

        String d_hoverSection;
        bool d_hovering;
        int d_clicked;
        std::map<const Window*, int> d_buttons;
    };

    class FALAGARDBASE_API FalagardTripperTooltip : public FalagardTooltip
    {
    public:
        static const utf8 WidgetTypeName[];
        FalagardTripperTooltip(const String& type, const String& name);
        void setTripperText(uint id, const String& text);
        void clearTripperText(uint id);
        void clearTripperTexts() { d_lines.clear(); refreshText(); }
        size_t getTripperCount() const { return d_lines.size(); }
    protected:
        virtual bool testClassName_impl(const String& class_name) const
        {
            if (class_name == (const utf8*)"FalagardTripperTooltip") return true;
            return FalagardTooltip::testClassName_impl(class_name);
        }
        void refreshText();
        std::map<uint, String> d_lines;
    };

    class FALAGARDBASE_API FalagardSuperBarButtonFactory : public WindowFactory
    {
    public:
        FalagardSuperBarButtonFactory() : WindowFactory(FalagardSuperBarButton::WidgetTypeName) {}
        Window* createWindow(const String& name) { return new FalagardSuperBarButton(d_type, name); }
        void destroyWindow(Window* window) { delete window; }
    };

    class FALAGARDBASE_API FalagardTripperTooltipFactory : public WindowFactory
    {
    public:
        FalagardTripperTooltipFactory() : WindowFactory(FalagardTripperTooltip::WidgetTypeName) {}
        Window* createWindow(const String& name) { return new FalagardTripperTooltip(d_type, name); }
        void destroyWindow(Window* window) { delete window; }
    };
}
