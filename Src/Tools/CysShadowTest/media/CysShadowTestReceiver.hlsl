// CY-Source shadow test receiver (Src\Tools\CysShadowTest): ground and props lit by the sun, shadowed through the
// engine's CYSShadowLib.inc (Src\Engine\WXCore\CYS\Shadow\media). Local test shader: the game's receivers are the
// client_GL templates (ShaderLib/CalcShadow.inc), see CysShadowTestReceiverB.hlsl for that path.

#include "CYSShadowLib.inc"

uniform float4x4 world_matrix;
uniform float4x4 viewproj_matrix;

struct ReceiverVertex
{
    float4 position : POSITION;
    float3 worldPos : TEXCOORD0;
    float3 worldNormal : TEXCOORD1;
};

ReceiverVertex receiverVS(float4 position : POSITION, float3 normal : NORMAL)
{
    ReceiverVertex OUT;
    float4 pw = mul(world_matrix, position);
    OUT.position = mul(viewproj_matrix, pw);
    OUT.worldPos = pw.xyz;
    OUT.worldNormal = mul((float3x3)world_matrix, normal);
    return OUT;
}

sampler2D ShadowMapSampler : register(s5);
uniform float4 light_position;          // directional light: (-direction, 0)
uniform float4 light_diffuse_colour;
uniform float4 ambient_light_colour;
uniform float3 camera_position;
uniform float4 albedo;                  // rgb base colour, a = grid line strength
uniform float4 gridParams;              // x cell size (world units), y unused, z cascade tint, w shadow type

float3 cascadeTint(float i)
{
    return i < 0.5 ? float3(1.0, 0.30, 0.30) :
          (i < 1.5 ? float3(0.30, 1.0, 0.30) :
          (i < 2.5 ? float3(0.30, 0.50, 1.0) : float3(1.0, 0.85, 0.25)));
}

float4 receiverPS(ReceiverVertex IN) : COLOR
{
    float3 n = normalize(IN.worldNormal);
    float3 toLight = normalize(light_position.xyz);
    float ndl = saturate(dot(n, toLight));

    // anti-aliased metre grid in world xz: shows texel density and any shimmer of the shadow edges
    float2 coord = IN.worldPos.xz / gridParams.x;
    float2 g = abs(frac(coord - 0.5) - 0.5) / max(fwidth(coord), 1.0e-5);
    float gridLine = 1.0 - min(min(g.x, g.y), 1.0);

    float cascade = -1.0;
    float visibility = 1.0;
    [branch] if (gridParams.w > 1.5)
        visibility = cysShadowSimple(ShadowMapSampler, IN.worldPos, n, toLight);
    else
        visibility = cysShadowCSM(ShadowMapSampler, IN.worldPos, n, toLight, camera_position, cascade);
    visibility = lerp(1.0, visibility, shadow_param.x);

    float3 base = albedo.rgb * (1.0 - albedo.a * gridLine);
    float3 colour = base * (ambient_light_colour.rgb + light_diffuse_colour.rgb * ndl * visibility);
    if (gridParams.z > 0.5 && cascade >= 0.0)
        colour = lerp(colour, cascadeTint(cascade) * dot(colour, float3(0.4, 0.4, 0.4)) * 1.6, 0.55);
    return float4(colour, 1.0);
}
