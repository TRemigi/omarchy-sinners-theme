import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Catalog.js" as Catalog

// The top of a tab: whether the plugin the tab is about is installed and on, and the one button that changes it. Turning a plugin
// on or off, or installing it, needs the shell restarted, so the button stages the change, and the card says what will happen when
// Save is pressed. The bar tab has a choice of bars instead of one plugin, and stages that.
Column {
  id: root

  property var tab: ({})
  property var backend: null
  property QtObject bar: null
  property color foreground: Commons.Color.foreground
  property color accent: Commons.Color.accent
  property string fontFamily: Style.font.family

  readonly property color dim: Qt.darker(foreground, 1.45)
  readonly property bool isBar: tab.kind === "bar"
  readonly property string pluginId: tab.plugins && tab.plugins.length > 0 ? tab.plugins[0] : ""
  readonly property string now: backend ? Catalog.stateOf(backend.status, pluginId) : "missing"
  readonly property string wanted: backend ? Catalog.wantedState(backend.status, backend.staged, pluginId) : "missing"
  readonly property bool pending: now !== wanted
  readonly property string barChoice: backend ? Catalog.barChoice(backend.status, backend.staged) : "omarchy.bar"

  spacing: Style.spacing.lg

  // ---- one plugin -------------------------------------------------------------------------------------------------------

  Row {
    visible: !root.isBar
    width: parent.width
    spacing: Style.spacing.xl

    Column {
      width: parent.width - actionButton.width - parent.spacing
      spacing: Style.spacing.xxs

      Flow {
        width: parent.width
        spacing: Style.spacing.lg
        Text {
          textFormat: Text.PlainText
          text: Catalog.nameOf(root.pluginId)
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.title
          font.bold: true
        }
        Text {
          textFormat: Text.PlainText
          text: root.now === "on" ? "ON" : (root.now === "off" ? "OFF" : "NOT INSTALLED")
          color: root.now === "on" ? root.accent : root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
          topPadding: Style.space(4)
        }
      }
      Text {
        textFormat: Text.PlainText
        width: parent.width
        text: root.tab.summary || ""
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WordWrap
      }
    }

    Button {
      id: actionButton
      anchors.verticalCenter: parent.verticalCenter
      bordered: true
      selected: root.pending
      foreground: root.foreground
      fontFamily: root.fontFamily
      enabled: root.backend !== null && !root.backend.applying
      // What a click does depends on what the change is now: undo a staged one, or stage the opposite of what is there.
      text: root.pending ? "Undo"
          : (root.now === "on" ? "Turn off" : (root.now === "off" ? "Turn on" : "Install"))
      onClicked: root.backend.stagePlugin(root.pluginId, root.pending ? root.now === "on" : root.now !== "on")
    }
  }

  Text {
    textFormat: Text.PlainText
    visible: !root.isBar && root.pending
    width: parent.width
    text: root.wanted === "on"
      ? (root.now === "missing" ? "Save installs it and turns it on." : "Save turns it on.")
      : "Save turns it off."
    color: root.accent
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    wrapMode: Text.WordWrap
  }

  Text {
    textFormat: Text.PlainText
    visible: !root.isBar && Catalog.replaces(root.pluginId) !== "" && root.wanted === "on"
    width: parent.width
    text: "It takes the place of " + Catalog.replaces(root.pluginId) + " while it is on. Turn it off and they are back."
    color: root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }

  // ---- the choice of bar -----------------------------------------------------------------------------------------------

  Column {
    visible: root.isBar
    width: parent.width
    spacing: Style.spacing.md

    Text {
      textFormat: Text.PlainText
      text: "Bar style"
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.title
      font.bold: true
    }
    Text {
      textFormat: Text.PlainText
      width: parent.width
      text: root.tab.summary || ""
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }
    ButtonGroup {
      width: parent.width
      foreground: root.foreground
      fontFamily: root.fontFamily
      options: [
        { value: "omarchy.bar", label: "Omarchy's bar" },
        { value: "sinners.bar", label: "Dark boards" },
        { value: "sinners.bar-light", label: "Light boards" }
      ]
      value: root.barChoice
      onChanged: function(next) { if (root.backend && !root.backend.applying) root.backend.stageBar(next) }
    }
    Text {
      textFormat: Text.PlainText
      visible: root.backend !== null && ["omarchy.bar", "sinners.bar", "sinners.bar-light"].indexOf(root.barChoice) === -1
      width: parent.width
      text: "The bar in use is " + root.barChoice + ", which is not one of these."
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }
    Text {
      textFormat: Text.PlainText
      visible: root.backend !== null && root.backend.staged.bar !== undefined
      width: parent.width
      text: root.backend && root.backend.staged.bar !== undefined
        ? (root.backend.staged.bar === "omarchy.bar" ? "Save goes back to Omarchy's own bar."
           : (Catalog.stateOf(root.backend.status, root.backend.staged.bar) === "missing"
              ? "Save installs these boards and switches the bar to them." : "Save switches the bar to these boards."))
        : ""
      color: root.accent
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }
  }
}
