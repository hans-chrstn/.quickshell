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
        
        Text { 
            text: "🔔"
            font.pixelSize: 30 
            Layout.alignment: Qt.AlignHCenter
        }
        Text { 
            text: "No Notifications"
            color: "#888"
            font.italic: true
            Layout.alignment: Qt.AlignHCenter
        }
    }

    Item {
        anchors.fill: parent
        visible: root.count > 0
        
        Text {
            id: notifHeader
            text: `Notifications (${notificationList.count})`
            color: "white"
            font.bold: true
            font.pixelSize: 10
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 0
        }

        ListView {
            id: notificationList
            anchors.top: notifHeader.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 0
            anchors.topMargin: 5
            
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            
            model: root.server ? root.server.trackedNotifications : null
            spacing: 5
            
            delegate: Rectangle {
                width: parent.width
                height: 50
                color: "#333"
                radius: 8
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 10
                    
                    Rectangle {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        color: "#444"
                        radius: 6
                        clip: true
                        Text { anchors.centerIn: parent; text: "🔔" }
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            text: modelData.summary || "Notification"
                            color: "white"
                            font.bold: true
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: modelData.body || ""
                            color: "#aaa"
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                    
                    Text {
                        text: "✕"
                        color: "#888"
                        font.pixelSize: 12
                        TapHandler { onTapped: modelData.dismiss() }
                    }
                }
            }
        }
    }
}
