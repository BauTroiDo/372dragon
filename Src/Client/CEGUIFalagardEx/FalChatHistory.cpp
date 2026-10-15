#include "FalChatHistory.h"
#include "CEGUIExceptions.h"
#include "CEGUIWindowManager.h"
#include "elements/CEGUIPushButton.h"
#include "elements/CEGUIScrollbar.h"
#include "falagard/CEGUIFalWidgetLookManager.h"
#include "falagard/CEGUIFalWidgetLookFeel.h"
#include "FalChatBoard.h"
#include "CEGUIPropertyHelper.h"
#include <cmath>

// Start of CEGUI namespace section
namespace CEGUI
{
	//===================================================================================
	//
	// FalagardChatHistory/ParentWindow
	//
	//===================================================================================
	const utf8 FalagardChatHistory::ParentWindow::WidgetTypeName[] = "Falagard/ChatHistory/ParentWindow";
	FalagardChatHistory::ParentWindow::ParentWindow(const String& type, const String& name) :
        Window(type, name)
	{
	}

	FalagardChatHistory::ParentWindow::~ParentWindow()
    {
    }

	Window* FalagardChatHistory::ParentWindowFactory::createWindow(const String& name)
    {
		return new FalagardChatHistory::ParentWindow(d_type, name);
    }

	void FalagardChatHistory::ParentWindowFactory::destroyWindow(Window* window)
    {
		delete window;
    }	
	//===================================================================================
	//
	// FalagardChatHistory
	//
	//===================================================================================
    const utf8  FalagardChatHistory::WidgetTypeName[] = "Falagard/ChatHistory";

    namespace {
        class BoardKillTimerProperty : public Property {
        public:
            BoardKillTimerProperty() : Property("BoardKillTimer","Lifetime in seconds for insert modes 3 and 4; 0 disables expiry.","0") {}
            String get(const PropertyReceiver* r) const { return PropertyHelper::intToString(static_cast<const FalagardChatHistory*>(r)->getBoardKillTimer()); }
            void set(PropertyReceiver* r,const String& v) {
                int seconds=0;char tail=0;
                if (sscanf(v.c_str(),"%d %c",&seconds,&tail)!=1 || seconds<0) throw InvalidRequestException("BoardKillTimer requires a nonnegative integer.");
                static_cast<FalagardChatHistory*>(r)->setBoardKillTimer(seconds);
            }
        } boardKillTimerProperty;
        class CysChatChildProperty : public Property {
        public:
            CysChatChildProperty() : Property("ChildItem","Chat row factory: key:ChatBoard name:TYPE.","key:ChatBoard name:WoWLook/ChatBoard") {}
            String get(const PropertyReceiver* r) const { return "key:ChatBoard name:"+static_cast<const FalagardChatHistory*>(r)->getChatBoardType(); }
            void set(PropertyReceiver* r,const String& v) {
                char key[32]={}, name[128]={}, tail=0;
                if (sscanf(v.c_str(),"key:%31s name:%127s %c",key,name,&tail)!=2 || String(key)!="ChatBoard")
                    throw InvalidRequestException("ChildItem requires key:ChatBoard name:TYPE.");
                static_cast<FalagardChatHistory*>(r)->setChatBoardType(name);
            }
        } cysChatChildProperty;
    }
	FalagardChatHistoryProperties::ChatBoardNumber		FalagardChatHistory::d_chatBoardNumProperty;

    FalagardChatHistory::FalagardChatHistory(const String& type, const String& name) :
        Window(type, name), 
		d_parentWindow(0),
		d_vertScrollbar(0),
		d_totalHeight(0),
        d_boardKillTimer(0),
        d_chatBoardType("WoWLook/ChatBoard"),
		d_chatBoardNum(3),
		d_first(true),
        d_toEnd(0),
		d_extendHeight(0)
    {
        addChatHistoryProperties();
    }

    FalagardChatHistory::~FalagardChatHistory()
    {
    }

	void FalagardChatHistory::addChatHistoryProperties(void)
    {
		CEGUI_START_ADD_STATICPROPERTY( FalagardChatHistory )
		   CEGUI_ADD_STATICPROPERTY( &d_chatBoardNumProperty );
           CEGUI_ADD_STATICPROPERTY( &cysChatChildProperty );
           CEGUI_ADD_STATICPROPERTY( &boardKillTimerProperty );
		CEGUI_END_ADD_STATICPROPERTY
	}

