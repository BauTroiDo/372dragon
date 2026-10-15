#include ".\falagardsuperprogress.h"
#include "CEGUIPropertyHelper.h"
#include "falagard/CEGUIFalWidgetLookManager.h"
#include "falagard/CEGUIFalWidgetLookFeel.h"
#include <cmath>
namespace CEGUI
{

    namespace {
        class LightEnableProperty : public Property {
        public:
            LightEnableProperty() : Property("LightEnable","Draw the look light at the progress head.","False") {}
            String get(const PropertyReceiver* r) const { return PropertyHelper::boolToString(static_cast<const FalagardSuperProgress*>(r)->getLightEnable()); }
            void set(PropertyReceiver* r,const String& v) { static_cast<FalagardSuperProgress*>(r)->setLightEnable(PropertyHelper::stringToBool(v)); }
        } lightEnableProperty;
        class FadeStateProperty : public Property {
        public:
            FadeStateProperty() : Property("SetFadeState","0 resets a cast bar; 2 fades it out and hides it.","0") {}
            String get(const PropertyReceiver* r) const { return PropertyHelper::intToString(static_cast<const FalagardSuperProgress*>(r)->getFadeState()); }
            void set(PropertyReceiver* r,const String& v) { static_cast<FalagardSuperProgress*>(r)->setFadeState(PropertyHelper::stringToInt(v)); }
        } fadeStateProperty;
    }
	const utf8  FalagardSuperProgress::WidgetTypeName[] = "Falagard/SuperProgress";

	FalagardSuperProgressProperties::ProgressImage			FalagardSuperProgress::d_effectImageProperty;
	FalagardSuperProgressProperties::EffectColor			FalagardSuperProgress::d_effectAlphaProperty;
	FalagardSuperProgressProperties::EffectColorLevel		FalagardSuperProgress::d_EffectColorLevelProperty;
	
	FalagardSuperProgressProperties::MoveSpeed				FalagardSuperProgress::d_MoveSpeedProperty;
		
	FalagardSuperProgress::FalagardSuperProgress( const String& type, const String& name ) : 
		ProgressBar( type, name ), d_lightEnable(false), d_fadeState(0), d_fadeElapsed(0), d_fadeAlpha(1)
	{
		CEGUI_START_ADD_STATICPROPERTY( FalagardSuperProgress )
		   CEGUI_ADD_STATICPROPERTY( &d_effectImageProperty  );
           CEGUI_ADD_STATICPROPERTY( &lightEnableProperty );
           CEGUI_ADD_STATICPROPERTY( &fadeStateProperty );
		   CEGUI_ADD_STATICPROPERTY( &d_MoveSpeedProperty  );
		   CEGUI_ADD_STATICPROPERTY( &d_effectAlphaProperty  );
		   CEGUI_ADD_STATICPROPERTY( &d_EffectColorLevelProperty  );
		CEGUI_END_ADD_STATICPROPERTY

		d_BackImage.setHorzFormatting(RenderableImage::HorzStretched);
		d_BackImage.setVertFormatting(RenderableImage::VertStretched);

		d_MoveSpeed		= 1; // 每毫秒走0.01%;
		d_curPos		= 1;
		d_progress		= 1;
        d_EffectColor=ColourRect(colour(1,1,1,1));
        for (int i=0;i<11;++i) d_EffectColorLevel[i]=ColourRect(colour(1,1,1,1));
	}

	FalagardSuperProgress::~FalagardSuperProgress(void)
	{

	}

