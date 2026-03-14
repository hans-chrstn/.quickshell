import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

Item {
    id: root

    property string icon: ""
    property color color: "white"
    property bool isVisible: true
    
    signal clicked()

    width: 32
    Layout.fillHeight: true
    visible: isVisible

    Rectangle {
        anchors.fill: parent
        color: root.color
        opacity: {
            if (mouseArea.pressed) {
                return 0.4
            }
            if (mouseArea.containsMouse) {
                return 0.25
            }
            return 0.15
        }
        
        Behavior on opacity { 
            NumberAnimation { 
                duration: 150 
            } 
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.color
        font.pixelSize: 18
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            root.clicked()
        }
    }
}
