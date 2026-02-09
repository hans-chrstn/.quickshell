import QtQuick
import QtQuick.Shapes
import qs.components

BaseCorner {
    anchors.top: true
    anchors.right: true

    Shape {
        anchors.fill: parent
        layer.enabled: true; layer.samples: 4
        ShapePath {
            strokeWidth: 0; fillColor: root.sColor
            PathSvg { path: "M 25 0 L 0 0 L 0 15 A 10 10 0 0 1 10 25 L 25 25 Z" }
        }
    }
}