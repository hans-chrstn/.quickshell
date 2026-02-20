import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs.config
import qs.components

Item {
    id: root
    
    property var server: null 
    property int count: server ? server.trackedNotifications.values.length : 0
    
    ColumnLayout {
        anchors.centerIn: parent
        visible: root.count === 0
        spacing: 12
        Text { text: "󰂚"; color: "white"; opacity: 0.05; font.pixelSize: 42; Layout.alignment: Qt.AlignHCenter }
        Text { text: "NO NOTIFICATIONS"; color: "white"; opacity: 0.2; font.pixelSize: 9; font.weight: Font.Black; font.letterSpacing: 2; Layout.alignment: Qt.AlignHCenter }
    }

    Item {
        anchors.fill: parent
        visible: root.count > 0
        
        RowLayout {
            id: notifHeader; anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 20; anchors.topMargin: 15
            Text { text: "NOTIFICATIONS"; color: "white"; opacity: 0.3; font.weight: Font.Black; font.pixelSize: 10; font.letterSpacing: 2 }
            Item { Layout.fillWidth: true }
            Text { text: "CLEAR ALL"; color: FrameConfig.accentColor; font.weight: Font.Bold; font.pixelSize: 9; opacity: 0.6; TapHandler { onTapped: { let notifs = root.server.trackedNotifications.values; for (let i = 0; i < notifs.length; i++) notifs[i].dismiss(); } } }
        }

        ListView {
            id: notificationList; anchors.top: notifHeader.bottom; anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 15; anchors.topMargin: 10
            clip: true; spacing: 8; model: root.server ? root.server.trackedNotifications : null
            
            delegate: Item {
                id: notifDelegate
                width: ListView.view.width
                height: expanded ? (mainLayout.implicitHeight + 24) : 54
                property bool expanded: false
                
                Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }

                Rectangle {
                    anchors.fill: parent; radius: 16; color: "white"
                    opacity: notifDelegate.expanded ? 0.08 : 0.05
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                RowLayout {
                    id: mainLayout
                    anchors.fill: parent; anchors.margins: 12; spacing: 12
                    
                    Item {
                        Layout.preferredWidth: 8; Layout.preferredHeight: 8
                        Layout.alignment: Qt.AlignTop
                        Layout.topMargin: 4
                        Rectangle { 
                            anchors.centerIn: parent
                            width: 8; height: 8; radius: 4; color: FrameConfig.accentColor; opacity: 0.8
                        }
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        Layout.alignment: Qt.AlignTop
                        Text { 
                            text: modelData.summary || "Notification"
                            color: "white"; font.weight: Font.DemiBold; font.pixelSize: 13
                            elide: notifDelegate.expanded ? Text.ElideNone : Text.ElideRight
                            wrapMode: notifDelegate.expanded ? Text.Wrap : Text.NoWrap
                            Layout.fillWidth: true 
                        }
                        Text { 
                            text: modelData.body || ""
                            color: "white"; opacity: 0.6; font.pixelSize: 11
                            elide: notifDelegate.expanded ? Text.ElideNone : Text.ElideRight
                            wrapMode: notifDelegate.expanded ? Text.Wrap : Text.NoWrap
                            visible: text !== ""
                            Layout.fillWidth: true 
                        }
                    }
                    
                    Item {
                        Layout.preferredWidth: 24; Layout.preferredHeight: 24
                        Layout.alignment: Qt.AlignTop
                        Text { 
                            anchors.centerIn: parent
                            text: "󰅖"; color: "white"; opacity: 0.3; font.pixelSize: 16
                        }
                        TapHandler { onTapped: modelData.dismiss() }
                    }
                }

                TapHandler {
                    onTapped: notifDelegate.expanded = !notifDelegate.expanded
                }
            }
        }
    }
}
