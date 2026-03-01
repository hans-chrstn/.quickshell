import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

RowLayout {
    id: rootHeader
    Layout.fillWidth: true
    property bool showSettings: false
    
    property alias settingsButton: settingsBtn

    ColumnLayout {
        spacing: 4
        
        StyledLabel { 
            text: rootHeader.showSettings ? "SETTINGS" : "EXPLORER"
            type: "configHeader"
            opacity: 0.3 
        }
        
        Rectangle { 
            Layout.preferredHeight: 24
            Layout.preferredWidth: Math.min(pathText.implicitWidth + 24, 250)
            radius: 12
            color: ThemeManager.contentOnBackgroundColor
            opacity: 0.12
            border.color: ThemeManager.outlinePrimaryColor
            border.width: 1
            visible: !rootHeader.showSettings
            
            StyledLabel { 
                id: pathText
                anchors.centerIn: parent
                text: FileBrowserManager.currentPath
                type: "monospace"
                font.family: ThemeManager.fontFamily
                opacity: 1.0
                elideMode: Text.ElideLeft
                width: parent.width - 20 
            }
        }
    }
    
    Item {
        Layout.fillWidth: true 
    }
    
    Row {
        spacing: 10
        
        Rectangle {
            id: settingsBtn
            width: 36
            height: 36
            radius: 10
            color: (rootHeader.showSettings || activeFocus) ? ThemeManager.accentColor : ThemeManager.surfacePrimaryColor
            opacity: (rootHeader.showSettings || activeFocus) ? 1.0 : (hSet.hovered ? 0.8 : 0.5)
            
            focus: true
            Keys.onSpacePressed: rootHeader.showSettings = !rootHeader.showSettings
            Keys.onEnterPressed: rootHeader.showSettings = !rootHeader.showSettings
            Keys.onReturnPressed: rootHeader.showSettings = !rootHeader.showSettings
            Keys.onRightPressed: hiddenBtn.forceActiveFocus()

            StyledLabel { 
                anchors.centerIn: parent
                text: "󰒓"
                type: "icon"
                customColor: (rootHeader.showSettings || parent.activeFocus) ? ThemeManager.contentPrimaryColor : ThemeManager.contentOnBackgroundColor
            }
            
            border.color: activeFocus ? "white" : "transparent"
            border.width: activeFocus ? 2 : 0

            TapHandler {
                onTapped: {
                    rootHeader.showSettings = !rootHeader.showSettings
                }
            }
            HoverHandler {
                id: hSet
                cursorShape: Qt.PointingHandCursor 
            }
            
            scale: (hSet.hovered || activeFocus) ? 1.1 : 1.0
            Behavior on scale {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutQuart 
                } 
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 200 
                } 
            }
            Behavior on color {
                ColorAnimation {
                    duration: 200 
                } 
            }
        }
        
        Rectangle {
            id: hiddenBtn
            width: 36
            height: 36
            radius: 10
            color: (FileBrowserManager.isShowingHiddenFiles || activeFocus) ? ThemeManager.accentColor : ThemeManager.surfacePrimaryColor
            opacity: (FileBrowserManager.isShowingHiddenFiles || activeFocus) ? 1.0 : (hHidden.hovered ? 0.8 : 0.5)
            visible: !rootHeader.showSettings
            
            Keys.onSpacePressed: FileBrowserManager.isShowingHiddenFiles = !FileBrowserManager.isShowingHiddenFiles
            Keys.onEnterPressed: FileBrowserManager.isShowingHiddenFiles = !FileBrowserManager.isShowingHiddenFiles
            Keys.onReturnPressed: FileBrowserManager.isShowingHiddenFiles = !FileBrowserManager.isShowingHiddenFiles
            Keys.onLeftPressed: settingsBtn.forceActiveFocus()

            StyledLabel { 
                anchors.centerIn: parent
                text: "󰈈"
                type: "icon"
                customColor: (FileBrowserManager.isShowingHiddenFiles || parent.activeFocus) ? ThemeManager.contentPrimaryColor : ThemeManager.contentOnBackgroundColor
            }
            
            border.color: activeFocus ? "white" : "transparent"
            border.width: activeFocus ? 2 : 0

            TapHandler {
                onTapped: {
                    FileBrowserManager.isShowingHiddenFiles = !FileBrowserManager.isShowingHiddenFiles
                }
            }
            HoverHandler {
                id: hHidden
                cursorShape: Qt.PointingHandCursor 
            }
            
            scale: (hHidden.hovered || activeFocus) ? 1.1 : 1.0
            Behavior on scale {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutQuart 
                } 
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 200 
                } 
            }
            Behavior on color {
                ColorAnimation {
                    duration: 200 
                } 
            }
        }
    }
}
