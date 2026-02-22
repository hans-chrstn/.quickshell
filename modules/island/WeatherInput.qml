import QtQuick
import QtQuick.Layouts
import qs.services

ColumnLayout {
    id: root
    spacing: 10
    
    signal finished()

    Text {
        text: "ENTER COORDINATES"
        color: ThemeService.backgroundContent
        font.pixelSize: 10
        font.weight: Font.Bold
        Layout.alignment: Qt.AlignHCenter
        opacity: 0.6
    }

    Rectangle {
        width: 200; height: 36; radius: 18
        color: ThemeService.surfaceStrong; opacity: locInput.activeFocus ? 1.0 : 0.5
        Layout.alignment: Qt.AlignHCenter
        border.color: ThemeService.backgroundContent
        border.width: locInput.activeFocus ? 1 : 0
        
        TextInput {
            id: locInput
            anchors.fill: parent
            anchors.leftMargin: 15; anchors.rightMargin: 15
            verticalAlignment: TextInput.AlignVCenter
            horizontalAlignment: TextInput.AlignHCenter
            color: ThemeService.backgroundContent
            font.pixelSize: 14
            selectByMouse: true
            onAccepted: {
                WeatherService.saveLocation(text)
                root.finished()
            }
            Keys.onEscapePressed: root.finished()
            
            Text {
                text: "lat,lon"
                color: ThemeService.backgroundContent; opacity: 0.3
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
            color: ThemeService.backgroundContent
            opacity: 0.5
            font.pixelSize: 12
            TapHandler {
                onTapped: root.finished()
            }
        }
    }
    
    Text {
        text: "PRESS ENTER TO SAVE"
        color: ThemeService.backgroundContent; opacity: 0.3; font.pixelSize: 8
        Layout.alignment: Qt.AlignHCenter
    }
    
    Component.onCompleted: locInput.forceActiveFocus()
}