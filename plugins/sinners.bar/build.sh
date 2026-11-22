#!/usr/bin/env bash
# Regenerate Bar.qml and BarModel.js: Omarchy's own bar, plus patches/0001-boards.patch.
#
#   ./build.sh           copy the installed bar and apply the patch (fails if the patch no longer fits)
#   ./build.sh --check   say whether the installed bar still matches what UPSTREAM records, and change nothing
#
# Bar.qml is generated and committed, so the plugin installs from this repo alone; never edit it by hand.
# Change the patch instead (edit a copy of the stock Bar.qml, then diff -u it back into patches/).
set -euo pipefail
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"
SRC="$OMARCHY_PATH/shell/plugins/bar"
[[ -f $SRC/Bar.qml && -f $SRC/BarModel.js ]] || { echo "build.sh: no stock bar at $SRC" >&2; exit 1; }

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
patch -p1 --quiet < patches/0001-boards.patch
{ echo "omarchy $(version)"; echo "# sha256 of the stock files Bar.qml was built from"; now_hashes; } > UPSTREAM
echo "Built Bar.qml from Omarchy $(version) with patches/0001-boards.patch."
