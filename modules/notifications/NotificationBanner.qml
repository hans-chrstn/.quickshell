import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtMultimedia
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.services

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
        source: Quickshell.shellPath("assets/sfx/button1.wav")
        volume: 0.4
    }
    
    signal requestExpand()
    
    onDismissingChanged: if (dismissing) root.dismiss()
    
    Layout.fillWidth: true
    implicitHeight: 80
    
    opacity: 1.0
    scale: 1.0
    
    Item {
        id: contentItem
        anchors.fill: parent
        opacity: 0
        scale: 0.9
        
        transform: [
            Translate { id: trans; x: 100 },
            Translate { 
                x: !root.stackExpanded ? NotificationService.globalDragX : dragProxy.x 
            }
        ]
        
        Item {
            id: dragProxy
            
            onXChanged: {
                if (dragArea.drag.active && !root.stackExpanded && root.index === 0) {
                    NotificationService.globalDragX = x
                }
            }

            Behavior on x { 
                enabled: !dragArea.drag.active
                NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
            }
        }
        
        Connections {
            target: NotificationService
            function onGlobalDragXChanged() {
            }
        }
        
        Binding on opacity {
            when: dragArea.drag.active || (!root.stackExpanded && NotificationService.globalDragX !== 0)
            value: 1.0 - Math.min(1.0, Math.abs(!root.stackExpanded ? NotificationService.globalDragX : dragProxy.x) / 300)
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
                let dragVal = !root.stackExpanded ? NotificationService.globalDragX : dragProxy.x
                
                if (Math.abs(dragVal) > 100) {
                    root.removeHistory = true
                    
                    if (!root.stackExpanded && root.index === 0 && root.count > 1) {
                        NotificationService.dismissAll()
                        NotificationService.globalDragX = 0
                    } else {
                        trans.x = dragProxy.x
                        dragProxy.x = 0 
                        root.dismiss()
                    }
                } else {
                    dragProxy.x = 0
                    if (!root.stackExpanded) NotificationService.globalDragX = 0
                }
            }
        }
        
        ClippingRectangle {
            anchors.fill: parent
            radius: 20
            color: ThemeService.backgroundMain
            border.color: ThemeService.outlineMain
            border.width: 1
            
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowOpacity: 0.3
                shadowBlur: 0.4
                shadowVerticalOffset: 2
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: 12
                    color: ThemeService.accentColor
                    opacity: 0.1
                    
                    Text {
                        anchors.centerIn: parent
                        text: "󰂚"
                        color: ThemeService.accentColor
                        font.pixelSize: 20
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    
                    Text {
                        text: root.notification ? root.notification.summary : "Notification"
                        color: ThemeService.backgroundContent
                        font.weight: Font.Black
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    
                    Text {
                        text: root.notification ? root.notification.body : ""
                        color: ThemeService.backgroundContent
                        opacity: 0.6
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        visible: text !== ""
                        Layout.fillWidth: true
                    }
                }

                Item {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    
                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        color: ThemeService.backgroundContent
                        opacity: hh.hovered ? 0.8 : 0.3
                        font.pixelSize: 16
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                    
                    TapHandler { 
                        onTapped: {
                            root.removeHistory = true
                            root.dismiss()
                        } 
                    }
                    HoverHandler { id: hh; cursorShape: Qt.PointingHandCursor }
                }
            }
        }
    }
    
    Component.onCompleted: {
        showAnim.start()
    }
    
    ParallelAnimation {
        id: showAnim
        NumberAnimation { target: contentItem; property: "opacity"; to: 1.0; duration: 400; easing.type: Easing.OutExpo }
        NumberAnimation { target: contentItem; property: "scale"; to: 1.0; duration: 500; easing.type: Easing.OutBack }
        NumberAnimation { target: trans; property: "x"; to: 0; duration: 400; easing.type: Easing.OutExpo }
    }

    Timer {
        interval: 5000
        running: NotificationService.expandedCount === 0
        onTriggered: {
            root.removeHistory = false
            root.dismiss()
        }
    }

    function dismiss() {
        SfxService.playButton1()
        hideAnim.start()
    }

    ParallelAnimation {
        id: hideAnim
        NumberAnimation { target: contentItem; property: "opacity"; to: 0.0; duration: 300; easing.type: Easing.InExpo }
        NumberAnimation { target: trans; property: "x"; to: 400; duration: 300; easing.type: Easing.InExpo }
        onFinished: {
            if (root.removeHistory && root.notification) root.notification.dismiss()
            NotificationService.removePopup(root.notification)
        }
    }
}