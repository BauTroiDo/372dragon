# CYS component: CysPostFxTest.exe (Src/Tools/CysPostFxTest) - test of the CY-Source post-processing framework
# (Src/Engine/WXCore/CYS/PostFX, Docs/specs/render/02-postfx.md): client_GL LogicModels on a lit ground plane, every
# post filter off/on through WX::PostFilterManager, back-buffer PNGs and GPU-synchronised frame times.
#   bin\CysPostFxTest.exe [--data DIR] [--out DIR] [--cases a,b,...] [--bench N] [--list]
# Needs the components zlib .. wxcore in the same build tree. RenderSystem_Direct3D9.dll, Plugin_ParticleFX2.dll and
# Plugin_Scorpio.dll are loaded by name at run time from the exe folder, so they are build dependencies here.
# The WXRender runtime material system (materials agent) is compiled in, as in ogre_smoke.cmake, so the client_GL
# templates render the way Render.dll does.
if(NOT TARGET cys_wxcore OR NOT TARGET OgreMain)
    message(WARNING "CYS: postfx_test needs the ogremain and wxcore components in the same tree - skipped")
    return()
endif()

set(_cys_pft "${CYS_SRC}/Tools/CysPostFxTest")
# CYS fx-render 2026-09-13: the post-processing sources are part of WXCore now (CYS/PostFX/*.cpp, globbed by
# wxcore.cmake); the test links them from cys_wxcore like the game and the viewer.

add_executable(CysPostFxTest
    "${_cys_pft}/PostFxTestMain.cpp"
    "${CYS_SRC}/Engine/WXRender/MaterialSystem/CysMaterialSystem.cpp")
target_include_directories(CysPostFxTest PRIVATE "${_cys_pft}" "${CYS_SRC}/Engine/WXRender")
target_compile_definitions(CysPostFxTest PRIVATE _CONSOLE NOMINMAX WIN32_LEAN_AND_MEAN CYS_WXRENDER_MATERIAL_SYSTEM=1)
target_link_libraries(CysPostFxTest PRIVATE cys_wxcore dbghelp)
if(TARGET cys_zlib)
    target_link_libraries(CysPostFxTest PRIVATE cys_zlib)
endif()
if(TARGET cys_d3dx9)
    target_link_libraries(CysPostFxTest PRIVATE cys_d3dx9)
else()
    target_link_libraries(CysPostFxTest PRIVATE d3d9 "${CYS_DX_LIB}/d3dx9.lib" legacy_stdio_definitions)
endif()
foreach(_cys_pft_rt RenderSystem_Direct3D9 Plugin_CgProgramManager cys_particlefx2 cys_scorpio)
    if(TARGET ${_cys_pft_rt})
        add_dependencies(CysPostFxTest ${_cys_pft_rt})
    endif()
endforeach()
if(MSVC)
    target_compile_options(CysPostFxTest PRIVATE /bigobj)
endif()
set_target_properties(CysPostFxTest PROPERTIES FOLDER Tools)
