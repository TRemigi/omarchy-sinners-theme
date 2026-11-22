#!/usr/bin/env python3
"""Draws the boards of the two Sinners bars as transparent PNGs: "dark" (plugins/sinners.bar), charred cypress with some of its
oxblood paint left on it, and "light" (plugins/sinners.bar-light), the light warm-grey wood of the film's sign.

usage: make-bar-wood.py [--sun STRENGTH] [plugins-dir]        (default: this repo's plugins/)

--sun backlights the dark bar's boards, as if by the low sun in the wallpaper behind them (see SUN). The default is 0.2; 0 is off.

Needs numpy, scipy and Pillow, which Omarchy does not install. In a throwaway virtualenv:

    python -m venv /tmp/wood && /tmp/wood/bin/pip install numpy scipy pillow
    /tmp/wood/bin/python tools/make-bar-wood.py

The PNGs are committed, so installing the bar needs none of this; run it only to change how the boards look.
It is deterministic: the same code writes the same files.

Original work: the wood, paint and nails are procedural (tools/woodlib.py). No photograph or film frame is sampled or
traced. See "A bar of boards" in the README.

It also draws the painted squares behind the shown workspace (plugins/sinners.workspaces/): square-filled.png and
square-outline.png, a patch and a brushed outline of paint in the theme's cream, for the dark bar; and square-red.png, a patch in
the red of the sign's lettering, for the light bar. 20 x 24 logical px.

Each board is three files, because a board's length depends on the widgets on it:
  <name>-body.png   a long strip of wood and paint, cropped by the bar to the board's length
  <name>-lcap.png   the left end: ragged saw cut, end grain, two nails, fading into the body
  <name>-rcap.png   the right end, the same turned round
All are drawn at 2x. The bar is SURFACE logical px tall: TOP of margin, a board BOARD_H tall, and the rest is the
board's shadow on the wallpaper, drawn into the image because a layer surface cannot draw outside itself.
"""
import os, sys, tomllib
import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter, gaussian_filter1d

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from woodlib import SS, smooth, anis, make_wood, paint, nail, shade, lut, DARK, BROWN

SURFACE, TOP, BOARD_H = 36, 3, 30          # logical px; must match Bar.qml's stripSize and WoodBoard.qml
CAP_W = 28                                  # logical px of end cap, the last 16 of which fade into the body
END_AT = 3                                  # where the sawn end sits in a cap, logical px from the image edge
PAINT = (0.30, 0.075, 0.055)                # oxblood, before wear
PAINT_LEFT = 0.0                           # how much of a board still has its paint: the rest has weathered away to the wood


def theme_colour(key):
    """A colour from the theme's colors.toml, as floats 0..1, so what is drawn here follows the theme."""
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "colors.toml")
    with open(path, "rb") as f:
        h = tomllib.load(f)[key].lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


CREAM = theme_colour("foreground")          # the shown workspace's square: the theme's cream, the same as the lettering (not the brighter title cream)
SQ_W, SQ_H = 20, 24                         # logical px; must match plugins/sinners.workspaces' patch
BOARDS = {"left": (1000, 101), "center": (1000, 202), "right": (700, 303)}   # name: (body width logical, seed)
# A board's own look, over the shared one. tone scales its brightness. weather (0 to 1) is how weathered it is: fewer cracks and
# a smoother surface below 1. The clock's board is calmer than the others, so its decorative lettering reads, and it is lighter for the same
# reason; the left and right boards are lifted to the same brightness (tone 1.70 puts their median luminance, 0.13 at tone 1, on the clock
# board's 0.226) but keep their full weathering.
LOOK = {"left": dict(tone=1.70), "right": dict(tone=1.70), "center": dict(tone=1.30, weather=0.35)}
DEFAULT_LOOK = dict(tone=1.0, weather=1.0)

