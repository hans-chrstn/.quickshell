import QtQuick
import QtQuick.Layouts
import qs.core
import "NumericRange.js" as NumericRange

Item {
    id: root

    required property real value
    property real from: 0
    property real to: 100
    property real stepSize: 1
    property int decimals: NumericRange.decimalsFor(stepSize)
    property string suffix: ""
    property string accessibleName: "Numeric value"
    signal valueEdited(real value)

    implicitWidth: 142
    implicitHeight: 30

    readonly property real normalizedValue: NumericRange.quantize(
        value, from, to, stepSize, from)
    readonly property string formattedValue:
        normalizedValue.toFixed(Math.max(0, decimals))

    function commitText(text) {
        const parsed = Number(String(text).trim())
        const next = NumericRange.quantize(parsed, from, to, stepSize,
            normalizedValue)
        editor.text = next.toFixed(Math.max(0, decimals))
        valueEdited(next)
    }

    function step(direction) {
        valueEdited(NumericRange.stepped(normalizedValue, direction,
            from, to, stepSize))
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Design.surfaceRaised
        border.width: 1
        border.color: editor.activeFocus ? Design.blue : Design.separator

        Behavior on border.color { ColorAnimation { duration: 110 } }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Item {
                Layout.preferredWidth: 32
                Layout.fillHeight: true
                opacity: root.normalizedValue > root.from ? 1 : 0.3

                Text {
                    anchors.centerIn: parent
                    text: "−"
                    color: Design.text
                    font.family: Design.fontText
                    font.pixelSize: 15
                }

                TapHandler {
                    enabled: root.normalizedValue > root.from
                    onTapped: root.step(-1)
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 16
                color: Design.separator
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Row {
                    anchors.centerIn: parent
                    spacing: 3

                    TextInput {
                        id: editor
                        width: Math.max(28, contentWidth)
                        text: root.formattedValue
                        color: Design.text
                        selectionColor: Design.blue
                        selectedTextColor: Design.text
                        horizontalAlignment: TextInput.AlignHCenter
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Design.fontMono
                        font.pixelSize: 10
                        inputMethodHints: Qt.ImhFormattedNumbersOnly

                        validator: DoubleValidator {
                            bottom: root.from
                            top: root.to
                            decimals: root.decimals
                            notation: DoubleValidator.StandardNotation
                        }

                        onEditingFinished: root.commitText(text)
                        Keys.onUpPressed: root.step(1)
                        Keys.onDownPressed: root.step(-1)
                    }

                    Text {
                        visible: root.suffix.length > 0
                        text: root.suffix
                        color: Design.textMuted
                        font.family: Design.fontMono
                        font.pixelSize: 9
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 16
                color: Design.separator
            }

            Item {
                Layout.preferredWidth: 32
                Layout.fillHeight: true
                opacity: root.normalizedValue < root.to ? 1 : 0.3

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    color: Design.text
                    font.family: Design.fontText
                    font.pixelSize: 14
                }

                TapHandler {
                    enabled: root.normalizedValue < root.to
                    onTapped: root.step(1)
                }
            }
        }
    }
}
