pragma ComponentBehavior: Bound

import QtQuick

// One weathered board behind a section of the bar: charred cypress with oxblood paint left on it in worn patches, a ragged sawn end with two nails at
// each end, and the board's shadow beneath it. All of it is pre-drawn (tools/make-bar-wood.py); this only cuts the picture to
// the board's length. Set name to left, center or right to pick which board's pictures.
//
// The pictures are 2x and 36 logical px tall, with the board itself 30 of that (3 of margin above, the shadow below). They are
// scaled by height/36 so they stay in proportion when the bar's size follows the font size.
//
// The body picture is 1000 logical px (700 for right). A longer board repeats it, end to end, up to three times; the join
// shows only as the grain not quite lining up.
Item {
  id: root

  property string name: "left"

  readonly property real k: height / 36            // pictures are drawn for a 36px bar
  readonly property real capWidth: 28 * k          // each end cap, of which the inner `fade` fades into the body
  readonly property real fade: 16 * k
  readonly property url dir: Qt.resolvedUrl("wood/")

  implicitHeight: 36

  // The body runs under both caps' fades. Its picture is shown unshifted, so its x is the board's x.
  Item {
    x: root.capWidth - root.fade
    width: Math.max(0, root.width - 2 * (root.capWidth - root.fade))
    height: parent.height
    clip: true

    Repeater {
      model: 3
      Image {
        required property int index
        x: -(root.capWidth - root.fade) + index * width
        width: sourceSize.width / 2 * root.k
        height: parent.height
        source: root.dir + root.name + "-body.png"
        smooth: true
        asynchronous: false
        visible: x < root.width
      }
    }
  }

  Image {
    x: 0
    width: root.capWidth
    height: parent.height
    source: root.dir + root.name + "-lcap.png"
    smooth: true
  }

  Image {
    x: root.width - root.capWidth
    width: root.capWidth
    height: parent.height
    source: root.dir + root.name + "-rcap.png"
    smooth: true
  }
}
