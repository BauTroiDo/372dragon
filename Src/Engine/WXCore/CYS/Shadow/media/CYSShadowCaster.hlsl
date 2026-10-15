// CY-Source (shadow agent): depth-only shadow casters for the CY-Source shadow atlas. Used only when client_GL's
// MaterialTemplates.zip does not provide B's Depth_* programs (Character.program).
//
// Output: linear light-view depth (-z in light view space, world units) in .r - the value ShaderLib/CalcShadow.inc
// and CYSShadowLib.inc compare; 0 is reserved for "no caster" (the clear colour of the atlas).
// Defines: USE_SKIN     linear blend skinning, <= MAX_SKIN_BONES bones per sub-mesh (OGRE passes the used bones)
//          USE_TEXCOORD pass uv to the pixel shader
//          ALPHA_TEST   clip at alphaRef (the pass alpha reference / 255) with the texture at s0
// Matrices follow B's convention: column_major_matrices false, mul(M, v).

#ifndef USE_SKIN
#define USE_SKIN 0
#endif
#ifndef USE_TEXCOORD
#define USE_TEXCOORD 0
#endif
#ifndef ALPHA_TEST
#define ALPHA_TEST 0
#endif
#ifndef MAX_SKIN_BONES
#define MAX_SKIN_BONES 74
#endif

uniform float4x4 world_matrix;
uniform float4x4 view_matrix;
uniform float4x4 projection_matrix;
#if USE_SKIN
uniform float3x4 world_matrix_array_3x4[MAX_SKIN_BONES];
uniform float4 imodel_userdata;     // .y = blend weights per vertex of the mesh being drawn
#endif

struct CasterInput
{
    float4 position : POSITION;
#if USE_TEXCOORD
    float2 uv : TEXCOORD0;
#endif
#if USE_SKIN
    float4 blendIndices : BLENDINDICES;
    float4 blendWeights : BLENDWEIGHT;
#endif
};

struct CasterOutput
{
    float4 position : POSITION;
    float3 uvDepth : TEXCOORD0;     // xy = uv, z = linear light-view depth
};

CasterOutput casterVS(CasterInput IN)
{
    float4 worldPos;
#if USE_SKIN
    float3 blended = float3(0, 0, 0);
    for (int i = 0; i < 4; ++i)
    {
        // Weights past the mesh's count are undefined (a FLOAT3 element reads w = 1): only
        // imodel_userdata.y of them take part.
        float w = (i < imodel_userdata.y) ? IN.blendWeights[i] : 0.0;
        blended += mul(world_matrix_array_3x4[(int)IN.blendIndices[i]], IN.position) * w;
    }
    worldPos = float4(blended, 1.0);
#else
    worldPos = mul(world_matrix, IN.position);
#endif
    float4 viewPos = mul(view_matrix, worldPos);
    CasterOutput OUT;
    OUT.position = mul(projection_matrix, viewPos);
#if USE_TEXCOORD
    OUT.uvDepth = float3(IN.uv, -viewPos.z);
#else
    OUT.uvDepth = float3(0.0, 0.0, -viewPos.z);
#endif
    return OUT;
}

#if ALPHA_TEST
sampler2D casterTexture : register(s0);
uniform float alphaRef;
#endif

float4 casterPS(float3 uvDepth : TEXCOORD0) : COLOR
{
#if ALPHA_TEST
    clip(tex2D(casterTexture, uvDepth.xy).a - alphaRef);
#endif
    return float4(uvDepth.z, 0.0, 0.0, 1.0);
}
