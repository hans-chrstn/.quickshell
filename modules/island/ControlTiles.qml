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
    
    SoundEffect {
        id: toggleSound
        source: Quickshell.shellPath("assets/sfx/button2.wav")
        volume: 0.4
    }

    ExpandableControlTile { 
        icon: "󰖩"; label: "Wifi"
        active: !!WifiService.wifiEnabled
        enabled: WifiService.hasWifi
        onClicked: {
            WifiService.toggleWifi()
            SfxService.playButton2()
        }
        onLongPressed: {
            ViewService.openControlPanel("wifi")
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
            ViewService.openControlPanel("bluetooth")
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

