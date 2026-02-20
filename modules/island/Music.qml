import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.config
import qs.components

Item {
    id: root
    property var player: null
    
    RowLayout { 
        anchors.fill: parent
        anchors.margins: 15
        spacing: 20
        
        Item {
            Layout.preferredWidth: FrameConfig.musicArtSize
            Layout.preferredHeight: FrameConfig.musicArtSize
            Layout.alignment: Qt.AlignVCenter
            
            Rectangle {
                anchors.fill: parent; anchors.topMargin: 4
                radius: FrameConfig.musicArtRadius
                color: "black"; opacity: FrameConfig.musicArtShadowOpacity
            }

            Item {
                id: vinylDisk
                anchors.fill: parent
                
                RotationAnimator on rotation {
                    from: 0; to: 360
                    duration: 8000
                    loops: Animation.Infinite
                    running: root.player && root.player.playbackState === MprisPlaybackState.Playing
                }
                
                ClippingRectangle { 
                    anchors.fill: parent
                    radius: FrameConfig.musicArtRadius
                    color: "#222"
                    
                    Image {
                        anchors.fill: parent
                        source: (root.player && root.player.trackArtUrl) || ""
                        fillMode: Image.PreserveAspectCrop
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 500 } }
                    }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "󰝚"; color: "white"; opacity: 0.2; font.pixelSize: 24
                        visible: !root.player || !root.player.trackArtUrl || parent.children[0].status !== Image.Ready
                    }
                }
                
                Rectangle {
                    anchors.centerIn: parent
                    width: FrameConfig.musicHoleSize
                    height: FrameConfig.musicHoleSize
                    radius: width / 2
                    color: "#1e1e1e"
                    border.color: Qt.rgba(1, 1, 1, 0.1); border.width: 1
                }
            }
        }
        
        ColumnLayout { 
            Layout.fillWidth: true; spacing: 4
            Layout.alignment: Qt.AlignVCenter
            
            Text { 
                Layout.fillWidth: true
                text: (root.player && root.player.trackTitle) || "No Music"
                color: "white"; font.weight: Font.DemiBold; font.pixelSize: 14
                elide: Text.ElideRight 
            }
            Text { 
                Layout.fillWidth: true
                text: (root.player && root.player.trackArtist) || "Nothing playing"
                color: "white"; opacity: 0.5; font.pixelSize: 11
                elide: Text.ElideRight 
            }
            
            Item {
                Layout.fillWidth: true; Layout.preferredHeight: 4; Layout.topMargin: 8
                Rectangle { anchors.fill: parent; radius: 2; color: "white"; opacity: 0.1 }
                Rectangle {
                    height: parent.height; radius: 2; color: "white"; opacity: 0.8
                    width: (root.player && root.player.length > 0) ? parent.width * (root.player.position / root.player.length) : 0
                }
            }

            RowLayout { 
                Layout.fillWidth: true; Layout.topMargin: 8
                spacing: FrameConfig.musicControlSpacing
                Layout.alignment: Qt.AlignHCenter
                
                Item { Layout.fillWidth: true }
                
                Text { 
                    text: "󰒮"; color: "white"; opacity: 0.6; font.pixelSize: 20
                    Layout.alignment: Qt.AlignVCenter
                    TapHandler { onTapped: root.player.previous() } 
                }
                
                Text { 
                    text: (root.player && root.player.playbackState === MprisPlaybackState.Playing) ? "󰏤" : "󰐊"
                    color: "white"; font.pixelSize: 28
                    Layout.alignment: Qt.AlignVCenter
                    TapHandler { onTapped: root.player.togglePlaying() } 
                }
                
                Text { 
                    text: "󰒭"; color: "white"; opacity: 0.6; font.pixelSize: 20
                    Layout.alignment: Qt.AlignVCenter
                    TapHandler { onTapped: root.player.next() } 
                }
                
                Item { Layout.fillWidth: true }
            }
        }
    }
}
