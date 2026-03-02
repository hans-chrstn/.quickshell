import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs.core

Item {
    id: root
    
    implicitWidth: 400
    implicitHeight: 150
    visible: !!MusicManager.activePlayer && MusicManager.activePlayer.playbackState === MprisPlaybackState.Playing

    readonly property color accentColor: ColorManager.accentColor

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 2
            
            Text { 
                id: trackTitleLabel
                Layout.alignment: Qt.AlignHCenter
                text: MusicManager.activePlayer ? MusicManager.activePlayer.trackTitle : ""
                color: ThemeManager.contentOnBackgroundColor
                font.pixelSize: 15
                font.weight: Font.Bold
                elide: Text.ElideRight
                Layout.maximumWidth: 350 
            }
            
            Text { 
                id: trackArtistLabel
                Layout.alignment: Qt.AlignHCenter
                text: MusicManager.activePlayer ? MusicManager.activePlayer.trackArtist : ""
                color: ThemeManager.contentOnBackgroundColor
                opacity: 0.5
                font.pixelSize: 13
                elide: Text.ElideRight
                Layout.maximumWidth: 300 
            }
        }

        Item {
            id: progressContainer
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 240
            Layout.preferredHeight: 4
            Layout.topMargin: 8
            Layout.bottomMargin: 8

            Rectangle {
                anchors.fill: parent
                radius: 2
                color: ThemeManager.contentOnBackgroundColor
                opacity: 0.1
            }

            Rectangle {
                id: progressBar
                height: parent.height
                radius: 2
                color: root.accentColor
                width: (MusicManager.activePlayer && MusicManager.activePlayer.length > 0) 
                    ? (MusicManager.activePlayer.position / MusicManager.activePlayer.length) * parent.width 
                    : 0
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 40
            
            Text { 
                id: previousTrackIcon
                text: "󰒮"
                color: ThemeManager.contentOnBackgroundColor
                font.pixelSize: 24
                opacity: previousTrackHoverHandler.hovered ? 1 : 0.6
                
                TapHandler { 
                    onTapped: { 
                        MusicManager.activePlayer.previous()
                        SoundManager.playToggle() 
                    } 
                }
                HoverHandler { 
                    id: previousTrackHoverHandler
                    cursorShape: Qt.PointingHandCursor 
                } 
            }
            
            Rectangle {
                id: playPauseButtonContainer
                width: 54
                height: 54
                radius: 27
                color: Qt.rgba(1, 1, 1, 0.1)
                border.color: root.accentColor
                border.width: 1
                
                Text { 
                    id: playPauseIcon
                    anchors.centerIn: parent
                    text: MusicManager.activePlayer && MusicManager.activePlayer.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"
                    color: ThemeManager.contentOnBackgroundColor
                    font.pixelSize: 32 
                }
                
                TapHandler { 
                    onTapped: { 
                        MusicManager.activePlayer.togglePlaying()
                        SoundManager.playToggle() 
                    } 
                }
                HoverHandler { 
                    id: playPauseHoverHandler
                    cursorShape: Qt.PointingHandCursor 
                }
                
                scale: playPauseHoverHandler.hovered ? 1.1 : 1.0
                Behavior on scale { 
                    NumberAnimation { 
                        duration: 200 
                    } 
                }
            }
            
            Text { 
                id: nextTrackIcon
                text: "󰒭"
                color: ThemeManager.contentOnBackgroundColor
                font.pixelSize: 24
                opacity: nextTrackHoverHandler.hovered ? 1 : 0.6
                
                TapHandler { 
                    onTapped: { 
                        MusicManager.activePlayer.next()
                        SoundManager.playToggle() 
                    } 
                }
                HoverHandler { 
                    id: nextTrackHoverHandler
                    cursorShape: Qt.PointingHandCursor 
                } 
            }
        }
    }
}
