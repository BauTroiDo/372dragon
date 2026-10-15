# Tests/fx/particles targets (see particles_test.cmake). Needs the wxcore component (and its OGRE / ParticleFX2
# dependencies) in the same build tree.
if(NOT TARGET cys_wxcore)
    message(WARNING "CYS: Tests/fx/particles needs the wxcore component in the same build tree - skipped")
    return()
endif()

set(_cys_pt_dir "${CMAKE_CURRENT_LIST_DIR}")
set(_cys_pt_src "${CMAKE_SOURCE_DIR}")   # Src of the tree being built (current or baseline)
option(CYS_PARTICLES_UNIT "Build CYSParticleUnitTest (needs the fx-particles sources)" ON)

# ---- bench: only APIs that exist in every tree -------------------------------------------------------------------
add_executable(CYSParticleBench "${_cys_pt_dir}/particle_bench.cpp")
target_compile_definitions(CYSParticleBench PRIVATE _CONSOLE NOMINMAX WIN32_LEAN_AND_MEAN)
target_link_libraries(CYSParticleBench PRIVATE cys_wxcore)
if(MSVC)
    target_compile_options(CYSParticleBench PRIVATE /bigobj)
endif()
set_target_properties(CYSParticleBench PROPERTIES FOLDER Tests)

# ---- unit tests ---------------------------------------------------------------------------------------------------
# The classes under test are not exported (Plugin_ParticleFX2 exports only dllStartPlugin; the ParticleFX plug-in
# is compiled into OgreMain without exports), so their sources are compiled into the test as well. The runtime
# copies (OgreMain / Plugin_ParticleFX2) are tested through the factories and the parameter dictionaries.
if(CYS_PARTICLES_UNIT)
    add_executable(CYSParticleUnitTest
        "${_cys_pt_dir}/particle_unit_test.cpp"
        "${_cys_pt_src}/Engine/ParticleFX2/src/OgreColourFadingAffector.cpp"
        "${_cys_pt_src}/Engine/ParticleFX2/src/OgreScaleInterpolatorAffector.cpp"
        "${_cys_pt_src}/Engine/ParticleFX2/src/OgreRevolutionAffector.cpp"
        "${_cys_pt_src}/Engine/OGRE/PlugIns/ParticleFX/src/OgreEllipsoidEmitter.cpp")
    target_include_directories(CYSParticleUnitTest PRIVATE
        "${_cys_pt_src}/Engine/ParticleFX2/include"
        "${_cys_pt_src}/Engine/OGRE/PlugIns/ParticleFX/include")
    target_compile_definitions(CYSParticleUnitTest PRIVATE _CONSOLE NOMINMAX WIN32_LEAN_AND_MEAN)
    target_link_libraries(CYSParticleUnitTest PRIVATE cys_wxcore)
    if(MSVC)
        target_compile_options(CYSParticleUnitTest PRIVATE /bigobj)
    endif()
    set_target_properties(CYSParticleUnitTest PROPERTIES FOLDER Tests)
endif()
