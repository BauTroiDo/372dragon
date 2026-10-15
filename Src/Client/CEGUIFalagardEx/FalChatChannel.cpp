#include "FalChatChannel.h"
#include "CEGUIPropertyHelper.h"
#include "CEGUIExceptions.h"
#include "falagard/CEGUIFalWidgetLookManager.h"
#include "falagard/CEGUIFalWidgetLookFeel.h"


// Start of CEGUI namespace section
namespace CEGUI
{
	//===================================================================================
	//
	// FalagardChatChannel
	//
	//===================================================================================
    namespace {
        class CysChannelBkgProperty : public Property {
        public:
            CysChannelBkgProperty() : Property("ChannelBkg","Three-part row background: dir:left|middle|right set:NAME image:NAME; any other direction is ignored, an unresolved image stays empty.","") {}
            String get(const PropertyReceiver* r) const { return static_cast<const FalagardChatChannel*>(r)->getItemBkgDescriptor(); }
            void set(PropertyReceiver* r,const String& v) { static_cast<FalagardChatChannel*>(r)->setItemBkg(v); }
        } cysChannelBkgProperty;
        class CysHoverColorProperty : public Property {
        public:
            CysHoverColorProperty() : Property("HoverColor","ARGB tint of the channel hover background.","FFFF0000") {}
            String get(const PropertyReceiver* r) const { return PropertyHelper::colourToString(static_cast<const FalagardChatChannel*>(r)->getHoverColor()); }
            void set(PropertyReceiver* r,const String& v) {
                String digits=v;
                if (digits.length()>=2 && digits[0]=='0' && (digits[1]=='x' || digits[1]=='X')) digits=digits.substr(2);
                if (digits.length()!=8) throw InvalidRequestException("HoverColor requires eight ARGB hex digits.");
                argb_t value=0;
                for (size_t i=0;i<8;++i) {
                    const utf32 ch=digits[i]; unsigned digit;
                    if (ch>='0' && ch<='9') digit=ch-'0'; else if (ch>='a' && ch<='f') digit=ch-'a'+10;
                    else if (ch>='A' && ch<='F') digit=ch-'A'+10; else throw InvalidRequestException("Invalid HoverColor hex digit.");
                    value=(value<<4)|digit;
                }
                static_cast<FalagardChatChannel*>(r)->setHoverColor(colour(value));
            }
        } cysHoverColorProperty;
    }
    const utf8  FalagardChatChannel::WidgetTypeName[] = "Falagard/ChatChannel";

	FalagardChatChannelProperties::ItemSize			FalagardChatChannel::d_itemSizeProperty;
	FalagardChatChannelProperties::AnchorPosition	FalagardChatChannel::d_anchorPositionProperty;
	FalagardChatChannelProperties::HoverChannelBkg	FalagardChatChannel::d_hoverChannelBkgProperty;
	FalagardChatChannelProperties::HoverChannel		FalagardChatChannel::d_hoverChannelProperty;
	FalagardChatChannelProperties::HoverChannelName	FalagardChatChannel::d_hoverChannelNameProperty;

	FalagardChatChannel::FalagardChatChannel(const String& type, const String& name) :
        Window(type, name),
		d_itemSize(0.0, 0.0),
		d_anchorPosition(0.0, 0.0),
		d_hoverChannelBkg(0),
		d_hoverChannel(-1),
		d_lastHoverChannel(-1),
		d_pushed(false)
    {
        d_itemBkg[0]=d_itemBkg[1]=d_itemBkg[2]=0;
        d_hoverColour=colour(0xFFFF0000);
        addChatChannelProperties();

		setAlwaysOnTop(true);
    }

    FalagardChatChannel::~FalagardChatChannel()
    {
    }

	void FalagardChatChannel::addChatChannelProperties(void)
    {
		CEGUI_START_ADD_STATICPROPERTY( FalagardChatChannel )
		   CEGUI_ADD_STATICPROPERTY( &d_itemSizeProperty );
           CEGUI_ADD_STATICPROPERTY( &cysChannelBkgProperty );
           CEGUI_ADD_STATICPROPERTY( &cysHoverColorProperty );
		   CEGUI_ADD_STATICPROPERTY( &d_anchorPositionProperty );
		   CEGUI_ADD_STATICPROPERTY( &d_hoverChannelBkgProperty );
		   CEGUI_ADD_STATICPROPERTY( &d_hoverChannelProperty );
		   CEGUI_ADD_STATICPROPERTY( &d_hoverChannelNameProperty );
		CEGUI_END_ADD_STATICPROPERTY
	}

