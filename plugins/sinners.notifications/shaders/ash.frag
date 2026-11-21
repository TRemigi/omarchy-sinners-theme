#version 440

// What happens around a burning card, drawn in a window larger than the card and over it:
//  * the light the fire throws on what is near it (the card, and the wall behind it),
//  * flames, short and uneven, licking up from the fire line over the paper that is about to catch,
//  * a faint smoke that rises from the burnt part and thins out above the card,
//  * ash: flakes of every size and brightness, tumbling as they rise on the heat, glowing at first; and rarer sparks,
//    quick and bright, that go out fast.
// None of it is stored. Each is a function of the clock and of the fire's arrival field, which is shared with
// burn.frag (the SHARED block, checked identical by build-shaders.sh), so ash and smoke come only from where the card
// has really burnt, and the light and flames are where the fire really is. A flake's source cell sends it up; for a
// pixel, the cells that could have sent a flake to it are the ones just below it and to its sides.
//
// The output is premultiplied alpha.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float t;           // seconds since the card caught light
    float dur;         // seconds the fire takes to cross the card
    float tail;        // seconds after that, for the last of the smoke and ash
    float seed;
    vec2 cardSize;     // the card, in pixels
    vec2 origin;       // where the card's top-left corner is within this item, in pixels
    vec2 overlay;      // this item's size, in pixels
} ubuf;

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

const float CELL = 9.0;      // pixels; a flake's source cell
const float DENSITY = 0.26;  // the share of cells that send a flake

// Draws (rgb premultiplied by a, a) over the pixel so far.
void over(inout vec4 dst, vec3 rgb, float a) {
    dst.rgb = rgb + dst.rgb * (1.0 - a);
    dst.a = a + dst.a * (1.0 - a);
}

