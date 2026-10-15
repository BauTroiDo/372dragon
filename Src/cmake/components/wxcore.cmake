# CYS component: WXCore - the Fairy/WX engine core (scene, terrain, objects, effects, LogicModel) - static library.
# Old project: Engine/WXCore/WXCore.vcxproj (105 sources, static, /MD). We build the same list minus the three
# Xerces-C files (WXXercesHelper/Parser/Writer.cpp): nothing calls CreateXercesParser()/CreateXercesWriter(),
# model/scene XML goes through WXExpatParser, and XMLWriter is an abstract interface injected by the caller
# (only the SceneEdit tool saves scenes). So Xerces is not required.
# MODELSYSTEM_STATIC_LINK is PUBLIC: ModelSystem/ModelTypes.h then declares MODEL_API empty in WXCore and in
# every consumer (0.85 put it only on 3 files; WXRender defined it globally).
# WXCore calls Plugin_Scorpio functions directly (see scorpio.cmake), so cys_scorpio is a PUBLIC link dependency.

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

set(_cys_wxc "${CYS_SRC}/Engine/WXCore")
add_library(cys_wxcore STATIC
    "${_cys_wxc}/Core/BasicRenderable.cpp"
    "${_cys_wxc}/Core/FrameStatsListener.cpp"
    "${_cys_wxc}/Core/SceneNodeSwitcher.cpp"
    "${_cys_wxc}/Core/SerializerUtil.cpp"
    "${_cys_wxc}/Core/Terrain.cpp"
    "${_cys_wxc}/Core/TerrainData.cpp"
    "${_cys_wxc}/Core/TerrainDataSerializer.cpp"
    "${_cys_wxc}/Core/TerrainTile.cpp"
    "${_cys_wxc}/Core/TerrainTileEditable.cpp"
    "${_cys_wxc}/Core/TerrainTileOptimized.cpp"
    "${_cys_wxc}/Core/TerrainTileRenderable.cpp"
    "${_cys_wxc}/Core/TerrainTypeInfos.cpp"
    "${_cys_wxc}/Core/utf.cpp"
    "${_cys_wxc}/Core/WXActor.cpp"
    "${_cys_wxc}/Core/WXActorObject.cpp"
    "${_cys_wxc}/Core/WXCollisionModel.cpp"
    "${_cys_wxc}/Core/WXCollisionModelManager.cpp"
    "${_cys_wxc}/Core/WXEffectObject.cpp"
    "${_cys_wxc}/Core/WXEnviromentObject.cpp"
    "${_cys_wxc}/Core/WXExpatParser.cpp"
    "${_cys_wxc}/Core/WXFactory.cpp"
    "${_cys_wxc}/Core/WXLightObject.cpp"
    "${_cys_wxc}/Core/WXLogicModelObject.cpp"
    "${_cys_wxc}/Core/WXMaterialInstance.cpp"
    "${_cys_wxc}/Core/WXMaterialScriptSolver.cpp"
    "${_cys_wxc}/Core/WXMeshInformer.cpp"
    "${_cys_wxc}/Core/WXModel.cpp"
    "${_cys_wxc}/Core/WXModelObject.cpp"
    "${_cys_wxc}/Core/WXObject.cpp"
    "${_cys_wxc}/Core/WXObjectFactory.cpp"
    "${_cys_wxc}/Core/WXObjectFactoryManager.cpp"
    "${_cys_wxc}/Core/WXObjectProxy.cpp"
    "${_cys_wxc}/Core/WXParticleSystemObject.cpp"
    "${_cys_wxc}/Core/WXPlacementObject.cpp"
    "${_cys_wxc}/Core/WXProjector.cpp"
    "${_cys_wxc}/Core/WXPropertyHelper.cpp"
    "${_cys_wxc}/Core/WXPropertyInterface.cpp"
    "${_cys_wxc}/Core/WXRayCollide.cpp"
    "${_cys_wxc}/Core/WXResources.cpp"
    "${_cys_wxc}/Core/WXResourceSolver.cpp"
    "${_cys_wxc}/Core/WXResourceSolverHelper.cpp"
    "${_cys_wxc}/Core/WXScene.cpp"
    "${_cys_wxc}/Core/WXSceneInfo.cpp"
    "${_cys_wxc}/Core/WXSceneSerializer.cpp"
    "${_cys_wxc}/Core/WXSceneSolver.cpp"
    "${_cys_wxc}/Core/WXSkyBoxObject.cpp"
    "${_cys_wxc}/Core/WXSkyDomeObject.cpp"
    "${_cys_wxc}/Core/WXSkyPlaneObject.cpp"
    "${_cys_wxc}/Core/WXStaticEntityObject.cpp"
    "${_cys_wxc}/Core/WXSystem.cpp"
    "${_cys_wxc}/Core/WXTerrainLiquid.cpp"
    "${_cys_wxc}/Core/WXTerrainLiquidObject.cpp"
    "${_cys_wxc}/Core/WXTerrainProjector.cpp"
    "${_cys_wxc}/Core/WXTerrainSolver.cpp"
    "${_cys_wxc}/Core/WXTransform.cpp"
    "${_cys_wxc}/Core/WXTransparentor.cpp"
    "${_cys_wxc}/Core/WXUtils.cpp"
    "${_cys_wxc}/Core/WXXMLAttributes.cpp"
    "${_cys_wxc}/Core/WXXMLHandler.cpp"
    "${_cys_wxc}/Core/WXXMLNode.cpp"
    "${_cys_wxc}/Core/WXXMLParser.cpp"
    "${_cys_wxc}/Core/WXXMLWriter.cpp"
    "${_cys_wxc}/EffectSystem/WXAnimationEffectInfo.cpp"
    "${_cys_wxc}/EffectSystem/WXAnimationRibbon.cpp"
    "${_cys_wxc}/EffectSystem/WXAnimationSceneLightInfo.cpp"
    "${_cys_wxc}/EffectSystem/WXAnimationSound.cpp"
    "${_cys_wxc}/EffectSystem/WXBeamElement.cpp"
    "${_cys_wxc}/EffectSystem/WXBillboardSetElement.cpp"
    "${_cys_wxc}/EffectSystem/WXEffect.cpp"
    "${_cys_wxc}/EffectSystem/WXEffectBasic.cpp"
    "${_cys_wxc}/EffectSystem/WXEffectElement.cpp"
    "${_cys_wxc}/EffectSystem/WXEffectElementFactory.cpp"
    "${_cys_wxc}/EffectSystem/WXEffectManager.cpp"
    "${_cys_wxc}/EffectSystem/WXMainSceneLight.cpp"
    "${_cys_wxc}/EffectSystem/WXMeshElement.cpp"
    "${_cys_wxc}/EffectSystem/WXParticleElement.cpp"
    "${_cys_wxc}/EffectSystem/WXPointLightElement.cpp"
    "${_cys_wxc}/EffectSystem/WXProjectorElement.cpp"
    "${_cys_wxc}/EffectSystem/WXSkill.cpp"
    "${_cys_wxc}/ModelSystem/SkeletonMesh.cpp"
    "${_cys_wxc}/ModelSystem/SkeletonMeshEditable.cpp"
    "${_cys_wxc}/ModelSystem/SkeletonMeshUtil.cpp"
    "${_cys_wxc}/ModelSystem/WXLogicModel.cpp"
    "${_cys_wxc}/ModelSystem/WXLogicModelManager.cpp"
    "${_cys_wxc}/OgreExt/OgreAutoAnimationEntity.cpp"
    "${_cys_wxc}/OgreExt/OgreBillboardChain.cpp"
    "${_cys_wxc}/OgreExt/OgreMeshAnimationAffector.cpp"
    "${_cys_wxc}/OgreExt/OgreMeshParticleRenderer.cpp"
    "${_cys_wxc}/OgreExt/OgreMeshParticleVisualData.cpp"
    "${_cys_wxc}/OgreExt/OgreMeshRotationAffector.cpp"
    "${_cys_wxc}/OgreExt/OgreRibbonRenderer.cpp"
    "${_cys_wxc}/OgreExt/OgreRibbonSet.cpp"
    "${_cys_wxc}/OgreExt/OgreTexCoordBillboardParticleRenderer.cpp"
    "${_cys_wxc}/PostFilter/WXBloomPostFilter.cpp"
    "${_cys_wxc}/PostFilter/WXFadePostFilter.cpp"
    "${_cys_wxc}/PostFilter/WXFloodlightingPostFilter.cpp"
    "${_cys_wxc}/PostFilter/WXHeatVisionPostFilter.cpp"
    "${_cys_wxc}/PostFilter/WXMotionBlurPostFilter.cpp"
    "${_cys_wxc}/PostFilter/WXPostFilter.cpp"
    "${_cys_wxc}/PostFilter/WXPostFilterManager.cpp"
    "${_cys_wxc}/PostFilter/WXPostFilters.cpp"
    "${_cys_wxc}/ResourceSystem/WXPakFileSystem.cpp")
