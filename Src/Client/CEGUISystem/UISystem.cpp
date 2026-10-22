#include "stdafx.h"
#include "UISystem.h"
//#include <OgreRoot.h>//移到了UISystem.h中
#include <CEGUISystem.h>
#include <OgreCEGUIRenderer.h>
#include <TDException.h>
#include <CEGUISchemeManager.h>
#include <CEGUIWindowManager.h>
#include <CEGUIWindowFactoryManager.h>
#include <CEGUILogger.h> // CYS: alias log
#include <CEGUIFontManager.h>
#include "ceguiwindow.h"
#include "uiwindowmng.h"
#include "TDKernel.h"
#include <CEGUIScriptModule.h>
#include "UIScript.h"
#include "TDScriptSystem.h"
#include "UIIconsMng.h"
#include <CEGUIImageset.h>
#include <OgreCEGUITexture.h>
#include <OgreTexture.h>
#include <OgreHardwarePixelBuffer.h>
#include <OgreTextureManager.h>
#include "ceguianimatemanager.h"
#include "ogretimer.h"
#include "UIString.h"
#include "TDInputSystem.h"
#include "TDGfxSystem.h"
#include "..\WxRender\RenderSystem.h"
#include "TDCursorSystem.h"
#include "../CEGUIFalagardEx/FalActionButton.h"
#include "../CEGUIFalagardEx/IFalSuperTooltip.h"
#include "TDActionSystem.h"
#include <CEGUIEventArgs.h>
#include "UICreatureBoardSystem.h"
#include "TDTimeSystem.h"
#include "TDProfile.h"
#include "TDEventDefine.h"
#include "TDFakeObjSystem.h"
#include "elements\CEGUIStaticImage.h"
#include "CEGUIIme.h"
#include "AxTrace.h"
#include "windows.h"
#include "TDGameInterface.h"
#include <CEGUIHyperLinkManager.h>
#include "CysInfoLink.h"	// CYS-INFOLINK: CY key layout "<x>,<y>,<scene>,<type>,<target>"
#include "CysUiEdit.h"		// CYS-UIEDIT: bo sua bo cuc UI ngay trong game
#include "TDObjectSystem.h"	// CYS-INFOPARITY: tObject_Item of a bag action item
#include "UIString.h"
#include "TDVariable.h"
#include "TDWorldSystem.h"

WX_IMPLEMENT_DYNAMIC(CUISystem, GETCLASS(tUISystem));
CUISystem* CUISystem::s_pMe = NULL;
// CYS: keep the Game module independent of CEGUI's DLL import library.
VOID CUISystem::SetClickSoundCallback(void (*callback)(int))
{
    CEGUI::Window::setClickSoundCallback(callback);
}
CUISystem::CUISystem(VOID)
{
	s_pMe = this;	
	//m_pBtnInDragging = NULL;
	m_szNameBtnInDragging = "";
	m_hDraggingCursor = NULL;
	m_bIsDragEnd = false;
	m_bActivePaoPao = true;
	memset(&m_infoUseItem, 0, sizeof(m_infoUseItem));	// CYS-INFOPARITY: nothing pending
}

CUISystem::~CUISystem(VOID)
{
}

VOID CUISystem::InjectInput(VOID)
{
	CEGUI::System& ceguiSystem = CEGUI::System::getSingleton();
	InputEventQueue& queueInput = g_pInputSys->GetInputQueue();
	POINT pt = g_pInputSys->MouseGetPos();

	for(INT i=0; i<(INT)queueInput.size(); i++)
	{
		InputEvent& event = queueInput[i];
		if(event.bProcessed) continue;	//已经处理过的事件

		// CYS-UIEDIT 19/09: bo sua bo cuc UI. `CysUiEdit::Armed()` doc `CYS_UIEDIT` MOT lan; khi
		// khong bat, ca khoi nay la mot lan so sanh int roi di tiep — khong mot pixel, khong mot
		// su kien nao doi duong. Khi bat va dang o che do sua, cac su kien chuot/phim cua bo sua
		// bi NUOT tai day, truoc khi bom vao CEGUI, nen khong tranh voi xu ly chuot cua game.
		if(CysUiEdit::Armed())
		{
			const bool bShift = (::GetKeyState(VK_SHIFT) & 0x8000) != 0;
			const bool bCtrl  = (::GetKeyState(VK_CONTROL) & 0x8000) != 0;
			bool bEaten = false;
			switch(event.nEvent)
			{
			case EVENT_KEY_DOWN:
				bEaten = CysUiEdit::OnKey((INT)event.kIndex, bShift, bCtrl);
				break;
			case EVENT_MOUSE_MOVE:
			case EVENT_MOUSE_LDRAG_MOVE:
				bEaten = CysUiEdit::OnMouseMove((FLOAT)pt.x, (FLOAT)pt.y);
				break;
			case EVENT_MOUSE_LBDOWN:
				bEaten = CysUiEdit::OnMouseDown((FLOAT)pt.x, (FLOAT)pt.y, bShift);
				break;
			case EVENT_MOUSE_LBUP:
			case EVENT_MOUSE_LBCLICK:
				bEaten = CysUiEdit::OnMouseUp((FLOAT)pt.x, (FLOAT)pt.y);
				break;
			default:
				break;
			}
			if(bEaten) { event.bProcessed = true; continue; }
		}

		switch(event.nEvent)
		{
		//---------------------------------------------------
		//鼠标
		case EVENT_MOUSE_MOVE:
		case EVENT_MOUSE_LDRAG_MOVE:
		case EVENT_MOUSE_RDRAG_MOVE:
			{
				POINT pt = g_pInputSys->MouseGetPos();	
				DWORD dwMouseFlag = g_pInputSys->MouseGetFlag();
				if(ceguiSystem.injectMousePosition((FLOAT)pt.x, (FLOAT)pt.y))
					event.bProcessed = true;
			}
			break;

		case EVENT_MOUSE_LBDOWN:
			{
				//如果在拖动中,处理拖动结束
				if(TryEndActionDrag((FLOAT)pt.x, (FLOAT)pt.y, FALSE))
				{
					event.bProcessed = true;
				}
				else
				{
					if(ceguiSystem.injectMouseButtonDown( CEGUI::LeftButton ))
						event.bProcessed = true;
				}
			}
			break;

		case EVENT_MOUSE_LBUP:
			{
				if(CEGUI::Window::getCaptureWindow())
				{
					if(ceguiSystem.injectMouseButtonUp( CEGUI::LeftButton ))
					{
						event.bProcessed = true;
						//捕获本桢鼠标Click事件
						for(INT j=0; j<(INT)queueInput.size(); j++) 
						{
							if(queueInput[j].nEvent == EVENT_MOUSE_LBCLICK || queueInput[j].nEvent == EVENT_MOUSE_LBUP) //
								queueInput[j].bProcessed = true;
						}
					}
				}
				if(TryEndActionDrag((FLOAT)pt.x, (FLOAT)pt.y, TRUE))
					event.bProcessed = true;
			}
			break;
		case EVENT_MOUSE_LBCLICK:
			{
				if(ceguiSystem.injectMouseButtonUp( CEGUI::LeftButton ))
				{
					event.bProcessed = true;
					//捕获本桢鼠标Click事件
					for(INT j=0; j<(INT)queueInput.size(); j++) 
					{
						if(queueInput[j].nEvent == EVENT_MOUSE_LBCLICK || queueInput[j].nEvent == EVENT_MOUSE_LBUP) //
							queueInput[j].bProcessed = true;
					}
				}
			}
			break;

		case EVENT_MOUSE_RBDOWN:
			{
				if(ceguiSystem.injectMouseButtonDown( CEGUI::RightButton ))
				{
					event.bProcessed = true;
				}
			}
			break;

		case EVENT_MOUSE_RBCLICK:
			{
                if(ceguiSystem.injectMouseButtonUp( CEGUI::RightButton ))
				{
					event.bProcessed = true;

					//捕获本桢鼠标Click事件
					for(INT j=0; j<(INT)queueInput.size(); j++) 
					{
						if(queueInput[j].nEvent == EVENT_MOUSE_RBCLICK || queueInput[j].nEvent == EVENT_MOUSE_RBUP)
							queueInput[j].bProcessed = true;
					}
				}

				//右键点击，恢复到缺省技能操作，用于退出修理，鉴定，等特殊鼠标命令状态
				g_pGameInterface->Skill_CancelAction();
			}
			break;

		case EVENT_MOUSE_RBUP:
			{
				if(ceguiSystem.injectMouseButtonUp( CEGUI::RightButton ))
				{
					event.bProcessed = true;
				}
			}
			break;

		case EVENT_MOUSE_LBDOWNREPEAT:
			{
			}
			break;

        case EVENT_MOUSE_WHEEL_UP:
        case EVENT_MOUSE_WHEEL_DOWN:
        {
            // Refresh the position even when the pointer has not moved this frame.
            // CEGUI bubbles the wheel from row/icon children to their scroll container.
            ceguiSystem.injectMousePosition((FLOAT)pt.x, (FLOAT)pt.y);
            const float delta=event.nEvent==EVENT_MOUSE_WHEEL_UP?1.0f:-1.0f;
            // Tooltips are mouse-hollow: keep the pointer on the item while reading
            // long equipment details. Scroll visible comparison cards together.
            const char* tips[]={"_SuperTooltip_","_SuperTooltip_Compare","_SuperTooltip_Compare2"};
            for(const char* name:tips) {
                auto& wm=CEGUI::WindowManager::getSingleton();
                if(wm.isWindowPresent(name)) {
                    auto tip=dynamic_cast<CEGUI::IFalagardSuperTooltip*>(wm.getWindow(name));
                    if(tip && tip->scrollContent(delta))event.bProcessed=true;
                }
            }
            if(!event.bProcessed)event.bProcessed=ceguiSystem.injectMouseWheelChange(delta);
            break;
        }

		default:
			continue;
		}

		if(!event.bProcessed)
		{
			//对于未加Handle的Keybord Event，根据位置判断是否应该捕获
			if(event.nEvent == EVENT_KEY_DOWN || event.nEvent == EVENT_KEY_UP)
			{
			}
			else
			//对于未加Handle的Mouse Event，根据位置判断是否应该捕获
			{
				CEGUI::Window* pWindow = ceguiSystem.getTargetWindow(CEGUI::Point((FLOAT)pt.x, (FLOAT)pt.y));

				if(	event.nEvent == EVENT_MOUSE_LBDOWN || event.nEvent == EVENT_MOUSE_LBUP ||
					event.nEvent == EVENT_MOUSE_LBCLICK || event.nEvent == EVENT_MOUSE_LDBCLICK ||
					event.nEvent == EVENT_MOUSE_LBDOWNREPEAT)
				{
					if(pWindow && !(pWindow->getMouseLButtonHollow()))
						event.bProcessed = true;
					if(pWindow && pWindow->testClassName((const CEGUI::utf8*)"FalagardChatBoard"))
						event.bProcessed = false;
				}
				else if(event.nEvent == EVENT_MOUSE_RBDOWN || event.nEvent == EVENT_MOUSE_RBUP ||
					event.nEvent == EVENT_MOUSE_RBCLICK || event.nEvent == EVENT_MOUSE_RDBCLICK)
				{
					if(pWindow && !(pWindow->getMouseRButtonHollow()))
						event.bProcessed = true;
				}
				else if(pWindow && !(pWindow->getMouseHollow()))
				{
					event.bProcessed = true;
				}
			}
		}
	}
}















