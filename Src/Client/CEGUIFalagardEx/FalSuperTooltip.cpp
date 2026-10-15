#include "FalSuperTooltip.h"
#include "CEGUIPropertyHelper.h" // CYS-HUD
#include "CysTooltipContract.h"
#include "falagard/CEGUIFalWidgetLookManager.h"
#include "falagard/CEGUIFalWidgetLookFeel.h"
#include <CEGUIWindowManager.h>
#include <CEGUILogger.h>
#include <cstdio>
#include "CEGUISystem.h"
#include "CEGUIRenderer.h"
//#include "AxTrace.h"

// Start of CEGUI namespace section
namespace CEGUI
{
	static std::vector< String > split_string( const String& str, const String& delims = "\t\n ", unsigned int maxSplits = 0);

	//===================================================================================
	//
	// FalagardSuperTooltip/ResizeText
	//
	//===================================================================================
	const utf8  FalagardSuperTooltip::ResizeText::WidgetTypeName[] = "Falagard/SuperTooltip/ResizeText";
	
	FalagardResizeTextProperties::TopFrame		FalagardSuperTooltip::ResizeText::d_topFrameProperty;
	FalagardResizeTextProperties::MiddleFrame	FalagardSuperTooltip::ResizeText::d_middleFrameProperty;
	FalagardResizeTextProperties::BottomFrame	FalagardSuperTooltip::ResizeText::d_bottomFrameProperty;
	FalagardResizeTextProperties::TextArea 		FalagardSuperTooltip::ResizeText::d_textAreaProperty;

	// CYS-HUD: GL properties MaxWidth / MinWidth of Falagard/SuperTooltip/ResizeText (strings in client_GL
	// CEGUIFalagard.dll next to SelfFitWindow's MaxWidth/MinWidth; 20 GL tooltip layouts write both).
	namespace
	{
		class ResizeTextMaxWidth : public Property
		{
		public:
			ResizeTextMaxWidth() : Property("MaxWidth", "Property to get/set the maximum pixel width of the text part (0 = unlimited).", "0") {}
			String get(const PropertyReceiver* r) const { return PropertyHelper::intToString(static_cast<int>(static_cast<const FalagardSuperTooltip::ResizeText*>(r)->getMaxWidth())); }
			void set(PropertyReceiver* r, const String& v) { static_cast<FalagardSuperTooltip::ResizeText*>(r)->setMaxWidth(PropertyHelper::stringToFloat(v)); }
		};
		class ResizeTextMinWidth : public Property
		{
		public:
			ResizeTextMinWidth() : Property("MinWidth", "Property to get/set the minimum pixel width of the text part.", "0") {}
			String get(const PropertyReceiver* r) const { return PropertyHelper::intToString(static_cast<int>(static_cast<const FalagardSuperTooltip::ResizeText*>(r)->getMinWidth())); }
			void set(PropertyReceiver* r, const String& v) { static_cast<FalagardSuperTooltip::ResizeText*>(r)->setMinWidth(PropertyHelper::stringToFloat(v)); }
		};
		ResizeTextMaxWidth s_resizeTextMaxWidth;
		ResizeTextMinWidth s_resizeTextMinWidth;
	}

	FalagardSuperTooltip::ResizeText::ResizeText(const String& type, const String& name) :
        FalagardSimpleText(type, name),
		d_topFrame(0),
		d_middleFrame(0),
		d_bottomFrame(0),
		d_textArea(UDim(0, 0), UDim(0, 0), UDim(0, 0), UDim(0, 0)),
		d_maxWidth(0),
		d_minWidth(0)
    {
        addResizeTextProperties();
    }

	void FalagardSuperTooltip::ResizeText::clampWidth(void)
	{
		float width = getAbsoluteWidth();
		float clamped = width;
		if (d_minWidth > 0 && clamped < d_minWidth) clamped = d_minWidth;
		if (d_maxWidth > 0 && clamped > d_maxWidth) clamped = d_maxWidth;
		if (clamped != width) setWidth(Absolute, clamped);
	}

