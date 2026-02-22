import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Notifications
import qs.components
import qs.services

Item {
    id: root
    anchors.fill: parent

    ListView {
        id: notifList
        anchors.fill: parent
        anchors.margins: 10
        model: NotificationService.history
        spacing: ThemeService.notifSpacing
        clip: true
        
        delegate: Item {
            width: notifList.width
            height: ThemeService.notifItemHeight
            
            Rectangle {
                id: bgRect
                anchors.fill: parent
                radius: 12
                color: ThemeService.surfaceVariant
                border.color: ThemeService.outlineMain
                border.width: 1
                
                opacity: hh.hovered ? ThemeService.notifHoverOpacity * 10 : ThemeService.notifOpacity * 10
                Behavior on opacity { NumberAnimation { duration: 200 } }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12
                    
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 8
                        color: ThemeService.primaryAccent
                        opacity: 0.1
                        
                        Text {
                            anchors.centerIn: parent
                            text: model.icon ? "" : "󰂚"
                            color: ThemeService.primaryAccent
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
                        Text {
                            text: model.summary || "Notification"
                            color: ThemeService.backgroundContent
                            font.weight: Font.Bold
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: model.body || ""
                            color: ThemeService.backgroundContent
                            opacity: 0.6
                            font.pixelSize: 10
                            elide: Text.ElideRight
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
                            color: ThemeService.backgroundContent
                            opacity: hhDel.hovered ? 1.0 : 0.3
                            font.pixelSize: 14
                        }
                        TapHandler { onTapped: NotificationService.removeHistory(index) }
                        HoverHandler { id: hhDel; cursorShape: Qt.PointingHandCursor }
                    }
                }
            }
            
            HoverHandler { id: hh }
        }
        
        Text {
            anchors.centerIn: parent
            text: "NO NOTIFICATIONS"
            color: ThemeService.backgroundContent
            opacity: 0.2
            font.pixelSize: 10
            font.weight: Font.Black
            font.letterSpacing: 2
            visible: notifList.count === 0
        }

        footer: Item {
            width: notifList.width
            height: 50
            visible: notifList.count > 0
            
            Rectangle {
                anchors.centerIn: parent
                width: 120; height: 30; radius: 15
                color: ThemeService.surfaceVariantStrong
                border.color: ThemeService.outlineMain
                border.width: 1
                
                Text {
                    anchors.centerIn: parent
                    text: "CLEAR ALL history"
                    color: ThemeService.backgroundContent
                    font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 1
                    opacity: hhClear.hovered ? 1.0 : 0.6
                }
                
                TapHandler { 
                    onTapped: {
                        NotificationService.history.clear()
                        SfxService.playComplete()
                    }
                }
                HoverHandler { id: hhClear; cursorShape: Qt.PointingHandCursor }
            }
        }
    }
}
