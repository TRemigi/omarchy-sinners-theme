import QtQuick

// Chipped, grainy paint on the lettering of one board of the bar. Put it after the board's widgets, as a sibling: it covers the board
// and draws the board's own picture over the widgets in small flakes (shaders/wear.frag). On bare board that is the board over
// itself, which changes nothing; over a letter it puts the board's red back on top of the lettering, as a chip where the paint has
// worn off, and, a little, where the wood is grooved, so the lettering shows the grain's dark lines as paint over wood does.
//
// Nothing here redraws or hides a widget, so their text and icons are exactly as the shell draws them, and clicks, hover and
// tooltips never see this: it takes no input. If the shader cannot run, it draws nothing, and the lettering is merely unworn.
Item {
  id: root

  property Item board: null          // the WoodBoard this is over
  property real seed: 1              // where in the flake noise this board starts, so boards do not wear alike
  property real strength: 0.4       // 0 is no flakes; 1 puts the board back over a flake completely
  property real grain: 0.95          // 0 is no grain in the lettering; 1 lets the wood's dark grooves through completely

  x: board ? board.x : 0
  y: board ? board.y : 0
  width: board ? board.width : 0
  height: board ? board.height : 0
  visible: !!board && board.visible && width > 0 && (strength > 0 || grain > 0)

  ShaderEffectSource {
    id: boardPicture
    sourceItem: root.board
    live: true
  }

  ShaderEffect {
    anchors.fill: parent

    property variant source: boardPicture
    property real strength: root.strength
    property real grain: root.grain
    property size size: Qt.size(root.width, root.height)
    property size offset: Qt.size(root.seed * 137.0, root.seed * 11.0)

    fragmentShader: Qt.resolvedUrl("shaders/wear.frag.qsb")
  }
}
