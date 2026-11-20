#!/usr/bin/env python3
"""Builds the "eyes" unlock logo: two glowing red eyes above a dimmed OMARCHY wordmark.

usage: eyes.py <stock-unlock.png> <out.png>

Inspired by the red-eyed face on the Sinners illustrated poster. Drawn from scratch, with no pixels
from the poster. Only its measurements were used. On the poster each eye is a tiny sharp point:
core #E93A03, a steep glow that falls to the dark ambient within about 34px (on a 2764px-wide
image), a thin vertical streak, and a dark socket. The glow alpha is fitted to the measured falloff:
alpha(d) = exp(-(d / 17.2)^2.63), with d in poster pixels, scaled here by K.

The canvas is 800x400. Plymouth centers the logo and puts the password field 40px below its bottom
edge, so this is about 106px taller than the default wordmark. Keep logos about 400px tall or less.
"""
import subprocess
import sys
import tempfile

STOCK, OUT = sys.argv[1], sys.argv[2]

CORE = '#E93A03'
W, H = 800, 400                 # logo canvas
EYE_SPACING, EYE_Y = 300, 84    # eye centers, in canvas pixels
WM_Y = 178                      # wordmark top; it is 800x188
K = 1.15                        # glow scale relative to the poster
R0 = 17.2 * K
C = 240                         # eye tile size
M = C // 2


def magick(*args):
    subprocess.run(['magick', *args], check=True)


def alpha_from(mask, color, out):
    """Fill `color` through a grayscale `mask` used as alpha."""
    magick('-size', f'{C}x{C}', f'xc:{color}', mask, '-alpha', 'off', '-compose', 'CopyOpacity', '-composite', out)


with tempfile.TemporaryDirectory() as t:
    # glow: fitted falloff
    magick('-size', f'{C}x{C}', 'xc:black', '-fx', f'exp(-pow(hypot(i-{M},j-{M})/{R0:.1f},2.63))',
           '-alpha', 'off', f'{t}/glow_mask.png')
    alpha_from(f'{t}/glow_mask.png', CORE, f'{t}/glow.png')
    # vertical streak through the eye
    magick('-size', f'{C}x{C}', 'xc:black', '-fx', f'0.8*exp(-pow(abs(j-{M})/42,2))*exp(-pow(abs(i-{M})/1.5,2))',
           '-alpha', 'off', f'{t}/streak_mask.png')
    alpha_from(f'{t}/streak_mask.png', CORE, f'{t}/streak.png')
    # dark socket: a soft black ellipse, 42% at the center
    magick('-size', '200x110', 'xc:black', '-fill', 'white', '-draw', 'ellipse 100,55 74,25 0,360',
           '-blur', '0x12', '-alpha', 'off', '-evaluate', 'multiply', '0.42', f'{t}/sock_mask.png')
    magick('-size', '200x110', 'xc:black', f'{t}/sock_mask.png', '-alpha', 'off',
           '-compose', 'CopyOpacity', '-composite', f'{t}/sock.png')
    # one eye: socket, glow, streak, then a crisp square core, like the wordmark's pixels
    magick('-size', f'{C}x{C}', 'xc:none',
           f'{t}/sock.png', '-geometry', f'+{M - 100}+{M - 55}', '-compose', 'Over', '-composite',
           f'{t}/glow.png', '-compose', 'Over', '-composite',
           f'{t}/streak.png', '-compose', 'Over', '-composite',
           '-fill', CORE, '-draw', f'rectangle {M - 4},{M - 4} {M + 3},{M + 3}',
           f'{t}/eye.png')
    # dimmed wordmark: the stock letters' alpha filled with a dark-ember gradient
    magick('(', '-size', '800x94', 'gradient:#8A210A-#6E2410', '-size', '800x94', 'gradient:#6E2410-#5A1F0F',
           '-append', '+repage', ')',
           '(', STOCK, '-alpha', 'extract', '-alpha', 'off', '+repage', ')',
           '-compose', 'CopyOpacity', '-composite', '+repage', f'{t}/wordmark.png')
    # compose the logo
    cmd = ['-size', f'{W}x{H}', 'xc:none', f'{t}/wordmark.png', '-geometry', f'+0+{WM_Y}',
           '-compose', 'Over', '-composite']
    for dx in (-EYE_SPACING // 2, EYE_SPACING // 2):
        cmd += [f'{t}/eye.png', '-geometry', f'{W // 2 + dx - M:+d}{EYE_Y - M:+d}',
                '-compose', 'Over', '-composite']
    magick(*cmd, '+repage', '-depth', '8', '+set', 'date:create', '+set', 'date:modify',
           '+set', 'date:timestamp', OUT)
