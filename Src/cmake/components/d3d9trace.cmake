# CYS component: CysD3D9Trace (Src/Tools/CysD3D9Trace) - d3d9.dll proxy (x64) that records, for selected frames, every
# draw call of a Direct3D 9 application with its full pipeline state: render/sampler/texture-stage states, textures
# (size/format/mips/content hash), vertex/pixel shaders (bytecode hash + D3DX disassembly + constant table), the shader
# constants in effect at that draw, render targets/viewport/scissor, pass order, occlusion-query pixel counts, and
# optionally a PNG of the render target at the end of every pass. Frame times of every Present go to frametimes.tsv.
# Used to compare the CY 3.71 client with CY-Source draw for draw (Tools/render/d3d9_trace_diff.py,
# Docs/specs/render/d3d9-parity_vi.md).
#
# Output: bin/d3d9trace/d3d9.dll (own folder so it never shadows the system d3d9.dll of the tools in bin/). Copy it
# ONLY into a private copy of a run folder (next to Game.exe / TlbbViewer.exe). No dependency on other components;
# D3DX9 (d3dx9_43.dll) is loaded at run time, its headers come from the bundled SDK through a shim include dir.
# Owner: d3d9-trace agent (2026-09-15).
set(_cys_dt "${CYS_SRC}/Tools/CysD3D9Trace")
set(_cys_dt_shim "${CMAKE_BINARY_DIR}/cys_d3d9trace_shim/include")
file(GLOB _cys_dt_hdrs "${CYS_DX_INC}/d3dx9*.h" "${CYS_DX_INC}/d3dx9*.inl")
file(COPY ${_cys_dt_hdrs} DESTINATION "${_cys_dt_shim}")

add_library(CysD3D9Trace SHARED
    "${_cys_dt}/D3D9Trace.cpp"
    "${_cys_dt}/d3d9trace.def")
target_include_directories(CysD3D9Trace PRIVATE "${_cys_dt_shim}")
target_compile_definitions(CysD3D9Trace PRIVATE NOMINMAX WIN32_LEAN_AND_MEAN _CRT_SECURE_NO_WARNINGS)
target_link_libraries(CysD3D9Trace PRIVATE dxguid)
set_target_properties(CysD3D9Trace PROPERTIES
    OUTPUT_NAME d3d9
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/d3d9trace"
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/d3d9trace"
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib/d3d9trace"
    PDB_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/d3d9trace"
    FOLDER Tools)
