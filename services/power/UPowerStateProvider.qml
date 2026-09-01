import QtQuick
import Quickshell.Services.UPower

QtObject {
    readonly property bool ready: Boolean(UPower.displayDevice?.ready)
    readonly property bool available: ready
        && Boolean(UPower.displayDevice?.isLaptopBattery)
    readonly property bool onBattery: available && Boolean(UPower.onBattery)
    readonly property real percentage: available
        ? Math.max(0, Math.min(1,
            Number(UPower.displayDevice?.percentage) || 0)) : 1
}
