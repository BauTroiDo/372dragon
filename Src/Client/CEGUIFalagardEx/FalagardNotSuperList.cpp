// CYS-HUD: Falagard/NotSuperList + Falagard/NotSuperListItem. See the header for the evidence from client_GL.
#include "FalagardNotSuperList.h"
#include "CEGUIWindowManager.h"
#include "CEGUIWindowFactoryManager.h"
#include "CEGUIPropertyHelper.h"
#include "CEGUIExceptions.h"
#include "CEGUILogger.h"
#include "CEGUIScriptModule.h"
#include "elements/CEGUIScrollbar.h"
#include "falagard/CEGUIFalWidgetLookManager.h"
#include "falagard/CEGUIFalWidgetLookFeel.h"
#include <algorithm>
#include <cstdio>

namespace CEGUI
{
    //////////////////////////////////////////////////////////////////////////
    // properties
    namespace
    {
        class SelectModeProperty : public Property
        {
        public:
            SelectModeProperty() : Property("SelectMode", "child items select mode, include \"None\", \"Single\", \"Multi\"", "Single") {}
            String get(const PropertyReceiver* r) const
            {
                switch (static_cast<const FalagardNotSuperList*>(r)->getSelectMode())
                {
                case FalagardNotSuperList::SelectNone: return "None";
                case FalagardNotSuperList::SelectMulti: return "Multi";
                default: return "Single";
                }
            }
            void set(PropertyReceiver* r, const String& v)
            {
                FalagardNotSuperList* list = static_cast<FalagardNotSuperList*>(r);
                if (v == "None") list->setSelectMode(FalagardNotSuperList::SelectNone);
                else if (v == "Multi") list->setSelectMode(FalagardNotSuperList::SelectMulti);
                else if (v == "Single") list->setSelectMode(FalagardNotSuperList::SelectSingle);
                else Logger::getSingleton().logEvent("NotSuperList '" + list->getName() + "': unknown SelectMode '" + v + "' ignored.", Errors);
            }
        };
        class VScrollModeProperty : public Property
        {
        public:
            VScrollModeProperty() : Property("VScrollMode", "vertical scrollbar show mode, include \"Hide\", \"Show\", \"Auto\"", "Auto") {}
            String get(const PropertyReceiver* r) const
            {
                switch (static_cast<const FalagardNotSuperList*>(r)->getVScrollMode())
                {
                case FalagardNotSuperList::VScrollHide: return "Hide";
                case FalagardNotSuperList::VScrollShow: return "Show";
                default: return "Auto";
                }
            }
            void set(PropertyReceiver* r, const String& v)
            {
                FalagardNotSuperList* list = static_cast<FalagardNotSuperList*>(r);
                // GL layouts also write "" and "True" here; B accepts them silently (no error in its CEGUI.log).
                if (v == "Hide") list->setVScrollMode(FalagardNotSuperList::VScrollHide);
                else if (v == "Show" || v == "True") list->setVScrollMode(FalagardNotSuperList::VScrollShow);
                else list->setVScrollMode(FalagardNotSuperList::VScrollAuto);
            }
        };
        class MultiColumnProperty : public Property
        {
        public:
            MultiColumnProperty() : Property("MultiColumn", "number of columns the child items are laid out in (\"1\", \"3\", ...)", "1") {}
            String get(const PropertyReceiver* r) const { return PropertyHelper::intToString(static_cast<const FalagardNotSuperList*>(r)->getMultiColumn()); }
            void set(PropertyReceiver* r, const String& v)
            {
                int n = 0;
                if (std::sscanf(v.c_str(), "%d", &n) != 1 || n < 1)
                {
                    Logger::getSingleton().logEvent("NotSuperList: MultiColumn '" + v + "' ignored (expected a positive integer).", Errors);
                    return;
                }
                static_cast<FalagardNotSuperList*>(r)->setMultiColumn(n);
            }
        };
        class ChildrenHoverSectionProperty : public Property
        {
        public:
            ChildrenHoverSectionProperty() : Property("ChildrenHoverSection", "imagery section of the item look drawn while the mouse hovers an item or it is selected", "DefaultHoverSection") {}
            String get(const PropertyReceiver* r) const { return static_cast<const FalagardNotSuperList*>(r)->getChildrenHoverSection(); }
            void set(PropertyReceiver* r, const String& v) { static_cast<FalagardNotSuperList*>(r)->setChildrenHoverSection(v); }
        };
        class ItemSelectedProperty : public Property
        {
        public:
            ItemSelectedProperty() : Property("Selected", "whether this list item is selected.", "False") {}
            String get(const PropertyReceiver* r) const { return PropertyHelper::boolToString(static_cast<const FalagardNotSuperListItem*>(r)->getSelected()); }
            void set(PropertyReceiver* r, const String& v) { static_cast<FalagardNotSuperListItem*>(r)->setSelected(PropertyHelper::stringToBool(v)); }
        };
        class ItemHoverSectionProperty : public Property
        {
        public:
            ItemHoverSectionProperty() : Property("HoverSection", "imagery section drawn while hovering or selected.", "DefaultHoverSection") {}
            String get(const PropertyReceiver* r) const { return static_cast<const FalagardNotSuperListItem*>(r)->getHoverSection(); }
            void set(PropertyReceiver* r, const String& v) { static_cast<FalagardNotSuperListItem*>(r)->setHoverSection(v); }
        };
        SelectModeProperty s_selectMode;
        VScrollModeProperty s_vscrollMode;
        MultiColumnProperty s_multiColumn;
        ChildrenHoverSectionProperty s_childrenHoverSection;
        ItemSelectedProperty s_itemSelected;
        ItemHoverSectionProperty s_itemHoverSection;

