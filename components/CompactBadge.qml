import QtQuick
import qs.core

Rectangle {
    id: root

    required property string text
    property color accentColor: Design.blue

    implicitWidth: 26
    implicitHeight: 26
    radius: 8
    color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.16)

    Text {
        anchors.centerIn: parent
        text: root.text
        color: root.accentColor
        font.family: Design.fontDisplay
        font.pixelSize: 9
        font.weight: Font.Bold
    }
}
