#include "StdAfx.h"
#include "UIGlobal.h"
#include "UILuaControl.h"
#include "TDScriptSystem.h"
#include "TDException.h"
#include "UISystem.h"
#include "UIIconsMng.h"
#include <OgreMemoryManager.h>
#include <elements\CEGUIProgressBar.h>
#include "ceguipropertyhelper.h"
#include <CEGUIFontManager.h>
#include <vector>
#include <string>
#include <cstring>
#include "UIString.h"
#include "CysTooltipContract.h"
#include <elements\CEGUIPopupMenu.h>
#include <elements\ceguilistbox.h>
#include <elements\CEGUIScrollbar.h>
#include <elements\ceguilistboxtextitem.h>
#include <elements\ceguicombobox.h>
#include <elements\ceguimulticolumnlist.h>
#include "..\CEGUIFalagardEx\FalActionButton.h"
#include "..\CEGUIFalagardEx\FalagardComplexWindow.h"
#include "..\CEGUIFalagardEx\FalagardEditbox.h"
#include "..\CEGUIFalagardEx\FalSuperTooltip.h"
#include "..\CEGUIFalagardEx\Falagardinfolist.h"
#include "..\CEGUIFalagardEx\Falagardminimap.h"
#include "..\CEGUIFalagardEx\Falagardradar.h"
#include "..\CEGUIFalagardEx\FalagardScenemap.h"
#include "..\CEGUIFalagardEx\FalagardAnimate.h"
// CYS-HUD
#include "..\CEGUIFalagardEx\FalagardNotSuperList.h"
#include "..\CEGUIFalagardEx\FalagardListBoxEx.h"
// CYS-MTSWEEP 19/09: can hai lop nay de phan biet ba nghia cua ten Lua `AddItem` theo kieu THAT.
#include "..\CEGUIFalagardEx\FalagardImageListItem.h"
#include "..\CEGUIFalagardEx\FalagardImageListEx.h"
#include "..\CEGUIFalagardEx\FalagardScrollInfo.h"
#include "..\CEGUIFalagardEx\FalagardAchievementWindow.h"
#include "..\CEGUIFalagardEx\FalagardParticleSystem.h"
#include "UIWindowMng.h"
#include <CEGUIScriptModule.h>
#include "CEGUIPropertyHelper.h"
#include "TDObjectSystem.h"
#include "tdworldsystem.h"
#include "TDDBC_Struct.h"
#include "UIWindowMng.h"
#include "TDEventDefine.h"
#include "TDFakeObjSystem.h"
#include "CysUiMeshBridge.h"
#include <cstdarg>   // CYS-MESHWIN: cysMeshWinLog
#include <cstring>   // CYS-MESHWIN: strstr
#include "CysUiFadeBinding.h"
#include "CysFlashBinding.h"
#include "..\CEGUIFalagardEx\FalChatHistory.h"
#include "..\CEGUIFalagardEx\FalChatChannel.h"
#include "..\CEGUIFalagardEx\FalagardWorldmap.h"
#include "..\CEGUIFalagardEx\FalagardSoftKeyBoard.h"
#include "tddatabase.h"
#include "AxTrace.h"
// CYS-MTSWEEP 19/09: dieu huong theo kieu THAT can den hai lop o tren nhanh Editbox cua CY.
#include <elements\CEGUIEditbox.h>
#include <elements\CEGUIMultiLineEditbox.h>
#include <cmath>
#include <limits>

