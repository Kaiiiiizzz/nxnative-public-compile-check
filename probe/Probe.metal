#include <metal_stdlib>
using namespace metal;
struct VertexOut { float4 position [[position]]; float3 color; };
vertex VertexOut probe_vertex(uint index [[vertex_id]]) {
    const float2 positions[3] = {float2(0, 0.55), float2(-0.55, -0.55), float2(0.55, -0.55)};
    const float3 colors[3] = {float3(1, 0.2, 0.4), float3(0.2, 1, 0.5), float3(0.2, 0.4, 1)};
    return {float4(positions[index], 0, 1), colors[index]};
}
fragment float4 probe_fragment(VertexOut input [[stage_in]]) { return float4(input.color, 1); }
