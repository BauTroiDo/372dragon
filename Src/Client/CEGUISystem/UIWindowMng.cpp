#include "stdafx.h"
#include "UIGlobal.h"
#include <TDException.h>
#include "UIWindowMng.h"
#include <CEGUIWindowManager.h>
#include "ceguiwindow.h"
#include <CEGUISystem.h>
#include <CEGUILogger.h>		// CYS-ITEMTEXT: a CY layout that fails to load is logged, not fatal
#include <CEGUIExceptions.h>
#include <CEGUIFontManager.h>	// CYS-QUEST: CysFitQuestButtons
#include "TDDataBase.h"
#include "TDDBC_Struct.h"
#include "TDKernel.h"
#include "TDScriptSystem.h"
#include "UIScript.h"
#include "LuaPlus.h"
#include "UILuaControl.h"
#include <OgreMemoryManager.h>
#include "UIString.h"
#include "../CEGUIFalagardEx/FalActionButton.h"
#include "UISystem.h"
#include "CysUiEdit.h"
#include "CysUiCommandRoutes.h"
#include <CEGUIResourceProvider.h>
#include "TDProfile.h"
#include "../CEGUIFalagardEx/FalSuperTooltip.h"
#include "../CEGUIFalagardEx/FalagardMeshWindow.h"
#include <process.h>
#include "TDObjectSystem.h"
#include "TDVariable.h"
#include "AxTrace.h"
#include "windows.h"
#include "tdeventdefine.h"
using namespace LuaPlus;
namespace { CysUiCommandRoutes::Table g_uiCommandRoutes; }
CEGUI::Window*  CUIWindowMng::m_pBackGroundSheet = NULL; // 客户端窗口底板
CUIWindowMng*	CUIWindowMng::s_pMe	= NULL;
BOOL CUIWindowMng::s_bShuttingDown = FALSE;
CUIWindowItem::CUIWindowItem(const _DBC_UI_LAYOUTDEFINE* pLayoutDef)
{
	TDAssert(pLayoutDef);

	m_dwID				= pLayoutDef->nID;
	m_strWindowName		= pLayoutDef->szName;
	m_strLayoutFileName = pLayoutDef->szLayout;
	m_strScriptFileName = pLayoutDef->szScript;
	m_nIsCanDemise		= pLayoutDef->nDemise;


	m_pWindow			= NULL;
	m_pScriptEnv = NULL;
	
	m_bShow = FALSE;
	m_bLayoutLoaded = FALSE;
}

CUIWindowItem::~CUIWindowItem()
{
	//释放Lua环境
	g_pScriptSys->DestroyEnvironment(m_pScriptEnv);
	m_pScriptEnv = NULL;

	// CYS-HUD: dynamic controls
	for(std::map< STRING, LUA_CONTROL::Window* >::iterator it = m_mapDynamicControl.begin(); it != m_mapDynamicControl.end(); ++it)
	{
		if(it->second) LUA_CONTROL::Window::DestroyControl(it->second);
	}
	m_mapDynamicControl.clear();

	//释放lua实例
	for(INT i=0; i<(INT)m_vAllControl.size(); i++)
	{
		if(m_vAllControl[i])
		{
			LUA_CONTROL::Window::DestroyControl(m_vAllControl[i]);
			//LUA_CONTROL::Window* pWindow =  m_vAllControl[i];
			//delete pWindow;
			m_vAllControl[i] = NULL;
		}
	}
	m_vAllControl.clear();

	//释放cegui实例
	CEGUI::WindowManager::getSingleton().destroyWindow( m_pWindow );
	m_pWindow = NULL;
}

bool CUIWindowItem::callbackProperty(CEGUI::Window* window, CEGUI::String& propname, CEGUI::String& propvalue, void* userdata)
{
	if(propname == (CEGUI::utf8*)"Text" && !propvalue.empty())
	{
		//字符串转化
		CEGUI::String strUtf32;

		STRING strMbcs;
		CUIStringSystem::utf8_to_mbcs(STRING(propvalue.c_str()), strMbcs);
		CUIStringSystem::GetMe()->ParserString_Runtime(strMbcs, strUtf32);
		propvalue = strUtf32;
	}

	return true;
}

VOID CUIWindowItem::PreLoadWindow(VOID)
{
	//----------------------------------------------------------------------------
	//创建脚本运行环境
	m_pScriptEnv = g_pScriptSys->NewEnvironment(m_strWindowName.c_str(), m_strScriptFileName.c_str());

	//---------------------------------------
	//加载执行
	m_pScriptEnv->DoFile(m_strScriptFileName.c_str());

	//---------------------------------------
	//注册引用函数

	//注册"this"对象
	LuaObject metaUIWindowItem = g_pScriptSys->GetLuaState()->GetGlobals().GetByName("MetaTable_UIWindowItem");

	// CYS-CYGUI: LuaState::BoxPointer pushes the userdata and returns a LuaStackObject that nobody pops: one Lua
	// stack slot leaked per window created, until every checked script call failed with StackCapacity (code -4,
	// "top=" +1 per call in Build/Logs/2026-09-14-cy-gui/replay-6). objThis is a reference, so the slot can go.
	lua_State* rawState = g_pScriptSys->GetLuaState()->GetCState();
	const int stackTop = lua_gettop(rawState);
	LuaObject objThis = g_pScriptSys->GetLuaState()->BoxPointer(this);
	objThis.SetMetaTable(metaUIWindowItem);
	m_pScriptEnv->GetLuaObject()->SetObject("this", objThis);
	lua_settop(rawState, stackTop);

	//---------------------------------------
	//执行其中的***_PreLoad函数
	CHAR szTemp[MAX_PATH] = {0};
	_snprintf(szTemp, MAX_PATH, "%s_PreLoad", m_strWindowName.c_str());
	m_pScriptEnv->DoFunction(szTemp);

	m_bLayoutLoaded = FALSE;
}

