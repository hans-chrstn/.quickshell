import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services.settings

SettingPage {
    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        SettingsHeader { title: "Advanced" }

        Text {
            Layout.fillWidth: true
            text: "Developer options can change resource lifetime and recovery behavior."
            color: Design.textMuted
            font.family: Design.fontText
            font.pixelSize: 9
            wrapMode: Text.Wrap
        }

        SettingNavigationToggle {
            Layout.fillWidth: true
            title: "Adaptive lifecycle · Experimental"
            description: "Dangerous · tune inactive resource eviction"
            dangerous: true
            checked: SettingsService.adaptiveLifecycleEnabled
            onActivated: SettingsService.openPage("developer_lifecycle")
            onToggled: value => SettingsService.setSetting(
                "adaptiveLifecycleEnabled", value)
        }

        Item { Layout.fillHeight: true }
    }
}
