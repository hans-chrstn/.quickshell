import QtQuick
import qs.core

Text {
    id: root

    required property string label
    signal clicked()

    text: label
    color: hover.hovered ? Design.text : Design.textMuted
    font.family: Design.fontText
    font.pixelSize: 11

    Behavior on color { ColorAnimation { duration: 110 } }

    HoverHandler { id: hover }
    TapHandler {
        onTapped: root.clicked()
    }
}