// CYS-QUEST: the bottom buttons of the NPC dialogue are 40x20 CY frames at x 10 / 50 (Quest.layout.xml), laid out
// for two Chinese glyphs; "Nhận" / "Tiếp" in the 12 px Noto label font fill the whole 40 px and the two
// adjacent buttons read as one word. CY positions and labels are kept; the labels use a 10 px variant of the same font.
static VOID CysFitQuestButtons(VOID)
{
	CEGUI::FontBase* pFont = NULL;
	try { pFont = CEGUI::FontManager::getSingleton().createCysDerivedFont("CysQuestButton", "Schema/SongTiBmp12.font", 10.0f); }
	catch(CEGUI::Exception&) { pFont = NULL; }
	if(!pFont) return;
	static const char* const kButtons[] = { "Quest_Button_Accept", "Quest_Button_Continue", "Quest_Button_Refuse" };
	CEGUI::WindowManager& wm = CEGUI::WindowManager::getSingleton();
	for(INT i = 0; i < 3; ++i)
		if(wm.isWindowPresent(kButtons[i])) wm.getWindow(kButtons[i])->setFont(pFont);
}

VOID CUIWindowItem::LoadWindow(VOID)
{
	TDAssert(m_pWindow == NULL);
	if(m_bLayoutLoaded) return;

	// CYS-PERF: layout / control registration / OnLoad times of a slow demand load (CYS_PERF=1, >= 30 ms)
	LARGE_INTEGER cysT0, cysT1, cysT2, cysT3, cysF;
	::QueryPerformanceCounter(&cysT0);
	//----------------------------------------------------------------------------
	//加载布局文件
	m_pWindow = CEGUI::WindowManager::getSingleton().loadWindowLayout(m_strLayoutFileName, "", "",
		callbackProperty);
	::QueryPerformanceCounter(&cysT1);
	TDAssert(m_pWindow);
	// CYS-UIEDIT 19/09: ap vi tri/kich thuoc nguoi dung da keo tay, TRUOC _RegisterControlToScript de
	// script cua khung doc duoc hinh hoc da sua. Khong co file de thi day la mot lan tra ve 0 ngay.
	CysUiEdit::ApplyTo(m_pWindow, m_strLayoutFileName.c_str());
	//初始状态：隐藏
	m_pWindow->hide();
	CUIWindowMng::GetClientScreen()->addChildWindow(m_pWindow);

	//注册控件
	_RegisterControlToScript(m_pWindow);
	if(m_strWindowName == "Quest") CysFitQuestButtons(); // CYS-QUEST
	::QueryPerformanceCounter(&cysT2);

	//---------------------------------------
	//执行其中的***_OnLoad函数
	CHAR szTemp[MAX_PATH] = {0};
	_snprintf(szTemp, MAX_PATH, "%s_OnLoad", m_strWindowName.c_str());
	m_pScriptEnv->DoFunction(szTemp);

	m_bLayoutLoaded = TRUE;
	::QueryPerformanceCounter(&cysT3); ::QueryPerformanceFrequency(&cysF); // CYS-PERF
	{
		static int s_cysPerfOn = -1;
		if (s_cysPerfOn < 0) { char v[4] = {0}; s_cysPerfOn = ::GetEnvironmentVariableA("CYS_PERF", v, sizeof(v)) ? 1 : 0; }
		const double k = 1000.0 / double(cysF.QuadPart);
		if (s_cysPerfOn && double(cysT3.QuadPart - cysT0.QuadPart) * k >= 30.0)
		{
			char line[512];
			_snprintf(line, sizeof(line) - 1, "CYS-PERF slow load %s layout=%.1f ms register=%.1f ms onload=%.1f ms file=%s",
				m_strWindowName.c_str(), double(cysT1.QuadPart - cysT0.QuadPart) * k, double(cysT2.QuadPart - cysT1.QuadPart) * k,
				double(cysT3.QuadPart - cysT2.QuadPart) * k, m_strLayoutFileName.c_str());
			line[sizeof(line) - 1] = 0;
			CEGUI::Logger::getSingleton().logEvent(line, CEGUI::Standard);
		}
	}
}

