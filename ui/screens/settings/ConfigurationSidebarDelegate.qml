import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

BaseButton {
    id: root
    
    property var modelData
    property bool isCascadeAnimationActive: false
    property bool isSettingsClosing: false
    property real sidebarItemOpacity: 1.0

    width: ListView.view ? ListView.view.width : 0
    height: 48
    
    onClicked: {
        if (ListView.view) {
            ListView.view.currentIndex = index
            ListView.view.forceActiveFocus()
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        
        color: root.ListView.isCurrentItem ? ThemeManager.surfaceVariantColor : "transparent"
        opacity: root.sidebarItemOpacity
        scale: root.isHovered && !root.ListView.isCurrentItem ? 1.02 : 1.0
        
        Behavior on color {
            ColorAnimation {
                duration: 200
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutQuart
            }
        }

        transform: Translate {
            x: (root.isCascadeAnimationActive && !root.isSettingsClosing) ? 0 : -40
            Behavior on x { 
                SequentialAnimation {
                    PauseAnimation { 
                        duration: (root.isCascadeAnimationActive && !root.isSettingsClosing) ? (index * 35) : ((root.ListView.view.count - index) * 15) 
                    }
                    NumberAnimation { 
                        duration: (root.isCascadeAnimationActive && !root.isSettingsClosing) ? 500 : 150
                        easing.type: Easing.OutExpo 
                    }
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 4
            width: (root.ListView.isCurrentItem && root.ListView.view.activeFocus) ? 4 : 0
            height: 24
            radius: 2
            color: ThemeManager.primaryColor
            Behavior on width { 
                NumberAnimation { 
                    duration: 200
                    easing.type: Easing.OutBack 
                } 
            }
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 16
            spacing: 12
            
            Item {
                width: 28
                height: parent.height
                
                StyledLabel {
                    anchors.centerIn: parent
                    text: root.modelData.icon
                    type: "icon"
                    opacity: root.ListView.isCurrentItem ? 1.0 : 0.4
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                }
            }
            
            StyledLabel {
                anchors.verticalCenter: parent.verticalCenter
                text: root.modelData.category
                type: "body"
                font.weight: root.ListView.isCurrentItem ? Font.DemiBold : Font.Normal
                opacity: root.ListView.isCurrentItem ? 1.0 : 0.6
                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                    }
                }
            }
        }
        
        Rectangle {
            anchors.fill: parent
            radius: 12
            color: ThemeManager.contentOnBackgroundColor
            opacity: root.isHovered && !root.ListView.isCurrentItem ? 0.04 : 0
        }
    }
}
