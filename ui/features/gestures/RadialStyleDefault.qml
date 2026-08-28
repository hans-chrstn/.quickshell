import QtQuick
import qs.core

Item {
    id: styleRoot
    anchors.fill: parent
    
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.4)
        opacity: (hudWindow.isVisible && hudWindow.readyToDraw) ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }
    
    Item {
        id: menuContainer
        x: hudWindow.centerX - width/2
        y: hudWindow.centerY - height/2
        width: 300
        height: 300
        
        opacity: (hudWindow.isVisible && hudWindow.readyToDraw) ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
        
        Rectangle {
            anchors.centerIn: parent
            width: 60
            height: 60
            radius: 30
            color: ThemeManager.backgroundColor
            border.width: 2
            border.color: ThemeManager.accentColor
            
            Text {
                anchors.centerIn: parent
                text: hudWindow.formatPageName(hudWindow.availablePages[hudWindow.currentPageIndex])
                color: "white"
                font.pixelSize: 12
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                width: parent.width - 10
                wrapMode: Text.Wrap
            }
        }
        
        Rectangle {
            x: parent.width/2
            y: parent.height/2
            width: Math.sqrt(Math.pow(hudWindow.currentX - hudWindow.centerX, 2) + Math.pow(hudWindow.currentY - hudWindow.centerY, 2))
            height: 2
            color: ThemeManager.accentColor
            opacity: 0.5
            transformOrigin: Item.TopLeft
            rotation: Math.atan2(hudWindow.currentY - hudWindow.centerY, hudWindow.currentX - hudWindow.centerX) * 180 / Math.PI
            visible: width > 20
        }
        
        Repeater {
            model: hudWindow.activeConfig
            
            Item {
                width: 60
                height: 60
                
                property real angle: (index * (360 / hudWindow.activeConfig.length)) - 90
                property real rad: angle * Math.PI / 180
                property real dist: 100
                
                x: menuContainer.width/2 + Math.cos(rad) * dist - width/2
                y: menuContainer.height/2 + Math.sin(rad) * dist - height/2
                
                property bool isSelected: index === hudWindow.selectedIndex
                
                Rectangle {
                    anchors.fill: parent
                    radius: 30
                    color: isSelected ? ThemeManager.accentColor : "black"
                    opacity: isSelected ? 0.9 : 0.7
                    border.width: 2
                    border.color: isSelected ? "white" : ThemeManager.outlinePrimaryColor
                    
                    scale: isSelected ? 1.1 : 1.0
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                
                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.icon
                        font.pixelSize: 24
                        color: isSelected ? "black" : "white"
                    }
                    
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.name
                        font.pixelSize: 10
                        font.bold: true
                        color: isSelected ? "black" : "white"
                        visible: isSelected
                    }
                }
            }
        }
    }
}
