import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services.settings

SettingPage {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        SettingsHeader {
            title: "Island Style"
        }

        SettingSlider {
            Layout.fillWidth: true
            title: "Collapsed Width"
            description: "Width of the island in its resting state"
            from: 100; to: 300; stepSize: 5
            unit: "px"
            value: SettingsService.islandCollapsedWidth
            onValueEdited: value => SettingsService.setSetting("islandCollapsedWidth", value)
        }

        SettingSlider {
            Layout.fillWidth: true
            title: "Expanded Width"
            description: "Width applied proportionally to every island module"
            from: 90; to: 125; stepSize: 1
            unit: "%"
            value: SettingsService.islandWidthPercent
            onValueEdited: value => SettingsService.setSetting("islandWidthPercent", value)
        }

        SettingSlider {
            Layout.fillWidth: true
            title: "Expanded Height"
            description: "Height applied proportionally to every island module"
            from: 90; to: 125; stepSize: 1
            unit: "%"
            value: SettingsService.islandHeightPercent
            onValueEdited: value => SettingsService.setSetting("islandHeightPercent", value)
        }

        SettingSlider {
            Layout.fillWidth: true
            title: "Body Corner Radius"
            description: "Rounding of the bottom corners of the island"
            from: 0; to: 40; stepSize: 1
            unit: "px"
            value: SettingsService.islandBodyRadius
            onValueEdited: value => SettingsService.setSetting("islandBodyRadius", value)
        }

        SettingSlider {
            Layout.fillWidth: true
            title: "Wing Size"
            description: "Width of the side wings that anchor to the top edge"
            from: 0; to: 40; stepSize: 1
            unit: "px"
            value: SettingsService.islandWing
            onValueEdited: value => SettingsService.setSetting("islandWing", value)
        }

        SettingToggle {
            Layout.fillWidth: true
            title: "Compositor Blur"
            description: "Enable background blur effect behind the island"
            checked: SettingsService.enableBlur
            onToggled: newValue => SettingsService.setSetting("enableBlur", newValue)
        }

        Item { Layout.fillHeight: true }

        SettingButton {
            label: "Reset Style"
            Layout.preferredHeight: 18
            Layout.bottomMargin: 2
            onClicked: SettingsService.resetStyle()
        }
    }
}
