#include <metal_stdlib>

using namespace metal;

struct SnowUniforms {
    float2 viewSize;
    float2 origin;
    float columnWidth;
    int columnCount;
    float time;
    float scale;
    float dark;
    float pileTop;
    float pileBottom;
    float surfaceWidth;
    float cornerRadius;
    float ledge;
    float cornerExponent;
};

struct SnowSprite {
    float2 position;
    float2 velocity;
    float size;
    float alpha;
    float soft;
    float lump;
};

struct SnowSpriteOut {
    float4 position [[position]];
    float pointSize [[point_size]];
    float2 streak;
    float radius;
    float alpha;
    float soft;
    float lump;
    float spin;
};

vertex SnowSpriteOut snowSpriteVertex(
    uint vid [[vertex_id]],
    const device SnowSprite *sprites [[buffer(0)]],
    constant SnowUniforms &u [[buffer(1)]]
) {
    SnowSprite s = sprites[vid];

    float pixels = s.size * u.scale;
    float2 travel = s.velocity * 0.018;
    float smear = min(length(travel), s.size * (s.lump > 0.0 ? 1.2 : 2.2));
    float2 streak = smear > 0.25 ? normalize(travel) * smear * u.scale : float2(0.0);
    float reach = s.lump > 0.0 ? 1.3 : 1.0;
    float extent = max(pixels * reach + length(streak), 2.0);

    SnowSpriteOut out;
    out.position = float4(s.position / u.viewSize * 2.0 - 1.0, 0.0, 1.0);
    out.pointSize = extent;
    out.streak = streak / extent;
    out.radius = pixels / extent * 0.5;
    out.alpha = s.alpha * min(pixels / 2.0, 1.0) * pixels / max(pixels + length(streak) * 0.6, 0.001);
    out.soft = s.soft;
    out.lump = s.lump;
    out.spin = s.lump > 0.0 ? u.time * (s.lump - 0.5) * 9.0 + s.lump * 40.0 : 0.0;

    return out;
}

fragment float4 snowSpriteFragment(
    SnowSpriteOut in [[stage_in]],
    float2 coord [[point_coord]],
    constant SnowUniforms &u [[buffer(0)]]
) {
    float2 p = float2(coord.x - 0.5, 0.5 - coord.y);
    float2 half_ = in.streak * 0.5;
    float span = dot(half_, half_);
    float t = span > 0.0 ? clamp(dot(p, half_) / span, -1.0, 1.0) : 0.0;
    float2 d = p - half_ * t;
    float r = length(d) / max(in.radius, 0.001);
    float shading = 0.0;

    if (in.lump > 0.0) {
        float angle = atan2(d.y, d.x) + in.spin;
        r /= 1.0 + 0.14 * sin(3.0 * angle) + 0.08 * sin(5.0 * angle + in.lump * 21.0) + 0.05 * sin(2.0 * angle + in.lump * 9.0);
        shading = saturate(dot(d / max(in.radius, 0.001), float2(0.45, -0.6))) * 0.4;
    }

    float head = span > 0.0 ? 0.15 + 0.85 * pow(t * 0.5 + 0.5, 1.5) : 1.0;
    float a = saturate((1.0 - smoothstep(mix(0.6, 0.0, in.soft), 1.0, r)) * in.alpha * head * mix(1.3, 1.0, u.dark));

    if (a < 0.002) {
        discard_fragment();
    }

    float3 core = mix(float3(0.52, 0.65, 0.86), float3(0.965, 0.975, 0.995), u.dark);
    float3 rim = mix(float3(0.36, 0.48, 0.72), float3(0.62, 0.67, 0.77), u.dark);
    float3 color = mix(core, rim, saturate(smoothstep(0.35, 1.0, r) * 0.65 + shading));

    return float4(color * a, a);
}

struct SnowPileOut {
    float4 position [[position]];
    float2 point;
};