        const char* const kAutoParent = "__auto_parent__";
        const char* const kAutoVScroll = "__auto_vscrollbar__";

        // Properties that only mirror the unified area (copied through UnifiedAreaRect) or must not be cloned.
        bool skipOnClone(const String& name)
        {
            static const char* const skip[] = {
                "Width", "RelativeWidth", "AbsoluteWidth", "Height", "RelativeHeight", "AbsoluteHeight",
                "Size", "RelativeSize", "AbsoluteSize", "XPosition", "RelativeXPosition", "AbsoluteXPosition",
                "YPosition", "RelativeYPosition", "AbsoluteYPosition", "Position", "RelativePosition", "AbsolutePosition",
                "Rect", "RelativeRect", "AbsoluteRect", "UnifiedPosition", "UnifiedXPosition", "UnifiedYPosition",
                "UnifiedSize", "UnifiedWidth", "UnifiedHeight", "MetricsMode", "TextOriginal", 0 };
            for (int i = 0; skip[i]; ++i)
                if (name == skip[i]) return true;
            return false;
        }
    }

    //////////////////////////////////////////////////////////////////////////
    // FalagardNotSuperListItem
    const utf8 FalagardNotSuperListItem::WidgetTypeName[] = "Falagard/NotSuperListItem";
    const String FalagardNotSuperListItem::EventNamespace("NotSuperListItem");
    const String FalagardNotSuperListItem::EventSelectChanged("SelectChanged");

    FalagardNotSuperListItem::FalagardNotSuperListItem(const String& type, const String& name) :
        Window(type, name), d_selected(false), d_hovering(false), d_template(false), d_index(-1),
        d_hoverSection("DefaultHoverSection")
    {
        CEGUI_START_ADD_STATICPROPERTY(FalagardNotSuperListItem)
            CEGUI_ADD_STATICPROPERTY(&s_itemSelected);
            CEGUI_ADD_STATICPROPERTY(&s_itemHoverSection);
        CEGUI_END_ADD_STATICPROPERTY
        addEvent(EventSelectChanged);
    }

    FalagardNotSuperListItem::~FalagardNotSuperListItem() {}

    void FalagardNotSuperListItem::setSelected(bool selected)
    {
        if (d_selected == selected) return;
        d_selected = selected;
        WindowEventArgs args(this);
        onSelectChanged(args);
        requestRedraw();
    }

    void FalagardNotSuperListItem::onSelectChanged(WindowEventArgs& e)
    {
        fireEvent(EventSelectChanged, e, EventNamespace);
    }

