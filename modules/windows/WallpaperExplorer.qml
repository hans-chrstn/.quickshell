import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.services
import qs.components

FocusScope {
    id: root
    
    property alias showSettings: rootHeader.showSettings
    property alias gridView: grid
    property alias settingsBtn: settingsButton

    Keys.onUpPressed: settingsButton.forceActiveFocus()
    Keys.onDownPressed: grid.forceActiveFocus()

    ColumnLayout {
        anchors.fill: parent
        spacing: 20

        RowLayout {
            id: rootHeader
            Layout.fillWidth: true
            property bool showSettings: false

            ColumnLayout {
                spacing: 4
                Text { 
                    text: rootHeader.showSettings ? "SETTINGS" : "EXPLORER"
                    color: ThemeService.backgroundContent
                    font.pixelSize: 10
                    font.weight: Font.Black
                    font.letterSpacing: 3
                    opacity: 0.3 
                }
                Rectangle { 
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: Math.min(pathText.implicitWidth + 24, 250)
                    radius: 12
                    color: ThemeService.backgroundContent
                    opacity: 0.12
                    border.color: ThemeService.outlineMain
                    border.width: 1
                    visible: !rootHeader.showSettings
                    
                    Text { 
                        id: pathText
                        anchors.centerIn: parent
                        text: FileBrowserService.currentPath
                        color: ThemeService.backgroundContent
                        font.pixelSize: 9
                        font.family: "Monospace"
                        opacity: 1.0
                        elide: Text.ElideLeft
                        width: parent.width - 20 
                    }
                }
            }
            
            Item { Layout.fillWidth: true }
            
            Row {
                spacing: 10
                
                Rectangle {
                    id: settingsButton
                    width: 36; height: 36; radius: 10
                    color: (rootHeader.showSettings || activeFocus) ? ThemeService.accentColor : ThemeService.backgroundContent
                    opacity: (rootHeader.showSettings || activeFocus) ? 1.0 : 0.1
                    
                    focus: true
                    Keys.onSpacePressed: rootHeader.showSettings = !rootHeader.showSettings
                    Keys.onEnterPressed: rootHeader.showSettings = !rootHeader.showSettings
                    Keys.onReturnPressed: rootHeader.showSettings = !rootHeader.showSettings
                    Keys.onRightPressed: hiddenBtn.forceActiveFocus()

                    Text { 
                        anchors.centerIn: parent; text: "󰒓"
                        color: (rootHeader.showSettings || parent.activeFocus) ? ThemeService.primaryContent : ThemeService.backgroundContent
                        font.pixelSize: 18 
                    }
                    
                    border.color: activeFocus ? "white" : "transparent"
                    border.width: activeFocus ? 2 : 0

                    TapHandler { onTapped: rootHeader.showSettings = !rootHeader.showSettings }
                    HoverHandler { id: hSet; cursorShape: Qt.PointingHandCursor }
                    scale: (hSet.hovered || activeFocus) ? 1.1 : 1.0
                    Behavior on scale { NumberAnimation { duration: 200 } }
                }
                
                Rectangle {
                    id: hiddenBtn
                    width: 36; height: 36; radius: 10
                    color: (FileBrowserService.showHidden || activeFocus) ? ThemeService.accentColor : ThemeService.backgroundContent
                    opacity: (FileBrowserService.showHidden || activeFocus) ? 1.0 : 0.1
                    visible: !rootHeader.showSettings
                    
                    Keys.onSpacePressed: FileBrowserService.showHidden = !FileBrowserService.showHidden
                    Keys.onEnterPressed: FileBrowserService.showHidden = !FileBrowserService.showHidden
                    Keys.onReturnPressed: FileBrowserService.showHidden = !FileBrowserService.showHidden
                    Keys.onLeftPressed: settingsButton.forceActiveFocus()

                    Text { 
                        anchors.centerIn: parent; text: "󰈈"
                        color: (FileBrowserService.showHidden || parent.activeFocus) ? ThemeService.primaryContent : ThemeService.backgroundContent
                        font.pixelSize: 18 
                    }
                    
                    border.color: activeFocus ? "white" : "transparent"
                    border.width: activeFocus ? 2 : 0

                    TapHandler { onTapped: FileBrowserService.showHidden = !FileBrowserService.showHidden }
                    HoverHandler { id: hHidden; cursorShape: Qt.PointingHandCursor }
                    scale: (hHidden.hovered || activeFocus) ? 1.1 : 1.0
                    Behavior on scale { NumberAnimation { duration: 200 } }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !rootHeader.showSettings
            
            ClippingRectangle {
                anchors.fill: parent
                color: "transparent"
                radius: 0
                
                GridView { 
                    id: grid
                    anchors.fill: parent
                    anchors.margins: 10
                    model: FileBrowserService.model
                    cellWidth: 124
                    cellHeight: 124
                    clip: false
                    
                    onCurrentIndexChanged: {
                        positionViewAtIndex(currentIndex, GridView.Contain)
                        let item = model.get(currentIndex)
                        if (item && !item.isDir) {
                            WallpaperService.previewWallpaper = item.path
                        }
                    }
                    
                    function activateItem() {
                        let item = model.get(currentIndex)
                        if (item && item.isDir) FileBrowserService.changeDirectory(item.path)
                    }

                    Keys.onReturnPressed: activateItem()
                    Keys.onEnterPressed: activateItem()
                    Keys.onSpacePressed: activateItem()

                    Behavior on contentY { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
                    
                    delegate: Item { 
                        width: 114
                        height: 114
                        
                        readonly property bool isSelected: WallpaperService.previewWallpaper === model.path
                        readonly property bool isFocused: GridView.isCurrentItem && grid.activeFocus
                        readonly property bool isActive: isFocused || hh.hovered || isSelected

                        Rectangle { 
                            anchors.fill: parent
                            radius: 20
                            color: ThemeService.backgroundMain
                            
                            border.color: isFocused ? "white" : (isActive ? ThemeService.accentColor : ThemeService.outlineVariant)
                            border.width: isActive ? 2 : 1
                            clip: true
                            
                            Rectangle {
                                anchors.fill: parent
                                radius: 20; color: ThemeService.backgroundContent
                                opacity: isFocused ? 0.1 : (hh.hovered ? 0.05 : 0)
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                            }

                            ColumnLayout { 
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10
                                
                                Item { 
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Text { 
                                        anchors.centerIn: parent
                                        text: model.path === ".." ? "󰁝" : (model.isDir ? "󰉋" : "󰸉")
                                        color: model.isDir ? ThemeService.accentColor : ThemeService.backgroundContent
                                        font.pixelSize: model.isDir ? 42 : 36
                                        opacity: isActive ? 1.0 : 0.3
                                        Behavior on opacity { NumberAnimation { duration: 200 } } 
                                    }
                                }
                                
                                Text { 
                                    text: model.name
                                    color: ThemeService.backgroundContent
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    opacity: isActive ? 0.9 : 0.4
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight 
                                }
                            }
                            
                            MouseArea { 
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { 
                                    grid.currentIndex = index
                                    if (model.isDir) FileBrowserService.changeDirectory(model.path)
                                    else WallpaperService.previewWallpaper = model.path 
                                    grid.forceActiveFocus()
                                } 
                            }
                            
                            scale: isActive ? 1.05 : 1.0
                            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                            HoverHandler { id: hh }
                        }
                    }
                }
            }
        }
    }
}
