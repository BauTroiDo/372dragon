# Tests/scene: CYSSceneTest.exe target (see scene_test.cmake). Needs the wxcore component in the same tree.
if(NOT TARGET cys_wxcore)
    message(WARNING "CYS: Tests/scene needs the wxcore component in the same build tree - skipped")
    return()
endif()

add_executable(CYSSceneTest "${CYS_ROOT}/Tests/scene/scene_test.cpp")
target_compile_definitions(CYSSceneTest PRIVATE _CONSOLE NOMINMAX WIN32_LEAN_AND_MEAN)
target_link_libraries(CYSSceneTest PRIVATE cys_wxcore dbghelp)
if(MSVC)
    target_compile_options(CYSSceneTest PRIVATE /bigobj)
endif()
set_target_properties(CYSSceneTest PROPERTIES FOLDER Tests)
