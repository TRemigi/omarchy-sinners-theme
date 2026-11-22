import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Catalog.js" as Catalog

// What is inside the panel: the title, the tabs, the tab that is showing, and the footer with Save. Panel.qml puts it in a popup under the
// guitar and gives it the state to draw; it is a file of its own so it can be put on screen without a bar (see tools/check-settings.sh).
Item {
  id: body

  property var store: null
  property QtObject bar: null
  property color foreground: Commons.Color.foreground
  property color accent: Commons.Color.accent
  property color urgent: Commons.Color.urgent
  property string fontFamily: Style.font.family
  readonly property color dim: Qt.darker(foreground, 1.45)

  property string tabId: Catalog.TABS[0].id
  readonly property var currentTab: {
    for (var i = 0; i < Catalog.TABS.length; i++) if (Catalog.TABS[i].id === tabId) return Catalog.TABS[i]
    return Catalog.TABS[0]
  }

  signal closeRequested()

  // The question "reset this tab?" is showing.
  property bool confirmReset: false
  onConfirmResetChanged: if (confirmReset) confirmKeys.forceActiveFocus(); else body.forceActiveFocus()

  // Nothing is drawn until the first answer, which is a moment after the panel opens, so it never shows every plugin as missing.
  opacity: store && (store.loaded || store.problem !== "") ? 1 : 0
  Behavior on opacity { NumberAnimation { duration: Style.duration(120) } }

  focus: true
  // Escape closes. Keys go to a text field first, so typing is not cut short by it.
  Keys.onEscapePressed: closeRequested()

  // ---- header --------------------------------------------------------------------------------------------------------
  Item {
    id: header
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: Math.max(titleText.implicitHeight, hint.implicitHeight)

    Text {
      id: titleText
      textFormat: Text.PlainText
      text: "Sinners"
      color: body.foreground
      font.family: body.fontFamily
      font.pixelSize: Style.font.heading
      font.bold: true
    }
    Text {
      id: hint
      textFormat: Text.PlainText
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: !body.store.status.themeActive ? "The Sinners theme is not the active theme"
          : (!body.store.status.shellRunning ? "The shell is not answering" : "")
      color: body.dim
      font.family: body.fontFamily
      font.pixelSize: Style.font.caption
    }
  }

  // ---- tabs ----------------------------------------------------------------------------------------------------------
  Flow {
    id: tabs
    anchors.top: header.bottom
    anchors.topMargin: Style.spacing.lg
    anchors.left: parent.left
    anchors.right: parent.right
    spacing: Style.spacing.sm

    Repeater {
      model: Catalog.TABS
      delegate: Button {
        id: tabButton
        required property var modelData
        readonly property string tabState: Catalog.wantedState(body.store.status, body.store.staged, modelData.plugins[0])
        text: modelData.title
        // A dot says whether what the tab is about is on, and a filled one that it will be after Save.
        iconText: modelData.kind === "bar" ? "" : (tabState === "on" ? "●" : "○")
        iconSize: Style.font.caption
        selected: body.tabId === modelData.id
        foreground: body.foreground
        fontFamily: body.fontFamily
        onClicked: body.tabId = modelData.id
      }
    }
  }

  // ---- the footer: what Save will do ---------------------------------------------------------------------------------------
  Column {
    id: footer
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    spacing: Style.spacing.md

    PanelSeparator { width: parent.width; foreground: body.foreground }

    Column {
      visible: body.store.hasStaged
      width: parent.width
      spacing: Style.spacing.xxs

      Repeater {
        model: body.store.changes
        delegate: Text {
          required property string modelData
          textFormat: Text.PlainText
          width: footer.width
          text: "• " + modelData
          color: body.foreground
          font.family: body.fontFamily
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
        }
      }
    }

    Item {
      width: parent.width
      height: Math.max(saveNote.implicitHeight, saveRow.implicitHeight)

      Text {
        id: saveNote
        textFormat: Text.PlainText
        anchors.left: parent.left
        anchors.right: saveRow.left
        anchors.rightMargin: Style.space(12)
        anchors.verticalCenter: parent.verticalCenter
        text: body.store.applying ? "Applying. The shell restarts in a moment, and this panel comes back."
            : (body.store.hasStaged ? "Saving restarts the shell for a few seconds."
                               : "Everything else here applies as you change it.")
        color: body.dim
        font.family: body.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }

      Row {
        id: saveRow
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.spacing.md

        Button {
          visible: body.store.hasStaged && !body.store.applying
          text: "Discard"
          bordered: true
          foreground: body.foreground
          fontFamily: body.fontFamily
          onClicked: body.store.discard()
        }
        Button {
          text: body.store.applying ? "Saving…" : "Save"
          bordered: true
          selected: body.store.hasStaged && !body.store.applying
          enabled: body.store.hasStaged && !body.store.applying
          opacity: enabled ? 1 : 0.45
          foreground: body.foreground
          fontFamily: body.fontFamily
          onClicked: body.store.save()
        }
      }
    }
  }

  // ---- the tab ---------------------------------------------------------------------------------------------------------
  Flickable {
    id: tabScroller
    anchors.top: tabs.bottom
    anchors.topMargin: Style.spacing.xl
    anchors.bottom: footer.top
    anchors.bottomMargin: Style.spacing.lg
    anchors.left: parent.left
    anchors.right: parent.right
    contentWidth: width
    contentHeight: tabColumn.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.VerticalFlick
    interactive: contentHeight > height
    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

    // A different tab starts at its top.
    Connections {
      target: body
      function onTabIdChanged() { tabScroller.contentY = 0 }
    }

    Column {
      id: tabColumn
      width: tabScroller.width - Style.space(10)
      spacing: Style.spacing.xxl

      // What the last Save did, shown once when the panel comes back after the shell restarted.
      Item {
        visible: body.store.showLastApply
        width: parent.width
        height: visible ? lastColumn.implicitHeight : 0

        Column {
          id: lastColumn
          anchors.left: parent.left
          anchors.right: dismiss.left
          anchors.rightMargin: Style.space(8)
          spacing: Style.spacing.xxs

          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: body.store.lastApply && body.store.lastApply.failed > 0
              ? (body.store.lastApply.failed + " of " + body.store.lastApply.results.length + " changes did not apply")
              : "Saved. " + (body.store.lastApply && body.store.lastApply.restarted ? "The shell was restarted." : "")
            color: body.store.lastApply && body.store.lastApply.failed > 0 ? body.urgent : body.accent
            font.family: body.fontFamily
            font.pixelSize: Style.font.subtitle
            wrapMode: Text.WordWrap
          }
          Repeater {
            model: body.store.lastApply && body.store.lastApply.failed > 0 ? body.store.lastApply.results.filter(function(r) { return !r.ok }) : []
            delegate: Text {
              required property var modelData
              textFormat: Text.PlainText
              width: lastColumn.width
              text: modelData.op + ": " + modelData.message
              color: body.dim
              font.family: body.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }
          }
        }
        PanelActionButton {
          id: dismiss
          anchors.right: parent.right
          iconText: "×"
          tooltipText: "Dismiss"
          foreground: body.foreground
          onClicked: body.store.dismissLastApply()
        }
      }

      Text {
        visible: body.store.problem !== ""
        textFormat: Text.PlainText
        width: parent.width
        text: body.store.problem
        color: body.urgent
        font.family: body.fontFamily
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WordWrap
      }

      PluginCard {
        width: parent.width
        tab: body.currentTab
        backend: body.store
        bar: body.bar
        foreground: body.foreground
        accent: body.accent
        fontFamily: body.fontFamily
      }

      // The settings. A group heading starts where a control names a `section`.
      Column {
        width: parent.width
        spacing: Style.spacing.huge

        Text {
          textFormat: Text.PlainText
          visible: body.currentTab.kind !== "bar" && Catalog.controlsFor(body.currentTab.id).length > 0
            && Catalog.stateOf(body.store.status, body.currentTab.plugins[0]) !== "on"
          width: parent.width
          text: "Turn it on to change these."
          color: body.dim
          font.family: body.fontFamily
          font.pixelSize: Style.font.bodySmall
        }

        Repeater {
          model: Catalog.controlsFor(body.currentTab.id)
          delegate: Column {
            id: entry
            required property var modelData
            required property int index
            width: tabColumn.width
            spacing: Style.spacing.lg

            PanelSeparator {
              visible: entry.modelData.section !== undefined
              width: parent.width
              foreground: body.foreground
            }
            PanelSectionHeader {
              visible: entry.modelData.section !== undefined
              text: (entry.modelData.section || "").toUpperCase()
              foreground: body.foreground
              fontFamily: body.fontFamily
            }
            SettingRow {
              width: parent.width
              control: entry.modelData
              tab: body.currentTab
              settings: Catalog.settingsFor(body.store.status, entry.modelData, body.currentTab)
              controller: body.store
              scroller: tabScroller
              bar: body.bar
              foreground: body.foreground
              fontFamily: body.fontFamily
              active: entry.modelData.scope === "bar"
                || Catalog.stateOf(body.store.status, body.currentTab.plugins[0]) === "on"
            }
          }
        }

        Text {
          textFormat: Text.PlainText
          visible: Catalog.controlsFor(body.currentTab.id).length === 0
          width: parent.width
          text: "Nothing here to set yet. It dresses itself to suit whichever bar it sits on."
          color: body.dim
          font.family: body.fontFamily
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
        }

        // Back to the plugin's own defaults, after being asked.
        Item {
          visible: Catalog.controlsFor(body.currentTab.id).length > 0
          width: parent.width
          height: visible ? resetButton.implicitHeight : 0

          Button {
            id: resetButton
            anchors.right: parent.right
            text: "Reset to defaults"
            bordered: true
            foreground: body.foreground
            fontFamily: body.fontFamily
            readonly property bool usable: body.currentTab.kind === "bar"
              || Catalog.stateOf(body.store.status, body.currentTab.plugins[0]) === "on"
            enabled: usable && Catalog.changedControls(body.store.status, body.currentTab).length > 0
            opacity: enabled ? 1 : 0.4
            onClicked: body.confirmReset = true
          }
        }
      }
    }
  }

  // Keys go to the question while it is showing, and only to it.
  Item {
    id: confirmKeys
    Keys.onPressed: function(event) {
      confirmDialog.handleKey(event)
      event.accepted = true
    }
  }

  ConfirmDialog {
    id: confirmDialog
    anchors.fill: parent
    z: 10
    opened: body.confirmReset
    selectedIndex: 0
    message: "Reset every " + body.currentTab.title + " setting to its default? "
      + Catalog.changedControls(body.store.status, body.currentTab).length + " would change."
    confirmText: "Reset"
    background: Commons.Color.popups.background
    foreground: body.foreground
    selectedText: body.accent
    fontFamily: body.fontFamily
    onCanceled: body.confirmReset = false
    onConfirmed: {
      body.confirmReset = false
      body.store.resetTab(body.currentTab)
    }
  }
}
