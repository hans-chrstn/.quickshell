import QtQuick
import QtQuick.Layouts
import qs.core

Item {
    id: root

    required property string title
    required property string description
    required property bool checked
    signal toggled(bool newValue)

    implicitHeight: 38

    RowLayout {
        anchors.fill: parent
        spacing: 12

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

        Rectangle {
            width: 36
            height: 20
            radius: 10
            color: root.checked ? Design.blue : Design.surfaceRaised
            border.width: 1
            border.color: Design.separator

            Behavior on color { ColorAnimation { duration: 120 } }

            Rectangle {
                x: root.checked ? parent.width - width - 2 : 2
                y: 2
                width: 16
                height: 16
                radius: 8
                color: Design.text
                Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            }

            TapHandler {
                onTapped: root.toggled(!root.checked)
            }
        }
    }
}
