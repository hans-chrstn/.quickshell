import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services

ColumnLayout {
    id: root
    spacing: 20
    
    property alias showSettings: rootHeader.showSettings

    RowLayout {
        id: rootHeader
        Layout.fillWidth: true
        property bool showSettings: false

        ColumnLayout {
            spacing: 4
            Text { 
                text: rootHeader.showSettings ? "SETTINGS" : "EXPLORER"
                color: "white"
                font.pixelSize: 10
                font.weight: Font.Black
                font.letterSpacing: 3
                opacity: 0.3 
            }
            Rectangle { 
                Layout.preferredHeight: 24
                Layout.preferredWidth: Math.min(pathText.implicitWidth + 24, 250)
                radius: 12
                color: "white"
                opacity: 0.12
                border.color: Qt.rgba(1, 1, 1, 0.15)
                border.width: 1
                visible: !rootHeader.showSettings
                
                Text { 
                    id: pathText
                    anchors.centerIn: parent
                    text: FileBrowserService.currentPath
                    color: "white"
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
                width: 36; height: 36; radius: 10
                color: rootHeader.showSettings ? FrameConfig.accentColor : "white"
                opacity: rootHeader.showSettings ? 1.0 : 0.1
                Text { 
                    anchors.centerIn: parent; text: "󰒓"
                    color: rootHeader.showSettings ? "black" : "white"
                    font.pixelSize: 18 
                }
                TapHandler { onTapped: rootHeader.showSettings = !rootHeader.showSettings }
                HoverHandler { id: hSet; cursorShape: Qt.PointingHandCursor }
                scale: hSet.hovered ? 1.1 : 1.0
                Behavior on scale { NumberAnimation { duration: 200 } }
            }
            
            Rectangle {
                width: 36; height: 36; radius: 10
                color: FileBrowserService.showHidden ? FrameConfig.accentColor : "white"
                opacity: FileBrowserService.showHidden ? 1.0 : 0.1
                visible: !rootHeader.showSettings
                
                Text { 
                    id: hHiddenText
                    anchors.centerIn: parent; text: "󰈈"
                    color: FileBrowserService.showHidden ? "black" : "white"
                    font.pixelSize: 18 
                }
                TapHandler { onTapped: FileBrowserService.showHidden = !FileBrowserService.showHidden }
                HoverHandler { id: hHidden; cursorShape: Qt.PointingHandCursor }
                scale: hHidden.hovered ? 1.1 : 1.0
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
                
                Behavior on contentY { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
                
                delegate: Item { 
                    width: 114
                    height: 114
                    
                    Rectangle { 
                        anchors.fill: parent
                        radius: 20
                        color: "#0A0A0B"
                        border.color: (WallpaperService.previewWallpaper === model.path) ? FrameConfig.accentColor : Qt.rgba(1, 1, 1, 0.05)
                        border.width: (WallpaperService.previewWallpaper === model.path) ? 2 : 1
                        clip: true
                        
                        Rectangle { 
                            anchors.fill: parent
                            radius: 20
                            color: "transparent"
                            border.color: Qt.rgba(1, 1, 1, 0.05)
                            border.width: 1
                            anchors.margins: 1 
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
                                    color: model.isDir ? FrameConfig.accentColor : "white"
                                    font.pixelSize: model.isDir ? 42 : 36
                                    opacity: (WallpaperService.previewWallpaper === model.path || hh.hovered) ? 1.0 : 0.3
                                    Behavior on opacity { NumberAnimation { duration: 200 } } 
                                }
                            }
                            
                            Text { 
                                text: model.name
                                color: "white"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                opacity: (WallpaperService.previewWallpaper === model.path || hh.hovered) ? 0.9 : 0.4
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
                                if (model.isDir) FileBrowserService.changeDirectory(model.path)
                                else WallpaperService.previewWallpaper = model.path 
                            } 
                        }
                        
                        scale: hh.hovered ? 1.05 : 1.0
                        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                        HoverHandler { id: hh }
                    }
                }
            }
        }
    }
}
