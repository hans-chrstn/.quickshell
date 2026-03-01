import QtQuick
import qs.core
import qs.ui.shared

Column {
    id: root
    
    spacing: 6
    
    property string iconText: ""
    property string labelText: ""
    
    signal clicked()
    
    BaseButton {
        id: btn
        anchors.horizontalCenter: parent.horizontalCenter
        width: 44
        height: 44
        onClicked: {
            root.clicked()
        }
        
        Rectangle {
            anchors.fill: parent
            radius: 22
            color: "white"
            opacity: btn.isHovered ? 0.2 : 0.1
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }
            StyledLabel {
                anchors.centerIn: parent
                text: root.iconText
                type: "icon"
                font.pixelSize: 22
            }
        }
    }
    
    StyledLabel {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.labelText
        type: "caption"
        opacity: btn.isHovered ? 1.0 : 0.6
        font.weight: Font.Bold
        font.letterSpacing: 1
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }
    }
}
