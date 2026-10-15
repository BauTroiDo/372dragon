// CYS-HUD: Falagard/ScrollInfo + Falagard/ScrollInfoFixed. See the header for the evidence from client_GL.
#include "FalagardScrollInfo.h"
#include "CEGUIPropertyHelper.h"
#include "CEGUILogger.h"
#include "CEGUIExceptions.h"
#include "CEGUIFontBase.h"
#include "CEGUIFontManager.h"
#include <cstdio>

namespace CEGUI
{
    namespace
    {
        String compact(float f) // "2", "1.5" - not the "%f" of PropertyHelper::floatToString
        {
            char buf[32];
            std::sprintf(buf, "%g", f);
            return String(buf);
        }
        float number(const String& v, float fallback)
        {
            float f = 0;
            if (std::sscanf(v.c_str(), "%f", &f) != 1)
            {
                Logger::getSingleton().logEvent("ScrollInfo: number expected, '" + v + "' ignored.", Errors);
                return fallback;
            }
            return f;
        }
        class CoolDownProperty : public Property
        {
        public:
            CoolDownProperty() : Property("CoolDown", "seconds between two notices.", "2") {}
            String get(const PropertyReceiver* r) const { return compact(static_cast<const FalagardScrollInfo*>(r)->getCoolDown()); }
            void set(PropertyReceiver* r, const String& v) { FalagardScrollInfo* w = static_cast<FalagardScrollInfo*>(r); w->setCoolDown(number(v, w->getCoolDown())); }
        };
        class MoveSpeedProperty : public Property
        {
        public:
            MoveSpeedProperty() : Property("MoveSpeed", "marquee speed in pixels per second.", "32") {}
            String get(const PropertyReceiver* r) const { return compact(static_cast<const FalagardScrollInfo*>(r)->getMoveSpeed()); }
            void set(PropertyReceiver* r, const String& v) { FalagardScrollInfo* w = static_cast<FalagardScrollInfo*>(r); w->setMoveSpeed(number(v, w->getMoveSpeed())); }
        };
        class ScrollTimeProperty : public Property
        {
        public:
            ScrollTimeProperty() : Property("ScrollTime", "seconds a fixed notice stays (0 = 3 s); pause of a marquee notice at the middle.", "1") {}
            String get(const PropertyReceiver* r) const { return compact(static_cast<const FalagardScrollInfo*>(r)->getScrollTime()); }
            void set(PropertyReceiver* r, const String& v) { FalagardScrollInfo* w = static_cast<FalagardScrollInfo*>(r); w->setScrollTime(number(v, w->getScrollTime())); }
        };
        CoolDownProperty s_coolDown;
        MoveSpeedProperty s_moveSpeed;
        ScrollTimeProperty s_scrollTime;
    }

    const utf8 FalagardScrollInfo::WidgetTypeName[] = "Falagard/ScrollInfo";
    const utf8 FalagardScrollInfoFixed::WidgetTypeName[] = "Falagard/ScrollInfoFixed";
    const String FalagardScrollInfo::EventNamespace("ScrollInfo");
    const String FalagardScrollInfo::EventInfoShown("InfoShown");
    const String FalagardScrollInfo::EventQueueEmpty("QueueEmpty");

    FalagardScrollInfo::FalagardScrollInfo(const String& type, const String& name, bool fixed) :
        Window(type, name), d_fixed(fixed), d_hidden(false), d_showing(false),
        d_coolDown(2.0f), d_moveSpeed(32.0f), d_scrollTime(1.0f), d_life(0.0f), d_offset(0.0f), d_cool(0.0f), d_textWidth(0.0f)
    {
        CEGUI_START_ADD_STATICPROPERTY(FalagardScrollInfo)
            CEGUI_ADD_STATICPROPERTY(&s_coolDown);
            CEGUI_ADD_STATICPROPERTY(&s_moveSpeed);
            CEGUI_ADD_STATICPROPERTY(&s_scrollTime);
        CEGUI_END_ADD_STATICPROPERTY
        addEvent(EventInfoShown);
        addEvent(EventQueueEmpty);
    }

    FalagardScrollInfo::~FalagardScrollInfo() {}

    void FalagardScrollInfo::setInfoFont(const String& font)
    {
        try { setFont(font); }
        catch (Exception&) { Logger::getSingleton().logEvent("ScrollInfo '" + getName() + "': font '" + font + "' not found.", Errors); }
    }

    void FalagardScrollInfo::setWaitingInfo(const String& text)
    {
        if (text.empty()) return;
        d_queue.push_back(text);
        if (!d_showing && d_cool <= 0) next();
    }

    void FalagardScrollInfo::setWaitingInfoFirst(const String& text)
    {
        if (text.empty()) return;
        d_queue.push_front(text);
        if (!d_showing && d_cool <= 0) next();
    }

    void FalagardScrollInfo::ResetIt()
    {
        d_queue.clear();
        d_current.clear();
        d_showing = false;
        d_cool = 0;
        requestRedraw();
    }

    void FalagardScrollInfo::next()
    {
        if (d_queue.empty())
        {
            if (d_showing)
            {
                d_showing = false;
                d_current.clear();
                WindowEventArgs args(this);
                fireEvent(EventQueueEmpty, args, EventNamespace);
            }
            requestRedraw();
            return;
        }
        d_current = d_queue.front();
        d_queue.pop_front();
        d_showing = true;
        const FontBase* font = getFont();
        d_textWidth = font ? font->getTextExtent(d_current) : 0.0f;
        d_offset = d_fixed ? 0.0f : getAbsoluteWidth();
        WindowEventArgs args(this);
        fireEvent(EventInfoShown, args, EventNamespace);
        requestRedraw();
    }

    void FalagardScrollInfo::updateSelf(float elapsed)
    {
        Window::updateSelf(elapsed);
        if (elapsed <= 0 || elapsed > 1.0f) elapsed = elapsed <= 0 ? 0.0f : 1.0f;
        if (d_cool > 0)
        {
            d_cool -= elapsed;
            if (d_cool <= 0) { d_cool = 0; next(); }
            return;
        }
        if (!d_showing) return;
        bool done;
        if (d_fixed)
        {
            d_offset += elapsed;
            done = d_offset >= (d_scrollTime > 0 ? d_scrollTime : 3.0f);
        }
        else
        {
            d_offset -= d_moveSpeed * elapsed;
            done = d_offset + d_textWidth <= 0;
            requestRedraw();
        }
        if (done)
        {
            d_showing = false;
            d_current.clear();
            d_cool = d_coolDown;
            if (d_cool <= 0) next(); else requestRedraw();
        }
    }

    void FalagardScrollInfo::populateRenderCache()
    {
        if (d_hidden || !d_showing || d_current.empty()) return;
        const FontBase* font = getFont();
        if (!font) return;
        const Size size = getAbsoluteSize();
        const Rect clip(Point(0, 0), size);
        const float h = font->getFontHeight();
        const float y = (size.d_height - h) * 0.5f;
        ColourRect cols(colour(1.0f, 1.0f, 1.0f, getEffectiveAlpha()));
        if (d_fixed)
            d_renderCache.cacheText(this, d_current, font, Centred, Rect(0, y, size.d_width, y + h), 0.0f, cols, &clip);
        else
            d_renderCache.cacheText(this, d_current, font, LeftAligned, Rect(d_offset, y, d_offset + d_textWidth + 1.0f, y + h), 0.0f, cols, &clip);
    }
}