# The sign's wood: five tones, the 5th, 25th, 50th, 75th and 95th luminance percentiles of the wood in the film's Club Juke sign. Only these
# colours were taken from it (see README), not its picture.
SIGN_WOOD = lut([(q, tuple(c / 255 for c in rgb)) for q, rgb in
                 [(0.05, (106, 85, 72)), (0.25, (149, 127, 113)), (0.50, (173, 154, 139)), (0.75, (192, 174, 160)), (0.95, (211, 195, 181))]])
SIGN_RED = (188 / 255, 54 / 255, 46 / 255)  # the red of the sign's lettering, #BC362E: the light bar's shown-workspace square

# The sun is low in the middle of the wallpaper and the bar is at the top of the screen, so the sun is behind the boards and below them. A backlit
# board's face is in shadow; the light escapes round its edges and through its gaps. So: a bright warm rim along the lower edge and the sawn ends,
# light glowing through the cracks, a little light wrapping round the lower half of the face, and, in place of the drop shadow, a warm glow
# round the silhouette. k: how much of the strength reaches the board (the clock's, straight above the sun, the most). end_l and end_r: how much
# rim the board's left and right ends have, which is more on the end that faces the sun. SUN_STRENGTH (--sun) is the default 0.2; 0 is off.
SUN_RGB = theme_colour("accent")            # the sun's orange, #FB7407
SUN_STRENGTH = 0.2
SUN = {"left": dict(k=0.8, end_l=0.3, end_r=1.0), "center": dict(k=1.0, end_l=0.7, end_r=0.7), "right": dict(k=0.8, end_l=1.0, end_r=0.3)}


def sun_for(name, style):
    """The sun's light on a board, or None when it is off or the style has none."""
    if SUN_STRENGTH <= 0 or not style.get("sunlit"):
        return None
    return dict(glow=SUN_STRENGTH * SUN[name]["k"], end_l=SUN[name]["end_l"], end_r=SUN[name]["end_r"])


# One look per bar. paint: whether any oxblood paint is left on the wood. graded: whether the sun-warming grade is applied (the sign's own
# colours are not graded). relief: how strongly the grain and cracks are lit. cracks: board length per crack, in px, at weather 1.
STYLES = {
    "dark": dict(plugin="sinners.bar", look=LOOK, paint=True, graded=True, relief=0.9, cracks=900, lift=0.05, sunlit=True),
    # tone: each board's mean colour measured against the sign's wood (168, 148, 134); the left and right boards carry more cracks and
    # relief, which darken them, so they are lifted
    "light": dict(plugin="sinners.bar-light", look={"left": dict(tone=1.20), "right": dict(tone=1.20), "center": dict(tone=1.04, weather=0.35)},
                  paint=False, graded=False, relief=0.65,
                  cracks=1200, lift=0.0),
}

H = SURFACE * SS
TOP_PX, BH = TOP * SS, BOARD_H * SS


