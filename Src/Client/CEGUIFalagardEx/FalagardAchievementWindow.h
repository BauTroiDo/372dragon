#pragma once
// CYS-HUD: Falagard/AchievementWindow (GL scrolling list of typed element windows; absent from 0.85).
// Evidence: client_GL CEGUIFalagard.dll exports FalagardAchievementWindow::{AddChildElement, ClearAllElement,
// DestroyAllElementsAchievement, UpdateAllElement, GetWindowSizeByType, getItemCount, getItemWindow,
// getWindowDataByIndex, SetElementsInView, PageEnd, Get/SetVertScrollbarPosition, SetVertScrollbarHide,
// configureScrollbars, performWindowLayout, updateItemPos, updateRenderRect, getClientRectArea, handleItemClickEvent,
// handleItemLClickEvent, handleItemRClickEvent, handleItemMouseEnter/Leave, handleScrollbarChange, onMouseWheel,
// onSized, setChildSize, EventElementClick/LClick/RClick/MouseEnter/MouseLeave}, look TLBB_Look_AchievementWindow
// ("ChildItem key:X name:WindowType" per element kind, a NamedArea per key = element size, children
// __auto_parent__ + __auto_vscrollbar__). GL Lua (UI_CEGUI.dll MetaTable_Control_AchievementWindow): CleanAllElement,
// GetVertScrollbarPosition, SetVertScrollbarPosition, SetVertScrollbarHide, SetElementsInView; layouts subscribe
// ElementLClick and EventElementCheckButton1Click / EventElementButton1..6Click.
#include "FalModule.h"
#include "CEGUIWindowFactory.h"
#include <vector>
#include <map>

namespace CEGUI
{
    class Scrollbar;

    class FALAGARDBASE_API FalagardAchievementWindow : public Window
    {
    public:
        static const utf8 WidgetTypeName[];
        static const String EventNamespace;
        static const String EventElementClick;
        static const String EventElementLClick;
        static const String EventElementRClick;
        static const String EventElementMouseEnter;
        static const String EventElementMouseLeave;

        FalagardAchievementWindow(const String& type, const String& name);
        ~FalagardAchievementWindow();

        virtual void initialise();

        // ---- GL API
        Window* AddChildElement(const String& key);        //!< creates the window type mapped by ChildItem key
        void ClearAllElement();
        size_t getItemCount() const { return d_items.size(); }
        Window* getItemWindow(size_t index) const { return index < d_items.size() ? d_items[index] : 0; }
        Size GetWindowSizeByType(const String& key) const;
        void SetElementsInView(size_t index);              //!< scroll so that the element is visible
        void PageEnd();
        float GetVertScrollbarPosition() const;
        void SetVertScrollbarPosition(float position);
        void SetVertScrollbarHide(bool hide);
        void addChildItem(const String& key, const String& windowType) { d_childTypes[key] = windowType; }
        String getChildItem(const String& key) const;
        Rect getClientRectArea() const;
        Window* getContainer() const { return d_container; }
        Scrollbar* getVertScrollbar() const { return d_vertScrollbar; }
        int getClickedElement() const { return d_clicked; }

    protected:
        virtual void populateRenderCache();
        virtual void onSized(WindowEventArgs& e);
        virtual void onMouseWheel(MouseEventArgs& e);
        virtual void onChildAdded(WindowEventArgs& e);
        virtual bool testClassName_impl(const String& class_name) const
        {
            if (class_name == (const utf8*)"FalagardAchievementWindow") return true;
            return Window::testClassName_impl(class_name);
        }
        // CYS-CYGUI: virtual so the CY grid windows (ActionButtonWindow, EventsWindow) can lay the elements out in
        // several columns; the scrollbar maths then uses contentHeight().
        virtual void configureScrollbars();
        virtual void performWindowLayout();
        virtual float contentHeight() const;
        bool handleScrollbarChange(const EventArgs& e);
        bool handleItemLClick(const EventArgs& e);
        bool handleItemRClick(const EventArgs& e);
        bool handleItemEnter(const EventArgs& e);
        bool handleItemLeave(const EventArgs& e);
        int indexOf(const Window* w) const;

        Window* d_container;
        Scrollbar* d_vertScrollbar;
        std::vector<Window*> d_items;
        std::map<String, String> d_childTypes;
        int d_clicked;
        int d_nextIndex;
        bool d_hideScrollbar;
        bool d_inLayout;
    };

    class FALAGARDBASE_API FalagardAchievementWindowFactory : public WindowFactory
    {
    public:
        FalagardAchievementWindowFactory() : WindowFactory(FalagardAchievementWindow::WidgetTypeName) {}
        Window* createWindow(const String& name) { return new FalagardAchievementWindow(d_type, name); }
        void destroyWindow(Window* window) { delete window; }
    };
}
