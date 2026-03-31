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
        let audioPids = AudioManager.pidsPlayingAudio
        let audioApps = AudioManager.appNamesPlayingAudio
        
        for (let i = 0; i < windows.count; i++) {
            let idx = windows.index(i, 0)
            let wsId = windows.data(idx, 261)
            
            if (wsId === root.workspaceId) {
                let id = windows.data(idx, 257)
                let pid = windows.data(idx, 260)
                let appId = windows.data(idx, 259) || ""
                let title = windows.data(idx, 258) || ""
                
                let layout = layouts[id]
                if (layout) {
                    let w = layout.window_size ? layout.window_size[0] : (layout.tile_size ? layout.tile_size[0] : 100)
                    let h = layout.window_size ? layout.window_size[1] : (layout.tile_size ? layout.tile_size[1] : 100)
                    
                    let isPlaying = audioPids.includes(pid)
                    if (!isPlaying && audioApps.length > 0) {
                        let cleanAppId = appId.toLowerCase()
                        let cleanTitle = title.toLowerCase()
                        isPlaying = audioApps.some(name => {
                            let cleanName = name.toLowerCase()
                            return cleanAppId.includes(cleanName) || 
                                   cleanName.includes(cleanAppId) ||
                                   cleanTitle.includes(cleanName)
                        })
                        if (!isPlaying && cleanAppId === "feishin" && audioApps.includes("chromium")) isPlaying = true
                    }

                    list.push({
                        id: id,
                        appId: appId,
                        title: title,
                        iconPath: windows.data(idx, 265),
                        isFocused: windows.data(idx, 262),
                        isUrgent: windows.data(idx, 264),
                        isPlayingAudio: isPlaying,
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
        
        contentWidth: container.width
        contentHeight: height
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.DragAndOvershootBounds
        pixelAligned: true
        
        flickDeceleration: 1500
        maximumFlickVelocity: 2500
        clip: true

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: (event) => {
                let velocity = event.angleDelta.y * 10
                flick.flick(velocity, 0)
            }
        }

        Item {
            id: container
            width: Math.max(flick.width, windowRow.width)
            height: flick.height

            Row {
                id: windowRow
                height: parent.height
                spacing: ThemeManager.spacingSmall
                anchors.centerIn: parent

                Repeater {
                    model: root.workspaceWindows
                    delegate: Rectangle {
                        id: windowRect
                        width: modelData.width
                        height: modelData.height
                        anchors.verticalCenter: parent.verticalCenter
                        radius: ThemeManager.radiusSmall / 2
                        
                        readonly property bool isWindowHovered: hWin.hovered
                        
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

                        HoverHandler {
                            id: hWin
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            onTapped: {
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

                        Row {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 4
                            spacing: 4
                            z: 5

                            Rectangle {
                                width: Math.max(10, Math.min(parent.width / 3, 16))
                                height: width
                                radius: width / 2
                                color: ThemeManager.backgroundColor
                                visible: modelData.isPlayingAudio
                                border.color: ThemeManager.accentColor
                                border.width: 1

                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    shadowEnabled: true
                                    shadowColor: ThemeManager.accentColor
                                    shadowBlur: 0.5
                                    shadowOpacity: 0.8
                                }

                                StyledLabel {
                                    anchors.centerIn: parent
                                    text: ThemeManager.iconVolume
                                    font.pixelSize: parent.width * 0.6
                                    customColor: ThemeManager.accentColor
                                }
                            }

                            Rectangle {
                                width: Math.max(10, Math.min(parent.width / 3, 16))
                                height: width
                                radius: width / 2
                                color: ThemeManager.dangerColor
                                visible: modelData.isUrgent
                                
                                StyledLabel {
                                    anchors.centerIn: parent
                                    text: "!"
                                    font.pixelSize: parent.width * 0.8
                                    font.weight: Font.Black
                                    customColor: "white"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
