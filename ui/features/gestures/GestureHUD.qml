import QtQuick
import Quickshell
import qs.core

PanelWindow {
    id: hudWindow
    width: 400
    height: 400
    color: "transparent"
    
    visible: GestureManager.isGestureActive

    Rectangle {
        anchors.fill: parent
        color: "red"
        radius: 20
        
        opacity: GestureManager.isGestureActive ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }
    }
}
