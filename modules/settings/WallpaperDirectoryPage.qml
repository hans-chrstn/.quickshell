import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components.filepicker
import qs.services.config
import qs.services.settings
import qs.services.wallpaper

SettingPage {
    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        SettingsHeader { title: "Choose Folder" }

        DirectoryPicker {
            Layout.fillWidth: true
            Layout.fillHeight: true
            initialPath: ConfigService.wallpaperDirectories.length > 0
                ? ConfigService.wallpaperDirectories[0]
                : (Quickshell.env("HOME") || "/")
            onAccepted: path => {
                ConfigService.setWallpaperDirectories([path])
                WallpaperCatalogService.rescan()
                SettingsService.back()
            }
            onCanceled: SettingsService.back()
        }
    }
}
