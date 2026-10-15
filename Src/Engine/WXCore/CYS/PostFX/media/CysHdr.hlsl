// CY-Source post-processing: NewHDRBloom luminance, eye adaptation and final composite (ps_3_0).
// Semantics of the final pass: B Bloom.hlsl finalPassFp (Docs/specs/render/02-postfx.md 2), with a proper
// log-average luminance and temporal adaptation instead of B's one-frame 1x1 average.
#include "CysPostFxCommon.inc"

#ifndef USE_HDR
#define USE_HDR 0
#endif
#ifndef USE_AUTOEXPOSURE
#define USE_AUTOEXPOSURE 0
#endif

// 1) Log luminance of the linear scene: 4x4 bilinear taps spread over one destination texel (81 x 81).
float4 lumInit_ps(float2 uv : TEXCOORD0,
                  uniform sampler2D sceneTex : register(s0),
                  uniform float4 dstTexel) : COLOR
{
    float sum = 0.0;
    [unroll] for (int y = 0; y < 4; ++y)
    {
        [unroll] for (int x = 0; x < 4; ++x)
        {
            float2 o = (float2(x, y) - 1.5) * 0.25 * dstTexel.xy;
            sum += log(max(CysLuma(tex2D(sceneTex, uv + o).rgb), 1e-4));
        }
    }
    return float4(sum / 16.0, 0.0, 0.0, 1.0);
}

// 2) 3x3 average: each destination texel covers exactly 3x3 source texels (81 -> 27 -> 9 -> 3 -> 1).
float4 lumDown_ps(float2 uv : TEXCOORD0,
                  uniform sampler2D lumTex : register(s0),
                  uniform float4 srcTexel) : COLOR
{
    float sum = 0.0;
    [unroll] for (int y = -1; y <= 1; ++y)
    {
        [unroll] for (int x = -1; x <= 1; ++x)
            sum += tex2D(lumTex, uv + float2(x, y) * srcTexel.xy).r;
    }
    return float4(sum / 9.0, 0.0, 0.0, 1.0);
}

// 3) Eye adaptation: the adapted luminance moves towards the measured one; adaptParams.x = blend factor of this
//    frame (1 = reset), y/z = luminance clamp. An uninitialised / invalid previous value restarts from the measure.
float4 lumAdapt_ps(float2 uv : TEXCOORD0,
                   uniform sampler2D logLumTex : register(s0),
                   uniform sampler2D previousTex : register(s1),
                   uniform float4 adaptParams) : COLOR
{
    float current = clamp(exp(tex2D(logLumTex, float2(0.5, 0.5)).r), adaptParams.y, adaptParams.z);
    float previous = tex2D(previousTex, float2(0.5, 0.5)).r;
    float adapted = (previous > 0.0 && previous < 1e6) ? lerp(previous, current, adaptParams.x) : current;
    return float4(adapted, 0.0, 0.0, 1.0);
}

// CYS fx-render 2026-09-13: B's LDR path. Its scene_buffer is 8-bit A8R8G8B8 (Render.dll FUN_180213940, format
// 0xc), so ConvertToLinearSpace (B CopyFrameBuffer.hlsl) never sees more than 1: same conversion after a clamp.
float4 toLinearClamp_ps(float2 uv : TEXCOORD0,
                        uniform sampler2D sceneTex : register(s0)) : COLOR
{
    float4 c = saturate(tex2D(sceneTex, uv));
    return float4(CysGammaToLinear(c.rgb), c.a);
}

// ACES filmic fit (Narkowicz 2015), the constants of B's ACESTonemap.
float3 CysACES(float3 x)
{
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return saturate((x * (a * x + b)) / (x * (c * x + d) + e));
}

// 4) Final composite (B finalPassFp order): auto exposure scales the scene only, bloom * (colour, intensity) is
//    added, then ACES with the exposure multiplier, back to gamma space.
//    bloomColor = (rgb, intensity); exposureParams = (2^Exposure, auto-exposure key, compression, -)
float4 final_ps(float2 uv : TEXCOORD0,
                uniform sampler2D sceneTex : register(s0),
                uniform sampler2D bloomTex : register(s1),
                uniform sampler2D lumTex : register(s2),
                uniform float4 bloomColor,
                uniform float4 exposureParams) : COLOR
{
    float3 c = tex2D(sceneTex, uv).rgb;
#if USE_HDR && USE_AUTOEXPOSURE
    float lum = max(tex2D(lumTex, float2(0.5, 0.5)).r, 1e-4);
    c *= exposureParams.x * exposureParams.y * pow(lum, -exposureParams.z);
#endif
    c += tex2D(bloomTex, uv).rgb * (bloomColor.w * bloomColor.rgb);
#if USE_HDR
    c = CysACES(c * exposureParams.x);
#endif
    return float4(saturate(CysLinearToGamma(c)), 1.0);
}
