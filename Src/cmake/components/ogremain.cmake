# CYS component: OgreMain.dll = OGRE 1.2.5 "Dagon" core with the Fairy/WX changes.
#
# Target: OgreMain (SHARED -> bin/OgreMain.dll + lib/OgreMain.lib)
#   PUBLIC include dir: Src/Engine/OGRE/OgreMain/include (consumers get _OgreExport = dllimport)
#   PUBLIC link: cys_boost (headers only)
#
# Linking model, established from the source and the reference 0.85 builds (x86 Bin + x64 Bin64):
#  * Statically inside OgreMain.dll (Root::loadInnerPlugins()/PlatformManager call them directly):
#    - Win32 platform manager: OgrePlatformManager.cpp calls createPlatformConfigDialog() ...
#      directly; the OgrePlatform.dll load (OgrePlatformManager.cpp:53) is commented out.
#    - ParticleFX: registerParticleFactories(); AreaEmitter is declared _OgreExport
#      (OgreAreaEmitter.h:44); the reference OgreMain.dll exports AreaEmitter and contains the
#      emitter/affector factory names.
#    - OctreeSceneManager (+ Terrain): StartOctreeSceneManager(); reference OgreMain.dll contains
#      the OctreeSceneManager/HeightmapTerrainPageSource strings; no Plugin_*.dll was shipped.
#  * Plugin DLLs loaded by name (CYS change in OgreRoot.cpp, as the reference builds did for D3D9):
#    RenderSystem_Direct3D9.dll (component ogre_d3d9), Plugin_ParticleFX2.dll, Plugin_Scorpio.dll,
#    Plugin_CgProgramManager.dll (not built for x64: no Cg x64 SDK; its absence is only logged).
#
# Sources: every Src/Engine/OGRE/OgreMain/src/*.cpp except the two OGRE 1.4 shadow camera setups
# below. scripts/OgreMain.vcproj is stale (167 files) and misses 11 files this OgreMain needs and
# the reference DLL exports (PlatformInformation, OptimisedUtil*, ShadowCameraSetup(+PlaneOptimal),
# ConvexBody, Polygon, AlignedAllocator, Numerics; OgreSearchOps.cpp is empty on Win32).
set(_cys_ogre_dir "${CYS_SRC}/Engine/OGRE")
set(_cys_ogre_w32 "${_cys_ogre_dir}/PlatformManagers/Win32")
set(_cys_pfx_dir "${_cys_ogre_dir}/PlugIns/ParticleFX")
set(_cys_oct_dir "${_cys_ogre_dir}/PlugIns/OctreeSceneManager")

file(GLOB _cys_ogremain_src CONFIGURE_DEPENDS "${_cys_ogre_dir}/OgreMain/src/*.cpp")
# Not part of the Fairy OgreMain: they need OGRE 1.4 SceneManager::getShadowCasterBoundsInfo() and
# the reference OgreMain.dll exports neither FocusedShadowCameraSetup nor LiSPSMShadowCameraSetup.
list(REMOVE_ITEM _cys_ogremain_src
    "${_cys_ogre_dir}/OgreMain/src/OgreShadowCameraSetupFocused.cpp"
    "${_cys_ogre_dir}/OgreMain/src/OgreShadowCameraSetupLiSPSM.cpp")

