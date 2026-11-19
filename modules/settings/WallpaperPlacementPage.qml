import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.media
import qs.core
import qs.services.settings
import qs.services.wallpaper

SettingPage {
    id: root

    readonly property bool lockSeparate: SettingsService.wallpaperTarget === "lock" && !WallpaperAssignmentService.lockUsesDesktop
    readonly property string placementTarget: lockSeparate ? "lock" : "desktop"
    readonly property string placementScreenName: lockSeparate ? "" : SettingsService.wallpaperScreenName
    readonly property string path: SettingsService.wallpaperTarget === "lock" ? WallpaperAssignmentService.wallpaperForLockScreen(SettingsService.wallpaperScreenName) : WallpaperAssignmentService.wallpaperForScreen(SettingsService.wallpaperScreenName)
    property real draftZoom: 1
    property real draftPanX: 0
    property real draftPanY: 0
    property int draftRotation: 0
    property real pointerX: 0
    property real pointerY: 0

    function loadPlacement() {
        const current = WallpaperAssignmentService.placementFor(placementTarget, placementScreenName, path);
        draftZoom = current.zoom;
        draftPanX = current.panX;
        draftPanY = current.panY;
        draftRotation = current.rotation;
    }

    function commitPlacement() {
        WallpaperAssignmentService.setPlacement(placementTarget, placementScreenName, path, draftZoom, draftPanX, draftPanY, draftRotation);
    }

    function resetPlacement() {
        WallpaperAssignmentService.clearPlacement(placementTarget, placementScreenName, path);
        loadPlacement();
    }

    Component.onCompleted: loadPlacement()
    onPathChanged: loadPlacement()
    onPlacementTargetChanged: loadPlacement()
    onPlacementScreenNameChanged: loadPlacement()

    ColumnLayout {
        anchors.fill: parent
        spacing: Design.space12

        SettingsHeader {
            title: "Place Image"

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: SettingsService.wallpaperTarget === "lock" ? "Lock Screen" : SettingsService.wallpaperScreenName || "Desktop"
                color: Theme.textSecondary
                font.family: Design.fontText
                font.pixelSize: Design.typeLabel
            }
        }

        Rectangle {
            id: viewport
            Layout.fillWidth: true
            Layout.preferredHeight: 214
            radius: Design.radiusGrouped
            color: Theme.fillSubtle
            border.width: 1
            border.color: Theme.separatorStrong
            clip: true

            WallpaperPlacementImage {
                id: preview
                anchors.fill: parent
                anchors.margins: 2
                path: root.path
                cornerRadius: Math.max(0, viewport.radius - 2)
                placement: ({
                        zoom: root.draftZoom,
                        panX: root.draftPanX,
                        panY: root.draftPanY,
                        rotation: root.draftRotation
                    })
            }

            Repeater {
                model: 2

                Rectangle {
                    required property int index
                    x: (index + 1) * viewport.width / 3
                    width: 1
                    height: viewport.height
                    color: Theme.alpha(Theme.textPrimary, 0.48)
                    opacity: dragArea.pressed ? 1 : dragArea.containsMouse ? 0.55 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Design.motionStateDuration
                        }
                    }
                }
            }

            Repeater {
                model: 2

                Rectangle {
                    required property int index
                    y: (index + 1) * viewport.height / 3
                    width: viewport.width
                    height: 1
                    color: Theme.alpha(Theme.textPrimary, 0.48)
                    opacity: dragArea.pressed ? 1 : dragArea.containsMouse ? 0.55 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Design.motionStateDuration
                        }
                    }
                }
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.draftZoom > 1 ? Qt.OpenHandCursor : Qt.ArrowCursor
                onPressed: mouse => {
                    root.pointerX = mouse.x;
                    root.pointerY = mouse.y;
                }
                onPositionChanged: mouse => {
                    if (!pressed || root.draftZoom <= 1)
                        return;
                    const maxX = preview.maximumPanX;
                    const maxY = preview.maximumPanY;
                    if (maxX > 0)
                        root.draftPanX = Math.max(-1, Math.min(1, root.draftPanX + (mouse.x - root.pointerX) / maxX));
                    if (maxY > 0)
                        root.draftPanY = Math.max(-1, Math.min(1, root.draftPanY + (mouse.y - root.pointerY) / maxY));
                    root.pointerX = mouse.x;
                    root.pointerY = mouse.y;
                }
                onReleased: root.commitPlacement()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Design.space8

            IslandGlyph {
                name: "crop"
                glyphColor: Theme.textSecondary
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
            }

            Text {
                Layout.fillWidth: true
                text: root.draftZoom > 1 ? "Drag image to frame" : "Zoom to reposition"
                color: Theme.textSecondary
                font.family: Design.fontText
                font.pixelSize: Design.typeLabel
            }

            Text {
                text: Math.round(root.draftZoom * 100) + "%"
                color: Theme.textPrimary
                font.family: Design.fontMono
                font.pixelSize: Design.typeLabel
            }
        }

        ValueSlider {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            from: 1
            to: 3
            stepSize: 0.05
            value: root.draftZoom
            accentColor: Theme.accent
            onEditRequested: value => {
                root.draftZoom = value;
                if (value <= 1) {
                    root.draftPanX = 0;
                    root.draftPanY = 0;
                }
                root.commitPlacement();
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Design.space8

            Text {
                Layout.fillWidth: true
                text: "Rotation"
                color: Theme.textSecondary
                font.family: Design.fontText
                font.pixelSize: Design.typeBody
            }

            Text {
                text: root.draftRotation + "°"
                color: Theme.textPrimary
                font.family: Design.fontMono
                font.pixelSize: Design.typeLabel
            }

            GlyphButton {
                glyph: "rotate"
                accessibleName: "Rotate clockwise by 90 degrees"
                toolTip: "Rotate"
                onActivated: {
                    root.draftRotation = (root.draftRotation + 90) % 360;
                    root.commitPlacement();
                }
            }

            GlyphButton {
                glyph: "undo"
                accessibleName: "Reset wallpaper placement"
                toolTip: "Reset"
                onActivated: root.resetPlacement()
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
