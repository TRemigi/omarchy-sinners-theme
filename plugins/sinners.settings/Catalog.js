// What the settings panel shows, and how it turns a click into a change. Pure data and functions, with nothing from Qt or the
// shell, so tools/check-settings.sh can test it under node.
//
// A sister plugin is one of the other plugins in this theme. Each gets a tab, with a card at the top that says whether it is
// installed and on, and the settings it reads below. A setting is one of two kinds, and the kind decides how a change is made:
//
//   applies at once   written to shell.json, which the plugin is already watching, so the change shows as it is made. This is
//                     every control below, bar the bar's style.
//   staged            needs the shell restarted to take effect: installing a plugin, turning one on or off, and choosing the
//                     bar. It is held in `staged` until Save, then all of it is applied together and the shell is restarted once.

// The tabs, in order. `plugins` is what the tab's card manages; a bar tab has two to choose between, any other has one.
var TABS = [
  {
    id: "bar", title: "Bar", kind: "bar", plugins: ["sinners.bar", "sinners.bar-light"],
    summary: "A bar of weathered boards, dark or light, in place of Omarchy's own."
  },
  {
    id: "workspaces", title: "Workspaces", kind: "widget", plugins: ["sinners.workspaces"],
    summary: "The shown workspace as its number, in a painted cream square."
  },
  {
    id: "clock", title: "Clock", kind: "widget", plugins: ["sinners.clock"],
    summary: "The clock in the sun's gold, in a flared display face."
  },
  {
    id: "title", title: "Window title", kind: "widget", plugins: ["sinners.active-window"],
    summary: "The title of the focused window, a step dimmer than the rest of the bar."
  },
  {
    id: "embers", title: "Embers", kind: "service", plugins: ["sinners.embers"],
    summary: "Sparks and smoke that climb past the sun on the wallpaper."
  },
  {
    id: "notifications", title: "Notifications", kind: "service", plugins: ["sinners.notifications"],
    summary: "Toasts that burn away into ash when they leave."
  }
]

// What each plugin is called on a card, and what turning it on replaces (if anything).
var PLUGIN_INFO = {
  "sinners.bar": { name: "Dark boards", replaces: "Omarchy's bar" },
  "sinners.bar-light": { name: "Light boards", replaces: "Omarchy's bar" },
  "sinners.workspaces": { name: "Sinners Workspaces", replaces: "Omarchy's workspaces" },
  "sinners.clock": { name: "Sinners Clock", replaces: "Omarchy's clock" },
  "sinners.active-window": { name: "Sinners Window Title", replaces: "Omarchy's window title" },
  "sinners.embers": { name: "Embers", replaces: "" },
  "sinners.notifications": { name: "Sinners Notifications", replaces: "Omarchy's notification daemon" }
}

var CLOCK_FORMATS = [
  "dddd HH:mm", "dddd h:mm AP", "dddd HH:mm:ss", "dddd h:mm:ss AP", "HH:mm", "h:mm AP",
  "ddd d MMM HH:mm", "ddd d MMM h:mm AP", "d MMMM 'W'ww yyyy", "yyyy-MM-dd HH:mm"
]

var WEEK_START = [
  { value: "", label: "Follow the system" },
  { value: "sunday", label: "Sunday" },
  { value: "monday", label: "Monday" },
  { value: "tuesday", label: "Tuesday" },
  { value: "wednesday", label: "Wednesday" },
  { value: "thursday", label: "Thursday" },
  { value: "friday", label: "Friday" },
  { value: "saturday", label: "Saturday" }
]

