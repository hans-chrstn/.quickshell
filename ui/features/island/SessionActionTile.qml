import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

BaseButton {
    id: root
    
    Layout.preferredWidth: 140
    Layout.preferredHeight: 44
    
    property string actionIcon: ""
    property string actionLabel: ""
    property color actionHighlightColor: ThemeManager.accentColor
    
    signal actionTriggered()
    onClicked: {
        SoundManager.playClick()
        root.actionTriggered()
    }

    Rectangle {
        id: backgroundVisual
        anchors.fill: parent
        radius: 12
        color: ThemeManager.contentOnBackgroundColor
        opacity: root.isHovered ? 0.12 : 0.06
        border.color: root.actionHighlightColor
        border.width: root.isHovered ? 1 : 0
        
        Behavior on opacity { 
            NumberAnimation { 
                duration: 200 
            } 
        }
        Behavior on border.width { 
            NumberAnimation { 
                duration: 200 
            } 
        }
    }

    RowLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 12

        Text {
            id: iconVisual
            text: root.actionIcon
            color: root.isHovered ? root.actionHighlightColor : ThemeManager.contentOnBackgroundColor
            font.pixelSize: 18
            Behavior on color { 
                ColorAnimation { 
                    duration: 200 
                } 
            }
        }

        Text {
            id: labelVisual
            text: root.actionLabel
            color: ThemeManager.contentOnBackgroundColor
            font.pixelSize: 11
            font.weight: Font.Bold
            font.letterSpacing: 1
            Layout.fillWidth: true
        }
        
        Text {
            id: arrowIndicator
            text: "󰁔"
            color: ThemeManager.contentOnBackgroundColor
            opacity: root.isHovered ? 0.4 : 0
            font.pixelSize: 14
            Behavior on opacity { 
                NumberAnimation { 
                    duration: 200 
                } 
            }
        }
    }
}
