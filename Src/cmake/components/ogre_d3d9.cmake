# CYS component: RenderSystem_Direct3D9.dll (plugin DLL; Root::loadRenderPlugins_D3D9() loads it by
# name and calls dllStartPlugin -> Ogre::StartDirect3D9()).
#
# Targets:
#   cys_d3dx9               INTERFACE: D3DX9/DxErr9 headers + d3d9/d3dx9/DxErr9/dxguid libs (x86|x64).
#                           Reusable by any component that needs D3DX9.
#   RenderSystem_Direct3D9  SHARED -> bin/RenderSystem_Direct3D9.dll
#
# The bundled DX SDK is April 2007 (D3DX_SDK_VERSION 32, d3dx9.lib -> d3dx9_32.dll). Only its D3DX9
# and DxErr9 headers are used, through a shim include dir in the build tree: its d3d9.h/d3d9types.h,
# rpcsal.h, strsafe.h, dinput.h, ... would otherwise shadow the Windows SDK headers. d3d9.h therefore
# comes from the Windows SDK (same D3D_SDK_VERSION 32 interface).
set(_cys_dxshim "${CMAKE_BINARY_DIR}/cys_dxshim/include")
file(GLOB _cys_dxshim_hdrs "${CYS_DX_INC}/d3dx9*.h" "${CYS_DX_INC}/d3dx9*.inl" "${CYS_DX_INC}/dxerr9.h")
file(COPY ${_cys_dxshim_hdrs} DESTINATION "${_cys_dxshim}")

# x64: D3DX is linked against d3dx9_43.dll (June 2010 runtime; what client_GL\Bin64 ships and what the
# reference 0.85 x64 RenderSystem_Direct3D9.dll imports) instead of the SDK's d3dx9_32: the x64
# d3dx9_32 D3DXCompileShader crashes (access violation inside d3dx9_32.dll) on client_GL's HLSL
# templates. The import library is generated from the export table of the installed runtime; the
# D3DX C functions and ID3DXConstantTable used here are unchanged between D3DX 32 and 43, so the
# SDK 32 headers stay. Runtime files to ship next to the exe: d3dx9_43.dll + D3DCompiler_43.dll.
set(_cys_d3dx_lib "${CYS_DX_LIB}/d3dx9.lib")
set(_cys_d3dx43_dll "$ENV{SystemRoot}/System32/d3dx9_43.dll")
if(CYS_ARCH STREQUAL "x64" AND EXISTS "${_cys_d3dx43_dll}")
    set(_cys_d3dx43_dir "${CMAKE_BINARY_DIR}/cys_dxshim/lib")
    set(_cys_d3dx43_lib "${_cys_d3dx43_dir}/d3dx9_43.lib")
    if(NOT EXISTS "${_cys_d3dx43_lib}")
        file(MAKE_DIRECTORY "${_cys_d3dx43_dir}")
        # link.exe acts as dumpbin only when /dump is the FIRST argument
        execute_process(COMMAND "${CMAKE_LINKER}" /dump /exports "${_cys_d3dx43_dll}"
                        OUTPUT_VARIABLE _cys_exp RESULT_VARIABLE _cys_rc)
        string(REGEX MATCHALL "\n +[0-9]+ +[0-9A-F]+ +[0-9A-F]+ +[A-Za-z_][A-Za-z0-9_]*" _cys_rows "${_cys_exp}")
        list(LENGTH _cys_rows _cys_nexp)
        set(_cys_rc2 "skipped")
        if(_cys_nexp GREATER 100)
            set(_cys_def "LIBRARY d3dx9_43.dll\nEXPORTS\n")
            foreach(_r IN LISTS _cys_rows)
                string(REGEX REPLACE ".* ([A-Za-z_][A-Za-z0-9_]*)$" "\\1" _n "${_r}")
                string(APPEND _cys_def "    ${_n}\n")
            endforeach()
            file(WRITE "${_cys_d3dx43_dir}/d3dx9_43.def" "${_cys_def}")
            execute_process(COMMAND "${CMAKE_AR}" /nologo "/def:${_cys_d3dx43_dir}/d3dx9_43.def" /machine:x64
                                    "/out:${_cys_d3dx43_lib}"
                            RESULT_VARIABLE _cys_rc2 OUTPUT_QUIET)
        endif()
        message(STATUS "CYS: d3dx9_43 import library: ${_cys_nexp} exports (dump rc=${_cys_rc}), lib.exe rc=${_cys_rc2}")
    endif()
    if(EXISTS "${_cys_d3dx43_lib}")
        set(_cys_d3dx_lib "${_cys_d3dx43_lib}")
    endif()