// The controls of each tab. `scope` says where the value is stored:
//   plugin  a field on the plugin's entry in shell.json plugins[]
//   widget  a field on the widget's entry in the bar layout
//   bar     the bar itself (omarchy bar position / background)
// `def` is what the plugin does when the field is missing, and choosing it removes the field instead of writing it.
// `type` is toggle, slider, choice, format or number. Sliders and numbers take min, max and step.
var CONTROLS = {
  bar: [
    { key: "position", scope: "bar", type: "choice", label: "Position", def: "top",
      description: "The boards are drawn only on a top or bottom bar; a left or right bar looks stock.",
      options: [{ value: "top", label: "Top" }, { value: "bottom", label: "Bottom" }, { value: "left", label: "Left" }, { value: "right", label: "Right" }] },
    { key: "background", scope: "bar", type: "choice", label: "Background", def: "opaque",
      description: "What shows behind the bar's widgets between the boards.",
      options: [{ value: "opaque", label: "Opaque" }, { value: "glassy", label: "Glassy" }, { value: "none", label: "Clear" }] }
  ],
  workspaces: [],
  clock: [
    { key: "format", scope: "widget", type: "format", label: "Label", def: "dddd HH:mm", section: "Bar label",
      description: "How the time is written on the bar. A click on the clock itself still cycles through these." },
    { key: "formatAlt", scope: "widget", type: "format", label: "Alternate label", def: "d MMMM 'W'ww yyyy",
      description: "The second label in the cycle, which a right click on the clock shows." },
    { key: "weekStartDay", scope: "widget", type: "choice", label: "Week starts on", def: "", section: "Calendar",
      description: "The first column of the calendar that opens from the clock.", options: WEEK_START },
    { key: "birthYear", scope: "widget", type: "number", label: "Birth year", def: 0, min: 0, max: 2100, step: 1, off: 0, section: "Memento mori",
      description: "With a year here the calendar draws a second bar: how much of a life has gone. 0 hides it." },
    { key: "lifeExpectancy", scope: "widget", type: "number", label: "Life expectancy", def: 90, min: 1, max: 150, step: 1,
      description: "In years; the second bar measures your age against it.", needs: "birthYear" }
  ],
  title: [
    { key: "maxWidth", scope: "widget", type: "slider", label: "Widest title", def: 280, min: 80, max: 800, step: 10, unit: "px",
      description: "A longer title is cut short with an ellipsis at this width." }
  ],
  embers: [
    { key: "embers", scope: "plugin", type: "toggle", label: "Embers", def: true,
      description: "The sparks. Off leaves the smoke, if there is any." },
    { key: "smoke", scope: "plugin", type: "slider", label: "Smoke", def: 0.32, min: 0, max: 1, step: 0.01, percent: true,
      description: "How much dark smoke rises behind the embers. 0 is none." },
    { key: "intensity", scope: "plugin", type: "slider", label: "Brightness", def: 0.8, min: 0, max: 1, step: 0.01, percent: true,
      description: "How bright the embers burn." },
    { key: "density", scope: "plugin", type: "slider", label: "Amount", def: 1, min: 0.1, max: 1.5, step: 0.05, times: true,
      description: "How many embers are in the air at once. 1 is about seventy on a 1920 by 1200 screen." },
    { key: "speed", scope: "plugin", type: "slider", label: "Speed", def: 1, min: 0.25, max: 3, step: 0.05, times: true,
      description: "How fast everything moves, flicker included." },
    { key: "fpsCap", scope: "plugin", type: "slider", label: "Frame rate limit", def: 60, min: 5, max: 60, step: 5, integer: true, unit: "fps", section: "Cost",
      description: "The most frames a second the embers get. The smoke is held to 30 either way." },
    { key: "renderScale", scope: "plugin", type: "slider", label: "Sharpness", def: 1, min: 0.5, max: 1, step: 0.05, percent: true,
      description: "The fraction of the screen's size the embers are drawn at. Lower is cheaper and softer." }
  ],
  notifications: [
    { key: "burn", scope: "plugin", type: "toggle", label: "Burn away", def: true,
      description: "Toasts burn when they expire or are dismissed. Off is Omarchy's own fade." },
    { key: "burnSeconds", scope: "plugin", type: "slider", label: "Burn time", def: 2.6, min: 0.8, max: 6, step: 0.1, unit: "s", needs: "burn",
      description: "How long the fire takes to cross a toast. The smoke and ash settle for a second more." }
  ]
}

function clamp(value, low, high) {
  return Math.min(high, Math.max(low, value))
}

// A slider's value snapped to its step and kept in range, so the number written to shell.json is 0.35 and not 0.35000000000000003.
function snap(control, raw) {
  var step = control.step || 1
  var value = control.min + Math.round((Number(raw) - control.min) / step) * step
  value = clamp(value, control.min, control.max)
  var places = (String(step).split(".")[1] || "").length
  value = Number(value.toFixed(places))
  return control.integer ? Math.round(value) : value
}

