import QtQuick
import Quickshell
import Quickshell.Io
import "Catalog.js" as Catalog

// Everything the panel knows, and everything it does to the system. The panel draws this and calls it; it holds no state of its own
// beyond which tab is showing.
//
// Two kinds of change, kept apart on purpose:
//   change()   a setting that applies at once. It is written to shell.json, which the plugin concerned is watching, within a
//              fraction of a second, so the bar and the wallpaper follow while a slider is still being dragged.
//   stage*()   a change that needs the shell restarted: a plugin turned on or off or installed, or a different bar. It is held in
//              `staged` and nothing happens until save(), which hands all of it to `sinners-settings apply` at once.
//
// Everything that touches the system runs through bin/sinners-settings, which is also how it is tested.
Item {
  id: root

  readonly property string home: Quickshell.env("HOME")
  readonly property string helper: decodeURIComponent(Qt.resolvedUrl("bin/sinners-settings").toString().replace(/^file:\/\//, ""))

  // The helper's `status`, kept in step with shell.json. Until the first answer it describes a bare system.
  property var status: ({
    shellRunning: true, themeActive: false,
    bar: { id: "omarchy.bar", position: "top", background: "opaque" },
    plugins: ({}), lastApply: null
  })
  property bool loaded: false
  property string problem: ""

  // The bar makes one of these widgets for each screen, so none of them reads anything until its panel is open.
  property bool active: false

  // What is waiting for Save: { bar: <bar id>, plugins: { <id>: true | false } }, with an entry only where it differs from now.
  property var staged: ({})
  readonly property bool hasStaged: !Catalog.isEmpty(staged)
  readonly property var changes: Catalog.describeChanges(status, staged)

  property bool applying: false
  property real applyStartedAt: 0
  property real dismissedAt: 0

  // The outcome of the last Save, shown for a few minutes after it, which is how it reaches the panel that opens again once the shell
  // has restarted.
  readonly property var lastApply: status && status.lastApply ? status.lastApply : null
  readonly property bool showLastApply: lastApply !== null && lastApply.state === "done" && !applying
    && lastApply.at > dismissedAt && (Date.now() / 1000 - lastApply.at) < 300

  signal refreshed()

  // ---- reading -------------------------------------------------------------------------------------------------------------

  property bool refreshQueued: false
  property string _statusText: ""

  function refresh() {
    // A write in flight would be undone by a status read that started before it landed, so the read waits for it.
    if (statusProc.running || writeProc.running || writeTimer.running || _queueSize() > 0) {
      refreshQueued = true
      return
    }
    refreshQueued = false
    statusProc.running = true
  }

  Process {
    id: statusProc
    running: false
    command: [root.helper, "status"]
    stdout: StdioCollector { id: statusOut; waitForEnd: true; onStreamFinished: root._statusText = text }
    stderr: StdioCollector { id: statusErr; waitForEnd: true }
    onExited: function(exitCode) {
      var out = String(statusOut.text || root._statusText || "")
      if (exitCode === 0) {
        try {
          root.status = JSON.parse(out)
          root.loaded = true
          root.problem = ""
          root.refreshed()
        } catch (e) {
          root.problem = "The settings helper answered with something that is not JSON."
        }
      } else {
        root.problem = String(statusErr.text || "").trim() || "The settings helper failed (exit " + exitCode + ")."
      }
      if (root.refreshQueued) root.refresh()
    }
  }

  // shell.json is what the plugins read, so a change to it (from here, from `omarchy bar set`, or by hand) is a reason to look again.
  FileView {
    path: Quickshell.env("SINNERS_SHELL_JSON") || (root.home + "/.config/omarchy/shell.json")
    watchChanges: true
    printErrors: false
    onFileChanged: { reload(); if (root.active || root.applying) settleTimer.restart() }
  }
  Timer { id: settleTimer; interval: 250; onTriggered: root.refresh() }

  // While Save is working, ask for the outcome now and then; if the shell is restarted this whole item goes with it, and the one
  // that replaces it reads the outcome when it starts.
  Timer {
    interval: 1000
    repeat: true
    running: root.applying
    onTriggered: {
      // A helper that never started (no setsid, say) would leave the panel waiting for good.
      if (Date.now() - root.applyStartedAt > 120000) {
        root.applying = false
        root.problem = "Saving did not finish. Run: " + root.helper + " status"
        return
      }
      root.refresh()
      var last = root.lastApply
      if (last && last.state === "done" && last.at >= Math.floor(root.applyStartedAt / 1000)) {
        root.applying = false
        root.staged = ({})
      }
    }
  }

  // ---- changes that apply at once ----------------------------------------------------------------------------------------------

  // Writes waiting to go out, last one wins per setting, so a slider being dragged costs one write each interval and not one a pixel.
  property var _queue: ({})

  function _queueSize() {
    var count = 0
    for (var key in _queue) count++
    return count
  }

  // Change one control of a tab to `value`.
  function change(tab, control, value) {
    var write = Catalog.writeFor(control, tab, value)
    _patch(write)
    var id = write.kind + "|" + (write.id || "") + "|" + (write.key || "")
    var next = {}
    for (var key in _queue) next[key] = _queue[key]
    next[id] = write
    _queue = next
    if (!writeTimer.running && !writeProc.running) writeTimer.start()
  }

  // Put every setting of a tab back to its default: the field is removed from shell.json (or, for the bar, set to the bar's default), so
  // the plugin does what it does with no setting at all. Plugin on or off, and the choice of bar, are not settings and stay as they are.
  function resetTab(tab) {
    var controls = Catalog.changedControls(status, tab)
    for (var i = 0; i < controls.length; i++) change(tab, controls[i], controls[i].def)
    flush()
  }

  // Send what is waiting now, for the end of a drag.
  function flush() {
    writeTimer.stop()
    _flush()
  }

  // The status as it will be once the write lands, so a control moves the moment it is touched and not when the file has been
  // rewritten and read back.
  function _patch(write) {
    var next = JSON.parse(JSON.stringify(status))
    if (write.kind === "bar-position") next.bar.position = write.value
    else if (write.kind === "bar-background") next.bar.background = write.value
    else if (next.plugins && next.plugins[write.id]) {
      var settings = next.plugins[write.id].settings || {}
      if (write.value === null) delete settings[write.key]
      else settings[write.key] = write.value
      next.plugins[write.id].settings = settings
    }
    status = next
  }

  Timer { id: writeTimer; interval: 140; onTriggered: root._flush() }

  function _flush() {
    if (writeProc.running) { writeTimer.start(); return }
    var writes = []
    for (var key in _queue) writes.push(_queue[key])
    if (writes.length === 0) {
      if (refreshQueued) refresh()
      return
    }
    _queue = ({})
    writeProc.command = [root.helper, "batch", JSON.stringify(writes)]
    writeProc.running = true
  }

  Process {
    id: writeProc
    running: false
    stderr: StdioCollector { id: writeErr; waitForEnd: true }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.problem = String(writeErr.text || "").trim() || "A setting could not be saved."
        root.refreshQueued = true
      } else if (root.problem !== "") {
        root.problem = ""
      }
      if (root._queueSize() > 0) root._flush()
      else root.refresh()
    }
  }

  // ---- changes that wait for Save -----------------------------------------------------------------------------------------------

  function stagePlugin(id, on) { staged = Catalog.stagePlugin(status, staged, id, on) }
  function stageBar(id) { staged = Catalog.stageBar(status, staged, id) }
  function discard() { staged = ({}) }

  function dismissLastApply() { dismissedAt = Date.now() / 1000 }

  // Hand the staged changes to the helper, detached: it restarts the shell, which takes this panel with it, so it cannot be this
  // panel's child. It opens the panel again when the new shell is up.
  function save() {
    var ops = Catalog.planOps(status, staged)
    if (ops.length === 0 || applying) return
    applying = true
    applyStartedAt = Date.now()
    Quickshell.execDetached(["setsid", "-f", root.helper, "apply", "--reopen", "--json", JSON.stringify({ ops: ops })])
  }
}
