import QtQuick
import QtQuick.Shapes
import qs.components

BaseCorner {
    anchors.bottom: true
    anchors.left: true

    Shape {
        anchors.fill: parent
        layer.enabled: true; layer.samples: 4
        ShapePath {
            strokeWidth: 0; fillColor: root.sColor
            PathSvg { path: "M 0 25 L 25 25 L 25 10 A 10 10 0 0 1 15 0 L 0 0 Z" }
        }
    }
}