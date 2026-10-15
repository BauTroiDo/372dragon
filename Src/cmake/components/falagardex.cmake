# CYS component: CEGUIFalagardEx - the TLBB widget set (ActionButton, MiniMap, Radar, SuperTooltip, ChatHistory,
# ComplexWindow, SoftKeyBoard, ...) on top of Falagard - static library.
# Old project: Client/CEGUIFalagardEx/CEGUIFalagardEx.vcxproj (47 sources + ..\Common\AxTrace.cpp = Engine/Interface,
# static, MultiByte, FALAGARDBASE_EXPORTS). As in 0.85 (CEGUIFalagard.vcxproj ProjectReference -> CEGUIFalagardEx) it is
# linked INTO CEGUIFalagard.dll: FalModule.cpp there registers these factories, and FALAGARDBASE_EXPORTS makes the classes
# dllexport from that DLL (the modern client's CEGUIFalagard.dll exports FalagardActionButton etc. as well).
# Left out like in 0.85 (in no project): FalagardEditBox, FalagardChatEditBox, FalagardImageListEx/Item,
# FalagardNumberEditBox, FalChat/ImageList(Ex)Properties, FalChatMotionSelecter* (empty files).
# Target: cys_falagardex (PUBLIC include dir = Src/Client/CEGUIFalagardEx).
set(_cys_fex "${CYS_SRC}/Client/CEGUIFalagardEx")
add_library(cys_falagardex STATIC
    "${CYS_SRC}/Engine/Interface/AxTrace.cpp"
    "${_cys_fex}/FalActionButton.cpp"
    "${_cys_fex}/FalActionButtonProperties.cpp"
    "${_cys_fex}/FalagardAnimate.cpp"
    "${_cys_fex}/FalagardStar.cpp"
    "${_cys_fex}/FalagardLoginWidgets.cpp"
    "${_cys_fex}/FalagardNotSuperList.cpp"
    "${_cys_fex}/FalagardListBoxEx.cpp"
    "${_cys_fex}/FalagardParticleSystem.cpp"
    "${_cys_fex}/FalagardScrollInfo.cpp"
    "${_cys_fex}/FalagardAchievementWindow.cpp"
    "${_cys_fex}/FalagardDragDropTarget.cpp"
    "${_cys_fex}/FalagardSuperBarButton.cpp"
    "${_cys_fex}/CysStoredProperties.cpp"
    "${_cys_fex}/FalagardCyWidgets.cpp"   # CYS-CYGUI: CY 3.71 window types
    "${_cys_fex}/FalagardMapImage.cpp"
    "${_cys_fex}/FalagardBeHitBoard.cpp"
    "${_cys_fex}/FalagardCheckButton.cpp"
    "${_cys_fex}/FalagardComplexWindow.cpp"
    "${_cys_fex}/FalagardComplexWindowProperties.cpp"
    "${_cys_fex}/FalagardInfoList.cpp"
    "${_cys_fex}/FalagardMeshWindow.cpp"
    "${_cys_fex}/FalagardMeshWindowProperties.cpp"
    "${_cys_fex}/FalagardMiniMap.cpp"
    "${_cys_fex}/FalagardPaoPao.cpp"
    "${_cys_fex}/FalagardRadar.cpp"
    "${_cys_fex}/FalagardResizeText.cpp"
    "${_cys_fex}/FalagardRewardItem.cpp"
    "${_cys_fex}/FalagardSceneMap.cpp"
    "${_cys_fex}/FalagardSelfFitWindow.cpp"
    "${_cys_fex}/FalagardSoftKeyBoard.cpp"
    "${_cys_fex}/FalagardSuperProgress.cpp"
    "${_cys_fex}/FalagardWorldMap.cpp"
    "${_cys_fex}/FalagardWorldMapProperties.cpp"
    "${_cys_fex}/FalAnimateProperties.cpp"
    "${_cys_fex}/FalBoundWindow.cpp"
    "${_cys_fex}/FalBoundWindowProperties.cpp"
    "${_cys_fex}/FalChatBoard.cpp"
    "${_cys_fex}/FalChatBoardProperties.cpp"
    "${_cys_fex}/FalChatChannel.cpp"
    "${_cys_fex}/FalChatChannelProperties.cpp"
    "${_cys_fex}/FalChatHistory.cpp"
    "${_cys_fex}/FalChatHistoryProperties.cpp"
    "${_cys_fex}/FalCreatureBoard.cpp"
    "${_cys_fex}/FalCreatureBoardProperties.cpp"
    "${_cys_fex}/FalDragTitle.cpp"
    "${_cys_fex}/FalDragTitleProperties.cpp"
    "${_cys_fex}/FalIMEEditBox.cpp"
    "${_cys_fex}/FalIMEEditBoxProperties.cpp"
    "${_cys_fex}/FalMinimapProperties.cpp"
    "${_cys_fex}/FalMoney.cpp"
    "${_cys_fex}/FalMoneyProperties.cpp"
    "${_cys_fex}/FalMultiIMEEditBox.cpp"
    "${_cys_fex}/FalMultiIMEEditBoxProperties.cpp"
    "${_cys_fex}/FalSimpleText.cpp"
    "${_cys_fex}/FalSimpleTextProperties.cpp"
    "${_cys_fex}/FalStopWatch.cpp"
    "${_cys_fex}/FalStopWatchProperties.cpp"
    "${_cys_fex}/FalSuperTooltip.cpp"
    "${_cys_fex}/FalSuperTooltipProperties.cpp")
# Falagard headers (FalButton.h, FalModule.h ...) come straight from the widget-set dir: cys_falagardex cannot link
# cys_ceguifalagard (that DLL links this library). Engine/Interface: AxTrace.h (CYS include fix in 2 files).
target_include_directories(cys_falagardex
    PUBLIC  "${_cys_fex}"
    PRIVATE "${CYS_TP}/CEGUI-0.4.1/CEGUI/WidgetSets/Falagard/include" "${CYS_SRC}/Engine/Interface")
target_compile_definitions(cys_falagardex PRIVATE FALAGARDBASE_EXPORTS _LIB _MBCS)
# cys_ceguiogrerenderer only for OgreCEGUIRenderer.h (FalagardMeshWindow.cpp); an import is only recorded if used.
target_link_libraries(cys_falagardex
    PUBLIC  cys_ceguibase cys_wx_ogre cys_wx_boost
    PRIVATE cys_ceguiogrerenderer)
if(MSVC)
    target_compile_options(cys_falagardex PRIVATE /w14311 /w14312 /w14302)
endif()
set_target_properties(cys_falagardex PROPERTIES OUTPUT_NAME CEGUIFalagardEx FOLDER UI)

if(TARGET cys_ceguifalagard)
    target_link_libraries(cys_ceguifalagard PRIVATE cys_falagardex)
endif()