    void FalagardNotSuperListItem::updateHoverState(bool hovering)
    {
        if (d_hovering == hovering) return;
        d_hovering = hovering;
        requestRedraw();
    }

    String FalagardNotSuperListItem::MapChildName(const String& original) const
    {
        if (original.empty()) return original;
        const String mapped = original + d_suffix;
        WindowManager& wm = WindowManager::getSingleton();
        if (wm.isWindowPresent(mapped)) return mapped;
        if (d_suffix.empty() && wm.isWindowPresent(original)) return original; // a template asked about itself
        return String("");
    }

    bool FalagardNotSuperListItem::SetChildItemEvent(const String& original, const String& event, const String& function)
    {
        const String mapped = MapChildName(original);
        if (mapped.empty())
        {
            Logger::getSingleton().logEvent("NotSuperListItem '" + getName() + "': no sub item '" + original + "' for SetChildItemEvent.", Errors);
            return false;
        }
        Window* child = WindowManager::getSingleton().getWindow(mapped);
        child->subscribeEvent(event, ScriptFunctor(function));
        child->cysRecordScriptedEvent(event, function);
        return true;
    }

    void FalagardNotSuperListItem::populateRenderCache()
    {
        if (d_lookName.empty()) return;
        const WidgetLookFeel& wlf = WidgetLookManager::getSingleton().getWidgetLook(d_lookName);
        const char* state = isDisabled() ? "DisabledBackground" : "EnabledBackground";
        if (wlf.isStateImageryPresent(state))
            wlf.getStateImagery(state).render(*this);
        else if (wlf.isStateImageryPresent(isDisabled() ? "Disabled" : "Enabled"))
            wlf.getStateImagery(isDisabled() ? "Disabled" : "Enabled").render(*this);
        if ((d_hovering || d_selected) && !d_hoverSection.empty())
        {
            try
            {
                wlf.getImagerySection(d_hoverSection).render(*this, 0.0f);
            }
            catch (UnknownObjectException&)
            {
                // the look has no such section: nothing to highlight with (B stays silent as well)
            }
        }
    }

    void FalagardNotSuperListItem::onMouseEnters(MouseEventArgs& e)
    {
        Window::onMouseEnters(e);
        updateHoverState(true);
    }

    void FalagardNotSuperListItem::onMouseLeaves(MouseEventArgs& e)
    {
        Window::onMouseLeaves(e);
        updateHoverState(false);
    }

    void FalagardNotSuperListItem::onMouseButtonDown(MouseEventArgs& e)
    {
        Window::onMouseButtonDown(e);
    }

    //////////////////////////////////////////////////////////////////////////
    // FalagardNotSuperList
    const utf8 FalagardNotSuperList::WidgetTypeName[] = "Falagard/NotSuperList";
    const String FalagardNotSuperList::EventNamespace("NotSuperList");
    const String FalagardNotSuperList::EventElementLClick("ElementLClick");
    const String FalagardNotSuperList::EventElementRClick("ElementRClick");
    const String FalagardNotSuperList::EventElementClick("ElementClick");
    const String FalagardNotSuperList::EventClicked("Clicked");
    const String FalagardNotSuperList::EventSelectionChanged("ItemSelectionChanged");
    const String FalagardNotSuperList::EventListContentsChanged("ListContentsChanged");

    FalagardNotSuperList::FalagardNotSuperList(const String& type, const String& name) :
        Window(type, name), d_container(0), d_vertScrollbar(0), d_hover(0), d_selectMode(SelectSingle),
        d_vscrollMode(VScrollAuto), d_columns(1), d_nextIndex(0), d_inLayout(false), d_hoverSection("DefaultHoverSection")
    {
        CEGUI_START_ADD_STATICPROPERTY(FalagardNotSuperList)
            CEGUI_ADD_STATICPROPERTY(&s_selectMode);
            CEGUI_ADD_STATICPROPERTY(&s_vscrollMode);
            CEGUI_ADD_STATICPROPERTY(&s_multiColumn);
            CEGUI_ADD_STATICPROPERTY(&s_childrenHoverSection);
        CEGUI_END_ADD_STATICPROPERTY
        addEvent(EventElementLClick);
        addEvent(EventElementRClick);
        addEvent(EventElementClick);
        addEvent(EventClicked);
        addEvent(EventSelectionChanged);
        addEvent(EventListContentsChanged);
    }

