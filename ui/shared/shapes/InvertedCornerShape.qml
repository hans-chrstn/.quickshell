import QtQuick
import QtQuick.Shapes
import qs.core

Item {
    id: root

    property bool isAtTop: false
    property bool isAtLeft: false
    property bool isAtBottom: false
    property real cornerRadius: 0
    property color cornerBackgroundColor: ThemeManager.backgroundPrimaryColor
    property real visualRotation: 0

    property string invertedCornerPath: {
        let widthValue = root.width
        let heightValue = root.height
        let radiusValue = root.cornerRadius

        if (root.isAtTop && root.isAtLeft) {
            return `M 0 0 L ${widthValue} 0 L ${widthValue} ${heightValue} A ${radiusValue} ${radiusValue} 0 0 0 0 0 Z`
        } else if (root.isAtTop && !root.isAtLeft) {
            return `M ${widthValue} 0 L 0 0 L 0 ${heightValue} A ${radiusValue} ${radiusValue} 0 0 1 ${widthValue} 0 Z`
        } else if (root.isAtBottom && root.isAtLeft) {
            return `M 0 ${heightValue} L ${widthValue} ${heightValue} L ${widthValue} 0 A ${radiusValue} ${radiusValue} 0 0 1 0 ${heightValue} Z`
        } else if (root.isAtBottom && !root.isAtLeft) {
            return `M ${widthValue} ${heightValue} L 0 ${heightValue} L 0 0 A ${radiusValue} ${radiusValue} 0 0 0 ${widthValue} ${heightValue} Z`
        }
        return ""
    }

    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4
        rotation: root.visualRotation
        
        ShapePath {
            fillColor: root.cornerBackgroundColor
            strokeWidth: 0
            PathSvg { 
                path: root.invertedCornerPath 
            }
        }
    }
}
