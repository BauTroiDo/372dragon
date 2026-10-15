# Tests/scene: headless load test of every scene file of a data folder (CYSSceneTest.exe; CanonicalCY by default).
#
# Injected into a build tree without touching Src/CMakeLists.txt (each component file there has one owner):
#   cmake -S Src -B Build/cmake/scene-x64 ... -DCMAKE_PROJECT_CYSource_INCLUDE=<CY-Source>/Tests/scene/scene_test.cmake
# CMake includes this file right after project(CYSource); the target itself is defined once the whole
# Src/CMakeLists.txt has been processed (cys_wxcore and OgreMain exist then). The path is baked into the deferred
# call because deferred arguments are evaluated when the call runs (CMAKE_CURRENT_LIST_DIR is Src by then).
set(_cys_scene_test_targets "${CMAKE_CURRENT_LIST_DIR}/scene_test_targets.cmake")
cmake_language(EVAL CODE
    "cmake_language(DEFER DIRECTORY \"${CMAKE_SOURCE_DIR}\" CALL include \"${_cys_scene_test_targets}\")")
