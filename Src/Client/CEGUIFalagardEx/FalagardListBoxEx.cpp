// CYS-HUD: Falagard/ListBoxEx. See the header for the evidence from client_GL.
#include "FalagardListBoxEx.h"
#include "CEGUIWindowManager.h"
#include "CEGUILogger.h"
#include "CEGUIExceptions.h"
#include "CEGUIPropertyHelper.h"
#include "elements/CEGUIScrollbar.h"
#include "elements/CEGUIListboxTextItem.h"
#include "elements/CEGUIPushButton.h"
#include "falagard/CEGUIFalWidgetLookManager.h"
#include <algorithm>
#include <cstdio>

namespace CEGUI
{
    const utf8 FalagardListBoxEx::WidgetTypeName[] = "Falagard/ListBoxEx";
    const String FalagardListBoxEx::EventNamespace("ListBoxEx");
    const String FalagardListBoxEx::EventButtonClickedForEye("ButtonClickedForEye");
    const String FalagardListBoxEx::EventButtonClickedForClose("ButtonClickedForClose");
    const String FalagardListBoxEx::EventButtonClickedForSet("ButtonClickedForSet");
    const String FalagardListBoxEx::EventButtonClickedForSns("ButtonClickedForSns");
    const String FalagardListBoxEx::EventButtonClickedForSjsl("ButtonClickedForSjsl");
    const String FalagardListBoxEx::EventItemSelectionByRButton("ItemSelectionByRButton");

    FalagardListBoxEx::FalagardListBoxEx(const String& type, const String& name) :
        FalagardListbox(type, name), d_clickedItem(-1), d_layoutPending(false)
    {
        addEvent(EventButtonClickedForEye);
        addEvent(EventButtonClickedForClose);
        addEvent(EventButtonClickedForSet);
        addEvent(EventButtonClickedForSns);
        addEvent(EventButtonClickedForSjsl);
        addEvent(EventItemSelectionByRButton);
    }

    FalagardListBoxEx::~FalagardListBoxEx() {}

    void FalagardListBoxEx::initialise()
    {
        FalagardListbox::initialise();
        if (d_vertScrollbar)
            d_vertScrollbar->subscribeEvent(Scrollbar::EventScrollPositionChanged, Event::Subscriber(&FalagardListBoxEx::handleScroll, this));
    }

    ListboxItem* FalagardListBoxEx::AddItemEx(const String& text, uint id, int type, const colour& col, int align, const String& face)
    {
        ListboxTextItem* item = new ListboxTextItem(text, id);
        item->setTextColours(col);
        item->setSelectionColours(colour(0xFFC8B88E));
        if (align >= LeftAligned && align <= WordWrapJustified)
            item->setHorzFomate(static_cast<TextFormatting>(align));
        RowExtra extra = { type, face };
        RowWidgets widgets = { 0, 0, 0, 0 };
        d_extra.push_back(extra);
        d_widgets.push_back(widgets);
        addItem(item); // Listbox owns and deletes the item (auto_delete)
        d_layoutPending = true;
        return item;
    }

    int FalagardListBoxEx::rowOfWidget(const Window* w) const
    {
        for (size_t i = 0; i < d_widgets.size(); ++i)
            if (d_widgets[i].eye == w || d_widgets[i].close == w || d_widgets[i].set == w || d_widgets[i].portrait == w)
                return static_cast<int>(i);
        return -1;
    }

    void FalagardListBoxEx::RemoveItemEx(ListboxItem* item)
    {
        const size_t index = getItemIndex(item);
        if (index >= d_widgets.size()) { removeItem(item); return; }
        WindowManager& wm = WindowManager::getSingleton();
        RowWidgets& w = d_widgets[index];
        Window* ws[] = { w.eye, w.close, w.set, w.portrait };
        for (int i = 0; i < 4; ++i) if (ws[i]) wm.destroyWindow(ws[i]);
        d_widgets.erase(d_widgets.begin() + index);
        d_extra.erase(d_extra.begin() + index);
        removeItem(item);
        d_layoutPending = true;
        updateLayout();
    }