    void FalagardChatChannel::setItemBkg(const String& descriptor)
    {
        // CYS-UILAYOUTS: the grammar is real - client_GL's CEGUIFalagard.dll carries the literals
        // " dir:%15s", "left", "middle", "right" and the named areas ItemBkgLeft/Middle/RightSize.
        // What it does NOT do is throw: the only ChannelBkg value that ships (CY ChatFrame once, GL
        // ChatFrame three times) is "dir:CommonFrame set:Chat image:CommonEditBoxBK", i.e. a direction
        // token that matches none of the three, plus an imageset "Chat" that does not exist
        // (CommonEditBoxBK lives in imageset CommonFrame).  An unknown direction is therefore ignored -
        // no part is written, nothing is drawn, nothing is logged - which is also how the engine treats
        // an image descriptor it cannot resolve (PropertyHelper::stringToImage returns 0 silently).
        // Throwing made ChatFrame, a core HUD window, report an error the real client does not have.
        char direction[16]={}, set[128]={}, imageName[128]={};
        if (sscanf(descriptor.c_str()," dir:%15s set:%127s image:%127s",direction,set,imageName)==3)
        {
            const String dir(direction);
            const int index=dir=="left"?0:dir=="middle"?1:dir=="right"?2:-1;
            if (index>=0)
            {
                const Image* image=PropertyHelper::stringToImage(String("set:")+set+" image:"+imageName);
                d_itemBkg[index]=image;   // unresolved stays null, like every other image property
            }
        }
        d_itemBkgDescriptor=descriptor; requestRedraw();
    }
    const Image* FalagardChatChannel::getItemBkg(int index) const
    {
        if (index<0 || index>=3) throw InvalidRequestException("ChannelBkg index is out of range.");
        return d_itemBkg[index];
    }

	void FalagardChatChannel::onMouseMove(MouseEventArgs& e)
	{
		// base class processing
		Window::onMouseMove(e);

		updateInternalState(e.position);
		e.handled = true;
	}

	void FalagardChatChannel::updateInternalState(const Point& ptMouse)
	{
        if (d_allChannel.empty()) { d_hoverChannel=-1; return; }
		Point pt(ptMouse);

		pt.d_x -= windowToScreenX(0);
		pt.d_y -= windowToScreenY(0);

		Rect absarea(getPixelRect());
		absarea.offset(Point(-absarea.d_left, -absarea.d_top));

		if(absarea.isPointInRect(pt))
		{
			float fItemHeight = absarea.getHeight()/(int)d_allChannel.size();

			d_hoverChannel = (int)(pt.d_y/fItemHeight);
			if(d_lastHoverChannel != d_hoverChannel)
			{
				requestRedraw();
				d_lastHoverChannel = d_hoverChannel;
			}
		}
	}

	void FalagardChatChannel::onMouseButtonDown(MouseEventArgs& e)
	{
		// default processing
		Window::onMouseButtonDown(e);

		if (e.button == LeftButton)
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
	}

	void FalagardChatChannel::onMouseButtonUp(MouseEventArgs& e)
	{
		// default processing
		Window::onMouseButtonUp(e);

		if (e.button == LeftButton)
		{
			releaseInput();

			// event was handled by us.
			e.handled = true;
		}
	}

	void FalagardChatChannel::onMouseLeaves(MouseEventArgs& e)
	{
		// base class processing
		Window::onMouseLeaves(e);

		d_hoverChannel = -1;
		d_lastHoverChannel = -1;
		requestRedraw();
	}

