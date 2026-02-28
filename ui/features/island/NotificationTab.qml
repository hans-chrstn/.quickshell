import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import Quickshell
import Quickshell.Services.Notifications
import qs.core
import qs.ui.shared

Item {
    id: root
    anchors.fill: parent

    ListView {
        id: notifList
        anchors.fill: parent
        anchors.margins: 10
        model: NotificationManager.historyModel
        spacing: ThemeManager.notificationSpacing
        clip: true
        
        delegate: Item {
            width: notifList.width
            height: ThemeManager.notificationItemHeight
            
            Rectangle {
                id: bgRect
                anchors.fill: parent
                radius: 12
                color: ThemeManager.surfaceVariantColor
                border.color: ThemeManager.outlinePrimaryColor
                border.width: 1
                
                opacity: hh.hovered ? ThemeManager.notificationHoverOpacity * 10 : ThemeManager.notificationOpacity * 10
                scale: hh.hovered ? 1.02 : 1.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12
                    
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 8
                        color: ThemeManager.primaryColor
                        opacity: 0.1
                        
                        Text {
                            anchors.centerIn: parent
                            text: model.icon ? "" : "󰂚"
                            color: ThemeManager.primaryColor
                            font.pixelSize: 18
                        }
                        
                        Image {
                            anchors.fill: parent
                            anchors.margins: 4
                            source: model.icon ? (model.icon.startsWith("/") ? "file://" + model.icon : Quickshell.iconPath(model.icon)) : ""
                            fillMode: Image.PreserveAspectFit
                            visible: model.icon !== ""
                        }
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        StyledLabel {
                            type: "label"
                            text: model.summary || "Notification"
                            font.weight: Font.Bold
                            elideMode: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        StyledLabel {
                            type: "caption"
                            text: model.body || ""
                            opacity: 0.6
                            elideMode: Text.ElideRight
                            Layout.fillWidth: true
                            visible: text !== ""
                        }
                    }
                    
                    Item {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            color: ThemeManager.contentOnBackgroundColor
                            opacity: hhDel.hovered ? 1.0 : 0.3
                            font.pixelSize: 14
                        }
                        TapHandler { onTapped: NotificationManager.clearHistoryItem(index) }
                        HoverHandler { id: hhDel; cursorShape: Qt.PointingHandCursor }
                    }
                }
            }
            
            HoverHandler { id: hh }
        }
        
        StyledLabel {
            anchors.centerIn: parent
            type: "caption"
            text: "NO NOTIFICATIONS"
            opacity: 0.2
            font.weight: Font.Black
            letterSpacing: 2
            visible: notifList.count === 0
        }

        footer: Item {
            width: notifList.width
            height: 50
            visible: notifList.count > 0
            
            Rectangle {
                anchors.centerIn: parent
                width: 120; height: 30; radius: 15
                color: ThemeManager.surfaceVariantStrongColor
                border.color: ThemeManager.outlinePrimaryColor
                border.width: 1
                
                StyledLabel {
                    anchors.centerIn: parent
                    type: "caption"
                    text: "CLEAR HISTORY"
                    font.weight: Font.Bold
                    letterSpacing: 1
                    opacity: hhClear.hovered ? 1.0 : 0.6
                }
                
                TapHandler { 
                    onTapped: {
                        NotificationManager.historyModel.clear()
                        SoundManager.playSuccess()
                    }
                }
                HoverHandler { id: hhClear; cursorShape: Qt.PointingHandCursor }
            }
        }
    }
}
