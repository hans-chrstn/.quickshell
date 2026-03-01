import QtQuick
import qs.core
import qs.ui.shared.shapes

Item {
    id: root
    
    property bool isAtTop: true
    property bool isAtLeft: true
    property real cornerRadius: ThemeManager.dynamicIslandCornerRadius
    property color cornerBackgroundColor: ThemeManager.backgroundPrimaryColor
    property real visualRotation: 0
    
    width: cornerRadius
    height: cornerRadius
    clip: true
    z: 100

    InvertedCornerShape {
        anchors.fill: parent
        isAtTop: root.isAtTop
        isAtLeft: root.isAtLeft
        visualRotation: root.visualRotation
        cornerRadius: root.cornerRadius
        cornerBackgroundColor: root.cornerBackgroundColor
    }
}
