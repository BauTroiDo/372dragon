# Tests/fx: headless parse test of client_GL all.particle / all.effect / all.skill (CYSFxParseTest.exe).
#
# Injected into a build tree without touching Src/CMakeLists.txt (each component file there has one owner):
#   cmake -S Src -B Build/cmake/wxfx-x64 ... -DCMAKE_PROJECT_CYSource_INCLUDE=<CY-Source>/Tests/fx/fx_test.cmake
# CMake includes this file right after project(CYSource); the target is defined once the whole Src/CMakeLists.txt
# has been processed (cys_wxcore exists then). The path is baked into the deferred call because deferred arguments
# are evaluated when the call runs (CMAKE_CURRENT_LIST_DIR is Src by then).
set(_cys_fx_test_targets "${CMAKE_CURRENT_LIST_DIR}/fx_test_targets.cmake")
cmake_language(EVAL CODE
    "cmake_language(DEFER DIRECTORY \"${CMAKE_SOURCE_DIR}\" CALL include \"${_cys_fx_test_targets}\")")
