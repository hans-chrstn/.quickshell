import QtQuick
import QtQuick.Controls
import qs.core

Rectangle {
    id: root

    required property string glyph
    property string accessibleName: ""
    property string toolTip: accessibleName
    property bool primary: false
    property color accentColor: Theme.accent
    property real glyphSize: 17
    signal activated

    implicitWidth: 30
    implicitHeight: 30
    radius: 10
    color: primary ? Theme.alpha(root.accentColor, tap.pressed ? 0.30 : hover.hovered ? 0.23 : 0.16) : tap.pressed ? Theme.controlPressed : hover.hovered ? Theme.controlHover : Theme.controlFill
    border.width: primary ? 1 : 0
    border.color: primary ? Theme.alpha(root.accentColor, 0.36) : "transparent"
    scale: tap.pressed ? 0.94 : 1
    opacity: enabled ? 1 : 0.42

    Accessible.name: accessibleName
    Accessible.role: Accessible.Button
    IslandToolTip {
        visible: hover.hovered && root.toolTip.length > 0
        text: root.toolTip
    }

    Behavior on color {
        ColorAnimation {
            duration: 110
        }
    }
    Behavior on scale {
        NumberAnimation {
            duration: 80
            easing.type: Easing.OutCubic
        }
    }

    IslandGlyph {
        anchors.centerIn: parent
        width: root.glyphSize
        height: root.glyphSize
        name: root.glyph
        glyphColor: root.primary || hover.hovered ? Theme.textPrimary : Theme.textSecondary
    }

    HoverHandler {
        id: hover
    }
    TapHandler {
        id: tap
        enabled: root.enabled
        acceptedButtons: Qt.LeftButton
        onTapped: {
            root.forceActiveFocus();
            root.activated();
        }
    }
}