// CYS-HOST2: CYS_HOST2_OFF=1 keeps the host-2 registrations out (same-binary control of the A/B measurement).
// CYS-HOST2: dau do doc bien moi truong mot lan (AddTextElement o duoi dung no lam manh moi truy vet).
static bool cysHost2Probe()
{
	static int s_probe = -1;
	if (s_probe < 0) { char text[4] = {0}; s_probe = (::GetEnvironmentVariableA("CYS_HOST2_PROBE", text, sizeof(text)) == 1 && text[0] == '1') ? 1 : 0; }
	return s_probe == 1;
}
static bool cysHost2Off()
{
	static int s_off = -1;
	if (s_off < 0) { char text[4] = {0}; s_off = (::GetEnvironmentVariableA("CYS_HOST2_OFF", text, sizeof(text)) == 1 && text[0] == '1') ? 1 : 0; }
	return s_off == 1;
}
static bool cysChatEnterOff()
{
	static const bool off = []() {
		char value[4] = {};
		return ::GetEnvironmentVariableA("CYS_CHATENTER_OFF", value, sizeof(value)) == 1 && value[0] == '1';
	}();
	return off;
}
using namespace LuaPlus;
namespace LUA_CONTROL
{

LuaPlus::LuaObject* Window::s_pMetaTable = NULL;
// CYS-HUD
LuaPlus::LuaObject* NotSuperListLuaWindow::s_pMetaTable = NULL;
LuaPlus::LuaObject* NotSuperListItemLuaWindow::s_pMetaTable = NULL;
LuaPlus::LuaObject* ListBoxEx::s_pMetaTable = NULL;
LuaPlus::LuaObject* ScrollInfo::s_pMetaTable = NULL;
LuaPlus::LuaObject* AchievementWindow::s_pMetaTable = NULL;
LuaPlus::LuaObject* EffectWindow::s_pMetaTable = NULL;
INT Window::StartFade(LuaPlus::LuaState* state)
{ return CysUiFadeBinding::startFade(state->GetCState(), *m_pWindow); }

Window*	Window::CreateControl(CEGUI::Window* pWindow)
{
	CEGUI::String strType = pWindow->getWidgetType();

	if(strType == "Falagard/ActionButton")
	{
		return new ActionButton(pWindow);
	}
	else if(strType == "Falagard/ProgressBar")
	{
		return new ProgressBar(pWindow);
	}
	else if(strType == "Falagard/PopMenu")
	{
		return new PopMenu(pWindow);
	}
	else if( strType == "Falagard/Radar" )
	{
		return new Minimap( pWindow );
	}
	else if( strType == "Falagard/ComplexWindow" )
	{
		return new ComplexWindow( pWindow );
	}
	else if( strType == "Falagard/Listbox" )
	{
		return new ListBox( pWindow );
	}
	else if ( strType == "Falagard/ImageListbox" )
	{
		return new ImageListBox( pWindow );
	}
	else if ( strType == "Falagard/ImageListboxEx" )
	{
		return new ImageListBoxEx( pWindow );
	}
	else if( strType =="Falagard/CheckBox" )
	{
		return new CheckButton( pWindow );
	}
	else if( strType == "Falagard/Combobox" )
	{
		return new ComboBox( pWindow );
	}
	else if( strType == "Falagard/StaticImage" )
	{
		return new StaticImage( pWindow );
	}
	else if( strType == "Falagard/Scrollbar" )
	{
		return new ScrollBar( pWindow );
	}
	else if( strType == "Falagard/SuperTooltip" )
	{
		return new SuperTooltip( pWindow );
	}
	else if( strType == "Falagard/MeshWindow" )
	{
		return new MeshWindow( pWindow );
	}
	else if(strType == "Falagard/ChatHistory")
	{
		return new ChatHistory(pWindow);
	}
	else if(strType == "Falagard/ChatChannel")
	{
		return new ChatChannel(pWindow);
	}
	else if( strType == "Falagard/SceneMap" )
	{
		return new Scenemap( pWindow );
	}
	else if( strType == "Falagard/WorldMap" )
	{
		return new Worldmap( pWindow );
	}
	else if( strType == "Falagard/InfoList" )
	{
		return new InfoList( pWindow );
	}
	else if( strType == "Falagard/MultiColumnList" )
	{
		return new CtrlList( pWindow );
	}
	else if( strType == "Falagard/SoftKeyWindow" )
	{
		return new SoftKeyWindow( pWindow );
	}
	else if( strType == "Falagard/Animate" || strType == "Falagard/AnimateImage" || strType == "Falagard/AnimateButton" )
	{
		return new AnimateWindow( pWindow );
	}
	// CYS-HUD
	else if( strType == "Falagard/NotSuperList" )
	{
		return new NotSuperListLuaWindow( pWindow );
	}
	else if( strType == "Falagard/NotSuperListItem" )
	{
		return new NotSuperListItemLuaWindow( pWindow );
	}
	else if( strType == "Falagard/ListBoxEx" )
	{
		return new ListBoxEx( pWindow );
	}
	else if( strType == "Falagard/ScrollInfo" || strType == "Falagard/ScrollInfoFixed" )
	{
		return new ScrollInfo( pWindow );
	}
	else if( strType == "Falagard/AchievementWindow" )
	{
		return new AchievementWindow( pWindow );
	}
	else if( strType == "Falagard/PS" )
	{
		return new EffectWindow( pWindow );
	}
	else
	{
		return new Window(pWindow);
	}
}

VOID Window::DestroyControl(Window* pThis)
{
	delete pThis;
}


VOID Window::RegisterMetaTable(VOID)
{
	LuaPlus::LuaState* pLuaState = g_pScriptSys->GetLuaState();
	TDAssert(pLuaState);

	//-----------------------------------------------------------
	//0. Window
	Window::s_pMetaTable = new LuaPlus::LuaObject;
	*Window::s_pMetaTable = pLuaState->GetGlobals().CreateTable("MetaTable_Control_Window");
	Window::s_pMetaTable->SetObject("__index", *Window::s_pMetaTable);
    Window::s_pMetaTable->RegisterObjectFunctor("StartFade", &Window::StartFade);

	Window::s_pMetaTable->RegisterObjectFunctor("SetProperty", &Window::setProperty);
	Window::s_pMetaTable->RegisterObjectFunctor("GetProperty", &Window::getProperty);
	Window::s_pMetaTable->RegisterObjectFunctor("GetType"	, &Window::getType);
	Window::s_pMetaTable->RegisterObjectFunctor("GetName"	, &Window::getName);
    Window::s_pMetaTable->RegisterObjectFunctor("GetWindowSize", &Window::GetWindowSize);
    Window::s_pMetaTable->RegisterObjectFunctor("SetXAttachPos", &Window::SetXAttachPos);
	Window::s_pMetaTable->RegisterObjectFunctor("GetText"	, &Window::getText);
	// D1/D2: CY calls these names; its generated stubs return empty / do nothing.
	// Register before LuaApiGen, which preserves real functions. All control
	// metatables currently alias this table, so the implementations check type.
	if (!cysChatEnterOff())
	{
		Window::s_pMetaTable->RegisterObjectFunctor("GetItemElementsString", &Window::GetItemElementsString);
		Window::s_pMetaTable->RegisterObjectFunctor("SetItemElementsString", &Window::SetItemElementsString);
	}
	Window::s_pMetaTable->RegisterObjectFunctor("SetText"	, &Window::setText);
	Window::s_pMetaTable->RegisterObjectFunctor("SetTextOriginal"	, &Window::setTextOriginal);
	Window::s_pMetaTable->RegisterObjectFunctor("TransText"	, &Window::TransText);
	Window::s_pMetaTable->RegisterObjectFunctor("Show"		, &Window::Show);
	Window::s_pMetaTable->RegisterObjectFunctor("Hide"		, &Window::Hide);
	Window::s_pMetaTable->RegisterObjectFunctor("Disable"	, &Window::Disable);
	Window::s_pMetaTable->RegisterObjectFunctor("Enable"	, &Window::Enable);
	Window::s_pMetaTable->RegisterObjectFunctor("IsVisible"	, &Window::IsVisible);
	Window::s_pMetaTable->RegisterObjectFunctor("SetForce"	, &Window::setForce);
	Window::s_pMetaTable->RegisterObjectFunctor("SetToolTip", &Window::SetToolTip);
	Window::s_pMetaTable->RegisterObjectFunctor("CaptureInput", &Window::CaptureInput);
	Window::s_pMetaTable->RegisterObjectFunctor("CenterWindow", &Window::CenterWindow);
	Window::s_pMetaTable->RegisterObjectFunctor("SetWindowCenter", &Window::SetWindowCenter);
	Window::s_pMetaTable->RegisterObjectFunctor("SetClippedByParent", &Window::SetClippedByParent);
    Window::s_pMetaTable->RegisterObjectFunctor("AutoMousePosition", &Window::AutoMousePosition);
	Window::s_pMetaTable->RegisterObjectFunctor("SetEvent", &Window::SetEvent); // CYS-HUD
	

	//-----------------------------------------------------------
	//1. Progress
	ProgressBar::s_pMetaTable = new LuaPlus::LuaObject;
	*ProgressBar::s_pMetaTable = pLuaState->GetGlobals().CreateTable("MetaTable_Control_ProgressBar");
	*ProgressBar::s_pMetaTable = *Window::s_pMetaTable;
	ProgressBar::s_pMetaTable->SetObject("__index", *ProgressBar::s_pMetaTable);

	ProgressBar::s_pMetaTable->RegisterObjectFunctor("SetProgress"	, &ProgressBar::SetProgress);

	//-----------------------------------------------------------
	//2. ActionButton
	ActionButton::s_pMetaTable = new LuaPlus::LuaObject;
	*ActionButton::s_pMetaTable = pLuaState->GetGlobals().CreateTable("MetaTable_Control_ActionButton");
	*ActionButton::s_pMetaTable = *Window::s_pMetaTable;
	ActionButton::s_pMetaTable->SetObject("__index", *ActionButton::s_pMetaTable);

	ActionButton::s_pMetaTable->RegisterObjectFunctor("SetActionItem"	, &ActionButton::Lua_SetActionItem);
	ActionButton::s_pMetaTable->RegisterObjectFunctor("DoAction"		, &ActionButton::Lua_DoAction);
	ActionButton::s_pMetaTable->RegisterObjectFunctor("DoSubAction"		, &ActionButton::Lua_DoSubAction);
	ActionButton::s_pMetaTable->RegisterObjectFunctor("SetPushed"		, &ActionButton::Lua_SetPushed);
	ActionButton::s_pMetaTable->RegisterObjectFunctor("SetFlash"		, &ActionButton::Lua_SetFlash);
	ActionButton::s_pMetaTable->RegisterObjectFunctor("Gloom"			, &ActionButton::Lua_Gloom);
	ActionButton::s_pMetaTable->RegisterObjectFunctor("Bright"			, &ActionButton::Lua_Bright);


	//-----------------------------------------------------------
	//3. PopMenu
	PopMenu::s_pMetaTable = new LuaPlus::LuaObject;
	*PopMenu::s_pMetaTable = pLuaState->GetGlobals().CreateTable("MetaTable_Control_PopMenu");
	*PopMenu::s_pMetaTable = *Window::s_pMetaTable;
	PopMenu::s_pMetaTable->SetObject("__index", *PopMenu::s_pMetaTable);

	PopMenu::s_pMetaTable->RegisterObjectFunctor("OpenPopMenu"	,	&PopMenu::OpenPopMenu);
	PopMenu::s_pMetaTable->RegisterObjectFunctor("ClosePopMenu"	,	&PopMenu::ClosePopMenu);
	PopMenu::s_pMetaTable->RegisterObjectFunctor("SetPopMenuPos",	&PopMenu::SetPopMenuPos);

	//-----------------------------------------------------------
	//4. ComplexWindow
	ComplexWindow::s_pMetaTable = new LuaPlus::LuaObject;
	*ComplexWindow::s_pMetaTable = pLuaState->GetGlobals().CreateTable("MetaTable_Control_ComplexWindow");
	*ComplexWindow::s_pMetaTable = *Window::s_pMetaTable;
	ComplexWindow::s_pMetaTable->SetObject("__index", *ComplexWindow::s_pMetaTable);

	ComplexWindow::s_pMetaTable->RegisterObjectFunctor("AddTextElement"	, &ComplexWindow::AddTextElement);
	ComplexWindow::s_pMetaTable->RegisterObjectFunctor("AddOptionElement"	, &ComplexWindow::AddOptionElement);
	ComplexWindow::s_pMetaTable->RegisterObjectFunctor("AddItemElement"	, &ComplexWindow::AddItemElement);
	ComplexWindow::s_pMetaTable->RegisterObjectFunctor("AddActionElement"	, &ComplexWindow::AddActionElement);
	ComplexWindow::s_pMetaTable->RegisterObjectFunctor("AddMoneyElement"	, &ComplexWindow::AddMoneyElement);
	ComplexWindow::s_pMetaTable->RegisterObjectFunctor("AddJiaoZiElement"	, &ComplexWindow::AddMoneyElement); // CYS-QUEST: CY jiaozi reward row (same money widget)
	ComplexWindow::s_pMetaTable->RegisterObjectFunctor("AddImpactElement"	, &ComplexWindow::AddImpactElement);
	ComplexWindow::s_pMetaTable->RegisterObjectFunctor("ClearAllElement"	, &ComplexWindow::CleanAllElement);
	ComplexWindow::s_pMetaTable->RegisterObjectFunctor("SetTextColour"	, &ComplexWindow::SetTextColour);
	ComplexWindow::s_pMetaTable->RegisterObjectFunctor("PageEnd"	, &ComplexWindow::PageEnd);

	//-----------------------------------------------------------
	//5.Minimap
	Minimap::s_pMetaTable = new LuaPlus::LuaObject;
	*Minimap::s_pMetaTable = pLuaState->GetGlobals().CreateTable("MetaTable_Control_Minimap");
	*Minimap::s_pMetaTable = *Window::s_pMetaTable;
	Minimap::s_pMetaTable->SetObject("__index", *Minimap::s_pMetaTable);

	Minimap::s_pMetaTable->RegisterObjectFunctor( "UpdateFlag", &Minimap::UpdateFlag);

	//-----------------------------------------------------------
	//6. ListBox
	ListBox::s_pMetaTable = new LuaPlus::LuaObject;
	*ListBox::s_pMetaTable = pLuaState->GetGlobals().CreateTable("MetaTable_Control_Listbox");
	*ListBox::s_pMetaTable = *Window::s_pMetaTable;
	ListBox::s_pMetaTable->SetObject("__index", *ListBox::s_pMetaTable);

	ListBox::s_pMetaTable->RegisterObjectFunctor( "SetItemTooltip", &ListBox::SetItemTooltip );
	ListBox::s_pMetaTable->RegisterObjectFunctor( "AddItem", &ListBox::AddItem );
	ListBox::s_pMetaTable->RegisterObjectFunctor( "SetListItemText", &ListBox::SetItemText );
	ListBox::s_pMetaTable->RegisterObjectFunctor( "GetItem", &ListBox::GetItem);
	ListBox::s_pMetaTable->RegisterObjectFunctor( "DelItem", &ListBox::DelItem);
	ListBox::s_pMetaTable->RegisterObjectFunctor( "ClearListBox", &ListBox::ClearListBox);
	ListBox::s_pMetaTable->RegisterObjectFunctor( "GetItemNumber", &ListBox::GetItemNumber);
	ListBox::s_pMetaTable->RegisterObjectFunctor( "GetFirstSelectItem", &ListBox::GetFirstSelectItem);
	ListBox::s_pMetaTable->RegisterObjectFunctor( "SetItemSelect", &ListBox::SetItemSelect);
	ListBox::s_pMetaTable->RegisterObjectFunctor( "SetItemSelectByItemID", &ListBox::SetItemSelectByItemID);
	// CYS-HOST2: CY's scroll-position pair (7 frames: Friend, QuestLog, MissionTrack, MailTarget, ...). Left out under
	// CYS_HOST2_OFF=1 so the LuaApiGen stubs stay (same-binary control of the A/B measurement).
	if (!cysHost2Off())
	{
		ListBox::s_pMetaTable->RegisterObjectFunctor( "GetCurrentFirstItem", &ListBox::GetCurrentFirstItem);
		ListBox::s_pMetaTable->RegisterObjectFunctor( "SetCurrentFirstItem", &ListBox::SetCurrentFirstItem);
	}


	//-----------------------------------------------------------
	//7. ChatWindows

	//-----------------------------------------------------------
	//8. ChatInputWindow

	//-----------------------------------------------------------
	//9. ImageListBox
	ImageListBox::s_pMetaTable = new LuaPlus::LuaObject;
	*ImageListBox::s_pMetaTable = pLuaState->GetGlobals().CreateTable("MetaTable_Control_ImageListbox");
	*ImageListBox::s_pMetaTable = *Window::s_pMetaTable;
	ImageListBox::s_pMetaTable->SetObject("__index", *ImageListBox::s_pMetaTable);

	ImageListBox::s_pMetaTable->RegisterObjectFunctor( "AddItem", &ImageListBox::AddItem );

	//-----------------------------------------------------------
	//10. ImageListBoxEx
	ImageListBoxEx::s_pMetaTable = new LuaPlus::LuaObject;
	*ImageListBoxEx::s_pMetaTable = pLuaState->GetGlobals().CreateTable("MetaTable_Control_ImageListboxEx");
	*ImageListBoxEx::s_pMetaTable = *Window::s_pMetaTable;
	ImageListBoxEx::s_pMetaTable->SetObject("__index", *ImageListBoxEx::s_pMetaTable);

	ImageListBoxEx::s_pMetaTable->RegisterObjectFunctor( "AddItem", &ImageListBoxEx::AddItem );

	//-----------------------------------------------------------
	//11. CheckBox
	CheckButton::s_pMetaTable = new LuaPlus::LuaObject;
	*CheckButton::s_pMetaTable = pLuaState->GetGlobals().CreateTable("MetaTable_Control_ImageCheckbox");
	*CheckButton::s_pMetaTable = *Window::s_pMetaTable;
	CheckButton::s_pMetaTable->SetObject("__index", *ImageListBoxEx::s_pMetaTable);

	CheckButton::s_pMetaTable->RegisterObjectFunctor( "SetCheck", &CheckButton::SetCheck );
	CheckButton::s_pMetaTable->RegisterObjectFunctor( "GetCheck", &CheckButton::GetCheck );
	CheckButton::s_pMetaTable->RegisterObjectFunctor( "FlashMe", &CheckButton::FlashMe );

	//-----------------------------------------------------------
	//12. ComboBox
	ComboBox::s_pMetaTable = new LuaPlus::LuaObject;
	*ComboBox::s_pMetaTable = pLuaState->GetGlobals().CreateTable("MetaTable_Control_ComboBox");
	*ComboBox::s_pMetaTable = *Window::s_pMetaTable;
	ComboBox::s_pMetaTable->SetObject("__index", *ComboBox::s_pMetaTable);

	ComboBox::s_pMetaTable->RegisterObjectFunctor( "ComboBoxAddItem", &ComboBox::ComboBoxAddItem);
	// CYS-PLUMB: CY renamed the same call. B's UI_CEGUI.dll registers AddTextItem on MetaTable_Control_ComboBox
	// (catalog impl_va 0x180012ee0) with the identical body - lua_isstring(2), GetString, new ListboxTextItem(text,
	// lua_tonumber(3)), selection colours, Combobox::addItem. 75 CY frames call AddTextItem, 28 call ComboBoxAddItem.
	ComboBox::s_pMetaTable->RegisterObjectFunctor( "AddTextItem", &ComboBox::ComboBoxAddItem);
	ComboBox::s_pMetaTable->RegisterObjectFunctor( "ResetList", &ComboBox::ResetList);
	ComboBox::s_pMetaTable->RegisterObjectFunctor( "GetCurrentSelect", &ComboBox::GetCurrentSelect);
	ComboBox::s_pMetaTable->RegisterObjectFunctor( "SetCurrentSelect", &ComboBox::SetCurrentSelect);
	//-----------------------------------------------------------
	//13. StaticImage
	StaticImage::s_pMetaTable = new LuaPlus::LuaObject;
	*StaticImage::s_pMetaTable = pLuaState->GetGlobals().CreateTable("MetaTable_Control_StaticImage");
	*StaticImage::s_pMetaTable = *Window::s_pMetaTable;
	StaticImage::s_pMetaTable->SetObject("__index", *StaticImage::s_pMetaTable);

	StaticImage::s_pMetaTable->RegisterObjectFunctor( "SetImage", &StaticImage::SetImage);
	StaticImage::s_pMetaTable->RegisterObjectFunctor( "SetImageColor", &StaticImage::SetImageColor);

	//-----------------------------------------------------------
	//14. ScrollBar
	ScrollBar::s_pMetaTable = new LuaPlus::LuaObject;
	*ScrollBar::s_pMetaTable = pLuaState->GetGlobals().CreateTable("MetaTable_Control_ScrollBar");
	*ScrollBar::s_pMetaTable = *Window::s_pMetaTable;
	ScrollBar::s_pMetaTable->SetObject("__index", *ScrollBar::s_pMetaTable);

	ScrollBar::s_pMetaTable->RegisterObjectFunctor( "SetPosition", &ScrollBar::SetPosition );
	ScrollBar::s_pMetaTable->RegisterObjectFunctor( "GetPosition", &ScrollBar::GetPosition );

	//-----------------------------------------------------------
	//15. SuperTooltip
	SuperTooltip::s_pMetaTable = new LuaPlus::LuaObject;
	*SuperTooltip::s_pMetaTable = pLuaState->GetGlobals().CreateTable("MetaTable_Control_SuperTooltip");
	*SuperTooltip::s_pMetaTable = *Window::s_pMetaTable;
	SuperTooltip::s_pMetaTable->SetObject("__index", *SuperTooltip::s_pMetaTable);

	SuperTooltip::s_pMetaTable->RegisterObjectFunctor( "PositionSelf", &SuperTooltip::PositionSelf );

	//-----------------------------------------------------------
	//16. MeshWindow
	MeshWindow::s_pMetaTable = new LuaPlus::LuaObject;
	*MeshWindow::s_pMetaTable = pLuaState->GetGlobals().CreateTable("MetaTable_Control_MeshWindow");
	*MeshWindow::s_pMetaTable = *Window::s_pMetaTable;
	MeshWindow::s_pMetaTable->SetObject("__index", *MeshWindow::s_pMetaTable);

	MeshWindow::s_pMetaTable->RegisterObjectFunctor("SetFakeObject", &MeshWindow::SetFakeObject );
	MeshWindow::s_pMetaTable->RegisterObjectFunctor("RotateBegin", &MeshWindow::RotateBegin );
	MeshWindow::s_pMetaTable->RegisterObjectFunctor("RotateEnd", &MeshWindow::RotateEnd );
	MeshWindow::s_pMetaTable->RegisterObjectFunctor("ChangeActionBegin", &MeshWindow::ChangeActionBegin );
	// CYS-MESHWIN 19/09: the CY *Ex API (registered by CY at UI_CEGUI.dll 0x18002bb15-0x18002bcf6, same order).
	// These eight names are registered nowhere else in the shared metatable (grep 19/09), so the shared-metatable
	// rule holds by uniqueness; every body still checks testClassName("FalagardMeshWindow") first.
	MeshWindow::s_pMetaTable->RegisterObjectFunctor("AttachWindowEx", &MeshWindow::AttachWindowEx );
	MeshWindow::s_pMetaTable->RegisterObjectFunctor("DetachWindowEx", &MeshWindow::DetachWindowEx );
	MeshWindow::s_pMetaTable->RegisterObjectFunctor("RotateBeginEx", &MeshWindow::RotateBeginEx );
	MeshWindow::s_pMetaTable->RegisterObjectFunctor("RotateEndEx", &MeshWindow::RotateEndEx );
	MeshWindow::s_pMetaTable->RegisterObjectFunctor("RestPositonEx", &MeshWindow::RestPositonEx );
	MeshWindow::s_pMetaTable->RegisterObjectFunctor("GetCameraEx", &MeshWindow::GetCameraEx );
	MeshWindow::s_pMetaTable->RegisterObjectFunctor("SetCameraEx", &MeshWindow::SetCameraEx );
	MeshWindow::s_pMetaTable->RegisterObjectFunctor("ChangeCameraDistanceEx", &MeshWindow::ChangeCameraDistanceEx );
	//-----------------------------------------------------------
	//17. ChatHistory
	ChatHistory::s_pMetaTable = new LuaPlus::LuaObject;
	*ChatHistory::s_pMetaTable = pLuaState->GetGlobals().CreateTable("MetaTable_Control_ChatHistory");
	*ChatHistory::s_pMetaTable = *Window::s_pMetaTable;
	ChatHistory::s_pMetaTable->SetObject("__index", *ChatHistory::s_pMetaTable);

	ChatHistory::s_pMetaTable->RegisterObjectFunctor("InsertChatString", &ChatHistory::InsertChatString);
	ChatHistory::s_pMetaTable->RegisterObjectFunctor("RemoveAllChatString", &ChatHistory::RemoveAllChatString);
	ChatHistory::s_pMetaTable->RegisterObjectFunctor("ScrollToEnd", &ChatHistory::ScrollToEnd);
	ChatHistory::s_pMetaTable->RegisterObjectFunctor("ExtendClearRegion", &ChatHistory::ExtendClearRegion);

	//-----------------------------------------------------------
	//18. ChatChannel
	ChatChannel::s_pMetaTable = new LuaPlus::LuaObject;
	*ChatChannel::s_pMetaTable = pLuaState->GetGlobals().CreateTable("MetaTable_Control_ChatChannel");
	*ChatChannel::s_pMetaTable = *Window::s_pMetaTable;
	ChatChannel::s_pMetaTable->SetObject("__index", *ChatChannel::s_pMetaTable);

	ChatChannel::s_pMetaTable->RegisterObjectFunctor("ClearAllChannel", &ChatChannel::ClearAllChannel);
	ChatChannel::s_pMetaTable->RegisterObjectFunctor("AddChannel", &ChatChannel::AddChannel);

	//-----------------------------------------------------------
	//19. Scenemap
	Scenemap::s_pMetaTable = new LuaPlus::LuaObject;
	*Scenemap::s_pMetaTable = pLuaState->GetGlobals().CreateTable("MetaTable_Control_SceneMapWindow");
	*Scenemap::s_pMetaTable = *Window::s_pMetaTable;
	Scenemap::s_pMetaTable->SetObject("__index", *Scenemap::s_pMetaTable);

	
	Scenemap::s_pMetaTable->RegisterObjectFunctor("SetSceneFileName", &Scenemap::SetSceneFileName );
	Scenemap::s_pMetaTable->RegisterObjectFunctor("CloseSceneMap", &Scenemap::CloseSceneMap );
	Scenemap::s_pMetaTable->RegisterObjectFunctor("GetMouseScenePos", &Scenemap::GetMouseScenePos );
	Scenemap::s_pMetaTable->RegisterObjectFunctor("UpdateSceneMap", &Scenemap::UpdateSceneMap );
	Scenemap::s_pMetaTable->RegisterObjectFunctor("SetSceneZoomMode", &Scenemap::SetSceneZoomMode );
	Scenemap::s_pMetaTable->RegisterObjectFunctor("UpdateViewRect", &Scenemap::UpdateViewRect);

	//20. Worldmap
	Worldmap::s_pMetaTable = new LuaPlus::LuaObject;
	*Worldmap::s_pMetaTable = pLuaState->GetGlobals().CreateTable("MetaTable_Control_WorldMapWindow");
	*Worldmap::s_pMetaTable = *Window::s_pMetaTable;
	Worldmap::s_pMetaTable->SetObject("__index", *Worldmap::s_pMetaTable);

	Scenemap::s_pMetaTable->RegisterObjectFunctor("InitWorldMap", &Worldmap::InitWorldMap );
	Scenemap::s_pMetaTable->RegisterObjectFunctor("GetCurrentSelectScene", &Worldmap::GetCurrentSelectScene );
	Scenemap::s_pMetaTable->RegisterObjectFunctor("UpdateWorldMap", &Worldmap::UpdateWorldMap );
	

	// 21. InfoList
	InfoList::s_pMetaTable = new LuaPlus::LuaObject;
	*InfoList::s_pMetaTable = pLuaState->GetGlobals().CreateTable("MetaTable_Control_InfoListWindow");
	*InfoList::s_pMetaTable = *Window::s_pMetaTable;
	InfoList::s_pMetaTable->SetObject("__index", *InfoList::s_pMetaTable);

	InfoList::s_pMetaTable->RegisterObjectFunctor("AddInfo", &InfoList::AddInfo );

	// 22 CtrlList
	CtrlList::s_pMetaTable = new LuaPlus::LuaObject;
	*CtrlList::s_pMetaTable = pLuaState->GetGlobals().CreateTable("MetaTable_Control_CtrlListWindow");
	*CtrlList::s_pMetaTable = *Window::s_pMetaTable;
	CtrlList::s_pMetaTable->SetObject("__index", *CtrlList::s_pMetaTable);

	CtrlList::s_pMetaTable->RegisterObjectFunctor("AddColumn", &CtrlList::AddColumn );
	CtrlList::s_pMetaTable->RegisterObjectFunctor("SetSelectItem", &CtrlList::SetSelectItem );
	CtrlList::s_pMetaTable->RegisterObjectFunctor("InsertColumn", &CtrlList::InsertColumn );
	CtrlList::s_pMetaTable->RegisterObjectFunctor("AddNewItem", &CtrlList::AddNewItem );
	CtrlList::s_pMetaTable->RegisterObjectFunctor("SetItemText", &CtrlList::SetItemText );
	CtrlList::s_pMetaTable->RegisterObjectFunctor("SetItemData", &CtrlList::SetItemData );
	CtrlList::s_pMetaTable->RegisterObjectFunctor("DeleteItem", &CtrlList::DeleteItem );
	CtrlList::s_pMetaTable->RegisterObjectFunctor("RemoveAllItem", &CtrlList::RemoveAllItem );
	CtrlList::s_pMetaTable->RegisterObjectFunctor("GetItemText", &CtrlList::GetItemText );
	CtrlList::s_pMetaTable->RegisterObjectFunctor("GetItemCount", &CtrlList::GetItemCount );
	CtrlList::s_pMetaTable->RegisterObjectFunctor("GetColumnCount", &CtrlList::GetColumnCount );
	CtrlList::s_pMetaTable->RegisterObjectFunctor("GetSelectItem", &CtrlList::GetSelectItem );

	// 23 SoftKeyWindow
	SoftKeyWindow::s_pMetaTable = new LuaPlus::LuaObject;
	*SoftKeyWindow::s_pMetaTable = pLuaState->GetGlobals().CreateTable("MetaTable_Control_SoftKeyWindow");
	*SoftKeyWindow::s_pMetaTable = *Window::s_pMetaTable;
	SoftKeyWindow::s_pMetaTable->SetObject("__index", *SoftKeyWindow::s_pMetaTable);

	SoftKeyWindow::s_pMetaTable->RegisterObjectFunctor("SetAimEditBox", &SoftKeyWindow::SetAimEditBox );

	// 24 Animate
	AnimateWindow::s_pMetaTable = new LuaPlus::LuaObject;
	*AnimateWindow::s_pMetaTable = pLuaState->GetGlobals().CreateTable("MetaTable_Control_AnimateWindow");
	*AnimateWindow::s_pMetaTable = *Window::s_pMetaTable;
	AnimateWindow::s_pMetaTable->SetObject("__index", *AnimateWindow::s_pMetaTable);

	AnimateWindow::s_pMetaTable->RegisterObjectFunctor("Play", &AnimateWindow::Play);

	//-----------------------------------------------------------
	// CYS-HUD: 25. NotSuperList
	NotSuperListLuaWindow::s_pMetaTable = new LuaPlus::LuaObject;
	*NotSuperListLuaWindow::s_pMetaTable = pLuaState->GetGlobals().CreateTable("MetaTable_Control_NotSuperList");
	*NotSuperListLuaWindow::s_pMetaTable = *Window::s_pMetaTable;
	NotSuperListLuaWindow::s_pMetaTable->SetObject("__index", *NotSuperListLuaWindow::s_pMetaTable);
	NotSuperListLuaWindow::s_pMetaTable->RegisterObjectFunctor("AddChild", &NotSuperListLuaWindow::AddChild);
	NotSuperListLuaWindow::s_pMetaTable->RegisterObjectFunctor("Clear", &NotSuperListLuaWindow::Clear);
	NotSuperListLuaWindow::s_pMetaTable->RegisterObjectFunctor("GetListItemAt", &NotSuperListLuaWindow::GetListItemAt);
	NotSuperListLuaWindow::s_pMetaTable->RegisterObjectFunctor("GetListItemCount", &NotSuperListLuaWindow::GetListItemCount);
	// CYS-MTSWEEP 19/09: dang ky nay BI NUOT - `NotSuperListItemLuaWindow::GetSelected` o muc 26 ghi de len no
	// trong CUNG mot bang metatable dung chung. GIU dong dang ky lai (no ghi dung y dinh cho tung lop, va se
	// co nghia tro lai neu sau nay tach metatable theo lop), nhung CA HAI ban nay da duoc sua de dieu huong
	// theo kieu THAT => thu tu dang ky khong con quyet dinh hanh vi nua.
	NotSuperListLuaWindow::s_pMetaTable->RegisterObjectFunctor("GetSelected", &NotSuperListLuaWindow::GetSelected);
	NotSuperListLuaWindow::s_pMetaTable->RegisterObjectFunctor("SetScrollPosition", &NotSuperListLuaWindow::SetScrollPosition);
	NotSuperListLuaWindow::s_pMetaTable->RegisterObjectFunctor("GetScrollPosition", &NotSuperListLuaWindow::GetScrollPosition);
	NotSuperListLuaWindow::s_pMetaTable->RegisterObjectFunctor("RefreshLayout", &NotSuperListLuaWindow::RefreshLayout);
	NotSuperListLuaWindow::s_pMetaTable->RegisterObjectFunctor("SetScrollPosition4Index", &NotSuperListLuaWindow::SetScrollPosition4Index);

	// 26. NotSuperListItem
	NotSuperListItemLuaWindow::s_pMetaTable = new LuaPlus::LuaObject;
	*NotSuperListItemLuaWindow::s_pMetaTable = pLuaState->GetGlobals().CreateTable("MetaTable_Control_NotSuperListItem");
	*NotSuperListItemLuaWindow::s_pMetaTable = *Window::s_pMetaTable;
	NotSuperListItemLuaWindow::s_pMetaTable->SetObject("__index", *NotSuperListItemLuaWindow::s_pMetaTable);
	NotSuperListItemLuaWindow::s_pMetaTable->RegisterObjectFunctor("GetSubItem", &NotSuperListItemLuaWindow::GetSubItem);
	NotSuperListItemLuaWindow::s_pMetaTable->RegisterObjectFunctor("SetSubItemEvent", &NotSuperListItemLuaWindow::SetSubItemEvent);
	NotSuperListItemLuaWindow::s_pMetaTable->RegisterObjectFunctor("SetSelected", &NotSuperListItemLuaWindow::SetSelected);
	NotSuperListItemLuaWindow::s_pMetaTable->RegisterObjectFunctor("GetSelected", &NotSuperListItemLuaWindow::GetSelected);

	// 27. ListBoxEx (inherits the Listbox functions)
	ListBoxEx::s_pMetaTable = new LuaPlus::LuaObject;
	*ListBoxEx::s_pMetaTable = pLuaState->GetGlobals().CreateTable("MetaTable_Control_ListBoxEx");
	*ListBoxEx::s_pMetaTable = *ListBox::s_pMetaTable;
	ListBoxEx::s_pMetaTable->SetObject("__index", *ListBoxEx::s_pMetaTable);
	ListBoxEx::s_pMetaTable->RegisterObjectFunctor("AddItemEx", &ListBoxEx::AddItemEx);
	ListBoxEx::s_pMetaTable->RegisterObjectFunctor("DelItemEx", &ListBoxEx::DelItemEx);
	ListBoxEx::s_pMetaTable->RegisterObjectFunctor("AddItemExWithoutLayout", &ListBoxEx::AddItemEx);
	ListBoxEx::s_pMetaTable->RegisterObjectFunctor("AddFriendItemExWithoutLayout", &ListBoxEx::AddFriendItemExWithoutLayout);
	ListBoxEx::s_pMetaTable->RegisterObjectFunctor("ClearListBoxEx", &ListBoxEx::ClearListBoxEx);
	ListBoxEx::s_pMetaTable->RegisterObjectFunctor("RequestLayout", &ListBoxEx::RequestLayout);
	ListBoxEx::s_pMetaTable->RegisterObjectFunctor("GetClickedButtonItem", &ListBoxEx::GetClickedButtonItem);
	ListBoxEx::s_pMetaTable->RegisterObjectFunctor("SetVScrollbarAlpha", &ListBoxEx::SetVScrollbarAlpha);
	ListBoxEx::s_pMetaTable->RegisterObjectFunctor("GetItemNumByMissionId", &ListBoxEx::GetItemNumByMissionId);

	// 28. ScrollInfo / ScrollInfoFixed
	ScrollInfo::s_pMetaTable = new LuaPlus::LuaObject;
	*ScrollInfo::s_pMetaTable = pLuaState->GetGlobals().CreateTable("MetaTable_Control_ScrollInfo");
	*ScrollInfo::s_pMetaTable = *Window::s_pMetaTable;
	ScrollInfo::s_pMetaTable->SetObject("__index", *ScrollInfo::s_pMetaTable);
	ScrollInfo::s_pMetaTable->RegisterObjectFunctor("SetScrollInfo", &ScrollInfo::SetScrollInfo);
	ScrollInfo::s_pMetaTable->RegisterObjectFunctor("SetScrollInfoFixed", &ScrollInfo::SetScrollInfo);
	ScrollInfo::s_pMetaTable->RegisterObjectFunctor("ClearInfo", &ScrollInfo::ClearInfo);

	// 29. AchievementWindow
	AchievementWindow::s_pMetaTable = new LuaPlus::LuaObject;
	*AchievementWindow::s_pMetaTable = pLuaState->GetGlobals().CreateTable("MetaTable_Control_AchievementWindow");
	*AchievementWindow::s_pMetaTable = *Window::s_pMetaTable;
	AchievementWindow::s_pMetaTable->SetObject("__index", *AchievementWindow::s_pMetaTable);
	AchievementWindow::s_pMetaTable->RegisterObjectFunctor("CleanAllElement", &AchievementWindow::CleanAllElement);
	AchievementWindow::s_pMetaTable->RegisterObjectFunctor("AddChildElement", &AchievementWindow::AddChildElement);
	AchievementWindow::s_pMetaTable->RegisterObjectFunctor("GetVertScrollbarPosition", &AchievementWindow::GetVertScrollbarPosition);
	AchievementWindow::s_pMetaTable->RegisterObjectFunctor("SetVertScrollbarPosition", &AchievementWindow::SetVertScrollbarPosition);
	AchievementWindow::s_pMetaTable->RegisterObjectFunctor("SetVertScrollbarHide", &AchievementWindow::SetVertScrollbarHide);
	AchievementWindow::s_pMetaTable->RegisterObjectFunctor("SetElementsInView", &AchievementWindow::SetElementsInView);

	// 30. Effect (Falagard/PS)
	EffectWindow::s_pMetaTable = new LuaPlus::LuaObject;
	*EffectWindow::s_pMetaTable = pLuaState->GetGlobals().CreateTable("MetaTable_Control_Effect");
	*EffectWindow::s_pMetaTable = *Window::s_pMetaTable;
	EffectWindow::s_pMetaTable->SetObject("__index", *EffectWindow::s_pMetaTable);
	EffectWindow::s_pMetaTable->RegisterObjectFunctor("playEffect", &EffectWindow::playEffect);
	EffectWindow::s_pMetaTable->RegisterObjectFunctor("replayEffect", &EffectWindow::replayEffect);

	// CYS-CYGUI2: `*X::s_pMetaTable = *Window::s_pMetaTable` above aliases every control metatable to the ONE shared
	// Window table (LuaObject is a reference), while the `CreateTable("MetaTable_Control_X")` globals stayed empty
	// orphans. LuaApiGen extends the globals by name, so its per-type stubs (Flash, AddTextItem, ...) never reached a
	// control. Point every empty MetaTable_Control_* global at the shared table.
	{
		lua_State* raw = pLuaState->GetCState();
		std::vector<std::string> orphans;
		lua_pushnil(raw);
		while (lua_next(raw, LUA_GLOBALSINDEX))
		{
			if (lua_isstring(raw, -2) && lua_istable(raw, -1))
			{
				const char* key = lua_tostring(raw, -2);
				if (std::strncmp(key, "MetaTable_Control_", 18) == 0)
				{
					lua_pushnil(raw);
					const bool empty = lua_next(raw, -2) == 0;
					if (!empty) lua_pop(raw, 2);
					if (empty) orphans.push_back(key);
				}
			}
			lua_pop(raw, 1);
		}
		for (size_t i = 0; i < orphans.size(); ++i)
			pLuaState->GetGlobals().SetObject(orphans[i].c_str(), *Window::s_pMetaTable);
	}
}

VOID Window::DestroyMetaTable(VOID)
{
	#define safe_delete_metaTable( x ) if( x ){ delete( x ); x = NULL; }
	// CYS-HUD 25-30
	safe_delete_metaTable( EffectWindow::s_pMetaTable );
	safe_delete_metaTable( AchievementWindow::s_pMetaTable );
	safe_delete_metaTable( ScrollInfo::s_pMetaTable );
	safe_delete_metaTable( ListBoxEx::s_pMetaTable );
	safe_delete_metaTable( NotSuperListItemLuaWindow::s_pMetaTable );
	safe_delete_metaTable( NotSuperListLuaWindow::s_pMetaTable );
	// 24
	safe_delete_metaTable( AnimateWindow::s_pMetaTable );
	// 23 
	safe_delete_metaTable( SoftKeyWindow::s_pMetaTable );
	// 22
	safe_delete_metaTable( CtrlList::s_pMetaTable );
	// 21
	safe_delete_metaTable( InfoList::s_pMetaTable );
	// 20
	safe_delete_metaTable( Worldmap::s_pMetaTable );
	// 19
	safe_delete_metaTable( Scenemap::s_pMetaTable );
	// 18
	safe_delete_metaTable( ChatChannel::s_pMetaTable );
	// 17
	safe_delete_metaTable( ChatHistory::s_pMetaTable );
	// 16
	safe_delete_metaTable( MeshWindow::s_pMetaTable );
	// 15
	safe_delete_metaTable( SuperTooltip::s_pMetaTable );
	// 14
	safe_delete_metaTable( ScrollBar::s_pMetaTable );
	// 13
	safe_delete_metaTable( StaticImage::s_pMetaTable );
	// 12
	safe_delete_metaTable( ComboBox::s_pMetaTable );
	// 11.
	safe_delete_metaTable( CheckButton::s_pMetaTable );
	//10.
	safe_delete_metaTable( ImageListBoxEx::s_pMetaTable );
	//9.
	safe_delete_metaTable( ImageListBox::s_pMetaTable )
	//8.
	//7.

	//6.
	safe_delete_metaTable( ListBox::s_pMetaTable );
	
	//5.
	safe_delete_metaTable( Minimap::s_pMetaTable );

	//4.
	safe_delete_metaTable( ComplexWindow::s_pMetaTable );

	//3. 
	safe_delete_metaTable( PopMenu::s_pMetaTable );
	
	//2.
	safe_delete_metaTable( ActionButton::s_pMetaTable );

	//1.
	safe_delete_metaTable( ProgressBar::s_pMetaTable );

	//0.
	safe_delete_metaTable( Window::s_pMetaTable );
}


INT Window::setProperty(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);

