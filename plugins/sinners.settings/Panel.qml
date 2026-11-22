import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Catalog.js" as Catalog

// The Sinners settings: a guitar on the bar, in the tray's drawer, and under it a panel with a tab for each of the theme's other plugins.
//
// Most of what is here applies the moment it is changed (a slider moves the embers while it is being dragged). What cannot, because it
// needs the shell restarted, is staged and shown in the footer, and one Save applies it all and restarts the shell once. Nothing
// here asks the user to run a command.
//
//   omarchy-shell sinners.settings toggle     open or close the panel from a keybind or a script
Panel {
  id: root
  moduleName: "sinners.settings"
  ipcTarget: "sinners.settings"
  manageIpc: false

  readonly property color foreground: bar ? bar.foreground : Commons.Color.foreground
  readonly property color accent: Commons.Color.accent
  readonly property color urgent: bar ? bar.urgent : Commons.Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.45)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: {
    if (opened) {
      settingsStore.refresh()
      Qt.callLater(function() { if (panel.loadedContent) panel.loadedContent.forceActiveFocus() })
    } else if (panel.loadedContent) {
      // A question left showing when the panel closed is not there when it opens again.
      panel.loadedContent.confirmReset = false
    }
  }

  SettingsState { id: settingsStore; active: root.opened }

  ShellIpc {
    target: root.ipcTarget
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  // Not a BarIconButton: that fits whatever it is given to the bar's icon size, a dozen pixels at most, and a guitar is long and thin, so
  // it came out a few pixels wide. This is the same button underneath (the press, the tooltip, the click registration), with the guitar
  // drawn at most of the bar's height instead.
  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    labelVisible: false
    hasVisualContent: true
    readonly property real guitarHeight: Math.round(barSize * (vertical ? 0.9 : 0.8))
    fixedWidth: vertical ? -1 : Math.max(Style.bar.iconSlot, guitar.width + Style.space(12))
    fixedHeight: vertical ? guitar.height + Style.space(8) : -1
    onPressed: function(buttonCode) { root.toggle() }

    GuitarIcon {
      id: guitar
      anchors.centerIn: parent
      iconSize: button.guitarHeight
      color: root.barForeground
      scale: button.pressScale
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: panel.loadedContent
    contentWidth: panel.fittedContentWidth(Style.space(540))
    contentHeight: panel.fittedContentHeight(Style.space(600), Style.space(680))

    content: PanelBody {
      id: body
      anchors.fill: parent
      store: settingsStore
      bar: root.bar
      foreground: root.foreground
      accent: root.accent
      urgent: root.urgent
      fontFamily: root.fontFamily
      onCloseRequested: root.close()
    }
  }
}
