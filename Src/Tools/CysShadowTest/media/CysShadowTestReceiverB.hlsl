// CY-Source shadow test receiver through client_GL's own shader library (MaterialTemplates.zip ShaderLib): the
// shadow term is computed by B's calculateShadow_csm / calcNormalBias (ShaderLib/CalcShadow.inc) exactly as the
// Model_* templates do, so this validates what the provider feeds against B's contract. Compiled with
// SHADOWMAP_TYPE=1. __VS__ / __PS__ stay undefined: the stage functions of CalcShadow.inc need the template
// structs (VertParams, FragInput) that this test does not include.

#include "ShaderLib/ParamNamed.inc"
#include "ShaderLib/ParamNamedAuto.inc"
#include "ShaderLib/CalcShadow.inc"

struct ReceiverBVertex
{
    float4 position : POSITION;
    float4 posInView : TEXCOORD0;
    float3 worldPos : TEXCOORD1;
    float3 worldNormal : TEXCOORD2;
};

ReceiverBVertex receiverBVS(float4 position : POSITION, float3 normal : NORMAL)
{
    ReceiverBVertex OUT;
    float4 pw = mul(world_matrix, position);
    float3 nw = normalize(mul((float3x3)world_matrix, normal));
    OUT.position = mul(viewproj_matrix, pw);
    // = Calc_Shadow_Vs for SHADOWMAP_TYPE CSM
    OUT.posInView = mul(shadow_view_matrix, float4(pw.xyz + calcNormalBias(nw), pw.w));
    OUT.worldPos = pw.xyz;
    OUT.worldNormal = nw;
    return OUT;
}

sampler2D shadowAtlas : register(s5);
uniform float4 albedo;
uniform float4 gridParams;

float4 receiverBPS(ReceiverBVertex IN) : COLOR
{
    // = Calc_Shadow_Ps for SHADOWMAP_TYPE CSM, non-PBR
    float brightness = dot(light_diffuse_colour_array[0].rgb, float3(0.299, 0.587, 0.114));
    float shadowFactor = calculateShadow_csm(shadowAtlas, IN.posInView, brightness, IN.worldPos);
    float r = 1.0 - shadow_param.x;
    shadowFactor = r + shadowFactor * (1.0 - r);

    float3 n = normalize(IN.worldNormal);
    float ndl = saturate(dot(n, normalize(light_position_array[0].xyz)));
    float2 coord = IN.worldPos.xz / gridParams.x;
    float2 g = abs(frac(coord - 0.5) - 0.5) / max(fwidth(coord), 1.0e-5);
    float gridLine = 1.0 - min(min(g.x, g.y), 1.0);
    float3 base = albedo.rgb * (1.0 - albedo.a * gridLine);
    float3 colour = base * (ambient_light_colour.rgb + light_diffuse_colour_array[0].rgb * ndl * shadowFactor);
    return float4(colour, 1.0);
}
