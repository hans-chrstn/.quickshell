import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs.services

ColumnLayout {
    id: root
    spacing: 15
    Layout.alignment: Qt.AlignHCenter
    Layout.topMargin: 20
    visible: !!MusicService.activePlayer && MusicService.activePlayer.playbackState === MprisPlaybackState.Playing

    readonly property color accent: ColorService.accent

    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 2
        Text { 
            Layout.alignment: Qt.AlignHCenter
            text: MusicService.activePlayer ? MusicService.activePlayer.trackTitle : ""
            color: "white"; font.pixelSize: 15; font.weight: Font.Bold
            elide: Text.ElideRight; Layout.maximumWidth: 350 
        }
        Text { 
            Layout.alignment: Qt.AlignHCenter
            text: MusicService.activePlayer ? MusicService.activePlayer.trackArtist : ""
            color: "white"; opacity: 0.5; font.pixelSize: 13
            elide: Text.ElideRight; Layout.maximumWidth: 300 
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 30
        Text { 
            text: "󰒮"; color: "white"; font.pixelSize: 24; opacity: hPrev.hovered ? 1 : 0.6
            TapHandler { onTapped: { MusicService.activePlayer.previous(); SfxService.playButton2() } }
            HoverHandler { id: hPrev; cursorShape: Qt.PointingHandCursor } 
        }
        Rectangle {
            width: 50; height: 50; radius: 25; color: Qt.rgba(1, 1, 1, 0.1); border.color: root.accent; border.width: 1
            Rectangle { 
                anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 3; radius: 1.5; color: root.accent; opacity: 0.5; clip: true
                Rectangle { 
                    anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; 
                    width: (MusicService.activePlayer && MusicService.activePlayer.length > 0) ? (MusicService.activePlayer.position / MusicService.activePlayer.length) * parent.width : 0; color: root.accent 
                }
            }
            Text { anchors.centerIn: parent; text: MusicService.activePlayer && MusicService.activePlayer.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"; color: "white"; font.pixelSize: 32 }
            TapHandler { onTapped: { MusicService.activePlayer.togglePlaying(); SfxService.playButton2() } }
            HoverHandler { id: hPlay; cursorShape: Qt.PointingHandCursor }
            scale: hPlay.hovered ? 1.1 : 1.0; Behavior on scale { NumberAnimation { duration: 200 } }
        }
        Text { 
            text: "󰒭"; color: "white"; font.pixelSize: 24; opacity: hNext.hovered ? 1 : 0.6
            TapHandler { onTapped: { MusicService.activePlayer.next(); SfxService.playButton2() } }
            HoverHandler { id: hNext; cursorShape: Qt.PointingHandCursor } 
        }
    }
}
