// Sinners Embers: owns the settings, the theme gate, the shader's clock, and one ember layer per screen.
// Everything is dormant unless the active theme is sinners, so leaving the plugin enabled across theme switches
// is safe: no window is shown and no timer runs.
//
// Settings are inline fields on this plugin's entry in ~/.config/omarchy/shell.json `plugins[]`:
//   embers (bool, true)         switch the embers off without disabling the plugin
//   intensity (0-1, 0.8)        how bright they are
//   density (0.1-1.5, 1)        how many; 1 is about seventy in view at once on a 1920x1200 screen, most of them small
//   speed (0.25-3, 1)           how fast everything moves, flicker included
//   fpsCap (5-60, 30)           frames per second
//   renderScale (0.5-1, 1)      the fraction of the screen's size the shader renders at; lower is cheaper and softer
// A change to shell.json applies at once. A new shader or QML file needs `omarchy restart shell`.

import QtQuick
import Quickshell
import Quickshell.Io

Scope {
  id: root

  // Injected by omarchy-shell.
  property var shell: null
  property var manifest: null
  property string omarchyPath: ""
  property var pluginRegistry: null
  property var barWidgetRegistry: null

  readonly property string pluginId: "sinners.embers"
  readonly property string home: Quickshell.env("HOME")

  property bool themeActive: false
  property bool embers: true
  property real intensity: 0.8
  property real density: 1.0
  property real speed: 1.0
  property int fpsCap: 30
  property real renderScale: 1.0

  readonly property bool running: themeActive && embers && intensity > 0 && density > 0

  // Random per session, so the embers are never in the same places twice.
  readonly property real seed: Math.random() * 100.0

  // The shader's clock, in seconds, shared by every screen. It is accumulated rather than read from the wall
  // clock, so changing `speed` speeds the embers up or slows them from where they are instead of making them
  // jump. It starts at a random point. It wraps every six hours: past that a float32 clock is too coarse to
  // place an ember to the pixel, and the wrap (every ember re-lofted at once, once) is the lesser harm.
  readonly property real clockWrap: 21600
  property real clock: Math.random() * 3600
  property real lastTickMs: 0

  function clamp(value, low, high) {
    return Math.min(high, Math.max(low, value))
  }

  function applyConfig(raw) {
    var entry = ({})
    try {
      var cfg = JSON.parse(raw)
      if (Array.isArray(cfg.plugins)) {
        cfg.plugins.forEach(function(item) {
          if (!item || item.id !== root.pluginId) return
          for (var key in item) entry[key] = item[key]
        })
      }
    } catch (e) {}

    embers = entry.embers !== false
    intensity = typeof entry.intensity === "number" ? clamp(entry.intensity, 0, 1) : 0.8
    density = typeof entry.density === "number" ? clamp(entry.density, 0.1, 1.5) : 1.0
    speed = typeof entry.speed === "number" ? clamp(entry.speed, 0.25, 3) : 1.0
    fpsCap = typeof entry.fpsCap === "number" ? Math.round(clamp(entry.fpsCap, 5, 60)) : 30
    renderScale = typeof entry.renderScale === "number" ? clamp(entry.renderScale, 0.5, 1) : 1.0
  }

  FileView {
    id: themeFile
    path: root.home + "/.local/state/omarchy/current/theme.name"
    watchChanges: true
    printErrors: false
    onLoaded: root.themeActive = text().trim() === "sinners"
    onFileChanged: reload()
    onLoadFailed: root.themeActive = false
  }

  FileView {
    id: configFile
    path: root.home + "/.config/omarchy/shell.json"
    watchChanges: true
    printErrors: false
    onLoaded: root.applyConfig(text())
    onFileChanged: reload()
  }

  // Advances the clock at the frame rate cap. A long gap (the machine slept, the shell stalled) counts as at most
  // a quarter of a second.
  Timer {
    interval: Math.round(1000 / Math.max(5, Math.min(60, root.fpsCap)))
    running: root.running
    repeat: true
    onRunningChanged: if (running) root.lastTickMs = Date.now()
    onTriggered: {
      var now = Date.now()
      root.clock = (root.clock + Math.min(0.25, (now - root.lastTickMs) / 1000) * root.speed) % root.clockWrap
      root.lastTickMs = now
    }
  }

  Variants {
    model: Quickshell.screens

    EmberLayer {
      required property var modelData
      screen: modelData
      service: root
    }
  }
}