VOID CUIWindowItem::_RegisterControlToScript(CEGUI::Window* pWindow)
{
	//设置UserData,用于回朔调用
	pWindow->setUserData(this);

	//Register Me
	LUA_CONTROL::Window* pTempControl = LUA_CONTROL::Window::CreateControl(pWindow);

	// CYS-CYGUI: pop the slot BoxPointer leaves (one per control = tens of thousands per session); see Init.
	lua_State* rawState = g_pScriptSys->GetLuaState()->GetCState();
	const int stackTop = lua_gettop(rawState);
	LuaObject objThis = g_pScriptSys->GetLuaState()->BoxPointer(pTempControl);
	objThis.SetMetaTable(*(pTempControl->GetMetaTable()));

	CEGUI::String strTemp = pWindow->getName();
	m_pScriptEnv->GetLuaObject()->SetObject(strTemp.c_str(), objThis);
	lua_settop(rawState, stackTop);
	
	m_vAllControl.push_back(pTempControl);

	//对ActionButton特殊处理
	if(pWindow->testClassName((CEGUI::utf8*)"FalagardActionButton"))
	{
		CEGUI::IFalagardActionButton* pActionButton = (CEGUI::IFalagardActionButton*)(CEGUI::FalagardActionButton*)pWindow;

		//DrawStarted
		pActionButton->subscribeDragDropStartedEvent(CEGUI::Event::Subscriber(&CUISystem::handleActionDragDropStarted, CUISystem::GetMe()));
		//MouseEnter
		pActionButton->subscribeMouseEnterEvent(CEGUI::Event::Subscriber(&CUISystem::handleActionButtonMouseEnter, CUISystem::GetMe()));
		//MouseLeave
		pActionButton->subscribeMouseLeaveEvent(CEGUI::Event::Subscriber(&CUISystem::handleActionButtonMouseLeave, CUISystem::GetMe()));
		//ParentHidden
		pWindow->subscribeEvent((CEGUI::utf8*)"ParentHidden", CEGUI::Event::Subscriber(&CUISystem::handleActionButtonParentHidden, CUISystem::GetMe()));
	}
	else if(pWindow->testClassName((CEGUI::utf8*)"FalagardMeshWindow"))
	{
		CEGUI::IFalagardMeshWindow* pMeshWindow = (CEGUI::IFalagardMeshWindow*)(CEGUI::FalagardMeshWindow*)pWindow;

		pMeshWindow->subscribeShownEvent(CEGUI::Event::Subscriber(&CUISystem::handleMeshWindowShown, CUISystem::GetMe()));
		pMeshWindow->subscribeHidenEvent(CEGUI::Event::Subscriber(&CUISystem::handleMeshWindowHiden, CUISystem::GetMe()));
	}

	//Register Child
	for(INT i=0; i<(INT)pWindow->getChildCount(); i++)
	{
		_RegisterControlToScript(pWindow->getChildAtIdx(i));
	}

	return;
}

// CYS-HUD ---------------------------------------------------------------------------------------------------
LuaPlus::LuaObject CUIWindowItem::GetControlObject(CEGUI::Window* pWindow)
{
	LUA_CONTROL::Window* pControl = NULL;
	for(INT i=0; i<(INT)m_vAllControl.size(); i++)
	{
		if(m_vAllControl[i] && m_vAllControl[i]->GetCEGUIWindow() == pWindow) { pControl = m_vAllControl[i]; break; }
	}
	if(!pControl)
	{
		STRING strName = pWindow->getName().c_str();
		std::map< STRING, LUA_CONTROL::Window* >::iterator it = m_mapDynamicControl.find(strName);
		if(it != m_mapDynamicControl.end() && it->second && it->second->GetCEGUIWindow() != pWindow)
		{
			// the name was reused by a new clone: drop the stale control
			LUA_CONTROL::Window::DestroyControl(it->second);
			m_mapDynamicControl.erase(it);
			it = m_mapDynamicControl.end();
		}
		if(it == m_mapDynamicControl.end())
		{
			pControl = LUA_CONTROL::Window::CreateControl(pWindow);
			m_mapDynamicControl[strName] = pControl;
		}
		else
			pControl = it->second;
	}
	// CYS-CYGUI: same BoxPointer slot leak as _RegisterControlToScript; the returned LuaObject is a reference.
	lua_State* rawState = g_pScriptSys->GetLuaState()->GetCState();
	const int stackTop = lua_gettop(rawState);
	LuaObject obj = g_pScriptSys->GetLuaState()->BoxPointer(pControl);
	obj.SetMetaTable(*(pControl->GetMetaTable()));
	lua_settop(rawState, stackTop);
	return obj;
}

VOID CUIWindowItem::ReleaseControlObject(CEGUI::Window* pWindow)
{
	if(!pWindow) return;
	// children first (their names are unique too)
	for(INT i=0; i<(INT)pWindow->getChildCount(); i++) ReleaseControlObject(pWindow->getChildAtIdx(i));
	std::map< STRING, LUA_CONTROL::Window* >::iterator it = m_mapDynamicControl.find(STRING(pWindow->getName().c_str()));
	if(it != m_mapDynamicControl.end())
	{
		if(it->second) LUA_CONTROL::Window::DestroyControl(it->second);
		m_mapDynamicControl.erase(it);
	}
}

VOID CUIWindowItem::_TransWindowText(CEGUI::Window* pWindow)
{
	CEGUI::String str = pWindow->getTextOriginal();
	if(!str.empty())
	{
		STRING strMBCS_ToTrans;
		CUIStringSystem::utf8_to_mbcs(str.c_str(), strMBCS_ToTrans);

		// 经过special转化的string，已经是utf32格式。
		CEGUI::String strMBCS_Transed_Done;

		CUIStringSystem::GetMe()->ParserString_Runtime(strMBCS_ToTrans, strMBCS_Transed_Done);

		pWindow->setText(strMBCS_Transed_Done);
	}
	//Register Child
	for(INT i=0; i<(INT)pWindow->getChildCount(); i++)
	{
		_TransWindowText(pWindow->getChildAtIdx(i));
	}
}

