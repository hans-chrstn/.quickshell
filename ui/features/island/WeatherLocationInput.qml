import QtQuick
import QtQuick.Layouts
import qs.core

ColumnLayout {
    id: root
    
    spacing: 10
    
    signal interactionFinished()

    Text {
        id: headerLabel
        text: "ENTER COORDINATES"
        color: ThemeManager.contentOnBackgroundColor
        font.pixelSize: 10
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
        
        TextInput {
            id: coordinateInput
            anchors.fill: parent
            anchors.leftMargin: 15
            anchors.rightMargin: 15
            verticalAlignment: TextInput.AlignVCenter
            horizontalAlignment: TextInput.AlignHCenter
            color: ThemeManager.contentOnBackgroundColor
            font.pixelSize: 14
            selectByMouse: true
            
            onAccepted: {
                WeatherManager.updateLocation(text)
                root.interactionFinished()
            }
            Keys.onEscapePressed: root.interactionFinished()
            
            Text {
                id: placeholderText
                text: "lat,lon"
                color: ThemeManager.contentOnBackgroundColor
                opacity: 0.3
                visible: !parent.text && !parent.activeFocus
                anchors.centerIn: parent
            }
        }
        
        TapHandler {
            onTapped: coordinateInput.forceActiveFocus()
        }

        Text {
            id: clearButton
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: "✕"
            color: ThemeManager.contentOnBackgroundColor
            opacity: 0.5
            font.pixelSize: 12
            
            TapHandler {
                onTapped: root.interactionFinished()
            }
        }
    }
    
    Text {
        id: instructionsLabel
        text: "PRESS ENTER TO SAVE"
        color: ThemeManager.contentOnBackgroundColor
        opacity: 0.3
        font.pixelSize: 8
        Layout.alignment: Qt.AlignHCenter
    }
    
    Component.onCompleted: coordinateInput.forceActiveFocus()
}