	FalagardSuperTooltip::ResizeText::~ResizeText()
	{
	}

	float FalagardSuperTooltip::ResizeText::_resizeSelf(void)
	{
		const FontBase* font = getFont();
		// can't do anything without a font :)
		if (font == 0)
			return 0.0f;

		// get destination area for the text.
        Rect textArea(getTextRenderArea());
		//AxTrace(0, 1, "Size=%.2f,%.2f", getPixelRect().getWidth(), getPixelRect().getHeight());

		float fTextHeight = font->getFormattedSize(d_text, textArea, (TextFormatting)d_horzFormatting).d_height 
			+ (FontBase::LineSpace);

		float fTopFrameHeight = d_topFrame ? d_topFrame->getSourceTextureArea().getHeight() : 0.f;
		float fMiddleFrameHeight = d_middleFrame ? d_middleFrame->getSourceTextureArea().getHeight() : 0.f;
		float fBottomFrameHeight = d_bottomFrame ? d_bottomFrame->getSourceTextureArea().getHeight() : 0.f;

        Rect wndArea(getAbsoluteRect());
        fTextHeight += wndArea.getHeight() - textArea.getHeight();

        if (CysTooltipContract::Probe())
        {
            char line[512];
            std::snprintf(line, sizeof(line), "CYS-FT-TEXTAREA: window=%s look=%s chars=%u size=%.1f,%.1f area=%.1f,%.1f,%.1f,%.1f measured=%.1f",
                getName().c_str(), d_lookName.c_str(), static_cast<unsigned>(d_text.length()),
                wndArea.getWidth(), wndArea.getHeight(), textArea.d_left, textArea.d_top,
                textArea.d_right, textArea.d_bottom, fTextHeight);
            Logger::getSingleton().logEvent(line, Standard);
        }

		return ceguimax(fTopFrameHeight+fMiddleFrameHeight+fBottomFrameHeight, fTextHeight);
	}
	
	void FalagardSuperTooltip::ResizeText::populateRenderCache()
	{
        Rect wndArea(getAbsoluteRect());

		float fTopFrameHeight = d_topFrame ? d_topFrame->getSourceTextureArea().getHeight() : 0.f;
		float fBottomFrameHeight = d_bottomFrame ? d_bottomFrame->getSourceTextureArea().getHeight() : 0.f;

		float fMiddleFrameHeight = wndArea.getHeight()-fTopFrameHeight-fBottomFrameHeight;

	    ColourRect final_cols(colour(1.0f, 1.0f, 1.0f));
		// CYS-HUD: GL tooltips give no TopFrame/MiddleFrame/BottomFrame; they draw the look's "Enabled" imagery
		// (TLBB_Look_ResizeTextFrame). 0.85 dereferenced the null images (Rect::offset crash in 11 layouts).
		if (d_topFrame)
			d_renderCache.cacheImage(*d_topFrame, Rect(0, 0, wndArea.getWidth(),fTopFrameHeight), 0.0f, final_cols);
		if (d_middleFrame)
			d_renderCache.cacheImage(*d_middleFrame,
				Rect(0, fTopFrameHeight, wndArea.getWidth(), fTopFrameHeight+fMiddleFrameHeight), 0.0f, final_cols);
		if (d_bottomFrame)
			d_renderCache.cacheImage(*d_bottomFrame,
				Rect(0, fTopFrameHeight+fMiddleFrameHeight, wndArea.getWidth(), wndArea.getHeight()), 0.0f, final_cols);
		if (!d_topFrame && !d_middleFrame && !d_bottomFrame && !d_lookName.empty())
		{
			const WidgetLookFeel& wlf = WidgetLookManager::getSingleton().getWidgetLook(d_lookName);
			const char* state = isDisabled() ? "Disabled" : "Enabled";
			if (wlf.isStateImageryPresent(state))
				wlf.getStateImagery(state).render(*this);
		}

		// ResizeText has already rendered either its explicit frame images or its look.
		populateTextRenderCache();
		//d_topFrame->draw()
	}

