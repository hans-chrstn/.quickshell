import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.config

Item {
    id: root
    property var player: null
    
    FrameAnimation {
        running: root.visible && root.player && root.player.playbackState === MprisPlaybackState.Playing
        onTriggered: if (root.player) root.player.positionChanged()
    }

    RowLayout { 
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 15
        
        ClippingRectangle { 
            Layout.preferredWidth: 60
            Layout.preferredHeight: 60
            radius: 30
            color: "#333" 
            Layout.alignment: Qt.AlignVCenter
            
            Item {
                anchors.fill: parent
                RotationAnimator on rotation { from: 0; to: 360; duration: 4000; loops: Animation.Infinite; running: root.player && root.player.playbackState === MprisPlaybackState.Playing }
                
                Image {
                    anchors.fill: parent
                    source: (root.player && root.player.trackArtUrl) || ""
                    fillMode: Image.PreserveAspectCrop
                }
            }
            
            Rectangle {
                width: 15; height: 15
                radius: 7.5
                color: FrameConfig.color
                anchors.centerIn: parent
            }
        }
        
        ColumnLayout { 
            Layout.fillWidth: true 
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2
            
            Item { Layout.fillHeight: true } 
            
            Text { 
                Layout.fillWidth: true
                text: (root.player && root.player.trackTitle) || "No Music"
                color: "white"
                font.weight: Font.DemiBold
                font.pixelSize: 14
                elide: Text.ElideRight 
                horizontalAlignment: Text.AlignLeft
            }
            Text { 
                Layout.fillWidth: true
                text: (root.player && root.player.trackArtist) || "Nothing playing"
                color: "white"
                opacity: 0.6
                font.pixelSize: 11
                elide: Text.ElideRight 
                horizontalAlignment: Text.AlignLeft
            }
            
            Item {
                id: progressBarArea
                Layout.fillWidth: true
                Layout.preferredHeight: 12
                Layout.topMargin: 4
                
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: 4
                    color: "white"
                    opacity: 0.1
                    radius: 2
                    
                    Rectangle {
                        height: parent.height
                        radius: 2
                        color: FrameConfig.accentColor
                        width: (root.player && root.player.length > 0) 
                               ? parent.width * (root.player.position / root.player.length) 
                               : 0
                        
                        Rectangle {
                            anchors.fill: parent
                            color: FrameConfig.accentColor
                            opacity: 0.3
                            radius: 2
                            visible: parent.width > 0
                        }
                    }
                }
                
                TapHandler {
                    onTapped: (event) => {
                        if (root.player && root.player.canSeek && root.player.length > 0) {
                            var pos = event.position.x / progressBarArea.width * root.player.length
                            root.player.position = pos
                        }
                    }
                }
            }

            Row { 
                spacing: 24
                visible: !!root.player
                Layout.alignment: Qt.AlignHCenter 
                Layout.topMargin: 4
                
                Text { text: "󰒮"; color: "white"; opacity: 0.8; font.pixelSize: 18; TapHandler { onTapped: if(root.player) root.player.previous() } }
                Text { 
                    text: (root.player && root.player.playbackState === MprisPlaybackState.Playing) ? "󰏤" : "󰐊"
                    color: "white"
                    font.pixelSize: 24
                    TapHandler { onTapped: if(root.player) root.player.togglePlaying() } 
                }
                Text { text: "󰒭"; color: "white"; opacity: 0.8; font.pixelSize: 18; TapHandler { onTapped: if(root.player) root.player.next() } }
            }
            
            Item { Layout.fillHeight: true }
        }
    }
}
