import QtQuick
import Quickshell
import qs.core

QtObject {
    id: root

    property var view
    property var activePlayer: null

    property ListModel tabModel: ListModel {
        function updateModel() {
            clear()
            append({
                "type": "timeDate"
            })
            append({
                "type": "music"
            })
            append({
                "type": "notif"
            })

            if (BatteryManager.isUPowerAvailable && BatteryManager.mainDevice && BatteryManager.mainDevice.type !== 0) {
                append({
                    "type": "battery"
                })
            }

            if (ThemeManager.isWeatherVisible) {
                append({
                    "type": "weather"
                })
            }

            append({
                "type": "cc"
            })
            append({
                "type": "tray"
            })
        }
    }

    readonly property alias model: root.tabModel

    property var trayConnections: Connections {
        target: SystemTrayManager
        function onHoveredIndexChanged() {
            if (SystemTrayManager.hoveredIndex !== -1) {
                for (let i = 0; i < root.tabModel.count; i++) {
                    if (root.tabModel.get(i).type === "tray") {
                        if (view) {
                            view.currentIndex = i
                        }
                        break
                    }
                }
            }
        }
    }

    property var themeConnections: Connections {
        target: ThemeManager
        function onIsWeatherVisibleChanged() {
            root.tabModel.updateModel()
        }
    }

    property var batteryConnections: Connections {
        target: BatteryManager
        function onIsUPowerAvailableChanged() {
            root.tabModel.updateModel()
        }
    }

    Component.onCompleted: {
        root.tabModel.updateModel()
    }
}
