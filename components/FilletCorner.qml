import QtQuick
import qs.services
import qs.components

Item {
    id: root
    
    property bool isTop: true
    property bool isLeft: true
    property real cornerRadius: ThemeService.dynamicIslandCornerRadius
    property color cornerColor: ThemeService.backgroundMain
    property real filletRotation: 0
    
    width: cornerRadius
    height: cornerRadius
    clip: true
    z: 100

    RoundedCornerShape {
        anchors.fill: parent
        isTop: root.isTop
        isLeft: root.isLeft
        rotation: root.filletRotation
        cornerRadius: root.cornerRadius
        cornerColor: root.cornerColor
    }
}
