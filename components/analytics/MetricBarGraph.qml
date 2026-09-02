import QtQuick
import QtQuick.Layouts
import qs.core

ColumnLayout {
    id: root

    required property var metrics
    property real maximumValue: {
        let maximum = 0
        for (let index = 0; index < metrics.length; ++index)
            maximum = Math.max(maximum,
                Math.max(0, Number(metrics[index].value ?? 0)))
        return maximum
    }
    property string unit: ""
    property int barHeight: 3
    property int labelColumnWidth: 48
    spacing: 2

    Repeater {
        model: root.metrics

        RowLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 5

            Text {
                Layout.preferredWidth: root.labelColumnWidth
                Layout.minimumWidth: root.labelColumnWidth
                text: modelData.label ?? ""
                color: Design.textMuted
                font.family: Design.fontText
                font.pixelSize: 7
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: root.barHeight
                radius: height / 2
                color: Design.surfaceRaised

                Rectangle {
                    width: root.maximumValue > 0
                        ? parent.width * Math.max(0,
                            Number(modelData.value ?? 0)) / root.maximumValue
                        : 0
                    height: parent.height
                    radius: height / 2
                    color: modelData.color ?? Design.blue
                }
            }

            Text {
                Layout.preferredWidth: 34
                horizontalAlignment: Text.AlignRight
                text: Number(modelData.value ?? 0).toFixed(0) + root.unit
                color: Design.textMuted
                font.family: Design.fontMono
                font.pixelSize: 7
            }
        }
    }
}