static BOOL CysChatInputShouldIgnore(UINT message)
{
	switch(message)
	{
	case WM_CHAR: case WM_SYSCHAR: case WM_DEADCHAR:
	case WM_KEYDOWN: case WM_KEYUP:
	case WM_IME_CHAR: case WM_IME_COMPOSITION: case WM_IME_STARTCOMPOSITION: case WM_IME_ENDCOMPOSITION:
		break;
	default:
		return FALSE;	// mouse / focus / everything else: never touched
	}

	if(!g_pVariableSystem) return FALSE;
	BOOL bHave = FALSE;
	const INT nNonChatActive = g_pVariableSystem->GetAs_Int("NonChatActive", &bHave);
	if(!bHave || nNonChatActive != 1) return FALSE;		// unknown, or the player really is typing

	CEGUI::Window* pActive = Ime::GetActiveIMEEditBox();
	if(!pActive) return FALSE;
	return (0 == strcmp(pActive->getName().c_str(), "Chat_EditBox")) ? TRUE : FALSE;
}

BOOL CUISystem::MessageProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	if(CysChatInputShouldIgnore(message)) return FALSE;	// CYS-MOVE2
	return Ime::ImeMsgProc(message, wParam, lParam);
}

BOOL CUISystem::IsMouseHover(VOID)
{
	if(m_szNameBtnInDragging != "")
	{
		CEGUI::FalagardActionButton *pBtnInDragging = (CEGUI::FalagardActionButton *)CEGUI::WindowManager::getSingleton().getWindow(m_szNameBtnInDragging);
		//if(m_pBtnInDragging) 
		if(pBtnInDragging) 
			return true;
	}

	POINT pt = g_pInputSys->MouseGetPos();

	CEGUI::System& ceguiSystem = CEGUI::System::getSingleton();
	CEGUI::Window* pWindow = ceguiSystem.getTargetWindow(CEGUI::Point((FLOAT)pt.x, (FLOAT)pt.y), 0);
	if(pWindow && !(pWindow->getMouseHollow() || pWindow->getMouseLButtonHollow()))
	{
		if(pWindow->testClassName((CEGUI::utf8*)"FalagardChatBoard") && getChatBoard_HyplinkContex(pt.x,pt.y).empty())
		{
			return false;
		}

		return true;
	}

	return false;
}

BOOL CUISystem::IsMouseHover_ChatBoard(LONG x, LONG y)
{
	CEGUI::System& ceguiSystem = CEGUI::System::getSingleton();
	CEGUI::Window* pWindow = ceguiSystem.getTargetWindow(CEGUI::Point((FLOAT)x, (FLOAT)y));

	const char *name = pWindow->getName().c_str();
	if(pWindow && pWindow->testClassName((CEGUI::utf8*)"FalagardChatBoard"))
		return TRUE;
	else
		return FALSE;
}

STRING CUISystem::getChatBoard_HyplinkContex(LONG x, LONG y)
{
	if(IsMouseHover_ChatBoard(x,y))
	{
		CEGUI::System& ceguiSystem = CEGUI::System::getSingleton();
		CEGUI::Window* pWindow = ceguiSystem.getTargetWindow(CEGUI::Point((FLOAT)x, (FLOAT)y));

		CEGUI::String strUtf = CEGUI::HyperLinkManager::getSingleton().getHyperLinkContex(pWindow, CEGUI::Point((FLOAT)x, (FLOAT)y));
		STRING strMbc;
		CUIStringSystem::utf8_to_mbcs(strUtf.c_str(), strMbc);

		return strMbc;
	}

	return STRING("");
}

