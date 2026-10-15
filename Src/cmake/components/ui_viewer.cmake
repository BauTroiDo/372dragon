# CYS component: CysUiViewer.exe (target cys_ui_viewer) - x64 UI oracle on our engine: loads the game's CEGUI data
# (WoWLookSkin.scheme.xml, imagesets, looknfeel, fonts) with OgreMain + RenderSystem_Direct3D9 + CEGUIBase +
# CEGUIOgreRenderer, renders any layout (or all 1,214) without game logic to PNG, and reports what fails to load.
# Sources: Src/Tools/CysUiViewer (run with --help). Owner: UI viewer agent.
#
# Needs the components zlib .. ogremain, ogre_d3d9, cegui (+ falagardex for CEGUIFalagard.dll) in the same tree:
#   "zlib;zziplib;freetype;devil;ogremain;ogre_d3d9;ogre_plugins;ogre_platform;opcode;tinyxml;expat;wxengine;
#    cegui;falagardex;luaplus;ui_viewer"
# Run-time only (loaded by name from the exe folder, so build dependencies here): RenderSystem_Direct3D9.dll
# (Root::loadRenderPlugins_D3D9) and CEGUIFalagard.dll (the scheme's <WindowSet>, widget set + CEGUIFalagardEx).
# LuaPlus is not linked (layout events go to a null script module), so its PUBLIC /EHc- does not apply here.
# zlib: PNG writer (the x64 DevIL is built without PNG). windowscodecs/ole32: WIC fallback decoder for jpg/png when
# the engine has no codec for them (DevIL x64 is built with IL_NO_JPG/IL_NO_PNG); --no-wic shows the engine alone.
if(NOT TARGET OgreMain OR NOT TARGET cys_ceguibase OR NOT TARGET cys_ceguiogrerenderer)
    message(WARNING "CYS: ui_viewer needs the ogremain and cegui components in the same tree - skipped")
    return()
endif()

set(_cys_uv "${CYS_SRC}/Tools/CysUiViewer")
add_executable(cys_ui_viewer
    "${_cys_uv}/UiViewerMain.cpp"
    "${_cys_uv}/UiViewerApp.cpp"
    "${_cys_uv}/UiViewerApp.h"
    "${_cys_uv}/UiViewerRender.cpp"
    "${_cys_uv}/UiViewerOptions.cpp"
    "${_cys_uv}/UiViewerOptions.h"
    "${_cys_uv}/UiViewerReport.cpp"
    "${_cys_uv}/UiViewerReport.h"
    "${_cys_uv}/UiViewerText.cpp"
    "${_cys_uv}/UiViewerText.h")
# CYS-INFOLINK: CysInfoLink.h (header only, no CEGUI/Windows dependency) is shared with the game's parser so the
# viewer's markup mirror expands the CY coordinate tags exactly like UIString.cpp does.
target_include_directories(cys_ui_viewer PRIVATE "${_cys_uv}" "${CYS_SRC}/Client/CEGUISystem")
target_compile_definitions(cys_ui_viewer PRIVATE _CONSOLE NOMINMAX WIN32_LEAN_AND_MEAN)
target_link_libraries(cys_ui_viewer PRIVATE
    cys_ceguiogrerenderer cys_ceguibase OgreMain cys_zlib
    d3d9 dbghelp windowscodecs ole32 user32 shlwapi)
foreach(_cys_uv_rt RenderSystem_Direct3D9 cys_ceguifalagard)
    if(TARGET ${_cys_uv_rt})
        add_dependencies(cys_ui_viewer ${_cys_uv_rt})
    endif()
endforeach()
set_target_properties(cys_ui_viewer PROPERTIES OUTPUT_NAME CysUiViewer FOLDER Tools)
