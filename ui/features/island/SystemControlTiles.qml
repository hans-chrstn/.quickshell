import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.ui.shared

GridLayout {
    id: root
    
    columns: 2
    rowSpacing: 12
    columnSpacing: 12

    InteractionTile {
        id: wifiInteractionTile
        tileIcon: WifiManager.isEnabled ? "󰖩" : "󰖪"
        isTileActive: !!WifiManager.isEnabled
        enabled: WifiManager.isAvailable
        
        onTileClicked: {
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

    InteractionTile {
        id: bluetoothInteractionTile
        tileIcon: BluetoothManager.isEnabled ? "󰂯" : "󰂲"
        isTileActive: !!BluetoothManager.isEnabled
        enabled: BluetoothManager.isAvailable
        
        onTileClicked: {
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

    InteractionTile {
        id: airplaneModeInteractionTile
        tileIcon: "󰀝"
        isTileActive: !!WifiManager.isAirplaneModeEnabled
        enabled: WifiManager.isAvailable
        
        onTileClicked: {
            SoundManager.playToggle()
            WifiManager.toggleAirplaneMode()
        }
    }

    InteractionTile {
        id: doNotDisturbInteractionTile
        tileIcon: NotificationManager.isDoNotDisturbEnabled ? "󰖔" : "󰂚"
        isTileActive: !!NotificationManager.isDoNotDisturbEnabled
        
        onTileClicked: {
            SoundManager.playToggle()
            NotificationManager.toggleDoNotDisturb()
        }
    }
}
