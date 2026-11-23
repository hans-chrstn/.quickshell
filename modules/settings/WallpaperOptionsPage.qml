import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components.scrolling
import qs.core
import qs.services.config
import qs.services.settings
import qs.services.wallpaper

SettingPage {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        SettingsHeader {
            title: "Wallpaper Options"
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            SmoothScrollBehavior {
                target: optionsScroller
            }
            ScrollEdgeFeedback {
                target: optionsScroller
            }

            Flickable {
                id: optionsScroller
                anchors.fill: parent
                contentWidth: width
                contentHeight: optionsColumn.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: MinimalScrollBar {}

                ColumnLayout {
                    id: optionsColumn
                    width: optionsScroller.width
                    spacing: 10

                    Text {
                        text: "Media"
                        color: Theme.textSecondary
                        font.family: Design.fontText
                        font.pixelSize: Design.typeBody
                        font.weight: Font.DemiBold
                    }

                    SettingNavigationToggle {
                        Layout.fillWidth: true
                        title: "Allow optimization"
                        description: "May use CPU and disk space"
                        dangerous: true
                        checked: ConfigService.allowWallpaperOptimization
                        onActivated: SettingsService.openPage("wallpaper_optimization")
                        onToggled: value => SettingsService.setSetting("allowWallpaperOptimization", value)
                    }

                    SettingNavigationTile {
                        Layout.fillWidth: true
                        title: "Cache"
                        description: "View and remove cached media"
                        onActivated: SettingsService.openPage("wallpaper_cache")
                    }

                    Repeater {
                        model: WallpaperGuardrailService.assignedAssessments

                        WallpaperGuardrailCard {
                            required property var modelData
                            Layout.fillWidth: true
                            assessment: modelData
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: WallpaperGuardrailService.assignedAssessments.length === 0
                        text: "Choose a wallpaper to see playback details"
                        color: Theme.textSecondary
                        font.family: Design.fontText
                        font.pixelSize: Design.typeLabel
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Theme.separator
                    }

                    Text {
                        text: "Playback"
                        color: Theme.textSecondary
                        font.family: Design.fontText
                        font.pixelSize: Design.typeBody
                        font.weight: Font.DemiBold
                    }

                    SettingToggle {
                        Layout.fillWidth: true
                        title: "Pause animation while idle"
                        description: checked ? "Stop after " + root.idleTimeoutLabel() : "Keep playing when idle"
                        checked: ConfigService.pauseWallpaperWhenIdle
                        onToggled: value => SettingsService.setSetting("pauseWallpaperWhenIdle", value)
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: ConfigService.pauseWallpaperWhenIdle

                        Text {
                            Layout.fillWidth: true
                            text: "Idle timeout"
                            color: Theme.textSecondary
                            font.family: Design.fontText
                            font.pixelSize: Design.typeBody
                        }

                        SettingNumericStepper {
                            value: ConfigService.wallpaperIdleTimeoutSeconds / 60
                            from: 1
                            to: 120
                            stepSize: 1
                            decimals: 0
                            suffix: "min"
                            accessibleName: "Animated wallpaper idle timeout"
                            onValueEdited: value => SettingsService.setSetting("wallpaperIdleTimeoutSeconds", value * 60)
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Theme.separator
                    }

                    Text {
                        text: "Transitions"
                        color: Theme.textSecondary
                        font.family: Design.fontText
                        font.pixelSize: Design.typeBody
                        font.weight: Font.DemiBold
                    }

                    SettingToggle {
                        Layout.fillWidth: true
                        title: "Wallpaper transitions"
                        description: checked ? "Fade between images" : "Change images immediately"
                        checked: ConfigService.wallpaperTransitionsEnabled
                        onToggled: value => SettingsService.setSetting("wallpaperTransitionsEnabled", value)
                    }

                    SettingSlider {
                        Layout.fillWidth: true
                        enabled: ConfigService.wallpaperTransitionsEnabled && !ConfigService.reduceWallpaperMotion
                        opacity: enabled ? 1 : 0.45
                        title: "Transition duration"
                        description: "Fade time"
                        from: 120
                        to: 800
                        stepSize: 20
                        value: ConfigService.wallpaperTransitionDuration
                        onValueEdited: value => SettingsService.setSetting("wallpaperTransitionDuration", value)
                    }

                    SettingToggle {
                        Layout.fillWidth: true
                        enabled: ConfigService.wallpaperTransitionsEnabled
                        opacity: enabled ? 1 : 0.45
                        title: "Reduce wallpaper motion"
                        description: checked ? "Change images without a fade" : "Use the fade above"
                        checked: ConfigService.reduceWallpaperMotion
                        onToggled: value => SettingsService.setSetting("reduceWallpaperMotion", value)
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Theme.separator
                    }

                    Text {
                        text: "Power"
                        color: Theme.textSecondary
                        font.family: Design.fontText
                        font.pixelSize: Design.typeBody
                        font.weight: Font.DemiBold
                    }

                    SettingToggle {
                        Layout.fillWidth: true
                        title: "Coverage-aware suspension"
                        description: "Pause when windows cover most of the wallpaper"
                        checked: ConfigService.experimentalFloatingWallpaperSuspension
                        onToggled: value => SettingsService.setSetting("experimentalFloatingWallpaperSuspension", value)
                    }

                    SettingToggle {
                        Layout.fillWidth: true
                        title: "Pause animation on battery"
                        description: "Show a still image on battery"
                        checked: ConfigService.experimentalPauseWallpaperOnBattery
                        onToggled: value => SettingsService.setSetting("experimentalPauseWallpaperOnBattery", value)
                    }
                }
            }
        }
    }

    function idleTimeoutLabel() {
        const minutes = Math.max(1, Math.round(ConfigService.wallpaperIdleTimeoutSeconds / 60));
        return minutes === 1 ? "1 minute idle" : minutes + " minutes idle";
    }
}
