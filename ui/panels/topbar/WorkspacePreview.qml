import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQml.Models
import Quickshell
import Quickshell.Widgets
import qs.core
import qs.ui.shared

ClippingRectangle {
    id: root
    
    property var screen: null
    property int workspaceId: -1
    property bool active: false
    
    property real screenWidth: (screen && screen.width) ? screen.width : 1920
    property real screenHeight: (screen && screen.height) ? screen.height : 1080
    
    readonly property real previewScale: ThemeManager.workspacePreviewScale
    width: screenWidth * previewScale
    height: screenHeight * previewScale
    
    radius: ThemeManager.workspacePreviewRadius
    color: Qt.rgba(ThemeManager.backgroundColor.r, ThemeManager.backgroundColor.g, ThemeManager.backgroundColor.b, ThemeManager.workspacePreviewOpacity)
    
    opacity: active ? 1 : 0
    scale: active ? 1 : 0.95
    
    Behavior on opacity { NumberAnimation { duration: ThemeManager.durationFast } }
    Behavior on scale { NumberAnimation { duration: ThemeManager.durationMedium; easing.type: Easing.OutBack } }

    HoverHandler {
        id: masterHover
        onHoveredChanged: {
            ViewManager.previewHovered = hovered
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: ThemeManager.workspacePreviewRadius
        color: "transparent"
        border.color: ThemeManager.outlinePrimaryColor
        border.width: 1
        z: 10
    }

    MultiEffect {
        anchors.fill: parent
        source: bgPreview
        blurEnabled: true
        blur: root.active ? ThemeManager.workspacePreviewBlur : 0.0
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

    readonly property var workspaceWindows: {
        if (!active || workspaceId === -1) return []
        
        let list = []
        let windows = NiriManager.windows
        let layouts = NiriManager.windowLayouts
        
        for (let i = 0; i < windows.count; i++) {
            let idx = windows.index(i, 0)
            let wsId = windows.data(idx, 261)
            
            if (wsId === root.workspaceId) {
                let id = windows.data(idx, 257)
                let layout = layouts[id]
                if (layout) {
                    let w = layout.window_size ? layout.window_size[0] : (layout.tile_size ? layout.tile_size[0] : 100)
                    let h = layout.window_size ? layout.window_size[1] : (layout.tile_size ? layout.tile_size[1] : 100)
                    list.push({
                        id: id,
                        appId: windows.data(idx, 259),
                        title: windows.data(idx, 258),
                        iconPath: windows.data(idx, 265),
                        isFocused: windows.data(idx, 262),
                        width: w * root.previewScale * 0.8,
                        height: h * root.previewScale * 0.8
                    })
                }
            }
        }
        return list
    }

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.margins: ThemeManager.spacingMedium
        contentWidth: windowRow.width
        contentHeight: height
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Row {
            id: windowRow
            height: parent.height
            spacing: ThemeManager.spacingSmall
            anchors.verticalCenter: parent.verticalCenter
            leftPadding: Math.max(0, (flick.width - width) / 2)

            Repeater {
                model: root.workspaceWindows
                delegate: Rectangle {
                    id: windowRect
                    width: modelData.width
                    height: modelData.height
                    anchors.verticalCenter: parent.verticalCenter
                    radius: ThemeManager.radiusSmall / 2
                    
                    readonly property bool isWindowHovered: maWin.containsMouse
                    
                    color: (modelData.isFocused || isWindowHovered) 
                        ? Qt.rgba(ThemeManager.accentColor.r, ThemeManager.accentColor.g, ThemeManager.accentColor.b, 0.4) 
                        : ThemeManager.surfacePrimaryColor
                    
                    border.color: isWindowHovered 
                        ? "white" 
                        : (modelData.isFocused ? ThemeManager.accentColor : ThemeManager.outlineVariantColor)
                    
                    border.width: isWindowHovered ? 3 : (modelData.isFocused ? 2 : 1)

                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: ThemeManager.shadowPrimaryColor
                        shadowBlur: 0.3
                        shadowOpacity: 0.8
                    }

                    MouseArea {
                        id: maWin
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            NiriManager.focusWindowById(modelData.id)
                            ViewManager.setHoveredWorkspace(-1)
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: ThemeManager.spacingExtraSmall / 2
                        spacing: 1

                        Image {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: windowRect.height > 20 ? 16 : 12
                            Layout.preferredHeight: Layout.preferredWidth
                            source: modelData.iconPath ? "file://" + modelData.iconPath : ""
                            visible: windowRect.height > 10
                        }

                        StyledLabel {
                            Layout.fillWidth: true
                            text: modelData.title
                            font.pixelSize: 5
                            font.weight: (modelData.isFocused || windowRect.isWindowHovered) ? Font.Bold : Font.Normal
                            elideMode: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            customColor: (modelData.isFocused || windowRect.isWindowHovered) ? "white" : ThemeManager.surfaceContentColor
                            opacity: 0.8
                            visible: windowRect.height > 20
                        }
                    }
                }
            }
        }
    }
}
