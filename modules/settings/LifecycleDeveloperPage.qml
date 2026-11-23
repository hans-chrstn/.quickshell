import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services.settings

SettingPage {
    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        SettingsHeader {
            title: "Lifecycle"
        }

        Text {
            Layout.fillWidth: true
            text: "Affects inactive views"
            color: Theme.textSecondary
            font.family: Design.fontText
            font.pixelSize: Design.typeLabel
            font.weight: Font.DemiBold
        }

        SettingToggle {
            Layout.fillWidth: true
            title: "Adaptive eviction"
            description: checked ? "Share an idle-view budget" : "Use fixed unload timeouts"
            dangerous: true
            checked: SettingsService.adaptiveLifecycleEnabled
            onToggled: value => SettingsService.setSetting("adaptiveLifecycleEnabled", value)
        }

        SettingChoiceRow {
            Layout.fillWidth: true
            enabled: SettingsService.adaptiveLifecycleEnabled
            opacity: enabled ? 1 : 0.38
            title: "Idle-view budget"
            choices: [0, 60, 100, 120, 180]
            value: SettingsService.lifecycleInactiveBudgetUnits
            formatChoice: value => String(value)
            onChoiceSelected: value => SettingsService.setSetting("lifecycleInactiveBudgetUnits", value)

            Behavior on opacity {
                NumberAnimation {
                    duration: Design.motionStateDuration
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Lower budgets unload more idle views. Zero keeps none warm."
            color: Theme.textSecondary
            font.family: Design.fontText
            font.pixelSize: Design.typeLabel
            wrapMode: Text.Wrap
        }

        Text {
            Layout.fillWidth: true
            text: "Active views stay loaded. Each view can restore its state when reopened."
            color: Theme.textSecondary
            font.family: Design.fontText
            font.pixelSize: Design.typeLabel
            wrapMode: Text.Wrap
        }

        Item {
            Layout.fillHeight: true
        }

        SettingButton {
            label: "Reset Lifecycle"
            onClicked: SettingsService.resetLifecycleSettings()
        }
    }
}
