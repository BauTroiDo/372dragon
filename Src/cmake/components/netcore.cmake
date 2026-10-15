# Modern client transport: async login/list/create/charlogin, the game socket
# (connect, enter scene, world traffic, transfer, quit) and a pure world model.
# No dependency on legacy packet classes.
if(NOT TARGET cys_protocolgen)
    message(FATAL_ERROR "CYS netcore requires component protocolgen")
endif()
set(_cys_netcore "${CYS_SRC}/Client/NetCore")
add_library(cys_netcore STATIC
    "${_cys_netcore}/NetCommon.cpp" "${_cys_netcore}/NetCommon.h"
    "${_cys_netcore}/LoginClient.cpp" "${_cys_netcore}/LoginClient.h"
    "${_cys_netcore}/GameClient.cpp" "${_cys_netcore}/GameClient.h"
    "${_cys_netcore}/WorldModel.cpp" "${_cys_netcore}/WorldModel.h"
    "${_cys_netcore}/NetStream.cpp" "${_cys_netcore}/NetStream.h" # CYS: data-source seam (Winsock default)
    "${_cys_netcore}/ReplayStream.cpp" "${_cys_netcore}/ReplayStream.h" # CYS: offline replay source (CYS_WORLD_REPLAY)
    "${_cys_netcore}/RecordStream.cpp" "${_cys_netcore}/RecordStream.h" # CYS-CORE: frame recorder (bot fixture)
    "${_cys_netcore}/ServerProfile.cpp" "${_cys_netcore}/ServerProfile.h" # CYS: Patch/CysServerProfile.txt endpoint policy
    "${CYS_SRC}/Tools/CysNetBot/LoginProbe.cpp")
target_include_directories(cys_netcore PUBLIC "${_cys_netcore}"
    PRIVATE "${CYS_SRC}/Tools/CysNetBot")
target_link_libraries(cys_netcore PUBLIC cys_protocolgen PRIVATE ws2_32 iphlpapi) # CYS: iphlpapi = local adapter check
target_compile_definitions(cys_netcore PRIVATE WIN32_LEAN_AND_MEAN NOMINMAX)
set_target_properties(cys_netcore PROPERTIES FOLDER Client)
add_executable(cys_netcore_tests "${CYS_ROOT}/Tests/net/netcore_tests.cpp")
target_include_directories(cys_netcore_tests PRIVATE "${CYS_SRC}/Tools/CysNetBot")
target_link_libraries(cys_netcore_tests PRIVATE cys_netcore)
set_target_properties(cys_netcore_tests PROPERTIES FOLDER Tests)
if(EXISTS "${CYS_ROOT}/Tests/net/world_session_tests.cpp")
    add_executable(cys_world_tests "${CYS_ROOT}/Tests/net/world_session_tests.cpp")
    target_include_directories(cys_world_tests PRIVATE "${CYS_SRC}/Tools/CysNetBot")
    target_link_libraries(cys_world_tests PRIVATE cys_netcore ws2_32)
    target_compile_definitions(cys_world_tests PRIVATE WIN32_LEAN_AND_MEAN NOMINMAX)
    set_target_properties(cys_world_tests PROPERTIES FOLDER Tests)
endif()
if(MSVC)
    target_compile_options(cys_netcore PRIVATE /W4)
    target_compile_options(cys_netcore_tests PRIVATE /W4)
    if(TARGET cys_world_tests)
        target_compile_options(cys_world_tests PRIVATE /W4)
    endif()
endif()
