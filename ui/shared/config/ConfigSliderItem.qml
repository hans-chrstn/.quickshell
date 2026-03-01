import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core
import qs.ui.shared

Item {
    id: root
    
    property var configurationItemData: null
    width: parent ? parent.width : 0
    height: 60
    focus: true
    
    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 4
        
        RowLayout {
            Layout.fillWidth: true
            
            StyledLabel { 
                text: root.configurationItemData ? root.configurationItemData.label : ""
                type: "configLabel"
                opacity: 0.9
                Layout.alignment: Qt.AlignVCenter 
            }
            
            Item { Layout.fillWidth: true }
            
            StyledLabel { 
                text: root.configurationItemData ? (root.configurationItemData.step < 1 ? ThemeManager[root.configurationItemData.property].toFixed(2) : Math.round(ThemeManager[root.configurationItemData.property])) : ""
                type: "configValue"
                opacity: 0.5
                Layout.alignment: Qt.AlignVCenter 
            }
        }
        
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            color: "transparent"
            
            Slider {
                id: sliderInput
                anchors.fill: parent
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                focus: true
                activeFocusOnTab: false
                
                Keys.onLeftPressed: { 
                    value -= stepSize
                    ThemeManager[root.configurationItemData.property] = value
                    ThemeManager.saveConfiguration() 
                }
                Keys.onRightPressed: { 
                    value += stepSize
                    ThemeManager[root.configurationItemData.property] = value
                    ThemeManager.saveConfiguration() 
                }
                
                from: root.configurationItemData ? root.configurationItemData.min : 0
                to: root.configurationItemData ? root.configurationItemData.max : 100
                stepSize: root.configurationItemData ? (root.configurationItemData.step || 1) : 1
                value: root.configurationItemData ? ThemeManager[root.configurationItemData.property] : 0
                
                onMoved: { 
                    ThemeManager[root.configurationItemData.property] = value 
                }
                
                onPressedChanged: { 
                    if (!pressed) {
                        ThemeManager.saveConfiguration() 
                    }
                }
                
                background: Rectangle {
                    width: parent.width
                    height: 6
                    radius: 3
                    color: ThemeManager.contentOnBackgroundColor
                    opacity: 0.1
                    anchors.centerIn: parent
                    
                    Rectangle { 
                        width: parent.parent.visualPosition * parent.width
                        height: parent.height
                        radius: 3
                        color: ThemeManager.accentColor 
                    }
                }
                
                handle: Rectangle {
                    x: parent.visualPosition * (parent.availableWidth - width)
                    anchors.verticalCenter: parent.verticalCenter 
                    width: 20
                    height: 20
                    radius: 10
                    color: ThemeManager.contentOnBackgroundColor
                    border.color: sliderInput.activeFocus ? "white" : ThemeManager.accentColor
                    border.width: sliderInput.activeFocus ? 2 : 1
                    scale: parent.pressed || sliderInput.activeFocus ? 1.2 : 1.0
                    Behavior on scale { 
                        NumberAnimation { 
                            duration: 150 
                        } 
                    }
                }
            }
        }
    }
}
