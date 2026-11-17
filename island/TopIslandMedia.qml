import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.components
import qs.core
import qs.services.media

Item {
    id: root

    property bool expanded: false
    property var player: PlayerService.activePlayer
    property var availablePlayers: PlayerService.players
    readonly property bool hasPlayer: player !== null
    readonly property bool playing: player?.isPlaying === true
    readonly property int trackId: player?.uniqueId || 0

    onTrackIdChanged: trackReveal.restart()

    ParallelAnimation {
        id: trackReveal
        running: false
        NumberAnimation {
            target: artwork
            property: "scale"
            from: Design.mediaTrackRevealScale
            to: 1
            duration: Design.mediaTrackRevealDuration
            easing.type: Design.mediaTrackRevealEasing
        }
        NumberAnimation {
            target: trackDetails
            property: "opacity"
            from: 0.35
            to: 1
            duration: Design.springContentFadeInDuration
            easing.type: Design.motionStandardEasing
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: Design.space20
        anchors.rightMargin: Design.space20
        anchors.topMargin: root.expanded ? Design.space20 : Design.space16
        anchors.bottomMargin: root.expanded ? Design.space16 : Design.space12
        spacing: root.expanded ? Design.space8 : Design.space4

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.expanded ? 118 : 72
            spacing: Design.space16

            MediaArtwork {
                id: artwork
                Layout.preferredWidth: root.expanded ? 118 : 72
                Layout.preferredHeight: Layout.preferredWidth
                sourceUrl: root.player?.trackArtUrl || ""
                cornerRadius: root.expanded ? Design.radiusPanel : Design.radiusGrouped
            }

            ColumnLayout {
                id: trackDetails
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: root.expanded ? Design.space6 : Design.space2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Design.space6

                    Rectangle {
                        Layout.preferredWidth: 5
                        Layout.preferredHeight: 5
                        radius: 3
                        color: root.playing ? Theme.accent : Theme.textTertiary
                        Behavior on color {
                            ColorAnimation {
                                duration: Design.motionStateDuration
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.hasPlayer ? root.player.identity : "MEDIA"
                        color: Theme.textTertiary
                        font.family: Design.fontText
                        font.pixelSize: Design.typeCaption
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.player?.trackTitle || (root.hasPlayer ? "Unknown title" : "Nothing playing")
                    color: Theme.textPrimary
                    font.family: Design.fontDisplay
                    font.pixelSize: root.expanded ? Design.typeDisplay : Design.typeTitle
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.player?.trackArtist || (root.hasPlayer ? "Unknown artist" : "Open a media player")
                    color: Theme.textSecondary
                    font.family: Design.fontText
                    font.pixelSize: Design.typeBody
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.expanded && (root.player?.trackAlbum || "").length > 0 && root.player.trackAlbum !== root.player.trackTitle
                    text: root.player?.trackAlbum || ""
                    color: Theme.textTertiary
                    font.family: Design.fontText
                    font.pixelSize: Design.typeLabel
                    elide: Text.ElideRight
                }
            }
        }

        MediaProgress {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            player: root.player
            peak: PlayerService.peak
            onSeekRequested: seconds => PlayerService.seekTo(seconds)
            onSeekDeltaRequested: seconds => PlayerService.seekBy(seconds)
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            spacing: Design.space8

            Item {
                Layout.fillWidth: true
            }
            GlyphButton {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                glyph: "skipPrevious"
                accessibleName: "Previous track"
                enabled: root.player?.canGoPrevious === true
                onActivated: PlayerService.previous()
            }
            GlyphButton {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                glyph: root.playing ? "pause" : "play"
                accessibleName: root.playing ? "Pause" : "Play"
                enabled: root.player?.canTogglePlaying === true
                primary: true
                onActivated: PlayerService.togglePlaying()
            }
            GlyphButton {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                glyph: "skipNext"
                accessibleName: "Next track"
                enabled: root.player?.canGoNext === true
                onActivated: PlayerService.next()
            }
            Item {
                Layout.fillWidth: true
            }
        }

        RowLayout {
            visible: root.expanded
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            spacing: Design.space8

            GlyphButton {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                glyph: "shuffle"
                accessibleName: root.player?.shuffle ? "Disable shuffle" : "Enable shuffle"
                enabled: root.player?.canControl === true && root.player?.shuffleSupported === true
                primary: root.player?.shuffle === true
                onActivated: PlayerService.toggleShuffle()
            }
            GlyphButton {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                glyph: "repeat"
                accessibleName: root.player?.loopState === MprisLoopState.Track ? "Repeat track" : root.player?.loopState === MprisLoopState.Playlist ? "Repeat playlist" : "Enable repeat"
                enabled: root.player?.canControl === true && root.player?.loopSupported === true
                primary: root.hasPlayer && root.player.loopState !== MprisLoopState.None
                onActivated: PlayerService.cycleRepeat()
            }
            Item {
                Layout.fillWidth: true
            }
        }

        RowLayout {
            visible: root.expanded && root.availablePlayers.length > 1
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            spacing: Design.space6

            Repeater {
                model: root.availablePlayers

                Rectangle {
                    required property var modelData
                    required property int index
                    Layout.preferredHeight: 26
                    Layout.preferredWidth: Math.min(130, Math.max(52, label.implicitWidth + 18))
                    radius: Design.radiusControl
                    color: root.player?.dbusName === modelData.dbusName ? Theme.fillSelected : Theme.fillQuiet
                    border.color: root.player?.dbusName === modelData.dbusName ? Theme.accent : Theme.separator

                    Behavior on color {
                        ColorAnimation {
                            duration: Design.motionStateDuration
                        }
                    }

                    Text {
                        id: label
                        anchors.centerIn: parent
                        width: parent.width - 16
                        text: (modelData.identity || "Player") + (root.availablePlayers.filter(candidate => candidate.identity === modelData.identity).length > 1 ? " " + (index + 1) : "")
                        color: root.player?.dbusName === modelData.dbusName ? Theme.textPrimary : Theme.textSecondary
                        font.family: Design.fontText
                        font.pixelSize: Design.typeLabel
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: PlayerService.selectPlayer(modelData.dbusName)
                        Accessible.role: Accessible.Button
                        Accessible.name: "Select " + (modelData.identity || "media player")
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }
    }
}