	ColourRect& FalagardSuperProgress::getCurColor()
	{
		int nColor = int( d_curPos * 10 );
		if( nColor < 0 ) nColor = 0;
		if( nColor > 10 ) nColor = 10;
		return d_EffectColorLevel[nColor];
	}
	void	FalagardSuperProgress::populateRenderCache()
	{
        // Modern B looks supply Enabled/Disabled and Effect imagery instead of ProgressImage.
        const WidgetLookFeel* look=d_lookName.empty() ? 0 : &WidgetLookManager::getSingleton().getWidgetLook(d_lookName);
        if (look && !d_BackImage.getImage()) {
            if (look->isStateImageryPresent("Background")) look->getStateImagery("Background").render(*this);
            Rect area=look->isNamedAreaDefined("ProgressArea") ? look->getNamedArea("ProgressArea").getArea().getPixelRect(*this) : Rect(0,0,getAbsoluteWidth(),getAbsoluteHeight());
            Rect fill=area;
            fill.setWidth(area.getWidth()*(d_lightEnable ? d_progress : ceguimax(d_curPos,d_progress)));
            const char* state=isDisabled() ? "Disabled" : "Enabled";
            if (look->isStateImageryPresent(state)) look->getStateImagery(state).render(*this,fill,&getCurColor());
            if (!d_lightEnable && d_curPos!=d_progress && look->isStateImageryPresent("Effect")) {
                Rect effect=area;
                effect.d_left+=area.getWidth()*ceguimin(d_curPos,d_progress);
                effect.d_right=area.d_left+area.getWidth()*ceguimax(d_curPos,d_progress);
                look->getStateImagery("Effect").render(*this,effect,&d_EffectColor);
            }
        } else {

		if( d_curPos == d_progress )
			d_rectProgress = Rect( 0, 0, getAbsoluteWidth() * d_progress, getAbsoluteHeight() );
		// 不管是不是有效果,都要画这一步得
		d_BackImage.setColours( getCurColor() );
		d_BackImage.setRect( d_rectProgress );
		d_BackImage.draw( d_renderCache );
		if( d_curPos != d_progress )
		{
			d_BackImage.setColours( d_EffectColor );
			d_BackImage.setRect( d_rectEffect );
			d_BackImage.draw( d_renderCache );
		}
        }
        if (d_lightEnable && look && look->isStateImageryPresent("LightEnable")) {
            const Rect area=look->isNamedAreaDefined("ProgressArea") ? look->getNamedArea("ProgressArea").getArea().getPixelRect(*this) : Rect(0,0,getAbsoluteWidth(),getAbsoluteHeight());
            const Size size=look->isNamedAreaDefined("LightArea") ? look->getNamedArea("LightArea").getArea().getPixelRect(*this).getSize() : Size(area.getHeight(),area.getHeight());
            const float x=area.d_left+area.getWidth()*d_progress-size.d_width*.5f;
            const float y=area.d_top+(area.getHeight()-size.d_height)*.5f;
            look->getStateImagery("LightEnable").render(*this,Rect(Point(x,y),size));
        }
	}

	void   FalagardSuperProgress::setEffectImage( const Image* pImage )
	{
		d_BackImage.setImage( pImage );
	}

	void    FalagardSuperProgress::setEffectColor( ColourRect& color )  
	{
		d_EffectColor = color;
	}
	void   FalagardSuperProgress::setEffectColorLevel( int nIndex, ColourRect&	color )
	{
		for( int i = nIndex; i < 11; i ++ ) // 把以后所有得颜色填成这个颜色
			d_EffectColorLevel[ i ] = color;
	}

