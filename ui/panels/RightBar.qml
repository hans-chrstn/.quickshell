import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.ui.panels
import qs.ui.shared

SystemPanel {
    anchors.right: true
    anchors.top: true
    anchors.bottom: true
    
    margins {
        top: 0
        bottom: 0
    }
    
    implicitWidth: ThemeManager.globalThickness
    color: ThemeManager.backgroundColor
}