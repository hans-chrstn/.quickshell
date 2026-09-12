import QtQuick
import QtQuick.Layouts
import qs.core

RowLayout {
    id: root

    required property var summary
    spacing: 6

    Repeater {
        model: [
            { label: "Active", value: root.summary.active ?? 0,
              color: Design.green },
            { label: "Retained", value: root.summary.retained ?? 0,
              color: Design.blue },
            { label: "Eligible", value: root.summary.eligible ?? 0,
              color: Design.yellow },
            { label: "Unloaded", value: root.summary.unloaded ?? 0,
              color: Design.textMuted }
        ]

        Rectangle {
            required property var modelData
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: 9
            color: Design.surface
            border.width: 1
            border.color: Design.separator

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
                    color: Design.textMuted
                    font.family: Design.fontText
                    font.pixelSize: 8
                }
            }
        }
    }
}