def wood_canvas(rng, w, ragged_end=False, weather=1.0, style=STYLES["dark"]):
    """The board's rows only (BH x w): charred cypress with some of its oxblood paint left on it, shaded, as float RGB, plus the end
    profile if any. The paint is in worn patches, stretched along the grain, that cover PAINT_LEFT of the board."""
    # The slow swings of tone (blotch) are for a long board. On a short piece, such as an end cap, they are one random offset, so
    # they are damped there; the cap is also scaled to its body's tone (see cap()).
    v, hg, cr = make_wood(BH, w, rng, ring=(6.0, 12.0), lift=style["lift"], knots=int(rng.random() < 0.4),
                          crack_rate=weather / style["cracks"], crack_y="edges", blotch=1.0 if w > 400 else 0.3)
    if style["paint"]:
        rgb = 0.55 * BROWN(v - 0.04) + 0.45 * DARK(v)   # the wood: dark, weathered, a little warm
    else:
        rgb = SIGN_WOOD(np.clip(0.5 + (v - 0.5) * 2.2, 0, 1))      # the sign's wood: v is spread across its own tonal range
    Yd = np.arange(BH, dtype=np.float32)[:, None]
    vedge = np.minimum(Yd, BH - 1 - Yd)               # distance from the top or bottom edge
    hg = hg - 1.8 * smooth(3.0, 0.0, vedge)
    rgb = rgb * (1 - 0.35 * smooth(2.5, 0.0, vedge))[..., None]
    worn = smooth(0, 4, vedge) * np.ones((1, w), np.float32)
    xl = None
    if ragged_end:                                      # sawn end on the left, ragged by a pixel or two
        xl = (END_AT * SS + 1.6 * gaussian_filter1d(rng.standard_normal(BH).astype(np.float32), 2.0) / 0.45)[:, None]
        X = np.arange(w, dtype=np.float32)[None, :]
        d = X - xl
        grain_end = smooth(9.0, 0.0, d)                 # end grain: darker, and the paint is thin there
        rgb = rgb * (1 - 0.55 * grain_end)[..., None]
        hg = hg - 1.6 * grain_end
        worn = worn * smooth(0, 7, d)
    if not style["paint"]:
        return rgb, hg, xl, cr
    # the same wood with all its paint on it, and then the paint kept only where the patches say
    rgb_p, hg_p = rgb.copy(), hg.copy()
    paint(rgb_p, hg_p, np.clip(worn * 1.4, 0, 1), PAINT, rng, v, block=smooth(0.55, 0.95, cr), wear=1.0, opacity=0.92, wobble=1.0)
    n = 0.6 * anis(rng, BH, w, 120, 8) + 0.4 * anis(rng, BH, w, 28, 2)
    ranks = np.empty(n.size, np.float32)
    ranks[np.argsort(n, axis=None)] = np.linspace(0, 1, n.size, dtype=np.float32)       # 0..1, evenly spread, so PAINT_LEFT is exact
    t = smooth(1 - PAINT_LEFT - 0.12, 1 - PAINT_LEFT + 0.12, ranks.reshape(n.shape))
    if PAINT_LEFT <= 0:                                 # the mask's soft edge would leave a faint tint at the ends of the range
        t = np.zeros_like(t)
    elif PAINT_LEFT >= 1:
        t = np.ones_like(t)
    rgb = rgb * (1 - t[..., None]) + rgb_p * t[..., None]
    hg = hg * (1 - t) + hg_p * t
    return rgb, hg, xl, cr


def _backlight(sun, cr, w, xl=None, end=0.0):
    """How much of the sun's light reaches the board's face, as an alpha map (BH x w) for lit() to screen in: a rim a few pixels deep along the
    lower edge, a little light wrapping round the lower half of the face, light through the cracks (with a small bloom), and, on a cap, a rim
    along the sawn end (end is how much of it: more on the end that faces the sun)."""
    Y = np.arange(BH, dtype=np.float32)[:, None]
    bottom = smooth(6.0, 0.0, BH - 1 - Y)
    wrap = 0.12 * smooth(0.40, 1.0, Y / (BH - 1)) ** 2
    crack = np.clip(0.9 * cr + 0.35 * gaussian_filter(cr, 1.2), 0, 1)
    a = 0.85 * bottom + wrap + crack
    if xl is not None and end > 0:
        X = np.arange(w, dtype=np.float32)[None, :]
        a = a + end * 0.8 * smooth(7.0, 0.0, X - xl)
    return np.clip(a * sun["glow"], 0, 1)


