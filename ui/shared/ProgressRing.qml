import QtQuick
import QtQuick.Shapes
import qs.core

Item {
    id: root

    property real value: 0.0
    property real strokeWidth: 6
    
    Behavior on value { 
        NumberAnimation { 
            duration: 1000 
            easing.type: Easing.Linear 
        } 
    }
    property color strokeColor: ThemeManager.accentColor
    property color backgroundColor: Qt.rgba(1, 1, 1, 0.05)
    
    implicitWidth: 200
    implicitHeight: 200

    Shape {
        id: shape
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            strokeColor: root.backgroundColor
            fillColor: "transparent"
            strokeWidth: root.strokeWidth
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: (root.width - root.strokeWidth) / 2
                radiusY: (root.height - root.strokeWidth) / 2
                startAngle: -90
                sweepAngle: 360
            }
        }

        ShapePath {
            strokeColor: root.strokeColor
            fillColor: "transparent"
            strokeWidth: root.strokeWidth
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: (root.width - root.strokeWidth) / 2
                radiusY: (root.height - root.strokeWidth) / 2
                startAngle: -90
                sweepAngle: root.value * 360
            }
        }
    }
}
