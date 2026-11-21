#version 440

// Smoke drifting up over the wallpaper, under the embers: dark, soft, slow, and only just there.
//
// What makes it read as smoke and not as fog:
//  * It is dark. Smoke takes light away, so it is drawn as a translucent brown-black over the sky, and shows as
//    silhouettes against the sun and the red glow around it.
//  * It rises and spreads. It is densest at the bottom of the screen, where the fire would be, and thins as it
//    climbs. The pattern is carried upward and slightly sideways by the same kind of wind the embers have, and it
//    keeps changing shape as it goes (the noise is three-dimensional, with time as the third axis), so it never
//    loops.
//  * It curls. The noise is warped by more noise, which gives the folded, billowing edges that plain noise lacks.
//  * It is lit from behind. Where the side of a wisp faces the sun, it glows orange, and more strongly the nearer
//    the sun is; the rest stays dark.
//
// The output is premultiplied alpha with alpha raised to cover the colour. The sun's position is given by the
// service so that it matches the wallpaper's. Rebuild with build-shaders.sh after editing.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;        // seconds, accumulated by the service
    float amount;      // 0-1: how much smoke
    float seed;        // random per session
    vec2 resolution;
    vec3 sun;          // the sun's centre (x from the left, y up from the bottom) and radius, in screen heights
} ubuf;

float hash31(vec3 p3) {
    p3 = fract(p3 * 0.1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}

// Smooth value noise in three dimensions.
float vnoise(vec3 x) {
    vec3 i = floor(x);
    vec3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    float a = mix(mix(hash31(i), hash31(i + vec3(1, 0, 0)), f.x),
                  mix(hash31(i + vec3(0, 1, 0)), hash31(i + vec3(1, 1, 0)), f.x), f.y);
    float b = mix(mix(hash31(i + vec3(0, 0, 1)), hash31(i + vec3(1, 0, 1)), f.x),
                  mix(hash31(i + vec3(0, 1, 1)), hash31(i + vec3(1, 1, 1)), f.x), f.y);
    return mix(a, b, f.z);
}

// Four octaves. Each is twice as fine in space but only 1.7 times as fast in time: finer detail changes faster, as
// small eddies do, but not so much faster that the smoke seems to boil.
float fbm(vec3 x) {
    float sum = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 4; i++) {
        sum += amp * vnoise(x);
        x = vec3(mat2(0.80, -0.60, 0.60, 0.80) * x.xy * 2.03, x.z * 1.7) + vec3(17.1, 9.2, 3.7);
        amp *= 0.5;
    }
    return sum;   // about 0..0.94, centred near 0.47
}

// How much smoke there is at p (screen heights, y up), 0..1.
//
// A soft body of billows with thin filaments running through it. The filaments are the ridge of the same noise,
// the curve where it crosses its middle value, so they follow the edges of the billows instead of floating free.
// The noise is stretched a little along the flow. The flow is not one rigid drift: the field that warps the
// pattern is carried at a different speed from the pattern, so the shapes are continually sheared, folded and
// pulled out as they climb, and they change on top of that as the third axis, time, advances.
float density(vec2 p) {
    float t = ubuf.time;
    float z = t * 0.030 + ubuf.seed;

    // The field that bends the pattern: broad, and carried more slowly than the pattern is.
    vec2 qw = vec2(1.5 * (p.x - 0.006 * t), 1.1 * (p.y - 0.018 * t));
    vec2 warp = vec2(fbm(vec3(qw, z)), fbm(vec3(qw + 7.3, z + 3.1))) - 0.47;

    // The pattern: carried up and a little to the right, and stretched a little upward.
    vec2 q = vec2(2.1 * (p.x - 0.014 * t), 1.5 * (p.y - 0.036 * t));
    float n = fbm(vec3(q + warp * 1.7, z * 1.3));

    float soft = smoothstep(0.42, 0.66, n);
    float ridge = 1.0 - abs(2.0 * n - 1.0);                // 1 along a filament, 0 away from it
    float thin = smoothstep(0.74, 0.95, ridge);
    // Filaments thin out and thicken along their length instead of running unbroken.
    float breakup = smoothstep(0.20, 0.60, fbm(vec3(q * 0.5 + 3.0, z * 0.8)));

    float rise = exp(-p.y * 1.2);                          // thick where it starts, thinner where it has climbed
    return clamp(0.55 * soft + 0.75 * thin * breakup, 0.0, 1.0) * rise;
}

void main() {
    float aspect = ubuf.resolution.x / ubuf.resolution.y;
    vec2 p = vec2(qt_TexCoord0.x * aspect, 1.0 - qt_TexCoord0.y);   // y = 0 is the bottom, 1 the top

    float d = density(p);

    // Light from the sun reaches the side of a wisp that faces it: the point just toward the sun is clearer.
    vec2 toSun = ubuf.sun.xy - p;
    float dist = length(toSun);
    vec2 dir = toSun / max(dist, 1e-4);
    float edge = clamp((d - density(p + dir * 0.035)) * 3.0, 0.0, 1.0);
    float reach = exp(-max(0.0, dist - ubuf.sun.z) / (ubuf.sun.z * 2.5));   // the nearer the sun, the more light
    reach *= smoothstep(ubuf.sun.z * 0.98, ubuf.sun.z * 1.10, dist);       // none on the sun's face: there it is a silhouette

    float a = d * ubuf.amount * 0.75;
    vec3 body = vec3(0.055, 0.028, 0.022) * a;                       // a warm brown-black, not grey
    vec3 lit = vec3(1.00, 0.40, 0.08) * (edge * reach * 1.6) * a;    // the sun through the thin edge
    vec3 rgb = body + lit;
    float alpha = max(a, max(rgb.r, max(rgb.g, rgb.b)));             // premultiplied: colour never exceeds alpha
    fragColor = vec4(rgb, alpha) * ubuf.qt_Opacity;
}
