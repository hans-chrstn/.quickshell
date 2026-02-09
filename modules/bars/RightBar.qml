import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

PanelWindow {
    property var modelData
    screen: modelData
    
    anchors {
        right: true
        top: true
        bottom: true
    }
    
    margins {
        top: 0
        bottom: 0
    }
    
    implicitWidth: FrameConfig.thickness
    color: FrameConfig.color
}