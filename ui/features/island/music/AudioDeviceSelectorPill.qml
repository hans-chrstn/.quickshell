import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import qs.core
import qs.ui.shared

ExpandingPill {
    id: root

    property string mode: "device"
    
    expandable: (mode === "device" ? AudioManager.sinks.count > 0 : Mpris.players.values.length > 0)
    
    collapsedWidth: 100
    expandedWidth: 100
    collapsedHeight: 18
    expandedHeight: mode === "player" ? 64 : 44
    pillRadius: 9
    
    pillColor: Qt.rgba(1, 1, 1, 0.08)
    pillBorderColor: Qt.rgba(1, 1, 1, 0.1)

    RowLayout {
        id: headerRow
        Layout.fillWidth: true
        Layout.preferredHeight: 10
        spacing: 3

        BaseButton {
            width: 10
            height: 10
            cornerRadius: 2
            onClicked: root.mode = (root.mode === "device" ? "player" : "device")
            
            StyledLabel {
                anchors.centerIn: parent
                text: root.mode === "device" ? ThemeManager.iconAudioInput : ThemeManager.iconMusic
                type: "caption"
                font.pixelSize: 8
                opacity: 0.6
            }
        }

        StyledLabel {
            Layout.fillWidth: true
            text: {
                if (root.mode === "device") {
                    let sink = AudioManager.defaultSink
                    return sink ? (sink.description || sink.name || "Device") : "No Device"
                } else {
                    let player = MusicManager.activePlayer
                    return player ? (player.identity || player.name || "Player") : "No Player"
                }
            }
            type: "caption"
            font.pixelSize: 7
            font.weight: Font.Bold
            elideMode: Text.ElideRight
        }

        StyledLabel {
            text: root.isExpanded ? ThemeManager.iconClose : ThemeManager.iconSelector
            type: "caption"
            font.pixelSize: 7
            opacity: 0.4
            visible: root.expandable
        }

        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: root.mode = (root.mode === "device" ? "player" : "device")
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.isExpanded
        opacity: root.isExpanded ? 1 : 0
        
        Behavior on opacity {
            NumberAnimation {
                duration: 250
            }
        }

        ListView {
            id: unifiedList
            anchors.fill: parent
            anchors.topMargin: 1
            anchors.bottomMargin: 1
            model: root.mode === "device" ? AudioManager.sinks : Mpris.players.values
            spacing: 0
            clip: true
            interactive: true
            
            snapMode: ListView.SnapToItem
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: 0
            preferredHighlightEnd: 20
            
            boundsBehavior: Flickable.StopAtBounds

            delegate: BaseButton {
                id: delegateButton
                width: unifiedList.width
                height: 20
                cornerRadius: 4
                
                readonly property var currentItem: root.mode === "device" ? model : modelData

                onClicked: {
                    if (root.mode === "device") {
                        if (currentItem.node) AudioManager.selectSink(currentItem.node)
                    } else {
                        MusicManager.selectPlayer(currentItem)
                    }
                    root.isExpanded = false
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    spacing: 4

                    StyledLabel {
                        text: {
                            if (root.mode === "device") return ThemeManager.iconAudioOutput
                            return (currentItem.playbackState === MprisPlaybackState.Playing) ? "󰐊" : "󰏤"
                        }
                        type: "caption"
                        font.pixelSize: 8
                        opacity: delegateButton.isHovered ? 0.8 : 0.4
                    }

                    StyledLabel {
                        Layout.fillWidth: true
                        text: {
                            if (root.mode === "device") return currentItem.name || "Device"
                            return currentItem.name || currentItem.identity || "Player"
                        }
                        type: "caption"
                        font.pixelSize: 7
                        elideMode: Text.ElideRight
                        opacity: delegateButton.isHovered ? 1.0 : 0.7
                        font.weight: {
                            if (root.mode === "device") {
                                let sink = AudioManager.defaultSink
                                return (sink && sink.node === currentItem.node) ? Font.Bold : Font.Normal
                            } else {
                                let player = MusicManager.activePlayer
                                return (player && player.name === currentItem.name) ? Font.Bold : Font.Normal
                            }
                        }
                    }
                }
            }
        }
    }
}
