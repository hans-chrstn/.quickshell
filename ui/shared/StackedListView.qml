import QtQuick
import Quickshell
import qs.core

ListView {
    id: root
    
    property bool isStackExpanded: false
    property int collapsedVisibleItemCount: 2
    property int collapsedItemSpacing: -65
    property int expandedItemSpacing: 10
    
    spacing: isStackExpanded ? expandedItemSpacing : collapsedItemSpacing
    Behavior on spacing { NumberAnimation { duration: 300; easing.type: ThemeManager.animationEasing } }
    
    function isItemVisible(index) {
        return isStackExpanded || index < collapsedVisibleItemCount
    }
    
    onCountChanged: {
        if (count <= collapsedVisibleItemCount) {
            isStackExpanded = false
        }
    }

    header: Item {
        width: root.width
        height: (root.isStackExpanded && root.count > root.collapsedVisibleItemCount) ? 40 : 0
        visible: (root.isStackExpanded && root.count > root.collapsedVisibleItemCount)
        clip: true
        Behavior on height { NumberAnimation { duration: 300 } }
        
        Row {
            anchors.centerIn: parent
            spacing: 10
            
            Rectangle {
                width: 80; height: 24; radius: 12
                color: ThemeManager.surfaceStrongColor
                border.color: ThemeManager.outlinePrimaryColor
                border.width: 1
                opacity: 0.8
                
                Text {
                    anchors.centerIn: parent
                    text: "COLLAPSE"
                    color: ThemeManager.contentOnBackgroundColor
                    font.pixelSize: 10; font.weight: Font.Bold
                }
                
                TapHandler { 
                    onTapped: root.isStackExpanded = false 
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }

            Rectangle {
                width: 80; height: 24; radius: 12
                color: ThemeManager.surfaceStrongColor
                border.color: ThemeManager.accentColor
                border.width: 1
                opacity: 0.8
                
                Text {
                    anchors.centerIn: parent
                    text: "CLEAR ALL"
                    color: ThemeManager.accentColor
                    font.pixelSize: 10; font.weight: Font.Bold
                }
                
                TapHandler { 
                    onTapped: {
                        NotificationManager.clearAllNotifications()
                        root.isStackExpanded = false
                        SoundManager.playSuccess()
                    }
                }
                HoverHandler { id: clearHoverHandler; cursorShape: Qt.PointingHandCursor }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !root.isStackExpanded && root.count > 1
        onClicked: root.isStackExpanded = true
        z: 2000
    }
}
