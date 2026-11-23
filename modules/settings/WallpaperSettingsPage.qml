import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.components.filepicker
import qs.components.scrolling
import qs.core
import qs.services.controlcenter
import qs.services.settings
import qs.services.wallpaper
import qs.services.wallpaper.projects

SettingPage {
    id: root

    readonly property string desktopPath: WallpaperAssignmentService.wallpaperForScreen(SettingsService.wallpaperScreenName)
    readonly property string lockPath: WallpaperAssignmentService.wallpaperForLockScreen(SettingsService.wallpaperScreenName)
    readonly property string selectedPath: SettingsService.wallpaperTarget === "lock" ? lockPath : desktopPath
    readonly property var selectedRecord: WallpaperProbeService.recordFor(selectedPath)

    function openEditor() {
        WallpaperEditorService.open(SettingsService.targetScreenName);
        ControlCenterService.close();
    }

    Component.onCompleted: {
        if (WallpaperCatalogService.configured && WallpaperCatalogService.wallpapers.length === 0 && !WallpaperCatalogService.scanning)
            WallpaperCatalogService.rescan();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Design.space8

        SettingsHeader {
            title: "Wallpaper"

            Item {
                Layout.fillWidth: true
            }

            GlyphButton {
                glyph: "folder"
                accessibleName: "Browse wallpaper files"
                toolTip: "Browse files"
                onActivated: SettingsService.openPage("wallpaper_file")
            }

            GlyphButton {
                glyph: "settings"
                accessibleName: "Wallpaper options"
                toolTip: "Options"
                onActivated: SettingsService.openPage("wallpaper_options")
            }

            GlyphButton {
                glyph: "crop"
                enabled: root.selectedRecord.kind === "static"
                accessibleName: "Adjust wallpaper crop and rotation"
                toolTip: "Adjust image"
                onActivated: SettingsService.openPage("wallpaper_adjust")
            }

            GlyphButton {
                glyph: "edit"
                accessibleName: "Open Wallpaper Studio"
                toolTip: "Wallpaper Studio"
                onActivated: root.openEditor()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Design.space8

            WallpaperPreviewCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                title: "Desktop"
                subtitle: SettingsService.wallpaperScreenName || "All displays"
                path: root.desktopPath
                placementTarget: "desktop"
                placementScreenName: SettingsService.wallpaperScreenName
                selected: SettingsService.wallpaperTarget === "desktop"
                accessibleName: "Choose desktop wallpaper"
                onActivated: SettingsService.wallpaperTarget = "desktop"
            }

            WallpaperPreviewCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                title: "Lock Screen"
                subtitle: WallpaperAssignmentService.lockUsesDesktop ? "Follows desktop" : "Separate image"
                path: root.lockPath
                placementTarget: WallpaperAssignmentService.lockUsesDesktop ? "desktop" : "lock"
                placementScreenName: WallpaperAssignmentService.lockUsesDesktop ? SettingsService.wallpaperScreenName : ""
                selected: SettingsService.wallpaperTarget === "lock"
                accessibleName: "Choose lock screen wallpaper"
                onActivated: SettingsService.wallpaperTarget = "lock"
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Design.space8

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Design.minimumTouchTarget

                Flickable {
                    anchors.fill: parent
                    contentWidth: targetRow.width
                    contentHeight: height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: targetRow
                        height: parent.height
                        spacing: Design.space6

                        WallpaperTargetButton {
                            label: "All"
                            selected: SettingsService.wallpaperScreenName.length === 0
                            onActivated: SettingsService.wallpaperScreenName = ""
                        }

                        Repeater {
                            model: Quickshell.screens

                            WallpaperTargetButton {
                                required property var modelData
                                label: modelData.name
                                selected: SettingsService.wallpaperScreenName === modelData.name
                                onActivated: SettingsService.wallpaperScreenName = modelData.name
                            }
                        }
                    }
                }
            }

            GlyphButton {
                visible: SettingsService.wallpaperTarget === "lock" && !WallpaperAssignmentService.lockUsesDesktop
                glyph: "checkmark"
                accessibleName: "Use desktop wallpaper on lock screen"
                toolTip: "Use desktop image"
                onActivated: WallpaperAssignmentService.useDesktopForLock()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.separator
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Design.space8

            Text {
                Layout.fillWidth: true
                text: "Library"
                color: Theme.textPrimary
                font.family: Design.fontText
                font.pixelSize: Design.typeBody
                font.weight: Font.DemiBold
            }

            Text {
                text: WallpaperCatalogService.scanning || WallpaperCatalogService.classifying ? "···" : String(WallpaperCatalogService.wallpapers.length)
                color: Theme.textTertiary
                font.family: Design.fontMono
                font.pixelSize: Design.typeLabel
            }

            GlyphButton {
                glyph: "folder"
                accessibleName: "Choose wallpaper library folder"
                toolTip: "Library folder"
                onActivated: SettingsService.openPage("wallpaper_directory")
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            SmoothScrollBehavior {
                target: grid
            }

            GridView {
                id: grid
                anchors.fill: parent
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: WallpaperCatalogService.wallpapers
                cellWidth: Math.max(100, width / 3)
                cellHeight: 108
                reuseItems: true

                ScrollBar.vertical: MinimalScrollBar {}

                delegate: WallpaperTile {
                    required property var modelData
                    width: grid.cellWidth - Design.space6
                    height: grid.cellHeight - Design.space6
                    record: modelData
                    selected: path === root.selectedPath
                    onActivated: if (selectable)
                        WallpaperAssignmentService.assignTarget(SettingsService.wallpaperTarget, SettingsService.wallpaperScreenName, path)
                }

                Column {
                    anchors.centerIn: parent
                    spacing: Design.space8
                    visible: !WallpaperCatalogService.scanning && WallpaperCatalogService.wallpapers.length === 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: WallpaperCatalogService.error.length > 0 ? WallpaperCatalogService.error : "Choose a wallpaper folder"
                        color: Theme.textSecondary
                        font.family: Design.fontText
                        font.pixelSize: Design.typeLabel
                    }

                    PickerButton {
                        anchors.horizontalCenter: parent.horizontalCenter
                        label: "Choose Folder"
                        onActivated: SettingsService.openPage("wallpaper_directory")
                    }
                }
            }
        }
    }
}