    void FalagardSuperProgress::setFadeState(int state)
    {
        // Both CY and GL call 0 on SHOW and 2 on HIDE/BREAK. A new cast must
        // cancel the previous fade; repeated end notifications must not extend it.
        if (state == 0) {
            d_fadeState = 0;
            d_fadeElapsed = 0;
            setAlpha(1.0f);
        } else if (state == 2 && d_fadeState != 2) {
            d_fadeState = 2;
            d_fadeElapsed = 0;
            d_fadeAlpha = getAlpha();
        }
    }
	void	FalagardSuperProgress::updateSelf(float elapsed)
	{
        ProgressBar::updateSelf(elapsed);
        if (d_fadeState == 2 && isVisible() && std::isfinite(elapsed) && elapsed >= 0) {
            const float fadeSeconds = 0.3f;
            d_fadeElapsed += elapsed;
            setAlpha(d_fadeAlpha * ceguimax(0.0f, 1.0f - d_fadeElapsed / fadeSeconds));
            if (d_fadeElapsed >= fadeSeconds) hide();
        }

		if( d_curPos != d_progress )  // 说明需要更新了
		{
			
			float fMoveLength = elapsed * d_MoveSpeed;
			if( d_curPos > d_progress ) // 如果比当前得值,就说名是再减
			{
				d_curPos -= fMoveLength;
				if( d_curPos < d_progress )
					d_curPos = d_progress;
			}
			else
			{
				d_curPos += fMoveLength;
				if( d_curPos > d_progress )
					d_curPos = d_progress;
			}
			if( d_curPos < d_progress )
			{	
				d_rectEffect = Rect( getAbsoluteWidth() * d_curPos, 0, getAbsoluteWidth() * d_progress, getAbsoluteHeight() );
				d_rectProgress = Rect( 0, 0, getAbsoluteWidth() * d_progress, getAbsoluteHeight() );
			}
			else
			{
				d_rectEffect = Rect( getAbsoluteWidth() * d_progress, 0, getAbsoluteWidth() * d_curPos, getAbsoluteHeight() );
				d_rectProgress = Rect( 0, 0, getAbsoluteWidth() * d_curPos, getAbsoluteHeight() );
			}
			if( d_curPos < 0 )
				d_curPos = 0;
			if( d_curPos > 1 )
				d_curPos = 1;
			requestRedraw();
			d_needsRedraw = true;
		}
	
	}
	
	namespace FalagardSuperProgressProperties
	{

		//////////////////////////////////////////////////////////////////////////////////////
		String ProgressImage::get(const PropertyReceiver* receiver) const
		{
			return "";//PropertyHelper::imageToString(static_cast<const FalagardImageListBox*>(receiver)->setNormalImage());
		}

		void ProgressImage::set(PropertyReceiver* receiver, const String& value)
		{
			static_cast<FalagardSuperProgress*>(receiver)->setEffectImage(PropertyHelper::stringToImage(value));
		}

		//////////////////////////////////////////////////////////////////////////////////////
		String EffectColor::get(const PropertyReceiver* receiver) const
		{
			return "";
		}

		void EffectColor::set(PropertyReceiver* receiver, const String& value)
		{
			static_cast<FalagardSuperProgress*>(receiver)->setEffectColor( PropertyHelper::stringToColourRect(value) );
		}
		//////////////////////////////////////////////////////////////////////////////////////
		String EffectColorLevel::get(const PropertyReceiver* receiver) const
		{
			return "";//PropertyHelper::imageToString(static_cast<const FalagardImageListBox*>(receiver)->setNormalImage());
		}

		void EffectColorLevel::set(PropertyReceiver* receiver, const String& value)
		{
			int nIndex = 0;
			argb_t topLeft = 0xFF000000, topRight = 0xFF000000, bottomLeft = 0xFF000000, bottomRight = 0xFF000000;
			sscanf(value.c_str(), "index:%d tl:%8X tr:%8X bl:%8X br:%8X", &nIndex, &topLeft, &topRight, &bottomLeft, &bottomRight );
			static_cast<FalagardSuperProgress*>(receiver)->setEffectColorLevel( nIndex, ColourRect( topLeft, topRight, bottomLeft, bottomRight ) );
		}
		String MoveSpeed::get(const PropertyReceiver* receiver) const
		{
			return "";//PropertyHelper::imageToString(static_cast<const FalagardImageListBox*>(receiver)->setNormalImage());
		}

		void MoveSpeed::set(PropertyReceiver* receiver, const String& value)
		{
			static_cast<FalagardSuperProgress*>(receiver)->setMoveSpeed( PropertyHelper::stringToFloat(value));
		}
	};


	//////////////////////////////////////////////////////////////////////////
    /*************************************************************************

        Factory Methods

    *************************************************************************/
    //////////////////////////////////////////////////////////////////////////
    Window* FalagardSuperProgressFactory::createWindow(const String& name)
    {
        return new FalagardSuperProgress(d_type, name);
    }

    void FalagardSuperProgressFactory::destroyWindow(Window* window)
    {
		delete window;
    }

}
