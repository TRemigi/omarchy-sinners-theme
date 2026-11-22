#!/bin/bash
# Checks the settings plugin (plugins/sinners.settings) as far as it can be checked without a running shell:
#   1. Catalog.js, which decides what the panel shows and what Save does, under node;
#   2. bin/sinners-settings, which does everything to the system, against a copy of a shell.json and stand-ins for `omarchy` and
#      `omarchy-shell`, so nothing real is read, written or restarted;
#   3. the manifest, with `omarchy plugin validate`;
#   4. the QML, for syntax errors, with Qt 6's qmllint (skipped if it is not installed).
# It cannot test how the panel looks or behaves in the shell: that needs the shell itself. `tools/check-settings.sh --render` also
# starts a throwaway quickshell on Qt's offscreen platform, puts the panel's body on screen with the real helper behind it (still against
# the copies) and writes a picture of each tab to the directory it prints.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
PLUGIN=$ROOT/plugins/sinners.settings
HELPER=$PLUGIN/bin/sinners-settings
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
fails=0

fail() { echo "FAIL: $*" >&2; fails=$((fails + 1)); }
ok() { echo "ok:   $*"; }
check() { # check <description> <command...>
  local what=$1
  shift
  if "$@" >/dev/null 2>&1; then ok "$what"; else fail "$what"; fi
}
equals() { # equals <description> <expected> <actual>
  if [[ $2 == "$3" ]]; then ok "$1"; else fail "$1: expected '$2', got '$3'"; fi
}

command -v jq >/dev/null || { echo "jq is needed" >&2; exit 1; }

# --- 1. Catalog.js ---------------------------------------------------------------------------------------------------------
if command -v node >/dev/null; then
  if node - "$PLUGIN/Catalog.js" <<'JS'
const C = require(process.argv[2])
const assert = require("assert")
const status = { bar: { id: "sinners.bar", position: "top", background: "opaque" }, plugins: {
  "sinners.bar": { present: true, enabled: true, settings: {} }, "sinners.bar-light": { present: true, enabled: false, settings: {} },
  "sinners.clock": { present: true, enabled: true, settings: { format: "HH:mm" } },
  "sinners.embers": { present: true, enabled: false, settings: {} },
  "sinners.notifications": { present: false, enabled: false, settings: {} } } }

// states
assert.strictEqual(C.stateOf(status, "sinners.clock"), "on")
assert.strictEqual(C.stateOf(status, "sinners.embers"), "off")
assert.strictEqual(C.stateOf(status, "sinners.notifications"), "missing")
assert.strictEqual(C.stateOf(status, "sinners.workspaces"), "missing")

// staging: a change asked for twice, or undone, leaves nothing staged
let s = C.stagePlugin(status, undefined, "sinners.embers", true)
assert.deepStrictEqual(s.plugins, { "sinners.embers": true })
assert.ok(C.isEmpty(C.stagePlugin(status, s, "sinners.embers", false)))
assert.ok(C.isEmpty(C.stagePlugin(status, undefined, "sinners.clock", true)))
assert.ok(C.isEmpty(C.stageBar(status, undefined, "sinners.bar")))
assert.strictEqual(C.stageBar(status, undefined, "sinners.bar-light").bar, "sinners.bar-light")
assert.strictEqual(C.stageBar(status, undefined, "omarchy.bar").bar, "omarchy.bar")

// the plan: off before on, the bar last
s = C.stagePlugin(status, undefined, "sinners.notifications", true)
s = C.stagePlugin(status, s, "sinners.clock", false)
s = C.stageBar(status, s, "sinners.bar-light")
assert.deepStrictEqual(C.planOps(status, s), [
  { type: "disable", id: "sinners.clock" }, { type: "enable", id: "sinners.notifications" }, { type: "bar", id: "sinners.bar-light" }])
assert.deepStrictEqual(C.describeChanges(status, s), [
  "Install and turn on Sinners Notifications", "Turn off Sinners Clock", "Use light boards for the bar"])
assert.strictEqual(C.wantedState(status, s, "sinners.bar"), "off")
assert.strictEqual(C.wantedState(status, s, "sinners.bar-light"), "on")
assert.strictEqual(C.wantedState(status, s, "sinners.notifications"), "on")

