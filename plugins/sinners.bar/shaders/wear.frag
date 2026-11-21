#version 440

// Worn paint on the bar's lettering: the widgets' text and icons, drawn as they would be, with flakes of the paint gone.
// The flakes are a tileable mask (wood/wear.png, drawn by tools/make-bar-wood.py) stretched along the grain, so they break a
// letter up where it crosses the grain, as chipped paint does. The mask repeats every 512 x 36 logical px; offset says
// where in it each section starts, so two sections never wear alike.
//
// Output is premultiplied alpha, as the source is: the whole pixel, colour and alpha together, is scaled down.
// Rebuild with build-shaders.sh after editing.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float strength;    // 0-1: how much of a flake's paint is gone (1 takes it all)
    vec2 size;         // the item's size, in logical px
    vec2 offset;       // where in the mask this item starts, in logical px
} ubuf;

layout(binding = 1) uniform sampler2D source;
layout(binding = 2) uniform sampler2D wear;

void main() {
    vec4 c = texture(source, qt_TexCoord0);
    vec2 uv = fract((qt_TexCoord0 * ubuf.size + ubuf.offset) / vec2(512.0, 36.0));
    float w = texture(wear, uv).r;
    // The mask is rank-normalised, so about 1 pixel in 7 is past the lower threshold, and 1 in 20 is all the way worn.
    float worn = smoothstep(0.86, 0.95, w) * ubuf.strength;
    fragColor = c * (1.0 - worn) * ubuf.qt_Opacity;
}
