import QtQuick
import QtQuick.Shapes
import qs.components

BaseCorner {
    anchors.bottom: true
    anchors.right: true

    Shape {
        anchors.fill: parent
        layer.enabled: true; layer.samples: 4
        ShapePath {
            strokeWidth: 0; fillColor: root.sColor
            PathSvg { path: "M 25 25 L 0 25 L 0 10 A 10 10 0 0 0 10 0 L 25 0 Z" }
        }
    }
}