    FalagardNotSuperList::~FalagardNotSuperList() {}

    void FalagardNotSuperList::initialise()
    {
        WindowManager& wm = WindowManager::getSingleton();
        if (!d_container && wm.isWindowPresent(getName() + kAutoParent))
        {
            d_container = wm.getWindow(getName() + kAutoParent);
            d_container->setClippedByParent(true);
        }
        if (!d_vertScrollbar && wm.isWindowPresent(getName() + kAutoVScroll))
        {
            d_vertScrollbar = static_cast<Scrollbar*>(wm.getWindow(getName() + kAutoVScroll));
            d_vertScrollbar->subscribeEvent(Scrollbar::EventScrollPositionChanged,
                Event::Subscriber(&FalagardNotSuperList::handleScrollbarChange, this));
            d_vertScrollbar->setAlwaysOnTop(true);
        }
        configureScrollbars();
    }

    Window* FalagardNotSuperList::getTemplate(const String& name) const
    {
        for (size_t i = 0; i < d_templates.size(); ++i)
            if (d_templates[i]->getName() == name) return d_templates[i];
        return 0;
    }

    void FalagardNotSuperList::onChildAdded(WindowEventArgs& e)
    {
        Window::onChildAdded(e);
        Window* child = e.window;
        if (!child) return;
        // the look may be assigned after initialise() (tests, setLookNFeel by hand): adopt the auto children here too
        if (!d_container && child->getName() == getName() + kAutoParent)
        {
            d_container = child;
            d_container->setClippedByParent(true);
            return;
        }
        if (!d_vertScrollbar && child->getName() == getName() + kAutoVScroll && child->testClassName("Scrollbar"))
        {
            d_vertScrollbar = static_cast<Scrollbar*>(child);
            d_vertScrollbar->subscribeEvent(Scrollbar::EventScrollPositionChanged, Event::Subscriber(&FalagardNotSuperList::handleScrollbarChange, this));
            d_vertScrollbar->setAlwaysOnTop(true);
            return;
        }
        if (!child->testClassName("FalagardNotSuperListItem")) return;
        FalagardNotSuperListItem* item = static_cast<FalagardNotSuperListItem*>(child);
        if (item->getItemIndex() >= 0) return; // one of our clones being re-parented
        // An item authored in the layout under this list is a template: kept, never drawn.
        item->setTemplate(true);
        item->setHoverSection(d_hoverSection);
        item->setVisible(false);
        if (std::find(d_templates.begin(), d_templates.end(), child) == d_templates.end())
            d_templates.push_back(child);
    }

    void FalagardNotSuperList::onChildRemoved(WindowEventArgs& e)
    {
        Window::onChildRemoved(e);
        std::vector<Window*>::iterator it = std::find(d_templates.begin(), d_templates.end(), e.window);
        if (it != d_templates.end()) d_templates.erase(it);
    }

    void FalagardNotSuperList::setChildrenHoverSection(const String& section)
    {
        d_hoverSection = section;
        for (size_t i = 0; i < d_templates.size(); ++i)
            static_cast<FalagardNotSuperListItem*>(d_templates[i])->setHoverSection(section);
        for (size_t i = 0; i < d_items.size(); ++i)
            static_cast<FalagardNotSuperListItem*>(d_items[i])->setHoverSection(section);
    }

