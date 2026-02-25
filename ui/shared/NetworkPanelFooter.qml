import QtQuick
import QtQuick.Layouts
import qs.core

RowLayout {
    id: root
    
    Layout.fillWidth: true
    spacing: 12
    
    property string panelType: "wifi"
    
    readonly property bool isComponentEnabled: panelType === "wifi" ? WifiManager.isEnabled : BluetoothManager.isEnabled

    Text { 
        text: root.panelType.toUpperCase() + " POWER"
        color: ThemeManager.contentOnBackgroundColor
        font.pixelSize: 11
        font.weight: Font.Black
        opacity: 0.6 
    }
    
    Item { Layout.fillWidth: true }

    Rectangle {
        width: 120
        height: 40
        radius: 20
        color: ThemeManager.surfaceVariantStrongColor
        visible: panelType === "bluetooth" && root.isComponentEnabled
        
        Text {
            anchors.centerIn: parent
            text: BluetoothManager.isScanning ? "SCANNING..." : "SCAN FOR DEVICES"
            color: ThemeManager.contentOnBackgroundColor
            font.pixelSize: 9
            font.weight: Font.Black
        }
        
        TapHandler {
            onTapped: BluetoothManager.startScan()
        }
        HoverHandler { cursorShape: Qt.PointingHandCursor }
    }
    
    Rectangle {
        id: toggleButton
        width: 100
        height: 40
        radius: 20
        color: root.isComponentEnabled ? ThemeManager.accentColor : ThemeManager.contentOnBackgroundColor
        opacity: root.isComponentEnabled ? 1.0 : 0.1
        
        Text {
            anchors.centerIn: parent
            text: root.isComponentEnabled ? "ENABLED" : "DISABLED"
            color: root.isComponentEnabled ? ThemeManager.contentPrimaryColor : ThemeManager.contentOnBackgroundColor
            font.pixelSize: 9
            font.weight: Font.Black
        }
        
        TapHandler {
            onTapped: {
                if (root.panelType === "wifi") {
                    WifiManager.togglePower()
                } else {
                    BluetoothManager.togglePower()
                }
            }
        }
        HoverHandler { 
            id: toggleHoverHandler
            cursorShape: Qt.PointingHandCursor 
        }
    }
}
