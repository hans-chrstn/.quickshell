import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core

PanelWindow {
    id: root
    
    color: "transparent"

    property alias modelData: root.screen
    property color panelBackgroundColor: ThemeManager.backgroundColor
}
