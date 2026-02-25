import QtQuick
import qs.core

Row {
    id: root
    
    property int tabCount: 0
    property int currentTabIndex: 0
    property color indicatorColor: ThemeManager.contentOnBackgroundColor
    property int dotDiameter: 4
    property int activeDotWidth: 12

    anchors.horizontalCenter: parent.horizontalCenter
    spacing: ThemeManager.indicatorRowSpacing

    Repeater { 
        model: root.tabCount
        
        delegate: Rectangle { 
            width: root.currentTabIndex === index ? root.activeDotWidth : root.dotDiameter
            height: root.dotDiameter
            radius: root.dotDiameter / 2
            color: root.indicatorColor
            opacity: root.currentTabIndex === index ? 0.8 : 0.2
            
            Behavior on width { 
                NumberAnimation { 
                    duration: 300
                    easing.type: Easing.OutQuint 
                } 
            }
            Behavior on opacity { 
                NumberAnimation { 
                    duration: 300 
                } 
            }
        } 
    }
}
