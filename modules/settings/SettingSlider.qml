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

    implicitHeight: description.length > 0 ? 64 : 52

    ColumnLayout {
        anchors.fill: parent
        spacing: Design.space4

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: root.title
                    color: Theme.textPrimary
                    font.family: Design.fontText
                    font.pixelSize: Design.typeBody
                    font.weight: Font.DemiBold
                }
                Text {
                    text: root.description
                    visible: text.length > 0
                    color: Theme.textSecondary
                    font.family: Design.fontText
                    font.pixelSize: Design.typeLabel
                    elide: Text.ElideRight
                }
            }

            Text {
                text: Math.round(root.value) + " " + root.unit
                color: control.activeFocus || control.pressed ? Theme.textPrimary : Theme.textSecondary
                font.family: Design.fontMono
                font.pixelSize: Design.typeLabel

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
            Layout.preferredHeight: Design.minimumTouchTarget
            from: root.from
            to: root.to
            stepSize: root.stepSize
            value: root.value
            accentColor: Theme.accent
            Accessible.name: root.title
            onEditRequested: value => root.valueEdited(value)
        }
    }
}