def lit(rgb, hg, tone=1.0, weather=1.0, style=STYLES["dark"], sun_a=None):
    """Light it from above and left, as the mockups were, and warm it toward the sun (not the light bar's: it keeps the sign's colours). tone and
    weather: see LOOK. sun_a, if given, is the sun's light from behind (see _backlight): a screen blend, so it adds light and warms it."""
    out = shade(rgb, hg, strength=style["relief"] * (0.55 + 0.45 * weather))
    if not style["graded"]:
        out = np.clip(out * tone, 0, 1)
    else:
        lum = (out * np.array([0.30, 0.59, 0.11], np.float32)).sum(-1, keepdims=True)
        out = lum + (out - lum) * 0.8
        out = np.clip(out * np.array([1.0, 0.93, 0.84], np.float32) * 0.95 * tone, 0, 1)
    if sun_a is not None:
        a = sun_a[..., None] * np.asarray(SUN_RGB, np.float32)
        out = np.clip(1 - (1 - out) * (1 - a), 0, 1)
    return out


def shadow_rows(w):
    """Alpha of the board's shadow under it: a tight dark line, then a soft fall-off, across width w."""
    n = H - (TOP_PX + BH)
    t = np.arange(n, dtype=np.float32) / n
    a = 0.50 * (1 - t) ** 2 + 0.22 * np.exp(-t * 7)
    return np.repeat(np.clip(a, 0, 0.62)[:, None], w, axis=1)


def spill_rows(w, glow):
    """Alpha of the warm glow round a backlit board's lower edge, which takes the place of its shadow: brightest at the edge, fading downward."""
    n = H - (TOP_PX + BH)
    t = np.arange(n, dtype=np.float32) / n
    a = glow * 1.1 * (1 - t) ** 1.6
    return np.repeat(np.clip(a, 0, 0.6)[:, None], w, axis=1)


def assemble(rgb, board_alpha, shadow_alpha, shadow_rgb=(0.0, 0.0, 0.0)):
    """Place the board's rows into the full-height strip, with its shadow (black) or its glow (the sun's colour) beneath. Returns RGBA uint8."""
    w = rgb.shape[1]
    out = np.zeros((H, w, 4), np.float32)
    out[TOP_PX:TOP_PX + BH, :, :3] = rgb
    out[TOP_PX:TOP_PX + BH, :, 3] = board_alpha
    out[TOP_PX + BH:, :, :3] = np.asarray(shadow_rgb, np.float32)
    out[TOP_PX + BH:, :, 3] = shadow_alpha
    return (np.clip(out, 0, 1) * 255 + 0.5).astype(np.uint8)


def body(name, wlog, seed, style=STYLES["dark"]):
    rng = np.random.default_rng(seed)
    w = wlog * SS
    look = {**DEFAULT_LOOK, **style["look"].get(name, {})}
    sun = sun_for(name, style)
    rgb, hg, _, cr = wood_canvas(rng, w, weather=look["weather"], style=style)
    rgb = lit(rgb, hg, look["tone"], look["weather"], style, _backlight(sun, cr, w) if sun else None)
    if sun:
        return assemble(rgb, np.ones((BH, w), np.float32), spill_rows(w, sun["glow"]), SUN_RGB)
    return assemble(rgb, np.ones((BH, w), np.float32), shadow_rows(w))


def luma(rgb):
    return (rgb * np.array([0.2126, 0.7152, 0.0722], np.float32)).sum(-1)


