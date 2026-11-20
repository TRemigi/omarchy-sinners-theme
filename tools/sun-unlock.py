#!/usr/bin/env python3
"""Builds an unlock logo with the wallpaper's sun behind the title, aligned to the wallpaper on the real screen.

How the alignment works. Omarchy shows the 3840x2160 wallpaper scaled to cover the screen and center-cropped
(Qt's PreserveAspectCrop). Plymouth shows the logo at its own pixel size, centered on the screen. So the sun
layer (make-wallpaper.sh --sun-layer) is scaled and cropped exactly as the desktop does it, which gives a
screen-sized image, and the logo is the central crop of that image. Centered on the screen, the logo lands on
the wallpaper's sun, in the same size and the same colors.

The sun's position and size are read from make-wallpaper.sh, so the two cannot drift apart. The logo is only
correct for the screen size it was built for (see --screen); `hyprctl monitors` shows yours.

Plymouth puts the password field 40px below the logo, so the logo's height decides how low the field sits.
"""
import argparse, math, os, random, re, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
src = open(os.path.join(HERE, 'make-wallpaper.sh')).read()
geo = re.search(r'W=(\d+); H=(\d+); CX=(\d+); CY=(\d+); R=(\d+)', src)
if not geo:
    sys.exit('sun-unlock: cannot find the sun geometry line in make-wallpaper.sh')
WALLPAPER_W, WALLPAPER_H, SUN_X, SUN_Y, SUN_R = map(int, geo.groups())

ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
ap.add_argument('--screen', default='1920x1200', help='the real screen size, WxH (hyprctl monitors)')
ap.add_argument('--canvas', help='logo size WxH; default: the screen minus a margin of 1/12 of its width and 1/10 of its height per side')
ap.add_argument('--layer', help='4K sun layer from make-wallpaper.sh --sun-layer; built if omitted')
ap.add_argument('--word', help='the title PNG; omitted = the sun alone')
ap.add_argument('--word-dy', type=float, help='title centre, px below the sun centre; default 0: centred on the sun. (On the poster the title sits 0.13 radii low, because it is part of a text block that is itself centred.)')
ap.add_argument('--embers', type=int, default=40, help='sparks in the glow around the sun')
ap.add_argument('--fade', default='ellipse', choices=['rect', 'radial', 'ellipse'], help='how the halo fades out before the canvas ends')
ap.add_argument('--ellipse-x', type=float, default=640, help='ellipse fade: horizontal reach from the sun centre, px')
ap.add_argument('--out', required=True)
ap.add_argument('--screen-layer', help='also write the screen-sized sun layer here (for verification)')
a = ap.parse_args()

SW, SH = map(int, a.screen.split('x'))
if a.canvas:
    CW, CH = map(int, a.canvas.split('x'))
else:
    CW, CH = SW - 2 * round(SW / 12), SH - 2 * round(SH / 10)
assert (SW - CW) % 2 == 0 and (SH - CH) % 2 == 0, 'canvas and screen must have the same parity so Plymouth centers on whole pixels'
s = max(SW / WALLPAPER_W, SH / WALLPAPER_H)                   # cover-fit scale
sw_s, sh_s = round(WALLPAPER_W * s), round(WALLPAPER_H * s)   # scaled wallpaper size
ox, oy = (sw_s - SW) / 2, (sh_s - SH) / 2                      # centered crop, in px (can be half pixels)
x0, y0 = (SW - CW) // 2, (SH - CH) // 2                        # where Plymouth puts the logo's top-left corner
sun_x, sun_y, sun_r = SUN_X * sw_s / WALLPAPER_W - ox - x0, SUN_Y * s - oy - y0, SUN_R * s   # in logo coordinates
word_dy = a.word_dy if a.word_dy is not None else 0.0
print(f'scale {s:.5f}; sun on screen ({sun_x + x0:.1f}, {sun_y + y0:.1f}) r={sun_r:.1f}; in the logo ({sun_x:.1f}, {sun_y:.1f})')

def m(*args): subprocess.run(['magick', *args], check=True)
tmp = tempfile.mkdtemp(prefix='sunlogo.')
w = lambda n: os.path.join(tmp, n)

layer = a.layer
if not layer:
    layer = w('layer4k.png')
    subprocess.run([os.path.join(HERE, 'make-wallpaper.sh'), layer, '--sun-layer'], check=True)

# 1. scale and crop the sun layer the way the desktop does: cover-fit, then a centered crop (half-pixel exact)
m(layer, '-filter', 'Lanczos', '-resize', f'{sw_s}x{sh_s}!', '-virtual-pixel', 'transparent',
  '-define', f'distort:viewport={SW}x{SH}+0+0', '-distort', 'SRT', f'0,0 1 0 {-ox},{-oy}', '+repage', w('screen_layer.png'))
