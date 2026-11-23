import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components.scrolling
import qs.core
import qs.services.settings

SettingPage {
    id: root

    Flickable {
        id: settingsScroll
        anchors.fill: parent
        contentWidth: width
        contentHeight: settingsColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        SmoothScrollBehavior {
            target: settingsScroll
        }
        ScrollEdgeFeedback {
            target: settingsScroll
        }
        ScrollBar.vertical: MinimalScrollBar {}

        ColumnLayout {
            id: settingsColumn
            width: settingsScroll.width - Design.space8
            spacing: Design.space8

            SettingsHeader {
                title: "Island Style"
            }

            SettingSlider {
                Layout.fillWidth: true
                title: "Compact width"
                description: "Time and weather"
                from: 260
                to: 420
                stepSize: 5
                unit: "px"
                value: SettingsService.topIslandCompactWidth
                onValueEdited: value => SettingsService.setSetting("topIslandCompactWidth", value)
            }

            SettingSlider {
                Layout.fillWidth: true
                title: "Expanded width"
                description: "Media, alerts, and apps"
                from: 85
                to: 115
                stepSize: 1
                unit: "%"
                value: SettingsService.topIslandExpandedScale
                onValueEdited: value => SettingsService.setSetting("topIslandExpandedScale", value)
            }

            SettingSlider {
                Layout.fillWidth: true
                title: "Expanded corners"
                description: ""
                from: 16
                to: 40
                stepSize: 1
                unit: "px"
                value: SettingsService.topIslandCornerRadius
                onValueEdited: value => SettingsService.setSetting("topIslandCornerRadius", value)
            }

            SettingToggle {
                Layout.fillWidth: true
                title: "Compositor blur"
                description: "Island and rail"
                checked: SettingsService.enableBlur
                onToggled: newValue => SettingsService.setSetting("enableBlur", newValue)
            }

            SettingButton {
                label: "Reset Style"
                Layout.alignment: Qt.AlignRight
                onClicked: SettingsService.resetStyle()
            }
        }
    }
}
