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
            text: "🔔"
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
                id: notifDelegate
                width: ListView.view.width
                height: expanded ? (mainLayout.implicitHeight + 24) : FrameConfig.notifItemHeight
                
                property bool expanded: false
                Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }

                Rectangle {
                    anchors.fill: parent
                    anchors.bottomMargin: 4
                    color: "white"
                    radius: 12
                    opacity: (notifMouse.containsMouse || expanded) ? 0.12 : 0.06
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                RowLayout {
                    id: mainLayout
                    width: parent.width
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 12
                    spacing: 12
                    
                    Rectangle {
                        Layout.preferredWidth: FrameConfig.notifIconSize
                        Layout.preferredHeight: FrameConfig.notifIconSize
                        color: FrameConfig.accentColor
                        opacity: 0.15
                        radius: width / 2
                        Layout.alignment: Qt.AlignTop
                        
                        Text { 
                            anchors.centerIn: parent
                            text: "🔔"
                            color: "white"
                            font.pixelSize: 14
                        }
                    }
                    
                    ColumnLayout {
                        id: textColumn
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: 2
                        opacity: (notifMouse.containsMouse || expanded) ? 1.0 : 0.85
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        
                        Text {
                            text: modelData.summary || "Notification"
                            color: "white"
                            font.weight: Font.DemiBold
                            font.pixelSize: 13
                            elide: Text.ElideRight
                            wrapMode: expanded ? Text.Wrap : Text.NoWrap
                            maximumLineCount: expanded ? 10 : 1
                            Layout.fillWidth: true
                        }
                        Text {
                            text: modelData.body || ""
                            color: "white"
                            opacity: 0.7
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            wrapMode: expanded ? Text.Wrap : Text.NoWrap
                            maximumLineCount: expanded ? 20 : 1
                            Layout.fillWidth: true
                            visible: text !== ""
                        }
                    }
                    
                    Text {
                        text: "✕"
                        color: "white"
                        opacity: closeMouse.containsMouse ? 1.0 : 0.3
                        font.pixelSize: 18
                        Layout.alignment: Qt.AlignTop
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                }
                
                MouseArea {
                    id: notifMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: notifDelegate.expanded = !notifDelegate.expanded
                }

                MouseArea {
                    id: closeMouse
                    width: 32; height: 32
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 4
                    z: 100
                    hoverEnabled: true
                    onClicked: modelData.dismiss()
                }
            }
            
            
        }
    }
}
