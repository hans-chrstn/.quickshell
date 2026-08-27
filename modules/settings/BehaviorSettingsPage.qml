import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services.settings

Item {
    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Text {
            text: "Behavior"
            color: Design.text
            font.family: Design.fontDisplay
            font.pixelSize: 20
            font.weight: Font.DemiBold
        }

        SettingSlider {
            Layout.fillWidth: true
            title: "Hover intent"
            description: "Delay before the resting island expands"
            from: 0; to: 1000; stepSize: 20
            value: SettingsService.expandDelay
            onValueEdited: value => SettingsService.expandDelay = value
        }
        SettingSlider {
            Layout.fillWidth: true
            title: "Auto hide"
            description: "Delay before the unattended island hides"
            from: 300; to: 3000; stepSize: 50
            value: SettingsService.hideDelay
            onValueEdited: value => SettingsService.hideDelay = value
        }

        Item { Layout.fillHeight: true }

        Text {
            text: "Reset Behavior"
            color: resetHover.hovered ? Design.text : Design.textMuted
            font.family: Design.fontText
            font.pixelSize: 11
            HoverHandler { id: resetHover }
            TapHandler { onTapped: SettingsService.resetBehavior() }
        }
    }
}
