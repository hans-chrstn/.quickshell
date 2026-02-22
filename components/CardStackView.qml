import QtQuick
import QtMultimedia
import Quickshell
import qs.services
import qs.components

ListView {
    id: root
    
    property bool stackExpanded: false
    property int collapsedVisibleCount: 2
    property int collapsedSpacing: -65
    property int expandedSpacing: 10
    
    spacing: stackExpanded ? expandedSpacing : collapsedSpacing
    Behavior on spacing { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
    
    function isItemVisible(index) {
        return stackExpanded || index < collapsedVisibleCount
    }
    
    onCountChanged: {
        if (count <= collapsedVisibleCount) stackExpanded = false
    }

    header: Item {
        width: root.width
        height: (root.stackExpanded && root.count > root.collapsedVisibleCount) ? 40 : 0
        visible: (root.stackExpanded && root.count > root.collapsedVisibleCount)
        clip: true
        Behavior on height { NumberAnimation { duration: 300 } }
        
        Row {
            anchors.centerIn: parent
            spacing: 10
            
            Rectangle {
                width: 80; height: 24; radius: 12
                color: ThemeService.surfaceStrong
                border.color: ThemeService.outlineMain
                border.width: 1
                opacity: 0.8
                
                Text {
                    anchors.centerIn: parent
                    text: "COLLAPSE"
                    color: ThemeService.backgroundContent
                    font.pixelSize: 10; font.weight: Font.Bold
                }
                
                TapHandler { onTapped: root.stackExpanded = false }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }

            Rectangle {
                width: 80; height: 24; radius: 12
                color: ThemeService.surfaceStrong
                border.color: ThemeService.accentColor
                border.width: 1
                opacity: 0.8
                
                Text {
                    anchors.centerIn: parent
                    text: "CLEAR ALL"
                    color: ThemeService.accentColor
                    font.pixelSize: 10; font.weight: Font.Bold
                }
                
                TapHandler { 
                    onTapped: {
                        NotificationService.dismissAll()
                        root.stackExpanded = false
                        SfxService.playComplete()
                    }
                }
                HoverHandler { id: hhClear; cursorShape: Qt.PointingHandCursor }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !root.stackExpanded && root.count > 1
        onClicked: root.stackExpanded = true
        z: 2000
    }
}