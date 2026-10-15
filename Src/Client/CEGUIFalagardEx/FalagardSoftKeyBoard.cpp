
#include ".\falagardsoftkeyboard.h"
#include "ceguipropertyhelper.h"
#include "ceguiinputevent.h"
#include "elements\ceguieditbox.h"
#include "ceguiwindowmanager.h"
#include "ceguiimagesetmanager.h"
#include "ceguiimageset.h"
#include "CEGUIExceptions.h"
namespace CEGUI
{
    namespace {
        const Image* cysKeyImage(const String& value, int& type) {
            char set[128] = {}, image[128] = {}, tail = 0;
            if (sscanf(value.c_str(), "type:%d set:%127s image:%127s %c", &type,set,image,&tail) != 3 || type < 0 || type >= BUTTON_TYPE_NUMBER)
                throw InvalidRequestException("Soft key image requires type:0..3 set:NAME image:NAME.");
            return &ImagesetManager::getSingleton().getImageset(set)->getImage(image);
        }
        class CysKeyNormalImageProperty : public Property {
        public:
            CysKeyNormalImageProperty() : Property("NormalImage", "Normal key image; type:0..3 set:NAME image:NAME.", "") {}
            String get(const PropertyReceiver* r) const { return "type:0 " + PropertyHelper::imageToString(static_cast<const FalagardSoftKeyBoard*>(r)->getNormalImage(0)); }
            void set(PropertyReceiver* r,const String& value) { int type = -1; const Image* image = cysKeyImage(value,type); static_cast<FalagardSoftKeyBoard*>(r)->setNormalImage(type,image); }
        } cysKeyNormalImageProperty;
    }
    const String FalagardSoftKeyBoard::EventNamespace("FalagardSoftKeyBoard");
	const utf8 FalagardSoftKeyBoard::WidgetTypeName[] = "Falagard/SoftKeyWindow";

	FalagardSoftKeyProperties::HoverImage   FalagardSoftKeyBoard::d_hoverImage;
	FalagardSoftKeyProperties::PushedImage   FalagardSoftKeyBoard::d_pushedImage;
	FalagardSoftKeyProperties::KeySize      FalagardSoftKeyBoard::d_keySize;

	const String FalagardSoftKeyBoard::EventReturn( (utf8*)"ReturnPush" );

	FalagardSoftKeyBoard::FalagardSoftKeyBoard(const String& type, const String& name):
			FalagardStaticImage( type, name )
	{
		m_pAimEditBox = NULL;
		m_bShiftDown = false;
		m_pLastKey = NULL;
		m_pCurrentKey = NULL;
		GridWidth = 30;
		GridHeight = 30;
		for( int i = 0; i < BUTTON_TYPE_NUMBER; i ++ )
		{
			m_pNormalImage[ i ] = NULL;
			m_pHoverImage[ i ] = NULL;
			m_pPushedImage[ i ] = NULL;
		}
		m_bKeyDown = false;
		CEGUI_START_ADD_STATICPROPERTY( FalagardSoftKeyBoard )
			CEGUI_ADD_STATICPROPERTY( &d_hoverImage );
			CEGUI_ADD_STATICPROPERTY( &d_pushedImage );
			CEGUI_ADD_STATICPROPERTY( &d_keySize );
            CEGUI_ADD_STATICPROPERTY( &cysKeyNormalImageProperty );
		CEGUI_END_ADD_STATICPROPERTY
	}

