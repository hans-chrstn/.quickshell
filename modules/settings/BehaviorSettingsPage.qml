import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services.island
import qs.services.settings

SettingPage {
    id: root

    readonly property bool zenModeEnabled: {
        const revision = IslandPresentationService.revision;
        return revision >= 0 && IslandPresentationService.isZenEnabled(SettingsService.targetScreenName);
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        SettingsHeader {
            title: "Behavior"
        }

        SettingSlider {
            Layout.fillWidth: true
            title: "Hover intent"
            description: "Delay before the resting island expands"
            from: 0
            to: 1000
            stepSize: 20
            value: SettingsService.expandDelay
            onValueEdited: value => SettingsService.setSetting("expandDelay", value)
        }
        SettingSlider {
            Layout.fillWidth: true
            title: "Auto hide"
            description: "Delay before the unattended island hides"
            from: 300
            to: 3000
            stepSize: 50
            value: SettingsService.hideDelay
            onValueEdited: value => SettingsService.setSetting("hideDelay", value)
        }

        SettingToggle {
            Layout.fillWidth: true
            title: "Zen mode on this display"
            description: "Silence notifications, microphone privacy, and other automatic displays"
            checked: root.zenModeEnabled
            onToggled: value => IslandPresentationService.setZenEnabled(SettingsService.targetScreenName, value)
        }

        Item {
            Layout.fillHeight: true
        }

        SettingButton {
            label: "Reset Behavior"
            onClicked: SettingsService.resetBehavior()
        }
    }
}
