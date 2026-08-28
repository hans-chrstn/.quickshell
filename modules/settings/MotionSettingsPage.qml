import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services.settings

SettingPage {
    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        SettingsHeader {
            title: "Motion"
        }

        SettingSlider {
            Layout.fillWidth: true
            title: "Island resize"
            description: "Expansion and contraction duration"
            from: 200; to: 900; stepSize: 10
            value: SettingsService.resizeDuration
            onValueEdited: value => SettingsService.resizeDuration = value
        }
        SettingSlider {
            Layout.fillWidth: true
            title: "Edge reveal"
            description: "Show and hide motion at the monitor edge"
            from: 120; to: 600; stepSize: 10
            value: SettingsService.revealDuration
            onValueEdited: value => SettingsService.revealDuration = value
        }
        SettingSlider {
            Layout.fillWidth: true
            title: "Content reveal"
            description: "Standard module content entrance"
            from: 80; to: 400; stepSize: 10
            value: SettingsService.contentRevealDuration
            onValueEdited: value => SettingsService.contentRevealDuration = value
        }
        SettingSlider {
            Layout.fillWidth: true
            title: "Attention delay"
            description: "Pause before an invoked module expands"
            from: 0; to: 500; stepSize: 10
            value: SettingsService.attentionExpandDelay
            onValueEdited: value => SettingsService.attentionExpandDelay = value
        }
        SettingSlider {
            Layout.fillWidth: true
            title: "Module handoff"
            description: "Closing lifecycle before returning to the clock"
            from: 180; to: 800; stepSize: 10
            value: SettingsService.moduleCloseDuration
            onValueEdited: value => SettingsService.moduleCloseDuration = value
        }

        Item { Layout.fillHeight: true }

        SettingButton {
            label: "Reset Motion"
            Layout.preferredHeight: 18
            Layout.bottomMargin: 2
            onClicked: SettingsService.resetMotion()
        }
    }
}
