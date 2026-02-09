import QtQuick
import QtQuick.Shapes
import qs.components

BaseCorner {
    anchors.top: true
    anchors.left: true

    Shape {
        anchors.fill: parent
        visible: true
        layer.enabled: true
        layer.samples: 4
        ShapePath {
            strokeWidth: 0
            fillColor: root.sColor
            PathSvg {
                path: "M 0 0 L 25 0 L 25 15 A 10 10 0 0 0 15 25 L 0 25 Z"
            }
        }
    }
}