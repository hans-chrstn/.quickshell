import QtQuick
import qs.core

Rectangle {
    id: root

    property real value: 0
    property real maximumValue: 1
    property color accentColor: Design.text
    property bool animated: true
    readonly property real progress: maximumValue > 0 ? Math.max(0, Math.min(1, value / maximumValue)) : 0

    implicitWidth: 112
    implicitHeight: 6
    radius: height / 2
    color: Qt.rgba(1, 1, 1, 0.12)
    clip: true

    Rectangle {
        width: parent.width * root.progress
        height: parent.height
        radius: parent.radius
        color: root.accentColor

        Behavior on width {
            enabled: root.animated
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }
    }
}
