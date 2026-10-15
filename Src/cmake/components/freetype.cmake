# CYS component: FreeType 2.2.1, static (Src/ThirdParty/FreeType). No project file existed:
# standard FreeType 2 "one file per module" build, module set = include/freetype/config/ftmodule.h
# (autofit tt t1 cff t1cid pfr t42 winfnt pcf psaux psnames pshinter raster sfnt smooth bdf)
# plus gzip/lzw stream support and the cache sub-system. gxvalid/otvalid are not in ftmodule.h.
# Target: cys_freetype (PUBLIC include dir = Src/ThirdParty/FreeType/include -> <ft2build.h>)
set(_cys_ft_dir "${CYS_TP}/FreeType")
set(_cys_ft_src "${_cys_ft_dir}/src")
add_library(cys_freetype STATIC
    # base layer (ftbase.c #includes ftcalc/ftgloadr/ftobjs/ftoutln/ftrfork/ftstream/fttrigon/ftutil/...)
    "${_cys_ft_src}/base/ftsystem.c"
    "${_cys_ft_src}/base/ftinit.c"
    "${_cys_ft_src}/base/ftdebug.c"
    "${_cys_ft_src}/base/ftbase.c"
    # optional base components
    "${_cys_ft_src}/base/ftbbox.c"
    "${_cys_ft_src}/base/ftbdf.c"
    "${_cys_ft_src}/base/ftbitmap.c"
    "${_cys_ft_src}/base/ftglyph.c"
    "${_cys_ft_src}/base/ftgxval.c"
    "${_cys_ft_src}/base/ftmm.c"
    "${_cys_ft_src}/base/ftotval.c"
    "${_cys_ft_src}/base/ftpfr.c"
    "${_cys_ft_src}/base/ftstroke.c"
    "${_cys_ft_src}/base/ftsynth.c"
    "${_cys_ft_src}/base/fttype1.c"
    "${_cys_ft_src}/base/ftwinfnt.c"
    "${_cys_ft_src}/base/ftxf86.c"
    # modules (single-file builds)
    "${_cys_ft_src}/autofit/autofit.c"
    "${_cys_ft_src}/bdf/bdf.c"
    "${_cys_ft_src}/cache/ftcache.c"
    "${_cys_ft_src}/cff/cff.c"
    "${_cys_ft_src}/cid/type1cid.c"
    "${_cys_ft_src}/gzip/ftgzip.c"
    "${_cys_ft_src}/lzw/ftlzw.c"
    "${_cys_ft_src}/pcf/pcf.c"
    "${_cys_ft_src}/pfr/pfr.c"
    "${_cys_ft_src}/psaux/psaux.c"
    "${_cys_ft_src}/pshinter/pshinter.c"
    "${_cys_ft_src}/psnames/psmodule.c"
    "${_cys_ft_src}/raster/raster.c"
    "${_cys_ft_src}/sfnt/sfnt.c"
    "${_cys_ft_src}/smooth/smooth.c"
    "${_cys_ft_src}/truetype/truetype.c"
    "${_cys_ft_src}/type1/type1.c"
    "${_cys_ft_src}/type42/type42.c"
    "${_cys_ft_src}/winfonts/winfnt.c")
set_target_properties(cys_freetype PROPERTIES OUTPUT_NAME "cys_freetype")
target_include_directories(cys_freetype PUBLIC "${_cys_ft_dir}/include")
target_compile_definitions(cys_freetype PRIVATE FT2_BUILD_LIBRARY)
