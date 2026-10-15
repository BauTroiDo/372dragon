

#include "FalActionButton.h"
#include "CEGUIAnimateManager.h"
#include "CEGUIAnimate.h"
#include <CEGUIFontManager.h>
#include <CEGUILogger.h>
#include <CEGUIPropertyHelper.h>
#include "CysStoredProperties.h"
#include "falagard/CEGUIFalWidgetLookManager.h"
#include "falagard/CEGUIFalWidgetLookFeel.h"
#include <cstdio>
#include <math.h>
#include "windows.h"
// Start of CEGUI namespace section
namespace CEGUI
{
    // Evidence only: preserve the real mouse/capture path while locating a missing left Clicked event.
    static bool CysActionGestureProbe()
    {
        char flag[8] = {};
        return (GetEnvironmentVariableA("CYS_UNEQUIP_LIVE", flag, sizeof(flag)) == 1 && flag[0] == '1') ||
            (GetEnvironmentVariableA("CYS_NBSHOP_LIVE", flag, sizeof(flag)) == 1 && flag[0] == '1');
    }

    static void CysActionGestureLog(const char* phase, FalagardActionButton* button, int mouse, bool pushed, bool dragging)
    {
        if (!CysActionGestureProbe()) return;
        Window* sheet = System::getSingleton().getGUISheet();
        Window* hit = sheet ? sheet->getChildAtPosition(MouseCursor::getSingleton().getPosition()) : NULL;
        Window* active = sheet ? sheet->getActiveChild() : NULL;
        char text[512] = {};
        std::snprintf(text, sizeof(text), "CYS-ACTION-GESTURE: %s window=%s mouse=%d active=%d captured=%d pushed=%d dragging=%d hit=%s active_window=%s",
            phase, button->getName().c_str(), mouse, button->isActive(), button->isCapturedByThis(), pushed, dragging,
            hit ? hit->getName().c_str() : "none", active ? active->getName().c_str() : "none");
        Logger::getSingleton().logEvent(text, Standard);
    }
    //////////////////////////////////////////////////////////////////////////
    // Window type string
    const utf8  FalagardActionButton::WidgetTypeName[] = "Falagard/ActionButton";
    // Event Strings
    const String FalagardActionButton::EventNamespace("Falagard/ActionButton");
    const String FalagardActionButton::EventDragStarted("DragStarted");
    const String FalagardActionButton::EventDragEnded("DragEnded");
    const String FalagardActionButton::EventDragPositionChanged("DragPositionChanged");
    const String FalagardActionButton::EventDragEnabledChanged("DragEnabledChanged");
    const String FalagardActionButton::EventDragThresholdChanged("DragThresholdChanged");
    const String FalagardActionButton::EventDragDropTargetChanged("DragDropTargetChanged");
    const String FalagardActionButton::EventDropItemEnters("DropItemEnters");
    const String FalagardActionButton::EventDropItemLeaves("DropItemLeaves");
    const String FalagardActionButton::EventDropItemDropped("DropItemDropped");
	const String FalagardActionButton::EventRBClicked((utf8*)"RBClicked");

    FalagardActionButtonProperties::Empty				FalagardActionButton::d_emptyProperty;
    FalagardActionButtonProperties::Checked				FalagardActionButton::d_checkedProperty;
    FalagardActionButtonProperties::Default				FalagardActionButton::d_defaultProperty;
	FalagardActionButtonProperties::Gloom				FalagardActionButton::d_gloomProperty;
	FalagardActionButtonProperties::CornerChar			FalagardActionButton::d_cornerCharProperty;
    FalagardActionButtonProperties::DraggingEnabled		FalagardActionButton::d_dragEnabledProperty;
    FalagardActionButtonProperties::DragThreshold		FalagardActionButton::d_dragThresholdProperty;
    FalagardActionButtonProperties::DragAcceptName		FalagardActionButton::d_dragAcceptNameProperty;

    FalagardActionButton::FalagardActionButton(const String& type, const String& name) :
        FalagardButton(type, name),
		d_empty(true),
		d_checked(false),
		d_default(false),
		//d_gloom(false),
        d_draggingEnabled(false),
        d_leftMouseDown(false),
        d_dragging(false),
        d_dragThreshold(4.0f),
		m_pLogicData(0),
		d_ActiveButton(LeftButton),
		d_DragButton(RightButton)
    {
        addActionButtonProperties();

		d_animate1.d_animate = 0;

		setClippedByParent(false);
		d_gloom = false;
    }

