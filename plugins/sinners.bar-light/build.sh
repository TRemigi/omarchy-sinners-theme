#!/usr/bin/env bash
# Regenerate the light bar's generated files:
#   Bar.qml, BarModel.js   Omarchy's own bar, plus ../sinners.bar/patches/0001-boards.patch (the boards, shared with the dark bar) and
#                          this plugin's patches/0002-light.patch (the lettering colour)
#   WoodBoard.qml, WornPaint.qml, shaders/wear.frag(.qsb)   copies of the dark bar's, which are the one source of them
# The pictures in wood/ are drawn by tools/make-bar-wood.py, not by this script.
#
#   ./build.sh           copy the installed bar and the shared files and apply the patches (fails if a patch no longer fits)
#   ./build.sh --check   say whether the installed bar still matches what UPSTREAM records, and change nothing
#
# Everything this makes is committed, so the plugin installs from this repo alone; never edit it by hand. Change a patch, or the dark
# bar's file, instead.
set -euo pipefail
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"
SRC="$OMARCHY_PATH/shell/plugins/bar"
DARK=../sinners.bar
[[ -f $SRC/Bar.qml && -f $SRC/BarModel.js ]] || { echo "build.sh: no stock bar at $SRC" >&2; exit 1; }
[[ -f $DARK/patches/0001-boards.patch ]] || { echo "build.sh: no $DARK/patches/0001-boards.patch" >&2; exit 1; }

now_hashes() { (cd "$SRC" && sha256sum Bar.qml BarModel.js); }
version() { omarchy-version 2>/dev/null || cat "$OMARCHY_PATH/version" 2>/dev/null || echo unknown; }

if [[ ${1:-} == --check ]]; then
  if [[ -f UPSTREAM ]] && diff -q <(grep -E '^[0-9a-f]{64}  ' UPSTREAM) <(now_hashes) >/dev/null; then
    echo "Omarchy's bar is unchanged since this fork was built ($(sed -n 's/^omarchy //p' UPSTREAM))."
  else
    echo "Omarchy's bar has changed since this fork was built (now $(version)). Run ./build.sh and look at the boards." >&2
    exit 2
  fi
  exit 0
fi

cp "$SRC/Bar.qml" "$SRC/BarModel.js" .
patch -p1 --quiet < "$DARK/patches/0001-boards.patch"
patch -p1 --quiet < patches/0002-light.patch
cp "$DARK/WoodBoard.qml" "$DARK/WornPaint.qml" .
mkdir -p shaders
cp "$DARK/shaders/wear.frag" "$DARK/shaders/wear.frag.qsb" shaders/
{ echo "omarchy $(version)"; echo "# sha256 of the stock files Bar.qml was built from"; now_hashes; } > UPSTREAM
echo "Built Bar.qml from Omarchy $(version) with 0001-boards.patch and 0002-light.patch."
