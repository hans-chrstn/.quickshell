import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property bool isTop: false
    property bool isLeft: false
    property real cornerRadius: 0
    property color cornerColor: "#222222"

    property string cornerPath: {
        var W = root.width;
        var H = root.height;
        var R = root.cornerRadius;

        if (root.isLeft) {
            return `M 0 0 L ${W} 0 L ${W} ${H} A ${R} ${R} 0 0 0 0 0 Z`;
        } else {
            return `M ${W} 0 L 0 0 L 0 ${H} A ${R} ${R} 0 0 1 ${W} 0 Z`;
        }
    }

    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4
        
        ShapePath {
            fillColor: root.cornerColor
            strokeWidth: 0
            strokeColor: "transparent"
           
            PathSvg { path: root.cornerPath }
        }
    }
}
