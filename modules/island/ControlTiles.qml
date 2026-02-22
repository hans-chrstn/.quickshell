import QtQuick
import QtQuick.Layouts
import QtMultimedia
import Quickshell
import qs.config
import qs.components
import qs.services

GridLayout {
    id: root
    columns: 2
    rowSpacing: 12
    columnSpacing: 12
    
    property var controlPanelWin: null

    ExpandableControlTile { 
        icon: "󰖩"; label: "Wifi"
        active: !!WifiService.wifiEnabled
        enabled: WifiService.hasWifi
        onClicked: {
            WifiService.toggleWifi()
            SfxService.playButton2()
        }
        onLongPressed: {
            if (root.controlPanelWin) {
                root.controlPanelWin.activePage = "wifi"
                root.controlPanelWin.visible = true
            }
        }
    }
    
    ExpandableControlTile { 
        icon: "󰂯"; label: "Bluetooth"
        active: !!BluetoothService.bluetoothEnabled
        enabled: BluetoothService.hasBluetooth
        onClicked: {
            BluetoothService.toggleBluetooth()
            SfxService.playButton2()
        }
        onLongPressed: {
            if (root.controlPanelWin) {
                root.controlPanelWin.activePage = "bluetooth"
                root.controlPanelWin.visible = true
            }
        }
    }
    
    ControlTile { 
        icon: "󰀝"; active: !!WifiService.airplaneMode
        enabled: WifiService.hasWifi
        onClicked: {
            WifiService.toggleAirplane()
            SfxService.playButton2()
        }
    }
    
    ControlTile { 
        icon: NotificationService.dndEnabled ? "󰖔" : "󰂚"
        active: !!NotificationService.dndEnabled
        enabled: true
        onClicked: {
            NotificationService.toggleDND()
            SfxService.playButton2()
        }
    }
}

