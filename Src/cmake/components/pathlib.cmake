# CYS component: PathLib.dll — clean-room reimplementation of the navmesh path-finding DLL
# (no surviving source). Produces PathLib.dll with the same exported factory API that
# Render.dll (client_GL) and the 0.85 x64 Game.exe import. Self-contained: depends only on
# the C++ runtime and Win32 (DllMain). Global flags (C++14, /MD, /source-charset:utf-8
# /execution-charset:.936) come from CYSCommon.cmake.
set(_cys_pl "${CYS_SRC}/Engine/PathLib")
add_library(cys_pathlib SHARED
    "${_cys_pl}/NavMesh.cpp"
    "${_cys_pl}/PathDataImpl.cpp"
    "${_cys_pl}/PathFinderImpl.cpp"
    "${_cys_pl}/BuildingCollisionImpl.cpp"
    "${_cys_pl}/PathLibRoot.cpp")
target_include_directories(cys_pathlib PUBLIC "${_cys_pl}")
target_compile_definitions(cys_pathlib PRIVATE PATHLIB_EXPORTS)
set_target_properties(cys_pathlib PROPERTIES OUTPUT_NAME PathLib FOLDER Engine)
message(STATUS "CYS: PathLib -> PathLib.dll (${CYS_ARCH})")
