import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property bool isTop: false
    property bool isLeft: false
    property bool isBottom: false
    property real cornerRadius: 0
    property color cornerColor: "#222222"
    property real rotation: 0

    property string cornerPath: {
        var W = root.width;
        var H = root.height;
        var R = root.cornerRadius;

        if (root.isTop && root.isLeft) {
            return `M 0 0 L ${W} 0 L ${W} ${H} A ${R} ${R} 0 0 0 0 0 Z`;
        } else if (root.isTop && !root.isLeft) {
            return `M ${W} 0 L 0 0 L 0 ${H} A ${R} ${R} 0 0 1 ${W} 0 Z`;
        } else if (root.isBottom && root.isLeft) {
            return `M 0 ${H} L ${W} ${H} L ${W} 0 A ${R} ${R} 0 0 1 0 ${H} Z`;
        } else if (root.isBottom && !root.isLeft) {
            return `M ${W} ${H} L 0 ${H} L 0 0 A ${R} ${R} 0 0 0 ${W} ${H} Z`;
        }
        return "";
    }

    property string strokePath: {
        var W = root.width;
        var H = root.height;
        var R = root.cornerRadius;

        if (root.isTop && root.isLeft) {
            return `M ${W} ${H} A ${R} ${R} 0 0 0 0 0`;
        } else if (root.isTop && !root.isLeft) {
            return `M 0 ${H} A ${R} ${R} 0 0 1 ${W} 0`;
        } else if (root.isBottom && root.isLeft) {
            return `M ${W} 0 A ${R} ${R} 0 0 1 0 ${H}`;
        } else if (root.isBottom && !root.isLeft) {
            return `M 0 0 A ${R} ${R} 0 0 0 ${W} ${H}`;
        }
        return "";
    }

    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4
        rotation: root.rotation
        
        ShapePath {
            fillColor: root.cornerColor
            strokeWidth: 0
            PathSvg { path: root.cornerPath }
        }
    }
}
