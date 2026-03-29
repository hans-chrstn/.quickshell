import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.core
import qs.ui.shared

Rectangle {
    id: root
    
    property var screen: null
    property int workspaceId: -1
    property real screenWidth: screen ? screen.width : 1920
    property real screenHeight: screen ? screen.height : 1080
    
    readonly property real previewScale: 0.15
    width: screenWidth * previewScale
    height: screenHeight * previewScale
    
    radius: ThemeManager.globalCornerRadius
    color: Qt.rgba(ThemeManager.backgroundColor.r, ThemeManager.backgroundColor.g, ThemeManager.backgroundColor.b, 0.8)
    border.color: Qt.rgba(ThemeManager.accentColor.r, ThemeManager.accentColor.g, ThemeManager.accentColor.b, 0.4)
    border.width: 1
    
    opacity: visible ? 1 : 0
    scale: visible ? 1 : 0.95
    
    Behavior on opacity { NumberAnimation { duration: 200 } }
    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
    
    clip: true

    MultiEffect {
        anchors.fill: parent
        source: bgPreview
        blurEnabled: true
        blur: 0.4
        brightness: -0.2
        saturation: 0.2
    }

    Image {
        id: bgPreview
        anchors.fill: parent
        source: {
            let path = WallpaperManager.activeWallpaperPath
            if (!path) return ""
            return (path.startsWith("/") ? "file://" : "") + path
        }
        fillMode: Image.PreserveAspectCrop
        visible: false
    }

    Item {
        id: container
        anchors.fill: parent
        anchors.margins: 8

        Repeater {
            model: NiriManager.windows
            delegate: Item {
                id: windowDelegate
                readonly property var layout: NiriManager.windowLayouts[model.id]
                
                visible: model.workspaceId === root.workspaceId && layout !== undefined
                
                width: layout ? (layout.window_size[0] * root.previewScale * 0.9) : 0
                height: layout ? (layout.window_size[1] * root.previewScale * 0.9) : 0
                
                x: (parent.width - width) / 2
                y: (parent.height - height) / 2

                Rectangle {
                    id: windowRect
                    anchors.fill: parent
                    radius: 6
                    color: model.isFocused ? Qt.rgba(ThemeManager.accentColor.r, ThemeManager.accentColor.g, ThemeManager.accentColor.b, 0.4) : Qt.rgba(0, 0, 0, 0.5)
                    border.color: model.isFocused ? ThemeManager.accentColor : Qt.rgba(1, 1, 1, 0.15)
                    border.width: model.isFocused ? 2 : 1

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: "black"
                        shadowBlur: 0.4
                        shadowVerticalOffset: 2
                        shadowOpacity: 0.5
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 2

                        Image {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: parent.parent.height > 30 ? 24 : 16
                            Layout.preferredHeight: Layout.preferredWidth
                            source: model.iconPath ? "file://" + model.iconPath : ""
                            smooth: true
                            mipmap: true
                        }

                        StyledLabel {
                            Layout.fillWidth: true
                            text: model.title
                            font.pixelSize: 7
                            font.weight: model.isFocused ? Font.Bold : Font.Normal
                            elideMode: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            customColor: model.isFocused ? "white" : ThemeManager.contentOnBackgroundColor
                            opacity: 0.9
                            visible: parent.parent.height > 25
                        }
                    }
                }
            }
        }
    }
}
