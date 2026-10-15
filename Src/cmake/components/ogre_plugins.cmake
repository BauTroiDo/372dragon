# CYS component: OGRE plugins (ParticleFX, OctreeSceneManager, CgProgramManager).
#
#  * ParticleFX and OctreeSceneManager(+Terrain) are compiled INTO OgreMain.dll (see ogremain.cmake):
#    Root::loadInnerPlugins() calls registerParticleFactories()/StartOctreeSceneManager() directly,
#    AreaEmitter is exported from OgreMain (_OgreExport, OgreAreaEmitter.h:44), and the reference
#    0.85 OgreMain.dll (x86 Bin and x64 Bin64) contains both; no Plugin_ParticleFX.dll or
#    Plugin_OctreeSceneManager.dll was ever shipped with it. No target for them here.
#
#  * Plugin_CgProgramManager (SHARED -> bin/Plugin_CgProgramManager.dll, x64 only): loaded by name
#    from Root::loadInnerPlugins() (WX::System calls it). There is no Cg x64 SDK in the tree, so:
#      - headers: Cg 1.4 from Src/ThirdParty/OgreDeps/include/Cg (CG_VERSION_NUM 1400);
#      - import library: generated at configure time from the export table of an x64 cg.dll
#        (Cg 3.1, default client_GL\Bin64\cg.dll, used read-only); the C API the plugin uses
#        (cgCreateContext/Program, cgGetProgramString, cgGet*LeafParameter, cgGetParameter*,
#        cgIsParameterReferenced, cgGetError*, cgGetLastListing) is unchanged from Cg 1.4 to 3.1;
#      - cg.dll is copied next to the plugin after the build (runtime dependency).
#    Without an x64 cg.dll the target is skipped and loadInnerPlugins() only logs the absence.
set(CYS_CG_DLL "${CYS_ROOT}/../client_GL/Bin64/cg.dll" CACHE FILEPATH
    "x64 cg.dll (Cg 3.1) used to build and run Plugin_CgProgramManager (read-only source, copied to bin)")

if(CYS_ARCH STREQUAL "x64" AND EXISTS "${CYS_CG_DLL}")
    set(_cys_cg_dir "${CMAKE_BINARY_DIR}/cys_cg")
    set(_cys_cg_lib "${_cys_cg_dir}/cg.lib")
    if(NOT EXISTS "${_cys_cg_lib}")
        file(MAKE_DIRECTORY "${_cys_cg_dir}")
        # link.exe acts as dumpbin only when /dump is the FIRST argument
        execute_process(COMMAND "${CMAKE_LINKER}" /dump /exports "${CYS_CG_DLL}"
                        OUTPUT_VARIABLE _cys_exp RESULT_VARIABLE _cys_rc)
        string(REGEX MATCHALL "\n +[0-9]+ +[0-9A-F]+ +[0-9A-F]+ +[A-Za-z_][A-Za-z0-9_]*" _cys_rows "${_cys_exp}")
        list(LENGTH _cys_rows _cys_nexp)
        set(_cys_rc2 "skipped")
        if(_cys_nexp GREATER 100)
            set(_cys_def "LIBRARY cg.dll\nEXPORTS\n")
            foreach(_r IN LISTS _cys_rows)
                string(REGEX REPLACE ".* ([A-Za-z_][A-Za-z0-9_]*)$" "\\1" _n "${_r}")
                string(APPEND _cys_def "    ${_n}\n")
            endforeach()
            file(WRITE "${_cys_cg_dir}/cg.def" "${_cys_def}")
            execute_process(COMMAND "${CMAKE_AR}" /nologo "/def:${_cys_cg_dir}/cg.def" /machine:x64 "/out:${_cys_cg_lib}"
                            RESULT_VARIABLE _cys_rc2 OUTPUT_QUIET)
        endif()
        message(STATUS "CYS: cg import library from ${CYS_CG_DLL}: ${_cys_nexp} exports (dump rc=${_cys_rc}), lib.exe rc=${_cys_rc2}")
    endif()
endif()

if(CYS_ARCH STREQUAL "x64" AND EXISTS "${CYS_CG_DLL}" AND EXISTS "${CMAKE_BINARY_DIR}/cys_cg/cg.lib")
    set(_cys_cgp_dir "${CYS_SRC}/Engine/OGRE/PlugIns/CgProgramManager")
    add_library(Plugin_CgProgramManager SHARED
        "${_cys_cgp_dir}/src/OgreCgProgram.cpp"
        "${_cys_cgp_dir}/src/OgreCgProgramFactory.cpp"
        "${_cys_cgp_dir}/src/OgreCgProgramManagerDll.cpp"
        "${_cys_cgp_dir}/misc/OgreCgProgramManager.def")
    target_include_directories(Plugin_CgProgramManager PRIVATE
        "${_cys_cgp_dir}/include" "${CYS_TP}/OgreDeps/include")
    target_compile_definitions(Plugin_CgProgramManager PRIVATE _USRDLL)
    target_link_libraries(Plugin_CgProgramManager PRIVATE OgreMain "${CMAKE_BINARY_DIR}/cys_cg/cg.lib")
    add_custom_command(TARGET Plugin_CgProgramManager POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${CYS_CG_DLL}" "$<TARGET_FILE_DIR:Plugin_CgProgramManager>/cg.dll"
        COMMENT "CYS: copy x64 cg.dll next to Plugin_CgProgramManager.dll")
else()
    message(STATUS "CYS: Plugin_CgProgramManager skipped (needs x64 and an x64 cg.dll: CYS_CG_DLL=${CYS_CG_DLL})")
endif()
