import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

BaseButton {
    id: root
    
    Layout.preferredWidth: 140
    Layout.preferredHeight: 44
    cornerRadius: 12
    
    property string actionIcon: ""
    property string actionLabel: ""
    property color actionHighlightColor: ThemeManager.accentColor
    
    signal actionTriggered()
    onClicked: {
        SoundManager.playClick()
        root.actionTriggered()
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: ThemeManager.contentOnBackgroundColor
        opacity: root.isHovered ? 0.12 : 0.06
        
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 12
        
        StyledLabel {
            text: root.actionIcon
            type: "icon"
            font.pixelSize: 18
            customColor: root.isHovered ? root.actionHighlightColor : ThemeManager.contentOnBackgroundColor
            opacity: root.isHovered ? 1.0 : 0.6
            Behavior on customColor { ColorAnimation { duration: 200 } }
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
        
        StyledLabel {
            text: root.actionLabel
            type: "caption"
            font.weight: Font.Bold
            letterSpacing: 1
            Layout.fillWidth: true
            opacity: root.isHovered ? 1.0 : 0.4
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
        
        StyledLabel {
            text: ThemeManager.iconRightArrow
            type: "icon"
            font.pixelSize: 14
            opacity: root.isHovered ? 0.4 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }
}
