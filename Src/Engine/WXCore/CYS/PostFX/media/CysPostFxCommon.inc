#ifndef CYS_POSTFX_COMMON_INC
#define CYS_POSTFX_COMMON_INC
// CY-Source post-processing: shared helpers (SM3).

// Same approximations as B's PostProcessUtility.inc, so ConvertToLinearSpace (B) and our passes agree.
float3 CysGammaToLinear(float3 c)
{
    return c * (c * (c * 0.305306011 + 0.682171111) + 0.012522878);
}

float3 CysLinearToGamma(float3 c)
{
    c = max(c, 0.0);
    return max(1.055 * pow(c, 0.416666667) - 0.055, 0.0);
}

float CysLuma(float3 c)
{
    return dot(c, float3(0.299, 0.587, 0.114));
}

// View-space position (camera looks down -z) from uv and the linear view depth of the depth node;
// projParams.xy = tan(fovX / 2), tan(fovY / 2).
float3 CysViewPos(float2 uv, float depth, float4 projParams)
{
    return float3((uv.x * 2.0 - 1.0) * projParams.x, (1.0 - uv.y * 2.0) * projParams.y, -1.0) * depth;
}

#endif
