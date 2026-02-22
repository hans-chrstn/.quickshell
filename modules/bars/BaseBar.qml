import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

PanelWindow {
    id: baseBarRoot
    color: "transparent"

    property var modelData
    screen: modelData

    property int barThickness: ThemeService.thickness
    property color barColor: ThemeService.color
}
