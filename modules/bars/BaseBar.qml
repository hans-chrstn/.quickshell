import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

PanelWindow {
    id: baseBarRoot

    property var modelData
    screen: modelData

    property int barThickness: FrameConfig.thickness
    property color barColor: FrameConfig.color
}
