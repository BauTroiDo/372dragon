#include ".\falagardselffitwindow.h"
#include "ceguipropertyhelper.h"
#include "windows.h"
#include "ceguifontbase.h"
#include "CEGUIExceptions.h"
#include <cmath>
#include "falagard/CEGUIFalWidgetLookManager.h"
#include "falagard/CEGUIFalWidgetLookFeel.h"
namespace CEGUI
{
    namespace {
        class CysMinHeightProperty : public Property {
        public:
            CysMinHeightProperty() : Property("MinHeight", "Minimum fitted text height in pixels.", "0") {}
            String get(const PropertyReceiver* r) const { return PropertyHelper::floatToString(static_cast<const FalagardSelfFitWindow*>(r)->getMinHeight()); }
            void set(PropertyReceiver* r, const String& v) { static_cast<FalagardSelfFitWindow*>(r)->setMinHeight(PropertyHelper::stringToFloat(v)); }
        } cysMinHeightProperty;
        class CysFitTextAreaProperty : public Property {
        public:
            CysFitTextAreaProperty() : Property("FitTextArea", "Fit the rendered text format including look insets and glyph padding.", "False") {}
            String get(const PropertyReceiver* r) const { return PropertyHelper::boolToString(static_cast<const FalagardSelfFitWindow*>(r)->getFitTextArea()); }
            void set(PropertyReceiver* r, const String& v) { static_cast<FalagardSelfFitWindow*>(r)->setFitTextArea(PropertyHelper::stringToBool(v)); }
        } cysFitTextAreaProperty;
    }
    const utf8 FalagardSelfFitWindow::WidgetTypeName[] = "Falagard/SelfFitWindow";

	FalagardSelfFitProperties::FitType			FalagardSelfFitWindow::d_FitTypeProperty;
	FalagardSelfFitProperties::FitPosition		FalagardSelfFitWindow::d_FitPosProperty;
	FalagardSelfFitProperties::MaxWidth			FalagardSelfFitWindow::d_MaxWidthProperty;
	FalagardSelfFitProperties::Life				FalagardSelfFitWindow::d_LifeProperty;
	FalagardSelfFitProperties::FadeOutTime		FalagardSelfFitWindow::d_FadeOutProperty;
	FalagardSelfFitProperties::FadeInTime		FalagardSelfFitWindow::d_FadeInProperty;
	FalagardSelfFitWindow::FalagardSelfFitWindow(const String& type, const String& name):
		FalagardSimpleText(type, name)
	{
		
		d_maxWidth = 200;
        d_minHeight = 0;
        d_fitTextArea = false;
		m_bFadeMode = false;
		m_nFitType = SELF_FIT_CENTER;
		m_fFadeInTime = 1;
		m_fFadeOutTime = 2;
		m_fLife = 1;
		CEGUI_START_ADD_STATICPROPERTY( FalagardSelfFitWindow )
		   CEGUI_ADD_STATICPROPERTY( &d_FitTypeProperty );
           CEGUI_ADD_STATICPROPERTY( &d_FitPosProperty );
		   CEGUI_ADD_STATICPROPERTY( &d_MaxWidthProperty );
           CEGUI_ADD_STATICPROPERTY( &cysMinHeightProperty );
           CEGUI_ADD_STATICPROPERTY( &cysFitTextAreaProperty );
		   CEGUI_ADD_STATICPROPERTY( &d_LifeProperty );
           CEGUI_ADD_STATICPROPERTY( &d_FadeOutProperty );
		   CEGUI_ADD_STATICPROPERTY( &d_FadeInProperty );

		CEGUI_END_ADD_STATICPROPERTY
	}

	FalagardSelfFitWindow::~FalagardSelfFitWindow(void)
	{
	}

	void FalagardSelfFitWindow::updateSelf(float elapsed)
	{
		if( m_bFadeMode && m_fCurLife < m_fMaxLife && isVisible() )
		{
			m_fCurLife += elapsed;
			if( m_fCurLife > m_fMaxLife )
			{
				hide();
				return;
			}
			if( m_fCurLife < m_fFadeInTime )  
				setAlpha( m_fCurLife / m_fFadeInTime );
			else if( m_fCurLife < m_fFadeInTime + m_fLife )
				setAlpha( 1 );
			else
				setAlpha( ( m_fMaxLife - m_fCurLife ) / m_fFadeOutTime );
			requestRedraw();
			
		}
	}

