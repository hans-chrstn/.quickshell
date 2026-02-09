import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.modules.bars

BaseBar {
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    
    implicitHeight: FrameConfig.thickness
    
    Rectangle {
        anchors.fill: parent
        color: FrameConfig.color
    }
}