	Rect FalagardSuperTooltip::ResizeText::getTextRenderArea(void) const
	{
        const Rect explicitArea(d_textArea.asAbsolute(getAbsoluteSize()));
        static const bool oldSize = []() {
            const char* value = std::getenv("CYS_FT_RESIZETEXT_OLD");
            return value && value[0] == '1' && value[1] == 0;
        }();
        if (!CysTooltipContract::Old() && !oldSize && explicitArea.getWidth() <= 0 && !d_lookName.empty())
        {
            // CY/GL TLBB_Look_ResizeTextFrame declares a NamedArea, not the old
            // TextArea URect property. Measure and paint in the same inset area.
            // Reading the zero default instead wraps at width 0 and adds the
            // complete previous window height as padding on every refresh.
            const WidgetLookFeel& look = WidgetLookManager::getSingleton().getWidgetLook(d_lookName);
            if (look.isNamedAreaDefined("TextArea"))
                return look.getNamedArea("TextArea").getArea().getPixelRect(*this);
        }
        return explicitArea;
	}

	void FalagardSuperTooltip::ResizeText::addResizeTextProperties(void)
	{
		CEGUI_START_ADD_STATICPROPERTY( ResizeText )
		   CEGUI_ADD_STATICPROPERTY( &d_topFrameProperty );
		   CEGUI_ADD_STATICPROPERTY( &d_middleFrameProperty );
		   CEGUI_ADD_STATICPROPERTY( &d_bottomFrameProperty );
		   CEGUI_ADD_STATICPROPERTY( &d_textAreaProperty );
		   CEGUI_ADD_STATICPROPERTY( &s_resizeTextMaxWidth ); // CYS-HUD
		   CEGUI_ADD_STATICPROPERTY( &s_resizeTextMinWidth ); // CYS-HUD
		CEGUI_END_ADD_STATICPROPERTY
	}

    //////////////////////////////////////////////////////////////////////////
    /*************************************************************************
        Factory Methods
    *************************************************************************/
    //////////////////////////////////////////////////////////////////////////
	Window* FalagardSuperTooltip::ResizeTextFactory::createWindow(const String& name)
    {
        return new ResizeText(d_type, name);
    }

	void FalagardSuperTooltip::ResizeTextFactory::destroyWindow(Window* window)
    {
		delete window;
    }

	//===================================================================================
	//
	// FalagardSuperTooltip
	//
	//===================================================================================
    const utf8  FalagardSuperTooltip::WidgetTypeName[] = "Falagard/SuperTooltip";

	FalagardSuperTooltipProperties::PageElements	FalagardSuperTooltip::d_pageElementsProperty;

	FalagardSuperTooltip::FalagardSuperTooltip(const String& type, const String& name) :
        Window(type, name)
    {
        addSuperTooltipProperties();

        setAlwaysOnTop(true);
	}

    FalagardSuperTooltip::~FalagardSuperTooltip()
    {
    }

	void FalagardSuperTooltip::addSuperTooltipProperties(void)
    {
		CEGUI_START_ADD_STATICPROPERTY( FalagardSuperTooltip )
		   CEGUI_ADD_STATICPROPERTY( &d_pageElementsProperty );
		CEGUI_END_ADD_STATICPROPERTY
	}

	String FalagardSuperTooltip::getPageElementsName(void) const
	{
		String strOut;

		ElementsVector::const_iterator it;
		for(it=d_VectorElements.begin(); it!=d_VectorElements.end(); it++)
		{
			strOut += it->pWindow->getName();
			strOut += (utf8*)";";
		}

		return strOut;
	}
	
