import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs.config

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
            color: FrameConfig.accentColor
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
        
        RowLayout {
            id: notifHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            anchors.topMargin: 8
            
            Text {
                text: "CENTER"
                color: "white"
                opacity: 0.3
                font.weight: Font.Black
                font.pixelSize: 10
                font.letterSpacing: 2
            }
            
            Item { Layout.fillWidth: true }
            
            Text {
                text: "CLEAR ALL"
                color: FrameConfig.accentColor
                font.weight: Font.Bold
                font.pixelSize: 9
                font.letterSpacing: 1
                opacity: clearMouse.containsMouse ? 1.0 : 0.6
                Behavior on opacity { NumberAnimation { duration: 200 } }
                
                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        let notifs = root.server.trackedNotifications.values;
                        for (let i = 0; i < notifs.length; i++) {
                            notifs[i].dismiss();
                        }
                    }
                }
            }
        }

        ListView {
            id: notificationList
            anchors.top: notifHeader.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 12
            anchors.topMargin: 4
            
            clip: true
            spacing: FrameConfig.notifSpacing
            
            model: root.server ? root.server.trackedNotifications : null
            
            delegate: Item {
                width: ListView.view.width
                height: FrameConfig.notifItemHeight
                
                Rectangle {
                    anchors.fill: parent
                    anchors.bottomMargin: 1
                    color: "white"
                    opacity: notifMouse.containsMouse ? FrameConfig.notifHoverOpacity : FrameConfig.notifOpacity
                    radius: 12
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12
                        
                        Rectangle {
                            Layout.preferredWidth: FrameConfig.notifIconSize
                            Layout.preferredHeight: FrameConfig.notifIconSize
                            color: FrameConfig.accentColor
                            opacity: 0.1
                            radius: width / 2
                            Text { 
                                anchors.centerIn: parent
                                text: "󰂚"
                                color: FrameConfig.accentColor
                                font.pixelSize: 14
                            }
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: -2
                            Text {
                                text: modelData.summary || "Notification"
                                color: "white"
                                font.weight: Font.DemiBold
                                font.pixelSize: 13
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: modelData.body || ""
                                color: "white"
                                opacity: 0.5
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                        
                        Text {
                            text: "󰅖"
                            color: "white"
                            opacity: closeMouse.containsMouse ? 1.0 : 0.2
                            font.pixelSize: 18
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                            
                            MouseArea {
                                id: closeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: modelData.dismiss()
                            }
                        }
                    }
                }
                
                MouseArea {
                    id: notifMouse
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }
        }
    }
}