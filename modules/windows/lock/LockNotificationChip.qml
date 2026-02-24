import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services

Rectangle {
    id: root
    height: 32; width: notifContent.implicitWidth + 30
    radius: 16
    color: Qt.rgba(1, 1, 1, 0.1)
    
    border.color: ColorService.accent || ThemeService.accentColor
    border.width: 1
    visible: NotificationService.history.count > 0

    SequentialAnimation on opacity { 
        running: root.visible; loops: Animation.Infinite
        NumberAnimation { to: 0.6; duration: 1500; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1.0; duration: 1500; easing.type: Easing.InOutSine } 
    }

    RowLayout { 
        id: notifContent
        anchors.centerIn: parent
        spacing: 8
        Text { 
            text: "󰂚"
            color: ColorService.accent || ThemeService.accentColor
            font.pixelSize: 14
            opacity: 0.8 
        }
        Text { 
            text: NotificationService.history.count + " UNREAD NOTIFICATIONS"
            color: "white"
            font.pixelSize: 10
            font.weight: Font.Black
            font.letterSpacing: 1
        }
    }
}
