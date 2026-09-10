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
            enabledChoices: WallpaperOptimizationPolicyService.settingsResolutionModes()
            value: WallpaperOptimizationPolicyService.resolutionMode()
            choiceWidth: 54
            formatChoice: value => value === 0 ? "Native"
                : value === -1 ? "Custom" : value + "×"
            onChoiceSelected: value =>
                WallpaperOptimizationPolicyService.setResolutionMode(value)
        }

        RowLayout {
            Layout.fillWidth: true
            visible: WallpaperOptimizationPolicyService.resolutionMode() === -1

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
                    WallpaperOptimizationPolicyService.settingsMaximumResolutionScale())
                stepSize: WallpaperOptimizationPolicyService.resolutionCustomStep
                decimals: 2
                suffix: "×"
                accessibleName: "Custom wallpaper resolution scale"
                onValueEdited: value =>
                    WallpaperOptimizationPolicyService.setCustomResolutionScale(value)
            }
        }

        SettingChoiceRow {
            Layout.fillWidth: true
            title: "Frame rate"
            choices: [15, 24, 30, -1]
            enabledChoices: WallpaperOptimizationPolicyService.settingsFrameRateModes()
            value: WallpaperOptimizationPolicyService.frameRateMode()
            choiceWidth: 54
            formatChoice: value => value === -1 ? "Custom" : String(value)
            onChoiceSelected: value =>
                WallpaperOptimizationPolicyService.setFrameRateMode(value)
        }

        RowLayout {
            Layout.fillWidth: true
            visible: WallpaperOptimizationPolicyService.frameRateMode() === -1

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
                    WallpaperOptimizationPolicyService.settingsMaximumFrameRate())
                stepSize: WallpaperOptimizationPolicyService.frameRateCustomStep
                decimals: 2
                suffix: "FPS"
                accessibleName: "Custom wallpaper frame rate"
                onValueEdited: value =>
                    WallpaperOptimizationPolicyService.setCustomFrameRate(value)
            }
        }

        SettingChoiceRow {
            Layout.fillWidth: true
            title: "Bitrate"
            choices: [4, 8, 12, -1]
            enabledChoices: WallpaperOptimizationPolicyService.settingsBitRateModes()
            value: WallpaperOptimizationPolicyService.bitRateMode()
            choiceWidth: 54
            formatChoice: value => value === -1 ? "Custom" : String(value)
            onChoiceSelected: value =>
                WallpaperOptimizationPolicyService.setBitRateMode(value)
        }

        RowLayout {
            Layout.fillWidth: true
            visible: WallpaperOptimizationPolicyService.bitRateMode() === -1

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
                    WallpaperOptimizationPolicyService.settingsMaximumBitRate())
                stepSize: WallpaperOptimizationPolicyService.bitRateCustomStep
                decimals: 1
                suffix: "Mbps"
                accessibleName: "Custom wallpaper bitrate"
                onValueEdited: value =>
                    WallpaperOptimizationPolicyService.setCustomBitRate(value)
            }
        }

        Item { Layout.fillHeight: true }
    }
}
