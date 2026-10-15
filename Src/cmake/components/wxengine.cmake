# CYS component: WXEngine - the tEngine kernel (tKernel/tNode/tClass registry, TDThrow/TDAssert exceptions and
# crash report, profile, time, util) plus the abstract tXxxSystem classes of Engine/Interface - static library.
# Old project: Engine/WXEngine/WXEngine.vcxproj (static, TENGDA_EXPORTS, MultiByte). The modern client ships a
# tEngine.dll, but in this source every TDENGDA_API use is commented out (Interface/TDClass.h:10,
# Interface/TDProfile.h:39) so a DLL would export nothing. It therefore stays static and is linked into each
# module that needs it (Game.exe, Render.dll) exactly like 0.85; the kernel object crosses module boundaries only
# through DllInit(tKernel*).
set(_cys_wxe "${CYS_SRC}/Engine/WXEngine")
add_library(cys_wxengine STATIC
    "${CYS_SRC}/Engine/Interface/AxTrace.cpp"
    "${_cys_wxe}/Cursor/TDCursorSystem.cpp"
    "${_cys_wxe}/DBC/TDDataBase.cpp"
    "${_cys_wxe}/debuger/TDDebuge.cpp"
    "${_cys_wxe}/Exception/CysCrtGuard.cpp"
    "${_cys_wxe}/Exception/TDCrashReport.cpp"
    "${_cys_wxe}/Exception/TDException.cpp"
    "${_cys_wxe}/Exception/XZip.cpp"
    "${_cys_wxe}/FakeObject/TDFakeObjSystem.cpp"
    "${_cys_wxe}/Game/Action/TDActionSystem.cpp"
    "${_cys_wxe}/Game/DataPool/TDDataPool.cpp"
    "${_cys_wxe}/Game/DataPool/TDUIDataPool.cpp"
    "${_cys_wxe}/Game/Event/TDEventSystem.cpp"
    "${_cys_wxe}/Game/Interface/TDGameInterface.cpp"
    "${_cys_wxe}/Game/Object/TDObjectSystem.cpp"
    "${_cys_wxe}/Game/World/TDWorldSystem.cpp"
    "${_cys_wxe}/Gfx/TDGfxSystem.cpp"
    "${_cys_wxe}/Helper/TDHelperSystem.cpp"
    "${_cys_wxe}/Input/TDInputSystem.cpp"
    "${_cys_wxe}/Kernel/TDClass.cpp"
    "${_cys_wxe}/Kernel/TDKernel.cpp"
    "${_cys_wxe}/Kernel/TDNode.cpp"
    "${_cys_wxe}/Math/TDMath.cpp"
    "${_cys_wxe}/Profile/TDProfile.cpp"
    "${_cys_wxe}/Script/TDScriptSystm.cpp"
    "${_cys_wxe}/Sound/TDSound.cpp"
    "${_cys_wxe}/stdafx.cpp"
    "${_cys_wxe}/Time/TDTimeSystem.cpp"
    "${_cys_wxe}/UI/TDUISystem.cpp"
    "${_cys_wxe}/Util/TDUtil.cpp"
    "${_cys_wxe}/Variable/TDVariable.cpp"
    "${_cys_wxe}/WXEngine.cpp")
# Exception/TDCrashReport.cpp includes "..\WXClient\Global.h" and "..\WXClient\Resource.h" (0.85 resolved them
# through ..\Common = Client\Common). Src/Client/WXClient as the LAST search dir makes <dir>\..\WXClient\*.h resolve
# while "StdAfx.h" etc. still come from WXEngine/Interface first. (A source-file INCLUDE_DIRECTORIES property would
# be emitted BEFORE the target dirs and pick WXClient's own StdAfx.h.)
target_include_directories(cys_wxengine
    PUBLIC  "${CYS_SRC}/Engine/Interface"
    PRIVATE "${_cys_wxe}" "${CYS_SRC}/Client/WXClient")
target_compile_definitions(cys_wxengine PRIVATE TENGDA_EXPORTS _MBCS)
target_link_libraries(cys_wxengine PUBLIC shlwapi winmm)
if(MSVC)
    target_compile_options(cys_wxengine PRIVATE /w14311 /w14312 /w14302)
endif()
set_target_properties(cys_wxengine PROPERTIES OUTPUT_NAME WXEngine FOLDER Engine)
