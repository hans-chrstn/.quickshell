pragma Singleton
import QtQuick
import Quickshell
import qs.components

Singleton {
    id: root

    property bool hasUPower: false
    
    readonly property var device: providerLoader.item ? providerLoader.item.displayDevice : null

    AvailabilityCheck {
        dbusService: "org.freedesktop.UPower"
        onChecked: (exists) => {
            root.hasUPower = exists
            if (exists) {
                providerLoader.source = "UPowerBatteryProvider.qml"
            }
        }
    }

    Loader {
        id: providerLoader
        active: root.hasUPower
    }
}
