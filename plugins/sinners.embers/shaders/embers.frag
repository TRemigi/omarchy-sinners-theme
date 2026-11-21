#version 440

// Embers drifting up over the wallpaper, drawn as light on a transparent layer.
//
// Three depths. The far layer is many small, dim, sharp sparks; the middle layer is the main population; the
// near layer is a few large, out-of-focus ones that move faster, like sparks close to the camera. Each layer is
// a row of columns, and each column carries one ember per cycle: it is lofted from just below the screen, climbs
// at its own speed, and cools as it goes. Nothing is stored: where every ember is, and how hot, is a function of
// the clock, so there are no particles to update and a frame costs only the fifteen embers near each pixel.
//
// What makes it read as real:
//  * Heat. Each ember starts white-yellow and cools through orange and red to black, while it shrinks and
//    flickers; many burn out before they reach the top, so the embers thin out as they rise.
//  * One wind. Every ember is carried by the same slowly changing shear and gusts, so neighbours move together,
//    and each adds its own small flutter on top.
//  * Light, not paint. The cores are overexposed (tone-mapped), so a hot ember blooms toward white and a cool
//    one stays a dull red. Its halo is cooler than its core.
//  * A little motion blur along the path, and a soft halo that is wider on the near embers.
//
// The output is premultiplied alpha with alpha raised to cover the colour, so it is an ordinary translucent
// layer and needs no blend tricks from the compositor. Rebuild with build-shaders.sh after editing.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;        // seconds, accumulated by the service (already scaled by the speed setting)
    float intensity;   // overall brightness, 0-1
    float density;     // how many embers, 0-1.5
    float seed;        // random per session
    vec2 resolution;
} ubuf;

const float TAU = 6.2831853;

