import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.components

GridLayout {
    id: root
    columns: 2
    rowSpacing: 12
    columnSpacing: 12

    ControlTile {
        icon: WifiManager.isEnabled ? "󰖩" : "󰖪"
        active: !!WifiManager.isEnabled
        enabled: WifiManager.isAvailable
        onClicked: {
            SoundManager.playToggle()
            WifiManager.togglePower()
        }
        
        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: {
                SoundManager.playToggle()
                ViewManager.openControlPanel("wifi")
            }
        }
    }

    ControlTile {
        icon: BluetoothManager.isEnabled ? "󰂯" : "󰂲"
        active: !!BluetoothManager.isEnabled
        enabled: BluetoothManager.isAvailable
        onClicked: {
            SoundManager.playToggle()
            BluetoothManager.togglePower()
        }
        
        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: {
                SoundManager.playToggle()
                ViewManager.openControlPanel("bluetooth")
            }
        }
    }

    ControlTile {
        icon: "󰀝"
        active: !!WifiManager.isAirplaneModeEnabled
        enabled: WifiManager.isAvailable
        onClicked: {
            SoundManager.playToggle()
            WifiManager.toggleAirplaneMode()
        }
    }

    ControlTile {
        icon: NotificationManager.isDoNotDisturbEnabled ? "󰖔" : "󰂚"
        active: !!NotificationManager.isDoNotDisturbEnabled
        onClicked: {
            SoundManager.playToggle()
            NotificationManager.toggleDoNotDisturb()
        }
    }
}
