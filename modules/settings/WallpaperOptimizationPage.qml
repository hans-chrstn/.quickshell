import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services.config
import qs.services.settings
import qs.services.wallpaper

SettingPage {
    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        SettingsHeader { title: "Media Optimization" }

        Text {
            Layout.fillWidth: true
            text: "Each enabled step becomes part of the cache recipe. Changing one creates a separate optimized copy the next time you choose Optimize & Use."
            color: Design.textMuted
            font.family: Design.fontText
            font.pixelSize: 10
            wrapMode: Text.Wrap
        }

        SettingToggle {
            Layout.fillWidth: true
            title: "Limit resolution"
            description: "Downscale to the selected monitor without upscaling"
            checked: ConfigService.optimizeWallpaperResolution
            onToggled: value => SettingsService.setSetting(
                "optimizeWallpaperResolution", value)
        }

        SettingToggle {
            Layout.fillWidth: true
            title: "Limit frame rate"
            description: "Reduce continuous decoding to 30 FPS"
            checked: ConfigService.optimizeWallpaperFrameRate
            onToggled: value => SettingsService.setSetting(
                "optimizeWallpaperFrameRate", value)
        }

        SettingToggle {
            Layout.fillWidth: true
            title: "Limit bitrate"
            description: "Cap output near 12 Mbps to reduce decode and I/O pressure"
            checked: ConfigService.optimizeWallpaperBitRate
            onToggled: value => SettingsService.setSetting(
                "optimizeWallpaperBitRate", value)
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Design.separator
        }

        Text {
            text: "Optimization Cache"
            color: Design.textMuted
            font.family: Design.fontText
            font.pixelSize: 10
            font.weight: Font.DemiBold
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: {
                    if (WallpaperOptimizationService.clearState === "clearing")
                        return "Clearing cached derivatives…"
                    if (WallpaperOptimizationService.clearState === "ready")
                        return "Optimization cache cleared"
                    if (WallpaperOptimizationService.clearState === "failed")
                        return WallpaperOptimizationService.clearError
                    if (WallpaperOptimizationService.hasAssignedOptimizedCopy())
                        return "Select original wallpapers before clearing"
                    return "Cached copies remain until explicitly cleared"
                }
                color: WallpaperOptimizationService.clearState === "failed"
                    ? Design.red : Design.textMuted
                font.family: Design.fontText
                font.pixelSize: 9
                wrapMode: Text.Wrap
            }

            SettingButton {
                label: "Clear Cache"
                dangerous: true
                visible: !WallpaperOptimizationService.clearing
                onClicked: WallpaperOptimizationService.clearCache()
            }
        }

        Item { Layout.fillHeight: true }
    }
}
