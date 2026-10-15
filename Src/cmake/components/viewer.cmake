# CYS component: TlbbViewer.exe - Win32 x64 viewer for client_GL assets on OgreMain + RenderSystem_Direct3D9 +
# WXCore (no game layer): LogicModel from all.obj (+ animation / skill), effects from all.effect, .Scene files,
# orbit camera, and fixed-time-step back-buffer screenshots for the oracle tests (Docs/07 section 2).
#
# Needs the components zlib .. wxcore in the same build tree. RenderSystem_Direct3D9.dll, Plugin_ParticleFX2.dll and
# Plugin_Scorpio.dll are loaded by name at run time from the exe folder, so they are build dependencies here.
# Sources: Src/Tools/TlbbViewer. Run with --help for the command line.
if(NOT TARGET cys_wxcore OR NOT TARGET OgreMain)
    message(WARNING "CYS: viewer needs the ogremain and wxcore components in the same tree - skipped")
    return()
endif()

set(_cys_vw "${CYS_SRC}/Tools/TlbbViewer")
# CYS 2026-09-12: the WXRender runtime material system (vertex-program pairing for the ps_3_0-only client_GL
# templates, runtime variants, shader microcode cache) is compiled in as in ogre_smoke.cmake; without it client_GL
# models render as white silhouettes (Docs/08 muc 3.11). Only its own folder is added to the include path.
set(_cys_vw_ms "${CYS_SRC}/Engine/WXRender/MaterialSystem")
add_executable(TlbbViewer
    "${_cys_vw}/ViewerMain.cpp"
    "${_cys_vw}/ViewerApp.cpp"
    "${_cys_vw}/ViewerApp.h"
    "${_cys_vw}/ViewerOptions.cpp"
    "${_cys_vw}/ViewerOptions.h"
    "${_cys_vw}/ViewerFx.cpp" # CYS fx-audit: --fx-census / --fx-sheet
    "${_cys_vw_ms}/CysMaterialSystem.cpp"
    "${_cys_vw_ms}/CysMaterialSystem.h")
target_include_directories(TlbbViewer PRIVATE "${_cys_vw}" "${_cys_vw_ms}")
target_compile_definitions(TlbbViewer PRIVATE _CONSOLE NOMINMAX WIN32_LEAN_AND_MEAN CYS_WXRENDER_MATERIAL_SYSTEM=1)
target_link_libraries(TlbbViewer PRIVATE cys_wxcore dbghelp)
if(TARGET cys_d3dx9)
    # D3DX9 headers (build-tree shim) + d3d9/d3dx9 libs, shared with RenderSystem_Direct3D9.
    target_link_libraries(TlbbViewer PRIVATE cys_d3dx9)
else()
    target_link_libraries(TlbbViewer PRIVATE d3d9 "${CYS_DX_LIB}/d3dx9.lib" legacy_stdio_definitions)
endif()
foreach(_cys_vw_rt RenderSystem_Direct3D9 Plugin_CgProgramManager cys_particlefx2 cys_scorpio)
    if(TARGET ${_cys_vw_rt})
        add_dependencies(TlbbViewer ${_cys_vw_rt})
    endif()
endforeach()
set_target_properties(TlbbViewer PROPERTIES FOLDER Tools)
