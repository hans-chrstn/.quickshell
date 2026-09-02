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

        SettingsHeader { title: "Wallpaper Options" }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            SmoothScrollBehavior { target: optionsScroller }
            ScrollEdgeFeedback { target: optionsScroller }

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
                        text: "Playback Assessment"
                        color: Design.textMuted
                        font.family: Design.fontText
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    SettingNavigationToggle {
                        Layout.fillWidth: true
                        title: "Allow media optimization · Dangerous"
                        description: "Permits explicit transcoding with sustained CPU and disk use"
                        dangerous: true
                        checked: ConfigService.allowWallpaperOptimization
                        onActivated: SettingsService.openPage(
                            "wallpaper_optimization")
                        onToggled: value => SettingsService.setSetting(
                            "allowWallpaperOptimization", value)
                    }

                    SettingNavigationTile {
                        Layout.fillWidth: true
                        title: "Cache"
                        description: "Inspect, clean, and clear generated media"
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
                        text: "Assign a wallpaper to inspect playback cost"
                        color: Design.textMuted
                        font.family: Design.fontText
                        font.pixelSize: 10
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Design.separator
                    }

                    Text {
                        text: "Playback"
                        color: Design.textMuted
                        font.family: Design.fontText
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    SettingToggle {
                        Layout.fillWidth: true
                        title: "Pause animation while idle"
                        description: checked
                            ? "Recommended · pauses decoding after "
                                + root.idleTimeoutLabel()
                            : "Higher resource use · animation continues while you are away"
                        checked: ConfigService.pauseWallpaperWhenIdle
                        onToggled: value => SettingsService.setSetting(
                            "pauseWallpaperWhenIdle", value)
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: ConfigService.pauseWallpaperWhenIdle

                        Text {
                            Layout.fillWidth: true
                            text: "Idle timeout"
                            color: Design.textMuted
                            font.family: Design.fontText
                            font.pixelSize: 10
                        }

                        SettingNumericStepper {
                            value: ConfigService.wallpaperIdleTimeoutSeconds / 60
                            from: 1
                            to: 120
                            stepSize: 1
                            decimals: 0
                            suffix: "min"
                            accessibleName: "Animated wallpaper idle timeout"
                            onValueEdited: value => SettingsService.setSetting(
                                "wallpaperIdleTimeoutSeconds", value * 60)
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Design.separator
                    }

                    Text {
                        text: "Transitions"
                        color: Design.textMuted
                        font.family: Design.fontText
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    SettingToggle {
                        Layout.fillWidth: true
                        title: "Wallpaper transitions"
                        description: checked
                            ? "Crossfade between settled wallpaper selections"
                            : "Switch wallpapers immediately"
                        checked: ConfigService.wallpaperTransitionsEnabled
                        onToggled: value => SettingsService.setSetting(
                            "wallpaperTransitionsEnabled", value)
                    }

                    SettingSlider {
                        Layout.fillWidth: true
                        enabled: ConfigService.wallpaperTransitionsEnabled
                            && !ConfigService.reduceWallpaperMotion
                        opacity: enabled ? 1 : 0.45
                        title: "Transition duration"
                        description: "Duration of the bounded two-renderer crossfade"
                        from: 120
                        to: 800
                        stepSize: 20
                        value: ConfigService.wallpaperTransitionDuration
                        onValueEdited: value => SettingsService.setSetting(
                            "wallpaperTransitionDuration", value)
                    }

                    SettingToggle {
                        Layout.fillWidth: true
                        enabled: ConfigService.wallpaperTransitionsEnabled
                        opacity: enabled ? 1 : 0.45
                        title: "Reduce wallpaper motion"
                        description: checked
                            ? "Use immediate swaps without wallpaper motion"
                            : "Allow the configured crossfade"
                        checked: ConfigService.reduceWallpaperMotion
                        onToggled: value => SettingsService.setSetting(
                            "reduceWallpaperMotion", value)
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Design.separator
                    }

                    Text {
                        text: "Experimental"
                        color: Design.textMuted
                        font.family: Design.fontText
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    SettingToggle {
                        Layout.fillWidth: true
                        title: "Coverage-aware suspension"
                        description: "Keep animation running until floating windows cover 75%"
                        checked: ConfigService.experimentalFloatingWallpaperSuspension
                        onToggled: value => SettingsService.setSetting(
                            "experimentalFloatingWallpaperSuspension", value)
                    }

                    SettingToggle {
                        Layout.fillWidth: true
                        title: "Pause animation on battery"
                        description: "Use the static poster while the laptop is unplugged"
                        checked: ConfigService.experimentalPauseWallpaperOnBattery
                        onToggled: value => SettingsService.setSetting(
                            "experimentalPauseWallpaperOnBattery", value)
                    }
                }
            }
        }
    }

    function idleTimeoutLabel() {
        const minutes = Math.max(1, Math.round(
            ConfigService.wallpaperIdleTimeoutSeconds / 60))
        return minutes === 1 ? "1 minute away" : minutes + " minutes away"
    }
}
