import QtQuick
import qs.config
import qs.components
import qs.services

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
                color: "#222"; border.color: "#444"; border.width: 1
                opacity: 0.8
                
                Text {
                    anchors.centerIn: parent
                    text: "COLLAPSE"
                    color: "white"; font.pixelSize: 10; font.weight: Font.Bold
                }
                
                TapHandler { onTapped: root.stackExpanded = false }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }

            Rectangle {
                width: 80; height: 24; radius: 12
                color: "#222"; border.color: FrameConfig.accentColor; border.width: 1
                opacity: 0.8
                
                Text {
                    anchors.centerIn: parent
                    text: "CLEAR ALL"
                    color: FrameConfig.accentColor; font.pixelSize: 10; font.weight: Font.Bold
                }
                
                TapHandler { 
                    onTapped: {
                        NotificationService.dismissAll()
                        root.stackExpanded = false
                    }
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
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
