import QtQuick
import qs.core
import qs.components

InteractionFrame {
    id: root

    required property string glyph
    required property string accessibleName
    property bool active: false
    signal activated

    implicitWidth: Design.controlRailButtonSize
    implicitHeight: Design.controlRailButtonSize
    cornerRadius: width / 2
    selected: active
    accentSelectedOutline: active
    baseColor: Theme.fillQuiet
    hoverColor: Theme.fillElevated
    onTriggered: activated()

    Accessible.name: accessibleName
    Accessible.role: Accessible.Button

    IslandGlyph {
        anchors.centerIn: parent
        width: 19
        height: 19
        name: root.glyph
        glyphColor: root.active ? Theme.accent : root.hovered ? Theme.textPrimary : Theme.textSecondary
    }

    IslandToolTip {
        visible: root.hovered && root.enabled
        text: root.accessibleName
    }
}
