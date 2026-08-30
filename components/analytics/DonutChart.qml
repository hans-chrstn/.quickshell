import QtQuick
import QtQuick.Layouts
import qs.core

RowLayout {
    id: root

    required property var segments
    property string centerValue: ""
    property string centerLabel: ""
    property int diameter: 68
    property int strokeWidth: 8
    spacing: 14

    readonly property real totalValue: {
        let total = 0
        for (let index = 0; index < segments.length; ++index)
            total += Math.max(0, Number(segments[index].value ?? 0))
        return total
    }

    implicitHeight: Math.max(diameter, legend.implicitHeight)

    Item {
        Layout.preferredWidth: root.diameter
        Layout.preferredHeight: root.diameter

        Canvas {
            id: canvas
            anchors.fill: parent

            onPaint: {
                const context = getContext("2d")
                context.reset()
                const center = width / 2
                const radius = Math.max(0,
                    (Math.min(width, height) - root.strokeWidth) / 2)
                context.lineWidth = root.strokeWidth
                context.lineCap = "round"

                if (root.totalValue <= 0) {
                    context.strokeStyle = Design.surfaceRaised
                    context.beginPath()
                    context.arc(center, center, radius, 0, Math.PI * 2)
                    context.stroke()
                    return
                }

                const gap = root.segments.length > 1 ? 0.045 : 0
                let angle = -Math.PI / 2
                for (let index = 0; index < root.segments.length; ++index) {
                    const segment = root.segments[index]
                    const value = Math.max(0, Number(segment.value ?? 0))
                    if (value <= 0)
                        continue
                    const sweep = Math.PI * 2 * value / root.totalValue
                    context.strokeStyle = segment.color ?? Design.textMuted
                    context.beginPath()
                    context.arc(center, center, radius, angle + gap,
                        angle + sweep - gap)
                    context.stroke()
                    angle += sweep
                }
            }

            Connections {
                target: root
                function onSegmentsChanged() { canvas.requestPaint() }
                function onTotalValueChanged() { canvas.requestPaint() }
            }

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Component.onCompleted: requestPaint()
        }

        Column {
            anchors.centerIn: parent
            spacing: -1

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.centerValue
                color: Design.text
                font.family: Design.fontMono
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.centerLabel
                color: Design.textMuted
                font.family: Design.fontText
                font.pixelSize: 7
            }
        }
    }

    GridLayout {
        id: legend
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 6
        rowSpacing: 6

        Repeater {
            model: root.segments

            Rectangle {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 27
                radius: 8
                color: Design.surface
                border.width: 1
                border.color: Design.separator

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 5

                    Rectangle {
                        Layout.preferredWidth: 6
                        Layout.preferredHeight: 6
                        radius: 3
                        color: modelData.color ?? Design.textMuted
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.label ?? ""
                        color: Design.textMuted
                        font.family: Design.fontText
                        font.pixelSize: 8
                        elide: Text.ElideRight
                    }

                    Text {
                        text: modelData.value ?? 0
                        color: Design.text
                        font.family: Design.fontMono
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
    }
}
