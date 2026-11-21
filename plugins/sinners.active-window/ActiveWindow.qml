import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Commons as Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.active-window"


  readonly property var toplevel: ToplevelManager.activeToplevel
  readonly property string title: toplevel ? (toplevel.title || toplevel.appId || "") : ""
  readonly property int maxLabelWidth: Number(setting("maxWidth", 280))

  // The light bar (sinners.bar-light) has dark lettering, because its boards are light; the dark bar has cream. The bar's text colour is
  // all this widget is told of the bar, so it is how it tells which it is on: dark text means light boards.
  readonly property bool lightBoards: bar && bar.barForeground
    ? bar.barForeground.r * 0.2126 + bar.barForeground.g * 0.7152 + bar.barForeground.b * 0.0722 < 0.4 : false

  visible: title !== "" && !vertical
  implicitWidth: visible ? Math.min(maxLabelWidth, labelText.implicitWidth) + Style.spacing.controlPaddingX * 2 : 0
  implicitHeight: barSize

  Behavior on implicitWidth {
    NumberAnimation { duration: Style.duration(180); easing.type: Easing.OutCubic }
  }

  Item {
    anchors.fill: parent
    anchors.leftMargin: Style.space(8)
    anchors.rightMargin: Style.space(8)
    clip: true

    Text {
      id: labelText
      textFormat: Text.PlainText
      anchors.verticalCenter: parent.verticalCenter
      anchors.left: parent.left
      width: parent.width
      text: root.title
      // The title is a step dimmer than the rest of the lettering, so the eye goes to the workspaces and the clock first. On the dark bar that is
      // the theme's dimmed cream (colors.toml's light_foreground, #BF9F71; or [bar] title in the theme's shell.toml), drawn solid. On the light
      // bar the stock 85% opacity already makes it a step dimmer than the rust text (3.4:1 against 4.2:1), and dimming it further would be
      // unreadable on light wood, so it is left as it is.
      color: root.lightBoards || !root.bar ? (root.bar ? root.bar.barForeground : Commons.Color.foreground)
                                           : Commons.Color.flatColor(Commons.Color.pick("bar.title", "#BF9F71"), "#BF9F71")
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.body
      elide: Text.ElideRight
      opacity: root.lightBoards ? 0.85 : 1
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor

    onClicked: function(mouse) {
      if (!root.toplevel) return
      if (mouse.button === Qt.MiddleButton) {
        root.toplevel.close()
      } else if (mouse.button === Qt.RightButton) {
        root.toplevel.close()
      } else {
        root.toplevel.activate()
      }
    }
    onEntered: if (root.bar) root.bar.showTooltip(root, root.title)
    onExited: if (root.bar) root.bar.hideTooltip(root)
  }
}
