#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

[[ stitchable ]] half4 ambientLight(
    float2 position,
    half4 color,
    float4 videoRect,
    float4 bounds,
    texture2d<half> frame,
    float4 crop
) {
    constexpr float fan = 0.3;
    constexpr float blur = 0.2;
    constexpr int taps = 16;
    constexpr sampler linearSampler(address::clamp_to_edge, filter::linear);

    float2 center = (videoRect.xy + videoRect.zw) * 0.5;
    float2 halfSize = max((videoRect.zw - videoRect.xy) * 0.5, float2(0.001));
    float2 p = (position - center) / halfSize;
    float s = max(abs(p.x), abs(p.y));

    float2 uv;
    float progress = 0.0;

    if (s <= 1.0) {
        uv = p * 0.5 + 0.5;
    } else {
        uv = clamp(p / (1.0 + (s - 1.0) * fan), -1.0, 1.0) * 0.5 + 0.5;

        float2 outside = max(videoRect.xy - position, position - videoRect.zw);
        bool2 isBefore = position < videoRect.xy;
        float2 space = abs(select(videoRect.zw, videoRect.xy, isBefore) - select(bounds.zw, bounds.xy, isBefore));
        float2 edge = saturate(outside / max(space, float2(0.001)));

        progress = max(edge.x, edge.y);
    }

    float falloff = pow(1.0 - progress, 2.2);

    if (falloff <= 0.0) {
        return half4(0.0);
    }

    float2 cropScale = 1.0 - crop.xy - crop.zw;

    if (progress <= 0.0) {
        half4 sampled = frame.sample(linearSampler, saturate(crop.xy + uv * cropScale));

        return half4(sampled.rgb * half(falloff), half(falloff));
    }

    float2 radius = blur * progress * float2(1.0, halfSize.x / halfSize.y);
    half3 sum = half3(0.0);

    for (int index = 0; index < taps; index++) {
        float angle = float(index) * 2.39996;
        float2 offset = float2(cos(angle), sin(angle)) * sqrt((float(index) + 0.5) / float(taps)) * radius;

        sum += frame.sample(linearSampler, saturate(crop.xy + (uv + offset) * cropScale)).rgb;
    }

    return half4(sum / half(taps) * half(falloff), half(falloff));
}
