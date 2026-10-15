#include "WXPostFilters.h"
#include "WXPostFilterManager.h"
#include "CYS/PostFX/CysPostFx.h" // CYS: CY-Source post filters

namespace WX {

extern void registerAllPostFilterFactories(PostFilterManager* postFilterManager)
{
    assert(postFilterManager);

    postFilterManager->registerFactory(getHeatVisionPostFilterFactory());
    postFilterManager->registerFactory(getBloomPostFilterFactory());
    postFilterManager->registerFactory(getFloodlightingPostFilterFactory());
    postFilterManager->registerFactory(getFadePostFilterFactory());
    postFilterManager->registerFactory(getMotionBlurPostFilterFactory());
    // CYS: NewHDRBloom, FXAA, FXAAQuality, DLAA, ColorLUT, GodRays, DoF, HeightFog, GenSSAO (CYS/PostFX)
    CysPostFx::registerFactories(postFilterManager);
}

}
