import QtQuick
import QtQuick.Layouts
import QtMultimedia
import Quickshell
import qs.services
import qs.components

Item {
    id: root
    anchors.fill: parent
    
    SoundEffect {
        id: clickSound
        source: Quickshell.shellPath("assets/sfx/button1.wav")
        volume: 0.5
    }

    RowLayout {
        id: mainView
        anchors.centerIn: parent
        spacing: 24

        ControlTiles {
            id: tiles
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            width: 1; height: 70
            color: ThemeService.backgroundContent; opacity: 0.05
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            spacing: 6
            Layout.alignment: Qt.AlignVCenter
            
            ControlSliders { 
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: "OPEN SETTINGS 󰒓"
                color: ThemeService.accentColor
                font.pixelSize: 8
                font.weight: Font.Black; font.letterSpacing: 1
                Layout.alignment: Qt.AlignRight
                Layout.topMargin: 2
                
                opacity: hhSet.hovered ? 1.0 : 0.6
                Behavior on opacity { NumberAnimation { duration: 200 } }
                
                TapHandler { 
                    onTapped: { 
                        ViewService.openSettings()
                        SfxService.playButton1()
                    } 
                }
                HoverHandler { id: hhSet; cursorShape: Qt.PointingHandCursor }
            }
        }
    }
}
