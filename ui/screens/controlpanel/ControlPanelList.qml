import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.ui.shared

ListView {
    id: root
    
    property string activePage: "wifi"
    
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    spacing: 10
    model: root.activePage === "wifi" ? NetworkManager.networkModel : BluetoothManager.deviceModel
    
    topMargin: 10
    bottomMargin: 10
    leftMargin: 12
    rightMargin: 12

    delegate: NetworkItemDelegate {
        panelType: root.activePage
    }
}