// What a control currently holds: the plugin's own setting when it has one, the default when it does not.
function valueOf(control, settings) {
  var have = settings && settings[control.key] !== undefined && settings[control.key] !== null
  var value = have ? settings[control.key] : control.def
  if (control.type === "slider" || control.type === "number") {
    var number = Number(value)
    return isFinite(number) ? number : control.def
  }
  if (control.type === "toggle") return value !== false
  return value
}

// What to write for a value: null (remove the field, so the plugin's own default is back) when it is the default.
function valueToWrite(control, value) {
  if (control.type === "slider") value = snap(control, value)
  if (control.type === "number") value = Math.round(clamp(Number(value) || 0, control.min, control.max))
  if (control.type === "number" && control.off !== undefined && value === control.off) return null
  return value === control.def ? null : value
}

// The text beside a slider.
function describe(control, value) {
  var number = Number(value)
  if (control.percent) return Math.round(number * 100) + "%"
  if (control.times) return number.toFixed(2).replace(/0$/, "").replace(/\.0$/, "") + "×"
  var text = control.integer ? String(Math.round(number)) : String(number)
  return control.unit ? text + " " + control.unit : text
}

// ---- what is installed, and what Save will do ------------------------------------------------------------------------

// The state of one plugin from the helper's `status`: "missing" (not linked into Omarchy's plugins directory), "off" (there, but
// not enabled) or "on". A bar is "on" while it is the bar in use.
function stateOf(status, id) {
  var plugin = status && status.plugins ? status.plugins[id] : null
  if (!plugin || !plugin.present) return "missing"
  return plugin.enabled ? "on" : "off"
}

// What a plugin will be once Save is pressed: its staged state, or what it is now.
function wantedState(status, staged, id) {
  var now = stateOf(status, id)
  if (staged && staged.bar !== undefined && (id === "sinners.bar" || id === "sinners.bar-light"))
    return staged.bar === id ? "on" : (now === "missing" ? "missing" : "off")
  if (staged && staged.plugins && staged.plugins[id] !== undefined) return staged.plugins[id] ? "on" : "off"
  return now
}

// The bar in use, or the one staged.
function barChoice(status, staged) {
  if (staged && staged.bar !== undefined) return staged.bar
  return status && status.bar ? status.bar.id : "omarchy.bar"
}

// Stage a plugin being turned on or off. Returns the new staged object; asking for what it already is drops the entry.
function stagePlugin(status, staged, id, on) {
  var next = { bar: staged ? staged.bar : undefined, plugins: {} }
  var plugins = staged && staged.plugins ? staged.plugins : {}
  for (var key in plugins) next.plugins[key] = plugins[key]
  if ((stateOf(status, id) === "on") === on) delete next.plugins[id]
  else next.plugins[id] = on
  if (next.bar === undefined) delete next.bar
  return next
}

// Stage the choice of bar; choosing the one in use drops it.
function stageBar(status, staged, id) {
  var next = { bar: id, plugins: {} }
  var plugins = staged && staged.plugins ? staged.plugins : {}
  for (var key in plugins) next.plugins[key] = plugins[key]
  if (status && status.bar && status.bar.id === id) delete next.bar
  return next
}

function isEmpty(staged) {
  if (!staged) return true
  if (staged.bar !== undefined) return false
  for (var key in (staged.plugins || {})) return false
  return true
}

// The ops `sinners-settings apply` takes, turning plugins off before on (so one that replaces a built-in is free to be replaced).
function planOps(status, staged) {
  var ops = []
  var plugins = staged && staged.plugins ? staged.plugins : {}
  var id
  for (id in plugins) if (!plugins[id]) ops.push({ type: "disable", id: id })
  for (id in plugins) if (plugins[id]) ops.push({ type: "enable", id: id })
  if (staged && staged.bar !== undefined) ops.push({ type: "bar", id: staged.bar })
  return ops
}

function nameOf(id) {
  if (id === "omarchy.bar") return "Omarchy's own bar"
  return PLUGIN_INFO[id] ? PLUGIN_INFO[id].name : id
}

