#!/bin/bash
# Renders the ember shader on software GL and composites it over the wallpaper, the way the compositor does
# (a premultiplied "over": result = embers + wallpaper * (1 - alpha)). For looking at the shader without a
# compositor; it does not test the QML.
#
#   usage: tools/preview-embers.sh OUT.png [TIME] [WxH] [SEED] [INTENSITY] [DENSITY]
#          defaults: time 40 (seconds on the shader's clock), 1920x1200, seed 7, intensity 0.8, density 1
#          WALLPAPER=path overrides the wallpaper; NOWALL=1 renders the embers alone on black.
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

/usr/lib/qt6/bin/qsb -x "glsl,100 es" -o "$T/s.frag" "$PLUGIN/shaders/embers.frag.qsb"
gcc -O2 "$ROOT/tools/embers-harness.c" -o "$T/harness" -lEGL -lGLESv2

# The wallpaper as the desktop shows it: scaled to cover the screen, centered.
if [[ -z ${NOWALL:-} ]]; then
  magick "$WALL" -resize "${W}x${H}^" -gravity center -extent "${W}x${H}" -alpha off "$T/wall.png"
else
  magick -size "${W}x${H}" xc:black "$T/wall.png"
fi

frames=()
for tm in ${TIMES:-$TIME}; do
  EGL_PLATFORM=surfaceless LIBGL_ALWAYS_SOFTWARE=1 "$T/harness" "$T/s.frag" "$W" "$H" "$tm" "$SEED" "$INTEN" "$DENS" "$T/f$tm.pam"
  magick "$T/f$tm.pam" -alpha extract -negate "$T/inv.png"
  magick "$T/f$tm.pam" -alpha off "$T/rgb.png"
  magick "$T/wall.png" "$T/inv.png" -compose Multiply -composite "$T/rgb.png" -compose Plus -composite \
    -depth 8 "$T/out$tm.png"
  frames+=("$T/out$tm.png")
done
if (( ${#frames[@]} > 1 )); then magick "${frames[@]}" +append -resize 2400x "$OUT"; else magick "${frames[0]}" "$OUT"; fi
echo "wrote $OUT"