	void FalagardChatHistory::initialise(void)
	{
		// create the component sub-widgets
		d_parentWindow = static_cast<ParentWindow*>(WindowManager::getSingleton().getWindow(getName() + "__auto_parent__"));
		d_vertScrollbar = static_cast<Scrollbar*>(WindowManager::getSingleton().getWindow(getName() + "__auto_vscrollbar__"));
		d_toEnd = static_cast<PushButton*>(WindowManager::getSingleton().getWindow(getName() + "__auto_toend_btn__"));
		// alawys show.
		d_vertScrollbar->show();

		d_parentWindow->setChatHistoryWindow(this);
		d_parentWindow->setMouseLButtonHollow(true);

		addChildWindow(d_vertScrollbar);
		addChildWindow(d_toEnd);

		//Resize child window(VerscrollBar and ParentWindow)
		performChildWindowLayout();
		//Resize all child elements.
		performWindowLayout();

		// event subscription
		d_vertScrollbar->setScrollPosition(0);
		d_vertScrollbar->subscribeEvent(Scrollbar::EventScrollPositionChanged, Event::Subscriber(&FalagardChatHistory::handleScrollbarChange, this));
		d_toEnd->subscribeEvent(PushButton::EventMouseButtonDown, Event::Subscriber(&FalagardChatHistory::handleToEndBtnClick, this));
	}

	Rect FalagardChatHistory::getTextRenderArea(void) const
	{
		return d_parentWindow->getPixelRect();
	}

    void FalagardChatHistory::onMouseWheel(MouseEventArgs& e)
    {
        Window::onMouseWheel(e);
        if (!e.handled && d_vertScrollbar && d_vertScrollbar->isVisible() &&
            d_vertScrollbar->getDocumentSize() > d_vertScrollbar->getPageSize())
        {
            d_vertScrollbar->setScrollPosition(d_vertScrollbar->getScrollPosition() -
                d_vertScrollbar->getStepSize() * e.wheelChange);
            e.handled = true;
        }
    }

	void FalagardChatHistory::onSized(WindowEventArgs& e)
	{
		Window::onSized(e);

		performWindowLayout();
		requestRedraw();
	}

	/*************************************************************************
		Insert a chat string to chat board list.
	*************************************************************************/
    void FalagardChatHistory::setChatBoardType(const String& value)
    {
        if (value.empty()) throw InvalidRequestException("ChatBoard child type cannot be empty.");
        // Do not instantiate children during look property initialization.
        d_chatBoardType=value;
    }
    void FalagardChatHistory::setBoardKillTimer(int seconds)
    {
        if (seconds<0) throw InvalidRequestException("BoardKillTimer cannot be negative.");
        d_boardKillTimer=seconds;
    }
    void FalagardChatHistory::updateSelf(float elapsed)
    {
        Window::updateSelf(elapsed);
        if (!(elapsed>0) || !std::isfinite(elapsed)) return;
        bool changed=false;
        for (std::map<FalagardChatBoard*,float>::iterator it=d_boardTimers.begin();it!=d_boardTimers.end();) {
            it->second-=elapsed;
            if (it->second>0) { ++it; continue; }
            FalagardChatBoard* row=it->first;
            it=d_boardTimers.erase(it);
            m_listChatBoard.remove(row);
            if (d_parentWindow) d_parentWindow->removeChildWindow(row);
            // CY owns rows through WindowManager; deferred destruction avoids detached leaks.
            WindowManager::getSingleton().destroyWindow(row);
            changed=true;
        }
        if (changed && d_parentWindow) performWindowLayout();
    }
	void FalagardChatHistory::insertChatString(const String& strChat)
    {
        insertChatString(0,strChat,0);
    }
    FalagardChatBoard* FalagardChatHistory::insertChatString(uint id,const String& strChat,int mode)
	{
        if (mode<0 || mode>4) throw InvalidRequestException("Unknown chat insert mode.");
        if (mode==2) { performWindowLayout(); return 0; }
        Window* created=WindowManager::getSingleton().createWindow(d_chatBoardType);
        FalagardChatBoard* pWindow=dynamic_cast<FalagardChatBoard*>(created);
        if (!pWindow) { WindowManager::getSingleton().destroyWindow(created); throw InvalidRequestException("ChatBoard child factory has the wrong native type."); }
        if (!d_parentWindow || !d_vertScrollbar) {
            WindowManager::getSingleton().destroyWindow(pWindow);
            throw InvalidRequestException("ChatHistory children are not initialized.");
        }
        pWindow->setID(id);
		pWindow->setText(strChat);
		pWindow->show();
		//pWindow->setMouseLButtonHollow(true);

		if(m_listChatBoard.size() == d_chatBoardNum && m_listChatBoard.size() > 0)
		{
            FalagardChatBoard* old=m_listChatBoard.front();
            d_boardTimers.erase(old);
            d_parentWindow->removeChildWindow(old);
            m_listChatBoard.pop_front();
            WindowManager::getSingleton().destroyWindow(old);
		}

		d_parentWindow->addChildWindow(pWindow);

		m_listChatBoard.push_back(pWindow);
        if ((mode==3 || mode==4) && d_boardKillTimer>0) d_boardTimers[pWindow]=float(d_boardKillTimer);
        if (mode==1 || mode==3) return pWindow;

		float posEnd = d_vertScrollbar->getDocumentSize()-d_vertScrollbar->getPageSize();
		bool bPosEnd = (posEnd - d_vertScrollbar->getScrollPosition() < 10)?true:false;

		float fWinHeight = pWindow->resizeSelf(getTextRenderArea().getWidth());
		//use d_extendHeight first.
		if(d_extendHeight > 0.0f)
		{
			d_extendHeight = (d_extendHeight - fWinHeight > 0.0f)?(d_extendHeight - fWinHeight):0.0f;
		}

		performWindowLayout();

		if(bPosEnd || (d_vertScrollbar->getDocumentSize() > d_vertScrollbar->getPageSize() && d_first))
		{
			//scroll to end
			d_vertScrollbar->setScrollPosition(
				d_vertScrollbar->getDocumentSize()-d_vertScrollbar->getPageSize());
			d_first = false;
		}

		if(!bPosEnd && (m_listChatBoard.size() == d_chatBoardNum && d_vertScrollbar->getScrollPosition()))
		{
			Rect absarea(getTextRenderArea());
			//scroll up a new chatboard window's height
			d_vertScrollbar->setScrollPosition(
				d_vertScrollbar->getScrollPosition() - fWinHeight);
		}
        return pWindow;
	}

