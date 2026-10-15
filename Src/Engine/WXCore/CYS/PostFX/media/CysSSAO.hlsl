// CY-Source post-processing: GenSSAO (ps_3_0). Input: the depth node (linear view depth, R32F, far value = sky).
// Output "CYS/Global/SSAO": 1 = open, 0 = fully occluded (the convention of B's ssao_buffer, CalcLight.inc).
#include "CysPostFxCommon.inc"

// AO: 16 samples in the hemisphere around the depth-derived normal (cosine-weighted golden-angle spiral, closer
// samples denser), rotated per pixel by a 4x4 noise texture; an occluder counts only within the radius.
//   projParams = (tan(fovX/2), tan(fovY/2), 1 / depth width, 1 / depth height)
//   aoParams   = (radius, bias, sky threshold, intensity)          noiseScale.xy = AO target size / 4
//   fadeParams = (distance where AO starts to fade, distance where it is gone, bias per unit of depth, -)
float4 genAO_ps(float2 uv : TEXCOORD0,
                uniform sampler2D depthTex : register(s0),
                uniform sampler2D noiseTex : register(s1),
                uniform float4 projParams,
                uniform float4 aoParams,
                uniform float4 noiseScale,
                uniform float4 fadeParams) : COLOR
{
    // The AO target is smaller than the depth node: reconstruct at the centre of the depth texel actually read,
    // else at grazing angles the position is off by several units and flat ground occludes itself in bands.
    uv = (floor(uv / projParams.zw) + 0.5) * projParams.zw;
    float d = tex2Dlod(depthTex, float4(uv, 0.0, 0.0)).r;
    if (d >= aoParams.z || d >= fadeParams.y)
        return float4(1.0, 1.0, 1.0, 1.0);
    float3 p = CysViewPos(uv, d, projParams);

    // normal from the neighbour on each axis that is closer in depth (no smearing across silhouettes)
    float2 tx = float2(projParams.z, 0.0);
    float2 ty = float2(0.0, projParams.w);
    float3 pr = CysViewPos(uv + tx, tex2Dlod(depthTex, float4(uv + tx, 0.0, 0.0)).r, projParams);
    float3 pl = CysViewPos(uv - tx, tex2Dlod(depthTex, float4(uv - tx, 0.0, 0.0)).r, projParams);
    float3 pd = CysViewPos(uv + ty, tex2Dlod(depthTex, float4(uv + ty, 0.0, 0.0)).r, projParams);
    float3 pu = CysViewPos(uv - ty, tex2Dlod(depthTex, float4(uv - ty, 0.0, 0.0)).r, projParams);
    float3 dx = (abs(pr.z - p.z) < abs(p.z - pl.z)) ? (pr - p) : (p - pl);
    float3 dy = (abs(pd.z - p.z) < abs(p.z - pu.z)) ? (pd - p) : (p - pu);
    float3 n = normalize(cross(dy, dx));

    float3 rv = float3(tex2Dlod(noiseTex, float4(uv * noiseScale.xy, 0.0, 0.0)).xy * 2.0 - 1.0, 0.0);
    float3 t = normalize(rv - n * dot(rv, n));
    float3 b = cross(n, t);

    float bias = aoParams.y + fadeParams.z * d;
    float occlusion = 0.0;
    [unroll] for (int i = 0; i < 16; ++i)
    {
        float k = (i + 0.5) / 16.0;
        float phi = i * 2.39996323;
        float3 h = float3(cos(phi) * sqrt(k), sin(phi) * sqrt(k), sqrt(1.0 - k));
        float scale = lerp(0.15, 1.0, k * k);
        float3 s = p + (t * h.x + b * h.y + n * h.z) * (scale * aoParams.x);
        float sz = max(-s.z, 1e-3);
        float2 suv = float2(s.x / (sz * projParams.x), s.y / (sz * projParams.y));
        suv = float2(suv.x * 0.5 + 0.5, 0.5 - suv.y * 0.5);
        float sd = tex2Dlod(depthTex, float4(suv, 0.0, 0.0)).r;
        float range = saturate(aoParams.x / max(abs(d - sd), 1e-3));
        occlusion += ((sd < sz - bias) ? 1.0 : 0.0) * range;
    }
    float fade = 1.0 - saturate((d - fadeParams.x) / max(fadeParams.y - fadeParams.x, 1.0));
    float ao = saturate(1.0 - aoParams.w * fade * occlusion / 16.0);
    return float4(ao, ao, ao, 1.0);
}

// Depth-aware separable Gaussian (9 taps); blurParams = (texel step x, y, depth tolerance as a fraction of depth, -)
float4 blur_ps(float2 uv : TEXCOORD0,
               uniform sampler2D aoTex : register(s0),
               uniform sampler2D depthTex : register(s1),
               uniform float4 blurParams) : COLOR
{
    float weights[5] = { 0.2270270270, 0.1945945946, 0.1216216216, 0.0540540541, 0.0162162162 };
    float d0 = tex2D(depthTex, uv).r;
    float tolerance = max(blurParams.z * d0, 1e-3);
    float sum = tex2D(aoTex, uv).r * weights[0];
    float wsum = weights[0];
    [unroll] for (int i = 1; i < 5; ++i)
    {
        float2 o = blurParams.xy * i;
        float k1 = weights[i] * saturate(1.0 - abs(tex2D(depthTex, uv + o).r - d0) / tolerance);
        float k2 = weights[i] * saturate(1.0 - abs(tex2D(depthTex, uv - o).r - d0) / tolerance);
        sum += tex2D(aoTex, uv + o).r * k1 + tex2D(aoTex, uv - o).r * k2;
        wsum += k1 + k2;
    }
    float ao = sum / wsum;
    return float4(ao, ao, ao, 1.0);
}

// Composite for materials that do not read the AO themselves; applyParams = (strength, power, 1: show AO only, -)
float4 apply_ps(float2 uv : TEXCOORD0,
                uniform sampler2D sceneTex : register(s0),
                uniform sampler2D aoTex : register(s1),
                uniform float4 applyParams) : COLOR
{
    float4 c = tex2D(sceneTex, uv);
    float ao = pow(saturate(tex2D(aoTex, uv).r), applyParams.y);
    if (applyParams.z > 0.5)
        return float4(ao, ao, ao, 1.0);
    c.rgb *= lerp(1.0, ao, applyParams.x);
    return c;
}
