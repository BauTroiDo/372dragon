/************************************************************************
    filename:   FalButton.cpp
    created:    Wed Jun 22 2005
    author:     Paul D Turner <paul@cegui.org.uk>
*************************************************************************/
/*************************************************************************
    Crazy Eddie's GUI System (http://www.cegui.org.uk)
    Copyright (C)2004 - 2005 Paul D Turner (paul@cegui.org.uk)
 
    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.
 
    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.
 
    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*************************************************************************/
#include "FalButton.h"
#include "CEGUIAnimate.h"
#include "CEGUIAnimateManager.h"
#include "CEGUIPropertyHelper.h"
#include "CEGUISystem.h"
#include "falagard/CEGUIFalWidgetLookManager.h"
#include "falagard/CEGUIFalWidgetLookFeel.h"

// Start of CEGUI namespace section
namespace CEGUI
{
    namespace {
        class BtnAnimationProperty : public Property {
        public:
            BtnAnimationProperty() : Property("BtnAnimation","Animation resource for the button overlay.","") {}
            String get(const PropertyReceiver* r) const { return static_cast<const FalagardButton*>(r)->getBtnAnimation(); }
            void set(PropertyReceiver* r,const String& v) { static_cast<FalagardButton*>(r)->setBtnAnimation(v); }
        } btnAnimationProperty;
        class EnableAnimationProperty : public Property {
        public:
            EnableAnimationProperty() : Property("EnableAnimation","Start or stop the button animation overlay.","False") {}
            String get(const PropertyReceiver* r) const { return PropertyHelper::boolToString(static_cast<const FalagardButton*>(r)->isAnimateEnabled()); }
            void set(PropertyReceiver* r,const String& v) { static_cast<FalagardButton*>(r)->enableAnimate(PropertyHelper::stringToBool(v)); }
        } enableAnimationProperty;
        class FlashProperty : public Property {
        public:
            FlashProperty() : Property("Flash","Pulse button alpha while nonzero.","0") {}
            String get(const PropertyReceiver* r) const { return PropertyHelper::intToString(static_cast<const FalagardButton*>(r)->getFlash()); }
            void set(PropertyReceiver* r,const String& v) { static_cast<FalagardButton*>(r)->setFlash(PropertyHelper::stringToInt(v)); }
        } flashProperty;
    }
    const utf8 FalagardButton::WidgetTypeName[] = "Falagard/Button";

    FalagardButton::FalagardButton(const String& type, const String& name) :
        PushButton(type, name), d_btnAnimation(0), d_btnAnimationFrame(0),
        d_btnAnimationStart(0), d_btnAnimationAlpha(1), d_btnAnimationEnabled(false),
        d_flashMode(0), d_flashElapsed(0), d_flashIncreasing(false)
    {
        CEGUI_START_ADD_STATICPROPERTY(FalagardButton)
            CEGUI_ADD_STATICPROPERTY(&btnAnimationProperty);
            CEGUI_ADD_STATICPROPERTY(&enableAnimationProperty);
            CEGUI_ADD_STATICPROPERTY(&flashProperty);
        CEGUI_END_ADD_STATICPROPERTY
    }

    FalagardButton::~FalagardButton()
    {
    }

    void FalagardButton::setBtnAnimation(const String& name)
    {
        AnimateManager* manager=AnimateManager::getSingletonPtr();
        // B preserves the old resource if the manager or name is unavailable.
        if (!manager || !manager->isAnimatePresent(name)) return;
        d_btnAnimation=const_cast<Animate*>(manager->getAnimate(name));
        d_btnAnimationStart=0;
        d_btnAnimationFrame=d_btnAnimation->getFrame(0);
        d_btnAnimationAlpha=1;
        requestRedraw();
    }
    String FalagardButton::getBtnAnimation() const
    {
        return d_btnAnimation ? d_btnAnimation->getName() : String("");
    }
    void FalagardButton::enableAnimate(bool enabled)
    {
        enabled=enabled && d_btnAnimation;
        if (enabled==d_btnAnimationEnabled) return;
        d_btnAnimationEnabled=enabled;
        d_btnAnimationStart=int(System::getSingleton().getCurTimeElapsed()*1000.0f);
        d_btnAnimationFrame=enabled ? d_btnAnimation->getFrame(0,-1) : 0;
        d_btnAnimationAlpha=enabled ? d_btnAnimation->getFrameAlpha(0,-1) : 1;
        requestRedraw();
    }
    void FalagardButton::updateSelf(float elapsed)
    {
        Window::updateSelf(elapsed);
        if (!isVisible()) return;
        // B +0x3540: animation takes precedence and pauses the flash phase.
        if (d_btnAnimation && d_btnAnimationEnabled)
        {
            const int time=int(System::getSingleton().getCurTimeElapsed()*1000.0f)-d_btnAnimationStart;
            // CYS-PERF-FIX btnalpha: requestRedraw() and setAlpha() rebuild the whole GUI in CEGUI 0.4 even when
            // nothing changed, and updateSelf ran them every frame for every visible button (setAlpha(1) below).
            // Same values, applied only when they change.
            const Image* cysFrame=d_btnAnimation->getFrame(time,-1); // CYS-PERF-FIX btnalpha
            const float cysAlpha=d_btnAnimation->getFrameAlpha(time,-1); // CYS-PERF-FIX btnalpha
            if (cysFrame!=d_btnAnimationFrame || cysAlpha!=d_btnAnimationAlpha) // CYS-PERF-FIX btnalpha
            {
                d_btnAnimationFrame=cysFrame; // CYS-PERF-FIX btnalpha
                d_btnAnimationAlpha=cysAlpha; // CYS-PERF-FIX btnalpha
                requestRedraw(); // CYS-PERF-FIX btnalpha
            }
            return;
        }
        if (d_flashMode)
        {
            d_flashElapsed += d_flashIncreasing ? elapsed : -elapsed;
            if (d_flashElapsed <= 0) { d_flashElapsed = 0; d_flashIncreasing = true; }
            if (d_flashElapsed >= 0.6f) { d_flashElapsed = 0.6f; d_flashIncreasing = false; }
            if (getAlpha() != d_flashElapsed / 0.6f) // CYS-PERF-FIX btnalpha
                setAlpha(d_flashElapsed / 0.6f); // CYS-PERF-FIX btnalpha
        }
        else if (getAlpha() != 1.0f) // CYS-PERF-FIX btnalpha
            setAlpha(1); // CYS-PERF-FIX btnalpha
    }

