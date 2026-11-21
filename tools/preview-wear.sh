#!/bin/bash
# Renders the bar's worn-paint effect (plugins/sinners.bar/shaders/wear.frag) on software GL and writes a picture: the same
# line of lettering on a board, as the stock bar draws it (above) and through the effect (below), at 3x. For looking at the
# effect without a shell. It tests the shader, not the QML around it (WornPaint.qml), which only the real shell runs.
#
#   usage: tools/preview-wear.sh OUT.png
#          STRENGTH=0.85 how much of a flake's paint is gone (the plugin's default)
#          TEXT="..."    the lettering
#
# Needs qt6-shadertools (qsb), gcc with EGL and GLESv2 headers, and ImageMagick; and numpy and Pillow for the composite (see
# make-bar-wood.py for how to get them). It prints how much of the lettering the wear took.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
PLUGIN=$ROOT/plugins/sinners.bar
OUT=${1:?usage: preview-wear.sh OUT.png}
STRENGTH=${STRENGTH:-0.85}
TEXT=${TEXT:-Saturday 2:42 PM    foot: omarchy-sinners-theme}
PY=${PYTHON:-python3}
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

/usr/lib/qt6/bin/qsb -x "glsl,100 es" -o "$T/wear.gles" "$PLUGIN/shaders/wear.frag.qsb"
gcc -O2 "$ROOT/tools/shader-harness.c" -o "$T/harness" -lEGL -lGLESv2

# The lettering, 440 x 36 logical px as one section of the bar draws it, and the mask as the plugin ships it.
magick -size 440x36 xc:none -font /usr/share/fonts/noto/NotoSans-CondensedBlack.ttf -pointsize 13 -fill "#E8C48C" \
  -gravity West -annotate +8+0 "$TEXT" -depth 8 "$T/text.pam"
magick "$PLUGIN/wood/wear.png" -colorspace sRGB -type TrueColorAlpha -depth 8 "$T/mask.pam"

# Mesa's surfaceless platform runs without a display or a GPU.
EGL_PLATFORM=surfaceless LIBGL_ALWAYS_SOFTWARE=1 SOURCE="$T/text.pam" WEAR="$T/mask.pam" FLOATS="strength=$STRENGTH" \
  VEC2="size=440:36,offset=137:11" "$T/harness" "$T/wear.gles" 440 36 0 0 0 0 "$T/out.pam"

"$PY" -I - "$T" "$PLUGIN/wood/left-body.png" "$OUT" <<'PY'
import sys
import numpy as np
from PIL import Image

t, board_png, out = sys.argv[1:4]

def pam(path):
    b = open(path, "rb").read()
    i = b.index(b"ENDHDR\n") + 7
    h = dict(l.split() for l in b[:i].decode().splitlines()[1:-1] if " " in l)
    return np.frombuffer(b[i:], np.uint8).reshape(int(h["HEIGHT"]), int(h["WIDTH"]), 4).astype(np.float32) / 255

src, worn = pam(f"{t}/text.pam"), pam(f"{t}/out.pam")
ink = src[..., 3] > 0.6
lost = ink & (worn[..., 3] < 0.6 * src[..., 3])
print(f"lettering pixels: {int(ink.sum())}, mostly worn away: {int(lost.sum())} ({100 * lost.sum() / ink.sum():.1f}%)")

board = np.asarray(Image.open(board_png).convert("RGBA").crop((0, 0, 880, 72)).resize((440, 36), Image.LANCZOS), np.float32) / 255
stock = src.copy()
stock[..., :3] *= stock[..., 3:4]                       # the effect's output is premultiplied; so is the stock row, to match
rows = [f[..., :3] + board[..., :3] * (1 - f[..., 3:4]) for f in (stock, worn)]
im = np.concatenate(rows, 0)
Image.fromarray((np.clip(im, 0, 1) * 255).astype(np.uint8)).resize((440 * 3, 72 * 3), Image.NEAREST).save(out)
PY
echo "wrote $OUT"