def cap(name, seed, flip, target, style=STYLES["dark"]):
    """An end cap. target is the median luminance of the board's body: the cap is scaled to match it, because it is drawn as a
    separate small piece of wood whose overall tone is a random draw, and one drew a right cap a fifth as bright as its board."""
    rng = np.random.default_rng(seed)
    w = CAP_W * SS
    look = {**DEFAULT_LOOK, **style["look"].get(name, {})}
    sun = sun_for(name, style)
    rgb, hg, xl, cr = wood_canvas(rng, w, ragged_end=True, weather=look["weather"], style=style)
    X = np.arange(w, dtype=np.float32)[None, :]
    for ny in (8 * SS, BH - 8 * SS):                    # a pair of nails, 11 logical px in from the end
        nail(rgb, hg, END_AT * SS + 11 * SS + rng.normal(0, 1.0), ny + rng.normal(0, 1.0), rng, r=1.9 * SS)
    sun_a = _backlight(sun, cr, w, xl, sun["end_r" if flip else "end_l"]) if sun else None       # the cap is drawn with its end on the left, then flipped
    rgb = lit(rgb, hg, look["tone"], look["weather"], style, sun_a)
    # match the body's tone, measured on the stretch that is opaque and clear of the sawn end's darkening and of the nails
    here = np.median(luma(rgb[:, 14:26]))                # columns, in this cap's 2x pixels: 7 to 13 logical px from its edge
    rgb = np.clip(rgb * float(np.clip(target / max(here, 1e-4), 0.5, 6.0)), 0, 1)
    inner = smooth(w, w - 16 * SS, X) * np.ones((BH, 1), np.float32)         # fades into the body underneath
    board_alpha = np.clip(X - xl + 0.5, 0, 1) * inner
    below = spill_rows(w, sun["glow"]) if sun else shadow_rows(w)
    sh = below * np.clip((X - END_AT * SS) / 6.0, 0, 1) * smooth(w, w - 16 * SS, X)
    img = assemble(rgb, board_alpha, sh, SUN_RGB if sun else (0.0, 0.0, 0.0))
    return img[:, ::-1] if flip else img


def _wobble(rng, n, amp, sigma):
    """A smooth 1-D wobble of n samples, about +-amp px."""
    w = gaussian_filter1d(rng.standard_normal(n).astype(np.float32), sigma)
    return amp * w / (w.std() + 1e-6)


def _streaks(rng, h, w, along_x):
    """Brush streaks, -1..1: noise stretched along the stroke, fine bristle lines over a broader swell."""
    sx, sy = ((16.0, 0.9), (40.0, 2.6)) if along_x else ((0.9, 16.0), (2.6, 40.0))
    n = 0.6 * gaussian_filter(rng.standard_normal((h, w)).astype(np.float32), sx[::-1], mode="reflect")
    n = n / (n.std() + 1e-6) + 0.5 * gaussian_filter(rng.standard_normal((h, w)).astype(np.float32), sy[::-1], mode="reflect") / 0.2
    n = n / (n.std() + 1e-6)
    return np.clip(n / 2.0, -1, 1)


def _rgba(alpha, streak, colour=None):
    col = np.asarray(CREAM if colour is None else colour, np.float32) * (0.975 + 0.04 * streak)[..., None]
    out = np.concatenate([np.clip(col, 0, 1), alpha[..., None]], axis=-1)
    return (np.clip(out, 0, 1) * 255 + 0.5).astype(np.uint8)


def square_filled(colour=None):
    """A patch of cream paint, brushed on: its sides a little uneven where the brush ended, a few thin streaks showing the wood."""
    rng = np.random.default_rng(606)
    w, h = SQ_W * SS, SQ_H * SS
    Y, X = np.mgrid[0:h, 0:w].astype(np.float32)
    left = 1.5 * SS + _wobble(rng, h, 0.28 * SS, 4) + _wobble(rng, h, 0.22 * SS, 0.8)    # the strokes' ends: a little uneven
    right = w - 1.5 * SS + _wobble(rng, h, 0.28 * SS, 4) + _wobble(rng, h, 0.22 * SS, 0.8)
    top = 1.5 * SS + _wobble(rng, w, 0.22 * SS, 5)                                        # along a stroke: smoother
    bottom = h - 1.5 * SS + _wobble(rng, w, 0.22 * SS, 5)
    cov = (np.clip(X - left[:, None] + 0.5, 0, 1) * np.clip(right[:, None] - X + 0.5, 0, 1)
           * np.clip(Y - top[None, :] + 0.5, 0, 1) * np.clip(bottom[None, :] - Y + 0.5, 0, 1))
    streak = _streaks(rng, h, w, True)
    thick = np.clip(0.91 + 0.13 * streak, 0.74, 1.0)                                       # a few thin streaks let the wood through
    return _rgba(cov * thick, streak, colour)


