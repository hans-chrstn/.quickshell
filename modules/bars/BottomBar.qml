import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

PanelWindow {
    property var modelData
    screen: modelData
    anchors {
        bottom: true
        left: true
        right: true
    }
    
    implicitHeight: FrameConfig.thickness
    color: "transparent"
    
    Rectangle {
        anchors.fill: parent
        color: FrameConfig.color
    }
}
