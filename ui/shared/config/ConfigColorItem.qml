import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core
import qs.ui.shared
import qs.ui.shared.effects

Item {
    id: root
    
    property var configurationItemData: null
    width: parent ? parent.width : 0
    height: expanded ? 260 : 44
    
    property bool expanded: false

    Behavior on height {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutQuart
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            Layout.leftMargin: 12
            Layout.rightMargin: 12
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
                Layout.alignment: Qt.AlignVCenter
                text: root.configurationItemData ? ThemeManager[root.configurationItemData.property].toString() : ""
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
            
            BaseButton {
                width: 32
                height: 32
                cornerRadius: 16
                Layout.alignment: Qt.AlignVCenter
                onClicked: {
                    root.expanded = !root.expanded
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 16
                    color: root.configurationItemData ? ThemeManager[root.configurationItemData.property] : "transparent"
                    border.color: root.expanded ? ThemeManager.accentColor : ThemeManager.outlineStrongColor
                    border.width: 2
                }
            }
        }

        Item {
            id: pickerContainer
            Layout.fillWidth: true
            Layout.preferredHeight: root.expanded ? 210 : 0
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.bottomMargin: root.expanded ? 12 : 0
            clip: true
            opacity: root.expanded ? 1.0 : 0.0
            visible: opacity > 0.01

            Behavior on opacity { NumberAnimation { duration: 250 } }
            Behavior on Layout.preferredHeight { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }

            HSVColorPicker {
                id: picker
                anchors.fill: parent
                currentColor: root.configurationItemData ? ThemeManager[root.configurationItemData.property] : "#FFFFFF"
                
                Component.onCompleted: {
                    updateFromColor(currentColor)
                }

                onColorChanged: (newColor) => {
                    if (root.expanded) {
                        ThemeManager[root.configurationItemData.property] = newColor
                        ThemeManager.saveConfiguration()
                    }
                }
            }
        }
    }
}
