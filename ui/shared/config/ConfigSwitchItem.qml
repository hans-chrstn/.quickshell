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
            readonly property bool isOn: ThemeManager[root.configurationItemData.property]
            color: switchIndicator.isOn ? "#34C759" : ThemeManager.outlineStrongColor
            border.color: root.activeFocus ? "white" : "transparent"
            border.width: root.activeFocus ? 2 : 0
            Behavior on color { ColorAnimation { duration: 140 } }

            Rectangle {
                x: switchIndicator.isOn ? parent.width - width - 2 : 2
                y: 2
                width: 20
                height: 20
                radius: 10
                color: "white"
                Behavior on x {
                    NumberAnimation {
                        duration: 140
                        easing.type: Easing.OutCubic
                    }
                }
            }

            TapHandler {
                onTapped: root.performToggle()
            }
        }
    }
}
