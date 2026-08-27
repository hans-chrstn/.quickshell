import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.services.wallpaper

Item {
    id: root

    property string targetScreenName: ""
    readonly property string effectiveWallpaper:
        WallpaperAssignmentService.wallpaperForScreen(targetScreenName)

    function assign(path) {
        if (targetScreenName.length > 0)
            WallpaperAssignmentService.setForScreen(targetScreenName, path)
        else
            WallpaperAssignmentService.setGlobal(path)
    }

    Component.onCompleted: {
        if (WallpaperCatalogService.wallpapers.length === 0
                && !WallpaperCatalogService.scanning)
            WallpaperCatalogService.rescan()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Wallpaper"
                color: Design.text
                font.family: Design.fontDisplay
                font.pixelSize: 20
                font.weight: Font.DemiBold
            }

            Item { Layout.fillWidth: true }

            Text {
                text: WallpaperCatalogService.scanning
                    ? "Scanning…" : WallpaperCatalogService.wallpapers.length + " images"
                color: Design.textMuted
                font.family: Design.fontText
                font.pixelSize: 10
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            contentWidth: targets.width
            contentHeight: height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Row {
                id: targets
                height: parent.height
                spacing: 6

                WallpaperTargetButton {
                    label: "All Displays"
                    selected: root.targetScreenName.length === 0
                    onActivated: root.targetScreenName = ""
                }

                Repeater {
                    model: Quickshell.screens

                    WallpaperTargetButton {
                        required property var modelData
                        label: modelData.name
                        selected: root.targetScreenName === modelData.name
                        onActivated: root.targetScreenName = modelData.name
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Design.separator
        }

        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: WallpaperCatalogService.wallpapers
            cellWidth: Math.max(120, width / 3)
            cellHeight: 112

            delegate: WallpaperTile {
                required property var modelData
                width: grid.cellWidth - 8
                height: grid.cellHeight - 8
                path: String(modelData)
                selected: path === root.effectiveWallpaper
                onActivated: root.assign(path)
            }

            Text {
                anchors.centerIn: parent
                visible: !WallpaperCatalogService.scanning
                    && WallpaperCatalogService.wallpapers.length === 0
                text: WallpaperCatalogService.error.length > 0
                    ? WallpaperCatalogService.error : "No wallpapers found"
                color: Design.textMuted
                font.family: Design.fontText
                font.pixelSize: 12
            }
        }
    }
}
