import QtQuick
import qs.components
import qs.core

HighlightableSurface {
    id: root

    required property string label
    signal activated

    implicitWidth: labelText.implicitWidth + 24
    implicitHeight: 32
    accentColor: Design.blue
    baseColor: Design.surface
    cornerRadius: 10
    onSurfaceActivated: root.activated()

    Text {
        id: labelText
        anchors.centerIn: parent
        text: root.label
        color: root.selected ? Design.text : Design.textMuted
        font.family: Design.fontText
        font.pixelSize: 11
        font.weight: Font.Medium
    }
}
