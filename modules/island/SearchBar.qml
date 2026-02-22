import QtQuick
import QtQuick.Layouts
import QtMultimedia
import Quickshell
import qs.config
import qs.components
import qs.services

Rectangle {
    id: root
    
    property bool active: false
    property alias text: searchInput.text
    
    onActiveChanged: {
        SfxService.playButton1()
        if (active) {
            Qt.callLater(() => {
                searchInput.forceActiveFocus()
            })
        } else {
            root.focus = true
        }
    }
    
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.topMargin: root.active ? 12 : 6
    
    width: root.active ? (parent.width - 40) : 24
    height: root.active ? FrameConfig.appIslandSearchBarHeight : 4
    radius: root.active ? FrameConfig.appIslandSearchBarRadius : 2
    
    color: root.active ? Qt.rgba(0.1, 0.1, 0.12, 0.95) : "white"
    opacity: root.active ? 1.0 : 0.2
    
    border.color: "white"
    border.width: root.active ? 1 : 0
    
    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
    Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
    Behavior on anchors.topMargin { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
    Behavior on radius { NumberAnimation { duration: 400 } }
    Behavior on color { ColorAnimation { duration: 400 } }
    Behavior on opacity { NumberAnimation { duration: 400 } }
    Behavior on border.width { NumberAnimation { duration: 400 } }

    MouseArea {
        anchors.fill: parent
        onPressed: (mouse) => mouse.accepted = true
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16; anchors.rightMargin: 12; spacing: 10
        opacity: root.active ? 1.0 : 0.0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 200 } }
        
        Text { 
            text: "󰍉"
            color: "white"
            opacity: 0.5
            font.pixelSize: 18 
        }
        
        TextInput {
            id: searchInput
            Layout.fillWidth: true; verticalAlignment: TextInput.AlignVCenter
            color: FrameConfig.appIslandSearchBarColor
            font.pixelSize: FrameConfig.appIslandSearchInputFontSize
            font.weight: Font.Medium
            selectionColor: FrameConfig.accentColor
            
            Text {
                text: "Search applications..."
                color: "white"
                opacity: 0.3
                font.pixelSize: 14
                visible: !searchInput.text && !searchInput.activeFocus
            }
        }
        
        Text { 
            text: "󰅖"
            color: "white"
            opacity: 0.4
            font.pixelSize: 16 
            
            TapHandler { 
                onTapped: {
                    root.active = false
                }
            }
            HoverHandler { cursorShape: Qt.PointingHandCursor }
            
            scale: shhClose.hovered ? 1.2 : 1.0
            Behavior on scale { NumberAnimation { duration: 200 } }
            HoverHandler { id: shhClose }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !root.active
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.active = true
        }
    }
}
