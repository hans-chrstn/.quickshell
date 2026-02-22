import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

ColumnLayout {
    id: root
    spacing: 10
    
    signal finished()

    Text {
        text: "ENTER COORDINATES"
        color: "white"
        font.pixelSize: 10
        font.weight: Font.Bold
        Layout.alignment: Qt.AlignHCenter
        opacity: 0.6
    }

    Rectangle {
        width: 200; height: 36; radius: 18
        color: "white"; opacity: locInput.activeFocus ? 0.2 : 0.1
        Layout.alignment: Qt.AlignHCenter
        border.color: "white"
        border.width: locInput.activeFocus ? 1 : 0
        
        TextInput {
            id: locInput
            anchors.fill: parent
            anchors.leftMargin: 15; anchors.rightMargin: 15
            verticalAlignment: TextInput.AlignVCenter
            horizontalAlignment: TextInput.AlignHCenter
            color: "white"
            font.pixelSize: 14
            selectByMouse: true
            onAccepted: {
                WeatherService.saveLocation(text)
                root.finished()
            }
            Keys.onEscapePressed: root.finished()
            
            Text {
                text: "lat,lon"
                color: "white"; opacity: 0.3
                visible: !parent.text && !parent.activeFocus
                anchors.centerIn: parent
            }
        }
        
        TapHandler {
            onTapped: locInput.forceActiveFocus()
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: "✕"
            color: "white"
            opacity: 0.5
            font.pixelSize: 12
            TapHandler {
                onTapped: root.finished()
            }
        }
    }
    
    Text {
        text: "PRESS ENTER TO SAVE"
        color: "white"; opacity: 0.3; font.pixelSize: 8
        Layout.alignment: Qt.AlignHCenter
    }
    
    Component.onCompleted: locInput.forceActiveFocus()
}
