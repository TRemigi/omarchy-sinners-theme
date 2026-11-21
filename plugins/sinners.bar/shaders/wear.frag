#version 440

// Chipped paint on the bar's lettering. This is drawn over a section's widgets, and what it draws is the board under them: a picture
// of the board (`source`), kept only in small flakes stretched along the grain. On bare board that is the board over itself, which
// changes nothing; over a letter it puts the board's own red back on top of the lettering, as a chip where the paint has worn
// off. Nothing here redraws the widgets, so their text and icons stay exactly as the shell draws them.
//
// It also lets the board through, a little, wherever the board is grooved (darker than the board just above and below it), which
// puts the wood's dark grain lines across a letter, as paint over wood shows them.
//
// The flakes are noise made here, not a picture: long along the grain (x), a pixel or two across it, in clusters. offset
// says where in the noise each board starts, so two boards never wear alike.
//
// Output is premultiplied alpha, as the source is: the whole pixel, colour and alpha together, is scaled by the flake.
// Rebuild with build-shaders.sh after editing.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float strength;    // 0-1: how much of a flake is the board showing again (1 is all of it)
    float grain;       // 0-1: how much of the wood's dark grooves show through the paint (0 is none)
    vec2 size;         // the board's size, in logical px
    vec2 offset;       // where in the noise this board starts, in logical px
} ubuf;

layout(binding = 1) uniform sampler2D source;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// Smooth value noise.
float vnoise(vec2 x) {
    vec2 i = floor(x), f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
               mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

float luma(vec3 c) {
    return dot(c, vec3(0.30, 0.59, 0.11));
}

void main() {
    vec2 p = qt_TexCoord0 * ubuf.size + ubuf.offset;                       // logical px
    vec4 board = texture(source, qt_TexCoord0);

    // Flakes: stretched along the grain, in two sizes, in clusters.
    float flake = 0.62 * vnoise(vec2(p.x / 9.0, p.y / 0.9)) + 0.38 * vnoise(vec2(p.x / 3.0 + 31.0, p.y / 0.7 + 7.0));
    float cluster = vnoise(vec2(p.x / 55.0 + 3.0, p.y / 5.0));
    // About 11% of the board is touched at all and 9% is flaked solid at strength 1 (measured on software GL; the preview
    // script prints it), so about 9% of the lettering is chipped.
    float worn = smoothstep(0.74, 0.84, flake * (0.55 + 0.9 * cluster)) * ubuf.strength;

    // Grooves: where the board is darker than the board a few pixels above and below it (the grain runs along x, so across
    // it is where grain lines, cracks and pits show up). Paint lies over wood and takes its grooves; so the board is let
    // through there, a little, and a letter gets the wood's dark lines across it while bare board shows no change.
    float dy = 1.0 / ubuf.size.y;                                          // one logical px, across the grain
    float around = 0.25 * (luma(texture(source, qt_TexCoord0 + vec2(0.0, 2.0 * dy)).rgb)
                         + luma(texture(source, qt_TexCoord0 - vec2(0.0, 2.0 * dy)).rgb)
                         + luma(texture(source, qt_TexCoord0 + vec2(0.0, 4.0 * dy)).rgb)
                         + luma(texture(source, qt_TexCoord0 - vec2(0.0, 4.0 * dy)).rgb));
    float groove = clamp((around - luma(board.rgb)) / 0.10, 0.0, 1.0) * ubuf.grain;

    // Only the board's own rows: its margin above and the shadow below are not paint.
    float rows = step(3.0 / 36.0, qt_TexCoord0.y) * step(qt_TexCoord0.y, 33.0 / 36.0);

    fragColor = board * (max(worn, groove) * rows) * ubuf.qt_Opacity;
}
