import QtQuick
import QtQuick.Layouts
import qs.core

Item {
    id: root

    required property string title
    required property string subtitle
    required property string glyph
    required property real value
    required property real maximumValue
    required property bool muted
    property bool available: true
    property color accentColor: Theme.accent
    readonly property bool amplified: !muted && value > 1.0001
    readonly property color effectiveAccent: muted ? Theme.textSecondary : amplified ? Theme.warning : accentColor
    signal valueEdited(real value)
    signal muteRequested(bool muted)
    signal stepRequested(int steps)

    implicitWidth: 576
    implicitHeight: 110
    opacity: available ? 1 : 0.46

    Accessible.name: title + " volume"
    Accessible.description: subtitle

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        anchors.topMargin: 13
        anchors.bottomMargin: 13
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: root.title
                color: Theme.textPrimary
                font.family: Design.fontText
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }

            Text {
                Layout.fillWidth: true
                text: root.available ? root.subtitle : "Unavailable"
                color: Theme.textSecondary
                font.family: Design.fontText
                font.pixelSize: 12
                elide: Text.ElideMiddle
            }

            Text {
                text: root.muted ? "Muted" : Math.max(0, Math.round(root.value * 100)) + "%"
                color: root.effectiveAccent
                font.family: Design.fontMono
                font.pixelSize: 13
                font.weight: Font.Medium
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            GlyphButton {
                Layout.preferredWidth: 42
                Layout.preferredHeight: 42
                glyphSize: 24
                enabled: root.available
                glyph: root.glyph
                accessibleName: (root.muted ? "Unmute " : "Mute ") + root.title.toLowerCase()
                primary: root.muted
                accentColor: root.muted ? Theme.danger : root.accentColor
                onActivated: root.muteRequested(!root.muted)
            }

            AudioLevelSlider {
                id: levelSlider

                Layout.fillWidth: true
                Layout.preferredHeight: 42
                enabled: root.available
                from: 0
                to: Math.max(0.01, root.maximumValue)
                stepSize: 0.01
                value: Math.max(from, Math.min(to, root.value))
                Accessible.name: root.title + " level"
                accentColor: root.effectiveAccent
                onLevelEdited: value => root.valueEdited(value)
                onStepRequested: steps => root.stepRequested(steps)
            }
        }
    }
}
