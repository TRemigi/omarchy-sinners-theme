#!/bin/bash
# Renders the smoke and ember shaders on software GL and composites them over the wallpaper, the way the compositor
# does (a premultiplied "over": result = layer + wallpaper * (1 - alpha)), smoke first and embers on top. The smoke
# is rendered at 40% size and scaled up, as the plugin does. For looking at the shaders without a compositor; it
# does not test the QML.
#
#   usage: tools/preview-embers.sh OUT.png [TIME] [WxH] [SEED] [INTENSITY] [DENSITY]
#          defaults: time 40 (seconds on the shader's clock), 1920x1200, seed 7, intensity 0.8, density 1
#          WALLPAPER=path overrides the wallpaper; NOWALL=1 renders on black.
#          LAYERS="smoke embers" chooses what is drawn (default both); AMOUNT=0.32 is the smoke's strength.
#          TIMES="10 20 30" renders a contact sheet of several moments side by side instead of one frame.
#          FRAMES=30 also prints the time one draw takes (llvmpipe, so not GPU timings).
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
PLUGIN=$ROOT/plugins/sinners.embers
OUT=${1:?usage: preview-embers.sh OUT.png [TIME] [WxH] [SEED] [INTENSITY] [DENSITY]}
TIME=${2:-40}; SIZE=${3:-1920x1200}; SEED=${4:-7}; INTEN=${5:-0.8}; DENS=${6:-1}
W=${SIZE%x*}; H=${SIZE#*x}
WALL=${WALLPAPER:-$ROOT/backgrounds/1-sinners-sun.webp}
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

LAYERS=${LAYERS:-smoke embers}
for layer in $LAYERS; do
  [[ $layer == smoke || $layer == embers ]] || { echo "LAYERS may name smoke and embers, not '$layer'" >&2; exit 1; }
  /usr/lib/qt6/bin/qsb -x "glsl,100 es" -o "$T/$layer.frag" "$PLUGIN/shaders/$layer.frag.qsb"
done
gcc -O2 "$ROOT/tools/embers-harness.c" -o "$T/harness" -lEGL -lGLESv2

# The wallpaper as the desktop shows it: scaled to cover the screen, centered.
if [[ -z ${NOWALL:-} ]]; then
  magick "$WALL" -resize "${W}x${H}^" -gravity center -extent "${W}x${H}" -alpha off "$T/wall.png"
else
  magick -size "${W}x${H}" xc:black "$T/wall.png"
fi

frames=()
for tm in ${TIMES:-$TIME}; do
  cp "$T/wall.png" "$T/out$tm.png"
  for layer in $LAYERS; do
    if [[ $layer == smoke ]]; then SW=$(( W * 4 / 10 )); SH=$(( H * 4 / 10 )); else SW=$W; SH=$H; fi
    EGL_PLATFORM=surfaceless LIBGL_ALWAYS_SOFTWARE=1 "$T/harness" "$T/$layer.frag" "$SW" "$SH" "$tm" "$SEED" "$INTEN" "$DENS" "$T/$layer.pam"
    # to the screen's size (bilinear, as the plugin's layer is), then: wallpaper * (1 - alpha) + colour
    magick "$T/$layer.pam" -filter Triangle -resize "${W}x${H}!" "$T/$layer-big.pam"
    magick "$T/$layer-big.pam" -alpha extract -negate "$T/inv.png"
    magick "$T/$layer-big.pam" -alpha off "$T/rgb.png"
    magick "$T/out$tm.png" "$T/inv.png" -compose Multiply -composite "$T/rgb.png" -compose Plus -composite \
      -depth 8 "$T/out$tm.png"
  done
  frames+=("$T/out$tm.png")
done
if (( ${#frames[@]} > 1 )); then magick "${frames[@]}" +append -resize 2400x "$OUT"; else magick "${frames[0]}" "$OUT"; fi
echo "wrote $OUT"
