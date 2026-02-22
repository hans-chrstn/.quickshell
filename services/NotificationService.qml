pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool dndEnabled: false
    
    readonly property alias trackedNotifications: server.trackedNotifications
    readonly property alias popups: popupModel
    readonly property alias history: historyModel
    
    property int expandedCount: 0
    property real globalDragX: 0
    property string activeScreenName: ""
        
    signal popupsUpdated()
    
    ListModel { id: popupModel }
    ListModel { id: historyModel }
    
    function toggleDND() {
        root.dndEnabled = !root.dndEnabled
    }
    
    function removePopup(notification) {
        for (let i = 0; i < popupModel.count; i++) {
            if (popupModel.get(i).notification === notification) {
                popupModel.remove(i)
                root.popupsUpdated()
                break
            }
        }
    }
    
    function removeHistory(index) {
        if (index >= 0 && index < historyModel.count) {
            historyModel.remove(index)
        }
    }
    
    NotificationServer {
        id: server
        bodySupported: true
        keepOnReload: true
        
        onNotification: (n) => {
            n.tracked = true
            
            historyModel.insert(0, {
                "summary": n.summary,
                "body": n.body,
                "appName": n.appName,
                "icon": n.icon || "",
                "id": n.id,
                "notification": n
            })
            
            if (!root.dndEnabled) {
                popupModel.insert(0, { "notification": n, "dismissing": false })
                root.popupsUpdated()
            }
        }
    }
    
    Timer {
        id: dismissTimer
        interval: 50
        repeat: true
        onTriggered: {
            if (popupModel.count > 0) {
                let found = false
                for (let i = popupModel.count - 1; i >= 0; i--) {
                    if (!popupModel.get(i).dismissing) {
                        popupModel.setProperty(i, "dismissing", true)
                        found = true
                        break
                    }
                }
                if (!found) stop()
            } else {
                root.popupsUpdated()
                stop()
            }
        }
    }
    
    function dismissAll() {
        historyModel.clear()
        if (server.trackedNotifications && server.trackedNotifications.values) {
             server.trackedNotifications.values.forEach(n => n.dismiss())
        }
        
        dismissTimer.start()
        root.popupsUpdated()
    }

    Component.onCompleted: {
        if (Quickshell.screens.length > 0) {
            root.activeScreenName = Quickshell.screens[0].name
        }
    }
}
