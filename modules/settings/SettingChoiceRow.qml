import QtQuick
import QtQuick.Layouts
import qs.core

Item {
    id: root

    required property string title
    required property var choices
    required property var value
    property var enabledChoices: choices
    property var formatChoice: value => String(value)
    property real choiceWidth: 42
    signal choiceSelected(var value)

    implicitHeight: 34

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Text {
            Layout.fillWidth: true
            text: root.title
            color: Design.textMuted
            font.family: Design.fontText
            font.pixelSize: 10
        }

        RowLayout {
            spacing: 5

            Repeater {
                model: root.choices

                Rectangle {
                    required property var modelData
                    readonly property bool selected: modelData === root.value
                    readonly property bool choiceEnabled:
                        root.enabledChoices.indexOf(modelData) >= 0

                    Layout.preferredWidth: root.choiceWidth
                    Layout.preferredHeight: 24
                    radius: 12
                    color: selected ? Design.blue : Design.surfaceRaised
                    border.width: 1
                    border.color: selected ? Design.blue : Design.separator
                    opacity: choiceEnabled ? 1 : 0.32

                    Behavior on color { ColorAnimation { duration: 110 } }
                    Behavior on border.color {
                        ColorAnimation { duration: 110 }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: root.formatChoice(parent.modelData)
                        color: Design.text
                        font.family: Design.fontMono
                        font.pixelSize: 10
                        font.weight: parent.selected
                            ? Font.DemiBold : Font.Normal
                    }

                    TapHandler {
                        enabled: parent.choiceEnabled
                        onTapped: root.choiceSelected(parent.modelData)
                    }
                }
            }
        }
    }
}
