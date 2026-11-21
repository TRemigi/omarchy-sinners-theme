#!/bin/bash
# Checks the one thing about the burn that must hold for every card: it finishes. At progress 1 nothing of the card
# may be left, and at progress 0 all of it must be there. Renders burn.frag over a solid card, for many seeds (the
# range Toast.qml makes: 1 to 11.7) and several card sizes, on software GL, and reads the alpha channel.
#
#   tools/check-burn-completes.sh            exits 1 if any seed and size leaves anything, or burns early
#   SIZES="508x85 380x78" SEEDS="1 2.5" tools/check-burn-completes.sh
#   SHADER=other.frag.qsb tools/check-burn-completes.sh   check a different compiled shader
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
SIZES=${SIZES:-"508x85 380x78 380x200 300x60"}
SEEDS=${SEEDS:-$(awk 'BEGIN{for (k = 0; k <= 96; k += 4) printf "%.3f ", 1 + k / 9}')}
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

SHADER=${SHADER:-$ROOT/plugins/sinners.notifications/shaders/burn.frag.qsb}     # a compiled burn.frag; for testing the check
/usr/lib/qt6/bin/qsb -x "glsl,100 es" -o "$T/burn.frag" "$SHADER"
gcc -O2 "$ROOT/tools/shader-harness.c" -o "$T/harness" -lEGL -lGLESv2

bad=0; runs=0
for size in $SIZES; do
  w=${size%x*}; h=${size#*x}
  magick -size "${w}x${h}" xc:white -alpha on -depth 8 "$T/card.pam"
  for seed in $SEEDS; do
    for p in 0 1; do
      EGL_PLATFORM=surfaceless LIBGL_ALWAYS_SOFTWARE=1 SOURCE="$T/card.pam" FLOATS="progress=$p" VEC2="cardSize=$w:$h" \
        "$T/harness" "$T/burn.frag" "$w" "$h" 0 "$seed" 0 0 "$T/out.pam" 2>/dev/null
      # the alpha channel's smallest and largest value, 0 to 255
      range=$(magick "$T/out.pam" -alpha extract -format '%[fx:int(255*minima)] %[fx:int(255*maxima)]' info:)
      lo=${range% *}; hi=${range#* }
      runs=$((runs + 1))
      if [[ $p == 1 && $hi -gt 0 ]]; then echo "FAIL: ${size} seed ${seed}: at progress 1 the card still has alpha up to $hi"; bad=1; fi
      if [[ $p == 0 && $lo -lt 250 ]]; then echo "FAIL: ${size} seed ${seed}: at progress 0 the card is already missing (alpha down to $lo)"; bad=1; fi
    done
  done
done
(( bad == 0 )) && echo "ok: $runs renders; every card is whole at progress 0 and gone at progress 1"
exit $bad