VOID CUISystem::Initial(VOID*)
{
	//----------------------------------------------------------------------
	//保存全局变量
	g_pScriptSys = (tScriptSystem*)g_pKernel->GetNode("bin\\script");
	TDAssert(g_pScriptSys);

	g_pEventSys = (tEventSystem*)g_pKernel->GetNode("bin\\event");
	TDAssert(g_pEventSys);

	g_pActionSys = (tActionSystem*)g_pKernel->GetNode("bin\\action");
	TDAssert(g_pActionSys);

	g_pInputSys = (tInputSystem*)g_pKernel->GetNode("bin\\input");
	TDAssert(g_pInputSys);

	g_pGfxSystem = (CRenderSystem*)g_pKernel->GetNode("bin\\gfx");
	TDAssert(g_pGfxSystem);

	g_pObjectSystem = (tObjectSystem*)g_pKernel->GetNode("bin\\objman");
	TDAssert(g_pObjectSystem);

	g_pCursorSystem = (tCursorSystem*)g_pKernel->GetNode("bin\\cursor");
	TDAssert(g_pCursorSystem);

	g_pDebuger = (tDebuger*)g_pKernel->GetNode("bin\\debuger");
	//TDAssert(g_pDebuger);

	g_pWorldSystem = ( tWorldSystem* ) g_pKernel->GetNode("bin\\worldman");
	TDAssert( g_pWorldSystem );

	g_pTimer = (tTimeSystem*)g_pKernel->GetNode("bin\\time");
	TDAssert(g_pTimer);

	g_pFakeSystem = (tFakeObjSystem*)g_pKernel->GetNode("bin\\fake");
	TDAssert(g_pFakeSystem);

	g_pVariableSystem = (tVariableSystem*)g_pKernel->GetNode("bin\\var");
	TDAssert(g_pVariableSystem);

	g_pGameInterface = (tGameInterfaceBase*)g_pKernel->GetNode("bin\\interface");
	TDAssert(g_pVariableSystem);

	g_pDataBaseSystem = (tDataBaseSystem*)g_pKernel->GetNode("bin\\dbc");
	TDAssert(g_pDataBaseSystem);

	g_hMainWnd = g_pGfxSystem->GetWindow();

	//----------------------------------------------------------------------
	//初始化CEGUI
	m_pOgreRoot = Ogre::Root::getSingletonPtr();
	TDAssert(m_pOgreRoot);

	Ogre::RenderWindow* pWindow = (Ogre::RenderWindow*)m_pOgreRoot->getRenderTarget("");

	m_pCEGUIScript = new CEGUI::CGameUIScript;
	m_pCEGUIRender = new CEGUI::OgreCEGUIRenderer((Ogre::RenderTarget*)pWindow, 
		Ogre::RENDER_QUEUE_OVERLAY, false, 0, m_pOgreRoot->getSceneManager("FairyMainScene"));

	m_pCEGUISystem = new CEGUI::System( m_pCEGUIRender, m_pCEGUIScript, (const CEGUI::utf8*)"");

	//使用UI资源组
	m_pCEGUISystem->getResourceProvider()->setDefaultResourceGroup("General");

	// CYS: font and UI text must use the same code page before the first scheme loads.
	BOOL cysHaveCodePage = FALSE;
	const INT cysCodePage = g_pVariableSystem->GetAs_Int("System_CodePage", &cysHaveCodePage);
	CEGUI::FontManager::getSingleton().setCodePage(cysHaveCodePage && cysCodePage > 0 ? cysCodePage : 936);
	
	//加载总控文件
	CEGUI::SchemeManager::getSingleton().loadScheme("Schema\\WoWLookSkin.scheme.xml");
	// CYS: native 0.85 code creates some windows by WoWLook/* type names (scene map, radar, world map, chat
	// CYS: history, creature boards). client_GL schemes only map TLBB_* types, so each missing WoWLook name gets an
	// CYS: alias to its client_GL equivalent; a scheme that still maps WoWLook/* is left untouched.
	{
		static const char* const cysAliases[][2] = {
			{"WoWLook/StaticImage", "TLBB_StaticImageNULL"}, {"WoWLook/CreatureBoard", "TLBB_CreatureBoard"},
			{"WoWLook/BeHitBoard", "TLBB_BeHitBoard"}, {"WoWLook/ChatBoard", "TLBB_ChatBoard"},
			{"WoWLook/Money", "TLBB_Money"}, {"WoWLook/ActionButton", "TLBB_ActionButton"},
			{"WoWLook/RewardItem", "TLBB_RewardItem"}, {"WoWLook/Tooltip", "TLBB_Tooltip"},
			// CYS-QUEST: option buttons / plain buttons of the NPC dialogue ComplexWindow (TLBB_Look_ComplexWindow ChildItem)
			{"WoWLook/QuestButton_1", "TLBB_QuestButton"}, {"WoWLook/QuestButton_2", "TLBB_QuestButton"},
			{"WoWLook/QuestButton_3", "TLBB_QuestButton"}, {"WoWLook/QuestButton_4", "TLBB_QuestButton"},
			{"WoWLook/Button_1", "TLBB_ButtonNULL"}};
		CEGUI::WindowFactoryManager& cysFactories = CEGUI::WindowFactoryManager::getSingleton();
		for (const auto& cysAlias : cysAliases)
		{
			if (!cysFactories.isFactoryPresent(cysAlias[0]) && cysFactories.isFactoryPresent(cysAlias[1]))
			{
				cysFactories.addWindowTypeAlias(cysAlias[0], cysAlias[1]);
				CEGUI::Logger::getSingleton().logEvent(CEGUI::String("CYS: window type alias ") + cysAlias[0] + " -> " + cysAlias[1]);
			}
		}
	}

	m_pCEGUISystem->setTooltip(CEGUI::WindowFactoryManager::getSingleton().isFactoryPresent("TLBB_Tooltip")
		? "TLBB_Tooltip" : "WoWLook/Tooltip");

	//----------------------------------------------------------------------
	//挂接超连接管理器
	CEGUI::HyperLinkManager::getSingleton().subscribeEvent("HyperLinkActive",CEGUI::Event::Subscriber(&CUISystem::handleHyperLinkActive, CUISystem::GetMe()));
	CEGUI::HyperLinkManager::getSingleton().subscribeEvent("HyperLinkLeftActive",CEGUI::Event::Subscriber(&CUISystem::handleHyperLinkLeftActive, CUISystem::GetMe()));
	CEGUI::HyperLinkManager::getSingleton().subscribeEvent("HyperLinkRightActive",CEGUI::Event::Subscriber(&CUISystem::handleHyperLinkRightActive, CUISystem::GetMe()));
	CEGUI::HyperLinkManager::getSingleton().subscribeEvent("HyperLinkInactive",CEGUI::Event::Subscriber(&CUISystem::handleHyperLinkInactive, CUISystem::GetMe()));

	//----------------------------------------------------------------------
	//初始化动画管理器
	new CEGUI::AnimateManager( "schema\\wowanimate.xml" );

	//中文输入初始化
	Ime::InitializeImm((unsigned int)HandleToULong(g_hMainWnd)); // CYS: x64 - explicit handle truncation (C4302); CEGUIIme sign-extends it back
	
	//----------------------------------------------------------------------
	//文本管理器
	m_pStringSystem = new CUIStringSystem;
	m_pStringSystem->Init();

	//----------------------------------------------------------------------
	//初始化图标管理器
	m_pIconsMng = new CUIIconsManager;
	TDAssert( m_pIconsMng);
	m_pIconsMng->Initial();

	//----------------------------------------------------------------------
	//初始化布局管理器
	m_pWindowMng = new CUIWindowMng;
	TDAssert( m_pWindowMng );
	m_pWindowMng->Init();
	//----------------------------------------------------------------------

	//初始化角色信息板管理器
	m_pCreatureBoardSystem = new CUICreatureBoardSystem;
	m_pCreatureBoardSystem->Initial();

	//----------------------------------------------------------------------
	//拖动操作
	//m_pBtnInDragging = NULL;
	m_szNameBtnInDragging= "";

	/*RECT rect;
	GetClientRect(g_hMainWnd, &rect);
	g_pEventSys->PushEvent(GE_CHAT_ADJUST_MOVE_CTL, rect.right-rect.left, rect.bottom-rect.top);*/

}

