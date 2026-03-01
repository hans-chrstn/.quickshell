import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.ui.shared

Rectangle {
    id: root
    
    property bool isSearchActive: false
    property alias searchText: searchInput.text
    
    onIsSearchActiveChanged: {
        SoundManager.playClick()
        if (isSearchActive) {
            Qt.callLater(() => {
                searchInput.forceActiveFocus()
            })
        } else {
            root.focus = true
        }
    }
    
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.topMargin: root.isSearchActive ? 12 : 6
    
    width: root.isSearchActive ? (parent.width - 40) : 24
    height: root.isSearchActive ? ThemeManager.appIslandSearchBarHeight : 4
    radius: root.isSearchActive ? ThemeManager.appIslandSearchBarRadius : 2
    
    color: root.isSearchActive ? ThemeManager.backgroundPrimaryColor : ThemeManager.contentOnBackgroundColor
    opacity: root.isSearchActive ? 1.0 : 0.2
    
    border.color: ThemeManager.contentOnBackgroundColor
    border.width: root.isSearchActive ? 1 : 0
    
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
        anchors.leftMargin: 16
        anchors.rightMargin: 12
        spacing: 10
        opacity: root.isSearchActive ? 1.0 : 0.0
        visible: opacity > 0.01
        
        Behavior on opacity { 
            NumberAnimation { 
                duration: 200 
            } 
        }
        
        StyledLabel { 
            text: "󰍉"
            type: "body"
            customColor: ThemeManager.contentOnBackgroundColor
            opacity: 0.5
            font.pixelSize: 18 
        }
        
        TextInput {
            id: searchInput
            Layout.fillWidth: true
            verticalAlignment: TextInput.AlignVCenter
            color: ThemeManager.appIslandSearchBarColor
            font.family: ThemeManager.fontFamily
            font.pixelSize: ThemeManager.appIslandSearchInputFontSize
            font.weight: Font.Medium
            selectionColor: ThemeManager.accentColor
            
            StyledLabel {
                text: "Search applications..."
                type: "body"
                customColor: ThemeManager.contentOnBackgroundColor
                opacity: 0.3
                font.pixelSize: 14
                visible: !searchInput.text && !searchInput.activeFocus
            }
        }
        
        StyledLabel { 
            text: "󰅖"
            type: "body"
            customColor: ThemeManager.contentOnBackgroundColor
            opacity: closeHoverHandler.hovered ? 1.0 : 0.4
            font.pixelSize: 16 
            
            TapHandler { 
                onTapped: {
                    root.isSearchActive = false
                }
            }
            HoverHandler { cursorShape: Qt.PointingHandCursor }
            
            scale: closeHoverHandler.hovered ? 1.2 : 1.0
            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
            Behavior on opacity { NumberAnimation { duration: 200 } }
            HoverHandler { id: closeHoverHandler }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !root.isSearchActive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.isSearchActive = true
        }
    }
}
