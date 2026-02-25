import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services

Rectangle {
    id: root
    
    property bool active: false
    property alias text: searchInput.text
    
    onActiveChanged: {
        SoundManager.playClick()
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
    height: root.active ? ThemeManager.appIslandSearchBarHeight : 4
    radius: root.active ? ThemeManager.appIslandSearchBarRadius : 2
    
    color: root.active ? ThemeManager.backgroundPrimaryColor : ThemeManager.contentOnBackgroundColor
    opacity: root.active ? 1.0 : 0.2
    
    border.color: ThemeManager.contentOnBackgroundColor
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
            color: ThemeManager.contentOnBackgroundColor
            opacity: 0.5
            font.pixelSize: 18 
        }
        
        TextInput {
            id: searchInput
            Layout.fillWidth: true; verticalAlignment: TextInput.AlignVCenter
            color: ThemeManager.appIslandSearchBarColor
            font.pixelSize: ThemeManager.appIslandSearchInputFontSize
            font.weight: Font.Medium
            selectionColor: ThemeManager.accentColor
            
            Text {
                text: "Search applications..."
                color: ThemeManager.contentOnBackgroundColor
                opacity: 0.3
                font.pixelSize: 14
                visible: !searchInput.text && !searchInput.activeFocus
            }
        }
        
        Text { 
            text: "󰅖"
            color: ThemeManager.contentOnBackgroundColor
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
