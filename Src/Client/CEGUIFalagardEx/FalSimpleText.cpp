
#include "FalSimpleText.h"
#include "falagard/CEGUIFalWidgetLookManager.h"
#include "falagard/CEGUIFalWidgetLookFeel.h"

// Start of CEGUI namespace section
namespace CEGUI
{
	//===================================================================================
	//
	// FalagardSimpleText
	//
	//===================================================================================
    const utf8  FalagardSimpleText::WidgetTypeName[] = "Falagard/SimpleText";

	FalagardSimpleTextProperties::VertFormatting	FalagardSimpleText::d_vertFormattingProperty;
	FalagardSimpleTextProperties::HorzFormatting	FalagardSimpleText::d_horzFormattingProperty;
	FalagardSimpleTextProperties::TextScale			FalagardSimpleText::d_textScaleProperty;
	FalagardSimpleTextProperties::TextColor			FalagardSimpleText::d_textColorProperty;

    FalagardSimpleText::FalagardSimpleText(const String& type, const String& name) :
        Window(type, name),
		d_horzFormatting(LeftAligned),
		d_vertFormatting(VertCentred)
    {
		d_fScaleX = 1;
		d_fScaleY = 1;
		d_TextColour = colour( 1,1,1,1 );
        addSimpleTextProperties();
    }

    FalagardSimpleText::~FalagardSimpleText()
    {
    }

	void FalagardSimpleText::addSimpleTextProperties(void)
    {
		CEGUI_START_ADD_STATICPROPERTY( FalagardSimpleText )
		   CEGUI_ADD_STATICPROPERTY( &d_vertFormattingProperty );
		   CEGUI_ADD_STATICPROPERTY( &d_horzFormattingProperty );
		   CEGUI_ADD_STATICPROPERTY( &d_textScaleProperty );
		   CEGUI_ADD_STATICPROPERTY( &d_textColorProperty );
		CEGUI_END_ADD_STATICPROPERTY
    }

	/*************************************************************************
		Set the formatting required for the text.	
	*************************************************************************/
	void FalagardSimpleText::setVerticalFormatting(VertFormatting v_fmt)
	{
		d_vertFormatting = v_fmt;
		requestRedraw();
	}
	

	/*************************************************************************
		Set the formatting required for the text.	
	*************************************************************************/
	void FalagardSimpleText::setHorizontalFormatting(HorzFormatting h_fmt)
	{
		d_horzFormatting = h_fmt;
		requestRedraw();
	}

	/*************************************************************************
		Perform the actual rendering for this Window.
	*************************************************************************/
	void FalagardSimpleText::populateRenderCache()
	{
        // CY/GL SimpleText looks own their cell background and frame (for example
        // MuliteTextFrame and SimpleTextTitleFrame). Paint those even for empty text.
        if (!d_lookName.empty())
        {
            const WidgetLookFeel& look = WidgetLookManager::getSingleton().getWidgetLook(d_lookName);
            const char* state = isDisabled() && look.isStateImageryPresent("Disabled") ? "Disabled" : "Enabled";
            if (look.isStateImageryPresent(state)) look.getStateImagery(state).render(*this);
        }
        populateTextRenderCache();
	}

    Rect FalagardSimpleText::getTextRenderArea(void) const
    {
        if (!d_lookName.empty())
        {
            const WidgetLookFeel& look=WidgetLookManager::getSingleton().getWidgetLook(d_lookName);
            if (look.isNamedAreaDefined("TextArea")) return look.getNamedArea("TextArea").getArea().getPixelRect(*this);
        }
        return Rect(Point(0,0),getAbsoluteSize());
    }

	void FalagardSimpleText::populateTextRenderCache()
	{
		const FontBase* font = getFont();
		// can't render text without a font or empty text
		if (font == 0 || d_text.empty())
			return;
		
		// get destination area for the text.
		Rect textArea(getTextRenderArea());
		Rect clipper(textArea);
		// CYS-ITEMTEXT 15/09: CY rows are 16 px for Chinese; Noto 14-15 px Vietnamese is ~20 px tall once centred, so the
		// window rect cut the marks above/below the letters ("Số lượng" -> "lương", "Cấp yêu cầu" -> "vêu", gui-live-3
		// tooltip). The text keeps its position; only the clip grows vertically (never horizontally).
		clipper.d_top -= 4.0f;
		clipper.d_bottom += 4.0f;

		float textHeight = font->getFormattedSize(d_text, textArea, (TextFormatting)d_horzFormatting,d_fScaleX, d_fScaleY ).d_height;

		// adjust y positioning according to formatting option
		switch(d_vertFormatting)
		{
		case TopAligned:
			textArea.d_top += 1; //extern border
			break;

		case VertCentred:
			textArea.d_top += PixelAligned((textArea.getHeight() - textHeight) * 0.5f);
			break;

		case BottomAligned:
			textArea.d_top = textArea.d_bottom - textHeight;
			break;
		}

	    ColourRect final_cols( d_TextColour );
		final_cols.setAlpha( d_alpha );
		d_renderCache.cacheText(this, 
			d_text, font, (TextFormatting)d_horzFormatting, textArea, 0, final_cols, &clipper, true, d_fScaleX, d_fScaleY);
	}

	void FalagardSimpleText::setTextScale( Size  scale )
	{
		d_fScaleX = scale.d_width;
		d_fScaleY = scale.d_height; 
		requestRedraw();
	}

    //////////////////////////////////////////////////////////////////////////
    /*************************************************************************

        Factory Methods

    *************************************************************************/
    //////////////////////////////////////////////////////////////////////////
    Window* FalagardSimpleTextFactory::createWindow(const String& name)
    {
        return new FalagardSimpleText(d_type, name);
    }

    void FalagardSimpleTextFactory::destroyWindow(Window* window)
    {
		delete window;
    }

}
