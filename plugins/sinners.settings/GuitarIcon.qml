import QtQuick
import QtQuick.Shapes

// A resonator guitar standing upright: headstock at the top, a straight neck, and a waisted body whose lower bout holds the round
// resonator, drawn as a ring cut out of the body with the cone's cap left standing in the middle of it. One colour, so it takes
// the bar's lettering colour like every other icon on the bar.
//
// It is drawn in a 54 by 100 box and scaled to `iconSize`, its height. The proportions are stouter than a real guitar's, and the neck
// and the ring are thick, because on a bar it is only a few dozen pixels tall and a true-to-life one is a hairline.
Item {
  id: root

  property real iconSize: 16
  property color color: "white"

  readonly property real unit: iconSize / 100
  readonly property real aspectRatio: 0.54

  width: 54 * unit
  height: 100 * unit
  implicitWidth: width
  implicitHeight: height

  Shape {
    width: 54
    height: 100
    scale: root.unit
    transformOrigin: Item.TopLeft
    antialiasing: true
    layer.enabled: true
    layer.samples: 4

    // The headstock and the neck, as one piece that widens at the top. The body's top edge is under the neck's foot, so the two are
    // separate paths: where they overlap, an even-odd fill would cut a hole.
    ShapePath {
      fillColor: root.color
      strokeWidth: 0
      startX: 19; startY: 0
      PathLine { x: 35; y: 0 }
      PathLine { x: 35; y: 14 }
      PathLine { x: 31; y: 18 }
      PathLine { x: 31; y: 46 }
      PathLine { x: 23; y: 46 }
      PathLine { x: 23; y: 18 }
      PathLine { x: 19; y: 14 }
      PathLine { x: 19; y: 0 }
    }

    // The body with the resonator in it: the outline, then the ring's circle (a hole, under even-odd), then the cone's cap (solid again).
    ShapePath {
      fillColor: root.color
      fillRule: ShapePath.OddEvenFill
      strokeWidth: 0

      // The outline, clockwise from the top of the upper bout, wide below the waist.
      startX: 27; startY: 40
      PathCubic { control1X: 37;  control1Y: 40;  control2X: 45; control2Y: 44.5; x: 45; y: 52 }
      PathCubic { control1X: 45;  control1Y: 57.5; control2X: 43; control2Y: 59;  x: 43; y: 63 }
      PathCubic { control1X: 43;  control1Y: 69;  control2X: 54; control2Y: 69;   x: 54; y: 81 }
      PathCubic { control1X: 54;  control1Y: 92;  control2X: 42; control2Y: 100;  x: 27; y: 100 }
      PathCubic { control1X: 12;  control1Y: 100; control2X: 0;  control2Y: 92;   x: 0;  y: 81 }
      PathCubic { control1X: 0;   control1Y: 69;  control2X: 11; control2Y: 69;   x: 11; y: 63 }
      PathCubic { control1X: 11;  control1Y: 59;  control2X: 9;  control2Y: 57.5; x: 9;  y: 52 }
      PathCubic { control1X: 9;   control1Y: 44.5; control2X: 17; control2Y: 40;  x: 27; y: 40 }

      // The ring: a circle of radius 13 about (27, 80), as two half turns.
      PathMove { x: 40; y: 80 }
      PathArc { x: 14; y: 80; radiusX: 13; radiusY: 13; direction: PathArc.Clockwise }
      PathArc { x: 40; y: 80; radiusX: 13; radiusY: 13; direction: PathArc.Clockwise }

      // The cone's cap, radius 6.5.
      PathMove { x: 33.5; y: 80 }
      PathArc { x: 20.5; y: 80; radiusX: 6.5; radiusY: 6.5; direction: PathArc.Clockwise }
      PathArc { x: 33.5; y: 80; radiusX: 6.5; radiusY: 6.5; direction: PathArc.Clockwise }
    }
  }
}