	if (!(args[2].IsString())) return 0;
	if (!(args[3].IsString())) return 0;

	LPCTSTR szPropertyName = args[2].GetString();
	LPCTSTR szPropertyValue = args[3].GetString();

	STRING strIconFullName,strUtf8_IconName;
	char value[ 128 ];
	sprintf( value, "%s", szPropertyName);
	if(strcmp(value, "ShortImage") == 0)
	{
		szPropertyName = "Image";
		strIconFullName = CUIIconsManager::GetMe()->GetIconFullName( args[3].GetString() );
		CUIStringSystem::mbcs_to_utf8(strIconFullName.c_str(), strUtf8_IconName);
		szPropertyValue = strUtf8_IconName.c_str();
	}
	
	STRING strValue_utf8;
	if(strcmp(value, "Text") == 0)
	{
		STRING strValue_mbcs(args[3].GetString());
		CUIStringSystem::mbcs_to_utf8(strValue_mbcs, strValue_utf8);
		szPropertyValue = strValue_utf8.c_str();
	}

	try
	{
		m_pWindow->setProperty((CEGUI::utf8*)szPropertyName, (CEGUI::utf8*)szPropertyValue);
	}
	catch(...) { }

	return 0;
}
// 将窗口居中显示，相对与父窗口
INT Window::SetXAttachPos(LuaPlus::LuaState* state)
{
    // B UI_CEGUI.dll 0x180025340..0x180025454: right if it fits, otherwise left.
    lua_State* L=state->GetCState();
    if(!m_pWindow || !lua_isnumber(L,2) || !lua_isnumber(L,3) || !lua_isnumber(L,4))return 0;
    const float anchor=(float)lua_tonumber(L,2), occupied=(float)lua_tonumber(L,3);
    const float width=m_pWindow->getAbsoluteWidth();
    const float screen=CEGUI::System::getSingleton().getRenderer()->getWidth();
    const float x=lua_tonumber(L,4)!=0 && anchor+occupied+width<=screen ? anchor+occupied : anchor-width;
    m_pWindow->setXPosition(CEGUI::Absolute,x);state->PushNumber(x);return 1;
}
INT		Window::CenterWindow( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	CEGUI::Window* pParent = m_pWindow->getParent();
	if( pParent )
	{
		CEGUI::Point pos;
		CEGUI::Rect rect = pParent->getAbsoluteRect();
		pos.d_x = ( rect.d_left + rect.d_right) / 2 - m_pWindow->getAbsoluteRect().getWidth() / 2;
		pos.d_y = ( rect.d_top + rect.d_bottom ) / 2 - m_pWindow->getAbsoluteRect().getHeight() / 2;
		m_pWindow->setPosition( CEGUI::Absolute, pos );
	}
	return 0;
}
// 将窗口居中显示，相对与父窗口
INT		Window::SetWindowCenter( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	if( !args[ 2 ].IsInteger() ) return 0;
	if( !args[ 3 ].IsInteger() ) return 0;

	CEGUI::Point pos;
	pos.d_x = args[ 2 ].GetInteger() - m_pWindow->getAbsoluteRect().getWidth() / 2;
	pos.d_y = args[ 3 ].GetInteger() - m_pWindow->getAbsoluteRect().getHeight() / 2;
	m_pWindow->setPosition( CEGUI::Absolute, pos );
	return 0;
}
//设置窗口的随父属性
INT		Window::SetClippedByParent( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	if( !args[ 2 ].IsInteger() ) return 0;
	
	INT n = args[ 2 ].GetInteger();

	if(n == 0)
	{
		m_pWindow->setClippedByParent(false);
		m_pWindow->setAlwaysOnTop(true);
	}
	else
		m_pWindow->setClippedByParent(true);

	return 0;
}
//自动设置窗口的位置
INT		Window::AutoMousePosition( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	if (!(args[2].IsString())||(!(args[3].IsString())))
	{
		return 0;
	}

	FLOAT fX = args[2].GetFloat();
	FLOAT fY = args[3].GetFloat();

	//重新计算
	FLOAT fWidth	= m_pWindow->getAbsoluteWidth();
	FLOAT fHeight	= m_pWindow->getAbsoluteHeight();

	FLOAT fScreenWidth	= CUIWindowMng::GetClientScreen()->getAbsoluteWidth();
	FLOAT fScreenHeight = CUIWindowMng::GetClientScreen()->getAbsoluteHeight();

	if(fX + fWidth + 5.0f> fScreenWidth) 
		fX -= fWidth+5.0f;
	else 
		fX += 5.0f;

	if(fY + fHeight + 5.0f > fScreenHeight) 
		fY -= fHeight+5.0f;
	else
		fY += 5.0f;

	CEGUI::Point tmpPos;
	tmpPos.d_x = fX;
	tmpPos.d_y = fY;

	((CEGUI::Window*)m_pWindow)->setPosition(CEGUI::Absolute, tmpPos);

	return 0;
}

INT Window::getProperty(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);

	if (!(args[2].IsString())) return 0;

	try
	{
		CEGUI::String strUtf32 = m_pWindow->getProperty((CEGUI::utf8*)args[2].GetString());
		
		STRING strUtf8;
		CUIStringSystem::utf8_to_mbcs(strUtf32.c_str(), strUtf8);

		pState->PushString(strUtf8.c_str());
	}
	catch(...)
	{
		pState->PushString("");
	}

	return 1;
}

INT	Window::setText(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);

	INT t = args[2].GetType();
	if( args[ 2 ].IsInteger() ) // 如果是个数字
	{
		char value[ 128 ];
		sprintf( value, "%d", args[ 2 ].GetInteger() );
		std::string strUtf8;
		CUIStringSystem::mbcs_to_utf8(value, strUtf8);

		m_pWindow->setText((CEGUI::String)(CEGUI::utf8*)(strUtf8.c_str()));
	}
	else
	if ( args[2].IsString() )
	{

		//代码转化
		std::string strMbcs = args[2].GetString();
		CEGUI::String strUtf32;
		CUIStringSystem::GetMe()->ParserString_Runtime(strMbcs, strUtf32);

		m_pWindow->setText(strUtf32);
	}

	return 0;
}

INT Window::Hide(LuaPlus::LuaState* pState)
{
	m_pWindow->setVisible(false);
	if(m_pWindow->testClassName((const CEGUI::utf8*)"Editbox"))
	{
		m_pWindow->releaseInput();
	}
	return 0;
}

INT	Window::getText(LuaPlus::LuaState* pState)
{
	std::string strUtf8 = m_pWindow->getText().c_str();//utf::mbcs_to_utf8(strMbcs);
	std::string strMbcs;
	CUIStringSystem::utf8_to_mbcs(strUtf8, strMbcs);
	pState->PushString( strMbcs.c_str() );
	return 1;
}

INT Window::GetItemElementsString(LuaPlus::LuaState* pState)
{
	// No item-element objects exist in our IME widget yet. Live clients return
	// exactly d_text in this case (D1/D6); preserve literal #R / #{...} input.
	if (!dynamic_cast<CEGUI::Editbox*>(m_pWindow) &&
		!dynamic_cast<CEGUI::MultiLineEditbox*>(m_pWindow))
	{
		pState->PushString("");
		return 1;
	}
	return getText(pState);
}

INT Window::SetItemElementsString(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);
	if (!args[2].IsString()) return 0;
	CEGUI::Editbox* edit = dynamic_cast<CEGUI::Editbox*>(m_pWindow);
	CEGUI::MultiLineEditbox* multi = dynamic_cast<CEGUI::MultiLineEditbox*>(m_pWindow);
	if (!edit && !multi) return 0;
	std::string utf8;
	CUIStringSystem::mbcs_to_utf8(args[2].GetString(), utf8);
	// Do not use ParserString_Runtime: this is editable input, not chat markup.
	CEGUI::String text(reinterpret_cast<const CEGUI::utf8*>(utf8.c_str()));
	const size_t maxLength = edit ? edit->getMaxTextLength() : multi->getMaxTextLength();
	if (text.length() > maxLength) text.erase(maxLength, text.length() - maxLength);
	m_pWindow->setText(text);
	if (edit) { edit->setSelection(0, 0); edit->setCaratIndex(text.length()); }
	else { multi->setSelection(0, 0); multi->setCaratIndex(text.length()); }
	return 0;
}
INT	Window::setTextOriginal(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);

	INT t = args[2].GetType();
	if (!(args[2].IsString())) return 0;

	//代码转化
	std::string strMbcs = args[2].GetString();
	std::string strUtf8;
	CUIStringSystem::mbcs_to_utf8(strMbcs, strUtf8);

	m_pWindow->setTextOriginal((CEGUI::String)(CEGUI::utf8*)(strUtf8.c_str()));

	return 0;
}
INT	Window::setForce( LuaPlus::LuaState* pState)
{
	m_pWindow->activate();

	return 0;
}
INT	Window::SetToolTip( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	if( !( args[ 2 ].IsString() ) ) return 0;
	std::string strMbcs = args[2].GetString();
	CEGUI::String  strLast;
	CUIStringSystem::GetMe()->ParserString_Runtime( strMbcs, strLast );

	m_pWindow->setProperty("Tooltip", strLast );
	
	return 0;
}

INT	Window::TransText(LuaPlus::LuaState* pState)
{
	CEGUI::String str = m_pWindow->getTextOriginal();
	if(!str.empty())
	{
		STRING strMBCS_ToTrans;
		CUIStringSystem::utf8_to_mbcs(str.c_str(), strMBCS_ToTrans);
		// 经过special转化的string，已经是utf32格式。
		CEGUI::String strMBCS_Transed_Done;
		
		CUIStringSystem::GetMe()->ParserString_Runtime(strMBCS_ToTrans, strMBCS_Transed_Done);

		m_pWindow->setText(strMBCS_Transed_Done);
	}
	return 0;
}

INT Window::CaptureInput( LuaPlus::LuaState* pState)
{
	m_pWindow->activate();
	m_pWindow->captureInput();
	return 0;
}

//==============================================================================
LuaPlus::LuaObject* ProgressBar::s_pMetaTable = NULL;
INT ProgressBar::SetProgress(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);
	if (!(args[2].IsNumber())) return 0;
	if (!(args[3].IsNumber())) return 0;

	FLOAT fNow = (FLOAT)args[2].GetNumber();
	FLOAT fMax = (FLOAT)args[3].GetNumber();

	((CEGUI::ProgressBar*)m_pWindow)->setProgress((FLOAT)fNow/fMax);

	return 0;
}

//==============================================================================
LuaPlus::LuaObject* ActionButton::s_pMetaTable = NULL;
INT ActionButton::Lua_SetActionItem(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);
	if (!(args[2].IsInteger())) return 0;
	
	INT idItem = (INT)args[2].GetInteger();

	Update(idItem);
	return 0;
}

INT ActionButton::Lua_DoAction(LuaPlus::LuaState* pState)
{
	if(m_pActionItem)
		m_pActionItem->DoAction();
	return 0;
}

INT ActionButton::Lua_DoSubAction(LuaPlus::LuaState* pState)
{
	if(m_pActionItem)
		m_pActionItem->DoSubAction();
	return 0;
}

INT ActionButton::Lua_SetPushed(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);
	if (!(args[2].IsInteger())) return 0;
	
	BOOL bCheck = args[2].GetInteger() == 1;

	SetCheck(bCheck);

	return 0;
}

INT	ActionButton::Lua_SetFlash(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);
	if (!(args[2].IsInteger())) return 0;
	
	BOOL bFlash = args[2].GetInteger();

	EnterFlash(bFlash);

	return 0;
}
//锁定
VOID ActionButton::Locked(VOID)
{
	m_pWindow->setProperty("Locked", "False");
	m_pWindow->requestRedraw();
}
//解除锁定
VOID ActionButton::Unlock(VOID)
{
	m_pWindow->setProperty("Locked", "False");
	m_pWindow->requestRedraw();
}

VOID ActionButton::BeDestroyed(VOID)
{
	m_pWindow->setProperty("Empty", "True");
	m_pWindow->setProperty("EquipmentDurability", "-1");
	m_pWindow->setProperty("Tooltip", (CEGUI::utf8*)"");
	((CEGUI::IFalagardActionButton*)(CEGUI::FalagardActionButton*)m_pWindow)->setLogicItemData((void*)(INT_PTR)(-1));
	((CEGUI::IFalagardActionButton*)(CEGUI::FalagardActionButton*)m_pWindow)->cleanAnimate();

	//隐藏Tooltip
	if(g_pActionSys->GetTooltipsFocus() && g_pActionSys->GetTooltipsFocus() == m_pActionItem)
	{
		AxTrace(0, 0, "***CleanSupertooltips");
		g_pEventSys->PushEvent(GE_SUPERTOOLTIP, "0");
	}

	m_pWindow->requestRedraw();
	m_pActionItem = NULL;
}

VOID ActionButton::Update(INT idItem)
{
	//取得ActionItem
	tActionItem* pActionItem = g_pActionSys->GetAction(idItem);

	//断开和原来的Action的联系
	if(m_pActionItem && pActionItem != m_pActionItem)
	{
		m_pActionItem->RemoveRefrence(this);
	}

	if(NULL == pActionItem)
	{
		//如果逻辑项为空, 清空显示
		BeDestroyed();
		return;
	}

	//设置有效无效标记
	if(pActionItem->IsEnabled())
	{
		Bright();
	}
	else
	{
		Gloom();
	}

	//设置新的Action
	((CEGUI::IFalagardActionButton*)(CEGUI::FalagardActionButton*)m_pWindow)->setLogicItemData((void*)(INT_PTR)pActionItem->GetID());

	m_pActionItem = pActionItem;
	LPCTSTR DragName = ((CEGUI::FalagardActionButton*)m_pWindow)->getDragAcceptName();

	if(DragName[0] == 'M' || DragName[0] == 'F')
	{
		pActionItem->AddReference(this,TRUE);
	}
	else
	{
		pActionItem->AddReference(this,FALSE);
	}

	const STRING strIconName = 
		CUISystem::GetMe()->GetIconManager()->GetIconFullName(m_pActionItem->GetIconName());

	m_pWindow->show();
	m_pWindow->setProperty("Empty", "False");
    if (CEGUI::PropertyHelper::stringToBool(m_pWindow->getProperty("ShowDurability")))
    {
        const STRING current=pActionItem->GetAttributeValue("dam"), maximum=pActionItem->GetAttributeValue("dam_max");
        const double maxValue=atof(maximum.c_str()), curValue=atof(current.c_str());
        const double ratio=!current.empty() && maxValue>0 && curValue>=0 ? std::min(1.0,curValue/maxValue) : -1.0;
        m_pWindow->setProperty("EquipmentDurability",CEGUI::PropertyHelper::floatToString(static_cast<float>(ratio)));
    }
	if(!strIconName.empty())
	{
		m_pWindow->setProperty("NormalImage", strIconName);
	}
}

//屏蔽
VOID	ActionButton::Disable(VOID)
{
	m_pWindow->setProperty("Disabled", "True");
	m_pWindow->requestRedraw();
}

//开启
VOID	ActionButton::Enable(VOID)
{
	m_pWindow->setProperty("Disabled", "False");
	m_pWindow->requestRedraw();
}

//变灰
VOID	ActionButton::Gloom(VOID)
{
	m_pWindow->setProperty("Gloom", "True");
	m_pWindow->requestRedraw();
}

//变亮
VOID	ActionButton::Bright(VOID)
{
	m_pWindow->setProperty("Gloom", "False");
	m_pWindow->requestRedraw();
}

INT	ActionButton::Lua_Gloom(LuaPlus::LuaState* pState)
{
	Gloom();

	return 0;
}

INT	ActionButton::Lua_Bright(LuaPlus::LuaState* pState)
{
	Bright();

	return 0;
}

VOID ActionButton::SetCheck(BOOL bCheck)
{
	m_pWindow->setProperty("Checked", bCheck ? "True" : "False");

	m_pWindow->requestRedraw();
}

//按钮设置成default的状态
VOID ActionButton::SetDefault(BOOL bDefault)
{
	m_pWindow->setProperty("Default", bDefault ? "True" : "False");

	m_pWindow->requestRedraw();
}

VOID ActionButton::SetCornerChar(CORNER_NUMBER_POS pos, LPCTSTR szChar)
{
	CHAR szTemp[MAX_PATH];
	switch(pos)
	{
	case ANP_TOPLEFT:
		{
			_snprintf(szTemp, MAX_PATH, "TopLeft %s", szChar);
			m_pWindow->setProperty("CornerChar", szTemp);
		}
		break;
	case ANP_TOPRIGHT:
		{
			_snprintf(szTemp, MAX_PATH, "TopRight %s", szChar);
			m_pWindow->setProperty("CornerChar", szTemp);
		}
		break;
	case ANP_BOTLEFT:
		{
			_snprintf(szTemp, MAX_PATH, "BotLeft %s", szChar);
			m_pWindow->setProperty("CornerChar", szTemp);
		}
		break;
	case ANP_BOTRIGHT:
		{
			_snprintf(szTemp, MAX_PATH, "BotRight %s", szChar);
			m_pWindow->setProperty("CornerChar", szTemp);
		}
		break;
	}
}

VOID ActionButton::EnterCoolDown(INT nTime, FLOAT fPercent)
{
	if(nTime <= 0)
	{
		((CEGUI::IFalagardActionButton*)(CEGUI::FalagardActionButton*)m_pWindow)->cleanAnimate();
	}
	else
	{
		((CEGUI::IFalagardActionButton*)(CEGUI::FalagardActionButton*)m_pWindow)->setAnimate(
			"CoolDown", nTime, fPercent);
	}
}

VOID ActionButton::EnterFlash(BOOL bFlash)
{
	if(bFlash)
	{
		((CEGUI::IFalagardActionButton*)(CEGUI::FalagardActionButton*)m_pWindow)->setAnimate(
			"Flash", 1000, 0.0);
	}
	else
	{
		((CEGUI::IFalagardActionButton*)(CEGUI::FalagardActionButton*)m_pWindow)->cleanAnimate();
	}
}


//==============================================================================
LuaPlus::LuaObject* PopMenu::s_pMetaTable = NULL;
INT PopMenu::OpenPopMenu(LuaPlus::LuaState* pState)
{
	((CEGUI::PopupMenu*)m_pWindow)->openPopupMenu();
	return 0;
}

INT PopMenu::ClosePopMenu(LuaPlus::LuaState* pState)
{
	((CEGUI::PopupMenu*)m_pWindow)->closePopupMenu();
	return 0;
}

// 设置位置
INT	PopMenu::SetPopMenuPos(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);
	if (!(args[2].IsString())||(!(args[3].IsString())))
	{
		return 0;
	}

	FLOAT fX = args[2].GetFloat();
	FLOAT fY = args[3].GetFloat();

	//重新计算
	FLOAT fWidth	= m_pWindow->getAbsoluteWidth();
	FLOAT fHeight	= m_pWindow->getAbsoluteHeight();

	FLOAT fScreenWidth	= CUIWindowMng::GetClientScreen()->getAbsoluteWidth();
	FLOAT fScreenHeight = CUIWindowMng::GetClientScreen()->getAbsoluteHeight();

	if(fX + fWidth > fScreenWidth) fX -= fWidth;
	if(fY + fHeight > fScreenHeight) fY -= fHeight;

	((CEGUI::PopupMenu*)m_pWindow)->setXPosition(CEGUI::Relative, fX/fScreenWidth);
	((CEGUI::PopupMenu*)m_pWindow)->setYPosition(CEGUI::Relative, fY/fScreenHeight);

	m_pWindow->requestRedraw();
	return 0;
}

//==============================================================================
LuaPlus::LuaObject* ComplexWindow::s_pMetaTable = NULL;
INT ComplexWindow::AddTextElement(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);
	if (!(args[2].IsString())) return 0;

	//文字转化
	std::string strMbcs = args[2].GetString();

