# Tests/fx/particles: CYSParticleUnitTest (client_GL particle parity, Docs/specs/render/07b-particles_vi.md) and
# CYSParticleBench (CPU cost of particle update + render-queue submission, 200 systems).
#
# Injected into a build tree without touching Src/CMakeLists.txt (same scheme as Tests/fx/fx_test.cmake):
#   cmake -S <tree>/Src -B <build> ... -DCMAKE_PROJECT_CYSource_INCLUDE=<CY-Source>/Tests/fx/particles/particles_test.cmake
# -DCYS_PARTICLES_UNIT=OFF builds the bench only (a baseline tree of an older commit lacks the tested APIs).
set(_cys_particles_targets "${CMAKE_CURRENT_LIST_DIR}/particles_targets.cmake")
cmake_language(EVAL CODE
    "cmake_language(DEFER DIRECTORY \"${CMAKE_SOURCE_DIR}\" CALL include \"${_cys_particles_targets}\")")
