# CYS component: Plugin_ParticleFX2 - OGRE particle plugin DLL (PolarEmitter, ColourFading/Movement/Revolution/
# ScaleInterpolator affectors) used by the Fairy effect data. Loaded by Ogre::Root::loadPlugin("Plugin_ParticleFX2").
# Old project: Engine/ParticleFX2/scripts/Plugin_ParticleFX2_VC8.vcproj; exports from misc/OgreParticleFX2Dll.def.

# ---- Shared WX build helpers (identical copy in scorpio/particlefx2/wxcore/wxrender.cmake; first one wins) -------
# cys_wx_ogre : OgreMain - the ogremain component's target when it is configured in the same tree, else OgreMain
#               headers + OgreMain.lib of another tree (CYS_OGRE_LIB_DIR, default Build/cmake/ogre-<arch>/lib).
# cys_wx_boost: cys_boost + an overlay holding boost/preprocessor/debug/*.hpp, which Src/ThirdParty/boost lacks (the
#               importer skipped folders named "debug"; repetition/repeat.hpp needs debug/error.hpp). The 3 headers
#               are copied from the read-only Reference tree into this build tree only while Src is missing them.
if(NOT TARGET cys_wx_ogre)
    add_library(cys_wx_ogre INTERFACE)
    set(_cys_ogre_tgt "")
    foreach(_t OgreMain cys_ogremain ogremain)
        if(NOT _cys_ogre_tgt AND TARGET ${_t})
            set(_cys_ogre_tgt ${_t})
        endif()
    endforeach()
    if(_cys_ogre_tgt)
        target_link_libraries(cys_wx_ogre INTERFACE ${_cys_ogre_tgt})
    else()
        set(CYS_OGRE_LIB_DIR "${CYS_ROOT}/Build/cmake/ogre-${CYS_ARCH}/lib" CACHE PATH
            "Directory holding OgreMain.lib when the ogremain component is not part of this tree")
        target_include_directories(cys_wx_ogre INTERFACE "${CYS_SRC}/Engine/OGRE/OgreMain/include")
        # By name + link dir, not a file path: Ninja must not demand the file before the other tree has built it.
        target_link_directories(cys_wx_ogre INTERFACE "${CYS_OGRE_LIB_DIR}")
        target_link_libraries(cys_wx_ogre INTERFACE OgreMain)
    endif()
    # OgreMain's public headers need boost (OgrePoolAllocator.h -> boost/pool); mirrors its PUBLIC cys_boost.
    target_link_libraries(cys_wx_ogre INTERFACE cys_wx_boost)
endif()
if(NOT TARGET cys_wx_boost)
    add_library(cys_wx_boost INTERFACE)
    target_link_libraries(cys_wx_boost INTERFACE cys_boost)
    if(NOT EXISTS "${CYS_TP}/boost/boost/preprocessor/debug/error.hpp")
        file(GLOB _cys_bref LIST_DIRECTORIES true
            "${CYS_ROOT}/Reference/tlbb085/085/SourceCode/Client/*/boost/boost/preprocessor/debug")
        if(_cys_bref)
            list(GET _cys_bref 0 _cys_bref)
            file(COPY "${_cys_bref}/" DESTINATION "${CMAKE_BINARY_DIR}/cys_boost_overlay/boost/preprocessor/debug")
            target_include_directories(cys_wx_boost INTERFACE "${CMAKE_BINARY_DIR}/cys_boost_overlay")
        else()
            message(WARNING "CYS: boost/preprocessor/debug/*.hpp missing from Src/ThirdParty/boost and Reference")
        endif()
    endif()
endif()
# ------------------------------------------------------------------------------------------------------------------

set(_cys_pfx "${CYS_SRC}/Engine/ParticleFX2")
add_library(cys_particlefx2 SHARED
    "${_cys_pfx}/src/OgreColourFadingAffector.cpp"
    "${_cys_pfx}/src/OgreMovementAffector.cpp"
    "${_cys_pfx}/src/OgreParticleFX2.cpp"
    "${_cys_pfx}/src/OgrePolarEmitter.cpp"
    "${_cys_pfx}/src/OgreRevolutionAffector.cpp"
    "${_cys_pfx}/src/OgreScaleInterpolatorAffector.cpp"
    # CYS: RevoluMove / PolarMove affectors of the 2024-2026 effect data (Docs/specs/render/04-effects-particles.md)
    "${_cys_pfx}/src/OgreRevoluMoveAffector.cpp"
    "${_cys_pfx}/src/OgrePolarMoveAffector.cpp"
    "${_cys_pfx}/misc/OgreParticleFX2Dll.def")
target_include_directories(cys_particlefx2 PRIVATE "${_cys_pfx}/include")
target_compile_definitions(cys_particlefx2 PRIVATE _USRDLL PLUGIN_ParticleFX2_EXPORTS)
target_link_libraries(cys_particlefx2 PRIVATE cys_wx_ogre)
if(MSVC)
    target_compile_options(cys_particlefx2 PRIVATE /w14311 /w14312 /w14302)
endif()
set_target_properties(cys_particlefx2 PROPERTIES OUTPUT_NAME Plugin_ParticleFX2 PREFIX "" FOLDER Plugins)
