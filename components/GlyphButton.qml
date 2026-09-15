import QtQuick
import QtQuick.Controls
import qs.core

Rectangle {
    id: root

    required property string glyph
    property string accessibleName: ""
    property string toolTip: accessibleName
    property bool primary: false
    signal activated

    implicitWidth: 30
    implicitHeight: 30
    radius: 10
    color: primary ? Qt.rgba(Design.blue.r, Design.blue.g, Design.blue.b, tap.pressed ? 0.30 : hover.hovered ? 0.24 : 0.17) : tap.pressed ? Qt.rgba(1, 1, 1, 0.13) : hover.hovered ? Design.surfaceRaised : Design.surface
    border.width: primary ? 1 : 0
    border.color: primary ? Qt.rgba(Design.blue.r, Design.blue.g, Design.blue.b, 0.45) : "transparent"
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
        name: root.glyph
        glyphColor: root.primary || hover.hovered ? Design.text : Design.textMuted
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