	FalagardSoftKeyBoard::~FalagardSoftKeyBoard(void)
	{
	}
	void FalagardSoftKeyBoard::SetActiveEditBox( String& windowName )
	{
		m_pAimEditBox = WindowManager::getSingleton().getWindow( windowName );
	}
	void FalagardSoftKeyBoard::onMouseButtonUp( MouseEventArgs& e )
	{
		if( m_bKeyDown && e.button == LeftButton && m_pCurrentKey && m_pAimEditBox )
		{
			m_pAimEditBox->activate();
			switch( m_pCurrentKey->m_pKeyDefine->nType )
			{
			case SoftKey_Back:
				((Editbox*)m_pAimEditBox)->handleBackspace();
				break;
			case SoftKey_Return:
				fireEvent(EventReturn, e, EventNamespace);
				break;
			case SoftKey_Shift:
				m_bShiftDown = !m_bShiftDown;
				ResetAllKey();
				break;
			default:
				((Editbox*)m_pAimEditBox)->addCharater( m_pCurrentKey->m_pKeyDefine->uChar );
				break;
			}
			m_bKeyDown = false;
		}
		releaseInput();
		requestRedraw();
	}
	void FalagardSoftKeyBoard::onMouseLeaves( MouseEventArgs& e )
	{
		m_bKeyDown = false;
		m_pCurrentKey = NULL;
		releaseInput();
		requestRedraw();
	}
	void FalagardSoftKeyBoard::onMouseButtonDown( MouseEventArgs& e )
	{
		
		if( e.button == LeftButton && m_pCurrentKey )
		{
			m_bKeyDown = true;
			requestRedraw();
			activate();
			captureInput();
		}

	}
	void FalagardSoftKeyBoard::onMouseMove( MouseEventArgs& e )
	{
		updateKeyPosition( e.position );
		Window::onMouseMove( e );
	}
	void FalagardSoftKeyBoard::updateKeyPosition( const Point& screenPos )
	{
		m_pCurrentKey = getKeyByPosition( screenPos );
		if( m_pCurrentKey )
		{
			switch( m_pCurrentKey->m_pKeyDefine->nType )
			{
			case SoftKey_Back:
				m_pCurrentKey = &m_aKeyPosList[ SoftKey_Back ].at( 0 );
				break;
			case SoftKey_Shift:
				m_pCurrentKey = &m_aKeyPosList[ SoftKey_Shift ].at( 0 );
				break;
			case SoftKey_Return:
				m_pCurrentKey = &m_aKeyPosList[ SoftKey_Return ].at( 0 );
				break;
			default:
				break;
			}
		}
		if( m_pCurrentKey != m_pLastKey ) // 如果变了，就把旧的关闭
		{	
			setKeyHover( m_pLastKey, false );
			setKeyHover( m_pCurrentKey, true );
			m_pLastKey = m_pCurrentKey;
			m_bKeyDown = false;
			requestRedraw();
		}
	}
	SKey_Position* FalagardSoftKeyBoard::getKeyByPosition( const Point& screenPos )
	{
		Point pos = screenPos;
		pos.d_x -= getPixelRect().d_left;
		pos.d_y -= getPixelRect().d_top;
		for( int j = 0; j < SoftKey_TypeNumber; j ++ )
		{
			for( int i = 0; i < int( m_aKeyPosList[ j ].size() ); i ++ )
			{
				SKey_Position *pItem = &m_aKeyPosList[ j ].at( i );
				CEGUI::Rect rect;
				rect.d_left   = pItem->m_Pos.d_x;
				rect.d_top    = pItem->m_Pos.d_y;
				rect.d_right  = rect.d_left + GridWidth;
				rect.d_bottom = rect.d_top + GridHeight;
				if( rect.isPointInRect( pos ) )
				{
					return pItem;
				}
			}
		}
		return NULL;
	}
	void FalagardSoftKeyBoard::setKeyHover( SKey_Position* pKey, bool bHover )
	{
		if( pKey )
			pKey->setHover( bHover );
	}
	void FalagardSoftKeyBoard::setKeyPosition( int x, int y, int nType )
	{
		SKey_Position item;
		item.m_Pos.d_x = x * GridWidth; 
		item.m_Pos.d_y = y * GridHeight;
		m_aKeyPosList[ nType ].push_back( item );
	}
	void FalagardSoftKeyBoard::setKeyDefine( utf32 nchar, int nType )
	{
		SKey_Define  define;
		define.uChar = nchar;
		define.nType = nType;
		m_aKeyDefineList[ nType ].push_back( define );
	}
	void FalagardSoftKeyBoard::onShown(WindowEventArgs& e)
	{
		ResetAllKey();
		FalagardStaticImage::onShown( e );
	}
	// 重值所有的键
	void FalagardSoftKeyBoard::ResetAllKey()
	{
		assert(m_aKeyPosList[ SoftKey_Punctuation ].size() == m_aKeyDefineList[ SoftKeyDef_Punctuation ].size() );

		// 随机排列字符和字母
		int nStart = rand() % int( m_aKeyPosList[ SoftKey_Punctuation ].size() );
		int nIndex;
		for( int i = 0; i < int( m_aKeyPosList[ SoftKey_Punctuation ].size() ); i ++ )
		{
			nIndex = i + nStart;
			if( nIndex >= int( m_aKeyPosList[ SoftKey_Punctuation ].size() ) )
				nIndex = nIndex - int( m_aKeyPosList[ SoftKey_Punctuation ].size() );
			SKey_Position* pItem = &m_aKeyPosList[ SoftKey_Punctuation ].at( i );
			pItem->m_pKeyDefine  = &m_aKeyDefineList[ SoftKeyDef_Punctuation ].at( nIndex );
		}
		nStart = rand() % int( m_aKeyPosList[ SoftKey_Number ].size() );
		for( int i = 0; i < int( m_aKeyPosList[ SoftKey_Number ].size() ); i ++ )
		{
			nIndex = i + nStart;
			if( nIndex >= int( m_aKeyPosList[ SoftKey_Number ].size() ) )
				nIndex = nIndex - int( m_aKeyPosList[ SoftKey_Number ].size() );
			SKey_Position* pItem = &m_aKeyPosList[ SoftKey_Number ].at( i );
			pItem->m_pKeyDefine  = &m_aKeyDefineList[ SoftKeyDef_Number ].at( nIndex );
		}
		nStart = rand() % int( m_aKeyPosList[ SoftKey_Word ].size() );
		for( int i = 0; i < int( m_aKeyPosList[ SoftKey_Word ].size() ); i ++ )
		{
			nIndex = i + nStart;
			if( nIndex >= int( m_aKeyPosList[ SoftKey_Word ].size() ) )
				nIndex = nIndex - int( m_aKeyPosList[ SoftKey_Word ].size() );

			SKey_Position* pItem = &m_aKeyPosList[ SoftKey_Word ].at( i );
			if( m_bShiftDown )
				pItem->m_pKeyDefine  = &m_aKeyDefineList[ SoftKeyDef_Capital_Word ].at( nIndex );
			else
				pItem->m_pKeyDefine  = &m_aKeyDefineList[ SoftKeyDef_Lower_Word ].at( nIndex );
		}

		
		for( int i = 0; i < int ( m_aKeyPosList[ SoftKey_Back ].size() ); i ++ )
		{
			SKey_Position* pItem = &m_aKeyPosList[ SoftKey_Back ].at( i );
			pItem->m_pKeyDefine = &m_KeyDefBack;
		}
		for( int i = 0; i < int ( m_aKeyPosList[ SoftKey_Return].size() ); i ++ )
		{
			SKey_Position* pItem = &m_aKeyPosList[ SoftKey_Return ].at( i );
			pItem->m_pKeyDefine = &m_KeyDefReturn;
		}
		for( int i = 0; i < int ( m_aKeyPosList[ SoftKey_Shift].size() ); i ++ )
		{
			SKey_Position* pItem = &m_aKeyPosList[ SoftKey_Shift ].at( i );
			pItem->m_pKeyDefine = &m_KeyDefShift;
		}
		requestRedraw();
	}
	void FalagardSoftKeyBoard::initialise()
	{
		// 符号
		for( int i = 33; i < 48; i ++ )
			setKeyDefine( i, SoftKeyDef_Punctuation );
		for( int i = 58; i < 65; i ++ )
			setKeyDefine( i, SoftKeyDef_Punctuation );
		for( int i = 91; i < 97; i ++ )
			setKeyDefine( i, SoftKeyDef_Punctuation );
		for( int i = 123; i < 127; i ++ )
			setKeyDefine( i, SoftKeyDef_Punctuation );
		// 数字
		for( int i = 48; i < 58; i ++ )
			setKeyDefine( i, SoftKeyDef_Number );
		// 小写字符
		for( int i = 97; i < 123; i ++ )
			setKeyDefine( i, SoftKeyDef_Lower_Word );
		// 大写字符
		for( int i = 65; i < 91; i ++ )
			setKeyDefine( i, SoftKeyDef_Capital_Word );

		m_KeyDefReturn.nType = SoftKey_Return;
		m_KeyDefShift.nType = SoftKey_Shift;
		m_KeyDefBack.nType = SoftKey_Back;

		resetAllPosition();
		FalagardStaticImage::initialise();
		
	}
	void FalagardSoftKeyBoard::setKeySize( const Size& size )
	{
		GridWidth = size.d_width;
		GridHeight = size.d_height;
		resetAllPosition();
	}
	void FalagardSoftKeyBoard::resetAllPosition()
	{
		for( int i = 0; i < SoftKey_TypeNumber; i ++ )
			m_aKeyPosList[ i ].clear();
		SKey_Position item;
		for( int i = 0; i < 10; i ++ ) // 第二排
		{
			setKeyPosition( i + 1, 1, SoftKey_Number );
		}
		// 标点符号
		for( int i = 0; i < 13; i ++ )
		{
			setKeyPosition( i , 0, SoftKey_Punctuation );
		}
		// 第二排的第一个
		setKeyPosition( 0, 1, SoftKey_Punctuation);
		setKeyPosition( 11,1, SoftKey_Punctuation);
		setKeyPosition( 12,1, SoftKey_Punctuation);
		setKeyPosition( 10,2, SoftKey_Punctuation);
		setKeyPosition( 11,2, SoftKey_Punctuation);
		setKeyPosition( 12,2, SoftKey_Punctuation);
		setKeyPosition( 13,2, SoftKey_Punctuation);
		setKeyPosition( 9,3, SoftKey_Punctuation);
		setKeyPosition( 10,3, SoftKey_Punctuation);
		setKeyPosition( 11,3, SoftKey_Punctuation);
		setKeyPosition( 12,3, SoftKey_Punctuation);
		setKeyPosition( 7,4, SoftKey_Punctuation);
		setKeyPosition( 8,4, SoftKey_Punctuation);
		setKeyPosition( 9,4, SoftKey_Punctuation);
		setKeyPosition( 10,4, SoftKey_Punctuation);
		setKeyPosition( 11,4, SoftKey_Punctuation);
		setKeyPosition( 12,4, SoftKey_Punctuation);
		setKeyPosition( 13,4, SoftKey_Punctuation);
		setKeyPosition( 14,4, SoftKey_Punctuation);

		// 字母
		for( int i = 0; i < 10; i ++ )
			setKeyPosition( i , 2, SoftKey_Word );
		for( int i = 0; i < 9; i ++ )
			setKeyPosition( i , 3, SoftKey_Word );
		for( int i = 0; i < 7; i ++ )
			setKeyPosition( i , 4, SoftKey_Word );

		
		setKeyPosition( 13,0,SoftKey_Back );
		setKeyPosition( 14,0,SoftKey_Back );

		setKeyPosition( 13,1,SoftKey_Shift );
		setKeyPosition( 14,1,SoftKey_Shift );

		
		setKeyPosition( 13,3,SoftKey_Return );
		setKeyPosition( 14,2,SoftKey_Return );
		setKeyPosition( 14,3,SoftKey_Return );
		
		
		ResetAllKey();
	}
    void FalagardSoftKeyBoard::populateRenderCache()
    {
        FalagardStaticImage::populateRenderCache();
        ColourRect colours(colour(1,1,1,getEffectiveAlpha()));
        const FontBase* font = getFont();
        auto keyRect = [&](const SKey_Position& key, int type) {
            Rect r(key.m_Pos, Size(GridWidth, GridHeight));
            if (type == SoftKey_Back || type == SoftKey_Shift || type == SoftKey_Return)
                r.d_right += GridWidth;
            if (type == SoftKey_Return) r.d_top -= GridHeight;
            return r;
        };
        // CYS: normal key imagery precedes text; special keys span multiple cells.
        for (int group = 0; group < SoftKey_TypeNumber; ++group) {
            const int type = group == SoftKey_Back ? BUTTON_TYPE_BACK : group == SoftKey_Shift ? BUTTON_TYPE_SHIFT : group == SoftKey_Return ? BUTTON_TYPE_RETURN : BUTTON_TYPE_NORMAL;
            const size_t count = type == BUTTON_TYPE_NORMAL ? m_aKeyPosList[group].size() : (m_aKeyPosList[group].empty() ? 0 : 1);
            for (size_t i = 0; i < count; ++i) {
                const SKey_Position& key = m_aKeyPosList[group][i];
                Rect r = keyRect(key,group);
                if (m_pNormalImage[type]) d_renderCache.cacheImage(*m_pNormalImage[type],r,0,colours);
                if (font && key.m_pKeyDefine && group < SoftKey_Type_Number) {
                    String text; text = key.m_pKeyDefine->uChar;
                    const float height = font->getFormattedSize(text,r,CEGUI::LeftAligned).d_height;
                    r.d_top += (r.getHeight()-height)*.5f;
                    d_renderCache.cacheText(this,text,font,Centred,r,0,colours,&r,true);
                }
            }
        }
        if (m_pCurrentKey && m_pCurrentKey->m_pKeyDefine) {
            const int keyType = m_pCurrentKey->m_pKeyDefine->nType;
            const int type = keyType == SoftKey_Back ? BUTTON_TYPE_BACK : keyType == SoftKey_Shift ? BUTTON_TYPE_SHIFT : keyType == SoftKey_Return ? BUTTON_TYPE_RETURN : BUTTON_TYPE_NORMAL;
            const Image* overlay = m_bKeyDown ? m_pPushedImage[type] : m_pHoverImage[type];
            if (overlay) d_renderCache.cacheImage(*overlay,keyRect(*m_pCurrentKey,keyType),0,colours);
        }
    }
    void FalagardSoftKeyBoard::setNormalImage(int type,const Image* image)
    {
        if (type < 0 || type >= BUTTON_TYPE_NUMBER) throw InvalidRequestException("Soft key image type is out of range.");
        m_pNormalImage[type] = image; requestRedraw();
    }
    const Image* FalagardSoftKeyBoard::getNormalImage(int type) const
    {
        if (type < 0 || type >= BUTTON_TYPE_NUMBER) throw InvalidRequestException("Soft key image type is out of range.");
        return m_pNormalImage[type];
    }
    void FalagardSoftKeyBoard::setHoverImage(int type,const Image* image)
    {
        if (type < 0 || type >= BUTTON_TYPE_NUMBER) throw InvalidRequestException("Soft key image type is out of range.");
        m_pHoverImage[type] = image; requestRedraw();
    }
    void FalagardSoftKeyBoard::setPushedImage(int type,const Image* image)
    {
        if (type < 0 || type >= BUTTON_TYPE_NUMBER) throw InvalidRequestException("Soft key image type is out of range.");
        m_pPushedImage[type] = image; requestRedraw();
    }

