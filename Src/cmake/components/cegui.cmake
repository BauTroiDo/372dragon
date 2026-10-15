# CYS component: CEGUI 0.4.1 with the TLBB/Fairy changes (Src/ThirdParty/CEGUI-0.4.1) -> three DLLs.
#
# Targets (SHARED; output names = the file names the client ships and loads):
#   cys_ceguibase         -> CEGUIBase.dll         (0.85: !Scripts/VC7.1/CEGUIBase.vcxproj, TargetName UIBase)
#   cys_ceguifalagard     -> CEGUIFalagard.dll     (0.85: CEGUIFalagard.vcxproj, TargetName UIFrame)
#   cys_ceguiogrerenderer -> CEGUIOgreRenderer.dll (0.85: CEGUIOgreRenderer.vcxproj, a STATIC lib linked into UI_CEGUI)
#
# CEGUIBase: the 154 sources of the 0.85 project = core + elements + falagard + the TLBB additions (Animate, HyperLink,
#   Ime) + the bundled PCRE 5.0 (compiled in; its dllimport block is commented out in pcre.h) + the expat parser module
#   (CEGUISystem.cpp:67-68 hard-wires CEGUI_DEFAULT_XMLPARSER = ExpatParser; Xerces/TinyXML parsers are not built).
#   FreeType and expat are linked statically, as in the modern client (its CEGUIBase.dll imports SHLWAPI/USER32 only).
# CEGUIFalagard: the Falagard widget set plus the TLBB widgets of Src/Client/CEGUIFalagardEx (static cys_falagardex,
#   attached by falagardex.cmake). 0.85 did the same (ProjectReference CEGUIFalagard -> CEGUIFalagardEx); FalModule.cpp
#   registers both factory sets, so CEGUIFalagard.dll needs the falagardex component. Loaded at runtime by
#   CEGUI::FactoryModule for the scheme's <WindowSet>; UI_CEGUI.dll does not link it.
# CEGUIOgreRenderer: OgreCEGUIRenderer.h already switches OGRE_GUIRENDERER_API between dllexport/dllimport, so it is
#   built as a DLL like the modern client (whose UI_CEGUI.dll imports CEGUIOgreRenderer.dll).

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

set(_cys_cegui "${CYS_TP}/CEGUI-0.4.1")
set(_cys_cg "${_cys_cegui}/CEGUI")
set(_cys_cgfal "${_cys_cg}/WidgetSets/Falagard")
set(_cys_cgogre "${_cys_cegui}/CEGUIRenderer")

