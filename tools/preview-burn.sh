#!/bin/bash
# Renders the notification burn (burn.frag on a card, and ash.frag around it) on software GL and composites it over a
# background, as a contact sheet of several moments, for looking at the effect without a shell. It tests the shaders,
# not the QML around them in plugins/sinners.notifications.
#
#   usage: tools/preview-burn.sh OUT.png [SEED]
#          PROGRESS="0.1 0.3 0.5 0.7 0.9 1.2" the moments, as a share of the burn's length (above 1 = the ash tail)
#          DUR=2.6 and TAIL=1.0 are the burn's and the tail's length in seconds (the plugin's defaults)
#          CARD=card.png uses your own card (any size) instead of the mock one
#          BGIMG=patch.png is what is behind it; by default a patch of the wallpaper
#          VIS_LEFT, VIS_RIGHT, VIS_TOP, VIS_BOTTOM: how much of the room around the card is on screen (pixels). The
#            defaults show all of it; a toast at the top right of a screen has VIS_TOP=8 and VIS_RIGHT=0, and what
#            is off the screen is cut away, as it is for real.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
PLUGIN=$ROOT/plugins/sinners.notifications
OUT=${1:?usage: preview-burn.sh OUT.png [SEED]}
SEED=${2:-3}
DUR=${DUR:-2.6}; TAIL=${TAIL:-1.0}
PROGRESS=${PROGRESS:-0.1 0.3 0.5 0.7 0.9 1.2}
WALL=${WALLPAPER:-$ROOT/backgrounds/1-sinners-sun.webp}
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

MX=48; MT=64; MB=80                # room around the card for ash and smoke: sides, above, below (as in Toast.qml)

color() { omarchy-theme-color --file "$ROOT/colors.toml" "$1"; }
for layer in burn ash; do
  /usr/lib/qt6/bin/qsb -x "glsl,100 es" -o "$T/$layer.frag" "$PLUGIN/shaders/$layer.frag.qsb"
done
gcc -O2 "$ROOT/tools/shader-harness.c" -o "$T/harness" -lEGL -lGLESv2

# The card: yours, or a mock with rounded corners, a border, an icon, a title and two lines of body.
if [[ -n ${CARD:-} ]]; then
  magick "$CARD" -alpha on -depth 8 "$T/card.pam"
else
  BG=$(color lighter_background); FG=$(color foreground); DIM=$(color muted); ACC=$(color accent); BORDER=$(color selection)
  FONT=/usr/share/fonts/noto/NotoSans-Regular.ttf; FONTB=/usr/share/fonts/noto/NotoSans-Bold.ttf
  magick -size 380x78 xc:none -fill "$BORDER" -draw "roundrectangle 0,0 379,77 8,8" \
    -fill "$BG" -draw "roundrectangle 2,2 377,75 6,6" -fill "$ACC" -draw "circle 38,39 38,25" \
    -font "$FONTB" -pointsize 15 -fill "$FG" -annotate +68+30 "Build finished" \
    -font "$FONT" -pointsize 13 -fill "$DIM" -annotate +68+52 "omarchy-sinners-theme: all checks passed" \
    -font "$FONT" -pointsize 13 -fill "$DIM" -annotate +68+68 "3 files changed, 240 insertions" \
    -depth 8 "$T/card.pam"
fi
CW=$(magick identify -format %w "$T/card.pam"); CH=$(magick identify -format %h "$T/card.pam")
OW=$((CW + 2 * MX)); OH=$((CH + MT + MB))
VL=${VIS_LEFT:-$MX}; VR=${VIS_RIGHT:-$MX}; VT=${VIS_TOP:-$MT}; VB=${VIS_BOTTOM:-$MB}

# What is behind it, on a canvas the size of the whole overlay (black where nothing would be on screen).
if [[ -n ${BGIMG:-} ]]; then
  magick -size ${OW}x${OH} xc:black "$BGIMG" -geometry +$((MX - VL))+$((MT - VT)) -composite -alpha off -depth 8 "$T/bg.png"
else
  magick "$WALL" -resize 1920x1200^ -gravity center -extent 1920x1200 -alpha off -gravity NorthWest \
    -crop ${OW}x${OH}+1300+60 +repage "$T/bg.png"
fi

over() {   # over BASE LAYER.pam OUT [geometry]: premultiplied "over", with the layer at an offset
  magick "$1" \( "$2" -alpha extract -negate \) -geometry "${4:-+0+0}" -compose Multiply -composite \
         \( "$2" -alpha off \) -geometry "${4:-+0+0}" -compose Plus -composite -depth 8 "$3"
}
run() { EGL_PLATFORM=surfaceless LIBGL_ALWAYS_SOFTWARE=1 "$@" 2>/dev/null; }

frames=()
for p in $PROGRESS; do
  t=$(awk -v p="$p" -v d="$DUR" 'BEGIN{printf "%.4f", p*d}')
  q=$(awk -v p="$p" 'BEGIN{printf "%.4f", (p > 1 ? 1 : p)}')
  SOURCE="$T/card.pam" FLOATS="progress=$q" VEC2="cardSize=$CW:$CH" \
    run "$T/harness" "$T/burn.frag" $CW $CH 0 $SEED 0 0 "$T/burn.pam"
  FLOATS="t=$t,dur=$DUR,tail=$TAIL" VEC2="cardSize=$CW:$CH,origin=$MX:$MT,overlay=$OW:$OH" \
    run "$T/harness" "$T/ash.frag" $OW $OH 0 $SEED 0 0 "$T/ash.pam"
  over "$T/bg.png" "$T/burn.pam" "$T/f$p.png" "+$MX+$MT"
  over "$T/f$p.png" "$T/ash.pam" "$T/f$p.png"
  magick "$T/f$p.png" -crop "$((OW - (MX - VL) - (MX - VR)))x$((OH - (MT - VT) - (MB - VB)))+$((MX - VL))+$((MT - VT))" +repage \
    -fill white -pointsize 12 -gravity NorthWest -annotate +6+4 "$t s" "$T/f$p.png"
  frames+=("$T/f$p.png")
done
magick montage "${frames[@]}" -tile ${TILE:-2x} -geometry +4+4 -background '#000' "$OUT"
echo "wrote $OUT"