	namespace FalagardSoftKeyProperties
	{
		String	KeySize::get(const PropertyReceiver* receiver) const
		{
			return "";
		}
		void	KeySize::set(PropertyReceiver* receiver, const String& value)
		{
			static_cast<FalagardSoftKeyBoard*>(receiver)->setKeySize( PropertyHelper::stringToSize( value ) );
		}

		String	HoverImage::get(const PropertyReceiver* receiver) const
		{
			return "";
		}
        void HoverImage::set(PropertyReceiver* receiver,const String& value)
        {
            int type = -1;
            const Image* image = cysKeyImage(value,type);
            static_cast<FalagardSoftKeyBoard*>(receiver)->setHoverImage(type,image);
        }
		String	PushedImage::get(const PropertyReceiver* receiver) const
		{
			return "";
		}
        void PushedImage::set(PropertyReceiver* receiver,const String& value)
        {
            int type = -1;
            const Image* image = cysKeyImage(value,type);
            static_cast<FalagardSoftKeyBoard*>(receiver)->setPushedImage(type,image);
        }
	};

		 //*************************************************************************/
    //////////////////////////////////////////////////////////////////////////
    Window* FalagardSoftKeyFactory::createWindow(const String& name)
    {
        return new FalagardSoftKeyBoard(d_type, name);
    }

    void FalagardSoftKeyFactory::destroyWindow(Window* window)
    {
		delete window;
    }
}