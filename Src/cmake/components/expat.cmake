# CYS component: expat 2.0.x - static library (WXCore Core/WXExpatParser.cpp; also usable by CEGUI's expat parser).
# Old project: ThirdParty/expat/lib/expat_static.dsp (/MT, COMPILED_FROM_DSP -> winconfig.h). We build /MD.
# expat_external.h in this tree already declares XMLPARSEAPI(type) as plain `type`; XML_STATIC is still made
# PUBLIC so any consumer never sees __declspec(dllimport).
set(_cys_expat "${CYS_TP}/expat/lib")
add_library(cys_expat STATIC
    "${_cys_expat}/xmlparse.c"
    "${_cys_expat}/xmlrole.c"
    "${_cys_expat}/xmltok.c")
target_include_directories(cys_expat PUBLIC "${_cys_expat}")
target_compile_definitions(cys_expat
    PUBLIC XML_STATIC
    PRIVATE COMPILED_FROM_DSP _LIB)
set_target_properties(cys_expat PROPERTIES OUTPUT_NAME expat FOLDER ThirdParty)
