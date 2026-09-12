import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services.settings

SettingPage {
    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        SettingsHeader { title: "Lifecycle" }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: [
                    { label: "Experimental", color: Design.yellow },
                    { label: "Dangerous", color: Design.red }
                ]

                Rectangle {
                    required property var modelData
                    Layout.preferredWidth: badgeText.implicitWidth + 12
                    Layout.preferredHeight: 18
                    radius: 9
                    color: Qt.rgba(modelData.color.r, modelData.color.g,
                        modelData.color.b, 0.13)
                    border.width: 1
                    border.color: Qt.rgba(modelData.color.r,
                        modelData.color.g, modelData.color.b, 0.38)

                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: modelData.label
                        color: modelData.color
                        font.family: Design.fontText
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        SettingToggle {
            Layout.fillWidth: true
            title: "Adaptive eviction"
            description: checked
                ? "Inactive eligible resources share the adaptive budget"
                : "Owners use deterministic fallback timeouts only"
            dangerous: true
            checked: SettingsService.adaptiveLifecycleEnabled
            onToggled: value => SettingsService.setSetting(
                "adaptiveLifecycleEnabled", value)
        }

        SettingChoiceRow {
            Layout.fillWidth: true
            enabled: SettingsService.adaptiveLifecycleEnabled
            opacity: enabled ? 1 : 0.38
            title: "Inactive budget · Dangerous"
            choices: [0, 60, 100, 120, 180]
            value: SettingsService.lifecycleInactiveBudgetUnits
            formatChoice: value => String(value)
            onChoiceSelected: value => SettingsService.setSetting(
                "lifecycleInactiveBudgetUnits", value)

            Behavior on opacity { NumberAnimation { duration: 120 } }
        }

        Text {
            Layout.fillWidth: true
            text: "Lower values release more inactive eligible resources. Zero keeps none warm; this never overrides active or state-owner protection."
            color: Design.textMuted
            font.family: Design.fontText
            font.pixelSize: 8
            wrapMode: Text.Wrap
        }

        Text {
            Layout.fillWidth: true
            text: "Always enforced: active and state-owning resources are protected; owners may refuse eviction; restoration contracts, diagnostics, and deterministic tie-breaking remain enabled."
            color: Design.textMuted
            font.family: Design.fontText
            font.pixelSize: 8
            wrapMode: Text.Wrap
        }

        Item { Layout.fillHeight: true }

        SettingButton {
            label: "Reset Lifecycle"
            onClicked: SettingsService.resetLifecycleSettings()
        }
    }
}
