# Thiết lập chung cho mọi thành phần của CY-Source.

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
set(CMAKE_POSITION_INDEPENDENT_CODE OFF)

get_filename_component(CYS_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/.." ABSOLUTE)
set(CYS_SRC "${CMAKE_CURRENT_SOURCE_DIR}")
set(CYS_TP "${CYS_SRC}/ThirdParty")

if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(CYS_ARCH x64)
else()
    set(CYS_ARCH x86)
endif()

# Đầu ra theo từng cây build (không ghi thẳng vào Build/Client/Bin64 để các cây build song song
# không đè nhau; bước "stage" sẽ chép sau).
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
set(CMAKE_PDB_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

if(MSVC)
    # CYS-WARNSWEEP 19/09 — MỨC CẢNH BÁO. Trước hôm nay dòng này KHÔNG có cờ /W nào, và
    # cmake_minimum_required(3.25) => CMP0092 NEW => CMake cũng không tự thêm /W3 nữa, nên cl chạy ở
    # /W1 (mức MẶC ĐỊNH, thấp nhất). Hậu quả đo được: C4474 ("too many arguments passed for format
    # string", mức 3) im lặng ở cấu hình cũ, trong đó có MỘT LỖI THẬT (tên cửa hàng bị vứt,
    # GCPlayerShopEstablishHandler.cpp:14). Chi tiết + số đo: Timeline/handoff/warn-sweep.md.
    #   /W3                     mức tín hiệu/nhiễu tốt nhất đã đo. ĐỪNG nâng lên /W4: nó kéo theo
    #                           C4100/C4127/C4189 và biến tín hiệu thành nhiễu trở lại.
    #   /w34701 /w34703         "biến (con trỏ) có thể chưa khởi tạo" vốn là mức 4 => vô hình ở /W3.
    #                           Đây là vùng nguy hiểm THẬT của cây này: 20 khoản trong mã của ta,
    #                           16 là lỗi thật (2 chỗ giải tham chiếu con trỏ rác).
    #   /w34715                 "không phải mọi nhánh đều trả về giá trị" (mức 4). Hiện toàn cây = 0;
    #                           để sẵn cho tương lai.
    # Cảnh báo KHÔNG làm hỏng build (không có /WX ở đâu cả). Mọi nhánh sẽ thấy THÊM cảnh báo kể từ
    # commit này — đó là TÍNH NĂNG, không phải hồi quy.
    #
    # /wd4244 /wd4267 (thu hẹp giá trị, 596 + 340 khoản) được GIỮ NGUYÊN. Đây là đánh giá theo
    # HIỆN TRẠNG, không phải vĩnh viễn: phần lớn là thu hẹp có chủ ý khi đóng gói cấu trúc mạng, và
    # 936 khoản sẽ nhấn chìm tín hiệu. Cách đúng để soi chúng là bật /w34244 cho MỘT target mỗi lần,
    # như ogremain.cmake đã làm với tuỳ chọn CYS_OGRE_WARN_TRUNC.
    #
    # Mã nguồn đã chuyển UTF-8; literal tiếng Trung là khoá tài nguyên -> biên dịch ra byte GBK.
    add_compile_options(
        /MP /Zi /nologo
        /source-charset:utf-8 /execution-charset:.936
        /W3 /w34701 /w34703 /w34715
        /wd4828 /wd4819 /wd4996 /wd4251 /wd4275 /wd4244 /wd4267 /wd4018 /wd4305 /wd4800 /wd4995
        $<$<COMPILE_LANGUAGE:CXX>:/EHsc>)
    add_compile_definitions(
        WIN32 _WINDOWS
        _CRT_SECURE_NO_WARNINGS _CRT_NONSTDC_NO_DEPRECATE _SCL_SECURE_NO_WARNINGS
        _SILENCE_STDEXT_HASH_DEPRECATION_WARNINGS _SILENCE_ALL_CXX17_DEPRECATION_WARNINGS
        _HAS_AUTO_PTR_ETC=1 _WINSOCK_DEPRECATED_NO_WARNINGS
        $<$<NOT:$<CONFIG:Debug>>:NDEBUG>)
    add_link_options(/DEBUG $<$<NOT:$<CONFIG:Debug>>:/OPT:REF> $<$<NOT:$<CONFIG:Debug>>:/OPT:ICF>)
endif()

# DirectX 9 SDK đi kèm cây mã (Include + Lib/x86|x64).
set(CYS_DX_INC "${CYS_TP}/DirectX9/Include")
set(CYS_DX_LIB "${CYS_TP}/DirectX9/Lib/${CYS_ARCH}")

# boost (chỉ header).
add_library(cys_boost INTERFACE)
target_include_directories(cys_boost INTERFACE "${CYS_TP}/boost")
# BOOST_ALL_NO_LIB đã được định nghĩa sẵn trong boost/config/user.hpp:111 của cây mã này.

# FMOD Engine 2.02.35 (Core API) — SDK do người dùng tải, cài ở ThirdParty/_sdk/fmod (không commit).
set(CYS_FMOD_CORE "${CYS_TP}/_sdk/fmod/api/core")
if(EXISTS "${CYS_FMOD_CORE}/inc/fmod.h")
    add_library(cys_fmod SHARED IMPORTED GLOBAL)
    set_target_properties(cys_fmod PROPERTIES
        IMPORTED_LOCATION "${CYS_FMOD_CORE}/lib/${CYS_ARCH}/fmod.dll"
        IMPORTED_IMPLIB "${CYS_FMOD_CORE}/lib/${CYS_ARCH}/fmod_vc.lib"
        INTERFACE_INCLUDE_DIRECTORIES "${CYS_FMOD_CORE}/inc")
    message(STATUS "CYS: FMOD Core có sẵn (${CYS_FMOD_CORE})")
else()
    message(STATUS "CYS: chưa có FMOD SDK ở ${CYS_FMOD_CORE}")
endif()

# Nạp một thành phần nếu file của nó đã tồn tại.
macro(cys_component _name)
    set(_cys_f "${CYS_SRC}/cmake/components/${_name}.cmake")
    if(EXISTS "${_cys_f}")
        message(STATUS "CYS: thành phần ${_name}")
        include("${_cys_f}")
    else()
        message(STATUS "CYS: chưa có thành phần ${_name} (bỏ qua)")
    endif()
endmacro()