// values: defaults are removed from the file rather than written into it, and sliders write tidy numbers
const smoke = C.CONTROLS.embers.find(c => c.key === "smoke")
assert.strictEqual(C.valueToWrite(smoke, 0.32), null)
assert.strictEqual(C.valueToWrite(smoke, 0.35000000000000003), 0.35)
assert.strictEqual(C.valueToWrite(smoke, 7), 1)
assert.strictEqual(C.valueOf(smoke, {}), 0.32)
assert.strictEqual(C.valueOf(smoke, { smoke: 0.5 }), 0.5)
const fps = C.CONTROLS.embers.find(c => c.key === "fpsCap")
assert.strictEqual(C.valueToWrite(fps, 33), 35)
const burn = C.CONTROLS.notifications.find(c => c.key === "burn")
assert.strictEqual(C.valueOf(burn, { burn: false }), false)
assert.strictEqual(C.valueOf(burn, {}), true)
const birth = C.CONTROLS.clock.find(c => c.key === "birthYear")
assert.strictEqual(C.valueToWrite(birth, 0), null)
assert.strictEqual(C.valueToWrite(birth, 1990), 1990)
assert.strictEqual(C.enabledBy(C.CONTROLS.clock.find(c => c.key === "lifeExpectancy"), {}), false)
assert.strictEqual(C.enabledBy(C.CONTROLS.clock.find(c => c.key === "lifeExpectancy"), { birthYear: 1990 }), true)
assert.strictEqual(C.enabledBy(C.CONTROLS.notifications.find(c => c.key === "burnSeconds"), { burn: false }), false)

// every control belongs to a tab, with the fields its type needs, and a default that is inside its own range
const tabs = C.TABS.map(t => t.id)
for (const id of Object.keys(C.CONTROLS)) assert.ok(tabs.includes(id), "controls for unknown tab " + id)
for (const tab of C.TABS) for (const c of C.controlsFor(tab.id)) {
  assert.ok(["plugin", "widget", "bar"].includes(c.scope), c.key + " scope")
  assert.ok(["toggle", "slider", "choice", "format", "number"].includes(c.type), c.key + " type")
  if (c.type === "slider" || c.type === "number") {
    assert.ok(c.min <= c.max && c.step > 0, c.key + " range")
    assert.ok(c.def >= c.min && c.def <= c.max, c.key + " default is out of range")
  }
  if (c.type === "choice") assert.ok(c.options.some(o => o.value === c.def), c.key + " default is not an option")
}
for (const tab of C.TABS) for (const id of tab.plugins) assert.ok(C.PLUGIN_INFO[id], id + " has no name")

// reset: only what is not at its default
const clockTab = C.TABS.find(t => t.id === "clock"), embersTab = C.TABS.find(t => t.id === "embers"), barTab = C.TABS.find(t => t.id === "bar")
const named = (st, tab) => C.changedControls(st, tab).map(c => c.key)
assert.deepStrictEqual(named(status, clockTab), ["format"])
assert.deepStrictEqual(named(status, embersTab), [])
status.plugins["sinners.embers"].settings = { smoke: 0.5, intensity: 0.8, embers: false }
assert.deepStrictEqual(named(status, embersTab), ["embers", "smoke"])
assert.deepStrictEqual(named(status, barTab), [])
status.bar.position = "left"
assert.deepStrictEqual(named(status, barTab), ["position"])
for (const c of C.changedControls(status, embersTab)) assert.strictEqual(C.writeFor(c, embersTab, c.def).value, null)
assert.deepStrictEqual(C.writeFor(C.CONTROLS.bar[0], barTab, C.CONTROLS.bar[0].def), { kind: "bar-position", value: "top" })

// writes
assert.deepStrictEqual(C.writeFor(C.CONTROLS.clock[0], C.TABS[2], "HH:mm"), { kind: "widget", id: "sinners.clock", key: "format", value: "HH:mm" })
assert.deepStrictEqual(C.writeFor(C.CONTROLS.bar[0], C.TABS[0], "bottom"), { kind: "bar-position", value: "bottom" })
assert.strictEqual(C.isoWeek(new Date(2026, 10, 21)), 47)
assert.strictEqual(C.isoWeek(new Date(2021, 0, 3)), 53)
JS
  then ok "Catalog.js"; else fail "Catalog.js"; fi
else
  echo "skip: node is not installed, so Catalog.js was not tested"
fi

# --- 2. the helper ---------------------------------------------------------------------------------------------------------
BIN=$WORK/bin; STATE=$WORK/state; PLUGINS=$WORK/plugins; CFG=$WORK/shell.json; LOG=$WORK/calls.log
mkdir -p "$BIN" "$STATE" "$PLUGINS"
echo sinners >"$WORK/theme.name"
for id in sinners.bar sinners.bar-light sinners.clock sinners.embers sinners.settings; do ln -s "$ROOT/plugins/$id" "$PLUGINS/$id"; done

