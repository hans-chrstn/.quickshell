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
        
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on border.width { NumberAnimation { duration: 200 } }
    }

    RowLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 12

        StyledLabel {
            id: iconVisual
            text: root.actionIcon
            type: "icon"
            customColor: root.isHovered ? root.actionHighlightColor : ThemeManager.contentOnBackgroundColor
            Behavior on customColor { ColorAnimation { duration: 200 } }
        }

        StyledLabel {
            id: labelVisual
            text: root.actionLabel
            type: "caption"
            font.weight: Font.Bold
            letterSpacing: 1
            Layout.fillWidth: true
        }
        
        StyledLabel {
            id: arrowIndicator
            text: "󰁔"
            type: "icon"
            font.pixelSize: 14
            opacity: root.isHovered ? 0.4 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }
}
