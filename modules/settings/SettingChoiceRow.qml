import QtQuick
import QtQuick.Layouts
import qs.components
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

    implicitHeight: Design.minimumTouchTarget

    RowLayout {
        anchors.fill: parent
        spacing: Design.space8

        Text {
            Layout.fillWidth: true
            text: root.title
            color: Theme.textSecondary
            font.family: Design.fontText
            font.pixelSize: Design.typeBody
        }

        RowLayout {
            spacing: Design.space4

            Repeater {
                model: root.choices

                HighlightableSurface {
                    required property var modelData
                    readonly property bool choiceSelected: modelData === root.value
                    readonly property bool choiceEnabled: root.enabledChoices.indexOf(modelData) >= 0

                    Layout.preferredWidth: Math.max(root.choiceWidth, Design.minimumTouchTarget)
                    Layout.preferredHeight: Design.minimumTouchTarget
                    interactive: choiceEnabled
                    selected: choiceSelected
                    focused: hover.hovered
                    accentColor: Theme.accent
                    baseColor: Theme.fillElevated
                    cornerRadius: Design.radiusControl
                    opacity: choiceEnabled ? 1 : 0.32
                    accessibleName: root.title + ": " + root.formatChoice(modelData)

                    HoverHandler {
                        id: hover
                    }
                    onSurfaceActivated: root.choiceSelected(modelData)

                    Text {
                        anchors.centerIn: parent
                        text: root.formatChoice(parent.modelData)
                        color: Theme.textPrimary
                        font.family: Design.fontMono
                        font.pixelSize: Design.typeLabel
                        font.weight: parent.choiceSelected ? Font.DemiBold : Font.Normal
                    }
                }
            }
        }
    }
}