void main() {
    vec2 c = qt_TexCoord0 * ubuf.overlay - ubuf.origin;          // this pixel, in card space (y down)
    vec2 size = ubuf.cardSize;
    float unit = unitPx(size);
    float prog = clamp(ubuf.t / ubuf.dur, 0.0, 1.0);
    float end = frontEnd(size, ubuf.seed);
    float front = frontAt(prog, end);
    float outside = length(c - clamp(c, vec2(0.0), size));        // how far this pixel is beyond the card
    float behind = (front - arrival(c, size, ubuf.seed)) * unit;  // pixels past the fire line (negative: ahead of it)
    vec4 acc = vec4(0.0);

    // ---- the light of the fire on what is near it
    float soft = behind;
    if (outside > 3.0) {
        soft = 0.0;
        for (int k = -2; k <= 2; k++)
            soft += 0.2 * (front - arrival(c + vec2(float(k) * 14.0, 0.0), size, ubuf.seed)) * unit;
    }
    float hot = soft >= 0.0 ? exp(-soft / 9.0) : exp(soft / 14.0);
    float lit = hot * exp(-outside / 22.0) * smoothstep(0.0, 0.05, prog) * (1.0 - smoothstep(0.92, 1.0, prog));
    over(acc, vec3(1.0, 0.36, 0.07) * lit * 0.20, lit * 0.08);

    // ---- smoke, from the burnt part, rising and thinning, gone with the tail
    vec2 c0 = c + vec2(10.0 * sin(c.y / 23.0 + ubuf.seed), 36.0);
    vec2 in0 = clamp(c0, vec2(0.0), size);
    float inside0 = 1.0 - smoothstep(0.0, 12.0, length(c0 - in0));
    float burnt0 = smoothstep(6.0, 26.0, (front - arrival(c0, size, ubuf.seed)) * unit) * inside0;
    vec2 pl = vec2(c.x / 34.0, (c.y + ubuf.t * 30.0) / 46.0) + ubuf.seed;
    float plume = 0.6 * vnoise(pl) + 0.4 * vnoise(pl * 2.1 + 3.0);
    float smoke = burnt0 * smoothstep(0.38, 0.78, plume) * 0.22
                  * (1.0 - smoothstep(ubuf.dur, ubuf.dur + ubuf.tail, ubuf.t)) * exp(-max(0.0, -c.y) / 55.0);
    over(acc, vec3(0.19, 0.16, 0.14) * smoke, smoke);

    // ---- flames: tongues rising off the fire line, over the paper just ahead of it
    float ahead = -behind;                                        // pixels ahead of the line
    float streak = 0.65 * vnoise(vec2(c.x / 6.0, (c.y + ubuf.t * 80.0) / 15.0) + ubuf.seed * 3.3)
                 + 0.35 * vnoise(vec2(c.x / 3.1, (c.y + ubuf.t * 130.0) / 7.0) + ubuf.seed);
    float reach = mix(7.0, 20.0, streak);
    float flame = smoothstep(0.40, 0.80, streak) * (1.0 - smoothstep(0.0, reach, ahead)) * step(-3.0, ahead)
                  * exp(-outside / 10.0) * (1.0 - smoothstep(size.y, size.y + 3.0, c.y))            // none below the card
                  * smoothstep(0.0, 0.06, prog) * (1.0 - smoothstep(0.90, 0.99, prog));
    vec3 fcol = mix(vec3(1.0, 0.78, 0.30), vec3(1.0, 0.30, 0.05), smoothstep(0.0, reach, ahead));
    over(acc, fcol * flame * 0.50, flame * 0.42);

    // ---- flakes of ash, and sparks
    for (int iy = -6; iy <= 10; iy++) {
        for (int ix = -4; ix <= 3; ix++) {
            vec2 cell = floor(c / CELL) + vec2(float(ix), float(iy));
            if (hash21(cell + ubuf.seed * 13.0) > DENSITY) continue;

            vec2 s = (cell + vec2(hash21(cell + 1.7 + ubuf.seed), hash21(cell + 9.1 + ubuf.seed))) * CELL;
            if (s.x < 0.0 || s.x > size.x || s.y < 0.0 || s.y > size.y) continue;

            bool spark = hash21(cell + 8.8) < 0.18;
            // Ash lifts off where the char crumbles; sparks fly off the fire line.
            float lag = spark ? 3.0 : 24.0;
            float born = ((arrival(s, size, ubuf.seed) + lag / unit - FRONT_START) / (end - FRONT_START)) * ubuf.dur;
            float age = ubuf.t - born;
            if (age < 0.0) continue;
            float life = spark ? mix(0.35, 0.7, hash21(cell + 3.3)) : mix(0.9, 1.6, hash21(cell + 3.3));
            if (age > life) continue;

            float v = spark ? mix(60.0, 120.0, hash21(cell + 5.5)) : mix(22.0, 55.0, hash21(cell + 5.5));
            float rise = v * age * (1.0 - 0.25 * age / life);
            // A big piece is too heavy for the heat to carry: it falls, a little faster as it goes.
            bool heavy = !spark && hash21(cell + 6.6) > 0.62 && hash21(cell + 15.5) < 0.6;
            if (heavy) rise = -mix(10.0, 26.0, hash21(cell + 16.6)) * age * (1.0 + 0.5 * age);
            float wind = mix(-6.0, 14.0, hash21(cell + 7.7)) * age;
            float sway = (spark ? 3.0 : 7.0) * sin(age * mix(3.0, 7.0, hash21(cell + 2.2)) + hash21(cell + 4.4) * 6.28);
            vec2 pos = s + vec2(wind + sway, -rise);

            vec2 d = c - pos;
            float rad, shade;
            vec3 colour;
            float a;
            if (spark) {
                rad = mix(0.8, 1.3, hash21(cell + 6.6));
                float e = length(vec2(d.x, d.y / 3.0)) / rad;                      // a short streak up its path
                shade = 1.0 - smoothstep(0.5, 1.0, e);
                float cool = smoothstep(0.0, life, age);
                colour = mix(vec3(1.0, 0.72, 0.25), vec3(0.75, 0.18, 0.04), cool);
                a = shade * (1.0 - cool);
                if (a <= 0.0) continue;
                over(acc, colour * a, a * 0.6);
            } else {
                rad = 0.9 * pow(4.6, hash21(cell + 6.6));                           // 0.9 to 4.1, mostly small
                float aspect = mix(1.0, 2.6, hash21(cell + 9.9));
                float th = hash21(cell + 11.1) * 6.28 + age * mix(-3.0, 3.0, hash21(cell + 12.2));
                vec2 r = vec2(cos(th) * d.x + sin(th) * d.y, -sin(th) * d.x + cos(th) * d.y);
                float e = length(vec2(r.x / aspect, r.y)) / rad;
                e *= 1.0 + 0.55 * (vnoise(r / rad * 1.6 + hash21(cell + 17.7) * 40.0) - 0.5);   // ragged, not an ellipse
                shade = 1.0 - smoothstep(0.55, 1.0, e);
                if (shade <= 0.0) continue;
                float g = mix(0.20, 0.70, hash21(cell + 13.3));
                vec3 ash = vec3(g) * vec3(1.0, 0.95, 0.90);
                colour = mix(vec3(1.0, 0.45, 0.10), ash, smoothstep(0.0, 0.35, age));       // glowing, then grey
                a = shade * mix(0.55, 0.9, hash21(cell + 14.4)) * (1.0 - smoothstep(0.55 * life, life, age));
                over(acc, colour * a, a);
            }
        }
    }

    acc.rgb = min(acc.rgb, vec3(acc.a));                          // premultiplied: colour never exceeds alpha
    fragColor = acc * ubuf.qt_Opacity;
}
