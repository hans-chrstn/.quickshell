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

        SettingChoiceRow {
            Layout.fillWidth: true
            title: "Scale"
            choices: [0, 1, 1.5, -1]
            enabledChoices: WallpaperOptimizationService.settingsResolutionModes()
            value: WallpaperOptimizationService.resolutionMode()
            choiceWidth: 54
            formatChoice: value => value === 0 ? "Native"
                : value === -1 ? "Custom" : value + "×"
            onChoiceSelected: value =>
                WallpaperOptimizationService.setResolutionMode(value)
        }

        RowLayout {
            Layout.fillWidth: true
            visible: WallpaperOptimizationService.resolutionMode() === -1

            Text {
                Layout.fillWidth: true
                text: "Custom scale"
                color: Design.textMuted
                font.family: Design.fontText
                font.pixelSize: 10
            }

            SettingNumericStepper {
                value: ConfigService.optimizeWallpaperResolutionCustomScale
                from: 0.5
                to: Math.max(0.5,
                    WallpaperOptimizationService.settingsMaximumResolutionScale())
                stepSize: WallpaperOptimizationService.resolutionCustomStep
                decimals: 2
                suffix: "×"
                accessibleName: "Custom wallpaper resolution scale"
                onValueEdited: value =>
                    WallpaperOptimizationService.setCustomResolutionScale(value)
            }
        }

        SettingChoiceRow {
            Layout.fillWidth: true
            title: "Frame rate"
            choices: [15, 24, 30, -1]
            enabledChoices: WallpaperOptimizationService.settingsFrameRateModes()
            value: WallpaperOptimizationService.frameRateMode()
            choiceWidth: 54
            formatChoice: value => value === -1 ? "Custom" : String(value)
            onChoiceSelected: value =>
                WallpaperOptimizationService.setFrameRateMode(value)
        }

        RowLayout {
            Layout.fillWidth: true
            visible: WallpaperOptimizationService.frameRateMode() === -1

            Text {
                Layout.fillWidth: true
                text: "Custom frame rate"
                color: Design.textMuted
                font.family: Design.fontText
                font.pixelSize: 10
            }

            SettingNumericStepper {
                value: ConfigService.optimizeWallpaperFrameRateCustomLimit
                from: 1
                to: Math.max(1,
                    WallpaperOptimizationService.settingsMaximumFrameRate())
                stepSize: WallpaperOptimizationService.frameRateCustomStep
                decimals: 2
                suffix: "FPS"
                accessibleName: "Custom wallpaper frame rate"
                onValueEdited: value =>
                    WallpaperOptimizationService.setCustomFrameRate(value)
            }
        }

        SettingChoiceRow {
            Layout.fillWidth: true
            title: "Bitrate"
            choices: [4, 8, 12, -1]
            enabledChoices: WallpaperOptimizationService.settingsBitRateModes()
            value: WallpaperOptimizationService.bitRateMode()
            choiceWidth: 54
            formatChoice: value => value === -1 ? "Custom" : String(value)
            onChoiceSelected: value =>
                WallpaperOptimizationService.setBitRateMode(value)
        }

        RowLayout {
            Layout.fillWidth: true
            visible: WallpaperOptimizationService.bitRateMode() === -1

            Text {
                Layout.fillWidth: true
                text: "Custom bitrate"
                color: Design.textMuted
                font.family: Design.fontText
                font.pixelSize: 10
            }

            SettingNumericStepper {
                value: ConfigService.optimizeWallpaperBitRateCustomLimit
                from: 0.5
                to: Math.max(0.5,
                    WallpaperOptimizationService.settingsMaximumBitRate())
                stepSize: WallpaperOptimizationService.bitRateCustomStep
                decimals: 1
                suffix: "Mbps"
                accessibleName: "Custom wallpaper bitrate"
                onValueEdited: value =>
                    WallpaperOptimizationService.setCustomBitRate(value)
            }
        }

        Item { Layout.fillHeight: true }
    }
}
