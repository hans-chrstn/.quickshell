import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

Item {
    id: root
    
    property var configurationItemData: null
    width: parent ? parent.width : 0
    height: 44
    focus: true
    
    function performToggle() {
        ThemeManager[root.configurationItemData.property] = !ThemeManager[root.configurationItemData.property]
        ThemeManager.saveConfiguration()
    }

    Keys.onSpacePressed: root.performToggle()
    Keys.onEnterPressed: root.performToggle()
    Keys.onReturnPressed: root.performToggle()

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        
        StyledLabel { 
            text: root.configurationItemData ? root.configurationItemData.label : ""
            type: "configLabel"
            opacity: 0.9
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter 
        }
        
        Rectangle {
            id: switchIndicator
            implicitWidth: 44
            implicitHeight: 24
            radius: 12
            Layout.alignment: Qt.AlignVCenter
            color: ThemeManager[root.configurationItemData.property] ? ThemeManager.accentColor : ThemeManager.outlinePrimaryColor
            border.color: root.activeFocus ? "white" : "transparent"
            border.width: root.activeFocus ? 2 : 0
            
            Rectangle {
                x: ThemeManager[root.configurationItemData.property] ? parent.width - width - 2 : 2
                y: 2
                width: 20
                height: 20
                radius: 10
                color: ThemeManager[root.configurationItemData.property] ? ThemeManager.backgroundPrimaryColor : ThemeManager.contentOnBackgroundColor
                Behavior on x { 
                    NumberAnimation { 
                        duration: 200
                        easing.type: Easing.OutQuart 
                    } 
                }
                Behavior on color { 
                    ColorAnimation { 
                        duration: 200 
                    } 
                }
            }
            
            TapHandler { 
                onTapped: root.performToggle() 
            }
        }
    }
}
