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

        SettingChoiceRow {
            Layout.fillWidth: true
            visible: ConfigService.optimizeWallpaperResolution
            title: "Resolution limit"
            choices: WallpaperOptimizationService.resolutionScales
            enabledChoices:
                WallpaperOptimizationService.settingsResolutionScales()
            value: ConfigService.optimizeWallpaperResolutionScale
            formatChoice: value => value + "×"
            onChoiceSelected: value =>
                WallpaperOptimizationService.setDefaultResolutionScale(value)
        }

        SettingToggle {
            Layout.fillWidth: true
            title: "Limit frame rate"
            description: "Reduce continuous decoding to the selected rate"
            checked: ConfigService.optimizeWallpaperFrameRate
            onToggled: value => SettingsService.setSetting(
                "optimizeWallpaperFrameRate", value)
        }

        SettingChoiceRow {
            Layout.fillWidth: true
            visible: ConfigService.optimizeWallpaperFrameRate
            title: "Frame-rate limit"
            choices: [15, 24, 30]
            value: ConfigService.optimizeWallpaperFrameRateLimit
            onChoiceSelected: value => SettingsService.setSetting(
                "optimizeWallpaperFrameRateLimit", value)
        }

        SettingToggle {
            Layout.fillWidth: true
            title: "Limit bitrate"
            description: "Cap output near 12 Mbps to reduce decode and I/O pressure"
            checked: ConfigService.optimizeWallpaperBitRate
            onToggled: value => SettingsService.setSetting(
                "optimizeWallpaperBitRate", value)
        }

        Item { Layout.fillHeight: true }
    }
}
