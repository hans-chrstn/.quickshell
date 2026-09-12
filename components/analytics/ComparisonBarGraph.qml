import QtQuick
import QtQuick.Layouts
import qs.core

ColumnLayout {
    id: root

    required property var metrics
    property color beforeColor: Design.textMuted
    property color afterColor: Design.blue
    spacing: 4

    Repeater {
        model: root.metrics

        ColumnLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: modelData.label ?? ""
                    color: Design.textMuted
                    font.family: Design.fontText
                    font.pixelSize: 7
                }

                Text {
                    text: (modelData.beforeText ?? modelData.before ?? 0)
                        + " → "
                        + (modelData.afterText ?? modelData.after ?? 0)
                    color: Design.textMuted
                    font.family: Design.fontMono
                    font.pixelSize: 7
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 6

                readonly property real maximum: Math.max(1,
                    Number(modelData.before ?? 0),
                    Number(modelData.after ?? 0))

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    width: parent.width * Math.max(0,
                        Number(modelData.before ?? 0)) / parent.maximum
                    height: 2
                    radius: 1
                    color: root.beforeColor
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    width: parent.width * Math.max(0,
                        Number(modelData.after ?? 0)) / parent.maximum
                    height: 2
                    radius: 1
                    color: root.afterColor
                }
            }
        }
    }
}
