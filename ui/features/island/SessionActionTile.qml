import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

Item {
    id: root
    
    Layout.preferredWidth: 140
    Layout.preferredHeight: 44
    
    property string actionIcon: ""
    property string actionLabel: ""
    property color actionHighlightColor: ThemeManager.accentColor
    
    signal actionTriggered()

    Rectangle {
        id: backgroundVisual
        anchors.fill: parent
        radius: 12
        color: ThemeManager.contentOnBackgroundColor
        opacity: interactionHoverHandler.hovered ? 0.12 : 0.06
        border.color: root.actionHighlightColor
        border.width: interactionHoverHandler.hovered ? 1 : 0
        
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
            color: interactionHoverHandler.hovered ? root.actionHighlightColor : ThemeManager.contentOnBackgroundColor
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
            opacity: interactionHoverHandler.hovered ? 0.4 : 0
            font.pixelSize: 14
            Behavior on opacity { 
                NumberAnimation { 
                    duration: 200 
                } 
            }
        }
    }

    TapHandler {
        onTapped: {
            SoundManager.playClick()
            root.actionTriggered()
        }
    }
    
    HoverHandler { 
        id: interactionHoverHandler
        cursorShape: Qt.PointingHandCursor 
    }
    
    scale: interactionHoverHandler.hovered ? 1.02 : 1.0
    Behavior on scale { 
        NumberAnimation { 
            duration: 300
            easing.type: Easing.OutBack 
        } 
    }
}