cat >"$CFG" <<'JSON'
{
  "bar": {
    "id": "sinners.bar", "position": "top",
    "layout": {
      "left": [{ "id": "omarchy.menu" }],
      "center": [{ "id": "sinners.clock", "format": "dddd h:mm AP", "formatAlt": "d MMMM", "verticalFormat": "h" }],
      "right": [{ "id": "omarchy.tray" }], "tray": []
    }
  },
  "disabledPlugins": ["omarchy.notifications"],
  "plugins": [{ "id": "vocon" }, { "id": "sinners.embers", "smoke": 0.5 }],
  "version": 1
}
JSON
chmod 600 "$CFG"

# Stand-ins that record what they were asked and answer as a shell would. A failure is staged by naming the id in $FAIL_ON.
cat >"$BIN/omarchy" <<STUB
#!/bin/bash
echo "omarchy \$*" >>"$LOG"
[[ -n \${FAIL_ON:-} && "\$*" == *"\$FAIL_ON"* ]] && { echo "refused: \$FAIL_ON is in the way" >&2; exit 1; }
exit 0
STUB
cat >"$BIN/omarchy-shell" <<STUB
#!/bin/bash
echo "omarchy-shell \$*" >>"$LOG"
case "\$*" in
  "shell ping") echo ok ;;
  "shell listPlugins") echo '[{"id":"sinners.clock","enabled":true,"kinds":["bar-widget"]},{"id":"sinners.embers","enabled":false,"kinds":["service"]},{"id":"sinners.bar","enabled":true,"kinds":["bar"]}]' ;;
esac
STUB
chmod +x "$BIN/omarchy" "$BIN/omarchy-shell"

helper() {
  PATH="$BIN:$PATH" SINNERS_SHELL_JSON=$CFG SINNERS_PLUGINS_DIR=$PLUGINS SINNERS_STATE_DIR=$STATE SINNERS_THEME_STATE=$WORK/theme.name SINNERS_NO_NOTIFY=1 "$HELPER" "$@"
}

# status, with the shell not asked (what is read from shell.json alone)
st=$(SINNERS_NO_SHELL=1 helper status)
equals "status: the bar in use" sinners.bar "$(jq -r .bar.id <<<"$st")"
equals "status: the theme is active" true "$(jq -r .themeActive <<<"$st")"
equals "status: a linked plugin is present" true "$(jq -r '.plugins["sinners.clock"].present' <<<"$st")"
equals "status: a plugin never linked is not" false "$(jq -r '.plugins["sinners.workspaces"].present' <<<"$st")"
equals "status: a widget on the bar is enabled" true "$(jq -r '.plugins["sinners.clock"].enabled' <<<"$st")"
equals "status: a plugin in plugins[] is enabled" true "$(jq -r '.plugins["sinners.embers"].enabled' <<<"$st")"
equals "status: the settings plugin, not on the bar, is not" false "$(jq -r '.plugins["sinners.settings"].enabled' <<<"$st")"
equals "status: a widget's settings, without its id" '{"format":"dddd h:mm AP","formatAlt":"d MMMM","verticalFormat":"h"}' "$(jq -c '.plugins["sinners.clock"].settings' <<<"$st")"
equals "status: a plugin's settings" '{"smoke":0.5}' "$(jq -c '.plugins["sinners.embers"].settings' <<<"$st")"
# and from the running shell, which is the better source
st=$(helper status)
equals "status: the shell's own word for enabled" false "$(jq -r '.plugins["sinners.embers"].enabled' <<<"$st")"
equals "status: the shell is running" true "$(jq -r .shellRunning <<<"$st")"

