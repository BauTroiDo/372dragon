#ifndef CYS_SHADOW_LIB_INC
#define CYS_SHADOW_LIB_INC

// CY-Source (shadow agent): receiver side of the CY-Source shadow atlas for shaders that are not client_GL
// templates (terrain, water, tools, tests). It reads exactly the constants of the B contract
// (ShaderLib/CalcShadow.inc, Docs\specs\render\03-shadows.md §4), so one provider feeds both:
//   shadow_view_matrix, shadow_proj_matrix, shadow_param (x strength, y PBR strength, z tile size),
//   shadow_csm_param (x count, y 1/count, z blend band, w distance), shadow_csm_proj_scale / _offset
//   (row_major, row i = cascade i, t = posInView * scale + offset in [0,1]^3), isystem_userdata (.x constant
//   bias, .w normal bias - world units, tuned by the provider for the coarsest cascade).
// Improvements over CalcShadow.inc with the same inputs:
//   * box PCF of (2 CYS_SHADOW_PCF_RADIUS + 1) texels with exact bilinear edge weights (radius 1 is close to
//     B's 3x3); samples are clamped to the tile, so large radii never read the neighbouring cascade;
//   * the normal offset and the constant bias are scaled per cascade by its texel size relative to the
//     coarsest cascade: sharp contact shadows near the camera, no acne far away;
//   * blending into the next cascade over shadow_csm_param.z of the tile (commented out in B).
// Define CYS_SHADOW_LIB_NO_UNIFORMS when the uniforms are declared elsewhere (e.g. by ParamNamedAuto.inc).

#ifndef CYS_SHADOW_PCF_RADIUS
#define CYS_SHADOW_PCF_RADIUS 2
#endif

#ifndef CYS_SHADOW_LIB_NO_UNIFORMS
uniform float4x4 shadow_view_matrix;
uniform float4x4 shadow_proj_matrix;
uniform float4 shadow_param;
uniform float4 shadow_csm_param;
uniform row_major float4x4 shadow_csm_proj_scale;
uniform row_major float4x4 shadow_csm_proj_offset;
uniform float4 isystem_userdata;
#endif

// 1 when a receiver at receiverDepth lies behind the occluder stored in a texel (0 stored = nothing there).
float cysShadowTest(float receiverDepth, float occluderDepth, float bias)
{
    float occluder = occluderDepth > 0.0 ? occluderDepth : 1.0e7;
    return receiverDepth >= occluder + bias ? 1.0 : 0.0;
}

// Box-filtered PCF around 'uv' (atlas uv, texel = atlas texel size); samples clamped to [uvMin, uvMax].
float cysShadowPCF(sampler2D atlas, float2 uv, float receiverDepth, float bias, float2 texel, float2 uvMin,
                   float2 uvMax)
{
    const int R = CYS_SHADOW_PCF_RADIUS;
    float2 p = uv / texel - 0.5;        // texel-centre coordinates
    float2 base = floor(p);
    float2 f = p - base;
    float occlusion = 0.0;
    [loop] for (int y = -R; y <= R + 1; ++y)
    {
        float wy = (y == -R) ? (1.0 - f.y) : ((y == R + 1) ? f.y : 1.0);
        [loop] for (int x = -R; x <= R + 1; ++x)
        {
            float wx = (x == -R) ? (1.0 - f.x) : ((x == R + 1) ? f.x : 1.0);
            float2 s = clamp((base + float2(x, y) + 0.5) * texel, uvMin, uvMax);
            occlusion += wx * wy * cysShadowTest(receiverDepth, tex2Dlod(atlas, float4(s, 0.0, 0.0)).r, bias);
        }
    }
    return occlusion / ((2.0 * R + 1.0) * (2.0 * R + 1.0));
}

// Cascade texture coordinate of a light-view position (B's rows).
float4 cysCascadeCoord(float4 posInView, int i)
{
    return posInView * shadow_csm_proj_scale[i] + shadow_csm_proj_offset[i];
}

bool cysInsideCascade(float4 t)
{
    return all(t.xyz >= 0.0) && all(t.xyz <= 1.0);
}

// World units per texel of cascade i (the tile interior spans 1 / scale.x and tile size - 2 texels).
float cysCascadeTexel(int i)
{
    return 1.0 / (abs(shadow_csm_proj_scale[i].x) * max(shadow_param.z - 2.0, 1.0));
}

// Texel of the coarsest cascade (smallest non-zero x scale; unused rows are zero).
float cysCoarsestTexel()
{
    float4 s = float4(abs(shadow_csm_proj_scale[0].x), abs(shadow_csm_proj_scale[1].x),
                      abs(shadow_csm_proj_scale[2].x), abs(shadow_csm_proj_scale[3].x));
    float m = s.x;
    m = (s.y > 0.0 && s.y < m) ? s.y : m;
    m = (s.z > 0.0 && s.z < m) ? s.z : m;
    m = (s.w > 0.0 && s.w < m) ? s.w : m;
    return 1.0 / (max(m, 1.0e-9) * max(shadow_param.z - 2.0, 1.0));
}

