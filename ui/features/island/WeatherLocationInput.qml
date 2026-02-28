import QtQuick
import QtQuick.Layouts
import qs.core
import qs.ui.shared

ColumnLayout {
    id: root
    
    spacing: 10
    
    signal interactionFinished()

    StyledLabel {
        id: headerLabel
        type: "caption"
        text: "ENTER COORDINATES"
        font.weight: Font.Bold
        Layout.alignment: Qt.AlignHCenter
        opacity: 0.6
    }

    Rectangle {
        id: inputContainer
        width: 200
        height: 36
        radius: 18
        color: ThemeManager.surfaceStrongColor
        opacity: coordinateInput.activeFocus ? 1.0 : 0.5
        Layout.alignment: Qt.AlignHCenter
        border.color: ThemeManager.contentOnBackgroundColor
        border.width: coordinateInput.activeFocus ? 1 : 0
        
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on border.width { NumberAnimation { duration: 200 } }
        
        TextInput {
            id: coordinateInput
            anchors.fill: parent
            anchors.leftMargin: 15
            anchors.rightMargin: 15
            verticalAlignment: TextInput.AlignVCenter
            horizontalAlignment: TextInput.AlignHCenter
            color: ThemeManager.contentOnBackgroundColor
            font.family: ThemeManager.fontFamily
            font.pixelSize: 14
            selectByMouse: true
            
            onAccepted: {
                WeatherManager.updateLocation(text)
                root.interactionFinished()
            }
            Keys.onEscapePressed: root.interactionFinished()
            
            StyledLabel {
                id: placeholderText
                type: "body"
                text: "lat,lon"
                opacity: 0.3
                visible: !parent.text && !parent.activeFocus
                anchors.centerIn: parent
            }
        }
        
        TapHandler {
            onTapped: coordinateInput.forceActiveFocus()
        }

        StyledLabel {
            id: clearButton
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: "✕"
            type: "body"
            opacity: clearHover.hovered ? 1.0 : 0.5
            
            TapHandler {
                onTapped: root.interactionFinished()
            }
            HoverHandler { id: clearHover; cursorShape: Qt.PointingHandCursor }
        }
    }
    
    StyledLabel {
        id: instructionsLabel
        type: "caption"
        text: "PRESS ENTER TO SAVE"
        opacity: 0.3
        font.pixelSize: 8
        Layout.alignment: Qt.AlignHCenter
    }
    
    Component.onCompleted: coordinateInput.forceActiveFocus()
}