VOID CUISystem::Release(VOID)
{
	// Stop Lua dispatch before releasing any UI owner or its script environment.
	CUIWindowMng::BeginShutdown();
	if(m_pCreatureBoardSystem)
		m_pCreatureBoardSystem->Release();
	SAFE_DELETE( m_pCreatureBoardSystem );
	SAFE_DELETE( m_pIconsMng );
	SAFE_DELETE( m_pWindowMng );
	SAFE_DELETE( m_pStringSystem );

	delete CEGUI::AnimateManager::getSingletonPtr();

	Ime::UninitializeImm();

	SAFE_DELETE( m_pCEGUISystem );
	SAFE_DELETE( m_pCEGUIRender );
	SAFE_DELETE( m_pCEGUIScript );
}

VOID CUISystem::Tick(VOID)
{
	static UINT s_nLastTime = 0;

	UINT nTimeNow = g_pTimer->GetTimeNow();

	if(s_nLastTime == 0)
	{
		s_nLastTime = nTimeNow;
		return;
	}
    
	if( CEGUI::System::getSingletonPtr() )
		CEGUI::System::getSingleton().injectTimePulse(g_pTimer->CalSubTime(s_nLastTime, nTimeNow)/1000.0f); 

	s_nLastTime = nTimeNow;

	if( m_pCreatureBoardSystem )
		m_pCreatureBoardSystem->Tick();

	CysInfoUseItem_Tick();	// CYS-INFOPARITY: pending "walk there, then use the item" of a _INFOUSEITEM click

	static UINT s_nLastFreeTime = g_pTimer->GetTimeNow();
	if( g_pTimer->CalSubTime( s_nLastFreeTime, nTimeNow ) > 6000 ) // 每分钟释放一次
	{
		CEGUI::ImagesetManager::getSingleton().FreeUnuseImageset();
		s_nLastFreeTime = nTimeNow;
	}
//	AxVar(0, 0, AX_FLOAT32, "elapsed", &fElapsedTime);
}

/// 窗口大小发生改变
VOID CUISystem::OnSizeChange(UINT message, WPARAM wParam, LPARAM lParam)
{
	//用户点击最大化或者最小化
	if(WM_SIZE == message)
	{
		m_pCEGUIRender->_notifySizeChanged();
	}
	//用户拖动窗口边缘结束
	else if(WM_EXITSIZEMOVE == message)
	{
		m_pCEGUIRender->_notifySizeChanged();
	}
}

bool CUISystem::handleActionDragDropStarted(const CEGUI::EventArgs &e)
{
	const CEGUI::WindowEventArgs& eWindow = (const CEGUI::WindowEventArgs&)e;
	CEGUI::Window* pWindow = eWindow.window;
	if(!(pWindow->testClassName((CEGUI::utf8*)"FalagardActionButton"))) return false;

	OnDragBeging((CEGUI::FalagardActionButton*)pWindow);

	return false;
}

static bool CysQuickbarWindow(const CEGUI::Window* w) {
    if(!w)return false;
    const std::string name=w->getName().c_str();
    return name.find("MainMenuBar_")==0 || name.find("SubMenuBar_")==0;
}
bool CUISystem::handleActionButtonMouseEnter(const CEGUI::EventArgs &e)
{
	//AxTrace(0,0,"handleActionButtonMouseEnter");
	const CEGUI::WindowEventArgs& eWindow = (const CEGUI::WindowEventArgs&)e;
	CEGUI::Window* pWindow = eWindow.window;
	if(!pWindow || !(pWindow->testClassName((CEGUI::utf8*)"FalagardActionButton"))) return false;

	if(CysQuickbarWindow(pWindow)&&g_pVariableSystem->GetAs_Int("CysQuickbarNoTooltip"))return false;
	//得到逻辑数据
	CEGUI::IFalagardActionButton* pIBtn = (CEGUI::IFalagardActionButton*)(CEGUI::FalagardActionButton*)pWindow;
	tActionItem* pActionItem = (tActionItem*)(g_pActionSys->GetAction((INT)(INT_PTR)(pIBtn->getLogicItemData())));
	if(pActionItem)
	{
		//调用逻辑接口
		// CYS-FRAMESTRUTH 20/09: hand over the pixel rect of the BUTTON, as the living UI does (B UI_CEGUI.dll, the
		// mouse-enter handler found through the string "FalagardActionButton": window->getPixelRect() then
		// action->vt[0xa8](left, top, right, bottom)). The tooltip is anchored to the button, not to the cursor.
		const CEGUI::Rect rcButton = pWindow->getPixelRect();
		pActionItem->NotifyTooltipsShow((INT)rcButton.d_left, (INT)rcButton.d_top, (INT)rcButton.d_right, (INT)rcButton.d_bottom);
	}
	return false;
}

bool CUISystem::handleActionButtonMouseLeave(const CEGUI::EventArgs &e)
{
	const CEGUI::WindowEventArgs& eWindow = (const CEGUI::WindowEventArgs&)e;
	CEGUI::Window* pWindow = eWindow.window;
	if(!pWindow || !(pWindow->testClassName((CEGUI::utf8*)"FalagardActionButton"))) return false;

	//得到逻辑数据
	CEGUI::IFalagardActionButton* pIBtn = (CEGUI::IFalagardActionButton*)(CEGUI::FalagardActionButton*)pWindow;
	tActionItem* pActionItem = (tActionItem*)(g_pActionSys->GetAction((INT)(INT_PTR)(pIBtn->getLogicItemData())));
	
	if(pActionItem)
	{
		//调用逻辑接口
		pActionItem->NotifyTooltipsHide();
	}
	return false;
}

bool CUISystem::handleActionButtonParentHidden(const CEGUI::EventArgs& e)
{
	const CEGUI::WindowEventArgs& eWindow = (const CEGUI::WindowEventArgs&)e;
	CEGUI::Window* pWindow = eWindow.window;
	if(!pWindow || !(pWindow->testClassName((CEGUI::utf8*)"FalagardActionButton"))) return false;

	//得到逻辑数据
	CEGUI::IFalagardActionButton* pIBtn = (CEGUI::IFalagardActionButton*)(CEGUI::FalagardActionButton*)pWindow;
	tActionItem* pActionItem = (tActionItem*)(g_pActionSys->GetAction((INT)(INT_PTR)(pIBtn->getLogicItemData())));
	
	if(pActionItem)
	{
		//调用逻辑接口
		pActionItem->NotifyTooltipsHide();
	}
	return false;
}

bool CUISystem::handleMeshWindowShown(const CEGUI::EventArgs &e)
{
	const CEGUI::WindowEventArgs& eWindow = (const CEGUI::WindowEventArgs&)e;
	CEGUI::Window* pWindow = eWindow.window;
	if(!pWindow || !(pWindow->testClassName((CEGUI::utf8*)"FalagardMeshWindow"))) return false;

	CEGUI::Size sz = pWindow->getUnclippedInnerRect().getSize();
	if (sz.d_width <= 0 || sz.d_height <= 0) return false;
	g_pFakeSystem->OnUIShown(pWindow->getName().c_str(), sz.d_width/sz.d_height);

	return false;
}

