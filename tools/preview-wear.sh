#!/bin/bash
# Renders the bar's chipped-paint effect (plugins/sinners.bar/shaders/wear.frag) on software GL and writes a picture: the same
# line of lettering on a board, as the shell draws it (above) and with the flakes over it (below), at 3x. For looking at the
# effect without a shell. It tests the shader, not the QML around it (WornPaint.qml), which only the real shell runs.
#
# The live bar layers three things, and so does this: the board, the lettering on it, and over both the flakes, which are the
# board's own picture kept only where the noise says. On bare board a flake changes nothing; over a letter it is a chip.
#
#   usage: tools/preview-wear.sh OUT.png
#          STRENGTH=0.7  how much of a flake is the board showing again (the plugin's default)
#          TEXT="..."    the lettering
#
# Needs qt6-shadertools (qsb), gcc with EGL and GLESv2 headers, and ImageMagick; and numpy and Pillow for the composite (see
# make-bar-wood.py for how to get them). It prints how much of the lettering the wear took.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
PLUGIN=$ROOT/plugins/sinners.bar
OUT=${1:?usage: preview-wear.sh OUT.png}
STRENGTH=${STRENGTH:-0.7}
TEXT=${TEXT:-Saturday 3:13 PM    gremlin: omarchy-sinners-theme}
PY=${PYTHON:-python3}
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

/usr/lib/qt6/bin/qsb -x "glsl,100 es" -o "$T/wear.gles" "$PLUGIN/shaders/wear.frag.qsb"
gcc -O2 "$ROOT/tools/shader-harness.c" -o "$T/harness" -lEGL -lGLESv2

# What the shader is given: the left board as WoodBoard.qml shows it, 440 x 36 logical px (its picture is 2x), as `source`.
magick "$PLUGIN/wood/left-body.png" -crop 880x72+0+0 +repage -resize 440x36! -alpha on -depth 8 "$T/board.pam"
# The lettering, centred on the board's rows, for the composite.
magick -size 440x36 xc:none -font /usr/share/fonts/noto/NotoSans-CondensedBlack.ttf -pointsize 13 -fill "#E8C48C" \
  -gravity West -annotate +8+0 "$TEXT" -depth 8 "$T/text.pam"

# Mesa's surfaceless platform runs without a display or a GPU.
EGL_PLATFORM=surfaceless LIBGL_ALWAYS_SOFTWARE=1 SOURCE="$T/board.pam" FLOATS="strength=$STRENGTH" \
  VEC2="size=440:36,offset=137:11" "$T/harness" "$T/wear.gles" 440 36 0 0 0 0 "$T/flakes.pam"

"$PY" -I - "$T" "$OUT" <<'PY'
import sys
import numpy as np
from PIL import Image

t, out = sys.argv[1:3]

def pam(path):
    b = open(path, "rb").read()
    i = b.index(b"ENDHDR\n") + 7
    h = dict(l.split() for l in b[:i].decode().splitlines()[1:-1] if " " in l)
    return np.frombuffer(b[i:], np.uint8).reshape(int(h["HEIGHT"]), int(h["WIDTH"]), 4).astype(np.float32) / 255

# text and board: straight alpha, exactly the pictures the shader was given; flakes: its output, premultiplied
text, board, flakes = pam(f"{t}/text.pam"), pam(f"{t}/board.pam"), pam(f"{t}/flakes.pam")

on_board = board[..., :3] * board[..., 3:4]
stock = text[..., :3] * text[..., 3:4] + on_board * (1 - text[..., 3:4])        # the lettering over the board
worn = flakes[..., :3] + stock * (1 - flakes[..., 3:4])                          # the flakes over both

ink = text[..., 3] > 0.6
chipped = ink & (np.abs(worn - stock).sum(-1) > 0.35)
print(f"lettering pixels: {int(ink.sum())}, chipped away: {int(chipped.sum())} ({100 * chipped.sum() / ink.sum():.1f}%)")
bare = ~ink & (text[..., 3] < 0.05)
print(f"bare board pixels the flakes change (should be about none): {int((bare & (np.abs(worn - stock).sum(-1) > 0.03)).sum())} of {int(bare.sum())}")

im = np.concatenate([stock, worn], 0)
Image.fromarray((np.clip(im, 0, 1) * 255).astype(np.uint8)).resize((440 * 3, 72 * 3), Image.NEAREST).save(out)
PY
echo "wrote $OUT"
