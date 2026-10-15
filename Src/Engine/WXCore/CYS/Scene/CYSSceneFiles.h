#ifndef __CYS_SCENEFILES_H__
#define __CYS_SCENEFILES_H__

// CY-Source (scene agent): per-scene binary parameter files of the B post filters (05 §2, 02 §3):
//   <scene>.hdr (20 B, legacy HDR), <scene>.newhdrbloom (34 B), <scene>.hfog (64 B), <scene>.godrays (12 B).
// B looks them up in a temporary location for the scene folder, then in resource group "Scene"; absent files give
// the built-in defaults below. The post-filter framework (02) is not in CY-Source yet, so the values are only
// exposed through CYSEnvironment for the future filters.

#include "CYSEnvKey.h"

namespace WX
{
    /// .hdr: KeyValue, LimitedLuminance, GaussianMultiplier, GaussianOffset, GaussianDev (FUN_1801ade30).
    /// CY 3.71 (ci-cy, 14/09/2026): 10 scene files of CanonicalCY (dali_new_320, luoyang_new, suzhou_new, guishi,
    /// taohuadaofb, *_MD) are 28 bytes: the same 5 floats plus 2 trailing floats (0.5, 0.5 in every file). Their
    /// meaning is not traced yet; they are kept in cyExtra[] (hasCyExtra) and reported as deferred, not applied.
    struct CYSHdrFileParams
    {
        Real keyValue, limitedLuminance, gaussianMultiplier, gaussianOffset, gaussianDev;
        bool hasCyExtra;
        Real cyExtra[2];
        CYSHdrFileParams(void)
            : keyValue(0.5f), limitedLuminance(0.5f), gaussianMultiplier(1.0f), gaussianOffset(0.0f), gaussianDev(3.0f),
              hasCyExtra(false)
        {
            cyExtra[0] = cyExtra[1] = 0.0f;
        }
    };

    /// .newhdrbloom: f32 Intensity, Threshold, SoftKnee, Exposure, u8 UseHDR, UseAutoExposure, f32[4] BloomColor
    /// (FUN_1801981b0; field names from the setParameter function FUN_180198f80).
    struct CYSNewHdrBloomParams
    {
        Real intensity, threshold, softKnee, exposure;
        bool useHDR, useAutoExposure;
        Ogre::ColourValue bloomColour;
        CYSNewHdrBloomParams(void)
            : intensity(0.0f), threshold(1.0f), softKnee(0.5f), exposure(0.0f)
            , useHDR(true), useAutoExposure(true), bloomColour(Ogre::ColourValue::White)
        {
        }
    };

    /// .godrays: 3 floats (FUN_1801b7d40; parameter "Decay", constant sunPos_decay_exposure - the names of the
    /// last two are INF). No .godrays file exists in client_GL.
    struct CYSGodRaysParams
    {
        Real decay, exposure, weight;
        CYSGodRaysParams(void) : decay(0.98f), exposure(0.05f), weight(1.0f) {}
    };

    struct CYSSceneFileParams
    {
        bool hasHdr, hasNewHdrBloom, hasHeightFog, hasGodRays;
        CYSHdrFileParams hdr;
        CYSNewHdrBloomParams newHdrBloom;
        CYSHeightFogParams heightFog;     ///< .hfog (defaults when absent: CYSHeightFogParams())
        CYSGodRaysParams godRays;

        CYSSceneFileParams(void) { reset(); }
        void reset(void);
    };

    namespace CYSScene
    {
        /// Decoders for a whole file image; false + `error` when the size does not match.
        bool decodeHdr(const void* data, size_t size, CYSHdrFileParams& out, String* error);
        bool decodeNewHdrBloom(const void* data, size_t size, CYSNewHdrBloomParams& out, String* error);
        bool decodeHeightFog(const void* data, size_t size, CYSHeightFogParams& out, String* error);
        bool decodeGodRays(const void* data, size_t size, CYSGodRaysParams& out, String* error);

        /// Loads <sceneBaseName>.hdr/.newhdrbloom/.hfog/.godrays from `group` (then "Scene"); returns the
        /// number of files read. Size errors are recorded as unknown keys "Scene file <ext> ...".
        size_t loadSceneFileParams(const String& sceneBaseName, const String& group, CYSSceneFileParams& out);

        /// Reads a whole resource into memory (false when absent in all groups given). `foundGroup` optional.
        bool readResource(const String& name, const std::vector<String>& groups, std::vector<unsigned char>& bytes,
                          String* foundGroup = 0);
    }
}

#endif // __CYS_SCENEFILES_H__
