import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs.core

ColumnLayout {
    id: root
    
    spacing: 15
    Layout.alignment: Qt.AlignHCenter
    Layout.topMargin: 20
    visible: !!MusicManager.activePlayer && MusicManager.activePlayer.playbackState === MprisPlaybackState.Playing

    readonly property color accentColor: ColorManager.accentColor

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

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 30
        
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
            width: 50
            height: 50
            radius: 25
            color: Qt.rgba(1, 1, 1, 0.1)
            border.color: root.accentColor
            border.width: 1
            
            Rectangle { 
                id: trackProgressTrack
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 3
                radius: 1.5
                color: root.accentColor
                opacity: 0.5
                clip: true
                
                Rectangle { 
                    id: trackProgressBar
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: (MusicManager.activePlayer && MusicManager.activePlayer.length > 0) 
                        ? (MusicManager.activePlayer.position / MusicManager.activePlayer.length) * parent.width 
                        : 0
                    color: root.accentColor 
                }
            }
            
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
