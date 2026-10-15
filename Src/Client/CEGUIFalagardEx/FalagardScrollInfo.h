#pragma once
// CYS-HUD: Falagard/ScrollInfo + Falagard/ScrollInfoFixed (GL top-of-screen notice marquee; absent from 0.85).
// Evidence: client_GL CEGUIFalagard.dll exports FalagardScrollInfo::{setWaitingInfo, setWaitingInfoFirst, ResetIt,
// hideAll, showAll, setLife, setInfoFont, setCoolDown, setMoveSpeed, setScrollTime, isUpdateRequire, updateSelf,
// populateRenderCache, d_lifeProperty, d_propertyCoolDown, d_propertyMoveSpeed, d_propertyScrollTime} and
// FalagardScrollInfoFixed::{setWaitingInfo, ResetIt, setCoolDown, setMoveSpeed, setScrollTime, ...}; property strings
// "CoolDown", "MoveSpeed", "ScrollTime", "Font" (window font), look TLBB_Look_ScrollInfo "ChildItem key:Child
// name:TLBB_ChatBoard" (B draws each notice through a ChatBoard child, "_ScrollInfo"/"ScrollInfo_" name parts).
// GL Lua (UI_CEGUI.dll): SetScrollInfo(text, ...), SetScrollInfoFixed(text, ...), ClearInfo.
// Semantics implemented: ScrollInfo moves each queued notice from the right edge to the left edge at MoveSpeed px/s,
// waits CoolDown seconds, then shows the next one; ScrollInfoFixed centres each notice for ScrollTime seconds
// (0 -> 3 s) with CoolDown between notices. Text uses the window Font and the TLBB colour markup of the string.
#include "FalModule.h"
#include "CEGUIWindowFactory.h"
#include <deque>

namespace CEGUI
{
    class FALAGARDBASE_API FalagardScrollInfo : public Window
    {
    public:
        static const utf8 WidgetTypeName[];
        static const String EventNamespace;
        static const String EventInfoShown;  //!< a queued notice started to show
        static const String EventQueueEmpty; //!< the last notice finished

        FalagardScrollInfo(const String& type, const String& name, bool fixed = false);
        ~FalagardScrollInfo();

        // ---- GL API
        void setWaitingInfo(const String& text);        //!< queue a notice
        void setWaitingInfoFirst(const String& text);   //!< queue a notice in front of the others
        void ResetIt();                                 //!< drop every notice (Lua ClearInfo)
        void hideAll() { d_hidden = true; requestRedraw(); }
        void showAll() { d_hidden = false; requestRedraw(); }
        void setLife(float seconds) { d_life = seconds; }
        void setInfoFont(const String& font);

        void setCoolDown(float seconds) { d_coolDown = seconds < 0 ? 0 : seconds; }
        float getCoolDown() const { return d_coolDown; }
        void setMoveSpeed(float pixelsPerSecond) { d_moveSpeed = pixelsPerSecond <= 0 ? 32.0f : pixelsPerSecond; }
        float getMoveSpeed() const { return d_moveSpeed; }
        void setScrollTime(float seconds) { d_scrollTime = seconds < 0 ? 0 : seconds; }
        float getScrollTime() const { return d_scrollTime; }
        bool isFixed() const { return d_fixed; }
        bool isUpdateRequire() const { return !d_queue.empty() || d_showing; }
        size_t getQueueSize() const { return d_queue.size(); }
        const String& getCurrentText() const { return d_current; }
        float getOffset() const { return d_offset; }

    protected:
        virtual void updateSelf(float elapsed);
        virtual void populateRenderCache();
        virtual bool testClassName_impl(const String& class_name) const
        {
            if (class_name == (const utf8*)(d_fixed ? "FalagardScrollInfoFixed" : "FalagardScrollInfo")) return true;
            return Window::testClassName_impl(class_name);
        }
        void next();

        bool d_fixed;
        bool d_hidden;
        bool d_showing;
        float d_coolDown, d_moveSpeed, d_scrollTime, d_life;
        float d_offset;      //!< x of the text (ScrollInfo) or elapsed time (ScrollInfoFixed)
        float d_cool;        //!< remaining cool-down seconds
        float d_textWidth;
        String d_current;
        std::deque<String> d_queue;
    };

    class FALAGARDBASE_API FalagardScrollInfoFixed : public FalagardScrollInfo
    {
    public:
        static const utf8 WidgetTypeName[];
        FalagardScrollInfoFixed(const String& type, const String& name) : FalagardScrollInfo(type, name, true) {}
    };

    class FALAGARDBASE_API FalagardScrollInfoFactory : public WindowFactory
    {
    public:
        FalagardScrollInfoFactory() : WindowFactory(FalagardScrollInfo::WidgetTypeName) {}
        Window* createWindow(const String& name) { return new FalagardScrollInfo(d_type, name); }
        void destroyWindow(Window* window) { delete window; }
    };

    class FALAGARDBASE_API FalagardScrollInfoFixedFactory : public WindowFactory
    {
    public:
        FalagardScrollInfoFixedFactory() : WindowFactory(FalagardScrollInfoFixed::WidgetTypeName) {}
        Window* createWindow(const String& name) { return new FalagardScrollInfoFixed(d_type, name); }
        void destroyWindow(Window* window) { delete window; }
    };
}
