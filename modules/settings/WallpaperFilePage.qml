import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.filepicker
import qs.services.settings
import qs.services.wallpaper

SettingPage {
    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        SettingsHeader {
            title: SettingsService.wallpaperTarget === "lock" ? "Lock Wallpaper" : "Desktop Wallpaper"
        }

        FilePicker {
            Layout.fillWidth: true
            Layout.fillHeight: true
            mode: "wallpaper"
            maximumSelection: 1
            initialPath: WallpaperCatalogService.directories.length > 0 ? WallpaperCatalogService.directories[0] : WallpaperAssignmentService.wallpaperForScreen(SettingsService.wallpaperScreenName).length > 0 ? WallpaperAssignmentService.wallpaperForScreen(SettingsService.wallpaperScreenName).replace(/\/[^/]*$/, "") : (Quickshell.env("HOME") || "/")
            externalError: WallpaperAssignmentService.error
            onAccepted: paths => {
                if (WallpaperAssignmentService.assignTarget(SettingsService.wallpaperTarget, SettingsService.wallpaperScreenName, paths[0]))
                    SettingsService.back();
            }
            onCanceled: SettingsService.back()
        }
    }
}