// Occlusion (0 lit .. 1 shadowed) of cascade i at light-view position posInView.
float cysCascadeOcclusion(sampler2D atlas, float4 posInView, int i, float bias)
{
    float count = shadow_csm_param.x;
    float size = shadow_param.z;
    float4 t = cysCascadeCoord(posInView, i);
    float interior = (size - 2.0) / size;                   // B: borderScale
    float2 tileUV = (1.0 - interior) * 0.5 + saturate(t.xy) * interior;
    float2 uv = float2((i + tileUV.x) / count, tileUV.y);
    float2 texel = float2(1.0 / (size * count), 1.0 / size);
    float2 uvMin = float2(i / count, 0.0) + 0.5 * texel;
    float2 uvMax = float2((i + 1) / count, 1.0) - 0.5 * texel;
    return cysShadowPCF(atlas, uv, -posInView.z, bias, texel, uvMin, uvMax);
}

// Visibility (1 lit .. 0 shadowed) of a receiver for SHADOWMAP_TYPE 1 (cascades). normalWorld and toLight are
// normalised; cascade = index used, -1 outside every cascade. Strength (shadow_param.x/.y) is left to the caller.
float cysShadowCSM(sampler2D atlas, float3 posWorld, float3 normalWorld, float3 toLight, float3 cameraPos,
                   out float cascade)
{
    cascade = -1.0;
    float count = shadow_csm_param.x;
    if (count < 0.5)
        return 1.0;
    float cosine = saturate(dot(normalWorld, toLight));
    float sine = sqrt(1.0 - cosine * cosine);
    float4 posInView = mul(shadow_view_matrix, float4(posWorld, 1.0));
    float4 normalInView = mul(shadow_view_matrix, float4(normalWorld, 0.0));
    float coarsest = cysCoarsestTexel();
    // The provider sizes isystem_userdata.w for B's 3x3 kernel (reach 1.5 texels); a receiver on a slope needs
    // a normal offset of about (radius + 0.5) texels of the cascade in use to stay clear of its own depth.
    float normalScale = (CYS_SHADOW_PCF_RADIUS + 0.5) / 1.5;
    float occlusion = 0.0;
    float found = 0.0;
    [unroll] for (int i = 0; i < 4; ++i)
    {
        [branch] if (found == 0.0 && i < count)
        {
            float4 t = cysCascadeCoord(posInView, i);
            [branch] if (cysInsideCascade(t))
            {
                found = 1.0;
                cascade = i;
                float k = cysCascadeTexel(i) / coarsest;
                float4 p = posInView + normalInView * (sine * isystem_userdata.w * k * normalScale);
                occlusion = cysCascadeOcclusion(atlas, p, i, isystem_userdata.x * k);
                if (i + 1 < 4)
                {
                    float edge = min(min(t.x, 1.0 - t.x), min(t.y, 1.0 - t.y));
                    float band = shadow_csm_param.z;
                    [branch] if (edge < band && i + 1 < count)
                    {
                        float4 tn = cysCascadeCoord(posInView, i + 1);
                        [branch] if (cysInsideCascade(tn))
                        {
                            float kn = cysCascadeTexel(i + 1) / coarsest;
                            float4 pn = posInView + normalInView * (sine * isystem_userdata.w * kn * normalScale);
                            float next = cysCascadeOcclusion(atlas, pn, i + 1, isystem_userdata.x * kn);
                            occlusion = lerp(next, occlusion, edge / band);
                        }
                    }
                }
            }
        }
    }
    float fade = smoothstep(0.95 * shadow_csm_param.w, shadow_csm_param.w, length(posWorld - cameraPos));
    return 1.0 - occlusion * (1.0 - fade);
}

// Visibility for SHADOWMAP_TYPE 2 (one map over shadow_proj_matrix), with B's radial fade at the map edge.
float cysShadowSimple(sampler2D atlas, float3 posWorld, float3 normalWorld, float3 toLight)
{
    float cosine = saturate(dot(normalWorld, toLight));
    float sine = sqrt(1.0 - cosine * cosine);
    float4 v = mul(shadow_view_matrix, float4(posWorld + normalWorld * (sine * isystem_userdata.w), 1.0));
    float4 c = mul(shadow_proj_matrix, v);
    float2 uv = float2(0.5, 0.5) + float2(0.5, -0.5) * c.xy / c.w;
    if (any(uv < 0.001) || any(uv > 0.999))
        return 1.0;
    float2 texel = 1.0 / max(shadow_param.z, 1.0).xx;
    float occlusion = cysShadowPCF(atlas, uv, -v.z, isystem_userdata.x, texel, 0.5 * texel, 1.0 - 0.5 * texel);
    float radial = saturate((1.0 - length(uv - 0.5) * 2.0) / 0.2);
    return 1.0 - occlusion * radial;
}

#endif // CYS_SHADOW_LIB_INC
