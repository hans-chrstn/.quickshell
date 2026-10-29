import QtQuick
import QtQuick.Layouts
import qs.components
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
                    color: Theme.textPrimary
                    font.family: Design.fontText
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
                Text {
                    text: root.description
                    color: Theme.textSecondary
                    font.family: Design.fontText
                    font.pixelSize: 9
                }
            }

            Text {
                text: Math.round(root.value) + " " + root.unit
                color: control.activeFocus || control.pressed ? Theme.selection : Theme.textSecondary
                font.family: Design.fontMono
                font.pixelSize: 10

                Behavior on color {
                    ColorAnimation {
                        duration: Design.motionStateDuration
                        easing.type: Design.motionStandardEasing
                    }
                }
            }
        }

        ValueSlider {
            id: control
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            from: root.from
            to: root.to
            stepSize: root.stepSize
            value: root.value
            accentColor: Theme.selection
            onEditRequested: value => root.valueEdited(value)
        }
    }
}