    FalagardActionButton::~FalagardActionButton()
    {
    }

	void FalagardActionButton::initialise(void)
	{
		FalagardButton::initialise();

		//Ignore the normal tooltips
		setTooltip(0);
	}

	void FalagardActionButton::addActionButtonProperties(void)
    {
		CEGUI_START_ADD_STATICPROPERTY( FalagardActionButton )
		   CEGUI_ADD_STATICPROPERTY( &d_emptyProperty );
           CEGUI_ADD_STATICPROPERTY( &d_checkedProperty );
           CEGUI_ADD_STATICPROPERTY( &d_defaultProperty );
		   CEGUI_ADD_STATICPROPERTY( &d_gloomProperty );
		   CEGUI_ADD_STATICPROPERTY( &d_cornerCharProperty  );
		   CEGUI_ADD_STATICPROPERTY( &d_dragEnabledProperty );
           CEGUI_ADD_STATICPROPERTY( &d_dragThresholdProperty );
           CEGUI_ADD_STATICPROPERTY( &d_dragAcceptNameProperty );
		CEGUI_END_ADD_STATICPROPERTY
	}

	void FalagardActionButton::setAnimate(const String& name, int time_total, float percent)
	{
		int time_now = (int)(System::getSingleton().getCurTimeElapsed()*1000.0f);
		int time_start = (int)(time_now - time_total*percent);

		if(AnimateManager::getSingleton().isAnimatePresent(name))
		{
			d_animate1.d_animate = ( Animate*)AnimateManager::getSingleton().getAnimate(name);
			d_animate1.d_time_start = time_start;
			d_animate1.d_time_total = time_total;

			d_animate1.d_currentFrame = AnimateManager::getSingleton().getAnimate(name)->getFrame(0, time_total);
			
			if( name == (utf8*)"CoolDown" )
				m_bCoolDown = true;
			else
				m_bCoolDown = false;
			requestRedraw();
		}
	}

	void FalagardActionButton::cleanAnimate(void)
	{
		d_animate1.d_animate = 0;
		requestRedraw();
	}

