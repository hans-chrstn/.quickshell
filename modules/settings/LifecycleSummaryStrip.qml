import QtQuick
import QtQuick.Layouts
import qs.core

RowLayout {
    id: root

    required property var summary
    spacing: 6

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

        Rectangle {
            required property var modelData
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: 9
            color: Theme.fillSubtle
            border.width: 1
            border.color: Theme.separator

            Column {
                anchors.centerIn: parent
                spacing: 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.value
                    color: modelData.color
                    font.family: Design.fontMono
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.label
                    color: Theme.textSecondary
                    font.family: Design.fontText
                    font.pixelSize: 8
                }
            }
        }
    }
}
