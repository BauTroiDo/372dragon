// CY-Source (shadow agent): debug strip of the shadow atlas (CYSShadowSystem::setDebugView). Near casters are
// bright, far ones dark, empty texels (depth 0) dark blue; tile borders orange.

struct DebugVertex
{
    float4 position : POSITION;
    float2 uv : TEXCOORD0;
};

DebugVertex debugVS(float4 position : POSITION, float2 uv : TEXCOORD0)
{
    DebugVertex OUT;
    OUT.position = float4(position.xy, 0.0, 1.0);   // Rectangle2D corners are already in clip space
    OUT.uv = uv;
    return OUT;
}

sampler2D shadowAtlas : register(s0);
uniform float depthScale;   // 1 / largest cascade depth range
uniform float cascades;     // tiles side by side

float4 debugPS(float2 uv : TEXCOORD0) : COLOR
{
    float depth = tex2Dlod(shadowAtlas, float4(uv, 0.0, 0.0)).r;
    float3 colour = depth > 0.0
        ? lerp(float3(1.0, 0.94, 0.82), float3(0.16, 0.12, 0.10), saturate(depth * depthScale))
        : float3(0.05, 0.07, 0.13);
    float2 pixel = float2(abs(ddx(uv.x)) * cascades, abs(ddy(uv.y)));
    float tile = frac(uv.x * cascades);
    if (tile < 1.5 * pixel.x || tile > 1.0 - 1.5 * pixel.x || uv.y < 1.5 * pixel.y || uv.y > 1.0 - 1.5 * pixel.y)
        colour = float3(0.95, 0.45, 0.10);
    return float4(colour, 1.0);
}