vertex SnowPileOut snowPileVertex(uint vid [[vertex_id]], constant SnowUniforms &u [[buffer(0)]]) {
    float2 corner = float2(float(vid & 1), float(vid >> 1));
    float width = u.ledge > 0.0 ? u.surfaceWidth : float(u.columnCount) * u.columnWidth;
    float2 p = float2(corner.x * width, mix(u.pileBottom, u.pileTop, corner.y));

    SnowPileOut out;
    out.position = float4((p + u.origin) / u.viewSize * 2.0 - 1.0, 0.0, 1.0);
    out.point = p;

    return out;
}

static float snowHeight(const device float *heights, constant SnowUniforms &u, float x) {
    float f = x / u.columnWidth - 0.5;
    float base = floor(f);
    int i = clamp(int(base), 0, u.columnCount - 1);
    int j = min(i + 1, u.columnCount - 1);

    return mix(heights[i], heights[j], saturate(f - base));
}

static float snowHash(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);

    return fract(p.x * p.y);
}

static float4 snowShade(float y, float level, float bed, float underside, float slope, float scale, float time, float dark, float2 pixel) {
    float depth = level - y;
    float coverage = saturate(depth * scale + 0.5)
        * saturate((y - underside) * scale + 0.5)
        * saturate((level - bed) / 0.75);

    if (coverage <= 0.0) {
        return float4(0.0);
    }

    float light = dot(normalize(float2(-slope, 1.0)), normalize(float2(-0.5, 1.0)));

    float3 surface = mix(float3(0.84, 0.89, 0.96), float3(0.925, 0.94, 0.965), dark);
    float3 shadow = mix(float3(0.56, 0.65, 0.82), float3(0.72, 0.78, 0.88), dark);
    float shade = (1.0 - exp(-depth / 30.0)) * 0.32 + (1.0 - light) * 0.6 * exp(-depth / 5.0);
    float3 color = mix(surface, shadow, saturate(shade));

    color = mix(color, float3(0.975, 0.982, 0.995), exp(-depth * 0.9) * 0.6 * dark);
    color = mix(color, float3(0.45, 0.55, 0.74), exp(-depth * 0.8) * 0.7 * (1.0 - dark));
    color += (snowHash(floor(pixel)) - 0.5) * 0.02;

    float seed = snowHash(floor(pixel * 0.5) + 31.7);

    if (seed > 0.992) {
        float twinkle = pow(saturate(sin(time * (0.6 + seed * 1.8) + seed * 90.0)), 28.0);
        color = mix(color, float3(1.0), twinkle * exp(-depth / 7.0));
    }

    return float4(color * coverage, coverage);
}

static float snowCorner(float x, float width, float radius, float exponent) {
    float inset = min(x, width - x);

    if (radius <= 0.0 || inset >= radius) {
        return 0.0;
    }

    float u = 1.0 - inset / radius;

    return -radius * (1.0 - pow(max(0.0, 1.0 - pow(u, exponent)), 1.0 / exponent));
}

fragment float4 snowPileFragment(
    SnowPileOut in [[stage_in]],
    const device float *heights [[buffer(0)]],
    constant SnowUniforms &u [[buffer(1)]]
) {
    float x = in.point.x;
    float level = snowHeight(heights, u, x);
    float bed = snowHeight(heights + u.columnCount, u, x);
    float slope = (snowHeight(heights, u, x + 2.0) - snowHeight(heights, u, x - 2.0)) * 0.25;
    float underside = bed;

    if (u.ledge > 0.0) {
        float thickness = max(level - bed, 0.0);
        float edge = saturate(min(x, u.surfaceWidth - x) / u.columnWidth);

        bed = snowCorner(x, u.surfaceWidth, u.cornerRadius, u.cornerExponent);
        level = bed + thickness * edge;
        underside = -1e4;
    }

    float4 color = snowShade(in.point.y, level, bed, underside, slope, u.scale, u.time, u.dark, in.position.xy);

    if (color.a <= 0.0) {
        discard_fragment();
    }

    return color;
}
