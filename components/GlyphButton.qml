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
    baseColor: "transparent"
    hoverColor: Theme.interactionHover
    cornerRadius: 12
    controlInset: 2
    onTriggered: root.activated()

    Accessible.name: accessibleName
    Accessible.role: Accessible.Button
    IslandToolTip {
        visible: root.hovered && root.toolTip.length > 0
        text: root.toolTip
    }

    IslandGlyph {
        anchors.centerIn: parent
        width: root.glyphSize
        height: root.glyphSize
        name: root.glyph
        glyphColor: root.primary ? Theme.tintOpaque(root.accentColor) : root.hovered ? Theme.textPrimary : Theme.textSecondary
    }
}
