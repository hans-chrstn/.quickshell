pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool isDoNotDisturbEnabled: false
    
    readonly property alias activeNotifications: server.trackedNotifications
    readonly property alias popupModel: popupListModel
    readonly property alias historyModel: historyListModel
    
    property int expandedNotificationCount: 0
    property real interactionDragPosition: 0
        
    signal popupsUpdated()
    
    ListModel { id: popupListModel }
    ListModel { id: historyListModel }
    
    function toggleDoNotDisturb() {
        root.isDoNotDisturbEnabled = !root.isDoNotDisturbEnabled
    }
    
    function dismissPopup(notification) {
        for (let i = 0; i < popupListModel.count; i++) {
            if (popupListModel.get(i).notification === notification) {
                popupListModel.remove(i)
                root.popupsUpdated()
                break
            }
        }
    }
    
    function clearHistoryItem(index) {
        if (index >= 0 && index < historyListModel.count) {
            historyListModel.remove(index)
        }
    }
    
    NotificationServer {
        id: server
        bodySupported: true
        keepOnReload: true
        
        onNotification: (notification) => {
            notification.tracked = true
            
            historyListModel.insert(0, {
                "summary": notification.summary,
                "body": notification.body,
                "appName": notification.appName,
                "icon": notification.icon || "",
                "id": notification.id,
                "notification": notification
            })
            
            if (!root.isDoNotDisturbEnabled) {
                popupListModel.insert(0, { "notification": notification, "dismissing": false })
                root.popupsUpdated()
            }
        }
    }
    
    Timer {
        id: dismissAnimationTimer
        interval: 50
        repeat: true
        onTriggered: {
            if (popupListModel.count > 0) {
                let foundAny = false
                for (let i = popupListModel.count - 1; i >= 0; i--) {
                    if (!popupListModel.get(i).dismissing) {
                        popupListModel.setProperty(i, "dismissing", true)
                        foundAny = true
                        break
                    }
                }
                if (!foundAny) stop()
            } else {
                root.popupsUpdated()
                stop()
            }
        }
    }
    
    function clearAllNotifications() {
        historyListModel.clear()
        if (server.trackedNotifications && server.trackedNotifications.values) {
             server.trackedNotifications.values.forEach(notification => notification.dismiss())
        }
        
        dismissAnimationTimer.start()
        root.popupsUpdated()
    }
}