    void FalagardListBoxEx::ResetListEx()
    {
        WindowManager& wm = WindowManager::getSingleton();
        for (size_t i = 0; i < d_widgets.size(); ++i)
        {
            Window* ws[] = { d_widgets[i].eye, d_widgets[i].close, d_widgets[i].set, d_widgets[i].portrait };
            for (int k = 0; k < 4; ++k) if (ws[k]) wm.destroyWindow(ws[k]);
        }
        d_widgets.clear();
        d_extra.clear();
        d_clickedItem = -1;
        resetList();
    }

    int FalagardListBoxEx::GetItemNumByMissionId(uint id) const
    {
        for (size_t i = 0; i < d_listItems.size(); ++i)
            if (d_listItems[i]->getID() == id) return static_cast<int>(i);
        return -1;
    }

    void FalagardListBoxEx::SetVScrollbarAlpha(float alpha)
    {
        if (d_vertScrollbar) d_vertScrollbar->setAlpha(alpha);
    }

    void FalagardListBoxEx::ShowButton(size_t row, bool show)
    {
        if (row >= d_widgets.size()) return;
        Window* ws[] = { d_widgets[row].eye, d_widgets[row].close, d_widgets[row].set };
        for (int k = 0; k < 3; ++k) if (ws[k]) ws[k]->setVisible(show);
    }

    void FalagardListBoxEx::hideAllButtons()
    {
        for (size_t i = 0; i < d_widgets.size(); ++i) ShowButton(i, false);
    }

    Window* FalagardListBoxEx::makeRowWidget(const char* kind, size_t row, const String& windowType, const String& look)
    {
        char buf[64];
        std::sprintf(buf, "__%s__%02u", kind, static_cast<unsigned>(row));
        const String name = getName() + buf;
        WindowManager& wm = WindowManager::getSingleton();
        if (wm.isWindowPresent(name)) return wm.getWindow(name);
        if (!WidgetLookManager::getSingleton().isWidgetLookAvailable(look)) return 0; // skin without this look: no button
        Window* w = 0;
        try
        {
            w = wm.createWindow(windowType, name);
            w->setLookNFeel(windowType, look);
            w->setDestroyedByParent(true);
            w->setAlwaysOnTop(true);
            addChildWindow(w);
        }
        catch (Exception& e)
        {
            Logger::getSingleton().logEvent("ListBoxEx '" + getName() + "': row widget " + name + " failed - " + e.getMessage(), Errors);
            if (w) wm.destroyWindow(w);
            return 0;
        }
        return w;
    }