if a.screen_layer: m(w('screen_layer.png'), a.screen_layer)
# 2. the logo is the central crop of that
m(w('screen_layer.png'), '-crop', f'{CW}x{CH}+{x0}+{y0}', '+repage', w('canvas.png'))
# 3. fade the halo to nothing before the logo ends, so no hard edge shows. The disc itself is never touched.
room_top = sun_y - sun_r
mt = max(8, min(64, room_top - 4)); mx = 140; mb = 140
assert room_top > mt, 'the logo is too short to fade the halo above the disc without touching it; use a taller --canvas'
if a.fade == 'rect':
    expr = f'sx=min(i,w-1-i)/{mx}; sy=min(j/{mt:.1f},(h-1-j)/{mb}); tt=min(1,min(sx,sy)); tt*tt*(3-2*tt)'
elif a.fade == 'radial':      # a round corona, fully faded at the nearest edge (straight above the sun)
    d0, d1 = sun_r + 3, sun_y
    expr = f'dd=hypot(i-{sun_x},j-{sun_y}); tt=max(0,min(1,({d1}-dd)/({d1-d0}))); tt*tt*(3-2*tt)'
else:                         # an oval corona: it reaches further sideways than upwards, where the logo is short
    ax, ay = a.ellipse_x, sun_y
    r0 = (sun_r + 3) / ay     # keeps the disc untouched where the oval is tightest, straight above the sun
    expr = f'rr=hypot((i-{sun_x})/{ax},(j-{sun_y})/{ay}); tt=max(0,min(1,(1-rr)/{1-r0:.4f})); tt*tt*(3-2*tt)'
m('-size', f'{CW}x{CH}', 'xc:black', '-fx', expr, w('fade.png'))
m(w('canvas.png'), '-alpha', 'extract', w('alpha.png'))
m(w('alpha.png'), w('fade.png'), '-compose', 'Multiply', '-composite', w('alpha2.png'))
m(w('canvas.png'), w('alpha2.png'), '-alpha', 'off', '-compose', 'CopyOpacity', '-composite', w('logo0.png'))

cmd = [w('logo0.png')]
word_box = None
if a.word:
    ww, wh = map(int, subprocess.run(['magick', 'identify', '-format', '%w %h', a.word], capture_output=True, text=True, check=True).stdout.split())
    wx, wy = round(CW / 2 - ww / 2), round(sun_y + word_dy - wh / 2)
    word_box = (wx - 16, wy - 16, wx + ww + 16, wy + wh + 16)
# 4. embers: small squares rising around the sun. Only in the glow: on the face of the sun they read as dust.
if a.embers:
    random.seed(11)
    GOLD, ORANGE, RED = (249, 189, 6), (251, 116, 7), (233, 26, 2)
    draws, placed, tries = [], 0, 0
    while placed < a.embers and tries < 4000:
        tries += 1
        x = random.gauss(sun_x, sun_r * 0.95)                                   # rising: denser above the sun
        y = sun_y - abs(random.gauss(0, sun_r * 1.15)) + random.gauss(0, sun_r * 0.15)
        if not (24 < x < CW - 24 and 24 < y < CH - 150): continue
        if word_box and word_box[0] < x < word_box[2] and word_box[1] < y < word_box[3]: continue
        d = math.hypot(x - sun_x, y - sun_y)
        if d < sun_r + 10: continue
        color = GOLD if random.random() < 0.4 else ORANGE if random.random() < 0.65 else RED
        alpha = random.uniform(0.35, 0.95) * max(0.25, 1 - max(0, d - sun_r) / (sun_r * 1.2))
        size = 10 if random.random() < 0.2 else 6
        ex, ey = int(x) // 2 * 2, int(y) // 2 * 2
        draws += ['-fill', f'rgba({color[0]},{color[1]},{color[2]},{alpha:.2f})', '-draw', f'rectangle {ex},{ey} {ex + size - 1},{ey + size - 1}']
        placed += 1
    cmd += draws
if a.word:
    cmd += [a.word, '-geometry', f'+{wx}+{wy}', '-compose', 'Over', '-composite']
m(*cmd, '+repage', '-depth', '8', '+set', 'date:create', '+set', 'date:modify', '+set', 'date:timestamp', a.out)
print(f'wrote {a.out} ({CW}x{CH}); the password field will sit at y={y0 + CH + 40} of {SH}')
