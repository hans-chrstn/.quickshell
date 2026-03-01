import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

Item {
    id: root
    
    property var configurationItemData: null
    height: 40
    width: parent ? parent.width : 0
    
    StyledLabel {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        anchors.leftMargin: 12
        text: root.configurationItemData ? root.configurationItemData.label.toUpperCase() : ""
        type: "configHeader"
        opacity: 0.5
    }
}
