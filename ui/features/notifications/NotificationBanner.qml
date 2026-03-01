import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtMultimedia
import Quickshell
import Quickshell.Widgets
import qs.ui.shared
import qs.core
import qs.ui.features.notifications.banner

Item {
    id: root
    
    property var notification: null
    property bool stackExpanded: false
    property int index: 0
    property int count: 0
    property bool removeHistory: false 
    property bool dismissing: false
    
    SoundEffect {
        id: dismissSound
        source: Quickshell.shellPath("assets/audio/button1.wav")
        volume: 0.4
    }
    
    signal requestExpand()
    
    onDismissingChanged: {
        if (dismissing) {
            root.dismiss()
        }
    }
    
    Layout.fillWidth: true
    implicitHeight: 80
    
    opacity: 1.0
    scale: 1.0
    
    NotificationBannerDragLogic {
        id: dragLogic
        banner: root
        dragProxy: dragProxy
        trans: trans
        stackExpanded: root.stackExpanded
        index: root.index
        count: root.count
    }

    Item {
        id: contentItem
        anchors.fill: parent
        opacity: 0
        scale: 0.9
        
        transform: [
            Translate { 
                id: trans
                x: 100 
            },
            Translate { 
                x: !root.stackExpanded ? NotificationManager.interactionDragPosition : dragProxy.x 
            }
        ]
        
        Item {
            id: dragProxy
            onXChanged: {
                dragLogic.handleXChanged()
            }

            Behavior on x { 
                enabled: !dragArea.drag.active
                NumberAnimation { 
                    duration: 200
                    easing.type: Easing.OutQuad 
                }
            }
        }
        
        Binding on opacity {
            when: dragArea.drag.active || (!root.stackExpanded && NotificationManager.interactionDragPosition !== 0)
            value: 1.0 - Math.min(1.0, Math.abs(!root.stackExpanded ? NotificationManager.interactionDragPosition : dragProxy.x) / 300)
        }
        
        MouseArea {
            id: dragArea
            anchors.fill: parent
            drag.target: dragProxy
            drag.axis: Drag.XAxis
            drag.minimumX: 0
            drag.maximumX: 400
            
            onClicked: {
                if (!root.stackExpanded && root.count > 1) {
                    root.requestExpand()
                }
            }
            
            onReleased: {
                dragLogic.handleReleased()
            }
        }
        
        NotificationBannerContent {
            notification: root.notification
            onCloseClicked: {
                root.removeHistory = true
                root.dismiss()
            }
        }
    }
    
    Component.onCompleted: {
        showAnim.start()
    }
    
    ParallelAnimation {
        id: showAnim
        NumberAnimation { 
            target: contentItem
            property: "opacity"
            to: 1.0
            duration: 400
            easing.type: Easing.OutExpo 
        }
        NumberAnimation { 
            target: contentItem
            property: "scale"
            to: 1.0
            duration: 500
            easing.type: Easing.OutBack 
        }
        NumberAnimation { 
            target: trans
            property: "x"
            to: 0
            duration: 400
            easing.type: Easing.OutExpo 
        }
    }

    Timer {
        interval: 5000
        running: NotificationManager.expandedNotificationCount === 0
        onTriggered: {
            root.removeHistory = false
            root.dismiss()
        }
    }

    function dismiss() {
        SoundManager.playClick()
        hideAnim.start()
    }

    ParallelAnimation {
        id: hideAnim
        NumberAnimation { 
            target: contentItem
            property: "opacity"
            to: 0.0
            duration: 300
            easing.type: Easing.InExpo 
        }
        NumberAnimation { 
            target: trans
            property: "x"
            to: 400
            duration: 300
            easing.type: Easing.InExpo 
        }
        onFinished: {
            if (root.removeHistory && root.notification) {
                root.notification.dismiss()
            }
            NotificationManager.dismissPopup(root.notification)
        }
    }
}
