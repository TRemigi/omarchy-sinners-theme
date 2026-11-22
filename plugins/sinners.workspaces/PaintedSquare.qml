import QtQuick

// The painted square behind the shown workspace.
//
// On the dark bar it is in the theme's cream (`foreground`, #E8C48C, from colors.toml), the same as the lettering. Set `filled` to choose
// between the two drawings from tools/make-bar-wood.py: four rough brush strokes round the number (false), or a patch of cream paint with
// the number painted on it (true). The patch is easier to read, since the number sits on solid paint and not on the board.
//
// On the light bar (`red`, which the widget sets from the bar) it is a patch in the red of the film sign's lettering, #BC362E, with the
// number in cream on it.
//
// This is not generated from Omarchy's widget, so a build.sh run leaves it alone; edit `filled` here.
Item {
  id: root

  property bool filled: true
  property bool red: false

  Image {
    anchors.fill: parent
    source: Qt.resolvedUrl(root.red ? "square-red.png" : (root.filled ? "square-filled.png" : "square-outline.png"))
    smooth: true
  }
}