    void FalagardButton::drawSelf(float z)
    {
        // this is hackish and relies on insider knowlegde of the way that both PushButton (actually ButtonBase)
        // and Window implement things; Soon I'll get to updating things so that this can be replaced
        // with clean code.

        // do we need to update the cache?
        if (d_needsRedraw)
        {
            // remove old cached imagery
            d_renderCache.clearCachedImagery();
            // signal that we'll no loger need a redraw.
            d_needsRedraw = false;
            // call PushButton drawSelf method which will call one of the state drawing methods overridden in this class.
            PushButton::drawSelf(z);
            if (d_btnAnimationEnabled && d_btnAnimationFrame)
                d_renderCache.cacheImage(*d_btnAnimationFrame, Rect(0,0,getAbsoluteWidth(),getAbsoluteHeight()),
                    0, ColourRect(colour(1,1,1,d_btnAnimationAlpha*getEffectiveAlpha())));
        }

        // call Window drawSelf to get it to send the cached imagery to the renderer.
        Window::drawSelf(z);
    }

    void FalagardButton::drawNormal(float z)
    {
        doButtonRender("Normal");

        // Support for legacy custom image setting
        if (d_useNormalImage)
        {
            ColourRect colours(d_normalImage.getColours());
            colours.setAlpha(getEffectiveAlpha());
            d_normalImage.setColours(colours);
            d_normalImage.draw(d_renderCache);
        }
    }

    void FalagardButton::drawHover(float z)
    {
        doButtonRender("Hover");

        // Support for legacy custom image setting
        if (d_useHoverImage)
        {
            ColourRect colours(d_hoverImage.getColours());
            colours.setAlpha(getEffectiveAlpha());
            d_hoverImage.setColours(colours);
            d_hoverImage.draw(d_renderCache);
        }
    }

    void FalagardButton::drawPushed(float z)
    {
        doButtonRender("Pushed");

        // Support for legacy custom image setting
        if (d_usePushedImage)
        {
            ColourRect colours(d_pushedImage.getColours());
            colours.setAlpha(getEffectiveAlpha());
            d_pushedImage.setColours(colours);
            d_pushedImage.draw(d_renderCache);
        }
    }

    void FalagardButton::drawDisabled(float z)
    {
        doButtonRender("Disabled");

        // Support for legacy custom image setting
        if (d_useDisabledImage)
        {
            ColourRect colours(d_disabledImage.getColours());
            colours.setAlpha(getEffectiveAlpha());
            d_disabledImage.setColours(colours);
            d_disabledImage.draw(d_renderCache);
        }
    }

    void FalagardButton::doButtonRender(const String& state)
    {
        // this is the second part of the hackish code.  We're duplicating the first section of code
        // from the Window::drawSelf method to decide whether to actually do anything.  It is likely
        // this will be replaced with cleaner code in the near future...

        // this conditional is just here to respect old legacy settings
        if (d_useStandardImagery)
        {
            const StateImagery* imagery;

            try
            {
                // get WidgetLookFeel for the assigned look.
                const WidgetLookFeel& wlf = WidgetLookManager::getSingleton().getWidgetLook(d_lookName);
                // try and get imagery for the state we were given, though default to Normal state if the
                // desired state does not exist
                imagery = wlf.isStateImageryPresent(state) ? &wlf.getStateImagery(state) : &wlf.getStateImagery("Normal");
            }
            // catch exceptions, but do not exit.
            catch (UnknownObjectException)
            {
                // don't try and draw using missing imagery!
                return;
            }

            // peform the rendering operation.
            // NB: This is not in the above try block since we want UnknownObjectException exceptions to be emitted from
            // the rendering code for conditions such as missing Imagesets and/or Images.
            imagery->render(*this);
        }
    }

	Size FalagardButton::getRenderSize()
	{
		const FontBase* font = getFont();
		if( font == 0 )
			return Window::getRenderSize();
		Rect absarea( 0, 0, 1024,768 );
		Size size = font->getFormattedSize( d_text, absarea, (TextFormatting)LeftAligned );
		size.d_width += 30;
		size.d_height += 10;
		return size;
	}
    //////////////////////////////////////////////////////////////////////////
    /*************************************************************************

        Factory Methods

    *************************************************************************/
    //////////////////////////////////////////////////////////////////////////
    Window* FalagardButtonFactory::createWindow(const String& name)
    {
        return new FalagardButton(d_type, name);
    }

    void FalagardButtonFactory::destroyWindow(Window* window)
    {
        delete window;
    }

} // End of  CEGUI namespace section
