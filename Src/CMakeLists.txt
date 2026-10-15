# CY-Source — hệ build CMake.
#
# Mỗi thành phần có MỘT file riêng trong cmake/components/<tên>.cmake, do đúng một người/agent sở
# hữu. Thành phần nào chưa có file thì bị bỏ qua, nhờ vậy nhiều agent làm song song không chặn nhau.
# Chọn thành phần khi cấu hình: -DCYS_COMPONENTS="zlib;zziplib;..." (mặc định: tất cả).
cmake_minimum_required(VERSION 3.25)
project(CYSource LANGUAGES C CXX)

include(cmake/CYSCommon.cmake)

# Thứ tự = thứ tự phụ thuộc.
set(CYS_ALL_COMPONENTS
    zlib zziplib freetype devil
    ogremain ogre_d3d9 ogre_plugins ogre_platform ogre_smoke
    opcode tinyxml expat
    scorpio particlefx2
    wxengine wxcore wxrender pathlib
    cegui falagardex luaplus uisystem
    wxnetpackets protocolgen netcore wxclient
    viewer postfx_test shadow_test ui_viewer netbot actionset_check d3d9trace)
set(CYS_COMPONENTS "${CYS_ALL_COMPONENTS}" CACHE STRING "Các thành phần cần dựng")

foreach(_c IN LISTS CYS_ALL_COMPONENTS)
    if(_c IN_LIST CYS_COMPONENTS)
        cys_component(${_c})
    endif()
endforeach()
