pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.components

Singleton {
    id: root

    property bool hasUPower: false
    readonly property var device: hasUPower ? UPower.displayDevice : null

    BinaryCheck {
        id: upowerCheck
        binary: "upower"
        onExistsChanged: root.hasUPower = exists
    }
}