bool CUISystem::handleMeshWindowHiden(const CEGUI::EventArgs &e)
{
	const CEGUI::WindowEventArgs& eWindow = (const CEGUI::WindowEventArgs&)e;
	CEGUI::Window* pWindow = eWindow.window;
	if(!pWindow || !(pWindow->testClassName((CEGUI::utf8*)"FalagardMeshWindow"))) return false;

	g_pFakeSystem->OnUIHiden(pWindow->getName().c_str());

	return false;
}

VOID CUISystem::OnDragBeging(CEGUI::FalagardActionButton* pBtnDraging)
{
    if(CysQuickbarWindow(pBtnDraging)&&g_pVariableSystem->GetAs_Int("CysQuickbarLocked")){pBtnDraging->notifyDragingEnd();return;}
	if (getenv("CYS_QUICKBAR_LIVE")) CEGUI::Logger::getSingleton().logEvent(CEGUI::String("CYS-DRAG begin ")+pBtnDraging->getName());
	CEGUI::IFalagardActionButton* pIBtn = (CEGUI::IFalagardActionButton*)pBtnDraging;
	tActionItem* pActionItem = (tActionItem*)g_pActionSys->GetAction((INT)(INT_PTR)(pIBtn->getLogicItemData())); // CYS: x64 - action ID stored in the pointer slot (C4302)
	if(!pActionItem) return;

	//ui捕获输入
	g_pInputSys->SetCapture(ICS_UI);

	//将光标设为相应的Image
	if(m_hDraggingCursor)
	{
		::DestroyIcon(m_hDraggingCursor);
		m_hDraggingCursor = NULL;
	}

	m_hDraggingCursor = CUIIconsManager::GetMe()->CreateAsWinCursor(pActionItem->GetIconName());
	if(m_hDraggingCursor)
	{
		g_pCursorSystem->EnterUICursor(m_hDraggingCursor);
	}

	//保存正在托拽中的ActionButton
	//m_pBtnInDragging = (CEGUI::FalagardActionButton*)pBtnDraging;
	m_szNameBtnInDragging = ((CEGUI::Window*)pBtnDraging)->getName();
}

BOOL CUISystem::TryEndActionDrag(FLOAT x, FLOAT y, BOOL actionButtonOnly)
{
	if (getenv("CYS_QUICKBAR_LIVE")) CEGUI::Logger::getSingleton().logEvent(CEGUI::String("CYS-DRAG release source=")+m_szNameBtnInDragging);
	if (m_szNameBtnInDragging.empty()) return FALSE;
	CEGUI::Window* target = CEGUI::System::getSingleton().getTargetWindow(CEGUI::Point(x, y));
	if (target && getenv("CYS_QUICKBAR_LIVE")) CEGUI::Logger::getSingleton().logEvent(CEGUI::String("CYS-DRAG target=")+target->getName());
	if (!target || (actionButtonOnly && !target->testClassName((CEGUI::utf8*)"FalagardActionButton"))) return FALSE;
	OnDragEnd(target);
	return TRUE;
}

VOID CUISystem::OnDragEnd(CEGUI::Window* pWindowTarget)
{	
	//释放捕获
	g_pInputSys->SetCapture(ICS_NONE);
	//恢复光标
	if(m_hDraggingCursor)
	{
		g_pCursorSystem->LeaveUICursor();
		::DestroyIcon(m_hDraggingCursor);
		m_hDraggingCursor = NULL;
	}
	g_pCursorSystem->SetCursor(CURSOR_NORMAL);

	//通知正在托拽的ActionButton
	if(m_szNameBtnInDragging != "")
	{
		CEGUI::FalagardActionButton *pBtnInDragging = (CEGUI::FalagardActionButton *)CEGUI::WindowManager::getSingleton().getWindow(m_szNameBtnInDragging);
		CEGUI::IFalagardActionButton* pIBtn = (CEGUI::IFalagardActionButton*)pBtnInDragging;

		if(pBtnInDragging)
		{
			pIBtn->notifyDragingEnd();
		}

		if(g_pVariableSystem->GetAs_Int("CysQuickbarLocked") && (CysQuickbarWindow(pBtnInDragging)||CysQuickbarWindow(pWindowTarget))) {
            m_szNameBtnInDragging="";ChangeDragFlag(true);return;
        }
        //判断是否被销毁
		BOOL bBeDestroy = (pWindowTarget && pWindowTarget->getMouseHollow());

		//如果被拖入一个actionbutton上，取得该ActionButton的DragAcceptName
		CEGUI::IFalagardActionButton* pITargetBtn = NULL;
		if(pWindowTarget && pWindowTarget->testClassName((CEGUI::utf8*)"FalagardActionButton"))
		{
			pITargetBtn = (CEGUI::IFalagardActionButton*)(CEGUI::FalagardActionButton*)pWindowTarget;
			////pITargetBtn->notifyDragDrop_Droped(m_pBtnInDragging);
			pITargetBtn->notifyDragDrop_Droped(pBtnInDragging);
		}

		//通知逻辑系统
		tActionItem* pActionItem = (tActionItem*)g_pActionSys->GetAction((INT)(INT_PTR)(pIBtn->getLogicItemData())); // CYS: x64 - action ID stored in the pointer slot (C4302)
		if(pActionItem)
		{
			pActionItem->NotifyDragDropDragged(bBeDestroy, pITargetBtn ? (LPCTSTR)(pITargetBtn->getDragAcceptName()) : NULL, ((CEGUI::FalagardActionButton*)pIBtn)->getDragAcceptName());
		}
		//m_pBtnInDragging = NULL;
		m_szNameBtnInDragging = "";
		ChangeDragFlag(true);
	}

	CEGUI::WindowManager::WindowIterator itAllWindow = CEGUI::WindowManager::getSingleton().getIterator();
	for(itAllWindow.toStart(); !itAllWindow.isAtEnd(); itAllWindow++)
	{
		CEGUI::Window* pWindow = itAllWindow.getCurrentValue();
		if(pWindow && pWindow->isVisible() && pWindow->testClassName((CEGUI::utf8*)"FalagardActionButton"))
		{
			CEGUI::IFalagardActionButton* pIBtn = 
				(CEGUI::IFalagardActionButton*)(CEGUI::FalagardActionButton *)pWindow;

			pIBtn->notifyDragingEnd();
		}
	}

}

tCreatureBoard*	CUISystem::CreateCreatureBoard(VOID)
{
	return (tCreatureBoard*)m_pCreatureBoardSystem->CreateCreatureBoard();
}

VOID CUISystem::AddNewBeHitBoard( bool bDouble, LPCTSTR szInfo, FLOAT fStartX, FLOAT fStartY, int nType, int nMoveType )
{
	m_pCreatureBoardSystem->AddNewBeHit( bDouble, szInfo, fStartX, fStartY, nType, nMoveType );
}

//某一组UI是否处于打开中
BOOL CUISystem::IsWindowShow(LPCTSTR szUIName)
{
	return m_pWindowMng->IsWindowShow(szUIName);
}