    void FalagardSelfFitWindow::setMinHeight(float height)
    {
        if (!std::isfinite(height) || height < 0) throw InvalidRequestException("MinHeight must be finite and nonnegative.");
        d_minHeight = height;
        updateSelfSize();
    }

	void FalagardSelfFitWindow::updateSelfSize(void)
	{
        const FontBase* fnt = getFont();

        if (fnt && !d_text.empty())
        {
            if (d_fitTextArea)
            {
                // The CY name/title look has a 3px inset on every side. The
                // old +2 sizing lost 4px of text area and measured wrapped
                // text even when the label rendered a single centred line.
                const Rect textArea = getTextRenderArea();
                const float insetX = (std::max)(0.0f, getAbsoluteWidth() - textArea.getWidth());
                const float insetY = (std::max)(0.0f, getAbsoluteHeight() - textArea.getHeight());
                const float width = (std::min)(float(d_maxWidth), System::getSingleton().getRenderer()->getRect().getWidth());
                const Rect measure(0, 0, (std::max)(1.0f, width - insetX - 4.0f), 0);
                Size size = fnt->getFormattedSize(d_text, measure, (TextFormatting)d_horzFormatting, d_fScaleX, d_fScaleY);
                size.d_width = std::ceil(size.d_width + insetX + 4.0f);
                size.d_height = (std::max)(d_minHeight, std::ceil(size.d_height + insetY + 4.0f));
                if (getAbsoluteSize() != size) setSize(Absolute, size);
                return;
            }
            Rect area(System::getSingleton().getRenderer()->getRect());
			if(area.getWidth() > (float)d_maxWidth) area.d_right = area.d_left + d_maxWidth;

            // get required size of the tool tip according to the text extents.
			Size sz = fnt->getFormattedSize(d_text, area, CEGUI::WordWrapLeftAligned, d_fScaleX, d_fScaleY);
			sz.d_height += 2; //exten boarder
            if (sz.d_height < d_minHeight) sz.d_height = d_minHeight;
			sz.d_width += 2;
            setSize(Absolute, sz);
        }
        else
        {
            setSize(Absolute, Size(0,d_minHeight));
        }
		requestRedraw();
	}

	void FalagardSelfFitWindow::updateSelfPosition()
	{
		// 根据绑定类型移动位置
		updateSelfSize();
		CEGUI::Point pos = m_ptCenter;
		switch( m_nFitType )
		{
		case SELF_FIT_LEFT:
			pos.d_y -= getAbsoluteHeight()/2.f;
			break;
		case SELF_FIT_RIGHT:
			pos.d_x -= getAbsoluteWidth();
			pos.d_y -= getAbsoluteHeight()/2;
			break;
		case SELF_FIT_TOP:
			pos.d_x -= getAbsoluteWidth() / 2;
			break;
		case SELF_FIT_BOTTOM:
			pos.d_x -= getAbsoluteWidth() / 2;
			pos.d_y -= getAbsoluteHeight();
			break;
		case SELF_FIT_LEFTTOP:
			break;
		case SELF_FIT_LEFTBOTTOM:
			pos.d_y -= getAbsoluteHeight();
			break;
		case SELF_FIT_RIGHTTOP:
			pos.d_x -= getAbsoluteWidth();
			break;
		case SELF_FIT_RIGHTBOTOM:
			pos.d_x -= getAbsoluteWidth();
			pos.d_y -= getAbsoluteHeight();
			break;
		case SELF_FIT_CENTER:
			pos.d_x -= getAbsoluteWidth() / 2;
			pos.d_y -= getAbsoluteHeight() / 2;
			break;
		default:
			break;
		}

		setPosition(Absolute, pos);
	}
	void FalagardSelfFitWindow::onParentSized(WindowEventArgs& e)
	{
		FalagardSimpleText::onParentSized(e);
		updateSelfSize();
	}

	// 重新计算边框尺寸
	void FalagardSelfFitWindow::setText( const String& text )
	{
		Window::setText(text);

		updateSelfSize();
		m_fCurLife = 0;
		m_fMaxLife = m_fLife + m_fFadeInTime + m_fFadeOutTime;
		if( text.empty() )	hide();
	}

