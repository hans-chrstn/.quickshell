import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.modules.bars
import qs.modules.island

BaseBar {
    id: root

    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    
    property bool expandedMode: false

    implicitHeight: expandedMode ? FrameConfig.appIslandExpandedHeight : FrameConfig.thickness
    
    Timer {
        id: collapseTimer
        interval: FrameConfig.animDuration + FrameConfig.collapseTimerDelay
        onTriggered: root.expandedMode = false
    }

    color: "transparent"

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: FrameConfig.thickness
        color: FrameConfig.color
    }

    Rectangle {
        id: hoverArea
        width: 200
        height: root.implicitHeight
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        color: "transparent"

        HoverHandler {
            onHoveredChanged: {
                if (hovered) {
                    root.expandedMode = true
                    collapseTimer.stop()
                } else {
                    collapseTimer.restart()
                }
            }
        }
    }

    AppIsland {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        
        barHeight: FrameConfig.thickness
        barColor: FrameConfig.color
        expanded: root.expandedMode
    }
}
