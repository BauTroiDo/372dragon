# CYS component: TinyXML 2.x - static library (used by WXCore ModelSystem: SkeletonMeshUtil, WXLogicModelManager).
# Old project: ThirdParty/tinyxml/tinyxml_lib.vcproj (/MT, no TIXML_USE_STL). We build /MD (global
# CMAKE_MSVC_RUNTIME_LIBRARY) and WITH TIXML_USE_STL: both consumers do `#define TIXML_USE_STL` before
# <tinyxml.h> (WXLogicModelManager.cpp:35, SkeletonMeshUtil.cpp:12), and a non-STL library gives them a different
# class layout/vtable (TiXmlString vs std::string; Render.dll failed with unresolved TiXmlDocument::StreamIn/Out).
# Defined PUBLIC as empty ("TIXML_USE_STL=") so the consumers' identical #define is not a redefinition (C4005).
# xmltest.cpp is a test program (has main) and is not part of the library.
set(_cys_txml "${CYS_TP}/tinyxml")
add_library(cys_tinyxml STATIC
    "${_cys_txml}/tinystr.cpp"
    "${_cys_txml}/tinyxml.cpp"
    "${_cys_txml}/tinyxmlerror.cpp"
    "${_cys_txml}/tinyxmlparser.cpp")
target_include_directories(cys_tinyxml PUBLIC "${_cys_txml}")
target_compile_definitions(cys_tinyxml PUBLIC "TIXML_USE_STL=")
set_target_properties(cys_tinyxml PROPERTIES OUTPUT_NAME tinyxml FOLDER ThirdParty)