    Window* FalagardNotSuperList::cloneTree(const Window* source, const String& suffix, bool root)
    {
        WindowManager& wm = WindowManager::getSingleton();
        Window* copy = wm.createWindow(source->getType(), source->getName() + suffix);
        // geometry first (the other properties may depend on the size, e.g. text formatting)
        try { copy->setProperty("UnifiedAreaRect", source->getProperty("UnifiedAreaRect")); } catch (Exception&) {}
        // Properties live in the WindowFactory (static set) and in the look's PropertyDefinitions (this CEGUI fork).
        std::vector<const PropertySet*> sets;
        WindowFactoryManager& wfm = WindowFactoryManager::getSingleton();
        sets.push_back(wfm.getFactory(source->getWidgetType()));
        if (wfm.isFalagardMappedType(source->getType()))
            sets.push_back(&WidgetLookManager::getSingleton().getWidgetLook(wfm.getMappedLookForType(source->getType())));
        for (size_t s = 0; s < sets.size(); ++s)
        {
            PropertySet::PropertyIterator it(sets[s]->getIterator());
            for (; !it.isAtEnd(); ++it)
            {
                const String& name = it.getCurrentKey();
                if (name == "UnifiedAreaRect" || skipOnClone(name)) continue;
                if (root && (name == "Visible" || name == "Selected")) continue;
                try
                {
                    const String value = source->getProperty(name);
                    if (value == copy->getPropertyDefault(name)) continue;
                    copy->setProperty(name, value);
                }
                catch (Exception&)
                {
                    // read-only or unsupported on the copy: the layout loader would have logged it already
                }
            }
        }
        const Window::CysScriptedEventList& events = source->cysScriptedEvents();
        for (size_t i = 0; i < events.size(); ++i)
        {
            try
            {
                copy->subscribeEvent(events[i].first, ScriptFunctor(events[i].second));
                copy->cysRecordScriptedEvent(events[i].first, events[i].second);
            }
            catch (Exception&) {}
        }
        copy->setUserData(source->getUserData());
        copy->setDestroyedByParent(true);
        const String autoPrefix = source->getName() + "__auto_";
        for (uint i = 0; i < source->getChildCount(); ++i)
        {
            const Window* child = source->getChildAtIdx(i);
            if (child->getName().compare(0, autoPrefix.length(), autoPrefix) == 0) continue; // made by the look
            copy->addChildWindow(cloneTree(child, suffix, false));
        }
        return copy;
    }

    Window* FalagardNotSuperList::AddChild(const String& templateName)
    {
        Window* tpl = getTemplate(templateName);
        if (!tpl)
        {
            Logger::getSingleton().logEvent("NotSuperList '" + getName() + "': AddChild - no template item '" + templateName + "'.", Errors);
            return 0;
        }
        WindowManager& wm = WindowManager::getSingleton();
        char buf[32];
        String suffix;
        do
        {
            std::sprintf(buf, "__auto_%d__", d_nextIndex++);
            suffix = buf;
        } while (wm.isWindowPresent(templateName + suffix));
        Window* copy = 0;
        try
        {
            copy = cloneTree(tpl, suffix, true);
        }
        catch (Exception& e)
        {
            Logger::getSingleton().logEvent("NotSuperList '" + getName() + "': AddChild failed - " + e.getMessage(), Errors);
            return 0;
        }
        FalagardNotSuperListItem* item = static_cast<FalagardNotSuperListItem*>(copy);
        item->setTemplate(false);
        item->setSuffix(suffix);
        item->setItemIndex(d_nextIndex - 1);
        item->setHoverSection(d_hoverSection);
        item->setVisible(true);
        item->subscribeEvent(Window::EventMouseLClick, Event::Subscriber(&FalagardNotSuperList::handleItemLClick, this));
        item->subscribeEvent(Window::EventMouseRClick, Event::Subscriber(&FalagardNotSuperList::handleItemRClick, this));
        (d_container ? d_container : this)->addChildWindow(item);
        d_items.push_back(item);
        configureScrollbars();
        WindowEventArgs args(this);
        fireEvent(EventListContentsChanged, args, EventNamespace);
        return item;
    }

    void FalagardNotSuperList::EraseChild(Window* item)
    {
        std::vector<Window*>::iterator it = std::find(d_items.begin(), d_items.end(), item);
        if (it == d_items.end()) return;
        d_items.erase(it);
        if (d_hover == item) d_hover = 0;
        WindowManager::getSingleton().destroyWindow(item);
        configureScrollbars();
        WindowEventArgs args(this);
        fireEvent(EventListContentsChanged, args, EventNamespace);
    }

