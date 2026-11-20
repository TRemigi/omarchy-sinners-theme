#!/usr/bin/env python3
"""Checks that the unlock screen's sun lines up with the wallpaper's sun.

usage: verify-sun.py [WIDTHxHEIGHT]      default 1920x1200. Takes about two minutes: it renders two 4K images.

It builds the sun-only logo and a grain-free copy of the wallpaper with the same scripts, scales the wallpaper to
the screen the way Omarchy does, lays the logo over it where Plymouth would put it, and reports:
  1. the largest colour difference anywhere inside the disc (0-255; 0 or 1 is rounding), and
  2. the disc's left, right and top edges measured in the image, against the geometry computed from Omarchy's
     crop rules. These are measured on the output, so they do not depend on the scaling code under test. The red
     limb ring softens where "the edge" is, so this step uses a build with the limb off (SINNERS_SUN_RING=0).
The halo is not compared: the logo's halo sits on top of the wallpaper's own, so the two add up by design.
"""
import math, os, re, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
SCREEN = sys.argv[1] if len(sys.argv) > 1 else '1920x1200'
SW, SH = map(int, SCREEN.split('x'))
src = open(os.path.join(HERE, 'make-wallpaper.sh')).read()
WALLPAPER_W, WALLPAPER_H, SUN_X, SUN_Y, SUN_R = map(int, re.search(r'W=(\d+); H=(\d+); CX=(\d+); CY=(\d+); R=(\d+)', src).groups())
s = max(SW / WALLPAPER_W, SH / WALLPAPER_H)
exp_cx = SUN_X * round(WALLPAPER_W * s) / WALLPAPER_W - (round(WALLPAPER_W * s) - SW) / 2
exp_cy = SUN_Y * s - (round(WALLPAPER_H * s) - SH) / 2
exp_r = SUN_R * s

def run(*a): return subprocess.run(a, capture_output=True, text=True, check=True).stdout.strip()
tmp = tempfile.mkdtemp(prefix='verify-sun.')
w = lambda n: os.path.join(tmp, n)
print(f'screen {SCREEN}: the sun should be at ({exp_cx:.1f}, {exp_cy:.1f}) with radius {exp_r:.1f}')

# the grain-free wallpaper, built from the same script with only the grain line removed
open(w('nograin.sh'), 'w').write('\n'.join(l for l in src.split('\n') if 'grain.png -compose Overlay -composite' not in l))
run('bash', w('nograin.sh'), w('ref4k.png'))
run('python3', '-I', os.path.join(HERE, 'sun-unlock.py'), '--screen', SCREEN, '--layer', w('ref4k.png'), '--embers', '0',
    '--out', w('ignore.png'), '--screen-layer', w('ref_screen.png'))
run('python3', '-I', os.path.join(HERE, 'sun-unlock.py'), '--screen', SCREEN, '--embers', '0', '--out', w('logo.png'))
# the bare disc, for measuring its edges (the limb ring is off in both the wallpaper and the logo code)
run('env', 'SINNERS_SUN_RING=0', 'python3', '-I', os.path.join(HERE, 'sun-unlock.py'), '--screen', SCREEN, '--embers', '0', '--out', w('logo_bare.png'))
cw, ch = map(int, run('magick', 'identify', '-format', '%w %h', w('logo.png')).split())
x0, y0 = (SW - cw) // 2, (SH - ch) // 2

# 1. colour difference inside the disc (4px inside the rim), logo over the grain-free wallpaper
run('magick', w('ref_screen.png'), w('logo.png'), '-geometry', f'+{x0}+{y0}', '-compose', 'Over', '-composite', w('overlay.png'))
run('magick', w('overlay.png'), w('ref_screen.png'), '-fx', 'max(max(abs(u.r-v.r),abs(u.g-v.g)),abs(u.b-v.b))', w('diff.png'))
run('magick', '-size', f'{SW}x{SH}', 'xc:black', '-fill', 'white', '-draw',
    f'circle {exp_cx},{exp_cy} {exp_cx},{exp_cy - (exp_r - 4)}', w('mask.png'))
worst = float(run('magick', w('diff.png'), '-alpha', 'off', '-colorspace', 'Gray', w('mask.png'), '-alpha', 'off', '-colorspace', 'Gray',
                  '-compose', 'Multiply', '-composite', '-format', '%[fx:maxima*255]', 'info:'))

# 2. the disc's edges, measured on the bare-disc logo as Plymouth would draw it on a flat screen
run('magick', '-size', f'{SW}x{SH}', 'xc:#1A0905', w('logo_bare.png'), '-geometry', f'+{x0}+{y0}', '-compose', 'Over', '-composite', w('screen.png'))
def scan(crop, ch_index):
    out = run('magick', w('screen.png'), '-crop', crop, '+repage', 'txt:-')
    vals = []
    for line in out.splitlines()[1:]:
        m = re.match(r'(\d+),(\d+): \((\d+),(\d+),(\d+)', line)
        if m: vals.append((int(m[1]) + int(m[2]), int(m[3 + ch_index])))
    return vals
def steepest(vals, lo, hi):
    return vals[max(range(max(1, lo), min(hi, len(vals) - 1)), key=lambda i: abs(vals[i + 1][1] - vals[i - 1][1]))][0]
row = scan(f'{SW}x1+0+{round(exp_cy)}', 0)                  # red channel along the row through the sun's centre
left = steepest(row, round(exp_cx - exp_r) - 40, round(exp_cx - exp_r) + 40)
right = steepest(row, round(exp_cx + exp_r) - 40, round(exp_cx + exp_r) + 40)
col = scan(f'1x{SH}+{round(exp_cx)}+0', 1)                  # green channel down the centre column
top = steepest(col, round(exp_cy - exp_r) - 40, round(exp_cy - exp_r) + 40)
cx, r = (left + right) / 2, (right - left) / 2
cy = top + r
print(f'inside the disc: largest difference {worst:.2f} of 255')
print(f'measured edges: left x={left}, right x={right}, top y={top}  ->  centre ({cx:.1f}, {cy:.1f}), radius {r:.1f}')
ok = worst <= 2 and abs(cx - exp_cx) <= 1 and abs(cy - exp_cy) <= 1 and abs(r - exp_r) <= 1
print('PASS: the unlock sun lines up with the wallpaper sun' if ok else 'FAIL: the unlock sun is off the wallpaper sun')
sys.exit(0 if ok else 1)
