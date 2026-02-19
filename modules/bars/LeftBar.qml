import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.modules.bars

BaseBar {
    anchors.left: true
    anchors.top: true
    anchors.bottom: true
    
    margins {
        top: 0
        bottom: 0
    }
    
    implicitWidth: FrameConfig.thickness
    color: FrameConfig.color
}