import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.core
import qs.shared
import qs.ui.shared

Item {
    id: root
    
    property var mediaPlayer: null
    
    RowLayout { 
        anchors.fill: parent
        anchors.margins: 15
        spacing: 20
        
        Item {
            Layout.preferredWidth: ThemeManager.musicArtSize
            Layout.preferredHeight: ThemeManager.musicArtSize
            Layout.alignment: Qt.AlignVCenter
            visible: ThemeManager.isMusicArtVisible
            
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
                
                ClippingRectangle { 
                    anchors.fill: parent
                    radius: ThemeManager.musicArtRadius
                    color: ThemeManager.surfaceVariantColor
                    
                    Image {
                        id: albumArtImage
                        anchors.fill: parent
                        source: (root.mediaPlayer && root.mediaPlayer.trackArtUrl) || ""
                        fillMode: Image.PreserveAspectCrop
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { 
                            NumberAnimation { 
                                duration: 500 
                            } 
                        }
                    }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "󰝚"
                        color: ThemeManager.contentOnBackgroundColor
                        opacity: 0.2
                        font.pixelSize: 24
                        visible: !root.mediaPlayer || !root.mediaPlayer.trackArtUrl || albumArtImage.status !== Image.Ready
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
        
        ColumnLayout { 
            Layout.fillWidth: true
            spacing: 4
            Layout.alignment: Qt.AlignVCenter
            
            Text { 
                Layout.fillWidth: true
                text: (root.mediaPlayer && root.mediaPlayer.trackTitle) || "No Media Playing"
                color: ThemeManager.contentOnBackgroundColor
                font.weight: Font.DemiBold
                font.pixelSize: 14
                elide: Text.ElideRight 
            }
            Text { 
                Layout.fillWidth: true
                text: (root.mediaPlayer && root.mediaPlayer.trackArtist) || "Unknown Artist"
                color: ThemeManager.contentSecondaryColor
                opacity: 0.8
                font.pixelSize: 11
                elide: Text.ElideRight 
            }
            
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                Layout.topMargin: 8
                
                property bool isHovered: progressBarMouseArea.containsMouse
                property bool isDragging: progressBarMouseArea.pressed
                
                height: isHovered || isDragging ? 8 : 4
                Behavior on height { 
                    NumberAnimation { 
                        duration: 200
                        easing.type: Easing.OutQuart 
                    } 
                }
                
                Rectangle { 
                    anchors.fill: parent
                    radius: 2
                    color: ThemeManager.contentOnBackgroundColor
                    opacity: 0.1 
                }
                
                Rectangle {
                    height: parent.height
                    radius: 2
                    color: ThemeManager.contentOnBackgroundColor
                    opacity: 0.8
                    width: (root.mediaPlayer && root.mediaPlayer.length > 0) 
                        ? parent.width * (root.mediaPlayer.position / root.mediaPlayer.length) 
                        : 0
                }
                
                MouseArea {
                    id: progressBarMouseArea
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    preventStealing: true
                    cursorShape: Qt.PointingHandCursor
                    
                    function updatePosition(mouse) {
                        if (root.mediaPlayer && root.mediaPlayer.length > 0) {
                            let percentage = MathUtils.clamp(mouse.x / width, 0, 1)
                            root.mediaPlayer.position = percentage * root.mediaPlayer.length
                        }
                    }
                    
                    onPressed: (mouse) => updatePosition(mouse)
                    onPositionChanged: (mouse) => { if (pressed) updatePosition(mouse) }
                }
            }

            RowLayout { 
                Layout.fillWidth: true
                Layout.topMargin: 8
                spacing: ThemeManager.musicControlSpacing
                Layout.alignment: Qt.AlignHCenter
                
                Item { Layout.fillWidth: true }
                
                BaseButton {
                    Layout.alignment: Qt.AlignVCenter
                    width: 24; height: 24
                    hoverScale: 1.2
                    onClicked: root.mediaPlayer.previous()
                    
                    Text { 
                        anchors.centerIn: parent
                        text: "󰒮"
                        color: ThemeManager.contentOnBackgroundColor
                        opacity: 0.6
                        font.pixelSize: 20
                    }
                }
                
                BaseButton {
                    Layout.alignment: Qt.AlignVCenter
                    width: 32; height: 32
                    hoverScale: 1.2
                    onClicked: root.mediaPlayer.togglePlaying()
                    
                    Text { 
                        anchors.centerIn: parent
                        text: (root.mediaPlayer && root.mediaPlayer.playbackState === MprisPlaybackState.Playing) ? "󰏤" : "󰐊"
                        color: ThemeManager.contentOnBackgroundColor
                        font.pixelSize: 28
                    }
                }
                
                BaseButton {
                    Layout.alignment: Qt.AlignVCenter
                    width: 24; height: 24
                    hoverScale: 1.2
                    onClicked: root.mediaPlayer.next()
                    
                    Text { 
                        anchors.centerIn: parent
                        text: "󰒭"
                        color: ThemeManager.contentOnBackgroundColor
                        opacity: 0.6
                        font.pixelSize: 20
                    }
                }
                
                Item { Layout.fillWidth: true }
            }
        }
    }
}
