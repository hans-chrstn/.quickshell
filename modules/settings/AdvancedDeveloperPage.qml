import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services.config
import qs.services.settings

SettingPage {
    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        SettingsHeader {
            title: "Advanced"
        }

        Text {
            Layout.fillWidth: true
            text: "These controls affect resource use and display power."
            color: Theme.textSecondary
            font.family: Design.fontText
            font.pixelSize: Design.typeBody
            wrapMode: Text.Wrap
        }

        SettingNavigationToggle {
            Layout.fillWidth: true
            title: "Adaptive lifecycle"
            description: "May unload idle views sooner"
            dangerous: true
            checked: SettingsService.adaptiveLifecycleEnabled
            onActivated: SettingsService.openPage("developer_lifecycle")
            onToggled: value => SettingsService.setSetting("adaptiveLifecycleEnabled", value)
        }

        SettingToggle {
            Layout.fillWidth: true
            title: "Turn off idle displays"
            description: "Uses the system idle timeout"
            dangerous: true
            checked: ConfigService.experimentalDpmsOnIdle
            onToggled: value => SettingsService.setSetting("experimentalDpmsOnIdle", value)
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