VOID CUISystem::FakeObj_Show(LPCTSTR szWinName, LPCTSTR szName)
{
	//取得UI窗口
	CEGUI::Window* pMeshWindow = CEGUI::WindowManager::getSingleton().getWindow((CEGUI::utf8*)szWinName);
	if(!pMeshWindow || !(pMeshWindow->testClassName((CEGUI::utf8*)"FalagardMeshWindow"))) return;

	//按照固定的命名规则取得渲染纹理
	STRING strImageName = szName;
	strImageName += FAKE_RENDERTEXTURE;

	// CYS-MESHWIN 19/09: an imageset of that name may still exist (object re-hooked before its window was closed);
	// createImageset would throw AlreadyExistsException into the Lua call. Reuse it - it wraps the same RTT.
	CEGUI::Imageset* rttImageSet = NULL;
	if (CEGUI::ImagesetManager::getSingleton().isImagesetPresent((CEGUI::utf8*)strImageName.c_str()))
	{
		rttImageSet = CEGUI::ImagesetManager::getSingleton().getImageset((CEGUI::utf8*)strImageName.c_str());
	}
	else
	{
		//取得纹理，该纹理应该在渲染层已经创建
		CEGUI::Texture* rttTexture =
			((CEGUI::OgreCEGUIRenderer*)m_pCEGUIRender)->createTexture((CEGUI::utf8*)strImageName.c_str());
		TDAssert(rttTexture);

		//创建UI用的Imageset
		rttImageSet = CEGUI::ImagesetManager::getSingleton().createImageset(strImageName.c_str(), rttTexture);
		rttImageSet->setAutoFree( false );
		rttImageSet->defineImage((CEGUI::utf8*)"View",
			CEGUI::Point(0.0f, 0.0f),
			CEGUI::Size(rttTexture->getWidth(), rttTexture->getHeight()),
			CEGUI::Point(0.0f,0.0f));
	}

	//设置显示纹理

	((CEGUI::StaticImage*)pMeshWindow)->setImage(&(rttImageSet->getImage((CEGUI::utf8*)"View")));
	{
		// CYS-MESHWIN: the line a live run is judged by - the window now draws the render texture of the object.
		const CEGUI::Image& img = rttImageSet->getImage((CEGUI::utf8*)"View");
		char line[256] = {0};
		_snprintf(line, sizeof(line) - 1, "CYS-MESHWIN: FakeObj_Show window=%s image=%s %.0fx%.0f",
			szWinName, strImageName.c_str(), img.getWidth(), img.getHeight());
		CEGUI::Logger::getSingleton().logEvent((const CEGUI::utf8*)line);
	}
}

VOID CUISystem::FakeObj_Close(LPCTSTR szWinName, LPCTSTR szName)
{
	//取得UI窗口
	CEGUI::Window* pMeshWindow = CEGUI::WindowManager::getSingleton().getWindow((CEGUI::utf8*)szWinName);
	if(!pMeshWindow || !(pMeshWindow->testClassName((CEGUI::utf8*)"FalagardMeshWindow"))) return;   // CYS-MESHWIN: null guard

	//通知UI
	((CEGUI::StaticImage*)pMeshWindow)->setImage(0);

	//销毁UI的Imageset
	STRING strImageName = szName;
	strImageName += FAKE_RENDERTEXTURE;

	CEGUI::ImagesetManager::getSingleton().destroyImageset((CEGUI::utf8*)strImageName.c_str());
}

VOID CUISystem::Debug_SaveFontTexture(VOID)
{
#if 1
	//Make sure have out dir
	::CreateDirectory("DebugOut", NULL);

	CEGUI::FontManager* pFontManager = CEGUI::FontManager::getSingletonPtr();
	CEGUI::FontManager::FontIterator it = pFontManager->getIterator();

	for(it.toStart(); !it.isAtEnd(); it++)
	{
		const CEGUI::String&  strName = it.getCurrentKey();
		CEGUI::FontBase* pFont = it.getCurrentValue();

		//------------------------------------------------------------------
		//Create Directiory
		CHAR szFontOut[MAX_PATH];
		strncpy(szFontOut, ".\\DebugOut", MAX_PATH);
		PathAppend(szFontOut, strName.c_str());
		CreateDirectory(szFontOut, NULL);

		std::vector< CEGUI::Imageset* > vImagesets;
		INT nShouldLen = pFont->debug_GetFontImageset(vImagesets);
		if(nShouldLen != vImagesets.size()) vImagesets.resize(nShouldLen);
		pFont->debug_GetFontImageset(vImagesets);

		//------------------------------------------------------------------
		for(INT i=0; i<(INT)vImagesets.size(); i++)
		{
			const CEGUI::OgreCEGUITexture* pTexture = (const CEGUI::OgreCEGUITexture*)vImagesets[i]->getTexture();
			const Ogre::TexturePtr pOgreTex = pTexture->getOgreTexture();
			const Ogre::HardwarePixelBufferSharedPtr pPixelBuf = pOgreTex->getBuffer(0, 0);
			
			Ogre::Image imageOut;
			imageOut.load("_TEMP_.tga", "General");
//			imageOut.loadDynamicImage(

			imageOut.resize((Ogre::ushort)pPixelBuf->getWidth(), (Ogre::ushort)pPixelBuf->getHeight());
			pPixelBuf->blitToMemory(imageOut.getPixelBox());

			CHAR szFileName[MAX_PATH];
			strncpy(szFileName, szFontOut, MAX_PATH);
			PathAppend(szFileName, vImagesets[i]->getName().c_str());
			strcat(szFileName, ".tga");
			imageOut.save(szFileName);
		}
	}
#endif
}

VOID CUISystem::ChangeDragFlag(bool Flag) 
{
	m_bIsDragEnd = Flag;
}

BOOL CUISystem::IsDragFlag(VOID)
{
	return m_bIsDragEnd;
}

STRING CUISystem::ParserString_VarParam(LPCTSTR strID, ... )
{
	STRING strR = "";
	if(m_pStringSystem)
	{

		va_list ptr;
		
		va_start(ptr, strID);
		strR = m_pStringSystem->ParserString_VarParam(strID, ptr);
		va_end(ptr);
	}

	return strR;
}

VOID CUISystem::ParserString_NoColor(const STRING& strSrc, STRING& strOut, BOOL bControl)
{
	if(m_pStringSystem) return m_pStringSystem->ParserString_NoColor(strSrc, strOut, bControl);
}

STRING CUISystem::ParserString_NoColor_VarParam(LPCTSTR strID, ... )
{
	STRING strR = "未知错误";

	if(m_pStringSystem)
	{
		va_list ptr;
		va_start(ptr, strID);
		STRING strColor = m_pStringSystem->ParserString_VarParam(strID, ptr);
		va_end(ptr);
		m_pStringSystem->ParserString_NoColor(strColor, strR);
	}

	return strR;
}

STRING CUISystem::ParserString_NoVarParam(LPCTSTR strID)
{
	STRING strR = "";

	if(m_pStringSystem)
	{
		// CYS: return the resolved dictionary template to host formatters.
		strR = m_pStringSystem->ParserString_NoVarParam(strID);
	}

	return strR;
}

STRING CUISystem::ParserString_NoColor_NoVarParam(LPCTSTR strID)
{
	STRING strR = "";
	if(m_pStringSystem)
	{
		STRING strColor = m_pStringSystem->ParserString_NoVarParam(strID);
		m_pStringSystem->ParserString_NoColor(strColor, strR);
	}
	return strR;
}

BOOL CUISystem::CloseAllWindow()
{
	CUIWindowMng::GetMe()->CloseAllWindow();
	return TRUE;
}

BOOL CUISystem::CloseWindowByName(LPCTSTR szUIName)
{
	// CYS: report an unavailable UI or unknown layout to the host caller.
	return m_pWindowMng ? m_pWindowMng->CloseWindowByName(szUIName) : FALSE;
}

bool CUISystem::handleHyperLinkActive(const CEGUI::EventArgs &e)
{
	AxTrace(0,0,"handleHyperLinkActive");
	return true;
}

