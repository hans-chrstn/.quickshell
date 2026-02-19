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
    
    implicitHeight: FrameConfig.appIslandExpandedHeight
    
    exclusiveZone: FrameConfig.thickness
    color: "transparent"

    mask: Region {
        Region { item: barRect; intersection: Intersection.Combine }
        Region { item: appIsland; intersection: Intersection.Combine }
    }

    Rectangle {
        id: barRect
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: FrameConfig.thickness
        color: FrameConfig.color

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.alpha("white", 0.03) }
                GradientStop { position: 1.0; color: "transparent" }
            }
            rotation: 180
        }
    }

    AppIsland {
        id: appIsland
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        
        barHeight: FrameConfig.thickness
        barColor: FrameConfig.color
    }
}