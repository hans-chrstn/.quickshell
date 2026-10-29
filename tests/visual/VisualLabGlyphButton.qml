import QtQuick

VisualLabInteractionFrame {
    id: root

    required property string iconKind

    implicitWidth: 40
    implicitHeight: 40
    controlRadius: 12
    controlInset: 2

    Rectangle {
        anchors.centerIn: parent
        width: 30
        height: 30
        radius: 11
        color: root.selected ? "#1fff9f0a" : "#08ffffff"

        Behavior on color {
            ColorAnimation {
                duration: 140
            }
        }
    }

    VisualLabControlGlyph {
        anchors.centerIn: parent
        width: 17
        height: 17
        iconKind: root.iconKind
        glyphColor: root.semanticRole === "neutral" ? root.selected ? "#ffffaf32" : "#e8e8eb" : root.semanticColor
    }
}
