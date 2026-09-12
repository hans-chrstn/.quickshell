import QtQuick
import qs.core

Text {
    id: root

    required property string label
    property bool dangerous: false
    signal clicked()

    text: label
    color: root.dangerous ? Design.red
        : hover.hovered ? Design.text : Design.textMuted
    font.family: Design.fontText
    font.pixelSize: 11

    Behavior on color { ColorAnimation { duration: 110 } }

    HoverHandler { id: hover }
    TapHandler {
        onTapped: root.clicked()
    }
}