endif()

if(NOT TARGET cys_d3dx9)
    add_library(cys_d3dx9 INTERFACE)
    target_include_directories(cys_d3dx9 INTERFACE "${_cys_dxshim}")
    target_link_libraries(cys_d3dx9 INTERFACE
        d3d9 dxguid "${_cys_d3dx_lib}" "${CYS_DX_LIB}/DxErr9.lib" legacy_stdio_definitions)
endif()

set(_cys_d3d9_dir "${CYS_SRC}/Engine/OGRE/RenderSystems/Direct3D9")
set(_cys_d3d9_src "${_cys_d3d9_dir}/src")
add_library(RenderSystem_Direct3D9 SHARED
    "${_cys_d3d9_src}/OgreD3D9Driver.cpp"
    "${_cys_d3d9_src}/OgreD3D9DriverList.cpp"
    "${_cys_d3d9_src}/OgreD3D9EngineDll.cpp"
    "${_cys_d3d9_src}/OgreD3D9GpuProgram.cpp"
    "${_cys_d3d9_src}/OgreD3D9GpuProgramManager.cpp"
    "${_cys_d3d9_src}/OgreD3D9HardwareBufferManager.cpp"
    "${_cys_d3d9_src}/OgreD3D9HardwareIndexBuffer.cpp"
    "${_cys_d3d9_src}/OgreD3D9HardwareOcclusionQuery.cpp"
    "${_cys_d3d9_src}/OgreD3D9HardwarePixelBuffer.cpp"
    "${_cys_d3d9_src}/OgreD3D9HardwareVertexBuffer.cpp"
    "${_cys_d3d9_src}/OgreD3D9HLSLProgram.cpp"
    "${_cys_d3d9_src}/OgreD3D9HLSLProgramFactory.cpp"
    "${_cys_d3d9_src}/OgreD3D9Mappings.cpp"
    "${_cys_d3d9_src}/OgreD3D9MultiRenderTarget.cpp"
    "${_cys_d3d9_src}/OgreD3D9RenderSystem.cpp"
    "${_cys_d3d9_src}/OgreD3D9RenderWindow.cpp"
    "${_cys_d3d9_src}/OgreD3D9Texture.cpp"
    "${_cys_d3d9_src}/OgreD3D9TextureManager.cpp"
    "${_cys_d3d9_src}/OgreD3D9VertexDeclaration.cpp"
    "${_cys_d3d9_src}/OgreD3D9VideoMode.cpp"
    "${_cys_d3d9_src}/OgreD3D9VideoModeList.cpp"
    "${_cys_d3d9_dir}/misc/OgreD3D9RenderSystem.def")
target_include_directories(RenderSystem_Direct3D9 PRIVATE "${_cys_d3d9_dir}/include")
target_compile_definitions(RenderSystem_Direct3D9 PRIVATE
    _USRDLL RENDERSYSTEM_DIRECT3D9_EXPORTS OGRED3DENGINEDLL_EXPORTS)
target_link_libraries(RenderSystem_Direct3D9 PRIVATE OgreMain cys_d3dx9)
if(CYS_OGRE_WARN_TRUNC) # option defined in ogremain.cmake
    target_compile_options(RenderSystem_Direct3D9 PRIVATE /w14244 /w14267)
endif()
