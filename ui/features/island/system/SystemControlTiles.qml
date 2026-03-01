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
        tileIcon: NetworkManager.statusIcon
        isTileActive: NetworkManager.activeState === "connected"
        enabled: NetworkManager.isAvailable
        
        onTileClicked: {
            SoundManager.playToggle()
            NetworkManager.togglePower()
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
        isTileActive: !!NetworkManager.isAirplaneModeEnabled
        enabled: NetworkManager.isAvailable
        
        onTileClicked: {
            SoundManager.playToggle()
            NetworkManager.toggleAirplaneMode()
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