def square_outline():
    """Cream paint in four brush strokes round the number: each wobbles a little, and they overshoot at the corners."""
    from PIL import ImageDraw
    rng = np.random.default_rng(707)
    K = 4                                                       # drawn at 4x and averaged down, for smooth edges
    w, h = SQ_W * SS, SQ_H * SS
    # (start, end) in logical px, how wide, and whether it runs along x
    strokes = [((2.0, 4.0), (18.0, 3.7), 3.0, True),            # top, left to right
               ((16.5, 1.8), (17.1, 22.0), 2.9, False),         # right, downward
               ((18.1, 20.2), (1.8, 20.5), 3.1, True),          # bottom, right to left
               ((3.3, 22.2), (2.9, 1.6), 2.9, False)]           # left, upward
    mask = np.zeros((h, w), np.float32)
    for (x0, y0), (x1, y1), width, along_x in strokes:
        n = 60
        t = np.linspace(0, 1, n)
        xs, ys = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
        perp = _wobble(rng, n, 0.18, 5)
        if along_x:
            ys = ys + perp
        else:
            xs = xs + perp
        wd = width * (1 + 0.10 * _wobble(rng, n, 1.0, 6)) * (0.88 + 0.22 * np.sin(np.pi * np.clip(t, 0.02, 0.98)) ** 0.5)
        im = Image.new("L", (w * K, h * K), 0)
        # one polygon between the stroke's two edges, so it has no notches where short pieces would meet
        if along_x:
            edge_a, edge_b = list(zip(xs, ys - wd / 2)), list(zip(xs, ys + wd / 2))
        else:
            edge_a, edge_b = list(zip(xs - wd / 2, ys)), list(zip(xs + wd / 2, ys))
        poly = [(x * SS * K, y * SS * K) for x, y in edge_a + edge_b[::-1]]
        ImageDraw.Draw(im).polygon(poly, fill=255)
        stroke = np.asarray(im.resize((w, h), Image.BOX), np.float32) / 255
        streak_s = _streaks(rng, h, w, along_x)
        stroke = stroke * np.clip(0.93 + 0.14 * streak_s, 0.75, 1.0)
        mask = 1 - (1 - mask) * (1 - stroke)
    return _rgba(mask, _streaks(rng, h, w, True))


def main():
    global SUN_STRENGTH
    args = sys.argv[1:]
    if "--sun" in args:
        i = args.index("--sun")
        SUN_STRENGTH = float(args[i + 1])
        del args[i:i + 2]
    plugins = args[0] if args else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "plugins")
    for style_name, style in STYLES.items():
        out = os.path.join(plugins, style["plugin"], "wood")
        os.makedirs(out, exist_ok=True)
        for name, (wlog, seed) in BOARDS.items():
            b = body(name, wlog, seed, style)
            target = float(np.median(luma(b[TOP_PX:TOP_PX + BH, :, :3].astype(np.float32) / 255)))
            Image.fromarray(b).save(os.path.join(out, f"{name}-body.png"), optimize=True)
            Image.fromarray(cap(name, seed + 1, False, target, style)).save(os.path.join(out, f"{name}-lcap.png"), optimize=True)
            Image.fromarray(cap(name, seed + 2, True, target, style)).save(os.path.join(out, f"{name}-rcap.png"), optimize=True)
            print("wrote", style_name, name)
    wsdir = os.path.join(plugins, "sinners.workspaces")
    os.makedirs(wsdir, exist_ok=True)
    Image.fromarray(square_filled()).save(os.path.join(wsdir, "square-filled.png"), optimize=True)
    Image.fromarray(square_outline()).save(os.path.join(wsdir, "square-outline.png"), optimize=True)
    Image.fromarray(square_filled(SIGN_RED)).save(os.path.join(wsdir, "square-red.png"), optimize=True)
    print("wrote squares")


main()
