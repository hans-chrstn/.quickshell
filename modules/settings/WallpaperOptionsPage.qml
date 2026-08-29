import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components.scrolling
import qs.core
import qs.services.config
import qs.services.settings

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
}
