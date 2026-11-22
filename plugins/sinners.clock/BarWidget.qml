import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model

// Date/time label for the bar, and the host for the calendar popup.
//
// Left click reveals the calendar — asking "what is the date?" is what a
// click on a clock means — right click walks the common label formats, and
// middle click opens the timezone picker.
BarWidget {
  id: root
  moduleName: "omarchy.clock"

  property date displayDate: clock.date

  // The clock is lettered in Cinzel Decorative Black (SIL Open Font License; fonts/OFL.txt): flared, swashy capitals, in the spirit
  // of the Club Juke sign's lettering. It is loaded from this plugin's own folder, so nothing is installed. If it cannot be loaded,
  // or on a vertical bar, the clock is lettered as the stock clock is.
  FontLoader { id: signFont; source: Qt.resolvedUrl("fonts/CinzelDecorative-Black.ttf") }
  readonly property bool signLettering: !vertical && signFont.status === FontLoader.Ready

  // The light bar (sinners.bar-light) has dark lettering, because its boards are light; the dark bar has cream. The bar's text colour is
  // all this widget is told of the bar, so it is how it tells which it is on: dark text means light boards.
  readonly property bool lightBoards: bar && bar.barForeground
    ? bar.barForeground.r * 0.2126 + bar.barForeground.g * 0.7152 + bar.barForeground.b * 0.0722 < 0.4 : false

  readonly property string configuredFormat: vertical
    ? setting("verticalFormat", "HH\n—\nmm")
    : setting("format", "dddd HH:mm")
  readonly property string configuredAltFormat: vertical
    ? setting("verticalFormatAlt", "dd\nMMM\n'W'ww\n''yy")
    : setting("formatAlt", "d MMMM 'W'ww yyyy")

  readonly property var formatRing: Model.clockFormatRing(configuredFormat, configuredAltFormat, Model.clockFormats(vertical))

  // What the bar shows is what shell.json stores, so a cycled format is the
  // format from then on rather than something that reverts on restart.
  readonly property string activeFormat: configuredFormat

  // A seconds label needs the clock to tick sixty times as often, and a
  // repaint a second is a price only the formats that print seconds pay.
  readonly property bool showsSeconds: Model.clockNeedsSeconds(activeFormat)
  readonly property string displayText: formatted(displayDate)
  readonly property var verticalLines: displayText.split("\n")

  function refresh() {
    displayDate = new Date()
    if (panelLoader.item && panelLoader.item.refresh) panelLoader.item.refresh()
  }

  function cycleFormat() {
    var current = String(configuredFormat)
    var next = Model.nextClockFormat(formatRing, current)
    if (next === "" || next === current) return

    var entry = { id: root.moduleName }
    for (var key in root.settings) if (key !== "id") entry[key] = root.settings[key]
    entry[vertical ? "verticalFormat" : "format"] = next

    // Applied locally first so the label changes on the click itself; the
    // shell.json write comes back through the bar as the same value.
    root.settings = entry
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry)
  }

  // Day and month names follow the Omarchy language, not the system locale,
  // which only catches up at the next login.
  readonly property var formatLocale: Qt.locale(I18n.formatLocale)

  // The ISO week goes in as a literal, so its digits are localized here the
  // way Qt localizes the rest of the format.
  function formatted(date) {
    var week = Model.isoWeekLiteral(date.getFullYear(), date.getMonth(), date.getDate())
    week = week.split("").map(function(digit) { return I18n.formatNumber(digit) }).join("")
    return date.toLocaleString(root.formatLocale, activeFormat.replace(/ww/g, week))
  }

  // ---- Calendar popup. Shape contract for shell.summon/hide/toggle
  //      routing: Bar.findPanelWidget requires open/close/opened on the
  //      bar-widget root.
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function togglePanel() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  function toggleWeekStart() {
    if (panelLoader.item) panelLoader.item.toggleWeekStart()
  }

  // The clock fills more slot than it paints a mark for, at both
  // orientations: horizontally it is a text label in a padded slot, so the
  // dot takes the label width; vertically it is a stack of icon-sized lines,
  // so the dot takes one line — the same mark every icon widget gets, rather
  // than a rule running the height of the whole stack.
  readonly property real openPanelIndicatorWidth: button.labelWidth
  readonly property real openPanelIndicatorHeight: Math.max(Style.space(10), Math.round(Style.bar.iconSlot * 0.55))

  // Forwarded so this widget can stand in for the panel as the bar's popout
  // identity: Bar.requestPopout prefers closeForPopoutSwitch over close, and
  // KeyboardPanel reads popoutSwitchClosing back off its owner.
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  WallClock {
    id: clock
    step: root.showsSeconds ? 1000 : 60000
    onDateChanged: root.displayDate = date
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  ShellIpc {
    target: "omarchy.clock"

    function refresh(): void { root.broadcast("refresh") }
    function cycleFormat(): void { root.cycleFormat() }
    function toggleWeekStart(): void { root.toggleWeekStart() }
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.togglePanel() }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    // The clock is the bar's one gold thing on the dark bar, so the eye goes to the time first: the sun's gold (colors.toml's yellow), or
    // [bar] clock in the theme's shell.toml if it has one. On the light bar, whose boards are the light wood of the film's sign, it is the
    // sign's red deepened to 55%, #682016, for legibility (the sign's own red is 2:1 on its wood), or [bar] clock-light. Everything else
    // about the clock is stock.
    foreground: root.lightBoards ? Commons.Color.flatColor(Commons.Color.pick("bar.clock-light", "#682016"), "#682016")
                                 : Commons.Color.flatColor(Commons.Color.pick("bar.clock", "#F9BD06"), "#F9BD06")
    fontFamily: root.signLettering ? signFont.name : (bar ? bar.fontFamily : Style.font.family)
    fontSize: root.signLettering ? Style.font.body + 3 : Style.font.body
    text: root.vertical ? "" : (root.signLettering ? root.displayText.toUpperCase() : root.displayText)
    labelVisible: !root.vertical
    hasVisualContent: root.vertical ? root.verticalLines.length > 0 : text !== ""
    fixedHeight: root.vertical ? root.verticalLines.length * Style.bar.iconSlot : -1
    horizontalMargin: 8.75
    verticalPadding: 8.75
    tooltipText: I18n.t("clock.toggleFormat")
    // The clock is text to read, not an icon to press, so a click never
    // shrinks it; the format it cycles to, or the panel it opens, is feedback.
    pressFeedbackButtons: Qt.NoButton

    onPressed: function(b) {
      if (b === Qt.RightButton) root.cycleFormat()
      else if (b === Qt.MiddleButton) { if (root.bar) root.bar.run("omarchy-menu-timezone") }
      else root.togglePanel()
    }

    Column {
      visible: root.vertical
      anchors.fill: parent

      Repeater {
        model: root.verticalLines

        OpticalGlyph {
          required property string modelData
          width: button.width
          height: Style.bar.iconSlot
          text: modelData
          fontFamily: button.fontFamily
          fontSize: modelData.length > 3
            ? button.fontSize * 0.9
            : button.fontSize
          color: button.foreground
        }
      }
    }
  }
}
