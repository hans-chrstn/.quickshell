import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

BaseButton {
    id: root

    property var pageInfo: null
    property bool isSelected: false
    
    signal selected()

    Layout.alignment: Qt.AlignHCenter
    width: 44
    height: 44
    cornerRadius: 12
    tooltip: {
        return root.pageInfo ? root.pageInfo.title : ""
    }

    onClicked: {
        root.selected()
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.cornerRadius
        color: "transparent"
        border.color: ThemeManager.outlinePrimaryColor
        border.width: 1
        visible: {
            return !root.isSelected
        }
    }

    Text {
        anchors.centerIn: parent
        text: {
            return root.pageInfo ? root.pageInfo.icon : ""
        }
        color: {
            if (root.isSelected) {
                return ThemeManager.contentPrimaryColor
            }
            return ThemeManager.contentOnBackgroundColor
        }
        font.pixelSize: 22
        z: 1

        Behavior on color { 
            ColorAnimation { 
                duration: 250 
            } 
        }
    }
}
