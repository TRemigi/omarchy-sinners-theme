#!/bin/bash
# Checks hyprland.lua:
#   1. it is valid Lua (luac -p);
#   2. its border lines match hyprland_active_border and hyprland_inactive_border in colors.toml, written the way
#      Omarchy's template would write them, so the theme-shipped file cannot drift from the palette;
#   3. it runs against a stand-in for Hyprland's hl API and sets the settings it should.
# It cannot test what Hyprland does with the settings. After a change, run `hyprctl reload` and then
# `hyprctl configerrors`.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
LUA_FILE=$ROOT/hyprland.lua
fail() { echo "FAIL: $*" >&2; exit 1; }

command -v luac >/dev/null || fail "luac is not installed"
command -v lua >/dev/null || fail "lua is not installed"

luac -p "$LUA_FILE" || fail "hyprland.lua is not valid Lua"
echo "ok: valid Lua"

python3 -I - "$ROOT/colors.toml" "$LUA_FILE" <<'PY'
import re, sys
colors, lua = open(sys.argv[1]).read(), open(sys.argv[2]).read()

def key(name):
    m = re.search(rf'^{name}\s*=\s*"([^"]*)"', colors, re.M)
    return m.group(1) if m else None

def as_lua(spec):
    """What hypr_gradient writes in Omarchy's template: one colour is a string, several are a table."""
    parts = spec.split()
    angle = next((p[:-3] for p in parts if p.endswith('deg')), None)
    cols = [p for p in parts if not p.endswith('deg')]
    if len(cols) == 1:
        return f'"{cols[0]}"'
    inner = ", ".join(f'"{c}"' for c in cols)
    return "{ colors = { " + inner + " }" + (f", angle = {angle}" if angle else "") + " }"

bad = 0
for name, var in (("hyprland_active_border", "active_border_color"), ("hyprland_inactive_border", "inactive_border_color")):
    spec = key(name)
    if spec is None:
        print(f"skip: colors.toml has no {name}; Omarchy would use its default, hyprland.lua should not set {var}")
        continue
    want = f"local {var} = {as_lua(spec)}"
    if want in lua:
        print(f"ok: {var} matches colors.toml")
    else:
        got = re.search(rf"^local {var} = .*$", lua, re.M)
        print(f"FAIL: {var} differs from colors.toml\n   want: {want}\n   have: {got.group(0) if got else '(missing)'}", file=sys.stderr)
        bad = 1
sys.exit(bad)
PY

# Run the file against a stand-in for hl.config and report what it sets.
lua - "$LUA_FILE" <<'LUA'
local settings = {}
local function merge(into, from)
  for k, v in pairs(from) do
    if type(v) == "table" and type(into[k]) == "table" and v.colors == nil then merge(into[k], v) else into[k] = v end
  end
end
hl = { config = function(t) merge(settings, t) end }
dofile(arg[1])
local function need(cond, msg) if not cond then io.stderr:write("FAIL: " .. msg .. "\n"); os.exit(1) end end
need(settings.general and settings.general.col.active_border, "general.col.active_border is not set")
need(settings.general.col.inactive_border, "general.col.inactive_border is not set")
need(settings.group and settings.group.col.border_active, "group.col.border_active is not set")
local s = settings.decoration and settings.decoration.shadow
need(s, "decoration.shadow is not set")
need(s.enabled == true, "shadow is not enabled")
need(type(s.color) == "string" and s.color:match("^rgba%(%x%x%x%x%x%x%x%x%)$"), "shadow.color is not an rgba(RRGGBBAA) string")
need(s.color_inactive == "rgba(00000000)", "unfocused windows are not left without a shadow")
print(string.format("ok: runs; glow %s over %dpx, power %d; unfocused windows: none", s.color, s.range, s.render_power))
LUA
echo "all checks passed"
