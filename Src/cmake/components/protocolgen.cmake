# CYS component: ProtocolGen - C++ codecs for the skynet protocol (every packet and struct of
# Registry/protocol/packets.yaml), GENERATED into Src/Shared/ProtocolGen by Tools/protocol/codegen_cpp.py.
# Never edit the generated files; change the spec / generator / cpp_templates and regenerate.
# Self-contained: no dependency on Src/Shared/Common (the 0.85 net code); ASCII sources, C++14.
# Targets:
#   cys_protocolgen     static library; PUBLIC include dir Src/Shared/ProtocolGen -> #include "ProtocolGen.h"
#   cys_protocol_tests  Tests/protocol/protocol_tests.cpp (capture round trip, oracle corpus, fuzz);
#                       driven by Tests/protocol/run_protocol_tests.py
set(_cys_pg_dir "${CYS_SRC}/Shared/ProtocolGen")
file(GLOB _cys_pg_src CONFIGURE_DEPENDS "${_cys_pg_dir}/*.cpp")
file(GLOB _cys_pg_hdr CONFIGURE_DEPENDS "${_cys_pg_dir}/*.h")
if(NOT _cys_pg_src)
    message(FATAL_ERROR "CYS protocolgen: no sources in ${_cys_pg_dir}; run Tools/protocol/codegen_cpp.py")
endif()
add_library(cys_protocolgen STATIC ${_cys_pg_src} ${_cys_pg_hdr})
target_include_directories(cys_protocolgen PUBLIC "${_cys_pg_dir}")
set_target_properties(cys_protocolgen PROPERTIES OUTPUT_NAME cys_protocolgen FOLDER Shared)
if(MSVC)
    target_compile_options(cys_protocolgen PRIVATE /W3 /bigobj)
endif()

set(_cys_pg_tests "${CYS_ROOT}/Tests/protocol")
if(EXISTS "${_cys_pg_tests}/protocol_tests.cpp")
    add_executable(cys_protocol_tests "${_cys_pg_tests}/protocol_tests.cpp")
    target_link_libraries(cys_protocol_tests PRIVATE cys_protocolgen)
    set_target_properties(cys_protocol_tests PROPERTIES FOLDER Tests)
    if(MSVC)
        target_compile_options(cys_protocol_tests PRIVATE /W3)
    endif()
    # Optional AddressSanitizer build of the tests + library (-DCYS_PG_ASAN=ON, separate build tree).
    option(CYS_PG_ASAN "Build cys_protocolgen and cys_protocol_tests with /fsanitize=address" OFF)
    if(CYS_PG_ASAN AND MSVC)
        foreach(_t cys_protocolgen cys_protocol_tests)
            target_compile_options(${_t} PRIVATE /fsanitize=address)
        endforeach()
        target_link_options(cys_protocol_tests PRIVATE /INCREMENTAL:NO)
    endif()
endif()