// One line for each staged change, for the list above the Save button.
function describeChanges(status, staged) {
  var lines = []
  var plugins = staged && staged.plugins ? staged.plugins : {}
  for (var id in plugins) {
    var state = stateOf(status, id)
    if (!plugins[id]) lines.push("Turn off " + nameOf(id))
    else lines.push((state === "missing" ? "Install and turn on " : "Turn on ") + nameOf(id))
  }
  if (staged && staged.bar !== undefined) {
    var bar = staged.bar
    if (bar === "omarchy.bar") lines.push("Go back to Omarchy's own bar")
    else lines.push((stateOf(status, bar) === "missing" ? "Install and use " : "Use ") + nameOf(bar).toLowerCase() + " for the bar")
  }
  return lines
}

// Whether another plugin that this one replaces is in the way, which the installer refuses. The helper cannot say which, so the
// card only warns that the plugin replaces a built-in.
function replaces(id) {
  return PLUGIN_INFO[id] ? PLUGIN_INFO[id].replaces : ""
}

// The settings that belong on a tab, with each one's settings object picked out of the helper's status.
function controlsFor(tabId) {
  return CONTROLS[tabId] || []
}

function settingsFor(status, control, tab) {
  if (control.scope === "bar") return status && status.bar ? status.bar : {}
  var id = tab.plugins[0]
  return status && status.plugins && status.plugins[id] ? status.plugins[id].settings || {} : {}
}

// The write the helper's `batch` takes for a change to a control.
function writeFor(control, tab, value) {
  if (control.scope === "bar")
    return { kind: control.key === "position" ? "bar-position" : "bar-background", value: value }
  return { kind: control.scope, id: tab.plugins[0], key: control.key, value: valueToWrite(control, value) }
}

// The controls of a tab that are not at their defaults, which is what a reset would change.
function changedControls(status, tab) {
  var out = []
  var list = controlsFor(tab.id)
  for (var i = 0; i < list.length; i++) {
    var control = list[i]
    var value = valueOf(control, settingsFor(status, control, tab))
    var differs = control.scope === "bar" ? String(value) !== String(control.def) : valueToWrite(control, value) !== null
    if (differs) out.push(control)
  }
  return out
}

// A control that depends on another is greyed while that one is off (a burn time with burning off, a life expectancy with no birth year).
function enabledBy(control, settings) {
  if (!control.needs) return true
  var parent = null
  var all = CONTROLS
  for (var tabId in all) {
    for (var i = 0; i < all[tabId].length; i++) if (all[tabId][i].key === control.needs && all[tabId][i].scope === control.scope) parent = all[tabId][i]
  }
  if (!parent) return true
  var value = valueOf(parent, settings)
  if (parent.type === "toggle") return value === true
  if (parent.type === "number") return Number(value) !== (parent.off !== undefined ? parent.off : 0)
  return true
}

// The ISO 8601 week of a date, which the clock prints for `ww` in its formats.
function isoWeek(date) {
  var day = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()))
  var weekday = day.getUTCDay() || 7
  day.setUTCDate(day.getUTCDate() + 4 - weekday)
  var yearStart = new Date(Date.UTC(day.getUTCFullYear(), 0, 1))
  return Math.ceil(((day - yearStart) / 86400000 + 1) / 7)
}

// Whether the text is a clock format Qt would draw as something, as opposed to blank.
function sensibleFormat(text) {
  return String(text === undefined || text === null ? "" : text).replace(/^\s+|\s+$/g, "") !== ""
}

if (typeof module !== "undefined") {
  module.exports = {
    TABS: TABS, PLUGIN_INFO: PLUGIN_INFO, CONTROLS: CONTROLS, CLOCK_FORMATS: CLOCK_FORMATS, WEEK_START: WEEK_START,
    clamp: clamp, snap: snap, valueOf: valueOf, valueToWrite: valueToWrite, describe: describe,
    stateOf: stateOf, wantedState: wantedState, barChoice: barChoice, stagePlugin: stagePlugin, stageBar: stageBar,
    isEmpty: isEmpty, planOps: planOps, nameOf: nameOf, describeChanges: describeChanges, replaces: replaces,
    controlsFor: controlsFor, settingsFor: settingsFor, changedControls: changedControls, writeFor: writeFor, enabledBy: enabledBy, sensibleFormat: sensibleFormat, isoWeek: isoWeek
  }
}