VOID CUIWindowItem::Show(BOOL bShow)
{
	if(bShow == m_bShow) return;


	//显示
	if(bShow)
	{
		m_pWindow->show();
		m_pWindow->activate();
	}
	else
	{
		m_pWindow->hide();

		//响应窗口关闭时一些附加处理
		onWindowHidden();
	}

	//防止屏幕闪烁
	CUIWindowMng::GetClientScreen()->requestRedraw();

	
	m_bShow = bShow;
	// 禅让窗口,无论显示还是关闭窗口,都需要进行禅让窗口更新
}

void CUIWindowItem::onWindowHidden(void)
{
	//如果当前supertooltips
}

INT CUIWindowItem::LUA_RegisterEvent(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);
	if (!(args[2].IsString())) return 0;

	if(m_bLayoutLoaded) 
	{
		TDThrow("%s Must register event in \"***PreLoad\" Function ", m_strWindowName.c_str());
	}

	STRING strEventName = args[2].GetString();

	// CYS-PERF-FIX uievent: CY 3.71 UI_CEGUI RegisterEvent (Build/re/login-polish/out/u_onload.txt): argument 3 is an
	// optional boolean (default true) kept per event name at item +0x1c8; an event this window already registered is
	// not registered twice. 7.005 registrations of the CY scripts pass false (ADJEST_UI_POS, VIEW_RESOLUTION_CHANGED,
	// HIDE_ON_SCENE_TRANSED, OBJECT_CARED_EVENT, PACKAGE_ITEM_CHANGED_EX, MONEY_CHANGE_EX, ...).
	const BOOL bLoad = (pState->GetTop() >= 3 && args[3].IsBoolean()) ? (args[3].GetBoolean() ? TRUE : FALSE) : TRUE;
	if (m_cysEventLoad.find(strEventName) != m_cysEventLoad.end()) return 0;
	m_cysEventLoad[strEventName] = bLoad;

	// CYS: preserve all pointer bits through the event callback owner.
	g_pEventSys->RegisterEventHandle(strEventName, _OnGameEvent, reinterpret_cast<UINT_PTR>(this));
	return 0;
}

INT CUIWindowItem::LUA_Show(LuaPlus::LuaState* pState)
{
	CUIWindowMng::GetMe()->DemiseWindow( this, TRUE );
	Show(TRUE);
	return 0;
}

INT CUIWindowItem::LUA_Hide(LuaPlus::LuaState* pState)
{
	CUIWindowMng::GetMe()->DemiseWindow( this, FALSE );
	Show(FALSE);
	return 0;
}

//显示/隐藏
INT	 CUIWindowItem::LUA_TogleShow(LuaPlus::LuaState* pState)
{
	if(m_bShow) 
	{
		CUIWindowMng::GetMe()->DemiseWindow( this, FALSE );
		Show(FALSE);
	}
	else 
	{
		CUIWindowMng::GetMe()->DemiseWindow( this, TRUE );
		Show(TRUE);
	}
	return 0;
}
	
INT	CUIWindowItem::LUA_IsVisible(LuaPlus::LuaState* pState)
{
	pState->PushBoolean(m_bShow==TRUE);

	return 1;
}

//转化所有窗口上的文字
INT	CUIWindowItem::LUA_TransAllWindowText(LuaPlus::LuaState* pState)
{
	_TransWindowText(m_pWindow);
	return 0;
}

//关心与某逻辑Obj的距离(用于商人或者任务窗口，当距离超过一定距离后自动关闭)
// CYS-HOST2: B UI_CEGUI.dll 0x180058500 (CUIWindowItem::LUA_GetChildOffset, listing
// Build/Logs/2026-09-17-host-plumbing/measure/disasm/GetChildOffset.txt):
//     if (!lua_isstring(L, 2)) throw "LUA: CUIWindowItem::LUA_GetChildOffset Wrong Param1"
//     w = FindChild(name)                       // 0x180057690: isChild(name) ? getChild(name) : NULL, recursive
//     x = y = 0
//     while (w && w != m_pWindow) { x += w->getAbsoluteXPosition(); y += w->getAbsoluteYPosition(); w = w->d_parent; }
//     push(x); push(y); return 2
// getAbsoluteXPosition() in this CEGUI (0.4.1, CEGUIWindow.h:904) is the position in PIXELS RELATIVE TO THE PARENT
// ("absolute" = absolute metrics mode, not screen space), so the sum over the parent chain is the child's pixel
// offset inside this layout's root window - which is exactly how the scripts use it (ActionSkill.lua:807-814 adds
// ActionSkill_Frame's own AbsoluteXPosition to get to screen space). An unknown name gives (0, 0), as in B.
//
// B's FindChild (0x180057690) walks the tree itself: root->isChild(name) ? root->getChild(name) : for every child c,
// c->isChild(name) ? c->getChild(name) : recurse into c's children (0x1800575f0). It has to, because
// Window::isChild(name) / getChild(name) of this CEGUI (0.4.1, CEGUIWindow.cpp:333/393) look at DIRECT children only
// (the recursive lookup arrived with CEGUI 0.5). Caught live: "MiniMap_Forum" (MiniMap.layout.xml:485, nested) came back
// found=0 from a direct-only lookup (live-5-on).
static CEGUI::Window* cysFindDescendant(CEGUI::Window* pRoot, const CEGUI::String& name)
{
	if (!pRoot) return NULL;
	if (pRoot->isChild(name)) return pRoot->getChild(name);
	const CEGUI::uint nCount = pRoot->getChildCount();
	for (CEGUI::uint i = 0; i < nCount; ++i)
	{
		CEGUI::Window* pFound = cysFindDescendant(pRoot->getChildAtIdx(i), name);
		if (pFound) return pFound;
	}
	return NULL;
}