# ---- CEGUIBase.dll -------------------------------------------------------------------------------------------------
add_library(cys_ceguibase SHARED
    "${_cys_cg}/src/CysUnicodeText.cpp" # CYS: compose displayed Vietnamese before glyph lookup.
    "${_cys_cg}/expatParser/CEGUIExpatParser.cpp"
    "${_cys_cg}/src/AxTrace.cpp"
    "${_cys_cg}/src/CEGUIAnimate.cpp"
    "${_cys_cg}/src/CEGUIAnimateManager.cpp"
    "${_cys_cg}/src/CEGUIAnimate_xmlHandler.cpp"
    "${_cys_cg}/src/CEGUIBase.cpp"
    "${_cys_cg}/src/CEGUIcolour.cpp"
    "${_cys_cg}/src/CEGUIColourRect.cpp"
    "${_cys_cg}/src/CEGUIConfig_xmlHandler.cpp"
    "${_cys_cg}/src/CEGUIDefaultResourceProvider.cpp"
    "${_cys_cg}/src/CEGUIEvent.cpp"
    "${_cys_cg}/src/CEGUIEventArgs.cpp"
    "${_cys_cg}/src/CEGUIEventSet.cpp"
    "${_cys_cg}/src/CEGUIEventSignal.cpp"
    "${_cys_cg}/src/CEGUIEventSignalSet.cpp"
    "${_cys_cg}/src/CEGUIExceptions.cpp"
    "${_cys_cg}/src/CEGUIFactoryModule.cpp"
    "${_cys_cg}/src/CEGUIFontBase.cpp"
    "${_cys_cg}/src/CEGUIFontManager.cpp"
    "${_cys_cg}/src/CEGUIFont_Bitmap.cpp"
    "${_cys_cg}/src/CEGUIFont_FreeType.cpp"
    "${_cys_cg}/src/CEGUIFont_xmlHandler.cpp"
    "${_cys_cg}/src/CEGUIGlobalEventSet.cpp"
    "${_cys_cg}/src/CEGUIGUILayout_xmlHandler.cpp"
    "${_cys_cg}/src/CEGUIHyperLink.cpp"
    "${_cys_cg}/src/CEGUIHyperLinkManager.cpp"
    "${_cys_cg}/src/CEGUIImage.cpp"
    "${_cys_cg}/src/CEGUIImageset.cpp"
    "${_cys_cg}/src/CEGUIImagesetManager.cpp"
    "${_cys_cg}/src/CEGUIImageset_xmlHandler.cpp"
    "${_cys_cg}/src/CEGUIIme.cpp"
    "${_cys_cg}/src/CEGUILogger.cpp"
    "${_cys_cg}/src/CEGUIMouseCursor.cpp"
    "${_cys_cg}/src/CEGUIProperty.cpp"
    "${_cys_cg}/src/CEGUIPropertyHelper.cpp"
    "${_cys_cg}/src/CEGUIPropertySet.cpp"
    "${_cys_cg}/src/CEGUIRect.cpp"
    "${_cys_cg}/src/CEGUIRefPtr.cpp"
    "${_cys_cg}/src/CEGUIRenderableElement.cpp"
    "${_cys_cg}/src/CEGUIRenderableFrame.cpp"
    "${_cys_cg}/src/CEGUIRenderableImage.cpp"
    "${_cys_cg}/src/CEGUIRenderCache.cpp"
    "${_cys_cg}/src/CEGUIRenderer.cpp"
    "${_cys_cg}/src/CEGUIScheme.cpp"
    "${_cys_cg}/src/CEGUISchemeManager.cpp"
    "${_cys_cg}/src/CEGUIScheme_xmlHandler.cpp"
    "${_cys_cg}/src/CEGUIScriptModule.cpp"
    "${_cys_cg}/src/CEGUISize.cpp"
    "${_cys_cg}/src/CEGUIString.cpp"
    "${_cys_cg}/src/CEGUISystem.cpp"
    "${_cys_cg}/src/CEGUITexture.cpp"
    "${_cys_cg}/src/CEGUITextUtils.cpp"
    "${_cys_cg}/src/CEGUIVector.cpp"
    "${_cys_cg}/src/CEGUIWin32XMLSelectHack.cpp"
    "${_cys_cg}/src/CEGUIWindow.cpp"
    "${_cys_cg}/src/CEGUIWindowFactory.cpp"
    "${_cys_cg}/src/CEGUIWindowFactoryManager.cpp"
    "${_cys_cg}/src/CEGUIWindowManager.cpp"
    "${_cys_cg}/src/CEGUIWindowProperties.cpp"
    "${_cys_cg}/src/CEGUIXMLAttributes.cpp"
    "${_cys_cg}/src/CEGUIXMLHandler.cpp"
    "${_cys_cg}/src/CEGUIXMLParser.cpp"
    "${_cys_cg}/src/elements/CEGUIButtonBase.cpp"
    "${_cys_cg}/src/elements/CEGUIButtonBaseProperties.cpp"
    "${_cys_cg}/src/elements/CEGUICheckbox.cpp"
    "${_cys_cg}/src/elements/CEGUICheckboxProperties.cpp"
    "${_cys_cg}/src/elements/CEGUICombobox.cpp"
    "${_cys_cg}/src/elements/CEGUIComboboxProperties.cpp"
    "${_cys_cg}/src/elements/CEGUIComboDropList.cpp"
    "${_cys_cg}/src/elements/CEGUIDragContainer.cpp"
    "${_cys_cg}/src/elements/CEGUIDragContainerProperties.cpp"
    "${_cys_cg}/src/elements/CEGUIEditbox.cpp"
    "${_cys_cg}/src/elements/CEGUIEditboxProperties.cpp"
    "${_cys_cg}/src/elements/CEGUIFrameWindow.cpp"
    "${_cys_cg}/src/elements/CEGUIFrameWindowProperties.cpp"
    "${_cys_cg}/src/elements/CEGUIGUISheet.cpp"
    "${_cys_cg}/src/elements/CEGUIItemEntry.cpp"
    "${_cys_cg}/src/elements/CEGUIItemListBase.cpp"
    "${_cys_cg}/src/elements/CEGUIItemListBaseProperties.cpp"
    "${_cys_cg}/src/elements/CEGUIListbox.cpp"
    "${_cys_cg}/src/elements/CEGUIListboxItem.cpp"
    "${_cys_cg}/src/elements/CEGUIListboxProperties.cpp"
    "${_cys_cg}/src/elements/CEGUIListboxTextItem.cpp"
    "${_cys_cg}/src/elements/CEGUIListHeader.cpp"
    "${_cys_cg}/src/elements/CEGUIListHeaderProperties.cpp"
    "${_cys_cg}/src/elements/CEGUIListHeaderSegment.cpp"
    "${_cys_cg}/src/elements/CEGUIListHeaderSegmentProperties.cpp"
    "${_cys_cg}/src/elements/CEGUIMenubar.cpp"
    "${_cys_cg}/src/elements/CEGUIMenuBase.cpp"
    "${_cys_cg}/src/elements/CEGUIMenuBaseProperties.cpp"
    "${_cys_cg}/src/elements/CEGUIMenuItem.cpp"
    "${_cys_cg}/src/elements/CEGUIMenuItemProperties.cpp"
    "${_cys_cg}/src/elements/CEGUIMultiColumnList.cpp"
    "${_cys_cg}/src/elements/CEGUIMultiColumnListProperties.cpp"
    "${_cys_cg}/src/elements/CEGUIMultiLineEditbox.cpp"
    "${_cys_cg}/src/elements/CEGUIMultiLineEditboxProperties.cpp"
    "${_cys_cg}/src/elements/CEGUIPopupMenu.cpp"
    "${_cys_cg}/src/elements/CEGUIPopupMenuProperties.cpp"
    "${_cys_cg}/src/elements/CEGUIProgressBar.cpp"
    "${_cys_cg}/src/elements/CEGUIProgressBarProperties.cpp"
    "${_cys_cg}/src/elements/CEGUIPushButton.cpp"
    "${_cys_cg}/src/elements/CEGUIPushButtonProperties.cpp"
    "${_cys_cg}/src/elements/CEGUIRadioButton.cpp"
    "${_cys_cg}/src/elements/CEGUIRadioButtonProperties.cpp"
    "${_cys_cg}/src/elements/CEGUIScrollablePane.cpp"
    "${_cys_cg}/src/elements/CEGUIScrollablePaneProperties.cpp"
    "${_cys_cg}/src/elements/CEGUIScrollbar.cpp"
    "${_cys_cg}/src/elements/CEGUIScrollbarProperties.cpp"
    "${_cys_cg}/src/elements/CEGUIScrolledContainer.cpp"
    "${_cys_cg}/src/elements/CEGUIScrolledContainerProperties.cpp"
    "${_cys_cg}/src/elements/CEGUISlider.cpp"
    "${_cys_cg}/src/elements/CEGUISliderProperties.cpp"
    "${_cys_cg}/src/elements/CEGUISpinner.cpp"
    "${_cys_cg}/src/elements/CEGUISpinnerProperties.cpp"
    "${_cys_cg}/src/elements/CEGUIStatic.cpp"
    "${_cys_cg}/src/elements/CEGUIStaticImage.cpp"
    "${_cys_cg}/src/elements/CEGUIStaticImageProperties.cpp"
    "${_cys_cg}/src/elements/CEGUIStaticProperties.cpp"
    "${_cys_cg}/src/elements/CEGUIStaticText.cpp"
    "${_cys_cg}/src/elements/CEGUIStaticTextProperties.cpp"
    "${_cys_cg}/src/elements/CEGUITabButton.cpp"
    "${_cys_cg}/src/elements/CEGUITabControl.cpp"
    "${_cys_cg}/src/elements/CEGUITabControlProperties.cpp"
    "${_cys_cg}/src/elements/CEGUITextItem.cpp"
    "${_cys_cg}/src/elements/CEGUITextItemProperties.cpp"
    "${_cys_cg}/src/elements/CEGUIThumb.cpp"
    "${_cys_cg}/src/elements/CEGUIThumbProperties.cpp"
    "${_cys_cg}/src/elements/CEGUITitlebar.cpp"
    "${_cys_cg}/src/elements/CEGUITitlebarProperties.cpp"
    "${_cys_cg}/src/elements/CEGUITooltip.cpp"
    "${_cys_cg}/src/elements/CEGUITooltipProperties.cpp"
    "${_cys_cg}/src/falagard/CEGUIFalagard_xmlHandler.cpp"
    "${_cys_cg}/src/falagard/CEGUIFalComponentBase.cpp"
    "${_cys_cg}/src/falagard/CEGUIFalDimensions.cpp"
    "${_cys_cg}/src/falagard/CEGUIFalFrameComponent.cpp"
    "${_cys_cg}/src/falagard/CEGUIFalImageryComponent.cpp"
    "${_cys_cg}/src/falagard/CEGUIFalImagerySection.cpp"
    "${_cys_cg}/src/falagard/CEGUIFalLayerSpecification.cpp"
    "${_cys_cg}/src/falagard/CEGUIFalNamedArea.cpp"
    "${_cys_cg}/src/falagard/CEGUIFalPropertyDefinition.cpp"
    "${_cys_cg}/src/falagard/CEGUIFalPropertyInitialiser.cpp"
    "${_cys_cg}/src/falagard/CEGUIFalSectionSpecification.cpp"
    "${_cys_cg}/src/falagard/CEGUIFalStateImagery.cpp"
    "${_cys_cg}/src/falagard/CEGUIFalTextComponent.cpp"
    "${_cys_cg}/src/falagard/CEGUIFalWidgetComponent.cpp"
    "${_cys_cg}/src/falagard/CEGUIFalWidgetLookFeel.cpp"
    "${_cys_cg}/src/falagard/CEGUIFalWidgetLookManager.cpp"
    "${_cys_cg}/src/falagard/CEGUIFalXMLEnumHelper.cpp"
    "${_cys_cg}/src/pcre/chartables.c"
    "${_cys_cg}/src/pcre/get.c"
    "${_cys_cg}/src/pcre/maketables.c"
    "${_cys_cg}/src/pcre/pcre.c"
    "${_cys_cg}/src/pcre/pcreposix.c"
    "${_cys_cg}/src/pcre/study.c")
