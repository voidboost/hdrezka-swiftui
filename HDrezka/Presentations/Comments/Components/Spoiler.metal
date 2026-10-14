#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

static float2 hash22(float2 p) {
    float3 p3 = fract(float3(p.xyx) * float3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

static float4 hash43(float3 p) {
    float4 p4 = fract(float4(p.xyzx) * float4(0.1031, 0.1030, 0.0973, 0.1099));
    p4 += dot(p4, p4.wzxy + 33.33);
    return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}

static float lifeAlpha(float base, float age) {
    float curve = age < 0.25 ? 0.0
        : age < 0.5 ? (age - 0.25) * 4.0
        : age < 0.75 ? 1.0 - (age - 0.5) * 4.0
        : -(age - 0.75) * 4.0;

    return saturate(base + curve);
}

[[ stitchable ]] half4 spoiler(
    float2 position,
    half4 color,
    float time,
    float cell,
    float radius,
    device const float *drifts,
    int count
) {
    float reach = radius + 0.5;
    float alpha = 0.0;

    for (int index = 0; index + 1 < count; index += 2) {
        float2 local = position - float2(drifts[index], drifts[index + 1]);
        float2 start = floor(local / cell - 0.5);
        float layer = float(index) * 50.85;

        for (int y = 0; y <= 1; y++) {
            for (int x = 0; x <= 1; x++) {
                float2 c = start + float2(x, y);
                float2 key = c + layer;
                float2 seed = hash22(key);
                float t = time + seed.x;
                float cycle = floor(t);
                float age = t - cycle;

                float4 random = hash43(float3(key, cycle));
                float2 particle = (c + random.xy + (random.zw - 0.5) * 0.5 * age) * cell;
                float2 delta = local - particle;
                float distanceSquared = dot(delta, delta);

                if (distanceSquared < reach * reach) {
                    float base = saturate(fract(seed.y + cycle * 0.618034) * 2.0);
                    alpha = max(alpha, saturate(reach - sqrt(distanceSquared)) * lifeAlpha(base, age));
                }
            }
        }
    }

    return color * half(alpha);
}
