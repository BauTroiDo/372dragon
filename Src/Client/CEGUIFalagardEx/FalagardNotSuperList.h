#pragma once
// CYS-HUD: Falagard/NotSuperList + Falagard/NotSuperListItem (GL widgets absent from 0.85).
// Evidence: client_GL CEGUIFalagard.dll exports FalagardNotSuperList::{AddChild, EraseChild, Clear, GetListSize,
// GetListItem, SetSelected, GetSelected, RefreshLayout, layoutChildItems, configureScrollbars, pushVirtualChildWindow,
// popVirtualChildWindow, createWindowR, handleItemLClickEvent, Get/SetVertScrollbarPosition, ...} and
// FalagardNotSuperListItem::{MapChildName, SetChildItemEvent, setSelected, setHoverSection, updateHoverState};
// property strings "SelectMode" (None/Single/Multi), "VScrollMode" (Hide/Show/Auto), "MultiColumn",
// "ChildrenHoverSection"/"DefaultHoverSection", child suffix "__auto_%d__", named areas ClientRect/ClientRectVScroll.
// GL Lua: list:AddChild("TemplateItemName") -> item; item:GetSubItem("OriginalChildName"); item:SetEvent(...).
// Model: the NotSuperListItem windows declared inside the list in the layout are TEMPLATES (kept hidden); AddChild
// clones a template (properties, scripted <Event> bindings, children) under "__auto_parent__" and stacks the clones
// in MultiColumn columns; "__auto_vscrollbar__" scrolls them. Unknown property values are logged, never thrown.
#include "FalModule.h"
#include "CEGUIWindowFactory.h"
#include <vector>

namespace CEGUI
{
    class Scrollbar;

    class FALAGARDBASE_API FalagardNotSuperListItem : public Window
    {
    public:
        static const utf8 WidgetTypeName[];
        static const String EventNamespace;
        static const String EventSelectChanged;

        FalagardNotSuperListItem(const String& type, const String& name);
        ~FalagardNotSuperListItem();

        void setSelected(bool selected);
        bool getSelected() const { return d_selected; }
        void setHoverSection(const String& section) { d_hoverSection = section; requestRedraw(); }
        const String& getHoverSection() const { return d_hoverSection; }
        void updateHoverState(bool hovering);
        bool isHovering() const { return d_hovering; }

        // Template bookkeeping (a template is the item authored in the layout; clones are made by the list).
        bool isTemplate() const { return d_template; }
        void setTemplate(bool value) { d_template = value; }
        const String& getSuffix() const { return d_suffix; }
        void setSuffix(const String& suffix) { d_suffix = suffix; }
        int getItemIndex() const { return d_index; }
        void setItemIndex(int index) { d_index = index; }

        // Original child name (as written in the layout) -> the name of this clone's child; "" when absent.
        String MapChildName(const String& original) const;
        // Bind a Lua handler on a sub item of this clone (GL: item:SetSubItemEvent(child, event, "fn()")).
        bool SetChildItemEvent(const String& original, const String& event, const String& function);

    protected:
        virtual void populateRenderCache();
        virtual void onMouseEnters(MouseEventArgs& e);
        virtual void onMouseLeaves(MouseEventArgs& e);
        virtual void onMouseButtonDown(MouseEventArgs& e);
        virtual void onSelectChanged(WindowEventArgs& e);
        virtual bool testClassName_impl(const String& class_name) const
        {
            if (class_name == (const utf8*)"FalagardNotSuperListItem") return true;
            return Window::testClassName_impl(class_name);
        }

        bool d_selected;
        bool d_hovering;
        bool d_template;
        int d_index;
        String d_suffix;
        String d_hoverSection;
    };

    class FALAGARDBASE_API FalagardNotSuperList : public Window
    {
    public:
        static const utf8 WidgetTypeName[];
        static const String EventNamespace;
        static const String EventElementLClick;   //!< a clone was left clicked (layouts: ElementLClick)
        static const String EventElementRClick;
        static const String EventElementClick;
        static const String EventClicked;         //!< layouts: Clicked
        static const String EventSelectionChanged;
        static const String EventListContentsChanged;