INT CUIWindowItem::LUA_GetChildOffset(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);
	if (!args[2].IsString() && !args[2].IsNumber())   // B: lua_isstring(L, 2) accepts a number too
	{
		TDThrow("LUA: CUIWindowItem::LUA_GetChildOffset Wrong Param1");
	}
	const CEGUI::String name((const CEGUI::utf8*)args[2].GetString());
	CEGUI::Window* pWalk = cysFindDescendant(m_pWindow, name);
	float fX = 0.0f, fY = 0.0f;
	while (pWalk && pWalk != m_pWindow)
	{
		fX += pWalk->getAbsoluteXPosition();
		fY += pWalk->getAbsoluteYPosition();
		pWalk = pWalk->getParent();
	}
	{	// CYS_HOST2_PROBE=1: prove the offset against screen rects (child unclipped rect minus the root's)
		static int s_probe = -1;
		if (s_probe < 0) { char text[4] = {0}; s_probe = (::GetEnvironmentVariableA("CYS_HOST2_PROBE", text, sizeof(text)) == 1 && text[0] == '1') ? 1 : 0; }
		if (s_probe == 1 && m_pWindow)
		{
			CEGUI::Window* pChild = cysFindDescendant(m_pWindow, name);
			const CEGUI::Rect rootRect = m_pWindow->getUnclippedPixelRect();
			const CEGUI::Rect childRect = pChild ? pChild->getUnclippedPixelRect() : rootRect;
			char line[512] = {0};
			_snprintf(line, sizeof(line) - 1, "CYS-HOST2: GetChildOffset %s:%s -> (%.1f, %.1f); screen delta (%.1f, %.1f) found=%d",
				m_strWindowName.c_str(), name.c_str(), fX, fY, childRect.d_left - rootRect.d_left, childRect.d_top - rootRect.d_top, pChild ? 1 : 0);
			CEGUI::Logger::getSingleton().logEvent((const CEGUI::utf8*)line);
		}
	}
	pState->PushNumber(fX);
	pState->PushNumber(fY);
	return 2;
}

INT CUIWindowItem::LUA_CareObject(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);
	if (!(args[2].IsInteger()))
	{
		TDThrow("LUA: CUIWindowItem::LUA_CareObject[2] Wrong Param1");
	}
	if (!(args[3].IsInteger())) 
	{
		TDThrow("LUA: CUIWindowItem::LUA_CareObject[3] Wrong Param1");
	}
	if (pState->GetTop() >= 4 && !args[4].IsNil() && !args[4].IsString())
	{
		TDThrow("LUA: CUIWindowItem::LUA_CareObject[4] Wrong Param1");
	}
	//Object的ID
	INT nObjID = args[2].GetInteger();

	//是否关心
	INT	bCare = args[3].GetInteger()==1;

	//谁在关心
	// GL/CY CareObject(object, enabled) identifies the caller by its window name.
	// Keep the explicit third argument accepted by the original 0.85 Lua scripts.
	std::string str = args[4].IsString() ? args[4].GetString() : m_strWindowName;

	g_pObjectSystem->CareObject(nObjID, bCare, str);

	return 0;
}