bool CUISystem::handleHyperLinkLeftActive(const CEGUI::EventArgs &e)
{
	AxTrace(0,0,"handleHyperLinkLeftActive");
	const CEGUI::HyperLinkEventArgs& eHyperLink = (const CEGUI::HyperLinkEventArgs&)e;

	STRING strWnd, strLink,strtype,strSID,strX,strY;
	CUIStringSystem::utf8_to_mbcs(eHyperLink.windowName.c_str(), strWnd);
	CUIStringSystem::utf8_to_mbcs(eHyperLink.hyperLinkName.c_str(), strLink);





	{
		CysInfoLink::Link cyLink;
		if(strLink.find('#') == STRING::npos && CysInfoLink::ParseKey(strLink, cyLink))
		{
			const INT nCurScene = g_pWorldSystem ? g_pWorldSystem->GetActiveSceneID() : -1;
			CHAR szInfoLog[192] = {0};
			_snprintf(szInfoLog, sizeof(szInfoLog) - 1,
				"CYS-INFOLINK: click type=%d scene=%d cur=%d pos=%d,%d", cyLink.type, cyLink.scene, nCurScene,
				cyLink.x, cyLink.y);
			CEGUI::Logger::getSingleton().logEvent((const CEGUI::utf8*)szInfoLog);

			// scene < 0 means "the scene you are in" - 292 _INFOHOME rows of StrDictionary.txt ship "-1".
			if(cyLink.scene >= 0 && cyLink.scene != nCurScene)
			{


				g_pEventSys->PushEvent(GE_NEW_DEBUGMESSAGE, CUIStringSystem::FromGbkLiteral("您还没到达目标场景。").c_str()); // CYS: GBK literal -> UI code page
				return false;
			}




			if(g_pGameInterface)
				g_pGameInterface->Player_MoveTo(fVector2((FLOAT)cyLink.x, (FLOAT)cyLink.y));
			if(cyLink.type == 2)
				CysInfoUseItem_Arm(CysInfoLink::UseItemID(cyLink.target), cyLink.scene < 0 ? nCurScene : cyLink.scene,
					(FLOAT)cyLink.x, (FLOAT)cyLink.y);
			return true;
		}
	}

	strtype = strLink;
	//计算名字
	STRING::size_type nValidEnd = strLink.find("#", 0);
	if(nValidEnd != STRING::npos) 
	{
		STRING::size_type nFinalEnd	= strLink.size();
		strtype = strtype.substr(nValidEnd, nFinalEnd);
		if (strcmp(strtype.c_str(),"#w") == 0) //判断是否为寻路坐标超连接eg: #aB{sid,x,y##w}(x,y)#aE
		{
			strLink = strLink.substr(0,nValidEnd);
			STRING::size_type nValidEnd = strLink.find(",", 0);
			if(nValidEnd == STRING::npos) 
			{
				return false;
			}
			STRING::size_type nFinalEnd	= strLink.size();
			strSID = strLink.substr(0,nValidEnd);     //备用目标场景ID
			if (atoi(strSID.c_str()) != g_pWorldSystem->GetActiveSceneID())
			{
				g_pEventSys->PushEvent(GE_NEW_DEBUGMESSAGE, CUIStringSystem::FromGbkLiteral("您还没到达目标场景。").c_str()); // CYS: GBK literal -> UI code page
				return false;
			}
			strLink = strLink.substr(nValidEnd+1,nFinalEnd);
			
			nValidEnd = strLink.find(",", 0);
			if(nValidEnd == STRING::npos) 
			{
				return false;
			}
			nFinalEnd	= strLink.size();
			strX = strLink.substr(0,nValidEnd);
			strY = strLink.substr(nValidEnd+1,nFinalEnd);

			g_pGameInterface->Player_MoveTo(fVector2(atoi(strX.c_str()),atoi(strY.c_str())));
		}else if (strcmp(strtype.c_str(),"#z") == 0)  //判断是否为说物品超连接eg: #aB{playID,itemID##z}name#aE
		{
			if(g_pInputSys->IsKeyDown(KC_LCONTROL))
			{

			}
		}else
		{
			return false;
		}
	}else if(CEGUI::WindowManager::getSingleton().isWindowPresent(eHyperLink.windowName))
	{
		CEGUI::Window* pWindow = CEGUI::WindowManager::getSingleton().getWindow(eHyperLink.windowName);

		if(pWindow->testClassName((CEGUI::utf8*)"FalagardChatBoard"))
		{
			g_pEventSys->PushEvent(GE_CHAT_CHANGE_PRIVATENAME, strLink.c_str());
		}
	}

	return true;
}

// CYS-INFOPARITY 19/09 ------------------------------------------------------------------------------------------
// The bag slots are CActionItem_Item objects registered in the action system under sequential ids
// (GMActionSystem.cpp UpdateAction_FromItem -> _CreateID()); tActionSystem only exposes GetAction(id), so the
// item is found by probing the ids. Once per arrival, a few hundred map lookups at most.
static tActionItem* cysFindBagActionByTableID(INT nItemID)
{
	if(!g_pActionSys || nItemID <= 0) return NULL;
	for(INT id = 1; id < 65536; ++id)
	{
		tActionItem* pAction = g_pActionSys->GetAction(id);
		if(!pAction || pAction->GetType() != AOT_ITEM) continue;
		tObject_Item* pItem = (tObject_Item*)pAction->GetImpl();
		if(pItem && pItem->GetTypeOwner() == tObject_Item::IO_MYSELF_PACKET && pItem->GetIdTable() == nItemID)
			return pAction;
	}
	return NULL;
}

VOID CUISystem::CysInfoUseItem_Arm(INT nItemID, INT nScene, FLOAT fX, FLOAT fY)
{
	CHAR szLog[160] = {0};
	if(nItemID <= 0)
	{

		m_infoUseItem.bActive = FALSE;
		_snprintf(szLog, sizeof(szLog) - 1, "CYS-INFOLINK: useitem target is not an 8-digit item id, walk only");
		CEGUI::Logger::getSingleton().logEvent((const CEGUI::utf8*)szLog);
		return;
	}
	m_infoUseItem.bActive	= TRUE;
	m_infoUseItem.nItemID	= nItemID;
	m_infoUseItem.nScene	= nScene;
	m_infoUseItem.fX		= fX;
	m_infoUseItem.fY		= fY;
	m_infoUseItem.nDeadline	= (g_pTimer ? g_pTimer->GetTimeNow() : 0) + 120000;	// two minutes of walking at most
	_snprintf(szLog, sizeof(szLog) - 1, "CYS-INFOLINK: useitem armed id=%d scene=%d pos=%d,%d", nItemID, nScene, (INT)fX, (INT)fY);
	CEGUI::Logger::getSingleton().logEvent((const CEGUI::utf8*)szLog);
}

VOID CUISystem::CysInfoUseItem_Tick(VOID)
{
	if(!m_infoUseItem.bActive) return;
	if(!g_pWorldSystem || !g_pGameInterface || !g_pTimer) { m_infoUseItem.bActive = FALSE; return; }

	CHAR szLog[160] = {0};
	const INT nCurScene = g_pWorldSystem->GetActiveSceneID();
	if(nCurScene != m_infoUseItem.nScene || (INT)(g_pTimer->GetTimeNow() - m_infoUseItem.nDeadline) > 0)
	{

		m_infoUseItem.bActive = FALSE;
		_snprintf(szLog, sizeof(szLog) - 1, "CYS-INFOLINK: useitem cancelled id=%d (scene %d->%d or timeout)",
			m_infoUseItem.nItemID, m_infoUseItem.nScene, nCurScene);
		CEGUI::Logger::getSingleton().logEvent((const CEGUI::utf8*)szLog);
		return;
	}

	// map (x,y) of the player = (x,z) of the world position, as SceneMap/Radar read it (UILuaControl.cpp:1609)
	const fVector3 vMe = g_pWorldSystem->GetMyselfPos();
	const FLOAT dx = vMe.x - m_infoUseItem.fX, dy = vMe.z - m_infoUseItem.fY;
	if(dx * dx + dy * dy > 2.0f * 2.0f) return;

	m_infoUseItem.bActive = FALSE;
	tActionItem* pAction = cysFindBagActionByTableID(m_infoUseItem.nItemID);
	if(!pAction)
	{

		_snprintf(szLog, sizeof(szLog) - 1, "CYS-INFOLINK: useitem arrived, id=%d is not in the bag", m_infoUseItem.nItemID);
		CEGUI::Logger::getSingleton().logEvent((const CEGUI::utf8*)szLog);
		return;
	}
	_snprintf(szLog, sizeof(szLog) - 1, "CYS-INFOLINK: useitem arrived, id=%d bag=%d -> PacketItem_UserItem",
		m_infoUseItem.nItemID, pAction->GetPosIndex());
	CEGUI::Logger::getSingleton().logEvent((const CEGUI::utf8*)szLog);
	fVector2 fvPos(m_infoUseItem.fX, m_infoUseItem.fY);
	g_pGameInterface->PacketItem_UserItem(pAction, -1, fvPos);	// same path as a double-click on the bag slot
}

