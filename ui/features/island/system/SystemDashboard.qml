import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.ui.shared

Item {
    id: root
    
    anchors.fill: parent

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 0

        RowLayout {
            id: mainLayout
            spacing: 24

            SystemControlTiles {
                id: controlTiles
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle {
                width: 1
                Layout.preferredHeight: 70
                color: ThemeManager.contentOnBackgroundColor
                opacity: 0.05
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                spacing: 12
                Layout.alignment: Qt.AlignVCenter
                
                SystemControlSliders { 
                    id: sliders
                    Layout.alignment: Qt.AlignVCenter
                }

                StyledLabel {
                    text: "OPEN SETTINGS " + ThemeManager.iconSettings
                    type: "caption"
                    font.weight: Font.Black
                    font.pixelSize: 8
                    letterSpacing: 1
                    customColor: ThemeManager.accentColor
                    Layout.alignment: Qt.AlignRight
                    Layout.topMargin: 4
                    
                    opacity: settingsInteractionHandler.hovered ? 1.0 : 0.6
                    scale: settingsInteractionHandler.hovered ? 1.05 : 1.0
                    
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                    Behavior on scale {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutQuart
                        }
                    }
                    
                    TapHandler { 
                        onTapped: { 
                            ViewManager.openSettings()
                            SoundManager.playClick()
                        } 
                    }
                    HoverHandler { 
                        id: settingsInteractionHandler
                        cursorShape: Qt.PointingHandCursor 
                    }
                }
            }
        }
    }
}
