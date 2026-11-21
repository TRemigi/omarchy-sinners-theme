#!/bin/bash

# Compile shaders/*.frag to the .qsb files the plugin loads. The compiled files are committed, so installing the
# plugin does not need qt6-shadertools (which provides qsb).
#
# burn.frag and ash.frag each carry a copy of the fire's arrival field (between the SHARED markers): the ash and the
# light must be where the fire really is. burn.frag is the source; this copies its block into ash.frag first, so the
# two cannot differ. Edit the block in burn.frag only.

set -euo pipefail

cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/shaders"
QSB=${QSB:-/usr/lib/qt6/bin/qsb}

python3 -I - <<'PY'
def block(text):
    return text.index('// ==== BEGIN SHARED'), text.index('// ==== END SHARED')
burn, ash = open('burn.frag').read(), open('ash.frag').read()
a, b = block(burn)
c, d = block(ash)
if burn[a:b] != ash[c:d]:
    open('ash.frag', 'w').write(ash[:c] + burn[a:b] + ash[d:])
    print("build-shaders: copied the SHARED block from burn.frag into ash.frag")
PY

for src in *.frag; do
  "$QSB" --glsl "100 es,120,150" --hlsl 50 --msl 12 -o "$src.qsb" "$src"
  echo "built shaders/$src.qsb"
done
