import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config

Rectangle {
    id: root
    
    property string icon: ""
    property string label: ""
    property bool active: false
    property bool enabled: true
    property color activeColor: FrameConfig.accentColor
    
    signal clicked()

    width: 48; height: 48; radius: 16
    color: active ? activeColor : "white"
    opacity: enabled ? (active ? 1.0 : 0.1) : 0.03
    
    Behavior on color { ColorAnimation { duration: 250 } }
    Behavior on opacity { NumberAnimation { duration: 250 } }

    Item {
        anchors.centerIn: parent
        width: 24; height: 24
        
        Text {
            anchors.centerIn: parent
            text: root.icon
            color: root.active ? "black" : "white"
            font.pixelSize: 20
            opacity: root.enabled ? (root.active ? 1.0 : 0.8) : 0.3
        }
        
        Rectangle {
            anchors.centerIn: parent
            width: 26; height: 2; radius: 1
            color: "white"; opacity: 0.6
            rotation: 45
            visible: !root.enabled
        }
    }

    TapHandler { 
        enabled: root.enabled
        onTapped: root.clicked() 
    }
}