target_include_directories(cys_ceguibase
    PUBLIC  "${_cys_cg}/include"
    PRIVATE "${_cys_cg}/src" "${_cys_cg}/expatParser")
target_compile_definitions(cys_ceguibase PRIVATE CEGUIBASE_EXPORTS _USRDLL)
target_link_libraries(cys_ceguibase PRIVATE cys_freetype cys_expat shlwapi user32 normaliz) # CYS: Windows NFC.
if(MSVC)
    # Pointer-truncation warnings kept visible for the x64 port (as on the WX targets).
    target_compile_options(cys_ceguibase PRIVATE /w14311 /w14312 /w14302)
endif()
set_target_properties(cys_ceguibase PROPERTIES OUTPUT_NAME CEGUIBase FOLDER UI)

# ---- CEGUIFalagard.dll ---------------------------------------------------------------------------------------------
add_library(cys_ceguifalagard SHARED
    "${_cys_cgfal}/src/FalButton.cpp"
    "${_cys_cgfal}/src/FalCheckbox.cpp"
    "${_cys_cgfal}/src/FalCombobox.cpp"
    "${_cys_cgfal}/src/FalComboDropList.cpp"
    "${_cys_cgfal}/src/FalEditbox.cpp"
    "${_cys_cgfal}/src/FalFrameWindow.cpp"
    "${_cys_cgfal}/src/FalListbox.cpp"
    "${_cys_cgfal}/src/FalListHeader.cpp"
    "${_cys_cgfal}/src/FalListHeaderProperties.cpp"
    "${_cys_cgfal}/src/FalListHeaderSegment.cpp"
    "${_cys_cgfal}/src/FalListHeaderSegmentProperties.cpp"
    "${_cys_cgfal}/src/FalMenuBar.cpp"
    "${_cys_cgfal}/src/FalMenuItem.cpp"
    "${_cys_cgfal}/src/FalModule.cpp"
    "${_cys_cgfal}/src/FalMultiColumnList.cpp"
    "${_cys_cgfal}/src/FalMultiLineEditbox.cpp"
    "${_cys_cgfal}/src/FalMultiLineEditboxProperties.cpp"
    "${_cys_cgfal}/src/FalPopupMenu.cpp"
    "${_cys_cgfal}/src/FalProgressBar.cpp"
    "${_cys_cgfal}/src/FalProgressBarProperties.cpp"
    "${_cys_cgfal}/src/FalRadioButton.cpp"
    "${_cys_cgfal}/src/FalScrollablePane.cpp"
    "${_cys_cgfal}/src/FalScrollbar.cpp"
    "${_cys_cgfal}/src/FalScrollbarProperties.cpp"
    "${_cys_cgfal}/src/FalSlider.cpp"
    "${_cys_cgfal}/src/FalSliderProperties.cpp"
    "${_cys_cgfal}/src/FalSpinner.cpp"
    "${_cys_cgfal}/src/FalStaticImage.cpp"
    "${_cys_cgfal}/src/FalStaticText.cpp"
    "${_cys_cgfal}/src/FalSystemButton.cpp"
    "${_cys_cgfal}/src/FalTabButton.cpp"
    "${_cys_cgfal}/src/FalTabControl.cpp"
    "${_cys_cgfal}/src/FalTabControlProperties.cpp"
    "${_cys_cgfal}/src/FalTabPane.cpp"
    "${_cys_cgfal}/src/FalThumb.cpp"
    "${_cys_cgfal}/src/FalTitlebar.cpp"
    "${_cys_cgfal}/src/FalTooltip.cpp")
