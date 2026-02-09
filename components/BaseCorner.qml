import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import "../config"

PanelWindow {
    id: root
    property var modelData
    screen: modelData

    property int sThick: FrameConfig.thickness
    property int iRadius: 10
    property int sRadius: sThick + iRadius
    property color sColor: FrameConfig.color
    
implicitWidth: sRadius
implicitHeight: sRadius
}