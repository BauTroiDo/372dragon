# Tests/fx: CYSFxParseTest.exe target (see fx_test.cmake). Needs the wxcore component in the same build tree.
if(NOT TARGET cys_wxcore)
    message(WARNING "CYS: Tests/fx needs the wxcore component in the same build tree - skipped")
    return()
endif()

add_executable(CYSFxParseTest "${CYS_ROOT}/Tests/fx/fx_parse_test.cpp")
target_compile_definitions(CYSFxParseTest PRIVATE _CONSOLE NOMINMAX WIN32_LEAN_AND_MEAN)
target_link_libraries(CYSFxParseTest PRIVATE cys_wxcore)
if(MSVC)
    target_compile_options(CYSFxParseTest PRIVATE /bigobj)
endif()
set_target_properties(CYSFxParseTest PROPERTIES FOLDER Tests)