bool CUISystem::handleHyperLinkRightActive(const CEGUI::EventArgs &e)
{
	AxTrace(0,0,"handleHyperLinkRightActive");
	const CEGUI::HyperLinkEventArgs& eHyperLink = (const CEGUI::HyperLinkEventArgs&)e;

	STRING strWnd, strLink;
	CUIStringSystem::utf8_to_mbcs(eHyperLink.windowName.c_str(), strWnd);
	CUIStringSystem::utf8_to_mbcs(eHyperLink.hyperLinkName.c_str(), strLink);

	if(CEGUI::WindowManager::getSingleton().isWindowPresent(eHyperLink.windowName))
	{
		CEGUI::Window* pWindow = CEGUI::WindowManager::getSingleton().getWindow(eHyperLink.windowName);
		if(pWindow->testClassName((CEGUI::utf8*)"FalagardChatBoard"))
		{
			//if(g_pInputSys->IsKeyDown(KC_LCONTROL))
				g_pEventSys->PushEvent(GE_CHAT_CONTEX_MENU, strLink.c_str());
		}
	}
	return true;
}

bool CUISystem::handleHyperLinkInactive(const CEGUI::EventArgs &e)
{
	AxTrace(0,0,"handleHyperLinkInactive");

	STRING strR = "HelpWindow";
	const CEGUI::HyperLinkEventArgs& eHyperLink = (const CEGUI::HyperLinkEventArgs&)e;

	STRING strUtf8,strUtf9;
	CUIStringSystem::utf8_to_mbcs(eHyperLink.hyperLinkName.c_str(), strUtf9);

	//g_pEventSys->PushEvent(GE_NEW_DEBUGMESSAGE, "mouse on hyperlink.");
	//g_pEventSys->PushEvent(GE_NEW_DEBUGMESSAGE, strUtf9.c_str());
	CUIStringSystem::utf8_to_mbcs(eHyperLink.windowName.c_str(), strUtf8);
	//g_pEventSys->PushEvent(GE_NEW_DEBUGMESSAGE, strUtf8.c_str());

	if(eHyperLink.windowName == "HelpWindow")
	{
	}
	else
	{
		return false;
	}

	return true;
}

BOOL CUISystem::IsIMEEditboxActive(LPCTSTR szWinName)
{
	if(Ime::GetActiveIMEEditBox())
	{
		CEGUI::Window* pWin = Ime::GetActiveIMEEditBox();

		if( 0 == strcmp(pWin->getName().c_str(), szWinName))
			return TRUE;
	}
	return FALSE;
}

BOOL CUISystem::IsIMEEditboxEmpty(VOID)
{
	if(Ime::GetActiveExitBox()->empty())
	{
		return TRUE;
	}
	return FALSE;
}

INT CUISystem::GetCurrentIMEState()
{
	return Ime::GetState();
}

STRING CUISystem::getTalkTemplate(const STRING& strKey, UINT index)
{
	return m_pStringSystem->getTalkTemplate(strKey, index);
}

STRING CUISystem::ModifyChatTemplate(const STRING& strTemp, const STRING& strTalker, const STRING& strTarget)
{
	return m_pStringSystem->ModifyChatTemplate(strTemp,strTalker,strTarget);
}

STRING CUISystem::getTalkRandHelpMsg()
{
	return m_pStringSystem->getTalkRandHelpMsg();
}

void CUISystem::OnPushEcsape()
{
	CUIWindowMng::GetMe()->OnEscape();
}


//过滤字符串中的非法敏感字符 2006-3-22
BOOL	CUISystem::CheckStringFilter(const STRING& strIn)
{
	if(m_pStringSystem)
	{
		return m_pStringSystem->_CheckStringFilter(strIn);
	}

	return   FALSE;
}
//过滤截断字符的<ERROR>
BOOL	CUISystem::CheckStringCode(const STRING& strIn, STRING& strOut) 
{
	if(m_pStringSystem)
	{
		return m_pStringSystem->_CheckStringCode(strIn,strOut);
	}

	return   FALSE;
}

//完全匹配过滤
BOOL	CUISystem::CheckStringFullCompare(const STRING& strIn, const STRING& strFilterType, BOOL bUseAllTable)
{
	if(m_pStringSystem)
	{
		return m_pStringSystem->_CheckStringFullCompare(strIn, strFilterType, bUseAllTable);
	}

	return   FALSE;
}
INT CUISystem::OgreColor_Lumination( UINT OgreColor )
{
	CEGUI::colour CEGUIColor;

	FLOAT fColor_a,fColor_r,fColor_g,fColor_b;

	fColor_a = (FLOAT)COLOR_A(OgreColor)/ 255.0f;
	fColor_r = (FLOAT)COLOR_R(OgreColor)/ 255.0f;
	fColor_g = (FLOAT)COLOR_G(OgreColor)/ 255.0f;
	fColor_b = (FLOAT)COLOR_B(OgreColor)/ 255.0f;

	CEGUIColor.setAlpha( fColor_a);
	CEGUIColor.setRed(fColor_r);
	CEGUIColor.setGreen(fColor_g);
	CEGUIColor.setBlue(fColor_b);

//	FLOAT xx = CEGUIColor.getLumination();

	return (INT)(CEGUIColor.getLumination() * 240);
}

UINT CUISystem::Lumination_OgreColor( UINT OgreColor, INT Lumination )
{
	CEGUI::colour CEGUIColor;

	
	FLOAT fColor_a,fColor_r,fColor_g,fColor_b,fLumination;

	fColor_a = (FLOAT)COLOR_A(OgreColor)/ 255.0f;
	fColor_r = (FLOAT)COLOR_R(OgreColor)/ 255.0f;
	fColor_g = (FLOAT)COLOR_G(OgreColor)/ 255.0f;
	fColor_b = (FLOAT)COLOR_B(OgreColor)/ 255.0f;
	fLumination = (FLOAT)Lumination / 240.0f;

	CEGUIColor.setAlpha( fColor_a);
	CEGUIColor.setRed( fColor_r );
	CEGUIColor.setGreen( fColor_g );
	CEGUIColor.setBlue( fColor_b );

	if( CEGUIColor.getLumination() != Lumination )
	{
		CEGUIColor.setHSL(CEGUIColor.getHue(),CEGUIColor.getSaturation(), fLumination );
	}
	
	INT Color_a,Color_r,Color_g,Color_b;
	Color_a = CEGUIColor.getAlpha() * 0xFF;
	Color_r = CEGUIColor.getRed() * 0xFF;
	Color_g = CEGUIColor.getGreen() * 0xFF;
	Color_b = CEGUIColor.getBlue() * 0xFF;

	return MAKE_COLOR(Color_r,Color_g,Color_b,Color_a);

}
