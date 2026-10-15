# CYS component: LuaPlus -> LuaPlus.dll = Lua 5.0.1 + the LuaPlus 5.0 C++ layer (LuaState/LuaObject/wide strings).
# TLBB build WITH the `continue` statement (src/llex.c:51 token list, src/lparser.c:1419 continuestat): client scripts
# use it, keep it. No `#` operator (Lua 5.0).
# Old project: ThirdParty/LuaPlus/!Scripts/VC7.1/LuaPlus.vcxproj (34 sources, DLL, MultiByte,
# LUA_OPNAMES LUAPLUS_BUILDDLL LUAPLUS_HAS_WCHAR_T). luace.c (WinCE), src/ltests.c and src/lib/luiolib.c are in no
# project and stay out.
# LUAPLUS_HAS_WCHAR_T is PUBLIC: it selects lua_WChar = wchar_t (else unsigned short), i.e. the mangled names of the
# LuaPlus C++ wide-string members, so every consumer must see the value the DLL was built with.
# Target: cys_luaplus (PUBLIC include dir = Src/ThirdParty/LuaPlus/Src/LuaPlus -> "LuaPlus.h").
set(_cys_lp "${CYS_TP}/LuaPlus/Src/LuaPlus")
add_library(cys_luaplus SHARED
    "${_cys_lp}/LuaObject.cpp"
    "${_cys_lp}/LuaPlus.cpp"
    "${_cys_lp}/LuaPlusAddons.c"
    "${_cys_lp}/LuaPlusFunctions.cpp"
    "${_cys_lp}/LuaStackObject.cpp"
    "${_cys_lp}/LuaState.cpp"
    "${_cys_lp}/lwstrlib.c"
    "${_cys_lp}/src/lapi.c"
    "${_cys_lp}/src/lcode.c"
    "${_cys_lp}/src/ldebug.c"
    "${_cys_lp}/src/ldo.c"
    "${_cys_lp}/src/ldump.c"
    "${_cys_lp}/src/lfunc.c"
    "${_cys_lp}/src/lgc.c"
    "${_cys_lp}/src/lib/lauxlib.c"
    "${_cys_lp}/src/lib/lbaselib.c"
    "${_cys_lp}/src/lib/ldblib.c"
    "${_cys_lp}/src/lib/liolib.c"
    "${_cys_lp}/src/lib/lmathlib.c"
    "${_cys_lp}/src/lib/loadlib.c"
    "${_cys_lp}/src/lib/lstrlib.c"
    "${_cys_lp}/src/lib/ltablib.c"
    "${_cys_lp}/src/llex.c"
    "${_cys_lp}/src/lmem.c"
    "${_cys_lp}/src/lobject.c"
    "${_cys_lp}/src/lopcodes.c"
    "${_cys_lp}/src/lparser.c"
    "${_cys_lp}/src/lstate.c"
    "${_cys_lp}/src/lstring.c"
    "${_cys_lp}/src/ltable.c"
    "${_cys_lp}/src/ltm.c"
    "${_cys_lp}/src/lundump.c"
    "${_cys_lp}/src/lvm.c"
    "${_cys_lp}/src/lzio.c")
target_include_directories(cys_luaplus
    PUBLIC  "${_cys_lp}"
    PRIVATE "${_cys_lp}/include" "${_cys_lp}/src")
target_compile_definitions(cys_luaplus
    PUBLIC  LUAPLUS_HAS_WCHAR_T
    PRIVATE LUAPLUS_BUILDDLL LUA_OPNAMES _MBCS)
if(MSVC)
    target_compile_options(cys_luaplus PRIVATE /w14311 /w14312 /w14302)
    # /EHc- (PUBLIC, C++ only): the TLBB LuaPlus throws C++ exceptions THROUGH the extern "C" Lua API - _ALERT/LOG =
    # LS_LOG does `throw std::exception(msg)` for every script error (LuaPlus.cpp:238), and Game.exe catches it around
    # GetLuaState()->DoString() (WXClient/Script/GMScriptSystm.cpp:54-87). Under the global /EHsc MSVC assumes extern "C"
    # functions never throw and drops such handlers: on x64 the error then ends in std::terminate (0xC0000409; measured
    # with a scratch test, 12/09). Every consumer of LuaPlus therefore compiles with "extern C may throw" (cl prints
    # D9025 "overriding '/EHc' with '/EHc-'", harmless).
    target_compile_options(cys_luaplus PUBLIC $<$<COMPILE_LANGUAGE:CXX>:/EHc->)
endif()
set_target_properties(cys_luaplus PROPERTIES OUTPUT_NAME LuaPlus FOLDER ThirdParty)
