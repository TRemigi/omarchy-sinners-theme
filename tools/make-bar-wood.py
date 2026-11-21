#!/usr/bin/env python3
"""Draws the boards of the Sinners bar: charred cypress with some of its oxblood paint left on it, as transparent PNGs.

usage: make-bar-wood.py [outdir]        (default: plugins/sinners.bar/wood)

Needs numpy, scipy and Pillow, which Omarchy does not install. In a throwaway virtualenv:

    python -m venv /tmp/wood && /tmp/wood/bin/pip install numpy scipy pillow
    /tmp/wood/bin/python tools/make-bar-wood.py

The PNGs are committed, so installing the bar needs none of this; run it only to change how the boards look.
It is deterministic: the same code writes the same files.

Original work: the wood, paint and nails are procedural (tools/woodlib.py). No photograph or film frame is sampled or
traced. See "A bar of boards" in the README.

It also draws the painted cream square behind the shown workspace (plugins/sinners.workspaces/square-filled.png and
square-outline.png): a patch and a brushed outline of paint in the theme's cream, 20 x 24 logical px.

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
from woodlib import SS, smooth, anis, make_wood, paint, nail, shade, DARK, BROWN

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

H = SURFACE * SS
TOP_PX, BH = TOP * SS, BOARD_H * SS


def wood_canvas(rng, w, ragged_end=False):
    """The board's rows only (BH x w): charred cypress with some of its oxblood paint left on it, shaded, as float RGB, plus the end
    profile if any. The paint is in worn patches, stretched along the grain, that cover PAINT_LEFT of the board."""
    v, hg, cr = make_wood(BH, w, rng, ring=(6.0, 12.0), lift=0.05, knots=int(rng.random() < 0.4),
                          crack_rate=1 / 900, crack_y="edges")
    rgb = 0.55 * BROWN(v - 0.04) + 0.45 * DARK(v)       # the wood: dark, weathered, a little warm
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
    return rgb, hg, xl


def lit(rgb, hg):
    """Light it from above and left, as the mockups were, and warm it toward the sun."""
    out = shade(rgb, hg, strength=0.9)
    lum = (out * np.array([0.30, 0.59, 0.11], np.float32)).sum(-1, keepdims=True)
    out = lum + (out - lum) * 0.8
    return np.clip(out * np.array([1.0, 0.93, 0.84], np.float32) * 0.95, 0, 1)


def shadow_rows(w):
    """Alpha of the board's shadow under it: a tight dark line, then a soft fall-off, across width w."""
    n = H - (TOP_PX + BH)
    t = np.arange(n, dtype=np.float32) / n
    a = 0.50 * (1 - t) ** 2 + 0.22 * np.exp(-t * 7)
    return np.repeat(np.clip(a, 0, 0.62)[:, None], w, axis=1)


def assemble(rgb, board_alpha, shadow_alpha):
    """Place the board's rows into the full-height strip, with its shadow beneath. Returns RGBA uint8."""
    w = rgb.shape[1]
    out = np.zeros((H, w, 4), np.float32)
    out[TOP_PX:TOP_PX + BH, :, :3] = rgb
    out[TOP_PX:TOP_PX + BH, :, 3] = board_alpha
    out[TOP_PX + BH:, :, 3] = shadow_alpha
    return (np.clip(out, 0, 1) * 255 + 0.5).astype(np.uint8)


def body(name, wlog, seed):
    rng = np.random.default_rng(seed)
    w = wlog * SS
    rgb, hg, _ = wood_canvas(rng, w)
    rgb = lit(rgb, hg)
    return assemble(rgb, np.ones((BH, w), np.float32), shadow_rows(w))


def cap(name, seed, flip):
    rng = np.random.default_rng(seed)
    w = CAP_W * SS
    rgb, hg, xl = wood_canvas(rng, w, ragged_end=True)
    X = np.arange(w, dtype=np.float32)[None, :]
    for ny in (8 * SS, BH - 8 * SS):                    # a pair of nails, 11 logical px in from the end
        nail(rgb, hg, END_AT * SS + 11 * SS + rng.normal(0, 1.0), ny + rng.normal(0, 1.0), rng, r=1.9 * SS)
    rgb = lit(rgb, hg)
    inner = smooth(w, w - 16 * SS, X) * np.ones((BH, 1), np.float32)         # fades into the body underneath
    board_alpha = np.clip(X - xl + 0.5, 0, 1) * inner
    sh = shadow_rows(w) * np.clip((X - END_AT * SS) / 6.0, 0, 1) * smooth(w, w - 16 * SS, X)
    img = assemble(rgb, board_alpha, sh)
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


def _rgba(alpha, streak):
    col = np.asarray(CREAM, np.float32) * (0.975 + 0.04 * streak)[..., None]
    out = np.concatenate([np.clip(col, 0, 1), alpha[..., None]], axis=-1)
    return (np.clip(out, 0, 1) * 255 + 0.5).astype(np.uint8)


def square_filled():
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
    return _rgba(cov * thick, streak)


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
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "plugins", "sinners.bar", "wood")
    os.makedirs(out, exist_ok=True)
    for name, (wlog, seed) in BOARDS.items():
        Image.fromarray(body(name, wlog, seed)).save(os.path.join(out, f"{name}-body.png"), optimize=True)
        Image.fromarray(cap(name, seed + 1, False)).save(os.path.join(out, f"{name}-lcap.png"), optimize=True)
        Image.fromarray(cap(name, seed + 2, True)).save(os.path.join(out, f"{name}-rcap.png"), optimize=True)
        print("wrote", name)
    wsdir = os.path.join(out, "..", "..", "sinners.workspaces")
    os.makedirs(wsdir, exist_ok=True)
    Image.fromarray(square_filled()).save(os.path.join(wsdir, "square-filled.png"), optimize=True)
    Image.fromarray(square_outline()).save(os.path.join(wsdir, "square-outline.png"), optimize=True)
    print("wrote squares")


main()