//	std::string strUtf8 = utf::mbcs_to_utf8(strMbcs);

	CEGUI::String strUtf32;
	
	CEGUI::FontBase* theFont = NULL;
	//创建新的文字节
	CEGUI::IFalagardComplexWindow* pComplexWindow = (CEGUI::IFalagardComplexWindow*)(CEGUI::FalagardComplexWindow*)m_pWindow;
	if(args[3].IsString())
	{
		std::string strMbcsFont = args[3].GetString();
		CEGUI::String strUtf32Font;
		CUIStringSystem::GetMe()->ParserString_Runtime(strMbcsFont, strUtf32Font);
		
		CEGUI::FontManager* pFontManager = CEGUI::FontManager::getSingletonPtr();
		theFont = pFontManager->getFont(strUtf32Font);

	}

	INT	Typeset = 4;

	std::string strMbcsExtra1;	// = args[3].GetString();

	//马匪首领@4
	const char* strTemp = args[2].GetString();
	const char* strDelim1 = strchr(strTemp,'@');

	// CYS-HOST2 18/09: "<text>@<digit>" carries the typeset after the '@'. The original read strDelim1+2
	// unconditionally, so a string ENDING in '@' (or '@' + one last char) made assign() start one past the NUL and
	// scan arbitrary heap for the next zero byte - an out-of-bounds read that hands CEGUI a garbage String.
	// No CY mission table ships such a row today (checked all 28 Mission*/Task* tables: 0 hits), but the text also
	// comes from the server at runtime, so the guard stays. A '@' with nothing usable after it is simply not a
	// typeset marker: keep the whole string, keep the default typeset.
	if(strDelim1 && strDelim1[1] != '\0')
	{
		strMbcs.assign(strDelim1+2);
		strMbcsExtra1.assign(strDelim1+1,strDelim1+2);
		Typeset = atoi(&strMbcsExtra1.at(0));
	}

	CUIStringSystem::GetMe()->ParserString_Runtime(strMbcs, strUtf32);

	// CYS-HOST2 18/09: breadcrumb for the QuestLog process death (move-2: pressing Q ends the process at ~97 s with
	// no exception / assert / dump; review-red: Access Violation in CEGUIBase.dll reading 0xFFFFFFFF, reproducible
	// with host-2 OFF). The frame survives every AddTextElement (the last host-stub line is ResetScrollPosition,
	// QuestLog.lua:1466, after all of them), so the bad element is already in the window when it dies during layout
	// or draw. This line names the last element that went in - run with CYS_HOST2_PROBE=1 and read the tail.
	if (cysHost2Probe())
	{
		char head[96] = {0};
		std::strncpy(head, strMbcs.c_str(), sizeof(head) - 1);
		for (char* p = head; *p; ++p) { if (*p == '\r' || *p == '\n') *p = ' '; }
		char line[256] = {0};
		_snprintf(line, sizeof(line) - 1, "CYS-HOST2: AddTextElement %s bytes=%u utf32=%u typeset=%d font=%s [%s]",
			m_pWindow ? m_pWindow->getName().c_str() : "?", (unsigned)strMbcs.size(), (unsigned)strUtf32.length(),
			Typeset, theFont ? "given" : "window", head);
		CEGUI::Logger::getSingleton().logEvent((const CEGUI::utf8*)line);
	}

	// CYS-QLOG 19/09: phep cat "CYS_HOST2_NOINFO" da bi XOA o day. Gia thuyet "the #{_INFO...} lam chet khung Nhiem vu"
	// da bi LOAI bang so hoc: XSRWGZ_110917_27 dai 205 ky tu; 205 - 32 (#{_INFOUSEITEM...}) - 26 (#{_INFOAIM...})
	// - 4 (bon ma mau, moi ma 2 ky tu -> 1 utf32) = 143 = dung so "utf32=143" trong log => hai the _INFO sinh ra
	// 0 ky tu (ParserString_RuntimeNew khong co nhanh _INFO, tra tu dien truot) nen CEGUI KHONG BAO GIO nhin thay
	// chung, va bo loc cua phep cat khong bao gio khop. Nguyen nhan that: QuestLog.lua:1464 goi
	// QuestLog_Desc:SetScrollPosition() -> NotSuperListLuaWindow::SetScrollPosition ep kieu mu. Xem
	// Timeline\handoff\qlog-crash.md.
	//
	// CYS-INFOLINK 19/09: con so 143 o tren la phep do cua trang thai CU (the bi vut sach). Nhanh info-links
	// da cai nhanh _INFO vao ParserString_RuntimeNew (CysInfoLink.h), nen cung khoa do BAY GIO phai dai hon:
	//   #{_INFOUSEITEM160,93,2,38000173} -> "#aB{160,93,2,2,38000173}#u[160,93]#u#aE"  = 1+21+8+1 = 31 utf32
	//   #{_INFOAIM160,159,2,赵天师}       -> "#aB{160,159,2,0,赵天师}#u[160,159]#u#aE"  = 1+17+9+1 = 28 utf32
	//   143 + 31 + 28 = 202
	// => o kiem cua ban va: dong log nay cho XSRWGZ_110917_27 phai doc "utf32=202", khong con "utf32=143".
	// ("#u" van la 0 utf32 vi lop phong 0.85 chua co gach chan; xem Timeline\handoff\info-links.md muc 5.)
	//
	// CYS-INFOPARITY 19/09: "#u" KHONG con la 0 utf32. Nhanh info-parity cai gach chan nhu CY: moi "#u" phat mot
	// ma 0xE6000000 (bat) / 0xE7000000 (tat) (CY UI_CEGUI.dll 0x18004bc63/0x18004bc6b), lop phong CEGUIBase.dll ve
	// gach chan. Moi the _INFO co hai "#u" => +2 utf32 moi the:
	//   202 + 2 (_INFOUSEITEM) + 2 (_INFOAIM) = 206
	// => o kiem MOI: dong log nay cho XSRWGZ_110917_27 phai doc "utf32=206". (Dong co the _INFOMAP con them 2 ma
	// 0xE8 mau lien ket nua; XSRWGZ_110917_27 khong co _INFOMAP.) Xem Timeline\handoff\info-parity.md.

	pComplexWindow->AddChildElement_Text(strUtf32,theFont,(CEGUI::TextFormatting)Typeset);


	return 0;
}

INT ComplexWindow::AddOptionElement(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);
	if (!(args[2].IsString())) return 0;

	//文字转化
	std::string strMbcs;// = args[2].GetString();
	std::string strMbcsExtra1;// = args[3].GetString();
	std::string strMbcsExtra2;// = args[4].GetString();
	std::string strMbcsExtra3;// = args[5].GetString();
	//马匪首领#21107,-1$-1
	const char* strTemp = args[2].GetString();
	const char* strDelim1 = strchr(strTemp,'#');
	const char* strDelim2 = strchr(strTemp,',');
	const char* strDelim3 = strchr(strTemp,'$');
	// CYS-QUEST: CY Quest.lua (Quest_EventListUpdate) builds "text&script,index$icon"; the text itself carries #G/#{..}
	// colour and dictionary codes (and commas), so the three delimiters are searched from the end.
	{
		const char* cyIcon = strrchr(strTemp, '$');
		const char* cyComma = nullptr;
		const char* cyAmp = nullptr;
		if (cyIcon) for (const char* c = cyIcon; c > strTemp; --c) if (c[-1] == ',') { cyComma = c - 1; break; }
		if (cyComma) for (const char* c = cyComma; c > strTemp; --c) if (c[-1] == '&') { cyAmp = c - 1; break; }
		if (cyAmp)
		{
			strDelim1 = cyAmp; strDelim2 = cyComma; strDelim3 = cyIcon;
		}
	}

	if( (strDelim1 && (!strDelim2 || !strDelim3) ) ||
		(strDelim2 && (!strDelim1 || !strDelim3) ) ||
		(strDelim3 && (!strDelim1 || !strDelim2) ) )
	{
		// CYS-QUEST: a plain option text with a colour code (#G...) is not an error: show it without extras
		strDelim1 = strDelim2 = strDelim3 = nullptr;
	}

	if(strDelim1 && strDelim2 && strDelim3)
	{
		strMbcs.assign(strTemp,strDelim1-strTemp);
		strMbcsExtra1.assign(strDelim1+1,strDelim2-1-strDelim1);
		strMbcsExtra2.assign(strDelim2+1,strDelim3-1-strDelim2);
		strMbcsExtra3.assign(strDelim3+1);
	}
	else
	{
		strMbcs.assign(strTemp);
		strMbcsExtra1.assign("-1");
		strMbcsExtra2.assign("-1");
		strMbcsExtra3.assign("-1");
	}

	CEGUI::String strUtf32;
	CUIStringSystem::GetMe()->ParserString_Runtime(strMbcs, strUtf32);

	CEGUI::String strExtra1;
	CUIStringSystem::GetMe()->ParserString_Runtime(strMbcsExtra1, strExtra1);
	
	CEGUI::String strExtra2;
	CUIStringSystem::GetMe()->ParserString_Runtime(strMbcsExtra2, strExtra2);

	CEGUI::String strExtra3;
	CUIStringSystem::GetMe()->ParserString_Runtime(strMbcsExtra3, strExtra3);

	//创建新的选项节
	CEGUI::IFalagardComplexWindow* pComplexWindow = (CEGUI::IFalagardComplexWindow*)(CEGUI::FalagardComplexWindow*)m_pWindow;
	pComplexWindow->AddChildElement_Option(strUtf32,strExtra1,strExtra2,strExtra3);

	return 0;
}
INT PushWindowControl( LuaPlus::LuaState* pState, CEGUI::Window* pWindow );

INT ComplexWindow::AddItemElement(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);
	// CYS-CYGUI2: every control shares one metatable (see RegisterMetaTable), so a CY AchievementWindow list calling
	// AddItemElement("SelectServerCatalog", "LEFT", ...) lands here. CY semantics: create the ChildItem of that key
	// and return its control (SelectServer.lua 2240). Item elements of a ComplexWindow take integers.
	if (args[2].IsString() && !args[2].IsNumber())
	{
		if (CEGUI::FalagardAchievementWindow* list = dynamic_cast<CEGUI::FalagardAchievementWindow*>(m_pWindow))
			return PushWindowControl(pState, list->AddChildElement((CEGUI::utf8*)args[2].GetString()));
		return 0;
	}
	if (!(args[2].IsInteger())) return 0;
	if (!(args[3].IsInteger())) return 0;
	if (!(args[4].IsInteger())) return 0;

	INT  idItem	= args[2].GetInteger();
	INT	 nNum	= args[3].GetInteger();
	BOOL bRadio		= (args[4].GetInteger() == 1);
	BOOL bReArrange = FALSE;
	if(args[5].IsInteger())
		bReArrange = (args[5].GetInteger() == 1);

	tObject_Item* pItem = g_pObjectSystem->FindItem(idItem);

	STRING strIconFullName = CUIIconsManager::GetMe()->GetIconFullName(pItem->GetIconName());
	STRING strUtf8_IconName;
	CUIStringSystem::mbcs_to_utf8(strIconFullName.c_str(), strUtf8_IconName);

	STRING strUtf8_Desc;
	CUIStringSystem::mbcs_to_utf8(pItem->GetName(), strUtf8_Desc);

	CEGUI::IFalagardComplexWindow* pComplexWindow = (CEGUI::IFalagardComplexWindow*)(CEGUI::FalagardComplexWindow*)m_pWindow;
	pComplexWindow->AddChildElement_Item( (CEGUI::String)(CEGUI::utf8*)(strUtf8_IconName.c_str()), (CEGUI::String)(CEGUI::utf8*)(strUtf8_Desc.c_str()), bRadio==TRUE, bReArrange==TRUE);
//	pComplexWindow->AddChildElement_Item( idItem, (CEGUI::String)(CEGUI::utf8*)(strUtf8_Desc.c_str()), bRadio==TRUE, bReArrange==TRUE);


	return 0;
}

INT ComplexWindow::AddActionElement(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);
	if (!(args[2].IsInteger())) return 0;
	if (!(args[3].IsInteger())) return 0;
	if (!(args[4].IsInteger())) return 0;

	INT  idItem	= args[2].GetInteger();
	INT	 nNum	= args[3].GetInteger();
	BOOL bRadio		= (args[4].GetInteger() == 1);
	BOOL bReArrange = FALSE;
	if(args[5].IsInteger())
		bReArrange = (args[5].GetInteger() == 1);

	tActionItem* pActionItem = g_pActionSys->GetAction(idItem);

	if(NULL == pActionItem)
		return 0;

	const STRING strIconFullName =
		CUISystem::GetMe()->GetIconManager()->GetIconFullName(pActionItem->GetIconName());

	// CYS-HOST2 18/09: breadcrumb for the QuestLog process death. The last element that goes in before the crash is
	// the rewards header, so the reward items added right after it are the suspects. CUIIconsManager::GetIconFullName
	// answers the LITERAL "set:X image:X" when the icon name is unknown (UIIconsMng.cpp:54); CEGUI resolves that to a
	// NULL Image (PropertyHelper::stringToImage returns 0 when the imageset is absent), and a reward button drawn
	// with a NULL image is exactly the kind of read that ends the process with no Lua error.
	if (cysHost2Probe())
	{
		char line[256] = {0};
		_snprintf(line, sizeof(line) - 1, "CYS-HOST2: AddActionElement %s id=%d num=%d radio=%d icon=\"%s\" full=\"%s\"%s",
			m_pWindow ? m_pWindow->getName().c_str() : "?", idItem, nNum, bRadio ? 1 : 0,
			pActionItem->GetIconName() ? pActionItem->GetIconName() : "(null)", strIconFullName.c_str(),
			strIconFullName == "set:X image:X" ? "   <<< ICON KHONG CO - anh NULL" : "");
		CEGUI::Logger::getSingleton().logEvent((const CEGUI::utf8*)line);
	}

	STRING strUtf8_IconName;
	CUIStringSystem::mbcs_to_utf8(strIconFullName.c_str(), strUtf8_IconName);

	CEGUI::IFalagardComplexWindow* pComplexWindow = (CEGUI::IFalagardComplexWindow*)(CEGUI::FalagardComplexWindow*)m_pWindow;
	CEGUI::IFalagardActionButton* pActionButton = (CEGUI::IFalagardActionButton*)(CEGUI::FalagardActionButton*)pComplexWindow->AddChildElement_Action( strUtf8_IconName, idItem, bRadio==TRUE, bReArrange==TRUE);

	if(pActionItem->GetDefineID() != 20005020)//随机奖励物品不显示supertooltip
	{
	//MouseEnter
		pActionButton->subscribeMouseEnterEvent(CEGUI::Event::Subscriber(&CUISystem::handleActionButtonMouseEnter, CUISystem::GetMe()));
	//MouseLeave
		pActionButton->subscribeMouseLeaveEvent(CEGUI::Event::Subscriber(&CUISystem::handleActionButtonMouseLeave, CUISystem::GetMe()));
	//ParentHidden
		((CEGUI::Window*)(CEGUI::FalagardActionButton*)pActionButton)->
			subscribeEvent((CEGUI::utf8*)"ParentHidden", CEGUI::Event::Subscriber(&CUISystem::handleActionButtonParentHidden, CUISystem::GetMe()));
	}
	return 0;
}

//struct SBuffImpact;
INT ComplexWindow::AddImpactElement(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);
	if (!(args[2].IsString())) return 0;
//	if (!(args[3].IsInteger())) return 0;
//	if (!(args[4].IsInteger())) return 0;

//	args[2].GetString()  idImpact	= args[2].GetString();
//	INT		nNum	= args[3].GetInteger();
//	BOOL bRadio		= (args[4].GetInteger() == 1);

//	tObject_Item* pItem = g_pObjectSystem->FindItem(idItem);
	//SBuffImpact *pBuffImpact = GetBuffImpactMgr()->GetBuffImpact( idImpact );

	STRING strIconFullName = CUIIconsManager::GetMe()->GetIconFullName( args[2].GetString() );
	STRING strUtf8_IconName;
	CUIStringSystem::mbcs_to_utf8(strIconFullName, strUtf8_IconName);

	STRING strUtf8_Desc;
	CUIStringSystem::mbcs_to_utf8("", strUtf8_Desc);

	CEGUI::IFalagardComplexWindow* pComplexWindow = (CEGUI::IFalagardComplexWindow*)(CEGUI::FalagardComplexWindow*)m_pWindow;
//	pComplexWindow->AddChildElement_Item( (CEGUI::String)(CEGUI::utf8*)(strUtf8_IconName.c_str()), (CEGUI::String)(CEGUI::utf8*)(strUtf8_Desc.c_str()), bRadio);
	//	改了使用方法
	//	pComplexWindow->AddChildElement_Item( (CEGUI::String)(CEGUI::utf8*)(strUtf8_IconName.c_str()),(CEGUI::String)(CEGUI::utf8*)(strUtf8_Desc.c_str()),0,0);
	return 0;
}

INT ComplexWindow::AddMoneyElement(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);
	if (!(args[2].IsString())) return 0;

	CEGUI::IFalagardComplexWindow* pComplexWindow = (CEGUI::IFalagardComplexWindow*)(CEGUI::FalagardComplexWindow*)m_pWindow;

	pComplexWindow->AddChildElement_Money(atoi(args[2].GetString()));

	return 0;
}

INT ComplexWindow::CleanAllElement(LuaPlus::LuaState* pState)
{
	CEGUI::IFalagardComplexWindow* pComplexWindow = (CEGUI::IFalagardComplexWindow*)(CEGUI::FalagardComplexWindow*)m_pWindow;

	pComplexWindow->ClearAllElement();

	return 0;
}

//更改字体的颜色
INT ComplexWindow::SetTextColour(LuaPlus::LuaState* pState)
{
	return 0;
}
INT ComplexWindow::PageEnd(LuaPlus::LuaState* pState)
{
	CEGUI::IFalagardComplexWindow* pComplexWindow = (CEGUI::IFalagardComplexWindow*)(CEGUI::FalagardComplexWindow*)m_pWindow;
	pComplexWindow->PageEnd();
	return 0;
}

//==============================================================================
LuaPlus::LuaObject* Minimap::s_pMetaTable = NULL;

LPCTSTR FLAG_CLASS_NAME[] = {"Animate","ExpNPC","Teamate","OtherPlayer","ExpObj",};
INT Minimap::UpdateFlag( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	
	// CYS-CYGUI2: the CY 3.71 minimap (MiniMap_MapArea) is a Falagard/SceneMap, not the 0.85 Radar, and every control
	// shares this metatable; casting it to FalagardRadar gave a wrong interface pointer (the view never followed the
	// player: black round minimap, replay-12). Pick the interface by the real class; a scene map also re-centres on
	// the player as Scenemap::UpdateViewRect does.
	CEGUI::FalagardSceneMap* pSceneMap = dynamic_cast<CEGUI::FalagardSceneMap*>(m_pWindow);
	CEGUI::IFalagardSceneMapWindow* pWindow = pSceneMap ? (CEGUI::IFalagardSceneMapWindow*)pSceneMap
		: (CEGUI::IFalagardSceneMapWindow*)(CEGUI::FalagardRadar*)m_pWindow;
	fVector3 MyselfPos = g_pWorldSystem->GetMyselfPos();
	int		 nDir = g_pWorldSystem->GetMyselfDir( );
	pWindow->setMyselfPos( CEGUI::Point( MyselfPos.x, MyselfPos.z ) );
	pWindow->setMyselfDir( nDir );
	if (args[2].IsNumber())
		pWindow->setMAXJuLi(args[2].GetFloat());
	if (pSceneMap)
		pWindow->setSceneMapCenter();
	if( m_pWindow->isVisible() )
	{
		// 跟新所有的标志位置
		pWindow->Clear();

		for( INT i = 0; i < 9; i ++ )
		{
			std::list< MAP_POS_DEFINE >* listObj = g_pWorldSystem->GetObjectListByClass( i );
			// 得到了当前类型所有的物体的链表
			std::list< MAP_POS_DEFINE >::iterator it;
			for( it = listObj->begin(); it != listObj->end(); it ++ )
			{
				std::string strUtf8;
				std::string strMbcs = (*it).name;
				CUIStringSystem::mbcs_to_utf8(strMbcs, strUtf8 );
				if( i == 2 ) // 如果是队友，需要单独处理
					if( (*it).dwSceneID != g_pWorldSystem->GetActiveSceneID() ) // 在同一场景才会添加
						continue;
				pWindow->setMinimapData( i, (*it).pos.x, (*it).pos.z,  (CEGUI::String)(CEGUI::utf8*)strUtf8.c_str() );
			}
		}
	}
	return 0;
}
//==============================================================================
// ListBox
LuaPlus::LuaObject* ListBox::s_pMetaTable = NULL;

// CYS-MTSWEEP 19/09 - CUNG LOP LOI voi `SetScrollPosition` cua `qlog-crash`, KHAC trieu chung: khong chet,
// chi IM LANG khong lam gi.
// `AddItem` la ten Lua duy nhat trong ca bang bi dang ky BA lan (`ListBox`, `ImageListBox`, `ImageListBoxEx`).
// Vi moi dieu khien dung CHUNG mot metatable (`RegisterMetaTable`), ban dang ky SAU nuot ban truoc, nen ban
// `ImageListBoxEx` thang cho MOI cua so. Ban do doi (chuoi, so nguyen, so nguyen) roi dat THUOC TINH "AddItem" -
// thuoc tinh ma chi `Falagard/ImageListbox` va `Falagard/ImageListboxEx` dinh nghia
// (`FalImageListProperties.h:117`, `FalImageListExProperties.h:64`).
// Do thuc te tren 2.043 tep Lua + 2.032 layout: 124 loi goi `:AddItem(` nam tren `Falagard/Listbox` va 35 tren
// `Falagard/ListBoxEx`; tat ca deu truyen 2 hoac 4 doi so kieu khac (`GemList_List:AddItem(text, 1)`,
// `Friend_List:AddItem(text, id, "FFFFFFFF", 4)`) => thoat som o `args[4].IsInteger()` => KHONG them gi ca.
// Nguoi choi chi thay danh sach ban be / ngoc / tran thu / to doi TRONG.
// Cach sua: mot bo dieu huong theo kieu THAT, dung chung cho ca ba ban dang ky, nen thu tu dang ky khong con
// quyet dinh hanh vi nua. Thu tu kiem bat buoc di tu rieng den chung: ca ba lop deu ke thua `FalagardListbox`.
namespace
{
	// Nghia cua `Falagard/Listbox` va `Falagard/ListBoxEx`: (chuoi, chi so, [mau], [dinh dang]).
	INT cysAddItem_Listbox( CEGUI::Listbox* pList, LuaPlus::LuaState* pState )
	{
		LuaStack args(pState);
		if (!(args[2].IsString()))
			return 0;
		if (!(args[3].IsInteger()))
			return 0;

		//Text
		std::string strMbcs = args[2].GetString();
		std::string strUtf8;
		CUIStringSystem::mbcs_to_utf8(strMbcs, strUtf8);

		//TextIndex
		INT nIndex = args[3].GetInteger();

		//TextColor
		CEGUI::colour colorText = CEGUI::colour(1.0f, 1.0f, 1.0f);
		if(args[4].IsString())
		{
			colorText = CEGUI::PropertyHelper::stringToColour((CEGUI::utf8*)args[4].GetString());
		}
		CEGUI::String strUtf32;
		CUIStringSystem::GetMe()->ParserString_Runtime(strMbcs, strUtf32);

		CEGUI::ListboxTextItem* pItem = new CEGUI::ListboxTextItem( strUtf32,  nIndex);
		pItem->setTextColours(colorText);
		pItem->setSelectionColours(CEGUI::colour(0xFFC8B88E));
		// CYS: Listbox/Combobox apply SelectBrush and SelectColour from the current look.
		if( args[ 5 ].IsInteger() )
			pItem->setHorzFomate( CEGUI::TextFormatting( args[ 5 ].GetInteger() ) );
		pList->addItem( pItem );
		return 0;
	}

