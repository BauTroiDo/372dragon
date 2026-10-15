# CYS component: CysShadowTest.exe (Src/Tools/CysShadowTest) - test bench of the cascaded shadow maps of
# Engine/WXCore/CYS/Shadow: client_GL models (Tests/oracle/cases.json) standing on a ground plane under a sun, shadows
# off / on, cascade debug view, atlas dump, GPU timing (D3D9 timestamp queries) and a shimmer test.
#   bin\CysShadowTest.exe --out <dir> [--models M07,M08,...] [--size 4096] [--width 1920 --height 1080] [--show]
# Needs zlib .. wxcore in the same tree. Like OgreSmoke it also compiles the WXRender runtime material system (it only
# needs OgreMain), so the models render with client_GL's templates and receive shadows through B's CalcShadow.inc
# (SHADOWMAP_TYPE 1). RenderSystem_Direct3D9.dll, Plugin_ParticleFX2.dll and Plugin_Scorpio.dll are loaded by name
# from the exe folder, hence the dependencies.
if(NOT TARGET cys_wxcore OR NOT TARGET OgreMain)
    message(WARNING "CYS: shadow_test needs the ogremain and wxcore components in the same tree - skipped")
    return()
endif()

set(_cys_st "${CYS_SRC}/Tools/CysShadowTest")
add_executable(CysShadowTest
    "${_cys_st}/ShadowTest.cpp"
    "${CYS_SRC}/Engine/WXRender/MaterialSystem/CysMaterialSystem.cpp")
target_include_directories(CysShadowTest PRIVATE "${_cys_st}" "${CYS_SRC}/Engine/WXRender")
target_compile_definitions(CysShadowTest PRIVATE
    _CONSOLE NOMINMAX WIN32_LEAN_AND_MEAN CYS_WXRENDER_MATERIAL_SYSTEM=1
    "CYS_SHADOW_MEDIA_DIR=\"${CYS_SRC}/Engine/WXCore/CYS/Shadow/media\""
    "CYS_SHADOW_TEST_MEDIA_DIR=\"${_cys_st}/media\""
    "CYS_ORACLE_CASES=\"${CYS_ROOT}/Tests/oracle/cases.json\"")
target_link_libraries(CysShadowTest PRIVATE cys_wxcore dbghelp)
if(TARGET cys_d3dx9)
    target_link_libraries(CysShadowTest PRIVATE cys_d3dx9) # d3d9 + d3dx9 (PNG writer, queries)
else()
    target_link_libraries(CysShadowTest PRIVATE d3d9 "${CYS_DX_LIB}/d3dx9.lib" legacy_stdio_definitions)
endif()
foreach(_cys_st_rt RenderSystem_Direct3D9 Plugin_CgProgramManager cys_particlefx2 cys_scorpio)
    if(TARGET ${_cys_st_rt})
        add_dependencies(CysShadowTest ${_cys_st_rt})
    endif()
endforeach()
set_target_properties(CysShadowTest PROPERTIES FOLDER Tools)
