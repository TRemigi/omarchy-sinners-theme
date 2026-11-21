import QtQuick

// The painted square behind the shown workspace, in the theme's lightest cream (its title cream, #F8EFD9, from colors.toml). Set `filled` to choose between the two drawings from
// tools/make-bar-wood.py: four rough brush strokes round the number (false), or a patch of cream paint with the number painted
// on it (true). The patch is easier to read, since the number is red on cream and not red on the red board.
//
// This is not generated from Omarchy's widget, so a build.sh run leaves it alone; edit `filled` here.
Item {
  id: root

  property bool filled: true

  Image {
    anchors.fill: parent
    source: Qt.resolvedUrl(root.filled ? "square-filled.png" : "square-outline.png")
    smooth: true
  }
}
