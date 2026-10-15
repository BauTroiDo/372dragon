# CYS component: WXRender -> Render.dll, the tEngine "Gfx" plugin (CRenderSystem, CResourceProvider, cameras, RF
# objects, fake-object render targets) on top of WXCore. Game.exe loads it with tKernel::LoadPlugin("Render.dll");
# exports DllInit/DllRelease (WXRender.def).
# Old project: Engine/WXRender/WXRender.vcxproj (19 sources, MultiByte, RENDER_FAIRY_EXPORTS, MODELSYSTEM_STATIC_LINK;
# links WXCore, OgreMain, expat, Opcode, tinyxml, WXEngine, winmm). HardwareInfoSystem/DummyObject/EffectObj/
# HelpPanel/ProcessBar/WXObj.cpp are on disk but in neither 0.85 project (they reference old Fairy* headers).
# WXRender.rc needs MFC's afxres.h and was not built by 0.85 either; it is left out.

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

set(_cys_wxr "${CYS_SRC}/Engine/WXRender")
add_library(cys_wxrender SHARED
    "${_cys_wxr}/Camera/Camera.cpp"
    "${_cys_wxr}/Camera/Camera_CharSel.cpp"
    "${_cys_wxr}/Camera/Camera_Scene.cpp"
    "${_cys_wxr}/DebugPanel.cpp"
    "${_cys_wxr}/Global.cpp"
    "${_cys_wxr}/MaterialSystem/CysMaterialSystem.cpp" # CYS: runtime material system (VS pairing, variants)
    "${_cys_wxr}/Object/RFObj.cpp"
    "${_cys_wxr}/Object/RFObjDummy.cpp"
    "${_cys_wxr}/Object/RFObject.cpp"
    "${_cys_wxr}/Object/RFObj_Actor.cpp"
    "${_cys_wxr}/Object/RFObj_Model.cpp"
    "${_cys_wxr}/Object/RFObj_Static.cpp"
    "${_cys_wxr}/Render.cpp"
    "${_cys_wxr}/RenderSystem.cpp"
    "${_cys_wxr}/ResourceLoadListener.cpp"
    "${_cys_wxr}/ResourceProvider.cpp"
    "${_cys_wxr}/RFFakeObjectManager.cpp"
    "${_cys_wxr}/stdafx.cpp"
    "${_cys_wxr}/TerrainGrid.cpp"
    "${_cys_wxr}/WXObj_ProjTex.cpp"
    "${_cys_wxr}/WXRender.def")
target_include_directories(cys_wxrender PRIVATE "${_cys_wxr}")
target_compile_definitions(cys_wxrender PRIVATE _USRDLL RENDER_FAIRY_EXPORTS _MBCS)
target_link_libraries(cys_wxrender PRIVATE cys_wxcore cys_wxengine cys_wx_ogre cys_wx_boost winmm)
if(MSVC)
    target_compile_options(cys_wxrender PRIVATE /bigobj /w14311 /w14312 /w14302)
endif()
set_target_properties(cys_wxrender PROPERTIES OUTPUT_NAME Render PREFIX "" FOLDER Engine)