	void FalagardSuperTooltip::setPageElementsName(const String& strName)
	{
        d_scrollOffset = 0;
		//Split string 
		std::vector< String > vElementNameVector = split_string(strName, (utf8*)";", getChildCount());

		//Hide all sub window
		int nChildSize = (int)getChildCount();
		for(int i=0; i<nChildSize; i++)
		{
			d_children[i]->hide();
		}

		//Clear old elements
		d_VectorElements.clear();
		int nSize = (int)vElementNameVector.size();
		for(int i=0; i<nSize; i++)
		{
			//Only accept child window
			if(!isChild(vElementNameVector[i])) continue;

			//Get Child window
			Window* pChild = getChild(vElementNameVector[i]);
			pChild->show();

			Elements newElement;
			newElement.pWindow = pChild;
			//Dynamic size window (Resize Text)
			if(pChild->testClassName("FalagardSuperTooltip/ResizeText"))
			{
				newElement.bDynamicSize = true;
			}
			//Static size window
			else
			{
				newElement.bDynamicSize = false;
			}

			d_VectorElements.push_back(newElement);
		}
	}

	void FalagardSuperTooltip::onSized(WindowEventArgs& e)
	{
		Window::onSized( e );

		//resizeSelf();
	}

    void FalagardSuperTooltip::onMoved(WindowEventArgs& e)
    {
        Window::onMoved(e);
        // Comparison Lua moves the main tooltip down one header row after
        // PositionSelf. Keep the entire scroll viewport inside the screen.
        if(d_contentHeight>getAbsoluteHeight()) {
            const float bottom=System::getSingleton().getRenderer()->getHeight()-8.0f;
            const float limit=ceguimax(0.0f,bottom-getAbsoluteHeight());
            if(getAbsoluteYPosition()>limit)
                setWindowYPosition(UDim(0,limit));
        }
    }

    void FalagardSuperTooltip::populateRenderCache()
    {
		//Ignore when child elements empty
		if(d_VectorElements.empty()) return;

		//Draw frame border!

        // get WidgetLookFeel for the assigned look.
        const WidgetLookFeel& wlf = WidgetLookManager::getSingleton().getWidgetLook(d_lookName);
        // try and get imagery for our current state
        const StateImagery* imagery = &wlf.getStateImagery("Frame");
        // peform the rendering operation.
        imagery->render(*this);
    }
	
