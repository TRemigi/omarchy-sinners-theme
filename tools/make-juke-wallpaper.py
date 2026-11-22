#!/usr/bin/env python3
"""Draws the Club Juke wallpaper: the juke joint at night as ASCII art, with red eyes in the sky over it.

usage: make-juke-wallpaper.py <out.png> [scale]      scale 2 (the default) gives 3840x2160
       then: magick out.png -define webp:lossless=true backgrounds/3-sinners-club-juke.webp

The cool counterpart to the warm sun wallpapers: a moonlit navy and teal night, with the only warm colour in the club's
windows, the light they put on its plank walls, its sign and the lamp, and the red of the eyes. The scene is an original
composition: the layout (a wide plank building with a tin roof, patchwork windows, a lamp post on the left, a line of people
across the yard, a car each side, trees behind) follows a still of Club Juke, but nothing is traced or sampled from it.

How it is made. The scene is painted at 1920x1080, each pixel with a colour and a material (sky, roof, wall, window, ...).
It is then cut into a grid of 8x16 character cells, 240 across, and each cell becomes one character of its main material:
the roof `|==|`, the plank walls `|:|:`, windows `+=#%@` by brightness, the ground ` .,:;=+`, the eyes ` .:-=+*#@`, stars
`.+*`. People, cars and the doorway are left blank, so they read as dark shapes against the lit yard. The characters are
drawn in Noto Sans Mono Bold at `scale` times that size. It is deterministic. Needs numpy and Pillow (see make-bar-wood.py).
"""
import math, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

W, H = 1920, 1080                   # the scene is laid out at this size; the picture is drawn at `scale` times it
CW, CH = 8, 16                      # character cell
COLS, ROWS = W // CW, math.ceil(H / CH)
OUT = sys.argv[1]
K = int(sys.argv[2]) if len(sys.argv) > 2 else 2
FONT = '/usr/share/fonts/noto/NotoSansMono-Bold.ttf'
rng = np.random.default_rng(7)

# materials
SKY, STAR, TREE, ROOF, WALL, WIN, DOOR, GROUND, FIG, CAR, LAMP, POST, EYE, SIGN = range(14)

rgb = np.zeros((H, W, 3), np.float32)
mat = np.zeros((H, W), np.int16)
Y, X = np.mgrid[0:H, 0:W].astype(np.float32)

def hexc(h): return np.array([int(h[i:i + 2], 16) / 255 for i in (1, 3, 5)], np.float32)
def mask(draw_fn):
    im = Image.new('L', (W, H), 0); draw_fn(ImageDraw.Draw(im)); return np.asarray(im) > 127
def put(m, material, colour):
    mat[m] = material; rgb[m] = colour

# sky: deep navy, a little lighter toward the horizon
t = np.clip(Y / 620, 0, 1)[..., None]
rgb[:] = hexc('#03060C') * (1 - t) + hexc('#0C1A26') * t
mat[:] = SKY
# eyes: two glowing red eyes, centred over the club
EYES = [(800, 190), (1120, 190)]
glow = np.zeros((H, W), np.float32)
for ex, ey in EYES:
    d = np.hypot((X - ex) / 1.0, (Y - ey) / 0.8)
    glow += np.exp(-(d / 75) ** 2) * 0.5 + np.exp(-(d / 20) ** 2) * 2.6
    glow += np.exp(-((X - ex) / 4.0) ** 2) * np.exp(-((Y - ey) / 105) ** 2) * 1.1      # the vertical slit flare