set(_cys_ogre_static_plugins
    # Win32 platform manager (PlatformManagers/Win32/scripts/PlatformManager_Win32.vcproj)
    "${_cys_ogre_w32}/src/OgreWin32ConfigDialog.cpp"
    "${_cys_ogre_w32}/src/OgreWin32ErrorDialog.cpp"
    "${_cys_ogre_w32}/src/OgreWin32Input.cpp"
    "${_cys_ogre_w32}/src/OgreWin32Input8.cpp"
    "${_cys_ogre_w32}/src/OgreWin32PlatformDll.cpp"
    "${_cys_ogre_w32}/src/OgreWin32Timer.cpp"
    "${_cys_ogre_w32}/misc/OgreWin32Resources.rc"
    # ParticleFX (PlugIns/ParticleFX/scripts/Plugin_ParticleFX.vcproj)
    "${_cys_pfx_dir}/src/OgreAreaEmitter.cpp"
    "${_cys_pfx_dir}/src/OgreBoxEmitter.cpp"
    "${_cys_pfx_dir}/src/OgreColourFaderAffector.cpp"
    "${_cys_pfx_dir}/src/OgreColourFaderAffector2.cpp"
    "${_cys_pfx_dir}/src/OgreColourImageAffector.cpp"
    "${_cys_pfx_dir}/src/OgreColourInterpolatorAffector.cpp"
    "${_cys_pfx_dir}/src/OgreCylinderEmitter.cpp"
    "${_cys_pfx_dir}/src/OgreDeflectorPlaneAffector.cpp"
    "${_cys_pfx_dir}/src/OgreDirectionRandomiserAffector.cpp"
    "${_cys_pfx_dir}/src/OgreEllipsoidEmitter.cpp"
    "${_cys_pfx_dir}/src/OgreHollowEllipsoidEmitter.cpp"
    "${_cys_pfx_dir}/src/OgreLinearForceAffector.cpp"
    "${_cys_pfx_dir}/src/OgreParticleFX.cpp"
    "${_cys_pfx_dir}/src/OgrePointEmitter.cpp"
    "${_cys_pfx_dir}/src/OgreRingEmitter.cpp"
    "${_cys_pfx_dir}/src/OgreRotationAffector.cpp"
    "${_cys_pfx_dir}/src/OgreScaleAffector.cpp"
    # OctreeSceneManager + TerrainSceneManager (PlugIns/OctreeSceneManager/scripts/*.vcproj)
    "${_cys_oct_dir}/src/OgreHeightmapTerrainPageSource.cpp"
    "${_cys_oct_dir}/src/OgreOctree.cpp"
    "${_cys_oct_dir}/src/OgreOctreeCamera.cpp"
    "${_cys_oct_dir}/src/OgreOctreeNode.cpp"
    "${_cys_oct_dir}/src/OgreOctreeSceneManager.cpp"
    "${_cys_oct_dir}/src/OgreOctreeSceneManagerDll.cpp"
    "${_cys_oct_dir}/src/OgreOctreeSceneQuery.cpp"
    "${_cys_oct_dir}/src/OgreTerrainPage.cpp"
    "${_cys_oct_dir}/src/OgreTerrainPageSource.cpp"
    "${_cys_oct_dir}/src/OgreTerrainRenderable.cpp"
    "${_cys_oct_dir}/src/OgreTerrainSceneManager.cpp"
    "${_cys_oct_dir}/src/OgreTerrainVertexProgram.cpp")

add_library(OgreMain SHARED ${_cys_ogremain_src} ${_cys_ogre_static_plugins})
target_include_directories(OgreMain
    PUBLIC  "${_cys_ogre_dir}/OgreMain/include"
    PRIVATE "${_cys_ogre_w32}/include" "${_cys_pfx_dir}/include" "${_cys_oct_dir}/include")
target_compile_definitions(OgreMain PRIVATE OGRE_NONCLIENT_BUILD _USRDLL)
target_link_libraries(OgreMain
    PUBLIC  cys_boost
    PRIVATE cys_zziplib cys_zlib cys_freetype cys_ilu cys_devil
            dinput8 dxguid winmm
            windowscodecs ole32) # CYS: OgreWICCodec.cpp (PNG/JPEG/BMP/GIF/TIFF via WIC)

# Diagnostics: -DCYS_OGRE_WARN_TRUNC=ON re-enables C4244/C4267 (globally disabled) on the OGRE targets
# to hunt implicit x64 truncations such as the _findfirst handle kept in a long (OgreFileSystem.cpp).
option(CYS_OGRE_WARN_TRUNC "Re-enable C4244/C4267 on OGRE targets (x64 truncation hunt)" OFF)
if(CYS_OGRE_WARN_TRUNC)
    target_compile_options(OgreMain PRIVATE /w14244 /w14267)
endif()

# OgreWin32Input8.cpp includes (but does not use) <dxerr8.h>, which only the old DX SDK has.
# It is exposed through the header shim that ogre_d3d9.cmake also uses (no DX SDK d3d9.h etc.).
set(_cys_dxshim "${CMAKE_BINARY_DIR}/cys_dxshim/include")
file(COPY "${CYS_DX_INC}/dxerr8.h" DESTINATION "${_cys_dxshim}")
target_include_directories(OgreMain PRIVATE "${_cys_dxshim}")
