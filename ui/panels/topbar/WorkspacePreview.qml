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

    property real layoutWidthNeeded: 0
    property real layoutHeightNeeded: 0

    readonly property var workspaceWindows: {
        if (!active || workspaceId === -1) return []
        
        let list = []
        let windows = WindowManager.getWorkspaceWindows(workspaceId)
        let audioPids = AudioManager.pidsPlayingAudio
        let audioApps = AudioManager.appNamesPlayingAudio
        
        let minX = 0;
        let minY = 0;
        if (windows.length > 0) {
            minX = Math.min(...windows.map(w => w.posX));
            minY = Math.min(...windows.map(w => w.posY));
        }

        let currentX = 0;
        let maxW = 0;
        let maxH = 0;

        for (let i = 0; i < windows.length; i++) {
            let win = windows[i]
            
            let isPlaying = audioPids.includes(win.pid)
            if (!isPlaying && audioApps.length > 0) {
                let cleanAppId = win.appId.toLowerCase()
                let cleanTitle = win.title.toLowerCase()
                isPlaying = audioApps.some(name => {
                    let cleanName = name.toLowerCase()
                    return cleanAppId.includes(cleanName) || 
                           cleanName.includes(cleanAppId) ||
                           cleanTitle.includes(cleanName)
                })
                if (!isPlaying && cleanAppId === "feishin" && audioApps.includes("chromium")) isPlaying = true
            }

            let w = win.width * root.previewScale * 0.8;
            let h = win.height * root.previewScale * 0.8;
            let finalX = 0;
            let finalY = 0;

            finalX = (win.posX - minX) * root.previewScale * 0.8;
            finalY = (win.posY - minY) * root.previewScale * 0.8;

            maxW = Math.max(maxW, finalX + w);
            maxH = Math.max(maxH, finalY + h);

            list.push({
                id: win.id,
                appId: win.appId,
                title: win.title,
                iconPath: win.iconPath,
                isFocused: win.isFocused,
                isUrgent: win.isUrgent,
                isPlayingAudio: isPlaying,
                width: w,
                height: h,
                posX: finalX,
                posY: finalY
            })
        }
        
        layoutWidthNeeded = maxW;
        layoutHeightNeeded = maxH;
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
        interactive: !ViewManager.isDragging
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
            width: Math.max(flick.width, root.layoutWidthNeeded)
            height: flick.height

            Item {
                id: windowContainer
                width: root.layoutWidthNeeded
                height: root.layoutHeightNeeded
                anchors.centerIn: parent

                Repeater {
                    model: root.workspaceWindows
                    delegate: Rectangle {
                        id: windowRect
                        width: modelData.width
                        height: modelData.height
                        
                        x: modelData.posX
                        y: modelData.posY
                        radius: ThemeManager.radiusSmall / 2
                        
                        readonly property bool isWindowHovered: maWin.containsMouse
                        
                        color: (modelData.isFocused || isWindowHovered) 
                            ? Qt.rgba(ThemeManager.accentColor.r, ThemeManager.accentColor.g, ThemeManager.accentColor.b, 0.4) 
                            : ThemeManager.surfacePrimaryColor
                        
                        border.color: isWindowHovered 
                            ? ThemeManager.surfaceContentColor 
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
                            cursorShape: ViewManager.isDragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                            
                            property real startX: 0
                            property real startY: 0
                            property bool potentialDrag: false
                            property var windowIdToDrag: null

                            onPressed: (mouse) => {
                                startX = mouse.x
                                startY = mouse.y
                                potentialDrag = true
                                windowIdToDrag = modelData.id
                            }

                            onPositionChanged: (mouse) => {
                                if (potentialDrag && !ViewManager.isDragging) {
                                    let dist = Math.sqrt(Math.pow(mouse.x - startX, 2) + Math.pow(mouse.y - startY, 2))
                                    if (dist > 10) {
                                        ViewManager.activeDragWindowId = windowIdToDrag
                                        ViewManager.activeDragIcon = modelData.iconPath
                                    }
                                }

                                if (ViewManager.isDragging) {
                                    let mapped = maWin.mapToItem(null, mouse.x, mouse.y)
                                    let absX = (root.screen ? root.screen.x : 0) + mapped.x
                                    let absY = (root.screen ? root.screen.y : 0) + mapped.y
                                    
                                    ViewManager.dragX = absX
                                    ViewManager.dragY = absY
                                    
                                    if (root.screen) ViewManager.trackScreen(root.screen.name)
                                    ViewManager.checkDropTarget(absX, absY)
                                }
                            }

                            onReleased: {
                                if (ViewManager.isDragging) {
                                    if (ViewManager.hoveredTargetWorkspaceRef !== null) {
                                        WindowManager.moveWindowToWorkspace(
                                            ViewManager.activeDragWindowId, 
                                            ViewManager.hoveredTargetWorkspaceRef
                                        )
                                    }
                                    
                                    ViewManager.activeDragWindowId = null
                                    ViewManager.activeDragIcon = ""
                                    ViewManager.hoveredTargetWorkspaceId = -1
                                    ViewManager.hoveredTargetWorkspaceRef = null
                                    ViewManager.setHoveredWorkspace(-1)
                                } else if (potentialDrag) {
                                    WindowManager.focusWindowById(modelData.id)
                                    ViewManager.setHoveredWorkspace(-1)
                                }
                                potentialDrag = false
                            }

                            onCanceled: {
                                potentialDrag = false
                                ViewManager.activeDragWindowId = null
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
                                customColor: (modelData.isFocused || windowRect.isWindowHovered) ? ThemeManager.surfaceContentColor : ThemeManager.surfaceContentColor
                                opacity: (modelData.isFocused || windowRect.isWindowHovered) ? 1.0 : 0.8
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
                                    customColor: ThemeManager.surfaceContentColor
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
