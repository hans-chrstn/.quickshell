import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.core
import qs.ui.shared

Item {
    id: delegateRoot
    width: 114
    height: 114

    property var modelData
    property var gridView

    readonly property string itemPath: modelData.path
    readonly property bool isSelected: WallpaperManager.previewWallpaperPath === delegateRoot.itemPath
    readonly property bool isFocused: GridView.isCurrentItem && gridView.activeFocus
    readonly property bool isActive: isFocused || hh.hovered || isSelected

    Rectangle {
        anchors.fill: parent
        radius: 20
        color: ThemeManager.backgroundPrimaryColor
        
        border.color: isFocused ? "white" : (isActive ? ThemeManager.accentColor : ThemeManager.outlineVariantColor)
        border.width: isActive ? 2 : 1
        clip: true
        
        Rectangle {
            anchors.fill: parent
            radius: 20
            color: ThemeManager.contentOnBackgroundColor
            opacity: isFocused ? 0.1 : (hh.hovered ? 0.05 : 0)
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 4
            
            ClippingRectangle {
                id: thumbContainer
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 16
                color: "transparent"
                
                Image {
                    id: thumbImage
                    anchors.fill: parent
                    visible: modelData.isImage && !modelData.isDir && modelData.path !== ".."
                    source: visible ? "file://" + modelData.path : ""
                    sourceSize: Qt.size(200, 200)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    opacity: status === Image.Ready ? 1.0 : 0.0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 300
                        }
                    }
                }

                StyledLabel {
                    anchors.centerIn: parent
                    visible: modelData.isDir || (modelData.isImage && thumbImage.status !== Image.Ready) || (!modelData.isImage && !modelData.isDir)
                    text: modelData.path === ".." ? "󰁝" : (modelData.isDir ? "󰉋" : (modelData.isImage ? "󰸉" : "󰠮"))
                    type: "heading"
                    customColor: modelData.isDir ? ThemeManager.accentColor : ThemeManager.contentOnBackgroundColor
                    font.pixelSize: modelData.isDir ? 42 : 36
                    opacity: isActive ? 1.0 : 0.3
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                }
            }
            
            StyledLabel {
                text: modelData.name
                type: "caption"
                font.weight: Font.Medium
                opacity: isActive ? 0.9 : 0.4
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                elideMode: Text.ElideRight
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                Layout.bottomMargin: 4
            }
        }
        
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                gridView.currentIndex = index
                if (modelData.isDir) {
                    FileBrowserManager.navigateToPath(delegateRoot.itemPath)
                } else {
                    WallpaperManager.previewWallpaperPath = delegateRoot.itemPath
                }
                gridView.forceActiveFocus()
            }
        }
        
        scale: isActive ? 1.05 : 1.0
        Behavior on scale {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutExpo
            }
        }
        HoverHandler {
            id: hh
        }
    }
}
