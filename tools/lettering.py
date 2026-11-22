#!/usr/bin/env python3
"""Draws the title in the style of the Sinners poster's title, as a transparent PNG.

usage: lettering.py <out.png> [workdir] [word] [pointsize] [--wordmark LOGO.TXT]      (word: OMARCHY, pointsize: 175)

With --wordmark, the letters are Omarchy's ASCII wordmark (/usr/share/omarchy/logo.txt) instead of the font, and word is
ignored. Each character of the art is one column of the grid and two rows: a full block fills both, a half block one. The
pixels are square, a column is pointsize/16.6 px wide, and the art keeps its own proportions; the treatment below is the same.

Original work: Noto Sans Bold plus a procedural treatment, not the studio's logo. The style comes from measuring
the poster's title: clean straight letters on one baseline, stems 0.195 of the cap height, torn-paint chips only
on the axis-aligned edges (stem sides and ends) while diagonals stay razor-clean, and a few soft amber stains on
neon lemon. Every size below is given for pointsize 175 and scales with the pointsize. It is deterministic.
"""
import os, subprocess, sys, tempfile
args = sys.argv[1:]
WORDMARK = None
if '--wordmark' in args:
    i = args.index('--wordmark')
    WORDMARK = args[i + 1]
    del args[i:i + 2]
OUT = args[0]
WORK = args[1] if len(args) > 1 else tempfile.mkdtemp(prefix='lettering.')
os.makedirs(WORK, exist_ok=True)
WORD = args[2] if len(args) > 2 else 'OMARCHY'
PT = int(args[3]) if len(args) > 3 else 175
FONT = '/usr/share/fonts/noto/NotoSans-Bold.ttf'      # Noto Sans Bold, SIL Open Font License
if not os.path.exists(FONT):
    sys.exit(f'lettering: font not found: {FONT} (install the noto-fonts package)')
XSCALE = 93                 # % horizontal: brings stem/cap-height to the title's 0.195 and N/R to its widths
TRACK = 7                   # extra letter spacing in px at PT 175 (scaled with PT)
YEL, AMBER = '#F7F104', '#F2A00E'
U = PT / 175.0              # every blur/size below is for PT 175 and scales with the letters
GATE_COVER = 0.42           # share of the edge length that is ragged; the rest stays clean
CHIP_FRAC = 0.40            # share of the gated edge band that is bitten away
STAIN_COVER, STAIN_ALPHA = 0.055, 0.55
def m(*a): subprocess.run(['magick', *a], check=True)
def w(*a): return os.path.join(WORK, *a)
def size(f): return map(int, subprocess.run(['magick','identify','-format','%w %h',f],capture_output=True,text=True,check=True).stdout.split())
def mean(f): return float(subprocess.run(['magick',f,'-colorspace','Gray','-format','%[fx:mean]','info:'],capture_output=True,text=True,check=True).stdout)
def tail_threshold(img, frac):
    out = subprocess.run(['magick',img,'-colorspace','Gray','-depth','8','-format','%c','histogram:info:-'],capture_output=True,text=True,check=True).stdout
    counts = {}
    for line in out.splitlines():
        t = line.strip().split(':', 1)
        if len(t) == 2 and t[0].isdigit() and '(' in t[1]:
            v = int(t[1].split('(')[1].split(',')[0].strip().split('.')[0]); counts[v] = counts.get(v, 0) + int(t[0])
    total = sum(counts.values()); acc = 0
    for v in range(255, -1, -1):
        acc += counts.get(v, 0)
        if acc / total >= frac: return 100 * v / 255
    return 100.0
def wordmark_grid(path):
    """The ASCII wordmark as a plain PBM, one pixel per half character cell (black = ink, as PBM has it), and its size."""
    if not os.path.exists(path):
        sys.exit(f'lettering: wordmark not found: {path}')
    lines = open(path, encoding='utf-8').read().rstrip('\n').split('\n')
    halves = {'\u2588': (0, 1), '\u2580': (0,), '\u2584': (1,)}     # full block, upper half, lower half
    cols, rows = max(map(len, lines)), 2 * len(lines)
    grid = [[0] * cols for _ in range(rows)]
    for r, line in enumerate(lines):
        for c, ch in enumerate(line):
            for h in halves.get(ch, ()):
                grid[2 * r + h][c] = 1
    if not any(map(any, grid)):
        sys.exit(f'lettering: no block characters in {path}')
    return f'P1\n{cols} {rows}\n' + '\n'.join(' '.join(map(str, row)) for row in grid) + '\n', cols, rows

# 1. straight letters: same baseline, no rotation, no jitter
if WORDMARK:
    pbm, cols, rows = wordmark_grid(WORDMARK)
    open(w('wordmark.pbm'), 'w').write(pbm)
    cell = PT / 16.6
    # Enlarge with hard edges, then average down to the exact (fractional) size: square pixels, clean edges, no seams.
    m(w('wordmark.pbm'), '-negate', '-filter', 'Point', '-resize', '1600%', '-filter', 'Box',
      '-resize', f'{round(cols * cell)}x{round(rows * cell)}!', '-colorspace','Gray','-alpha','off',
      '-bordercolor','black','-border',str(round(20*U)), w('word.png'))