    void FalagardNotSuperList::Clear()
    {
        std::vector<Window*> items;
        items.swap(d_items);
        d_hover = 0;
        for (size_t i = 0; i < items.size(); ++i)
            WindowManager::getSingleton().destroyWindow(items[i]);
        d_nextIndex = 0; // names restart from __auto_0__ like B (the Lua control cache relies on it)
        if (d_vertScrollbar) d_vertScrollbar->setScrollPosition(0);
        configureScrollbars();
        WindowEventArgs args(this);
        fireEvent(EventListContentsChanged, args, EventNamespace);
    }

    void FalagardNotSuperList::SetSelected(Window* item, bool selected)
    {
        if (!item || !item->testClassName("FalagardNotSuperListItem")) return;
        if (d_selectMode == SelectNone) return;
        if (selected && d_selectMode == SelectSingle) cleanSelect();
        static_cast<FalagardNotSuperListItem*>(item)->setSelected(selected);
        WindowEventArgs args(item);
        fireEvent(EventSelectionChanged, args, EventNamespace);
    }

    Window* FalagardNotSuperList::GetSelected() const
    {
        for (size_t i = 0; i < d_items.size(); ++i)
            if (static_cast<FalagardNotSuperListItem*>(d_items[i])->getSelected()) return d_items[i];
        return 0;
    }

    void FalagardNotSuperList::cleanSelect()
    {
        for (size_t i = 0; i < d_items.size(); ++i)
            static_cast<FalagardNotSuperListItem*>(d_items[i])->setSelected(false);
    }

    void FalagardNotSuperList::SetChildHover(Window* item)
    {
        if (d_hover && d_hover != item) static_cast<FalagardNotSuperListItem*>(d_hover)->updateHoverState(false);
        d_hover = item;
        if (d_hover) static_cast<FalagardNotSuperListItem*>(d_hover)->updateHoverState(true);
    }

    bool FalagardNotSuperList::handleItemLClick(const EventArgs& e)
    {
        Window* item = static_cast<const WindowEventArgs&>(e).window;
        if (d_selectMode != SelectNone)
        {
            bool now = d_selectMode == SelectMulti ? !static_cast<FalagardNotSuperListItem*>(item)->getSelected() : true;
            SetSelected(item, now);
        }
        WindowEventArgs args(item);
        fireEvent(EventElementLClick, args, EventNamespace);
        fireEvent(EventElementClick, args, EventNamespace);
        fireEvent(EventClicked, args, EventNamespace);
        return true;
    }

    bool FalagardNotSuperList::handleItemRClick(const EventArgs& e)
    {
        WindowEventArgs args(static_cast<const WindowEventArgs&>(e).window);
        fireEvent(EventElementRClick, args, EventNamespace);
        fireEvent(EventElementClick, args, EventNamespace);
        return true;
    }

    Rect FalagardNotSuperList::getClientRectArea() const
    {
        if (!d_lookName.empty())
        {
            const WidgetLookFeel& wlf = WidgetLookManager::getSingleton().getWidgetLook(d_lookName);
            const bool scroll = d_vertScrollbar && d_vertScrollbar->isVisible();
            if (scroll && wlf.isNamedAreaDefined("ClientRectVScroll"))
                return wlf.getNamedArea("ClientRectVScroll").getArea().getPixelRect(*this);
            if (wlf.isNamedAreaDefined("ClientRect"))
                return wlf.getNamedArea("ClientRect").getArea().getPixelRect(*this);
        }
        Rect r(Point(0, 0), getAbsoluteSize());
        if (d_vertScrollbar && d_vertScrollbar->isVisible()) r.d_right -= d_vertScrollbar->getAbsoluteWidth();
        return r;
    }