    void FalagardListBoxEx::updateLayout()
    {
        d_layoutPending = false;
        // rows and row widgets stay in step even when Listbox::resetList was called behind our back
        while (d_extra.size() < d_listItems.size()) { RowExtra e = { 0, "" }; RowWidgets w = { 0, 0, 0, 0 }; d_extra.push_back(e); d_widgets.push_back(w); }
        while (d_extra.size() > d_listItems.size())
        {
            RowWidgets& w = d_widgets.back();
            Window* ws[] = { w.eye, w.close, w.set, w.portrait };
            for (int k = 0; k < 4; ++k) if (ws[k]) WindowManager::getSingleton().destroyWindow(ws[k]);
            d_widgets.pop_back(); d_extra.pop_back();
        }
        const Rect area = getListRenderArea();
        const float scroll = d_vertScrollbar ? d_vertScrollbar->getScrollPosition() : 0.0f;
        float y = area.d_top - scroll;
        for (size_t i = 0; i < d_listItems.size(); ++i)
        {
            const float h = d_listItems[i]->getPixelSize(this).d_height;
            const bool visibleRow = y + h > area.d_top && y < area.d_bottom;
            RowWidgets& w = d_widgets[i];
            const int type = d_extra[i].type;
            if (type == 3)
            {
                if (!w.eye) { w.eye = makeRowWidget("button__eye", i, "Falagard/Button", "TLBB_Look_SingleTrackOpen"); if (w.eye) w.eye->subscribeEvent(PushButton::EventClicked, Event::Subscriber(&FalagardListBoxEx::handleEye, this)); }
                if (!w.close) { w.close = makeRowWidget("button__close", i, "Falagard/Button", "TLBB_Look_SingleTrackClose"); if (w.close) w.close->subscribeEvent(PushButton::EventClicked, Event::Subscriber(&FalagardListBoxEx::handleClose, this)); }
            }
            else if (type == 4)
            {
                if (!w.set) { w.set = makeRowWidget("button__set", i, "Falagard/Button", "TLBB_Look_FriendSet"); if (w.set) w.set->subscribeEvent(PushButton::EventClicked, Event::Subscriber(&FalagardListBoxEx::handleSet, this)); }
            }
            if (!d_extra[i].face.empty() && !w.portrait)
            {
                w.portrait = makeRowWidget("image__portrait", i, "Falagard/StaticImage", "TLBB_Look_StaticImage");
                if (w.portrait)
                {
                    try { w.portrait->setProperty("Image", d_extra[i].face); }
                    catch (Exception&) { Logger::getSingleton().logEvent("ListBoxEx '" + getName() + "': portrait image '" + d_extra[i].face + "' ignored.", Errors); }
                }
            }
            const float size = std::max(8.0f, std::min(h, 20.0f));
            float right = area.d_right - 2.0f;
            Window* buttons[] = { w.close, w.eye, w.set };
            for (int k = 0; k < 3; ++k)
            {
                if (!buttons[k]) continue;
                right -= size + 2.0f;
                buttons[k]->setPosition(Absolute, Point(right, y + (h - size) * 0.5f));
                buttons[k]->setSize(Absolute, Size(size, size));
                buttons[k]->setVisible(visibleRow);
            }
            if (w.portrait)
            {
                w.portrait->setPosition(Absolute, Point(area.d_left + 1.0f, y + (h - size) * 0.5f));
                w.portrait->setSize(Absolute, Size(size, size));
                w.portrait->setVisible(visibleRow);
            }
            y += h;
        }
        requestRedraw();
    }

    bool FalagardListBoxEx::handleScroll(const EventArgs&) { updateLayout(); return true; }

    bool FalagardListBoxEx::handleEye(const EventArgs& e)
    {
        d_clickedItem = rowOfWidget(static_cast<const WindowEventArgs&>(e).window);
        WindowEventArgs args(this); fireEvent(EventButtonClickedForEye, args, EventNamespace); return true;
    }
    bool FalagardListBoxEx::handleClose(const EventArgs& e)
    {
        d_clickedItem = rowOfWidget(static_cast<const WindowEventArgs&>(e).window);
        WindowEventArgs args(this); fireEvent(EventButtonClickedForClose, args, EventNamespace); return true;
    }
    bool FalagardListBoxEx::handleSet(const EventArgs& e)
    {
        d_clickedItem = rowOfWidget(static_cast<const WindowEventArgs&>(e).window);
        WindowEventArgs args(this); fireEvent(EventButtonClickedForSet, args, EventNamespace); return true;
    }

    void FalagardListBoxEx::onListContentsChanged(WindowEventArgs& e)
    {
        FalagardListbox::onListContentsChanged(e);
        d_layoutPending = true;
        updateLayout();
    }

    void FalagardListBoxEx::onSized(WindowEventArgs& e)
    {
        FalagardListbox::onSized(e);
        updateLayout();
    }

    void FalagardListBoxEx::onMouseButtonDown(MouseEventArgs& e)
    {
        if (e.button == RightButton)
        {
            Point local(screenToWindowX(e.position.d_x), screenToWindowY(e.position.d_y));
            if (getMetricsMode() == Relative) local = relativeToAbsolute(local);
            ListboxItem* item = getItemAtPoint(local);
            if (item)
            {
                clearAllSelections();
                setItemSelectState(item, true);
                d_clickedItem = static_cast<int>(getItemIndex(item));
                WindowEventArgs args(this);
                fireEvent(EventItemSelectionByRButton, args, EventNamespace);
            }
        }
        FalagardListbox::onMouseButtonDown(e);
    }
}