	// Nghia cua `Falagard/ImageListbox`: dat thuoc tinh "AddItem" dang `id=<n> text=<s>`.
	INT cysAddItem_ImageList( CEGUI::Window* pWindow, LuaPlus::LuaState* pState )
	{
		LuaStack args(pState);
		if (!(args[2].IsString()))
			return 0;
		char value[ 128 ];
		sprintf( value, "id=%d text=%s", args[ 3 ].IsInteger() ? args[ 3 ].GetInteger() : 0, args[2].GetString() );
		pWindow->setProperty( "AddItem", value );
		return 0;
	}

	// Nghia cua `Falagard/ImageListboxEx`: dat thuoc tinh "AddItem" dang `id=<n> state=<n> text=<s>`.
	INT cysAddItem_ImageListEx( CEGUI::Window* pWindow, LuaPlus::LuaState* pState )
	{
		LuaStack args(pState);
		if (!(args[2].IsString()))
			return 0;
		if( !( args[ 3 ].IsInteger() ) )
			return 0;
		if( !( args[ 4 ].IsInteger() ) )
			return 0;

		CEGUI::String strText;
		char value[ 128 ];

		sprintf( value, "id=%d state=%d text=%s", args[ 3 ].GetInteger(), args[ 4 ].GetInteger(), args[2].GetString() );
		std::string strMbcs = value;
		std::string strUtf8;
		CUIStringSystem::mbcs_to_utf8(strMbcs, strUtf8);
		pWindow->setProperty( "AddItem", (CEGUI::String)(CEGUI::utf8*)(strUtf8.c_str()) );
		return 0;
	}

	INT cysAddItemDispatch( CEGUI::Window* pWindow, LuaPlus::LuaState* pState )
	{
		if (dynamic_cast<CEGUI::FalagardImageListBoxEx*>(pWindow))
			return cysAddItem_ImageListEx(pWindow, pState);
		if (dynamic_cast<CEGUI::FalagardImageListBox*>(pWindow))
			return cysAddItem_ImageList(pWindow, pState);
		if (CEGUI::Listbox* pList = dynamic_cast<CEGUI::Listbox*>(pWindow))
			return cysAddItem_Listbox(pList, pState);
		return 0;
	}
}

// Ca ba ban dang ky deu di vao cung bo dieu huong => thu tu dang ky khong con quyet dinh hanh vi.
INT ListBox::AddItem( LuaPlus::LuaState* pState )
{
	return cysAddItemDispatch(m_pWindow, pState);
}
// CYS-MTSWEEP 19/09: `TeamPT.lua:267` goi dang BA doi so cua CY `SetItemTooltip(cot, hang, chu)` tren
// `TeamPT_List` = `TLBB_MultiColumnListNoScroll` -> `Falagard/MultiColumnList`. Ban dang ky duy nhat la ban
// Listbox => `setItemTooltipsEnabled` GHI `d_itemTooltips` o offset cua Listbox tren mot MultiColumnList,
// roi `getListboxItemFromIndex` doc `d_listItems` cung o offset do.
// HOM NAY no chua no vi `args[3].IsString()` sai (`iRow` la so) nen ham thoat som - tuc tinh nang tooltip cua
// khung TO DOI dang CHET IM. Sua: phan phoi theo kieu THAT + nhan ca hai dang doi so.
// `Listbox::getListboxItemFromIndex` NEM `InvalidRequestException` khi chi so vuot bien (CEGUIListbox.cpp:205)
// va ban cu con thieu ca phep kiem NULL - hai loi nho di kem, sua luon.
INT ListBox::SetItemTooltip( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	if (!(args[2].IsInteger()))
		return 0;

	if (CEGUI::Listbox* pList = dynamic_cast<CEGUI::Listbox*>(m_pWindow))
	{
		if( !( args[ 3 ].IsString() ) ) return 0;
		const INT index = args[ 2 ].GetInteger();
		if (index < 0 || (size_t)index >= pList->getItemCount()) return 0;
		pList->setItemTooltipsEnabled( true );
		if (CEGUI::ListboxItem* pItem = pList->getListboxItemFromIndex( (size_t)index ))
			pItem->setTooltipText( args[ 3 ].GetString() );
		return 0;
	}
	if (CEGUI::MultiColumnList* pGrid = dynamic_cast<CEGUI::MultiColumnList*>(m_pWindow))
	{
		// CY: (cot, hang, chu). CEGUI 0.4.1 MultiColumnList khong co tooltip theo o, nhung `ListboxItem` thi co,
		// nen dat chu vao muc la dung cho va khong the chet; phan VE tooltip cho MCL la viec parity rieng.
		if( !( args[ 4 ].IsString() ) ) return 0;
		if( !( args[ 3 ].IsNumber() ) ) return 0;
		CEGUI::MCLGridRef grid_ref( (unsigned int)(INT)args[3].GetNumber(), (unsigned int)args[2].GetInteger() );
		if (grid_ref.row >= pGrid->getRowCount() || grid_ref.column >= pGrid->getColumnCount()) return 0;
		if (CEGUI::ListboxItem* pItem = pGrid->getItemAtGridReference( grid_ref ))
			pItem->setTooltipText( args[ 4 ].GetString() );
		return 0;
	}
	return 0;
}
INT ListBox::SetItemText( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	if (!(args[2].IsInteger())) 
		return 0;
	if( !( args[ 3 ].IsString() ) )
		return 0;
	CEGUI::ListboxItem* pItem = ((CEGUI::Listbox*)m_pWindow)->getListboxItemFromIndex( args[ 2 ].GetInteger() );
	std::string strMbcs = args[3].GetString();
	CEGUI::String strUtf32;
	CUIStringSystem::GetMe()->ParserString_Runtime(strMbcs, strUtf32);
	pItem->setText( strUtf32 );
	((CEGUI::Listbox*)m_pWindow)->requestRedraw();
	return 0;
}
INT ListBox::DelItem( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	if (!(args[2].IsInteger())) 
		return 0;
	CEGUI::ListboxItem* pItem = ((CEGUI::Listbox*)m_pWindow)->getListboxItemFromIndex( args[ 2 ].GetInteger() );
	((CEGUI::Listbox*)m_pWindow)->removeItem( pItem );
	return 0;
}

INT ListBox::GetItem( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	if (!(args[2].IsInteger())) 
		return 0;
	if( args[ 2 ].GetInteger() < 0 )
		return 0;
	CEGUI::ListboxItem* pItem = ((CEGUI::Listbox*)m_pWindow)->getListboxItemFromIndex( args[ 2 ].GetInteger() - 1 );
	std::string strMbcs;
	CUIStringSystem::utf8_to_mbcs(pItem->getText().c_str(), strMbcs);
	pState->PushString( strMbcs.c_str() );
	pState->PushInteger( pItem->getID() );
	return 2;
}

INT ListBox::ClearListBox( LuaPlus::LuaState* pState )
{
	((CEGUI::Listbox*)m_pWindow)->resetList();
	return 0;
}

INT	ListBox::GetFirstSelectItem( LuaPlus::LuaState* pState )
{
	CEGUI::ListboxTextItem* pItem = (CEGUI::ListboxTextItem*)((CEGUI::Listbox*)m_pWindow)->getFirstSelectedItem();
	if(!pItem) 
		pState->PushInteger(-1);
	else
		pState->PushInteger(pItem->getID());

	return 1;
}

INT	ListBox::SetItemSelect( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	if (!(args[2].IsInteger())) 
		return 0;
	
	INT nItemIndex = args[2].GetInteger();

	((CEGUI::Listbox*)m_pWindow)->setItemSelectState(nItemIndex, true);
	return 0;
}

INT	ListBox::SetItemSelectByItemID( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	if (!(args[2].IsInteger())) 
		return 0;
	
	INT nItemID = args[2].GetInteger();

	((CEGUI::Listbox*)m_pWindow)->setItemSelectStateByItemID(nItemID, true);
	return 0;
}

//==============================================================================
// ImageListBox
LuaPlus::LuaObject* ImageListBox::s_pMetaTable = NULL;
INT ImageListBox::AddItem( LuaPlus::LuaState* pState )
{
	return cysAddItemDispatch(m_pWindow, pState);   // CYS-MTSWEEP: xem bo dieu huong o tren
}
//==============================================================================
// ImageListBoxEx
LuaPlus::LuaObject* ImageListBoxEx::s_pMetaTable = NULL;
// CYS-MTSWEEP 19/09: day la ban DANG KY THANG cua ten `AddItem` (dang ky cuoi cung trong `RegisterMetaTable`),
// tuc moi cua so trong game deu roi vao day. Nay no di vao cung bo dieu huong voi hai ban kia.
INT ImageListBoxEx::AddItem( LuaPlus::LuaState* pState )
{
	return cysAddItemDispatch(m_pWindow, pState);
}
//==============================================================================
//CheckButton
LuaPlus::LuaObject* CheckButton::s_pMetaTable = NULL;
INT CheckButton::FlashMe(LuaPlus::LuaState* state)
{
    return CysFlashBinding::flashMe(state->GetCState(), *m_pWindow);
}
INT CheckButton::SetCheck( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	if( !args[ 2 ].IsInteger() ) return 0;
	
	if( args[ 2 ].GetInteger() == 1 )

		m_pWindow->setProperty( "Selected", "True" );
	else
		m_pWindow->setProperty( "Selected", "False" );

	return 0;
}
INT CheckButton::GetCheck( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	if(CEGUI::PropertyHelper::stringToBool(  m_pWindow->getProperty( "Selected" ) ))
		pState->PushInteger(TRUE);
	else
		pState->PushInteger(FALSE);

//	pState->PushBoolean( CEGUI::PropertyHelper::stringToBool(  m_pWindow->getProperty( "Selected" ) ) );
	return 1;
}

// CYS-HOST2: the CY scroll-position pair of MetaTable_Control_Listbox.
//   GetCurrentFirstItem  B UI_CEGUI.dll 0x180015830: item = Listbox::getFirstVisibleItem(); push(item ? getItemIndex(item) : -1.0)
//   SetCurrentFirstItem  B UI_CEGUI.dll 0x180021b00: Listbox::setFirstVisibleItem((size_t)(int)lua_tonumber(2))
// Both Listbox members exist only in client_GL's CEGUIBase.dll (exports, RVA 0xE4FA0 / 0xE6600; listings in
// Build/Logs/2026-09-17-host-2/re/CEGUIBase_*.txt); CEGUI 0.4.1 in this tree has neither, so they are rebuilt here
// from those listings over the public Listbox API (B's Rect is laid out top/bottom/left/right - read from
// Rect::isPointInRect - which is what makes the three listings consistent):
//   getFirstVisibleItem: y = renderArea.top - vertScrollbar.position; for each item: y += item height; the first
//                        item whose bottom edge passes renderArea.top is it. No scrollbar -> item 0.
//   setFirstVisibleItem: index >= count -> nothing. before = sum of heights below index, total = sum of all;
//                        total == areaHeight -> nothing; if (areaHeight > total - before) before = total - areaHeight;
//                        vertScrollbar.setScrollPosition(before).
// The vertical scrollbar is the child CEGUIListbox.cpp:116 creates under "<name>__auto_vscrollbar__".
namespace
{
	CEGUI::Scrollbar* cysListVertScrollbar(CEGUI::Listbox* pList)
	{
		const CEGUI::String name = pList->getName() + (const CEGUI::utf8*)"__auto_vscrollbar__";
		CEGUI::WindowManager& wm = CEGUI::WindowManager::getSingleton();
		return wm.isWindowPresent(name) ? static_cast<CEGUI::Scrollbar*>(wm.getWindow(name)) : NULL;
	}

	CEGUI::ListboxItem* cysFirstVisibleItem(CEGUI::Listbox* pList)
	{
		const size_t count = pList->getItemCount();
		if (count == 0) return NULL;
		CEGUI::Scrollbar* pBar = cysListVertScrollbar(pList);
		if (!pBar) return pList->getListboxItemFromIndex(0);   // B starts y at renderArea.bottom here: item 0 wins at once
		const CEGUI::Rect area = pList->getListRenderArea();
		float y = area.d_top - pBar->getScrollPosition();
		for (size_t i = 0; i < count; ++i)
		{
			CEGUI::ListboxItem* pItem = pList->getListboxItemFromIndex(i);
			y += pItem->getPixelSize(pList).d_height;
			if (y > area.d_top) return pItem;
		}
		return NULL;
	}

	void cysSetFirstVisibleItem(CEGUI::Listbox* pList, size_t index)
	{
		const size_t count = pList->getItemCount();
		if (index >= count) return;
		CEGUI::Scrollbar* pBar = cysListVertScrollbar(pList);
		if (!pBar) return;
		const CEGUI::Rect area = pList->getListRenderArea();
		const float areaHeight = area.d_bottom - area.d_top;
		float before = 0.0f, total = 0.0f;
		for (size_t i = 0; i < count; ++i)
		{
			const float h = pList->getListboxItemFromIndex(i)->getPixelSize(pList).d_height;
			if (i < index) before += h;
			total += h;
		}
		if (total == areaHeight) return;                                   // B: exact compare, nothing to do
		if (areaHeight > total - before) before = total - areaHeight;      // B: never scroll past the end
		pBar->setScrollPosition(before);
	}

}

INT ListBox::GetCurrentFirstItem( LuaPlus::LuaState* pState )
{
	CEGUI::Listbox* pList = (CEGUI::Listbox*)m_pWindow;
	CEGUI::ListboxItem* pItem = cysFirstVisibleItem(pList);
	const double index = pItem ? (double)pList->getItemIndex(pItem) : -1.0;
	if (cysHost2Probe())
	{
		CEGUI::Scrollbar* pBar = cysListVertScrollbar(pList);
		char line[256] = {0};
		_snprintf(line, sizeof(line) - 1, "CYS-HOST2: GetCurrentFirstItem %s -> %g (items=%u scroll=%.1f)",
			pList->getName().c_str(), index, (unsigned)pList->getItemCount(), pBar ? pBar->getScrollPosition() : -1.0f);
		CEGUI::Logger::getSingleton().logEvent((const CEGUI::utf8*)line);
	}
	pState->PushNumber(index);
	return 1;
}

INT ListBox::GetItemNumber( LuaPlus::LuaState* pState )
{
	pState->PushInteger((INT)((CEGUI::Listbox*)m_pWindow)->getItemCount());
	return 1;
}

INT ListBox::SetCurrentFirstItem( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	if (!args[2].IsNumber()) return 0;                 // B: lua_tonumber(2) of a non-number is 0 -> item 0; nil here is safer
	const int index = (int)args[2].GetNumber();       // B: (int) then size_t - a negative index is refused by "index >= count"
	CEGUI::Listbox* pList = (CEGUI::Listbox*)m_pWindow;
	if (index >= 0) cysSetFirstVisibleItem(pList, (size_t)index);
	if (cysHost2Probe())
	{
		CEGUI::Scrollbar* pBar = cysListVertScrollbar(pList);
		CEGUI::ListboxItem* pFirst = cysFirstVisibleItem(pList);
		char line[256] = {0};
		_snprintf(line, sizeof(line) - 1, "CYS-HOST2: SetCurrentFirstItem %s <- %d (items=%u scroll=%.1f now first=%d)",
			pList->getName().c_str(), index, (unsigned)pList->getItemCount(), pBar ? pBar->getScrollPosition() : -1.0f,
			pFirst ? (int)pList->getItemIndex(pFirst) : -1);
		CEGUI::Logger::getSingleton().logEvent((const CEGUI::utf8*)line);
	}
	return 0;
}

LuaPlus::LuaObject* ComboBox::s_pMetaTable = NULL;
INT ComboBox::ComboBoxAddItem( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	// CYS-PLUMB: B's UI_CEGUI AddTextItem (0x180012ee0) gates on lua_isstring, which is also true for a number, and
	// only then reads LuaStackObject::GetString. 0.85 tested LUA_TSTRING alone, so a numeric caption silently added
	// nothing (BangHuiFuLi.lua:62 "SetHour:AddTextItem( i+7, i )" left the hour dropdown empty). "%.14g" is Lua's own
	// number->string format, so the text is what Lua's tostring() would have produced.
	std::string strMbcs;
	if (args[2].IsString())
		strMbcs = args[2].GetString();
	else if (args[2].IsNumber())
	{
		CHAR szNum[40] = {0};
		_snprintf(szNum, sizeof(szNum) - 1, "%.14g", args[2].GetNumber());
		strMbcs = szNum;
	}
	else
		return 0;
	CEGUI::String caption;
	CUIStringSystem::GetMe()->ParserString_Runtime(strMbcs, caption);
	CEGUI::ListboxTextItem* pItem = new CEGUI::ListboxTextItem(caption, args[3].GetInteger());

	pItem->setSelectionColours(CEGUI::colour(1.0f, 0.0f, 0.0f));
	// CYS: Listbox/Combobox apply SelectBrush and SelectColour from the current look.
	((CEGUI::Combobox*)m_pWindow)->addItem( pItem );

	return 0;
}
INT		ComboBox::ResetList( LuaPlus::LuaState* pState )
{
	((CEGUI::Combobox*)m_pWindow)->resetList();
	return 0;
}
// CYS-MTSWEEP 19/09: `CreateRole.lua:900/922/1108` goi `GetCurrentSelect()` tren `CreateRole_SelectHair` /
// `_SelectFace` / `_SelectClothin` - ca ba deu la `TLBB_Frame2` -> `Falagard/StaticImage`, KHONG phai Combobox.
// `Combobox::getSelectedItem()` doc `d_droplist` roi goi ham AO tren no => con tro rac. Ba ham Lua chua ham
// nay (`CreateRole_ComboListSelect*`) hien KHONG duoc gan vao su kien nao => min dang NAM IM, dung nghia
// "moi khung chua ai mo thi min van nam im". Van sua vi do la man TAO NHAN VAT, ai cung di qua.
INT		ComboBox::GetCurrentSelect( LuaPlus::LuaState* pState )
{
	CEGUI::Combobox* pCombo = dynamic_cast<CEGUI::Combobox*>(m_pWindow);
	if( pCombo && pCombo->getSelectedItem() )
	{
		pState->PushString( pCombo->getSelectedItem()->getText().c_str() );
		pState->PushInteger( int( pCombo->getSelectedItem()->getID() ) );
	}
	else
	{
		pState->PushString( "-1" );
		pState->PushInteger( -1 );
	}

	return 2;
}
INT		ComboBox::SetCurrentSelect( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	// B UI_CEGUI 0x21b40: invalid type/index leaves selection and text unchanged.
	if (!args[2].IsNumber()) return 0;
	const double value = std::trunc(args[2].GetNumber());
	if (!std::isfinite(value) || value < 0 || value > (std::numeric_limits<int>::max)()) return 0;
	const size_t index = static_cast<size_t>(value);
	CEGUI::Combobox* box = static_cast<CEGUI::Combobox*>(m_pWindow);
	if (index >= box->getItemCount()) return 0;
	CEGUI::ListboxItem* pItem = box->getListboxItemFromIndex(index);
	if (!pItem) return 0;
	box->setItemSelectState(index, true);
	box->setText(pItem->getText());
	return 0;
}

////////////////////////////////////////////////////////////////////////////////////
LuaPlus::LuaObject* StaticImage::s_pMetaTable = NULL;
INT StaticImage::SetImageColor( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	if (!(args[2].IsString())) 
		return 0;
	CEGUI::colour color = CEGUI::PropertyHelper::stringToColour( args[ 2 ].GetString() );
	CEGUI::ColourRect colorRect( color );
	m_pWindow->setProperty( "ImageColours", CEGUI::PropertyHelper::colourRectToString( colorRect ) );

	return 0;
}
INT StaticImage::SetImage( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	if (!(args[2].IsString())) 
		return 0;
	if( args[3].IsString() ) // 说明这个图片是全路径
	{
		// CYS-CRTGUARD 20/09/2026: ba doi so cua 0.85 bi dat SAI THU TU (commit nhap ma goc
		// 9abac1e3). Nguyen van: `_snprintf("set:%s image:%s", 128, a, b)` nghia la
		//   buffer = HANG CHUOI "set:%s image:%s"  -> ghi vao .rdata (bo nho CHI DOC)
		//   count  = 128
		//   format = args[2].GetString()           -> chuoi dinh dang do LUA dieu khien
		// va `strImageName` thi CHUA BAO GIO duoc ghi, roi van duoc doc ngay dong sau.
		// Ba loi trong mot dong: ghi vao bo nho chi doc, chuoi dinh dang khong tin cay,
		// va doc bien chua khoi tao. Sua lai dung thu tu, khong doi y dinh.
		char strImageName[128] = {0};
		_snprintf(strImageName, sizeof(strImageName) - 1, "set:%s image:%s",
			args[2].GetString(), args[3].GetString());
		strImageName[sizeof(strImageName) - 1] = 0;		// _snprintf khong tu ket NUL khi day
		m_pWindow->setProperty("Image", strImageName );
	}
	else// 说明是icon
	{
		STRING strIconName;
		try
		{
			strIconName = CUISystem::GetMe()->GetIconManager()->GetIconFullName(args[2].GetString());
			m_pWindow->setProperty("Image", (CEGUI::utf8*)strIconName.c_str());
		}
		catch(...)
		{
			CHAR szDebug[1024] = {0};
			_snprintf(szDebug, 1024, 
				"传说中的LuaError，一定要告诉我，我找它很久了\n"
				"arg2=%s\n"
				"Full=%s\n"
				"pWindow=%08X\n"
				"this=%08X",
				args[2].GetString(), strIconName.c_str(), (DWORD)(DWORD_PTR)m_pWindow, (DWORD)(DWORD_PTR)this);

			MessageBox(g_hMainWnd, szDebug, "LUA", MB_OK|MB_ICONINFORMATION);
		}
	}
	return 0;
}
////////////////////////////////////////////////////////////////////////////////////
// ScrollBar
LuaPlus::LuaObject* ScrollBar::s_pMetaTable = NULL;
INT ScrollBar::GetPosition( LuaPlus::LuaState* pState )
{
	pState->PushNumber( ((CEGUI::Scrollbar*)m_pWindow)->getScrollPosition() );
	return 1;
}

