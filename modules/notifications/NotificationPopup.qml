import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

PanelWindow {
    id: root
    
    anchors.top: true
    anchors.right: true
    
    property var modelData
    screen: modelData
    
    Connections {
        target: NotificationManager
        function onActiveScreenNameChanged() { updateVisibility() }
        function onPopupsUpdated() { updateVisibility() }
    }

    function updateVisibility() {
        root.visible = (screen && screen.name === NotificationManager.activeScreenName && NotificationManager.popupModel.count > 0)
    }

    Component.onCompleted: updateVisibility()

    implicitWidth: 450
    implicitHeight: 800
    color: "transparent"
    
    exclusionMode: ExclusionMode.Ignore
    
    mask: Region {
        item: notifList
    }
    
    CardStackView {
        id: notifList
        anchors.top: parent.top
        anchors.right: parent.right 
        anchors.rightMargin: 20
        anchors.topMargin: 50 
        width: 400
        
        height: notifList.stackExpanded ? Math.max(150, Math.min(contentHeight, 750)) : Math.max(80, Math.min(contentHeight, 120))
        
        onStackExpandedChanged: {
            if (notifList.stackExpanded) NotificationManager.expandedNotificationCount++
            else NotificationManager.expandedNotificationCount--
        }
        
        model: NotificationManager.popupModel
        delegate: NotificationBanner {
            notification: model.notification
            width: ListView.view.width
            z: 1000 - model.index
            index: model.index
            count: notifList.count
            
            stackExpanded: notifList.stackExpanded
            dismissing: model.dismissing 
            
            onRequestExpand: notifList.stackExpanded = true 
            
            readonly property bool isVisibleInStack: notifList.isItemVisible(model.index)
            visible: true
            height: implicitHeight
            
            scale: notifList.stackExpanded ? 1.0 : Math.max(0.8, (1.0 - (model.index * 0.05)))
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
            
            opacity: isVisibleInStack ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }
}
