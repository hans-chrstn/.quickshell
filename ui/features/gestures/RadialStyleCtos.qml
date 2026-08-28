import QtQuick
import qs.core

Item {
    id: styleRoot
    anchors.fill: parent
    
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.02, 0.05, 0.08, 0.8)
        opacity: (hudWindow.isVisible && hudWindow.readyToDraw) ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
        
        Repeater {
            model: Math.ceil(parent.height / 4)
            Rectangle {
                y: index * 4
                width: parent.width
                height: 1
                color: ThemeManager.accentColor
                opacity: 0.03
            }
        }
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
            x: parent.width/2
            y: parent.height/2
            width: Math.sqrt(Math.pow(hudWindow.currentX - hudWindow.centerX, 2) + Math.pow(hudWindow.currentY - hudWindow.centerY, 2))
            height: 1
            color: ThemeManager.accentColor
            transformOrigin: Item.TopLeft
            rotation: Math.atan2(hudWindow.currentY - hudWindow.centerY, hudWindow.currentX - hudWindow.centerX) * 180 / Math.PI
            visible: width > 30
            
            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: 6
                color: ThemeManager.accentColor
                opacity: 0.2
            }
        }
        
        Item {
            anchors.centerIn: parent
            width: 80
            height: 80
            
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.width: 1
                border.color: ThemeManager.accentColor
                opacity: 0.4
                radius: width/2
                
                Rectangle {
                    width: 6; height: 6; radius: 3
                    color: ThemeManager.accentColor
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                Rectangle {
                    width: 6; height: 6; radius: 3
                    color: ThemeManager.accentColor
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                NumberAnimation on rotation {
                    from: 0; to: 360
                    duration: 6000
                    loops: Animation.Infinite
                    running: hudWindow.isVisible
                }
            }
            
            Rectangle {
                anchors.centerIn: parent
                width: 60
                height: 60
                radius: 30
                color: Qt.rgba(0.02, 0.05, 0.08, 0.9)
                border.width: 1
                border.color: ThemeManager.accentColor
                
                Text {
                    anchors.centerIn: parent
                    text: "[ " + hudWindow.formatPageName(hudWindow.availablePages[hudWindow.currentPageIndex]) + " ]"
                    color: ThemeManager.accentColor
                    font.pixelSize: 10
                    font.bold: true
                    font.family: "monospace"
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width - 6
                    wrapMode: Text.Wrap
                }
            }
        }
        
        Repeater {
            model: hudWindow.activeConfig
            
            Item {
                width: 64
                height: 64
                
                property real angle: (index * (360 / hudWindow.activeConfig.length)) - 90
                property real rad: angle * Math.PI / 180
                property real dist: 100
                
                x: menuContainer.width/2 + Math.cos(rad) * dist - width/2
                y: menuContainer.height/2 + Math.sin(rad) * dist - height/2
                
                property bool isSelected: index === hudWindow.selectedIndex
                
                Rectangle {
                    anchors.fill: parent
                    radius: 32
                    color: isSelected ? ThemeManager.accentColor : Qt.rgba(0.02, 0.05, 0.08, 0.9)
                    opacity: isSelected ? 1.0 : 0.8
                    border.width: isSelected ? 2 : 1
                    border.color: ThemeManager.accentColor
                    
                    scale: isSelected ? 1.1 : 1.0
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + 12
                        height: parent.height + 12
                        radius: width/2
                        color: "transparent"
                        border.width: 1
                        border.color: ThemeManager.accentColor
                        opacity: isSelected ? 0.5 : 0
                        
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                        
                        NumberAnimation on rotation {
                            from: 360; to: 0
                            duration: 3000
                            loops: Animation.Infinite
                            running: hudWindow.isVisible && isSelected
                        }
                        
                        Rectangle {
                            width: 8; height: 2; color: ThemeManager.accentColor
                            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                        }
                        Rectangle {
                            width: 8; height: 2; color: ThemeManager.accentColor
                            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
                
                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.icon
                        font.pixelSize: 22
                        color: isSelected ? "black" : ThemeManager.accentColor
                    }
                    
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.name.toUpperCase()
                        font.pixelSize: 9
                        font.bold: true
                        font.family: "monospace"
                        color: isSelected ? "black" : ThemeManager.accentColor
                        visible: isSelected
                    }
                }
            }
        }
    }
}
