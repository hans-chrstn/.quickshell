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

    exclusiveZone: FrameConfig.thickness
    color: "transparent"

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: FrameConfig.thickness
        color: FrameConfig.color
    }

    AppIsland {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        
        barHeight: FrameConfig.thickness
        barColor: FrameConfig.color

        onExpandedChanged: {
            if (expanded) {
                root.expandedMode = true
                collapseTimer.stop()
            }
            else {
                collapseTimer.restart()
            }
        }
    }
}