# batch
: >"$LOG"
helper batch '[{"kind":"plugin","id":"sinners.embers","key":"smoke","value":0.7},{"kind":"widget","id":"sinners.clock","key":"format","value":"HH:mm"},{"kind":"widget","id":"sinners.clock","key":"formatAlt","value":null}]'
equals "batch: a plugin field is written" 0.7 "$(jq '.plugins[] | select(.id == "sinners.embers") | .smoke' "$CFG")"
equals "batch: a widget field is written" HH:mm "$(jq -r '.bar.layout.center[0].format' "$CFG")"
equals "batch: null removes the field" null "$(jq '.bar.layout.center[0].formatAlt' "$CFG")"
equals "batch: other fields are left alone" h "$(jq -r '.bar.layout.center[0].verticalFormat' "$CFG")"
equals "batch: other plugins are left alone" '{"id":"vocon"}' "$(jq -c '.plugins[0]' "$CFG")"
equals "batch: the file keeps its mode" 600 "$(stat -c %a "$CFG")"
check "batch: the running shell is told to read it again" grep -q "shell reloadConfig" "$LOG"
before=$(cat "$CFG")
if helper batch '[{"kind":"plugin","id":"sinners.notifications","key":"burn","value":false}]' 2>/dev/null; then fail "batch: a plugin with no entry was written to"; else ok "batch: a plugin with no entry is refused"; fi
if helper batch '[{"kind":"plugin","id":"vocon","key":"x","value":1}]' 2>/dev/null; then fail "batch: a plugin that is not ours was written to"; else ok "batch: a plugin that is not ours is refused"; fi
if helper batch '[{"kind":"plugin","id":"sinners.embers","key":"a b","value":1}]' 2>/dev/null; then fail "batch: a bad key was written"; else ok "batch: a bad key is refused"; fi
if helper batch '[{"kind":"bar-position","value":"sideways"}]' 2>/dev/null; then fail "batch: a bad position was passed on"; else ok "batch: a bad position is refused"; fi
equals "batch: a refused write changes nothing" "$before" "$(cat "$CFG")"
: >"$LOG"
helper batch '[{"kind":"bar-position","value":"bottom"},{"kind":"bar-background","value":"glassy"}]'
check "batch: the bar's position goes through omarchy" grep -qx "omarchy bar position bottom" "$LOG"
check "batch: the bar's background goes through omarchy" grep -qx "omarchy bar background glassy" "$LOG"

# apply: a dry run says what it would do, in order, and does nothing
plan='{"ops":[{"type":"disable","id":"sinners.clock"},{"type":"enable","id":"sinners.embers"},{"type":"bar","id":"sinners.bar-light"},{"type":"enable","id":"sinners.settings"}]}'
: >"$LOG"
out=$(SINNERS_DRY_RUN=1 helper apply --json "$plan")
equals "apply (dry run): the commands, in order, then the restart" \
  "omarchy plugin disable sinners.clock|omarchy plugin enable sinners.embers|omarchy bar use sinners.bar-light|omarchy plugin enable sinners.settings --section tray|omarchy restart shell" \
  "$(sed 's/^would run: //' <<<"$out" | paste -sd'|')"
equals "apply (dry run): nothing was run" 0 "$(grep -c '^omarchy ' "$LOG" || true)"
if SINNERS_DRY_RUN=1 helper apply --json '{"ops":[{"type":"enable","id":"evil.plugin"}]}' 2>/dev/null; then fail "apply: a plugin that is not ours was accepted"; else ok "apply: a plugin that is not ours is refused"; fi
if SINNERS_DRY_RUN=1 helper apply --json '{"ops":[{"type":"format","id":"sinners.clock"}]}' 2>/dev/null; then fail "apply: an unknown op was accepted"; else ok "apply: an unknown op is refused"; fi

# apply for real, against the stand-ins: one op fails, the others go ahead, and the shell is restarted once
: >"$LOG"
FAIL_ON=sinners.embers helper apply --json "$plan"
equals "apply: every op ran, the failing one too" "omarchy plugin disable sinners.clock|omarchy plugin enable sinners.embers|omarchy bar use sinners.bar-light|omarchy plugin enable sinners.settings --section tray|omarchy restart shell" \
  "$(grep '^omarchy ' "$LOG" | paste -sd'|')"
equals "apply: the shell was restarted once" 1 "$(grep -c '^omarchy restart shell' "$LOG")"
result=$STATE/last-apply.json
equals "apply: the outcome is recorded as done" done "$(jq -r .state "$result")"
equals "apply: one op is recorded as failed" 1 "$(jq .failed "$result")"
equals "apply: the failure says why" "refused: sinners.embers is in the way" "$(jq -r '.results[] | select(.ok | not) | .message' "$result")"
equals "apply: and that the shell restarted" true "$(jq .restarted "$result")"
equals "status: the outcome comes back with it" 1 "$(helper status | jq .lastApply.failed)"
: >"$LOG"
FAIL_ON=sinners helper apply --json "$plan"
equals "apply: when every op fails the shell is left alone" 0 "$(grep -c '^omarchy restart shell' "$LOG")"
: >"$LOG"
helper apply --reopen --json '{"ops":[{"type":"disable","id":"sinners.clock"}]}'
check "apply --reopen: the panel is opened again once the shell answers" grep -qx "omarchy-shell sinners.settings open" "$LOG"

# --- 3. the manifest -------------------------------------------------------------------------------------------------------
if command -v omarchy >/dev/null; then
  check "manifest: omarchy plugin validate" omarchy plugin validate "$PLUGIN"
else
  echo "skip: omarchy is not installed, so the manifest was not validated"