INT ScrollBar::SetPosition( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	if (!(args[2].IsNumber())) 
		return 0;
	((CEGUI::Scrollbar*)m_pWindow)->setScrollPosition((float)args[2].GetNumber());

	return 0;
}

////////////////////////////////////////////////////////////////////////////////////
// SuperTooltip
LuaPlus::LuaObject* SuperTooltip::s_pMetaTable = NULL;

INT SuperTooltip::PositionSelf( LuaPlus::LuaState* pState )
{
	// CYS-SEFIT 19/09: this function must return the placement it chose - the CY script binds TWO
	// values from it (SuperTooltip.lua:181 `g_pos1, g_pos2 = _SuperTooltip_:PositionSelf(...)`) and then
	// compares them as numbers (`tonumber(g_pos1) < tonumber(g_left)` at :187, `g_pos2 < y_offset` at
	// :191). The 0.85 body returned ZERO values on BOTH paths, so g_pos1/g_pos2 were always nil and
	// line 187 threw "attempt to compare nil with number" - measured 5 times in the user's 19/09 22:45
	// session (Build/Logs/2026-09-19-user-play-2/WXClient.log 1346/1392/1403/1438/1453), which is the
	// "khung Thong tin con loi" the user reported. One throw kills the whole Lua call, so everything
	// after :187 (the equipment-compare window placement) never ran.
	// The contract is TOTAL on purpose: every path returns two numbers, so no caller can see nil.
	LuaStack args(pState);
	if (!(args[2].IsString())||(!(args[3].IsString())))
	{
		// Cannot compute a new placement; answer with where the window already is rather than
		// nothing, so the script's numeric comparisons still have numbers to work with.
		pState->PushNumber(m_pWindow ? m_pWindow->getAbsoluteXPosition() : 0.0f);
		pState->PushNumber(m_pWindow ? m_pWindow->getAbsoluteYPosition() : 0.0f);
		return 2;
	}

	//强制SuperTooltip重新计算组件大小
	CEGUI::FalagardSuperTooltip* tooltip = dynamic_cast<CEGUI::FalagardSuperTooltip*>(m_pWindow);
	if (!tooltip)
	{
		pState->PushNumber(0); pState->PushNumber(0); return 2;
	}
	tooltip->resizeSelf();

	FLOAT fX = args[2].GetFloat();
	FLOAT fY = args[3].GetFloat();

	//重新计算
	FLOAT fWidth	= m_pWindow->getAbsoluteWidth();
	FLOAT fHeight	= m_pWindow->getAbsoluteHeight();

	FLOAT fScreenWidth	= CUIWindowMng::GetClientScreen()->getAbsoluteWidth();
	FLOAT fScreenHeight = CUIWindowMng::GetClientScreen()->getAbsoluteHeight();

	if (!CysTooltipContract::Old() && args[4].IsString() && args[5].IsString())
	{
		// D4: live PositionSelf takes the four edges of the hovered button.
		const FLOAT right = args[4].GetFloat(), bottom = args[5].GetFloat();
		fX = fWidth + right + 5.0f <= fScreenWidth ? right + 0.5f : fX - fWidth;
		fY = fHeight + bottom + 5.0f <= fScreenHeight ? bottom + 0.5f : fY - fHeight;
		if (fX < 0.0f) fX = 0.0f;
		if (fY < 0.0f) fY = 0.0f;
	}
	else
	{
		// Keep the existing point API for older callers and the negative arm.
		if (fX + fWidth + 5.0f > fScreenWidth) fX -= fWidth + 5.0f;
		else fX += 5.0f;
		if (fY + fHeight + 5.0f > fScreenHeight) fY -= fHeight + 5.0f;
		else fY += 5.0f;
	}

	// CYS-MTSWEEP 19/09: ban cu ep `m_pWindow` thanh `CEGUI::PopupMenu*` roi goi `setXPosition`/`setYPosition`.
	// Ca 27 cua so goi `PositionSelf` deu la `Falagard/SuperTooltip`, KHONG phai PopupMenu; hai ham nay lai la ham
	// cua chinh `CEGUI::Window` nen dia chi khong doi va hom nay chua no. Bo han phep ep - khong co ly do de giu
	// mot ep kieu mu chi de goi ham lop goc; giu no lai la de mot qua min cho nguoi sau doi ham.
	m_pWindow->setXPosition(CEGUI::Absolute, fX);
	m_pWindow->setYPosition(CEGUI::Absolute, fY);

	// CYS-SEFIT: hand the chosen placement back (see the note at the top of this function).
	pState->PushNumber(fX);
	pState->PushNumber(fY);
	return 2;
}


////////////////////////////////////////////////////////////////////////////////////
// MeshWindow
LuaPlus::LuaObject* MeshWindow::s_pMetaTable = NULL;

static unsigned int cysMeshTextureExtent(float value)
{
	// B truncates the absolute dimension before choosing 2^n, with n >= 1.
	if (!std::isfinite(value) || value < 0 || value > 1073741824.0f)
		TDThrow("MeshWindow: invalid absolute texture size");
	const unsigned int pixels = static_cast<unsigned int>(value);
	unsigned int result = 2;
	while (result < pixels) result *= 2;
	return result;
}

INT MeshWindow::SetFakeObject( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	if( !args[2].IsString())
		return 0;

	//通知FakeObject系统
	const CEGUI::Size size = m_pWindow->getAbsoluteSize();
	const CEGUI::String backgroundName = m_pWindow->getProperty("BackgroundName");
	CysUiMeshBridge::Hook hook = reinterpret_cast<CysUiMeshBridge::Hook>(
		GetProcAddress(GetModuleHandleA(NULL), "CysFakeObjOnUIHook"));
	if (!hook) TDThrow("MeshWindow: Game background bridge unavailable");
	hook(m_pWindow->getName().c_str(), args[2].GetString(),
		cysMeshTextureExtent(size.d_width), cysMeshTextureExtent(size.d_height),
		backgroundName.c_str());
	//通知UI
	m_pWindow->setProperty((CEGUI::utf8*)"FakeObject", (CEGUI::utf8*)args[2].GetString());

	return 0;
}

INT MeshWindow::RotateBegin(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);
	if( !args[2].IsNumber())
		return 0;

	FLOAT fAngle = args[2].GetFloat();

	//通知FakeObject系统
	g_pFakeSystem->RotateObj_Begin(m_pWindow->getProperty((CEGUI::utf8*)"FakeObject").c_str(), fAngle);

	return 0;
}

INT MeshWindow::ChangeActionBegin(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);
	if( !args[2].IsNumber())
		return 0;
	if( !args[3].IsNumber())
		return 0;
	INT ActionNUM = args[2].GetInteger();
	INT ActionLoop = args[3].GetInteger();

	//通知FakeObject系统
	g_pFakeSystem->Obj_ChangeAction(m_pWindow->getProperty((CEGUI::utf8*)"FakeObject").c_str(), ActionNUM,ActionLoop);

	return 0;
}

INT MeshWindow::RotateEnd(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);

	//通知FakeObject系统
	g_pFakeSystem->RotateObj_End(m_pWindow->getProperty((CEGUI::utf8*)"FakeObject").c_str());

	return 0;
}

////////////////////////////////////////////////////////////////////////////////////
// CYS-MESHWIN 19/09: the eight MetaTable_Control_MeshWindow:*Ex functions of CY 3.71.
//
// Source: Build\re\cy-oracle\CYGame\Bin64\UI_CEGUI.dll (CY 3.71, sha256 e90c68e0..., image base 0x180000000),
// registration block 0x18002ba55-0x18002bcf6 (member function stored in the functor, name from .rdata 0x18008bdc0..).
// CY routes the *Ex calls to a SECOND kernel node "bin\fakeEx" (g_pFakeSystemEx = 0x1800b6258; Game.exe class
// CFakeObjSystemEx, vtable 0x140af4898, found through RTTI), while SetFakeObject/RotateBegin/RotateEnd keep "bin\fake"
// (g_pFakeSystem = 0x1800b6250). Its mechanism is the classic one: Attach = create the RTT for (object, window),
// RotateBegin = remember (entry, speed) and add the speed to the face direction every tick (Game.exe 0x1401fa350 =
// exactly CFakeObjSystem::Tick), RotateEnd = forget it (0x1401f9d10). So the tree keeps ONE fake system and maps:
//
//   AttachWindowEx(obj)         0x180022450  w,h = (int)pixel size (NO pow2), bg = property "BackgroundName",
//                                            fakeEx->vt[15](window, obj, w, h, bg); does NOT set property FakeObject.
//                                            Here: CysFakeObjOnUIHook (pow2 as SetFakeObject; Game forces "Player" to
//                                            256x512 - CY's fakeEx forces 256x256, Game.exe 0x1401f9850) + property
//                                            FakeObject = obj so MeshShown fires when the window is visible (= the
//                                            RTT starts updating; CY's fakeEx keys the RTT by window and updates it
//                                            itself, this tree needs the event).
//   DetachWindowEx()            0x1800247c0  fakeEx->vt[16](window, 0)          -> hook(window, "", ...) = OnUIUnHook
//   RotateBeginEx(obj, angle)   0x180032b20  fakeEx->vt[18](obj, angle * 0.5f) -> RotateObj_Begin(obj, angle*0.5f)
//                                            (the 0.5f is CY's own, .rdata 0x180086574; also in CY's RotateBegin)
//   RotateEndEx()               0x180032c90  fakeEx->vt[19](window)             -> RotateObj_End(object of the window)
//   RestPositonEx()             0x1800329c0  fakeEx->vt[20](window) -> render vt[0x9e] -> CysFakeObjRestPose [SL]
//   GetCameraEx()               0x1800250d0  fakeEx->vt[21](window, &h, &d, &p); pushes 3 numbers
//   SetCameraEx(h, d, p[, x])   0x1800365c0  args 2-4 numbers, arg 5 optional (0); fakeEx->vt[22](window, h, d, p, x)
//   ChangeCameraDistanceEx(name, dir, delta)  0x180022a60  strstr(name, "Tujian") && fakeEx->vt[23](name) ->
//                                            camera (1.0, 9.5, 0.28); else get, d +/- delta (dir == 0 ? + : -), set.
// Argument checks are CY's (lua_isstring / lua_type == LUA_TNUMBER); a bad argument returns 0 values, no throw.
// METATABLE RULE (metatable-sweep 19/09): the shared metatable makes every registered name reachable from every Lua
// window; each body therefore checks testClassName("FalagardMeshWindow") before touching properties that only a
// mesh window has, and logs instead of casting.
namespace
{
	struct CysMeshWinBridge
	{
		CysUiMeshBridge::Hook hook;
		CysUiMeshBridge::CameraGet cameraGet;
		CysUiMeshBridge::CameraSet cameraSet;
		CysUiMeshBridge::RestPose restPose;
		CysUiMeshBridge::ObjectExists exists;
	};

	void cysMeshWinLog(const char* fmt, ...)
	{
		char line[512] = {0};
		va_list ap; va_start(ap, fmt);
		_vsnprintf(line, sizeof(line) - 1, fmt, ap);
		va_end(ap);
		CEGUI::Logger::getSingleton().logEvent((const CEGUI::utf8*)line);
	}

	// Game.exe exports, resolved once; the Hook is the export SetFakeObject already uses, the rest are new
	// (pairing check of the DLL cluster: grep -c CysFakeObjCameraGet Game.exe UI_CEGUI.dll must agree).
	const CysMeshWinBridge& cysMeshWinBridge()
	{
		static CysMeshWinBridge s_bridge = {NULL, NULL, NULL, NULL, NULL};
		static bool s_resolved = false;
		if (!s_resolved)
		{
			s_resolved = true;
			HMODULE game = GetModuleHandleA(NULL);
			s_bridge.hook = reinterpret_cast<CysUiMeshBridge::Hook>(GetProcAddress(game, "CysFakeObjOnUIHook"));
			s_bridge.cameraGet = reinterpret_cast<CysUiMeshBridge::CameraGet>(GetProcAddress(game, "CysFakeObjCameraGet"));
			s_bridge.cameraSet = reinterpret_cast<CysUiMeshBridge::CameraSet>(GetProcAddress(game, "CysFakeObjCameraSet"));
			s_bridge.restPose = reinterpret_cast<CysUiMeshBridge::RestPose>(GetProcAddress(game, "CysFakeObjRestPose"));
			s_bridge.exists = reinterpret_cast<CysUiMeshBridge::ObjectExists>(GetProcAddress(game, "CysFakeObjExists"));
			cysMeshWinLog("CYS-MESHWIN: Game bridge hook=%d cameraGet=%d cameraSet=%d restPose=%d exists=%d",
				s_bridge.hook ? 1 : 0, s_bridge.cameraGet ? 1 : 0, s_bridge.cameraSet ? 1 : 0, s_bridge.restPose ? 1 : 0, s_bridge.exists ? 1 : 0);
		}
		return s_bridge;
	}

	bool cysMeshWinIsMesh(CEGUI::Window* pWindow, const char* fn)
	{
		if (pWindow && pWindow->testClassName((const CEGUI::utf8*)"FalagardMeshWindow")) return true;
		cysMeshWinLog("CYS-MESHWIN: %s on %s [%s] ignored - not a FalagardMeshWindow", fn,
			pWindow ? pWindow->getName().c_str() : "?", pWindow ? pWindow->getWidgetType().c_str() : "?");
		return false;
	}

	// CY's defaults of this camera model (RFFakeObjectManager.cpp _GetFakeNode: 0.3 / 1.2 / 0.21), pushed when the
	// window shows nothing yet, so Lua arithmetic on GetCameraEx never sees nil.
	const float kMeshWinDefaultHeight = 0.3f;
	const float kMeshWinDefaultDistance = 1.2f;
	const float kMeshWinDefaultPitch = 0.21f;
}

INT MeshWindow::AttachWindowEx(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);
	if (!args[2].IsString()) return 0;
	if (!cysMeshWinIsMesh(m_pWindow, "AttachWindowEx")) return 0;

	const char* szObject = args[2].GetString();
	const CEGUI::Size size = m_pWindow->getAbsoluteSize();
	const CEGUI::String backgroundName = m_pWindow->getProperty((const CEGUI::utf8*)"BackgroundName");
	const CysMeshWinBridge& bridge = cysMeshWinBridge();
	if (!bridge.hook) TDThrow("MeshWindow: Game background bridge unavailable");   // same contract as SetFakeObject
	const unsigned int width = cysMeshTextureExtent(size.d_width);
	const unsigned int height = cysMeshTextureExtent(size.d_height);
	bridge.hook(m_pWindow->getName().c_str(), szObject, width, height, backgroundName.c_str());
	// The property setter fires MeshShown when the window is visible -> CUISystem::handleMeshWindowShown ->
	// OnUIShown -> the RTT starts auto-updating. Without it the texture stays at its clear colour.
	m_pWindow->setProperty((const CEGUI::utf8*)"FakeObject", (const CEGUI::utf8*)szObject);
	cysMeshWinLog("CYS-MESHWIN: AttachWindowEx %s <- %s rtt=%ux%u (window %.0fx%.0f) bg=%s visible=%d",
		m_pWindow->getName().c_str(), szObject, width, height, size.d_width, size.d_height,
		backgroundName.c_str(), m_pWindow->isVisible() ? 1 : 0);
	return 0;
}

INT MeshWindow::DetachWindowEx(LuaPlus::LuaState* pState)
{
	// CY ignores the Lua argument ("Player" in SelfEquip.lua:2847) and detaches by window name.
	LuaStack args(pState);
	if (!cysMeshWinIsMesh(m_pWindow, "DetachWindowEx")) return 0;
	const CysMeshWinBridge& bridge = cysMeshWinBridge();
	if (!bridge.hook) return 0;
	// Hooking the empty object name is the classic detach (CFakeObjSystem::OnUIHookWithBackground: a window that
	// shows another object is unhooked first, then the lookup of "" fails and returns) - the road every
	// SetFakeObject("") of the CY scripts already takes.
	bridge.hook(m_pWindow->getName().c_str(), "", 2, 2, "");
	m_pWindow->setProperty((const CEGUI::utf8*)"FakeObject", (const CEGUI::utf8*)"");
	cysMeshWinLog("CYS-MESHWIN: DetachWindowEx %s", m_pWindow->getName().c_str());
	return 0;
}

INT MeshWindow::RotateBeginEx(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);
	if (!args[2].IsString() || !args[3].IsNumber()) return 0;
	if (!cysMeshWinIsMesh(m_pWindow, "RotateBeginEx")) return 0;
	const FLOAT fAngle = args[3].GetFloat() * 0.5f;   // CY: mulss 0x180086574 (= 0.5f) before fakeEx->vt[18]
	g_pFakeSystem->RotateObj_Begin(args[2].GetString(), fAngle);
	// CYS-MESHEX 19/09: these five had no line of their own, so "installed" could not be told from "ran" in a live
	// run (meshwindow section 3.5 had to leave them at "no call yet"). One line per Lua call, button-rate only.
	cysMeshWinLog("CYS-MESHEX: RotateBeginEx %s <- %s speed=%.4f", m_pWindow->getName().c_str(), args[2].GetString(), fAngle);
	return 0;
}

INT MeshWindow::RotateEndEx(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);
	if (!cysMeshWinIsMesh(m_pWindow, "RotateEndEx")) return 0;
	const CEGUI::String object = m_pWindow->getProperty((const CEGUI::utf8*)"FakeObject");
	g_pFakeSystem->RotateObj_End(object.c_str());
	cysMeshWinLog("CYS-MESHEX: RotateEndEx %s (object %s)", m_pWindow->getName().c_str(), object.c_str());
	return 0;
}

INT MeshWindow::RestPositonEx(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);
	if (!cysMeshWinIsMesh(m_pWindow, "RestPositonEx")) return 0;
	const CysMeshWinBridge& bridge = cysMeshWinBridge();
	if (!bridge.restPose) return 0;
	const int rc = bridge.restPose(m_pWindow->getName().c_str());
	cysMeshWinLog("CYS-MESHWIN: RestPositonEx %s rc=%d", m_pWindow->getName().c_str(), rc);
	return 0;
}

INT MeshWindow::GetCameraEx(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);
	float h = kMeshWinDefaultHeight, d = kMeshWinDefaultDistance, p = kMeshWinDefaultPitch, x = 0.0f;
	if (cysMeshWinIsMesh(m_pWindow, "GetCameraEx"))
	{
		const CysMeshWinBridge& bridge = cysMeshWinBridge();
		const int rc = bridge.cameraGet ? bridge.cameraGet(m_pWindow->getName().c_str(), &h, &d, &p, &x) : -1;
		cysMeshWinLog("CYS-MESHEX: GetCameraEx %s rc=%d h=%.4f d=%.4f p=%.4f x=%.4f",
			m_pWindow->getName().c_str(), rc, h, d, p, x);
	}
	pState->PushNumber(h);
	pState->PushNumber(d);
	pState->PushNumber(p);
	return 3;
}

INT MeshWindow::SetCameraEx(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);
	if (!args[2].IsNumber() || !args[3].IsNumber() || !args[4].IsNumber()) return 0;
	if (!cysMeshWinIsMesh(m_pWindow, "SetCameraEx")) return 0;
	const float x = args[5].IsNumber() ? args[5].GetFloat() : 0.0f;   // CY: optional 5th stack slot, else 0
	const CysMeshWinBridge& bridge = cysMeshWinBridge();
	if (!bridge.cameraSet) return 0;
	const int rc = bridge.cameraSet(m_pWindow->getName().c_str(), args[2].GetFloat(), args[3].GetFloat(), args[4].GetFloat(), x);
	cysMeshWinLog("CYS-MESHEX: SetCameraEx %s rc=%d h=%.4f d=%.4f p=%.4f x=%.4f",
		m_pWindow->getName().c_str(), rc, args[2].GetFloat(), args[3].GetFloat(), args[4].GetFloat(), x);
	return 0;
}

INT MeshWindow::ChangeCameraDistanceEx(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);
	if (!args[2].IsString() || !args[3].IsNumber() || !args[4].IsNumber()) return 0;
	if (!cysMeshWinIsMesh(m_pWindow, "ChangeCameraDistanceEx")) return 0;
	const CysMeshWinBridge& bridge = cysMeshWinBridge();
	if (!bridge.cameraGet || !bridge.cameraSet) return 0;
	const char* szName = args[2].GetString();
	const char* szWindow = m_pWindow->getName().c_str();
	// CY 0x180022ac7-0x180022b40: a pet-book object ("Tujian" in the name, known to fakeEx) gets a fixed far camera
	// (.rdata 0x180087764 / 0x18008ddd0 / 0x18008ddb8 = 1.0 / 9.5 / 0.28).
	if (strstr(szName, "Tujian") && bridge.exists && bridge.exists(szName) == 1)
	{
		bridge.cameraSet(szWindow, 1.0f, 9.5f, 0.28f, 0.0f);
		cysMeshWinLog("CYS-MESHEX: ChangeCameraDistanceEx %s Tujian fixed 1.0/9.5/0.28", szWindow);
		return 0;
	}
	float h = kMeshWinDefaultHeight, d = kMeshWinDefaultDistance, p = kMeshWinDefaultPitch, x = 0.0f;
	if (bridge.cameraGet(szWindow, &h, &d, &p, &x) != 1)
	{
		cysMeshWinLog("CYS-MESHEX: ChangeCameraDistanceEx %s (%s) - no camera for this window", szWindow, szName);
		return 0;
	}
	const float delta = args[4].GetFloat();
	const float before = d;
	d = (args[3].GetInteger() == 0) ? d + delta : d - delta;   // CY: cvttsd2si of arg 3, 0 = farther
	bridge.cameraSet(szWindow, h, d, p, 0.0f);   // CY passes 0 as the 5th argument here
	cysMeshWinLog("CYS-MESHEX: ChangeCameraDistanceEx %s (%s) dir=%d delta=%.4f d %.4f -> %.4f",
		szWindow, szName, args[3].GetInteger(), delta, before, d);
	return 0;
}

