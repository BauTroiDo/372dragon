# CYS component: zziplib 0.13.x, static (Src/ThirdParty/zziplib = the OGRE dependency copy).
# Target: cys_zziplib (PUBLIC include dir = Src/ThirdParty/zziplib -> <zzip/zzip.h>)
# Source list follows zziplib/msvc7/zziplib.vcproj, plus fetch.c (__zzip_get64/__zzip_set64).
# Src/ThirdParty/zziplib-client (client copy, no "cache.locked" guard) is not built here.
set(_cys_zzip_dir "${CYS_TP}/zziplib")
add_library(cys_zziplib STATIC
    "${_cys_zzip_dir}/zzip/dir.c"
    "${_cys_zzip_dir}/zzip/err.c"
    "${_cys_zzip_dir}/zzip/fetch.c"
    "${_cys_zzip_dir}/zzip/file.c"
    "${_cys_zzip_dir}/zzip/info.c"
    "${_cys_zzip_dir}/zzip/plugin.c"
    "${_cys_zzip_dir}/zzip/stat.c"
    "${_cys_zzip_dir}/zzip/zip.c")
set_target_properties(cys_zziplib PROPERTIES OUTPUT_NAME "cys_zziplib")
target_include_directories(cys_zziplib PUBLIC "${_cys_zzip_dir}")
target_link_libraries(cys_zziplib PUBLIC cys_zlib)
