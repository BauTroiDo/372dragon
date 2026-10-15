# CYS component: zlib 1.2.3, static (Src/ThirdParty/zlib).
# Target: cys_zlib  (PUBLIC include dir = Src/ThirdParty/zlib -> <zlib.h>, <zconf.h>)
# Replaces the prebuilt x86 zdll.lib/zlib1.dll that OgreMain used to link.
set(_cys_zlib_dir "${CYS_TP}/zlib")
add_library(cys_zlib STATIC
    "${_cys_zlib_dir}/adler32.c"
    "${_cys_zlib_dir}/compress.c"
    "${_cys_zlib_dir}/crc32.c"
    "${_cys_zlib_dir}/deflate.c"
    "${_cys_zlib_dir}/gzio.c"
    "${_cys_zlib_dir}/infback.c"
    "${_cys_zlib_dir}/inffast.c"
    "${_cys_zlib_dir}/inflate.c"
    "${_cys_zlib_dir}/inftrees.c"
    "${_cys_zlib_dir}/trees.c"
    "${_cys_zlib_dir}/uncompr.c"
    "${_cys_zlib_dir}/zutil.c")
set_target_properties(cys_zlib PROPERTIES OUTPUT_NAME "cys_zlib")
target_include_directories(cys_zlib PUBLIC "${_cys_zlib_dir}")