target_include_directories(cys_wxcore PUBLIC
    "${_cys_wxc}"
    "${CYS_SRC}/Engine/Scorpio/include")
target_compile_definitions(cys_wxcore PUBLIC MODELSYSTEM_STATIC_LINK)
target_link_libraries(cys_wxcore PUBLIC cys_wx_ogre cys_wx_boost cys_opcode cys_tinyxml cys_expat)
if(TARGET cys_scorpio)
    # INTERFACE only: consumers link Plugin_Scorpio.lib, but WXCore.lib itself must not wait for the DLL link.
    target_link_libraries(cys_wxcore INTERFACE cys_scorpio)
endif()
if(MSVC)
    # /bigobj: boost multi_index/lambda heavy TUs; pointer-truncation warnings kept visible for the x64 port.
    target_compile_options(cys_wxcore PRIVATE /bigobj /w14311 /w14312 /w14302)
endif()
set_target_properties(cys_wxcore PROPERTIES OUTPUT_NAME WXCore FOLDER Engine)

# CYS: mã mới của CY-Source cho WXCore đặt trong Engine/WXCore/CYS/<tính-năng>/ và được gom tự động,
# để nhiều agent thêm file song song mà không phải sửa danh sách nguồn ở trên.
file(GLOB_RECURSE _cys_wxc_new CONFIGURE_DEPENDS "${_cys_wxc}/CYS/*.cpp")
if(_cys_wxc_new)
    target_sources(cys_wxcore PRIVATE ${_cys_wxc_new})
endif()
