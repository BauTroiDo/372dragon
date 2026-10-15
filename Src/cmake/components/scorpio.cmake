# CYS component: Plugin_Scorpio - cloth/fabric physics + hardware-skinning helper DLL (OGRE MovableObject
# factories "Cloth"/"Fabric", CollisionManager). WXCore calls it directly: Ogre::createCollisionManager()
# (ModelSystem/WXLogicModelManager.cpp:1038), destroyCollisionManager() (:1083) and
# Ogre::convertEntityToHardwareSkinning() (Core/WXUtils.cpp:713) - the DynLib paths there are commented out - so
# the import library is linked by WXCore's consumers (PUBLIC dependency of cys_wxcore when this component exists).
# Old project: Engine/Scorpio/scripts/Plugin_Scorpio.vcproj; exports from scripts/Plugin_Scorpio.def.
# Runtime media (hardware skinning material/program/cg) live in Engine/Scorpio/media.

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

set(_cys_sco "${CYS_SRC}/Engine/Scorpio")
add_library(cys_scorpio SHARED
    "${_cys_sco}/src/Scorpio.cpp"
    "${_cys_sco}/src/ScorpioCloth.cpp"
    "${_cys_sco}/src/ScorpioCollision.cpp"
    "${_cys_sco}/src/ScorpioFabric.cpp"
    "${_cys_sco}/src/ScorpioHardwareAnimation.cpp"
    "${_cys_sco}/src/PhysicsSimulation/PS_BoxCollider.cpp"
    "${_cys_sco}/src/PhysicsSimulation/PS_BucklingForceField.cpp"
    "${_cys_sco}/src/PhysicsSimulation/PS_ClothModel.cpp"
    "${_cys_sco}/src/PhysicsSimulation/PS_ColliderSet.cpp"
    "${_cys_sco}/src/PhysicsSimulation/PS_DampingForceField.cpp"
    "${_cys_sco}/src/PhysicsSimulation/PS_EulerIntegrator.cpp"
    "${_cys_sco}/src/PhysicsSimulation/PS_FabricSimulator.cpp"
    "${_cys_sco}/src/PhysicsSimulation/PS_Force.cpp"
    "${_cys_sco}/src/PhysicsSimulation/PS_GravityForceField.cpp"
    "${_cys_sco}/src/PhysicsSimulation/PS_Integrator.cpp"
    "${_cys_sco}/src/PhysicsSimulation/PS_Mass.cpp"
    "${_cys_sco}/src/PhysicsSimulation/PS_Math.cpp"
    "${_cys_sco}/src/PhysicsSimulation/PS_Matrix3x3.cpp"
    "${_cys_sco}/src/PhysicsSimulation/PS_Motion.cpp"
    "${_cys_sco}/src/PhysicsSimulation/PS_MovableCollider.cpp"
    "${_cys_sco}/src/PhysicsSimulation/PS_PlaneCollider.cpp"
    "${_cys_sco}/src/PhysicsSimulation/PS_RK2Integrator.cpp"
    "${_cys_sco}/src/PhysicsSimulation/PS_RK4Integrator.cpp"
    "${_cys_sco}/src/PhysicsSimulation/PS_Simulator.cpp"
    "${_cys_sco}/src/PhysicsSimulation/PS_SphereCollider.cpp"
    "${_cys_sco}/src/PhysicsSimulation/PS_StretchingForceField.cpp"
    "${_cys_sco}/src/PhysicsSimulation/PS_Vector3.cpp"
    "${_cys_sco}/src/PhysicsSimulation/PS_VerletIntegrator.cpp"
    "${_cys_sco}/scripts/Plugin_Scorpio.def")
target_include_directories(cys_scorpio PUBLIC "${_cys_sco}/include")
target_compile_definitions(cys_scorpio PRIVATE _USRDLL PLUGIN_Scorpio_EXPORTS)
target_link_libraries(cys_scorpio PRIVATE cys_wx_ogre cys_wx_boost)
if(MSVC)
    target_compile_options(cys_scorpio PRIVATE /w14311 /w14312 /w14302)
endif()
set_target_properties(cys_scorpio PROPERTIES OUTPUT_NAME Plugin_Scorpio PREFIX "" FOLDER Plugins)
