#!/usr/bin/env python3
"""Builds the embers logo: the gradient wordmark on a transparent canvas with a faint red halo
behind it and square-pixel embers rising above it.

usage: embers.py <wordmark.png> <out.png>   (wordmark: any size up to 1000x408)

The canvas is symmetric around the wordmark, because Plymouth centers the logo image on screen.
Plymouth also places the password field 40px below the image's bottom edge, so a taller canvas
pushes the field down by the same amount. Keep the canvas about 400px tall or less.
Embers are placed on a jittered column grid (seeded, so every run is identical) to spread them
evenly. They avoid the wordmark's own rows so they never touch the letters.
"""
import random
import subprocess
import sys

W, H = 1000, 408            # canvas
wordmark, out = sys.argv[1], sys.argv[2]
# The wordmark can be any size that fits the canvas; it is centered, and the embers keep clear of its rows.
WM_W, WM_H = map(int, subprocess.run(['magick', 'identify', '-format', '%w %h', wordmark],
                                     capture_output=True, text=True, check=True).stdout.split())
WM_X, WM_Y = (W - WM_W) // 2, (H - WM_H) // 2
GOLD, ORANGE, RED = (249, 189, 6), (251, 116, 7), (233, 26, 2)   # sun gradient stops

random.seed(11)
draws = []


def ember(x, y, size, color, alpha):
    x, y = x // 2 * 2, y // 2 * 2       # even coordinates, like the wordmark's pixel grid
    r, g, b = color
    draws.extend(['-fill', f'rgba({r},{g},{b},{alpha:.2f})',
                  '-draw', f'rectangle {x},{y} {x + size - 1},{y + size - 1}'])


def pick_color(warm):
    roll = random.random()
    return GOLD if roll < warm else ORANGE if roll < warm + 0.35 else RED


# Above the wordmark: one column cell per 40px, most cells get an ember, some get two.
# Embers are brighter and more gold the closer they are to the letters.
TOP_Y0, TOP_Y1 = 8, WM_Y - 12
for cx in range(30, W - 30, 40):
    for _ in range(1 + (random.random() < 0.4)):
        if random.random() < 0.85:
            y = random.randrange(TOP_Y0, TOP_Y1)
            closeness = (y - TOP_Y0) / (TOP_Y1 - TOP_Y0)          # 0 far, 1 near the letters
            ember(cx + random.randrange(0, 34), y,
                  10 if random.random() < 0.22 else 6,
                  pick_color(0.2 + 0.4 * closeness), 0.30 + 0.65 * closeness)

# Beside the letters, in the wordmark's own rows: a few on each side, outside the letters' span.
for side_x0, side_x1 in ((8, WM_X - 6), (WM_X + WM_W + 6, W - 14)):
    for _ in range(5):
        ember(random.randrange(side_x0, side_x1), random.randrange(WM_Y + 10, WM_Y + WM_H - 10),
              6, random.choice([ORANGE, RED]), random.uniform(0.3, 0.6))

# Below: sparse and dim red, like cooling ash.
for cx in range(60, W - 60, 90):
    if random.random() < 0.8:
        ember(cx + random.randrange(0, 80), random.randrange(WM_Y + WM_H + 12, H - 8),
              6, RED, random.uniform(0.25, 0.5))

subprocess.run(
    ['magick', '-size', f'{W}x{H}', '-define', f'gradient:radii={W * 0.47:.0f},{H * 0.43:.0f}',
     'radial-gradient:#E91A0248-#E91A0200', '-alpha', 'set',
     wordmark, '-geometry', f'+{WM_X}+{WM_Y}', '-composite',
     *draws, '-depth', '8', '+set', 'date:create', '+set', 'date:modify', '+set', 'date:timestamp', out],
    check=True)