	void FalagardActionButton::drawSelf( float z )
	{
		if (d_needsRedraw  )
		{
			d_renderCache.clearCachedImagery();
			d_needsRedraw = false;

            static const bool oldBackground = []() {
                char value[4] = {};
                return GetEnvironmentVariableA("CYS_ACTION_BACKGROUND_OLD", value, sizeof(value)) == 1 && value[0] == '1';
            }();
            if (!oldBackground && !d_lookName.empty())
            {
                const WidgetLookFeel& look = WidgetLookManager::getSingleton().getWidgetLook(d_lookName);
                if (look.isStateImageryPresent("BackgroundImage"))
                    doButtonRender("BackgroundImage");
            }
			
			//Empty
			if(isEmpty())
			{
                if (!oldBackground)
                {
                    const String backImage = cysStoredProperty(this, "BackImage");
                    if (!backImage.empty())
                    {
                        const Image* image = PropertyHelper::stringToImage(backImage);
                        if (image)
                        {
                            ColourRect colours(colour(1.0f, 1.0f, 1.0f, getEffectiveAlpha()));
                            d_renderCache.cacheImage(*image, Rect(Point(0, 0), getAbsoluteSize()), 0.0f, colours);
                        }
                    }
                }
				if((isHovering() || isPushed()) && !isDisabled(true) )//&& !isGloom())
				{
					drawHover(z);
				}
			}
			else
			{
				//Draw normal image
				drawNormal(z);

				//Notin Dragging
				if(d_dragging && !isGloom())
				{
					drawPushed(z);
				}
				else
				{
					//Draw disable mask only when disabled
					if (isDisabled(true) || isGloom() )
					{
						drawDisabled(z);
						if (isPushed() || isChecked()) 
						{
							drawPushed(z);
						}
					}
					else
					{
						//If pushed or checked draw "Pushed" Layer
						if (isPushed() || isChecked()) 
						{
							drawPushed(z);
						}

						//Draw "Hover" Layer
						if (isHovering() && !isChecked())
						{
							drawHover(z);
						}

						drawAnimate(z);
						// If default
						if(isDefault())
						{
							drawDefault(z);
						}
						
					}

					//Draw corner character
					drawCorner(z);
				}
			}
            // CY's gem-swap buttons remain separate. This strip uses real item
            // durability and adds no child window that could intercept clicks.
            if (!isEmpty() && PropertyHelper::stringToBool(cysStoredProperty(this,"ShowDurability")))
            {
                const float value=PropertyHelper::stringToFloat(cysStoredProperty(this,"EquipmentDurability"));
                if (value>=0 && value<=1 && getAbsoluteHeight()>4 && getAbsoluteWidth()>6)
                {
                    const Image* green=PropertyHelper::stringToImage("set:CommonStaticImage image:ProgressGreenM");
                    const Image* fill=value<0.1f ? PropertyHelper::stringToImage("set:CommonStaticImage image:ProgressRedM") : green;
                    Rect area(1,1,getAbsoluteWidth()-1,getAbsoluteHeight()-1);
                    if (!d_lookName.empty()) {
                        const WidgetLookFeel& look=WidgetLookManager::getSingleton().getWidgetLook(d_lookName);
                        if (look.isNamedAreaDefined("ActionArea")) area=look.getNamedArea("ActionArea").getArea().getPixelRect(*this);
                    }
                    const float right=area.d_right-2, bottom=area.d_bottom-2, top=area.d_top+2, height=bottom-top;
                    const ColourRect dark(colour(0,0,0,getEffectiveAlpha()));
                    const ColourRect colourFill(colour(1,1,1,getEffectiveAlpha()));
                    if(green) d_renderCache.cacheImage(*green,Rect(right-3,top,right,bottom),0,dark);
                    if(fill && value>0) d_renderCache.cacheImage(*fill,Rect(right-3,bottom-height*value,right,bottom),0,colourFill);
                }
            }
		}

		Window::drawSelf(z);
	}

	void FalagardActionButton::drawDefault(float z)
	{
        doButtonRender("Defaulted");
	}

	void FalagardActionButton::drawCorner(float z)
	{
		//Draw CornerChar
		ColourRect final_cols(colour(1.0f, 1.0f, 0.0f));

		//Top Left
		if(!d_CornerChar_TopLeft.d_Char.empty())
		{
			d_renderCache.cacheText(this, 
				d_CornerChar_TopLeft.d_Char, getFont(), (TextFormatting)LeftAligned, 
				Rect(2, 2, getAbsoluteSize().d_width, getAbsoluteSize().d_height), 0.0f, final_cols);
		}				
		//Top Right
		if(!d_CornerChar_TopRight.d_Char.empty())
		{
			d_renderCache.cacheText(this, 
				d_CornerChar_TopRight.d_Char, getFont(), (TextFormatting)RightAligned, 
				Rect(0, 2, getAbsoluteSize().d_width-2, getAbsoluteSize().d_height), 0.0f, final_cols);
		}				
		//Bottom Left
		if(!d_CornerChar_BotLeft.d_Char.empty())
		{
			//Get the font height
			float fFontHeight = getFont()->getFontHeight();
			d_renderCache.cacheText(this, 
				d_CornerChar_BotLeft.d_Char, getFont(), (TextFormatting)LeftAligned, 
				Rect(2, getAbsoluteSize().d_height-fFontHeight-2, getAbsoluteSize().d_width, getAbsoluteSize().d_height), 0.0f, final_cols);
		}				
		//Bottom Right
		if(!d_CornerChar_BotRight.d_Char.empty())
		{
			//Get the font height
			float fFontHeight = getFont()->getFontHeight();
			d_renderCache.cacheText(this, 
				d_CornerChar_BotRight.d_Char, getFont(), (TextFormatting)RightAligned, 
				Rect(0, getAbsoluteSize().d_height-fFontHeight-2, getAbsoluteSize().d_width-2, getAbsoluteSize().d_height), 0.0f, final_cols);
		}
	}

