import QtQuick
import QtQuick.Layouts
import qs.core

Item {
    id: root

    required property var segments
    property string title: ""
    property string valueText: ""
    property bool showLegend: true
    property int barHeight: 8
    property int segmentSpacing: 2

    readonly property real totalValue: {
        let total = 0
        for (let index = 0; index < segments.length; ++index)
            total += Math.max(0, Number(segments[index].value ?? 0))
        return total
    }

    implicitHeight: header.implicitHeight + 5 + barHeight
        + (showLegend ? 5 + legend.implicitHeight : 0)

    ColumnLayout {
        anchors.fill: parent
        spacing: 5

        RowLayout {
            id: header
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: root.title
                color: Design.textMuted
                font.family: Design.fontText
                font.pixelSize: 8
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Text {
                text: root.valueText
                visible: text.length > 0
                color: Design.textMuted
                font.family: Design.fontMono
                font.pixelSize: 8
            }
        }

        Rectangle {
            id: track
            Layout.fillWidth: true
            Layout.preferredHeight: root.barHeight
            radius: height / 2
            color: Design.surfaceRaised

            Row {
                anchors.fill: parent
                spacing: root.segmentSpacing

                Repeater {
                    model: root.segments

                    Rectangle {
                        required property var modelData
                        readonly property real normalizedValue:
                            Math.max(0, Number(modelData.value ?? 0))
                        width: root.totalValue > 0
                            ? Math.max(0, (track.width
                                - root.segmentSpacing
                                    * Math.max(0, root.segments.length - 1))
                                * normalizedValue / root.totalValue)
                            : 0
                        height: track.height
                        radius: height / 2
                        color: modelData.color ?? Design.textMuted
                        visible: normalizedValue > 0
                    }
                }
            }
        }

        RowLayout {
            id: legend
            Layout.fillWidth: true
            visible: root.showLegend
            spacing: 10

            Repeater {
                model: root.segments

                RowLayout {
                    required property var modelData
                    spacing: 4

                    Rectangle {
                        Layout.preferredWidth: 5
                        Layout.preferredHeight: 5
                        radius: 3
                        color: modelData.color ?? Design.textMuted
                    }

                    Text {
                        text: (modelData.label ?? "") + " "
                            + (modelData.value ?? 0)
                        color: Design.textMuted
                        font.family: Design.fontText
                        font.pixelSize: 7
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }
    }
}
