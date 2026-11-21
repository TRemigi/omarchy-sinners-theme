// Sinners: whether notification cards burn away, and for how long. One instance, made by Service.qml.
//
// Cards burn only while the Sinners theme is active, so this plugin is safe to leave enabled on every theme: on
// any other it is Omarchy's own notifications plugin and nothing more.
//
// Settings are inline fields on this plugin's entry in ~/.config/omarchy/shell.json `plugins[]`:
//   burn (bool, true)           cards burn away whenever they leave (they expire, are clicked, or are dismissed);
//                               false is the stock fade
//   burnSeconds (0.8-6, 2.6)    how long the fire takes to cross a card; the smoke and ash then settle for a moment
// A change to shell.json applies at once.

import QtQuick
import Quickshell
import Quickshell.Io

Scope {
  id: root

  readonly property string pluginId: "sinners.notifications"
  readonly property string home: Quickshell.env("HOME")

  property bool themeActive: false
  property bool burn: true
  property real seconds: 2.6

  // How long after the fire has crossed a card it stays, for the last of its smoke and ash to thin out and settle.
  // The card keeps its place in the stack for this long, and the window stays up.
  readonly property real tail: 1.0

  readonly property bool active: themeActive && burn

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
    burn = entry.burn !== false
    seconds = typeof entry.burnSeconds === "number" ? Math.min(6, Math.max(0.8, entry.burnSeconds)) : 2.6
  }

  FileView {
    path: root.home + "/.local/state/omarchy/current/theme.name"
    watchChanges: true
    printErrors: false
    onLoaded: root.themeActive = text().trim() === "sinners"
    onFileChanged: reload()
    onLoadFailed: root.themeActive = false
  }

  FileView {
    path: root.home + "/.config/omarchy/shell.json"
    watchChanges: true
    printErrors: false
    onLoaded: root.applyConfig(text())
    onFileChanged: reload()
  }
}
