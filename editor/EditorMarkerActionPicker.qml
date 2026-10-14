import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core

ColumnLayout {
    id: root

    required property var choices
    signal canceled
    signal choiceSelected(var choice)

    spacing: 6

    RowLayout {
        Layout.fillWidth: true

        GlyphButton {
            glyph: "chevronLeft"
            accessibleName: "Back to actions"
            toolTip: "Back to actions"
            onActivated: root.canceled()
        }

        Text {
            Layout.fillWidth: true
            text: "Choose action"
            color: Design.text
            font.family: Design.fontText
            font.pixelSize: 10
            font.weight: Font.DemiBold
        }
    }

    Repeater {
        model: root.choices

        ChoiceCard {
            required property var modelData
            Layout.fillWidth: true
            title: modelData.label
            description: modelData.description
            badgeText: modelData.badge
            onActivated: root.choiceSelected(modelData)
        }
    }
}