	/*************************************************************************
		Remove all chat boards.
	*************************************************************************/
	void FalagardChatHistory::removeAllChatStrings()
	{
        d_boardTimers.clear();
        for (std::list<FalagardChatBoard*>::iterator it=m_listChatBoard.begin();it!=m_listChatBoard.end();++it)
            WindowManager::getSingleton().destroyWindow(*it);

		m_listChatBoard.clear();
		d_extendHeight = 0.0f;

		performWindowLayout();

		d_first = false;
	}

	/*************************************************************************
	Extend a Clear Region in history window.
	*************************************************************************/
	void FalagardChatHistory::extendClearRegion()
	{
		if(m_listChatBoard.empty())
		{
			d_extendHeight = 0.0f;
			return;
		}

		//scroll to end before extend
		scrollToEnd();

		Rect absarea(getTextRenderArea());
		d_extendHeight = absarea.getHeight();	

		performWindowLayout();
		//set new scroll pos after extend
		d_vertScrollbar->setScrollPosition(
			d_vertScrollbar->getDocumentSize()-d_vertScrollbar->getPageSize()+d_extendHeight);
	}

	/*************************************************************************
		Scroll to End.
	*************************************************************************/
	void FalagardChatHistory::scrollToEnd()
	{
		d_extendHeight = 0.0f;
		performWindowLayout();
		//scroll to end
		d_vertScrollbar->setScrollPosition(
			d_vertScrollbar->getDocumentSize()-d_vertScrollbar->getPageSize());
	}

	/*************************************************************************
		Recaculate all sub window size.
	*************************************************************************/
	void FalagardChatHistory::performWindowLayout(void)
	{
        if (!d_parentWindow || !d_vertScrollbar) return;
		Rect absarea(getTextRenderArea());

		std::list< FalagardChatBoard* >::iterator it;
		float fHeightNow = 0.0f;

		for(it=m_listChatBoard.begin(); it!=m_listChatBoard.end(); it++)
		{
			FalagardChatBoard& child = *(*it);

			float childHeight = child.resizeSelf(absarea.getWidth());

			child.setSize(Absolute, Size(absarea.getWidth(), childHeight));
			child.setPosition(Absolute, Point(0.0f, fHeightNow-d_vertScrollbar->getScrollPosition()));
			child.requestRedraw();

			fHeightNow += childHeight;
		}

		d_totalHeight = fHeightNow + d_extendHeight;

		configureScrollbars();
	}

	void FalagardChatHistory::configureScrollbars()
	{
		// no scrollbars?  Can't configure then!
		if(!d_vertScrollbar) return;

		Rect initialArea(getTextRenderArea());

		//
		// Set up scroll bar values
		//
		Rect renderArea(getTextRenderArea());

		d_vertScrollbar->setDocumentSize(d_totalHeight);
		d_vertScrollbar->setPageSize(renderArea.getHeight());
		d_vertScrollbar->setStepSize(ceguimax(1.0f, renderArea.getHeight() / 10.0f));
		d_vertScrollbar->setScrollPosition(d_vertScrollbar->getScrollPosition());

		requestRedraw();
		d_parentWindow->requestRedraw();
	}

	/*************************************************************************
		Handler called when the scroll bar positions change
	*************************************************************************/
	bool FalagardChatHistory::handleScrollbarChange(const EventArgs& e)
	{
		performWindowLayout();

		requestRedraw();
		d_parentWindow->requestRedraw();
		return true;
	}

	/*************************************************************************
	Handler called when when the toEnd button clicked
	*************************************************************************/
	bool FalagardChatHistory::handleToEndBtnClick(const EventArgs& e)
	{
		scrollToEnd();
		return true;
	}

    //////////////////////////////////////////////////////////////////////////
    /*************************************************************************

        Factory Methods

    *************************************************************************/
    //////////////////////////////////////////////////////////////////////////
    Window* FalagardChatHistoryFactory::createWindow(const String& name)
    {
        return new FalagardChatHistory(d_type, name);
    }

    void FalagardChatHistoryFactory::destroyWindow(Window* window)
    {
		delete window;
    }
}
