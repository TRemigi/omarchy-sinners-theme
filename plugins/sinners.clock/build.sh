#!/usr/bin/env bash
# Regenerate the clock's files: Omarchy's own clock widget (four files), plus patches/0001-gold.patch on BarWidget.qml.
#
#   ./build.sh           copy the installed widget and apply the patch (fails if the patch no longer fits)
#   ./build.sh --check   say whether the installed widget still matches what UPSTREAM records, and change nothing
#
# BarWidget.qml, Panel.qml, Model.js and WallClock.qml are generated and committed, so the plugin installs from this repo alone;
# never edit them by hand. Only BarWidget.qml is patched; the other three are Omarchy's, unchanged, because the widget loads its
# calendar popup and its model from beside itself. Change the patch instead (edit a copy of the stock BarWidget.qml, then diff -u
# it back into patches/).
set -euo pipefail
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"
SRC="$OMARCHY_PATH/shell/plugins/panels/clock"
FILES=(BarWidget.qml Panel.qml Model.js WallClock.qml)
for f in "${FILES[@]}"; do
  [[ -f $SRC/$f ]] || { echo "build.sh: no stock clock file $SRC/$f" >&2; exit 1; }
done

now_hashes() { (cd "$SRC" && sha256sum "${FILES[@]}"); }
version() { omarchy-version 2>/dev/null || cat "$OMARCHY_PATH/version" 2>/dev/null || echo unknown; }

if [[ ${1:-} == --check ]]; then
  if [[ -f UPSTREAM ]] && diff -q <(grep -E '^[0-9a-f]{64}  ' UPSTREAM) <(now_hashes) >/dev/null; then
    echo "Omarchy's clock widget is unchanged since this fork was built ($(sed -n 's/^omarchy //p' UPSTREAM))."
  else
    echo "Omarchy's clock widget has changed since this fork was built (now $(version)). Run ./build.sh and look at the clock." >&2
    exit 2
  fi
  exit 0
fi

for f in "${FILES[@]}"; do cp "$SRC/$f" .; done
patch -p1 --quiet < patches/0001-gold.patch
{ echo "omarchy $(version)"; echo "# sha256 of the stock files these were built from"; now_hashes; } > UPSTREAM
echo "Built the clock from Omarchy $(version) with patches/0001-gold.patch."
