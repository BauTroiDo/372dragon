// CY-Source post-processing: GodRays sun mask (ps_3_0). B feeds genGodRays_fp with a render target of the EnScene
// sun ("SunRT"); this mask keeps the bright sky pixels around the sun's screen position instead, so any sky
// renderer (EnScene, SkySphere, a backdrop) produces rays.
//   sunParams  = (sun u, sun v, aspect w / h, radius as a fraction of the height)
//   maskParams = (sky depth threshold, brightness threshold, 1: use the depth node, intensity)
#include "CysPostFxCommon.inc"

float4 mask_ps(float2 uv : TEXCOORD0,
               uniform sampler2D sceneTex : register(s0),
               uniform sampler2D depthTex : register(s1),
               uniform float4 sunParams,
               uniform float4 maskParams) : COLOR
{
    float3 c = tex2D(sceneTex, uv).rgb;
    float sky = 1.0;
    if (maskParams.z > 0.5)
        sky = step(maskParams.x, tex2Dlod(depthTex, float4(uv, 0.0, 0.0)).r);
    float2 d = (uv - sunParams.xy) * float2(sunParams.z, 1.0);
    float falloff = saturate(1.0 - length(d) / max(sunParams.w, 1e-3));
    float bright = saturate((CysLuma(c) - maskParams.y) / max(1.0 - maskParams.y, 1e-3));
    return float4(c * (sky * bright * falloff * falloff * maskParams.w), 1.0);
}
