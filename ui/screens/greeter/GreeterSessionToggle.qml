import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

BaseButton {
    id: root
    
    property var logic
    
    width: 320
    height: 30
    
    onClicked: {
        logic.showSessionPicker = !logic.showSessionPicker
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(1, 1, 1, 0.05)
        radius: 15
        border.color: Qt.rgba(1, 1, 1, 0.1)
        border.width: 1
        scale: root.isHovered ? 1.02 : 1.0
        
        Behavior on scale {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutQuart
            }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: 10
            
            StyledLabel {
                text: ThemeManager.iconLauncher + "  " + SessionManager.currentSessionName.toUpperCase()
                type: "caption"
                font.weight: Font.Black
                font.letterSpacing: 1
                font.pixelSize: 10
                opacity: 0.6
            }
            
            StyledLabel {
                text: ThemeManager.iconSelector
                type: "caption"
                customColor: ColorManager.accentColor
                font.pixelSize: 10
                opacity: 0.8
            }
        }
    }
}
