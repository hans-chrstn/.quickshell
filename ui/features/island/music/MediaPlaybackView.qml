import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.core
import qs.shared
import qs.ui.shared

Item {
    id: root

    property var mediaPlayer: MusicManager.activePlayer
    readonly property bool isHovered: mainHoverHandler.hovered
    readonly property alias isSelectorExpanded: deviceSelector.isExpanded

    function collapseSelector() {
        deviceSelector.isExpanded = false
    }

    HoverHandler {
        id: mainHoverHandler
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 20

        Item {
            id: vinylContainer
            Layout.preferredWidth: ThemeManager.musicArtSize
            Layout.preferredHeight: ThemeManager.musicArtSize
            Layout.alignment: Qt.AlignVCenter
            visible: ThemeManager.isMusicArtVisible

            LazyContainer {
                id: vinylLoader
                anchors.fill: parent
                active: true
                
                component: Component {
                    Item {
                        id: vinylDiskVisual
                        anchors.fill: parent
                        z: 1

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowOpacity: ThemeManager.musicArtShadowOpacity
                            shadowBlur: 0.4
                            shadowVerticalOffset: 2
                        }

                        NumberAnimation on rotation {
                            from: 0
                            to: 360
                            duration: ThemeManager.musicRotationDuration
                            loops: Animation.Infinite
                            running: root.mediaPlayer && root.mediaPlayer.playbackState === MprisPlaybackState.Playing
                        }

                        SequentialAnimation on scale {
                            running: root.mediaPlayer && root.mediaPlayer.playbackState === MprisPlaybackState.Playing
                            loops: Animation.Infinite
                            NumberAnimation {
                                to: 1.05
                                duration: 2000
                                easing.type: Easing.OutSine
                            }
                            NumberAnimation {
                                to: 1.0
                                duration: 2000
                                easing.type: Easing.OutSine
                            }
                        }

                        ClippingRectangle {
                            id: artContainer
                            anchors.fill: parent
                            radius: width / 2
                            color: ThemeManager.surfaceVariantColor

                            property string resolvedArtUrl: ""

                            Process {
                                id: artConvertProc
                                property string targetUrl: ""
                                command: ["sh", "-c", "curl -s '" + targetUrl + "' -o /tmp/qs_art.webp && magick /tmp/qs_art.webp /tmp/qs_art.jpg"]
                                onExited: (exitCode) => {
                                    if (exitCode === 0) {
                                        artContainer.resolvedArtUrl = "file:///tmp/qs_art.jpg";
                                    } else {
                                        artContainer.resolvedArtUrl = targetUrl;
                                    }
                                }
                            }

                            Connections {
                                target: root.mediaPlayer
                                function onTrackArtUrlChanged() {
                                    artContainer.checkAndFetchArt()
                                }
                            }

                            Component.onCompleted: checkAndFetchArt()

                            function checkAndFetchArt() {
                                let url = root.mediaPlayer ? (root.mediaPlayer.trackArtUrl || "") : "";
                                if (url.startsWith("http") && url.includes("getCoverArt.view")) {
                                    artConvertProc.targetUrl = url;
                                    artConvertProc.running = true;
                                } else {
                                    artContainer.resolvedArtUrl = url;
                                }
                            }

                            Image {
                                id: albumArtImage
                                anchors.fill: parent
                                source: artContainer.resolvedArtUrl || ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: false
                                opacity: status === Image.Ready ? 1 : 0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 500
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: ThemeManager.iconMusic
                                color: ThemeManager.contentOnBackgroundColor
                                opacity: 0.5
                                font.pixelSize: 28
                                visible: albumArtImage.status !== Image.Ready
                            }
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: ThemeManager.musicHoleSize
                            height: ThemeManager.musicHoleSize
                            radius: width / 2
                            color: ThemeManager.backgroundPrimaryColor
                            border.color: ThemeManager.outlineVariantColor
                            border.width: 1
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 6

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledLabel {
                    Layout.fillWidth: true
                    Layout.rightMargin: 100
                    type: "body"
                    text: (root.mediaPlayer && root.mediaPlayer.trackTitle) || "No Media Playing"
                    font.weight: Font.DemiBold
                    font.pixelSize: 14
                    elideMode: Text.ElideRight
                }

                StyledLabel {
                    Layout.fillWidth: true
                    Layout.rightMargin: 100
                    type: "caption"
                    text: (root.mediaPlayer && root.mediaPlayer.trackArtist) || "Unknown Artist"
                    customColor: ThemeManager.contentSecondaryColor
                    opacity: 0.6
                    font.pixelSize: 11
                    elideMode: Text.ElideRight
                }
            }

            Item {
                id: progressBarContainer
                Layout.fillWidth: true
                Layout.preferredHeight: 6
                Layout.topMargin: 12

                Rectangle {
                    anchors.fill: parent
                    radius: 3
                    color: "#333333"
                }

                Rectangle {
                    height: parent.height
                    radius: 3
                    color: "white"
                    width: (root.mediaPlayer && root.mediaPlayer.length > 0)
                        ? parent.width * (root.mediaPlayer.position / root.mediaPlayer.length)
                        : 0

                    Behavior on width {
                        NumberAnimation {
                            duration: 500
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                MouseArea {
                    id: progressBarMouseArea
                    anchors.fill: parent
                    anchors.margins: -10
                    hoverEnabled: true
                    preventStealing: true
                    cursorShape: Qt.PointingHandCursor

                    function updatePosition(mouse) {
                        if (root.mediaPlayer && root.mediaPlayer.length > 0) {
                            let percentage = MathUtils.clamp(mouse.x / width, 0, 1)
                            root.mediaPlayer.position = percentage * root.mediaPlayer.length
                        }
                    }

                    onPressed: (mouse) => {
                        updatePosition(mouse)
                    }
                    onPositionChanged: (mouse) => {
                        if (pressed) {
                            updatePosition(mouse)
                        }
                    }
                }
            }

            RowLayout {
                id: playbackControls
                Layout.fillWidth: true
                spacing: 12
                Layout.alignment: Qt.AlignHCenter

                Item { Layout.fillWidth: true }

                BaseButton {
                    Layout.alignment: Qt.AlignVCenter
                    width: 22
                    height: 22
                    cornerRadius: 11
                    hoverScale: 1.2
                    tooltip: "Previous Track"
                    onClicked: {
                        root.mediaPlayer.previous()
                    }
                    opacity: root.isHovered ? 0.8 : 0.15
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 250
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: ThemeManager.iconPrevious
                        color: ThemeManager.contentOnBackgroundColor
                        font.pixelSize: 16
                    }
                }

                BaseButton {
                    Layout.alignment: Qt.AlignVCenter
                    width: 28
                    height: 28
                    cornerRadius: 14
                    hoverScale: 1.2
                    tooltip: (root.mediaPlayer && root.mediaPlayer.playbackState === MprisPlaybackState.Playing) ? "Pause" : "Play"
                    onClicked: {
                        root.mediaPlayer.togglePlaying()
                    }

                    Text {
                        anchors.centerIn: parent
                        text: (root.mediaPlayer && root.mediaPlayer.playbackState === MprisPlaybackState.Playing) ? ThemeManager.iconPause : ThemeManager.iconPlay
                        color: ThemeManager.contentOnBackgroundColor
                        font.pixelSize: 24
                    }
                }

                BaseButton {
                    Layout.alignment: Qt.AlignVCenter
                    width: 22
                    height: 22
                    cornerRadius: 11
                    hoverScale: 1.2
                    tooltip: "Next Track"
                    onClicked: {
                        root.mediaPlayer.next()
                    }
                    opacity: root.isHovered ? 0.8 : 0.15
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 250
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: ThemeManager.iconNext
                        color: ThemeManager.contentOnBackgroundColor
                        font.pixelSize: 16
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }
    }

    AudioDeviceSelectorPill {
        id: deviceSelector
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 16
        anchors.rightMargin: 15
        z: 100
    }
}
