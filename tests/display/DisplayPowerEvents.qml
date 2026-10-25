import QtQuick
import Quickshell
import DisplayPower

ShellRoot {
    DisplayPowerObserver {
        id: observer
        enabled: true
        Component.onCompleted: console.log("DISPLAY_POWER_INITIAL", available, JSON.stringify(screens), error)
        onStateChanged: console.log("DISPLAY_POWER", available, JSON.stringify(screens), error)
    }
}
