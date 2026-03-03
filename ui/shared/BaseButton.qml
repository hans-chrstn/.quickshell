import QtQuick
import qs.core
import qs.ui.shared.effects

Item {
    id: root
    
    property bool isPressed: tapHandler.pressed
    property bool isHovered: hoverHandler.hovered
    property alias cursorShape: hoverHandler.cursorShape
    property real cornerRadius: ThemeManager.globalCornerRadius
    
    property real hoverScale: 1.05
    property real pressScale: 0.92
    property int animationDuration: ThemeManager.animationDuration
    property int pressDuration: 100
    
    signal clicked()

    scale: isPressed ? pressScale : (isHovered ? hoverScale : 1.0)
    
    Behavior on scale { 
        NumberAnimation { 
            duration: root.isPressed ? root.pressDuration : root.animationDuration
            easing.type: root.isPressed ? Easing.OutCubic : Easing.OutBack
            easing.overshoot: 1.2
        } 
    }

    StateLayer {
        anchors.fill: parent
        cornerRadius: root.cornerRadius
        isPressed: root.isPressed
        mouseX: tapHandler.point.position.x
        mouseY: tapHandler.point.position.y
        z: 10
    }

    TapHandler {
        id: tapHandler
        onTapped: root.clicked()
    }

    HoverHandler {
        id: hoverHandler
        cursorShape: Qt.PointingHandCursor
    }
}
