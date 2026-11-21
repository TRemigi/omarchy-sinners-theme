#!/usr/bin/env bash
# Regenerate Workspaces.qml: Omarchy's own workspaces widget, plus patches/0001-plate.patch.
#
#   ./build.sh           copy the installed widget and apply the patch (fails if the patch no longer fits)
#   ./build.sh --check   say whether the installed widget still matches what UPSTREAM records, and change nothing
#
# Workspaces.qml is generated and committed, so the plugin installs from this repo alone; never edit it by hand.
# Change the patch instead (edit a copy of the stock Workspaces.qml, then diff -u it back into patches/).
set -euo pipefail
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"
SRC="$OMARCHY_PATH/shell/plugins/bar/widgets"
[[ -f $SRC/Workspaces.qml ]] || { echo "build.sh: no stock workspaces widget at $SRC" >&2; exit 1; }

now_hashes() { (cd "$SRC" && sha256sum Workspaces.qml); }
version() { omarchy-version 2>/dev/null || cat "$OMARCHY_PATH/version" 2>/dev/null || echo unknown; }

if [[ ${1:-} == --check ]]; then
  if [[ -f UPSTREAM ]] && diff -q <(grep -E '^[0-9a-f]{64}  ' UPSTREAM) <(now_hashes) >/dev/null; then
    echo "Omarchy's workspaces widget is unchanged since this fork was built ($(sed -n 's/^omarchy //p' UPSTREAM))."
  else
    echo "Omarchy's workspaces widget has changed since this fork was built (now $(version)). Run ./build.sh and look at the plate." >&2
    exit 2
  fi
  exit 0
fi

cp "$SRC/Workspaces.qml" .
patch -p1 --quiet < patches/0001-plate.patch
{ echo "omarchy $(version)"; echo "# sha256 of the stock file Workspaces.qml was built from"; now_hashes; } > UPSTREAM
echo "Built Workspaces.qml from Omarchy $(version) with patches/0001-plate.patch."
