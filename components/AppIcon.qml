import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.core

Item {
    id: root

    required property string name
    property var icon: ""
    property int iconSize: 28

    implicitWidth: iconSize
    implicitHeight: iconSize

    function resolveIcon(value) {
        const name = String(value || "")
        if (name.startsWith("file:") || name.startsWith("image:"))
            return name
        if (name.startsWith("/"))
            return LocalUrl.fromPath(name)

        const resolved = name.length > 0 ? Quickshell.iconPath(name, true) : ""
        if (String(resolved || "").length > 0)
            return resolved
        return Quickshell.iconPath("application-x-executable", true)
    }

    Rectangle {
        anchors.fill: parent
        radius: 7
        color: Design.surfaceRaised

        Text {
            anchors.centerIn: parent
            text: root.name.length > 0 ? root.name[0].toUpperCase() : "?"
            color: Design.textMuted
            font.family: Design.fontDisplay
            font.pixelSize: Math.round(root.iconSize * 0.48)
            font.weight: Font.Bold
        }
    }

    IconImage {
        id: image
        anchors.centerIn: parent
        width: root.iconSize
        height: root.iconSize
        implicitSize: root.iconSize
        source: root.resolveIcon(root.icon)
        asynchronous: true
        mipmap: false
        opacity: status === Image.Ready ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: 140 } }
    }
}