////////////////////////////////////////////////////////////////////////////////////
// ChatHistory
LuaPlus::LuaObject* ChatHistory::s_pMetaTable = NULL;
INT ChatHistory::InsertChatString(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);
	if( !args[2].IsString())
		return 0;

	//代码转化
	std::string strMbcs = args[2].GetString();
	CEGUI::String strUtf32;
	CUIStringSystem::GetMe()->ParserString_Runtime(strMbcs, strUtf32);
	((CEGUI::IFalagardChatHistory*)(CEGUI::FalagardChatHistory*)m_pWindow)->insertChatString(strUtf32);

	return 0;
}

INT ChatHistory::RemoveAllChatString(LuaPlus::LuaState* pState)
{
	((CEGUI::IFalagardChatHistory*)(CEGUI::FalagardChatHistory*)m_pWindow)->removeAllChatStrings();
	return 0;
}

INT	ChatHistory::ScrollToEnd(LuaPlus::LuaState* pState)
{
	((CEGUI::IFalagardChatHistory*)(CEGUI::FalagardChatHistory*)m_pWindow)->scrollToEnd();
	return 0;
}

INT ChatHistory::ExtendClearRegion(LuaPlus::LuaState* pState)
{
	((CEGUI::IFalagardChatHistory*)(CEGUI::FalagardChatHistory*)m_pWindow)->extendClearRegion();
	return 0;
}
////////////////////////////////////////////////////////////////////////////////////
// ChatChannel
LuaPlus::LuaObject* ChatChannel::s_pMetaTable = NULL;
INT ChatChannel::ClearAllChannel(LuaPlus::LuaState* pState)
{
	((CEGUI::IFalagardChatChannel*)(CEGUI::FalagardChatChannel*)m_pWindow)->clearAllChannel();

	return 0;
}

INT ChatChannel::AddChannel(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);
	if( !args[2].IsString() || !args[3].IsString() || !args[4].IsString())
		return 0;

	//代码转化
	std::string strMbcs_ChannelType =  args[2].GetString();
	CEGUI::String strUtf32_ChannelType;
	CUIStringSystem::GetMe()->ParserString_Runtime(strMbcs_ChannelType, strUtf32_ChannelType);

	std::string strMbcs_IconName =  args[3].GetString();
	CEGUI::String strUtf32_IconName;
	CUIStringSystem::GetMe()->ParserString_Runtime(strMbcs_IconName, strUtf32_IconName);

	std::string strMbcs_Name =  args[4].GetString();
	CEGUI::String strUtf32_Name;
	CUIStringSystem::GetMe()->ParserString_Runtime(strMbcs_Name, strUtf32_Name);

	((CEGUI::IFalagardChatChannel*)(CEGUI::FalagardChatChannel*)m_pWindow)->addChannel(
		strUtf32_ChannelType, strUtf32_IconName, strUtf32_Name);

	m_pWindow->moveToFront();
	return 0;
}

//==============================================================================
LuaPlus::LuaObject* Scenemap::s_pMetaTable = NULL;
INT Scenemap::SetSceneZoomMode( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	if( !args[ 2 ].IsNumber() ) return 0;
	CEGUI::IFalagardSceneMapWindow* pWindow= (CEGUI::IFalagardSceneMapWindow*)(CEGUI::FalagardSceneMap*)m_pWindow;
	pWindow->SetZoomMode( float( args[ 2 ].GetNumber()) );
	return 0;
}
INT Scenemap::UpdateViewRect( LuaPlus::LuaState* pState )
{
	CEGUI::IFalagardSceneMapWindow* pWindow= (CEGUI::IFalagardSceneMapWindow*)(CEGUI::FalagardSceneMap*)m_pWindow;
	fVector3 MyselfPos = g_pWorldSystem->GetMyselfPos();
	CEGUI::Point pos;
	pos.d_x = MyselfPos.x;
	pos.d_y = MyselfPos.z;
	pWindow->setMyselfPos( pos );

	pWindow->setSceneMapCenter( );
	return 0;
}
INT Scenemap::SetSceneFileName( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	if( !args[ 2 ].IsNumber() ) return 0;
	if( !args[ 3 ].IsNumber() ) return 0;
	if( !args[ 4 ].IsString() ) return 0;
	CEGUI::IFalagardSceneMapWindow* pWindow= (CEGUI::IFalagardSceneMapWindow*)(CEGUI::FalagardSceneMap*)m_pWindow;
	pWindow->SetSceneSize( CEGUI::Size( float( args[ 2 ].GetNumber() ), float( args[ 3 ].GetNumber() ) ) );
	// GL SceneMap_Show seeds UpdateViewRect before showing; the CY Lua omits that call.
	// Seed before CreateSceneMap can render its first arrow, using the same world sample as UpdateFlag.
	static const bool legacy = []() { char t[4] = {}; return (::GetEnvironmentVariableA("CYS_MAPDOTS_LEGACY", t, sizeof(t)) == 1 && t[0] == '1'); }();
	const bool seedMyself = !legacy && args[5].GetNumber() != 0 && g_pWorldSystem && g_pWorldSystem->GetActiveScene();
	if (seedMyself)
	{
		const fVector3 pos = g_pWorldSystem->GetMyselfPos();
		pWindow->setMyselfPos(CEGUI::Point(pos.x, pos.z));
		pWindow->setMyselfDir(g_pWorldSystem->GetMyselfDir());
	}
	pWindow->SetSceneFileName( args[ 4 ].GetString(), args[ 5 ].GetNumber() );
	if (seedMyself) pWindow->setSceneMapCenter();
	return 0;
}
INT Scenemap::CloseSceneMap( LuaPlus::LuaState* pState )
{
	CEGUI::IFalagardSceneMapWindow* pWindow= (CEGUI::IFalagardSceneMapWindow*)(CEGUI::FalagardSceneMap*)m_pWindow;
	pWindow->Clear();
	return 0;
}

INT Scenemap::GetMouseScenePos( LuaPlus::LuaState* pState )
{
	CEGUI::IFalagardSceneMapWindow* pWindow= (CEGUI::IFalagardSceneMapWindow*)(CEGUI::FalagardSceneMap*)m_pWindow;
	const CEGUI::Point pos = pWindow->GetMouseScenePos();
	pState->PushInteger( int( pos.d_x ) );
	pState->PushInteger( int( pos.d_y ) );
	return 2;
}


INT	Scenemap::UpdateSceneMap( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);

	if( !m_pWindow->isVisible() )
		return 0;
	CEGUI::IFalagardSceneMapWindow* pWindow= (CEGUI::IFalagardSceneMapWindow*)(CEGUI::FalagardRadar*)m_pWindow;
	fVector3 MyselfPos = g_pWorldSystem->GetMyselfPos();
	int		 nDir = g_pWorldSystem->GetMyselfDir( );
	pWindow->setMyselfPos( CEGUI::Point( MyselfPos.x, MyselfPos.z ) );
	pWindow->setMyselfDir( nDir );
	pWindow->setMAXJuLi(args[2].GetFloat());
	if( m_pWindow->isVisible() )
	{
		// 跟新所有的标志位置
		pWindow->Clear();
		for( INT i = 0; i < 9; i ++ )
		{
			if( i == 2 || i == 7 || i == 5 )
			{
				std::list< MAP_POS_DEFINE >* listObj = g_pWorldSystem->GetObjectListByClass( i );
				// 得到了当前类型所有的物体的链表
				std::list< MAP_POS_DEFINE >::iterator it;
				for( it = listObj->begin(); it != listObj->end(); it ++ )
				{
					std::string strUtf8;
					std::string strMbcs = (*it).name;
					CUIStringSystem::mbcs_to_utf8(strMbcs, strUtf8 );
					if( i == 2 ) // 如果是队友，需要单独处理
						if( (*it).dwSceneID != g_pWorldSystem->GetActiveSceneID() ) // 在同一场景才会添加
							continue;
					pWindow->setMinimapData( i, (*it).pos.x, (*it).pos.z,  (CEGUI::String)(CEGUI::utf8*)strUtf8.c_str() );
				}
			}
		}
	}
	
	

	return 0;
}

// 初始化世界地图
LuaPlus::LuaObject* Worldmap::s_pMetaTable = NULL;
INT	Worldmap::InitWorldMap( LuaPlus::LuaState* pState )
{
	const tDataBase* pdbcbase = g_pDataBaseSystem->GetDataBase( DBC_SCENE_DEFINE );
	int nNum = pdbcbase->GetRecordsNum();
	std::list< MAP_POS_DEFINE >* listObj = g_pWorldSystem->GetObjectListByClass( 2 );
	std::list< MAP_POS_DEFINE >::iterator it;
	
	CEGUI::IFalagardWorldMap* pWindow= (CEGUI::IFalagardWorldMap*)(CEGUI::FalagardWorldMap*)m_pWindow;

	pWindow->createBackground();
	for( int i = 0; i < nNum; i ++ )
	{
		const _DBC_SCENE_DEFINE* pLine = (const _DBC_SCENE_DEFINE*)((tDataBase*)pdbcbase)->Search_LineNum_EQU(i);
		if( pLine )
		{
			if( pLine->nWroldMapPosX == 0 ||pLine->nWroldMapPosY == 0 )
				continue;
			pWindow->setCityPos( pLine->nServerID, CEGUI::Point( float( pLine->nWroldMapPosX ), float( pLine->nWroldMapPosY ) ) );
			pWindow->setCityNamePos( pLine->nServerID, CEGUI::Point( float( pLine->nNameWroldMapPosX ),float( pLine->nNameWroldMapPosY ) ) );
			pWindow->setCityType( pLine->nServerID, pLine->szSceneType );
			
			pWindow->setCityNameNormalImage( pLine->nServerID, pLine->szCityNameNormalImageSet, pLine->szCityNameNormalImage  );
			pWindow->setCityNameHoverImage( pLine->nServerID, pLine->szCityNameHoverImageSet, pLine->szCityNameHoverImage );

			// 判断是不是当前场景
			//
			if( pLine->nServerID == g_pWorldSystem->GetActiveScene()->GetSceneDefine()->nServerID )
				pWindow->setCityCurrentScene( pLine->nServerID, 1 );
			else
				pWindow->setCityCurrentScene( pLine->nServerID, 0 );
		}

	}
	UpdatePlayer();
	pWindow->resetWorldMap();

	return 0;
}

INT	Worldmap::UpdateWorldMap( LuaPlus::LuaState* pState )
{
	UpdatePlayer();
	return 0;
}
INT Worldmap::GetCurrentSelectScene( LuaPlus::LuaState* pState )
{
	CEGUI::IFalagardWorldMap* pWindow= (CEGUI::IFalagardWorldMap*)(CEGUI::FalagardWorldMap*)m_pWindow;
	pState->PushInteger( pWindow->getCurrentSelectScene() );
	return 1;
}
CEGUI::String Worldmap::GetSceneNameByID( int id )
{
	const tDataBase* pdbcbase = g_pDataBaseSystem->GetDataBase( DBC_SCENE_DEFINE );
	int nNum = pdbcbase->GetRecordsNum();
	for( int i = 0; i < nNum; i ++ )
	{
		const _DBC_SCENE_DEFINE* pLine = (const _DBC_SCENE_DEFINE*)((tDataBase*)pdbcbase)->Search_First_Column_Equ(_DBC_SCENE_DEFINE::SCENE_SERVER_ID_COLUMN, i);
		if( pLine->nServerID == id )
			return pLine->szName;
	}
	return "";
}
void Worldmap::UpdatePlayer()
{
	const tDataBase* pdbcbase = g_pDataBaseSystem->GetDataBase( DBC_SCENE_DEFINE );
	int nNum = pdbcbase->GetRecordsNum();
	std::list< MAP_POS_DEFINE >* listObj = g_pWorldSystem->GetObjectListByClass( 2 );
	std::list< MAP_POS_DEFINE >::iterator it;
	// 遍历所有的好友
	CEGUI::IFalagardWorldMap* pWindow= (CEGUI::IFalagardWorldMap*)(CEGUI::FalagardWorldMap*)m_pWindow;
	pWindow->clearPlayerInfo();
	for( it = listObj->begin(); it != listObj->end(); it ++ )
	{
		std::string strUtf8;
		std::string strMbcs = ( *it ).name;
		CUIStringSystem::mbcs_to_utf8(strMbcs, strUtf8 );
		pWindow->addPlayerToCity(  (*it ).dwSceneID, (CEGUI::String)(CEGUI::utf8*)strUtf8.c_str() );

	}
}
LuaPlus::LuaObject* InfoList::s_pMetaTable = NULL;
INT InfoList::AddInfo( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	if (!(args[2].IsString())) 
		return 0;
	//TextIndex
	std::string strMbcs = args[2].GetString();
	std::string strUtf8;
	CUIStringSystem::mbcs_to_utf8(strMbcs, strUtf8);

	CEGUI::String strUtf32;
	CUIStringSystem::GetMe()->ParserString_Runtime(strMbcs, strUtf32);

	m_pWindow->setProperty( "AddInfo", strUtf32 );
	return 0;
}

LuaPlus::LuaObject* CtrlList::s_pMetaTable = NULL;

INT CtrlList::AddColumn( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	std::string caption = args[2].GetString();
	CEGUI::String strUtf32;
	CUIStringSystem::GetMe()->ParserString_Runtime(caption, strUtf32);
	((CEGUI::MultiColumnList*)m_pWindow)->addColumn( strUtf32, args[ 3 ].GetInteger(), args[ 4 ].GetFloat() );

	return 0;
}
INT CtrlList::InsertColumn( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	std::string caption = args[2].GetString();
	CEGUI::String strUtf32;
	CUIStringSystem::GetMe()->ParserString_Runtime(caption, strUtf32);
	((CEGUI::MultiColumnList*)m_pWindow)->insertColumn(	strUtf32, args[ 3 ].GetInteger(), args[ 4 ].GetFloat(), args[ 5 ].GetInteger() );
	
	return 0;
}
INT CtrlList::AddNewItem( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	std::string caption = args[2].GetString();
	CEGUI::String strUtf32;
	CUIStringSystem::GetMe()->ParserString_Runtime(caption, strUtf32);
	CEGUI::ListboxTextItem* pItem = new CEGUI::ListboxTextItem( strUtf32, args[ 3 ].GetInteger() );
	CEGUI::colour colorText = CEGUI::colour(1.0f, 1.0f, 1.0f);
	pItem->setTextColours(colorText);
	pItem->setSelectionColours(CEGUI::colour(1.0f, 0.0f, 0.0f));
	// CY uses CommonFrame for list selection; Common/HoverTextBak belongs to the older client.
	pItem->setSelectionColours(CEGUI::colour(0xFFC8B88E));
	pItem->setSelectionBrushImage(CEGUI::PropertyHelper::stringToImage("set:CommonFrame image:CommonEditBoxBK"));

	//Find first listboxitem in row.
	CEGUI::MCLGridRef  grid_ref( args[ 4 ].GetInteger(), 0 );
	CEGUI::ListboxItem* pExistItem = 0;

	unsigned int rowC = ((CEGUI::MultiColumnList*)m_pWindow)->getRowCount();
	unsigned int columC = ((CEGUI::MultiColumnList*)m_pWindow)->getColumnCount();
	if(grid_ref.row < rowC && grid_ref.column < columC)
	{
		pExistItem = ((CEGUI::MultiColumnList*)m_pWindow)->getItemAtGridReference( grid_ref );
	}
	if(pExistItem)
	{//exist, add subItem
		((CEGUI::MultiColumnList*)m_pWindow)->setItem(pItem, args[3].GetInteger(), args[4].GetInteger());
	}
	else
	{//not exist, add new Item
		//set firt listboxitem's ID as row idx. for CtrlList::GetSelectItem
		pItem->setID(args[4].GetInteger());
		((CEGUI::MultiColumnList*)m_pWindow)->addRow( pItem, args[ 3 ].GetInteger(), args[ 4 ].GetInteger() );
	}
	return 0;
}
INT CtrlList::SetItemText( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	CEGUI::MCLGridRef  grid_ref( args[ 2 ].GetInteger(), args[ 3 ].GetInteger() );
	CEGUI::ListboxItem* pItem = 0;

	unsigned int rowC = ((CEGUI::MultiColumnList*)m_pWindow)->getRowCount();
	unsigned int columC = ((CEGUI::MultiColumnList*)m_pWindow)->getColumnCount();
	if(grid_ref.row < rowC && grid_ref.column < columC)
	{
		pItem = ((CEGUI::MultiColumnList*)m_pWindow)->getItemAtGridReference( grid_ref );
	}
	if( pItem )
	{
		std::string caption = args[4].GetString();
		CEGUI::String strUtf32;
		CUIStringSystem::GetMe()->ParserString_Runtime(caption, strUtf32);
		pItem->setText( strUtf32 );
	}
	return 0;
}
INT CtrlList::SetItemData( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	CEGUI::MCLGridRef  grid_ref( args[ 2 ].GetInteger(), args[ 3 ].GetInteger() );
	CEGUI::ListboxItem* pItem = 0;

	unsigned int rowC = ((CEGUI::MultiColumnList*)m_pWindow)->getRowCount();
	unsigned int columC = ((CEGUI::MultiColumnList*)m_pWindow)->getColumnCount();
	if(grid_ref.row < rowC && grid_ref.column < columC)
	{
		pItem = ((CEGUI::MultiColumnList*)m_pWindow)->getItemAtGridReference( grid_ref );
	}
	if( pItem )
	{
	}
	return 0;
}
INT CtrlList::DeleteItem( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	((CEGUI::MultiColumnList*)m_pWindow)->removeRow( args[ 2 ].GetInteger() );
	return 0;
}
INT CtrlList::RemoveAllItem( LuaPlus::LuaState* pState )
{
	((CEGUI::MultiColumnList*)m_pWindow)->resetList();
	return 0;
}
// CYS-MTSWEEP 19/09: `NewBangHui_Xuanzhan.lua:182` goi `GetItemText(Index, 0)` tren
// `NewBangHui_Xuanzhan_Xuanfu` = `TLBB_ComboList` -> `Falagard/Combobox` (nhanh lien may chu, g_IsAcrossServer==1).
// Ban dang ky duy nhat cua ten nay la ban MultiColumnList => `getRowCount()` doc `d_grid` o offset cua
// MultiColumnList tren mot Combobox. Sua: phan phoi theo kieu THAT; Combobox/Listbox lay muc theo chi so.
INT CtrlList::GetItemText( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	CEGUI::ListboxItem* pItem = 0;

	if (CEGUI::MultiColumnList* pGrid = dynamic_cast<CEGUI::MultiColumnList*>(m_pWindow))
	{
		CEGUI::MCLGridRef grid_ref( args[ 2 ].GetInteger(), args[ 3 ].GetInteger() );
		if (grid_ref.row < pGrid->getRowCount() && grid_ref.column < pGrid->getColumnCount())
			pItem = pGrid->getItemAtGridReference( grid_ref );
	}
	else if (CEGUI::Combobox* pCombo = dynamic_cast<CEGUI::Combobox*>(m_pWindow))
	{
		const INT index = args[2].IsNumber() ? (INT)args[2].GetNumber() : -1;
		if (index >= 0 && (size_t)index < pCombo->getItemCount()) pItem = pCombo->getListboxItemFromIndex((size_t)index);
	}
	else if (CEGUI::Listbox* pListbox = dynamic_cast<CEGUI::Listbox*>(m_pWindow))
	{
		const INT index = args[2].IsNumber() ? (INT)args[2].GetNumber() : -1;
		if (index >= 0 && (size_t)index < pListbox->getItemCount()) pItem = pListbox->getListboxItemFromIndex((size_t)index);
	}

	if( pItem )
	{
		std::string strUtf8 = pItem->getText().c_str();//utf::mbcs_to_utf8(strMbcs);
		std::string strMbcs;
		CUIStringSystem::utf8_to_mbcs(strUtf8, strMbcs);
		pState->PushString( strMbcs.c_str() );
	}
	// CYS-MTSWEEP: KHONG doi nhanh "khong tim thay muc". Ban goc `return 1` ma khong day gi len ngan xep, nen
	// Lua nhan lai chinh doi so cuoi. Day la mot loi RIENG (ngan xep khong can) - da ghi vao handoff, khong sua
	// o day de ban va dung bang dung pham vi loi ep kieu mu.
	return 1;
}
INT CtrlList::GetItemCount( LuaPlus::LuaState* pState )
{
	pState->PushInteger( ((CEGUI::MultiColumnList*)m_pWindow)->getRowCount() );
	return 1;
}
INT CtrlList::GetColumnCount( LuaPlus::LuaState* pState )
{
	pState->PushInteger( ((CEGUI::MultiColumnList*)m_pWindow)->getColumnCount() );
	return 1;
}
INT CtrlList::GetSelectItem( LuaPlus::LuaState* pState )
{
	CEGUI::MultiColumnList* list = dynamic_cast<CEGUI::MultiColumnList*>(m_pWindow);
	CEGUI::ListboxItem* item = list ? list->getFirstSelectedItem() : 0;
	// AddNewItem assigns a cell/column ID; CY callers require the selected row.
	pState->PushInteger(item ? int(list->getItemRowIndex(item)) : -1);
	return 1;
}

INT CtrlList::SetSelectItem(LuaPlus::LuaState* pState)
{
	LuaStack args(pState);
	CEGUI::MultiColumnList* list = dynamic_cast<CEGUI::MultiColumnList*>(m_pWindow);
	if (!list || !args[2].IsNumber()) return 0;
	const int row = int(args[2].GetNumber());
	if (row < 0) { list->clearAllSelections(); return 0; }
	if (unsigned(row) < list->getRowCount() && list->getColumnCount())
		list->setItemSelectState(CEGUI::MCLGridRef(unsigned(row), 0), true);
	return 0;
}

LuaPlus::LuaObject* SoftKeyWindow::s_pMetaTable = NULL;

INT SoftKeyWindow::SetAimEditBox( LuaPlus::LuaState* pState)
{
	LuaStack args(pState);
	if( !args[ 2 ].IsString() ) return 0;
	CEGUI::IFalagardSoftKeyBoard * pWindow= (CEGUI::IFalagardSoftKeyBoard *)(CEGUI::FalagardSoftKeyBoard*)m_pWindow;
	pWindow->SetActiveEditBox( (CEGUI::String)( CEGUI::utf8*)(args[2].GetString()) );
	return 0;
}

