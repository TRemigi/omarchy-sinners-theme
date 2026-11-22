#!/bin/bash
# Builds the unlock screen with the wallpaper's sun, drawn in square blocks like ASCII art, behind the title: Omarchy's ASCII
# wordmark (/usr/share/omarchy/logo.txt) given the poster title's treatment (neon lemon, amber stains, chipped edges; see
# lettering.py). The blocks are the size of the wordmark's pixels, and the sun keeps the wallpaper's place, size and colours:
#   unlock-sinners-sun.png, preview-unlock-sinners-sun.png
#   unlock-sinners-sun-plain.png, preview-unlock-sinners-sun-plain.png: the same screen without the title
#   backgrounds/0-sinners-pixel-sun.webp: the same picture as a 3840x2160 wallpaper on the theme's background colour, the
#     default one (Omarchy starts a theme on the first of its backgrounds). Its sun, title and blocks are the unlock screen's
#     scaled to the wallpaper, so on the screen this is built for, the unlock screen gives way to it without a jump.
#   backgrounds/2-sinners-pixel-sun-plain.webp: the same wallpaper without the title (it sorts after the farmhouse wallpaper,
#     so the default stays the one with the title)
# Both put the sun in the middle of the screen (--centre), not above it where the farmhouse wallpaper has it, so they match
# each other and not that wallpaper. tools/verify-sun.py checks the sun's size and colours against the farmhouse wallpaper.
#
#   usage: tools/make-unlock-sun.sh [WIDTHxHEIGHT]      the screen size; default 1920x1200 (hyprctl monitors)
#          SINNERS_SCREEN=2560x1600 tools/make-unlock-sun.sh
#
# Unlike the other unlock screens, this one is built for one screen size: the sun has to land on the wallpaper's
# sun, and the wallpaper is scaled to the screen while Plymouth draws the logo at its own pixel size. Rebuild it
# if the display changes. Takes about a minute: it renders the 4K sun layer. Needs ImageMagick and Python 3.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
STOCK=/usr/share/omarchy/themes/ristretto   # the lock icon and password field come from the stock preview
SCREEN=${1:-${SINNERS_SCREEN:-1920x1200}}
[[ $SCREEN =~ ^[0-9]+x[0-9]+$ ]] || { echo "screen size must look like 1920x1200, got '$SCREEN'" >&2; exit 1; }
SW=${SCREEN%x*}; SH=${SCREEN#*x}
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

BG=$(omarchy-theme-color --file "$ROOT/colors.toml" background)
FG=$(omarchy-theme-color --file "$ROOT/colors.toml" foreground)

# The title's ink spans TITLE_RATIO of the sun's width. On the poster that is 0.92: the title's strokes run 1312px
# across a sun 1424px wide, leaving 2.5% to the rim on the left and 4.4% on the right. This is the width of the
# ink, not of the title image, which carries padding (an earlier version of this script measured the image, and
# built a title that was really 0.88). The sun scales with the screen, so the title is sized from it: a first guess
# at the pointsize, then one correction from the measured ink.
TITLE_RATIO=0.985
SUN_R=$(sed -n 's/.*; R=\([0-9]*\)$/\1/p' "$ROOT/tools/make-wallpaper.sh" | head -1)
SCALE=$(awk -v w="$SW" -v h="$SH" 'BEGIN{a=w/3840; b=h/2160; print (a>b?a:b)}')
TARGET=$(awk -v r="$SUN_R" -v s="$SCALE" -v ratio="$TITLE_RATIO" 'BEGIN{printf "%d", ratio*2*r*s+0.5}')
ink_width() { magick "$1" -trim +repage -format %w info:; }
PT=$(awk -v t="$TARGET" 'BEGIN{printf "%d", t/5.0+0.5}')
WORDMARK=/usr/share/omarchy/logo.txt
python3 -I "$ROOT/tools/lettering.py" "$T/title.png" "$T/lettering" OMARCHY "$PT" --wordmark "$WORDMARK" >/dev/null
PT=$(awk -v p="$PT" -v t="$TARGET" -v w="$(ink_width "$T/title.png")" 'BEGIN{printf "%d", p*t/w+0.5}')
python3 -I "$ROOT/tools/lettering.py" "$T/title.png" "$T/lettering" OMARCHY "$PT" --wordmark "$WORDMARK" >/dev/null
echo "title: pointsize $PT, ink $(ink_width "$T/title.png")px wide (target $TARGET); the sun is $(awk -v r="$SUN_R" -v s="$SCALE" 'BEGIN{printf "%d", 2*r*s+0.5}')px"
# The disc is drawn in square blocks the size of the wordmark's pixels (a column of the art is PT/16.6 px; see lettering.py).
PIXEL=$(awk -v p="$PT" 'BEGIN{printf "%d", p/16.6+0.5}')
"$ROOT/tools/make-wallpaper.sh" "$T/layer.png" --sun-layer >/dev/null   # the 4K sun layer, shared by both builds below
python3 -I "$ROOT/tools/sun-unlock.py" --screen "$SCREEN" --layer "$T/layer.png" --word "$T/title.png" --pixel "$PIXEL" --centre \
  --out "$ROOT/unlock-sinners-sun.png" --out-plain "$ROOT/unlock-sinners-sun-plain.png"

# Wallpaper: the same build on the full 3840x2160 wallpaper canvas. Everything sized in screen pixels above is divided by the
# screen's scale (the wallpaper is shown at SCALE of its size), so it comes back to the unlock screen's size on that screen.
PT4K=$(awk -v p="$PT" -v s="$SCALE" 'BEGIN{printf "%d", p/s+0.5}')
python3 -I "$ROOT/tools/lettering.py" "$T/title4k.png" "$T/lettering4k" OMARCHY "$PT4K" --wordmark "$WORDMARK" >/dev/null
python3 -I "$ROOT/tools/sun-unlock.py" --screen 3840x2160 --canvas 3840x2160 --layer "$T/layer.png" --word "$T/title4k.png" --centre \
  --pixel "$(awk -v p="$PIXEL" -v s="$SCALE" 'BEGIN{print p/s}')" --ellipse-x "$(awk -v s="$SCALE" 'BEGIN{print 640/s}')" \
  --ember-scale "$(awk -v s="$SCALE" 'BEGIN{print 1/s}')" --out "$T/wall.png" --out-plain "$T/wall-plain.png" >/dev/null
magick -size 3840x2160 "xc:$BG" "$T/wall.png" -compose Over -composite -define webp:lossless=true "$ROOT/backgrounds/0-sinners-pixel-sun.webp"
magick -size 3840x2160 "xc:$BG" "$T/wall-plain.png" -compose Over -composite -define webp:lossless=true "$ROOT/backgrounds/2-sinners-pixel-sun-plain.webp"

# Preview: the screen as Plymouth draws it (logo centered, password field 40px below it), fitted into the 1920x1080
# frame the other previews use so the theme switcher shows them alike.
CW=$(magick identify -format %w "$ROOT/unlock-sinners-sun.png"); CH=$(magick identify -format %h "$ROOT/unlock-sinners-sun.png")
X0=$(( (SW - CW) / 2 )); Y0=$(( (SH - CH) / 2 ))
magick -size 256x1 gradient:"$BG-$FG" "$T/ramp.png"
magick "$STOCK/preview-unlock.png" -crop 360x60+750+665 +repage -depth 8 -colorspace Gray \
  -level 15%,86% "$T/ramp.png" -clut "$T/lockfield.png"
for name in sinners-sun sinners-sun-plain; do
  magick -size "${SW}x${SH}" "xc:$BG" \
    "$ROOT/unlock-$name.png" -geometry "+$X0+$Y0" -composite \
    "$T/lockfield.png" -geometry "+$(( 750 + (SW - 1920) / 2 ))+$(( Y0 + CH + 40 - 9 ))" -composite \
    -resize 1920x1080 -background "$BG" -gravity center -extent 1920x1080 \
    -depth 8 +set date:create +set date:modify +set date:timestamp "$ROOT/preview-unlock-$name.png"
done
echo "wrote unlock-sinners-sun{,-plain}.png, their previews and backgrounds/{0-sinners-pixel-sun,2-sinners-pixel-sun-plain}.webp for a ${SCREEN} screen"
