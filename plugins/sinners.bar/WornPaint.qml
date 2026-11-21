import QtQuick

// Worn paint over the lettering of one section of the bar. Put it after its target, as a sibling: it takes the target's place
// and size, draws the target again through shaders/wear.frag (flakes of the text gone), and hides the original.
//
// It hides the original only once the shader has compiled. If the shader cannot run on this machine, nothing is hidden and
// the text is drawn as the stock bar draws it; the lettering is merely not worn. Clicks, hover and tooltips never see any
// of this: they belong to the target, which is still there and still visible to them.
Item {
  id: root

  property Item target: null
  property real seed: 1              // where in the mask this section starts, so sections do not wear alike
  property real strength: 0.85       // 0 is no wear; 1 takes a flake's paint away entirely

  x: target ? target.x : 0
  y: target ? target.y : 0
  width: target ? target.width : 0
  height: target ? target.height : 0

  Image {
    id: wearMask
    source: Qt.resolvedUrl("wood/wear.png")
    visible: false
    smooth: true
  }

  ShaderEffectSource {
    id: lettering
    sourceItem: root.target
    live: true
    hideSource: root.visible && root.width > 0 && fx.status === ShaderEffect.Compiled
  }

  ShaderEffect {
    id: fx
    anchors.fill: parent
    visible: root.width > 0 && root.height > 0

    property variant source: lettering
    property variant wear: wearMask
    property real strength: root.strength
    property size size: Qt.size(root.width, root.height)
    property size offset: Qt.size(root.seed * 137.0, root.seed * 11.0)

    fragmentShader: Qt.resolvedUrl("shaders/wear.frag.qsb")
  }
}
