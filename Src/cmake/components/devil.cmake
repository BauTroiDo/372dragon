# CYS component: DevIL 1.6.x image library, static (Src/ThirdParty/Devil).
# Targets: cys_devil (IL)  and  cys_ilu (ILU, links cys_devil).
# PUBLIC include dir = Src/ThirdParty/Devil/include -> <IL/il.h>, <IL/ilu.h>; il.h defines IL_STATIC_LIB.
#
# Only x86 VC6 libjpeg/libpng/libtiff exist in the tree, so the codecs that need them are compiled
# out (IL_NO_JPG/PNG/TIF/MNG/LCMS). DDS, TGA, BMP (and the other built-in loaders) still work.
# GAP: JPG/PNG/TIF through DevIL are unavailable in x64 until those libs are rebuilt or replaced.
set(_cys_il_dir "${CYS_TP}/Devil")
set(_cys_il_src "${_cys_il_dir}/src-IL/src")
add_library(cys_devil STATIC
    "${_cys_il_src}/il_alloc.c"      "${_cys_il_src}/il_bits.c"      "${_cys_il_src}/il_bmp.c"
    "${_cys_il_src}/il_convbuff.c"   "${_cys_il_src}/il_convert.c"   "${_cys_il_src}/il_cut.c"
    "${_cys_il_src}/il_dcx.c"        "${_cys_il_src}/il_dds-save.c"  "${_cys_il_src}/il_dds.c"
    "${_cys_il_src}/il_devil.c"      "${_cys_il_src}/il_doom.c"      "${_cys_il_src}/il_endian.c"
    "${_cys_il_src}/il_error.c"      "${_cys_il_src}/il_fastconv.c"  "${_cys_il_src}/il_files.c"
    "${_cys_il_src}/il_gif.c"        "${_cys_il_src}/il_hdr.c"       "${_cys_il_src}/il_header.c"
    "${_cys_il_src}/il_icon.c"       "${_cys_il_src}/il_internal.c"  "${_cys_il_src}/il_io.c"
    "${_cys_il_src}/il_jpeg.c"       "${_cys_il_src}/il_lif.c"       "${_cys_il_src}/il_main.c"
    "${_cys_il_src}/il_manip.c"      "${_cys_il_src}/il_mdl.c"       "${_cys_il_src}/il_mng.c"
    "${_cys_il_src}/il_neuquant.c"   "${_cys_il_src}/il_pal.c"       "${_cys_il_src}/il_pcd.c"
    "${_cys_il_src}/il_pcx.c"        "${_cys_il_src}/il_pic.c"       "${_cys_il_src}/il_pix.c"
    "${_cys_il_src}/il_png.c"        "${_cys_il_src}/il_pnm.c"       "${_cys_il_src}/il_profiles.c"
    "${_cys_il_src}/il_psd.c"        "${_cys_il_src}/il_psp.c"       "${_cys_il_src}/il_pxr.c"
    "${_cys_il_src}/il_quantizer.c"  "${_cys_il_src}/il_raw.c"       "${_cys_il_src}/il_rawdata.c"
    "${_cys_il_src}/il_register.c"   "${_cys_il_src}/il_rle.c"       "${_cys_il_src}/il_sgi.c"
    "${_cys_il_src}/il_stack.c"      "${_cys_il_src}/il_states.c"    "${_cys_il_src}/il_targa.c"
    "${_cys_il_src}/il_tiff.c"       "${_cys_il_src}/il_utility.c"   "${_cys_il_src}/il_wal.c"
    "${_cys_il_src}/il_xpm.c")
set_target_properties(cys_devil PROPERTIES OUTPUT_NAME "cys_devil")
target_include_directories(cys_devil
    PUBLIC  "${_cys_il_dir}/include"
    PRIVATE "${_cys_il_dir}/src-IL/include")
target_compile_definitions(cys_devil
    PUBLIC  IL_STATIC_LIB
    PRIVATE IL_NO_JPG=1 IL_NO_PNG=1 IL_NO_TIF=1 IL_NO_MNG=1 IL_NO_LCMS=1)

set(_cys_ilu_src "${_cys_il_dir}/src-ILU/src")
add_library(cys_ilu STATIC
    "${_cys_ilu_src}/ilu_error.c"     "${_cys_ilu_src}/ilu_filter.c"   "${_cys_ilu_src}/ilu_filter_rcg.c"
    "${_cys_ilu_src}/ilu_internal.c"  "${_cys_ilu_src}/ilu_main.c"     "${_cys_ilu_src}/ilu_manip.c"
    "${_cys_ilu_src}/ilu_mipmap.c"    "${_cys_ilu_src}/ilu_noise.c"    "${_cys_ilu_src}/ilu_region.c"
    "${_cys_ilu_src}/ilu_rotate.c"    "${_cys_ilu_src}/ilu_scale.c"    "${_cys_ilu_src}/ilu_scale2d.c"
    "${_cys_ilu_src}/ilu_scale3d.c"   "${_cys_ilu_src}/ilu_states.c"   "${_cys_ilu_src}/ilu_utilities.c")
set_target_properties(cys_ilu PROPERTIES OUTPUT_NAME "cys_ilu")
target_include_directories(cys_ilu PRIVATE "${_cys_il_dir}/src-ILU/include")
target_link_libraries(cys_ilu PUBLIC cys_devil)
