// One click-through window per screen, between the wallpaper and the windows, painting the smoke and then the
// embers over it. Both are in this one window so that their order is fixed. Hidden while a fullscreen window
// covers this screen, so a game or a video costs nothing. The clock is the service's.

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
  id: win

  required property var service

  // Smoke is soft, so it renders at 40% of the screen's size and is scaled up: a sixth of the pixels.
  readonly property real smokeScale: 0.4

  readonly property var hyprMonitor: Hyprland.monitorFor(screen)
  readonly property bool fullscreenHere: !!(hyprMonitor && hyprMonitor.activeWorkspace
    && hyprMonitor.activeWorkspace.hasFullscreen)

  visible: service.running && !fullscreenHere
  anchors { top: true; bottom: true; left: true; right: true }
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  mask: Region {}

  WlrLayershell.namespace: "sinners-embers"
  WlrLayershell.layer: WlrLayer.Bottom
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  ShaderEffect {
    id: smoke
    anchors.fill: parent
    visible: win.service.smokeOn

    layer.enabled: true
    layer.smooth: true
    layer.textureSize: Qt.size(Math.max(1, Math.round(width * win.smokeScale)),
                               Math.max(1, Math.round(height * win.smokeScale)))

    property real time: win.service.smokeClock
    property real amount: win.service.smoke
    property real seed: win.service.seed
    property size resolution: Qt.size(width, height)

    // The wallpaper's sun, in screen heights (x from the left, y up from the bottom, radius), so that the smoke
    // can be lit from it. The numbers are the geometry line of tools/make-wallpaper.sh (a 3840x2160 wallpaper,
    // the sun at 1920,940 with radius 600), fitted to the screen the way the desktop fits a wallpaper: scaled to
    // cover it and centered.
    readonly property real fit: Math.max(width / 3840, height / 2160)
    property vector3d sun: Qt.vector3d(
      ((1920 - 1920) * fit + width / 2) / height,
      1 - ((940 - 1080) * fit + height / 2) / height,
      600 * fit / height)

    fragmentShader: Qt.resolvedUrl("shaders/smoke.frag.qsb")
  }

  ShaderEffect {
    id: embers
    anchors.fill: parent
    visible: win.service.embersOn

    // The embers are a few pixels across, so this renders at the screen's own size unless the renderScale
    // setting is lowered to save work; the halos survive being scaled up, the cores go soft.
    layer.enabled: true
    layer.smooth: true
    layer.textureSize: Qt.size(Math.max(1, Math.round(width * win.service.renderScale)),
                               Math.max(1, Math.round(height * win.service.renderScale)))

    property real time: win.service.clock
    property real intensity: win.service.intensity
    property real density: win.service.density
    property real seed: win.service.seed
    property size resolution: Qt.size(width, height)

    fragmentShader: Qt.resolvedUrl("shaders/embers.frag.qsb")
  }
}