VOID WINAPI	CUIWindowItem::_OnGameEvent(const EVENT* pEvent, UINT_PTR dwOwnerData)
{
	if (CUIWindowMng::IsShuttingDown()) return;
	TDAssert(pEvent);
	
	//--------------------------------------------------------
	//分发
	CUIWindowItem* pWinItem = reinterpret_cast<CUIWindowItem*>(dwOwnerData);
	if(!pWinItem) return;
	// Route before demand-loading. CY's table names the actual receivers;
	// broadcasting UI_COMMAND would load over 1,400 unrelated layouts.
	if (pEvent->pEventDef && pEvent->pEventDef->idEvent == GE_UI_COMMAND) {
		if (pEvent->vArg.empty()) return;
		char* end = nullptr;
		const unsigned long command = strtoul(pEvent->vArg[0].c_str(), &end, 10);
		if (!end || *end || !g_uiCommandRoutes.Allows(command, pWinItem->m_dwID)) return;
	}

	// CYS-LOGIN: CY 3.71 UI_CEGUI.dll CUIWindowItem::_OnGameEvent (FUN_180079300) returns at once for
	// VIEW_RESOLUTION_CHANGED (event id 0x166, Game.exe table FUN_140a0db90) when the window is not loaded yet
	// (item +0x170 == 0; also requires item +0x180 == 1, INF: set for the demand-loaded windows). 1.651 of the 2.042 CY
	// scripts register that event, so without this every window resize (the login window 1280x720 -> View_Resoution
	// at character select, CysLoginWindowRestore) demand-loads ~1.150 layouts.
	if(!(pWinItem->m_bLayoutLoaded) && pEvent->pEventDef && pEvent->pEventDef->idEvent == GE_VIEW_RESOLUTION_CHANGED)
		return;

	// CYS-PERF-FIX uievent: CY 3.71 CUIWindowItem::_OnGameEvent (UI_CEGUI FUN_180079300): an event registered with
	// bLoad=false is dropped while the window is hidden (item +0x160 = shown): it neither demand-loads the layout nor runs
	// the script. Without it one package / world-entry event demand-loaded hundreds of CY layouts in a single frame
	// (perf-cy world replay: 815 ms and 1.07 M allocations after picking loot, 814 ms at world entry).
	// CYS_PERF_UIEVENT=legacy keeps the 0.85 behaviour for A/B runs.
	static int s_cysUiEventLegacy = -1;
	if (s_cysUiEventLegacy < 0)
	{
		char mode[16] = {0};
		const DWORD n = ::GetEnvironmentVariableA("CYS_PERF_UIEVENT", mode, sizeof(mode));
		s_cysUiEventLegacy = (n && n < sizeof(mode) && _stricmp(mode, "legacy") == 0) ? 1 : 0;
	}
	if (!s_cysUiEventLegacy && pEvent->pEventDef && pEvent->pEventDef->szEvent && !(pWinItem->m_bShow))
	{
		std::map< STRING, BOOL >::const_iterator itLoad = pWinItem->m_cysEventLoad.find(pEvent->pEventDef->szEvent);
		if (itLoad != pWinItem->m_cysEventLoad.end() && !itLoad->second)
			return;
	}

	// CYS-PERF: slow window log (CYS_PERF=1): window, event, whether the layout was demand-loaded, time >= 8 ms
	static int s_cysPerfOn = -1;
	if (s_cysPerfOn < 0) { char v[4] = {0}; s_cysPerfOn = ::GetEnvironmentVariableA("CYS_PERF", v, sizeof(v)) ? 1 : 0; }
	struct CysPerfWinLog
	{
		CUIWindowItem* item; const EVENT* ev; LARGE_INTEGER t0; bool on, wasLoaded;
		~CysPerfWinLog()
		{
			if (!on) return;
			LARGE_INTEGER t1, f; ::QueryPerformanceCounter(&t1); ::QueryPerformanceFrequency(&f);
			const double ms = double(t1.QuadPart - t0.QuadPart) * 1000.0 / double(f.QuadPart);
			if (ms >= 8.0)
			{
				char line[512];
				_snprintf(line, sizeof(line) - 1, "CYS-PERF slow window %s event %s %.1f ms loaded_now=%d", item->GetWindowName(),
					(ev->pEventDef && ev->pEventDef->szEvent) ? ev->pEventDef->szEvent : "?", ms, wasLoaded ? 0 : 1);
				line[sizeof(line) - 1] = 0;
				CEGUI::Logger::getSingleton().logEvent(line, CEGUI::Standard);
			}
		}
	} cysPerfWin = { pWinItem, pEvent, {0}, s_cysPerfOn == 1, pWinItem->m_bLayoutLoaded != FALSE };
	if (cysPerfWin.on) ::QueryPerformanceCounter(&cysPerfWin.t0);

	//加载
	if(!(pWinItem->m_bLayoutLoaded))
	{
		// CYS-ITEMTEXT 15/09: a CY layout that CEGUI refuses (ZBS_TeamInfo reuses the window name
		// NoDiffMatch_TeamManger_BottomFrame of NoDiffMatch_TeamManger) threw out of the main loop when an event
		// registered by every CY window (the login 3D scene load) demand-loaded all 1.153 layouts (item-text
		// gui-live-1). The window stays unloaded and its script is not called; the next event tries again.
		try
		{
			pWinItem->LoadWindow();
		}
		catch (CEGUI::Exception& e)
		{
			CEGUI::Logger::getSingleton().logEvent("CYS UI: window '" + CEGUI::String(pWinItem->m_strWindowName.c_str()) +
				"' not loaded: " + e.getMessage(), CEGUI::Errors);
			return;
		}
		if(!(pWinItem->m_bLayoutLoaded)) return;
	}

	//--------------------------------------------------------
	//参数
	for(INT i=0; i<(INT)pEvent->vArg.size(); i++)
	{
		CHAR szTemp[MAX_PATH];
		_snprintf(szTemp, MAX_PATH, "arg%d", i);
		g_pScriptSys->GetLuaState()->GetGlobals().SetString(szTemp, pEvent->vArg[i].c_str());
	}

	//--------------------------------------------------------
	//调用脚本
	CHAR szFunctionName[MAX_PATH];
	_snprintf(szFunctionName, MAX_PATH, "%s_OnEvent", 
		pWinItem->m_strWindowName.c_str());

	CHAR szFunctionParam[MAX_PATH];
	_snprintf(szFunctionParam, MAX_PATH, "\"%s\"", 
		pEvent->pEventDef->szEvent);

	pWinItem->m_pScriptEnv->DoFunction(szFunctionName, szFunctionParam);
}

