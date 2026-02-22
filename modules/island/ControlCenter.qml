import QtQuick
import QtQuick.Layouts
import QtMultimedia
import Quickshell
import qs.services
import qs.components
import qs.modules.windows
import qs.modules.island

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
        anchors.verticalCenterOffset: 0
        spacing: 24

        ControlTiles {
        }

        Rectangle {
            width: 1; height: 120
            color: "white"; opacity: 0.05
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            spacing: 12
            Layout.alignment: Qt.AlignVCenter

            ControlSliders { }
            
            Text {
                text: "OPEN SETTINGS 󰒓"
                color: ThemeService.accentColor; font.pixelSize: 9; font.weight: Font.Black; font.letterSpacing: 1
                Layout.alignment: Qt.AlignRight
                Layout.topMargin: 4
                Layout.bottomMargin: 12
                opacity: hhSet.hovered ? 1.0 : 0.6
                Behavior on opacity { NumberAnimation { duration: 200 } }
                TapHandler { 
                    onTapped: { 
                        ViewService.openSettings()
                        clickSound.play() 
                    } 
                }
                HoverHandler { id: hhSet; cursorShape: Qt.PointingHandCursor }
            }
        }
    }
}
