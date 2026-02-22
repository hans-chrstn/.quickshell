import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs.config
import qs.components
import qs.services

Item {
    id: root
    
    property int count: NotificationService.history.count
    
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
            Text { 
                text: "CLEAR ALL"
                color: FrameConfig.accentColor
                font.weight: Font.Bold
                font.pixelSize: 9
                opacity: hhClear.hovered ? 1.0 : 0.6
                Behavior on opacity { NumberAnimation { duration: 200 } }
                
                TapHandler { 
                    onTapped: {
                        NotificationService.dismissAll()
                    } 
                }
                HoverHandler { id: hhClear; cursorShape: Qt.PointingHandCursor }
            }
        }

        CardStackView {
            id: notificationList; anchors.top: notifHeader.bottom; anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 15; anchors.topMargin: 10
            expandedSpacing: FrameConfig.notifSpacing
            model: NotificationService.history
            
            delegate: Item {
                id: notifDelegate
                width: ListView.view.width
                
                readonly property bool isVisibleInStack: notificationList.isItemVisible(index)
                visible: true
                
                height: FrameConfig.notifItemHeight
                
                property bool expanded: false
                
                states: State {
                    name: "expanded"
                    when: notifDelegate.expanded
                    PropertyChanges { target: notifDelegate; height: (mainLayout.implicitHeight + 24) }
                }
                
                transitions: Transition {
                    NumberAnimation { property: "height"; duration: 200; easing.type: Easing.OutQuart }
                }
                
                z: 1000 - index
                
                opacity: isVisibleInStack ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                
                readonly property real stackScale: notificationList.stackExpanded ? 1.0 : Math.max(0.8, (1.0 - (index * 0.05)))
                scale: (thNotif.pressed ? 0.98 : (hhNotif.hovered ? 1.02 : 1.0)) * stackScale
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                
                Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }

                Rectangle {
                    id: bgRect
                    anchors.fill: parent; radius: 16
                    color: Qt.rgba(0.1, 0.1, 0.12, 0.8)
                    border.color: Qt.rgba(1, 1, 1, 0.1)
                    border.width: 1
                    
                    opacity: 1.0
                    
                    states: State {
                        when: notifDelegate.expanded || hhNotif.hovered
                        PropertyChanges { target: bgRect; color: Qt.rgba(0.15, 0.15, 0.18, 0.9) }
                    }
                    transitions: Transition { ColorAnimation { duration: 200 } }
                }

                RowLayout {
                    id: mainLayout
                    anchors.fill: parent; anchors.margins: 12; spacing: 12
                    
                    opacity: (index === 0 || notificationList.stackExpanded) ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    
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
                            text: model.summary || "Notification"
                            color: "white"; font.weight: Font.DemiBold; font.pixelSize: 13
                            elide: notifDelegate.expanded ? Text.ElideNone : Text.ElideRight
                            wrapMode: notifDelegate.expanded ? Text.Wrap : Text.NoWrap
                            Layout.fillWidth: true 
                        }
                        Text { 
                            text: model.body || ""
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
                            text: "󰅖"; color: "white"; opacity: hhDismiss.hovered ? 0.8 : 0.3; font.pixelSize: 16
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }
                        TapHandler { onTapped: NotificationService.removeHistory(index) }
                        HoverHandler { id: hhDismiss; cursorShape: Qt.PointingHandCursor }
                    }
                }

                TapHandler {
                    id: thNotif
                    onTapped: notifDelegate.expanded = !notifDelegate.expanded
                }
                HoverHandler { id: hhNotif }
            }
        }
    }
}
