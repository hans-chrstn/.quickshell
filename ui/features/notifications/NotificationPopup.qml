import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.ui.shared

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
    
    StackedListView {
        id: notifList
        anchors.top: parent.top
        anchors.right: parent.right 
        anchors.rightMargin: 20
        anchors.topMargin: 50 
        width: 400
        
        readonly property real targetHeight: isStackExpanded ? 750 : 120
        height: Math.min(contentHeight > 0 ? contentHeight : 0, targetHeight)
        
        onIsStackExpandedChanged: {
            if (notifList.isStackExpanded) NotificationManager.expandedNotificationCount++
            else NotificationManager.expandedNotificationCount--
        }
        
        model: NotificationManager.popupModel
        delegate: NotificationBanner {
            notification: model.notification
            width: ListView.view.width
            z: 1000 - model.index
            index: model.index
            count: notifList.count
            
            stackExpanded: notifList.isStackExpanded
            dismissing: model.dismissing 
            
            onRequestExpand: notifList.isStackExpanded = true 
            
            readonly property bool isVisibleInStack: notifList.isItemVisible(model.index)
            visible: true
            height: implicitHeight
            
            scale: notifList.isStackExpanded ? 1.0 : Math.max(0.8, (1.0 - (model.index * 0.05)))
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
            
            opacity: isVisibleInStack ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }
}