fi
check "manifest: the entry point exists" test -f "$PLUGIN/$(jq -r .entryPoints.barWidget "$PLUGIN/manifest.json")"
check "manifest: it goes in the tray drawer" test "$(jq -r .barWidget.defaultSection "$PLUGIN/manifest.json")" = tray
check "helper is executable" test -x "$HELPER"

# --- 4. the QML ---------------------------------------------------------------------------------------------------------
QMLLINT=/usr/lib/qt6/bin/qmllint
if [[ -x $QMLLINT ]]; then
  # The shell's own components are found through a directory laid out as `qs`, as the shell does. What is left out is what the shell's own
  # QML triggers too: unqualified ids from the enclosing file (the shell does not use ComponentBehavior: Bound), and Style's nested objects typed as QObject.
  mkdir -p "$WORK/lint/qs"
  ln -s "${OMARCHY_PATH:-/usr/share/omarchy}/shell/Ui" "$WORK/lint/qs/Ui"
  ln -s "${OMARCHY_PATH:-/usr/share/omarchy}/shell/Commons" "$WORK/lint/qs/Commons"
  problems=$(cd "$PLUGIN" && QT_QPA_PLATFORMTHEME= "$QMLLINT" -I "$WORK/lint" --unused-imports disable --renamed-type disable *.qml 2>&1 \
    | grep -E '^(Warning|Error)' | grep -vE '\[(unqualified|missing-property)\]' || true)
  if [[ -z $problems ]]; then ok "qmllint: no errors, and no warnings but the shell's own"; else fail "qmllint:"$'\n'"$problems"; fi
else
  echo "skip: Qt 6's qmllint is not installed, so the QML was not checked"
fi

# --- 5. (optional) the panel on screen --------------------------------------------------------------------------------------------
if [[ ${1:-} == --render ]]; then
  command -v quickshell >/dev/null || { echo "--render needs quickshell" >&2; exit 1; }
  OUT=$WORK/render
  mkdir -p "$OUT"
  for item in Ui Commons; do ln -s "${OMARCHY_PATH:-/usr/share/omarchy}/shell/$item" "$OUT/$item"; done
  for item in PanelBody PluginCard SettingRow SettingsState GuitarIcon; do ln -s "$PLUGIN/$item.qml" "$OUT/$item.qml"; done
  ln -s "$PLUGIN/Catalog.js" "$OUT/Catalog.js"
  ln -s "$PLUGIN/bin" "$OUT/bin"
  cat >"$OUT/shell.qml" <<'QML'
import QtQuick
import Quickshell
import "Catalog.js" as Catalog

ShellRoot {
  FloatingWindow {
    id: win
    visible: true
    implicitWidth: 900
    implicitHeight: 1000
    color: "#1a1210"
    SettingsState { id: st; active: true; Component.onCompleted: refresh() }
    Rectangle { id: bg; anchors.fill: parent; color: "#1a1210" }
    PanelBody { id: body; parent: bg; anchors.fill: parent; anchors.margins: 20; store: st; foreground: "#f0d9a8"; accent: "#e8a33d"; urgent: "#d24a2a" }
    property var tabs: ["bar", "workspaces", "clock", "title", "embers", "notifications", "reset-question"]
    property int at: 0
    function next() {
      if (at >= tabs.length) { Qt.quit(); return }
      body.confirmReset = tabs[at] === "reset-question"
      body.tabId = tabs[at] === "reset-question" ? "clock" : tabs[at]
      Qt.callLater(function() { settle.start() })
    }
    Timer { id: settle; interval: 700; onTriggered: bg.grabToImage(function(r) { r.saveToFile(win.tabs[win.at] + ".png"); win.at++; win.next() }) }
    Timer { interval: 1500; running: true; onTriggered: win.next() }
  }
}
QML
  (cd "$OUT" && PATH="$BIN:$PATH" SINNERS_SHELL_JSON=$CFG SINNERS_PLUGINS_DIR=$PLUGINS SINNERS_STATE_DIR=$STATE SINNERS_THEME_STATE=$WORK/theme.name SINNERS_NO_SHELL=1 \
     QT_QPA_PLATFORMTHEME= QT_QPA_PLATFORM=offscreen timeout 90 env -u DISPLAY -u WAYLAND_DISPLAY quickshell -n -p "$OUT" >/dev/null 2>&1 || true)
  keep=${TMPDIR:-/tmp}/sinners-settings-render
  rm -rf "$keep"; mkdir -p "$keep"; cp "$OUT"/*.png "$keep"/ 2>/dev/null || true
  echo "pictures of the tabs: $keep"
fi

echo
if (( fails > 0 )); then echo "$fails check(s) failed" >&2; exit 1; fi
echo "all checks passed"
