import QtQuick
import QtQuick.Layouts
import qs.services

RowLayout {
    id: root
    Layout.fillWidth: true
    spacing: 12
    
    property string pageType: "wifi"
    
    readonly property bool isEnabled: pageType === "wifi" ? WifiManager.isEnabled : BluetoothManager.isEnabled

    Text { 
        text: root.pageType.toUpperCase() + " POWER"
        color: ThemeManager.contentOnBackgroundColor; font.pixelSize: 11; font.weight: Font.Black; opacity: 0.6 
    }
    
    Item { Layout.fillWidth: true }

    Rectangle {
        width: 120; height: 40; radius: 20
        color: ThemeManager.surfaceVariantStrongColor
        visible: pageType === "bluetooth" && root.isEnabled
        
        Text {
            anchors.centerIn: parent
            text: BluetoothManager.isScanning ? "SCANNING..." : "SCAN FOR DEVICES"
            color: ThemeManager.contentOnBackgroundColor
            font.pixelSize: 9; font.weight: Font.Black
        }
        
        TapHandler {
            onTapped: BluetoothManager.startScan()
        }
        HoverHandler { cursorShape: Qt.PointingHandCursor }
    }
    
    Rectangle {
        width: 100; height: 40; radius: 20
        color: root.isEnabled ? ThemeManager.accentColor : ThemeManager.contentOnBackgroundColor
        opacity: root.isEnabled ? 1.0 : 0.1
        
        Text {
            anchors.centerIn: parent
            text: root.isEnabled ? "ENABLED" : "DISABLED"
            color: root.isEnabled ? ThemeManager.contentPrimaryColor : ThemeManager.contentOnBackgroundColor
            font.pixelSize: 9; font.weight: Font.Black
        }
        
        TapHandler {
            onTapped: {
                if (root.pageType === "wifi") WifiManager.togglePower()
                else BluetoothManager.togglePower()
            }
        }
        HoverHandler { id: hToggle; cursorShape: Qt.PointingHandCursor }
    }
}