	void FalagardActionButton::drawAnimate(float z)
	{
		if(!d_animate1.d_animate || !d_animate1.d_currentFrame) return;

		//Draw CornerChar
		ColourRect color(colour( 1.0f, 1.0f, 0 ));

		color.setAlpha( d_animate1.d_alpha );
		d_renderCache.cacheImage(*(d_animate1.d_currentFrame),
			Rect(0, 0, getAbsoluteSize().d_width, getAbsoluteSize().d_height), 0, color);
	}

    bool FalagardActionButton::isDraggingThresholdExceeded(const Point& local_mouse)
    {
        // calculate amount mouse has moved.
        float	deltaX = fabsf(local_mouse.d_x - d_dragPoint.d_x);
        float	deltaY = fabsf(local_mouse.d_y - d_dragPoint.d_y);

        // see if mouse has moved far enough to start dragging operation
        return (deltaX > d_dragThreshold || deltaY > d_dragThreshold) ? true : false;
    }

	void FalagardActionButton::updateAnimate(ANIMATE& animate)
	{
		if(!animate.d_animate) return;

		int time_now = (int)(System::getSingleton().getCurTimeElapsed()*1000.0f);

		const Image* pFrame = animate.d_animate->getFrame( time_now-animate.d_time_start, animate.d_time_total );
	
		animate.d_currentFrame = pFrame;
		animate.d_alpha = animate.d_animate->getFrameAlpha( time_now-animate.d_time_start, animate.d_time_total );
		requestRedraw();
		if( pFrame == NULL )
		{
			if( m_bCoolDown ) // 如果是cooldown ，就开始播放特效动画
			{
				setAnimate( "CoolDownEnd", -1, 0 );
				animate.d_alpha = 0;
			}
		}
	}

	void FalagardActionButton::updateSelf(float elapsed)
	{
		updateAnimate(d_animate1);
	}

    void FalagardActionButton::onMouseButtonDown(MouseEventArgs& e)
    {
//        FalagardButton::onMouseButtonDown(e);下面就是pushbutton中的部分
		// default processing
		Window::onMouseButtonDown(e);

		if (e.button == LeftButton || e.button == RightButton)
		{
			if (captureInput())
			{
				d_pushed = true;
				updateInternalState(e.position);
				requestRedraw();
			}

			// event was handled by us.
			e.handled = true;
		}
/////////////////////////////////////////////////////////
        if (e.button == LeftButton && isDraggingEnabled())
        {
			if(!d_dragging)
			{
				// get position of mouse as co-ordinates local to this window.
				Point localPos = (getMetricsMode() == Relative) ? 
					relativeToAbsolute(screenToWindow(e.position)) :
					screenToWindow(e.position);

				// store drag point for possible sizing or moving operation.
				d_dragPoint = localPos;
				d_leftMouseDown = true;

			}

			e.handled = true;
        }

		if (e.button == RightButton && isDraggingEnabled())
        {
			e.handled = true;
        }
        CysActionGestureLog("down", this, (int)e.button, isPushed(), d_dragging);
    }

	void FalagardActionButton::notifyDragingEnd(void)
	{
		d_dragging = false;
		d_leftMouseDown = false;
		WindowEventArgs args(this);
		fireEvent(EventDragEnded, args, EventNamespace);
		
		requestRedraw();
	}

	void FalagardActionButton::notifyDragDrop_Droped(FalagardActionButton* pBtn)
	{

	}