VOID CUIWindowItem::FireUIEvent(LPCTSTR szEventHandle, CEGUI::Window* pWindow)
{
	if (CUIWindowMng::IsShuttingDown() || !m_pScriptEnv) return;
	//--------------------------------------------------------
	//参数
	g_pScriptSys->GetLuaState()->GetGlobals().SetString("arg0", pWindow->getName().c_str());

	m_pScriptEnv->DoString(szEventHandle);
}
VOID CUIWindowItem::MoveTo( CEGUI::Point&  newPos )
{
	m_pWindow->setPosition( newPos );
}
void CUIWindowItem::PositionSelf()
{
	if( m_pWindow )
	{
		CEGUI::MouseCursor& cursor = CEGUI::MouseCursor::getSingleton();
        CEGUI::Rect screen( CEGUI::System::getSingleton().getRenderer()->getRect());
        CEGUI::Rect tipRect( m_pWindow->getUnclippedPixelRect());
        const CEGUI::Image* mouseImage = cursor.getImage();

        CEGUI::Point mousePos(cursor.getPosition());
        CEGUI::Size mouseSz(0,0);

        if (mouseImage)
        {
            mouseSz = mouseImage->getSize();
        }

        CEGUI::Point tmpPos(mousePos.d_x - tipRect.getWidth() - 5, mousePos.d_y - tipRect.getHeight() - 5);
        tipRect.setPosition(tmpPos);

        // if tooltip would be off the right of the screen,
        // reposition to the other side of the mouse cursor.
        if ( tipRect.d_right < 0 )
        {
            tmpPos.d_x = mousePos.d_x + mouseSz.d_width + 5;
        }

        // if tooltip would be off the bottom of the screen,
        // reposition to the other side of the mouse cursor.
        if ( tipRect.d_bottom < 0 )
        {
            tmpPos.d_y = mousePos.d_y + mouseSz.d_height + 5;
        }

        // set final position of tooltip window.
        m_pWindow->setPosition( CEGUI::Absolute, tmpPos);
	}
}
///////////////////////////////////////////////
// CUIWindowMng
CUIWindowMng::CUIWindowMng(VOID)
{
	s_pMe = this;
	s_bShuttingDown = FALSE;
}

CUIWindowMng::~CUIWindowMng(VOID)
{
	BeginShutdown();
	WINDOWLIST::iterator it;
	for(it=m_aWindowList.begin(); it!=m_aWindowList.end(); it++)
	{
		if(*(it))
		{
			delete (CUIWindowItem*)(*it);
			*it = NULL;
		}
	}
	m_aWindowList.clear();
	s_pMe = NULL;
}

// 初始化窗口管理器
VOID CUIWindowMng::Init(VOID)
{
	CEGUI::ResourceProvider* provider = CEGUI::System::getSingleton().getResourceProvider();
	CEGUI::RawDataContainer commands;
	provider->loadRawDataContainer("UICommandIndex.txt", commands, "General");
	try {
		g_uiCommandRoutes.Load(std::string((const char*)commands.getDataPtr(), commands.getSize()));
	} catch (...) { provider->unloadRawDataContainer(commands); throw; }
	provider->unloadRawDataContainer(commands);
	CEGUI::Logger::getSingleton().logEvent("CYS UI command routes: " + std::to_string(g_uiCommandRoutes.Size()));
	//创建ui系统底板
//	PROFILE_PUSH(Create_MainBoard);

	m_pBackGroundSheet = CEGUI::WindowManager::getSingleton().createWindow((CEGUI::utf8*)"DefaultGUISheet", (CEGUI::utf8*)"__BACKGOUNDSHEET__");
	m_pBackGroundSheet->setMouseHollow(true);
	m_pBackGroundSheet->moveToFront();
	//m_pBackGroundSheet->captureInput();
	m_pBackGroundSheet->setDistributesCapturedInputs(true);

	CEGUI::System::getSingleton().setGUISheet( m_pBackGroundSheet );

	// CYS-UIEDIT: bo sua khong phu thuoc truc tiep vao quan ly cua so — no goi qua con tro nay.
	CysUiEdit::SetOpenWindowFn(&CysUiEditOpenWindow);

//	PROFILE_POP(Create_MainBoard);

	//加载UI
	tDataBaseSystem* pUIDBC = (tDataBaseSystem*)g_pKernel->GetNode("bin\\dbc");
	TDAssert(pUIDBC);
	const tDataBase* pDBC = pUIDBC->GetDataBase(DBC_UI_LAYOUTDEFINE);

	for(INT i=0; i<(INT)pDBC->GetRecordsNum(); i++)
	{
		const _DBC_UI_LAYOUTDEFINE* pLine = (const _DBC_UI_LAYOUTDEFINE*)((tDataBase*)pDBC)->Search_LineNum_EQU(i);

		//产生一个新的WindowItem
		CUIWindowItem* pItem = new CUIWindowItem(pLine);
		//预加载窗口
		pItem->PreLoadWindow();

		m_aWindowList.push_back( pItem );
	}
}

// 关闭所有窗口
VOID CUIWindowMng::HideAllWindow()
{
	WINDOWLIST::iterator  it;
	for( it = m_aWindowList.begin(); it != m_aWindowList.end(); it ++ )
	{
		(*it)->Show(FALSE);
	}
}

BOOL CUIWindowMng::IsWindowShow(LPCTSTR szUIName)
{
	TDAssert(szUIName);

	WINDOWLIST::iterator  it;
	for( it=m_aWindowList.begin(); it != m_aWindowList.end(); it ++ )
	{
		if(strcmp((*it)->GetWindowName(), szUIName) == 0)
			return (*it)->IsWindowShow();
	}

	return FALSE;
}

