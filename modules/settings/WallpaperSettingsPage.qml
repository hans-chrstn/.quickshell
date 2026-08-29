import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.components.filepicker
import qs.components.scrolling
import qs.core
import qs.services.wallpaper
import qs.services.settings

SettingPage {
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
        if (WallpaperCatalogService.configured
                && WallpaperCatalogService.wallpapers.length === 0
                && !WallpaperCatalogService.scanning)
            WallpaperCatalogService.rescan()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        SettingsHeader {
            title: "Wallpaper"

            Item { Layout.fillWidth: true }

            Text {
                text: WallpaperCatalogService.scanning
                    ? "Scanning…" : WallpaperCatalogService.classifying
                        ? "Inspecting…"
                        : WallpaperCatalogService.wallpapers.length + " media"
                color: Design.textMuted
                font.family: Design.fontText
                font.pixelSize: 10
            }

            PickerButton {
                visible: WallpaperCatalogService.configured
                label: WallpaperCatalogService.configured
                    ? "Change Library" : "Choose Folder"
                onActivated: SettingsService.openPage("wallpaper_directory")
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34

                    SmoothScrollBehavior {
                        target: targetScroller
                        orientation: Qt.Horizontal
                    }

                    ScrollEdgeFeedback {
                        target: targetScroller
                        orientation: Qt.Horizontal
                        fadeHeight: 12
                    }

                    Flickable {
                        id: targetScroller
                        anchors.fill: parent
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
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Design.separator
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    SmoothScrollBehavior {
                        target: grid
                    }

                    ScrollEdgeFeedback {
                        target: grid
                    }

                    GridView {
                        id: grid
                        anchors.fill: parent
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: WallpaperCatalogService.wallpapers
                        cellWidth: Math.max(120, (width - 10) / 3)
                        cellHeight: 112

                        ScrollBar.vertical: MinimalScrollBar {}

                        delegate: WallpaperTile {
                            required property var modelData
                            width: grid.cellWidth - 8
                            height: grid.cellHeight - 8
                            record: modelData
                            selected: path === root.effectiveWallpaper
                            onActivated: if (selectable) root.assign(path)
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 8
                            visible: !WallpaperCatalogService.scanning
                                && WallpaperCatalogService.wallpapers.length === 0

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: !WallpaperCatalogService.configured
                                    ? "Choose a wallpaper folder to begin"
                                    : WallpaperCatalogService.error.length > 0
                                        ? WallpaperCatalogService.error
                                        : "No wallpapers found in this folder"
                                color: Design.textMuted
                                font.family: Design.fontText
                                font.pixelSize: 12
                            }

                            PickerButton {
                                anchors.horizontalCenter: parent.horizontalCenter
                                label: WallpaperCatalogService.configured
                                    ? "Change Library" : "Choose Folder"
                                primary: true
                                onActivated: SettingsService.openPage("wallpaper_directory")
                            }
                        }
                    }
                }
            }
        }
    }

}