else:
    adv = []
    for i, c in enumerate(WORD):
        m('-background','none','-font',FONT,'-pointsize',str(PT),'-fill','white','label:'+c,w(f'g{i}.png'))
        adv.append(tuple(size(w(f'g{i}.png'))))
    H = adv[0][1]; PAD = 30; track = round(TRACK * U)
    total = sum(a for a, _ in adv) + track * (len(WORD) - 1) + 2 * PAD
    cmd = ['-size', f'{total}x{H+2*PAD}', 'xc:black']; x = PAD
    for i in range(len(WORD)):
        cmd += [w(f'g{i}.png'), '-geometry', f'+{x}+{PAD}', '-compose', 'Over', '-composite']; x += adv[i][0] + track
    m(*cmd, '-colorspace','Gray','-alpha','off','-trim','+repage','-bordercolor','black','-border',str(round(20*U)),
      '-resize', f'{XSCALE}x100%!', w('word.png'))
W, Hh = size(w('word.png'))
def noise(seed, blur): return ['-seed',str(seed),'-size',f'{W}x{Hh}','xc:gray50','+noise','Random','-colorspace','Gray','-blur',f'0x{blur*U:.2f}','-auto-level']
# 2. ragged edges: erosion confined to a thin band along the edges, and gated into patches so most edges stay clean
m(w('word.png'),'-morphology','Dilate',f'Disk:{max(2,round(2*U))}',w('dil.png'))
m(w('word.png'),'-morphology','Erode',f'Disk:{max(2,round(5*U))}',w('ero.png'))
m(w('dil.png'),w('ero.png'),'-compose','Mathematics','-define','compose:args=0,-1,1,0','-composite','-blur',f'0x{1.0*U:.2f}',w('band.png'))
m(*noise(7, 16), w('gate_n.png'))
t = tail_threshold(w('gate_n.png'), GATE_COVER)
m(w('gate_n.png'), '-sigmoidal-contrast', f'14,{t:.1f}%', w('gate.png'))
m(*noise(11, 1.35), '-evaluate','Pow','1.3', w('teeth.png'))
# chips are hard cutouts: teeth above a threshold, inside the edge band, inside the gated patches
t = tail_threshold(w('teeth.png'), CHIP_FRAC)
m(w('teeth.png'), '-threshold', f'{t:.1f}%', w('teeth_bin.png'))
m(w('band.png'), '-threshold', '40%', w('band_bin.png'))
m(w('gate.png'), '-threshold', '50%', w('gate_bin.png'))
# Sobel gradients: an edge is axis-aligned when one gradient component is much larger than the other
m(w('word.png'), '-blur', f'0x{0.8*U:.2f}', '-define','convolve:bias=50%', '-morphology','Convolve','Sobel:0', w('gx.png'))
m(w('word.png'), '-blur', f'0x{0.8*U:.2f}', '-define','convolve:bias=50%', '-morphology','Convolve','Sobel:90', w('gy.png'))
m(w('gx.png'), w('gy.png'), '-colorspace','Gray', '-fx', 'max(0, 1-3.0*min(abs(u-0.5),abs(v-0.5))/(max(abs(u-0.5),abs(v-0.5))+0.01))',
  '-blur', f'0x{1.2*U:.2f}', '-threshold','50%', '-negate', '-morphology','Dilate',f'Disk:{round(4*U)}', '-negate', w('axis_bin.png'))
m(w('teeth_bin.png'), w('band_bin.png'), '-compose','Multiply','-composite', w('gate_bin.png'), '-compose','Multiply','-composite',
  w('axis_bin.png'), '-compose','Multiply','-composite',
  '-blur', f'0x{0.35*U:.2f}', '-sigmoidal-contrast','10,50%', '-negate', w('keep.png'))
m(w('word.png'), w('keep.png'), '-compose','Multiply','-composite', w('mask.png'))
# 3. fill: neon lemon with a few soft amber stains
m(*noise(51, 3.2), w('stain_n.png'))
t = tail_threshold(w('stain_n.png'), STAIN_COVER)
m(w('stain_n.png'), '-threshold', f'{t:.1f}%', '-blur', f'0x{0.8*U:.2f}', '-evaluate','Multiply',str(STAIN_ALPHA), w('stain.png'))
m('-size', f'{W}x{Hh}', f'xc:{YEL}', '(', '-size', f'{W}x{Hh}', f'xc:{AMBER}', w('stain.png'), '-alpha','off','-compose','CopyOpacity','-composite', ')',
  '-compose','Over','-composite', w('fill.png'))
m(w('fill.png'), w('mask.png'), '-alpha','off', '-compose','CopyOpacity','-composite', '-depth','8',
  '+set','date:create','+set','date:modify','+set','date:timestamp', OUT)
print(f'{W}x{Hh}; kept {100*mean(w("mask.png"))/mean(w("word.png")):.1f}% of the letter area; amber stain on {100*mean(w("stain.png"))/STAIN_ALPHA:.1f}% of the canvas')
