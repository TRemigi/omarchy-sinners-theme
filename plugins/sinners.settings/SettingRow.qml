import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Catalog.js" as Catalog

// One setting, drawn from its spec in Catalog.js: a toggle, a slider, a choice, a clock format or a number. The row holds no value of
// its own. It shows what `settings` says (which the state keeps up to date, optimistically, as it is changed) and tells the state
// what the user did, so a control cannot disagree with the file it edits.
Item {
  id: root

  property var control: ({})
  property var tab: ({})
  property var settings: ({})
  property var controller: null
  // The Flickable the row sits in, which a wheel over a slider scrolls (see sliderRow).
  property Item scroller: null
  property QtObject bar: null
  property color foreground: Commons.Color.foreground
  property string fontFamily: Style.font.family
  // False while the plugin the setting belongs to is not on: there is no entry in shell.json to change.
  property bool active: true

  readonly property var value: Catalog.valueOf(control, settings)
  readonly property bool available: active && Catalog.enabledBy(control, settings)
  readonly property color dim: Qt.darker(foreground, 1.45)

  function apply(next) {
    if (controller) controller.change(tab, control, next)
  }

  width: parent ? parent.width : 0
  implicitHeight: loader.item ? loader.item.implicitHeight : 0
  opacity: available ? 1 : 0.38
  enabled: available

  Loader {
    id: loader
    width: parent.width
    sourceComponent: {
      switch (root.control.type) {
        case "toggle": return toggleRow
        case "slider": return sliderRow
        case "format": return formatRow
        case "number": return numberRow
        default: return (root.control.options || []).length <= 4 ? segmentedRow : dropdownRow
      }
    }
  }

  // The label, and under it the sentence that says what the setting does.
  component Heading: Column {
    id: heading
    property string label: ""
    property string description: ""
    property string trailing: ""
    spacing: Style.spacing.xxs

    Item {
      width: parent.width
      height: titleText.implicitHeight
      Text {
        id: titleText
        textFormat: Text.PlainText
        text: heading.label
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.subtitle
      }
      Text {
        textFormat: Text.PlainText
        visible: heading.trailing !== ""
        anchors.right: parent.right
        text: heading.trailing
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
      }
    }
    Text {
      textFormat: Text.PlainText
      visible: heading.description !== ""
      width: parent.width
      text: heading.description
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }
  }

  Component {
    id: toggleRow
    Toggle {
      width: loader.width
      label: root.control.label
      description: root.control.description || ""
      checked: root.value === true
      foreground: root.foreground
      fontFamily: root.fontFamily
      onClicked: root.apply(!checked)
    }
  }

  Component {
    id: sliderRow
    Column {
      width: loader.width
      spacing: Style.spacing.md

      Heading {
        width: parent.width
        label: root.control.label
        description: root.control.description || ""
        trailing: Catalog.describe(root.control, Catalog.snap(root.control, slider.liveValue))
      }
      Item {
        width: parent.width
        height: slider.implicitHeight

        PanelSlider {
          id: slider
          anchors.fill: parent
          bar: root.bar
          minimum: root.control.min
          maximum: root.control.max
          step: root.control.step
          value: root.value
          // The slider rounds to whole numbers only when asked; steps of 5 or 0.05 are snapped when the value is written.
          integer: false
          onMoved: function(next) { root.apply(next) }
          onReleased: function(next) {
            root.apply(next)
            if (root.controller) root.controller.flush()
          }
        }

        // The slider takes the wheel for itself, so scrolling a long tab with the pointer passing over one would move it. This sits on top,
        // takes the wheel first, and scrolls the page; it takes no button, so presses and drags still reach the slider underneath.
        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.NoButton
          onWheel: function(wheel) {
            var page = root.scroller
            if (page) {
              var step = wheel.pixelDelta.y !== 0 ? wheel.pixelDelta.y : wheel.angleDelta.y * 0.6
              page.contentY = Math.max(0, Math.min(Math.max(0, page.contentHeight - page.height), page.contentY - step))
            }
            wheel.accepted = true
          }
        }
      }
    }
  }

  Component {
    id: segmentedRow
    Column {
      width: loader.width
      spacing: Style.spacing.md

      Heading {
        width: parent.width
        label: root.control.label
        description: root.control.description || ""
      }
      ButtonGroup {
        width: parent.width
        options: root.control.options
        value: String(root.value)
        foreground: root.foreground
        fontFamily: root.fontFamily
        onChanged: function(next) { root.apply(next) }
      }
    }
  }

  Component {
    id: dropdownRow
    Column {
      width: loader.width
      spacing: Style.spacing.md

      Heading {
        width: parent.width
        label: root.control.label
        description: root.control.description || ""
      }
      Dropdown {
        width: parent.width
        showLabel: false
        options: root.control.options
        value: String(root.value)
        foreground: root.foreground
        fontFamily: root.fontFamily
        onChanged: function(next) { root.apply(next) }
      }
    }
  }

  // A clock label: the presets, each drawn as it would look on the bar right now, and a free field for anything else.
  Component {
    id: formatRow
    Column {
      id: format
      width: loader.width
      spacing: Style.spacing.md

      readonly property string custom: "__custom__"
      readonly property var presets: Catalog.CLOCK_FORMATS
      readonly property bool isPreset: presets.indexOf(String(root.value)) !== -1
      property bool customChosen: false
      readonly property bool showCustom: customChosen || !isPreset
      readonly property date now: new Date()

      // The clock writes the two digits of the ISO week into the format before Qt sees it, as Qt has no ISO week of its own; this does the same, to show a sample.
      function sample(text) {
        var date = format.now
        var week = Catalog.isoWeek(date)
        var shown = String(text).replace(/ww/g, (week < 10 ? "0" : "") + week)
        return date.toLocaleString(Qt.locale(Commons.I18n.formatLocale), shown)
      }

      readonly property var options: {
        var list = []
        for (var i = 0; i < presets.length; i++) list.push({ value: presets[i], label: sample(presets[i]) })
        list.push({ value: custom, label: "Custom…" })
        return list
      }

      Heading {
        width: parent.width
        label: root.control.label
        description: root.control.description || ""
      }
      Dropdown {
        width: parent.width
        showLabel: false
        options: format.options
        value: format.showCustom ? format.custom : String(root.value)
        foreground: root.foreground
        fontFamily: root.fontFamily
        onChanged: function(next) {
          if (next === format.custom) {
            format.customChosen = true
          } else {
            format.customChosen = false
            root.apply(next)
          }
        }
      }
      Column {
        visible: format.showCustom
        width: parent.width
        spacing: Style.spacing.xs

        TextField {
          id: customField
          width: parent.width
          text: String(root.value)
          foreground: root.foreground
          font.family: root.fontFamily
          placeholderText: "dddd HH:mm"
          onEditingFinished: if (Catalog.sensibleFormat(text) && text !== String(root.value)) root.apply(text)
        }
        Text {
          textFormat: Text.PlainText
          width: parent.width
          text: Catalog.sensibleFormat(customField.text) ? "Looks like: " + format.sample(customField.text)
                                                       : "Qt date format: dddd, d MMMM, yyyy, HH:mm, h:mm AP, and so on"
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }
      }
    }
  }

  Component {
    id: numberRow
    Item {
      width: loader.width
      implicitHeight: Math.max(numberHeading.implicitHeight, numberField.implicitHeight)

      Heading {
        id: numberHeading
        anchors.left: parent.left
        anchors.right: numberField.left
        anchors.rightMargin: Style.space(12)
        label: root.control.label
        description: root.control.description || ""
      }
      NumberField {
        id: numberField
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        fieldWidth: Style.space(96)
        from: root.control.min
        to: root.control.key === "birthYear" ? new Date().getFullYear() : root.control.max
        stepSize: root.control.step
        value: Math.round(Number(root.value))
        foreground: root.foreground
        fontFamily: root.fontFamily
        onModified: function(next) { root.apply(next) }
        // A year is not "1,990".
        Component.onCompleted: numberField.field.textFromValue = function(number) { return String(number) }
      }
    }
  }
}
