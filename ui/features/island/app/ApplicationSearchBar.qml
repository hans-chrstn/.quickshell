import QtQuick
import Quickshell
import qs.core
import qs.ui.shared

Item {
    id: root
    
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.topMargin: 10
    
    width: 32
    height: 6
    
    BaseButton {
        anchors.fill: parent
        cornerRadius: 3
        
        onClicked: {
            LauncherManager.open()
        }

        Rectangle {
            anchors.fill: parent
            radius: 3
            color: ThemeManager.contentOnBackgroundColor
            opacity: parent.isHovered ? 0.6 : 0.2
            
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }
        }
    }
}
