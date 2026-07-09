import QtQuick
import qs.core
import qs.ui.shared.effects

Item {
    id: root
    
    property bool isPressed: tapHandler.pressed || extraTapHandler.pressed
    property bool isHovered: hoverHandler.hovered
    property alias cursorShape: hoverHandler.cursorShape
    property real cornerRadius: ThemeManager.globalCornerRadius
    
    property string tooltip: ""
    property string tooltipDescription: ""
    
    property Item highlightTarget: null
    property real highlightCornerRadius: root.cornerRadius
    
    property real hoverScale: 1.03
    property real pressScale: 0.96
    property int animationDuration: ThemeManager.animationDuration
    property int pressDuration: 90
    
    signal clicked()

    scale: isPressed ? pressScale : (isHovered ? hoverScale : 1.0)
    
    Behavior on scale { 
        NumberAnimation { 
            duration: root.isPressed ? root.pressDuration : root.animationDuration
            easing.type: root.isPressed ? Easing.OutCubic : Easing.OutBack
            easing.overshoot: 1.2
        } 
    }

    onIsPressedChanged: {
        if (root.highlightTarget && root.highlightTarget.hasOwnProperty("isPressed")) {
            root.highlightTarget.isPressed = root.isPressed
        }
    }

    StateLayer {
        visible: !root.highlightTarget
        anchors.fill: parent
        
        cornerRadius: root.highlightCornerRadius
        isPressed: root.isPressed
        mouseX: tapHandler.pressed ? tapHandler.point.position.x : extraTapHandler.point.position.x
        mouseY: tapHandler.pressed ? tapHandler.point.position.y : extraTapHandler.point.position.y
        z: 10
    }

    TapHandler {
        id: tapHandler
        onTapped: root.clicked()
    }

    TapHandler {
        id: extraTapHandler
        acceptedButtons: Qt.AllButtons
    }

    HoverHandler {
        id: hoverHandler
        cursorShape: Qt.PointingHandCursor
        onHoveredChanged: {
            if (hovered && root.tooltip !== "") {
                tooltipTimer.restart()
            } else {
                tooltipTimer.stop()
                TooltipManager.hide(root)
            }
        }
    }

    Timer {
        id: tooltipTimer
        interval: 500
        onTriggered: {
            TooltipManager.show(root, root.tooltip, root.tooltipDescription)
        }
    }
}
