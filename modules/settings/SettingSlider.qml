import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core

Item {
    id: root

    required property string title
    required property string description
    required property real value
    property real from: 0
    property real to: 1000
    property real stepSize: 10
    property string unit: "ms"
    signal valueEdited(real value)

    implicitHeight: 58

    ColumnLayout {
        anchors.fill: parent
        spacing: 5

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: root.title
                    color: Design.text
                    font.family: Design.fontText
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
                Text {
                    text: root.description
                    color: Design.textMuted
                    font.family: Design.fontText
                    font.pixelSize: 9
                }
            }

            Text {
                text: Math.round(root.value) + " " + root.unit
                color: Design.textMuted
                font.family: Design.fontMono
                font.pixelSize: 10
            }
        }

        Slider {
            id: control
            Layout.fillWidth: true
            Layout.preferredHeight: 16
            from: root.from
            to: root.to
            stepSize: root.stepSize
            value: root.value
            onMoved: root.valueEdited(value)

            background: Rectangle {
                x: control.leftPadding
                y: control.topPadding + control.availableHeight / 2 - height / 2
                width: control.availableWidth
                height: 3
                radius: 2
                color: Design.separator

                Rectangle {
                    width: control.visualPosition * parent.width
                    height: parent.height
                    radius: parent.radius
                    color: Design.blue
                }
            }

            handle: Rectangle {
                x: control.leftPadding + control.visualPosition
                    * (control.availableWidth - width)
                y: control.topPadding + control.availableHeight / 2 - height / 2
                implicitWidth: 12
                implicitHeight: 12
                radius: 6
                color: Design.text
                scale: control.pressed ? 1.25 : (sliderHover.hovered ? 1.12 : 1)

                Behavior on scale {
                    NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
                }

                HoverHandler { id: sliderHover }
            }
        }
    }
}