        enum SelectMode { SelectNone = 0, SelectSingle = 1, SelectMulti = 2 };
        enum VScrollMode { VScrollHide = 0, VScrollShow = 1, VScrollAuto = 2 };

        FalagardNotSuperList(const String& type, const String& name);
        ~FalagardNotSuperList();

        virtual void initialise();

        // ---- GL API
        Window* AddChild(const String& templateName);
        void EraseChild(Window* item);
        void Clear();
        size_t GetListSize() const { return d_items.size(); }
        Window* GetListItem(size_t index) const { return index < d_items.size() ? d_items[index] : 0; }
        void SetSelected(Window* item, bool selected);
        Window* GetSelected() const;
        void cleanSelect();
        void RefreshLayout() { layoutChildItems(); }
        float GetVertScrollbarPosition() const;
        void SetVertScrollbarPosition(float position);
        void SetVertScrollbarPosition4Index(size_t index);
        Window* GetChildHover() const { return d_hover; }
        void SetChildHover(Window* item);
        size_t getTemplateCount() const { return d_templates.size(); }
        Window* getTemplate(const String& name) const;

        // ---- properties
        void setSelectMode(SelectMode mode) { d_selectMode = mode; }
        SelectMode getSelectMode() const { return d_selectMode; }
        void setVScrollMode(VScrollMode mode) { d_vscrollMode = mode; configureScrollbars(); }
        VScrollMode getVScrollMode() const { return d_vscrollMode; }
        void setMultiColumn(int columns) { d_columns = columns < 1 ? 1 : columns; configureScrollbars(); }
        int getMultiColumn() const { return d_columns; }
        void setChildrenHoverSection(const String& section);
        const String& getChildrenHoverSection() const { return d_hoverSection; }

        Rect getClientRectArea() const;
        Scrollbar* getVertScrollbar() const { return d_vertScrollbar; }
        Window* getContainer() const { return d_container; }

    protected:
        virtual void populateRenderCache();
        virtual void onChildAdded(WindowEventArgs& e);
        virtual void onChildRemoved(WindowEventArgs& e);
        virtual void onSized(WindowEventArgs& e);
        virtual void onMouseWheel(MouseEventArgs& e);
        virtual bool testClassName_impl(const String& class_name) const
        {
            if (class_name == (const utf8*)"FalagardNotSuperList") return true;
            return Window::testClassName_impl(class_name);
        }

        void configureScrollbars();
        void layoutChildItems();
        bool handleScrollbarChange(const EventArgs& e);
        bool handleItemLClick(const EventArgs& e);
        bool handleItemRClick(const EventArgs& e);
        Window* cloneTree(const Window* source, const String& suffix, bool root);

        Window* d_container;        //!< __auto_parent__ (clones live here)
        Scrollbar* d_vertScrollbar; //!< __auto_vscrollbar__
        std::vector<Window*> d_templates;
        std::vector<Window*> d_items;
        Window* d_hover;
        SelectMode d_selectMode;
        VScrollMode d_vscrollMode;
        int d_columns;
        int d_nextIndex;
        bool d_inLayout;
        String d_hoverSection;
    };

    class FALAGARDBASE_API FalagardNotSuperListFactory : public WindowFactory
    {
    public:
        FalagardNotSuperListFactory() : WindowFactory(FalagardNotSuperList::WidgetTypeName) {}
        Window* createWindow(const String& name) { return new FalagardNotSuperList(d_type, name); }
        void destroyWindow(Window* window) { delete window; }
    };

    class FALAGARDBASE_API FalagardNotSuperListItemFactory : public WindowFactory
    {
    public:
        FalagardNotSuperListItemFactory() : WindowFactory(FalagardNotSuperListItem::WidgetTypeName) {}
        Window* createWindow(const String& name) { return new FalagardNotSuperListItem(d_type, name); }
        void destroyWindow(Window* window) { delete window; }
    };
}
