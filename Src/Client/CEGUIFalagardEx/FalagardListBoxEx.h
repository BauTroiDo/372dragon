#pragma once
// CYS-HUD: Falagard/ListBoxEx (GL text list with per-row buttons; absent from 0.85).
// Evidence: client_GL CEGUIFalagard.dll exports FalagardListBoxEx::{AddItemEx, AddItemExWithOutLayout, RemoveItemEx,
// ResetListEx, RequestLayOut, updateLayout, GetClickedButtonItem, SetVScrollbarAlpha, ShowButton, hideAllButtons,
// handleButtonClickedForEye/Close/Set, handle_scrollChange, onMouseMove, onMouseLeaves, Tick}; strings
// "ButtonClickedForEye", "ButtonClickedForClose", "ButtonClickedForSet", "__button__eye__%02d" (Falagard/Button +
// TLBB_Look_SingleTrackOpen), "__button__close__%02d" (TLBB_Look_SingleTrackClose), "__button__set__%02d"
// (TLBB_Look_FriendSet), "__image__portrait__%02d" (Falagard/StaticImage + TLBB_Look_StaticImage), and
// CListBoxExManager::{AddListBoxEx, RemovelistBoxEx, Tick}. GL Lua (UI_CEGUI.dll MetaTable_Control_ListBoxEx):
// AddItemEx, DelItemEx, AddItemExWithoutLayout(text, id, type, colour, align), AddFriendItemExWithoutLayout(..., face),
// ClearListBoxEx, RequestLayout, GetClickedButtonItem, SetVScrollbarAlpha, GetItemNumByMissionId; layouts subscribe
// ButtonClickedForSet/Sns/Sjsl, ItemSelectionByRButton, ItemSelectionChanged, MouseDoubleClick.
// The row-type -> button mapping is not recoverable from strings; the inference used here is documented in
// Docs/specs/ui/hud-widgets_vi.md (type 3 = track title: eye + close; type 4 = friend: set button; face -> portrait).
#include "FalListbox.h"
#include <vector>

namespace CEGUI
{
    class FALAGARDBASE_API FalagardListBoxEx : public FalagardListbox
    {
    public:
        static const utf8 WidgetTypeName[];
        static const String EventNamespace;
        static const String EventButtonClickedForEye;
        static const String EventButtonClickedForClose;
        static const String EventButtonClickedForSet;
        static const String EventButtonClickedForSns;
        static const String EventButtonClickedForSjsl;
        static const String EventItemSelectionByRButton;

        FalagardListBoxEx(const String& type, const String& name);
        ~FalagardListBoxEx();

        virtual void initialise();

        // ---- GL API
        // Adds a text row. type: 3 = title row with eye/close buttons, 4 = row with a set button (friend), else plain.
        ListboxItem* AddItemEx(const String& text, uint id, int type, const colour& col, int align, const String& face = "");
        ListboxItem* AddItemExWithOutLayout(const String& text, uint id, int type, const colour& col, int align, const String& face = "")
        { return AddItemEx(text, id, type, col, align, face); }
        void RemoveItemEx(ListboxItem* item);
        void ResetListEx();
        void RequestLayOut() { updateLayout(); }
        int GetClickedButtonItem() const { return d_clickedItem; }
        void SetVScrollbarAlpha(float alpha);
        void ShowButton(size_t row, bool show);
        void hideAllButtons();
        int GetItemNumByMissionId(uint id) const;
        void Tick(float elapsed) { (void)elapsed; }

    protected:
        struct RowExtra { int type; String face; };
        struct RowWidgets { Window* eye; Window* close; Window* set; Window* portrait; };

        virtual void onSized(WindowEventArgs& e);
        virtual void onMouseButtonDown(MouseEventArgs& e);
        virtual void onListContentsChanged(WindowEventArgs& e);
        virtual bool testClassName_impl(const String& class_name) const
        {
            if (class_name == (const utf8*)"FalagardListBoxEx") return true;
            return FalagardListbox::testClassName_impl(class_name);
        }

        void updateLayout();
        Window* makeRowWidget(const char* kind, size_t row, const String& windowType, const String& look);
        bool handleScroll(const EventArgs& e);
        bool handleEye(const EventArgs& e);
        bool handleClose(const EventArgs& e);
        bool handleSet(const EventArgs& e);
        int rowOfWidget(const Window* w) const;

        std::vector<RowExtra> d_extra;      //!< parallel to d_listItems
        std::vector<RowWidgets> d_widgets;  //!< parallel to d_listItems (windows may be 0)
        int d_clickedItem;
        bool d_layoutPending;
    };

    class FALAGARDBASE_API FalagardListBoxExFactory : public WindowFactory
    {
    public:
        FalagardListBoxExFactory() : WindowFactory(FalagardListBoxEx::WidgetTypeName) {}
        Window* createWindow(const String& name) { return new FalagardListBoxEx(d_type, name); }
        void destroyWindow(Window* window) { delete window; }
    };
}
