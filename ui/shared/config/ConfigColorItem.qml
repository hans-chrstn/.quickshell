import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core
import qs.ui.shared

Item {
    id: root
    
    property var configurationItemData: null
    width: parent ? parent.width : 0
    height: 44
    focus: true
    
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 16
        
        StyledLabel { 
            text: root.configurationItemData ? root.configurationItemData.label : ""
            type: "configLabel"
            opacity: 0.9
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter 
        }
        
        TextField {
            id: colorInput
            Layout.preferredWidth: 100
            color: ThemeManager.contentOnBackgroundColor
            font.pixelSize: 13
            font.family: "Fira Code"
            focus: true
            Layout.alignment: Qt.AlignVCenter
            text: root.configurationItemData ? ThemeManager[root.configurationItemData.property] : ""
            activeFocusOnTab: false
            
            background: Rectangle { 
                color: ThemeManager.contentOnBackgroundColor
                opacity: 0.05
                radius: 8
                border.color: colorInput.activeFocus ? ThemeManager.accentColor : ThemeManager.outlinePrimaryColor
                border.width: 1
            }
            
            onAccepted: { 
                ThemeManager[root.configurationItemData.property] = text
                ThemeManager.saveConfiguration()
                focus = false 
            }
        }
        
        Rectangle {
            width: 32
            height: 32
            radius: 16
            Layout.alignment: Qt.AlignVCenter
            color: root.configurationItemData ? ThemeManager[root.configurationItemData.property] : "transparent"
            border.color: colorInput.activeFocus ? "white" : ThemeManager.outlineStrongColor
            border.width: 2
        }
    }
}