# Src/Client: FalModule.cpp includes "CEGUIFalagardEx/<widget>.h" (CYS edit of the 0.85 "../../../" paths).
target_include_directories(cys_ceguifalagard
    PUBLIC  "${_cys_cgfal}/include"
    PRIVATE "${CYS_SRC}/Client")
target_compile_definitions(cys_ceguifalagard PRIVATE FALAGARDBASE_EXPORTS _USRDLL)
# OgreMain: the FalagardEx widgets use Ogre::Root/Timer (0.85 linked Main.lib; the modern DLL imports OgreMain.dll).
target_link_libraries(cys_ceguifalagard PUBLIC cys_ceguibase PRIVATE cys_wx_ogre cys_wx_boost user32)
if(MSVC)
    target_compile_options(cys_ceguifalagard PRIVATE /w14311 /w14312 /w14302)
    # /EHc-: FalModule.cpp's extern "C" registerFactory throws UnknownObjectException for an unknown widget type
    # (C4297 under /EHsc = undefined, in practice std::terminate); with /EHc- the exception reaches CEGUI's caller.
    target_compile_options(cys_ceguifalagard PRIVATE $<$<COMPILE_LANGUAGE:CXX>:/EHc->)
endif()
set_target_properties(cys_ceguifalagard PROPERTIES OUTPUT_NAME CEGUIFalagard FOLDER UI)

# ---- CEGUIOgreRenderer.dll -----------------------------------------------------------------------------------------
add_library(cys_ceguiogrerenderer SHARED
    "${_cys_cgogre}/src/OgreCEGUIRenderer.cpp"
    "${_cys_cgogre}/src/OgreCEGUIResourceProvider.cpp"
    "${_cys_cgogre}/src/OgreCEGUITexture.cpp")
target_include_directories(cys_ceguiogrerenderer PUBLIC "${_cys_cgogre}/include")
target_compile_definitions(cys_ceguiogrerenderer PRIVATE OGRE_GUIRENDERER_EXPORTS _USRDLL)
target_link_libraries(cys_ceguiogrerenderer PUBLIC cys_ceguibase cys_wx_ogre cys_wx_boost)
if(MSVC)
    target_compile_options(cys_ceguiogrerenderer PRIVATE /w14311 /w14312 /w14302)
endif()
set_target_properties(cys_ceguiogrerenderer PROPERTIES OUTPUT_NAME CEGUIOgreRenderer FOLDER UI)
