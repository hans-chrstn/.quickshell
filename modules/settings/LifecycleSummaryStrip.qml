import QtQuick
import QtQuick.Layouts
import qs.core

RowLayout {
    id: root

    required property var summary
    spacing: Design.space12

    Repeater {
        model: [
            {
                label: "Active",
                value: root.summary.active ?? 0,
                color: Theme.success
            },
            {
                label: "Retained",
                value: root.summary.retained ?? 0,
                color: Theme.accent
            },
            {
                label: "Eligible",
                value: root.summary.eligible ?? 0,
                color: Theme.warning
            },
            {
                label: "Unloaded",
                value: root.summary.unloaded ?? 0,
                color: Theme.textSecondary
            }
        ]

        SettingMetric {
            required property var modelData
            Layout.fillWidth: true
            label: modelData.label
            value: String(modelData.value)
        }
    }
}
