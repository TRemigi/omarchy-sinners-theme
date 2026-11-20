#!/bin/bash
# Builds the disk-unlock (Plymouth) images for the Sinners theme, each with a switcher preview:
#   unlock.png        the default: Omarchy's stock wordmark filled with the sun gradient
#   unlock-embers.png alternate: that wordmark with a red halo and rising pixel embers
#   unlock-eyes.png   alternate: glowing red eyes over a dimmed wordmark
# The previews reuse the stock preview's lock icon and password field, recolored from colors.toml.
# Omarchy reads unlock.png; the alternates are opt-in (see the README). Needs ImageMagick.
#
# usage: tools/make-unlock.sh   (run from anywhere; writes into the theme root)
set -euo pipefail

STOCK=/usr/share/omarchy/themes/ristretto   # any stock theme works: the files are identical
ROOT=$(cd "$(dirname "$0")/.." && pwd)
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

BG=$(omarchy-theme-color --file "$ROOT/colors.toml" background)
FG=$(omarchy-theme-color --file "$ROOT/colors.toml" foreground)

# Wordmark: sun gradient, gold -> orange -> red, through the stock letters' alpha
magick \( -size 800x94 gradient:'#F9BD06-#FB7407' \) \( -size 800x94 gradient:'#FB7407-#E91A02' \) -append +repage "$T/grad.png"
magick "$STOCK/unlock.png" -alpha extract -alpha off +repage "$T/mask.png"
magick "$T/grad.png" "$T/mask.png" -compose CopyOpacity -composite +repage -depth 8 +set date:create +set date:modify +set date:timestamp "$ROOT/unlock.png"

# Preview: lock icon + password field from the stock preview, mapped from its colors to ours.
# The stock preview is #2c2525 background and #e6d9db foreground, so gray levels map to a
# background -> foreground ramp.
magick -size 256x1 gradient:"$BG-$FG" "$T/ramp.png"
magick "$STOCK/preview-unlock.png" -crop 360x60+750+665 +repage -depth 8 -colorspace Gray \
  -level 15%,86% "$T/ramp.png" -clut "$T/lockfield.png"
magick -size 1920x1080 "xc:$BG" \
  "$ROOT/unlock.png" -geometry +560+446 -composite \
  "$T/lockfield.png" -geometry +750+665 -composite \
  -depth 8 +set date:create +set date:modify +set date:timestamp "$ROOT/preview-unlock.png"

# Embers variant: an alternate logo for the same Omarchy contract (see tools/embers.py).
# Its canvas is taller, so Plymouth puts the password field lower: logo centered vertically,
# field 40px below the logo's bottom edge. The preview follows the same rule.
EMBERS_H=408
python3 -I "$ROOT/tools/embers.py" "$ROOT/unlock.png" "$ROOT/unlock-embers.png"
LOGO_Y=$(( (1080 - EMBERS_H) / 2 ))
FIELD_Y=$(( LOGO_Y + EMBERS_H + 40 - 9 ))   # the lock/field crop starts 9px above the field
magick -size 1920x1080 "xc:$BG" \
  "$ROOT/unlock-embers.png" -geometry +460+$LOGO_Y -composite \
  "$T/lockfield.png" -geometry +750+$FIELD_Y -composite \
  -depth 8 +set date:create +set date:modify +set date:timestamp "$ROOT/preview-unlock-embers.png"

# Eyes variant: glowing red eyes over a dimmed wordmark (see tools/eyes.py). 800x400 canvas.
EYES_W=800; EYES_H=400
python3 -I "$ROOT/tools/eyes.py" "$STOCK/unlock.png" "$ROOT/unlock-eyes.png"
magick -size 1920x1080 "xc:$BG" \
  "$ROOT/unlock-eyes.png" -geometry +$(( (1920 - EYES_W) / 2 ))+$(( (1080 - EYES_H) / 2 )) -composite \
  "$T/lockfield.png" -geometry +750+$(( (1080 - EYES_H) / 2 + EYES_H + 40 - 9 )) -composite \
  -depth 8 +set date:create +set date:modify +set date:timestamp "$ROOT/preview-unlock-eyes.png"

echo "wrote unlock{,-embers,-eyes}.png and preview-unlock{,-embers,-eyes}.png in $ROOT (bg $BG, fg $FG)"
