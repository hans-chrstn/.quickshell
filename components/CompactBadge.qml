import QtQuick
import qs.core

Rectangle {
    id: root

    required property string text
    property color accentColor: Theme.accent

    implicitWidth: 26
    implicitHeight: 26
    radius: 8
    color: Theme.tint(accentColor)

    Text {
        anchors.centerIn: parent
        text: root.text
        color: root.accentColor
        font.family: Design.fontDisplay
        font.pixelSize: 9
        font.weight: Font.Bold
    }
}