	namespace FalagardSelfFitProperties
	{
		//////////////////////////////////////////////////////////////////////////
		String	MaxWidth::get(const PropertyReceiver* receiver) const
		{
			return PropertyHelper::intToString(static_cast<const FalagardSelfFitWindow*>(receiver)->getMaxWidth());
		}
		void MaxWidth::set(PropertyReceiver* receiver, const String& value)
		{
			static_cast<FalagardSelfFitWindow*>(receiver)->setMaxWidth( PropertyHelper::stringToInt( value ) );
		}

		//////////////////////////////////////////////////////////////////////////
		String	FitType::get(const PropertyReceiver* receiver) const
		{
			return "";
		}
		void	FitType::set(PropertyReceiver* receiver, const String& value)
		{
			int nType = 0;
			if( value == (utf8*)"Center" )
			{
				nType = FalagardSelfFitWindow::SELF_FIT_CENTER;
			}
			else if( value == (utf8*)"Left" )
			{
				nType = FalagardSelfFitWindow::SELF_FIT_LEFT;
			}
			else if( value == (utf8*)"Right" )
			{
				nType = FalagardSelfFitWindow::SELF_FIT_RIGHT;
			}
			else if( value == (utf8*)"Top" )
			{
				nType = FalagardSelfFitWindow::SELF_FIT_TOP;
			}
			else if( value == (utf8*)"Bottom" )
			{
				nType = FalagardSelfFitWindow::SELF_FIT_BOTTOM;
			}
			else if( value == (utf8*)"LeftTop" )
			{
				nType = FalagardSelfFitWindow::SELF_FIT_LEFTTOP;
			}
			else if( value == (utf8*)"RightBottm" )
			{
				nType = FalagardSelfFitWindow::SELF_FIT_RIGHTBOTOM;
			}
			else if( value == (utf8*)"LeftBottom" )
			{
				nType = FalagardSelfFitWindow::SELF_FIT_LEFTBOTTOM;
			}
			else if( value == (utf8*)"RightTop" )
			{
				nType = FalagardSelfFitWindow::SELF_FIT_RIGHTBOTOM;
			}

			static_cast<FalagardSelfFitWindow*>(receiver)->setFitType( nType );
		}

		/////////	/////////////////////////////////////////////////////////////////
			//////////////////////////////////////////////////////////////////////////
		String	FitPosition::get(const PropertyReceiver* receiver) const
		{
			Point nPos = static_cast<const FalagardSelfFitWindow*>(receiver)->getCenter();
			return PropertyHelper::pointToString( nPos );
		}
		void	FitPosition::set(PropertyReceiver* receiver, const String& value)
		{
			static_cast<FalagardSelfFitWindow*>(receiver)->setCenter( PropertyHelper::stringToPoint( value ) );
		}

/////////	/////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
		String	Life::get(const PropertyReceiver* receiver) const
		{
			return "";
		}
		void	Life::set(PropertyReceiver* receiver, const String& value)
		{
			static_cast<FalagardSelfFitWindow*>(receiver)->setLife( PropertyHelper::stringToFloat( value ) );
		}

/////////	/////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
		String	FadeInTime::get(const PropertyReceiver* receiver) const
		{
			return "";
		}
		void	FadeInTime::set(PropertyReceiver* receiver, const String& value)
		{
			static_cast<FalagardSelfFitWindow*>(receiver)->setFadeInTime( PropertyHelper::stringToFloat( value ) );
		}

/////////	/////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
		String	FadeOutTime::get(const PropertyReceiver* receiver) const
		{
			return "";
		}
		void	FadeOutTime::set(PropertyReceiver* receiver, const String& value)
		{
			static_cast<FalagardSelfFitWindow*>(receiver)->setFadeOutTime( PropertyHelper::stringToFloat( value ) );
		}

	}

	 //*************************************************************************/
    //////////////////////////////////////////////////////////////////////////
    Window* FalagardSelfFitFactory::createWindow(const String& name)
    {
        return new FalagardSelfFitWindow(d_type, name);
    }

    void FalagardSelfFitFactory::destroyWindow(Window* window)
    {
		delete window;
    }
};
