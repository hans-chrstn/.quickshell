import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core

Rectangle {
    id: root
    
    height: 32
    width: indicatorContentLayout.implicitWidth + 30
    radius: 16
    color: Qt.rgba(1, 1, 1, 0.1)
    
    border.color: ColorManager.accentColor || ThemeManager.accentColor
    border.width: 1
    visible: NotificationManager.historyModel.count > 0

    SequentialAnimation on opacity { 
        running: root.visible
        loops: Animation.Infinite
        NumberAnimation { 
            to: 0.6
            duration: 1500
            easing.type: Easing.InOutSine 
        }
        NumberAnimation { 
            to: 1.0
            duration: 1500
            easing.type: Easing.InOutSine 
        } 
    }

    RowLayout { 
        id: indicatorContentLayout
        anchors.centerIn: parent
        spacing: 8
        
        Text { 
            id: notificationIcon
            text: ThemeManager.iconNotification
            color: ColorManager.accentColor || ThemeManager.accentColor
            font.pixelSize: 14
            opacity: 0.8 
        }
        
        Text { 
            id: notificationCountLabel
            text: NotificationManager.historyModel.count + " UNREAD NOTIFICATIONS"
            color: ThemeManager.contentOnBackgroundColor
            font.pixelSize: 10
            font.weight: Font.Black
            font.letterSpacing: 1
        }
    }
}
