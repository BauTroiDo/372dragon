// CY-Source post-processing: copies, the final FP16 -> back buffer pass and the depth-node initialisation (ps_3_0).

float4 copy_ps(float2 uv : TEXCOORD0,
               uniform sampler2D srcTex : register(s0)) : COLOR
{
    return tex2D(srcTex, uv);
}

// Last pass of the chain. Interleaved-gradient-noise dither of +-0.5 LSB (ditherAmount = 1) hides the 8-bit banding
// that skies, fog and bloom gradients of the FP16 chain would otherwise show.
float4 final_ps(float2 uv : TEXCOORD0,
                float2 vpos : VPOS,
                uniform sampler2D srcTex : register(s0),
                uniform float ditherAmount) : COLOR
{
    float3 c = tex2D(srcTex, uv).rgb;
    float n = frac(52.9829189 * frac(dot(vpos, float2(0.06711056, 0.00583715))));
    c += (n - 0.5) * (ditherAmount / 255.0);
    return float4(c, 1.0);
}

// Depth node: every pixel starts at the far value (sky); B clears SceneDepth to 50000 (SceneDepth.hlsl).
float4 depthclear_ps(float2 uv : TEXCOORD0,
                     uniform float farValue) : COLOR
{
    return float4(farValue, 0.0, 0.0, 1.0);
}
