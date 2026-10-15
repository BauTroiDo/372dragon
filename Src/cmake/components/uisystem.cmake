# CYS component: CEGUISystem -> UI_CEGUI.dll, the tEngine "UI" plugin (CUISystem: CEGUI + OgreCEGUIRenderer + the
# LuaPlus script bridge, window manager, icons, creature boards, UI strings / #{KEY} resolver). Game.exe loads it with
# tKernel::LoadPlugin("UI_CEGUI.dll") and calls DllInit/DllRelease (TDKernel.cpp:175-176); CEGUISystem.def exports
# DllInit, DllMagicCode, DllRelease (the modern client's UI_CEGUI.dll exports exactly these three).
# Old project: Client/CEGUISystem/CEGUISystem.vcxproj (11 sources, MultiByte, UI_CEGUI_EXPORTS; linked Main.lib
# (OgreMain), WXCore.lib, WXEngine.lib, UIBase.lib (CEGUIBase), LuaPlus.lib and the static CEGUIOgreRenderer).
# From WXCore it only needs utf::* (UIString.cpp -> "Core/utf.h"); Core/utf.cpp is compiled in instead of linking the
# whole cys_wxcore (whose PUBLIC/INTERFACE deps would drag Scorpio/Opcode/tinyxml into the UI plugin).
# CEGUIFalagard is not linked: UI_CEGUI drives the TLBB widgets through the IFalagard* interfaces (virtual calls),
# like the modern client (its UI_CEGUI.dll imports CEGUIBase, CEGUIOgreRenderer, LuaPlus, OgreMain, tEngine only).
# Needs the cegui, falagardex (headers) and luaplus components plus wxengine and ogremain (or CYS_OGRE_LIB_DIR).
set(_cys_uis "${CYS_SRC}/Client/CEGUISystem")
add_library(cys_uisystem SHARED
    "${_cys_uis}/stdafx.cpp"
    "${_cys_uis}/CysUiEdit.cpp"
    "${_cys_uis}/UICreatureBoard.cpp"
    "${_cys_uis}/UICreatureBoardSystem.cpp"
    "${_cys_uis}/UIGlobal.cpp"
    "${_cys_uis}/UIIconsMng.cpp"
    "${_cys_uis}/UILuaControl.cpp"
    "${_cys_uis}/UIScript.cpp"
    "${_cys_uis}/UIString.cpp"
    "${_cys_uis}/UISystem.cpp"
    "${_cys_uis}/UIWindowMng.cpp"
    "${_cys_uis}/UI_CEGUI.cpp"
    "${CYS_SRC}/Engine/WXCore/Core/utf.cpp"
    "${_cys_uis}/CEGUISystem.def")
# "..\WxRender\RenderSystem.h" (UISystem.cpp:27) resolves through Engine/Interface (cys_wxengine) -> Engine/WXRender.
target_include_directories(cys_uisystem PRIVATE
    "${_cys_uis}"
    "${CYS_SRC}/Client/CEGUIFalagardEx"
    "${CYS_TP}/CEGUI-0.4.1/CEGUI/WidgetSets/Falagard/include"
    "${CYS_SRC}/Engine/WXCore")
target_compile_definitions(cys_uisystem PRIVATE _USRDLL UI_CEGUI_EXPORTS _MBCS)
# CYS-HUD: the GL Lua controls (NotSuperList, ListBoxEx, ScrollInfo, AchievementWindow, PS) call the concrete widget
# classes exported by CEGUIFalagard.dll, so UI_CEGUI now imports it. (client_GL's UI_CEGUI.dll reaches its widgets
# through interfaces and does not import CEGUIFalagard.dll; both DLLs sit in Bin64 either way.)
target_link_libraries(cys_uisystem PRIVATE
    cys_ceguibase cys_ceguifalagard cys_ceguiogrerenderer cys_luaplus cys_wxengine cys_wx_ogre cys_wx_boost
    imm32 shlwapi user32 gdi32 winmm)
if(MSVC)
    target_compile_options(cys_uisystem PRIVATE /w14311 /w14312 /w14302)
endif()
set_target_properties(cys_uisystem PROPERTIES OUTPUT_NAME UI_CEGUI PREFIX "" FOLDER Client)
