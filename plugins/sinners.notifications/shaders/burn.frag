#version 440

// A notification card burning away, as its layer effect: `source` is the card, drawn normally.
//
// How paper burns, and so how this does:
//  * The fire is lit at one point, the middle of the bottom edge, and spreads from it as a contour that climbs a
//    little slower than it spreads sideways and reaches the edges last. It meanders; it is not a wipe. (arrival().)
//  * Just ahead of the fire the paper browns and warms.
//  * On the fire line itself the glow is white-gold in a thin core, orange and red beyond it, and not even: it
//    flares and dulls along the line as the fire finds fuel.
//  * Behind the line the paper is charcoal, not black: grey-brown, flaky, partly ash, semi-transparent, with a
//    network of cracks that glow red for a while and then go dark.
//  * The char crumbles away from its far edge, raggedly, and is gone.
// Everything is a function of `progress`, so a frame needs no history. ash.frag draws what happens around the
// card: the light on its surroundings, the flames, the smoke and the ash.
//
// The block between the SHARED markers is repeated in ash.frag, which has to know where and when the card burnt.
// build-shaders.sh checks that the two copies are identical. The output is premultiplied alpha.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;    // 0 = untouched, 1 = gone
    float seed;        // differs from card to card, so each burns its own way
    vec2 cardSize;     // the card, in pixels
} ubuf;

layout(binding = 1) uniform sampler2D source;

// ==== BEGIN SHARED (identical in burn.frag and ash.frag)
float hash21(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 x) {
    vec2 i = floor(x), f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1, 0)), f.x), mix(hash21(i + vec2(0, 1)), hash21(i + vec2(1, 1)), f.x), f.y);
}

// One unit of the arrival field, in pixels.
float unitPx(vec2 size) { return size.x / 8.0 + size.y * 0.35; }

// The fire is lit at one point: the middle of the bottom edge, a little to one side or the other (by 4% of the width),
// so that no two cards are exactly alike.
float ignitionX(vec2 size, float seed) { return (0.5 + 0.08 * (hash21(vec2(3.0, seed)) - 0.5)) * size.x; }

// When the fire would reach q if the paper were perfectly even: the distance from the ignition point, with up a
// quarter longer than along, so the fire climbs a little slower than it spreads: a wide, rounded dome, which takes a
// moment to reach the top. (Raise the 1.25 to slow the climb further, lower it to quicken it: each 0.25 moves the
// time the fire reaches the top centre of a 508x85 card by about 0.12 s of a 2.6 s burn, and the far ends by almost
// nothing. Much below 0.75, a wide card is at the top at once and the fire just sweeps outward.)
float spread(vec2 q, vec2 size, float seed) {
    vec2 d = vec2(q.x - ignitionX(size, seed), (size.y - q.y) * 1.25);
    return length(d) / unitPx(size);
}

// When the fire reaches the point px (card space, pixels, y down), in those units. A point outside the card takes the
// value of the nearest point on it, so the light around the card can follow the fire.
float arrival(vec2 px, vec2 size, float seed) {
    vec2 q = clamp(px, vec2(0.0), size);
    q += 15.0 * (vec2(vnoise(q / 47.0 + seed), vnoise(q / 47.0 + seed + 7.3)) - 0.5);      // the contour meanders
    float best = spread(q, size, seed);
    float billow = 0.6 * vnoise(q / 38.0 + seed * 1.3) + 0.4 * vnoise(q / 19.0 + seed * 2.1 + 3.0);
    float fibre = vnoise(q / 6.0 + seed * 3.7);
    float lean = vnoise(q / 95.0 + seed * 5.0);                                            // some stretches burn slower
    return best + 0.60 * (billow - 0.5) + 0.30 * (lean - 0.5) + 0.05 * (fibre - 0.5);
}

// The fire line starts before the first point catches, and has to end past the last point on THIS card by more than
// the char is wide, or a stretch of the card is never burnt. The last point is on the top edge (the farthest from
// the ignition line), so the end is found from the even-paper arrival along it, plus the most the noise can add to
// it (0.57) and the char's width (0.52). The burn therefore always finishes, whatever the seed.
const float FRONT_START = -0.15;
float frontEnd(vec2 size, float seed) {
    float worst = 0.0;
    for (int k = 0; k <= 12; k++) worst = max(worst, spread(vec2(float(k) / 12.0 * size.x, 0.0), size, seed));
    return worst + 1.10;
}
float frontAt(float progress, float end) { return mix(FRONT_START, end, progress); }
// ==== END SHARED

