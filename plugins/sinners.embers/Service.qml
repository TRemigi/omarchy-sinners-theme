// Sinners Embers: owns the settings, the theme gate, the shaders' clock, and one layer per screen that draws the
// smoke and the embers.
// Everything is dormant unless the active theme is sinners, so leaving the plugin enabled across theme switches
// is safe: no window is shown and no timer runs.
//
// Settings are inline fields on this plugin's entry in ~/.config/omarchy/shell.json `plugins[]`:
//   embers (bool, true)         switch the embers off (the smoke stays; see `smoke`)
//   smoke (0-1, 0.32)           how much smoke; 0 switches it off
//   intensity (0-1, 0.8)        how bright the embers are
//   density (0.1-1.5, 1)        how many; 1 is about seventy in view at once on a 1920x1200 screen, most of them small
//   speed (0.25-3, 1)           how fast everything moves, flicker included
//   (with `embers` false and `smoke` 0 the plugin draws nothing and runs no timer)
//   fpsCap (5-60, 60)           the most frames per second the embers get; the smoke is held to 30, being soft and slow
//   renderScale (0.5-1, 1)      the fraction of the screen's size the embers render at; lower is cheaper and softer
//                               (the smoke is soft anyway and always renders at 0.4)
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
  property real smoke: 0.32
  property real intensity: 0.8
  property real density: 1.0
  property real speed: 1.0
  property int fpsCap: 60
  property real renderScale: 1.0

  readonly property bool embersOn: embers && intensity > 0 && density > 0
  readonly property bool smokeOn: smoke > 0
  readonly property bool running: themeActive && (embersOn || smokeOn)

  // Random per session, so the embers are never in the same places twice.
  readonly property real seed: Math.random() * 100.0

  // The shader's clock, in seconds, shared by every screen. It is accumulated rather than read from the wall
  // clock, so changing `speed` speeds the embers up or slows them from where they are instead of making them
  // jump. It starts at a random point. It wraps every six hours: past that a float32 clock is too coarse to
  // place an ember to the pixel, and the wrap (every ember re-lofted at once, once) is the lesser harm.
  readonly property real clockWrap: 21600
  property real clock: Math.random() * 3600
  property real lastTickMs: 0

  // The smoke's own copy of the clock, brought up to date only about 30 times a second: it moves slowly and
  // softly, so it gains nothing from more, and its texture is redrawn only when this changes.
  property real smokeClock: clock
  property real lastSmokeMs: 0

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
    smoke = typeof entry.smoke === "number" ? clamp(entry.smoke, 0, 1) : 0.32
    intensity = typeof entry.intensity === "number" ? clamp(entry.intensity, 0, 1) : 0.8
    density = typeof entry.density === "number" ? clamp(entry.density, 0.1, 1.5) : 1.0
    speed = typeof entry.speed === "number" ? clamp(entry.speed, 0.25, 3) : 1.0
    fpsCap = typeof entry.fpsCap === "number" ? Math.round(clamp(entry.fpsCap, 5, 60)) : 60
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

  // Advances the clock once per frame the display shows, at most fpsCap times a second, so that on a 60 Hz screen
  // the embers move on every refresh rather than on a timer that drifts against it. A long gap (the machine
  // slept, the shell stalled) counts as at most a quarter of a second.
  FrameAnimation {
    running: root.running
    onRunningChanged: if (running) { root.lastTickMs = Date.now(); root.lastSmokeMs = 0 }
    onTriggered: {
      var now = Date.now()
      var gap = now - root.lastTickMs
      if (gap < 1000 / Math.max(5, Math.min(60, root.fpsCap)) - 2) return
      root.clock = (root.clock + Math.min(0.25, gap / 1000) * root.speed) % root.clockWrap
      root.lastTickMs = now
      if (now - root.lastSmokeMs >= 28) {
        root.smokeClock = root.clock
        root.lastSmokeMs = now
      }
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
