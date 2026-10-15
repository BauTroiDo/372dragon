// CY-Source post-processing: full-screen quad vertex shader (vs_3_0) of every CY-Source pass except HeightFog.
// The quad is OGRE's compositor Rectangle2D (identity view / projection; OGRE applies the D3D9 half-texel offset).
// uv goes to TEXCOORD0 and TEXCOORD1 because B's FXAA pixel shaders (AntiAlias.hlsl) read TEXCOORD1.
void quad_vs(float4 pos : POSITION,
             float2 uv : TEXCOORD0,
             uniform float4x4 worldViewProj,
             out float4 oPos : POSITION,
             out float2 oUv0 : TEXCOORD0,
             out float2 oUv1 : TEXCOORD1)
{
    oPos = mul(worldViewProj, pos);
    oUv0 = uv;
    oUv1 = uv;
}