	void FalagardActionButton::onMouseButtonUp(MouseEventArgs& e)
	{
        CysActionGestureLog("up", this, (int)e.button, isPushed(), d_dragging);
//		FalagardButton::onMouseButtonUp(e);下面就是pushbutton中的部分
		if ((e.button == LeftButton) && isPushed())
		{
			Window* sheet = System::getSingleton().getGUISheet();

			if (sheet != NULL)
			{
				// if mouse was released over this widget
				if (this == sheet->getChildAtPosition(e.position))
				{
					// fire event
					WindowEventArgs args(this);
					onClicked(args);
				}

			}

			e.handled = true;
		}

		if(e.button == RightButton)
		{
			Window* sheet = System::getSingleton().getGUISheet();

			if (sheet != NULL)
			{
				// if mouse was released over this widget
				if (this == sheet->getChildAtPosition(e.position))
				{
					// fire event
					WindowEventArgs args(this);
					onRBClicked(args);
				}

			}
			
		}

		// default handling
//		ButtonBase::onMouseButtonUp(e);下面就是buttonbase中的部分
		Window::onMouseButtonUp(e);

		if (e.button == LeftButton || e.button == RightButton)
		{
			releaseInput();

			// event was handled by us.
			e.handled = true;
		}

        d_leftMouseDown = false;
	}
//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////
    void FalagardActionButton::onMouseMove(MouseEventArgs& e)
    {
		FalagardButton::onMouseMove(e);

		if(isDraggingEnabled() && !d_dragging && !isEmpty())
		{
			// get position of mouse as co-ordinates local to this window.
			Point localMousePos = (getMetricsMode() == Relative) ? 
				relativeToAbsolute(screenToWindow(e.position)) :
				screenToWindow(e.position);

			// if mouse button is down (but we're not yet being dragged)
			if (d_leftMouseDown)
			{
				if (isDraggingThresholdExceeded(localMousePos))
				{
					// Trigger the event
					WindowEventArgs args(this);
					d_dragging = true;
					releaseInput();

					fireEvent(EventDragStarted, e, EventNamespace);
				}
			}
		}
    }

	void FalagardActionButton::onClicked(WindowEventArgs& e)
	{
        CysActionGestureLog("clicked", this, 0, isPushed(), d_dragging);
		if(d_dragging) return;

		FalagardButton::onClicked(e);
	}

	void FalagardActionButton::onRBClicked(WindowEventArgs& e)
	{
		if(d_dragging) return;

		fireEvent(EventRBClicked, e, EventNamespace);
	}

	void FalagardActionButton::subscribeDragDropStartedEvent(Event::Subscriber subscriber)
	{
		subscribeEvent(EventDragStarted, subscriber);
	}

	void FalagardActionButton::subscribeMouseEnterEvent(Event::Subscriber subscriber)
	{
		subscribeEvent(EventMouseEnters, subscriber);
	}

	void FalagardActionButton::subscribeMouseLeaveEvent(Event::Subscriber subscriber)
	{
		
		subscribeEvent(EventMouseLeaves, subscriber);
	}

	String FalagardActionButton::getCornerChar(int nPos) const
	{
		switch(nPos)
		{
		case 0: return d_CornerChar_TopLeft.d_Char;
		case 1: return d_CornerChar_TopRight.d_Char;
		case 2: return d_CornerChar_BotLeft.d_Char;
		case 3: return d_CornerChar_BotRight.d_Char;
		default: return "";
		}
	}

	void FalagardActionButton::setCornerChar(int nPos, const String& strChar)
	{
		String strCharSafe="  ";
		if(strChar.size() > 3)
		{
			strCharSafe += strChar.substr(0, 3);
		}
		else strCharSafe += strChar;
		strCharSafe[0] = 0XFBFFFFFF;
		strCharSafe[1] = 0XFC010101;

		switch(nPos)
		{
		case 0: d_CornerChar_TopLeft.d_Char		= strCharSafe; break;
		case 1: d_CornerChar_TopRight.d_Char	= strCharSafe; break;
		case 2: d_CornerChar_BotLeft.d_Char		= strCharSafe; break;
		case 3: d_CornerChar_BotRight.d_Char	= strCharSafe; break;
		default: break;
		}

		requestRedraw();
	}

	void FalagardActionButton::prepareBigchar(void)
	{
		Window::prepareBigchar();

		((FontBase*)getFont())->prepareString(d_CornerChar_TopLeft.d_Char);
		((FontBase*)getFont())->prepareString(d_CornerChar_TopRight.d_Char);
		((FontBase*)getFont())->prepareString(d_CornerChar_BotLeft.d_Char);
		((FontBase*)getFont())->prepareString(d_CornerChar_BotRight.d_Char);
	}


	//////////////////////////////////////////////////////////////////////////
    /*************************************************************************

        Factory Methods

    *************************************************************************/
    //////////////////////////////////////////////////////////////////////////
    Window* FalagardActionButtonFactory::createWindow(const String& name)
    {
        return new FalagardActionButton(d_type, name);
    }

    void FalagardActionButtonFactory::destroyWindow(Window* window)
    {
		delete window;
    }
}
