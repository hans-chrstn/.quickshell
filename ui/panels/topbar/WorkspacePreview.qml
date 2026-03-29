import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.core
import qs.ui.shared

ClippingRectangle {
    id: root
    
    property var screen: null
    property int workspaceId: -1
    property real screenWidth: (screen && screen.width) ? screen.width : 1920
    property real screenHeight: (screen && screen.height) ? screen.height : 1080
    
    readonly property real previewScale: ThemeManager.workspacePreviewScale
    width: screenWidth * previewScale
    height: screenHeight * previewScale
    
    radius: ThemeManager.workspacePreviewRadius
    color: Qt.rgba(0, 0, 0, ThemeManager.workspacePreviewOpacity)
    
    opacity: 0
    scale: 0.95

    ParallelAnimation {
        id: fadeAnim
        running: root.visible
        
        NumberAnimation {
            target: root
            property: "opacity"
            to: 1
            duration: ThemeManager.durationFast
        }
        
        NumberAnimation {
            target: root
            property: "scale"
            to: 1
            duration: ThemeManager.durationFast
            easing.type: Easing.OutBack
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: ThemeManager.workspacePreviewRadius
        color: "transparent"
        border.color: Qt.rgba(1, 1, 1, 0.1)
        border.width: 1
        z: 10
    }

    MultiEffect {
        anchors.fill: parent
        source: bgPreview
        blurEnabled: true
        blur: root.visible ? ThemeManager.workspacePreviewBlur : 0.0
        brightness: -0.1
        saturation: 0.1
        z: -1
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
        anchors.margins: ThemeManager.spacingSmall

        Repeater {
            model: NiriManager.windows
            delegate: Item {
                id: windowDelegate
                readonly property var layout: NiriManager.windowLayouts[model.id]
                
                visible: model.workspaceId === root.workspaceId && layout !== undefined
                
                width: (layout && layout.window_size) ? (layout.window_size[0] * root.previewScale * 0.9) : 0
                height: (layout && layout.window_size) ? (layout.window_size[1] * root.previewScale * 0.9) : 0
                
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
                        shadowColor: ThemeManager.shadowPrimaryColor
                        shadowBlur: 0.4
                        shadowVerticalOffset: 2
                        shadowOpacity: 0.5
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: ThemeManager.spacingExtraSmall
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

    Rectangle {
        anchors.fill: parent
        radius: ThemeManager.workspacePreviewRadius
        color: "transparent"
        border.color: Qt.rgba(1, 1, 1, 0.05)
        border.width: 1
        anchors.margins: 1
        z: 9
    }
}