// Burning charcoal's colour at heat h: black, deep red, red, orange, gold, pale gold.
vec3 heatColour(float h) {
    vec3 c = mix(vec3(0.0), vec3(0.30, 0.020, 0.004), smoothstep(0.00, 0.12, h));
    c = mix(c, vec3(0.85, 0.120, 0.010), smoothstep(0.10, 0.35, h));
    c = mix(c, vec3(1.00, 0.420, 0.040), smoothstep(0.30, 0.60, h));
    c = mix(c, vec3(1.00, 0.780, 0.300), smoothstep(0.55, 0.90, h));
    c = mix(c, vec3(1.00, 0.800, 0.340), smoothstep(0.85, 1.15, h));
    return c;
}

// Cellular noise: the distance to the nearest and second-nearest of a scatter of points. Where the two are almost
// equal is a crack between cells, and the cracks join up into a network.
float cracks(vec2 x) {
    vec2 i = floor(x), f = fract(x);
    float d1 = 8.0, d2 = 8.0;
    for (int j = -1; j <= 1; j++) {
        for (int k = -1; k <= 1; k++) {
            vec2 g = vec2(float(k), float(j));
            vec2 o = vec2(hash21(i + g), hash21(i + g + 17.0));
            float d = length(g + o - f);
            if (d < d1) { d2 = d1; d1 = d; } else if (d < d2) { d2 = d; }
        }
    }
    return 1.0 - smoothstep(0.0, 0.07, d2 - d1);
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec4 src = texture(source, uv);
    if (src.a <= 0.0) { fragColor = vec4(0.0); return; }

    vec2 px = uv * ubuf.cardSize;
    float unit = unitPx(ubuf.cardSize);
    float end = frontEnd(ubuf.cardSize, ubuf.seed);
    float behind = (frontAt(ubuf.progress, end) - arrival(px, ubuf.cardSize, ubuf.seed)) * unit;   // pixels past the fire line

    float flick = pow(vnoise(px / 10.0 + ubuf.seed + vec2(0.0, ubuf.progress * 28.0)), 1.3);  // the fire flares and dulls
    float rag = vnoise(px / 5.0 + ubuf.seed * 3.1);

    // The paper: browns ahead of the fire, turns to charcoal behind it, and crumbles from the far edge.
    float scorch = smoothstep(-18.0, 0.0, behind);
    float charAmt = smoothstep(0.0, 10.0, behind);
    float flaky = 0.65 * vnoise(px / 4.2 + ubuf.seed * 4.0) + 0.35 * vnoise(px / 1.9 + ubuf.seed * 6.0);
    float ashy = smoothstep(8.0, 24.0, behind) * smoothstep(0.48, 0.95, flaky);             // greyer, and flakier, with age
    float edge = 30.0 + 14.0 * (rag - 0.5);
    float alive = 1.0 - smoothstep(edge - 12.0, edge + 4.0, behind);

    vec3 base = src.rgb;
    base = mix(base, base * vec3(0.55, 0.33, 0.18), scorch * (1.0 - charAmt));
    vec3 charcoal = mix(vec3(0.075, 0.058, 0.050), vec3(0.30, 0.28, 0.26), ashy * 0.85) * src.a;
    base = mix(base, charcoal, charAmt);
    float thin = alive * mix(1.0, 0.82, ashy);                                                // flaky bits are thin
    vec4 col = vec4(base * thin, src.a * thin);

    // The fire line: a thin white-gold core with orange and red beyond it, uneven along its length. A softer glow
    // runs ahead of it, over the paper that is about to catch.
    float line = behind >= 0.0 ? exp(-behind / 3.4) : 0.55 * exp(behind / 4.5);
    float heat = line * (0.30 + 0.70 * flick);
    vec3 glow = heatColour(heat * 1.15) * heat * 1.5;

    // The glowing cracks in the char, going dark as they cool.
    float net = cracks(px / 17.0 + ubuf.seed * 2.0);
    float crack = net * charAmt * exp(-behind / 6.5) * (0.35 + 0.65 * flick) * alive;
    glow += vec3(1.0, 0.27, 0.04) * crack * 1.3;

    col.rgb += glow * src.a * alive;
    col.a = max(col.a, min(1.0, max(glow.r, max(glow.g, glow.b)) * src.a * alive));
    col.rgb = min(col.rgb, vec3(col.a));                                                      // premultiplied: colour never exceeds alpha
    fragColor = col * ubuf.qt_Opacity;
}
