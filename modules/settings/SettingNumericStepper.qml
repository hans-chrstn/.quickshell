import QtQuick
import QtQuick.Layouts
import qs.components
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

    implicitWidth: 160
    implicitHeight: Design.minimumTouchTarget

    readonly property real normalizedValue: NumericRange.quantize(value, from, to, stepSize, from)
    readonly property string formattedValue: normalizedValue.toFixed(Math.max(0, decimals))

    function commitText(text) {
        const parsed = Number(String(text).trim());
        const next = NumericRange.quantize(parsed, from, to, stepSize, normalizedValue);
        editor.text = next.toFixed(Math.max(0, decimals));
        valueEdited(next);
    }

    function step(direction) {
        valueEdited(NumericRange.stepped(normalizedValue, direction, from, to, stepSize));
    }

    Rectangle {
        anchors.fill: parent
        radius: Design.radiusControl
        color: Theme.fillElevated
        border.width: 1
        border.color: editor.activeFocus ? Theme.accent : Theme.separator

        Behavior on border.color {
            ColorAnimation {
                duration: Design.motionStateDuration
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            HighlightableSurface {
                Layout.preferredWidth: Design.minimumTouchTarget
                Layout.fillHeight: true
                enabled: root.normalizedValue > root.from
                baseColor: "transparent"
                cornerRadius: Design.radiusControl
                accessibleName: "Decrease " + root.accessibleName
                onSurfaceActivated: root.step(-1)

                Text {
                    anchors.centerIn: parent
                    text: "−"
                    color: Theme.textPrimary
                    font.family: Design.fontText
                    font.pixelSize: Design.typeTitle
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 16
                color: Theme.separator
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
                        color: Theme.textPrimary
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.textPrimary
                        horizontalAlignment: TextInput.AlignHCenter
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Design.fontMono
                        font.pixelSize: Design.typeLabel
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
                        color: Theme.textSecondary
                        font.family: Design.fontMono
                        font.pixelSize: Design.typeLabel
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 16
                color: Theme.separator
            }

            HighlightableSurface {
                Layout.preferredWidth: Design.minimumTouchTarget
                Layout.fillHeight: true
                enabled: root.normalizedValue < root.to
                baseColor: "transparent"
                cornerRadius: Design.radiusControl
                accessibleName: "Increase " + root.accessibleName
                onSurfaceActivated: root.step(1)

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    color: Theme.textPrimary
                    font.family: Design.fontText
                    font.pixelSize: Design.typeTitle
                }
            }
        }
    }
}