rgb += glow[..., None] * hexc('#E91A02') * 0.9
mat[glow > 0.12] = EYE
# stars
STARS = {}
for _ in range(420):
    c, r = int(rng.integers(0, W // CW)), int(rng.integers(0, 30))
    if min(math.hypot(c * CW - ex, r * CH - ey) for ex, ey in EYES) < 150: continue
    STARS[r, c] = rng.uniform(0.25, 1.0)
# treeline behind the club
xs = np.arange(W)
top = 560 - 40 * np.abs(np.sin(xs / 37.0)) * rng.uniform(0.6, 1.0, W).cumsum() % 1 \
      - 25 * np.sin(xs / 190.0) ** 2 - 18 * np.abs(np.sin(xs / 23.0 + 1.3))
top = np.convolve(top, np.ones(9) / 9, mode='same')
m = (Y >= top[None, :]) & (Y < 660)
put(m, TREE, hexc('#12303A'))
# ground: dirt, lit by the windows and the lamp
GROUND_Y = 640
m = Y >= GROUND_Y
light = (0.55 * np.exp(-(((X - 960) / 620) ** 2 + ((Y - 660) / 150) ** 2))
         + 0.45 * np.exp(-(((X - 380) / 170) ** 2 + ((Y - 720) / 70) ** 2)))
grain = rng.random((H, W)).astype(np.float32)
g = (0.35 + 1.6 * light) * (0.75 + 0.5 * grain) * np.clip(1.2 - (Y - GROUND_Y) / 700, 0.4, 1.2)
gc = hexc('#1E3440')[None, None, :] * (1 - light[..., None]) + hexc('#5C8C96')[None, None, :] * light[..., None]
rgb[m] = (gc * g[..., None])[m]; mat[m] = GROUND
# the club: tin roof over plank walls
put(mask(lambda d: d.polygon([(560, 380), (1360, 380), (1450, 458), (470, 458)], fill=255)), ROOF, hexc('#4A7686'))
roof = mat == ROOF
rgb[roof] *= (0.8 + 0.35 * (np.sin(X[roof] / 6.0) > 0))[:, None] * (0.75 + 0.35 * ((Y[roof] - 380) / 78))[:, None]
put(mask(lambda d: d.rectangle([490, 458, 1430, 642], fill=255)), WALL, hexc('#1B2C35'))
wall = mat == WALL
rgb[wall] *= (0.75 + 0.5 * rng.random(W)[X[wall].astype(int) // 14 * 14 % W])[:, None]
put(mask(lambda d: d.rectangle([860, 560, 930, 642], fill=255)), DOOR, hexc('#070C10'))
WINDOWS = [(560, 492, 680, 538), (775, 492, 870, 530), (1060, 492, 1160, 538), (1250, 492, 1345, 530),
           (580, 560, 680, 600), (1050, 560, 1150, 604)]
for x0, y0, x1, y1 in WINDOWS:
    pw, ph = (x1 - x0) / 4, (y1 - y0) / 2
    for i in range(4):
        for j in range(2):
            b = rng.uniform(0.45, 1.0)
            m = mask(lambda d: d.rectangle([x0 + i * pw + 2, y0 + j * ph + 2, x0 + (i + 1) * pw - 2, y0 + (j + 1) * ph - 2], fill=255))
            tint = rng.uniform(0, 1)
            put(m, WIN, (hexc('#FFC23A') * (1 - tint) + hexc('#FB7407') * tint) * b)
put(mask(lambda d: d.rectangle([1340, 560, 1410, 592], fill=255)), SIGN, hexc('#F8502D'))
# the window light spilling on the wall and roof edge
for x0, y0, x1, y1 in WINDOWS:
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    sp = np.exp(-(((X - cx) / 110) ** 2 + ((Y - cy) / 45) ** 2)) * 0.5
    sel = (mat == WALL)
    rgb[sel] += (sp[..., None] * hexc('#C8641E'))[sel]
# lamp post and its lamp
put(mask(lambda d: d.rectangle([374, 400, 384, 700], fill=255)), POST, hexc('#2E4A55'))
lamp = np.exp(-(((X - 392) / 16) ** 2 + ((Y - 398) / 12) ** 2))
put(lamp > 0.3, LAMP, hexc('#F9A01E'))
# cars: an old car each side, as dark shapes
def car(x, y, w, h, flip=False):
    pts = [(0, 0.55), (0.12, 0.5), (0.22, 0.05), (0.62, 0.0), (0.72, 0.45), (0.98, 0.5), (1.0, 0.85), (0.0, 0.85)]
    if flip: pts = [(1 - a, b) for a, b in pts]
    body = mask(lambda d: d.polygon([(x + a * w, y + b * h) for a, b in pts], fill=255))
    wheels = mask(lambda d: [d.ellipse([x + c * w - 0.1 * w, y + 0.65 * h, x + c * w + 0.1 * w, y + 1.0 * h], fill=255) for c in (0.2, 0.8)])
    put(body | wheels, CAR, hexc('#0B151A'))
car(250, 640, 230, 140)
car(1700, 660, 300, 170, flip=True)
# the crowd: a curved line of people facing the club, and loose groups by the lamp and the car
def person(x, feet, h, lean=0.0):
    w = h * 0.26
    def dr(d):
        d.ellipse([x - w * 0.32, feet - h, x + w * 0.32, feet - h + w * 0.64], fill=255)                     # head
        d.polygon([(x - w * 0.5 + lean, feet - h * 0.82), (x + w * 0.5 + lean, feet - h * 0.82),
                   (x + w * 0.42, feet - h * 0.38), (x - w * 0.42, feet - h * 0.38)], fill=255)           # body
        d.rectangle([x - w * 0.36, feet - h * 0.4, x - w * 0.06, feet], fill=255)                          # legs
        d.rectangle([x + w * 0.06, feet - h * 0.4, x + w * 0.36, feet], fill=255)
    put(mask(dr), FIG, hexc('#04080B'))
for k in range(20):
    u = k / 19
    x = 560 + u * 960 + rng.uniform(-12, 12)
    feet = 790 + 40 * (1 - (2 * u - 1) ** 2) + rng.uniform(-8, 8)             # the line bows toward the viewer
    person(x, feet, rng.uniform(115, 135))
for x, f in [(190, 760), (225, 745), (450, 742), (480, 735), (1540, 770), (1585, 760), (1620, 775)]:
    person(x, f, rng.uniform(105, 125))

# ---- to ASCII -------------------------------------------------------------------------------------------------------
RAMP = {SKY: ' ', STAR: '.+*', TREE: ' .:;', GROUND: ' .,:;=+', WIN: '+=#%@', SIGN: '#', LAMP: '*@', POST: '|',
        EYE: ' .:-=+*#@', DOOR: ' ', FIG: ' ', CAR: ' '}
SCALE = {GROUND: 0.30, TREE: 0.06, EYE: 0.45, WIN: 0.6, LAMP: 0.6, SIGN: 1, POST: 1, STAR: 1, SKY: 1, DOOR: 1, FIG: 1, CAR: 1}
font = ImageFont.truetype(FONT, 13 * K)
out = Image.new('RGB', (W * K, H * K), (2, 4, 8))
od = ImageDraw.Draw(out)
lum = rgb @ np.array([0.2126, 0.7152, 0.0722], np.float32)
for r in range(ROWS):
    for c in range(COLS):
        ys, xs_ = slice(r * CH, min(H, (r + 1) * CH)), slice(c * CW, (c + 1) * CW)
        mm = np.bincount(mat[ys, xs_].ravel(), minlength=14)
        mt = int(np.argmax(mm))
        col = rgb[ys, xs_][mat[ys, xs_] == mt].mean(0)
        L = float(lum[ys, xs_][mat[ys, xs_] == mt].mean())
        if mt == ROOF:
            ch = '|' if c % 3 == 0 else ('=' if L > 0.12 else '-')
        elif mt == WALL:
            ch = '|' if c % 2 == 0 else (':' if L > 0.05 else '.')
        else:
            ramp = RAMP[mt]
            ch = ramp[min(len(ramp) - 1, int(L / SCALE[mt] * len(ramp)))]
            if mt == SKY and (r, c) in STARS:
                b = STARS[r, c]; ch = '.' if b < 0.6 else '+' if b < 0.9 else '*'
                col = hexc('#7FA4B8') * b * 0.6
        if ch == ' ': continue
        colour = tuple(int(min(255, v * 255 * 1.7 + 6)) for v in col)
        od.text(((c * CW + CW / 2) * K, (r * CH + CH / 2) * K), ch, font=font, fill=colour, anchor='mm')
out.save(OUT)