float hash31(vec3 p3) {
    p3 = fract(p3 * 0.1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}

float rnd(float key, float cycle, float n) { return hash31(vec3(key, cycle, n + ubuf.seed)); }

// The colour of burning charcoal at heat h (1 = just lofted, 0 = out): black, deep red, red, orange, gold, and
// a pale yellow-white above 1.
vec3 heatColour(float h) {
    vec3 c = mix(vec3(0.0), vec3(0.30, 0.020, 0.004), smoothstep(0.00, 0.12, h));
    c = mix(c, vec3(0.85, 0.120, 0.010), smoothstep(0.10, 0.35, h));
    c = mix(c, vec3(1.00, 0.420, 0.040), smoothstep(0.30, 0.60, h));
    c = mix(c, vec3(1.00, 0.780, 0.300), smoothstep(0.55, 0.90, h));
    c = mix(c, vec3(1.00, 0.880, 0.520), smoothstep(0.85, 1.15, h));
    return c;
}

// One depth layer, as linear light.
//   cols     columns across the screen's width: more, narrower columns are more, smaller embers
//   vmin..   climb speed, screen heights per second
//   rad      ember radius, screen heights
//   bright   peak brightness (the near layer is defocused, so its peak is low)
//   alive    chance that a column has an ember in a given cycle
//   shear    how far the wind leans the path sideways per screen height climbed
//   gust     how far the gusts push, screen heights
vec3 emberLayer(vec2 p, float aspect, float lid, float cols, float vmin, float vmax, float rad,
                float bright, float alive, float shear, float gust) {
    const float RISE = 1.25;                        // screen heights climbed in a full cycle
    const float REACH = 9.0;                        // the halo ends at this many radii; two columns each side hold it
    float t = ubuf.time;
    float colw = aspect / cols;

    // The air every ember in this layer shares. The pixel is moved into a frame in which paths are straight
    // and vertical, so an ember only has to be looked for in the columns near its own.
    float lean = shear * (1.0 + 0.35 * sin(t * 0.045 + lid * 2.1));
    float push = gust * (sin(t * 0.31 + p.y * 3.7 + lid * 5.0) + 0.6 * sin(t * 0.77 - p.y * 8.3 + lid));
    float x = p.x - lean * p.y - push;
    float i0 = floor(x / colw);

    vec3 light = vec3(0.0);
    for (int di = -2; di <= 2; di++) {
        float col = i0 + float(di);
        float key = col + lid * 997.0;

        float v = mix(vmin, vmax, rnd(key, 0.0, 1.0));       // this column's climb speed
        float period = RISE / v;
        float u = t / period + rnd(key, 0.0, 2.0);
        float cyc = mod(floor(u), 997.0);
        float s = fract(u);                                  // how far through the cycle

        if (rnd(key, cyc, 3.0) > alive * ubuf.density) continue;
        float end = mix(0.55, 1.0, rnd(key, cyc, 4.0));      // the cycle fraction at which it burns out
        float age = s / end;
        if (age >= 1.0) continue;

        // Where it is. Slightly quicker at first, as hot air is.
        float y = -0.05 + RISE * s * (1.0 + 0.25 * (1.0 - s)) + 0.05 * rnd(key, cyc, 5.0);
        // Size. Far above or below this pixel, an ember cannot reach it: skip the rest.
        float r = rad * mix(0.7, 1.5, rnd(key, cyc, 11.0)) * (0.5 + 0.5 * sqrt(1.0 - age));
        float smear = v * 0.02;                // the exposure: how far it travels while the shutter is open
        float dy = p.y - y;
        if (dy > REACH * r || dy < -(REACH * r + smear)) continue;

        float tau = s * period;
        float w1 = (0.10 + 0.22 * rnd(key, cyc, 6.0)) * TAU, w2 = (0.9 + 0.9 * rnd(key, cyc, 7.0)) * TAU;
        float flutter = (0.7 * sin(w1 * tau + TAU * rnd(key, cyc, 8.0)) + 0.3 * sin(w2 * tau + TAU * rnd(key, cyc, 9.0)))
                        * colw * 0.45 * (0.4 + 0.6 * s);
        float cx = (col + 0.5 + (rnd(key, cyc, 10.0) - 0.5) * 0.5) * colw + flutter;

        // Distance to the ember, measured on the real screen, so that it is round. (The straightened frame
        // above is only for finding it: measured there, every ember would be skewed by the wind.) Its path
        // is smeared by the exposure, along the lean.
        vec2 at = vec2(cx + lean * y + gust * (sin(t * 0.31 + y * 3.7 + lid * 5.0) + 0.6 * sin(t * 0.77 - y * 8.3 + lid)), y);
        vec2 heading = vec2(lean, 1.0);
        vec2 d = p - at;
        d -= heading * clamp(dot(d, heading) / dot(heading, heading), -smear, 0.0);
        float q = length(d) / r;
        if (q > REACH) continue;

        // Heat falls with age; the flicker is the ember being blown on and sheltered.
        float heat = pow(1.0 - age, 1.2);
        float flick = 0.62 + 0.23 * sin(TAU * (2.5 + 2.5 * rnd(key, cyc, 12.0)) * tau + TAU * rnd(key, cyc, 13.0))
                           + 0.15 * sin(TAU * (7.0 + 4.0 * rnd(key, cyc, 14.0)) * tau + TAU * rnd(key, cyc, 15.0));
        float fade = smoothstep(0.0, 0.02, s) * (1.0 - smoothstep(0.9, 1.0, age));
        float gain = bright * flick * fade * (0.25 + 2.2 * heat);

        float core = exp(-q * q * 1.6);
        float halo = 0.55 * exp(-q * 0.42) * (1.0 - smoothstep(5.0, REACH, q));
        light += gain * (heatColour(heat * 1.15) * core + heatColour(heat * 0.8) * halo * 0.6);
    }
    return light;
}

void main() {
    float aspect = ubuf.resolution.x / ubuf.resolution.y;
    vec2 p = vec2(qt_TexCoord0.x * aspect, 1.0 - qt_TexCoord0.y);   // y = 0 is the bottom, 1 the top

    vec3 light = vec3(0.0);
    light += emberLayer(p, aspect, 0.0, 90.0, 0.030, 0.050, 0.0017, 0.50, 0.80, 0.10, 0.012);
    light += emberLayer(p, aspect, 1.0, 44.0, 0.045, 0.075, 0.0034, 0.80, 0.75, 0.14, 0.020);
    light += emberLayer(p, aspect, 2.0, 12.0, 0.070, 0.110, 0.0110, 0.35, 0.70, 0.18, 0.035);

    vec3 c = 1.0 - exp(-light * 1.6 * ubuf.intensity);       // exposure: the cores overexpose toward white
    float a = max(c.r, max(c.g, c.b));                        // premultiplied: colour never exceeds alpha
    fragColor = vec4(c, a) * ubuf.qt_Opacity;
}
