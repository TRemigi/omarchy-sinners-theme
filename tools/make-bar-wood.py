#!/usr/bin/env python3
"""Draws the boards of the Sinners bar: weathered wood under worn barn-red paint, as transparent PNGs.

usage: make-bar-wood.py [outdir]        (default: plugins/sinners.bar/wood)

Needs numpy, scipy and Pillow, which Omarchy does not install. In a throwaway virtualenv:

    python -m venv /tmp/wood && /tmp/wood/bin/pip install numpy scipy pillow
    /tmp/wood/bin/python tools/make-bar-wood.py

The PNGs are committed, so installing the bar needs none of this; run it only to change how the boards look.
It is deterministic: the same code writes the same files.

Original work: the wood, paint and nails are procedural (tools/woodlib.py). No photograph or film frame is sampled or
traced. See "A bar of boards" in the README.

It also draws wear.png, a tileable mask of where the paint on the lettering has chipped (see WornPaint.qml), and the gold plate behind the shown workspace (plugins/sinners.workspaces/plate.png): a small board painted
sign-gold, 19 x 24 logical px with its shadow below.

Each board is three files, because a board's length depends on the widgets on it:
  <name>-body.png   a long strip of wood and paint, cropped by the bar to the board's length
  <name>-lcap.png   the left end: ragged saw cut, end grain, two nails, fading into the body
  <name>-rcap.png   the right end, the same turned round
All are drawn at 2x. The bar is SURFACE logical px tall: TOP of margin, a board BOARD_H tall, and the rest is the
board's shadow on the wallpaper, drawn into the image because a layer surface cannot draw outside itself.
"""
import os, sys
import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter, gaussian_filter1d

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from woodlib import SS, smooth, make_wood, paint, nail, shade, SILVER, BROWN

SURFACE, TOP, BOARD_H = 36, 3, 30          # logical px; must match Bar.qml's stripSize and WoodBoard.qml
CAP_W = 28                                  # logical px of end cap, the last 16 of which fade into the body
END_AT = 3                                  # where the sawn end sits in a cap, logical px from the image edge
PAINT = (0.45, 0.115, 0.085)                # barn red, before wear
GOLD = (0.80, 0.56, 0.07)                   # the shown workspace's plate: sign-painter's gold
PLATE_W, PLATE_H, PLATE_SH = 19, 24, 1      # logical px; must match plugins/sinners.workspaces' patch
BOARDS = {"left": (1000, 101), "center": (1000, 202), "right": (700, 303)}   # name: (body width logical, seed)

H = SURFACE * SS
TOP_PX, BH = TOP * SS, BOARD_H * SS


def wood_canvas(rng, w, ragged_end=False):
    """The board's rows only (BH x w): shaded wood with its paint on it, as float RGB, plus the end profile if any."""
    v, hg, cr = make_wood(BH, w, rng, ring=(6.0, 12.0), lift=0.05, knots=int(rng.random() < 0.4),
                          crack_rate=1 / 900, crack_y="edges")
    rgb = 0.7 * SILVER(v - 0.02) + 0.3 * BROWN(v)
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
    cover = np.clip(worn * 1.4, 0, 1)
    paint(rgb, hg, cover, PAINT, rng, v, block=smooth(0.55, 0.95, cr), wear=1.3, opacity=0.88, wobble=1.0)
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


def wear_mask():
    """Where the paint has worn off the lettering: flakes stretched along the grain, in a picture that tiles in both directions.
    512 x 36 logical px. Rank-normalised, so the shader's thresholds pick the same share of it wherever they are set."""
    rng = np.random.default_rng(505)
    shape = (36 * SS, 512 * SS)

    def noise(sx, sy):
        n = gaussian_filter(rng.standard_normal(shape).astype(np.float32), (sy, sx), mode="wrap")
        return n / n.std()

    n = 0.60 * noise(40, 1.8) + 0.50 * noise(11, 0.9) + 0.35 * noise(220, 7.0)
    ranks = np.empty(n.size, np.float32)
    ranks[np.argsort(n, axis=None)] = np.linspace(0, 1, n.size, dtype=np.float32)
    return (ranks.reshape(shape) * 255 + 0.5).astype(np.uint8)


def plate():
    """The gold plate under the shown workspace: wood, gold paint worn at the edges, square-ish corners, a thin shadow."""
    rng = np.random.default_rng(404)
    w, h = PLATE_W * SS, PLATE_H * SS
    v, hg, _ = make_wood(h, w, rng, ring=(4.0, 8.0), lift=0.05, knots=0, crack_rate=0)
    rgb = 0.7 * SILVER(v - 0.02) + 0.3 * BROWN(v)
    Y, X = np.mgrid[0:h, 0:w].astype(np.float32)
    edge = np.minimum(np.minimum(X, w - 1 - X), np.minimum(Y, h - 1 - Y))
    hg = hg - 1.6 * smooth(3.0, 0.0, edge)
    rgb = rgb * (1 - 0.35 * smooth(2.5, 0.0, edge))[..., None]
    paint(rgb, hg, np.clip(smooth(0, 3.5, edge) * 1.5, 0, 1), GOLD, rng, v, wear=0.55, opacity=0.95, wobble=0.6)
    rgb = lit(rgb, hg)
    corner = np.clip(edge + 0.5, 0, 1)                        # a corner cut off by a pixel, not a curve
    sh = np.repeat(np.array([0.50, 0.30], np.float32)[:PLATE_SH * SS, None], w, axis=1)
    out = np.zeros((h + PLATE_SH * SS, w, 4), np.float32)
    out[:h, :, :3], out[:h, :, 3], out[h:, :, 3] = rgb, corner, sh
    return (np.clip(out, 0, 1) * 255 + 0.5).astype(np.uint8)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "plugins", "sinners.bar", "wood")
    os.makedirs(out, exist_ok=True)
    for name, (wlog, seed) in BOARDS.items():
        Image.fromarray(body(name, wlog, seed)).save(os.path.join(out, f"{name}-body.png"), optimize=True)
        Image.fromarray(cap(name, seed + 1, False)).save(os.path.join(out, f"{name}-lcap.png"), optimize=True)
        Image.fromarray(cap(name, seed + 2, True)).save(os.path.join(out, f"{name}-rcap.png"), optimize=True)
        print("wrote", name)
    Image.fromarray(wear_mask(), "L").save(os.path.join(out, "wear.png"), optimize=True)
    print("wrote wear")
    wsdir = os.path.join(out, "..", "..", "sinners.workspaces")
    os.makedirs(wsdir, exist_ok=True)
    Image.fromarray(plate()).save(os.path.join(wsdir, "plate.png"), optimize=True)
    print("wrote plate")


main()
