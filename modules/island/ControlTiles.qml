import QtQuick
import QtQuick.Layouts
import QtMultimedia
import Quickshell
import qs.services
import qs.components

GridLayout {
    id: root
    columns: 2
    rowSpacing: 12
    columnSpacing: 12

    ControlTile {
        icon: WifiService.wifiEnabled ? "󰖩" : "󰖪"
        active: !!WifiService.wifiEnabled
        enabled: WifiService.hasWifi
        onClicked: {
            SfxService.playButton2()
            WifiService.toggleWifi()
        }
        
        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: {
                SfxService.playButton2()
                ViewService.openControlPanel("wifi")
            }
        }
    }

    ControlTile {
        icon: BluetoothService.bluetoothEnabled ? "󰂯" : "󰂲"
        active: !!BluetoothService.bluetoothEnabled
        enabled: BluetoothService.hasBluetooth
        onClicked: {
            SfxService.playButton2()
            BluetoothService.toggleBluetooth()
        }
        
        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: {
                SfxService.playButton2()
                ViewService.openControlPanel("bluetooth")
            }
        }
    }

    ControlTile {
        icon: "󰀝"
        active: !!WifiService.airplaneMode
        enabled: WifiService.hasWifi
        onClicked: {
            SfxService.playButton2()
            WifiService.toggleAirplane()
        }
    }

    ControlTile {
        icon: NotificationService.dndEnabled ? "󰖔" : "󰂚"
        active: !!NotificationService.dndEnabled
        onClicked: {
            SfxService.playButton2()
            NotificationService.toggleDND()
        }
    }
}
