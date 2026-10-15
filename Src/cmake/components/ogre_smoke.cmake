# CYS component: OgreSmoke.exe (Src/Tools/OgreSmoke) - x64 smoke test for OgreMain.dll +
# RenderSystem_Direct3D9.dll against client_GL data (read-only). Output: bin/OgreSmoke.exe;
# RenderSystem_Direct3D9.dll is loaded by name from the same bin directory.
#   bin\OgreSmoke.exe --out <dir> [--mesh NAME[+NAME]]... [--list FILE] [--frames 60] [--batch 200]
# CYS 2026-09-12: also compiles the WXRender runtime material system (it only needs OgreMain), so the
# smoke test renders client_GL templates the way Render.dll does (vertex program pairing, variants).
add_executable(OgreSmoke
    "${CYS_SRC}/Tools/OgreSmoke/OgreSmoke.cpp"
    "${CYS_SRC}/Engine/WXRender/MaterialSystem/CysMaterialSystem.cpp")
target_include_directories(OgreSmoke PRIVATE "${CYS_SRC}/Engine/WXRender")
target_compile_definitions(OgreSmoke PRIVATE CYS_WXRENDER_MATERIAL_SYSTEM=1)
target_link_libraries(OgreSmoke PRIVATE OgreMain cys_zlib d3d9 dbghelp) # dbghelp: crash stack + minidump
if(TARGET RenderSystem_Direct3D9)
    add_dependencies(OgreSmoke RenderSystem_Direct3D9) # plugin DLL, loaded at run time
endif()