    void FalagardNotSuperList::configureScrollbars()
    {
        if (!d_vertScrollbar) { layoutChildItems(); return; }
        // total content height with the scrollbar hidden first (Auto mode decides on it)
        float content = 0;
        {
            const Rect client = getClientRectArea();
            const float colWidth = client.getWidth() / d_columns;
            float rowHeight = 0, y = 0; int col = 0;
            (void)colWidth;
            for (size_t i = 0; i < d_items.size(); ++i)
            {
                rowHeight = std::max(rowHeight, d_items[i]->getAbsoluteHeight());
                if (++col >= d_columns) { y += rowHeight; rowHeight = 0; col = 0; }
            }
            content = y + rowHeight;
        }
        const float page = getAbsoluteHeight();
        bool show = d_vscrollMode == VScrollShow || (d_vscrollMode == VScrollAuto && content > page + 0.5f);
        d_vertScrollbar->setVisible(show);
        d_vertScrollbar->setDocumentSize(content);
        d_vertScrollbar->setPageSize(page);
        d_vertScrollbar->setStepSize(std::max(1.0f, page / 10.0f));
        d_vertScrollbar->setScrollPosition(d_vertScrollbar->getScrollPosition());
        layoutChildItems();
    }

    void FalagardNotSuperList::layoutChildItems()
    {
        if (d_inLayout) return;
        d_inLayout = true;
        const Rect client = getClientRectArea();
        if (d_container)
        {
            d_container->setPosition(Absolute, Point(client.d_left, client.d_top));
            d_container->setSize(Absolute, Size(std::max(1.0f, client.getWidth()), std::max(1.0f, client.getHeight())));
        }
        const float colWidth = client.getWidth() / d_columns;
        const float scroll = d_vertScrollbar ? d_vertScrollbar->getScrollPosition() : 0.0f;
        float rowHeight = 0, y = 0; int col = 0;
        for (size_t i = 0; i < d_items.size(); ++i)
        {
            Window* item = d_items[i];
            const float x = col * colWidth + (d_container ? 0.0f : client.d_left);
            item->setPosition(Absolute, Point(x, y - scroll + (d_container ? 0.0f : client.d_top)));
            rowHeight = std::max(rowHeight, item->getAbsoluteHeight());
            if (++col >= d_columns) { y += rowHeight; rowHeight = 0; col = 0; }
        }
        d_inLayout = false;
        requestRedraw();
    }

    bool FalagardNotSuperList::handleScrollbarChange(const EventArgs&)
    {
        layoutChildItems();
        return true;
    }

    float FalagardNotSuperList::GetVertScrollbarPosition() const
    {
        return d_vertScrollbar ? d_vertScrollbar->getScrollPosition() : 0.0f;
    }

    void FalagardNotSuperList::SetVertScrollbarPosition(float position)
    {
        if (d_vertScrollbar) d_vertScrollbar->setScrollPosition(position);
    }

    void FalagardNotSuperList::SetVertScrollbarPosition4Index(size_t index)
    {
        if (!d_vertScrollbar || index >= d_items.size()) return;
        float rowHeight = 0, y = 0; int col = 0;
        for (size_t i = 0; i < d_items.size(); ++i)
        {
            if (i == index) break;
            rowHeight = std::max(rowHeight, d_items[i]->getAbsoluteHeight());
            if (++col >= d_columns) { y += rowHeight; rowHeight = 0; col = 0; }
        }
        d_vertScrollbar->setScrollPosition(y);
    }

    void FalagardNotSuperList::populateRenderCache()
    {
        if (d_lookName.empty()) return;
        const WidgetLookFeel& wlf = WidgetLookManager::getSingleton().getWidgetLook(d_lookName);
        const char* state = isDisabled() ? "DisabledBackground" : "EnabledBackground";
        if (wlf.isStateImageryPresent(state))
            wlf.getStateImagery(state).render(*this);
    }

    void FalagardNotSuperList::onSized(WindowEventArgs& e)
    {
        Window::onSized(e);
        configureScrollbars();
    }

    void FalagardNotSuperList::onMouseWheel(MouseEventArgs& e)
    {
        Window::onMouseWheel(e);
        if (d_vertScrollbar && d_vertScrollbar->isVisible())
        {
            d_vertScrollbar->setScrollPosition(d_vertScrollbar->getScrollPosition() - d_vertScrollbar->getStepSize() * e.wheelChange);
            e.handled = true;
        }
    }
}