LuaPlus::LuaObject* AnimateWindow::s_pMetaTable = NULL;

INT AnimateWindow::Play( LuaPlus::LuaState* pState)
{
	// CYS: image and button controls have different multiple-inheritance offsets.
    CEGUI::IFalagardAnimate* pWindow = dynamic_cast<CEGUI::IFalagardAnimate*>(m_pWindow);
    if (!pWindow) TDThrow("Play requires an animation control.");
	LuaStack args(pState);
	pWindow->Play( args[ 2 ].GetBoolean() );
	return 0;
}
} // end namespace

#include <CEGUIExceptions.h>
namespace LUA_CONTROL
{
//-------------------------------------------------------------------------------------------------------------
// CYS-HUD: GL Lua controls. Text arguments are UTF-8 (System_CodePage=65001) and go through ParserString_Runtime
// like ListBox::AddItem; numbers are read leniently (integer or number).
namespace
{
	FLOAT luaNumber(LuaPlus::LuaStackObject& o, FLOAT fallback)
	{
		if (o.IsNumber()) return (FLOAT)o.GetNumber();
		if (o.IsString()) return (FLOAT)atof(o.GetString());
		return fallback;
	}
	INT luaInt(LuaPlus::LuaStackObject& o, INT fallback)
	{
		if (o.IsNumber()) return (INT)o.GetNumber();
		if (o.IsString()) return atoi(o.GetString());
		return fallback;
	}
	CEGUI::String luaText(LuaPlus::LuaStackObject& o)
	{
		CEGUI::String out;
		if (o.IsString())
		{
			std::string mbcs = o.GetString();
			CUIStringSystem::GetMe()->ParserString_Runtime(mbcs, out);
		}
		return out;
	}
}

INT PushWindowControl( LuaPlus::LuaState* pState, CEGUI::Window* pWindow )
{
	if (!pWindow) { pState->PushNil(); return 1; }
	CUIWindowItem* pItem = (CUIWindowItem*)pWindow->getUserData();
	if (!pItem) { pState->PushNil(); return 1; }
	LuaPlus::LuaObject obj = pItem->GetControlObject(pWindow);
	obj.PushStack();
	return 1;
}

INT Window::SetEvent( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	if (!args[2].IsString() || !args[3].IsString()) return 0;
	try
	{
		m_pWindow->subscribeEvent((CEGUI::utf8*)args[2].GetString(), CEGUI::ScriptFunctor((CEGUI::utf8*)args[3].GetString()));
		m_pWindow->cysRecordScriptedEvent((CEGUI::utf8*)args[2].GetString(), (CEGUI::utf8*)args[3].GetString());
	}
	catch (CEGUI::Exception& e)
	{
		CEGUI::Logger::getSingleton().logEvent("SetEvent '" + m_pWindow->getName() + "': " + e.getMessage(), CEGUI::Errors);
	}
	return 0;
}

// ---- NotSuperList
INT NotSuperListLuaWindow::AddChild( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	if (!args[2].IsString()) { pState->PushNil(); return 1; }
	CEGUI::Window* pItem = ((CEGUI::FalagardNotSuperList*)m_pWindow)->AddChild((CEGUI::utf8*)args[2].GetString());
	return PushWindowControl(pState, pItem);
}
// CYS-MTSWEEP 19/09: `ScrollInfo.lua:35,44` goi `ScrollInfo_Frame:Clear()` tren mot `Falagard/ScrollInfo`
// (canh 303-306). Ban dang ky duy nhat cua ten `Clear` la ban NotSuperList, nen ban cu doc `d_items` (mot
// std::vector) o offset cua NotSuperList tren mot doi tuong ScrollInfo => so phan tu rac => `GetListItem(i)`
// truot khoi vung nho. Ngu nghia dung cho ScrollInfo la `ResetIt()` (giong `ClearInfo`).
INT NotSuperListLuaWindow::Clear( LuaPlus::LuaState* pState )
{
	if (CEGUI::FalagardNotSuperList* pList = dynamic_cast<CEGUI::FalagardNotSuperList*>(m_pWindow))
	{
		CUIWindowItem* pItem = (CUIWindowItem*)m_pWindow->getUserData();
		if (pItem)
			for (size_t i = 0; i < pList->GetListSize(); ++i) pItem->ReleaseControlObject(pList->GetListItem(i));
		pList->Clear();
		return 0;
	}
	if (CEGUI::FalagardScrollInfo* pInfo = dynamic_cast<CEGUI::FalagardScrollInfo*>(m_pWindow))
	{
		pInfo->ResetIt();
		return 0;
	}
	return 0;
}
INT NotSuperListLuaWindow::GetListItemAt( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	INT index = luaInt(args[2], -1);
	if (index < 0) { pState->PushNil(); return 1; }
	return PushWindowControl(pState, ((CEGUI::FalagardNotSuperList*)m_pWindow)->GetListItem((size_t)index));
}
INT NotSuperListLuaWindow::GetListItemCount( LuaPlus::LuaState* pState )
{
	pState->PushInteger((INT)((CEGUI::FalagardNotSuperList*)m_pWindow)->GetListSize());
	return 1;
}
// CYS-MTSWEEP 19/09: `GetSelected` bi dang ky HAI lan (ban nay va ban NotSuperListItem o muc 26). Ca hai nay
// deu dieu huong theo kieu THAT, giong het nhau, nen ban nao thang cung khong doi hanh vi.
INT NotSuperListLuaWindow::GetSelected( LuaPlus::LuaState* pState )
{
	if (CEGUI::FalagardNotSuperList* pList = dynamic_cast<CEGUI::FalagardNotSuperList*>(m_pWindow))
		return PushWindowControl(pState, pList->GetSelected());
	if (CEGUI::FalagardNotSuperListItem* pItem = dynamic_cast<CEGUI::FalagardNotSuperListItem*>(m_pWindow))
	{
		pState->PushBoolean(pItem->getSelected());
		return 1;
	}
	pState->PushNil();
	return 1;
}
// CYS-QLOG 19/09: SUA LOI CHET TIEN TRINH khi bam `Q` (khung Nhiem vu). MOI dieu khien dung CHUNG mot metatable
// (RegisterMetaTable: `*X::s_pMetaTable = *Window::s_pMetaTable`), nen `QuestLog_Desc:SetScrollPosition()` cua
// CY (QuestLog.lua:1464) roi vao dung ban NotSuperList nay. `QuestLog_Desc` la `TLBB_ComplexWindow`
// (FalagardComplexWindow), khong phai NotSuperList: ep kieu C tho doc `d_vertScrollbar` o offset 0x690, ma o do
// FalagardComplexWindow giu `d_ActionButtonSize` = Size(35,35) theo look (`TLBBLook_ComplexWindow.looknfeel.xml:55`
// `w:35 h:35`) = 0x420C0000420C0000. Gia tri do khac 0 nen qua duoc `if (d_vertScrollbar)`, roi
// `Scrollbar::setScrollPosition` doc `[rcx+0x698]` tai mot dia chi KHONG CHINH TAC => #GP, Windows bao
// ACCESS_VIOLATION voi dia chi 0xFFFFFFFFFFFFFFFF (bao cao cu in `%08X` nen chi thay `0xFFFFFFFF`).
// Bang chung: minidump `Build\Logs\2026-09-17-host-2\live-{12,14,17}\tmp\dmp104.tmp` - RIP = CEGUIBase.dll+0xCE55E
// = `Scrollbar::setScrollPosition` (CEGUIScrollbar.cpp:175), rcx = 0x420C0000420C0000, xmm1 = 0.0f.
// Cach sua: KHONG bao gio ep kieu mu nua - phan phoi theo kieu THAT cua cua so; kieu nao khong co thanh cuon cua
// ta thi khong lam gi. Tham so vang (CY goi khong doi so = "giu nguyen vi tri") => giu vi tri hien tai.
INT NotSuperListLuaWindow::SetScrollPosition( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	if (CEGUI::FalagardNotSuperList* pList = dynamic_cast<CEGUI::FalagardNotSuperList*>(m_pWindow))
	{
		pList->SetVertScrollbarPosition(luaNumber(args[2], 0.0f));
		return 0;
	}
	// Cac nhanh duoi day la duong tung lam chet tien trinh; giu mot dong ve de lan sau khong phai doan.
	char qlogLine[224] = {0};
	const CEGUI::String qlogName = m_pWindow ? m_pWindow->getName() : CEGUI::String((CEGUI::utf8*)"?");
	if (CEGUI::FalagardComplexWindow* pComplex = dynamic_cast<CEGUI::FalagardComplexWindow*>(m_pWindow))
	{
		const float pos = luaNumber(args[2], pComplex->GetVertScrollbarPosition());
		pComplex->SetVertScrollbarPosition(pos);
		_snprintf(qlogLine, sizeof(qlogLine) - 1, "CYS-QLOG: SetScrollPosition %s -> ComplexWindow pos=%.1f", qlogName.c_str(), pos);
	}
	else if (CEGUI::FalagardAchievementWindow* pAchv = dynamic_cast<CEGUI::FalagardAchievementWindow*>(m_pWindow))
	{
		pAchv->SetVertScrollbarPosition(luaNumber(args[2], pAchv->GetVertScrollbarPosition()));
		_snprintf(qlogLine, sizeof(qlogLine) - 1, "CYS-QLOG: SetScrollPosition %s -> AchievementWindow", qlogName.c_str());
	}
	else
	{
		_snprintf(qlogLine, sizeof(qlogLine) - 1, "CYS-QLOG: SetScrollPosition %s -> khung khong co thanh cuon cua ta, bo qua", qlogName.c_str());
	}
	CEGUI::Logger::getSingleton().logEvent((const CEGUI::utf8*)qlogLine);
	return 0;
}
INT NotSuperListLuaWindow::GetScrollPosition( LuaPlus::LuaState* pState )
{
	// CYS-QLOG 19/09: cung ly do nhu SetScrollPosition - khong ep kieu mu.
	if (CEGUI::FalagardNotSuperList* pList = dynamic_cast<CEGUI::FalagardNotSuperList*>(m_pWindow))
		pState->PushNumber(pList->GetVertScrollbarPosition());
	else if (CEGUI::FalagardComplexWindow* pComplex = dynamic_cast<CEGUI::FalagardComplexWindow*>(m_pWindow))
		pState->PushNumber(pComplex->GetVertScrollbarPosition());
	else if (CEGUI::FalagardAchievementWindow* pAchv = dynamic_cast<CEGUI::FalagardAchievementWindow*>(m_pWindow))
		pState->PushNumber(pAchv->GetVertScrollbarPosition());
	else
		pState->PushNumber(0.0f);
	return 1;
}
INT NotSuperListLuaWindow::RefreshLayout( LuaPlus::LuaState* pState )
{
	((CEGUI::FalagardNotSuperList*)m_pWindow)->RefreshLayout();
	return 0;
}
INT NotSuperListLuaWindow::SetScrollPosition4Index( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	INT index = luaInt(args[2], -1);
	// CYS-QLOG 19/09: chi NotSuperList moi co phep nay; cua so kieu khac thi bo qua (xem SetScrollPosition).
	CEGUI::FalagardNotSuperList* pList = dynamic_cast<CEGUI::FalagardNotSuperList*>(m_pWindow);
	if (pList && index >= 0) pList->SetVertScrollbarPosition4Index((size_t)index);
	return 0;
}

// ---- NotSuperListItem
INT NotSuperListItemLuaWindow::GetSubItem( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	if (!args[2].IsString()) { pState->PushNil(); return 1; }
	CEGUI::String mapped = ((CEGUI::FalagardNotSuperListItem*)m_pWindow)->MapChildName((CEGUI::utf8*)args[2].GetString());
	if (mapped.empty()) { pState->PushNil(); return 1; }
	return PushWindowControl(pState, CEGUI::WindowManager::getSingleton().getWindow(mapped));
}
INT NotSuperListItemLuaWindow::SetSubItemEvent( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	if (!args[2].IsString() || !args[3].IsString() || !args[4].IsString()) return 0;
	((CEGUI::FalagardNotSuperListItem*)m_pWindow)->SetChildItemEvent((CEGUI::utf8*)args[2].GetString(),
		(CEGUI::utf8*)args[3].GetString(), (CEGUI::utf8*)args[4].GetString());
	return 0;
}
// CYS-MTSWEEP 19/09 (cung LOP loi voi QuestLog `SetScrollPosition`, xem Timeline\handoff\qlog-crash.md muc 3.1):
// `SetSelected` la ban dang ky DUY NHAT mang ten do, ma metatable la dung chung, nen no nhan MOI cua so.
// Do thuc te tren 2.043 tep Lua + 2.032 layout: 84 cua so goi `SetSelected` KHONG phai NotSuperListItem -
//   * 82 `Falagard/IMEEditBox` + 1 `Falagard/MultiIMEEditBox`: `edit:SetSelected(0, -1)` ngay sau `SetText` -
//     day la ngu nghia CY cua Editbox = `setSelection(start, end)` (chon chu de go de len). Ban cu ep kieu mu
//     thanh `FalagardNotSuperListItem*` roi GHI `d_selected` - mot phep GHI vao than mot doi tuong khac lop.
//   * 1 `Falagard/NotSuperList` (`WuLin_ListDown_LeftList:SetSelected(nType+1)`): ngu nghia CY la chon theo
//     CHI SO (1-based; xem chinh WuLin_List.lua:196 `SetSelected(index+1)` bi chu thich).
// Cach sua giong het `qlog-crash`: khong bao gio ep kieu mu, phan phoi theo kieu THAT.
INT NotSuperListItemLuaWindow::SetSelected( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	// 1. Phan tu that cua NotSuperList -> hanh vi cu, nay da duoc kiem kieu.
	if (CEGUI::FalagardNotSuperListItem* pItem = dynamic_cast<CEGUI::FalagardNotSuperListItem*>(m_pWindow))
	{
		const bool selected = args[2].IsBoolean() ? args[2].GetBoolean() : luaInt(args[2], 1) != 0;
		CEGUI::Window* pParent = m_pWindow->getParent();
		while (pParent && !pParent->testClassName("FalagardNotSuperList")) pParent = pParent->getParent();
		if (CEGUI::FalagardNotSuperList* pOwner = dynamic_cast<CEGUI::FalagardNotSuperList*>(pParent))
			pOwner->SetSelected(m_pWindow, selected);
		else
			pItem->setSelected(selected);
		return 0;
	}
	// 2. Chinh danh sach -> chon theo chi so 1-based (CY).
	if (CEGUI::FalagardNotSuperList* pList = dynamic_cast<CEGUI::FalagardNotSuperList*>(m_pWindow))
	{
		const INT index1 = luaInt(args[2], 0);
		pList->cleanSelect();
		if (index1 >= 1 && (size_t)(index1 - 1) < pList->GetListSize())
			pList->SetSelected(pList->GetListItem((size_t)(index1 - 1)), true);
		return 0;
	}
	// 3. O nhap chu -> ngu nghia CY `setSelection(start, end)`; -1 = het chuoi (CEGUI tu ket).
	{
		const size_t whole = (std::numeric_limits<size_t>::max)();
		const INT startI = luaInt(args[2], 0);
		const INT endI   = luaInt(args[3], -1);
		const size_t start = startI < 0 ? whole : (size_t)startI;
		const size_t end   = endI   < 0 ? whole : (size_t)endI;
		if (CEGUI::Editbox* pEdit = dynamic_cast<CEGUI::Editbox*>(m_pWindow))
		{
			pEdit->setSelection(start, end);
			return 0;
		}
		if (CEGUI::MultiLineEditbox* pMulti = dynamic_cast<CEGUI::MultiLineEditbox*>(m_pWindow))
		{
			pMulti->setSelection(start, end);
			return 0;
		}
	}
	return 0;
}
// CYS-MTSWEEP 19/09: `GetSelected` la MOT trong HAI ten bi dang ky hai lan trong ca bang
// (`NotSuperListLuaWindow::GetSelected` roi `NotSuperListItemLuaWindow::GetSelected`), nen ban ITEM nuot luon
// ban LIST. Hien khong tep .lua nao goi no => min dang nam im; van sua vi gia re va dung khuon.
INT NotSuperListItemLuaWindow::GetSelected( LuaPlus::LuaState* pState )
{
	if (CEGUI::FalagardNotSuperListItem* pItem = dynamic_cast<CEGUI::FalagardNotSuperListItem*>(m_pWindow))
	{
		pState->PushBoolean(pItem->getSelected());
		return 1;
	}
	if (CEGUI::FalagardNotSuperList* pList = dynamic_cast<CEGUI::FalagardNotSuperList*>(m_pWindow))
		return PushWindowControl(pState, pList->GetSelected());   // ngu nghia cua ban LIST: tra ve phan tu dang chon
	pState->PushNil();
	return 1;
}

// ---- ListBoxEx
INT ListBoxEx::AddItemEx( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	if (!args[2].IsString()) return 0;
	CEGUI::colour col(1.0f, 1.0f, 1.0f);
	if (args[5].IsString()) col = CEGUI::PropertyHelper::stringToColour((CEGUI::utf8*)args[5].GetString());
	((CEGUI::FalagardListBoxEx*)m_pWindow)->AddItemEx(luaText(args[2]), (CEGUI::uint)luaInt(args[3], 0), luaInt(args[4], 0), col, luaInt(args[6], 0));
	return 0;
}
INT ListBoxEx::AddFriendItemExWithoutLayout( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	if (!args[2].IsString()) return 0;
	CEGUI::colour col(1.0f, 1.0f, 1.0f);
	if (args[5].IsString()) col = CEGUI::PropertyHelper::stringToColour((CEGUI::utf8*)args[5].GetString());
	CEGUI::String face = args[7].IsString() ? CEGUI::String((CEGUI::utf8*)args[7].GetString()) : CEGUI::String("");
	((CEGUI::FalagardListBoxEx*)m_pWindow)->AddItemEx(luaText(args[2]), (CEGUI::uint)luaInt(args[3], 0), luaInt(args[4], 0), col, luaInt(args[6], 0), face);
	return 0;
}
INT ListBoxEx::DelItemEx( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	INT index = luaInt(args[2], -1);
	CEGUI::FalagardListBoxEx* pList = (CEGUI::FalagardListBoxEx*)m_pWindow;
	if (index >= 0 && (size_t)index < pList->getItemCount()) pList->RemoveItemEx(pList->getListboxItemFromIndex((size_t)index));
	return 0;
}
INT ListBoxEx::ClearListBoxEx( LuaPlus::LuaState* pState )
{
	((CEGUI::FalagardListBoxEx*)m_pWindow)->ResetListEx();
	return 0;
}
INT ListBoxEx::RequestLayout( LuaPlus::LuaState* pState )
{
	((CEGUI::FalagardListBoxEx*)m_pWindow)->RequestLayOut();
	return 0;
}
INT ListBoxEx::GetClickedButtonItem( LuaPlus::LuaState* pState )
{
	pState->PushInteger(((CEGUI::FalagardListBoxEx*)m_pWindow)->GetClickedButtonItem());
	return 1;
}
INT ListBoxEx::SetVScrollbarAlpha( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	((CEGUI::FalagardListBoxEx*)m_pWindow)->SetVScrollbarAlpha(luaNumber(args[2], 1.0f));
	return 0;
}
INT ListBoxEx::GetItemNumByMissionId( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	pState->PushInteger(((CEGUI::FalagardListBoxEx*)m_pWindow)->GetItemNumByMissionId((CEGUI::uint)luaInt(args[2], 0)));
	return 1;
}

// ---- ScrollInfo
INT ScrollInfo::SetScrollInfo( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	if (!args[2].IsString()) return 0;
	CEGUI::FalagardScrollInfo* pInfo = (CEGUI::FalagardScrollInfo*)m_pWindow;
	if (args[3].IsBoolean() ? args[3].GetBoolean() : luaInt(args[3], 0) != 0) pInfo->setWaitingInfoFirst(luaText(args[2]));
	else pInfo->setWaitingInfo(luaText(args[2]));
	return 0;
}
INT ScrollInfo::ClearInfo( LuaPlus::LuaState* pState )
{
	((CEGUI::FalagardScrollInfo*)m_pWindow)->ResetIt();
	return 0;
}

// ---- AchievementWindow
INT AchievementWindow::CleanAllElement( LuaPlus::LuaState* pState )
{
	CUIWindowItem* pItem = (CUIWindowItem*)m_pWindow->getUserData();
	CEGUI::FalagardAchievementWindow* pWnd = (CEGUI::FalagardAchievementWindow*)m_pWindow;
	if (pItem)
		for (size_t i = 0; i < pWnd->getItemCount(); ++i) pItem->ReleaseControlObject(pWnd->getItemWindow(i));
	pWnd->ClearAllElement();
	return 0;
}
INT AchievementWindow::AddChildElement( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	if (!args[2].IsString()) { pState->PushNil(); return 1; }
	return PushWindowControl(pState, ((CEGUI::FalagardAchievementWindow*)m_pWindow)->AddChildElement((CEGUI::utf8*)args[2].GetString()));
}
INT AchievementWindow::GetVertScrollbarPosition( LuaPlus::LuaState* pState )
{
	pState->PushNumber(((CEGUI::FalagardAchievementWindow*)m_pWindow)->GetVertScrollbarPosition());
	return 1;
}
INT AchievementWindow::SetVertScrollbarPosition( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	((CEGUI::FalagardAchievementWindow*)m_pWindow)->SetVertScrollbarPosition(luaNumber(args[2], 0.0f));
	return 0;
}
INT AchievementWindow::SetVertScrollbarHide( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	((CEGUI::FalagardAchievementWindow*)m_pWindow)->SetVertScrollbarHide(args[2].IsBoolean() ? args[2].GetBoolean() : luaInt(args[2], 1) != 0);
	return 0;
}
INT AchievementWindow::SetElementsInView( LuaPlus::LuaState* pState )
{
	LuaStack args(pState);
	INT index = luaInt(args[2], -1);
	if (index >= 0) ((CEGUI::FalagardAchievementWindow*)m_pWindow)->SetElementsInView((size_t)index);
	return 0;
}

// ---- Effect (Falagard/PS)
INT EffectWindow::playEffect( LuaPlus::LuaState* pState )
{
	((CEGUI::FalagardParticleSystem*)m_pWindow)->play();
	return 0;
}
INT EffectWindow::replayEffect( LuaPlus::LuaState* pState )
{
	((CEGUI::FalagardParticleSystem*)m_pWindow)->rePlay();
	return 0;
}
}
