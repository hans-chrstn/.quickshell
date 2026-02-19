import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications

Item {
    id: root
    
    property var server: null 
    property int count: server ? server.trackedNotifications.values.length : 0
    
    ColumnLayout {
        anchors.centerIn: parent
        visible: root.count === 0
        spacing: 0
        
        Text { 
            text: "󰂚"
            color: "white"
            opacity: 0.2
            font.pixelSize: 40 
            Layout.alignment: Qt.AlignHCenter
        }
        Text { 
            text: "NO NOTIFICATIONS"
            color: "white"
            opacity: 0.3
            font.pixelSize: 9
            font.weight: Font.Bold
            font.letterSpacing: 1.5
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 4
        }
    }

    Item {
        anchors.fill: parent
        visible: root.count > 0
        
        Text {
            id: notifHeader
            text: `NOTIFICATIONS (${notificationList.count})`
            color: "white"
            opacity: 0.5
            font.weight: Font.Bold
            font.pixelSize: 9
            font.letterSpacing: 1
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 4
        }

        ListView {
            id: notificationList
            anchors.top: notifHeader.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 10
            anchors.topMargin: 8
            
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            
            model: root.server ? root.server.trackedNotifications : null
            spacing: 8
            
            delegate: Rectangle {
                width: parent.width
                height: 54
                color: "white"
                opacity: 0.05
                radius: 10
                
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: "white"
                    border.width: 1
                    opacity: 0.1
                    radius: 10
                }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 12
                    
                    Rectangle {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        color: "white"
                        opacity: 0.1
                        radius: 8
                        clip: true
                        Text { anchors.centerIn: parent; text: "󰂚"; color: "white"; font.pixelSize: 14 }
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            text: modelData.summary || "Notification"
                            color: "white"
                            font.weight: Font.DemiBold
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: modelData.body || ""
                            color: "white"
                            opacity: 0.6
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                    
                    Text {
                        text: "󰅖"
                        color: "white"
                        opacity: 0.4
                        font.pixelSize: 16
                        TapHandler { onTapped: modelData.dismiss() }
                    }
                }
            }
        }
    }
}
