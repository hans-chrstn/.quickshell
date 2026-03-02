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
                ViewManager.toggleNetwork()
            }
        }
    }

    InteractionTile {
        id: bluetoothInteractionTile
        tileIcon: BluetoothManager.isEnabled ? ThemeManager.iconBluetooth : ThemeManager.iconBluetoothOff
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
                ViewManager.toggleBluetooth()
            }
        }
    }

    InteractionTile {
        id: airplaneModeInteractionTile
        tileIcon: ThemeManager.iconAirplane
        isTileActive: !!NetworkManager.isAirplaneModeEnabled
        enabled: NetworkManager.isAvailable
        
        onTileClicked: {
            SoundManager.playToggle()
            NetworkManager.toggleAirplaneMode()
        }
    }

    InteractionTile {
        id: doNotDisturbInteractionTile
        tileIcon: NotificationManager.isDoNotDisturbEnabled ? ThemeManager.iconDND : ThemeManager.iconNotification
        isTileActive: !!NotificationManager.isDoNotDisturbEnabled
        
        onTileClicked: {
            SoundManager.playToggle()
            NotificationManager.toggleDoNotDisturb()
        }
    }
}