	void FalagardChatChannel::populateRenderCache(void)
	{
        // get WidgetLookFeel for the assigned look.
		const WidgetLookFeel& wlf = WidgetLookManager::getSingleton().getWidgetLook(d_lookName);
        // try and get imagery for our current state
		const StateImagery* imagery = &wlf.getStateImagery("Frame");
        // peform the rendering operation.
		imagery->render(*this);

		const Rect rectIconSize(wlf.getNamedArea("IconSize").getArea().getPixelRect(*this));

		const FontBase* font = getFont();

		Rect absarea(getPixelRect());
		absarea.offset(Point(-absarea.d_left, -absarea.d_top));
		ColourRect final_cols(colour(1.0f, 1.0f, 1.0f));

        if (d_allChannel.empty()) return;
		float fItemHeight = absarea.getHeight()/(int)d_allChannel.size();

		for(int i=0; i<(int)d_allChannel.size(); i++)
		{
			ChannelItem& theChannel = d_allChannel[i];
            // CYS: B uses the three named item areas, repeated for each channel row.
            const char* areas[]={"ItemBkgLeftSize","ItemBkgMiddleSize","ItemBkgRightSize"};
            float left=0;
            for (int part=0;part<3;++part) {
                if (wlf.isNamedAreaDefined(areas[part])) {
                    Rect r=wlf.getNamedArea(areas[part]).getArea().getPixelRect(*this);
                    const float width=r.getWidth();
                    r.offset(Point(left-r.d_left,(fItemHeight-r.getHeight())*.5f+fItemHeight*i-r.d_top));
                    if (d_itemBkg[part]) d_renderCache.cacheImage(*d_itemBkg[part],r,0,final_cols);
                    left+=width;
                } else if (d_itemBkg[part]) {
                    throw UnknownObjectException("Channel background named area is missing.");
                }
            }

			Rect rectIcon(rectIconSize);
			rectIcon.offset(Point(0, (fItemHeight-rectIconSize.getHeight())/2 + fItemHeight*i));
			d_renderCache.cacheImage(
				*theChannel.d_headIcon, rectIcon, 0.0f, final_cols);

			Rect rectText(absarea.d_left, fItemHeight*i,
				absarea.d_right, fItemHeight*(i+1));
			rectText.d_left += rectIcon.getWidth()+2;
			
			if(d_hoverChannelBkg && d_hoverChannel == i)
			{
				d_renderCache.cacheImage(
					*d_hoverChannelBkg, rectText, 0.0f, ColourRect(d_hoverColour));
			}

			if (font) d_renderCache.cacheText(this,
				theChannel.d_strName, font, (TextFormatting)WordWrapLeftAligned, rectText, 0.0f, final_cols);
		}
	}

	void FalagardChatChannel::resizeSelf(void)
	{
		float fTotalHeight = d_itemSize.d_height * (int)d_allChannel.size();
		setSize(Absolute,Size(d_itemSize.d_width, fTotalHeight));

        if (!d_parent) { requestRedraw(); return; }
		float fParentHeight = d_parent->getPixelRect().getHeight();
		if(d_parent->getPixelRect().getWidth() < 1024) fParentHeight += 51;

		setPosition(Absolute,Point(d_anchorPosition.d_x, fParentHeight - d_anchorPosition.d_y - fTotalHeight));
	}

	void FalagardChatChannel::clearAllChannel(void)
	{
		d_allChannel.clear();
		resizeSelf();
	}

	void FalagardChatChannel::addChannel(const String& strType, const String& strIconName, const String& strName)
	{
		ChannelItem newChannel;

		newChannel.d_strType = strType;
		newChannel.d_headIcon = PropertyHelper::stringToImage(strIconName);
		if(!newChannel.d_headIcon) return;
		newChannel.d_strName = strName;

		d_allChannel.push_back(newChannel);
		resizeSelf();
	}

	String FalagardChatChannel::getHoverChannel(void) const
	{
		if(d_hoverChannel >= 0 && d_hoverChannel < (int)d_allChannel.size())
		{
			return d_allChannel[d_hoverChannel].d_strType;
		}
		return String("");
	}

	String FalagardChatChannel::getHoverChannelName(void) const
	{
		if(d_hoverChannel >= 0 && d_hoverChannel < (int)d_allChannel.size())
		{
			return d_allChannel[d_hoverChannel].d_strName;
		}
		return String("");
	}
    //////////////////////////////////////////////////////////////////////////
    /*************************************************************************

        Factory Methods

    *************************************************************************/
    //////////////////////////////////////////////////////////////////////////
	Window* FalagardChatChannelFactory::createWindow(const String& name)
    {
        return new FalagardChatChannel(d_type, name);
    }

    void FalagardChatChannelFactory::destroyWindow(Window* window)
    {
		delete window;
    }
}