	void FalagardSuperTooltip::resizeSelf(void)
	{
		// get child count
		int nElementNum = (int)d_VectorElements.size();
		if(nElementNum == 0) return;

		Rect  rcAbsoluteRect = getAbsoluteRect(); 

		// The part height(Absolute).
		std::vector< float >	vPartHeight(nElementNum);
				
		//AxTrace(0, 1, "--------------");

		float  fAbsHeight = 0;
		for(int i=0; i<nElementNum; ++i)
		{
			Elements& element = d_VectorElements[i];

			if(element.bDynamicSize)
			{
				//Ignore empty resize text control.
				if(element.pWindow->getText().empty())
				{
					element.pWindow->setText((utf8*)" ");
				}

				vPartHeight[i] = ((ResizeText*)element.pWindow)->_resizeSelf();
				fAbsHeight += vPartHeight[i];
				//AxTrace(0, 0, "D[%d] = %f", i, vPartHeight[i]);
			}
			//Static part
			else
			{
				vPartHeight[i] = element.pWindow->getAbsoluteHeight();
				fAbsHeight += element.pWindow->getAbsoluteRect().getHeight();

				//AxTrace(0, 0, "S[%d] = %f", i, vPartHeight[i]);
			}
		}

		// get named area"DynamicPartBorderSize"
		/*
		|		It's fake!!
		|	Left	- LeftBorder Width
		|	Top		- TopBorder Height
		|	Width	- RightBorder Width
		|	Height	- BottomBorder Height
		|
		*/
        //const WidgetLookFeel& wlf = WidgetLookManager::getSingleton().getWidgetLook(d_lookName);
		//const Rect rectBorder(wlf.getNamedArea("DynamicPartBorderSize").getArea().getPixelRect(*this));

		//Add header and footer size
		//fAbsHeight += rectBorder.d_top + rectBorder.getHeight();

        d_contentHeight = fAbsHeight;
        const float limit = ceguimax(100.0f, System::getSingleton().getRenderer()->getHeight()-8.0f);
        setHeight(Absolute, ceguimin(fAbsHeight,limit));
        d_scrollOffset = ceguimin(d_scrollOffset,ceguimax(0.0f,fAbsHeight-getAbsoluteHeight()));

		//Resize and reposition all sub window.
		float fHeightStep = -d_scrollOffset;
		for(int i=0; i<nElementNum; ++i)
		{
			Elements& element = d_VectorElements[i];

			//Ignore empty resize text control.
			if(element.bDynamicSize && element.pWindow->getText().empty()) continue;

            // CEGUI defaults each child's maximum height to one screen. The
            // scroll viewport is bounded, but the measured text document must
            // remain taller; otherwise centred text loses BOTH its first and
            // last lines and subsequent page elements overlap it.
            if(element.bDynamicSize)
                element.pWindow->setWindowMaxSize(UVector2(UDim(1,0),UDim(0,ceguimax(vPartHeight[i],limit))));
			element.pWindow->setHeight(Absolute, vPartHeight[i]);
			element.pWindow->setPosition(Absolute, 
				Point(element.pWindow->getAbsoluteXPosition(), fHeightStep));

			fHeightStep += element.pWindow->getAbsoluteHeight();

		}
	}

    bool FalagardSuperTooltip::scrollContent(float delta)
    {
        if(!isVisible() || d_contentHeight<=getAbsoluteHeight())return false;
        const float next=ceguimax(0.0f,ceguimin(d_contentHeight-getAbsoluteHeight(),d_scrollOffset-delta*60.0f));
        if(next==d_scrollOffset)return true;
        d_scrollOffset=next;
        // Never accumulate from a rounded negative position: legacy PixelAligned
        // truncates towards zero and otherwise drifts by one pixel per wheel
        // event, even after reaching the end of the document.
        float y=-next;
        for(auto& element:d_VectorElements) {
            element.pWindow->setWindowYPosition(UDim(0,y));
            y+=element.pWindow->getAbsoluteHeight();
        }
        requestRedraw();return true;
    }


    //////////////////////////////////////////////////////////////////////////
    /*************************************************************************

        Factory Methods

    *************************************************************************/
    //////////////////////////////////////////////////////////////////////////
    Window* FalagardSuperTooltipFactory::createWindow(const String& name)
    {
        return new FalagardSuperTooltip(d_type, name);
    }

    void FalagardSuperTooltipFactory::destroyWindow(Window* window)
    {
		delete window;
    }

    //////////////////////////////////////////////////////////////////////////
	// SplitString
	//		Copy from OGRE
    //////////////////////////////////////////////////////////////////////////
    std::vector<String> split_string( const String& str, const String& delims, unsigned int maxSplits)
    {
        // static unsigned dl;
        std::vector<String> ret;
        unsigned int numSplits = 0;

        // Use STL methods 
        size_t start, pos;
        start = 0;
        do 
        {
            pos = str.find_first_of(delims, start);
            if (pos == start)
            {
                // Do nothing
                start = pos + 1;
            }
            else if (pos == String::npos || (maxSplits && numSplits == maxSplits))
            {
                // Copy the rest of the string
                ret.push_back( str.substr(start) );
                break;
            }
            else
            {
                // Copy up to delimiter
                ret.push_back( str.substr(start, pos - start) );
                start = pos + 1;
            }
            // parse up to next real data
            start = str.find_first_not_of(delims, start);
            ++numSplits;

        } while (pos != String::npos);



        return ret;
    }
}