// CYS-UIEDIT 19/09: mo MOT khung theo ten, ke ca khung khong co duong mo binh thuong.
//
// `OpenWindow("X")` cua Lua chi day su kien `OPEN_WINDOW` (CysHostGlobals.cpp:167); khung nao KHONG
// tu dang ky su kien do va so khop `arg0 == "X"` thi khong bao gio mo. Do la ly do nguoi dung doi
// mot "NPC de mo cac khung con loi" — va cung la hinh thuc cua loi bam `Q` (khung nam im vi chua ai
// mo duoc no). Ham nay di thang qua danh sach cua CUIWindowMng nen khong phu thuoc script cua khung.
//
// Nap layout duoc boc try/catch giong _OnGameEvent (CYS-ITEMTEXT 15/09: mot layout CY bi CEGUI tu
// choi tung nem ra khoi vong lap chinh).
bool CysUiEditOpenWindow(const char* szUIName)
{
	CUIWindowMng* pMng = CUIWindowMng::GetMe();
	if(!pMng || !szUIName || !*szUIName) return false;
	return pMng->ShowWindowByName(szUIName) != FALSE;
}

BOOL CUIWindowMng::ShowWindowByName(LPCTSTR szUIName)
{
	if(!szUIName || !*szUIName) return FALSE;
	for(WINDOWLIST::iterator it = m_aWindowList.begin(); it != m_aWindowList.end(); ++it)
	{
		if(strcmp((*it)->GetWindowName(), szUIName) != 0) continue;
		CUIWindowItem* pItem = *it;
		if(!(pItem->IsLayoutLoaded()))
		{
			try
			{
				pItem->LoadWindow();
			}
			catch(CEGUI::Exception& e)
			{
				CEGUI::Logger::getSingleton().logEvent("CYS-UIEDIT: khong nap duoc '" +
					CEGUI::String((CEGUI::utf8*)pItem->GetWindowName()) + "': " + e.getMessage(), CEGUI::Errors);
				return FALSE;
			}
			if(!(pItem->IsLayoutLoaded())) return FALSE;
		}
		DemiseWindow(pItem, TRUE);
		pItem->Show(TRUE);
		return TRUE;
	}
	return FALSE;
}

BOOL CUIWindowMng::CloseWindowByName(LPCTSTR szUIName)
{
	// CYS: reuse managed Show(FALSE), which updates state and hide callbacks.
	if(!szUIName || !*szUIName) return FALSE;
	for(WINDOWLIST::iterator it = m_aWindowList.begin(); it != m_aWindowList.end(); ++it)
	{
		if(strcmp((*it)->GetWindowName(), szUIName) == 0)
		{
			DemiseWindow(*it, FALSE);
			(*it)->Show(FALSE);
			return TRUE;
		}
	}
	return FALSE;
}

void CUIWindowMng::DemiseWindowTest( CUIWindowItem* pItem, BOOL bShow )
{
	if( pItem->IsCanDemise() && bShow )
	{
		switch( pItem->GetDemiseType() )
		{
		case 2:
			{
				WINDOWLIST::iterator it;
				for( it = m_aWindowList.begin(); it != m_aWindowList.end(); it ++ )
				{
					if( (*it)->GetDemiseType() == 2 )  // 关掉所有的是2的窗口
					{
						// 如果打开，而且是自己，而且已经打开了，就不处理
						if( bShow && ( (*it) == pItem ) && (*it)->IsWindowShow() )
							return;
						if( (*it)->IsWindowShow() )
							(*it)->Show( FALSE );
					}
				}
			}
			break;
		case 3:
			{
				WINDOWLIST::iterator it;
				for( it = m_aWindowList.begin(); it != m_aWindowList.end(); it ++ )
				{
					if( (*it)->GetDemiseType() == 3 )  // 关掉所有的是3的窗口
					{
						// 如果打开，而且是自己，而且已经打开了，就不处理
						if( bShow && ( (*it) == pItem ) && (*it)->IsWindowShow() )
							return;
						if( (*it)->IsWindowShow() )
							(*it)->Show( FALSE );
					}
				}
			}
			break;
		case 4:
		case 6:
			{
				CloseAllWindow();
				break;
			}
		case 5: // 自适应窗口
			{
				pItem->PositionSelf();
			}
			break;
		default:
			break;
		}
	}
}
// 禅让窗口操作
VOID CUIWindowMng::DemiseWindow( CUIWindowItem* pItem, BOOL bShow )
{
	DemiseWindowTest( pItem, bShow );
	return;
}

bool CUIWindowMng::CloseAllWindow()
{
	bool bCloseOne = false;
	WINDOWLIST::iterator it;
	for( it = m_aWindowList.begin(); it != m_aWindowList.end(); it ++ )
	{
		if( (*it)->GetDemiseType() != 0 && (*it)->GetDemiseType() != 6 &&  (*it)->IsWindowShow() )  // 关掉所有的不是0和6的窗口
		{
			// 如果打开，而且是自己，而且已经打开了，就不处理
			if( (*it)->IsWindowShow() )
			{
				(*it)->Show( FALSE );
				bCloseOne = true;
			}
		}
	}

	return bCloseOne;
}

void CUIWindowMng::OnEscape() // 响应esc键
{
	//  [4/6/2006] yangjun
	if(CloseAllWindow()) return;

	// 如果没有窗口显示了，就开开系统菜单
	g_pEventSys->PushEvent( GE_TOGLE_SYSTEMFRAME );
}
