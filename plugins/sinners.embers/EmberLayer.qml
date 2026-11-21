// One click-through window per screen, between the wallpaper and the windows, painting the ember shader. Hidden
// while a fullscreen window covers this screen, so a game or a video costs nothing. The clock is the service's.

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
  id: win

  required property var service

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
    anchors.fill: parent

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
