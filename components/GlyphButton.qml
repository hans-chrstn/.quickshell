import QtQuick
import qs.core

InteractionFrame {
    id: root

    required property string glyph
    property string accessibleName: ""
    property string toolTip: accessibleName
    property bool primary: false
    property real glyphSize: 17
    signal activated

    implicitWidth: 40
    implicitHeight: 40
    selected: primary
    selectionFillEnabled: false
    cornerRadius: 12
    controlInset: 2
    onTriggered: root.activated()

    Accessible.name: accessibleName
    Accessible.role: Accessible.Button
    IslandToolTip {
        visible: root.hovered && root.toolTip.length > 0
        text: root.toolTip
    }

    Rectangle {
        anchors.centerIn: parent
        width: 30
        height: 30
        radius: 11
        color: root.primary ? Theme.alpha(root.accentColor, 0.12) : Theme.fillQuiet

        Behavior on color {
            ColorAnimation {
                duration: Design.motionStateDuration
                easing.type: Design.motionStandardEasing
            }
        }
    }

    IslandGlyph {
        anchors.centerIn: parent
        width: root.glyphSize
        height: root.glyphSize
        name: root.glyph
        glyphColor: root.primary ? Theme.tintOpaque(root.accentColor) : root.hovered ? Theme.textPrimary : Theme.textSecondary
    }
}
