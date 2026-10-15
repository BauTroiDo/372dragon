// CY-Source post-processing: depth node programs (Docs/specs/render/02-postfx.md 1, SceneDepth).
// Linear view-space depth (-viewZ, world units) into an R32F target: the encoding of B's Depth_ps.hlsl.
// Variants: CYS_WEIGHTS 0 (static or software-skinned) or 1..4 (hardware skinning with OGRE's
// world_matrix_array_3x4, up to 80 bones); CYS_UV 1 passes uv for the alpha-tested pixel shader.
#ifndef CYS_WEIGHTS
#define CYS_WEIGHTS 0
#endif
#ifndef CYS_UV
#define CYS_UV 0
#endif
#define CYS_MAX_BONES 80

struct CysDepthOut
{
    float4 pos     : POSITION;
    float3 uvDepth : TEXCOORD0;     // xy = uv, z = linear depth
};

#if CYS_WEIGHTS > 0
uniform float4 worldMatrix3x4Array[CYS_MAX_BONES * 3];
uniform float4x4 viewProj;
uniform float4x4 view;
#else
uniform float4x4 worldViewProj;
uniform float4x4 worldView;
#endif

CysDepthOut depth_vs(float4 position : POSITION
#if CYS_UV
                     , float2 uv : TEXCOORD0
#endif
#if CYS_WEIGHTS > 0
                     , float4 blendIdx : BLENDINDICES
                     , float4 blendWgt : BLENDWEIGHT
#endif
                     )
{
    CysDepthOut o;
#if CYS_WEIGHTS > 0
    float4 p = float4(position.xyz, 1.0);
    float3 wp = float3(0.0, 0.0, 0.0);
    [unroll] for (int i = 0; i < CYS_WEIGHTS; ++i)
    {
        int idx = (int)blendIdx[i] * 3;
        wp += float3(dot(worldMatrix3x4Array[idx], p),
                     dot(worldMatrix3x4Array[idx + 1], p),
                     dot(worldMatrix3x4Array[idx + 2], p)) * blendWgt[i];
    }
    float4 w4 = float4(wp, 1.0);
    o.pos = mul(viewProj, w4);
    float viewZ = mul(view, w4).z;
#else
    o.pos = mul(worldViewProj, position);
    float viewZ = mul(worldView, position).z;
#endif
#if CYS_UV
    o.uvDepth = float3(uv, -viewZ);
#else
    o.uvDepth = float3(0.0, 0.0, -viewZ);
#endif
    return o;
}

float4 depth_ps(float3 uvDepth : TEXCOORD0) : COLOR
{
    return float4(uvDepth.z, 0.0, 0.0, 1.0);
}

float4 depth_at_ps(float3 uvDepth : TEXCOORD0,
                   uniform sampler2D diffuseTex : register(s0),
                   uniform float alphaRef) : COLOR
{
    clip(tex2D(diffuseTex, uvDepth.xy).a - alphaRef);
    return float4(uvDepth.z, 0.0, 0.0, 1.0);
}
