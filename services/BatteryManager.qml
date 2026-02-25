pragma Singleton
import QtQuick
import Quickshell
import qs.components
import qs.utilities

Singleton {
    id: root

    property bool isUPowerAvailable: false
    
    readonly property var mainDevice: providerLoader.item ? providerLoader.item.displayDevice : null

    DependencyChecker {
        dbusBusName: "org.freedesktop.UPower"
        onAvailabilityChecked: (available) => {
            root.isUPowerAvailable = available
            if (available) {
                providerLoader.source = "BatteryProvider.qml"
            }
        }
    }

    Loader {
        id: providerLoader
        active: root.isUPowerAvailable
    }
}
