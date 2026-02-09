import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import "../config"

PanelWindow {
    id: root
    property var modelData
    screen: modelData

    property bool activeTop: false
    property bool activeBottom: false
    property bool activeLeft: false
    property bool activeRight: false

    property int sThick: FrameConfig.thickness
    property int iRadius: 10
    property int sRadius: sThick + iRadius
    property color sColor: FrameConfig.color
    
    anchors {
        top: activeTop
        bottom: activeBottom
        left: activeLeft
        right: activeRight
    }

    implicitWidth: sRadius
    implicitHeight: sRadius
    color: "transparent"
    
    exclusionMode: ExclusionMode.Ignore

  Shape {
      anchors.fill: parent
      visible: root.activeTop && root.activeLeft
      layer.enabled: true; layer.samples: 4
      ShapePath {
          strokeWidth: 0; fillColor: root.sColor
          PathSvg { path: "M 0 0 L 25 0 L 25 15 A 10 10 0 0 0 15 25 L 0 25 Z" }
      }
  }

  Shape {
      anchors.fill: parent
      visible: root.activeBottom && root.activeLeft
      layer.enabled: true; layer.samples: 4
      ShapePath {
          strokeWidth: 0; fillColor: root.sColor
          PathSvg { path: "M 0 25 L 25 25 L 25 10 A 10 10 0 0 1 15 0 L 0 0 Z" }
      }
  }

  Shape {
      anchors.fill: parent
      visible: root.activeTop && root.activeRight
      layer.enabled: true; layer.samples: 4
      ShapePath {
          strokeWidth: 0; fillColor: root.sColor
          PathSvg { path: "M 25 0 L 0 0 L 0 15 A 10 10 0 0 1 10 25 L 25 25 Z" }
      }
  }

  Shape {
      anchors.fill: parent
      visible: root.activeBottom && root.activeRight
      layer.enabled: true; layer.samples: 4
      ShapePath {
          strokeWidth: 0; fillColor: root.sColor
          PathSvg { path: "M 25 25 L 0 25 L 0 10 A 10 10 0 0 0 10 0 L 25 0 Z" }
      }
  }
}

